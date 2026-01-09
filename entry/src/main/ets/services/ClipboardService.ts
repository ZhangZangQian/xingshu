import pasteboard from '@ohos.pasteboard';
import Logger from '../utils/Logger';

/**
 * 剪贴板服务
 * 封装鸿蒙剪贴板 API
 */
export class ClipboardService {
  private static instance: ClipboardService;

  private constructor() {
  }

  public static getInstance(): ClipboardService {
    if (!ClipboardService.instance) {
      ClipboardService.instance = new ClipboardService();
    }
    return ClipboardService.instance;
  }

  /**
   * 读取剪贴板文本内容
   */
  async readText(): Promise<string> {
    try {
      const pasteboardData = pasteboard.getSystemPasteboard();
      const hasData = pasteboardData.hasPasteData();

      if (!hasData) {
        Logger.info('ClipboardService', 'Clipboard is empty');
        return '';
      }

      const pasteData = await pasteboardData.getData();
      const primaryText = pasteData.getPrimaryText();

      if (primaryText) {
        Logger.info('ClipboardService', `Read clipboard: ${primaryText.substring(0, 50)}...`);
        return primaryText;
      }

      return '';
    } catch (error) {
      Logger.error('ClipboardService', 'Failed to read clipboard', error as Error);
      throw new Error(`读取剪贴板失败: ${error.message}`);
    }
  }

  /**
   * 写入文本到剪贴板
   */
  async writeText(text: string): Promise<void> {
    try {
      const pasteboardData = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);

      pasteboardData.setPasteData(pasteData);

      Logger.info('ClipboardService', `Wrote to clipboard: ${text.substring(0, 50)}...`);
    } catch (error) {
      Logger.error('ClipboardService', 'Failed to write clipboard', error as Error);
      throw new Error(`写入剪贴板失败: ${error.message}`);
    }
  }

  /**
   * 清空剪贴板
   */
  async clear(): Promise<void> {
    try {
      const pasteboardData = pasteboard.getSystemPasteboard();
      pasteboardData.clearData();

      Logger.info('ClipboardService', 'Clipboard cleared');
    } catch (error) {
      Logger.error('ClipboardService', 'Failed to clear clipboard', error as Error);
      throw new Error(`清空剪贴板失败: ${error.message}`);
    }
  }
}
