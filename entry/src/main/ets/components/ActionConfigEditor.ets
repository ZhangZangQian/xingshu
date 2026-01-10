import { Action, ActionType } from '../models/Macro';
import { VariableOption } from './VariableSelector';
import { CommonTopBar, TopBarConfig } from './CommonTopBar';

// 条件分支配置类型
interface BranchCondition {
  field: string;
  operator: string;
  value: string;
}

interface NotificationActionConfig {
  title: string;
  content: string;
  enableSound: boolean;
  enableVibration: boolean;
}

interface HttpRequestActionConfig {
  url: string;
  method: string;
  body: string;
  headers: Record<string, string>;
  timeout: number;
}

interface OpenUrlActionConfig {
  url: string;
  openWith: string;
}

interface BaseBranchActionConfig {
  type: string;
  config: NotificationActionConfig | HttpRequestActionConfig | OpenUrlActionConfig;
}

export interface BranchConfig {
  name: string;
  conditions: BranchCondition[];
  actions: BaseBranchActionConfig[];
}

/**
 * 动作配置编辑器
 * 全屏弹窗，用于编辑动作的详细配置
 */
@CustomDialog
export struct ActionConfigEditor {
  // 对话框控制器
  controller: CustomDialogController;

  // 要编辑的动作（使用 @Watch 监听变化）
  @Prop @Watch('onActionChanged') action: Action;

  // 是否是编辑模式（false 表示新建）
  isEditMode: boolean = false;

  // 可用变量列表
  @Prop availableVariables: VariableOption[];

  // 回调函数
  onSave?: (action: Action) => void;
  onCancel?: () => void;

  // 内部状态 - 配置数据
  @State configData: Record<string, Object> = {};

  // 条件分支编辑器状态
  @State branches: BranchConfig[] = [];
  @State editingBranchIndex: number = -1;
  @State editingConditionIndex: number = -1;
  @State editingActionIndex: number = -1;
  @State showBranchEditor: boolean = false;
  @State conditionField: string = '';
  @State conditionOperator: string = '==';
  @State conditionValue: string = '';

  aboutToAppear() {
    // 初始化配置数据
    this.initializeConfigData();
  }

  /**
   * 当 action 属性变化时调用（@Watch 回调）
   */
  onActionChanged() {
    console.info('[ActionConfigEditor] Action changed, reinitializing config');
    this.initializeConfigData();
  }

  /**
   * 初始化配置数据
   */
  private initializeConfigData() {
    try {
      this.configData = JSON.parse(this.action.config);
      console.info('[ActionConfigEditor] Config data initialized:', JSON.stringify(this.configData));

      // 初始化条件分支数据
      if (this.action.type === ActionType.IF_ELSE) {
        const branchesData = this.configData['branches'] as BranchConfig[];
        this.branches = branchesData || [];
      }
    } catch (error) {
      console.error('[ActionConfigEditor] Failed to parse config:', error);
      this.configData = {};

      // 如果是条件分支，初始化默认数据
      if (this.action.type === ActionType.IF_ELSE) {
        this.branches = [];
      }
    }
  }

  /**
   * 更新配置数据（触发响应式更新）
   * ArkTS 不支持对象展开运算符，需要手动复制
   */
  private updateConfigData(key: string, value: Object) {
    console.info(`[ActionConfigEditor] Updating config: ${key} = ${JSON.stringify(value)}`);
    // 创建新对象并手动复制所有属性
    const newConfig: Record<string, Object> = {};
    const keys = Object.keys(this.configData);
    for (let i = 0; i < keys.length; i++) {
      newConfig[keys[i]] = this.configData[keys[i]];
    }
    // 更新指定的键值
    newConfig[key] = value;
    // 触发响应式更新
    this.configData = newConfig;
  }

