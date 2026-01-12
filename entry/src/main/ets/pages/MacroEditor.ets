import { Macro, MacroInput, Trigger, Action, TriggerType, ActionType, TimeTriggerConfig, NetworkTriggerConfig, HttpHeaders, Folder } from '../models/Macro';
import { ActionViewModel, ActionViewModelFactory, TextSegment } from '../models/ActionViewModel';
import { DatabaseService } from '../services/DatabaseService';
import { VariableFlowAnalyzer } from '../utils/VariableFlowAnalyzer';
import { ActionConfigSummaryGenerator } from '../utils/ActionConfigSummaryGenerator';
import { VariableNameRecommender } from '../utils/VariableNameRecommender';
import { VariableOption } from '../components/VariableSelector';
import { CommonTopBar, TopBarConfig } from '../components/CommonTopBar';
import { ActionTypes } from '../constants/ActionTypes';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 动作信息接口
 */
interface ActionInfo {
  type: string;
  displayName: string;
  description: string;
  icon: string;
  color: string;
  category: string;
}

/**
 * 宏编辑页（iOS快捷指令风格）
 * 参考iPhone快捷指令app的界面设计
 */
@Entry
@Component
struct MacroEditor {
  @State macroName: string = '';
  @State macroDescription: string = '';
  @State macroEnabled: boolean = true;
  @State selectedFolderId: number | null = null;
  @State folders: Folder[] = [];
  @State isEditMode: boolean = false;
  @State triggers: Trigger[] = [];
  @State actions: Action[] = [];
  @State actionViewModels: ActionViewModel[] = [];
  @State highlightedVariable: string = '';
  @State showSettings: boolean = false; // 设置面板显示状态
  @State showActionDrawer: boolean = false; // 动作抽屉显示状态
  @State actionSearchText: string = ''; // 动作搜索文字
  @State selectedActionCategory: string = 'all'; // 选中的动作分类
  @State inlineEditingIndex: number = -1; // 内联编辑的动作索引
  @State inlineEditingField: string = ''; // 内联编辑的字段名
  @State inlineEditingValue: string = ''; // 内联编辑的值








  // 动作配置编辑器状态
  @State expandedActionIndex: number = -1;
  @State editingAction: Action | null = null;
  @State editingActionConfig: Record<string, Object> = {};
  @State availableVariablesForEditor: VariableOption[] = [];

  // 文件夹选择器状态
  @State showFolderSelector: boolean = false;

  private macroId: number = 0;
  private databaseService: DatabaseService = DatabaseService.getInstance();

  async aboutToAppear() {
    await this.loadFolders();

    // 检查是否是编辑模式
    const params = router.getParams() as Record<string, Object>;
    if (params && params['macroId']) {
      this.isEditMode = true;
      this.macroId = params['macroId'] as number;
      await this.loadMacro();
    }
  }

