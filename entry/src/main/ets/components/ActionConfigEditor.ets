import { Action, ActionType } from '../models/Macro';
import { VariableOption } from './VariableSelector';

/**
 * 动作配置编辑器
 * 全屏弹窗，用于编辑动作的详细配置
 */
@CustomDialog
export struct ActionConfigEditor {
  // 对话框控制器
  controller: CustomDialogController;

  // 要编辑的动作
  @Link action: Action;

  // 是否是编辑模式（false 表示新建）
  isEditMode: boolean = false;

  // 可用变量列表
  @Link availableVariables: VariableOption[];

  // 回调函数
  onSave?: (action: Action) => void;
  onCancel?: () => void;

  // 内部状态 - 配置数据
  @State configData: Record<string, Object> = {};

  aboutToAppear() {
    // 初始化配置数据
    try {
      this.configData = JSON.parse(this.action.config);
    } catch (error) {
      console.error('[ActionConfigEditor] Failed to parse config:', error);
      this.configData = {};
    }
  }

  /**
   * 保存配置
   */
  private handleSave() {
    try {
      // 验证配置
      const errors = this.validateConfig();
      if (errors.length > 0) {
        AlertDialog.show({
          title: '配置错误',
          message: errors.join('\n'),
          confirm: {
            value: '确定',
            action: () => {}
          }
        });
        return;
      }

      // 更新 action 的 config
      this.action.config = JSON.stringify(this.configData);

      // 调用回调
      if (this.onSave) {
        this.onSave(this.action);
      }

      // 关闭对话框
      this.controller.close();
    } catch (error) {
      console.error('[ActionConfigEditor] Failed to save config:', error);
    }
  }

  /**
   * 取消编辑
   */
  private handleCancel() {
    if (this.onCancel) {
      this.onCancel();
    }
    this.controller.close();
  }

  /**
   * 验证配置
   */
  private validateConfig(): string[] {
    const errors: string[] = [];

    switch (this.action.type) {
      case ActionType.CLIPBOARD_READ:
        if (!this.configData['saveToVariable']) {
          errors.push('必须指定保存到的变量名');
        }
        break;

      case ActionType.TEXT_PROCESS:
        if (!this.configData['input']) {
          errors.push('输入来源不能为空');
        }
        if (!this.configData['operation']) {
          errors.push('操作类型不能为空');
        }
        if (this.configData['operation'] === 'regex_extract' && !this.configData['pattern']) {
          errors.push('正则表达式不能为空');
        }
        break;

      case ActionType.HTTP_REQUEST:
        if (!this.configData['url']) {
          errors.push('URL 不能为空');
        }
        if (!this.configData['method']) {
          errors.push('请求方法不能为空');
        }
        break;

      case ActionType.USER_DIALOG:
        if (!this.configData['type']) {
          errors.push('对话框类型不能为空');
        }
        if (!this.configData['title']) {
          errors.push('对话框标题不能为空');
        }
        break;

      case ActionType.OPEN_URL:
        if (!this.configData['url']) {
          errors.push('URL 不能为空');
        }
        break;

      case ActionType.NOTIFICATION:
        if (!this.configData['title']) {
          errors.push('通知标题不能为空');
        }
        if (!this.configData['content']) {
          errors.push('通知内容不能为空');
        }
        break;
    }

    return errors;
  }

