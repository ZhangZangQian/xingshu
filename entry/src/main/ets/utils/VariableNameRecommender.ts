import { ActionType } from '../models/Macro';

/**
 * 变量名推荐器
 * 根据动作类型和现有变量，智能推荐变量名
 */
export class VariableNameRecommender {
  /**
   * 推荐输出变量名
   * @param actionType 动作类型
   * @param existingVariables 已存在的变量名集合
   * @returns 推荐的变量名
   */
  static recommendOutputVariableName(
    actionType: ActionType,
    existingVariables: Set<string>
  ): string {
    // 获取基础推荐名称
    const baseName = this.getBaseNameForActionType(actionType);

    // 如果基础名称未被使用，直接返回
    if (!existingVariables.has(baseName)) {
      return baseName;
    }

    // 否则添加数字后缀
    let counter = 2;
    let candidateName = `${baseName}${counter}`;
    while (existingVariables.has(candidateName)) {
      counter++;
      candidateName = `${baseName}${counter}`;
    }

    return candidateName;
  }

  /**
   * 根据动作类型获取基础变量名
   */
  private static getBaseNameForActionType(actionType: ActionType): string {
    const baseNames: Record<string, string> = {
      'clipboard_read': 'clipboard_content',
      'clipboard_write': 'clipboard_result',
      'text_process': 'processed_text',
      'http_request': 'api_response',
      'user_dialog': 'user_input',
      'open_url': 'url_result',
      'notification': 'notification_result',
      'launch_app': 'app_result'
    };

    return baseNames[actionType] || 'result';
  }

  /**
   * 推荐特定操作的变量名
   * @param actionType 动作类型
   * @param operation 操作类型（如 regex_extract）
   * @param existingVariables 已存在的变量名集合
   * @returns 推荐的变量名
   */
  static recommendSpecificVariableName(
    actionType: ActionType,
    operation: string,
    existingVariables: Set<string>
  ): string {
    let baseName = '';

    // 根据操作类型推荐特定名称
    if (actionType === ActionType.TEXT_PROCESS) {
      const operationNames: Record<string, string> = {
        'regex_extract': 'extracted_text',
        'replace': 'replaced_text',
        'split': 'split_result',
        'uppercase': 'uppercase_text',
        'lowercase': 'lowercase_text',
        'url_encode': 'encoded_url',
        'url_decode': 'decoded_url'
      };
      baseName = operationNames[operation] || 'processed_text';
    } else if (actionType === ActionType.USER_DIALOG) {
      const dialogNames: Record<string, string> = {
        'confirm': 'user_confirmed',
        'single_select': 'user_choice',
        'multi_select': 'user_selections',
        'text_input': 'user_input'
      };
      baseName = dialogNames[operation] || 'user_input';
    } else {
      baseName = this.getBaseNameForActionType(actionType);
    }

    // 如果基础名称未被使用，直接返回
    if (!existingVariables.has(baseName)) {
      return baseName;
    }

    // 否则添加数字后缀
    let counter = 2;
    let candidateName = `${baseName}${counter}`;
    while (existingVariables.has(candidateName)) {
      counter++;
      candidateName = `${baseName}${counter}`;
    }

    return candidateName;
  }

  /**
   * 从现有动作列表中提取所有已定义的变量名
   * @param actions 动作列表
   * @returns 已定义的变量名集合
   */
  static extractExistingVariableNames(
    actions: Array<{ config: string }>
  ): Set<string> {
    const variableNames = new Set<string>();

    // 添加系统变量
    ['date', 'time', 'timestamp', 'clipboard', 'network_type', 'battery_level']
      .forEach(v => variableNames.add(v));

    // 添加动作输出的变量
    actions.forEach(action => {
      try {
        const config = JSON.parse(action.config);
        if (config.saveToVariable) {
          variableNames.add(config.saveToVariable);
        }
        if (config.saveResponseTo) {
          variableNames.add(config.saveResponseTo);
        }
      } catch (error) {
        // 忽略解析错误
      }
    });

    return variableNames;
  }

  /**
   * 推荐基于上下文的变量名
   * 例如：如果前一个动作是"读取剪贴板"，则推荐与URL相关的名称
   */
  static recommendContextualVariableName(
    actionType: ActionType,
    operation: string,
    previousActionType?: ActionType,
    existingVariables?: Set<string>
  ): string {
    const vars = existingVariables || new Set<string>();

    // 特殊情况：文本处理 + 正则提取 URL
    if (actionType === ActionType.TEXT_PROCESS &&
        operation === 'regex_extract' &&
        previousActionType === ActionType.CLIPBOARD_READ) {
      const urlBaseName = 'extracted_url';
      if (!vars.has(urlBaseName)) {
        return urlBaseName;
      }
    }

    // 默认使用特定操作推荐
    return this.recommendSpecificVariableName(actionType, operation, vars);
  }
}
