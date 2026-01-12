import promptAction from '@ohos.promptAction';

@Component
export struct FABButton {
  @State isPressed: boolean = false;
  onTap: () => void = () => {};

  build() {
    Button() {
      Text('+')
        .fontSize(32)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor('#007DFF')
    .shadow({
      radius: 12,
      color: '#30000000',
      offsetX: 0,
      offsetY: 4
    })
    .margin({ right: 16, bottom: 16 })
    .scale({ x: this.isPressed ? 0.95 : 1, y: this.isPressed ? 0.95 : 1 })
    .animation({
      duration: 100,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      this.onTap();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
  }
}
