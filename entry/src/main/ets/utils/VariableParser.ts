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
    console.log(`[VariableParser] parse START`);
    console.log(`[VariableParser] Input: ${input}`);
    if (!input || typeof input !== 'string') {
      console.log(`[VariableParser] parse early return: input is empty or not string`);
      return input;
    }

    let result = input;
    let depth = 0;
    console.log(`[VariableParser] Starting parse loop, initial result: ${result}`);

    // 递归解析，支持嵌套变量
    while (depth < VariableParser.MAX_PARSE_DEPTH) {
      console.log(`[VariableParser] === Parse depth ${depth + 1} ===`);

      // 测试是否还有变量占位符
      const hasVariables = VariableParser.VARIABLE_PATTERN.test(result);
      console.log(`[VariableParser] test() result: ${hasVariables}`);
      console.log(`[VariableParser] Current result: ${result}`);

      if (!hasVariables) {
        console.log(`[VariableParser] No more variables, breaking loop`);
        break;
      }

      const previousResult = result;
      result = await VariableParser.replaceVariables(result, context);

      // 如果没有变化，说明无法解析，退出循环
      if (result === previousResult) {
        console.log(`[VariableParser] Result unchanged, breaking loop`);
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
    console.log(`[VariableParser] replaceVariables START`);
    console.log(`[VariableParser] Input: ${input}`);

    // 先找出所有需要替换的占位符
    const replacements: Array<{ placeholder: string, value: string }> = [];
    const regex = /\{([^}]+)\}/g;
    let match: RegExpExecArray | null;

    while ((match = regex.exec(input)) !== null) {
      const placeholder = match[0];
      const variablePath = match[1];

      console.log(`[VariableParser] Matched: ${placeholder} -> ${variablePath}`);
      const value = await VariableParser.resolveVariable(variablePath, context);
      console.log(`[VariableParser] Resolved value: ${value}`);

      if (value !== undefined && value !== null) {
        replacements.push({
          placeholder: placeholder,
          value: String(value)
        });
      } else {
        Logger.warn('VariableParser', `Variable not found: ${variablePath}`);
      }
    }

    // 执行替换（使用正则表达式全局替换，支持同一变量多次出现）
    let result = input;
    for (const repl of replacements) {
      const beforeReplace = result;
      // 使用正则表达式全局替换所有匹配项，先转义正则特殊字符
      const escapedPlaceholder = repl.placeholder.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const globalReplaceRegex = new RegExp(escapedPlaceholder, 'g');
      result = result.replace(globalReplaceRegex, repl.value);
      console.log(`[VariableParser] Replaced: ${beforeReplace} -> ${result}`);
    }

    console.log(`[VariableParser] Result: ${result}`);
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
      value = await context.getVariable(rootVariable);
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
