import { Action, UserDialogConfig } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import promptAction from '@ohos.promptAction';

/**
 * 用户交互对话框动作执行器
 *
 * 注意：由于多选和文本输入对话框需要自定义 CustomDialog，
 * 而 CustomDialog 必须在 UI 层使用，服务层无法直接创建。
 *
 * 这里提供两种实现方案：
 * 1. 使用全局事件总线（DialogEventBus）通知 UI 层显示对话框
 * 2. 对于简化版，使用连续的单选模拟多选功能
 */

/**
 * 对话框事件总线（用于服务层与UI层通信）
 */
export class DialogEventBus {
  private static instance: DialogEventBus;
  private multiSelectCallback: ((config: UserDialogConfig) => Promise<string[]>) | null = null;
  private textInputCallback: ((config: UserDialogConfig) => Promise<string>) | null = null;

  private constructor() {}

  public static getInstance(): DialogEventBus {
    if (!DialogEventBus.instance) {
      DialogEventBus.instance = new DialogEventBus();
    }
    return DialogEventBus.instance;
  }

  /**
   * 注册多选对话框回调（由 UI 层调用）
   */
  public registerMultiSelectHandler(handler: (config: UserDialogConfig) => Promise<string[]>) {
    this.multiSelectCallback = handler;
  }

  /**
   * 注册文本输入对话框回调（由 UI 层调用）
   */
  public registerTextInputHandler(handler: (config: UserDialogConfig) => Promise<string>) {
    this.textInputCallback = handler;
  }

  /**
   * 显示多选对话框（由服务层调用）
   */
  public async showMultiSelect(config: UserDialogConfig): Promise<string[]> {
    if (!this.multiSelectCallback) {
      Logger.warn('DialogEventBus', 'MultiSelect handler not registered, using fallback');
      // 降级方案：使用多次单选模拟
      return await this.fallbackMultiSelect(config);
    }
    return await this.multiSelectCallback(config);
  }

  /**
   * 显示文本输入对话框（由服务层调用）
   */
  public async showTextInput(config: UserDialogConfig): Promise<string> {
    if (!this.textInputCallback) {
      Logger.warn('DialogEventBus', 'TextInput handler not registered, using fallback');
      // 降级方案：返回默认值
      return config.defaultValue || '';
    }
    return await this.textInputCallback(config);
  }

  /**
   * 降级方案：使用多次单选模拟多选
   */
  private async fallbackMultiSelect(config: UserDialogConfig): Promise<string[]> {
    const selected: string[] = [];

    // 最多允许选择 5 项
    for (let i = 0; i < 5; i++) {
      const remainingOptions = config.options?.filter(opt => !selected.includes(opt)) || [];

      if (remainingOptions.length === 0) {
        break;
      }

      // 添加"完成选择"选项
      const dialogOptions = [...remainingOptions, '完成选择'];

      try {
        const result = await new Promise<number>((resolve, reject) => {
          promptAction.showDialog({
            title: config.title,
            message: selected.length > 0
              ? `已选择: ${selected.join(', ')}\n继续选择或点击"完成选择"`
              : config.message || '请选择选项',
            buttons: dialogOptions.map(opt => ({ text: opt, color: '#000000' }))
          }).then((res) => resolve(res.index))
            .catch((err) => reject(err));
        });

        if (result === dialogOptions.length - 1) {
          // 用户点击了"完成选择"
          break;
        }

        selected.push(remainingOptions[result]);
      } catch (error) {
        Logger.error('DialogEventBus', 'Fallback multi-select failed', error as Error);
        break;
      }
    }

    return selected;
  }
}

/**
 * 用户交互对话框动作执行器
 */
export class UserDialogAction implements IActionExecutor {
  private dialogEventBus: DialogEventBus;

  constructor() {
    this.dialogEventBus = DialogEventBus.getInstance();
  }

