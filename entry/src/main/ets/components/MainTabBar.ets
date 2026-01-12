import window from '@ohos.window';

interface TabItem {
  icon: string;
  label: string;
}

@Component
export struct MainTabBar {
  @Link currentIndex: number;
  onTabChange: (index: number) => void = () => {};
  @State bottomSafeHeight: number = 0;

  private tabs: TabItem[] = [
    { icon: '🏠', label: '我的宏' },
    { icon: '📄', label: '模板' },
    { icon: '⚙️', label: '设置' }
  ];

  aboutToAppear() {
    this.getBottomSafeArea();
  }

  private async getBottomSafeArea() {
    try {
      const windowStage = AppStorage.get('windowStage') as window.WindowStage;
      if (windowStage) {
        const mainWindow = windowStage.getMainWindowSync();
        const type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
        const avoidArea = mainWindow.getWindowAvoidArea(type);
        const bottomRectHeight = px2vp(avoidArea.bottomRect.height);
        this.bottomSafeHeight = bottomRectHeight;
      }
    } catch (error) {
      console.error('MainTabBar', 'Failed to get bottom safe area', error as Error);
    }
  }

  build() {
    Row() {
      ForEach(this.tabs, (tab: TabItem, index: number) => {
        Column() {
          Text(tab.icon)
            .fontSize(24)
            .fontColor(this.currentIndex === index ? '#007DFF' : '#AEAEB2')

          Text(tab.label)
            .fontSize(11)
            .fontColor(this.currentIndex === index ? '#007DFF' : '#AEAEB2')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height(49)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.currentIndex !== index) {
            this.currentIndex = index;
            this.onTabChange(index);
          }
        })
      })
    }
    .width('100%')
    .height(49 + this.bottomSafeHeight)
    .padding({ bottom: this.bottomSafeHeight })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 0.5 }, color: '#14000000' })
  }
}
