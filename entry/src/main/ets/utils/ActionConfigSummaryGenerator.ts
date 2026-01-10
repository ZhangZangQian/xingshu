import { Action, ActionType } from '../models/Macro';

/**
 * 动作配置摘要生成器
 * 用于生成动作的简短描述，在动作列表中显示
 */
export class ActionConfigSummaryGenerator {
  /**
   * 生成动作配置摘要
   * @param action 动作
   * @returns 配置摘要字符串
   */
  static generate(action: Action): string {
    try {
      const config = JSON.parse(action.config);

      switch (action.type) {
        case ActionType.CLIPBOARD_READ:
          return this.generateClipboardReadSummary(config);

        case ActionType.CLIPBOARD_WRITE:
          return this.generateClipboardWriteSummary(config);

        case ActionType.TEXT_PROCESS:
          return this.generateTextProcessSummary(config);

        case ActionType.HTTP_REQUEST:
          return this.generateHttpRequestSummary(config);

        case ActionType.USER_DIALOG:
          return this.generateUserDialogSummary(config);

        case ActionType.OPEN_URL:
          return this.generateOpenUrlSummary(config);

        case ActionType.NOTIFICATION:
          return this.generateNotificationSummary(config);

        case ActionType.LAUNCH_APP:
          return this.generateLaunchAppSummary(config);

        case ActionType.SET_VARIABLE:
          return this.generateSetVariableSummary(config);

        case ActionType.IF_ELSE:
          return this.generateIfElseSummary(config);

        case ActionType.JSON_PROCESS:
          return this.generateJsonProcessSummary(config);

        default:
          return '未知动作类型';
      }
    } catch (error) {
      return '配置格式错误';
    }
  }

  /**
   * 生成读取剪贴板摘要
   */
  private static generateClipboardReadSummary(config: any): string {
    if (config.saveToVariable) {
      return `读取剪贴板 → {${config.saveToVariable}}`;
    }
    return '读取剪贴板';
  }

  /**
   * 生成写入剪贴板摘要
   */
  private static generateClipboardWriteSummary(config: any): string {
    const content = config.content || '';
    const preview = this.truncateText(content, 30);
    return `写入内容: ${preview}`;
  }

  /**
   * 生成文本处理摘要
   */
  private static generateTextProcessSummary(config: any): string {
    const operationNames: Record<string, string> = {
      'regex_extract': '正则提取',
      'replace': '文本替换',
      'split': '文本分割',
      'uppercase': '转大写',
      'lowercase': '转小写',
      'url_encode': 'URL 编码',
      'url_decode': 'URL 解码'
    };

    const operation = operationNames[config.operation] || config.operation;
    const input = config.input ? this.truncateText(config.input, 20) : '(未设置)';

    let details = '';
    switch (config.operation) {
      case 'regex_extract':
        const pattern = config.pattern ? this.truncateText(config.pattern, 20) : '(未设置)';
        details = `\n正则: ${pattern}`;
        break;
      case 'replace':
        details = `\n搜索: ${this.truncateText(config.searchValue || '', 15)}`;
        break;
      case 'split':
        details = `\n分隔符: ${config.separator || '(未设置)'}`;
        break;
    }

    return `${operation}\n输入: ${input}${details}`;
  }

  /**
   * 生成 HTTP 请求摘要
   */
  private static generateHttpRequestSummary(config: any): string {
    const method = config.method || 'GET';
    const url = config.url ? this.truncateText(config.url, 40) : '(未设置)';
    return `${method} ${url}`;
  }

  /**
   * 生成用户对话框摘要
   */
  private static generateUserDialogSummary(config: any): string {
    const typeNames: Record<string, string> = {
      'confirm': '确认对话框',
      'single_select': '单选对话框',
      'multi_select': '多选对话框',
      'text_input': '文本输入'
    };

    const type = typeNames[config.type] || config.type;
    const title = config.title ? this.truncateText(config.title, 20) : '(未设置)';

    let details = '';
    if (config.type === 'single_select' || config.type === 'multi_select') {
      const optionCount = config.options ? config.options.length : 0;
      details = `\n选项数: ${optionCount}`;
    }

    return `${type}: ${title}${details}`;
  }

