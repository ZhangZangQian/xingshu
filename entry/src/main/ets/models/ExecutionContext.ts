import { TriggerType } from './Macro';
import { ClipboardService } from '../services/ClipboardService';

/**
 * 宏执行上下文实现类
 */
export class ExecutionContextImpl {
  macroId: number;
  triggerType: TriggerType;
  variables: Map<string, Object>;
  startTime: number;

  constructor(macroId: number, triggerType: TriggerType) {
    this.macroId = macroId;
    this.triggerType = triggerType;
    this.variables = new Map<string, Object>();
    this.startTime = Date.now();
  }

  /**
   * 设置变量
   */
  setVariable(name: string, value: Object): void {
    this.variables.set(name, value);
  }

  /**
   * 获取变量
   */
  getVariable(name: string): Object | undefined {
    return this.variables.get(name);
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
