/**
 * 日期时间辅助工具类
 */
export class DateTimeHelper {
  /**
   * 格式化时间戳为可读字符串
   * @param timestamp 时间戳（毫秒）
   * @param format 格式（'YYYY-MM-DD HH:mm:ss' 或 'YYYY-MM-DD' 或 'HH:mm:ss'）
   */
  static formatTimestamp(timestamp: number, format: string = 'YYYY-MM-DD HH:mm:ss'): string {
    const date = new Date(timestamp);

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');

    switch (format) {
      case 'YYYY-MM-DD HH:mm:ss':
        return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
      case 'YYYY-MM-DD':
        return `${year}-${month}-${day}`;
      case 'HH:mm:ss':
        return `${hours}:${minutes}:${seconds}`;
      default:
        return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    }
  }

  /**
   * 格式化时长（毫秒）为可读字符串
   * @param duration 时长（毫秒）
   */
  static formatDuration(duration: number): string {
    if (duration < 1000) {
      return `${duration}ms`;
    }

    const seconds = Math.floor(duration / 1000);
    const ms = duration % 1000;

    if (seconds < 60) {
      return `${seconds}.${String(ms).padStart(3, '0').substring(0, 2)}s`;
    }

    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;

    if (minutes < 60) {
      return `${minutes}m ${remainingSeconds}s`;
    }

    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;

    return `${hours}h ${remainingMinutes}m`;
  }

  /**
   * 计算相对时间（如"3 分钟前"）
   */
  static getRelativeTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;

    if (diff < 0) {
      return '未来';
    }

    const seconds = Math.floor(diff / 1000);
    if (seconds < 60) {
      return '刚刚';
    }

    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) {
      return `${minutes} 分钟前`;
    }

    const hours = Math.floor(minutes / 60);
    if (hours < 24) {
      return `${hours} 小时前`;
    }

    const days = Math.floor(hours / 24);
    if (days < 7) {
      return `${days} 天前`;
    }

    const weeks = Math.floor(days / 7);
    if (weeks < 4) {
      return `${weeks} 周前`;
    }

    const months = Math.floor(days / 30);
    if (months < 12) {
      return `${months} 个月前`;
    }

    const years = Math.floor(days / 365);
    return `${years} 年前`;
  }

  /**
   * 解析时间字符串为时间戳
   * @param timeString 时间字符串（如 "14:30:00"）
   */
  static parseTime(timeString: string): { hour: number; minute: number; second: number } | null {
    const parts = timeString.split(':');
    if (parts.length !== 3) {
      return null;
    }

    const hour = parseInt(parts[0]);
    const minute = parseInt(parts[1]);
    const second = parseInt(parts[2]);

    if (isNaN(hour) || isNaN(minute) || isNaN(second)) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) {
      return null;
    }

    return { hour, minute, second };
  }

  /**
   * 获取下一个执行时间（每日重复）
   * @param hour 小时（0-23）
   * @param minute 分钟（0-59）
   * @param second 秒（0-59）
   */
  static getNextDailyTime(hour: number, minute: number, second: number): number {
    const now = new Date();
    const target = new Date();

    target.setHours(hour);
    target.setMinutes(minute);
    target.setSeconds(second);
    target.setMilliseconds(0);

    // 如果目标时间已过，设置为明天
    if (target.getTime() <= now.getTime()) {
      target.setDate(target.getDate() + 1);
    }

    return target.getTime();
  }

  /**
   * 获取下一个执行时间（每周重复）
   * @param weekdays 星期几数组（0=周日，1=周一...6=周六）
   * @param hour 小时
   * @param minute 分钟
   * @param second 秒
   */
  static getNextWeeklyTime(weekdays: number[], hour: number, minute: number, second: number): number {
    const now = new Date();
    let target = new Date();

    target.setHours(hour);
    target.setMinutes(minute);
    target.setSeconds(second);
    target.setMilliseconds(0);

    // 查找下一个符合条件的日期
    for (let i = 0; i < 7; i++) {
      const currentWeekday = target.getDay();

      if (weekdays.includes(currentWeekday) && target.getTime() > now.getTime()) {
        return target.getTime();
      }

      target.setDate(target.getDate() + 1);
    }

    // 如果 7 天内没有找到，返回第一个匹配的星期
    target = new Date();
    target.setHours(hour);
    target.setMinutes(minute);
    target.setSeconds(second);
    target.setMilliseconds(0);

    for (let i = 0; i < 7; i++) {
      target.setDate(target.getDate() + 1);
      if (weekdays.includes(target.getDay())) {
        return target.getTime();
      }
    }

    return target.getTime();
  }
}
