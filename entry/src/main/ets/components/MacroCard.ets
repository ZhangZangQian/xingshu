import { Macro } from '../models/Macro';

/**
 * 宏卡片组件
 */
@Component
export struct MacroCard {
  @Prop macro: Macro;
  @Prop onToggle: (id: number, enabled: boolean) => void = () => {};
  @Prop onTrigger: (id: number) => void = () => {};
  @Prop onEdit: (id: number) => void = () => {};
  @Prop onDelete: (id: number) => void = () => {};

  build() {
    Card() {
      Column({ space: 12 }) {
        // 标题行
        Row() {
          // 图标
          if (this.macro.icon) {
            Image(this.macro.icon)
              .width(32)
              .height(32)
              .borderRadius(8)
          } else {
            Text('📱')
              .fontSize(32)
          }

          // 宏名称
          Text(this.macro.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 12 })
            .flexGrow(1)

          // 启用/禁用开关
          Toggle({ type: ToggleType.Switch, isOn: this.macro.enabled })
            .onChange((isOn: boolean) => {
              this.onToggle(this.macro.id, isOn);
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 描述
        if (this.macro.description) {
          Text(this.macro.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // 操作按钮
        Row({ space: 8 }) {
          Button('手动触发')
            .fontSize(14)
            .height(32)
            .flexGrow(1)
            .onClick(() => {
              this.onTrigger(this.macro.id);
            })

          Button('编辑')
            .fontSize(14)
            .height(32)
            .flexGrow(1)
            .backgroundColor('#f0f0f0')
            .fontColor('#333333')
            .onClick(() => {
              this.onEdit(this.macro.id);
            })

          Button('删除')
            .fontSize(14)
            .height(32)
            .flexGrow(1)
            .backgroundColor('#ff4d4f')
            .onClick(() => {
              this.onDelete(this.macro.id);
            })
        }
        .width('100%')

        // 更新时间
        Text(`更新时间：${this.formatTime(this.macro.updatedAt)}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .padding(16)
      .width('100%')
    }
    .margin({ bottom: 12 })
    .width('100%')
  }

  /**
   * 格式化时间戳
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }
}
