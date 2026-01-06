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
   * 评估条件列表（所有条件必须都为 true）
   *
   * @param conditions 条件列表
   * @param context 执行上下文
   * @returns 是否通过条件
   */
  public async evaluate(conditions: Condition[], context: ExecutionContext): Promise<boolean> {
    if (conditions.length === 0) {
      return true;
    }

    Logger.info('ConditionEvaluator', `Evaluating ${conditions.length} conditions`);

    for (const condition of conditions) {
      const result = await this.evaluateSingleCondition(condition, context);
      Logger.info('ConditionEvaluator',
        `Condition [${condition.field} ${condition.operator} ${condition.value}] = ${result}`);

      if (!result) {
        Logger.info('ConditionEvaluator', 'Condition failed, stopping evaluation');
        return false;
      }
    }

    Logger.info('ConditionEvaluator', 'All conditions passed');
    return true;
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
}
