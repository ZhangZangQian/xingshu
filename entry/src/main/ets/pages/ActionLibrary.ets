import router from '@ohos.router';
import { ActionItem, LogicNode } from '../models/WorkflowModels';
import { ACTION_DATA, LOGIC_DATA, CATEGORY_LABELS, ActionCategoryLabels, LogicCategoryLabels } from '../data/WorkflowData';
import { getConfigDisplayTemplate } from '../data/ConfigTemplates';
import { WorkflowDataManager } from '../utils/WorkflowDataManager';

interface FeaturedWorkflow {
  title: string;
  description: string;
  icon: string;
  iconColor: string;
  tag: string;
  gradientColor: string;
}

interface CategoryItem {
  title: string;
  icon: string;
  iconColor: string;
}

interface SuggestedAction {
  id: number;
  title: string;
  description: string;
  icon: string;
  iconColor: string;
}

@Entry
@Component
struct ActionLibrary {
  @State searchValue: string = '';
  @State selectedTab: string = 'actions'; // 'actions' or 'logic'

  @State featuredWorkflows: FeaturedWorkflow[] = [
    {
      title: 'Morning Briefing',
      description: 'Daily digest, weather, and calendar events spoken aloud.',
      icon: '\u2600',
      iconColor: '#F97316',
      tag: 'v2.4',
      gradientColor: 'linear-gradient(135deg, rgba(249, 115, 22, 0.2), rgba(42, 47, 55, 1))'
    },
    {
      title: 'Auto-Log Expenses',
      description: 'Scan receipts and append to Sheets instantly.',
      icon: '\u{1F4B8}',
      iconColor: '#607AFB',
      tag: 'Auto',
      gradientColor: 'linear-gradient(135deg, rgba(96, 122, 251, 0.2), rgba(42, 47, 55, 1))'
    },
    {
      title: 'ETA Sharer',
      description: 'Calculate drive time and text contacts your arrival.',
      icon: '\u{1F4CD}',
      iconColor: '#A855F7',
      tag: 'GPS',
      gradientColor: 'linear-gradient(135deg, rgba(168, 85, 247, 0.2), rgba(42, 47, 55, 1))'
    }
  ];

  @State categories: CategoryItem[] = [
    { title: 'Apps', icon: '\u{1F4F1}', iconColor: '#3B82F6' },
    { title: 'Scripting', icon: '\u{1F4BB}', iconColor: '#A855F7' },
    { title: 'Media', icon: '\u{1F3A5}', iconColor: '#F97316' },
    { title: 'Location', icon: '\u{1F4E0}', iconColor: '#EF4444' }
  ];

  @State suggestedActions: SuggestedAction[] = [
    {
      id: 1,
      title: 'Get Current Weather',
      description: 'Returns weather at current location',
      icon: '\u26C5',
      iconColor: '#F59E0B'
    },
    {
      id: 2,
      title: 'Resize Image',
      description: 'Scale image to specific dimension',
      icon: '\u{1F6B5}',
      iconColor: '#EC4899'
    },
    {
      id: 3,
      title: 'Run JavaScript',
      description: 'Execute code snippet on webpage',
      icon: '\u{1F4BB}',
      iconColor: '#06B6D4'
    },
    {
      id: 4,
      title: 'Quick Share',
      description: 'Share clipboard to recent contacts',
      icon: '\u{1F447}',
      iconColor: '#22C55E'
    }
  ];

  @State filteredActions: ActionItem[] = ACTION_DATA;
  @State filteredLogic: LogicNode[] = LOGIC_DATA;
  @State groupedActions: Record<string, ActionItem[]> = {};
  @State groupedLogic: Record<string, LogicNode[]> = {};

  aboutToAppear(): void {
    this.updateFilteredData();
  }

