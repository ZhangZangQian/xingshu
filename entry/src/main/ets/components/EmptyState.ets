@Component
export struct EmptyState {
  @Prop icon: string = '📱';
  @Prop title: string = '暂无内容';
  @Prop subtitle: string = '';
  @Prop buttonText: string = '';
  onButtonClick: () => void = () => {};

  build() {
    Column() {
      Text(this.icon)
        .fontSize(80)
        .margin({ bottom: 16 })

      Text(this.title)
        .fontSize(20)
        .fontColor('#1A1A1A')
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })

      if (this.subtitle) {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor('#AEAEB2')
          .margin({ bottom: 24 })
      }

      if (this.buttonText) {
        Button(this.buttonText)
          .fontSize(15)
          .height(44)
          .borderRadius(8)
          .padding({ left: 24, right: 24 })
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.onButtonClick();
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
