import { Macro, Trigger, Action, Condition, TriggerType } from '../models/Macro';
import { ExecutionContextImpl } from '../models/ExecutionContext';
import { TriggerManager } from './TriggerManager';
import { ActionExecutor } from './ActionExecutor';
import { ConditionEvaluator } from './ConditionEvaluator';
import { DatabaseService } from './DatabaseService';
import { NotificationService } from './NotificationService';
import Logger from '../utils/Logger';

/**
 * 宏执行引擎
 * 核心职责：调度宏的执行流程
 */
export class MacroEngine {
  private static instance: MacroEngine;
  private triggerManager: TriggerManager | null = null;
  private actionExecutor: ActionExecutor | null = null;
  private conditionEvaluator: ConditionEvaluator | null = null;
  private databaseService: DatabaseService | null = null;
  private notificationService: NotificationService | null = null;
  private initialized: boolean = false;

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): MacroEngine {
    if (!MacroEngine.instance) {
      MacroEngine.instance = new MacroEngine();
    }
    return MacroEngine.instance;
  }

  /**
   * 初始化引擎（应用启动时调用）
   * 注册所有已启用宏的触发器
   */
  public async initialize(context: Context): Promise<void> {
    if (this.initialized) {
      Logger.info('MacroEngine', 'Already initialized');
      return;
    }

    Logger.info('MacroEngine', 'Initializing...');

    try {
      // 1. 初始化依赖服务
      this.databaseService = DatabaseService.getInstance();
      await this.databaseService.initialize(context);

      this.triggerManager = TriggerManager.getInstance();
      this.actionExecutor = ActionExecutor.getInstance();
      this.conditionEvaluator = ConditionEvaluator.getInstance();
      this.notificationService = NotificationService.getInstance();

      // 2. 加载所有已启用的宏
      const enabledMacros = await this.databaseService.getEnabledMacros();

      // 3. 注册触发器
      for (const macro of enabledMacros) {
        await this.registerMacroTriggers(macro);
      }

      this.initialized = true;
      Logger.info('MacroEngine', `Initialized with ${enabledMacros.length} enabled macros`);
    } catch (error) {
      Logger.error('MacroEngine', 'Failed to initialize', error as Error);
      throw new Error(`宏引擎初始化失败: ${error.message}`);
    }
  }

  /**
   * 注册宏的所有触发器
   */
  private async registerMacroTriggers(macro: Macro): Promise<void> {
    if (!this.databaseService || !this.triggerManager) {
      throw new Error('MacroEngine not initialized');
    }

    const triggers = await this.databaseService.getTriggersByMacroId(macro.id);

    for (const trigger of triggers) {
      if (trigger.enabled) {
        await this.triggerManager.registerTrigger(trigger, macro.id, this.executeMacro.bind(this));
      }
    }
  }

  /**
   * 执行宏（由触发器回调调用）
   *
   * @param macroId 宏 ID
   * @param triggerType 触发类型
   * @returns 执行结果
   */
  public async executeMacro(macroId: number, triggerType: string): Promise<boolean> {
    if (!this.initialized || !this.databaseService || !this.actionExecutor ||
      !this.conditionEvaluator || !this.notificationService) {
      Logger.error('MacroEngine', 'Engine not initialized');
      return false;
    }

    const startTime = Date.now();
    Logger.info('MacroEngine', `Executing macro ${macroId}, triggered by ${triggerType}`);

    try {
      // 1. 加载宏配置
      const macro = await this.databaseService.getMacroById(macroId);
      if (!macro || !macro.enabled) {
        Logger.warn('MacroEngine', `Macro ${macroId} not found or disabled`);
        return false;
      }

      // 2. 创建执行上下文
      const context = new ExecutionContextImpl(macroId, triggerType as TriggerType);

      // 3. 检查条件
      const conditions = await this.databaseService.getConditionsByMacroId(macroId);
      if (conditions.length > 0) {
        const conditionsPassed = await this.conditionEvaluator.evaluate(conditions, context);
        if (!conditionsPassed) {
          Logger.info('MacroEngine', `Macro ${macroId} conditions not met, skipping execution`);
          await this.logExecution(macroId, triggerType, 'failed', 'Conditions not met', Date.now() - startTime);
          return false;
        }
      }

      // 4. 加载动作列表（按 order_index 排序）
      const actions = await this.databaseService.getActionsByMacroId(macroId);

      if (actions.length === 0) {
        Logger.warn('MacroEngine', `Macro ${macroId} has no actions`);
        return false;
      }

      // 5. 依次执行动作
      for (let i = 0; i < actions.length; i++) {
        const action = actions[i];
        Logger.info('MacroEngine', `Executing action ${i + 1}/${actions.length}: ${action.type}`);

        try {
          await this.actionExecutor.execute(action, context);
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          Logger.error('MacroEngine', `Action ${action.type} failed: ${errorMessage}`);

          // 记录部分失败
          await this.logExecution(macroId, triggerType, 'partial', `Action ${action.type} failed: ${errorMessage}`,
            Date.now() - startTime);

          // 发送错误通知
          await this.notificationService.sendErrorNotification(macro.name, `动作 ${action.type} 执行失败`);

          // 停止执行后续动作
          return false;
        }
      }

      // 6. 记录成功日志
      await this.logExecution(macroId, triggerType, 'success', '', Date.now() - startTime);

      // 7. 可选：发送成功通知（根据用户设置）
      // await this.notificationService.sendSuccessNotification(macro.name);

      Logger.info('MacroEngine', `Macro ${macroId} executed successfully in ${Date.now() - startTime}ms`);
      return true;

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('MacroEngine', `Macro ${macroId} execution failed: ${errorMessage}`);
      await this.logExecution(macroId, triggerType, 'failed', errorMessage, Date.now() - startTime);
      return false;
    }
  }

  /**
   * 记录执行日志
   */
  private async logExecution(
    macroId: number,
    triggerType: string,
    status: 'success' | 'failed' | 'partial',
    errorMessage: string,
    duration: number
  ): Promise<void> {
    if (!this.databaseService) return;

    try {
      await this.databaseService.insertExecutionLog({
        macroId: macroId,
        triggerType: triggerType,
        status: status,
        errorMessage: errorMessage || undefined,
        executedAt: Date.now(),
        duration: duration
      });
    } catch (error) {
      Logger.error('MacroEngine', 'Failed to log execution', error as Error);
    }
  }

  /**
   * 手动触发宏执行（用于测试或手动触发器）
   */
  public async manualTrigger(macroId: number): Promise<boolean> {
    return await this.executeMacro(macroId, 'manual');
  }

  /**
   * 启用宏（注册触发器）
   */
  public async enableMacro(macroId: number): Promise<void> {
    if (!this.databaseService || !this.triggerManager) {
      throw new Error('MacroEngine not initialized');
    }

    await this.databaseService.updateMacroEnabled(macroId, true);
    const macro = await this.databaseService.getMacroById(macroId);
    if (macro) {
      await this.registerMacroTriggers(macro);
    }

    Logger.info('MacroEngine', `Macro ${macroId} enabled`);
  }

  /**
   * 禁用宏（取消注册触发器）
   */
  public async disableMacro(macroId: number): Promise<void> {
    if (!this.databaseService || !this.triggerManager) {
      throw new Error('MacroEngine not initialized');
    }

    await this.databaseService.updateMacroEnabled(macroId, false);
    await this.triggerManager.unregisterMacroTriggers(macroId);

    Logger.info('MacroEngine', `Macro ${macroId} disabled`);
  }
}
