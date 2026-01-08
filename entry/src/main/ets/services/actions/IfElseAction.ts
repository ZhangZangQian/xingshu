import { Action, ActionType, IfElseConfig, Branch, BranchCondition, ConditionOperator, ActionConfig } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import { ConditionEvaluator } from '../ConditionEvaluator';
import { ActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';

const TAG = 'IfElseAction';

/**
 * IF_ELSE 条件分支动作执行器
 *
 * 核心功能：
 * - 支持多分支条件判断（if-else if-else）
 * - 支持 AND/OR 逻辑运算符
 * - 支持嵌套分支（分支内可以再包含 IF_ELSE 动作）
 * - 执行第一个条件满足的分支，然后退出
 *
 * 执行逻辑：
 * 1. 遍历 branches 列表
 * 2. 对每个分支评估 conditions
 * 3. 执行第一个条件满足的分支
 * 4. 如果所有分支都不满足，执行 else 分支（conditions 为空的分支）
 *
 * 配置示例：
 * {
 *   "branches": [
 *     {
 *       "name": "分支1",
 *       "conditions": [
 *         {"field": "{url}", "operator": "contains", "value": "goods"}
 *       ],
 *       "actions": [
 *         {"type": "notification", "config": {"title": "商品分支"}}
 *       ]
 *     },
 *     {
 *       "name": "else分支",
 *       "conditions": [],  // 空条件表示 else
 *       "actions": [...]
 *     }
 *   ]
 * }
 */
export class IfElseAction implements IActionExecutor {
  private conditionEvaluator: ConditionEvaluator;
  private actionExecutor: ActionExecutor;
  private static readonly MAX_DEPTH = 5;  // 最大嵌套深度
  private currentDepth: number = 0;

  constructor() {
    this.conditionEvaluator = ConditionEvaluator.getInstance();
    this.actionExecutor = ActionExecutor.getInstance();
  }

  /**
   * 执行 IF_ELSE 动作
   */
  async execute(action: Action, context: ExecutionContext): Promise<void> {
    // 检查嵌套深度
    this.currentDepth++;
    if (this.currentDepth > IfElseAction.MAX_DEPTH) {
      this.currentDepth--;
      throw new Error(`IF_ELSE nesting depth exceeds maximum (${IfElseAction.MAX_DEPTH})`);
    }

    try {
      const config = JSON.parse(action.config) as IfElseConfig;

      if (!config.branches || config.branches.length === 0) {
        Logger.warn(TAG, 'No branches defined in IF_ELSE action');
        return;
      }

      Logger.info(TAG, `[Depth ${this.currentDepth}] Evaluating ${config.branches.length} branches`);

      // 遍历所有分支
      for (let i = 0; i < config.branches.length; i++) {
        const branch = config.branches[i];
        const branchName = branch.name || `Branch ${i + 1}`;

        // 检查是否为 else 分支（没有条件）
        const isElseBranch = !branch.conditions || branch.conditions.length === 0;

        if (isElseBranch) {
          Logger.info(TAG, `[Depth ${this.currentDepth}] Executing else branch: ${branchName}`);
          await this.executeBranch(branch, context);
          return;  // else 分支执行后退出
        }

        // 评估分支条件
        const conditionsPassed = await this.evaluateBranchConditions(branch.conditions!, context);

        if (conditionsPassed) {
          Logger.info(TAG, `[Depth ${this.currentDepth}] Branch conditions met: ${branchName}`);
          await this.executeBranch(branch, context);
          return;  // 找到匹配分支后退出
        } else {
          Logger.info(TAG, `[Depth ${this.currentDepth}] Branch conditions not met: ${branchName}`);
        }
      }

      // 所有分支都不匹配
      Logger.info(TAG, `[Depth ${this.currentDepth}] No branch conditions matched`);

    } finally {
      this.currentDepth--;
    }
  }

  /**
   * 评估分支条件（支持 AND/OR 逻辑）
   *
   * 逻辑运算符说明：
   * - AND: 所有条件必须都满足
   * - OR: 任一条件满足即可
   *
   * 示例：
   * [
   *   {"field": "{a}", "operator": "==", "value": "1", "logicOperator": "OR"},
   *   {"field": "{b}", "operator": "==", "value": "2"}
   * ]
   * 结果：(a == 1) OR (b == 2)
   */
  private async evaluateBranchConditions(
    conditions: BranchCondition[],
    context: ExecutionContext
  ): Promise<boolean> {
    if (conditions.length === 0) return true;

    // 限制条件数量
    if (conditions.length > 10) {
      Logger.warn(TAG, `Too many conditions (${conditions.length}), limit is 10`);
      throw new Error('Branch conditions count exceeds maximum (10)');
    }

    let result = true;
    let currentLogic: 'AND' | 'OR' = 'AND';

    for (let i = 0; i < conditions.length; i++) {
      const condition = conditions[i];

      // 转换为 Condition 格式供 ConditionEvaluator 使用
      const singleResult = await this.conditionEvaluator.evaluate(
        [{
          id: 0,
          macroId: context.macroId,
          field: condition.field,
          operator: condition.operator,
          value: condition.value
        }],
        context
      );

      // 根据逻辑运算符合并结果
      if (i === 0) {
        result = singleResult;
      } else {
        if (currentLogic === 'AND') {
          result = result && singleResult;
        } else {
          result = result || singleResult;
        }
      }

      // 设置下一个条件的逻辑运算符
      currentLogic = condition.logicOperator || 'AND';

      Logger.info(TAG,
        `  Condition [${condition.field} ${condition.operator} ${condition.value}] = ${singleResult}, combined = ${result}`
      );

      // 短路优化
      if (currentLogic === 'AND' && !result) {
        Logger.info(TAG, '  Short-circuit: AND logic failed, skipping remaining conditions');
        break;
      }
      if (currentLogic === 'OR' && result) {
        Logger.info(TAG, '  Short-circuit: OR logic succeeded, skipping remaining conditions');
        break;
      }
    }

    return result;
  }

  /**
   * 执行分支内的动作列表
   */
  private async executeBranch(branch: Branch, context: ExecutionContext): Promise<void> {
    if (!branch.actions || branch.actions.length === 0) {
      Logger.warn(TAG, 'Branch has no actions');
      return;
    }

    Logger.info(TAG, `Executing ${branch.actions.length} actions in branch`);

    for (let i = 0; i < branch.actions.length; i++) {
      const actionConfig = branch.actions[i];

      // 构造 Action 对象（临时的，不存入数据库）
      const action: Action = {
        id: -1,  // 临时ID，表示这是嵌套动作
        macroId: context.macroId,
        type: actionConfig.type,
        config: JSON.stringify(actionConfig.config),
        orderIndex: i
      };

      try {
        Logger.info(TAG, `  Executing branch action ${i + 1}/${branch.actions.length}: ${actionConfig.type}`);
        await this.actionExecutor.execute(action, context);
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Branch action ${actionConfig.type} failed: ${errorMessage}`);

        // 分支内动作失败时，停止执行后续动作并向上传播错误
        throw new Error(`Branch action failed: ${errorMessage}`);
      }
    }

    Logger.info(TAG, 'Branch execution completed successfully');
  }
}
