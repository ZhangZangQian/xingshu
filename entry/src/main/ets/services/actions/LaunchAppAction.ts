import { Action, LaunchAppConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

/**
 * 启动应用动作执行器
 */
export class LaunchAppAction implements IActionExecutor {
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

    const config = JSON.parse(action.config) as LaunchAppConfig;
    Logger.info('LaunchAppAction', `Launching app: ${config.bundleName}`);

    const startTime = Date.now();

    try {
      // 构建 Want 对象
      const want: Want = {
        bundleName: config.bundleName,
        abilityName: config.abilityName,
        parameters: config.parameters || {}
      };

      // 根据启动模式设置
      let parsedUri: string | undefined = undefined;
      if (config.mode === 'implicit') {
        // 隐式启动
        if (config.action) {
          want.action = config.action;
        }
        if (config.uri) {
          parsedUri = await VariableParser.parse(config.uri, executionContext);
          want.uri = parsedUri;
        }
      } else {
        // 显式启动（需要 abilityName）
        if (!config.abilityName) {
          throw new Error('Explicit launch requires abilityName');
        }
      }

      // 启动应用
      await this.context.startAbility(want);
      Logger.info('LaunchAppAction', `App ${config.bundleName} launched successfully`);

      // 返回执行结果（使用解析后的值作为 inputData）
      return {
        status: 'success',
        inputData: {
          bundleName: config.bundleName,
          abilityName: config.abilityName,
          mode: config.mode,
          action: config.action,
          uri: parsedUri,
          parameters: config.parameters
        },
        outputData: {
          launchedBundleName: config.bundleName,
          launchedAbilityName: config.abilityName
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('LaunchAppAction', `Failed to launch app: ${errorMessage}`);
      throw new Error(`启动应用失败: ${errorMessage}`);
    }
  }
}
