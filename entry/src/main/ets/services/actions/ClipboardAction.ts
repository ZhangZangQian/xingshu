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

    // 准备输入数据
    const inputData: Record<string, any> = {
      operation: config.operation,
      content: config.content,
      saveToVariable: config.saveToVariable
    };

    try {
      const outputData: Record<string, any> = {
        operation: config.operation
      };

      if (config.operation === 'read') {
        // 读取剪贴板
        const content = await this.clipboardService.readText();
        Logger.info('ClipboardAction', `Read ${content.length} characters from clipboard`);

        outputData.content = content;
        outputData.contentLength = content.length;

        // 保存到变量
        if (config.saveToVariable) {
          context.setVariable(config.saveToVariable, content);
          outputData.savedToVariable = config.saveToVariable;
          Logger.info('ClipboardAction', `Clipboard content saved to variable: ${config.saveToVariable}`);
        }

      } else if (config.operation === 'write') {
        // 写入剪贴板
        if (!config.content) {
          throw new Error('Content is required for clipboard write operation');
        }

        const content = await VariableParser.parse(config.content, context);
        await this.clipboardService.writeText(content);
        Logger.info('ClipboardAction', `Wrote ${content.length} characters to clipboard`);

        outputData.writtenContent = content;
        outputData.writtenLength = content.length;

      } else {
        throw new Error(`Unknown clipboard operation: ${config.operation}`);
      }

      Logger.info('ClipboardAction', 'Clipboard operation completed successfully');

      // 返回执行结果
      return {
        status: 'success',
        inputData: inputData,
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
