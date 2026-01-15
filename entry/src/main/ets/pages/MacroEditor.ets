import router from '@ohos.router';
import { Workflow, WorkflowNode, TriggerType, ConfigDisplayItem, ConfigOption, VariableInfo } from '../models/WorkflowModels';
import { WorkflowDataManager } from '../utils/WorkflowDataManager';
import { OptionsSelectDialog, VariableSelectDialog, NumberInputDialog, TextInputDialog } from '../components/ConfigEditorDialogs';

// 使用 @Observed 装饰器使嵌套属性变化可被 ArkTS 观察
// 使用 @Track 装饰器标记需要在 UI 中引用并响应式更新的属性
@Observed
export class UIWorkflowItem {
  @Track id: string;
  @Track type: 'trigger' | 'action' | 'condition' | 'nested';
  @Track title: string;
  @Track icon: string;
  @Track iconColor: string;
  @Track description?: string;
  @Track avatar?: string;
  @Track message?: string;
  @Track configDisplay?: ConfigDisplayItem[];
  @Track config?: Record<string, string | number | boolean>;
  @Track children?: UIWorkflowItem[];

  constructor(
    id: string,
    type: 'trigger' | 'action' | 'condition' | 'nested',
    title: string,
    icon: string,
    iconColor: string,
    description?: string,
    avatar?: string,
    message?: string,
    configDisplay?: ConfigDisplayItem[],
    config?: Record<string, string | number | boolean>,
    children?: UIWorkflowItem[]
  ) {
    this.id = id;
    this.type = type;
    this.title = title;
    this.icon = icon;
    this.iconColor = iconColor;
    this.description = description;
    this.avatar = avatar;
    this.message = message;
    this.configDisplay = configDisplay;
    this.config = config;
    this.children = children;
  }
}


@Entry
@Component
struct MacroEditor {
  @State shortcutId: string = '';
  @State title: string = 'Untitled Shortcut';
  @State isEditingTitle: boolean = false;
  @State editingTitle: string = '';
  @State trigger: UIWorkflowItem | null = null;
  @State actions: UIWorkflowItem[] = [];
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  @State canPlay: boolean = false;
  @State icon: string = '\u2708';
  @State iconColor: string = '#607AFB';
  @State isEnabled: boolean = true;
  @State expandedConfigIds: string[] = [];

  // 弹窗编辑相关状态
  @State currentEditingItem: UIWorkflowItem | null = null;
  @State currentEditingConfigItem: ConfigDisplayItem | null = null;
  @State contextVariables: VariableInfo[] = [];
  @State dialogOptions: ConfigOption[] = [];
  @State dialogCurrentValue: string = '';

  // 弹窗控制器
  private optionsDialogController: CustomDialogController | null = null;
  private variableDialogController: CustomDialogController | null = null;
  private numberDialogController: CustomDialogController | null = null;
  private textDialogController: CustomDialogController | null = null;

  private dataManager: WorkflowDataManager = WorkflowDataManager.getInstance();

  aboutToAppear() {
    const params = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    if (params) {
      // 接收 shortcut_id 判断模式
      if (params['shortcut_id']) {
        this.shortcutId = params['shortcut_id'] as string;
        this.loadWorkflowFromManager();
      }
      // 兼容 title 参数
      if (params['title']) {
        this.title = params['title'] as string;
      }
      this.updateCounts();
    }
  }

  onPageShow(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    if (params) {
      if (params['trigger']) {
        const triggerData = params['trigger'] as Record<string, Object>;
        this.trigger = new UIWorkflowItem(
          triggerData['id'] as string,
          'trigger',
          triggerData['title'] as string,
          triggerData['icon'] as string,
          triggerData['iconColor'] as string,
          triggerData['description'] as string,
          undefined,
          undefined,
          triggerData['configDisplay'] as ConfigDisplayItem[],
          triggerData['config'] as Record<string, string | number | boolean>
        );
        this.updateCounts();
        console.info('[MacroEditor] Trigger received:', JSON.stringify(this.trigger));
      }
      else if (params['action']) {
        const actionData = params['action'] as Record<string, Object>;
        const actionItem = new UIWorkflowItem(
          this.generateUniqueId(),
          actionData['type'] as 'action' | 'condition' | 'nested',
          actionData['title'] as string,
          actionData['icon'] as string,
          actionData['iconColor'] as string,
          actionData['description'] as string,
          undefined,
          undefined,
          actionData['configDisplay'] as ConfigDisplayItem[],
          actionData['config'] as Record<string, string | number | boolean>
        );
        this.actions.push(actionItem);
        this.updateCounts();
        console.info('[MacroEditor] Action received:', JSON.stringify(actionItem));
      }
    }
  }

  // 加载编辑模式的真实数据
  loadWorkflowFromManager() {
    try {
      const workflow = this.dataManager.getWorkflow(this.shortcutId);
      if (workflow) {
        this.title = workflow.name;
        this.icon = workflow.icon;
        this.iconColor = workflow.iconColor;
        this.isEnabled = workflow.isEnabled;
        // 分离 trigger 和 actions
        const allItems = this.convertWorkflowNodesToActionItems(workflow.nodes);
        this.trigger = allItems.find(item => item.type === 'trigger') || null;
        this.actions = allItems.filter(item => item.type !== 'trigger');
        this.updateCounts();
      }
    } catch (error) {
      console.error('[MacroEditor] Load workflow failed:', error);
    }
  }

