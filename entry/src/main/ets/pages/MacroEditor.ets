import router from '@ohos.router';
import { Workflow, WorkflowNode, TriggerType, ConfigDisplayItem } from '../models/WorkflowModels';
import { WorkflowDataManager } from '../utils/WorkflowDataManager';

interface UIWorkflowItem {
  id: string;
  type: 'trigger' | 'action' | 'condition' | 'nested';
  title: string;
  icon: string;
  iconColor: string;
  description?: string;
  avatar?: string;
  message?: string;
  configDisplay?: ConfigDisplayItem[];
  config?: Record<string, string | number | boolean>;
  children?: UIWorkflowItem[];
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
        this.trigger = {
          id: triggerData['id'] as string,
          type: 'trigger',
          title: triggerData['title'] as string,
          icon: triggerData['icon'] as string,
          iconColor: triggerData['iconColor'] as string,
          description: triggerData['description'] as string,
          configDisplay: triggerData['configDisplay'] as ConfigDisplayItem[],
          config: triggerData['config'] as Record<string, string | number | boolean>
        };
        this.updateCounts();
        console.info('[MacroEditor] Trigger received:', JSON.stringify(this.trigger));
      }
      else if (params['action']) {
        const actionData = params['action'] as Record<string, Object>;
        const actionItem: UIWorkflowItem = {
          id: actionData['id'] as string,
          type: actionData['type'] as 'action' | 'condition' | 'nested',
          title: actionData['title'] as string,
          icon: actionData['icon'] as string,
          iconColor: actionData['iconColor'] as string,
          description: actionData['description'] as string,
          configDisplay: actionData['configDisplay'] as ConfigDisplayItem[],
          config: actionData['config'] as Record<string, string | number | boolean>
        };
        this.actions = [...this.actions, actionItem];
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

      const actionItem: UIWorkflowItem = {
        id: node.id,
        type: node.type,
        title: node.title,
        icon: node.icon,
        iconColor: node.iconColor,
        description: node.description,
        configDisplay: configDisplay,
        config: config,
        children: node.children ? this.convertWorkflowNodesToActionItems(node.children) : undefined
      };
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
    if (!item.config) {
      item.config = {};
    }
    item.config[configKey] = newValue;

    if (item.configDisplay) {
      const displayItem: ConfigDisplayItem | undefined = item.configDisplay.find(d => d.configKey === configKey);
      if (displayItem) {
        displayItem.label = this.formatDisplayValue(newValue, configKey);
      }
    }
  }

  formatDisplayValue(value: string | number | boolean, configKey?: string): string {
    return String(value);
  }

  validateConfigValue(value: string, configKey?: string): boolean {
    return true;
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
      // 合并 trigger 和 actions
      const allItems: UIWorkflowItem[] = [];
      if (this.trigger) {
        allItems.push(this.trigger);
      }
      allItems.push(...this.actions);

      const nodes = this.convertActionItemsToWorkflowNodes(allItems);

      const workflow: Workflow = {
        id: this.shortcutId || Date.now().toString(),
        name: this.title,
        icon: this.icon,
        iconColor: this.iconColor,
        createdAt: !this.shortcutId ? Date.now() : 0,
        updatedAt: Date.now(),
        isEnabled: this.isEnabled,
        triggerCount: this.trigger ? 1 : 0,
        actionCount: this.actions.length,
        nodes: nodes
      };

      if (!this.shortcutId) {
        await this.dataManager.createWorkflow(workflow);
      } else {
        // 更新现有工作流，保留原有的createdAt
        const existing = this.dataManager.getWorkflow(workflow.id);
        if (existing) {
          workflow.createdAt = existing.createdAt;
        }
        await this.dataManager.updateWorkflow(workflow);
      }

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

      Column() {
        ForEach(this.actions, (item: UIWorkflowItem, index: number) => {
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
        })
      }
      .width('100%')
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
        this.toggleConfigPanel(item.id);
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
          this.toggleConfigPanel(item.id);
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
          this.toggleConfigPanel(item.id);
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
              Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                  this.ConfigDisplayChip(configItem, item)
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
              Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                  this.ConfigDisplayChip(configItem, item)
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
            Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
              ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                this.ConfigDisplayChip(configItem, item)
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

      if (item.children && item.children.length > 0) {
        Column({ space: 0 }) {
          ForEach(item.children, (child: UIWorkflowItem, index: number) => {
            this.NestedActionCard(child)
          })

          this.EndIfCard()
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
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
          Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
            ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
              this.ConfigDisplayChip(configItem, item)
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
