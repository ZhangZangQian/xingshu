/**
 * 页面头部组件
 */
@Component
export struct PageHeader {
  title: string = '';
  showAvatar: boolean = false;
  avatarUrl: string = '';
  onAddClicked?: () => void;

  build() {
    Row() {
      Text(this.title)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      if (this.showAvatar) {
        Image(this.avatarUrl)
          .width(40)
          .height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)
          .border({ width: 1, color: '#F3F4F6' })
      }

      if (this.onAddClicked) {
        Button() {
          Text('+')
            .fontSize(24)
            .fontColor('#607AFB')
            .fontWeight(FontWeight.Medium)
        }
        .type(ButtonType.Normal)
        .backgroundColor('rgba(96, 122, 251, 0.1)')
        .borderRadius(999)
        .width(36)
        .height(36)
        .onClick(() => {
          this.onAddClicked?.();
        })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 48, bottom: 8 })
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

/**
 * 搜索栏组件
 */
@Component
export struct SearchBar {
  @Link searchText: string;
  placeholder: string = 'Search...';

  build() {
    Row() {
      Row() {
        Text('\uD83D\uDD0E')
          .fontSize(20)
          .fontColor('#9CA3AF')
          .margin({ left: 16, right: 12 })

        TextInput({ placeholder: this.placeholder, text: this.searchText })
          .placeholderColor('#6B7280')
          .backgroundColor('transparent')
          .border({ width: 0 })
          .layoutWeight(1)
          .fontSize(14)
          .fontColor('#111827')
          .onChange((value: string) => {
            this.searchText = value;
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor('#E5E7EB')
      .borderRadius(12)
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .backgroundColor('#F5F6F8')
  }
}
