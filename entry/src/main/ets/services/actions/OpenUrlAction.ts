import { Action, OpenUrlConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

/**
 * 打开 URL 动作执行器
 */
export class OpenUrlAction implements IActionExecutor {
  private context: common.UIAbilityContext | null = null;

  /**
   * 设置 Ability 上下文（在应用启动时调用）
   */
  public setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  async execute(action: Action, executionContext: ExecutionContext): Promise<ActionExecutionResult> {
    if (!this.context) {
      throw new Error('UIAbilityContext not initialized');
    }

    const config = JSON.parse(action.config) as OpenUrlConfig;
    Logger.info('OpenUrlAction', `Opening URL: ${config.url}`);

    const startTime = Date.now();

    try {
      // 解析变量
      const url = await VariableParser.parse(config.url, executionContext);

      // 构建 Want 对象
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      };

      // 根据打开方式设置
      if (config.openWith === 'browser') {
        want.entities.push('entity.system.browsable');
      }

      // 启动
      await this.context.startAbility(want);
      Logger.info('OpenUrlAction', `URL opened successfully: ${url}`);

      // 返回执行结果（使用解析后的值作为 inputData）
      return {
        status: 'success',
        inputData: {
          url: url,
          openWith: config.openWith
        },
        outputData: {
          openedUrl: url,
          openWith: config.openWith
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('OpenUrlAction', `Failed to open URL: ${errorMessage}`);
      throw new Error(`打开 URL 失败: ${errorMessage}`);
    }
  }
}