  /**
   * 生成打开 URL 摘要
   */
  private static generateOpenUrlSummary(config: any): string {
    const url = config.url ? this.truncateText(config.url, 40) : '(未设置)';
    const openWith = config.openWith === 'app' ? '应用打开' : '浏览器打开';
    return `${openWith}: ${url}`;
  }

  /**
   * 生成发送通知摘要
   */
  private static generateNotificationSummary(config: any): string {
    const title = config.title ? this.truncateText(config.title, 20) : '(未设置)';
    const content = config.content ? this.truncateText(config.content, 30) : '';
    return `标题: ${title}\n${content}`;
  }

  /**
   * 生成启动应用摘要
   */
  private static generateLaunchAppSummary(config: any): string {
    const bundleName = config.bundleName ? this.truncateText(config.bundleName, 30) : '(未设置)';
    return `启动应用: ${bundleName}`;
  }

  /**
   * 生成设置变量摘要
   */
  private static generateSetVariableSummary(config: any): string {
    const variableName = config.variableName || '(未设置)';
    const value = config.value !== undefined ? this.truncateText(config.value, 40) : '(未设置)';
    const scope = config.scope === 'global' ? '[全局]' : '[运行时]';
    return `${variableName} = ${value} ${scope}`;
  }

  /**
   * 生成条件分支摘要
   */
  private static generateIfElseSummary(config: any): string {
    const branches = config.branches || [];
    const branchCount = branches.length;
    if (branchCount === 0) {
      return '条件分支 (无分支)';
    }
    return `条件分支 (${branchCount} 个分支)`;
  }

  /**
   * 生成 JSON 处理摘要
   */
  private static generateJsonProcessSummary(config: any): string {
    const operationNames: Record<string, string> = {
      'json_query': 'JSON 查询',
      'json_filter': 'JSON 过滤',
      'json_map': 'JSON 映射',
      'json_merge': 'JSON 合并',
      'array_length': '数组长度',
      'array_get': '数组获取',
      'array_set': '数组设置',
      'json_encode': 'JSON 编码',
      'json_decode': 'JSON 解码'
    };

    const operation = operationNames[config.operation] || config.operation;
    const input = config.input ? this.truncateText(config.input, 30) : '(未设置)';

    let details = '';
    if (config.operation === 'json_query') {
      const path = config.queryPath ? this.truncateText(config.queryPath, 25) : '(未设置)';
      details = `\n路径: ${path}`;
    }

    return `${operation}\n输入: ${input}${details}`;
  }

  /**
   * 截断文本
   */
  private static truncateText(text: string, maxLength: number): string {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength) + '...';
  }

  /**
   * 提取输入变量（用于显示）
   */
  static extractInputVariables(action: Action): string[] {
    try {
      const config = JSON.parse(action.config);
      const variables: Set<string> = new Set();
      const regex = /\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g;

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
    } catch (error) {
      return [];
    }
  }

  /**
   * 提取输出变量（用于显示）
   */
  static extractOutputVariable(action: Action): string | null {
    try {
      const config = JSON.parse(action.config);

      switch (action.type) {
        case ActionType.CLIPBOARD_READ:
          return config.saveToVariable || null;

        case ActionType.TEXT_PROCESS:
          return config.saveToVariable || null;

        case ActionType.HTTP_REQUEST:
          return config.saveResponseTo || null;

        case ActionType.USER_DIALOG:
          return config.saveToVariable || null;

        case ActionType.SET_VARIABLE:
          return config.variableName || null;

        case ActionType.JSON_PROCESS:
          return config.saveToVariable || null;

        default:
          return null;
      }
    } catch (error) {
      return null;
    }
  }
}