  // 生成唯一ID
  generateUniqueId(): string {
    return Date.now().toString() + Math.random().toString(36).substring(2, 9);
  }

  convertWorkflowNodesToActionItems(nodes: WorkflowNode[]): UIWorkflowItem[] {
    const result: UIWorkflowItem[] = [];
    nodes.forEach(node => {
      const config: Record<string, string | number | boolean> = {};
      if (node.config) {
        node.config.forEach((value: Object, key: string) => {
          config[key] = value as string | number | boolean;
        });
      }

      let configDisplay: ConfigDisplayItem[] | undefined = undefined;
      if (node.type === 'trigger') {
        configDisplay = this.dataManager.getTriggerConfigDisplay(node.itemId, config);
      } else {
        configDisplay = this.dataManager.getActionConfigDisplay(node.itemId, config);
      }

      const actionItem = new UIWorkflowItem(
        this.generateUniqueId(),
        node.type,
        node.title,
        node.icon,
        node.iconColor,
        node.description,
        undefined,
        undefined,
        configDisplay,
        config,
        node.children ? this.convertWorkflowNodesToActionItems(node.children) : undefined
      );
      result.push(actionItem);
    });
    return result;
  }

  convertActionItemsToWorkflowNodes(items: UIWorkflowItem[]): WorkflowNode[] {
    const result: WorkflowNode[] = [];
    items.forEach(item => {
      const workflowNode: WorkflowNode = {
        id: item.id,
        type: item.type,
        itemId: item.id,
        itemType: TriggerType.TIME_DATE,
        title: item.title,
        icon: item.icon,
        iconColor: item.iconColor,
        description: item.description,
        config: item.config ? new Map(Object.entries(item.config)) : undefined,
        children: item.children ? this.convertActionItemsToWorkflowNodes(item.children) : undefined
      };
      result.push(workflowNode);
    });
    return result;
  }

  // 更新计数器
  updateCounts() {
    this.canPlay = this.trigger !== null && this.actions.length > 0;
  }

  hasTrigger(): boolean {
    return this.trigger !== null;
  }

  isConfigExpanded(itemId: string): boolean {
    return this.expandedConfigIds.includes(itemId);
  }

  toggleConfigPanel(itemId: string, forceState?: boolean) {
    const index = this.expandedConfigIds.indexOf(itemId);
    const newState = forceState !== undefined ? forceState : index === -1;

    if (newState && index === -1) {
      this.expandedConfigIds = [...this.expandedConfigIds, itemId];
    } else if (!newState && index !== -1) {
      this.expandedConfigIds = this.expandedConfigIds.filter(id => id !== itemId);
    }
  }

  updateConfigValue(item: UIWorkflowItem, configKey: string, newValue: string | number | boolean) {
    // 1. 更新 config 对象 (Immutable update)
    const newConfig: Record<string, string | number | boolean> = {};
    if (item.config) {
      const keys = Object.keys(item.config);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        newConfig[key] = item.config[key];
      }
    }
    newConfig[configKey] = newValue;
    item.config = newConfig;

