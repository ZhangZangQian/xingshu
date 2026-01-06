/**
 * 动作类型常量
 */
export class ActionTypes {
  static readonly LAUNCH_APP = 'launch_app';
  static readonly NOTIFICATION = 'notification';
  static readonly HTTP_REQUEST = 'http_request';
  static readonly CLIPBOARD_READ = 'clipboard_read';
  static readonly CLIPBOARD_WRITE = 'clipboard_write';
  static readonly OPEN_URL = 'open_url';
  static readonly TEXT_PROCESS = 'text_process';
  static readonly USER_DIALOG = 'user_dialog';

  /**
   * 获取所有动作类型
   */
  static getAll(): string[] {
    return [
      ActionTypes.LAUNCH_APP,
      ActionTypes.NOTIFICATION,
      ActionTypes.HTTP_REQUEST,
      ActionTypes.CLIPBOARD_READ,
      ActionTypes.CLIPBOARD_WRITE,
      ActionTypes.OPEN_URL,
      ActionTypes.TEXT_PROCESS,
      ActionTypes.USER_DIALOG
    ];
  }

  /**
   * 获取动作类型显示名称
   */
  static getDisplayName(type: string): string {
    switch (type) {
      case ActionTypes.LAUNCH_APP:
        return '启动应用';
      case ActionTypes.NOTIFICATION:
        return '发送通知';
      case ActionTypes.HTTP_REQUEST:
        return 'HTTP 请求';
      case ActionTypes.CLIPBOARD_READ:
        return '读取剪贴板';
      case ActionTypes.CLIPBOARD_WRITE:
        return '写入剪贴板';
      case ActionTypes.OPEN_URL:
        return '打开 URL';
      case ActionTypes.TEXT_PROCESS:
        return '文本处理';
      case ActionTypes.USER_DIALOG:
        return '用户交互对话框';
      default:
        return '未知类型';
    }
  }
}
