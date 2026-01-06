/**
 * 触发器类型常量
 */
export class TriggerTypes {
  static readonly TIME = 'time';
  static readonly NETWORK = 'network';
  static readonly MANUAL = 'manual';
  static readonly CLIPBOARD = 'clipboard';

  /**
   * 获取所有触发器类型
   */
  static getAll(): string[] {
    return [
      TriggerTypes.TIME,
      TriggerTypes.NETWORK,
      TriggerTypes.MANUAL,
      TriggerTypes.CLIPBOARD
    ];
  }

  /**
   * 获取触发器类型显示名称
   */
  static getDisplayName(type: string): string {
    switch (type) {
      case TriggerTypes.TIME:
        return '定时触发';
      case TriggerTypes.NETWORK:
        return '网络状态触发';
      case TriggerTypes.MANUAL:
        return '手动触发';
      case TriggerTypes.CLIPBOARD:
        return '剪贴板触发';
      default:
        return '未知类型';
    }
  }
}
