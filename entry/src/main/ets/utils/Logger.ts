/**
 * 日志工具类
 * 提供统一的日志记录功能
 */
export class Logger {
  private static readonly TAG_PREFIX = '[HarmonyMacro]';
  private static enableDebug: boolean = true;  // 开发阶段启用调试日志

  /**
   * 信息日志
   */
  static info(tag: string, message: string): void {
    console.info(`${Logger.TAG_PREFIX}[${tag}] ${message}`);
  }

  /**
   * 警告日志
   */
  static warn(tag: string, message: string): void {
    console.warn(`${Logger.TAG_PREFIX}[${tag}] ${message}`);
  }

  /**
   * 错误日志
   */
  static error(tag: string, message: string, error?: Error): void {
    if (error) {
      console.error(`${Logger.TAG_PREFIX}[${tag}] ${message}`, error);
    } else {
      console.error(`${Logger.TAG_PREFIX}[${tag}] ${message}`);
    }
  }

  /**
   * 调试日志（仅在 enableDebug 为 true 时输出）
   */
  static debug(tag: string, message: string): void {
    if (Logger.enableDebug) {
      console.debug(`${Logger.TAG_PREFIX}[${tag}] ${message}`);
    }
  }

  /**
   * 设置是否启用调试日志
   */
  static setDebugEnabled(enabled: boolean): void {
    Logger.enableDebug = enabled;
  }

  /**
   * 记录性能指标
   */
  static performance(tag: string, operation: string, duration: number): void {
    console.info(`${Logger.TAG_PREFIX}[Performance][${tag}] ${operation} took ${duration}ms`);
  }
}

export default Logger;
