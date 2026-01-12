import { EmptyState } from '../components/EmptyState';

@Component
export struct SettingsTab {
  build() {
    Column() {
      Scroll() {
        Column() {
          EmptyState({
            icon: '⚙️',
            title: '设置功能开发中',
            subtitle: '未来将支持以下功能：\n• 主题切换（深色模式）\n• 通知设置\n• 账号管理\n• 数据备份'
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }
      .flexGrow(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
