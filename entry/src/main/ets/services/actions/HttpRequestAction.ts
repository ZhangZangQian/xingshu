import { Action, HttpRequestConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { HttpService } from '../HttpService';
import { JsonUtils } from '../../utils/JsonUtils';

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
      console.log(`[HttpRequestAction] ====== START ======`);
      console.log(`[HttpRequestAction] Original config url: ${config.url}`);
      console.log(`[HttpRequestAction] Original config body: ${config.body}`);
      console.log(`[HttpRequestAction] ======`);

      // 解析变量
      const url = await VariableParser.parse(config.url, context);
      console.log(`[HttpRequestAction] Parsed url: ${url}`);
      console.log(`[HttpRequestAction] ======`);

      let parsedBody: string | undefined = undefined;
      if (config.body) {
        console.log(`[HttpRequestAction] ====== Body Parse START ======`);
        console.log(`[HttpRequestAction] Original body: ${config.body}`);

        // 直接打印所有变量状态
        console.log(`[HttpRequestAction] --- Variable Status ---`);
        console.log(`[HttpRequestAction] Runtime variables: ${Array.from(context.variables.entries()).map(([k, v]) => `${k}=${v}`).join(', ')}`);
        console.log(`[HttpRequestAction] Global variables: ${Array.from(context.globalVariables.entries()).map(([k, v]) => `${k}=${v}`).join(', ')}`);
        console.log(`[HttpRequestAction] -------------------------`);

        parsedBody = await VariableParser.parse(config.body, context);
        console.log(`[HttpRequestAction] Parsed body: ${parsedBody}`);

        // 验证变量替换
        console.log(`[HttpRequestAction] --- Verification ---`);
        console.log(`[HttpRequestAction] Original body contains '{extracted_url}': ${config.body.includes('{extracted_url}')}`);
        console.log(`[HttpRequestAction] Parsed body contains '{extracted_url}': ${parsedBody.includes('{extracted_url}')}`);

        if (parsedBody.includes('http://')) {
          console.log(`[HttpRequestAction] Parsed body contains 'http://': YES`);
        }

        console.log(`[HttpRequestAction] ==========================`);
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

      // 处理 POST/PUT 请求的 body 类型（默认 JSON）
      const bodyType = config.bodyType || 'json';
      if (parsedBody && (config.method === 'POST' || config.method === 'PUT')) {
        if (bodyType === 'json') {
          // JSON 格式：验证并确保是有效的 JSON 字符串
          if (!headers['Content-Type']) {
            headers['Content-Type'] = 'application/json';
          }
          // 解析并重新序列化 JSON，确保特殊字符（如换行符）被正确转义
          console.log(`[HttpRequestAction] Parsing JSON body, length: ${parsedBody.length}`);
          console.log(`[HttpRequestAction] Body (first 500 chars): ${parsedBody.substring(0, 500)}`);
          console.log(`[HttpRequestAction] Body (last 500 chars): ${parsedBody.substring(Math.max(0, parsedBody.length - 500))}`);
          try {
            const jsonObj = JSON.parse(parsedBody);
            parsedBody = JSON.stringify(jsonObj);
            console.log(`[HttpRequestAction] JSON parsed and re-serialized successfully`);
          } catch (error) {
            console.error(`[HttpRequestAction] JSON parse error: ${JSON.stringify(error)}`);
            throw new Error(`无效的 JSON body: ${error.message}`);
          }
        } else if (bodyType === 'form') {
          // 表单格式
          if (!headers['Content-Type']) {
            headers['Content-Type'] = 'application/x-www-form-urlencoded';
          }
        }
      }

      console.log(`[HttpRequestAction] Final URL: ${url}`);
      console.log(`[HttpRequestAction] Final Body: ${parsedBody}`);
      console.log(`[HttpRequestAction] Final Headers: ${JSON.stringify(headers)}`);
      console.log(`[HttpRequestAction] Body Type: ${bodyType}`);
      console.log(`[HttpRequestAction] ====== END ======`);

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
        context.setVariable(config.saveResponseTo, response.body);
        Logger.info('HttpRequestAction', `Response saved to variable: ${config.saveResponseTo}`);
      }

      // 新增：JSON 响应自动解析
      let parsedResponse: any = null;
      const shouldParseResponse = config.parseResponse !== false;

      if (shouldParseResponse && response.body) {
        parsedResponse = JsonUtils.parseJSONSafely(response.body);
      }

      // 新增：保存解析后的 JSON 对象
      if (config.saveParsedResponse && parsedResponse !== null) {
        context.setVariable(config.saveParsedResponse, parsedResponse);
        Logger.info('HttpRequestAction', `Parsed response saved to variable: ${config.saveParsedResponse}`);
      }

      // 新增：保存状态码
      if (config.saveStatusCodeTo) {
        context.setVariable(config.saveStatusCodeTo, response.statusCode);
        Logger.info('HttpRequestAction', `Status code saved to variable: ${config.saveStatusCodeTo}`);
      }

      Logger.info('HttpRequestAction', 'HTTP request completed successfully');

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
          parsedResponse: parsedResponse,
          statusCode: response.statusCode,
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
