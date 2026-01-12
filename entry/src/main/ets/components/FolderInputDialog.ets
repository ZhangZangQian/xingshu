import { Folder } from '../models/Macro';
import { FOLDER_ICONS } from '../constants/FolderConstants';

interface FolderIconItem {
  name: string;
  value: string;
}

@Component
export struct FolderInputDialog {
  @State folderName: string = '';
  @State selectedIconIndex: number = 0;
  title: string = '新建文件夹';
  defaultName: string = '';
  defaultIcon: string = 'folder';
  onConfirm: (name: string, icon: string) => void = () => {};
  onCancel: () => void = () => {};

  aboutToAppear() {
    this.folderName = this.defaultName;
    const iconIndex = FOLDER_ICONS.findIndex(item => item.value === this.defaultIcon);
    if (iconIndex !== -1) {
      this.selectedIconIndex = iconIndex;
    }
  }

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .margin({ bottom: 20 })

      Column({ space: 16 }) {
        Column({ space: 8 }) {
          Text('文件夹名称')
            .fontSize(14)
            .fontColor('#8E8E93')

          TextInput({ text: this.folderName, placeholder: '请输入文件夹名称' })
            .maxLength(30)
            .onChange((value: string) => {
              this.folderName = value;
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 8 }) {
          Text('图标')
            .fontSize(14)
            .fontColor('#8E8E93')

          Grid() {
            ForEach(FOLDER_ICONS, (item: FolderIconItem, index: number) => {
              GridItem() {
                  Column({ space: 4 }) {
                  SymbolGlyph($r(`sys.symbol.${item.value}`))
                    .fontSize(24)
                    .fontColor([this.selectedIconIndex === index ? '#007DFF' : '#AEAEB2'])

                  Text(item.name)
                    .fontSize(12)
                    .fontColor(this.selectedIconIndex === index ? '#007DFF' : '#AEAEB2')
                }
                .width('100%')
                .height(60)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.selectedIconIndex === index ? '#EBF5FF' : '#F2F2F7')
                .borderRadius(8)
              }
              .onClick(() => {
                this.selectedIconIndex = index;
              })
            }, (item: FolderIconItem, index: number) => `${item.value}_${index}`)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width('100%')

      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#007DFF')
          .backgroundColor('#FFFFFF')
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onCancel();
          })

        Button('确定')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .layoutWeight(1)
          .height(44)
          .enabled(this.folderName.trim().length > 0)
          .onClick(() => {
            this.onConfirm(this.folderName.trim(), FOLDER_ICONS[this.selectedIconIndex].value);
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width(320)
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 24,
      color: '#30000000',
      offsetX: 0,
      offsetY: 8
    })
  }
}
