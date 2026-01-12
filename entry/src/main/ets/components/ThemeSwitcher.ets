import { themeManager, ThemeMode } from '../utils/ThemeManager';

@Component
export struct ThemeSwitcher {
  @State currentMode: ThemeMode = 'auto';

  aboutToAppear(): void {
    this.currentMode = themeManager.getCurrentThemeMode();
  }

  build() {
    Row() {
      Button() {
        Row() {
          Text(this.getIcon('light'))
            .fontSize(20)
            .fontColor(this.currentMode === 'light' ? '#111827' : '#9CA3AF')
            .margin({ right: 4 })

          Text('浅色')
            .fontSize(14)
            .fontColor(this.currentMode === 'light' ? '#111827' : '#9CA3AF')
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor(this.currentMode === 'light' ? '#F3F4F6' : 'transparent')
      .borderRadius(8)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        this.setThemeMode('light');
      })

      Button() {
        Row() {
          Text(this.getIcon('auto'))
            .fontSize(20)
            .fontColor(this.currentMode === 'auto' ? '#111827' : '#9CA3AF')
            .margin({ right: 4 })

          Text('自动')
            .fontSize(14)
            .fontColor(this.currentMode === 'auto' ? '#111827' : '#9CA3AF')
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor(this.currentMode === 'auto' ? '#F3F4F6' : 'transparent')
      .borderRadius(8)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        this.setThemeMode('auto');
      })

      Button() {
        Row() {
          Text(this.getIcon('dark'))
            .fontSize(20)
            .fontColor(this.currentMode === 'dark' ? '#111827' : '#9CA3AF')
            .margin({ right: 4 })

          Text('深色')
            .fontSize(14)
            .fontColor(this.currentMode === 'dark' ? '#111827' : '#9CA3AF')
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor(this.currentMode === 'dark' ? '#F3F4F6' : 'transparent')
      .borderRadius(8)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        this.setThemeMode('dark');
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceAround)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
  }

  private getIcon(mode: ThemeMode): string {
    switch (mode) {
      case 'light':
        return '\u2600';
      case 'dark':
        return '\u263D';
      case 'auto':
      default:
        return '\u2699';
    }
  }

  private async setThemeMode(mode: ThemeMode): Promise<void> {
    this.currentMode = mode;
    await themeManager.setThemeMode(mode);
  }
}
