import notificationManager from '@ohos.notificationManager';
import Logger from '../utils/Logger';

/**
 * 通知服务
 * 封装鸿蒙通知 API
 */
export class NotificationService {
  private static instance: NotificationService;
  private notificationId: number = 1000;  // 通知 ID 起始值

  private constructor() {
  }

  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /**
   * 发送通知
   *
   * @param title 通知标题
   * @param content 通知内容
   * @param options 可选配置
   */
  async sendNotification(
    title: string,
    content: string,
    options?: {
      enableSound?: boolean;
      enableVibration?: boolean;
      icon?: string;
    }
  ): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: this.getNextNotificationId(),
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content
          }
        },
        // 通知配置
        ...(options?.enableSound !== undefined && { soundEnabled: options.enableSound }),
        ...(options?.enableVibration !== undefined && {
          vibrationEnabled: options.enableVibration
        })
      };

      await notificationManager.publish(notificationRequest);

      Logger.info('NotificationService', `Notification sent: ${title}`);
    } catch (error) {
      Logger.error('NotificationService', 'Failed to send notification', error as Error);
      throw new Error(`发送通知失败: ${error.message}`);
    }
  }

  /**
   * 发送成功通知
   */
  async sendSuccessNotification(macroName: string): Promise<void> {
    await this.sendNotification(
      '宏执行成功',
      `"${macroName}" 已成功执行`,
      {
        enableSound: true,
        enableVibration: false
      }
    );
  }

  /**
   * 发送错误通知
   */
  async sendErrorNotification(macroName: string, errorMessage: string): Promise<void> {
    await this.sendNotification(
      '宏执行失败',
      `"${macroName}" 执行失败: ${errorMessage}`,
      {
        enableSound: true,
        enableVibration: true
      }
    );
  }

  /**
   * 取消通知
   */
  async cancelNotification(notificationId: number): Promise<void> {
    try {
      await notificationManager.cancel(notificationId);
      Logger.info('NotificationService', `Notification ${notificationId} cancelled`);
    } catch (error) {
      Logger.error('NotificationService', `Failed to cancel notification ${notificationId}`, error as Error);
    }
  }

  /**
   * 取消所有通知
   */
  async cancelAllNotifications(): Promise<void> {
    try {
      await notificationManager.cancelAll();
      Logger.info('NotificationService', 'All notifications cancelled');
    } catch (error) {
      Logger.error('NotificationService', 'Failed to cancel all notifications', error as Error);
    }
  }

  /**
   * 获取下一个通知 ID
   */
  private getNextNotificationId(): number {
    return this.notificationId++;
  }
}
