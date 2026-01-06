import { ExecutionContextImpl } from '../models/ExecutionContext';
import Logger from './Logger';

/**
 * 变量解析器
 * 解析字符串中的变量占位符（如 {varName}、{date}、{action_1.result}）
 */
export class VariableParser {
  private static readonly VARIABLE_PATTERN = /\{([^}]+)\}/g;
  private static readonly MAX_PARSE_DEPTH = 10;  // 防止无限递归

  /**
   * 解析字符串中的所有变量
   *
   * @param input 输入字符串
   * @param context 执行上下文
   * @returns 解析后的字符串
   */
  static async parse(input: string, context: ExecutionContextImpl): Promise<string> {
    if (!input || typeof input !== 'string') {
      return input;
    }

    let result = input;
    let depth = 0;

    // 递归解析，支持嵌套变量
    while (VariableParser.VARIABLE_PATTERN.test(result) && depth < VariableParser.MAX_PARSE_DEPTH) {
      const previousResult = result;
      result = await VariableParser.replaceVariables(result, context);

      // 如果没有变化，说明无法解析，退出循环
      if (result === previousResult) {
        break;
      }

      depth++;
    }

    if (depth >= VariableParser.MAX_PARSE_DEPTH) {
      Logger.warn('VariableParser', `Max parse depth reached for input: ${input}`);
    }

    return result;
  }

  /**
   * 替换一轮变量
   */
  private static async replaceVariables(input: string, context: ExecutionContextImpl): Promise<string> {
    const matches = input.matchAll(VariableParser.VARIABLE_PATTERN);
    let result = input;

    for (const match of matches) {
      const placeholder = match[0];  // 如 {varName}
      const variablePath = match[1]; // 如 varName 或 action_1.result

      const value = await VariableParser.resolveVariable(variablePath, context);

      if (value !== undefined && value !== null) {
        result = result.replace(placeholder, String(value));
      } else {
        Logger.warn('VariableParser', `Variable not found: ${variablePath}`);
      }
    }

    return result;
  }

  /**
   * 解析变量路径
   * 支持：
   * - 简单变量：varName
   * - 系统变量：date, time, timestamp, clipboard 等
   * - 嵌套属性：action_1.result.code
   */
  private static async resolveVariable(path: string, context: ExecutionContextImpl): Promise<Object | undefined> {
    const parts = path.split('.');
    const rootVariable = parts[0];

    // 1. 尝试从系统变量获取
    let value: Object | undefined = await context.getSystemVariable(rootVariable);

    // 2. 如果不是系统变量，从上下文变量获取
    if (value === undefined) {
      value = context.getVariable(rootVariable);
    }

    // 3. 如果有嵌套属性，继续解析
    if (value !== undefined && parts.length > 1) {
      value = VariableParser.resolveNestedProperty(value, parts.slice(1));
    }

    return value;
  }

  /**
   * 解析嵌套属性
   * 例如：action_1.result.code
   */
  private static resolveNestedProperty(obj: Object, path: string[]): Object | undefined {
    let current: Object | undefined = obj;

    for (const key of path) {
      if (current === undefined || current === null) {
        return undefined;
      }

      if (typeof current === 'object' && key in current) {
        current = current[key];
      } else {
        return undefined;
      }
    }

    return current;
  }

  /**
   * 提取字符串中的所有变量名
   */
  static extractVariables(input: string): string[] {
    if (!input || typeof input !== 'string') {
      return [];
    }

    const variables: string[] = [];
    const matches = input.matchAll(VariableParser.VARIABLE_PATTERN);

    for (const match of matches) {
      variables.push(match[1]);
    }

    return variables;
  }

  /**
   * 验证变量名是否合法
   * 合法格式：字母开头，可包含字母、数字、下划线、点号
   */
  static isValidVariableName(name: string): boolean {
    if (!name || typeof name !== 'string') {
      return false;
    }

    const pattern = /^[a-zA-Z][a-zA-Z0-9_\.]*$/;
    return pattern.test(name);
  }
}
