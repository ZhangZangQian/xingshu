import router from '@ohos.router';
import { TriggerItem } from '../models/WorkflowModels';
import { TRIGGER_DATA, CATEGORY_LABELS, TriggerCategoryLabels } from '../data/WorkflowData';
import { getConfigDisplayTemplate } from '../data/ConfigTemplates';

@Entry
@Component
struct TriggerLibrary {
  @State currentLevel: 'category' | 'list' = 'category'; // 当前层级：分类列表或触发器列表
  @State selectedCategory: string = ''; // 选中的分类
  @State categoryLabel: string = ''; // 分类显示名称
  @State searchText: string = '';
  @State filteredCategories: string[] = [];
  @State filteredTriggers: TriggerItem[] = [];

  aboutToAppear(): void {
    this.updateFilteredCategories();
  }

  // 更新过滤的分类列表
  updateFilteredCategories(): void {
    const categories: string[] = ['basic_env', 'device_state', 'harmony_ecosystem', 'user_intent'];

    if (this.searchText) {
      const lowerText = this.searchText.toLowerCase();
      const filtered = categories.filter(category => {
        const categoryLabel = this.getTriggerCategoryLabel(category);
        const triggers = TRIGGER_DATA.filter(item => item.category === category);
        const hasMatchingTrigger = triggers.some(trigger =>
          trigger.name.toLowerCase().includes(lowerText) ||
          trigger.description.toLowerCase().includes(lowerText)
        );
        return categoryLabel.toLowerCase().includes(lowerText) || hasMatchingTrigger;
      });
      this.filteredCategories = filtered;
    } else {
      this.filteredCategories = categories;
    }
  }

  // 更新过滤的触发器列表
  updateFilteredTriggers(): void {
    let filtered = TRIGGER_DATA.filter(item => item.category === this.selectedCategory);

    if (this.searchText) {
      const lowerText = this.searchText.toLowerCase();
      filtered = filtered.filter(item =>
        item.name.toLowerCase().includes(lowerText) ||
        item.description.toLowerCase().includes(lowerText)
      );
    }

    this.filteredTriggers = filtered;
  }

  // 选择分类，切换到触发器列表层级
  selectCategory(category: string): void {
    this.selectedCategory = category;
    this.categoryLabel = this.getTriggerCategoryLabel(category);
    this.currentLevel = 'list';
    this.updateFilteredTriggers();
  }

  // 返回分类列表层级
  backToCategories(): void {
    this.currentLevel = 'category';
    this.selectedCategory = '';
    this.categoryLabel = '';
  }

