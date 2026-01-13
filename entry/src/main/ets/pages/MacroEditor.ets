import router from '@ohos.router';
import { Workflow, WorkflowNode, WorkflowStats, TriggerType } from '../models/WorkflowModels';
import { WorkflowDataManager } from '../utils/WorkflowDataManager';

interface ActionItem {
  id: string;
  type: 'trigger' | 'action' | 'condition' | 'nested';
  title: string;
  icon: string;
  iconColor: string;
  description?: string;
  children?: ActionItem[];
  avatar?: string;
  message?: string;
}

@Entry
@Component
struct MacroEditor {
  @State shortcutId: string = ''; // 空字符串表示新建模式
  @State title: string = 'Untitled Shortcut';
  @State trigger: ActionItem | null = null; // 单个触发器
  @State actions: ActionItem[] = []; // 动作列表
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  @State canPlay: boolean = false;
  @State isCreateMode: boolean = true; // 是否为新建模式
  @State icon: string = '\u2708'; // 默认图标
  @State iconColor: string = '#607AFB'; // 默认图标颜色
  @State isEnabled: boolean = true; // 是否启用

  private dataManager: WorkflowDataManager = WorkflowDataManager.getInstance();

  aboutToAppear() {
    //TODO 找到最新的跳转方案
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      // 接收 trigger 参数（从 TriggerLibrary 选择后返回）
      if (params['trigger']) {
        const triggerData = params['trigger'] as Record<string, Object>;
        this.trigger = {
          id: triggerData['id'] as string,
          type: triggerData['type'] as 'trigger',
          title: triggerData['title'] as string,
          icon: triggerData['icon'] as string,
          iconColor: triggerData['iconColor'] as string,
          description: triggerData['description'] as string
        };
        // 恢复已有 actions
        // if (params['existingActions']) {
        //   this.actions = params['existingActions'] as ActionItem[];
        // }
        this.isCreateMode = false;
      }
      // 接收 action 参数（从 ActionLibrary 选择后返回）
      else if (params['action']) {
        const actionData = params['action'] as Record<string, Object>;
        const actionItem: ActionItem = {
          id: actionData['id'] as string,
          type: actionData['type'] as 'action' | 'condition' | 'nested',
          title: actionData['title'] as string,
          icon: actionData['icon'] as string,
          iconColor: actionData['iconColor'] as string,
          description: actionData['description'] as string
        };
        // 恢复已有 trigger
        // if (params['existingTrigger']) {
        //   this.trigger = params['existingTrigger'] as ActionItem;
        // }
        // 恢复已有 actions
        if (params['existingActions']) {
          this.actions = [...params['existingActions'] as ActionItem[]];
        }
        // 追加新 action
        this.actions.push(actionItem);
        this.isCreateMode = false;
      }
      // 接收 shortcut_id 判断模式
      else if (params['shortcut_id']) {
        this.shortcutId = params['shortcut_id'] as string;
        this.isCreateMode = false;
        this.loadWorkflowFromManager();
      }
      // 兼容 title 参数
      if (params['title']) {
        this.title = params['title'] as string;
      }

      this.updateCounts();
    } else {
      // 没有参数，默认为新建模式
      this.isCreateMode = true;
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

  // 将WorkflowNode转换为ActionItem（用于UI展示）
  convertWorkflowNodesToActionItems(nodes: WorkflowNode[]): ActionItem[] {
    const result: ActionItem[] = [];
    nodes.forEach(node => {
      const actionItem: ActionItem = {
        id: node.id,
        type: node.type,
        title: node.title,
        icon: node.icon,
        iconColor: node.iconColor,
        description: node.description,
        children: node.children ? this.convertWorkflowNodesToActionItems(node.children) : undefined
      };
      result.push(actionItem);
    });
    return result;
  }

  // 将ActionItem转换为WorkflowNode（用于保存）
  convertActionItemsToWorkflowNodes(items: ActionItem[]): WorkflowNode[] {
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
        children: item.children ? this.convertActionItemsToWorkflowNodes(item.children) : undefined
      };
      result.push(workflowNode);
    });
    return result;
  }

  // 加载编辑模式的 mock 数据
  loadMockData() {
    this.trigger = {
      id: '1',
      type: 'trigger',
      title: 'At 7:00 AM Daily',
      icon: '\u23F0',
      iconColor: '#FF9500',
      description: 'When'
    };
    this.actions = [
      {
        id: '2',
        type: 'action',
        title: 'Get Current Weather',
        icon: '\u2600',
        iconColor: '#FF9500',
        description: 'at Current Location'
      },
      {
        id: '3',
        type: 'condition',
        title: 'Scripting',
        icon: '\uD83D\uDEAA',
        iconColor: '#A855F7',
        description: 'If Temperature is greater than 30°C',
          children: [
          {
            id: '4',
            type: 'nested',
            title: 'Send Message',
            icon: '\uD83D\uDCAC',
            iconColor: '#22C55E',
            description: 'To: Mom',
            avatar: 'M',
            message: 'It\'s getting hot in here!'
          }
        ]
      },
      {
        id: '5',
        type: 'action',
        title: 'Play Music',
        icon: '\u266B',
        iconColor: '#EC4899',
        description: 'Playlist: Morning Vibes ☀️'
      }
    ];
    this.updateCounts();
  }

  // 更新计数器
  updateCounts() {
    this.canPlay = this.trigger !== null && this.actions.length > 0;
  }

  // 判断是否有 Trigger
  hasTrigger(): boolean {
    return this.trigger !== null;
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
      const allItems: ActionItem[] = [];
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
        createdAt: this.isCreateMode ? Date.now() : 0,
        updatedAt: Date.now(),
        isEnabled: this.isEnabled,
        triggerCount: this.trigger ? 1 : 0,
        actionCount: this.actions.length,
        nodes: nodes
      };

      if (this.isCreateMode) {
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
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')

        // 只在编辑模式下显示 Automation 标签
        if (!this.isCreateMode) {
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
        if (this.isCreateMode) {
          // 新建模式：显示 Add Trigger 和空状态
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

          Column() {
            this.EmptyStateSection()
          }
          .layoutWeight(1)
          .margin({ top: 32, bottom: 80 })
        } else {
          // 编辑模式：显示已有的触发器和动作列表
          if (this.hasTrigger()) {
            // 有 Trigger：先显示 Trigger，再显示其他动作
            this.TriggerSection(this.trigger!)

            if (this.actions.length > 0) {
              this.ActionsSection()
            }
          } else {
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

            // 如果已有 actions，也显示它们
            if (this.actions.length > 0) {
              this.ActionsSection()
            }
          }

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
      //TODO 替换最新的
      router.pushUrl({
        url: 'pages/TriggerLibrary',
        params: {
          existingActions: this.actions
        }
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
          url: 'pages/ActionLibrary',
          params: {
            existingActions: this.actions,
            existingTrigger: this.trigger
          }
        });
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  TriggerSection(triggerItem: ActionItem) {
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

      Column({ space: 12 }) {
        ForEach(this.actions, (item: ActionItem, index: number) => {
          if (item.type === 'condition') {
            this.ConditionBlock(item, index)
          } else {
            this.ActionItemWithConnector(item, index)
          }
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ActionItemWithConnector(item: ActionItem, index: number) {
    Stack() {
      if (this.shouldShowConnector(index)) {
        Row()
          .width(2)
          .height('100%')
          .backgroundColor('#D1D5DB')
          .position({ x: 36, y: 0 })
          .zIndex(-1)
      }

      this.ActionCard(item, index)
    }
    .width('100%')
  }

  @Builder
  TriggerCard(item: ActionItem) {
    Stack() {
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
            Text(item.description || '')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')
              .letterSpacing(0.5)

            Blank()

            Text('\u22EE')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .margin({ top: 4 })
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
    }
    .width('100%')
    .borderRadius(12)
  }

  @Builder
  ActionCard(item: ActionItem, index: number) {
    Stack() {
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

            Text('\u2630')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          if (item.description) {
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
    }
    .width('100%')
  }

  @Builder
  ConditionBlock(item: ActionItem, index: number) {
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

            Text('\u2630')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          if (item.description) {
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

      if (item.children && item.children.length > 0) {
        Column({ space: 12 }) {
          ForEach(item.children, (child: ActionItem, index: number) => {
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
  NestedActionCard(item: ActionItem) {
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

          Text('\u2630')
            .fontSize(20)
            .fontColor('#D1D5DB')
        }
        .width('100%')

        if (item.description) {
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
          url: 'pages/ActionLibrary',
          params: {
            existingActions: this.actions,
            existingTrigger: this.trigger
          }
        });
      })
  }

  @Builder
  BottomPanel() {
    Column() {
      Row() {
        if (this.isCreateMode) {
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
