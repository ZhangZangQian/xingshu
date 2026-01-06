import relationalStore from '@ohos.data.relationalStore';
import { Macro, Trigger, Action, Condition, ExecutionLog } from '../models/Macro';
import Logger from '../utils/Logger';

/**
 * 数据库服务
 * 封装所有数据库操作
 */
export class DatabaseService {
  private static instance: DatabaseService;
  private store: relationalStore.RdbStore | null = null;
  private static readonly DB_NAME = 'HarmonyMacro.db';
  private static readonly DB_VERSION = 1;

  private constructor() {
  }

  public static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  /**
   * 初始化数据库
   */
  async initialize(context: Context): Promise<void> {
    if (this.store) {
      Logger.info('DatabaseService', 'Database already initialized');
      return;
    }

    Logger.info('DatabaseService', 'Initializing database...');

    const config: relationalStore.StoreConfig = {
      name: DatabaseService.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.store = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      Logger.info('DatabaseService', 'Database initialized successfully');
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to initialize database', error as Error);
      throw new Error(`数据库初始化失败: ${error.message}`);
    }
  }

  /**
   * 创建数据库表
   */
  private async createTables(): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const createTableSQLs = [
      // 宏定义表
      `CREATE TABLE IF NOT EXISTS macro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL CHECK(LENGTH(name) >= 1 AND LENGTH(name) <= 50),
        description TEXT,
        icon TEXT,
        enabled INTEGER DEFAULT 1 CHECK(enabled IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )`,

      // 创建索引
      `CREATE INDEX IF NOT EXISTS idx_macro_enabled ON macro(enabled)`,
      `CREATE INDEX IF NOT EXISTS idx_macro_updated_at ON macro(updated_at DESC)`,

      // 触发器表
      `CREATE TABLE IF NOT EXISTS trigger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        macro_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('time', 'network', 'manual', 'clipboard')),
        config TEXT NOT NULL,
        enabled INTEGER DEFAULT 1 CHECK(enabled IN (0, 1)),
        FOREIGN KEY (macro_id) REFERENCES macro(id) ON DELETE CASCADE
      )`,

      // 创建索引
      `CREATE INDEX IF NOT EXISTS idx_trigger_macro_id ON trigger(macro_id)`,
      `CREATE INDEX IF NOT EXISTS idx_trigger_type ON trigger(type)`,

      // 动作表
      `CREATE TABLE IF NOT EXISTS action (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        macro_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN (
          'launch_app', 'notification', 'http_request',
          'clipboard_read', 'clipboard_write',
          'open_url', 'text_process', 'user_dialog'
        )),
        config TEXT NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (macro_id) REFERENCES macro(id) ON DELETE CASCADE
      )`,

      // 创建索引
      `CREATE INDEX IF NOT EXISTS idx_action_macro_id ON action(macro_id)`,
      `CREATE INDEX IF NOT EXISTS idx_action_order ON action(macro_id, order_index)`,

      // 条件表
      `CREATE TABLE IF NOT EXISTS condition (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        macro_id INTEGER NOT NULL,
        field TEXT NOT NULL,
        operator TEXT NOT NULL CHECK(operator IN ('==', '!=', '>', '<', '>=', '<=', 'contains', 'regex')),
        value TEXT NOT NULL,
        FOREIGN KEY (macro_id) REFERENCES macro(id) ON DELETE CASCADE
      )`,

      // 创建索引
      `CREATE INDEX IF NOT EXISTS idx_condition_macro_id ON condition(macro_id)`,

      // 执行日志表
      `CREATE TABLE IF NOT EXISTS execution_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        macro_id INTEGER NOT NULL,
        trigger_type TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('success', 'failed', 'partial')),
        error_message TEXT,
        executed_at INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        FOREIGN KEY (macro_id) REFERENCES macro(id) ON DELETE CASCADE
      )`,

      // 创建索引
      `CREATE INDEX IF NOT EXISTS idx_log_macro_id ON execution_log(macro_id)`,
      `CREATE INDEX IF NOT EXISTS idx_log_executed_at ON execution_log(executed_at DESC)`,
      `CREATE INDEX IF NOT EXISTS idx_log_status ON execution_log(status)`,

      // 数据库版本表
      `CREATE TABLE IF NOT EXISTS db_version (
        version INTEGER PRIMARY KEY,
        applied_at INTEGER NOT NULL
      )`,

      // 插入初始版本
      `INSERT OR IGNORE INTO db_version (version, applied_at) VALUES (${DatabaseService.DB_VERSION}, ${Date.now()})`
    ];

