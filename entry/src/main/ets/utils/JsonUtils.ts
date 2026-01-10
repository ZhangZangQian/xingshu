import Logger from './Logger';

/**
 * JSON 工具类
 * 提供 JSONPath 查询、数组操作等高级功能
 */
export class JsonUtils {
  /**
   * 通过路径获取值（支持 JSONPath 语法）
   *
   * 支持的语法：
   * - 字段访问：users.name
   * - 数组索引：items[0]
   * - 混合路径：users[0].name
   * - 通配符：items[*]
   * - 过滤器：items[?age>18]
   */
  static getValueByPath(obj: any, path: string[]): any {
    if (!obj || path.length === 0) return obj;

    let current = obj;

    for (const segment of path) {
      if (current === undefined || current === null) return undefined;

      // 数组索引 [0]
      if (segment.match(/^\[(\d+)\]$/)) {
        const index = parseInt(segment.match(/\d+/)![0]);
        if (Array.isArray(current)) {
          current = current[index];
        } else {
          return undefined;
        }
      }
      // 通配符 [*]
      else if (segment === '*') {
        if (Array.isArray(current)) {
          return current;
        }
        return undefined;
      }
      // 过滤器 [?condition]
      else if (segment.match(/^\[\?.+\]$/)) {
        if (!Array.isArray(current)) return undefined;
        const condition = segment.replace('[?', '').replace(']', '');
        current = current.filter((item: any) =>
          JsonUtils.evaluateCondition(item, condition)
        );
      }
      // 普通字段访问
      else {
        current = current[segment];
      }
    }

    return current;
  }

  /**
   * 通过路径设置值
   */
  static setValueByPath(obj: any, path: string[], value: any): void {
    if (path.length === 0) {
      throw new Error('Path cannot be empty');
    }

    let current = obj;

    // 遍历到倒数第二层
    for (let i = 0; i < path.length - 1; i++) {
      const segment = path[i];

      // 如果路径不存在，创建
      if (!(segment in current)) {
        // 检查下一层是否是数组索引
        const nextIsArrayIndex = path[i + 1].match(/^\[(\d+)\]$/);
        current[segment] = nextIsArrayIndex ? [] : {};
      }

      current = current[segment];

      if (!current || typeof current !== 'object') {
        throw new Error(`Cannot set property on non-object at path: ${path.slice(0, i + 1).join('.')}`);
      }
    }

    // 设置最后一层
    const lastSegment = path[path.length - 1];
    if (lastSegment.match(/^\[(\d+)\]$/)) {
      // 数组索引
      const index = parseInt(lastSegment.match(/\d+/)![0]);
      if (Array.isArray(current)) {
        current[index] = value;
      } else {
        throw new Error('Target is not an array');
      }
    } else {
      // 对象字段
      current[lastSegment] = value;
    }
  }

  /**
   * 数组过滤
   */
  static filterArray(array: any[], filterFn: (item: any) => boolean): any[] {
    if (!Array.isArray(array)) {
      throw new Error('filterArray requires array input');
    }
    return array.filter(filterFn);
  }

  /**
   * 数组映射
   */
  static mapArray(array: any[], mapFn: (item: any) => any): any[] {
    if (!Array.isArray(array)) {
      throw new Error('mapArray requires array input');
    }
    return array.map(mapFn);
  }

  /**
   * 在数组中查找
   */
  static findInArray(array: any[], condition: (item: any) => boolean): any | undefined {
    if (!Array.isArray(array)) {
      throw new Error('findInArray requires array input');
    }
    return array.find(condition);
  }

  /**
   * JSON 合并（浅合并）
   */
  static mergeJSON(target: any, source: any): any {
    if (typeof target !== 'object' || target === null) return source;
    if (typeof source !== 'object' || source === null) return target;

    return {
      ...target,
      ...source
    };
  }

  /**
   * 安全解析 JSON
   */
  static parseJSONSafely(jsonStr: string, defaultValue: any = null): any {
    try {
      return JSON.parse(jsonStr);
    } catch (error) {
      Logger.warn('JsonUtils', `Failed to parse JSON: ${jsonStr.substring(0, 100)}...`);
      return defaultValue;
    }
  }

  /**
   * 评估条件表达式（用于数组过滤）
   * 支持的语法：age>18, name=='John', status==true
   */
  private static evaluateCondition(item: any, condition: string): boolean {
    const operators = ['>=', '<=', '==', '!=', '>', '<'];
    let operator = null;
    let opIndex = -1;

    // 查找运算符
    for (const op of operators) {
      opIndex = condition.indexOf(op);
      if (opIndex > 0) {
        operator = op;
        break;
      }
    }

    if (!operator || opIndex === -1) {
      // 布尔值直接检查
      return item[condition] === true;
    }

    const field = condition.substring(0, opIndex).trim();
    const valueStr = condition.substring(opIndex + operator.length).trim();

    // 解析值
    let value: any = valueStr;
    if (valueStr.startsWith("'") && valueStr.endsWith("'")) {
      value = valueStr.slice(1, -1);
    } else if (valueStr === 'true') {
      value = true;
    } else if (valueStr === 'false') {
      value = false;
    } else if (!isNaN(Number(valueStr))) {
      value = Number(valueStr);
    }

    // 比较
    switch (operator) {
      case '==':
        return item[field] == value;
      case '!=':
        return item[field] != value;
      case '>':
        return item[field] > value;
      case '<':
        return item[field] < value;
      case '>=':
        return item[field] >= value;
      case '<=':
        return item[field] <= value;
      default:
        return false;
    }
  }
}
