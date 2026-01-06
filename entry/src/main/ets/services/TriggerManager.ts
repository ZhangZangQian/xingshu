import { Trigger, TriggerType, TimeTriggerConfig, NetworkTriggerConfig } from '../models/Macro';
import workScheduler from '@ohos.resourceschedule.workScheduler';
import Logger from '../utils/Logger';

/**
 * 触发器管理器
 * 核心职责：注册和管理各类触发器
 */
export class TriggerManager {
  private static instance: TriggerManager;
  private registeredTriggers: Map<number, workScheduler.WorkInfo>;  // triggerId -> WorkInfo
  private macroCallbacks: Map<number, (macroId: number, triggerType: string) => Promise<boolean>>;

  private constructor() {
    this.registeredTriggers = new Map();
    this.macroCallbacks = new Map();
  }

  public static getInstance(): TriggerManager {
    if (!TriggerManager.instance) {
      TriggerManager.instance = new TriggerManager();
    }
    return TriggerManager.instance;
  }

  /**
   * 注册触发器
   *
   * @param trigger 触发器配置
   * @param macroId 关联宏 ID
   * @param callback 触发回调函数
   */
  public async registerTrigger(
    trigger: Trigger,
    macroId: number,
    callback: (macroId: number, triggerType: string) => Promise<boolean>
  ): Promise<void> {
    Logger.info('TriggerManager', `Registering trigger ${trigger.id} (type: ${trigger.type}) for macro ${macroId}`);

    // 保存回调函数
    this.macroCallbacks.set(macroId, callback);

    switch (trigger.type) {
      case TriggerType.TIME:
        await this.registerTimeTrigger(trigger, macroId);
        break;
      case TriggerType.NETWORK:
        await this.registerNetworkTrigger(trigger, macroId);
        break;
      case TriggerType.MANUAL:
        // 手动触发器不需要注册后台任务
        Logger.info('TriggerManager', 'Manual trigger does not require background task');
        break;
      case TriggerType.CLIPBOARD:
        // 剪贴板触发器（手动触发时读取）
        Logger.info('TriggerManager', 'Clipboard trigger is handled manually');
        break;
      default:
        Logger.warn('TriggerManager', `Unknown trigger type: ${trigger.type}`);
    }
  }

