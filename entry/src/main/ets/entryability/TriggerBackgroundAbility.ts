import WorkSchedulerExtensionAbility from '@ohos.WorkSchedulerExtensionAbility';
import workScheduler from '@ohos.resourceschedule.workScheduler';
import hilog from '@ohos.hilog';
import { TriggerManager } from '../services/TriggerManager';

/**
 * 后台触发器 Ability
 * 处理 Work Scheduler 的回调
 */
export default class TriggerBackgroundAbility extends WorkSchedulerExtensionAbility {
  /**
   * Work Scheduler 任务开始回调
   */
  onWorkStart(workInfo: workScheduler.WorkInfo) {
    hilog.info(0x0000, 'TriggerBackgroundAbility', 'Work started: %{public}d', workInfo.workId);

    try {
      const macroId = workInfo.parameters?.macroId as number;
      const triggerType = workInfo.parameters?.triggerType as string;

      if (!macroId || !triggerType) {
        hilog.error(0x0000, 'TriggerBackgroundAbility', 'Invalid work parameters');
        return;
      }

      // 触发宏执行
      const triggerManager = TriggerManager.getInstance();
      triggerManager.triggerMacro(macroId, triggerType);

    } catch (error) {
      hilog.error(0x0000, 'TriggerBackgroundAbility', 'Failed to start work: %{public}s', error.message);
    }
  }

  /**
   * Work Scheduler 任务停止回调
   */
  onWorkStop(workInfo: workScheduler.WorkInfo) {
    hilog.info(0x0000, 'TriggerBackgroundAbility', 'Work stopped: %{public}d', workInfo.workId);
  }
}