    for (const sql of createTableSQLs) {
      try {
        await this.store.executeSql(sql);
      } catch (error) {
        Logger.error('DatabaseService', `Failed to execute SQL: ${sql}`, error as Error);
        throw error;
      }
    }

    Logger.info('DatabaseService', 'Database tables created');
  }

  // ==================== 宏 CRUD ====================

  /**
   * 创建宏
   */
  async insertMacro(macro: Omit<Macro, 'id'>): Promise<number> {
    if (!this.store) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      name: macro.name,
      description: macro.description || '',
      icon: macro.icon || '',
      enabled: macro.enabled ? 1 : 0,
      created_at: macro.createdAt,
      updated_at: macro.updatedAt
    };

    try {
      const rowId = await this.store.insert('macro', valueBucket);
      Logger.info('DatabaseService', `Macro created with id: ${rowId}`);
      return rowId as number;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to insert macro', error as Error);
      throw new Error(`创建宏失败: ${error.message}`);
    }
  }

  /**
   * 查询宏（按 ID）
   */
  async getMacroById(id: number): Promise<Macro | null> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('macro');
    predicates.equalTo('id', id);

    try {
      const resultSet = await this.store.query(predicates);

      if (resultSet.goToFirstRow()) {
        const macro = this.parseMacroFromResultSet(resultSet);
        resultSet.close();
        return macro;
      }

      resultSet.close();
      return null;
    } catch (error) {
      Logger.error('DatabaseService', `Failed to get macro ${id}`, error as Error);
      throw new Error(`查询宏失败: ${error.message}`);
    }
  }

  /**
   * 查询所有宏
   */
  async getAllMacros(): Promise<Macro[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('macro');
    predicates.orderByDesc('updated_at');

    try {
      const resultSet = await this.store.query(predicates);
      const macros: Macro[] = [];

      while (resultSet.goToNextRow()) {
        macros.push(this.parseMacroFromResultSet(resultSet));
      }

      resultSet.close();
      Logger.info('DatabaseService', `Retrieved ${macros.length} macros`);
      return macros;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to get all macros', error as Error);
      throw new Error(`查询宏列表失败: ${error.message}`);
    }
  }

  /**
   * 查询已启用的宏
   */
  async getEnabledMacros(): Promise<Macro[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('macro');
    predicates.equalTo('enabled', 1);

    try {
      const resultSet = await this.store.query(predicates);
      const macros: Macro[] = [];

      while (resultSet.goToNextRow()) {
        macros.push(this.parseMacroFromResultSet(resultSet));
      }

      resultSet.close();
      return macros;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to get enabled macros', error as Error);
      throw new Error(`查询已启用宏失败: ${error.message}`);
    }
  }

  /**
   * 更新宏
   */
  async updateMacro(id: number, updates: Partial<Omit<Macro, 'id' | 'createdAt'>>): Promise<void> {
    if (!this.store) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {};
    if (updates.name !== undefined) valueBucket.name = updates.name;
    if (updates.description !== undefined) valueBucket.description = updates.description;
    if (updates.icon !== undefined) valueBucket.icon = updates.icon;
    if (updates.enabled !== undefined) valueBucket.enabled = updates.enabled ? 1 : 0;
    valueBucket.updated_at = Date.now();

    const predicates = new relationalStore.RdbPredicates('macro');
    predicates.equalTo('id', id);

    try {
      await this.store.update(valueBucket, predicates);
      Logger.info('DatabaseService', `Macro ${id} updated`);
    } catch (error) {
      Logger.error('DatabaseService', `Failed to update macro ${id}`, error as Error);
      throw new Error(`更新宏失败: ${error.message}`);
    }
  }

  /**
   * 更新宏启用状态
   */
  async updateMacroEnabled(id: number, enabled: boolean): Promise<void> {
    await this.updateMacro(id, { enabled });
  }

  /**
   * 删除宏（级联删除触发器、动作、条件、日志）
   */
  async deleteMacro(id: number): Promise<void> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('macro');
    predicates.equalTo('id', id);

    try {
      await this.store.delete(predicates);
      Logger.info('DatabaseService', `Macro ${id} deleted`);
    } catch (error) {
      Logger.error('DatabaseService', `Failed to delete macro ${id}`, error as Error);
      throw new Error(`删除宏失败: ${error.message}`);
    }
  }

  // ==================== 触发器 CRUD ====================

  /**
   * 创建触发器
   */
  async insertTrigger(trigger: Omit<Trigger, 'id'>): Promise<number> {
    if (!this.store) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      macro_id: trigger.macroId,
      type: trigger.type,
      config: trigger.config,
      enabled: trigger.enabled ? 1 : 0
    };

    try {
      const rowId = await this.store.insert('trigger', valueBucket);
      return rowId as number;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to insert trigger', error as Error);
      throw new Error(`创建触发器失败: ${error.message}`);
    }
  }

  /**
   * 查询宏的所有触发器
   */
  async getTriggersByMacroId(macroId: number): Promise<Trigger[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('trigger');
    predicates.equalTo('macro_id', macroId);

    try {
      const resultSet = await this.store.query(predicates);
      const triggers: Trigger[] = [];

      while (resultSet.goToNextRow()) {
        triggers.push(this.parseTriggerFromResultSet(resultSet));
      }

      resultSet.close();
      return triggers;
    } catch (error) {
      Logger.error('DatabaseService', `Failed to get triggers for macro ${macroId}`, error as Error);
      throw new Error(`查询触发器失败: ${error.message}`);
    }
  }

  // ==================== 动作 CRUD ====================

  /**
   * 创建动作
   */
  async insertAction(action: Omit<Action, 'id'>): Promise<number> {
    if (!this.store) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      macro_id: action.macroId,
      type: action.type,
      config: action.config,
      order_index: action.orderIndex
    };

    try {
      const rowId = await this.store.insert('action', valueBucket);
      return rowId as number;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to insert action', error as Error);
      throw new Error(`创建动作失败: ${error.message}`);
    }
  }

  /**
   * 查询宏的所有动作（按 order_index 排序）
   */
  async getActionsByMacroId(macroId: number): Promise<Action[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('action');
    predicates.equalTo('macro_id', macroId);
    predicates.orderByAsc('order_index');

    try {
      const resultSet = await this.store.query(predicates);
      const actions: Action[] = [];

      while (resultSet.goToNextRow()) {
        actions.push(this.parseActionFromResultSet(resultSet));
      }

      resultSet.close();
      return actions;
    } catch (error) {
      Logger.error('DatabaseService', `Failed to get actions for macro ${macroId}`, error as Error);
      throw new Error(`查询动作失败: ${error.message}`);
    }
  }

  // ==================== 条件 CRUD ====================

  /**
   * 创建条件
   */
  async insertCondition(condition: Omit<Condition, 'id'>): Promise<number> {
    if (!this.store) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      macro_id: condition.macroId,
      field: condition.field,
      operator: condition.operator,
      value: condition.value
    };

    try {
      const rowId = await this.store.insert('condition', valueBucket);
      return rowId as number;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to insert condition', error as Error);
      throw new Error(`创建条件失败: ${error.message}`);
    }
  }

  /**
   * 查询宏的所有条件
   */
  async getConditionsByMacroId(macroId: number): Promise<Condition[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('condition');
    predicates.equalTo('macro_id', macroId);

    try {
      const resultSet = await this.store.query(predicates);
      const conditions: Condition[] = [];

      while (resultSet.goToNextRow()) {
        conditions.push(this.parseConditionFromResultSet(resultSet));
      }

      resultSet.close();
      return conditions;
    } catch (error) {
      Logger.error('DatabaseService', `Failed to get conditions for macro ${macroId}`, error as Error);
      throw new Error(`查询条件失败: ${error.message}`);
    }
  }

  // ==================== 执行日志 CRUD ====================

  /**
   * 插入执行日志
   */
  async insertExecutionLog(log: Omit<ExecutionLog, 'id'>): Promise<number> {
    if (!this.store) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      macro_id: log.macroId,
      trigger_type: log.triggerType,
      status: log.status,
      error_message: log.errorMessage || '',
      executed_at: log.executedAt,
      duration: log.duration
    };

    try {
      const rowId = await this.store.insert('execution_log', valueBucket);
      return rowId as number;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to insert execution log', error as Error);
      throw new Error(`记录日志失败: ${error.message}`);
    }
  }

  /**
   * 查询宏的执行日志（最近 N 条）
   */
  async getExecutionLogsByMacroId(macroId: number, limit: number = 50): Promise<ExecutionLog[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('execution_log');
    predicates.equalTo('macro_id', macroId);
    predicates.orderByDesc('executed_at');
    predicates.limitAs(limit);

    try {
      const resultSet = await this.store.query(predicates);
      const logs: ExecutionLog[] = [];

      while (resultSet.goToNextRow()) {
        logs.push(this.parseExecutionLogFromResultSet(resultSet));
      }

      resultSet.close();
      return logs;
    } catch (error) {
      Logger.error('DatabaseService', `Failed to get execution logs for macro ${macroId}`, error as Error);
      throw new Error(`查询执行日志失败: ${error.message}`);
    }
  }

  /**
   * 查询所有执行日志（最近 N 条）
   */
  async getAllExecutionLogs(limit: number = 100): Promise<ExecutionLog[]> {
    if (!this.store) throw new Error('Database not initialized');

    const predicates = new relationalStore.RdbPredicates('execution_log');
    predicates.orderByDesc('executed_at');
    predicates.limitAs(limit);

    try {
      const resultSet = await this.store.query(predicates);
      const logs: ExecutionLog[] = [];

      while (resultSet.goToNextRow()) {
        logs.push(this.parseExecutionLogFromResultSet(resultSet));
      }

      resultSet.close();
      return logs;
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to get all execution logs', error as Error);
      throw new Error(`查询执行日志失败: ${error.message}`);
    }
  }

  /**
   * 清理旧日志（保留最近 30 天）
   */
  async cleanOldLogs(daysToKeep: number = 30): Promise<void> {
    if (!this.store) throw new Error('Database not initialized');

    const cutoffTime = Date.now() - daysToKeep * 24 * 60 * 60 * 1000;

    const predicates = new relationalStore.RdbPredicates('execution_log');
    predicates.lessThan('executed_at', cutoffTime);

    try {
      const deletedRows = await this.store.delete(predicates);
      Logger.info('DatabaseService', `Cleaned ${deletedRows} old execution logs`);
    } catch (error) {
      Logger.error('DatabaseService', 'Failed to clean old logs', error as Error);
    }
  }

  // ==================== 辅助方法 ====================

  /**
   * 从 ResultSet 解析宏对象
   */
  private parseMacroFromResultSet(resultSet: relationalStore.ResultSet): Macro {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      description: resultSet.getString(resultSet.getColumnIndex('description')) || undefined,
      icon: resultSet.getString(resultSet.getColumnIndex('icon')) || undefined,
      enabled: resultSet.getLong(resultSet.getColumnIndex('enabled')) === 1,
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    };
  }

  /**
   * 从 ResultSet 解析触发器对象
   */
  private parseTriggerFromResultSet(resultSet: relationalStore.ResultSet): Trigger {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      macroId: resultSet.getLong(resultSet.getColumnIndex('macro_id')),
      type: resultSet.getString(resultSet.getColumnIndex('type')) as any,
      config: resultSet.getString(resultSet.getColumnIndex('config')),
      enabled: resultSet.getLong(resultSet.getColumnIndex('enabled')) === 1
    };
  }

  /**
   * 从 ResultSet 解析动作对象
   */
  private parseActionFromResultSet(resultSet: relationalStore.ResultSet): Action {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      macroId: resultSet.getLong(resultSet.getColumnIndex('macro_id')),
      type: resultSet.getString(resultSet.getColumnIndex('type')) as any,
      config: resultSet.getString(resultSet.getColumnIndex('config')),
      orderIndex: resultSet.getLong(resultSet.getColumnIndex('order_index'))
    };
  }

  /**
   * 从 ResultSet 解析条件对象
   */
  private parseConditionFromResultSet(resultSet: relationalStore.ResultSet): Condition {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      macroId: resultSet.getLong(resultSet.getColumnIndex('macro_id')),
      field: resultSet.getString(resultSet.getColumnIndex('field')),
      operator: resultSet.getString(resultSet.getColumnIndex('operator')) as any,
      value: resultSet.getString(resultSet.getColumnIndex('value'))
    };
  }

  /**
   * 从 ResultSet 解析执行日志对象
   */
  private parseExecutionLogFromResultSet(resultSet: relationalStore.ResultSet): ExecutionLog {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      macroId: resultSet.getLong(resultSet.getColumnIndex('macro_id')),
      triggerType: resultSet.getString(resultSet.getColumnIndex('trigger_type')),
      status: resultSet.getString(resultSet.getColumnIndex('status')) as any,
      errorMessage: resultSet.getString(resultSet.getColumnIndex('error_message')) || undefined,
      executedAt: resultSet.getLong(resultSet.getColumnIndex('executed_at')),
      duration: resultSet.getLong(resultSet.getColumnIndex('duration'))
    };
  }
}
