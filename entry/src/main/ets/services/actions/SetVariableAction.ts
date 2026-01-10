import { Action, SetVariableConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { DatabaseService } from '../DatabaseService';
import { Variable, VariableScope, VariableType, VariableInput, isJSONObject, isJSONArray } from '../../models/Variable';
import { JsonUtils } from '../../utils/JsonUtils';

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
      const parsedValueStr = await VariableParser.parse(config.value, context);
      Logger.info('SetVariableAction', `Parsed value: ${parsedValueStr}`);

      // 新增：类型处理
      let finalValue: any = parsedValueStr;
      let variableType: VariableType = VariableType.STRING;

      // 如果指定解析为 JSON
      if (config.parseAsJSON) {
        finalValue = JsonUtils.parseJSONSafely(parsedValueStr);
        if (finalValue === null) {
          throw new Error(`Failed to parse JSON: ${parsedValueStr}`);
        }

        // 推断类型
        if (isJSONObject(finalValue)) {
          variableType = VariableType.OBJECT;
        } else if (isJSONArray(finalValue)) {
          variableType = VariableType.ARRAY;
        } else if (typeof finalValue === 'number') {
          variableType = VariableType.NUMBER;
        } else if (typeof finalValue === 'boolean') {
          variableType = VariableType.BOOLEAN;
        } else {
          variableType = VariableType.STRING;
        }
      } else if (config.type && config.type !== 'auto') {
        // 显式类型转换
        switch (config.type) {
          case 'number':
            finalValue = Number(parsedValueStr);
            variableType = VariableType.NUMBER;
            break;
          case 'boolean':
            finalValue = parsedValueStr === 'true';
            variableType = VariableType.BOOLEAN;
            break;
          case 'object':
          case 'array':
            finalValue = JsonUtils.parseJSONSafely(parsedValueStr);
            variableType = config.type === 'object' ? VariableType.OBJECT : VariableType.ARRAY;
            break;
          case 'string':
          default:
            finalValue = parsedValueStr;
            variableType = VariableType.STRING;
            break;
        }
      } else {
        // 自动推断类型
        finalValue = this.inferType(parsedValueStr);
        variableType = this.inferTypeToVariableType(finalValue);
      }

      // 根据作用域设置变量
      switch (config.scope) {
        case 'runtime':
          await this.setRuntimeVariable(config.variableName, finalValue, context);
          break;

        case 'global':
          await this.setGlobalVariable(config.variableName, finalValue, context, variableType);
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
          value: parsedValueStr,
          scope: config.scope
        },
        outputData: {
          variableName: config.variableName,
          value: finalValue,
          scope: config.scope,
          type: variableType
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
  private async setRuntimeVariable(name: string, value: any, context: ExecutionContext): Promise<void> {
    context.setVariable(name, value);
    Logger.info('SetVariableAction', `Runtime variable '${name}' set to: ${JSON.stringify(value)}`);
  }

  /**
   * 设置全局变量（持久化到数据库）
   */
  private async setGlobalVariable(
    name: string,
    value: any,
    context: ExecutionContext,
    type: VariableType
  ): Promise<void> {
    const databaseService = DatabaseService.getInstance();

    // 检查全局变量是否已存在
    const existingVariables = await databaseService.getGlobalVariables();
    const existingVar = existingVariables.find(v => v.name === name);

    if (existingVar) {
      // 更新现有变量
      await databaseService.updateVariable(existingVar.id, {
        value: value,
        type: type
      });
      Logger.info('SetVariableAction', `Global variable '${name}' updated to: ${JSON.stringify(value)}`);
    } else {
      // 创建新变量
      const newVar: VariableInput = {
        name: name,
        value: value,
        type: type,
        scope: VariableScope.GLOBAL,
        macroId: undefined,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      await databaseService.insertVariable(newVar);
      Logger.info('SetVariableAction', `Global variable '${name}' created with value: ${JSON.stringify(value)}`);
    }

    // 同时更新上下文中的全局变量缓存
    context.globalVariables.set(name, value);
  }

  /**
   * 自动推断类型
   */
  private inferType(value: string): any {
    // 尝试解析为 JSON
    const jsonParsed = JsonUtils.parseJSONSafely(value);
    if (jsonParsed !== null) {
      return jsonParsed;
    }

    // 数字
    if (!isNaN(Number(value))) {
      return Number(value);
    }

    // 布尔值
    if (value === 'true') return true;
    if (value === 'false') return false;

    // 默认字符串
    return value;
  }

  /**
   * 推断变量类型
   */
  private inferTypeToVariableType(value: any): VariableType {
    if (isJSONObject(value)) return VariableType.OBJECT;
    if (isJSONArray(value)) return VariableType.ARRAY;
    if (typeof value === 'number') return VariableType.NUMBER;
    if (typeof value === 'boolean') return VariableType.BOOLEAN;
    return VariableType.STRING;
  }
}