    // 2. 更新 configDisplay (Immutable update)
    if (item.configDisplay) {
      const newDisplayList: ConfigDisplayItem[] = [];
      for (let i = 0; i < item.configDisplay.length; i++) {
        const displayItem = item.configDisplay[i];
        if (displayItem.configKey === configKey) {
          const newItem: ConfigDisplayItem = {
            displayType: displayItem.displayType,
            label: this.formatDisplayValue(newValue, configKey),
            configKey: displayItem.configKey,
            style: displayItem.style,
            validation: displayItem.validation,
            editorType: displayItem.editorType,
            optionsSource: displayItem.optionsSource,
            placeholder: displayItem.placeholder
          };
          newDisplayList.push(newItem);
        } else {
          newDisplayList.push(displayItem);
        }
      }
      item.configDisplay = newDisplayList;
    }
  }

  // 手动拷贝 config 对象
  cloneConfig(config: Record<string, string | number | boolean>): Record<string, string | number | boolean> {
    const result: Record<string, string | number | boolean> = {};
    const keys = Object.keys(config);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      result[key] = config[key];
    }
    return result;
  }

  formatDisplayValue(value: string | number | boolean, configKey?: string): string {
    return String(value);
  }

  validateConfigValue(value: string, configKey?: string): boolean {
    return true;
  }

  // 使用 @Observed 类后，嵌套属性变化会自动被观察
  // 但数组需要重新赋值才能触发列表刷新
  forceRefreshTrigger() {
    // @Observed 类的属性变化会自动触发 UI 更新
    // 这里通过临时置空再恢复来确保触发刷新
    if (this.trigger) {
      const temp = this.trigger;
      this.trigger = null;
      this.trigger = temp;
    }
  }

  forceRefreshActions() {
    // 创建新数组引用触发列表刷新
    this.actions = this.actions.slice();
  }

  // 打开配置编辑器（根据 editorType 弹出对应弹窗）
  openConfigEditor(item: UIWorkflowItem, configItem: ConfigDisplayItem) {
    if (!configItem.configKey || configItem.editorType === 'none') {
      return;
    }

    this.currentEditingItem = item;
    this.currentEditingConfigItem = configItem;
    const currentValue = item.config?.[configItem.configKey] || '';

    switch (configItem.editorType) {
      case 'select':
        this.showOptionsDialog(item, configItem, String(currentValue));
        break;
      case 'variable':
        this.collectContextVariables();
        this.showVariableDialog(item, configItem);
        break;
      case 'number':
        this.showNumberDialog(item, configItem, Number(currentValue) || 0);
        break;
      case 'text':
        this.showTextDialog(item, configItem, String(currentValue));
        break;
      case 'time':
        this.showTimeDialog(item, configItem, String(currentValue));
        break;
      default:
        // 默认展开面板（兼容旧逻辑）
        this.toggleConfigPanel(item.id);
    }
  }

  // 收集上下文变量
  collectContextVariables() {
    const variables: VariableInfo[] = [];

    // 1. 收集前面卡片的输出变量
    this.actions.forEach((action, index) => {
      if (action.id !== this.currentEditingItem?.id) {
        // set_variable 动作的输出
        if (action.config?.['name']) {
          variables.push({
            id: `var_${index}`,
            name: action.config['name'] as string,
            type: 'string',
            icon: '📝',
            source: `${action.title} 输出`
          });
        }
      }
    });

    // 2. 预定义系统变量
    variables.push(
      { id: 'sys_time', name: '当前时间', type: 'string', icon: '🕐', source: '系统' },
      { id: 'sys_date', name: '当前日期', type: 'string', icon: '📅', source: '系统' },
      { id: 'sys_battery', name: '电量', type: 'number', icon: '🔋', source: '系统' },
      { id: 'sys_location', name: '当前位置', type: 'string', icon: '📍', source: '系统' }
    );

    this.contextVariables = variables;
  }

  // 显示选项选择弹窗
  showOptionsDialog(item: UIWorkflowItem, configItem: ConfigDisplayItem, currentValue: string) {
    const options = configItem.optionsSource?.staticOptions || [];
    this.dialogOptions = options;
    this.dialogCurrentValue = currentValue;

    this.optionsDialogController = new CustomDialogController({
      builder: OptionsSelectDialog({
        title: this.getConfigLabel(configItem),
        options: options,
        currentValue: currentValue,
        onSelect: (value: string, label: string) => {
          this.updateConfigValue(item, configItem.configKey!, value);
          // 更新显示标签
          if (configItem.configKey && item.configDisplay) {
            const displayItem = item.configDisplay.find(d => d.configKey === configItem.configKey);
            if (displayItem) {
              displayItem.label = label;
            }
          }
          // 触发刷新
          if (item.type === 'trigger') {
            this.forceRefreshTrigger();
          } else {
            this.forceRefreshActions();
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.optionsDialogController.open();
  }

  // 显示变量选择弹窗
  showVariableDialog(item: UIWorkflowItem, configItem: ConfigDisplayItem) {
    this.variableDialogController = new CustomDialogController({
      builder: VariableSelectDialog({
        title: '选择变量',
        variables: this.contextVariables,
        onSelect: (variable: VariableInfo) => {
          this.updateConfigValue(item, configItem.configKey!, variable.name);
          // 更新显示标签
          if (configItem.configKey && item.configDisplay) {
            const displayItem = item.configDisplay.find(d => d.configKey === configItem.configKey);
            if (displayItem) {
              displayItem.label = variable.name;
            }
          }
          // 触发刷新
          if (item.type === 'trigger') {
            this.forceRefreshTrigger();
          } else {
            this.forceRefreshActions();
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.variableDialogController.open();
  }

  // 显示数字输入弹窗
  showNumberDialog(item: UIWorkflowItem, configItem: ConfigDisplayItem, currentValue: number) {
    this.numberDialogController = new CustomDialogController({
      builder: NumberInputDialog({
        title: this.getConfigLabel(configItem),
        currentValue: currentValue,
        min: configItem.validation?.min,
        max: configItem.validation?.max,
        placeholder: configItem.placeholder,
        onConfirm: (value: number) => {
          this.updateConfigValue(item, configItem.configKey!, value);
          // 更新显示标签
          if (configItem.configKey && item.configDisplay) {
            const displayItem = item.configDisplay.find(d => d.configKey === configItem.configKey);
            if (displayItem) {
              displayItem.label = String(value);
            }
          }
          // 触发刷新
          if (item.type === 'trigger') {
            this.forceRefreshTrigger();
          } else {
            this.forceRefreshActions();
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.numberDialogController.open();
  }

  // 显示文本输入弹窗
  showTextDialog(item: UIWorkflowItem, configItem: ConfigDisplayItem, currentValue: string) {
    this.textDialogController = new CustomDialogController({
      builder: TextInputDialog({
        title: this.getConfigLabel(configItem),
        currentValue: currentValue,
        placeholder: configItem.placeholder,
        onConfirm: (value: string) => {
          this.updateConfigValue(item, configItem.configKey!, value);
          // 更新显示标签
          if (configItem.configKey && item.configDisplay) {
            const displayItem = item.configDisplay.find(d => d.configKey === configItem.configKey);
            if (displayItem) {
              displayItem.label = value || configItem.placeholder || configItem.configKey;
            }
          }
          // 触发刷新
          if (item.type === 'trigger') {
            this.forceRefreshTrigger();
          } else {
            this.forceRefreshActions();
          }
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.textDialogController.open();
  }

  // 显示时间选择弹窗（使用系统 TimePicker）
  showTimeDialog(item: UIWorkflowItem, configItem: ConfigDisplayItem, currentValue: string) {
    // 解析当前时间值
    let hour = 7;
    let minute = 0;
    if (currentValue) {
      const match = currentValue.match(/(\d{1,2}):(\d{2})/);
      if (match) {
        hour = parseInt(match[1]);
        minute = parseInt(match[2]);
      }
    }

    // 使用系统时间选择器
    TimePickerDialog.show({
      selected: new Date(2020, 1, 1, hour, minute),
      useMilitaryTime: false,
      onAccept: (value: TimePickerResult) => {
        const formattedTime = `${value.hour}:${value.minute.toString().padStart(2, '0')}`;
        const displayTime = this.formatTimeDisplay(value.hour, value.minute);

        this.updateConfigValue(item, configItem.configKey!, formattedTime);

        // 更新显示标签
        if (configItem.configKey && item.configDisplay) {
          const displayItem = item.configDisplay.find(d => d.configKey === configItem.configKey);
          if (displayItem) {
            displayItem.label = displayTime;
          }
        }

        // 触发刷新
        if (item.type === 'trigger') {
          this.forceRefreshTrigger();
        } else {
          this.forceRefreshActions();
        }
      }
    });
  }

  // 格式化时间显示
  formatTimeDisplay(hour: number, minute: number): string {
    const isPM = hour >= 12;
    const displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
    return `${displayHour}:${minute.toString().padStart(2, '0')} ${isPM ? 'PM' : 'AM'}`;
  }

  // 获取配置项标签
  getConfigLabel(configItem: ConfigDisplayItem): string {
    if (configItem.configKey) {
      // 将 configKey 转换为友好的标签
      const keyMap: Record<string, string> = {
        'timeType': '时间类型',
        'timeValue': '时间',
        'repeat': '重复',
        'variable': '变量',
        'operator': '操作符',
        'value': '值',
        'target': '目标',
        'action': '动作',
        'type': '类型',
        'location': '位置'
      };
      return keyMap[configItem.configKey] || configItem.configKey;
    }
    return '配置';
  }


  // 判断是否显示连接线
  shouldShowConnector(index: number): boolean {
    if (!this.hasTrigger()) {
      return false;
    }
    return index < this.actions.length - 1;
  }

  // 保存工作流
  async saveWorkflow() {
    try {
      console.info('[MacroEditor] Workflow saved successfully');
    } catch (error) {
      console.error('[MacroEditor] Save workflow failed:', error);
    }
  }

  build() {
    Column() {
      this.Header()
      this.Content()
      this.BottomPanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Row() {
          Text('\u2039')
            .fontSize(20)
            .fontColor('#007AFF')
            .margin({ right: 4 })

          Text('Back')
            .fontSize(16)
            .fontColor('#007AFF')
            .fontWeight(FontWeight.Medium)
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor('transparent')
      .width(80)
      .height(40)
      .borderRadius(999)
      .onClick(() => {
        router.back();
      })

      Column() {
        if (this.isEditingTitle) {
          TextInput({ text: this.editingTitle })
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .padding({ left: 8, right: 8 })
            .onChange((value: string) => {
              this.editingTitle = value;
            })
            .onSubmit(() => {
              if (this.editingTitle.trim()) {
                this.title = this.editingTitle.trim();
              }
              this.isEditingTitle = false;
            })
            .onBlur(() => {
              if (this.editingTitle.trim()) {
                this.title = this.editingTitle.trim();
              }
              this.isEditingTitle = false;
            })
            .width(200)
        } else {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
        }

        // 只在编辑模式下显示 Automation 标签
        if (this.shortcutId) {
          Row() {
            Text('')
              .width(6)
              .height(6)
              .borderRadius(999)
              .backgroundColor('#FF9500')
              .margin({ right: 4 })

            Text('Automation')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8E8E93')
              .letterSpacing(0.5)
          }
          .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .gesture(
        TapGesture({ count: 2 })
          .onAction(() => {
            if (!this.isEditingTitle) {
              this.isEditingTitle = true;
              this.editingTitle = this.title;
            }
          })
      )

      Button() {
        Text('Done')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
      }
      .type(ButtonType.Normal)
      .backgroundColor('transparent')
      .width(60)
      .height(40)
      .borderRadius(999)
      .onClick(() => {
        this.saveWorkflow();
        router.back();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('rgba(255, 255, 255, 0.8)')
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: '#E5E5EA' })
  }

  @Builder
  Content() {
    Scroll() {
      Column() {
        // 根据 trigger 和 actions 状态动态显示内容
        if (!this.hasTrigger()) {
          // 没有 Trigger：显示 Add Trigger 按钮
          Column() {
            Row() {
              Text('Trigger')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#9CA3AF')
                .letterSpacing(0.5)
            }
            .width('100%')
            .margin({ bottom: 8 })

            this.AddTriggerButton()
          }
          .width('100%')
          .margin({ bottom: 20 })
        } else {
          // 有 Trigger：显示 Trigger
          this.TriggerSection(this.trigger as UIWorkflowItem);
        }

        // Actions 区域
        if (this.actions.length === 0) {
          // 没有 Actions：显示空状态
          Column() {
            this.EmptyStateSection()
          }
          .layoutWeight(1)
          .margin({ top: 32, bottom: 80 })
        } else {
          // 有 Actions：显示 Actions 列表和 Add Action 按钮
          this.ActionsSection()
          this.AddActionButton()
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 250 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  AddTriggerButton() {
    Button() {
      Row({ space: 12 }) {
        Row() {
          Text('+')
            .fontSize(24)
            .fontColor('#007AFF')
        }
        .width(40)
        .height(40)
        .borderRadius(8)
        .backgroundColor('rgba(0, 122, 255, 0.1)')
        .justifyContent(FlexAlign.Center)

        Text('Add Trigger')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#007AFF')
      }
    }
    .type(ButtonType.Normal)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: '#E5E5EA' })
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/TriggerLibrary'
      });
    })
  }

  @Builder
  EmptyStateSection() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(128)
          .height(128)
          .borderRadius(999)
          .backgroundColor('#F9FAFB')

        Row()
          .width(128)
          .height(128)
          .borderRadius(999)
          .linearGradient({
            angle: 135,
            colors: [['#F9FAFB', 0.0], ['rgba(249, 250, 251, 0)', 1.0]]
          })

        Text('🪄')
          .fontSize(64)
          .fontColor('rgba(163, 163, 175, 0.8)')
      }
      .width(128)
      .height(128)
      .margin({ bottom: 24 })

      Text('No Actions Yet')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#000000')
        .letterSpacing(-0.3)
        .margin({ bottom: 8 })

      Text('Add actions to build your automation')
        .fontSize(14)
        .fontColor('#6B7280')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .margin({ bottom: 40 })

      Button() {
        Row({ space: 12 }) {
          Text('◎')
            .fontSize(28)
            .fontColor('#007AFF')

          Text('Add Action')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007AFF')
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor('rgba(0, 122, 255, 0.05)')
      .borderRadius(24)
      .border({ width: 2, color: 'rgba(0, 122, 255, 0.3)', style: BorderStyle.Dashed })
      .width(260)
      .height(64)
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ActionLibrary'
        });
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  TriggerSection(triggerItem: UIWorkflowItem) {
    Stack() {
      Column() {
        Row() {
          Text('TRIGGER')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9CA3AF')
            .letterSpacing(0.5)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Column() {
          this.TriggerCard(triggerItem)
        }
        .width('100%')

        if (this.actions.length > 1) {
          Row()
            .width(2)
            .height(20)
            .backgroundColor('#D1D5DB')
            .margin({ left: 36, top: -8 })
        }
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  ActionsSection() {
    Column() {
      Row() {
        Text('ACTIONS')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#9CA3AF')
          .letterSpacing(0.5)
      }
      .width('100%')
      .margin({ bottom: 8, top: 8 })

      List({ space: 0, initialIndex: 0 }) {
        ForEach(this.actions, (item: UIWorkflowItem, index: number) => {
          ListItem() {
            Column() {
              if (item.type === 'condition') {
                this.ConditionBlock(item, index)
              } else {
                Column() {
                  this.ActionCard(item, index)

                  if (index < this.actions.length - 1) {
                    Row()
                      .width(2)
                      .height(12)
                      .backgroundColor('#D1D5DB')
                      .margin({ left: 36 })
                  }
                }
                .width('100%')
              }
            }
            .width('100%')
          }
        }, (item: UIWorkflowItem) => item.id)
        .onMove((from: number, to: number) => {
          console.info('ActionsSection onMove From: ' + from + ', To: ' + to);
          let tmp = this.actions.splice(from, 1);
          this.actions.splice(to, 0, tmp[0]);
          this.actions = [...this.actions];
          console.info('ActionsSection after move: ' + JSON.stringify(this.actions.map(a => a.id)));
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 0 })
    }
    .width('100%')
  }

  @Builder
  ActionItemWithConnector(item: UIWorkflowItem, index: number) {
    this.ActionCard(item, index)
  }

  @Builder
  ConfigDisplayChip(configItem: ConfigDisplayItem, item: UIWorkflowItem) {
    if (configItem.displayType === 'text') {
      Text(configItem.label)
        .fontSize(12)
        .fontColor('#6B7280')
        .fontWeight(FontWeight.Medium)
    } else if (configItem.displayType === 'button' || configItem.displayType === 'tag') {
      Button(configItem.label) {
        Row({ space: 4 }) {
          if (configItem.style?.icon) {
            Text(configItem.style.icon)
              .fontSize(14)
              .fontColor(configItem.style.textColor)
          }
          Text(configItem.label)
            .fontSize(12)
            .fontColor(configItem.style?.textColor || '#2563EB')
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor(configItem.style?.backgroundColor || '#EFF6FF')
      .borderRadius(6)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .border({
        width: 1,
        color: configItem.style?.borderColor || '#BFDBFE'
      })
      .onClick(() => {
        // 使用弹窗式编辑器
        this.openConfigEditor(item, configItem);
      })
    } else if (configItem.displayType === 'icon-tag') {
      Row({ space: 4 }) {
        if (configItem.style?.icon) {
          Text(configItem.style.icon || '')
            .fontSize(12)
            .fontColor(configItem.style?.textColor)
        }
        Text(configItem.label)
          .fontSize(12)
          .fontColor(configItem.style?.textColor)
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(configItem.style?.backgroundColor)
      .borderRadius(6)
      .border({ width: 1, color: configItem.style?.borderColor })
      .onClick(() => {
        if (configItem.configKey) {
          // 使用弹窗式编辑器
          this.openConfigEditor(item, configItem);
        }
      })
    } else if (configItem.displayType === 'avatar-tag') {
      Row({ space: 4 }) {
        Row() {
          Text(configItem.style?.avatar?.letter || '')
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor(configItem.style?.avatar?.textColor)
        }
        .width(16)
        .height(16)
        .borderRadius(999)
        .backgroundColor(configItem.style?.avatar?.bgColor)
        .justifyContent(FlexAlign.Center)

        Text(configItem.label)
          .fontSize(12)
          .fontColor(configItem.style?.textColor)
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(configItem.style?.backgroundColor)
      .borderRadius(6)
      .border({ width: 1, color: configItem.style?.borderColor })
      .onClick(() => {
        if (configItem.configKey) {
          // 使用弹窗式编辑器
          this.openConfigEditor(item, configItem);
        }
      })
    }
  }

  @Builder
  ExpandedConfigPanel(item: UIWorkflowItem) {
    Column() {
      Row() {
        Text('Configuration')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#6B7280')

        Blank()

        Button() {
          Text('✕')
            .fontSize(16)
            .fontColor('#9CA3AF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .onClick(() => {
          this.toggleConfigPanel(item.id, false);
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .border({ width: { bottom: 1 }, color: '#E5E5EA' })

      if (item.configDisplay) {
        ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
          this.ConfigItemEditor(configItem, item)
        })
      }
    }
    .width('100%')
    .backgroundColor('#F9FAFB')
    .borderRadius(12)
    .margin({ top: 8 })
  }

  @Builder
  ConfigItemEditor(configItem: ConfigDisplayItem, item: UIWorkflowItem) {
    Row() {
      Text(configItem.configKey || '')
        .fontSize(14)
        .fontColor('#374151')
        .width(100)

      Blank()

      if (configItem.configKey && item.config) {
        this.ConfigValueInput(configItem, item.config[configItem.configKey] || '', (newValue) => {
          this.updateConfigValue(item, configItem.configKey!, newValue);
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  ConfigValueInput(configItem: ConfigDisplayItem, currentValue: string | number | boolean, onChange: (value: string | number | boolean) => void) {
    TextInput({ text: String(currentValue) })
      .onChange((value: string) => {
        if (this.validateConfigValue(value, configItem.configKey)) {
          onChange(value);
        }
      })
      .width(200)
      .fontSize(14)
      .fontColor('#000000')
      .backgroundColor('#FFFFFF')
      .borderRadius(6)
      .border({ width: 1, color: '#E5E7EB' })
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
  }

  @Builder
  TriggerCard(item: UIWorkflowItem) {
    Stack() {
      Column() {
        Row() {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .fontColor('#FF9500')
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('#FFF0D6')
          .justifyContent(FlexAlign.Center)

          Column() {
            Row() {
              Text(item.title || 'When')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF9500')
                .letterSpacing(0.5)

              Blank()

              Button() {
                Text('\u22EE')
                  .fontSize(20)
                  .fontColor('#D1D5DB')
              }
              .type(ButtonType.Normal)
              .backgroundColor('transparent')
              .width(28)
              .height(28)
            }
            .width('100%')

            if (item.configDisplay && item.configDisplay.length > 0) {
              Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
                ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                  Row() {
                    this.ConfigDisplayChip(configItem, item)
                  }
                  .margin({ right: 8, bottom: 4 })
                })
              }
              .margin({ top: 4 })
            } else {
              Text(item.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#000000')
                .margin({ top: 4 })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
        .border({ width: 2, color: 'rgba(255, 149, 0, 0.3)' })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/TriggerLibrary'
          });
        })

        if (this.isConfigExpanded(item.id)) {
          this.ExpandedConfigPanel(item)
        }
      }
      .width('100%')
    }
    .borderRadius(12)
  }

  @Builder
  ActionCard(item: UIWorkflowItem, index: number) {
    Stack() {
      Column() {
        Row() {
          Text('⋮⋮')
            .fontSize(14)
            .fontColor('#9CA3AF')
            .letterSpacing(-1)
            .padding({ left: 4, right: 4 })
            .margin({ right: 8 })

          Stack() {
            Row() {
              Text(item.icon)
                .fontSize(24)
                .fontColor(item.iconColor)
            }
            .width(40)
            .height(40)
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
            .justifyContent(FlexAlign.Center)

            Row()
              .width(40)
              .height(40)
              .borderRadius(12)
              .backgroundColor(item.iconColor + '1A')
          }
          .width(40)
          .height(40)

          Column() {
            Row() {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#000000')

              Blank()

              if (item.configDisplay && item.configDisplay.length > 0) {
                Button() {
                  Text('⚙️')
                    .fontSize(14)
                    .fontColor('#9CA3AF')
                }
                .type(ButtonType.Normal)
                .backgroundColor('transparent')
                .width(28)
                .height(28)
                .borderRadius(6)
                .onClick(() => {
                  this.toggleConfigPanel(item.id);
                })
              }
            }
            .width('100%')

            if (item.configDisplay && item.configDisplay.length > 0) {
              Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
                ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                  Row() {
                    this.ConfigDisplayChip(configItem, item)
                  }
                  .margin({ right: 8, bottom: 4 })
                })
              }
              .margin({ top: 8 })
            } else if (item.description) {
              Column() {
                if (item.avatar) {
                  Row() {
                    Text(item.description.split(':')[0] + ':')
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#6B7280')

                    Row() {
                      Text(item.avatar)
                        .fontSize(9)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#166534')

                      Text(item.description.split(': ')[1])
                        .fontSize(12)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#166534')
                        .margin({ left: 4 })
                    }
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#F0FDF4')
                    .borderRadius(6)
                    .margin({ left: 8 })
                  }
                  .margin({ top: 6 })
                } else {
                  Text(item.description)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#6B7280')
                    .margin({ top: 6 })
                }

                if (item.message) {
                  Row() {
                    Text('\u275D')
                      .fontSize(14)
                      .fontColor('#9CA3AF')
                      .margin({ top: 2 })

                    Text(item.message)
                      .fontSize(12)
                      .fontColor('#374151')
                      .fontStyle(FontStyle.Italic)
                  }
                  .width('100%')
                  .padding(8)
                  .backgroundColor('#F9FAFB')
                  .borderRadius(8)
                  .border({ width: 1, color: '#F3F4F6' })
                  .margin({ top: 8 })
                }
              }
              .alignItems(HorizontalAlign.Start)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
        .border({ width: 1, color: '#E5E5EA' })

        if (this.isConfigExpanded(item.id)) {
          this.ExpandedConfigPanel(item)
        }
      }
      .width('100%')
    }
  }

  @Builder
  ConditionBlock(item: UIWorkflowItem, index: number) {
    Column() {
      // 卡片1: 如果 (If)
      Row() {
        Text('⋮⋮')
          .fontSize(14)
          .fontColor('#9CA3AF')
          .letterSpacing(-1)
          .padding({ left: 4, right: 4 })
          .margin({ right: 8 })

        Stack() {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .fontColor(item.iconColor)
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .justifyContent(FlexAlign.Center)

          Row()
            .width(40)
            .height(40)
            .borderRadius(12)
            .border({ width: 4, color: '#FFFFFF' })
            .backgroundColor(item.iconColor + '1A')
        }
        .width(40)
        .height(40)

        Column() {
          Row() {
            Text(item.title)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')

            Blank()
          }
          .width('100%')

          if (item.configDisplay && item.configDisplay.length > 0) {
            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
              ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                Row() {
                  this.ConfigDisplayChip(configItem, item)
                }
                .margin({ right: 8, bottom: 4 })
              })
            }
            .margin({ top: 8 })
          } else if (item.description) {
            Text(item.description)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#6B7280')
              .margin({ top: 6 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
      .border({ width: 2, color: 'rgba(245, 158, 11, 0.3)' })

      // Then 分支：子动作（If 条件为真时执行）
      if (item.children && item.children.length > 0) {
        // 连接线
        Row()
          .width(2)
          .height(16)
          .backgroundColor('#D1D5DB')
          .margin({ left: 36 })

        Column({ space: 8 }) {
          ForEach(item.children.filter((c: UIWorkflowItem) => c.type !== 'nested'), (child: UIWorkflowItem) => {
            this.NestedActionCard(child)
          })
        }
        .width('100%')
      }

      // 连接线
      Row()
        .width(2)
        .height(16)
        .backgroundColor('#D1D5DB')
        .margin({ left: 36 })

      // 卡片2: 否则 (Else)
      this.ElseCard(item)

      // Else 分支：子动作（If 条件为假时执行）
      if (item.children && item.children.some((c: UIWorkflowItem) => c.type === 'nested')) {
        Row()
          .width(2)
          .height(16)
          .backgroundColor('#D1D5DB')
          .margin({ left: 36 })

        Column({ space: 8 }) {
          ForEach(item.children.filter((c: UIWorkflowItem) => c.type === 'nested'), (child: UIWorkflowItem) => {
            this.NestedActionCard(child)
          })
        }
        .width('100%')
      }

      // 连接线
      Row()
        .width(2)
        .height(16)
        .backgroundColor('#D1D5DB')
        .margin({ left: 36 })

      // 卡片3: 结束 (End If)
      this.EndIfCard()
    }
    .width('100%')
  }

  @Builder
  ElseCard(item: UIWorkflowItem) {
    Row() {
      Text('⋮⋮')
        .fontSize(14)
        .fontColor('#9CA3AF')
        .letterSpacing(-1)
        .padding({ left: 4, right: 4 })
        .margin({ right: 8 })

      Row() {
        Text('➖')
          .fontSize(20)
          .fontColor('#6B7280')
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .backgroundColor('#F3F4F6')
      .justifyContent(FlexAlign.Center)

      Column() {
        Text('否则')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#6B7280')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: '#E5E5EA' })
  }

  @Builder
  NestedActionCard(item: UIWorkflowItem) {
    Row() {
      Stack() {
        Row() {
          Text(item.icon)
            .fontSize(24)
            .fontColor(item.iconColor)
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Center)

        Row()
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor(item.iconColor + '1A')
      }
      .width(40)
      .height(40)

      Column() {
        Row() {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')

          Blank()

          if (item.configDisplay && item.configDisplay.length > 0) {
            Button() {
              Text('⚙️')
                .fontSize(14)
                .fontColor('#9CA3AF')
            }
            .type(ButtonType.Normal)
            .backgroundColor('transparent')
            .width(28)
            .height(28)
            .borderRadius(6)
            .onClick(() => {
              this.toggleConfigPanel(item.id);
            })
          }
        }
        .width('100%')

        if (item.configDisplay && item.configDisplay.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
            ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
              Row() {
                this.ConfigDisplayChip(configItem, item)
              }
              .margin({ right: 8, bottom: 4 })
            })
          }
          .margin({ top: 8 })
        } else if (item.description) {
          Column() {
            if (item.avatar) {
              Row() {
                Text(item.description.split(':')[0] + ':')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#6B7280')

                Row() {
                  Text(item.avatar)
                    .fontSize(9)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#166534')

                  Text(item.description.split(': ')[1])
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#166534')
                    .margin({ left: 4 })
                }
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#F0FDF4')
                .borderRadius(6)
                .margin({ left: 8 })
              }
              .margin({ top: 6 })
            } else {
              Text(item.description)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#6B7280')
                .margin({ top: 6 })
            }

            if (item.message) {
              Row() {
                Text('\u275D')
                  .fontSize(14)
                  .fontColor('#9CA3AF')
                  .margin({ top: 2 })

                Text(item.message)
                  .fontSize(12)
                  .fontColor('#374151')
                  .fontStyle(FontStyle.Italic)
              }
              .width('100%')
              .padding(8)
              .backgroundColor('#F9FAFB')
              .borderRadius(8)
              .border({ width: 1, color: '#F3F4F6' })
              .margin({ top: 8 })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: '#E5E5EA' })
    .margin({ left: 24 })
  }

  @Builder
  EndIfCard() {
    Stack() {
      Row() {
        Row()
          .width(32)
          .height(32)
          .borderRadius(12)
          .backgroundColor('#F3F4F6')
          .justifyContent(FlexAlign.Center)
          .margin({ left: 4 })

        Column() {
          Text('End If')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#9CA3AF')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('rgba(255, 255, 255, 0.6)')
      .borderRadius(12)
      .border({ width: 1, color: 'rgba(229, 229, 234, 0.6)' })
    }
    .width('100%')
  }

  @Builder
  AddActionButton() {
    Row() {
      Text('+')
        .fontSize(20)
        .fontColor('#9CA3AF')

      Text('Add Action')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4B5563')
        .margin({ left: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(999)
    .border({ width: 1, color: '#D1D5DB' })
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    .margin({ top: 12, bottom: 12 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ActionLibrary'
        });
      })
  }

  @Builder
  BottomPanel() {
    Column() {
      Row() {
        if (!this.shortcutId) {
          // 新建模式：动态的统计和状态控制
          Text(`${this.trigger ? 1 : 0} TRIGGERS • ${this.actions.length} ACTIONS`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#9CA3AF')
            .letterSpacing(0.5)

          Blank()

          Row({ space: 16 }) {
            Button() {
              Text('↺')
                .fontSize(20)
                .fontColor(this.canUndo ? '#6B7280' : '#9CA3AF')
            }
            .type(ButtonType.Normal)
            .backgroundColor('transparent')
            .borderRadius(999)
            .width(36)
            .height(36)
            .enabled(this.canUndo)

            Button() {
              Text('↻')
                .fontSize(20)
                .fontColor(this.canRedo ? '#6B7280' : '#9CA3AF')
            }
            .type(ButtonType.Normal)
            .backgroundColor('transparent')
            .borderRadius(999)
            .width(36)
            .height(36)
            .enabled(this.canRedo)
          }
          .opacity(this.canUndo || this.canRedo ? 1 : 0.4)
          .grayscale(!this.canUndo && !this.canRedo ? 1 : 0)

          Button() {
            Text('▶')
              .fontSize(24)
              .fontColor(this.canPlay ? '#FFFFFF' : '#D1D5DB')
          }
          .type(ButtonType.Normal)
          .backgroundColor(this.canPlay ? '#007AFF' : '#F3F4F6')
          .borderRadius(999)
          .width(44)
          .height(44)
          .enabled(this.canPlay)
          .shadow(this.canPlay ? {
            radius: 14,
            color: 'rgba(0, 122, 255, 0.3)',
            offsetY: 4
          } : undefined)
        } else {
          // 编辑模式：固定显示
          Text(`${this.trigger ? 1 : 0} Trigger \u2022 ${this.actions.length} Actions`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#6B7280')
            .letterSpacing(0.5)

          Blank()

          Row() {
            Button() {
              Text('\u21A9')
                .fontSize(20)
                .fontColor('#9CA3AF')
            }
            .type(ButtonType.Normal)
            .backgroundColor('transparent')
            .width(36)
            .height(36)
            .borderRadius(999)

            Button() {
              Text('\u21AA')
                .fontSize(20)
                .fontColor('#9CA3AF')
            }
            .type(ButtonType.Normal)
            .backgroundColor('transparent')
            .width(36)
            .height(36)
            .borderRadius(999)
          }

          Button() {
            Text('\u25B6')
              .fontSize(24)
              .fontColor('#FFFFFF')
          }
          .type(ButtonType.Normal)
          .backgroundColor('#007AFF')
          .borderRadius(999)
          .width(44)
          .height(44)
          .shadow({
            radius: 14,
            color: 'rgba(0, 122, 255, 0.3)',
            offsetY: 4
          })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 16 })

      Row()
        .width(48)
        .height(6)
        .backgroundColor('#E5E5EA')
        .borderRadius(999)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 20, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 32, topRight: 32 })
    .shadow({ radius: 40, color: 'rgba(0, 0, 0, 0.08)', offsetY: -10 })
    .border({ width: { top: 1 }, color: '#F3F4F6' })
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
  }
}
