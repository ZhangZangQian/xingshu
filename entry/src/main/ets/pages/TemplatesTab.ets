import { EmptyState } from '../components/EmptyState';

@Component
export struct TemplatesTab {
  build() {
    Column() {
      Scroll() {
        Column() {
          EmptyState({
            icon: '📋',
            title: '模板功能开发中',
            subtitle: '未来将提供丰富的宏模板，一键创建自动化流程',
            buttonText: '返回'
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
