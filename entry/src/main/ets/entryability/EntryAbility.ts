import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import { MacroEngine } from '../services/MacroEngine';
import { ActionExecutor } from '../services/ActionExecutor';
import { LaunchAppAction } from '../services/actions/LaunchAppAction';
import { NotificationAction } from '../services/actions/NotificationAction';
import { HttpRequestAction } from '../services/actions/HttpRequestAction';
import { ClipboardAction } from '../services/actions/ClipboardAction';
import { OpenUrlAction } from '../services/actions/OpenUrlAction';
import { TextProcessAction } from '../services/actions/TextProcessAction';
import { UserDialogAction } from '../services/actions/UserDialogAction';
import { SetVariableAction } from '../services/actions/SetVariableAction';
import { IfElseAction } from '../services/actions/IfElseAction';
import { JsonProcessAction } from '../services/actions/JsonProcessAction';
import { ActionType } from '../models/Macro';
import { Action } from '@ohos.multimodalInput.touchEvent';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Ability onCreate');

    // 检查是否从快捷方式启动（手动触发宏）
    if (want.parameters && want.parameters.macroId) {
      const macroId = want.parameters.macroId as number;
      hilog.info(0x0000, 'EntryAbility', 'Triggered by shortcut, macroId: %{public}d', macroId);

      // 延迟执行宏（等待初始化完成）
      setTimeout(async () => {
        try {
          const macroEngine = MacroEngine.getInstance();
          await macroEngine.manualTrigger(macroId);
        } catch (error) {
          hilog.error(0x0000, 'EntryAbility', 'Failed to trigger macro: %{public}s', error.message);
        }
      }, 1000);
    }
  }

  onDestroy() {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Ability onWindowStageCreate');

    // 先初始化应用
    await this.initializeApp();

    // 初始化完成后再加载页面
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'EntryAbility', 'Failed to load content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'EntryAbility', 'Succeeded in loading content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy() {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    hilog.info(0x0000, 'EntryAbility', '%{public}s', 'Ability onBackground');
  }

  /**
   * 初始化应用
   */
  private async initializeApp() {
    try {
      hilog.info(0x0000, 'EntryAbility', 'Initializing app...');

      // 1. 初始化宏引擎
      const macroEngine = MacroEngine.getInstance();
      await macroEngine.initialize(this.context);

      // 2. 注册所有动作执行器
      const actionExecutor = ActionExecutor.getInstance();

      // 注册需要 Context 的动作执行器
      const launchAppAction = new LaunchAppAction();
      launchAppAction.setContext(this.context);
      actionExecutor.registerExecutor(ActionType.LAUNCH_APP, launchAppAction);

      const openUrlAction = new OpenUrlAction();
      openUrlAction.setContext(this.context);
      actionExecutor.registerExecutor(ActionType.OPEN_URL, openUrlAction);

      // 注册其他动作执行器
      actionExecutor.registerExecutor(ActionType.NOTIFICATION, new NotificationAction());
      actionExecutor.registerExecutor(ActionType.HTTP_REQUEST, new HttpRequestAction());
      actionExecutor.registerExecutor(ActionType.CLIPBOARD_READ, new ClipboardAction());
      actionExecutor.registerExecutor(ActionType.CLIPBOARD_WRITE, new ClipboardAction());
      actionExecutor.registerExecutor(ActionType.TEXT_PROCESS, new TextProcessAction());
      actionExecutor.registerExecutor(ActionType.USER_DIALOG, new UserDialogAction());
      actionExecutor.registerExecutor(ActionType.SET_VARIABLE, new SetVariableAction());
      actionExecutor.registerExecutor(ActionType.IF_ELSE, new IfElseAction());
      actionExecutor.registerExecutor(ActionType.JSON_PROCESS, new JsonProcessAction());

      hilog.info(0x0000, 'EntryAbility', 'App initialized successfully');
    } catch (error) {
      hilog.error(0x0000, 'EntryAbility', 'Failed to initialize app: %{public}s', error.message);
    }
  }
}
