import { Action, ActionType, ActionExecutionResult } from '../models/Macro';
import { ExecutionContext } from '../models/ExecutionContext';
import { DatabaseService } from './DatabaseService';
import Logger from '../utils/Logger';

/**
 * 动作执行器基类
 */
export interface IActionExecutor {
  /**
   * 执行动作
   * @param action 动作配置
   * @param context 执行上下文
   * @returns 执行结果
   */
  execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult>;
}

/**
 * 动作执行器（策略模式）
 * 核心职责：根据动作类型分发到具体执行器
 */
export class ActionExecutor {
  private static instance: ActionExecutor;
  private executors: Map<ActionType, IActionExecutor>;
  private executionLogId: number | null = null;

  private constructor() {
    this.executors = new Map();
  }

  public static getInstance(): ActionExecutor {
    if (!ActionExecutor.instance) {
      ActionExecutor.instance = new ActionExecutor();
    }
    return ActionExecutor.instance;
  }

  /**
   * 设置当前执行日志 ID（由 MacroEngine 设置）
   */
  public setExecutionLogId(executionLogId: number): void {
    this.executionLogId = executionLogId;
    Logger.info('ActionExecutor', `Set execution log ID: ${executionLogId}`);
  }

  /**
   * 清除当前执行日志 ID
   */
  public clearExecutionLogId(): void {
    this.executionLogId = null;
  }

  /**
   * 注册动作执行器
   */
  public registerExecutor(type: ActionType, executor: IActionExecutor): void {
    this.executors.set(type, executor);
    Logger.info('ActionExecutor', `Registered executor for action type: ${type}`);
  }

  /**
   * 执行动作
   *
   * @param action 动作配置
   * @param context 执行上下文
   * @returns 执行结果
   */
  public async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    Logger.info('ActionExecutor', `Executing action: ${action.type}`);

    const startTime = Date.now();
    let result: ActionExecutionResult;

    try {
      const executor = this.executors.get(action.type);

      if (!executor) {
        throw new Error(`No executor registered for action type: ${action.type}`);
      }

      // 执行动作
      result = await executor.execute(action, context);

      // 如果执行器没有返回结果，创建一个成功的结果
      if (!result) {
        result = {
          status: 'success',
          duration: Date.now() - startTime
        };
      }

      // 确保包含 duration
      if (result.duration === undefined) {
        result.duration = Date.now() - startTime;
      }

      Logger.info('ActionExecutor', `Action ${action.type} completed in ${result.duration}ms`);

      // 性能监控：单个动作执行时间 < 3 秒
      if (result.duration > 3000) {
        Logger.warn('ActionExecutor', `Action ${action.type} took ${result.duration}ms, exceeding 3s threshold`);
      }

      // 记录动作执行日志
      await this.logActionExecution(action, context, result);

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('ActionExecutor', `Action ${action.type} failed: ${errorMessage}`);

      // 创建失败结果
      result = {
        status: 'failed',
        errorMessage: errorMessage,
        duration: Date.now() - startTime
      };

      // 记录失败日志
      await this.logActionExecution(action, context, result);

      throw new Error(`动作执行失败 [${action.type}]: ${errorMessage}`);
    }

    return result;
  }

  /**
   * 记录动作执行日志
   */
  private async logActionExecution(
    action: Action,
    context: ExecutionContext,
    result: ActionExecutionResult
  ): Promise<void> {
    if (!this.executionLogId) {
      Logger.warn('ActionExecutor', 'No execution log ID set, skipping action log recording');
      return;
    }

    try {
      const databaseService = DatabaseService.getInstance();
      await databaseService.insertActionExecutionLog({
        executionLogId: this.executionLogId,
        actionId: action.id,
        actionType: action.type,
        actionOrderIndex: action.orderIndex,
        inputData: result.inputData ? JSON.stringify(result.inputData) : undefined,
        outputData: result.outputData ? JSON.stringify(result.outputData) : undefined,
        status: result.status,
        errorMessage: result.errorMessage,
        duration: result.duration,
        executedAt: Date.now()
      });

      Logger.info('ActionExecutor', `Action execution logged for ${action.type}`);
    } catch (error) {
      Logger.error('ActionExecutor', 'Failed to log action execution', error as Error);
    }
  }
}
