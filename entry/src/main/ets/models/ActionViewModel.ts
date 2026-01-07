import { Action } from './Macro';

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
  configSummary: string;         // 配置摘要（显示在卡片上）
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
   * @returns ActionViewModel
   */
  static create(
    action: Action,
    inputVariables: string[],
    outputVariable: string | null,
    configSummary: string,
    isValid: boolean,
    validationErrors: string[]
  ): ActionViewModel {
    return {
      ...action,
      inputVariables,
      outputVariable,
      configSummary,
      isValid,
      validationErrors
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
      isValid: true,
      validationErrors: []
    };
  }
}
