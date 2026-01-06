import { Action, ActionType } from '../models/Macro';
import { ExecutionContext } from '../models/ExecutionContext';
import Logger from '../utils/Logger';

/**
 * 动作执行器基类
 */
export interface IActionExecutor {
  /**
   * 执行动作
   * @param action 动作配置
   * @param context 执行上下文
   */
  execute(action: Action, context: ExecutionContext): Promise<void>;
}

/**
 * 动作执行器（策略模式）
 * 核心职责：根据动作类型分发到具体执行器
 */
export class ActionExecutor {
  private static instance: ActionExecutor;
  private executors: Map<ActionType, IActionExecutor>;

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
   */
  public async execute(action: Action, context: ExecutionContext): Promise<void> {
    Logger.info('ActionExecutor', `Executing action: ${action.type}`);

    const startTime = Date.now();

    try {
      const executor = this.executors.get(action.type);

      if (!executor) {
        throw new Error(`No executor registered for action type: ${action.type}`);
      }

      await executor.execute(action, context);

      const duration = Date.now() - startTime;
      Logger.info('ActionExecutor', `Action ${action.type} completed in ${duration}ms`);

      // 性能监控：单个动作执行时间 < 3 秒
      if (duration > 3000) {
        Logger.warn('ActionExecutor', `Action ${action.type} took ${duration}ms, exceeding 3s threshold`);
      }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('ActionExecutor', `Action ${action.type} failed: ${errorMessage}`);
      throw new Error(`动作执行失败 [${action.type}]: ${errorMessage}`);
    }
  }
}
