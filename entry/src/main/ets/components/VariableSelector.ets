import { Variable } from '../models/Variable';

/**
 * 变量选项数据结构
 */
export interface VariableOption {
  name: string;                 // 变量名（不含花括号）
  displayName: string;          // 显示名称（含花括号）
  type: 'system' | 'runtime' | 'macro' | 'global';  // 变量类型
  description?: string;         // 描述信息
  sourceActionIndex?: number;   // 来源动作索引（runtime 类型）
}

/**
 * 变量选择器组件
 * 用于在配置动作时选择变量
 */
@Component
export struct VariableSelector {
  // 可用变量列表
  @Link availableVariables: VariableOption[];

  // 当前选中的变量
  @Link selectedVariable: string;

  // 是否显示系统变量
  @State showSystemVariables: boolean = true;

  // 搜索关键词
  @State searchKeyword: string = '';

  // 回调函数
  onVariableSelected?: (variableName: string) => void;
  onCancel?: () => void;

  /**
   * 过滤变量列表
   */
  private getFilteredVariables(type: string): VariableOption[] {
    return this.availableVariables
      .filter(v => v.type === type)
      .filter(v => {
        if (!this.searchKeyword) return true;
        return v.name.toLowerCase().includes(this.searchKeyword.toLowerCase()) ||
               v.description?.toLowerCase().includes(this.searchKeyword.toLowerCase());
      });
  }

  /**
   * 处理变量选择
   */
  private handleSelectVariable(variableName: string) {
    this.selectedVariable = variableName;
    if (this.onVariableSelected) {
      this.onVariableSelected(variableName);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('选择变量')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .flexGrow(1)

        Button('取消')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel();
            }
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')

      // 搜索框
      Row() {
        TextInput({ placeholder: '搜索变量名...', text: this.searchKeyword })
          .fontSize(16)
          .flexGrow(1)
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#ffffff')

      Divider()

      // 变量列表
      Scroll() {
        Column() {
          // 系统变量
          if (this.showSystemVariables) {
            this.buildVariableSection('系统变量', 'system', '#52c41a');
          }

          // 运行时变量（动作输出）
          this.buildVariableSection('运行时变量', 'runtime', '#1890ff');

          // 宏变量
          this.buildVariableSection('宏变量', 'macro', '#722ed1');

          // 全局变量
          this.buildVariableSection('全局变量', 'global', '#fa8c16');
        }
        .width('100%')
      }
      .flexGrow(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  /**
   * 构建变量分组
   */
  @Builder
  buildVariableSection(title: string, type: string, color: string) {
    const variables = this.getFilteredVariables(type);

    if (variables.length > 0) {
      Column() {
        // 分组标题
        Text(title)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 16, top: 16, bottom: 8 })

        // 变量列表
        Column() {
          ForEach(variables, (variable: VariableOption) => {
            this.buildVariableItem(variable, color);
          }, (variable: VariableOption) => variable.name)
        }
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .margin({ left: 16, right: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  /**
   * 构建变量项
   */
  @Builder
  buildVariableItem(variable: VariableOption, color: string) {
    Row() {
      // 变量类型指示器
      Text()
        .width(4)
        .height('100%')
        .backgroundColor(color)
        .margin({ right: 12 })

      // 变量信息
      Column({ space: 4 }) {
        Text(variable.displayName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedVariable === variable.name ? '#007DFF' : '#333333')

        if (variable.description) {
          Text(variable.description)
            .fontSize(12)
            .fontColor('#999999')
        }

        if (variable.sourceActionIndex !== undefined) {
          Text(`来自动作 ${variable.sourceActionIndex + 1}`)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .flexGrow(1)
      .alignItems(HorizontalAlign.Start)

      // 选中标记
      if (this.selectedVariable === variable.name) {
        Text('✓')
          .fontSize(20)
          .fontColor('#007DFF')
      }
    }
    .width('100%')
    .padding(12)
    .onClick(() => {
      this.handleSelectVariable(variable.name);
    })

    Divider()
      .strokeWidth(0.5)
      .color('#f0f0f0')
  }
}

/**
 * 变量选择器帮助类
 * 用于生成可用变量列表
 */
export class VariableSelectorHelper {
  /**
   * 生成系统变量列表
   */
  static getSystemVariables(): VariableOption[] {
    return [
      {
        name: 'date',
        displayName: '{date}',
        type: 'system',
        description: '当前日期 (YYYY-MM-DD)'
      },
      {
        name: 'time',
        displayName: '{time}',
        type: 'system',
        description: '当前时间 (HH:mm:ss)'
      },
      {
        name: 'timestamp',
        displayName: '{timestamp}',
        type: 'system',
        description: '当前时间戳（毫秒）'
      },
      {
        name: 'clipboard',
        displayName: '{clipboard}',
        type: 'system',
        description: '剪贴板内容'
      },
      {
        name: 'network_type',
        displayName: '{network_type}',
        type: 'system',
        description: '当前网络类型'
      },
      {
        name: 'battery_level',
        displayName: '{battery_level}',
        type: 'system',
        description: '当前电量百分比'
      }
    ];
  }

  /**
   * 从宏变量生成选项
   */
  static fromMacroVariables(variables: Variable[]): VariableOption[] {
    return variables
      .filter(v => v.scope === 'macro')
      .map(v => ({
        name: v.name,
        displayName: `{${v.name}}`,
        type: 'macro' as const,
        description: `类型: ${this.getTypeLabel(v.type)}, 值: ${v.value}`
      }));
  }

  /**
   * 从全局变量生成选项
   */
  static fromGlobalVariables(variables: Variable[]): VariableOption[] {
    return variables
      .filter(v => v.scope === 'global')
      .map(v => ({
        name: v.name,
        displayName: `{${v.name}}`,
        type: 'global' as const,
        description: `类型: ${this.getTypeLabel(v.type)}, 值: ${v.value}`
      }));
  }

  /**
   * 获取变量类型标签
   */
  private static getTypeLabel(type: string): string {
    const labels: Record<string, string> = {
      'string': '文本',
      'number': '数字',
      'boolean': '布尔'
    };
    return labels[type] || type;
  }
}