  /**
   * 获取动作类型名称
   */
  private getActionTypeName(): string {
    const names: Record<string, string> = {
      'clipboard_read': '读取剪贴板',
      'clipboard_write': '写入剪贴板',
      'text_process': '文本处理',
      'http_request': 'HTTP 请求',
      'user_dialog': '用户对话框',
      'open_url': '打开 URL',
      'notification': '发送通知',
      'launch_app': '启动应用'
    };
    return names[this.action.type] || this.action.type;
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleCancel();
          })

        Text(this.isEditMode ? `编辑${this.getActionTypeName()}` : `添加${this.getActionTypeName()}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .flexGrow(1)
          .textAlign(TextAlign.Center)

        Button('保存')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')

      Divider()

      // 表单内容区（根据动作类型显示不同表单）
      Scroll() {
        Column() {
          this.buildFormContent();
        }
        .width('100%')
        .padding(16)
      }
      .flexGrow(1)
      .scrollBar(BarState.Auto)
      .backgroundColor('#f5f5f5')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建表单内容（根据动作类型）
   */
  @Builder
  buildFormContent() {
    switch (this.action.type) {
      case ActionType.CLIPBOARD_READ:
      case ActionType.CLIPBOARD_WRITE:
        this.buildClipboardForm();
        break;

      case ActionType.TEXT_PROCESS:
        this.buildTextProcessForm();
        break;

      case ActionType.HTTP_REQUEST:
        this.buildHttpRequestForm();
        break;

      case ActionType.USER_DIALOG:
        this.buildUserDialogForm();
        break;

      case ActionType.OPEN_URL:
        this.buildOpenUrlForm();
        break;

      case ActionType.NOTIFICATION:
        this.buildNotificationForm();
        break;

      default:
        Text('暂不支持此动作类型的配置')
          .fontSize(14)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .padding(40);
    }
  }

  /**
   * 构建剪贴板配置表单
   */
  @Builder
  buildClipboardForm() {
    Column({ space: 16 }) {
      // 操作类型（读取/写入）
      Column({ space: 8 }) {
        Text('操作类型 *')
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('读取')
            .fontSize(14)
            .height(36)
            .backgroundColor(this.configData['operation'] === 'read' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['operation'] === 'read' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.configData['operation'] = 'read';
            })

          Button('写入')
            .fontSize(14)
            .height(36)
            .backgroundColor(this.configData['operation'] === 'write' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['operation'] === 'write' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.configData['operation'] = 'write';
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 读取模式：保存到变量
      if (this.configData['operation'] === 'read') {
        Column({ space: 8 }) {
          Text('保存到变量 *')
            .fontSize(14)
            .fontColor('#666666')

          TextInput({
            placeholder: '例如：clipboard_content',
            text: this.configData['saveToVariable'] as string
          })
            .fontSize(14)
            .onChange((value: string) => {
              this.configData['saveToVariable'] = value;
            })

          Text('变量命名规则：字母开头，可含数字和下划线')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      // 写入模式：写入内容
      if (this.configData['operation'] === 'write') {
        Column({ space: 8 }) {
          Text('写入内容 *')
            .fontSize(14)
            .fontColor('#666666')

          TextArea({
            placeholder: '输入要写入的内容，支持变量引用 {varName}',
            text: this.configData['content'] as string
          })
            .fontSize(14)
            .height(100)
            .onChange((value: string) => {
              this.configData['content'] = value;
            })

          Text('支持引用变量，例如：{clipboard_content}')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  /**
   * 构建文本处理配置表单
   */
  @Builder
  buildTextProcessForm() {
    Column({ space: 16 }) {
      // 操作类型选择
      Column({ space: 8 }) {
        Text('操作类型 *')
          .fontSize(14)
          .fontColor('#666666')

        Grid() {
          GridItem() {
            this.buildOperationButton('regex_extract', '正则提取')
          }
          GridItem() {
            this.buildOperationButton('replace', '文本替换')
          }
          GridItem() {
            this.buildOperationButton('split', '文本分割')
          }
          GridItem() {
            this.buildOperationButton('uppercase', '转大写')
          }
          GridItem() {
            this.buildOperationButton('lowercase', '转小写')
          }
          GridItem() {
            this.buildOperationButton('url_encode', 'URL编码')
          }
          GridItem() {
            this.buildOperationButton('url_decode', 'URL解码')
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 输入来源
      Column({ space: 8 }) {
        Text('输入来源 *')
          .fontSize(14)
          .fontColor('#666666')

        Row() {
          TextInput({
            placeholder: '例如：{clipboard_content}',
            text: this.configData['input'] as string
          })
            .fontSize(14)
            .flexGrow(1)
            .onChange((value: string) => {
              this.configData['input'] = value;
            })

          Button('选择变量')
            .fontSize(12)
            .height(36)
            .onClick(() => {
              // TODO: 打开变量选择器
            })
        }
        .width('100%')

        Text('可直接输入文本或引用变量 {varName}')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 正则提取相关配置
      if (this.configData['operation'] === 'regex_extract') {
        this.buildRegexExtractConfig();
      }

      // 文本替换相关配置
      if (this.configData['operation'] === 'replace') {
        this.buildReplaceConfig();
      }

      // 文本分割相关配置
      if (this.configData['operation'] === 'split') {
        this.buildSplitConfig();
      }

      // 保存结果到变量
      Column({ space: 8 }) {
        Text('保存结果到变量 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：extracted_url',
          text: this.configData['saveToVariable'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['saveToVariable'] = value;
          })

        Text('变量命名规则：字母开头，可含数字和下划线')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  /**
   * 构建操作类型按钮
   */
  @Builder
  buildOperationButton(operation: string, label: string) {
    Button(label)
      .fontSize(12)
      .height(36)
      .width('100%')
      .backgroundColor(this.configData['operation'] === operation ? '#007DFF' : '#f0f0f0')
      .fontColor(this.configData['operation'] === operation ? '#ffffff' : '#333333')
      .onClick(() => {
        this.configData['operation'] = operation;
      })
  }

  /**
   * 构建正则提取配置
   */
  @Builder
  buildRegexExtractConfig() {
    Column({ space: 16 }) {
      // 正则表达式
      Column({ space: 8 }) {
        Text('正则表达式 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：https?://[^\\s]+',
          text: this.configData['pattern'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['pattern'] = value;
          })

        Text('常用模板：')
          .fontSize(12)
          .fontColor('#999999')

        Flex({ wrap: FlexWrap.Wrap }) {
          this.buildRegexTemplate('https?://[^\\s]+', 'URL')
          this.buildRegexTemplate('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}', '邮箱')
          this.buildRegexTemplate('1[3-9]\\d{9}', '手机号')
          this.buildRegexTemplate('\\d+', '数字')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 捕获组索引
      Column({ space: 8 }) {
        Text('捕获组索引')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '0（默认：完整匹配）',
          text: this.configData['groupIndex'] ? String(this.configData['groupIndex']) : '0'
        })
          .fontSize(14)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.configData['groupIndex'] = Number(value) || 0;
          })

        Text('0 表示完整匹配，1 表示第一个捕获组')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  /**
   * 构建正则模板按钮
   */
  @Builder
  buildRegexTemplate(pattern: string, label: string) {
    Button(label)
      .fontSize(11)
      .height(28)
      .padding({ left: 8, right: 8 })
      .margin({ right: 8, bottom: 8 })
      .backgroundColor('#e6f7ff')
      .fontColor('#1890ff')
      .onClick(() => {
        this.configData['pattern'] = pattern;
      })
  }

  /**
   * 构建文本替换配置
   */
  @Builder
  buildReplaceConfig() {
    Column({ space: 16 }) {
      // 搜索值
      Column({ space: 8 }) {
        Text('搜索值 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '要替换的文本或正则表达式',
          text: this.configData['searchValue'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['searchValue'] = value;
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 替换值
      Column({ space: 8 }) {
        Text('替换值 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '替换为的内容',
          text: this.configData['replaceValue'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['replaceValue'] = value;
          })

        Text('支持引用变量，例如：{var_name}')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }

  /**
   * 构建文本分割配置
   */
  @Builder
  buildSplitConfig() {
    Column({ space: 8 }) {
      Text('分隔符 *')
        .fontSize(14)
        .fontColor('#666666')

      TextInput({
        placeholder: '例如：,',
        text: this.configData['separator'] as string
      })
        .fontSize(14)
        .onChange((value: string) => {
          this.configData['separator'] = value;
        })

      Text('用于分割文本的字符或字符串')
        .fontSize(12)
        .fontColor('#999999')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  /**
   * 构建 HTTP 请求配置表单
   */
  @Builder
  buildHttpRequestForm() {
    Column({ space: 16 }) {
      // 请求方法
      Column({ space: 8 }) {
        Text('请求方法 *')
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('GET')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'GET' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'GET' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.configData['method'] = 'GET';
            })

          Button('POST')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'POST' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'POST' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.configData['method'] = 'POST';
            })

          Button('PUT')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'PUT' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'PUT' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.configData['method'] = 'PUT';
            })

          Button('DELETE')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'DELETE' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'DELETE' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.configData['method'] = 'DELETE';
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // URL
      Column({ space: 8 }) {
        Text('URL *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：https://api.example.com/data',
          text: this.configData['url'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['url'] = value;
          })

        Text('支持引用变量，例如：https://api.com/{extracted_url}')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // Headers（简化版：仅支持 Content-Type）
      Column({ space: 8 }) {
        Text('Content-Type')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: 'application/json',
          text: this.configData['headers'] ? (this.configData['headers'] as Record<string, string>)['Content-Type'] : ''
        })
          .fontSize(14)
          .onChange((value: string) => {
            if (!this.configData['headers']) {
              this.configData['headers'] = {};
            }
            (this.configData['headers'] as Record<string, string>)['Content-Type'] = value;
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // Body（仅 POST/PUT 显示）
      if (this.configData['method'] === 'POST' || this.configData['method'] === 'PUT') {
        Column({ space: 8 }) {
          Text('请求体（Body）')
            .fontSize(14)
            .fontColor('#666666')

          TextArea({
            placeholder: '输入 JSON 或其他格式的请求体',
            text: this.configData['body'] as string
          })
            .fontSize(14)
            .height(150)
            .onChange((value: string) => {
              this.configData['body'] = value;
            })

          Text('支持引用变量，例如：{"url": "{extracted_url}"}')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      // 超时时间
      Column({ space: 8 }) {
        Text('超时时间（毫秒）')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '30000（默认30秒）',
          text: this.configData['timeout'] ? String(this.configData['timeout']) : '30000'
        })
          .fontSize(14)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.configData['timeout'] = Number(value) || 30000;
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 保存响应到变量
      Column({ space: 8 }) {
        Text('保存响应到变量')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：api_response',
          text: this.configData['saveResponseTo'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['saveResponseTo'] = value;
          })

        Text('留空则不保存响应')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  /**
   * 构建用户对话框配置表单
   */
  @Builder
  buildUserDialogForm() {
    Column({ space: 16 }) {
      // 对话框类型
      Column({ space: 8 }) {
        Text('对话框类型 *')
          .fontSize(14)
          .fontColor('#666666')

        Grid() {
          GridItem() {
            this.buildDialogTypeButton('confirm', '确认对话框')
          }
          GridItem() {
            this.buildDialogTypeButton('single_select', '单选对话框')
          }
          GridItem() {
            this.buildDialogTypeButton('multi_select', '多选对话框')
          }
          GridItem() {
            this.buildDialogTypeButton('text_input', '文本输入')
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 标题
      Column({ space: 8 }) {
        Text('对话框标题 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：请选择爆款标记',
          text: this.configData['title'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['title'] = value;
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 消息
      Column({ space: 8 }) {
        Text('提示消息')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '可选的提示信息',
          text: this.configData['message'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['message'] = value;
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 选项列表（单选/多选）
      if (this.configData['type'] === 'single_select' || this.configData['type'] === 'multi_select') {
        Column({ space: 8 }) {
          Text('选项列表 *')
            .fontSize(14)
            .fontColor('#666666')

          TextArea({
            placeholder: '每行一个选项，例如：\n普通款\n潜力款\n大爆款',
            text: this.configData['options'] ? (this.configData['options'] as string[]).join('\n') : ''
          })
            .fontSize(14)
            .height(150)
            .onChange((value: string) => {
              // 按行分割选项
              const options = value.split('\n').filter(line => line.trim().length > 0);
              this.configData['options'] = options;
            })

          Text('每行输入一个选项')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      // 文本输入相关配置
      if (this.configData['type'] === 'text_input') {
        Column({ space: 16 }) {
          // 占位符
          Column({ space: 8 }) {
            Text('输入框占位符')
              .fontSize(14)
              .fontColor('#666666')

            TextInput({
              placeholder: '例如：请输入备注',
              text: this.configData['placeholder'] as string
            })
              .fontSize(14)
              .onChange((value: string) => {
                this.configData['placeholder'] = value;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 默认值
          Column({ space: 8 }) {
            Text('默认值')
              .fontSize(14)
              .fontColor('#666666')

            TextInput({
              placeholder: '可选的默认值',
              text: this.configData['defaultValue'] as string
            })
              .fontSize(14)
              .onChange((value: string) => {
                this.configData['defaultValue'] = value;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .width('100%')
      }

      // 保存到变量
      Column({ space: 8 }) {
        Text('保存到变量')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：user_choice',
          text: this.configData['saveToVariable'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.configData['saveToVariable'] = value;
          })

        Text('留空则不保存用户输入')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  /**
   * 构建对话框类型按钮
   */
  @Builder
  buildDialogTypeButton(type: string, label: string) {
    Button(label)
      .fontSize(12)
      .height(36)
      .width('100%')
      .backgroundColor(this.configData['type'] === type ? '#007DFF' : '#f0f0f0')
      .fontColor(this.configData['type'] === type ? '#ffffff' : '#333333')
      .onClick(() => {
        this.configData['type'] = type;
      })
  }

  /**
   * 构建打开 URL 配置表单（占位）
   */
  @Builder
  buildOpenUrlForm() {
    Text('打开 URL 配置表单（待实现）')
      .fontSize(14)
      .fontColor('#999999');
  }

  /**
   * 构建通知配置表单（占位）
   */
  @Builder
  buildNotificationForm() {
    Text('通知配置表单（待实现）')
      .fontSize(14)
      .fontColor('#999999');
  }
}
