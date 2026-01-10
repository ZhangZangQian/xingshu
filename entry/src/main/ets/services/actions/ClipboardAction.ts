import { Action, ClipboardConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { ClipboardService } from '../ClipboardService';

/**
 * 剪贴板操作动作执行器
 */
export class ClipboardAction implements IActionExecutor {
  private clipboardService: ClipboardService;

  constructor() {
    this.clipboardService = ClipboardService.getInstance();
  }

  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as ClipboardConfig;
    Logger.info('ClipboardAction', `Clipboard operation: ${config.operation}`);

    const startTime = Date.now();

    try {
      const outputData: Record<string, any> = {
        operation: config.operation
      };

      let parsedContent: string | undefined = undefined;

      if (config.operation === 'read') {
        // 读取剪贴板
        const content = await this.clipboardService.readText();
        Logger.info('ClipboardAction', `Read ${content.length} characters from clipboard`);

        parsedContent = content;
        outputData.content = content;
        outputData.contentLength = content.length;

        // 保存到变量
        if (config.saveToVariable) {
          context.setVariable(config.saveToVariable, content);
          outputData.savedToVariable = config.saveToVariable;
          Logger.info('ClipboardAction', `Clipboard content saved to variable: ${config.saveToVariable}, content length: ${content.length}, content: ${content.substring(0, 50)}`);
        }

      } else if (config.operation === 'write') {
        // 写入剪贴板
        if (!config.content) {
          throw new Error('Content is required for clipboard write operation');
        }

        parsedContent = await VariableParser.parse(config.content, context);
        await this.clipboardService.writeText(parsedContent);
        Logger.info('ClipboardAction', `Wrote ${parsedContent.length} characters to clipboard`);

        outputData.writtenContent = parsedContent;
        outputData.writtenLength = parsedContent.length;

      } else {
        throw new Error(`Unknown clipboard operation: ${config.operation}`);
      }

      Logger.info('ClipboardAction', 'Clipboard operation completed successfully');

      // 返回执行结果（使用解析后的值作为 inputData）
      return {
        status: 'success',
        inputData: {
          operation: config.operation,
          content: parsedContent || config.content,
          saveToVariable: config.saveToVariable
        },
        outputData: outputData,
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('ClipboardAction', `Clipboard operation failed: ${errorMessage}`);
      throw new Error(`剪贴板操作失败: ${errorMessage}`);
    }
  }
}
