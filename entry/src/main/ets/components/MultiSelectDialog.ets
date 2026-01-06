/**
 * 多选对话框组件
 * 用于"快小红"场景的分类标签选择
 */
@CustomDialog
export struct MultiSelectDialog {
  private controller: CustomDialogController;
  private title: string = '请选择';
  private options: string[] = [];
  private selectedIndexes: number[] = [];
  private onConfirm: (selected: string[]) => void = () => {};

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
              Checkbox()
                .select(this.selectedIndexes.includes(index))
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    if (!this.selectedIndexes.includes(index)) {
                      this.selectedIndexes.push(index);
                    }
                  } else {
                    const idx = this.selectedIndexes.indexOf(index);
                    if (idx > -1) {
                      this.selectedIndexes.splice(idx, 1);
                    }
                  }
                })

              Text(option)
                .fontSize(16)
                .flexGrow(1)
                .onClick(() => {
                  // 点击文本也触发选中/取消
                  const isSelected = this.selectedIndexes.includes(index);
                  if (isSelected) {
                    const idx = this.selectedIndexes.indexOf(index);
                    if (idx > -1) {
                      this.selectedIndexes.splice(idx, 1);
                    }
                  } else {
                    this.selectedIndexes.push(index);
                  }
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

      // 已选数量提示
      Text(`已选择 ${this.selectedIndexes.length} 项`)
        .fontSize(14)
        .fontColor('#666666')

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
            const selected = this.selectedIndexes.map(idx => this.options[idx]);
            this.onConfirm(selected);
            this.controller.close();
          })
      }
      .width('100%')

      // 全选/取消全选按钮
      Row({ space: 12 }) {
        Button('全选')
          .fontSize(14)
          .height(36)
          .flexGrow(1)
          .backgroundColor('#f0f0f0')
          .fontColor('#333333')
          .onClick(() => {
            this.selectedIndexes = Array.from({ length: this.options.length }, (_, i) => i);
          })

        Button('取消全选')
          .fontSize(14)
          .height(36)
          .flexGrow(1)
          .backgroundColor('#f0f0f0')
          .fontColor('#333333')
          .onClick(() => {
            this.selectedIndexes = [];
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
