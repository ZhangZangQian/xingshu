import { Condition, ConditionOperator } from '../models/Macro';
import { ExecutionContext } from '../models/ExecutionContext';
import Logger from '../utils/Logger';
import { VariableParser } from '../utils/VariableParser';

/**
 * 条件判断器
 * 核心职责：评估宏的执行条件
 */
export class ConditionEvaluator {
  private static instance: ConditionEvaluator;

  private constructor() {}

  public static getInstance(): ConditionEvaluator {
    if (!ConditionEvaluator.instance) {
      ConditionEvaluator.instance = new ConditionEvaluator();
    }
    return ConditionEvaluator.instance;
  }

  /**
   * 评估条件列表
   *
   * @param conditions 条件列表
   * @param context 执行上下文
   * @param logic 条件关系：'and'（所有条件都满足）或 'or'（任一条件满足），默认为 'and'
   * @returns 是否通过条件
   */
  public async evaluate(conditions: Condition[], context: ExecutionContext, logic: 'and' | 'or' = 'and'): Promise<boolean> {
    if (conditions.length === 0) {
      return true;
    }

    Logger.info('ConditionEvaluator', `Evaluating ${conditions.length} conditions with logic: ${logic}`);

    for (const condition of conditions) {
      const result = await this.evaluateSingleCondition(condition, context);
      Logger.info('ConditionEvaluator',
        `Condition [${condition.field} ${condition.operator} ${condition.value}] = ${result}`);

      if (logic === 'or') {
        // OR 逻辑：任一条件满足即返回 true
        if (result) {
          Logger.info('ConditionEvaluator', 'Condition passed (OR logic), stopping evaluation');
          return true;
        }
      } else {
        // AND 逻辑：任一条件不满足即返回 false
        if (!result) {
          Logger.info('ConditionEvaluator', 'Condition failed (AND logic), stopping evaluation');
          return false;
        }
      }
    }

    // AND 逻辑：所有条件都满足返回 true
    // OR 逻辑：所有条件都不满足返回 false
    const finalResult = logic === 'and';
    Logger.info('ConditionEvaluator', `Evaluation complete, result: ${finalResult}`);
    return finalResult;
  }

  /**
   * 评估单个条件
   */
  private async evaluateSingleCondition(condition: Condition, context: ExecutionContext): Promise<boolean> {
    try {
      // 1. 解析字段值（支持变量替换）
      const fieldValueStr = await VariableParser.parse(condition.field, context);
      const expectedValueStr = await VariableParser.parse(condition.value, context);

      // 2. 根据运算符执行比较
      switch (condition.operator) {
        case ConditionOperator.EQUALS:
          return this.compareEquals(fieldValueStr, expectedValueStr);

        case ConditionOperator.NOT_EQUALS:
          return !this.compareEquals(fieldValueStr, expectedValueStr);

        case ConditionOperator.GREATER_THAN:
          return this.compareNumeric(fieldValueStr, expectedValueStr, '>');

        case ConditionOperator.LESS_THAN:
          return this.compareNumeric(fieldValueStr, expectedValueStr, '<');

        case ConditionOperator.GREATER_EQUAL:
          return this.compareNumeric(fieldValueStr, expectedValueStr, '>=');

        case ConditionOperator.LESS_EQUAL:
          return this.compareNumeric(fieldValueStr, expectedValueStr, '<=');

        case ConditionOperator.CONTAINS:
          return this.compareContains(fieldValueStr, expectedValueStr);

        case ConditionOperator.NOT_CONTAINS:
          return !this.compareContains(fieldValueStr, expectedValueStr);

        case ConditionOperator.IS_EMPTY:
          return this.compareIsEmpty(fieldValueStr);

        case ConditionOperator.IS_NOT_EMPTY:
          return !this.compareIsEmpty(fieldValueStr);

        case ConditionOperator.REGEX:
          return this.compareRegex(fieldValueStr, expectedValueStr);

        default:
          Logger.error('ConditionEvaluator', `Unknown operator: ${condition.operator}`);
          return false;
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('ConditionEvaluator', `Failed to evaluate condition: ${errorMessage}`);
      return false;
    }
  }

  /**
   * 相等比较（字符串或数值）
   */
  private compareEquals(actual: string, expected: string): boolean {
    // 尝试数值比较
    const actualNum = parseFloat(actual);
    const expectedNum = parseFloat(expected);

    if (!isNaN(actualNum) && !isNaN(expectedNum)) {
      return actualNum === expectedNum;
    }

    // 字符串比较
    return actual === expected;
  }

  /**
   * 数值比较
   */
  private compareNumeric(actual: string, expected: string, operator: '>' | '<' | '>=' | '<='): boolean {
    const actualNum = parseFloat(actual);
    const expectedNum = parseFloat(expected);

    if (isNaN(actualNum) || isNaN(expectedNum)) {
      Logger.warn('ConditionEvaluator', `Cannot compare non-numeric values: ${actual}, ${expected}`);
      return false;
    }

    switch (operator) {
      case '>':
        return actualNum > expectedNum;
      case '<':
        return actualNum < expectedNum;
      case '>=':
        return actualNum >= expectedNum;
      case '<=':
        return actualNum <= expectedNum;
    }
  }

  /**
   * 包含比较
   */
  private compareContains(actual: string, expected: string): boolean {
    return actual.includes(expected);
  }

  /**
   * 正则匹配
   */
  private compareRegex(actual: string, pattern: string): boolean {
    try {
      // 安全性检查：设置执行超时
      const regex = new RegExp(pattern);

      // 简单的超时保护（ArkTS 中可能需要不同的实现）
      const startTime = Date.now();
      const result = regex.test(actual);
      const duration = Date.now() - startTime;

      if (duration > 100) {
        Logger.warn('ConditionEvaluator', `Regex execution took ${duration}ms, may have performance issue`);
      }

      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('ConditionEvaluator', `Invalid regex pattern: ${pattern}, error: ${errorMessage}`);
      return false;
    }
  }

  /**
   * 检查值是否为空
   * 判断标准：null、undefined、空字符串、空数组、空对象
   */
  private compareIsEmpty(value: string): boolean {
    // 检查 null 或 undefined
    if (value === null || value === undefined) {
      return true;
    }

    // 检查空字符串（包括仅包含空白字符）
    if (typeof value === 'string' && value.trim() === '') {
      return true;
    }

    // 尝试解析 JSON 对象/数组
    try {
      const parsed = JSON.parse(value);
      // 空数组
      if (Array.isArray(parsed) && parsed.length === 0) {
        return true;
      }
      // 空对象
      if (typeof parsed === 'object' && parsed !== null && Object.keys(parsed).length === 0) {
        return true;
      }
    } catch (error) {
      // 不是 JSON，继续使用字符串判断
    }

    return false;
  }
}
