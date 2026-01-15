import { ConfigOption, VariableInfo } from '../models/WorkflowModels';

/**
 * 选项选择弹窗
 * 用于 select 类型配置项，显示静态选项列表供用户选择
 */
@CustomDialog
export struct OptionsSelectDialog {
  controller: CustomDialogController;
  title: string = '选择选项';
  options: ConfigOption[] = [];
  currentValue: string = '';
  onSelect: (value: string, label: string) => void = () => {};

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')

        Blank()

        Button() {
          Text('✕')
            .fontSize(18)
            .fontColor('#9CA3AF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .width(32)
        .height(32)
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .border({ width: { bottom: 1 }, color: '#E5E5EA' })

      // 选项列表
      List() {
        ForEach(this.options, (option: ConfigOption) => {
          ListItem() {
            Row() {
              Text(option.label)
                .fontSize(16)
                .fontColor('#000000')

              Blank()

              if (option.value === this.currentValue) {
                Text('✓')
                  .fontSize(20)
                  .fontColor('#007AFF')
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 14, bottom: 14 })
            .backgroundColor(option.value === this.currentValue ? '#F3F4F6' : 'transparent')
            .onClick(() => {
              this.onSelect(option.value, option.label);
              this.controller.close();
            })
          }
        })
      }
      .width('100%')
      .height(280)
      .divider({ strokeWidth: 1, color: '#F3F4F6', startMargin: 20, endMargin: 20 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

/**
 * 变量选择弹窗
 * 用于 variable 类型配置项，显示上下文变量列表供用户选择
 */
@CustomDialog
export struct VariableSelectDialog {
  controller: CustomDialogController;
  title: string = '选择变量';
  variables: VariableInfo[] = [];
  onSelect: (variable: VariableInfo) => void = () => {};

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')

        Blank()

        Button() {
          Text('✕')
            .fontSize(18)
            .fontColor('#9CA3AF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .width(32)
        .height(32)
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .border({ width: { bottom: 1 }, color: '#E5E5EA' })

      if (this.variables.length === 0) {
        // 空状态
        Column() {
          Text('📦')
            .fontSize(48)
            .margin({ bottom: 16 })

          Text('暂无可用变量')
            .fontSize(16)
            .fontColor('#9CA3AF')
            .margin({ bottom: 8 })

          Text('请先添加"设置变量"动作')
            .fontSize(14)
            .fontColor('#C4C4C4')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        // 变量列表
        List() {
          ForEach(this.variables, (variable: VariableInfo) => {
            ListItem() {
              Row() {
                // 变量图标
                Row() {
                  Text(variable.icon || '📦')
                    .fontSize(18)
                }
                .width(36)
                .height(36)
                .backgroundColor('#FEF3C7')
                .borderRadius(10)
                .justifyContent(FlexAlign.Center)

                Column() {
                  Text(variable.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#000000')

                  Text(variable.source || '用户定义')
                    .fontSize(12)
                    .fontColor('#9CA3AF')
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })

                Blank()

                // 变量类型标签
                Text(this.getTypeLabel(variable.type))
                  .fontSize(11)
                  .fontColor('#6B7280')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F3F4F6')
                  .borderRadius(4)
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
              .onClick(() => {
                this.onSelect(variable);
                this.controller.close();
              })
            }
          })
        }
        .width('100%')
        .height(320)
        .divider({ strokeWidth: 1, color: '#F3F4F6', startMargin: 68, endMargin: 20 })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  getTypeLabel(type: string): string {
    switch (type) {
      case 'string': return '文本';
      case 'number': return '数字';
      case 'boolean': return '布尔';
      case 'object': return '对象';
      default: return type;
    }
  }
}

/**
 * 数字输入弹窗
 * 用于 number 类型配置项
 */
@CustomDialog
export struct NumberInputDialog {
  controller: CustomDialogController;
  title: string = '输入数值';
  currentValue: number = 0;
  min?: number;
  max?: number;
  placeholder?: string;
  onConfirm: (value: number) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear() {
    this.inputValue = String(this.currentValue);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('取消')
            .fontSize(16)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .onClick(() => {
          this.controller.close();
        })

        Blank()

        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')

        Blank()

        Button() {
          Text('确定')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .onClick(() => {
          const num = Number(this.inputValue);
          if (!isNaN(num)) {
            // 范围校验
            let finalValue = num;
            if (this.min !== undefined && num < this.min) {
              finalValue = this.min;
            }
            if (this.max !== undefined && num > this.max) {
              finalValue = this.max;
            }
            this.onConfirm(finalValue);
          }
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .border({ width: { bottom: 1 }, color: '#E5E5EA' })

      // 输入区域
      Column() {
        TextInput({ text: this.inputValue, placeholder: this.placeholder || '请输入数值' })
          .type(InputType.Number)
          .fontSize(24)
          .fontColor('#000000')
          .textAlign(TextAlign.Center)
          .backgroundColor('#F9FAFB')
          .borderRadius(12)
          .padding(16)
          .onChange((value: string) => {
            this.inputValue = value;
          })

        if (this.min !== undefined || this.max !== undefined) {
          Text(`范围: ${this.min ?? '-∞'} ~ ${this.max ?? '+∞'}`)
            .fontSize(12)
            .fontColor('#9CA3AF')
            .margin({ top: 12 })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 32 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

/**
 * 文本输入弹窗
 * 用于 text 类型配置项
 */
@CustomDialog
export struct TextInputDialog {
  controller: CustomDialogController;
  title: string = '输入文本';
  currentValue: string = '';
  placeholder?: string;
  onConfirm: (value: string) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear() {
    this.inputValue = this.currentValue;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('取消')
            .fontSize(16)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .onClick(() => {
          this.controller.close();
        })

        Blank()

        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')

        Blank()

        Button() {
          Text('确定')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007AFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('transparent')
        .onClick(() => {
          this.onConfirm(this.inputValue);
          this.controller.close();
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .border({ width: { bottom: 1 }, color: '#E5E5EA' })

      // 输入区域
      Column() {
        TextInput({ text: this.inputValue, placeholder: this.placeholder || '请输入' })
          .fontSize(16)
          .fontColor('#000000')
          .backgroundColor('#F9FAFB')
          .borderRadius(12)
          .padding(16)
          .onChange((value: string) => {
            this.inputValue = value;
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 32 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}
