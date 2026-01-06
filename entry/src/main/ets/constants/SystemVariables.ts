/**
 * 系统变量常量
 */
export class SystemVariables {
  static readonly DATE = 'date';
  static readonly TIME = 'time';
  static readonly TIMESTAMP = 'timestamp';
  static readonly CLIPBOARD = 'clipboard';
  static readonly NETWORK_TYPE = 'network_type';
  static readonly BATTERY_LEVEL = 'battery_level';

  /**
   * 获取所有系统变量
   */
  static getAll(): string[] {
    return [
      SystemVariables.DATE,
      SystemVariables.TIME,
      SystemVariables.TIMESTAMP,
      SystemVariables.CLIPBOARD,
      SystemVariables.NETWORK_TYPE,
      SystemVariables.BATTERY_LEVEL
    ];
  }

  /**
   * 获取系统变量显示名称
   */
  static getDisplayName(variable: string): string {
    switch (variable) {
      case SystemVariables.DATE:
        return '当前日期（YYYY-MM-DD）';
      case SystemVariables.TIME:
        return '当前时间（HH:mm:ss）';
      case SystemVariables.TIMESTAMP:
        return '当前时间戳';
      case SystemVariables.CLIPBOARD:
        return '剪贴板内容';
      case SystemVariables.NETWORK_TYPE:
        return '当前网络类型';
      case SystemVariables.BATTERY_LEVEL:
        return '当前电量百分比';
      default:
        return '未知变量';
    }
  }

  /**
   * 获取系统变量描述
   */
  static getDescription(variable: string): string {
    switch (variable) {
      case SystemVariables.DATE:
        return '获取当前日期，格式：2026-01-06';
      case SystemVariables.TIME:
        return '获取当前时间，格式：14:30:00';
      case SystemVariables.TIMESTAMP:
        return '获取当前时间戳（毫秒）';
      case SystemVariables.CLIPBOARD:
        return '读取系统剪贴板的文本内容';
      case SystemVariables.NETWORK_TYPE:
        return '获取当前网络类型（wifi/mobile/unknown）';
      case SystemVariables.BATTERY_LEVEL:
        return '获取当前电池电量（0-100）';
      default:
        return '';
    }
  }
}
