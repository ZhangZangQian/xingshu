import { Action } from './Macro';

/**
 * 结构化文本段接口
 * 用于展示可点击的配置摘要
 */
export interface TextSegment {
  text: string;            // 文本内容
  isClickable: boolean;     // 是否可点击
  color?: string;           // 文字颜色（可选）
  backgroundColor?: string; // 背景颜色（可选）
  value?: string;           // 实际值（点击时传递）
  field?: string;           // 字段标识（用于聚焦到对应输入框）
}

/**
 * 动作视图模型（用于 UI 层）
 * 扩展了原始 Action 模型，添加了 UI 相关的计算属性
 */
export interface ActionViewModel extends Action {
  // 原有字段继承自 Action:
  // id: number;
  // macroId: number;
  // type: ActionType;
  // config: string;
  // orderIndex: number;

  // UI 相关字段
  inputVariables: string[];      // 此动作使用的输入变量
  outputVariable: string | null; // 此动作输出的变量
  configSummary: string;         // 配置摘要（显示在卡片上，向后兼容）
  configSegments: TextSegment[]; // 结构化配置摘要（用于渲染可点击内容）
  isValid: boolean;              // 配置是否有效
  validationErrors: string[];    // 验证错误信息
}

/**
 * ActionViewModel 工厂类
 * 用于将 Action 转换为 ActionViewModel
 */
export class ActionViewModelFactory {
  /**
   * 将 Action 转换为 ActionViewModel
   * @param action 原始动作
   * @param inputVariables 输入变量数组
   * @param outputVariable 输出变量
   * @param configSummary 配置摘要
   * @param isValid 是否有效
   * @param validationErrors 验证错误
   * @param configSegments 结构化配置摘要（可选）
   * @returns ActionViewModel
   */
  static create(
    action: Action,
    inputVariables: string[],
    outputVariable: string | null,
    configSummary: string,
    isValid: boolean,
    validationErrors: string[],
    configSegments: TextSegment[] = []
  ): ActionViewModel {
    return {
      ...action,
      inputVariables,
      outputVariable,
      configSummary,
      isValid,
      validationErrors,
      configSegments
    };
  }

  /**
   * 从 Action 创建 ActionViewModel（自动计算所有属性）
   * 注意：此方法不进行验证，需要外部调用时传入已定义的变量集合
   */
  static fromAction(action: Action): ActionViewModel {
    return {
      ...action,
      inputVariables: [],
      outputVariable: null,
      configSummary: '',
      configSegments: [],
      isValid: true,
      validationErrors: []
    };
  }
}
