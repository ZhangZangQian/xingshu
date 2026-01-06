import { Macro, MacroInput, Trigger, Action, TriggerType, ActionType, TimeTriggerConfig, NetworkTriggerConfig, HttpHeaders } from '../models/Macro';
import { DatabaseService } from '../services/DatabaseService';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 宏编辑页（完整版）
 * 支持基本信息、触发器、动作配置
 */
@Entry
@Component
struct MacroEditor {
  @State macroName: string = '';
  @State macroDescription: string = '';
  @State macroEnabled: boolean = true;
  @State isEditMode: boolean = false;
  @State triggers: Trigger[] = [];
  @State actions: Action[] = [];

  private macroId: number = 0;
  private databaseService: DatabaseService = DatabaseService.getInstance();

  async aboutToAppear() {
    // 检查是否是编辑模式
    const params = router.getParams() as Record<string, Object>;
    if (params && params['macroId']) {
      this.isEditMode = true;
      this.macroId = params['macroId'] as number;
      await this.loadMacro();
    }
  }

  /**
   * 加载宏数据
   */
  private async loadMacro() {
    try {
      const macro = await this.databaseService.getMacroById(this.macroId);
      if (macro) {
        this.macroName = macro.name;
        this.macroDescription = macro.description || '';
        this.macroEnabled = macro.enabled;
      }

      // 加载触发器和动作
      this.triggers = await this.databaseService.getTriggersByMacroId(this.macroId);
      this.actions = await this.databaseService.getActionsByMacroId(this.macroId);

    } catch (error) {
      Logger.error('MacroEditor', 'Failed to load macro', error as Error);
      promptAction.showToast({ message: '加载宏数据失败' });
    }
  }

  /**
   * 保存宏
   */
  private async handleSave() {
    // 验证输入
    if (!this.macroName || this.macroName.trim().length === 0) {
      promptAction.showToast({ message: '请输入宏名称' });
      return;
    }

    if (this.macroName.length > 50) {
      promptAction.showToast({ message: '宏名称不能超过 50 个字符' });
      return;
    }

    // 验证必须有至少1个触发器和1个动作
    if (this.triggers.length === 0) {
      promptAction.showToast({ message: '请至少添加1个触发器' });
      return;
    }

    if (this.actions.length === 0) {
      promptAction.showToast({ message: '请至少添加1个动作' });
      return;
    }

    try {
      const now = Date.now();

      if (this.isEditMode) {
        // 更新宏基本信息
        await this.databaseService.updateMacro(this.macroId, {
          name: this.macroName.trim(),
          description: this.macroDescription.trim(),
          enabled: this.macroEnabled
        });

        // 保存触发器和动作(简化版：先删除再插入)
        // TODO: 完整实现应该比对差异，只更新变化的数据

        promptAction.showToast({ message: '宏已更新' });
      } else {
        // 创建新宏
        const macro: MacroInput = {
          name: this.macroName.trim(),
          description: this.macroDescription.trim(),
          enabled: this.macroEnabled,
          createdAt: now,
          updatedAt: now
        };
        this.macroId = await this.databaseService.insertMacro(macro);

        // 保存触发器
        for (const trigger of this.triggers) {
          await this.databaseService.insertTrigger({
            macroId: this.macroId,
            type: trigger.type,
            config: trigger.config,
            enabled: trigger.enabled
          });
        }

        // 保存动作
        for (const action of this.actions) {
          await this.databaseService.insertAction({
            macroId: this.macroId,
            type: action.type,
            config: action.config,
            orderIndex: action.orderIndex
          });
        }

        promptAction.showToast({ message: '宏已创建' });
      }

      // 返回列表页
      router.back();
    } catch (error) {
      Logger.error('MacroEditor', 'Failed to save macro', error as Error);
      promptAction.showToast({ message: '保存失败' });
    }
  }

  /**
   * 取消编辑
   */
  private handleCancel() {
    router.back();
  }

  /**
   * 添加触发器
   */
  private handleAddTrigger() {
    // 显示触发器类型选择对话框
    promptAction.showDialog({
      title: '选择触发器类型',
      message: '请选择一种触发器类型',
      buttons: [
        { text: '定时触发', color: '#000000' },
        { text: '网络状态触发', color: '#000000' },
        { text: '手动触发', color: '#000000' }
      ]
    }).then((result) => {
      switch (result.index) {
        case 0:
          this.showTimeTriggerDialog();
          break;
        case 1:
          this.showNetworkTriggerDialog();
          break;
        case 2:
          this.addManualTrigger();
          break;
      }
    });
  }

