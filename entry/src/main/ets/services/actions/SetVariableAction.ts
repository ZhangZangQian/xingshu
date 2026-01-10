import { Action, SetVariableConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { DatabaseService } from '../DatabaseService';
import { Variable, VariableScope, VariableType, VariableInput } from '../../models/Variable';

/**
 * 设置变量动作执行器
 *
 * 功能特性:
 * 1. 支持设置两种作用域的变量: runtime(运行时)、global(全局)
 * 2. 支持变量引用，value 可以包含 {variable_name} 格式的变量引用
 * 3. runtime 变量仅在当前执行上下文中有效
 * 4. global 变量会持久化到数据库
 */
export class SetVariableAction implements IActionExecutor {
  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as SetVariableConfig;
    Logger.info('SetVariableAction', `Setting variable: ${config.variableName}, scope: ${config.scope}`);

    const startTime = Date.now();

    try {
      // 解析变量值（支持变量引用）
      const parsedValue = await VariableParser.parse(config.value, context);
      Logger.info('SetVariableAction', `Parsed value: ${parsedValue}`);

      // 根据作用域设置变量
      switch (config.scope) {
        case 'runtime':
          await this.setRuntimeVariable(config.variableName, parsedValue, context);
          break;

        case 'global':
          await this.setGlobalVariable(config.variableName, parsedValue, context);
          break;

        default:
          throw new Error(`Unknown variable scope: ${config.scope}`);
      }

      Logger.info('SetVariableAction', `Variable ${config.variableName} set successfully`);

      // 返回执行结果（使用解析后的值作为 inputData）
      return {
        status: 'success',
        inputData: {
          variableName: config.variableName,
          value: parsedValue,
          scope: config.scope
        },
        outputData: {
          variableName: config.variableName,
          value: parsedValue,
          scope: config.scope
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('SetVariableAction', `Failed to set variable: ${errorMessage}`);
      throw new Error(`设置变量失败: ${errorMessage}`);
    }
  }

  /**
   * 设置运行时变量（仅在当前执行上下文中有效）
   */
  private async setRuntimeVariable(name: string, value: string, context: ExecutionContext): Promise<void> {
    context.setVariable(name, value);
    Logger.info('SetVariableAction', `Runtime variable '${name}' set to: ${value}`);
  }

  /**
   * 设置全局变量（持久化到数据库）
   */
  private async setGlobalVariable(name: string, value: string, context: ExecutionContext): Promise<void> {
    const databaseService = DatabaseService.getInstance();

    // 检查全局变量是否已存在
    const existingVariables = await databaseService.getGlobalVariables();
    const existingVar = existingVariables.find(v => v.name === name);

    if (existingVar) {
      // 更新现有变量
      await databaseService.updateVariable(existingVar.id, {
        value: value,
        type: VariableType.STRING
      });
      Logger.info('SetVariableAction', `Global variable '${name}' updated to: ${value}`);
    } else {
      // 创建新变量
      const newVar: VariableInput = {
        name: name,
        value: value,
        type: VariableType.STRING,
        scope: VariableScope.GLOBAL,
        macroId: undefined,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      await databaseService.insertVariable(newVar);
      Logger.info('SetVariableAction', `Global variable '${name}' created with value: ${value}`);
    }

    // 同时更新上下文中的全局变量缓存
    context.globalVariables.set(name, value);
  }
}
