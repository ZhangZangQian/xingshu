import { Action, HttpRequestConfig, ActionExecutionResult } from '../../models/Macro';
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

  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as HttpRequestConfig;
    Logger.info('HttpRequestAction', `Sending HTTP ${config.method} request to ${config.url}`);

    const startTime = Date.now();

    try {
      console.log(`[HttpRequestAction] Original config url: ${config.url}`);
      console.log(`[HttpRequestAction] Original config body: ${config.body}`);

      // 打印相关变量
      const extractedUrl = await context.getVariable('extracted_url');
      console.log(`[HttpRequestAction] extracted_url variable: ${extractedUrl}`);

      // 解析变量
      const url = await VariableParser.parse(config.url, context);
      console.log(`[HttpRequestAction] Parsed url: ${url}`);

      let parsedBody: string | undefined = undefined;
      if (config.body) {
        console.log(`[HttpRequestAction] Before body parse, body: ${config.body}`);
        parsedBody = await VariableParser.parse(config.body, context);
        console.log(`[HttpRequestAction] Parsed body: ${parsedBody}`);

        // 同步日志（确保立即输出）
        console.log(`[HttpRequestAction SYNC] ====== Body Parse Summary ======`);
        console.log(`[HttpRequestAction SYNC] Original body contains extracted_url: ${config.body.includes('{extracted_url}')}`);
        console.log(`[HttpRequestAction SYNC] Parsed body contains extracted_url: ${parsedBody.includes('{extracted_url}')}`);
        console.log(`[HttpRequestAction SYNC] Parsed body contains actual URL: ${parsedBody.includes('http://xhslink.com')}`);
        console.log(`[HttpRequestAction SYNC] ==================================`);
      }

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
        parsedBody,
        config.timeout || 30000
      );

      // 保存响应到变量
      if (config.saveResponseTo) {
        context.setVariable(config.saveResponseTo, response);
        Logger.info('HttpRequestAction', `Response saved to variable: ${config.saveResponseTo}`);
      }

      Logger.info('HttpRequestAction', 'HTTP request completed successfully');

      // 返回执行结果（使用解析后的值作为 inputData）
      return {
        status: 'success',
        inputData: {
          method: config.method,
          url: url,
          headers: headers,
          body: parsedBody,
          timeout: config.timeout
        },
        outputData: {
          url: url,
          headers: headers,
          body: parsedBody,
          response: response,
          savedToVariable: config.saveResponseTo
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('HttpRequestAction', `HTTP request failed: ${errorMessage}`);
      throw new Error(`HTTP 请求失败: ${errorMessage}`);
    }
  }
}
