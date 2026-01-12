import { Macro, TriggerType } from '../models/Macro';
import promptAction from '@ohos.promptAction';

interface TriggerTag {
  icon: string;
  text: string;
}

@Component
export struct MacroCard {
  @Prop macro: Macro;
  @Prop viewMode: 'grid' | 'list' = 'grid';
  @State isPressed: boolean = false;

  onToggle: (id: number, enabled: boolean) => void = () => {};
  onTrigger: (id: number) => void = () => {};
  onEdit: (id: number) => void = () => {};
  onDelete: (id: number) => void = () => {};
  onMore: (id: number) => void = () => {};

  private getMacroColor(): string {
    const colors = [
      '#007DFF', '#34C759', '#FF9500', '#FF3B30',
      '#AF52DE', '#5AC8FA', '#FF2D55', '#5856D6',
      '#FFCC00', '#8E8E93'
    ];
    const index = this.macro.id % colors.length;
    return colors[index];
  }

  private getMacroIcon(): string {
    return this.macro.icon || '📱';
  }

  private getTriggerTags(): TriggerTag[] {
    const tags: TriggerTag[] = [];
    if (this.macro.triggers && this.macro.triggers.length > 0) {
      this.macro.triggers.forEach(trigger => {
        switch (trigger.type) {
          case TriggerType.TIME:
            tags.push({ icon: '⏱️', text: '定时' });
            break;
          case TriggerType.NETWORK:
            tags.push({ icon: '📱', text: '网络' });
            break;
          case TriggerType.MANUAL:
            tags.push({ icon: '👆', text: '手动' });
            break;
          case TriggerType.CLIPBOARD:
            tags.push({ icon: '📋', text: '剪贴板' });
            break;
          default:
            break;
        }
      });
    }
    return tags.length > 0 ? tags : [{ icon: '👆', text: '手动' }];
  }

  private formatTime(timestamp: number): string {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  build() {
    Column() {
      if (this.viewMode === 'grid') {
        this.buildGridCard();
      } else {
        this.buildListCard();
      }
    }
    .scale({ x: this.isPressed ? 0.98 : 1, y: this.isPressed ? 0.98 : 1 })
    .animation({
      duration: 100,
      curve: Curve.EaseInOut
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
  }

  @Builder
  buildGridCard() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.bolt_fill'))
          .fontSize(32)
          .fontColor([this.getMacroColor()])

        Blank()

        Button() {
          Text('⋯')
            .fontSize(20)
            .fontColor('#AEAEB2')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.onEdit(this.macro.id);
        })
      }
      .width('100%')
      .padding({ left: 12, top: 12, right: 12 })

      Blank()

      Column({ space: 4 }) {
        Text(this.macro.name)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
          .width('100%')
          .lineHeight(1.3)

        Text(`${this.macro.actions?.length || 0} 个动作`)
          .fontSize(11)
          .fontColor('#AEAEB2')
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, bottom: 10 })
      .width('100%')
    }
    .width('100%')
    .height(100)
    .padding(0)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({
      radius: 10,
      color: '#14000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.onTrigger(this.macro.id);
    })
  }

  @Builder
  buildListCard() {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.bolt_fill'))
          .fontSize(32)
          .fontColor(['#FFFFFF'])
      }
      .width(52)
      .height(52)
      .borderRadius(12)
      .backgroundColor(this.getMacroColor())
      .shadow({
        radius: 6,
        color: '#26000000',
        offsetX: 0,
        offsetY: 2
      })
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      Column({ space: 4 }) {
        Row() {
          Text(this.macro.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .flexGrow(1)

          Button() {
            Text('⋯')
              .fontSize(24)
              .fontColor('#AEAEB2')
          }
          .width(24)
          .height(24)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.onMore(this.macro.id);
          })

          Toggle({ type: ToggleType.Switch, isOn: this.macro.enabled })
            .width(32)
            .height(20)
            .onChange((isOn: boolean) => {
              this.onToggle(this.macro.id, isOn);
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        if (this.macro.description) {
          Text(this.macro.description)
            .fontSize(15)
            .fontColor('#6E6E73')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(1.2)
        }

        Row({ space: 6 }) {
          ForEach(this.getTriggerTags(), (tag: TriggerTag) => {
            Row({ space: 4 }) {
              Text(tag.icon)
                .fontSize(12)
              Text(tag.text)
                .fontSize(11)
                .fontColor('#AEAEB2')
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
            .backgroundColor('#F2F2F7')
          })
        }
        .margin({ top: 4 })

        Row({ space: 4 }) {
          Text('🕐')
            .fontSize(12)
          Text(`最后执行：${this.formatTime(this.macro.updatedAt)}`)
            .fontSize(11)
            .fontColor('#AEAEB2')
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#14000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.onTrigger(this.macro.id);
    })
  }
}
