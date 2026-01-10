import { pasteboard, BusinessError } from '@kit.BasicServicesKit';

/**
 * 文本输入对话框组件
 * 用于用户输入文本内容，支持粘贴
 */
@CustomDialog
export struct TextInputDialog {
  private controller: CustomDialogController;
  private title: string = '请输入';
  private message?: string;
  private placeholder: string = '请输入内容...';
  private defaultValue: string = '';
  @State inputText: string = '';
  private onConfirm: (text: string) => void = () => {};

  aboutToAppear() {
    // 初始化输入框内容为默认值
    this.inputText = this.defaultValue;
  }

  build() {
    Column({ space: 16 }) {
      // 标题
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      // 提示信息（可选）
      if (this.message) {
        Text(this.message)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
      }

      // 文本输入框
      TextArea({
        placeholder: this.placeholder,
        text: this.inputText
      })
        .fontSize(16)
        .height(120)
        .width('100%')
        .onChange((value: string) => {
          this.inputText = value;
        })

      // 粘贴按钮和字符数统计
      Row() {
        // 粘贴按钮
        PasteButton()
          .padding({ top: 12, bottom: 12, left: 24, right: 24 })
          .onClick((event: ClickEvent, result: PasteButtonOnClickResult) => {
            if (PasteButtonOnClickResult.SUCCESS === result) {
              pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                if (err) {
                  console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                  return;
                }
                this.inputText = pasteData.getPrimaryText() || '';
              });
            }
          })

        Blank()

        // 字符数统计
        Text(`${this.inputText.length} 字符`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')

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
            this.onConfirm(this.inputText);
            this.controller.close();
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
