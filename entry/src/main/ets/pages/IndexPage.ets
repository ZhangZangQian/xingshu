import router from '@ohos.router';
import { PageHeader, SearchBar } from '../components/CommonComponents';
import { Workflow } from '../models/WorkflowModels';
import { WorkflowDataManager } from '../utils/WorkflowDataManager';

interface ShortcutItem {
  id: string;
  name: string;
  actions: number;
  iconSymbol: string;
  gradient: string[];
  isEnabled: boolean;
}

@Component
export struct IndexPage {
  @State searchText: string = '';
  @State shortcuts: ShortcutItem[] = [];
  private dataManager: WorkflowDataManager = WorkflowDataManager.getInstance();

  aboutToAppear() {
    this.loadWorkflows();
  }

  loadWorkflows() {
    try {
      const workflows = this.dataManager.getWorkflows();
      this.shortcuts = workflows.map(wf => {
        const shortcut: ShortcutItem = {
          id: wf.id,
          name: wf.name,
          actions: wf.actionCount,
          iconSymbol: wf.icon,
          gradient: [wf.iconColor, this.adjustColor(wf.iconColor, -20)],
          isEnabled: wf.isEnabled
        };
        return shortcut;
      });
    } catch (error) {
      console.error('[IndexPage] Load workflows failed:', error);
    }
  }

  adjustColor(color: string, percent: number): string {
    return color;
  }

  build() {
    Column() {
      PageHeader({
        title: 'My Shortcuts',
        onAddClicked: () => {
          router.pushUrl({
            url: 'pages/MacroEditor',
            params: {} // 不传递 shortcut_id，自动识别为新建模式
          }).catch((err: Error) => {
            console.error('Failed to navigate:', err.message);
          });
        }
      })
      SearchBar({ placeholder: 'Search your library...', searchText: $searchText })
      this.ShortcutsList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder
  ShortcutsList() {
    Scroll() {
      Column() {
        Row() {
          Text('ALL SHORTCUTS')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#6B7280')
            .letterSpacing(1)

          Text('Select')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#607AFB')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 8, bottom: 16 })

        Grid() {
          ForEach(this.shortcuts, (item: ShortcutItem) => {
            GridItem() {
              this.ShortcutCard(item)
            }
          }, (item: ShortcutItem) => item.id.toString())
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(16)
        .rowsGap(16)
        .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 20 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ShortcutCard(item: ShortcutItem) {
    Column() {
      Row() {
        Row() {
          Text(item.iconSymbol)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .width(44)
        .height(44)
        .borderRadius(12)
        .linearGradient({
          angle: 135,
          colors: [[item.gradient[0], 0.0], [item.gradient[1], 1.0]]
        })
        .justifyContent(FlexAlign.Center)
        .shadow({ radius: 8, color: item.gradient[1] + '33', offsetY: 4 })

        Blank()

        Button() {
          Row() {
            Text('\u2026')
              .fontSize(18)
              .fontColor('#9CA3AF')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .type(ButtonType.Normal)
        .backgroundColor('#F3F4F6')
        .borderRadius(999)
        .width(28)
        .height(28)
      }
      .width('100%')

      Column() {
        Text(item.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${item.actions} Actions`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6B7280')
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(0, 0, 0, 0.06)' })
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/MacroEditor',
        params: {
          shortcut_id: item.id.toString(), // 使用 item.id 作为 mock 的 shortcut_id
          title: item.name
        }
      }).catch((err: Error) => {
        console.error('Failed to navigate:', err.message);
      });
    })
  }
}
