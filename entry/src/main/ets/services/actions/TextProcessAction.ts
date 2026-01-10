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

    try {
      Logger.info('TextProcessAction', `Original input config: ${config.input}`);

      // 解析输入文本（支持变量）
      console.log(`[TextProcessAction] Before VariableParser.parse, input: ${config.input}`);
      const input = await VariableParser.parse(config.input, context);
      console.log(`[TextProcessAction] After VariableParser.parse, result: ${input}`);
      Logger.info('TextProcessAction', `Parsed input: ${input}`);

      // 解析其他配置参数中的变量
      const parsedPattern = config.pattern ? await VariableParser.parse(config.pattern, context) : undefined;
      const parsedSearchValue = config.searchValue ? await VariableParser.parse(config.searchValue, context) : undefined;
      const parsedReplaceValue = config.replaceValue ? await VariableParser.parse(config.replaceValue, context) : undefined;
      const parsedSeparator = config.separator ? await VariableParser.parse(config.separator, context) : undefined;

      let result: string | string[] = '';

      // 根据操作类型处理文本
      switch (config.operation) {
        case 'regex_extract':
          result = await this.regexExtract(input, parsedPattern!, config.groupIndex || 0, context);
          break;

        case 'replace':
          result = await this.replace(input, parsedSearchValue!, parsedReplaceValue!, context);
          break;

        case 'split':
          result = await this.split(input, parsedSeparator!, context);
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

      Logger.info('TextProcessAction', `Parsing input: ${config.input} -> ${input}`);
      Logger.info('TextProcessAction', 'Text processing completed successfully');

      // 返回执行结果（使用解析后的值作为 inputData）
      return {
        status: 'success',
        inputData: {
          operation: config.operation,
          input: input,
          pattern: parsedPattern,
          groupIndex: config.groupIndex,
          searchValue: parsedSearchValue,
          replaceValue: parsedReplaceValue,
          separator: parsedSeparator,
          saveToVariable: config.saveToVariable
        },
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
      const regex = new RegExp(pattern);
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
    // 支持正则替换
    try {
      const regex = new RegExp(searchValue, 'g');
      return input.replace(regex, replaceValue);
    } catch (error) {
      // 如果不是有效正则，则按字符串替换
      return input.split(searchValue).join(replaceValue);
    }
  }

  /**
   * 文本分割
   */
  private async split(input: string, separator: string, context: ExecutionContext): Promise<string[]> {
    return input.split(separator);
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
