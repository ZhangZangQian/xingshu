import { Action, NotificationConfig } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { NotificationService } from '../NotificationService';

/**
 * 发送通知动作执行器
 */
export class NotificationAction implements IActionExecutor {
  private notificationService: NotificationService;

  constructor() {
    this.notificationService = NotificationService.getInstance();
  }

  async execute(action: Action, context: ExecutionContext): Promise<void> {
    const config = JSON.parse(action.config) as NotificationConfig;
    Logger.info('NotificationAction', `Sending notification: ${config.title}`);

    try {
      // 解析变量
      const title = await VariableParser.parse(config.title, context);
      const content = await VariableParser.parse(config.content, context);

      // 发送通知
      await this.notificationService.sendNotification(
        title,
        content,
        {
          enableSound: config.enableSound,
          enableVibration: config.enableVibration
        }
      );

      Logger.info('NotificationAction', 'Notification sent successfully');

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('NotificationAction', `Failed to send notification: ${errorMessage}`);
      throw new Error(`发送通知失败: ${errorMessage}`);
    }
  }
}