  addActionToEditor(id: number | string, title: string, description: string, icon: string, iconColor: string, type: 'action' | 'condition' | 'nested') {
    try {
      const itemId = id.toString();
      const dataManager = WorkflowDataManager.getInstance();
      const config = this.getDefaultConfigValues(itemId);
      const configDisplay = dataManager.getActionConfigDisplay(itemId, config as Record<string, string | number | boolean>);

      router.back({
        url: 'pages/MacroEditor',
        params: {
          action: {
            id: itemId,
            type: type,
            title: title,
            description: description,
            icon: icon,
            iconColor: iconColor,
            configDisplay: configDisplay,
            config: config
          }
        }
      });
    } catch (err) {
      console.error('Failed to navigate back:', JSON.stringify(err));
    }
  }

  getDefaultConfigValues(itemId: string): Record<string, Object> {
    const config: Record<string, Object> = {};

    const action = ACTION_DATA.find(a => a.id === itemId);
    if (action && action.configs) {
      action.configs.forEach(c => {
        if (c.defaultValue !== undefined) {
          config[c.key] = c.defaultValue;
        }
      });
    }

    const logic = LOGIC_DATA.find(l => l.id === itemId);
    if (logic && logic.configs) {
      logic.configs.forEach(c => {
        if (c.defaultValue !== undefined) {
          config[c.key] = c.defaultValue;
        }
      });
    }

    return config;
  }

  updateFilteredData(): void {
    let filteredActions = ACTION_DATA;

    if (this.searchValue) {
      const lowerText = this.searchValue.toLowerCase();
      filteredActions = filteredActions.filter(item =>
        item.name.toLowerCase().includes(lowerText) ||
        item.description.toLowerCase().includes(lowerText)
      );
    }

    this.filteredActions = filteredActions;

    const groupedActions: Record<string, ActionItem[]> = {};
    filteredActions.forEach(action => {
      const category = action.category;
      if (!groupedActions[category]) {
        groupedActions[category] = [];
      }
      groupedActions[category].push(action);
    });

    this.groupedActions = groupedActions;

    let filteredLogic = LOGIC_DATA;

    if (this.searchValue) {
      const lowerText = this.searchValue.toLowerCase();
      filteredLogic = filteredLogic.filter(item =>
        item.name.toLowerCase().includes(lowerText) ||
        item.description.toLowerCase().includes(lowerText)
      );
    }

    this.filteredLogic = filteredLogic;

    const groupedLogic: Record<string, LogicNode[]> = {};
    filteredLogic.forEach(logicItem => {
      const category: string = logicItem.category;
      let list = groupedLogic[category];
      if (!list) {
        list = [];
        groupedLogic[category] = list;
      }
      list.push(logicItem);
    });

    this.groupedLogic = groupedLogic;
  }