  async execute(action: Action, context: ExecutionContext): Promise<void> {
    const config = JSON.parse(action.config) as UserDialogConfig;

    // 解析配置中的变量
    const parsedConfig = await this.parseConfig(config, context);

    Logger.info('UserDialogAction', `Showing user dialog: ${parsedConfig.type}`);

    try {
      let result: Object | undefined = undefined;

      switch (parsedConfig.type) {
        case 'confirm':
          result = await this.showConfirmDialog(parsedConfig);
          break;

        case 'single_select':
          result = await this.showSingleSelectDialog(parsedConfig);
          break;

        case 'multi_select':
          result = await this.showMultiSelectDialog(parsedConfig);
          break;

        case 'text_input':
          result = await this.showTextInputDialog(parsedConfig);
          break;

        default:
          throw new Error(`Unknown dialog type: ${parsedConfig.type}`);
      }

      // 保存用户输入到变量
      if (parsedConfig.saveToVariable && result !== undefined) {
        context.setVariable(parsedConfig.saveToVariable, result);
        Logger.info('UserDialogAction', `User input saved to variable: ${parsedConfig.saveToVariable} = ${JSON.stringify(result)}`);
      }

      Logger.info('UserDialogAction', 'User dialog completed successfully');

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('UserDialogAction', `User dialog failed: ${errorMessage}`);
      throw new Error(`用户对话框失败: ${errorMessage}`);
    }
  }

  /**
   * 解析配置中的变量
   */
  private async parseConfig(config: UserDialogConfig, context: ExecutionContext): Promise<UserDialogConfig> {
    return {
      ...config,
      title: await VariableParser.parse(config.title, context),
      message: config.message ? await VariableParser.parse(config.message, context) : undefined,
      placeholder: config.placeholder ? await VariableParser.parse(config.placeholder, context) : undefined,
      defaultValue: config.defaultValue ? await VariableParser.parse(config.defaultValue, context) : undefined
    };
  }

  /**
   * 显示确认对话框
   */
  private async showConfirmDialog(config: UserDialogConfig): Promise<boolean> {
    return new Promise((resolve, reject) => {
      promptAction.showDialog({
        title: config.title,
        message: config.message || '',
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '确定', color: '#007DFF' }
        ]
      }).then((result) => {
        // index 0 = 取消，1 = 确定
        resolve(result.index === 1);
      }).catch((error: Error) => {
        reject(error);
      });
    });
  }

  /**
   * 显示单选对话框
   */
  private async showSingleSelectDialog(config: UserDialogConfig): Promise<string> {
    if (!config.options || config.options.length === 0) {
      throw new Error('Options are required for single select dialog');
    }

    return new Promise((resolve, reject) => {
      promptAction.showDialog({
        title: config.title,
        message: config.message || '请选择一项',
        buttons: config.options.map((option) => ({ text: option, color: '#000000' }))
      }).then((result) => {
        const selectedOption = config.options![result.index];
        resolve(selectedOption);
      }).catch((error: Error) => {
        reject(error);
      });
    });
  }

  /**
   * 显示多选对话框
   * 使用 DialogEventBus 通知 UI 层显示 CustomDialog
   */
  private async showMultiSelectDialog(config: UserDialogConfig): Promise<string[]> {
    if (!config.options || config.options.length === 0) {
      throw new Error('Options are required for multi-select dialog');
    }

    Logger.info('UserDialogAction', `Showing multi-select dialog with ${config.options.length} options`);

    // 通过事件总线请求 UI 层显示多选对话框
    const selected = await this.dialogEventBus.showMultiSelect(config);

    Logger.info('UserDialogAction', `Multi-select result: ${selected.length} items selected`);
    return selected;
  }

  /**
   * 显示文本输入对话框
   * 使用 DialogEventBus 通知 UI 层显示 CustomDialog
   */
  private async showTextInputDialog(config: UserDialogConfig): Promise<string> {
    Logger.info('UserDialogAction', 'Showing text input dialog');

    // 通过事件总线请求 UI 层显示文本输入对话框
    const text = await this.dialogEventBus.showTextInput(config);

    Logger.info('UserDialogAction', `Text input result: ${text.length} characters`);
    return text;
  }
}
