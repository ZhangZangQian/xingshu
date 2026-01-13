import router from '@ohos.router';
import { PageHeader, SearchBar } from '../components/CommonComponents';

interface ShortcutItem {
  id: number;
  name: string;
  actions: number;
  iconSymbol: string;
  gradient: string[];
}

@Component
export struct IndexPage {
  @State searchText: string = '';
  @State shortcuts: ShortcutItem[] = [
    { id: 1, name: 'Morning Briefing', actions: 5, iconSymbol: '\u2600', gradient: ['#FB923C', '#F59E0B'] },
    { id: 2, name: 'Fast Charge', actions: 2, iconSymbol: '\u26A1', gradient: ['#34D399', '#0D9488'] },
    { id: 3, name: 'Music Mix', actions: 12, iconSymbol: '\u266B', gradient: ['#D946EF', '#9333EA'] },
    { id: 4, name: 'Work Mode', actions: 8, iconSymbol: '\u2692', gradient: ['#06B6D4', '#2563EB'] },
    { id: 5, name: 'Home ETA', actions: 3, iconSymbol: '\uD83D\uDE97', gradient: ['#3B82F6', '#4F46E5'] },
    { id: 6, name: 'Quick Note', actions: 1, iconSymbol: '\u270F', gradient: ['#FBBF24', '#FB923C'] },
    { id: 7, name: 'Laundry Timer', actions: 4, iconSymbol: '\u2696', gradient: ['#94A3B8', '#475569'] },
    { id: 8, name: 'Calculate Tip', actions: 6, iconSymbol: '\u0024', gradient: ['#4ADE80', '#059669'] }
  ];

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
