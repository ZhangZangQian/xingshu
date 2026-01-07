import { Variable, VariableScope, VariableType } from '../models/Variable';
import { DatabaseService } from '../services/DatabaseService';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 全局变量管理页面
 */
@Entry
@Component
struct GlobalVariables {
  @State variables: Variable[] = [];
  @State loading: boolean = true;
  @State showEditor: boolean = false;
  @State isEditMode: boolean = false;
  @State editingVariableId: number = 0;
  @State editorName: string = '';
  @State editorType: VariableType = VariableType.STRING;
  @State editorValue: string = '';
  private databaseService: DatabaseService = DatabaseService.getInstance();

  async aboutToAppear() {
    await this.loadVariables();
  }

  /**
   * 加载全局变量列表
   */
  private async loadVariables() {
    try {
      this.loading = true;
      this.variables = await this.databaseService.getGlobalVariables();
      Logger.info('GlobalVariables', `Loaded ${this.variables.length} variables`);
    } catch (error) {
      Logger.error('GlobalVariables', 'Failed to load variables', error as Error);
      promptAction.showToast({ message: '加载变量列表失败' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 创建变量
   */
  private handleCreateVariable() {
    this.isEditMode = false;
    this.editingVariableId = 0;
    this.editorName = '';
    this.editorType = VariableType.STRING;
    this.editorValue = '';
    this.showEditor = true;
  }

  /**
   * 编辑变量
   */
  private handleEditVariable(variable: Variable) {
    this.isEditMode = true;
    this.editingVariableId = variable.id;
    this.editorName = variable.name;
    this.editorType = variable.type;
    this.editorValue = this.formatValueForInput(variable);
    this.showEditor = true;
  }

  /**
   * 格式化变量值用于输入
   */
  private formatValueForInput(variable: Variable): string {
    if (variable.type === VariableType.BOOLEAN) {
      return variable.value ? 'true' : 'false';
    }
    return String(variable.value);
  }

  /**
   * 保存变量
   */
  private async handleSaveVariable() {
    // 验证输入
    if (!this.editorName || this.editorName.trim().length === 0) {
      promptAction.showToast({ message: '请输入变量名称' });
      return;
    }

    // 验证变量名格式（字母、数字、下划线）
    const namePattern = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
    if (!namePattern.test(this.editorName)) {
      promptAction.showToast({ message: '变量名只能包含字母、数字、下划线，且不能以数字开头' });
      return;
    }

    try {
      const now = Date.now();
      let value: string | number | boolean;

      // 根据类型解析值
      if (this.editorType === VariableType.STRING) {
        value = this.editorValue;
      } else if (this.editorType === VariableType.NUMBER) {
        value = Number(this.editorValue);
        if (isNaN(value)) {
          promptAction.showToast({ message: '请输入有效的数字' });
          return;
        }
      } else {
        value = this.editorValue.toLowerCase() === 'true';
      }

      if (this.isEditMode) {
        // 更新变量
        await this.databaseService.updateVariable(this.editingVariableId, {
          name: this.editorName.trim(),
          type: this.editorType,
          value: value
        });
        promptAction.showToast({ message: '变量已更新' });
      } else {
        // 创建变量
        await this.databaseService.insertVariable({
          scope: VariableScope.GLOBAL,
          name: this.editorName.trim(),
          type: this.editorType,
          value: value,
          createdAt: now,
          updatedAt: now
        });
        promptAction.showToast({ message: '变量已创建' });
      }

      this.showEditor = false;
      await this.loadVariables();
    } catch (error) {
      Logger.error('GlobalVariables', 'Failed to save variable', error as Error);
      promptAction.showToast({ message: (error as Error).message });
    }
  }

  /**
   * 取消编辑
   */
  private handleCancelEdit() {
    this.showEditor = false;
  }

  /**
   * 删除变量
   */
  private async handleDeleteVariable(variable: Variable) {
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除变量 "${variable.name}" 吗？`,
      buttons: [
        { text: '取消', color: '#000000' },
        { text: '删除', color: '#ff4d4f' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        try {
          await this.databaseService.deleteVariable(variable.id);
          promptAction.showToast({ message: '变量已删除' });
          await this.loadVariables();
        } catch (error) {
          Logger.error('GlobalVariables', 'Failed to delete variable', error as Error);
          promptAction.showToast({ message: '删除失败' });
        }
      }
    });
  }

  /**
   * 返回主页
   */
  private handleBack() {
    router.back();
  }

  /**
   * 格式化变量值显示
   */
  private formatValue(variable: Variable): string {
    if (variable.type === VariableType.BOOLEAN) {
      return variable.value ? '是' : '否';
    }
    return String(variable.value);
  }

  /**
   * 获取类型显示文本
   */
  private getTypeLabel(type: VariableType): string {
    const labels: Record<string, string> = {
      'string': '文本',
      'number': '数字',
      'boolean': '布尔'
    };
    return labels[type] || type;
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleBack();
          })

        Text('全局变量管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .flexGrow(1)
          .textAlign(TextAlign.Center)

        Button('创建')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleCreateVariable();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')

      // 编辑器区域
      if (this.showEditor) {
        Column({ space: 16 }) {
          Text(this.isEditMode ? '编辑变量' : '创建变量')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)

          // 变量名称
          Column({ space: 8 }) {
            Text('变量名称 *')
              .fontSize(14)
              .fontColor('#666666')

            TextInput({ placeholder: '例如：counter', text: this.editorName })
              .fontSize(16)
              .onChange((value: string) => {
                this.editorName = value;
              })

            Text('只能包含字母、数字、下划线，且不能以数字开头')
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 变量类型
          Column({ space: 8 }) {
            Text('变量类型 *')
              .fontSize(14)
              .fontColor('#666666')

            Row({ space: 12 }) {
              Button('文本')
                .fontSize(14)
                .backgroundColor(this.editorType === VariableType.STRING ? '#007DFF' : '#f0f0f0')
                .fontColor(this.editorType === VariableType.STRING ? '#ffffff' : '#333333')
                .onClick(() => {
                  this.editorType = VariableType.STRING;
                  if (this.editorValue === 'true' || this.editorValue === 'false') {
                    this.editorValue = '';
                  }
                })
                .enabled(!this.isEditMode)

              Button('数字')
                .fontSize(14)
                .backgroundColor(this.editorType === VariableType.NUMBER ? '#007DFF' : '#f0f0f0')
                .fontColor(this.editorType === VariableType.NUMBER ? '#ffffff' : '#333333')
                .onClick(() => {
                  this.editorType = VariableType.NUMBER;
                  this.editorValue = '0';
                })
                .enabled(!this.isEditMode)

              Button('布尔')
                .fontSize(14)
                .backgroundColor(this.editorType === VariableType.BOOLEAN ? '#007DFF' : '#f0f0f0')
                .fontColor(this.editorType === VariableType.BOOLEAN ? '#ffffff' : '#333333')
                .onClick(() => {
                  this.editorType = VariableType.BOOLEAN;
                  this.editorValue = 'true';
                })
                .enabled(!this.isEditMode)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 变量值
          Column({ space: 8 }) {
            Text('变量值 *')
              .fontSize(14)
              .fontColor('#666666')

            if (this.editorType === VariableType.BOOLEAN) {
              // 布尔类型：使用开关
              Row({ space: 12 }) {
                Button('false')
                  .fontSize(14)
                  .backgroundColor(this.editorValue === 'false' ? '#007DFF' : '#f0f0f0')
                  .fontColor(this.editorValue === 'false' ? '#ffffff' : '#333333')
                  .onClick(() => {
                    this.editorValue = 'false';
                  })

                Button('true')
                  .fontSize(14)
                  .backgroundColor(this.editorValue === 'true' ? '#007DFF' : '#f0f0f0')
                  .fontColor(this.editorValue === 'true' ? '#ffffff' : '#333333')
                  .onClick(() => {
                    this.editorValue = 'true';
                  })
              }
            } else if (this.editorType === VariableType.NUMBER) {
              // 数字类型
              TextInput({ placeholder: '例如：0', text: this.editorValue })
                .fontSize(16)
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.editorValue = value;
                })
            } else {
              // 文本类型
              TextInput({ placeholder: '例如：默认值', text: this.editorValue })
                .fontSize(16)
                .onChange((value: string) => {
                  this.editorValue = value;
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 操作按钮
          Row({ space: 12 }) {
            Button('取消')
              .fontSize(16)
              .flexGrow(1)
              .backgroundColor('#f0f0f0')
              .fontColor('#333333')
              .onClick(() => {
                this.handleCancelEdit();
              })

            Button('保存')
              .fontSize(16)
              .flexGrow(1)
              .backgroundColor('#007DFF')
              .onClick(() => {
                this.handleSaveVariable();
              })
          }
          .width('100%')
        }
        .padding(16)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .margin(16)
      }

      // 变量列表
      if (this.loading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
        }
        .flexGrow(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.variables.length === 0 && !this.showEditor) {
        Column() {
          Text('暂无全局变量')
            .fontSize(14)
            .fontColor('#999999')
          Text('点击右上角"创建"按钮添加变量')
            .fontSize(12)
            .fontColor('#cccccc')
            .margin({ top: 8 })
        }
        .flexGrow(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.showEditor) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.variables, (variable: Variable) => {
              Column({ space: 8 }) {
                Row() {
                  Column({ space: 4 }) {
                    Text(variable.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)

                    Row({ space: 8 }) {
                      Text(this.getTypeLabel(variable.type))
                        .fontSize(12)
                        .fontColor('#666666')

                      Text(`值: ${this.formatValue(variable)}`)
                        .fontSize(12)
                        .fontColor('#666666')
                    }
                  }
                  .flexGrow(1)
                  .alignItems(HorizontalAlign.Start)

                  Row({ space: 8 }) {
                    Button('编辑')
                      .fontSize(14)
                      .height(32)
                      .backgroundColor('#f0f0f0')
                      .fontColor('#333333')
                      .onClick(() => {
                        this.handleEditVariable(variable);
                      })

                    Button('删除')
                      .fontSize(14)
                      .height(32)
                      .backgroundColor('#ff4d4f')
                      .onClick(() => {
                        this.handleDeleteVariable(variable);
                      })
                  }
                }
                .width('100%')
              }
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .width('100%')
            }, (variable: Variable) => variable.id.toString())
          }
          .padding(16)
          .width('100%')
        }
        .flexGrow(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