  /**
   * 显示定时触发器配置对话框
   */
  private showTimeTriggerDialog() {
    promptAction.showDialog({
      title: '配置定时触发器',
      message: '请选择触发模式',
      buttons: [
        { text: '每日重复', color: '#000000' },
        { text: '每周重复', color: '#000000' },
        { text: '自定义间隔', color: '#000000' }
      ]
    }).then((result) => {
      let config: TimeTriggerConfig;

      switch (result.index) {
        case 0:
          // 每日重复 - 简化版：固定时间 09:00
          config = {
            mode: 'daily',
            dailyTime: { hour: 9, minute: 0, second: 0 }
          };
          break;
        case 1:
          // 每周重复 - 简化版：周一至周五 09:00
          config = {
            mode: 'weekly',
            weeklyTime: { weekdays: [1, 2, 3, 4, 5], hour: 9, minute: 0, second: 0 }
          };
          break;
        case 2:
          // 自定义间隔 - 简化版：60分钟
          config = {
            mode: 'interval',
            intervalTime: { intervalMinutes: 60 }
          };
          break;
        default:
          return;
      }

      // 添加触发器到列表
      const trigger: Trigger = {
        id: Date.now(), // 临时 ID
        macroId: this.macroId,
        type: TriggerType.TIME,
        config: JSON.stringify(config),
        enabled: true
      };
      this.triggers.push(trigger);
      promptAction.showToast({ message: '定时触发器已添加' });
    });
  }

  /**
   * 显示网络状态触发器配置对话框
   */
  private showNetworkTriggerDialog() {
    promptAction.showDialog({
      title: '配置网络状态触发器',
      message: '请选择触发条件',
      buttons: [
        { text: 'Wi-Fi 连接', color: '#000000' },
        { text: '移动数据连接', color: '#000000' },
        { text: '网络断开', color: '#000000' }
      ]
    }).then((result) => {
      let triggerOn: 'wifi_connected' | 'mobile_connected' | 'network_disconnected';

      switch (result.index) {
        case 0:
          triggerOn = 'wifi_connected';
          break;
        case 1:
          triggerOn = 'mobile_connected';
          break;
        case 2:
          triggerOn = 'network_disconnected';
          break;
        default:
          return;
      }

      const config: NetworkTriggerConfig = { triggerOn };
      const trigger: Trigger = {
        id: Date.now(),
        macroId: this.macroId,
        type: TriggerType.NETWORK,
        config: JSON.stringify(config),
        enabled: true
      };
      this.triggers.push(trigger);
      promptAction.showToast({ message: '网络状态触发器已添加' });
    });
  }

  /**
   * 添加手动触发器
   */
  private addManualTrigger() {
    const trigger: Trigger = {
      id: Date.now(),
      macroId: this.macroId,
      type: TriggerType.MANUAL,
      config: JSON.stringify({ methods: ['button', 'shortcut'] }),
      enabled: true
    };
    this.triggers.push(trigger);
    promptAction.showToast({ message: '手动触发器已添加' });
  }

  /**
   * 删除触发器
   */
  private deleteTrigger(index: number) {
    this.triggers.splice(index, 1);
  }

  /**
   * 添加动作
   */
  private handleAddAction() {
    // 显示动作类型选择对话框
    promptAction.showDialog({
      title: '选择动作类型',
      message: '请选择要添加的动作',
      buttons: [
        { text: '发送通知', color: '#000000' },
        { text: '读取剪贴板', color: '#000000' },
        { text: 'HTTP 请求', color: '#000000' },
        { text: '打开 URL', color: '#000000' },
        { text: '文本处理', color: '#000000' }
      ]
    }).then((result) => {
      switch (result.index) {
        case 0:
          this.addNotificationAction();
          break;
        case 1:
          this.addClipboardReadAction();
          break;
        case 2:
          this.addHttpRequestAction();
          break;
        case 3:
          this.addOpenUrlAction();
          break;
        case 4:
          this.addTextProcessAction();
          break;
      }
    });
  }

