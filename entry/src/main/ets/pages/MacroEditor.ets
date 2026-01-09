import { Macro, MacroInput, Trigger, Action, TriggerType, ActionType, TimeTriggerConfig, NetworkTriggerConfig, HttpHeaders } from '../models/Macro';
import { Variable, VariableScope, VariableType } from '../models/Variable';
import { ActionViewModel, ActionViewModelFactory } from '../models/ActionViewModel';
import { DatabaseService } from '../services/DatabaseService';
import { VariableFlowAnalyzer } from '../utils/VariableFlowAnalyzer';
import { ActionConfigSummaryGenerator } from '../utils/ActionConfigSummaryGenerator';
import { VariableNameRecommender } from '../utils/VariableNameRecommender';
import { ActionConfigEditor } from '../components/ActionConfigEditor';
import { VariableOption } from '../components/VariableSelector';
import { CommonTopBar, TopBarConfig } from '../components/CommonTopBar';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 宏编辑页（完整版）
 * 支持基本信息、触发器、动作、变量配置
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
  @State actionViewModels: ActionViewModel[] = []; // 动作视图模型
  @State highlightedVariable: string = ''; // 当前高亮的变量名
  @State variables: Variable[] = [];
  @State showVariableEditor: boolean = false;
  @State isVariableEditMode: boolean = false;
  @State editingVariableIndex: number = -1;
  @State varEditorName: string = '';
  @State varEditorType: VariableType = VariableType.STRING;
  @State varEditorValue: string = '';

  // 动作配置编辑器状态
  @State showActionConfigEditor: boolean = false;
  @State editingAction: Action | null = null;
  @State editingActionIndex: number = -1;
  @State availableVariablesForEditor: VariableOption[] = [];

  // 动作配置编辑器对话框控制器
  private actionConfigDialogController: CustomDialogController | null = null;

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

      // 加载触发器、动作和变量
      this.triggers = await this.databaseService.getTriggersByMacroId(this.macroId);
      this.actions = await this.databaseService.getActionsByMacroId(this.macroId);
      this.variables = await this.databaseService.getVariablesByMacroId(this.macroId);

      // 更新动作视图模型
      this.updateActionViewModels();

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
        Logger.info('MacroEditor', `Saving macro ${this.macroId} in edit mode`);

        // 更新宏基本信息
        await this.databaseService.updateMacro(this.macroId, {
          name: this.macroName.trim(),
          description: this.macroDescription.trim(),
          enabled: this.macroEnabled
        });

        Logger.info('MacroEditor', 'Macro basic info updated');

        // 保存触发器和动作（先删除再插入）
        // 1. 删除所有旧的触发器、动作、变量
        await this.databaseService.deleteTriggersByMacroId(this.macroId);
        await this.databaseService.deleteActionsByMacroId(this.macroId);
        await this.databaseService.deleteVariablesByMacroId(this.macroId);

        Logger.info('MacroEditor', 'Old triggers, actions, variables deleted');

        // 2. 重新插入触发器
        for (const trigger of this.triggers) {
          await this.databaseService.insertTrigger({
            macroId: this.macroId,
            type: trigger.type,
            config: trigger.config,
            enabled: trigger.enabled
          });
        }

        Logger.info('MacroEditor', `Inserted ${this.triggers.length} triggers`);

        // 3. 重新插入动作
        for (const action of this.actions) {
          await this.databaseService.insertAction({
            macroId: this.macroId,
            type: action.type,
            config: action.config,
            orderIndex: action.orderIndex
          });
        }

        Logger.info('MacroEditor', `Inserted ${this.actions.length} actions`);

        // 4. 重新插入变量
        for (const variable of this.variables) {
          await this.databaseService.insertVariable({
            scope: VariableScope.MACRO,
            macroId: this.macroId,
            name: variable.name,
            type: variable.type,
            value: variable.value,
            createdAt: now,
            updatedAt: now
          });
        }

        Logger.info('MacroEditor', `Inserted ${this.variables.length} variables`);

        promptAction.showToast({ message: '宏已更新' });
      } else {
        Logger.info('MacroEditor', 'Creating new macro');

        // 创建新宏
        const macro: MacroInput = {
          name: this.macroName.trim(),
          description: this.macroDescription.trim(),
          enabled: this.macroEnabled,
          createdAt: now,
          updatedAt: now
        };
        this.macroId = await this.databaseService.insertMacro(macro);

        Logger.info('MacroEditor', `Macro created with ID: ${this.macroId}`);

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

        // 保存变量
        for (const variable of this.variables) {
          await this.databaseService.insertVariable({
            scope: VariableScope.MACRO,
            macroId: this.macroId,
            name: variable.name,
            type: variable.type,
            value: variable.value,
            createdAt: now,
            updatedAt: now
          });
        }

        promptAction.showToast({ message: '宏已创建' });
      }

      // 返回列表页
      router.back();
    } catch (error) {
      Logger.error('MacroEditor', 'Failed to save macro', error as Error);
      promptAction.showToast({ message: `保存失败: ${error.message}` });
    }
  }

  /**
   * 取消编辑
   */
  private handleCancel() {
    router.back();
  }

  /**
   * c
   * 分析变量流向并生成配置摘要
   */
  private updateActionViewModels() {
    Logger.info('MacroEditor', `Updating action view models, actions count: ${this.actions.length}`);

    // 创建新的视图模型数组（确保引用变化以触发 UI 更新）
    const newViewModels: ActionViewModel[] = this.actions.map((action, index) => {
      Logger.info('MacroEditor', `Processing action ${index}, config: ${action.config}`);

      // 获取之前已定义的变量
      const definedVars = VariableFlowAnalyzer.getDefinedVariablesBeforeAction(
        this.actions,
        index,
        this.variables
      );

      // 验证动作配置
      const validationResult = VariableFlowAnalyzer.validateAction(
        action,
        index,
        definedVars
      );

      // 提取输入/输出变量
      const inputVars = ActionConfigSummaryGenerator.extractInputVariables(action);
      const outputVar = ActionConfigSummaryGenerator.extractOutputVariable(action);

      // 生成配置摘要
      const summary = ActionConfigSummaryGenerator.generate(action);
      Logger.info('MacroEditor', `Generated summary for action ${index}: ${summary}`);

      return ActionViewModelFactory.create(
        action,
        inputVars,
        outputVar,
        summary,
        validationResult.isValid,
        validationResult.errors
      );
    });

    // 使用新数组替换以触发 @State 响应式更新
    this.actionViewModels = newViewModels;
    Logger.info('MacroEditor', `View models updated, new count: ${this.actionViewModels.length}`);
  }

  /**
   * 处理变量点击，切换高亮状态
   */
  private handleVariableClick(varName: string) {
    if (this.highlightedVariable === varName) {
      // 如果点击的是已高亮的变量，取消高亮
      this.highlightedVariable = '';
    } else {
      // 否则高亮该变量
      this.highlightedVariable = varName;
    }
  }

  /**
   * 准备可用变量列表
   * @param actionIndex 当前编辑的动作索引
   */
  private prepareAvailableVariables(actionIndex: number) {
    this.availableVariablesForEditor = [];

    // 1. 添加系统变量
    const systemVars: VariableOption[] = [
      {
        name: 'date',
        displayName: '{date}',
        type: 'system',
        description: '当前日期 (YYYY-MM-DD)'
      },
      {
        name: 'time',
        displayName: '{time}',
        type: 'system',
        description: '当前时间 (HH:mm:ss)'
      },
      {
        name: 'timestamp',
        displayName: '{timestamp}',
        type: 'system',
        description: '当前时间戳'
      },
      {
        name: 'clipboard',
        displayName: '{clipboard}',
        type: 'system',
        description: '系统剪贴板内容'
      },
      {
        name: 'network_type',
        displayName: '{network_type}',
        type: 'system',
        description: '网络类型 (wifi/mobile)'
      },
      {
        name: 'battery_level',
        displayName: '{battery_level}',
        type: 'system',
        description: '电池电量百分比'
      }
    ];
    this.availableVariablesForEditor.push(...systemVars);

    // 2. 添加宏变量
    this.variables.forEach(variable => {
      this.availableVariablesForEditor.push({
        name: variable.name,
        displayName: `{${variable.name}}`,
        type: 'macro',
        description: `宏变量 (${this.getVariableTypeLabel(variable.type)})`
      });
    });

    // 3. 添加之前动作输出的变量
    for (let i = 0; i < actionIndex; i++) {
      const outputVar = ActionConfigSummaryGenerator.extractOutputVariable(this.actions[i]);
      if (outputVar) {
        const summary = ActionConfigSummaryGenerator.generate(this.actions[i]);
        this.availableVariablesForEditor.push({
          name: outputVar,
          displayName: `{${outputVar}}`,
          type: 'runtime',
          description: `来自动作 ${i + 1}: ${summary}`,
          sourceActionIndex: i
        });
      }
    }
  }

  /**
   * 编辑动作
   */
  private handleEditAction(index: number) {
    Logger.info('MacroEditor', `Opening action editor for index ${index}`);

    // 准备可用变量
    this.prepareAvailableVariables(index);

    // 设置编辑状态
    this.editingActionIndex = index;

    // 深拷贝动作对象（确保每次都是新对象引用）
    this.editingAction = JSON.parse(JSON.stringify(this.actions[index])) as Action;
    Logger.info('MacroEditor', `Editing action: ${JSON.stringify(this.editingAction)}`);

    // 销毁旧的对话框控制器（如果存在）
    if (this.actionConfigDialogController) {
      Logger.info('MacroEditor', 'Destroying old dialog controller');
      this.actionConfigDialogController = null;
    }

    // 创建新的编辑器对话框
    this.actionConfigDialogController = new CustomDialogController({
      builder: ActionConfigEditor({
        action: this.editingAction!,
        isEditMode: true,
        availableVariables: this.availableVariablesForEditor,
        onSave: (updatedAction: Action) => {
          this.handleActionConfigSave(updatedAction);
        },
        onCancel: () => {
          this.handleActionConfigCancel();
        }
      }),
      autoCancel: false,
      customStyle: true
    });

    Logger.info('MacroEditor', 'Opening dialog');
    this.actionConfigDialogController.open();
  }

  /**
   * 保存动作配置（仅更新内存，不持久化到数据库）
   */
  private handleActionConfigSave(updatedAction: Action) {
    Logger.info('MacroEditor', `Saving action config at index ${this.editingActionIndex}`);
    Logger.info('MacroEditor', `Updated action ID: ${updatedAction.id}, config: ${updatedAction.config}`);

    if (this.editingActionIndex >= 0 && this.editingActionIndex < this.actions.length) {
      // 确保保留正确的 orderIndex
      updatedAction.orderIndex = this.editingActionIndex;

      // 更新动作配置 - 使用 slice() 创建新数组以触发响应式更新（ArkTS 兼容）
      const newActions: Action[] = this.actions.slice();
      newActions[this.editingActionIndex] = updatedAction;
      this.actions = newActions;

      Logger.info('MacroEditor', `Actions array updated, length: ${this.actions.length}`);
      Logger.info('MacroEditor', `Updated action at index ${this.editingActionIndex}, new config: ${this.actions[this.editingActionIndex].config}`);

      // 强制清空视图模型，然后更新（确保 ForEach 重新渲染）
      this.actionViewModels = [];

      // 使用 setTimeout 确保 UI 更新
      setTimeout(() => {
        this.updateActionViewModels();
        Logger.info('MacroEditor', `View models updated, length: ${this.actionViewModels.length}`);
      }, 10);

      promptAction.showToast({ message: '动作配置已更新（点击保存宏后生效）' });
    }

    // 关闭编辑器
    if (this.actionConfigDialogController) {
      this.actionConfigDialogController.close();
      this.actionConfigDialogController = null;
    }

    // 重置编辑状态
    this.editingAction = null;
    this.editingActionIndex = -1;
  }

  /**
   * 取消编辑动作配置
   */
  private handleActionConfigCancel() {
    // 关闭编辑器
    if (this.actionConfigDialogController) {
      this.actionConfigDialogController.close();
      this.actionConfigDialogController = null;
    }

    // 重置编辑状态
    this.editingAction = null;
    this.editingActionIndex = -1;
  }

  /**
   * 使用"快小红"流程模板
   * 快速创建小红书内容采集到飞书的完整流程
   */
  private applyKuaiXiaoHongTemplate() {
    promptAction.showDialog({
      title: '使用快小红模板',
      message: '将自动创建：\n1. 手动触发器\n2. 读取剪贴板\n3. 正则提取 URL\n4. 用户对话框（选择爆款标记）\n5. 用户对话框（选择分类标签）\n6. HTTP POST 请求\n7. 打开飞书表格\n\n是否继续？',
      buttons: [
        { text: '取消', color: '#000000' },
        { text: '创建', color: '#007DFF' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.createKuaiXiaoHongTemplate();
      }
    });
  }

  /**
   * 创建快小红流程模板
   * 参考 docs/快小红宏流程完整解析.md
   */
  private createKuaiXiaoHongTemplate() {
    // 1. 添加手动触发器
    const manualTrigger: Trigger = {
      id: Date.now(),
      macroId: this.macroId,
      type: TriggerType.MANUAL,
      config: JSON.stringify({ methods: ['button', 'shortcut'] }),
      enabled: true
    };
    this.triggers.push(manualTrigger);

    // 2. 发送通知 - 启动提示
    const startNotificationAction: Action = {
      id: Date.now() + 1,
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '开始采集',
        content: '请按提示逐步操作',
        enableSound: false,
        enableVibration: false
      }),
      orderIndex: 0
    };
    this.actions.push(startNotificationAction);

    // 3. 读取剪贴板
    const clipboardAction: Action = {
      id: Date.now() + 2,
      macroId: this.macroId,
      type: ActionType.CLIPBOARD_READ,
      config: JSON.stringify({
        operation: 'read',
        saveToVariable: 'clipboard_content'
      }),
      orderIndex: 1
    };
    this.actions.push(clipboardAction);

    // 4. 正则提取 URL
    const textProcessAction: Action = {
      id: Date.now() + 3,
      macroId: this.macroId,
      type: ActionType.TEXT_PROCESS,
      config: JSON.stringify({
        operation: 'regex_extract',
        input: '{clipboard_content}',
        pattern: 'https?://[^\\s]+',
        groupIndex: 0,
        saveToVariable: 'extracted_url'
      }),
      orderIndex: 2
    };
    this.actions.push(textProcessAction);

    // 5. 用户对话框 - 选择爆款标记
    const qualityDialogAction: Action = {
      id: Date.now() + 4,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        dialogType: 'single_select',
        title: '🔥 请标记内容火爆程度',
        message: '请选择内容的质量等级',
        options: ['⚪ 普通款', '🟡 潜力款', '🔴 大爆款'],
        saveToVariable: 'quality'
      }),
      orderIndex: 3
    };
    this.actions.push(qualityDialogAction);

    // 6. 用户对话框 - 选择分类标签（40个选项）
    const labelDialogAction: Action = {
      id: Date.now() + 5,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        dialogType: 'single_select',
        title: '📑 请选择分类标签',
        message: '便于分类管理',
        options: [
          '💄时尚美妆', '🌍旅游出行', '🍜美食消费', '📚学习教育',
          '💹商业财经', '💼职场', '💴生米项目', '✨创意灵感',
          '📝干货分享', '⚙️效率工具', '🎁新奇好物', '🏠家居家装',
          '👶亲子母婴', '💖情感心理', '🏥医疗健康', '📺影视综艺',
          '🎵音乐', '📰时政社会', '🎨文学艺术', '🏛️人文历史',
          '🎭才艺技能', '📱科技数码', '📸摄影', '🎮游戏',
          '🚗汽车', '🎌二次元', '🏋️运动健身', '🔮星座命理',
          '📓生活记录', '🎯兴趣爱好', '❓其他', '🤖AI',
          '🍠小红书', '🎵抖音', '💬微信私域', '📺B站好物',
          '🎥视频号', '🪽飞书扣子', '▶️YouTube', '🎓在线课程'
        ],
        saveToVariable: 'label'
      }),
      orderIndex: 4
    };
    this.actions.push(labelDialogAction);

    // 7. 用户对话框 - 对标参考度评分
    const scoreDialogAction: Action = {
      id: Date.now() + 6,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        dialogType: 'single_select',
        title: '👍 请标记对标参考度',
        message: '1-5赞，0表示跳过',
        options: ['5 赞👍👍👍👍👍', '4 赞👍👍👍👍', '3 赞👍👍👍', '2 赞👍👍', '1 赞👍', '0 先不选，跳过'],
        saveToVariable: 'quality_score'
      }),
      orderIndex: 5
    };
    this.actions.push(scoreDialogAction);

    // 8. 用户对话框 - 备注说明输入
    const notesDialogAction: Action = {
      id: Date.now() + 7,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        dialogType: 'text_input',
        title: '📝 请输入收藏备注',
        message: '（选填）',
        placeholder: '输入备注内容...',
        saveToVariable: 'notes'
      }),
      orderIndex: 6
    };
    this.actions.push(notesDialogAction);

    // 9. 发送通知 - 上传进度
    const uploadNotificationAction: Action = {
      id: Date.now() + 8,
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '数据上传中',
        content: '请耐心等待...',
        enableSound: false,
        enableVibration: false
      }),
      orderIndex: 7
    };
    this.actions.push(uploadNotificationAction);

    // 10. HTTP POST 请求 - 调用 Coze API（笔记采集工作流）
    const headers: HttpHeaders = { 'Content-Type': 'application/json' };
    const httpAction: Action = {
      id: Date.now() + 9,
      macroId: this.macroId,
      type: ActionType.HTTP_REQUEST,
      config: JSON.stringify({
        method: 'POST',
        url: 'https://api.coze.cn/v1/workflow/run',
        headers: headers,
        body: '{"workflow_id":"7550495126771449906","parameters":{"url":"{extracted_url}","quality":"{quality_score}","read":"{quality}","notes":"{notes}","label":["{label}"],"xhscookie":""}}',
        timeout: 30000,
        saveResponseTo: 'api_response'
      }),
      orderIndex: 8
    };
    this.actions.push(httpAction);

    // 11. 文本处理 - 提取响应中的提示语
    const extractPromptAction: Action = {
      id: Date.now() + 10,
      macroId: this.macroId,
      type: ActionType.TEXT_PROCESS,
      config: JSON.stringify({
        operation: 'regex_extract',
        input: '{api_response}',
        pattern: '"prompt":"([^"]+)"',
        groupIndex: 1,
        saveToVariable: 'result_message'
      }),
      orderIndex: 9
    };
    this.actions.push(extractPromptAction);

    // 12. 发送通知 - 成功提示
    const successNotificationAction: Action = {
      id: Date.now() + 11,
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '✅ 采集成功',
        content: '{result_message}',
        enableSound: true,
        enableVibration: true
      }),
      orderIndex: 10
    };
    this.actions.push(successNotificationAction);

    // 13. 打开飞书多维表格
    const openUrlAction: Action = {
      id: Date.now() + 12,
      macroId: this.macroId,
      type: ActionType.OPEN_URL,
      config: JSON.stringify({
        url: 'https://applink.feishu.cn/client/docs/open?url=https://example.feishu.cn/base/xxx',
        openWith: 'browser'
      }),
      orderIndex: 11
    };
    this.actions.push(openUrlAction);

    // 14. 添加必需的全局变量（提示用户配置）
    this.variables.push({
      id: Date.now() + 100,
      scope: VariableScope.MACRO,
      macroId: this.macroId,
      name: '飞书多维表格授权码',
      type: VariableType.STRING,
      value: '',
      createdAt: Date.now(),
      updatedAt: Date.now()
    });

    this.variables.push({
      id: Date.now() + 101,
      scope: VariableScope.MACRO,
      macroId: this.macroId,
      name: '订单号',
      type: VariableType.STRING,
      value: '',
      createdAt: Date.now(),
      updatedAt: Date.now()
    });

    // 更新视图模型
    this.updateActionViewModels();

    promptAction.showDialog({
      title: '快小红模板创建成功',
      message: '已创建包含13个动作的完整采集流程。\n\n⚠️ 请在宏编辑页面配置以下必需变量：\n1. 飞书多维表格授权码\n2. 订单号\n\n然后将第10步的 body 中的授权码和订单号替换为 {飞书多维表格授权码} 和 {订单号}。',
      buttons: [
        { text: '知道了', color: '#007DFF' }
      ]
    });
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
        { text: '文本处理', color: '#000000' },
        { text: '设置变量', color: '#000000' },
        { text: '条件分支', color: '#000000' }
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
        case 5:
          this.addSetVariableAction();
          break;
        case 6:
          this.addIfElseAction();
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
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: '发送通知动作已添加' });
  }

  /**
   * 添加读取剪贴板动作
   */
  private addClipboardReadAction() {
    // 获取已存在的变量名
    const existingVars = VariableNameRecommender.extractExistingVariableNames(
      this.actions,
      this.variables
    );

    // 推荐变量名
    const recommendedName = VariableNameRecommender.recommendOutputVariableName(
      ActionType.CLIPBOARD_READ,
      existingVars
    );

    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.CLIPBOARD_READ,
      config: JSON.stringify({
        operation: 'read',
        saveToVariable: recommendedName
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: `读取剪贴板动作已添加，保存到变量 ${recommendedName}` });
  }

  /**
   * 添加 HTTP 请求动作
   */
  private addHttpRequestAction() {
    // 获取已存在的变量名
    const existingVars = VariableNameRecommender.extractExistingVariableNames(
      this.actions,
      this.variables
    );

    // 推荐变量名
    const recommendedName = VariableNameRecommender.recommendOutputVariableName(
      ActionType.HTTP_REQUEST,
      existingVars
    );

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
        saveResponseTo: recommendedName
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: `HTTP 请求动作已添加，保存到变量 ${recommendedName}` });
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
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: '打开 URL 动作已添加' });
  }

  /**
   * 添加文本处理动作
   */
  private addTextProcessAction() {
    // 获取已存在的变量名
    const existingVars = VariableNameRecommender.extractExistingVariableNames(
      this.actions,
      this.variables
    );

    // 获取前一个动作类型（用于上下文推荐）
    const previousActionType = this.actions.length > 0 ?
      this.actions[this.actions.length - 1].type : undefined;

    // 推荐变量名（上下文感知）
    const recommendedName = VariableNameRecommender.recommendContextualVariableName(
      ActionType.TEXT_PROCESS,
      'regex_extract',
      previousActionType,
      existingVars
    );

    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.TEXT_PROCESS,
      config: JSON.stringify({
        operation: 'regex_extract',
        input: '{clipboard_content}',
        pattern: 'https?://[^\\s]+',
        groupIndex: 0,
        saveToVariable: recommendedName
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: `文本处理动作已添加，保存到变量 ${recommendedName}` });
  }

  /**
   * 添加设置变量动作
   */
  private addSetVariableAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.SET_VARIABLE,
      config: JSON.stringify({
        variableName: 'my_variable',
        value: '',
        scope: 'runtime'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: '设置变量动作已添加' });
  }

  /**
   * 添加条件分支动作
   */
  private addIfElseAction() {
    // 创建一个简单的 IF_ELSE 模板
    // 定义分支配置的类型
    interface Condition {
      field: string;
      operator: string;
      value: string;
    }

    interface NotificationConfig {
      title: string;
      content: string;
      enableSound: boolean;
      enableVibration: boolean;
    }

    interface ActionWithConfig {
      type: string;
      config: NotificationConfig;
    }

    interface IfElseBranchConfig {
      name: string;
      conditions: Condition[];
      actions: ActionWithConfig[];
    }

    const branches: IfElseBranchConfig[] = [
      {
        name: '分支1',
        conditions: [
          {
            field: '{variable_name}',
            operator: '==',
            value: 'value1'
          }
        ],
        actions: [
          {
            type: 'notification',
            config: {
              title: '分支1执行',
              content: '条件满足时执行此分支',
              enableSound: false,
              enableVibration: false
            }
          }
        ]
      },
      {
        name: 'else分支',
        conditions: [],  // 空条件表示 else
        actions: [
          {
            type: 'notification',
            config: {
              title: 'else分支执行',
              content: '所有条件都不满足时执行此分支',
              enableSound: false,
              enableVibration: false
            }
          }
        ]
      }
    ];

    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.IF_ELSE,
      config: JSON.stringify({ branches: branches }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: '条件分支动作已添加，请在配置面板编辑' });
  }

  /**
   * 删除动作
   */
  private deleteAction(index: number) {
    // 检查是否会影响其他动作
    const affectedIndices = VariableFlowAnalyzer.getAffectedActionsByDeletion(
      this.actions,
      index
    );

    if (affectedIndices.length > 0) {
      const affectedActions = affectedIndices.map(i => `动作 ${i + 1}`).join('、');
      promptAction.showDialog({
        title: '警告',
        message: `删除此动作会影响 ${affectedActions}，是否继续？`,
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '删除', color: '#ff4d4f' }
        ]
      }).then((result) => {
        if (result.index === 1) {
          this.actions.splice(index, 1);
          // 重新调整 orderIndex
          this.actions.forEach((action, idx) => {
            action.orderIndex = idx;
          });
          this.updateActionViewModels(); // 更新视图模型
        }
      });
    } else {
      this.actions.splice(index, 1);
      // 重新调整 orderIndex
      this.actions.forEach((action, idx) => {
        action.orderIndex = idx;
      });
      this.updateActionViewModels(); // 更新视图模型
    }
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
      this.updateActionViewModels(); // 更新视图模型
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
      this.updateActionViewModels(); // 更新视图模型
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
      'user_dialog': '用户对话框',
      'set_variable': '设置变量'
    };
    return actionNames[action.type] || action.type;
  }

  // ==================== 变量管理 ====================

  /**
   * 添加宏变量
   */
  private handleAddVariable() {
    this.isVariableEditMode = false;
    this.editingVariableIndex = -1;
    this.varEditorName = '';
    this.varEditorType = VariableType.STRING;
    this.varEditorValue = '';
    this.showVariableEditor = true;
  }

  /**
   * 编辑宏变量
   */
  private handleEditVariable(variable: Variable, index: number) {
    this.isVariableEditMode = true;
    this.editingVariableIndex = index;
    this.varEditorName = variable.name;
    this.varEditorType = variable.type;
    this.varEditorValue = this.formatVariableValueForInput(variable);
    this.showVariableEditor = true;
  }

  /**
   * 格式化变量值用于输入
   */
  private formatVariableValueForInput(variable: Variable): string {
    if (variable.type === VariableType.BOOLEAN) {
      return variable.value ? 'true' : 'false';
    }
    return String(variable.value);
  }

  /**
   * 保存宏变量
   */
  private handleSaveVariable() {
    // 验证输入
    if (!this.varEditorName || this.varEditorName.trim().length === 0) {
      promptAction.showToast({ message: '请输入变量名称' });
      return;
    }

    // 验证变量名格式
    const namePattern = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
    if (!namePattern.test(this.varEditorName)) {
      promptAction.showToast({ message: '变量名只能包含字母、数字、下划线，且不能以数字开头' });
      return;
    }

    let value: string | number | boolean;

    // 根据类型解析值
    if (this.varEditorType === VariableType.STRING) {
      value = this.varEditorValue;
    } else if (this.varEditorType === VariableType.NUMBER) {
      value = Number(this.varEditorValue);
      if (isNaN(value)) {
        promptAction.showToast({ message: '请输入有效的数字' });
        return;
      }
    } else {
      value = this.varEditorValue.toLowerCase() === 'true';
    }

    if (this.isVariableEditMode && this.editingVariableIndex >= 0) {
      // 更新变量
      this.variables[this.editingVariableIndex].name = this.varEditorName.trim();
      this.variables[this.editingVariableIndex].type = this.varEditorType;
      this.variables[this.editingVariableIndex].value = value;
      this.variables[this.editingVariableIndex].updatedAt = Date.now();
      promptAction.showToast({ message: '变量已更新' });
    } else {
      // 添加新变量
      const variable: Variable = {
        id: Date.now(),
        scope: VariableScope.MACRO,
        macroId: this.macroId,
        name: this.varEditorName.trim(),
        type: this.varEditorType,
        value: value,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      this.variables.push(variable);
      promptAction.showToast({ message: '变量已添加' });
    }

    this.showVariableEditor = false;
  }

  /**
   * 取消编辑变量
   */
  private handleCancelVariableEdit() {
    this.showVariableEditor = false;
  }

  /**
   * 删除变量
   */
  private deleteVariable(index: number) {
    this.variables.splice(index, 1);
  }

  /**
   * 获取变量类型显示文本
   */
  private getVariableTypeLabel(type: VariableType): string {
    const labels: Record<string, string> = {
      'string': '文本',
      'number': '数字',
      'boolean': '布尔'
    };
    return labels[type] || type;
  }

  /**
   * 格式化变量值显示
   */
  private formatVariableValue(variable: Variable): string {
    if (variable.type === VariableType.BOOLEAN) {
      return variable.value ? '是' : '否';
    }
    return String(variable.value);
  }

  build() {
    Column() {
      // 统一顶部标题栏
      CommonTopBar({
        title: this.isEditMode ? '编辑宏' : '创建宏',
        onLeftClick: () => { this.handleCancel(); },
        onRightClick: () => { this.handleSave(); }
      })

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

          // 模板区域
          Column({ space: 12 }) {
            Text('快速开始')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)

            Text('使用预设模板快速创建宏')
              .fontSize(12)
              .fontColor('#999999')

            // 快小红模板按钮
            Row({ space: 12 }) {
              Column({ space: 8 }) {
                Row({ space: 8 }) {
                  Text('📱')
                    .fontSize(24)

                  Column({ space: 4 }) {
                    Text('快小红流程')
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)

                    Text('小红书内容采集到飞书')
                      .fontSize(12)
                      .fontColor('#666666')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .flexGrow(1)
                }

                Text('包含：读取剪贴板 → URL提取 → 用户选择 → API调用 → 打开飞书')
                  .fontSize(11)
                  .fontColor('#999999')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .flexGrow(1)
              .padding(12)
              .backgroundColor('#f0f9ff')
              .borderRadius(8)
              .border({ width: 1, color: '#91d5ff' })
              .onClick(() => {
                this.applyKuaiXiaoHongTemplate();
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
            if (this.actionViewModels.length === 0) {
              Text('暂无动作')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
            } else {
              Column({ space: 12 }) {
                ForEach(this.actionViewModels, (viewModel: ActionViewModel, index: number) => {
                  Column({ space: 8 }) {
                    // 动作卡片
                    Column({ space: 12 }) {
                      // 标题行
                      Row({ space: 12 }) {
                        // 序号和动作类型
                        Row({ space: 8 }) {
                          // 序号圆圈
                          Text(`${index + 1}`)
                            .fontSize(14)
                            .fontWeight(FontWeight.Bold)
                            .fontColor('#ffffff')
                            .width(28)
                            .height(28)
                            .textAlign(TextAlign.Center)
                            .borderRadius(14)
                            .backgroundColor(viewModel.isValid ? '#007DFF' : '#ff4d4f')

                          Column({ space: 4 }) {
                            Text(this.getActionDescription(viewModel))
                              .fontSize(16)
                              .fontWeight(FontWeight.Bold)

                            if (viewModel.configSummary) {
                              Text(viewModel.configSummary)
                                .fontSize(12)
                                .fontColor('#666666')
                                .maxLines(2)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                            }
                          }
                          .alignItems(HorizontalAlign.Start)
                          .flexGrow(1)
                        }
                        .flexGrow(1)

                        // 编辑按钮
                        Button('编辑')
                          .fontSize(12)
                          .height(28)
                          .padding({ left: 12, right: 12 })
                          .backgroundColor('#e6f7ff')
                          .fontColor('#1890ff')
                          .onClick(() => {
                            this.handleEditAction(index);
                          })
                      }
                      .width('100%')

                      // 输入变量标签
                      if (viewModel.inputVariables.length > 0) {
                        Row({ space: 8 }) {
                          Text('使用变量:')
                            .fontSize(12)
                            .fontColor('#999999')

                          Flex({ wrap: FlexWrap.Wrap }) {
                            ForEach(viewModel.inputVariables, (varName: string) => {
                              Text(`{${varName}}`)
                                .fontSize(11)
                                .fontColor(this.highlightedVariable === varName ? '#ffffff' : '#52c41a')
                                .backgroundColor(this.highlightedVariable === varName ? '#52c41a' : '#f6ffed')
                                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                                .borderRadius(4)
                                .margin({ right: 4, bottom: 4 })
                                .border({
                                  width: this.highlightedVariable === varName ? 2 : 1,
                                  color: this.highlightedVariable === varName ? '#52c41a' : '#b7eb8f'
                                })
                                .onClick(() => {
                                  this.handleVariableClick(varName);
                                })
                            })
                          }
                        }
                        .width('100%')
                      }

                      // 输出变量标签
                      if (viewModel.outputVariable) {
                        Row({ space: 8 }) {
                          Text('输出 →')
                            .fontSize(12)
                            .fontColor('#999999')

                          Text(`[${viewModel.outputVariable}]`)
                            .fontSize(11)
                            .fontColor(this.highlightedVariable === viewModel.outputVariable ? '#ffffff' : '#1890ff')
                            .fontWeight(FontWeight.Bold)
                            .backgroundColor(this.highlightedVariable === viewModel.outputVariable ? '#1890ff' : '#e6f7ff')
                            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                            .borderRadius(4)
                            .border({
                              width: this.highlightedVariable === viewModel.outputVariable ? 2 : 1,
                              color: this.highlightedVariable === viewModel.outputVariable ? '#1890ff' : '#91d5ff'
                            })
                            .onClick(() => {
                              this.handleVariableClick(viewModel.outputVariable!);
                            })
                        }
                        .width('100%')
                      }

                      // 验证错误提示
                      if (!viewModel.isValid && viewModel.validationErrors.length > 0) {
                        Column({ space: 4 }) {
                          ForEach(viewModel.validationErrors, (error: string) => {
                            Row({ space: 6 }) {
                              Text('⚠️')
                                .fontSize(12)

                              Text(error)
                                .fontSize(12)
                                .fontColor('#ff4d4f')
                                .flexGrow(1)
                            }
                          })
                        }
                        .width('100%')
                        .padding(8)
                        .backgroundColor('#fff1f0')
                        .borderRadius(4)
                        .border({ width: 1, color: '#ffa39e' })
                      }

                      // 操作按钮行
                      Row({ space: 8 }) {
                        // 排序按钮
                        Row({ space: 4 }) {
                          Button('↑')
                            .fontSize(14)
                            .height(28)
                            .width(36)
                            .padding(0)
                            .backgroundColor(index > 0 ? '#f0f0f0' : '#e0e0e0')
                            .fontColor(index > 0 ? '#333333' : '#999999')
                            .enabled(index > 0)
                            .onClick(() => {
                              this.moveActionUp(index);
                            })

                          Button('↓')
                            .fontSize(14)
                            .height(28)
                            .width(36)
                            .padding(0)
                            .backgroundColor(index < this.actionViewModels.length - 1 ? '#f0f0f0' : '#e0e0e0')
                            .fontColor(index < this.actionViewModels.length - 1 ? '#333333' : '#999999')
                            .enabled(index < this.actionViewModels.length - 1)
                            .onClick(() => {
                              this.moveActionDown(index);
                            })
                        }

                        Blank()

                        Button('删除')
                          .fontSize(12)
                          .height(28)
                          .padding({ left: 12, right: 12 })
                          .backgroundColor('#fff1f0')
                          .fontColor('#ff4d4f')
                          .onClick(() => {
                            this.deleteAction(index);
                          })
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor('#ffffff')
                    .borderRadius(8)
                    .border({
                      width: viewModel.isValid ? 1 : 2,
                      color: viewModel.isValid ? '#e8e8e8' : '#ff4d4f'
                    })

                    // 变量流向连线（使用 Unicode 箭头）
                    if (index < this.actionViewModels.length - 1) {
                      // 检查当前动作是否有输出变量，且下一个动作使用了该变量
                      if (viewModel.outputVariable &&
                        this.actionViewModels[index + 1].inputVariables.includes(viewModel.outputVariable)) {
                        // 有变量传递，显示变量标签
                        Row() {
                          Text('↓')
                            .fontSize(20)
                            .fontColor(this.highlightedVariable === viewModel.outputVariable ? '#52c41a' : '#1890ff')
                            .width('100%')
                            .textAlign(TextAlign.Center)

                          Text(`{${viewModel.outputVariable}}`)
                            .fontSize(11)
                            .fontColor(this.highlightedVariable === viewModel.outputVariable ? '#ffffff' : '#1890ff')
                            .backgroundColor(this.highlightedVariable === viewModel.outputVariable ? '#52c41a' : '#e6f7ff')
                            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                            .borderRadius(4)
                            .border({
                              width: this.highlightedVariable === viewModel.outputVariable ? 2 : 1,
                              color: this.highlightedVariable === viewModel.outputVariable ? '#52c41a' : '#91d5ff'
                            })
                            .position({ x: '50%', y: 10 })
                            .translate({ x: '-50%', y: 0 })
                            .onClick(() => {
                              this.handleVariableClick(viewModel.outputVariable!);
                            })
                        }
                        .width('100%')
                        .height(32)
                        .justifyContent(FlexAlign.Center)
                      } else if (viewModel.outputVariable) {
                        // 有输出但未被使用，显示普通连线
                        Text('↓')
                          .fontSize(16)
                          .fontColor('#d9d9d9')
                          .width('100%')
                          .textAlign(TextAlign.Center)
                          .height(24)
                      } else {
                        // 没有输出变量，显示普通连线
                        Text('↓')
                          .fontSize(16)
                          .fontColor('#d9d9d9')
                          .width('100%')
                          .textAlign(TextAlign.Center)
                          .height(24)
                      }
                    }
                  }
                  .width('100%')
                }, (viewModel: ActionViewModel, index: number) => {
                  // 使用多个属性组合作为 key，确保配置变化时触发重新渲染
                  const id = viewModel.id || 0;
                  const summary = viewModel.configSummary || '';
                  const valid = viewModel.isValid ? '1' : '0';
                  return `${index}_${id}_${summary}_${valid}`;
                })
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

          // 宏变量区域
          Column({ space: 12 }) {
            Row() {
              Text('宏变量')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .flexGrow(1)

              Text('可选')
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')

            // 变量编辑器
            if (this.showVariableEditor) {
              Column({ space: 16 }) {
                Text(this.isVariableEditMode ? '编辑变量' : '添加变量')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)

                // 变量名称
                Column({ space: 8 }) {
                  Text('变量名称 *')
                    .fontSize(14)
                    .fontColor('#666666')

                  TextInput({ placeholder: '例如：counter', text: this.varEditorName })
                    .fontSize(14)
                    .onChange((value: string) => {
                      this.varEditorName = value;
                    })

                  Text('只能包含字母、数字、下划线，且不能以数字开头')
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')

                // 变量类型
                Column({ space: 8 }) {
                  Text('变量类型 *')
                    .fontSize(14)
                    .fontColor('#666666')

                  Row({ space: 8 }) {
                    Button('文本')
                      .fontSize(12)
                      .height(28)
                      .backgroundColor(this.varEditorType === VariableType.STRING ? '#007DFF' : '#f0f0f0')
                      .fontColor(this.varEditorType === VariableType.STRING ? '#ffffff' : '#333333')
                      .onClick(() => {
                        this.varEditorType = VariableType.STRING;
                        if (this.varEditorValue === 'true' || this.varEditorValue === 'false') {
                          this.varEditorValue = '';
                        }
                      })
                      .enabled(!this.isVariableEditMode)

                    Button('数字')
                      .fontSize(12)
                      .height(28)
                      .backgroundColor(this.varEditorType === VariableType.NUMBER ? '#007DFF' : '#f0f0f0')
                      .fontColor(this.varEditorType === VariableType.NUMBER ? '#ffffff' : '#333333')
                      .onClick(() => {
                        this.varEditorType = VariableType.NUMBER;
                        this.varEditorValue = '0';
                      })
                      .enabled(!this.isVariableEditMode)

                    Button('布尔')
                      .fontSize(12)
                      .height(28)
                      .backgroundColor(this.varEditorType === VariableType.BOOLEAN ? '#007DFF' : '#f0f0f0')
                      .fontColor(this.varEditorType === VariableType.BOOLEAN ? '#ffffff' : '#333333')
                      .onClick(() => {
                        this.varEditorType = VariableType.BOOLEAN;
                        this.varEditorValue = 'true';
                      })
                      .enabled(!this.isVariableEditMode)
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')

                // 变量值
                Column({ space: 8 }) {
                  Text('变量值 *')
                    .fontSize(14)
                    .fontColor('#666666')

                  if (this.varEditorType === VariableType.BOOLEAN) {
                    // 布尔类型
                    Row({ space: 8 }) {
                      Button('false')
                        .fontSize(12)
                        .height(28)
                        .backgroundColor(this.varEditorValue === 'false' ? '#007DFF' : '#f0f0f0')
                        .fontColor(this.varEditorValue === 'false' ? '#ffffff' : '#333333')
                        .onClick(() => {
                          this.varEditorValue = 'false';
                        })

                      Button('true')
                        .fontSize(12)
                        .height(28)
                        .backgroundColor(this.varEditorValue === 'true' ? '#007DFF' : '#f0f0f0')
                        .fontColor(this.varEditorValue === 'true' ? '#ffffff' : '#333333')
                        .onClick(() => {
                          this.varEditorValue = 'true';
                        })
                    }
                  } else if (this.varEditorType === VariableType.NUMBER) {
                    // 数字类型
                    TextInput({ placeholder: '例如：0', text: this.varEditorValue })
                      .fontSize(14)
                      .type(InputType.Number)
                      .onChange((value: string) => {
                        this.varEditorValue = value;
                      })
                  } else {
                    // 文本类型
                    TextInput({ placeholder: '例如：默认值', text: this.varEditorValue })
                      .fontSize(14)
                      .onChange((value: string) => {
                        this.varEditorValue = value;
                      })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')

                // 操作按钮
                Row({ space: 8 }) {
                  Button('取消')
                    .fontSize(14)
                    .height(32)
                    .flexGrow(1)
                    .backgroundColor('#f0f0f0')
                    .fontColor('#333333')
                    .onClick(() => {
                      this.handleCancelVariableEdit();
                    })

                  Button('保存')
                    .fontSize(14)
                    .height(32)
                    .flexGrow(1)
                    .backgroundColor('#007DFF')
                    .onClick(() => {
                      this.handleSaveVariable();
                    })
                }
                .width('100%')
              }
              .padding(12)
              .backgroundColor('#e8f4ff')
              .borderRadius(8)
              .width('100%')
            }

            // 变量列表
            if (this.variables.length === 0 && !this.showVariableEditor) {
              Text('暂无宏变量')
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(20)
            } else if (!this.showVariableEditor) {
              Column({ space: 8 }) {
                ForEach(this.variables, (variable: Variable, index: number) => {
                  Row({ space: 12 }) {
                    Column({ space: 4 }) {
                      Text(variable.name)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)

                      Row({ space: 8 }) {
                        Text(this.getVariableTypeLabel(variable.type))
                          .fontSize(12)
                          .fontColor('#666666')

                        Text(`值: ${this.formatVariableValue(variable)}`)
                          .fontSize(12)
                          .fontColor('#666666')
                      }
                    }
                    .flexGrow(1)
                    .alignItems(HorizontalAlign.Start)

                    Row({ space: 8 }) {
                      Button('编辑')
                        .fontSize(14)
                        .height(32)
                        .backgroundColor('#f0f0f0')
                        .fontColor('#333333')
                        .onClick(() => {
                          this.handleEditVariable(variable, index);
                        })

                      Button('删除')
                        .fontSize(14)
                        .height(32)
                        .backgroundColor('#ff4444')
                        .onClick(() => {
                          this.deleteVariable(index);
                        })
                    }
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#f5f5f5')
                  .borderRadius(8)
                }, (variable: Variable, index: number) => index.toString())
              }
              .width('100%')
            }

            // 添加变量按钮
            if (!this.showVariableEditor) {
              Button('+ 添加宏变量')
                .width('100%')
                .height(40)
                .fontSize(16)
                .backgroundColor('#007DFF')
                .onClick(() => {
                  this.handleAddVariable();
                })
            }
          }
          .padding(16)
          .backgroundColor('#ffffff')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 80 })
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