  build() {
    Column() {
      this.Header()
      this.TabBar()
      Scroll() {
        Column({ space: 32 }) {
          this.SearchBar()
          if (this.selectedTab === 'actions') {
            this.FeaturedWorkflows()
            this.ActionsContent()
          } else {
            this.LogicContent()
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder
  Header() {
    Row() {
      Text('Action ')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .fontFamily('sans-serif')

      Text('Library')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#607AFB')
        .fontFamily('sans-serif')

      Blank()

      Button() {
        Text('\u2715')
          .fontSize(20)
          .fontColor('#6B7280')
      }
      .type(ButtonType.Normal)
      .backgroundColor('rgba(0, 0, 0, 0.05)')
      .width(36)
      .height(36)
      .borderRadius(999)
      .onClick(() => {
        router.back();
      })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 48, bottom: 16 })
    .backgroundColor('rgba(245, 246, 248, 0.9)')
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: 'rgba(0, 0, 0, 0.05)' })
  }

  @Builder
  TabBar() {
    Row({ space: 16 }) {
      Button() {
        Text('Actions')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedTab === 'actions' ? '#607AFB' : '#6B7280')
      }
      .type(ButtonType.Normal)
      .backgroundColor(this.selectedTab === 'actions' ? 'rgba(96, 122, 251, 0.1)' : 'transparent')
      .borderRadius(999)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .border({ width: this.selectedTab === 'actions' ? 1 : 0, color: 'rgba(96, 122, 251, 0.3)' })
      .onClick(() => {
        this.selectedTab = 'actions';
      })

      Button() {
        Text('Logic')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedTab === 'logic' ? '#607AFB' : '#6B7280')
      }
      .type(ButtonType.Normal)
      .backgroundColor(this.selectedTab === 'logic' ? 'rgba(96, 122, 251, 0.1)' : 'transparent')
      .borderRadius(999)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .border({ width: this.selectedTab === 'logic' ? 1 : 0, color: 'rgba(96, 122, 251, 0.3)' })
      .onClick(() => {
        this.selectedTab = 'logic';
      })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 12, bottom: 12 })
  }

  @Builder
  SearchBar() {
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Text('\u{1F539}')
          .fontSize(20)
          .fontColor('#9CA3AF')
          .margin({ left: 12, right: 12 })

        TextInput({ placeholder: '> Find actions, apps, or scripts...', text: this.searchValue })
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .borderRadius(12)
          .onChange((value: string) => {
            this.searchValue = value;
            this.updateFilteredData();
          })
      }
      .width('100%')
      .padding({ left: 4, right: 4 })
      .backgroundColor('#F3F4F6')
      .borderRadius(12)
      .border({ width: 1, color: 'rgba(0, 0, 0, 0.1)' })
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    }
    .width('100%')
  }

  @Builder
  FeaturedWorkflows() {
    Column({ space: 16 }) {
      Row() {
        Text('Featured Workflows')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')

        Blank()

        Text('View all')
          .fontSize(14)
          .fontColor('#607AFB')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      Scroll() {
        Row({ space: 16 }) {
          ForEach(this.featuredWorkflows, (item: FeaturedWorkflow) => {
            this.FeaturedCard(item)
          })
        }
        .width('100%')
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  FeaturedCard(item: FeaturedWorkflow) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column()
        .width(320)
        .height(192)
        .borderRadius(16)
        .linearGradient({
          angle: 135,
          colors: [[item.iconColor + '33', 0.0], ['#2A2F37', 1.0]]
        })
        .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 })
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.1)' })

      Column({ space: 12 }) {
        Row() {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .fontColor(item.iconColor)
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor(item.iconColor + '33')
          .border({ width: 1, color: item.iconColor + '4D' })
          .justifyContent(FlexAlign.Center)

          Blank()

          Text(item.tag)
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .borderRadius(6)
            .border({ width: 1, color: 'rgba(255, 255, 255, 0.1)' })
            .fontFamily('monospace')
        }
        .width('100%')

        Column({ space: 4 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text(item.description)
            .fontSize(14)
            .fontColor('#9CA3AF')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(24)
    }
    .width(320)
    .height(192)
    .borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 })
    .onClick(() => {
      console.log('Featured workflow clicked:', item.title);
    })
  }

  getCategoryLabel(category: string): string {
    const actionLabels: ActionCategoryLabels = CATEGORY_LABELS.action as ActionCategoryLabels;
    if (category === 'system_control') return actionLabels.system_control;
    if (category === 'app_service') return actionLabels.app_service;
    if (category === 'cross_device') return actionLabels.cross_device;
    if (category === 'file_processing') return actionLabels.file_processing;
    return category;
  }

  @Builder
  ActionsContent() {
    Column({ space: 16 }) {
      Text('Actions')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')

       ForEach(this.getActionCategories(), (category: string) => {
         Column({ space: 16 }) {
           Row() {
             Text(this.getCategoryLabel(category))
               .fontSize(16)
               .fontWeight(FontWeight.Bold)
               .fontColor('#6B7280')
           }
           .width('100%')

           Column({ space: 12 }) {
             ForEach(this.getCategoryActions(category), (item: ActionItem) => {
               this.SuggestedActionCard({
                 id: parseInt(item.id) || 0,
                 title: item.name,
                 description: item.description,
                 icon: item.icon,
                 iconColor: item.iconColor
               })
             })
           }
           .width('100%')
         }
         .width('100%')
       })
    }
    .width('100%')
  }

  getLogicCategoryLabel(category: string): string {
    const logicLabels: LogicCategoryLabels = CATEGORY_LABELS.logic as LogicCategoryLabels;
    if (category === 'flow_control') return logicLabels.flow_control;
    if (category === 'variable_data') return logicLabels.variable_data;
    if (category === 'advanced') return logicLabels.advanced;
    return category;
  }

  getCategoryActions(category: string): ActionItem[] {
    if (!this.groupedActions) {
      return [];
    }
    return this.groupedActions[category] || [];
  }

  getCategoryLogicNodes(category: string): LogicNode[] {
    if (!this.groupedLogic) {
      return [];
    }
    return this.groupedLogic[category] || [];
  }

  getActionCategories(): string[] {
    if (!this.groupedActions) {
      return [];
    }
    return Object.keys(this.groupedActions);
  }

  getLogicCategories(): string[] {
    if (!this.groupedLogic) {
      return [];
    }
    return Object.keys(this.groupedLogic);
  }

  @Builder
  LogicContent() {
    Column({ space: 16 }) {
      Text('Logic Nodes')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')

      ForEach(this.getLogicCategories(), (category: string) => {
        Column({ space: 16 }) {
          Row() {
            Text(this.getLogicCategoryLabel(category))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#6B7280')
          }
          .width('100%')

          Column({ space: 12 }) {
            ForEach(this.getCategoryLogicNodes(category), (item: LogicNode) => {
              this.LogicNodeCard(item)
            })
          }
          .width('100%')
        }
        .width('100%')
      })
    }
    .width('100%')
  }

  @Builder
  Categories() {
    Column({ space: 16 }) {
      Text('Categories')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')

      Grid() {
        ForEach(this.categories, (item: CategoryItem) => {
          GridItem() {
            Column({ space: 12 }) {
              Row() {
                Text(item.icon)
                  .fontSize(24)
                  .fontColor(item.iconColor)
              }
              .width(48)
              .height(48)
              .borderRadius(999)
              .backgroundColor(item.iconColor + '1A')
              .justifyContent(FlexAlign.Center)

              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#374151')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
            .border({ width: 1, color: 'rgba(0, 0, 0, 0.05)' })
          }
          .aspectRatio(1)
          .onClick(() => {
            console.log('Category clicked:', item.title);
          })
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  SuggestedActions() {
    Column({ space: 16 }) {
      Text('Suggested Actions')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')

      Column({ space: 12 }) {
        ForEach(this.suggestedActions, (item: SuggestedAction) => {
          this.SuggestedActionCard(item)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  SuggestedActionCard(item: SuggestedAction) {
    Row() {
      Row() {
        Text(item.icon)
          .fontSize(24)
          .fontColor(item.iconColor)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .backgroundColor(item.iconColor + '1A')
      .border({ width: 1, color: item.iconColor + '33' })
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')

        Text(item.description)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 16 })

      Button() {
        Text('+')
          .fontSize(20)
          .fontColor('#607AFB')
      }
      .type(ButtonType.Normal)
      .backgroundColor('#F3F4F6')
      .width(32)
      .height(32)
      .borderRadius(999)
      .onClick(() => {
        this.addActionToEditor(item.id, item.title, item.description, item.icon, item.iconColor, 'action');
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: 'rgba(0, 0, 0, 0.05)' })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      this.addActionToEditor(item.id, item.title, item.description, item.icon, item.iconColor, 'action');
    })
  }

  @Builder
  LogicNodeCard(item: LogicNode) {
    Row() {
      Row() {
        Text(item.icon)
          .fontSize(24)
          .fontColor(item.iconColor)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .backgroundColor(item.iconColor + '1A')
      .border({ width: 1, color: item.iconColor + '33' })
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')

        Text(item.description)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 16 })

      Button() {
        Text('+')
          .fontSize(20)
          .fontColor('#607AFB')
      }
      .type(ButtonType.Normal)
      .backgroundColor('#F3F4F6')
      .width(32)
      .height(32)
      .borderRadius(999)
      .onClick(() => {
        this.addActionToEditor(item.id, item.name, item.description, item.icon, item.iconColor, 'condition');
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: 'rgba(0, 0, 0, 0.05)' })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      this.addActionToEditor(item.id, item.name, item.description, item.icon, item.iconColor, 'condition');
    })
  }
}