  build() {
    Column() {
      this.Header()
      this.Content()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  Header() {
    Column() {
      Row() {
        // 返回按钮：在触发器列表层级显示，点击返回分类列表
        if (this.currentLevel === 'list') {
          Row()
            .width(44)
            .height(40)
            .onClick(() => {
              this.backToCategories();
            })
        } else {
          Row()
            .width(64)
            .height(40)
        }

        // 标题：根据层级显示不同文本
        Text(this.currentLevel === 'category' ? 'New Automation' : this.categoryLabel)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('Cancel')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .height(40)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .height(52)
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Row() {
          Text('\uD83D\uDD0D')
            .fontSize(20)
            .fontColor('#8E8E93')
        }
        .margin({ left: 12, right: 8 })

        TextInput({ placeholder: 'Search', text: this.searchText })
          .fontSize(17)
          .fontColor('#000000')
          .placeholderColor('#8E8E93')
          .backgroundColor(Color.Transparent)
          .borderRadius(10)
          .height(36)
          .onChange((value: string) => {
            this.searchText = value;
            // 根据当前层级更新不同的列表
            if (this.currentLevel === 'category') {
              this.updateFilteredCategories();
            } else {
              this.updateFilteredTriggers();
            }
          })
      }
      .width('100%')
      .height(36)
      .borderRadius(10)
      .backgroundColor('rgba(118, 118, 128, 0.12)')
      .margin({ top: 12, bottom: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 12 })
    .backgroundColor('rgba(242, 242, 247, 0.9)')
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: 'rgba(0, 0, 0, 0.1)' })
  }

  getTriggerCategoryLabel(category: string): string {
    const triggerLabels: TriggerCategoryLabels = CATEGORY_LABELS.trigger as TriggerCategoryLabels;
    if (category === 'basic_env') return triggerLabels.basic_env;
    if (category === 'device_state') return triggerLabels.device_state;
    if (category === 'harmony_ecosystem') return triggerLabels.harmony_ecosystem;
    if (category === 'user_intent') return triggerLabels.user_intent;
    return category;
  }

  getCategoryIcon(category: string): string {
    const icons: Record<string, string> = {
      'basic_env': '\uD83C\uDF0D',
      'device_state': '\uD83D\uDCF1',
      'harmony_ecosystem': '\uD83D\uDE80',
      'user_intent': '\uD83D\uDC4B'
    };
    return icons[category] || '\uD83D\uDCCC';
  }

  getCategoryColor(category: string): string {
    const colors: Record<string, string> = {
      'basic_env': '#10B981',
      'device_state': '#3B82F6',
      'harmony_ecosystem': '#8B5CF6',
      'user_intent': '#F59E0B'
    };
    return colors[category] || '#6B7280';
  }

  getCategoryTriggersCount(category: string): number {
    return TRIGGER_DATA.filter(item => item.category === category).length;
  }

  getDefaultConfigValues(item: TriggerItem): Record<string, Object> {
    const config: Record<string, Object> = {};
    item.configs?.forEach(c => {
      if (c.defaultValue !== undefined) {
        config[c.key] = c.defaultValue;
      }
    });
    return config;
  }

  @Builder
  Content() {
    Scroll() {
      Column() {
        if (this.currentLevel === 'category') {
          // 分类列表层级
          Row() {
            Text('Select a Category')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8E8E93')
              .letterSpacing(0.5)
          }
          .width('100%')
          .margin({ bottom: 8, top: 16 })

          ForEach(this.filteredCategories, (category: string) => {
            this.CategoryCard(category)
          })
        } else {
          // 触发器列表层级
          if (this.filteredTriggers.length === 0) {
            Column() {
              Text('No triggers found')
                .fontSize(17)
                .fontColor('#8E8E93')
                .margin({ top: 40 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            ForEach(this.filteredTriggers, (item: TriggerItem) => {
              this.TriggerItem(item)
            })
          }
        }

        Text('Triggers are events that start your automation without you having to tap anything.')
          .fontSize(13)
          .fontColor('#8E8E93')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 24 })
          .padding({ left: 24, right: 24 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 48 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  CategoryCard(category: string) {
    Row() {
      Row() {
        Text(this.getCategoryIcon(category))
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
      .width(44)
      .height(44)
      .borderRadius(12)
      .backgroundColor(this.getCategoryColor(category))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ left: 16, right: 16 })

      Column() {
        Text(this.getTriggerCategoryLabel(category))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .margin({ bottom: 2 })

        Text(`${this.getCategoryTriggersCount(category)} triggers`)
          .fontSize(15)
          .fontColor('#8E8E93')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('\u203A')
        .fontSize(24)
        .fontColor('#C5C5C7')
        .margin({ left: 8, right: 16 })
    }
    .width('100%')
    .height(72)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .margin({ bottom: 12 })
    .onClick(() => {
      // 点击分类卡片，切换到触发器列表层级
      this.selectCategory(category);
    })
  }

  @Builder
  TriggerItem(item: TriggerItem) {
    Row() {
      Row() {
        Text(item.icon)
          .fontSize(20)
          .fontColor('#FFFFFF')
      }
      .width(30)
      .height(30)
      .borderRadius(7)
      .backgroundColor(item.iconColor)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ left: 16, right: 12 })

      Column() {
        Text(item.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .margin({ bottom: 0.5 })

        Text(item.description)
          .fontSize(15)
          .fontColor('#8E8E93')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('\u203A')
        .fontSize(20)
        .fontColor('#C5C5C7')
        .margin({ left: 8, right: 16 })
    }
    .width('100%')
    .height(72)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .margin({ bottom: 12 })
    .onClick(() => {
      try {
        const configDisplay = getConfigDisplayTemplate(item.id);
        const config = this.getDefaultConfigValues(item);

        router.back({
          url: 'pages/MacroEditor',
          params: {
            trigger: {
              id: item.id,
              type: 'trigger',
              title: item.name,
              icon: item.icon,
              iconColor: item.iconColor,
              description: 'When',
              configDisplay: configDisplay,
              config: config
            }
          }
        });
      } catch (err) {
        console.error('Failed to navigate back:', JSON.stringify(err));
      }
    })
  }
}
