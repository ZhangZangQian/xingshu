import { Action, TextProcessConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import util from '@ohos.util';

/**
 * 文本处理动作执行器
 */
export class TextProcessAction implements IActionExecutor {
  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as TextProcessConfig;
    Logger.info('TextProcessAction', `Text processing operation: ${config.operation}`);

    const startTime = Date.now();

    // 准备输入数据
    const inputData: Record<string, any> = {
      operation: config.operation,
      input: config.input,
      pattern: config.pattern,
      groupIndex: config.groupIndex,
      searchValue: config.searchValue,
      replaceValue: config.replaceValue,
      separator: config.separator,
      saveToVariable: config.saveToVariable
    };

    try {
      // 解析输入文本（支持变量）
      const input = await VariableParser.parse(config.input, context);

      let result: string | string[] = '';

      // 根据操作类型处理文本
      switch (config.operation) {
        case 'regex_extract':
          result = await this.regexExtract(input, config.pattern!, config.groupIndex || 0, context);
          break;

        case 'replace':
          result = await this.replace(input, config.searchValue!, config.replaceValue!, context);
          break;

        case 'split':
          result = await this.split(input, config.separator!, context);
          break;

        case 'uppercase':
          result = input.toUpperCase();
          break;

        case 'lowercase':
          result = input.toLowerCase();
          break;

        case 'url_encode':
          result = await this.urlEncode(input, context);
          break;

        case 'url_decode':
          result = await this.urlDecode(input, context);
          break;

        default:
          throw new Error(`Unknown text processing operation: ${config.operation}`);
      }

      // 保存结果到变量
      if (config.saveToVariable) {
        context.setVariable(config.saveToVariable, result);
        Logger.info('TextProcessAction', `Result saved to variable: ${config.saveToVariable}`);
      }

      Logger.info('TextProcessAction', 'Text processing completed successfully');

      // 返回执行结果
      return {
        status: 'success',
        inputData: inputData,
        outputData: {
          input: input,
          result: result,
          savedToVariable: config.saveToVariable
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('TextProcessAction', `Text processing failed: ${errorMessage}`);
      throw new Error(`文本处理失败: ${errorMessage}`);
    }
  }

  /**
   * 正则提取
   */
  private async regexExtract(input: string, pattern: string, groupIndex: number, context: ExecutionContext): Promise<string> {
    try {
      const parsedPattern = await VariableParser.parse(pattern, context);
      const regex = new RegExp(parsedPattern);
      const match = input.match(regex);

      if (!match) {
        Logger.warn('TextProcessAction', 'Regex pattern did not match');
        return '';
      }

      // 返回指定捕获组（默认 0 = 完整匹配）
      return match[groupIndex] || '';
    } catch (error) {
      throw new Error(`Invalid regex pattern: ${pattern}`);
    }
  }

  /**
   * 文本替换
   */
  private async replace(input: string, searchValue: string, replaceValue: string, context: ExecutionContext): Promise<string> {
    const parsedSearchValue = await VariableParser.parse(searchValue, context);
    const parsedReplaceValue = await VariableParser.parse(replaceValue, context);

    // 支持正则替换
    try {
      const regex = new RegExp(parsedSearchValue, 'g');
      return input.replace(regex, parsedReplaceValue);
    } catch (error) {
      // 如果不是有效正则，则按字符串替换
      return input.split(parsedSearchValue).join(parsedReplaceValue);
    }
  }

  /**
   * 文本分割
   */
  private async split(input: string, separator: string, context: ExecutionContext): Promise<string[]> {
    const parsedSeparator = await VariableParser.parse(separator, context);
    return input.split(parsedSeparator);
  }

  /**
   * URL 编码
   */
  private async urlEncode(input: string, context: ExecutionContext): Promise<string> {
    try {
      return encodeURIComponent(input);
    } catch (error) {
      throw new Error('URL encoding failed');
    }
  }

  /**
   * URL 解码
   */
  private async urlDecode(input: string, context: ExecutionContext): Promise<string> {
    try {
      return decodeURIComponent(input);
    } catch (error) {
      throw new Error('URL decoding failed');
    }
  }
}