  /**
   * 加载文件夹列表
   */
  private async loadFolders() {
    try {
      this.folders = await this.databaseService.getAllFolders();
    } catch (error) {
      Logger.error('MacroEditor', 'Failed to load folders', error as Error);
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
        this.selectedFolderId = macro.folderId || null;
      }

      // 加载触发器和动作
      this.triggers = await this.databaseService.getTriggersByMacroId(this.macroId);
      this.actions = await this.databaseService.getActionsByMacroId(this.macroId);

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
          enabled: this.macroEnabled,
          folderId: this.selectedFolderId
        });

        Logger.info('MacroEditor', 'Macro basic info updated');

        // 保存触发器和动作（先删除再插入）
        // 1. 删除所有旧的触发器和动作
        await this.databaseService.deleteTriggersByMacroId(this.macroId);
        await this.databaseService.deleteActionsByMacroId(this.macroId);

        Logger.info('MacroEditor', 'Old triggers and actions deleted');

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

        promptAction.showToast({ message: '宏已更新' });
      } else {
        Logger.info('MacroEditor', 'Creating new macro');

        // 创建新宏
        const macro: MacroInput = {
          name: this.macroName.trim(),
          description: this.macroDescription.trim(),
          enabled: this.macroEnabled,
          folderId: this.selectedFolderId ?? undefined,
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
    const newViewModels: ActionViewModel[] = this.actions.map((action: Action, index: number): ActionViewModel => {
      Logger.info('MacroEditor', `Processing action ${index}, config: ${action.config}`);

      // 获取之前已定义的变量
      const definedVars = VariableFlowAnalyzer.getDefinedVariablesBeforeAction(
        this.actions,
        index
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

      // 生成结构化配置摘要
      const segments = ActionConfigSummaryGenerator.generateSegments(action);

      return ActionViewModelFactory.create(
        action,
        inputVars,
        outputVar,
        summary,
        validationResult.isValid,
        validationResult.errors,
        segments
      );
    });

    // 使用新数组替换以触发 @State 响应式更新
    this.actionViewModels = newViewModels;
    Logger.info('MacroEditor', `View models updated, new count: ${this.actionViewModels.length}`);
  }

  /**
   * 结束编辑
   */
  private finishEditing() {
    this.inlineEditingIndex = -1;
    this.inlineEditingField = '';
    this.inlineEditingValue = '';
  }

  /**
   * 处理变量点击，切换高亮状态或开始内联编辑
   */
  private handleVariableClick(varName: string, field?: string, actionIndex: number = -1): void {
    if (field && actionIndex >= 0) {
      // 开始内联编辑
      this.inlineEditingIndex = actionIndex;
      this.inlineEditingField = field;
      this.inlineEditingValue = this.getActionFieldValue(actionIndex, field);
    } else if (this.highlightedVariable === varName) {
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

    // 2. 添加之前动作输出的变量
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
   * 编辑动作（展开/收起）
   */
  private handleEditAction(index: number) {
    Logger.info('MacroEditor', `Toggling action editor for index ${index}`);

    // 如果点击的是已经展开的动作，则收起
    if (this.expandedActionIndex === index) {
      this.expandedActionIndex = -1;
      this.editingAction = null;
      this.editingActionConfig = {};
      return;
    }

    // 先结束当前的内联编辑
    this.finishEditing();

    // 准备可用变量
    this.prepareAvailableVariables(index);

    // 设置编辑状态
    this.expandedActionIndex = index;

    // 深拷贝动作对象和配置
    this.editingAction = JSON.parse(JSON.stringify(this.actions[index])) as Action;
    try {
      this.editingActionConfig = JSON.parse(this.editingAction.config);
    } catch (error) {
      this.editingActionConfig = {};
    }
    Logger.info('MacroEditor', `Editing action: ${JSON.stringify(this.editingAction)}`);
  }

  /**
   * 实时保存动作配置字段
   */
  private saveActionConfigField(key: string, value: Object) {
    if (this.editingAction && this.expandedActionIndex >= 0 && this.expandedActionIndex < this.actions.length) {
      // 更新编辑中的配置
      this.editingActionConfig[key] = value;

      // 更新动作配置
      this.editingAction.config = JSON.stringify(this.editingActionConfig);

      // 更新动作列表 - 使用 slice() 创建新数组以触发响应式更新
      const newActions: Action[] = this.actions.slice();
      newActions[this.expandedActionIndex] = JSON.parse(JSON.stringify(this.editingAction)) as Action;
      this.actions = newActions;

      // 使用 setTimeout 确保 UI 更新
      setTimeout(() => {
        this.updateActionViewModels();
      }, 10);
    }
  }

  /**
   * 使用"快小红"流程模板
   * 快速创建小红书内容采集到飞书的完整流程
   */
  private applyKuaiXiaoHongTemplate() {
    promptAction.showDialog({
      title: '使用快小红模板',
      message: '将自动创建：\n1. 手动触发器\n2. 输入内容（带粘贴按钮）\n3. 正则提取 URL\n4. 用户对话框（选择爆款标记）\n5. 用户对话框（选择分类标签）\n6. HTTP POST 请求\n7. 打开飞书表格\n\n是否继续？',
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

    // 1. 设置变量 - 飞书多维表格授权码
    const setAuthCodeAction: Action = {
      id: Date.now() + 1,
      macroId: this.macroId,
      type: ActionType.SET_VARIABLE,
      config: JSON.stringify({
        variableName: '飞书多维表格授权码',
        value: '',
        scope: 'runtime'
      }),
      orderIndex: 0
    };
    this.actions.push(setAuthCodeAction);

    // 2. 设置变量 - 订单号
    const setOrderIdAction: Action = {
      id: Date.now() + 2,
      macroId: this.macroId,
      type: ActionType.SET_VARIABLE,
      config: JSON.stringify({
        variableName: '订单号',
        value: '',
        scope: 'runtime'
      }),
      orderIndex: 1
    };
    this.actions.push(setOrderIdAction);

    // 3. 发送通知 - 启动提示
    const startNotificationAction: Action = {
      id: Date.now() + 3,
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '开始采集',
        content: '请按提示逐步操作',
        enableSound: false,
        enableVibration: false
      }),
      orderIndex: 2
    };
    this.actions.push(startNotificationAction);

    // 4. 用户输入对话框（支持粘贴）
    const inputDialogAction: Action = {
      id: Date.now() + 4,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        type: 'text_input',
        title: '📋 请输入小红书链接',
        message: '可直接粘贴剪贴板内容',
        placeholder: '在此粘贴链接或输入内容...',
        saveToVariable: 'clipboard_content'
      }),
      orderIndex: 3
    };
    this.actions.push(inputDialogAction);

    // 5. 正则提取 URL
    const textProcessAction: Action = {
      id: Date.now() + 5,
      macroId: this.macroId,
      type: ActionType.TEXT_PROCESS,
      config: JSON.stringify({
        operation: 'regex_extract',
        input: '{clipboard_content}',
        pattern: 'https?://[^\\s]+',
        groupIndex: 0,
        saveToVariable: 'extracted_url'
      }),
      orderIndex: 4
    };
    this.actions.push(textProcessAction);

    // 6. 用户对话框 - 选择爆款标记
    const qualityDialogAction: Action = {
      id: Date.now() + 6,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        type: 'single_select',
        title: '🔥 请标记内容火爆程度',
        message: '请选择内容的质量等级',
        options: ['⚪ 普通款', '🟡 潜力款', '🔴 大爆款'],
        saveToVariable: 'quality'
      }),
      orderIndex: 5
    };
    this.actions.push(qualityDialogAction);

    // 7. 用户对话框 - 选择分类标签（40个选项）
    const labelDialogAction: Action = {
      id: Date.now() + 7,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        type: 'single_select',
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
      orderIndex: 6
    };
    this.actions.push(labelDialogAction);

    // 8. 用户对话框 - 对标参考度评分
    const scoreDialogAction: Action = {
      id: Date.now() + 8,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        type: 'single_select',
        title: '👍 请标记对标参考度',
        message: '1-5赞，0表示跳过',
        options: ['5 赞👍👍👍👍👍', '4 赞👍👍👍👍', '3 赞👍👍👍', '2 赞👍👍', '1 赞👍', '0 先不选，跳过'],
        saveToVariable: 'quality_score'
      }),
      orderIndex: 7
    };
    this.actions.push(scoreDialogAction);

    // 9. 用户对话框 - 备注说明输入
    const notesDialogAction: Action = {
      id: Date.now() + 9,
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        type: 'text_input',
        title: '📝 请输入收藏备注',
        message: '（选填）',
        placeholder: '输入备注内容...',
        saveToVariable: 'notes'
      }),
      orderIndex: 8
    };
    this.actions.push(notesDialogAction);

    // 10. 发送通知 - 上传进度
    const uploadNotificationAction: Action = {
      id: Date.now() + 10,
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '数据上传中',
        content: '请耐心等待...',
        enableSound: false,
        enableVibration: false
      }),
      orderIndex: 9
    };
    this.actions.push(uploadNotificationAction);

     // 11. HTTP POST 请求 - 调用 Coze API（笔记采集工作流）
    const headers: HttpHeaders = { 'Content-Type': 'application/json' };
    const httpAction: Action = {
      id: Date.now() + 11,
      macroId: this.macroId,
      type: ActionType.HTTP_REQUEST,
      config: JSON.stringify({
        method: 'POST',
        url: 'https://api.coze.cn/v1/workflow/run',
        headers: headers,
        body: '{"workflow_id":"7550495126771449906","parameters":{"url":"{extracted_url}","quality":"{quality_score}","read":"{quality}","notes":"{notes}","label":["{label}"],"xhscookie":"{飞书多维表格授权码}","order_id":"{订单号}"}}',
        bodyType: 'json',
        timeout: 30000,
        parseResponse: true,
        saveResponseTo: 'api_response',
        saveParsedResponse: 'api_response_json',
        saveStatusCodeTo: 'api_status'
      }),
      orderIndex: 10
    };
    this.actions.push(httpAction);

    // 12. JSON 处理 - 查询响应中的提示语（使用 JSONPath）
    const extractPromptAction: Action = {
      id: Date.now() + 12,
      macroId: this.macroId,
      type: ActionType.JSON_PROCESS,
      config: JSON.stringify({
        operation: 'json_query',
        input: '{api_response_json}',
        queryPath: 'data.message',
        saveToVariable: 'result_message'
      }),
      orderIndex: 11
    };
    this.actions.push(extractPromptAction);

    // 13. 发送通知 - 成功提示（显示状态码）
    const successNotificationAction: Action = {
      id: Date.now() + 13,
      macroId: this.macroId,
      type: ActionType.NOTIFICATION,
      config: JSON.stringify({
        title: '✅ 采集成功',
        content: '{result_message}\n状态码: {api_status}',
        enableSound: true,
        enableVibration: true
      }),
      orderIndex: 12
    };
    this.actions.push(successNotificationAction);

    // 14. JSON 处理 - 查询更多数据（可选，展示 JSONPath 能力）
    const queryMoreDataAction: Action = {
      id: Date.now() + 14,
      macroId: this.macroId,
      type: ActionType.JSON_PROCESS,
      config: JSON.stringify({
        operation: 'json_query',
        input: '{api_response_json}',
        queryPath: 'data',
        saveToVariable: 'api_data'
      }),
      orderIndex: 13
    };
    this.actions.push(queryMoreDataAction);

    // 15. 打开飞书多维表格
    const openUrlAction: Action = {
      id: Date.now() + 15,
      macroId: this.macroId,
      type: ActionType.OPEN_URL,
      config: JSON.stringify({
        url: 'https://applink.feishu.cn/client/docs/open?url=https://example.feishu.cn/base/xxx',
        openWith: 'browser'
      }),
      orderIndex: 14
    };
    this.actions.push(openUrlAction);

    // 更新视图模型
    this.updateActionViewModels();

    promptAction.showDialog({
      title: '快小红模板创建成功',
      message: '已创建包含15个动作的完整采集流程。\n\n流程包含：\n1. 设置变量（飞书授权码）\n2. 设置变量（订单号）\n3-15. 采集、选择、上传流程\n\n✨ JSON 功能增强：\n- HTTP 响应自动解析为 JSON 对象\n- 使用 JSONPath 提取 API 返回数据\n- 可访问嵌套字段：\n  • {api_response_json.data.message} - 提取消息\n  • {api_response_json.data} - 获取完整数据对象\n  • {api_status} - 获取 HTTP 状态码\n\n⚠️ 请编辑前2个"设置变量"动作，填入实际的飞书授权码和订单号。',
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
        { text: '启动应用', color: '#000000' },
        { text: '发送通知', color: '#000000' },
        { text: '读取剪贴板', color: '#000000' },
        { text: '写入剪贴板', color: '#000000' },
        { text: 'HTTP 请求', color: '#000000' },
        { text: '打开 URL', color: '#000000' },
        { text: '文本处理', color: '#000000' },
        { text: 'JSON 处理', color: '#000000' },
        { text: '用户对话框', color: '#000000' },
        { text: '设置变量', color: '#000000' },
        { text: '条件分支', color: '#000000' }
      ]
    }).then((result) => {
      switch (result.index) {
        case 0:
          this.addLaunchAppAction();
          break;
        case 1:
          this.addNotificationAction();
          break;
        case 2:
          this.addClipboardReadAction();
          break;
        case 3:
          this.addClipboardWriteAction();
          break;
        case 4:
          this.addHttpRequestAction();
          break;
        case 5:
          this.addOpenUrlAction();
          break;
        case 6:
          this.addTextProcessAction();
          break;
        case 7:
          this.addJsonProcessAction();
          break;
        case 8:
          this.addUserDialogAction();
          break;
        case 9:
          this.addSetVariableAction();
          break;
        case 10:
          this.addIfElseAction();
          break;
      }
    });
  }

  /**
   * 添加启动应用动作
   */
  private addLaunchAppAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.LAUNCH_APP,
      config: JSON.stringify({
        bundleName: 'com.huawei.hmos.contacts',
        mode: 'explicit',
        abilityName: 'com.huawei.hmos.contacts.MainAbility',
        parameters: {} as Record<string, Object>
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
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
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
  }

  /**
   * 添加读取剪贴板动作
   */
  private addClipboardReadAction() {
    // 获取已存在的变量名
    const existingVars = VariableNameRecommender.extractExistingVariableNames(
      this.actions
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
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
  }

  /**
   * 添加写入剪贴板动作
   */
  private addClipboardWriteAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.CLIPBOARD_WRITE,
      config: JSON.stringify({
        operation: 'write',
        content: '{clipboard_content}'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
  }

  /**
   * 添加 HTTP 请求动作
   */
  private addHttpRequestAction() {
    // 获取已存在的变量名
    const existingVars = VariableNameRecommender.extractExistingVariableNames(
      this.actions
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
        bodyType: 'json',
        timeout: 30000,
        saveResponseTo: recommendedName
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
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
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
  }

  /**
   * 添加文本处理动作
   */
  private addTextProcessAction() {
    // 获取已存在的变量名
    const existingVars = VariableNameRecommender.extractExistingVariableNames(
      this.actions
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
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
  }

  /**
   * 添加用户对话框动作
   */
  private addUserDialogAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.USER_DIALOG,
      config: JSON.stringify({
        type: 'text_input',
        title: '请输入内容',
        message: '描述信息',
        placeholder: '在此输入...',
        saveToVariable: 'user_input'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
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
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
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
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
  }

  /**
   * 添加 JSON 处理动作
   */
  private addJsonProcessAction() {
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.JSON_PROCESS,
      config: JSON.stringify({
        operation: 'json_query',
        input: '{api_response}',
        queryPath: 'data.message',
        saveToVariable: 'extracted_field'
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels();
    setTimeout(() => {
      this.handleEditAction(this.actions.length - 1);
    }, 10);
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
   * 获取动作显示名称
   */
  private getActionDisplayName(viewModel: ActionViewModel): string {
    return ActionTypes.getDisplayName(viewModel.type);
  }

  /**
   * 构建内联配置表单
   */
  @Builder
  buildActionConfigForm() {
    if (this.editingAction) {
      Column({ space: 0 }) {
        Divider()

        Column({ space: 16 }) {
          if (this.editingAction.type === ActionType.NOTIFICATION) {
            this.buildNotificationFormInline();
          } else if (this.editingAction.type === ActionType.TEXT_PROCESS) {
            this.buildTextProcessFormInline();
          } else if (this.editingAction.type === ActionType.HTTP_REQUEST) {
            this.buildHttpRequestFormInline();
          } else if (this.editingAction.type === ActionType.USER_DIALOG) {
            this.buildUserDialogFormInline();
          } else if (this.editingAction.type === ActionType.OPEN_URL) {
            this.buildOpenUrlFormInline();
          } else if (this.editingAction.type === ActionType.LAUNCH_APP) {
            this.buildLaunchAppFormInline();
          } else if (this.editingAction.type === ActionType.CLIPBOARD_READ || this.editingAction.type === ActionType.CLIPBOARD_WRITE) {
            this.buildClipboardFormInline();
          } else if (this.editingAction.type === ActionType.SET_VARIABLE) {
            this.buildSetVariableFormInline();
          } else if (this.editingAction.type === ActionType.IF_ELSE) {
            this.buildIfElseFormInline();
          } else if (this.editingAction.type === ActionType.JSON_PROCESS) {
            this.buildJsonProcessFormInline();
          } else {
            Text('暂不支持此动作类型的配置')
              .fontSize(14)
              .fontColor('#999999')
              .textAlign(TextAlign.Center)
              .padding(20);
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F8F8')
        .borderRadius({ bottomLeft: 12, bottomRight: 12 })
      }
      .width('100%')
    }
  }

  @Builder
  buildNotificationFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('通知标题')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['title'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('title', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('通知内容')
          .fontSize(13)
          .fontColor('#666666')

        TextArea({ text: this.editingActionConfig['content'] as string })
          .fontSize(14)
          .height(60)
          .onChange((value: string) => {
            this.saveActionConfigField('content', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row({ space: 16 }) {
        Row({ space: 6 }) {
          Checkbox({ name: 'sound', group: 'notification' })
            .select(this.editingActionConfig['enableSound'] as boolean)
            .onChange((value: boolean) => {
              this.saveActionConfigField('enableSound', value);
            })
          Text('声音')
            .fontSize(14)
        }

        Row({ space: 6 }) {
          Checkbox({ name: 'vibration', group: 'notification' })
            .select(this.editingActionConfig['enableVibration'] as boolean)
            .onChange((value: boolean) => {
              this.saveActionConfigField('enableVibration', value);
            })
          Text('震动')
            .fontSize(14)
        }
      }
    }
    .width('100%')
  }

  @Builder
  buildOpenUrlFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('URL')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['url'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('url', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildClipboardFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('操作类型')
          .fontSize(13)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('读取')
            .fontSize(13)
            .height(32)
            .backgroundColor((this.editingActionConfig['operation'] as string || 'read') === 'read' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['operation'] as string || 'read') === 'read' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('operation', 'read');
            })

          Button('写入')
            .fontSize(13)
            .height(32)
            .backgroundColor((this.editingActionConfig['operation'] as string || 'read') === 'write' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['operation'] as string || 'read') === 'write' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('operation', 'write');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if ((this.editingActionConfig['operation'] as string || 'read') === 'read') {
        Column({ space: 6 }) {
          Text('保存到变量')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['saveToVariable'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('saveToVariable', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      if ((this.editingActionConfig['operation'] as string || 'read') === 'write') {
        Column({ space: 6 }) {
          Text('写入内容')
            .fontSize(13)
            .fontColor('#666666')

          TextArea({ text: this.editingActionConfig['content'] as string })
            .fontSize(14)
            .height(60)
            .onChange((value: string) => {
              this.saveActionConfigField('content', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  buildSetVariableFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('变量名')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['variableName'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('variableName', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('变量值')
          .fontSize(13)
          .fontColor('#666666')

        TextArea({ text: this.editingActionConfig['value'] as string })
          .fontSize(14)
          .height(60)
          .onChange((value: string) => {
            this.saveActionConfigField('value', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildJsonProcessFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('操作类型')
          .fontSize(13)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('JSON查询')
            .fontSize(13)
            .height(32)
            .backgroundColor((this.editingActionConfig['operation'] as string || 'json_query') === 'json_query' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['operation'] as string || 'json_query') === 'json_query' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('operation', 'json_query');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if ((this.editingActionConfig['operation'] as string || 'json_query') === 'json_query') {
        Column({ space: 6 }) {
          Text('输入来源')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['input'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('input', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 6 }) {
          Text('JSONPath查询')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['queryPath'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('queryPath', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 6 }) {
          Text('保存到变量')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['saveToVariable'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('saveToVariable', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  buildTextProcessFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('操作类型')
          .fontSize(13)
          .fontColor('#666666')

        Row({ space: 6 }) {
          Button('正则提取')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['operation'] as string || 'regex_extract') === 'regex_extract' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['operation'] as string || 'regex_extract') === 'regex_extract' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('operation', 'regex_extract');
            })

          Button('替换')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['operation'] as string || 'regex_extract') === 'replace' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['operation'] as string || 'regex_extract') === 'replace' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('operation', 'replace');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('输入来源')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['input'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('input', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if ((this.editingActionConfig['operation'] as string || 'regex_extract') === 'regex_extract') {
        Column({ space: 6 }) {
          Text('正则表达式')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['pattern'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('pattern', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      Column({ space: 6 }) {
        Text('保存到变量')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['saveToVariable'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('saveToVariable', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildHttpRequestFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('请求方法')
          .fontSize(13)
          .fontColor('#666666')

        Row({ space: 6 }) {
          Button('GET')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.editingActionConfig['method'] === 'GET' ? '#007DFF' : '#F2F2F7')
            .fontColor(this.editingActionConfig['method'] === 'GET' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('method', 'GET');
            })

          Button('POST')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.editingActionConfig['method'] === 'POST' ? '#007DFF' : '#F2F2F7')
            .fontColor(this.editingActionConfig['method'] === 'POST' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('method', 'POST');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('URL')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['url'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('url', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if (this.editingActionConfig['method'] === 'POST') {
        Column({ space: 6 }) {
          Text('请求体')
            .fontSize(13)
            .fontColor('#666666')

          TextArea({ text: this.editingActionConfig['body'] as string })
            .fontSize(14)
            .height(80)
            .onChange((value: string) => {
              this.saveActionConfigField('body', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      Column({ space: 6 }) {
        Text('保存响应到变量')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['saveResponseTo'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('saveResponseTo', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildUserDialogFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('对话框类型')
          .fontSize(13)
          .fontColor('#666666')

        Row({ space: 6 }) {
          Button('文本输入')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['type'] as string || 'text_input') === 'text_input' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['type'] as string || 'text_input') === 'text_input' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('type', 'text_input');
            })

          Button('确认对话框')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['type'] as string || 'text_input') === 'confirm' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['type'] as string || 'text_input') === 'confirm' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('type', 'confirm');
            })

          Button('单选')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['type'] as string || 'text_input') === 'single_select' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['type'] as string || 'text_input') === 'single_select' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('type', 'single_select');
            })

          Button('多选')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['type'] as string || 'text_input') === 'multi_select' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['type'] as string || 'text_input') === 'multi_select' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('type', 'multi_select');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 6 }) {
        Text('标题')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['title'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('title', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if ((this.editingActionConfig['type'] as string || 'text_input') === 'single_select' || (this.editingActionConfig['type'] as string || 'text_input') === 'multi_select') {
        Column({ space: 6 }) {
          Text('选项（每行一个）')
            .fontSize(13)
            .fontColor('#666666')

          TextArea({
            text: this.editingActionConfig['options'] ? (this.editingActionConfig['options'] as string[]).join('\n') : ''
          })
            .fontSize(14)
            .height(80)
            .onChange((value: string) => {
              this.saveActionConfigField('options', value.split('\n').filter(line => line.trim().length > 0));
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      Column({ space: 6 }) {
        Text('保存到变量')
          .fontSize(13)
          .fontColor('#666666')

        TextInput({ text: this.editingActionConfig['saveToVariable'] as string })
          .fontSize(14)
          .onChange((value: string) => {
            this.saveActionConfigField('saveToVariable', value);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildLaunchAppFormInline() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('启动模式')
          .fontSize(13)
          .fontColor('#666666')

        Row({ space: 6 }) {
          Button('显式')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['mode'] as string || 'explicit') === 'explicit' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['mode'] as string || 'explicit') === 'explicit' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('mode', 'explicit');
            })

          Button('隐式')
            .fontSize(12)
            .height(32)
            .backgroundColor((this.editingActionConfig['mode'] as string || 'explicit') === 'implicit' ? '#007DFF' : '#F2F2F7')
            .fontColor((this.editingActionConfig['mode'] as string || 'explicit') === 'implicit' ? '#FFFFFF' : '#1A1A1A')
            .onClick(() => {
              this.saveActionConfigField('mode', 'implicit');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if ((this.editingActionConfig['mode'] as string || 'explicit') === 'explicit') {
        Column({ space: 6 }) {
          Text('应用包名')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['bundleName'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('bundleName', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 6 }) {
          Text('组件名')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['abilityName'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('abilityName', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      if ((this.editingActionConfig['mode'] as string || 'explicit') === 'implicit') {
        Column({ space: 6 }) {
          Text('URI')
            .fontSize(13)
            .fontColor('#666666')

          TextInput({ text: this.editingActionConfig['uri'] as string })
            .fontSize(14)
            .onChange((value: string) => {
              this.saveActionConfigField('uri', value);
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  buildIfElseFormInline() {
    Column({ space: 12 }) {
      Text('条件分支功能较复杂，建议在桌面端编辑器中配置')
        .fontSize(13)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .padding(20)
    }
    .width('100%')
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
      'set_variable': '设置变量',
      'if_else': '条件分支',
      'json_process': 'JSON 处理'
    };
    const name: string = actionNames[action.type] || action.type;
    return name;
  }

  @Builder
  SettingsPanelBuilder() {
    Column() {
      Column() {
        Row() {
          Text('设置')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .flexGrow(1)

          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(20)
              .fontColor(['#8E8E93'])
          }
          .width(36)
          .height(36)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showSettings = false;
          })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 12 }) {
              Text('基本信息')
                .fontSize(13)
                .fontColor('#8E8E93')
                .width('100%')

              Column({ space: 8 }) {
                Text('宏名称')
                  .fontSize(15)
                  .fontColor('#1A1A1A')

                TextInput({ placeholder: '请输入宏名称', text: this.macroName })
                  .fontSize(16)
                  .backgroundColor('#F2F2F7')
                  .borderRadius(10)
                  .onChange((value: string) => {
                    this.macroName = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')

              Column({ space: 8 }) {
                Text('描述')
                  .fontSize(15)
                  .fontColor('#1A1A1A')

                TextArea({ placeholder: '请输入宏描述', text: this.macroDescription })
                  .fontSize(16)
                  .height(80)
                  .backgroundColor('#F2F2F7')
                  .borderRadius(10)
                  .onChange((value: string) => {
                    this.macroDescription = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            Column({ space: 12 }) {
              Row() {
                Text('触发器')
                  .fontSize(13)
                  .fontColor('#8E8E93')
                  .flexGrow(1)

                Text('+ 添加')
                  .fontSize(15)
                  .fontColor('#007AFF')
                  .onClick(() => {
                    this.handleAddTrigger();
                  })
              }
              .width('100%')

              if (this.triggers.length === 0) {
                Text('暂无触发器')
                  .fontSize(15)
                  .fontColor('#8E8E93')
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
                          .fontColor('#1A1A1A')

                        Text(trigger.type)
                          .fontSize(12)
                          .fontColor('#8E8E93')
                      }
                      .flexGrow(1)
                      .alignItems(HorizontalAlign.Start)

                      Button() {
                        SymbolGlyph($r('sys.symbol.trash'))
                          .fontSize(16)
                          .fontColor(['#FF3B30'])
                      }
                      .width(32)
                      .height(32)
                      .backgroundColor(Color.Transparent)
                      .onClick(() => {
                        this.deleteTrigger(index);
                      })
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor('#F2F2F7')
                    .borderRadius(10)
                  }, (trigger: Trigger, index: number) => index.toString())
                }
                .width('100%')
              }
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            Column({ space: 12 }) {
              Text('快速开始')
                .fontSize(13)
                .fontColor('#8E8E93')
                .width('100%')

              Button() {
                Row({ space: 12 }) {
                  Text('📱')
                    .fontSize(24)

                  Column({ space: 4 }) {
                    Text('快小红流程')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1A1A1A')

                    Text('小红书内容采集到飞书')
                      .fontSize(12)
                      .fontColor('#8E8E93')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .flexGrow(1)

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(16)
                    .fontColor(['#C7C7CC'])
                }
                .width('100%')
                .padding(12)
              }
              .width('100%')
              .backgroundColor('#F0F9FF')
              .borderRadius(10)
              .onClick(() => {
                this.applyKuaiXiaoHongTemplate();
              })
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width(320)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .padding(24)
      .shadow({
        radius: 24,
        color: '#30000000',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.showSettings = false;
    })
    .zIndex(3)
  }

  @Builder
  ActionDrawerBuilder() {
    Column() {
      Column() {
        Row() {
          Row()
            .width(36)
            .height(5)
            .backgroundColor('#C7C7CC')
            .borderRadius(3)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8, bottom: 16 })

        Row() {
          Text('添加动作')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .flexGrow(1)

          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(20)
              .fontColor(['#8E8E93'])
          }
          .width(36)
          .height(36)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showActionDrawer = false;
          })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(16)
            .fontColor(['#8E8E93'])

          TextInput({ placeholder: '搜索 App 和操作', text: this.actionSearchText })
            .fontSize(16)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.actionSearchText = value;
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#F2F2F7')
        .borderRadius(10)
        .margin({ bottom: 16 })

        Row({ space: 8 }) {
          Button('全部')
            .fontSize(14)
            .fontWeight(this.selectedActionCategory === 'all' ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedActionCategory === 'all' ? '#FFFFFF' : '#007AFF')
            .backgroundColor(this.selectedActionCategory === 'all' ? '#007AFF' : '#F2F2F7')
            .borderRadius(20)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedActionCategory = 'all';
            })

          Button('文本')
            .fontSize(14)
            .fontWeight(this.selectedActionCategory === 'text' ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedActionCategory === 'text' ? '#FFFFFF' : '#FF9500')
            .backgroundColor(this.selectedActionCategory === 'text' ? '#FF9500' : '#F2F2F7')
            .borderRadius(20)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedActionCategory = 'text';
            })

          Button('网络')
            .fontSize(14)
            .fontWeight(this.selectedActionCategory === 'network' ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedActionCategory === 'network' ? '#FFFFFF' : '#34C759')
            .backgroundColor(this.selectedActionCategory === 'network' ? '#34C759' : '#F2F2F7')
            .borderRadius(20)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedActionCategory = 'network';
            })

          Button('系统')
            .fontSize(14)
            .fontWeight(this.selectedActionCategory === 'system' ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedActionCategory === 'system' ? '#FFFFFF' : '#5856D6')
            .backgroundColor(this.selectedActionCategory === 'system' ? '#5856D6' : '#F2F2F7')
            .borderRadius(20)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedActionCategory = 'system';
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.getFilteredActions(), (actionInfo: ActionInfo) => {
              Button() {
                Row({ space: 12 }) {
                  Row() {
                    Text(actionInfo.icon)
                      .fontSize(20)
                  }
                  .width(40)
                  .height(40)
                  .backgroundColor(actionInfo.color)
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)

                  Column({ space: 2 }) {
                    Text(actionInfo.displayName)
                      .fontSize(16)
                      .fontColor('#1A1A1A')

                    Text(actionInfo.description)
                      .fontSize(13)
                      .fontColor('#8E8E93')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .flexGrow(1)

                  SymbolGlyph($r('sys.symbol.plus'))
                    .fontSize(20)
                    .fontColor(['#007AFF'])
                }
                .width('100%')
                .padding({ left: 4, right: 4, top: 4, bottom: 4 })
              }
              .width('100%')
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.addActionByType(actionInfo.type);
              })
            }, (actionInfo: ActionInfo) => actionInfo.type)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('70%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .padding({ left: 20, right: 20, top: 8, bottom: 34 })
      .shadow({
        radius: 24,
        color: '#20000000',
        offsetX: 0,
        offsetY: -4
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .backgroundColor('#66000000')
    .onClick(() => {
      this.showActionDrawer = false;
    })
    .zIndex(4)
  }

  @Builder
  CategoryTabBuilder(name: string, value: string, color: string) {
    Button(name)
      .fontSize(14)
      .fontWeight(this.selectedActionCategory === value ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.selectedActionCategory === value ? '#FFFFFF' : color)
      .backgroundColor(this.selectedActionCategory === value ? color : '#F2F2F7')
      .borderRadius(20)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .onClick(() => {
        this.selectedActionCategory = value;
      })
  }

  @Builder
  ActionCardBuilder(viewModel: ActionViewModel, index: number) {
    Column({ space: 0 }) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Row() {
            Text(this.getActionIcon(viewModel))
              .fontSize(20)
          }
          .width(40)
          .height(40)
          .backgroundColor(this.getActionColor(viewModel))
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)

          Column({ space: 4 }) {
            if (viewModel.configSegments && viewModel.configSegments.length > 0) {
              this.ConfigSummaryRenderer(viewModel.configSegments, index)
            } else if (viewModel.configSummary) {
              Text(viewModel.configSummary)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1A1A1A')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .flexGrow(1)

          Button() {
            SymbolGlyph(this.expandedActionIndex === index ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
              .fontSize(14)
              .fontColor(['#8E8E93'])
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.handleEditAction(index);
          })

          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(16)
              .fontColor(['#8E8E93'])
          }
          .width(32)
          .height(32)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.deleteAction(index);
          })
        }
        .width('100%')

        if (!viewModel.isValid && viewModel.validationErrors.length > 0) {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
              .fontSize(14)
              .fontColor(['#FF3B30'])

            Text(viewModel.validationErrors[0])
              .fontSize(13)
              .fontColor('#FF3B30')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .flexGrow(1)
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#FFF0F0')
          .borderRadius(8)
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .border({
        width: 1,
        color: viewModel.isValid ? '#E5E5EA' : '#FF3B30'
      })
      .onClick(() => {
        this.handleEditAction(index);
      })

      if (this.expandedActionIndex === index && this.editingAction) {
        this.buildActionConfigForm()
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  ConfigSummaryRenderer(segments: TextSegment[], actionIndex: number) {
    Row() {
      ForEach(segments, (segment: TextSegment, segIndex: number) => {
        if (segment.isClickable && segment.field &&
          this.inlineEditingIndex === actionIndex && this.inlineEditingField === segment.field) {
          TextInput({
            placeholder: segment.text,
            text: this.inlineEditingValue
          })
            .fontSize(14)
            .width(100)
            .height(32)
            .backgroundColor('#F2F2F7')
            .borderRadius(4)
            .onChange((value: string) => {
              this.inlineEditingValue = value;
            })
            .onBlur(() => {
              this.updateActionFieldValue(actionIndex, segment.field!, this.inlineEditingValue);
              this.finishEditing();
            })
        } else if (segment.isClickable) {
          Text(segment.text)
            .fontSize(14)
            .fontColor(segment.color || '#007AFF')
            .backgroundColor(segment.backgroundColor || Color.Transparent)
            .padding({ left:4, right: 4, top: 2, bottom: 2 })
            .borderRadius(4)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .onClick(() => {
              if (segment.field) {
                this.handleVariableClick(segment.value || '', segment.field, actionIndex);
              }
            })
        } else {
          Text(segment.text)
            .fontSize(14)
            .fontColor(segment.color || '#8E8E93')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }, (segment: TextSegment, index: number) => `segment_${index}_${segment.text}`)
    }
    .width('100%')
  }

  /**
   * 更新动作字段值
   */
  private updateActionFieldValue(actionIndex: number, field: string, value: string): void {
    const action = this.actions[actionIndex];
    const config: Record<string, Object> = JSON.parse(action.config) as Record<string, Object>;
    config[field] = value;
    action.config = JSON.stringify(config);

    const newActions = this.actions.slice();
    newActions[actionIndex] = action;
    this.actions = newActions;

    setTimeout(() => {
      this.updateActionViewModels();
    }, 10);
  }

  /**
   * 获取动作字段值
   */
  private getActionFieldValue(actionIndex: number, field: string): string {
    const action = this.actions[actionIndex];
    try {
      const config: Record<string, Object> = JSON.parse(action.config) as Record<string, Object>;
      return String(config[field] || '');
    } catch (error) {
      return '';
    }

    setTimeout(() => {
      this.updateActionViewModels();
    }, 10);
  }

  build() {
    Stack() {
      Column() {
        // iOS风格顶部导航栏
        Row() {
          // 左侧返回按钮（红色）
          Button() {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(20)
              .fontColor(['#ffffff'])
          }
          .width(36)
          .height(36)
          .backgroundColor('#FF3B30')
          .borderRadius(18)
          .onClick(() => {
            this.handleCancel();
          })

          // 中间标题
          Text(this.macroName || '未命名宏')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .flexGrow(1)
            .textAlign(TextAlign.Center)
            .margin({ left: 8, right: 8 })

          // 右侧按钮组
          Row({ space: 8 }) {
            // 设置按钮（蓝色）
            Button() {
              SymbolGlyph($r('sys.symbol.gearshape'))
                .fontSize(20)
                .fontColor(['#ffffff'])
            }
            .width(36)
            .height(36)
            .backgroundColor('#007AFF')
            .borderRadius(18)
            .onClick(() => {
              this.showSettings = true;
            })

            // 关闭按钮（灰色）
            Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(20)
                .fontColor(['#ffffff'])
            }
            .width(36)
            .height(36)
            .backgroundColor('#8E8E93')
            .borderRadius(18)
            .onClick(() => {
              router.back();
            })
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F2F2F7')
        .border({ width: { bottom: 1 }, color: '#E5E5EA' })

        // 主要内容区域（动作列表）
        Scroll() {
          Column({ space: 0 }) {
            // 动作列表
            if (this.actionViewModels.length === 0) {
              Column({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.list_bullet'))
                  .fontSize(64)
                  .fontColor(['#C7C7CC'])

                Text('暂无动作')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#8E8E93')

                Text('点击下方搜索栏添加动作')
                  .fontSize(14)
                  .fontColor('#8E8E93')
              }
              .width('100%')
              .padding({ top: 80 })
            } else {
              Column({ space: 0 }) {
                ForEach(this.actionViewModels, (viewModel: ActionViewModel, index: number) => {
                  this.ActionCardBuilder(viewModel, index)
                }, (viewModel: ActionViewModel, index: number) => {
                  const id = viewModel.id || 0;
                  const summary = viewModel.configSummary || '';
                  const valid = viewModel.isValid ? '1' : '0';
                  return `${index}_${id}_${summary}_${valid}`;
                })
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 80 })
        }
        .flexGrow(1)
        .scrollBar(BarState.Auto)
        .backgroundColor('#F2F2F7')

        // 底部操作栏
        Column() {
          Row({ space: 12 }) {
            // 撤销按钮
            Button() {
              SymbolGlyph($r('sys.symbol.undo'))
                .fontSize(20)
                .fontColor(['#007AFF'])
            }
            .width(44)
            .height(44)
            .backgroundColor('#F2F2F7')
            .borderRadius(22)
            .onClick(() => {
              // TODO: 实现撤销功能
            })

            // 重做按钮
            Button() {
              SymbolGlyph($r('sys.symbol.redo'))
                .fontSize(20)
                .fontColor(['#007AFF'])
            }
            .width(44)
            .height(44)
            .backgroundColor('#F2F2F7')
            .borderRadius(22)
            .onClick(() => {
              // TODO: 实现重做功能
            })

            // 分享按钮
            Button() {
              SymbolGlyph($r('sys.symbol.share'))
                .fontSize(20)
                .fontColor(['#007AFF'])
            }
            .width(44)
            .height(44)
            .backgroundColor('#F2F2F7')
            .borderRadius(22)
            .onClick(() => {
              // TODO: 实现分享功能
            })

            Blank()

            // 运行按钮（蓝色三角形）
            Button() {
              SymbolGlyph($r('sys.symbol.play_fill'))
                .fontSize(24)
                .fontColor(['#ffffff'])
            }
            .width(56)
            .height(56)
            .backgroundColor('#007AFF')
            .borderRadius(28)
            .onClick(() => {
              // TODO: 实现运行功能
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#ffffff')
          .border({ width: { top: 1 }, color: '#E5E5EA' })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F2F7')

      // 设置面板
      if (this.showSettings) {
        this.SettingsPanelBuilder()
      }

      // 动作抽屉
      if (this.showActionDrawer) {
        this.ActionDrawerBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
  // 获取过滤后的动作列表
  private getFilteredActions(): ActionInfo[] {
    let actions: ActionInfo[] = this.getAllActionInfos();

    if (this.selectedActionCategory !== 'all') {
      actions = actions.filter((action: ActionInfo): boolean => action.category === this.selectedActionCategory);
    }

    if (this.actionSearchText) {
      const searchLower = this.actionSearchText.toLowerCase();
      actions = actions.filter((action: ActionInfo): boolean =>
        action.displayName.toLowerCase().includes(searchLower) ||
        action.description.toLowerCase().includes(searchLower)
      );
    }

    return actions;
  }

  // 获取所有动作信息
  private getAllActionInfos(): ActionInfo[] {
    return [
      {
        type: ActionTypes.LAUNCH_APP,
        displayName: '启动应用',
        description: '打开指定的应用程序',
        icon: '📱',
        color: '#007AFF',
        category: 'system'
      },
      {
        type: ActionTypes.NOTIFICATION,
        displayName: '发送通知',
        description: '显示系统通知',
        icon: '🔔',
        color: '#FF9500',
        category: 'system'
      },
      {
        type: ActionTypes.CLIPBOARD_READ,
        displayName: '读取剪贴板',
        description: '获取剪贴板内容',
        icon: '📋',
        color: '#5856D6',
        category: 'text'
      },
      {
        type: ActionTypes.CLIPBOARD_WRITE,
        displayName: '写入剪贴板',
        description: '设置剪贴板内容',
        icon: '📝',
        color: '#5856D6',
        category: 'text'
      },
      {
        type: ActionTypes.HTTP_REQUEST,
        displayName: 'HTTP 请求',
        description: '发送网络请求',
        icon: '🌐',
        color: '#34C759',
        category: 'network'
      },
      {
        type: ActionTypes.OPEN_URL,
        displayName: '打开 URL',
        description: '在浏览器中打开链接',
        icon: '🔗',
        color: '#34C759',
        category: 'network'
      },
      {
        type: ActionTypes.TEXT_PROCESS,
        displayName: '文本处理',
        description: '正则、替换等操作',
        icon: '🔧',
        color: '#FF9500',
        category: 'text'
      },
      {
        type: ActionTypes.JSON_PROCESS,
        displayName: 'JSON 处理',
        description: '解析和查询 JSON',
        icon: '📦',
        color: '#FF9500',
        category: 'text'
      },
      {
        type: ActionTypes.USER_DIALOG,
        displayName: '用户对话框',
        description: '显示输入或选择对话框',
        icon: '💬',
        color: '#AF52DE',
        category: 'system'
      },
      {
        type: ActionTypes.SET_VARIABLE,
        displayName: '设置变量',
        description: '定义或修改变量值',
        icon: '🔑',
        color: '#5856D6',
        category: 'text'
      },
      {
        type: ActionTypes.IF_ELSE,
        displayName: '条件分支',
        description: '根据条件执行不同动作',
        icon: '🔀',
        color: '#FF3B30',
        category: 'system'
      }
    ];
  }

  // 根据类型添加动作
  private addActionByType(type: string) {
    switch (type) {
      case ActionTypes.LAUNCH_APP:
        this.addLaunchAppAction();
        break;
      case ActionTypes.NOTIFICATION:
        this.addNotificationAction();
        break;
      case ActionTypes.CLIPBOARD_READ:
        this.addClipboardReadAction();
        break;
      case ActionTypes.CLIPBOARD_WRITE:
        this.addClipboardWriteAction();
        break;
      case ActionTypes.HTTP_REQUEST:
        this.addHttpRequestAction();
        break;
      case ActionTypes.OPEN_URL:
        this.addOpenUrlAction();
        break;
      case ActionTypes.TEXT_PROCESS:
        this.addTextProcessAction();
        break;
      case ActionTypes.JSON_PROCESS:
        this.addJsonProcessAction();
        break;
      case ActionTypes.USER_DIALOG:
        this.addUserDialogAction();
        break;
      case ActionTypes.SET_VARIABLE:
        this.addSetVariableAction();
        break;
      case ActionTypes.IF_ELSE:
        this.addIfElseAction();
        break;
    }

    this.showActionDrawer = false;
  }

  // 获取动作图标
  private getActionIcon(viewModel: ActionViewModel): string {
    const actionInfo = this.getAllActionInfos().find((info: ActionInfo): boolean => info.type === viewModel.type);
    return actionInfo?.icon || '⚙️';
  }

  // 获取动作颜色
  private getActionColor(viewModel: ActionViewModel): string {
    const actionInfo = this.getAllActionInfos().find((info: ActionInfo): boolean => info.type === viewModel.type);
    return actionInfo?.color || '#8E8E93';
  }

}
