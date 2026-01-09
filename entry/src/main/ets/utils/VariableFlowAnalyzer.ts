import { Action, ActionType } from '../models/Macro';

/**
 * 变量流向数据结构
 */
export interface VariableFlow {
  variableName: string;           // 变量名
  sourceActionIndex: number;      // 来源动作索引（-1 表示全局变量或系统变量）
  targetActionIndices: number[];  // 使用该变量的动作索引
  type: 'runtime' | 'global' | 'system';  // 变量类型
}

/**
 * 变量流分析器
 * 用于分析宏中的变量定义、使用关系
 */
export class VariableFlowAnalyzer {
  /**
   * 分析动作列表中的变量流向
   * @param actions 动作列表
   * @returns 变量流向数组
   */
  static analyzeFlow(actions: Action[]): VariableFlow[] {
    const flows: VariableFlow[] = [];
    const definedVariables = new Set<string>();

    // 1. 添加系统变量
    const systemVariables = ['date', 'time', 'timestamp', 'clipboard', 'network_type', 'battery_level'];
    systemVariables.forEach(varName => {
      definedVariables.add(varName);
      flows.push({
        variableName: varName,
        sourceActionIndex: -1,
        targetActionIndices: [],
        type: 'system'
      });
    });

    // 2. 遍历动作，提取输入输出变量
    actions.forEach((action, index) => {
      try {
        const config = JSON.parse(action.config);

        // 提取输出变量
        const outputVar = this.extractOutputVariable(action.type, config);
        if (outputVar) {
          definedVariables.add(outputVar);

          // 检查是否已存在
          const existingFlow = flows.find(f => f.variableName === outputVar);
          if (existingFlow) {
            // 更新来源为当前动作
            existingFlow.sourceActionIndex = index;
            existingFlow.type = 'runtime';
          } else {
            flows.push({
              variableName: outputVar,
              sourceActionIndex: index,
              targetActionIndices: [],
              type: 'runtime'
            });
          }
        }

        // 提取输入变量
        const inputVars = this.extractInputVariables(action.type, config);
        inputVars.forEach(varName => {
          const flow = flows.find(f => f.variableName === varName);
          if (flow && !flow.targetActionIndices.includes(index)) {
            flow.targetActionIndices.push(index);
          }
        });
      } catch (error) {
        console.error(`[VariableFlowAnalyzer] Failed to parse action config at index ${index}:`, error);
      }
    });

    return flows;
  }

  /**
   * 提取动作的输出变量
   * @param type 动作类型
   * @param config 动作配置
   * @returns 输出变量名，如果没有则返回 null
   */
  private static extractOutputVariable(type: ActionType, config: any): string | null {
    switch (type) {
      case ActionType.CLIPBOARD_READ:
        return config.saveToVariable || null;

      case ActionType.TEXT_PROCESS:
        return config.saveToVariable || null;

      case ActionType.HTTP_REQUEST:
        return config.saveResponseTo || null;

      case ActionType.USER_DIALOG:
        return config.saveToVariable || null;

      default:
        return null;
    }
  }

  /**
   * 提取动作的输入变量（从字符串中解析 {varName}）
   * @param type 动作类型
   * @param config 动作配置
   * @returns 输入变量名数组
   */
  private static extractInputVariables(type: ActionType, config: any): string[] {
    const variables: Set<string> = new Set();
    const regex = /\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g;

    // 递归搜索配置对象中的所有字符串
    const searchObject = (obj: any) => {
      if (typeof obj === 'string') {
        let match;
        const tempRegex = new RegExp(regex);
        while ((match = tempRegex.exec(obj)) !== null) {
          variables.add(match[1]);
        }
      } else if (Array.isArray(obj)) {
        obj.forEach(searchObject);
      } else if (typeof obj === 'object' && obj !== null) {
        Object.values(obj).forEach(searchObject);
      }
    };

    searchObject(config);
    return Array.from(variables);
  }

