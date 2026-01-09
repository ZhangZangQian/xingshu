import { TriggerType } from './Macro';
import { Variable, VariableScope } from './Variable';
import { ClipboardService } from '../services/ClipboardService';
import { DatabaseService } from '../services/DatabaseService';

/**
 * 宏执行上下文实现类
 */
export class ExecutionContextImpl {
  macroId: number;
  triggerType: TriggerType;
  variables: Map<string, Object>;
  globalVariables: Map<string, Object>;
  startTime: number;

  constructor(macroId: number, triggerType: TriggerType) {
    this.macroId = macroId;
    this.triggerType = triggerType;
    this.variables = new Map<string, Object>();
    this.globalVariables = new Map<string, Object>();
    this.startTime = Date.now();
  }

  /**
   * 加载变量到上下文
   */
  async loadVariables(): Promise<void> {
    const databaseService = DatabaseService.getInstance();

    // 加载全局变量
    const globalVars = await databaseService.getGlobalVariables();
    for (const v of globalVars) {
      this.globalVariables.set(v.name, v.value);
    }

    // 宏变量已移除，通过"设置变量"动作在运行时创建
  }

  /**
   * 设置变量
   */
  setVariable(name: string, value: Object): void {
    this.variables.set(name, value);
  }

  /**
   * 获取变量 (三级解析: system → runtime → global)
   */
  async getVariable(name: string): Promise<Object | undefined> {
    // 1. 先查找系统变量
    const systemValue = await this.getSystemVariable(name);
    if (systemValue !== undefined) {
      return systemValue;
    }

    // 2. 再查找运行期变量
    if (this.variables.has(name)) {
      return this.variables.get(name);
    }

    // 3. 最后查找全局变量
    if (this.globalVariables.has(name)) {
      return this.globalVariables.get(name);
    }

    return undefined;
  }

  /**
   * 获取系统变量
   */
  async getSystemVariable(name: string): Promise<Object | undefined> {
    const now = new Date();

    switch (name) {
      case 'date':
        return this.formatDate(now);
      case 'time':
        return this.formatTime(now);
      case 'timestamp':
        return Date.now();
      case 'clipboard':
        try {
          const clipboardService = ClipboardService.getInstance();
          return await clipboardService.readText();
        } catch (error) {
          console.error('[ExecutionContext] Failed to read clipboard:', error);
          return '';
        }
      case 'network_type':
        // TODO: 实现网络类型获取
        return 'unknown';
      case 'battery_level':
        // TODO: 实现电量获取
        return 100;
      default:
        return undefined;
    }
  }

  /**
   * 格式化日期为 YYYY-MM-DD
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化时间为 HH:mm:ss
   */
  private formatTime(date: Date): string {
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }
}

// 导出类型别名以兼容其他文件
export type ExecutionContext = ExecutionContextImpl;
