import { PageHeader, SearchBar } from '../components/CommonComponents';
import { IndexPage } from './IndexPage';
import { GalleryPage } from './Gallery';
import { getActiveTab, setActiveTab } from '../utils/AppStorageManager';

@Entry
@Component
struct MainTabs {
  @StorageLink('activeTab') activeTab: number = 0;

  build() {
    Tabs({ index: this.activeTab }) {
      TabContent() {
        IndexPage()
      }
      .tabBar(this.TabBarBuilder(0, '\uD83D\uDD0D', 'My Flows'))

      TabContent() {
        GalleryPage()
      }
      .tabBar(this.TabBarBuilder(1, '\uD83D\uDDBC', 'Gallery'))

      TabContent() {
        Column() {
          Text('Settings')
            .fontSize(24)
            .fontColor('#111827')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .tabBar(this.TabBarBuilder(2, '\u2699', 'Settings'))
    }
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      setActiveTab(index);
    })
    .vertical(false)
    .barPosition(BarPosition.End)
  }

  @Builder
  TabBarBuilder(index: number, icon: string, label: string) {
    Column() {
      Row() {
        Text(icon)
          .fontSize(20)
          .fontColor(this.activeTab === index ? '#607AFB' : '#9CA3AF')
      }
      .width(48)
      .height(32)
      .borderRadius(999)
      .backgroundColor(this.activeTab === index ? 'rgba(96, 122, 251, 0.15)' : 'transparent')
      .justifyContent(FlexAlign.Center)

      Text(label)
        .fontSize(10)
        .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.activeTab === index ? '#607AFB' : '#6B7280')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
