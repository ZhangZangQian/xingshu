import router from '@ohos.router';

interface TriggerItem {
  id: number;
  title: string;
  icon: string;
  iconColor: string;
  description: string;
}

@Entry
@Component
struct TriggerLibrary {
  @State searchText: string = '';

  private triggerList: TriggerItem[] = [
    {
      id: 1,
      title: 'Time of Day',
      icon: '\u23F0',
      iconColor: '#007AFF',
      description: 'Specific Time, Sunrise/Sunset'
    },
    {
      id: 2,
      title: 'Location',
      icon: '\uD83D\uDCCD',
      iconColor: '#34C759',
      description: 'Arriving, Leaving'
    },
    {
      id: 3,
      title: 'Communication',
      icon: '\uD83D\uDCAC',
      iconColor: '#5AC8FA',
      description: 'Message, Email'
    },
    {
      id: 4,
      title: 'System',
      icon: '\u2699',
      iconColor: '#5856D6',
      description: 'Battery Level, Wi-Fi, Focus Mode'
    }
  ];

  build() {
    Column() {
      this.Header()
      this.Content()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  Header() {
    Column() {
      Row() {
        Row()
          .width(64)
          .height(40)

        Text('New Automation')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('Cancel')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .height(40)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .height(52)
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Row() {
          Text('\uD83D\uDD0D')
            .fontSize(20)
            .fontColor('#8E8E93')
        }
        .margin({ left: 12, right: 8 })

        TextInput({ placeholder: 'Search', text: this.searchText })
          .fontSize(17)
          .fontColor('#000000')
          .placeholderColor('#8E8E93')
          .backgroundColor(Color.Transparent)
          .borderRadius(10)
          .height(36)
          .onChange((value: string) => {
            this.searchText = value;
          })
      }
      .width('100%')
      .height(36)
      .borderRadius(10)
      .backgroundColor('rgba(118, 118, 128, 0.12)')
      .margin({ top: 12, bottom: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 12 })
    .backgroundColor('rgba(242, 242, 247, 0.9)')
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: 'rgba(0, 0, 0, 0.1)' })
  }

  @Builder
  Content() {
    Scroll() {
      Column() {
        Row() {
          Text('Select a Trigger')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#8E8E93')
            .letterSpacing(0.5)
        }
        .width('100%')
        .margin({ bottom: 8, top: 16 })

        Column() {
          ForEach(this.triggerList, (item: TriggerItem) => {
            this.TriggerItem(item)
          })
        }
        .width('100%')
        .borderRadius(12)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })

        Text('Triggers are events that start your automation without you having to tap anything.')
          .fontSize(13)
          .fontColor('#8E8E93')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 24 })
          .padding({ left: 24, right: 24 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 48 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  TriggerItem(item: TriggerItem) {
    Row() {
      Row() {
        Text(item.icon)
          .fontSize(20)
          .fontColor('#FFFFFF')
      }
      .width(30)
      .height(30)
      .borderRadius(7)
      .backgroundColor(item.iconColor)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ left: 16, right: 12 })

      Column() {
        Text(item.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .margin({ bottom: 0.5 })

        Text(item.description)
          .fontSize(15)
          .fontColor('#8E8E93')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('\u203A')
        .fontSize(20)
        .fontColor('#C5C5C7')
        .margin({ left: 8, right: 16 })
    }
    .width('100%')
    .height(72)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      console.log(`Selected trigger: ${item.title}`);
      router.back();
    })
  }
}