  /**
   * 验证动作配置
   * @param action 动作
   * @param actionIndex 动作索引
   * @param definedVariables 已定义的变量集合
   * @returns 验证结果
   */
  static validateAction(
    action: Action,
    actionIndex: number,
    definedVariables: Set<string>
  ): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    try {
      const config = JSON.parse(action.config);

      // 检查输入变量是否已定义
      const inputVars = this.extractInputVariables(action.type, config);
      inputVars.forEach(varName => {
        if (!definedVariables.has(varName)) {
          errors.push(`变量 {${varName}} 未定义或在此动作之前未输出`);
        }
      });

      // 检查必填字段
      switch (action.type) {
        case ActionType.CLIPBOARD_READ:
          if (!config.saveToVariable) {
            errors.push('必须指定保存到的变量名');
          }
          break;

        case ActionType.TEXT_PROCESS:
          if (!config.input) {
            errors.push('输入来源不能为空');
          }
          if (config.operation === 'regex_extract' && !config.pattern) {
            errors.push('正则表达式不能为空');
          }
          if (config.operation === 'replace') {
            if (!config.searchValue) errors.push('搜索值不能为空');
            if (config.replaceValue === undefined) errors.push('替换值不能为空');
          }
          if (config.operation === 'split' && !config.separator) {
            errors.push('分隔符不能为空');
          }
          break;

        case ActionType.HTTP_REQUEST:
          if (!config.url) {
            errors.push('URL 不能为空');
          }
          if (!config.method) {
            errors.push('请求方法不能为空');
          }
          break;

        case ActionType.OPEN_URL:
          if (!config.url) {
            errors.push('URL 不能为空');
          }
          break;

        case ActionType.NOTIFICATION:
          if (!config.title) {
            errors.push('通知标题不能为空');
          }
          if (!config.content) {
            errors.push('通知内容不能为空');
          }
          break;

        case ActionType.USER_DIALOG:
          if (!config.type) {
            errors.push('对话框类型不能为空');
          }
          if (!config.title) {
            errors.push('对话框标题不能为空');
          }
          if ((config.type === 'single_select' || config.type === 'multi_select') &&
              (!config.options || config.options.length === 0)) {
            errors.push('选项列表不能为空');
          }
          break;

        case ActionType.LAUNCH_APP:
          if (!config.bundleName) {
            errors.push('应用包名不能为空');
          }
          break;
      }
    } catch (error) {
      errors.push('配置格式错误：无法解析 JSON');
    }

    return { isValid: errors.length === 0, errors };
  }

  /**
   * 获取动作之前已定义的变量
   * @param actions 动作列表
   * @param actionIndex 当前动作索引
   * @returns 已定义的变量集合
   */
  static getDefinedVariablesBeforeAction(
    actions: Action[],
    actionIndex: number
  ): Set<string> {
    const definedVariables = new Set<string>();

    // 添加系统变量
    ['date', 'time', 'timestamp', 'clipboard', 'network_type', 'battery_level']
      .forEach(varName => definedVariables.add(varName));

    // 添加之前动作输出的变量（包括设置变量动作）
    for (let i = 0; i < actionIndex; i++) {
      try {
        const config = JSON.parse(actions[i].config);
        const outputVar = this.extractOutputVariable(actions[i].type, config);
        if (outputVar) {
          definedVariables.add(outputVar);
        }
      } catch (error) {
        console.error(`[VariableFlowAnalyzer] Failed to parse action config at index ${i}:`, error);
      }
    }

    return definedVariables;
  }

  /**
   * 检查删除动作的影响
   * @param actions 动作列表
   * @param deleteIndex 要删除的动作索引
   * @returns 受影响的动作索引数组
   */
  static getAffectedActionsByDeletion(actions: Action[], deleteIndex: number): number[] {
    const affectedIndices: number[] = [];

    try {
      const config = JSON.parse(actions[deleteIndex].config);
      const outputVar = this.extractOutputVariable(actions[deleteIndex].type, config);

      if (!outputVar) {
        return []; // 该动作没有输出变量，删除不影响其他动作
      }

      // 检查后续动作是否使用了该变量
      for (let i = deleteIndex + 1; i < actions.length; i++) {
        const nextConfig = JSON.parse(actions[i].config);
        const inputVars = this.extractInputVariables(actions[i].type, nextConfig);

        if (inputVars.includes(outputVar)) {
          affectedIndices.push(i);
        }
      }
    } catch (error) {
      console.error(`[VariableFlowAnalyzer] Failed to analyze deletion impact:`, error);
    }

    return affectedIndices;
  }
}