  /**
   * 注册定时触发器
   */
  private async registerTimeTrigger(trigger: Trigger, macroId: number): Promise<void> {
    try {
      const config = JSON.parse(trigger.config) as TimeTriggerConfig;

      let workInfo: workScheduler.WorkInfo = {
        workId: trigger.id,  // 使用 trigger.id 作为 workId
        bundleName: 'com.example.harmonymacro',  // TODO: 替换为实际包名
        abilityName: 'TriggerBackgroundAbility',
        parameters: {
          macroId: macroId,
          triggerType: 'time'
        }
      };

      // 根据不同模式设置触发条件
      switch (config.mode) {
        case 'once':
          // 一次性定时
          if (config.timestamp) {
            const delay = config.timestamp - Date.now();
            if (delay > 0) {
              workInfo.repeatCycleTime = 0;  // 不重复
              workInfo.isRepeat = false;
              Logger.info('TriggerManager', `Once trigger will fire in ${Math.round(delay / 1000)} seconds`);
            } else {
              Logger.warn('TriggerManager', `Trigger ${trigger.id} timestamp is in the past, skipping`);
              return;
            }
          }
          break;

        case 'daily':
          // 每日重复
          if (config.dailyTime) {
            const nextTriggerTime = this.calculateDailyNextTrigger(config.dailyTime);
            const delay = nextTriggerTime - Date.now();

            workInfo.repeatCycleTime = 24 * 60 * 60 * 1000;  // 24 小时
            workInfo.isRepeat = true;

            const nextDate = new Date(nextTriggerTime);
            Logger.info('TriggerManager', `Daily trigger will fire at ${nextDate.toLocaleString()}, delay: ${Math.round(delay / 1000)} seconds`);
          }
          break;

        case 'weekly':
          // 每周重复
          if (config.weeklyTime) {
            const nextTriggerTime = this.calculateWeeklyNextTrigger(config.weeklyTime);
            const delay = nextTriggerTime - Date.now();

            workInfo.repeatCycleTime = 7 * 24 * 60 * 60 * 1000;  // 7 天
            workInfo.isRepeat = true;

            const nextDate = new Date(nextTriggerTime);
            Logger.info('TriggerManager', `Weekly trigger will fire at ${nextDate.toLocaleString()}, delay: ${Math.round(delay / 1000)} seconds`);
          }
          break;

        case 'interval':
          // 自定义间隔
          if (config.intervalTime) {
            workInfo.repeatCycleTime = config.intervalTime.intervalMinutes * 60 * 1000;
            workInfo.isRepeat = true;
            Logger.info('TriggerManager', `Interval trigger will fire every ${config.intervalTime.intervalMinutes} minutes`);
          }
          break;
      }

      workScheduler.startWork(workInfo);
      this.registeredTriggers.set(trigger.id, workInfo);
      Logger.info('TriggerManager', `Time trigger ${trigger.id} registered successfully`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('TriggerManager', `Failed to register time trigger: ${errorMessage}`);
      throw new Error(`注册定时触发器失败: ${errorMessage}`);
    }
  }

  /**
   * 计算每日定时的下一次触发时间
   */
  private calculateDailyNextTrigger(dailyTime: { hour: number; minute: number; second: number }): number {
    const now = new Date();
    const nextTrigger = new Date();

    // 设置目标时间
    nextTrigger.setHours(dailyTime.hour, dailyTime.minute, dailyTime.second, 0);

    // 如果今天的目标时间已过，延迟到明天
    if (nextTrigger.getTime() <= now.getTime()) {
      nextTrigger.setDate(nextTrigger.getDate() + 1);
    }

    return nextTrigger.getTime();
  }

  /**
   * 计算每周定时的下一次触发时间
   */
  private calculateWeeklyNextTrigger(weeklyTime: { weekdays: number[]; hour: number; minute: number; second: number }): number {
    const now = new Date();
    const currentWeekday = now.getDay();  // 0 = 周日, 1 = 周一, ..., 6 = 周六

    // 找出最近的触发星期几
    let minDaysUntil = 7;
    for (const targetWeekday of weeklyTime.weekdays) {
      let daysUntil = (targetWeekday - currentWeekday + 7) % 7;

      // 如果是今天，检查时间是否已过
      if (daysUntil === 0) {
        const todayTrigger = new Date();
        todayTrigger.setHours(weeklyTime.hour, weeklyTime.minute, weeklyTime.second, 0);

        if (todayTrigger.getTime() <= now.getTime()) {
          // 今天的时间已过，下次是下周同一天
          daysUntil = 7;
        }
      }

      if (daysUntil < minDaysUntil) {
        minDaysUntil = daysUntil;
      }
    }

    const nextTrigger = new Date();
    nextTrigger.setDate(nextTrigger.getDate() + minDaysUntil);
    nextTrigger.setHours(weeklyTime.hour, weeklyTime.minute, weeklyTime.second, 0);

    return nextTrigger.getTime();
  }

  /**
   * 注册网络状态触发器
   */
  private async registerNetworkTrigger(trigger: Trigger, macroId: number): Promise<void> {
    try {
      const config = JSON.parse(trigger.config) as NetworkTriggerConfig;

      let networkType: workScheduler.NetworkType;
      switch (config.triggerOn) {
        case 'wifi_connected':
          networkType = workScheduler.NetworkType.NETWORK_TYPE_WIFI;
          break;
        case 'mobile_connected':
          networkType = workScheduler.NetworkType.NETWORK_TYPE_MOBILE;
          break;
        case 'wifi_disconnected':
        case 'network_disconnected':
          networkType = workScheduler.NetworkType.NETWORK_TYPE_ANY;
          break;
        default:
          networkType = workScheduler.NetworkType.NETWORK_TYPE_ANY;
      }

      const workInfo: workScheduler.WorkInfo = {
        workId: trigger.id,
        bundleName: 'com.example.harmonymacro',
        abilityName: 'TriggerBackgroundAbility',
        networkType: networkType,
        parameters: {
          macroId: macroId,
          triggerType: 'network',
          triggerOn: config.triggerOn
        }
      };

      workScheduler.startWork(workInfo);
      this.registeredTriggers.set(trigger.id, workInfo);
      Logger.info('TriggerManager', `Network trigger ${trigger.id} registered successfully`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('TriggerManager', `Failed to register network trigger: ${errorMessage}`);
      throw new Error(`注册网络触发器失败: ${errorMessage}`);
    }
  }

  /**
   * 取消注册宏的所有触发器
   */
  public async unregisterMacroTriggers(macroId: number): Promise<void> {
    Logger.info('TriggerManager', `Unregistering triggers for macro ${macroId}`);

    // 遍历所有已注册触发器，找到属于该宏的触发器
    const triggerIdsToRemove: number[] = [];
    for (const [triggerId, workInfo] of this.registeredTriggers.entries()) {
      if (workInfo.parameters?.macroId === macroId) {
        await this.unregisterTrigger(triggerId);
        triggerIdsToRemove.push(triggerId);
      }
    }

    // 清理回调
    this.macroCallbacks.delete(macroId);

    Logger.info('TriggerManager', `Unregistered ${triggerIdsToRemove.length} triggers for macro ${macroId}`);
  }

  /**
   * 取消注册单个触发器
   */
  private async unregisterTrigger(triggerId: number): Promise<void> {
    try {
      const workInfo = this.registeredTriggers.get(triggerId);
      if (workInfo) {
        workScheduler.stopWork(workInfo, false);
        this.registeredTriggers.delete(triggerId);
        Logger.info('TriggerManager', `Trigger ${triggerId} unregistered successfully`);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('TriggerManager', `Failed to unregister trigger ${triggerId}: ${errorMessage}`);
    }
  }

  /**
   * 触发宏执行（由后台任务回调）
   */
  public async triggerMacro(macroId: number, triggerType: string): Promise<void> {
    Logger.info('TriggerManager', `Triggering macro ${macroId} with type ${triggerType}`);

    const callback = this.macroCallbacks.get(macroId);
    if (callback) {
      try {
        await callback(macroId, triggerType);
      } catch (error) {
        Logger.error('TriggerManager', `Failed to execute macro ${macroId}`, error as Error);
      }
    } else {
      Logger.warn('TriggerManager', `No callback registered for macro ${macroId}`);
    }
  }
}