  /**
   * 保存配置
   */
  private handleSave() {
    try {
      console.info('[ActionConfigEditor] Starting save process');
      console.info('[ActionConfigEditor] Current configData:', JSON.stringify(this.configData));

      // 如果正在编辑分支，先返回分支列表
      if (this.showBranchEditor) {
        this.showBranchEditor = false;
        return;
      }

      // 验证配置
      const errors = this.validateConfig();
      if (errors.length > 0) {
        console.error('[ActionConfigEditor] Validation errors:', errors.join(', '));
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

      console.info('[ActionConfigEditor] Validation passed');

      // 创建新的 action 对象（不能直接修改 @Prop 变量）
      const updatedAction: Action = {
        id: this.action.id,
        macroId: this.action.macroId,
        type: this.action.type,
        config: JSON.stringify(this.configData),
        orderIndex: this.action.orderIndex
      };

      console.info('[ActionConfigEditor] Updated action created:', JSON.stringify(updatedAction));

      // 调用回调
      if (this.onSave) {
        console.info('[ActionConfigEditor] Calling onSave callback');
        this.onSave(updatedAction);
      } else {
        console.warn('[ActionConfigEditor] onSave callback is not defined!');
      }

      console.info('[ActionConfigEditor] Closing dialog');
      // 关闭对话框
      this.controller.close();
    } catch (error) {
      console.error('[ActionConfigEditor] Failed to save config:', error);
      AlertDialog.show({
        title: '保存失败',
        message: `错误：${error}`,
        confirm: {
          value: '确定',
          action: () => {}
        }
      });
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

      case ActionType.LAUNCH_APP:
        if (!this.configData['bundleName']) {
          errors.push('应用包名不能为空');
        }
        if (this.configData['mode'] === 'explicit' && !this.configData['abilityName']) {
          errors.push('显式启动需要指定组件名');
        }
        if (this.configData['mode'] === 'implicit' && !this.configData['action'] && !this.configData['uri']) {
          errors.push('隐式启动需要指定 action 或 uri');
        }
        break;

      case ActionType.SET_VARIABLE:
        if (!this.configData['variableName']) {
          errors.push('变量名不能为空');
        }
        if (!this.configData['value']) {
          errors.push('变量值不能为空');
        }
        if (!this.configData['scope']) {
          errors.push('变量作用域不能为空');
        }
        break;

      case ActionType.IF_ELSE:
        if (!this.configData['branches'] || !(this.configData['branches'] as Object[]).length) {
          errors.push('至少需要一个分支');
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
      'launch_app': '启动应用',
      'set_variable': '设置变量',
      'if_else': '条件分支'
    };
    return names[this.action.type] || this.action.type;
  }

  /**
   * 构建启动应用配置表单
   */
  @Builder
  buildLaunchAppForm() {
    Column({ space: 16 }) {
      // 启动模式
      Column({ space: 8 }) {
        Text('启动模式 *')
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('显式启动')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['mode'] === 'explicit' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['mode'] === 'explicit' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('mode', 'explicit');
            })

          Button('隐式启动')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['mode'] === 'implicit' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['mode'] === 'implicit' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('mode', 'implicit');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 应用包名
      Column({ space: 8 }) {
        Text('应用包名 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：com.huawei.hmos.contacts',
          text: this.configData['bundleName'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.updateConfigData('bundleName', value);
          })

        Text('HarmonyOS 应用的唯一标识符')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 显式启动：组件名
      if (this.configData['mode'] === 'explicit') {
        Column({ space: 8 }) {
          Text('组件名 *')
            .fontSize(14)
            .fontColor('#666666')

          TextInput({
            placeholder: '例如：com.huawei.hmos.contacts.MainAbility',
            text: this.configData['abilityName'] as string
          })
            .fontSize(14)
            .onChange((value: string) => {
              this.updateConfigData('abilityName', value);
            })

          Text('完整类名，包含包名')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      // 隐式启动配置
      if (this.configData['mode'] === 'implicit') {
        Column({ space: 16 }) {
          // Action
          Column({ space: 8 }) {
            Text('Action（可选）')
              .fontSize(14)
              .fontColor('#666666')

            TextInput({
              placeholder: '例如：ohos.want.action.VIEW',
              text: this.configData['action'] as string
            })
              .fontSize(14)
              .onChange((value: string) => {
                this.updateConfigData('action', value);
              })

            Text('常用的：ohos.want.action.VIEW、ohos.want.action.DIAL')
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // URI
          Column({ space: 8 }) {
            Text('URI（可选）')
              .fontSize(14)
              .fontColor('#666666')

            TextInput({
              placeholder: '例如：https://example.com 或 tel:123456789',
              text: this.configData['uri'] as string
            })
              .fontSize(14)
              .onChange((value: string) => {
                this.updateConfigData('uri', value);
              })

            Text('支持引用变量，例如：{url_variable}')
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      // 启动参数
      Column({ space: 8 }) {
        Text('启动参数（可选）')
          .fontSize(14)
          .fontColor('#666666')

        TextArea({
          placeholder: 'JSON 格式的键值对，例如：\n{"key1": "value1", "key2": "value2"}',
          text: this.configData['parameters'] ? JSON.stringify(this.configData['parameters'], null, 2) : ''
        })
          .fontSize(14)
          .height(120)
          .onChange((value: string) => {
            try {
              if (value.trim()) {
                const params: Record<string, Object> = JSON.parse(value);
                this.updateConfigData('parameters', params);
              } else {
                this.updateConfigData('parameters', {} as Record<string, Object>);
              }
            } catch (error) {
              // JSON 解析错误，暂不处理，用户可能在输入中
            }
          })

        Text('将作为 Want.parameters 传递给目标应用')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 使用说明
      Column({ space: 8 }) {
        Text('使用说明')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)

        Column({ space: 4 }) {
          Text('• 显式启动：直接指定应用包名和组件名，推荐用于已知应用')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
          Text('• 隐式启动：通过 action 或 uri 启动，系统自动匹配应用')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
          Text('• 获取包名：使用 DevEco Studio 的 HAP 查看工具')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor('#f9f9f9')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  build() {
    Column() {
      // 统一顶部标题栏（需要避让状态栏）
      CommonTopBar({
        title: this.isEditMode ? `编辑${this.getActionTypeName()}` : `添加${this.getActionTypeName()}`,
        avoidStatusBar: true, // 自定义对话框需要避让状态栏
        onLeftClick: () => { this.handleCancel(); },
        onRightClick: () => { this.handleSave(); }
      })

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
    if (this.action.type === ActionType.CLIPBOARD_READ || this.action.type === ActionType.CLIPBOARD_WRITE) {
      this.buildClipboardForm();
    } else if (this.action.type === ActionType.TEXT_PROCESS) {
      this.buildTextProcessForm();
    } else if (this.action.type === ActionType.HTTP_REQUEST) {
      this.buildHttpRequestForm();
    } else if (this.action.type === ActionType.USER_DIALOG) {
      this.buildUserDialogForm();
    } else if (this.action.type === ActionType.OPEN_URL) {
      this.buildOpenUrlForm();
    } else if (this.action.type === ActionType.NOTIFICATION) {
      this.buildNotificationForm();
    } else if (this.action.type === ActionType.LAUNCH_APP) {
      this.buildLaunchAppForm();
    } else if (this.action.type === ActionType.SET_VARIABLE) {
      this.buildSetVariableForm();
    } else if (this.action.type === ActionType.IF_ELSE) {
      this.buildIfElseForm();
    } else {
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
              this.updateConfigData('operation', 'read');
            })

          Button('写入')
            .fontSize(14)
            .height(36)
            .backgroundColor(this.configData['operation'] === 'write' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['operation'] === 'write' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('operation', 'write');
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
              this.updateConfigData('saveToVariable', value);
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
              this.updateConfigData('content', value);
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
              this.updateConfigData('input', value);
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
            this.updateConfigData('saveToVariable', value);
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
        this.updateConfigData('operation', operation);
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
            this.updateConfigData('pattern', value);
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
            this.updateConfigData('groupIndex', Number(value) || 0);
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
        this.updateConfigData('pattern', pattern);
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
            this.updateConfigData('searchValue', value);
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
            this.updateConfigData('replaceValue', value);
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
          this.updateConfigData('separator', value);
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
              this.updateConfigData('method', 'GET');
            })

          Button('POST')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'POST' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'POST' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('method', 'POST');
            })

          Button('PUT')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'PUT' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'PUT' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('method', 'PUT');
            })

          Button('DELETE')
            .fontSize(12)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['method'] === 'DELETE' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['method'] === 'DELETE' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('method', 'DELETE');
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
            this.updateConfigData('url', value);
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
            const headers = this.configData['headers'] as Record<string, string> || {};
            headers['Content-Type'] = value;
            this.updateConfigData('headers', headers);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // Body（仅 POST/PUT 显示）
      if (this.configData['method'] === 'POST' || this.configData['method'] === 'PUT') {
        // Body 类型选择
        Column({ space: 8 }) {
          Text('请求体类型')
            .fontSize(14)
            .fontColor('#666666')

          Row({ space: 8 }) {
            Button('JSON')
              .fontSize(12)
              .height(32)
              .flexGrow(1)
              .backgroundColor((this.configData['bodyType'] || 'json') === 'json' ? '#007DFF' : '#f0f0f0')
              .fontColor((this.configData['bodyType'] || 'json') === 'json' ? '#ffffff' : '#333333')
              .onClick(() => {
                this.updateConfigData('bodyType', 'json');
                // 自动设置 Content-Type
                const headers = this.configData['headers'] as Record<string, string> || {};
                if (!headers['Content-Type']) {
                  headers['Content-Type'] = 'application/json';
                  this.updateConfigData('headers', headers);
                }
              })

            Button('Form')
              .fontSize(12)
              .height(32)
              .flexGrow(1)
              .backgroundColor(this.configData['bodyType'] === 'form' ? '#007DFF' : '#f0f0f0')
              .fontColor(this.configData['bodyType'] === 'form' ? '#ffffff' : '#333333')
              .onClick(() => {
                this.updateConfigData('bodyType', 'form');
                // 自动设置 Content-Type
                const headers = this.configData['headers'] as Record<string, string> || {};
                if (!headers['Content-Type']) {
                  headers['Content-Type'] = 'application/x-www-form-urlencoded';
                  this.updateConfigData('headers', headers);
                }
              })

            Button('Text')
              .fontSize(12)
              .height(32)
              .flexGrow(1)
              .backgroundColor(this.configData['bodyType'] === 'text' ? '#007DFF' : '#f0f0f0')
              .fontColor(this.configData['bodyType'] === 'text' ? '#ffffff' : '#333333')
              .onClick(() => {
                this.updateConfigData('bodyType', 'text');
              })
          }

          Text('默认为 JSON 格式，自动设置 Content-Type')
            .fontSize(11)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        // Body 输入框
        Column({ space: 8 }) {
          Text('请求体（Body）')
            .fontSize(14)
            .fontColor('#666666')

          TextArea({
            placeholder: (this.configData['bodyType'] || 'json') === 'json' ? '输入 JSON 格式，例如：{"key": "value"}' :
              this.configData['bodyType'] === 'form' ? '输入表单格式，例如：key1=value1&key2=value2' :
              '输入纯文本',
            text: this.configData['body'] as string
          })
            .fontSize(14)
            .height(150)
            .onChange((value: string) => {
              this.updateConfigData('body', value);
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
            this.updateConfigData('timeout', Number(value) || 30000);
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
            this.updateConfigData('saveResponseTo', value);
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
            this.updateConfigData('title', value);
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
            this.updateConfigData('message', value);
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
              this.updateConfigData('options', options);
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
                this.updateConfigData('placeholder', value);
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
                this.updateConfigData('defaultValue', value);
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
            this.updateConfigData('saveToVariable', value);
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
        this.updateConfigData('type', type);
      })
  }

  /**
   * 构建条件分支配置表单
   */
  @Builder
  buildIfElseForm() {
    if (this.showBranchEditor) {
      this.buildBranchEditor();
    } else {
      this.buildBranchList();
    }
  }

  /**
   * 构建分支列表视图
   */
  @Builder
  buildBranchList() {
    Column({ space: 16 }) {
      // 标题和添加按钮
      Row() {
        Text('条件分支')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .flexGrow(1)

        Button('添加分支')
          .fontSize(14)
          .height(36)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#007DFF')
          .borderRadius(18)
          .onClick(() => {
            this.addBranch();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分支列表
      if (this.branches.length === 0) {
        Column() {
          Text('暂无分支')
            .fontSize(14)
            .fontColor('#999999')
            .padding(40)

          Button('创建第一个分支')
            .fontSize(14)
            .height(40)
            .padding({ left: 20, right: 20 })
            .backgroundColor('#007DFF')
            .borderRadius(20)
            .onClick(() => {
              this.addBranch();
            })
        }
        .width('100%')
        .padding(40)
        .backgroundColor('#fafafa')
        .borderRadius(12)
        .border({ width: 2, color: '#e0e0e0', style: BorderStyle.Dashed })
      } else {
        ForEach(this.branches, (branch: BranchConfig, index: number) => {
          this.buildBranchCard(branch, index);
        }, (branch: BranchConfig, index: number) => `${index}`)
      }

      // 说明文本
      Column({ space: 8 }) {
        Text('使用说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)

        Column({ space: 4 }) {
          Text('• 按顺序评估分支条件，第一个满足条件的分支将被执行')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
          Text('• 最后一个空条件的分支将作为 else 分支')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#fff7e6')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
  }

  /**
   * 构建单个分支卡片
   */
  @Builder
  buildBranchCard(branch: BranchConfig, index: number) {
    Column({ space: 12 }) {
      // 分支标题栏
      Row() {
        Column({ space: 4 }) {
          Text(branch.name || `分支 ${index + 1}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          if (branch.conditions.length === 0) {
            Text('else 分支（默认执行）')
              .fontSize(12)
              .fontColor('#ff9800')
          } else {
            Text(`${branch.conditions.length} 个条件 · ${branch.actions.length} 个动作`)
              .fontSize(12)
              .fontColor('#666666')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .flexGrow(1)

        Row({ space: 8 }) {
          Button('编辑')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#e6f7ff')
            .fontColor('#1890ff')
            .onClick(() => {
              this.editBranch(index);
            })

          Button('删除')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#fff1f0')
            .fontColor('#ff4d4f')
            .onClick(() => {
              this.deleteBranch(index);
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider()

      // 条件预览
      if (branch.conditions.length > 0) {
        Column({ space: 8 }) {
          Text('条件')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)

          Column({ space: 6 }) {
            ForEach(branch.conditions, (condition: BranchCondition, condIndex: number) => {
              Row({ space: 8 }) {
                Text(condition.field)
                  .fontSize(13)
                  .fontColor('#1890ff')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(condition.operator)
                  .fontSize(13)
                  .fontColor('#666666')

                Text(condition.value)
                  .fontSize(13)
                  .fontColor('#52c41a')
                  .flexGrow(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }, (condition: BranchCondition, condIndex: number) => `${condIndex}`)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#f9f9f9')
          .borderRadius(6)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      // 动作预览
      if (branch.actions.length > 0) {
        Column({ space: 8 }) {
          Text('执行动作')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(branch.actions.slice(0, 3), (action: BaseBranchActionConfig, actionIndex: number) => {
              Text(this.getActionTypeLabel(action.type))
                .fontSize(12)
                .fontColor('#666666')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#f0f0f0')
                .borderRadius(4)
            }, (action: BaseBranchActionConfig, actionIndex: number) => `${actionIndex}`)

            if (branch.actions.length > 3) {
              Text(`+${branch.actions.length - 3}`)
                .fontSize(12)
                .fontColor('#999999')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#f0f0f0')
                .borderRadius(4)
            }
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#0000000d', offsetX: 0, offsetY: 2 })
  }

  /**
   * 构建分支编辑器
   */
  @Builder
  buildBranchEditor() {
    Column({ space: 16 }) {
      // 返回按钮
      Button('← 返回分支列表')
        .fontSize(14)
        .height(36)
        .backgroundColor('#f5f5f5')
        .fontColor('#666666')
        .borderRadius(18)
        .onClick(() => {
          this.showBranchEditor = false;
        })
        .alignSelf(ItemAlign.Start)

      // 分支名称
      Column({ space: 8 }) {
        Text('分支名称')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)

        TextInput({
          placeholder: '例如：条件分支 1',
          text: this.branches[this.editingBranchIndex].name
        })
          .fontSize(14)
          .height(44)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .onChange((value: string) => {
            const branch = this.branches[this.editingBranchIndex];
            branch.name = value;
            this.updateBranchInConfig();
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 条件列表
      Column({ space: 12 }) {
        Row() {
          Text('条件')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .flexGrow(1)

          Button('添加条件')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#e6f7ff')
            .fontColor('#1890ff')
            .borderRadius(16)
            .onClick(() => {
              this.addCondition();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.branches[this.editingBranchIndex].conditions.length === 0) {
          Column() {
            Text('else 分支（无条件）')
              .fontSize(13)
              .fontColor('#ff9800')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#fff7e6')
          .borderRadius(8)
        } else {
          ForEach(this.branches[this.editingBranchIndex].conditions,
            (condition: BranchCondition, condIndex: number) => {
              this.buildConditionCard(condition, condIndex);
            }, (condition: BranchCondition, condIndex: number) => `${condIndex}`)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 动作列表
      Column({ space: 12 }) {
        Row() {
          Text('执行动作')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .flexGrow(1)

          Button('添加动作')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#e6f7ff')
            .fontColor('#1890ff')
            .borderRadius(16)
            .onClick(() => {
              this.addAction();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        ForEach(this.branches[this.editingBranchIndex].actions,
          (action: BaseBranchActionConfig, actionIndex: number) => {
            this.buildActionCard(action, actionIndex);
          }, (action: BaseBranchActionConfig, actionIndex: number) => `${actionIndex}`)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .padding(16)
  }

  /**
   * 构建条件卡片
   */
  @Builder
  buildConditionCard(condition: BranchCondition, condIndex: number) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        // 字段选择
        Column({ space: 4 }) {
          Text('字段')
            .fontSize(11)
            .fontColor('#999999')

          TextInput({
            placeholder: '{变量}',
            text: condition.field
          })
            .fontSize(13)
            .height(36)
            .padding({ left: 10, right: 10 })
            .backgroundColor('#f5f5f5')
            .borderRadius(6)
            .onChange((value: string) => {
              condition.field = value;
              this.updateBranchInConfig();
            })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 操作符选择
        Column({ space: 4 }) {
          Text('操作符')
            .fontSize(11)
            .fontColor('#999999')

          Select([
            { value: '==' },
            { value: '!=' },
            { value: '>' },
            { value: '<' },
            { value: '>=' },
            { value: '<=' },
            { value: '包含' },
            { value: '不包含' }
          ])
            .selected(this.getOperatorIndex(condition.operator))
            .value(this.getOperatorLabel(condition.operator))
            .font({ size: 13 })
            .selectedOptionFont({ size: 13 })
            .optionFont({ size: 13 })
            .height(36)
            .backgroundColor('#f5f5f5')
            .borderRadius(6)
            .onSelect((index: number, value: string) => {
              condition.operator = value;
              this.updateBranchInConfig();
            })
        }
        .alignItems(HorizontalAlign.Start)

        // 值输入
        Column({ space: 4 }) {
          Text('值')
            .fontSize(11)
            .fontColor('#999999')

          TextInput({
            placeholder: '比较值',
            text: condition.value
          })
            .fontSize(13)
            .height(36)
            .padding({ left: 10, right: 10 })
            .backgroundColor('#f5f5f5')
            .borderRadius(6)
            .onChange((value: string) => {
              condition.value = value;
              this.updateBranchInConfig();
            })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 删除按钮
      Row() {
        Blank()
        Button('删除条件')
          .fontSize(11)
          .height(28)
          .padding({ left: 10, right: 10 })
          .backgroundColor('#fff1f0')
          .fontColor('#ff4d4f')
          .borderRadius(14)
          .onClick(() => {
            this.deleteCondition(condIndex);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#ffffff')
    .borderRadius(8)
    .border({ width: 1, color: '#e0e0e0' })
  }

  /**
   * 构建动作卡片
   */
  @Builder
  buildActionCard(action: BaseBranchActionConfig, actionIndex: number) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(this.getActionTypeLabel(action.type))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text(this.getActionConfigSummary(action))
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .flexGrow(1)

      Button('删除')
        .fontSize(11)
        .height(28)
        .padding({ left: 10, right: 10 })
        .backgroundColor('#fff1f0')
        .fontColor('#ff4d4f')
        .borderRadius(14)
        .onClick(() => {
          this.deleteAction(actionIndex);
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#ffffff')
    .borderRadius(8)
    .border({ width: 1, color: '#e0e0e0' })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 添加分支
   */
  private addBranch() {
    const newBranch: BranchConfig = {
      name: `分支 ${this.branches.length + 1}`,
      conditions: [],
      actions: []
    };
    this.branches.push(newBranch);
    this.editBranch(this.branches.length - 1);
    this.updateBranchInConfig();
  }

  /**
   * 编辑分支
   */
  private editBranch(index: number) {
    this.editingBranchIndex = index;
    this.showBranchEditor = true;
  }

  /**
   * 删除分支
   */
  private deleteBranch(index: number) {
    this.branches.splice(index, 1);
    this.updateBranchInConfig();
  }

  /**
   * 添加条件
   */
  private addCondition() {
    const newCondition: BranchCondition = {
      field: '{variable}',
      operator: '==',
      value: 'value'
    };
    this.branches[this.editingBranchIndex].conditions.push(newCondition);
    this.updateBranchInConfig();
  }

  /**
   * 删除条件
   */
  private deleteCondition(condIndex: number) {
    this.branches[this.editingBranchIndex].conditions.splice(condIndex, 1);
    this.updateBranchInConfig();
  }

  /**
   * 添加动作
   */
  private addAction() {
    const config: NotificationActionConfig = {
      title: '通知标题',
      content: '通知内容',
      enableSound: false,
      enableVibration: false
    };

    const newAction: BaseBranchActionConfig = {
      type: 'notification',
      config: config
    };
    this.branches[this.editingBranchIndex].actions.push(newAction);
    this.updateBranchInConfig();
  }

  /**
   * 删除动作
   */
  private deleteAction(actionIndex: number) {
    this.branches[this.editingBranchIndex].actions.splice(actionIndex, 1);
    this.updateBranchInConfig();
  }

  /**
   * 更新配置数据
   */
  private updateBranchInConfig() {
    this.updateConfigData('branches', this.branches);
  }

  /**
   * 获取操作符标签
   */
  private getOperatorLabel(operator: string): string {
    const labels: Record<string, string> = {
      '==': '等于',
      '!=': '不等于',
      '>': '大于',
      '<': '小于',
      '>=': '大于等于',
      '<=': '小于等于',
      '包含': '包含',
      '不包含': '不包含'
    };
    return labels[operator] || operator;
  }

  /**
   * 获取操作符索引
   */
  private getOperatorIndex(operator: string): number {
    const operators = ['==', '!=', '>', '<', '>=', '<=', '包含', '不包含'];
    return operators.indexOf(operator);
  }

  /**
   * 获取动作类型标签
   */
  private getActionTypeLabel(type: string): string {
    const labels: Record<string, string> = {
      'notification': '发送通知',
      'clipboard_read': '读取剪贴板',
      'clipboard_write': '写入剪贴板',
      'http_request': 'HTTP 请求',
      'open_url': '打开 URL',
      'text_process': '文本处理',
      'launch_app': '启动应用',
      'user_dialog': '用户对话框',
      'set_variable': '设置变量'
    };
    return labels[type] || type;
  }

  /**
   * 获取动作配置摘要
   */
  private getActionConfigSummary(action: BaseBranchActionConfig): string {
    if (action.type === 'notification') {
      const config = action.config as NotificationActionConfig;
      return config.title || '无标题';
    } else if (action.type === 'http_request') {
      const config = action.config as HttpRequestActionConfig;
      return config.url || '无 URL';
    } else if (action.type === 'open_url') {
      const config = action.config as OpenUrlActionConfig;
      return config.url || '无 URL';
    } else {
      return '点击查看详情';
    }
  }

  /**
   * 构建打开 URL 配置表单
   */
  @Builder
  buildOpenUrlForm() {
    Column({ space: 16 }) {
      // URL
      Column({ space: 8 }) {
        Text('URL *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：https://example.com',
          text: this.configData['url'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.updateConfigData('url', value);
          })

        Text('支持引用变量，例如：{extracted_url}')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 打开方式
      Column({ space: 8 }) {
        Text('打开方式 *')
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('浏览器')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['openWith'] === 'browser' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['openWith'] === 'browser' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('openWith', 'browser');
            })

          Button('应用内')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['openWith'] === 'app' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['openWith'] === 'app' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('openWith', 'app');
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 使用说明
      Column({ space: 8 }) {
        Text('使用说明')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)

        Column({ space: 4 }) {
          Text('• 浏览器：使用系统浏览器打开链接')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
          Text('• 应用内：在应用内 WebView 中打开')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor('#f9f9f9')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  /**
   * 构建通知配置表单
   */
  @Builder
  buildNotificationForm() {
    Column({ space: 16 }) {
      // 通知标题
      Column({ space: 8 }) {
        Text('通知标题 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：任务完成',
          text: this.configData['title'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.updateConfigData('title', value);
          })

        Text('支持引用变量，例如：{variable_name}')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 通知内容
      Column({ space: 8 }) {
        Text('通知内容 *')
          .fontSize(14)
          .fontColor('#666666')

        TextArea({
          placeholder: '输入通知内容',
          text: this.configData['content'] as string
        })
          .fontSize(14)
          .height(100)
          .onChange((value: string) => {
            this.updateConfigData('content', value);
          })

        Text('支持引用变量，例如：处理了 {count} 条记录')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 通知选项
      Column({ space: 16 }) {
        Text('通知选项')
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 8 }) {
          // 提示音
          Row({ space: 8 }) {
            Text('提示音')
              .fontSize(14)
              .fontColor('#333333')

            Toggle({ type: ToggleType.Switch, isOn: this.configData['enableSound'] as boolean || false })
              .onChange((isOn: boolean) => {
                this.updateConfigData('enableSound', isOn);
              })
          }
          .flexGrow(1)

          // 震动
          Row({ space: 8 }) {
            Text('震动')
              .fontSize(14)
              .fontColor('#333333')

            Toggle({ type: ToggleType.Switch, isOn: this.configData['enableVibration'] as boolean || false })
              .onChange((isOn: boolean) => {
                this.updateConfigData('enableVibration', isOn);
              })
          }
          .flexGrow(1)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 使用说明
      Column({ space: 8 }) {
        Text('使用说明')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)

        Column({ space: 4 }) {
          Text('• 提示音：通知到达时播放系统提示音')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
          Text('• 震动：通知到达时震动提醒')
            .fontSize(12)
            .fontColor('#999999')
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor('#f9f9f9')
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  /**
   * 构建设置变量配置表单
   */
  @Builder
  buildSetVariableForm() {
    Column({ space: 16 }) {
      // 变量名
      Column({ space: 8 }) {
        Text('变量名 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：user_input',
          text: this.configData['variableName'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.updateConfigData('variableName', value);
          })

        Text('变量名只能包含字母、数字和下划线')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 变量值
      Column({ space: 8 }) {
        Text('变量值 *')
          .fontSize(14)
          .fontColor('#666666')

        TextInput({
          placeholder: '例如：{clipboard} 或直接输入值',
          text: this.configData['value'] as string
        })
          .fontSize(14)
          .onChange((value: string) => {
            this.updateConfigData('value', value);
          })

        Text('可直接输入常量值或引用变量 {varName}')
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 变量作用域
      Column({ space: 8 }) {
        Text('变量作用域 *')
          .fontSize(14)
          .fontColor('#666666')

        Row({ space: 8 }) {
          Button('运行时')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['scope'] === 'runtime' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['scope'] === 'runtime' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('scope', 'runtime');
            })

          Button('宏级')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['scope'] === 'macro' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['scope'] === 'macro' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('scope', 'macro');
            })

          Button('全局')
            .fontSize(14)
            .height(36)
            .flexGrow(1)
            .backgroundColor(this.configData['scope'] === 'global' ? '#007DFF' : '#f0f0f0')
            .fontColor(this.configData['scope'] === 'global' ? '#ffffff' : '#333333')
            .onClick(() => {
              this.updateConfigData('scope', 'global');
            })
        }
        .width('100%')

        // 作用域说明
        if (this.configData['scope'] === 'runtime') {
          Text('运行时变量仅在当前宏执行期间有效')
            .fontSize(12)
            .fontColor('#999999')
        } else if (this.configData['scope'] === 'macro') {
          Text('宏级变量持久化保存，仅在当前宏中可用')
            .fontSize(12)
            .fontColor('#999999')
        } else if (this.configData['scope'] === 'global') {
          Text('全局变量持久化保存，所有宏均可访问')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      // 使用示例
      Column({ space: 8 }) {
        Text('使用示例')
          .fontSize(14)
          .fontColor('#666666')

        Column({ space: 4 }) {
          Text('• 设置常量值: value = "Hello World"')
            .fontSize(12)
            .fontColor('#999999')
          Text('• 引用变量: value = "{clipboard}"')
            .fontSize(12)
            .fontColor('#999999')
          Text('• 组合使用: value = "用户输入: {user_input}"')
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .backgroundColor('#f9f9f9')
        .borderRadius(8)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
  }
}
