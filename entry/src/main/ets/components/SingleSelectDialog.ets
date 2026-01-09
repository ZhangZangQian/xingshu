import promptAction from '@ohos.promptAction';

/**
 * 单选对话框组件
 * 支持大量选项滚动显示
 */
@CustomDialog
export struct SingleSelectDialog {
  private controller: CustomDialogController;
  private title: string = '请选择';
  private options: string[] = [];
  private selectedIndex: number = -1;
  private onConfirm: (selected: string, index: number) => void = () => {};

  build() {
    Column({ space: 16 }) {
      // 标题
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 选项列表（使用 Scroll 支持滚动）
      Scroll() {
        Column({ space: 8 }) {
          ForEach(this.options, (option: string, index: number) => {
            Row({ space: 12 }) {
              Radio({ value: index.toString(), group: 'singleSelectGroup' })
                .checked(this.selectedIndex === index)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedIndex = index;
                  }
                })

              Text(option)
                .fontSize(16)
                .flexGrow(1)
                .onClick(() => {
                  this.selectedIndex = index;
                })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }, (option: string, index: number) => index.toString())
        }
        .width('100%')
      }
      .height(400)
      .width('100%')
      .scrollBar(BarState.Auto)

      // 按钮组
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .flexGrow(1)
          .backgroundColor('#f0f0f0')
          .fontColor('#333333')
          .onClick(() => {
            this.controller.close();
          })

        Button('确定')
          .fontSize(16)
          .flexGrow(1)
          .onClick(() => {
            if (this.selectedIndex >= 0 && this.selectedIndex < this.options.length) {
              const selected = this.options[this.selectedIndex];
              this.onConfirm(selected, this.selectedIndex);
              this.controller.close();
            } else {
              promptAction.showToast({ message: '请先选择一个选项' });
            }
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
