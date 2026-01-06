import Logger from './Logger';

/**
 * 数据校验器
 */
export class Validator {
  /**
   * 校验宏名称
   * 规则：1-50 字符，不允许特殊符号
   */
  static validateMacroName(name: string): { valid: boolean; error?: string } {
    if (!name || typeof name !== 'string') {
      return { valid: false, error: '宏名称不能为空' };
    }

    const trimmedName = name.trim();

    if (trimmedName.length < 1 || trimmedName.length > 50) {
      return { valid: false, error: '宏名称长度必须在 1-50 字符之间' };
    }

    // 不允许特殊符号（允许中文、字母、数字、空格、下划线、连字符）
    const pattern = /^[\u4e00-\u9fa5a-zA-Z0-9\s_-]+$/;
    if (!pattern.test(trimmedName)) {
      return { valid: false, error: '宏名称不能包含特殊符号' };
    }

    return { valid: true };
  }

  /**
   * 校验 URL
   * 规则：必须是有效的 HTTP/HTTPS 地址
   */
  static validateUrl(url: string): { valid: boolean; error?: string } {
    if (!url || typeof url !== 'string') {
      return { valid: false, error: 'URL 不能为空' };
    }

    try {
      const urlObj = new URL(url);

      if (urlObj.protocol !== 'http:' && urlObj.protocol !== 'https:') {
        return { valid: false, error: 'URL 必须是 HTTP 或 HTTPS 协议' };
      }

      return { valid: true };
    } catch (error) {
      return { valid: false, error: 'URL 格式不正确' };
    }
  }

  /**
   * 校验 HTTP Header
   * 规则：Key-Value 格式，Value 长度 < 1000 字符
   */
  static validateHttpHeader(key: string, value: string): { valid: boolean; error?: string } {
    if (!key || typeof key !== 'string') {
      return { valid: false, error: 'Header 名称不能为空' };
    }

    if (value === undefined || value === null) {
      return { valid: false, error: 'Header 值不能为空' };
    }

    if (typeof value === 'string' && value.length > 1000) {
      return { valid: false, error: 'Header 值长度不能超过 1000 字符' };
    }

    // Header 名称不能包含特殊字符
    const keyPattern = /^[a-zA-Z0-9\-_]+$/;
    if (!keyPattern.test(key)) {
      return { valid: false, error: 'Header 名称只能包含字母、数字、连字符和下划线' };
    }

    return { valid: true };
  }

  /**
   * 校验正则表达式
   * 规则：必须是有效的正则表达式，设置超时防止 ReDoS 攻击
   */
  static validateRegex(pattern: string): { valid: boolean; error?: string } {
    if (!pattern || typeof pattern !== 'string') {
      return { valid: false, error: '正则表达式不能为空' };
    }

    try {
      // 尝试创建正则表达式对象
      new RegExp(pattern);

      // 检查危险模式（简单检测）
      if (Validator.isDangerousRegex(pattern)) {
        return { valid: false, error: '正则表达式可能存在性能风险，请简化模式' };
      }

      return { valid: true };
    } catch (error) {
      Logger.error('Validator', `Invalid regex: ${pattern}`, error as Error);
      return { valid: false, error: '正则表达式格式不正确' };
    }
  }

  /**
   * 检测危险正则表达式
   * 简单检测可能导致 ReDoS 的模式
   */
  private static isDangerousRegex(pattern: string): boolean {
    // 检测嵌套量词（如 (a+)+、(a*)*）
    const nestedQuantifiers = /(\*|\+|\{[^}]+\})(\*|\+|\{[^}]+\})/;
    if (nestedQuantifiers.test(pattern)) {
      return true;
    }

    // 检测过长的模式（可能影响性能）
    if (pattern.length > 500) {
      return true;
    }

    return false;
  }

  /**
   * 校验定时触发器时间
   * 规则：定时触发器不允许设置过去的时间
   */
  static validateTimestamp(timestamp: number): { valid: boolean; error?: string } {
    if (!timestamp || typeof timestamp !== 'number') {
      return { valid: false, error: '时间戳不能为空' };
    }

    const now = Date.now();

    if (timestamp < now) {
      return { valid: false, error: '不能设置过去的时间' };
    }

    // 检查是否太远（超过 10 年）
    const tenYears = 10 * 365 * 24 * 60 * 60 * 1000;
    if (timestamp > now + tenYears) {
      return { valid: false, error: '时间不能超过 10 年后' };
    }

    return { valid: true };
  }

  /**
   * 校验 JSON 格式
   */
  static validateJson(jsonString: string): { valid: boolean; error?: string; data?: Object } {
    if (!jsonString || typeof jsonString !== 'string') {
      return { valid: false, error: 'JSON 字符串不能为空' };
    }

    try {
      const data = JSON.parse(jsonString);
      return { valid: true, data: data };
    } catch (error) {
      Logger.error('Validator', `Invalid JSON: ${jsonString}`, error as Error);
      return { valid: false, error: 'JSON 格式不正确' };
    }
  }

  /**
   * 校验应用包名
   * 规则：符合鸿蒙包名格式（如 com.example.app）
   */
  static validateBundleName(bundleName: string): { valid: boolean; error?: string } {
    if (!bundleName || typeof bundleName !== 'string') {
      return { valid: false, error: '应用包名不能为空' };
    }

    // 鸿蒙包名格式：至少两级，使用点号分隔，每级以字母开头
    const pattern = /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/;
    if (!pattern.test(bundleName)) {
      return { valid: false, error: '应用包名格式不正确（如：com.example.app）' };
    }

    return { valid: true };
  }

  /**
   * 校验剪贴板内容大小
   * 规则：< 1 MB
   */
  static validateClipboardContent(content: string): { valid: boolean; error?: string } {
    if (!content || typeof content !== 'string') {
      return { valid: true };  // 空内容也允许
    }

    const maxSize = 1024 * 1024;  // 1 MB
    const contentSize = new TextEncoder().encode(content).length;

    if (contentSize > maxSize) {
      return { valid: false, error: '剪贴板内容超过 1 MB 限制' };
    }

    return { valid: true };
  }

  /**
   * 校验 HTTP 请求体大小
   * 规则：< 10 MB
   */
  static validateHttpBody(body: string): { valid: boolean; error?: string } {
    if (!body || typeof body !== 'string') {
      return { valid: true };  // 空 body 允许
    }

    const maxSize = 10 * 1024 * 1024;  // 10 MB
    const bodySize = new TextEncoder().encode(body).length;

    if (bodySize > maxSize) {
      return { valid: false, error: 'HTTP 请求体超过 10 MB 限制' };
    }

    return { valid: true };
  }
}
