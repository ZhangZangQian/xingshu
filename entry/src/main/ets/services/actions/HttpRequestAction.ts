import { Action, HttpRequestConfig } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { HttpService } from '../HttpService';

/**
 * HTTP 请求动作执行器
 */
export class HttpRequestAction implements IActionExecutor {
  private httpService: HttpService;

  constructor() {
    this.httpService = HttpService.getInstance();
  }

  async execute(action: Action, context: ExecutionContext): Promise<void> {
    const config = JSON.parse(action.config) as HttpRequestConfig;
    Logger.info('HttpRequestAction', `Sending HTTP ${config.method} request to ${config.url}`);

    try {
      // 解析变量
      const url = await VariableParser.parse(config.url, context);
      const body = config.body ? await VariableParser.parse(config.body, context) : undefined;

      // 解析 headers 中的变量
      const headers: Record<string, string> = {};
      if (config.headers) {
        for (const key in config.headers) {
          const value = config.headers[key];
          if (value) {
            headers[key] = await VariableParser.parse(value, context);
          }
        }
      }

      // 发送请求
      const response = await this.httpService.request(
        config.method,
        url,
        headers,
        body,
        config.timeout || 30000
      );

      // 保存响应到变量
      if (config.saveResponseTo) {
        context.setVariable(config.saveResponseTo, response);
        Logger.info('HttpRequestAction', `Response saved to variable: ${config.saveResponseTo}`);
      }

      Logger.info('HttpRequestAction', 'HTTP request completed successfully');

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('HttpRequestAction', `HTTP request failed: ${errorMessage}`);
      throw new Error(`HTTP 请求失败: ${errorMessage}`);
    }
  }
}
