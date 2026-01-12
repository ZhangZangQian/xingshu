@Entry
@Component
struct TemplatePage {
  @State title: string = 'Template Page'
  @State isLoading: boolean = false

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back()
          })

        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 加载状态
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
      } else {
        // 主要内容区域
        Scroll() {
          Column({ space: 16 }) {
            Text('Content Area')
              .fontSize(16)
              .fontColor('#333333')

            Button('Action Button')
              .width('100%')
              .height(44)
              .onClick(() => {
                this.handleButtonClick()
              })
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private handleButtonClick(): void {
    // 处理按钮点击事件
    console.info('Button clicked')
  }
}
