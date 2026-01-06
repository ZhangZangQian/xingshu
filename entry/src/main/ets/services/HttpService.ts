import http from '@ohos.net.http';
import Logger from '../utils/Logger';

/**
 * HTTP 服务
 * 封装鸿蒙 HTTP API
 */
export class HttpService {
  private static instance: HttpService;
  private static readonly DEFAULT_TIMEOUT = 30000;  // 默认超时 30 秒

  private constructor() {
  }

  public static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }

  /**
   * 发送 HTTP 请求
   *
   * @param method 请求方法
   * @param url 请求 URL
   * @param headers 请求头
   * @param body 请求体
   * @param timeout 超时时间（毫秒）
   * @returns 响应数据
   */
  async request(
    method: 'GET' | 'POST' | 'PUT' | 'DELETE',
    url: string,
    headers?: Record<string, string>,
    body?: string,
    timeout?: number
  ): Promise<HttpResponse> {
    const startTime = Date.now();
    Logger.info('HttpService', `Sending ${method} request to: ${url}`);

    const httpRequest = http.createHttp();

    try {
      const requestOptions: http.HttpRequestOptions = {
        method: this.convertMethod(method),
        header: headers || {},
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeout || HttpService.DEFAULT_TIMEOUT,
        readTimeout: timeout || HttpService.DEFAULT_TIMEOUT
      };

      const response = await httpRequest.request(url, requestOptions);
      const duration = Date.now() - startTime;

      Logger.performance('HttpService', `${method} ${url}`, duration);

      // 解析响应
      const result: HttpResponse = {
        statusCode: response.responseCode,
        headers: response.header as Record<string, string>,
        body: typeof response.result === 'string' ? response.result : JSON.stringify(response.result),
        success: response.responseCode >= 200 && response.responseCode < 300
      };

      // 尝试解析 JSON
      if (result.body && typeof result.body === 'string') {
        try {
          result.data = JSON.parse(result.body);
        } catch (error) {
          // 不是 JSON 格式，保持原样
        }
      }

      if (!result.success) {
        Logger.warn('HttpService', `HTTP request failed with status: ${result.statusCode}`);
      }

      return result;
    } catch (error) {
      Logger.error('HttpService', `HTTP request failed: ${method} ${url}`, error as Error);
      throw new Error(`HTTP 请求失败: ${error.message}`);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * GET 请求
   */
  async get(url: string, headers?: Record<string, string>, timeout?: number): Promise<HttpResponse> {
    return this.request('GET', url, headers, undefined, timeout);
  }

  /**
   * POST 请求
   */
  async post(url: string, body?: string, headers?: Record<string, string>, timeout?: number): Promise<HttpResponse> {
    return this.request('POST', url, headers, body, timeout);
  }

  /**
   * PUT 请求
   */
  async put(url: string, body?: string, headers?: Record<string, string>, timeout?: number): Promise<HttpResponse> {
    return this.request('PUT', url, headers, body, timeout);
  }

  /**
   * DELETE 请求
   */
  async delete(url: string, headers?: Record<string, string>, timeout?: number): Promise<HttpResponse> {
    return this.request('DELETE', url, headers, undefined, timeout);
  }

  /**
   * 转换请求方法为鸿蒙 API 格式
   */
  private convertMethod(method: string): http.RequestMethod {
    switch (method.toUpperCase()) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }
}

/**
 * HTTP 响应数据结构
 */
export interface HttpResponse {
  statusCode: number;
  headers: Record<string, string>;
  body: string;
  data?: Object;  // 解析后的 JSON 数据（如果是 JSON 响应）
  success: boolean;
}