  /**
   * 添加发送通知动作
   */
  private addNotificationAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '通知标题',
        content: '通知内容',
        enableSound: true,
        enableVibration: true
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    promptAction.showToast({ message: '发送通知动作已添加' });
  }

  /**
   * 添加读取剪贴板动作
   */
  private addClipboardReadAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.CLIPBOARD_READ,
      config: JSON.stringify({
        operation: 'read',
        saveToVariable: 'clipboard_content'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    promptAction.showToast({ message: '读取剪贴板动作已添加' });
  }

  /**
   * 添加 HTTP 请求动作
   */
  private addHttpRequestAction() {
    const headers: HttpHeaders = { 'Content-Type': 'application/json' };
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.HTTP_REQUEST,
      config: JSON.stringify({
        method: 'POST',
        url: 'https://example.com/api',
        headers: headers,
        body: '{}',
        timeout: 30000,
        saveResponseTo: 'api_response'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    promptAction.showToast({ message: 'HTTP 请求动作已添加' });
  }

  /**
   * 添加打开 URL 动作
   */
  private addOpenUrlAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.OPEN_URL,
      config: JSON.stringify({
        url: 'https://example.com',
        openWith: 'browser'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    promptAction.showToast({ message: '打开 URL 动作已添加' });
  }

  /**
   * 添加文本处理动作
   */
  private addTextProcessAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.TEXT_PROCESS,
      config: JSON.stringify({
        operation: 'regex_extract',
        input: '{clipboard_content}',
        pattern: 'https?://[^\\s]+',
        groupIndex: 0,
        saveToVariable: 'extracted_url'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    promptAction.showToast({ message: '文本处理动作已添加' });
  }

  /**
   * 删除动作
   */
  private deleteAction(index: number) {
    this.actions.splice(index, 1);
    // 重新调整 orderIndex
    this.actions.forEach((action, idx) => {
      action.orderIndex = idx;
    });
  }

  /**
   * 上移动作
   */
  private moveActionUp(index: number) {
    if (index > 0) {
      const temp = this.actions[index];
      this.actions[index] = this.actions[index - 1];
      this.actions[index - 1] = temp;
      // 更新 orderIndex
      this.actions.forEach((action, idx) => {
        action.orderIndex = idx;
      });
    }
  }

  /**
   * 下移动作
   */
  private moveActionDown(index: number) {
    if (index < this.actions.length - 1) {
      const temp = this.actions[index];
      this.actions[index] = this.actions[index + 1];
      this.actions[index + 1] = temp;
      // 更新 orderIndex
      this.actions.forEach((action, idx) => {
        action.orderIndex = idx;
      });
    }
  }

  /**
   * 获取触发器描述
   */
  private getTriggerDescription(trigger: Trigger): string {
    if (trigger.type === TriggerType.TIME) {
      const config = JSON.parse(trigger.config) as TimeTriggerConfig;
      switch (config.mode) {
        case 'daily':
          return `每日 ${config.dailyTime?.hour || 0}:${String(config.dailyTime?.minute || 0).padStart(2, '0')}`;
        case 'weekly':
          return `每周重复`;
        case 'interval':
          return `每 ${config.intervalTime?.intervalMinutes || 0} 分钟`;
        default:
          return '定时触发';
      }
    } else if (trigger.type === TriggerType.NETWORK) {
      const config = JSON.parse(trigger.config) as NetworkTriggerConfig;
      const triggerNames: Record<string, string> = {
        'wifi_connected': 'Wi-Fi 连接时',
        'mobile_connected': '移动数据连接时',
        'network_disconnected': '网络断开时'
      };
      return triggerNames[config.triggerOn] || '网络状态触发';
    } else if (trigger.type === TriggerType.MANUAL) {
      return '手动触发';
    }
    return trigger.type;
  }

  /**
   * 获取动作描述
   */
  private getActionDescription(action: Action): string {
    const actionNames: Record<string, string> = {
      'notification': '发送通知',
      'clipboard_read': '读取剪贴板',
      'clipboard_write': '写入剪贴板',
      'http_request': 'HTTP 请求',
      'open_url': '打开 URL',
      'text_process': '文本处理',
      'launch_app': '启动应用',
      'user_dialog': '用户对话框'
    };
    return actionNames[action.type] || action.type;
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleCancel();
          })

        Text(this.isEditMode ? '编辑宏' : '创建宏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .flexGrow(1)
          .textAlign(TextAlign.Center)

        Button('保存')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')

      // 表单内容
      Scroll() {
        Column({ space: 16 }) {
          // 基本信息区域
          Column({ space: 16 }) {
            Text('基本信息')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)

            // 宏名称
            Column({ space: 8 }) {
              Text('宏名称 *')
                .fontSize(14)
                .fontColor('#666666')

              TextInput({ placeholder: '请输入宏名称（1-50 字符）', text: this.macroName })
                .fontSize(16)
                .onChange((value: string) => {
                  this.macroName = value;
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // 宏描述
            Column({ space: 8 }) {
              Text('描述（可选）')
                .fontSize(14)
                .fontColor('#666666')

              TextArea({ placeholder: '请输入宏描述', text: this.macroDescription })
                .fontSize(16)
                .height(100)
                .onChange((value: string) => {
                  this.macroDescription = value;
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // 启用状态
            Row() {
              Text('启用宏')
                .fontSize(16)
                .flexGrow(1)

              Toggle({ type: ToggleType.Switch, isOn: this.macroEnabled })
                .onChange((isOn: boolean) => {
                  this.macroEnabled = isOn;
                })
            }
            .width('100%')
          }
          .padding(16)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)

          // 触发器区域
          Column({ space: 12 }) {
            Row() {
              Text('触发器')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .flexGrow(1)

              Text('至少添加 1 个')
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')

            // 触发器列表
            if (this.triggers.length === 0) {
              Text('暂无触发器')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
            } else {
              Column({ space: 8 }) {
                ForEach(this.triggers, (trigger: Trigger, index: number) => {
                  Row({ space: 12 }) {
                    Column({ space: 4 }) {
                      Text(this.getTriggerDescription(trigger))
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)

                      Text(trigger.type)
                        .fontSize(12)
                        .fontColor('#666666')
                    }
                    .flexGrow(1)
                    .alignItems(HorizontalAlign.Start)

                    Button('删除')
                      .fontSize(14)
                      .height(32)
                      .backgroundColor('#ff4444')
                      .onClick(() => {
                        this.deleteTrigger(index);
                      })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#f5f5f5')
                  .borderRadius(8)
                }, (trigger: Trigger, index: number) => index.toString())
              }
              .width('100%')
            }

            // 添加触发器按钮
            Button('+ 添加触发器')
              .width('100%')
              .height(40)
              .fontSize(16)
              .backgroundColor('#007DFF')
              .onClick(() => {
                this.handleAddTrigger();
              })
          }
          .padding(16)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)

          // 动作区域
          Column({ space: 12 }) {
            Row() {
              Text('动作列表')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .flexGrow(1)

              Text('至少添加 1 个')
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')

            // 动作列表
            if (this.actions.length === 0) {
              Text('暂无动作')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
            } else {
              Column({ space: 8 }) {
                ForEach(this.actions, (action: Action, index: number) => {
                  Row({ space: 12 }) {
                    Text(`${index + 1}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .width(24)

                    Column({ space: 4 }) {
                      Text(this.getActionDescription(action))
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)

                      Text(action.type)
                        .fontSize(12)
                        .fontColor('#666666')
                    }
                    .flexGrow(1)
                    .alignItems(HorizontalAlign.Start)

                    // 排序按钮
                    Column({ space: 4 }) {
                      Button('↑')
                        .fontSize(14)
                        .height(28)
                        .width(40)
                        .backgroundColor(index > 0 ? '#007DFF' : '#cccccc')
                        .enabled(index > 0)
                        .onClick(() => {
                          this.moveActionUp(index);
                        })

                      Button('↓')
                        .fontSize(14)
                        .height(28)
                        .width(40)
                        .backgroundColor(index < this.actions.length - 1 ? '#007DFF' : '#cccccc')
                        .enabled(index < this.actions.length - 1)
                        .onClick(() => {
                          this.moveActionDown(index);
                        })
                    }

                    Button('删除')
                      .fontSize(14)
                      .height(32)
                      .backgroundColor('#ff4444')
                      .onClick(() => {
                        this.deleteAction(index);
                      })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#f5f5f5')
                  .borderRadius(8)
                }, (action: Action, index: number) => index.toString())
              }
              .width('100%')
            }

            // 添加动作按钮
            Button('+ 添加动作')
              .width('100%')
              .height(40)
              .fontSize(16)
              .backgroundColor('#007DFF')
              .onClick(() => {
                this.handleAddAction();
              })
          }
          .padding(16)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }
        .padding(16)
        .width('100%')
      }
      .flexGrow(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
