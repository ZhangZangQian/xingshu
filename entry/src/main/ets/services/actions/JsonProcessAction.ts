import { Action, JsonProcessConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { JsonUtils } from '../../utils/JsonUtils';

/**
 * JSON 处理动作执行器
 * 提供 JSONPath 查询、数组操作等高级功能
 */
export class JsonProcessAction implements IActionExecutor {
  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as JsonProcessConfig;
    Logger.info('JsonProcessAction', `JSON processing operation: ${config.operation}`);

    const startTime = Date.now();

    try {
      // 解析输入 JSON（支持变量）
      const inputStr = await VariableParser.parse(config.input, context);
      const inputObj = JsonUtils.parseJSONSafely(inputStr);

      if (inputObj === null) {
        throw new Error(`Invalid JSON input: ${inputStr}`);
      }

      let result: any;

      // 根据操作类型处理
      switch (config.operation) {
        case 'json_query':
          result = this.jsonQuery(inputObj, config.queryPath || '', context);
          break;

        case 'json_filter':
          result = this.jsonFilter(inputObj, config.filterCondition || '', context);
          break;

        case 'json_map':
          result = this.jsonMap(inputObj, config.mapField || '', context);
          break;

        case 'json_merge':
          result = this.jsonMerge(inputObj, config.mergeSource || '', context);
          break;

        case 'array_length':
          result = this.arrayLength(inputObj);
          break;

        case 'array_get':
          result = this.arrayGet(inputObj, config.arrayIndex || 0);
          break;

        case 'array_set':
          result = this.arraySet(inputObj, config.arrayIndex || 0, config.newValue || '', context);
          break;

        case 'json_encode':
          result = JSON.stringify(inputObj);
          break;

        case 'json_decode':
          // 已在上方解析，直接返回
          result = inputObj;
          break;

        default:
          throw new Error(`Unknown JSON processing operation: ${config.operation}`);
      }

      // 保存结果到变量
      if (config.saveToVariable) {
        context.setVariable(config.saveToVariable, result);
        Logger.info('JsonProcessAction', `Result saved to variable: ${config.saveToVariable}`);
      }

      Logger.info('JsonProcessAction', 'JSON processing completed successfully');

      return {
        status: 'success',
        inputData: {
          operation: config.operation,
          input: inputObj
        },
        outputData: {
          operation: config.operation,
          result: result,
          savedToVariable: config.saveToVariable
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('JsonProcessAction', `JSON processing failed: ${errorMessage}`);
      throw new Error(`JSON 处理失败: ${errorMessage}`);
    }
  }

  /**
   * JSONPath 查询
   * 示例：queryPath = "users.0.name"
   */
  private async jsonQuery(json: any, queryPath: string, context: ExecutionContext): Promise<any> {
    const path = queryPath.split('.');
    return JsonUtils.getValueByPath(json, path);
  }

  /**
   * JSON 数组过滤
   * 示例：filterCondition = "age>18"
   */
  private async jsonFilter(json: any[], filterCondition: string, context: ExecutionContext): Promise<any[]> {
    if (!Array.isArray(json)) {
      throw new Error('json_filter requires array input');
    }

    return json.filter(item => {
      return JsonUtils['evaluateCondition'](item, filterCondition);
    });
  }

  /**
   * JSON 数组映射（提取字段）
   * 示例：mapField = "name" -> [{name: "张三"}, {name: "李四"}] -> ["张三", "李四"]
   */
  private async jsonMap(json: any[], mapField: string, context: ExecutionContext): Promise<any[]> {
    if (!Array.isArray(json)) {
      throw new Error('json_map requires array input');
    }

    return json.map(item => item[mapField]);
  }

  /**
   * JSON 合并
   */
  private async jsonMerge(target: any, sourceStr: string, context: ExecutionContext): Promise<any> {
    const source = JsonUtils.parseJSONSafely(sourceStr);
    return JsonUtils.mergeJSON(target, source);
  }

  /**
   * 获取数组长度
   */
  private arrayLength(array: any[]): number {
    if (!Array.isArray(array)) {
      throw new Error('array_length requires array input');
    }
    return array.length;
  }

  /**
   * 获取数组元素
   */
  private arrayGet(array: any[], index: number): any {
    if (!Array.isArray(array)) {
      throw new Error('array_get requires array input');
    }
    return array[index];
  }

  /**
   * 设置数组元素
   */
  private async arraySet(array: any[], index: number, newValueStr: string, context: ExecutionContext): Promise<any[]> {
    const newValue = await VariableParser.parse(newValueStr, context);
    array[index] = newValue;
    return array;
  }
}
