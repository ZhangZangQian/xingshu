import { MacrosTab } from '../pages/MacrosTab';
import { TemplatesTab } from '../pages/TemplatesTab';
import { SettingsTab } from '../pages/SettingsTab';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  tabBuilder(index: number, label: string, symbolId: Resource) {
    Column({ space: 4 }) {
      SymbolGlyph(symbolId)
        .fontSize(24)
        .fontColor([this.currentTab === index ? '#007DFF' : '#AEAEB2'])
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? '#007DFF' : '#AEAEB2')
    }
    .width('100%')
    .height(49)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = index;
      this.tabsController.changeIndex(index);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        MacrosTab()
      }
      .tabBar(this.tabBuilder(0, '我的宏', $r('sys.symbol.house_fill')))

      TabContent() {
        TemplatesTab()
      }
      .tabBar(this.tabBuilder(1, '模板', $r('sys.symbol.doc_text_fill')))

      TabContent() {
        SettingsTab()
      }
      .tabBar(this.tabBuilder(2, '设置', $r('sys.symbol.gearshape_fill')))
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentTab = index;
    })
  }
}
