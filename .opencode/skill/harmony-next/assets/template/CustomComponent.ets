/**
 * 自定义组件模板
 */
@Component
export struct CustomComponent {
  @Prop title: string = 'Default Title'
  @Prop subtitle: string = ''
  @State isExpanded: boolean = false
  private onButtonClick?: () => void

  build() {
    Column() {
      // 标题区域
      Row() {
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)

          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 展开图标
        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(20)
          .height(20)
          .rotate({ angle: this.isExpanded ? 90 : 0 })
          .animation({
            duration: 200,
            curve: Curve.EaseInOut
          })
      }
      .width('100%')
      .padding(16)
      .onClick(() => {
        this.isExpanded = !this.isExpanded
      })

      // 展开内容
      if (this.isExpanded) {
        Column() {
          Text('Expanded Content')
            .fontSize(14)
            .fontColor('#666666')
            .padding({ top: 8, bottom: 8 })

          if (this.onButtonClick) {
            Button('Action')
              .fontSize(14)
              .height(36)
              .onClick(() => {
                this.onButtonClick?.()
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({
      radius: 4,
      color: '#1F000000',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}
