# HarmonyOS NEXT 宏应用 - 变量系统 JSON 支持改进方案

## 一、当前变量系统分析

### 1.1 现有架构

```
┌─────────────────────────────────────────────────────────────┐
│                    当前变量系统架构                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  变量类型 (Variable.ts)                                      │
│  ├─ STRING, NUMBER, BOOLEAN                                 │
│  └─ VariableValue = string | number | boolean               │
│                                                             │
│  变量解析 (VariableParser.ts)                               │
│  ├─ {variable_name} 格式解析                                │
│  ├─ 嵌套属性访问 {action_1.result.code}                      │
│  └─ 解析后统一转换为字符串 String(value)                     │
│                                                             │
│  变量存储 (DatabaseService.ts)                              │
│  ├─ variable 表: value TEXT 字段                             │
│  ├─ JSON 序列化存储 JSON.stringify(value)                    │
│  └─ 支持全局变量 / 宏变量                                    │
│                                                             │
│  执行上下文 (ExecutionContext.ts)                           │
│  ├─ runtimeVariables: Map<string, Object>                  │
│  ├─ globalVariables: Map<string, Object>                   │
│  └─ 系统变量: date, time, timestamp, clipboard 等          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 当前问题

| 问题点 | 描述 | 影响 |
|--------|------|------|
| **仅支持简单类型** | 只有 string/number/boolean | 无法存储 API 响应等复杂数据 |
| **解析强制转字符串** | `String(value)` 转换 | 对象变为 `[object Object]` |
| **无法保留结构** | JSON 对象被扁平化 | 无法访问深层属性 |
| **HTTP 响应限制** | 只能存储字符串响应 | API JSON 数据无法利用 |
| **缺少 JSON 操作** | 无 JSONPath、数组操作等 | 数据处理能力受限 |

### 1.3 实际场景限制

**场景：调用飞书 API 上传数据**

```typescript
// 当前实现（有问题）
HttpRequestAction.execute() {
  const response = await httpService.request(...); // JSON 响应
  context.setVariable('api_response', response);   // 存储为 "[object Object]"
}

// 后续无法使用
TextProcessAction.execute() {
  const value = await VariableParser.parse('{api_response}', context);
  // value = "[object Object]" ❌ 无法提取 JSON 中的字段
}
```

---

## 二、JSON 支持改进方案

### 2.1 整体架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                   JSON 支持变量系统架构                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐         ┌───────────────────────────┐    │
│  │   变量类型扩展    │         │    变量解析器增强          │    │
│  ├─────────────────┤         ├───────────────────────────┤    │
│  │ • OBJECT (新增)  │────────▶│ • 保留类型解析             │    │
│  │ • ARRAY (新增)   │         │ • JSONPath 语法支持       │    │
│  │ • STRING         │         │ • 类型推断机制             │    │
│  │ • NUMBER         │         │ • 智能转换（按需）         │    │
│  │ • BOOLEAN        │         └───────────────────────────┘    │
│  └─────────────────┘                    │                        │
│           │                              │                        │
│           │                              │                        │
│           ▼                              ▼                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │               执行上下文增强 (ExecutionContext)            │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  • variables: Map<string, VariableValue>                  │  │
│  │  • 支持存储任意 JSON 类型                                  │  │
│  │  • 类型感知的 getVariable()                                │  │
│  └────────────────────────────────────────────────────────────┘  │
│                           │                                     │
│                           ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              JSON 操作工具箱 (JsonUtils)                     │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  • getValueByPath(obj, path) - JSONPath 查询               │  │
│  │  • setValueByPath(obj, path, value) - JSONPath 设置        │  │
│  │  • filterArray(array, filterFn) - 数组过滤                 │  │
│  │  • mapArray(array, mapFn) - 数组映射                       │  │
│  │  • findInArray(array, condition) - 数组查找                 │  │
│  │  • mergeJSON(target, source) - JSON 合并                   │  │
│  │  • parseJSONSafely(str) - 安全解析                         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                           │                                     │
│                           ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │           动作类型扩展 (Action Types)                      │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │  ┌──────────────────┐  ┌──────────────────────────────┐    │  │
│  │  │ JSON_PROCESS     │  │ HTTP_REQUEST (增强)           │    │
│  │  ├──────────────────┤  ├──────────────────────────────┤    │  │
│  │  │ • json_query     │  │ • parseResponse: boolean      │    │  │
│  │  │ • json_filter    │  │ • saveParsedResponse: string  │    │  │
│  │  │ • json_map       │  │ • 自动 JSON 解析              │    │  │
│  │  │ • json_merge     │  └──────────────────────────────┘    │  │
│  │  │ • array_length   │                                       │  │
│  │  │ • array_get      │  ┌──────────────────────────────┐    │  │
│  │  │ • array_set      │  │ TEXT_PROCESS (增强)           │    │  │
│  │  │ json_encode      │  ├──────────────────────────────┤    │  │
│  │  │ json_decode      │  │ • 支持从 JSON 提取字段        │    │  │
│  │  └──────────────────┘  │ • 智能类型转换                │    │  │
│  │                       └──────────────────────────────┘    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 核心改进点

#### 改进点 1：变量类型扩展

**文件**：`entry/src/main/ets/models/Variable.ts`

```typescript
// 新增类型
export enum VariableType {
  STRING = 'string',
  NUMBER = 'number',
  BOOLEAN = 'boolean',
  OBJECT = 'object',   // ✨ 新增：JSON 对象
  ARRAY = 'array'      // ✨ 新增：JSON 数组
}

// 扩展类型定义
export type VariableValue =
  | string
  | number
  | boolean
  | Record<string, any>  // ✨ 新增：对象类型
  | any[];                // ✨ 新增：数组类型

// JSON 类型检查
export function isJSONObject(value: unknown): value is Record<string, any> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function isJSONArray(value: unknown): value is any[] {
  return Array.isArray(value);
}
```

**数据库迁移**：

```sql
-- 更新变量表约束
ALTER TABLE variable MODIFY COLUMN type TEXT CHECK(
  type IN ('string', 'number', 'boolean', 'object', 'array')
);
```

---

#### 改进点 2：变量解析器增强

**文件**：`entry/src/main/ets/utils/VariableParser.ts`

**新增功能**：

1. **JSONPath 语法支持**

```
支持路径格式：
• {variable}                    - 获取变量
• {variable.field}               - 获取对象字段
• {variable.items[0]}           - 数组索引
• {variable.users[2].name}      - 混合路径
• {variable.items[*]}           - 数组所有元素（映射）
• {variable.items[?age>18]}     - 数组过滤
```

2. **保留类型解析**

```typescript
// 核心改动：解析时保留原始类型
private static async resolveVariable(
  path: string,
  context: ExecutionContextImpl
): Promise<any> {
  const parts = path.split('.');
  const rootVariable = parts[0];

  // 1. 获取根变量
  let value: any = await context.getVariable(rootVariable);

  // 2. 深度解析 JSONPath
  if (value !== undefined && parts.length > 1) {
    value = JsonUtils.getValueByPath(value, parts.slice(1));
  }

  // ✨ 不再强制转字符串，保留原始类型
  return value;
}
```

3. **智能类型转换**（按需）

```typescript
/**
 * 解析字符串中的变量，并智能转换为目标类型
 *
 * @param input 输入字符串（如 "Name: {user.name}"）
 * @param context 执行上下文
 * @param targetFormat 目标格式（'string' | 'json' | 'preserve'）
 */
static async parse(
  input: string,
  context: ExecutionContextImpl,
  targetFormat: 'string' | 'json' | 'preserve' = 'string'
): Promise<string | any> {
  // ... 解析逻辑

  // 根据目标格式处理结果
  switch (targetFormat) {
    case 'preserve':
      return result;  // 保留原始类型
    case 'json':
      return JSON.parse(result);
    case 'string':
    default:
      // 如果结果是对象，尝试 JSON 序列化
      return typeof result === 'object' ? JSON.stringify(result) : String(result);
  }
}
```

---

#### 改进点 3：JSON 工具箱实现

**新建文件**：`entry/src/main/ets/utils/JsonUtils.ts`

```typescript
/**
 * JSON 工具类
 * 提供 JSONPath 查询、数组操作等高级功能
 */
export class JsonUtils {
  /**
   * 通过路径获取值（支持 JSONPath 语法）
   *
   * 示例：
   * getValueByPath(obj, ['users', '0', 'name']) -> "张三"
   * getValueByPath(obj, ['items', '*']) -> [所有元素]
   * getValueByPath(obj, ['items', '?age>18']) -> [过滤后的元素]
   */
  static getValueByPath(obj: any, path: string[]): any {
    let current = obj;

    for (const segment of path) {
      if (!current) return undefined;

      // 数组索引 [0]
      if (segment.match(/^\[(\d+)\]$/)) {
        const index = parseInt(segment.match(/\d+/)![0]);
        current = current[index];
      }
      // 通配符 [*] - 返回所有元素
      else if (segment === '*') {
        if (Array.isArray(current)) {
          return current;
        }
        return undefined;
      }
      // 过滤器 [?condition]
      else if (segment.match(/^\[\?.+\]$/)) {
        if (!Array.isArray(current)) return undefined;
        const condition = segment.replace('[?', '').replace(']', '');
        current = current.filter((item: any) => this.evaluateCondition(item, condition));
      }
      // 普通字段访问
      else {
        current = current[segment];
      }
    }

    return current;
  }

  /**
   * 通过路径设置值
   */
  static setValueByPath(obj: any, path: string[], value: any): void {
    let current = obj;

    for (let i = 0; i < path.length - 1; i++) {
      const segment = path[i];
      if (!(segment in current)) {
        // 自动创建路径
        current[segment] = {};
      }
      current = current[segment];
    }

    current[path[path.length - 1]] = value;
  }

  /**
   * 数组过滤
   */
  static filterArray(array: any[], filterFn: (item: any) => boolean): any[] {
    return array.filter(filterFn);
  }

  /**
   * 数组映射
   */
  static mapArray(array: any[], mapFn: (item: any) => any): any[] {
    return array.map(mapFn);
  }

  /**
   * 在数组中查找
   */
  static findInArray(array: any[], condition: (item: any) => boolean): any | undefined {
    return array.find(condition);
  }

  /**
   * JSON 合并
   */
  static mergeJSON(target: any, source: any): any {
    return {
      ...target,
      ...source
    };
  }

  /**
   * 安全解析 JSON
   */
  static parseJSONSafely(jsonStr: string, defaultValue: any = null): any {
    try {
      return JSON.parse(jsonStr);
    } catch (error) {
      Logger.warn('JsonUtils', `Failed to parse JSON: ${jsonStr}`);
      return defaultValue;
    }
  }

  /**
   * 评估条件表达式（用于数组过滤）
   * 示例：age>18, name=='John', status==true
   */
  private static evaluateCondition(item: any, condition: string): boolean {
    // 简单实现，支持基本比较
    const operators = ['>', '<', '>=', '<=', '==', '!=', '===', '!=='];
    let operator = null;
    let opIndex = -1;

    // 查找运算符
    for (const op of operators) {
      opIndex = condition.indexOf(op);
      if (opIndex > 0) {
        operator = op;
        break;
      }
    }

    if (!operator || opIndex === -1) {
      // 布尔值直接检查
      return item[condition] === true;
    }

    const field = condition.substring(0, opIndex).trim();
    const valueStr = condition.substring(opIndex + operator.length).trim();

    // 解析值
    let value: any = valueStr;
    if (valueStr.startsWith("'") && valueStr.endsWith("'")) {
      value = valueStr.slice(1, -1);
    } else if (valueStr === 'true') {
      value = true;
    } else if (valueStr === 'false') {
      value = false;
    } else if (!isNaN(Number(valueStr))) {
      value = Number(valueStr);
    }

    // 比较
    switch (operator) {
      case '==':
        return item[field] == value;
      case '===':
        return item[field] === value;
      case '!=':
        return item[field] != value;
      case '!==':
        return item[field] !== value;
      case '>':
        return item[field] > value;
      case '<':
        return item[field] < value;
      case '>=':
        return item[field] >= value;
      case '<=':
        return item[field] <= value;
      default:
        return false;
    }
  }
}
```

---

#### 改进点 4：新增 JSON 处理动作

**新建文件**：`entry/src/main/ets/services/actions/JsonProcessAction.ts`

```typescript
import { Action, JsonProcessConfig, ActionExecutionResult } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';
import { VariableParser } from '../../utils/VariableParser';
import { JsonUtils } from '../../utils/JsonUtils';

/**
 * JSON 处理动作执行器
 * 提供 JSONPath 查询、数组操作等高级功能
 */
export class JsonProcessAction implements IActionExecutor {
  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as JsonProcessConfig;
    Logger.info('JsonProcessAction', `JSON processing operation: ${config.operation}`);

    const startTime = Date.now();

    try {
      // 解析输入 JSON（支持变量）
      const inputStr = await VariableParser.parse(config.input, context);
      const inputObj = JsonUtils.parseJSONSafely(inputStr);

      if (inputObj === null) {
        throw new Error(`Invalid JSON input: ${inputStr}`);
      }

      let result: any;

      // 根据操作类型处理
      switch (config.operation) {
        case 'json_query':
          result = this.jsonQuery(inputObj, config.queryPath || '', context);
          break;

        case 'json_filter':
          result = this.jsonFilter(inputObj, config.filterCondition || '', context);
          break;

        case 'json_map':
          result = this.jsonMap(inputObj, config.mapField || '', context);
          break;

        case 'json_merge':
          result = this.jsonMerge(inputObj, config.mergeSource || '', context);
          break;

        case 'array_length':
          result = this.arrayLength(inputObj);
          break;

        case 'array_get':
          result = this.arrayGet(inputObj, config.arrayIndex || 0);
          break;

        case 'array_set':
          result = this.arraySet(inputObj, config.arrayIndex || 0, config.newValue || '', context);
          break;

        case 'json_encode':
          result = JSON.stringify(inputObj);
          break;

        case 'json_decode':
          // 已在上方解析，直接返回
          result = inputObj;
          break;

        default:
          throw new Error(`Unknown JSON processing operation: ${config.operation}`);
      }

      // 保存结果到变量
      if (config.saveToVariable) {
        context.setVariable(config.saveToVariable, result);
        Logger.info('JsonProcessAction', `Result saved to variable: ${config.saveToVariable}`);
      }

      Logger.info('JsonProcessAction', 'JSON processing completed successfully');

      return {
        status: 'success',
        inputData: {
          operation: config.operation,
          input: inputObj
        },
        outputData: {
          operation: config.operation,
          result: result,
          savedToVariable: config.saveToVariable
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      Logger.error('JsonProcessAction', `JSON processing failed: ${errorMessage}`);
      throw new Error(`JSON 处理失败: ${errorMessage}`);
    }
  }

  /**
   * JSONPath 查询
   * 示例：queryPath = "users.0.name"
   */
  private async jsonQuery(json: any, queryPath: string, context: ExecutionContext): Promise<any> {
    const path = queryPath.split('.');
    return JsonUtils.getValueByPath(json, path);
  }

  /**
   * JSON 数组过滤
   * 示例：filterCondition = "age>18"
   */
  private async jsonFilter(json: any[], filterCondition: string, context: ExecutionContext): Promise<any[]> {
    if (!Array.isArray(json)) {
      throw new Error('json_filter requires array input');
    }

    return json.filter(item => {
      return JsonUtils['evaluateCondition'](item, filterCondition);
    });
  }

  /**
   * JSON 数组映射（提取字段）
   * 示例：mapField = "name" -> [{name: "张三"}, {name: "李四"}] -> ["张三", "李四"]
   */
  private async jsonMap(json: any[], mapField: string, context: ExecutionContext): Promise<any[]> {
    if (!Array.isArray(json)) {
      throw new Error('json_map requires array input');
    }

    return json.map(item => item[mapField]);
  }

  /**
   * JSON 合并
   */
  private async jsonMerge(target: any, sourceStr: string, context: ExecutionContext): Promise<any> {
    const source = JsonUtils.parseJSONSafely(sourceStr);
    return JsonUtils.mergeJSON(target, source);
  }

  /**
   * 获取数组长度
   */
  private arrayLength(array: any[]): number {
    if (!Array.isArray(array)) {
      throw new Error('array_length requires array input');
    }
    return array.length;
  }

  /**
   * 获取数组元素
   */
  private arrayGet(array: any[], index: number): any {
    if (!Array.isArray(array)) {
      throw new Error('array_get requires array input');
    }
    return array[index];
  }

  /**
   * 设置数组元素
   */
  private async arraySet(array: any[], index: number, newValueStr: string, context: ExecutionContext): Promise<any[]> {
    const newValue = await VariableParser.parse(newValueStr, context);
    array[index] = newValue;
    return array;
  }
}
```

**配置接口**（在 `models/Macro.ts` 中添加）：

```typescript
/**
 * JSON 处理动作配置
 */
export interface JsonProcessConfig {
  operation: 'json_query' | 'json_filter' | 'json_map' | 'json_merge' |
              'array_length' | 'array_get' | 'array_set' | 'json_encode' | 'json_decode';

  // 所有操作通用
  input: string;                   // 输入 JSON 字符串（支持变量）
  saveToVariable?: string;         // 保存结果到变量

  // json_query
  queryPath?: string;              // JSONPath 路径（如 "users.0.name"）

  // json_filter
  filterCondition?: string;        // 过滤条件（如 "age>18"）

  // json_map
  mapField?: string;               // 提取字段名（如 "name"）

  // json_merge
  mergeSource?: string;            // 要合并的 JSON 字符串

  // array_get / array_set
  arrayIndex?: number;             // 数组索引

  // array_set
  newValue?: string;               // 新值（支持变量）
}
```

---

#### 改进点 5：HTTP 请求动作增强

**文件**：`entry/src/main/ets/services/actions/HttpRequestAction.ts`

**增强点**：

```typescript
/**
 * HTTP 请求动作配置（增强版）
 */
export interface HttpRequestConfig {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  url: string;
  headers?: HttpHeaders;
  body?: string;
  timeout?: number;

  // ✨ 新增：JSON 响应解析选项
  parseResponse?: boolean;          // 是否自动解析 JSON 响应（默认 true）
  saveResponseTo?: string;          // 保存原始响应到变量
  saveParsedResponse?: string;       // 保存解析后的 JSON 对象到变量
  saveStatusCodeTo?: string;         // 保存状态码到变量
}

/**
 * HTTP 请求动作执行器（增强版）
 */
export class HttpRequestAction implements IActionExecutor {
  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as HttpRequestConfig;

    const startTime = Date.now();

    try {
      // ... 解析 URL、headers、body（现有逻辑）

      // 发送请求
      const response = await this.httpService.request(
        config.method,
        url,
        headers,
        parsedBody,
        config.timeout || 30000
      );

      // ✨ 新增：JSON 响应自动解析
      let parsedResponse: any = null;
      const shouldParseResponse = config.parseResponse !== false;

      if (shouldParseResponse && response.body) {
        parsedResponse = JsonUtils.parseJSONSafely(response.body);
      }

      // 保存原始响应
      if (config.saveResponseTo) {
        context.setVariable(config.saveResponseTo, response.body);
        Logger.info('HttpRequestAction', `Response saved to variable: ${config.saveResponseTo}`);
      }

      // ✨ 新增：保存解析后的 JSON 对象
      if (config.saveParsedResponse && parsedResponse !== null) {
        context.setVariable(config.saveParsedResponse, parsedResponse);
        Logger.info('HttpRequestAction', `Parsed response saved to variable: ${config.saveParsedResponse}`);
      }

      // ✨ 新增：保存状态码
      if (config.saveStatusCodeTo) {
        context.setVariable(config.saveStatusCodeTo, response.statusCode);
        Logger.info('HttpRequestAction', `Status code saved to variable: ${config.saveStatusCodeTo}`);
      }

      return {
        status: 'success',
        inputData: { /* ... */ },
        outputData: {
          response: response,
          parsedResponse: parsedResponse,  // ✨ 新增
          statusCode: response.statusCode
        },
        duration: Date.now() - startTime
      };

    } catch (error) {
      // ... 错误处理
    }
  }
}
```

---

#### 改进点 6：SetVariableAction 增强

**文件**：`entry/src/main/ets/services/actions/SetVariableAction.ts`

**增强点**：

```typescript
/**
 * 设置变量动作配置（增强版）
 */
export interface SetVariableConfig {
  variableName: string;            // 变量名
  value: string;                   // 变量值（支持变量）
  scope: 'runtime' | 'global';     // 变量作用域

  // ✨ 新增：类型选项
  type?: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'auto';

  // ✨ 新增：是否解析 JSON
  parseAsJSON?: boolean;
}

/**
 * 设置变量动作执行器（增强版）
 */
export class SetVariableAction implements IActionExecutor {
  async execute(action: Action, context: ExecutionContext): Promise<ActionExecutionResult> {
    const config = JSON.parse(action.config) as SetVariableConfig;

    const startTime = Date.now();

    try {
      // 解析变量值（支持变量引用）
      const parsedValueStr = await VariableParser.parse(config.value, context);

      // ✨ 新增：类型处理
      let finalValue: any = parsedValueStr;

      // 如果指定解析为 JSON
      if (config.parseAsJSON) {
        finalValue = JsonUtils.parseJSONSafely(parsedValueStr);
        if (finalValue === null) {
          throw new Error(`Failed to parse JSON: ${parsedValueStr}`);
        }
      } else if (config.type && config.type !== 'string') {
        // 显式类型转换
        switch (config.type) {
          case 'number':
            finalValue = Number(parsedValueStr);
            break;
          case 'boolean':
            finalValue = parsedValueStr === 'true';
            break;
          case 'object':
          case 'array':
            finalValue = JsonUtils.parseJSONSafely(parsedValueStr);
            break;
          case 'auto':
          default:
            // 自动推断类型
            finalValue = this.inferType(parsedValueStr);
            break;
        }
      }

      // 根据作用域设置变量
      switch (config.scope) {
        case 'runtime':
          await this.setRuntimeVariable(config.variableName, finalValue, context);
          break;
        case 'global':
          await this.setGlobalVariable(config.variableName, finalValue, context, config.type || 'auto');
          break;
      }

      Logger.info('SetVariableAction', `Variable ${config.variableName} set to: ${JSON.stringify(finalValue)}`);

      return {
        status: 'success',
        inputData: { /* ... */ },
        outputData: { /* ... */ },
        duration: Date.now() - startTime
      };

    } catch (error) {
      // ... 错误处理
    }
  }

  /**
   * 自动推断类型
   */
  private inferType(value: string): any {
    // 尝试解析为 JSON
    const jsonParsed = JsonUtils.parseJSONSafely(value);
    if (jsonParsed !== null) {
      return jsonParsed;
    }

    // 数字
    if (!isNaN(Number(value))) {
      return Number(value);
    }

    // 布尔值
    if (value === 'true') return true;
    if (value === 'false') return false;

    // 默认字符串
    return value;
  }
}
```

---

## 三、使用示例

### 示例 1：从 API 响应提取数据

```json
{
  "name": "从飞书 API 获取用户数据",
  "actions": [
    {
      "type": "http_request",
      "config": {
        "method": "GET",
        "url": "https://open.feishu.cn/open-apis/user/v4/me",
        "headers": {
          "Authorization": "Bearer {access_token}"
        },
        "parseResponse": true,
        "saveParsedResponse": "api_response",
        "saveStatusCodeTo": "status_code"
      }
    },
    {
      "type": "json_process",
      "config": {
        "operation": "json_query",
        "input": "{api_response}",
        "queryPath": "data.user.name",
        "saveToVariable": "user_name"
      }
    },
    {
      "type": "notification",
      "config": {
        "title": "获取用户信息成功",
        "content": "用户名: {user_name}"
      }
    }
  ]
}
```

### 示例 2：数组过滤和映射

```json
{
  "name": "筛选成年用户",
  "actions": [
    {
      "type": "http_request",
      "config": {
        "method": "GET",
        "url": "https://api.example.com/users",
        "saveParsedResponse": "users"
      }
    },
    {
      "type": "json_process",
      "config": {
        "operation": "json_filter",
        "input": "{users}",
        "filterCondition": "age>=18",
        "saveToVariable": "adults"
      }
    },
    {
      "type": "json_process",
      "config": {
        "operation": "json_map",
        "input": "{adults}",
        "mapField": "name",
        "saveToVariable": "adult_names"
      }
    },
    {
      "type": "notification",
      "config": {
        "title": "成年用户列表",
        "content": "{adult_names}"
      }
    }
  ]
}
```

### 示例 3：构建 JSON 请求体

```json
{
  "name": "发送结构化数据",
  "actions": [
    {
      "type": "set_variable",
      "config": {
        "variableName": "request_body",
        "value": "{\"title\":\"{title}\",\"content\":\"{content}\",\"author\":\"{user_name}\"}",
        "parseAsJSON": true,
        "scope": "runtime"
      }
    },
    {
      "type": "http_request",
      "config": {
        "method": "POST",
        "url": "https://api.example.com/posts",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": "{request_body}",
        "saveResponseTo": "response"
      }
    }
  ]
}
```

---

## 四、实施计划

### 阶段 1：核心类型和工具（预计 2-3 天）

- [ ] 扩展 Variable.ts 类型定义
- [ ] 实现 JsonUtils.ts 工具类
- [ ] 更新 VariableParser.ts 解析逻辑
- [ ] 单元测试覆盖

### 阶段 2：现有动作增强（预计 2-3 天）

- [ ] 增强 HttpRequestAction（JSON 解析）
- [ ] 增强 SetVariableAction（类型支持）
- [ ] 更新 DatabaseService（数据库迁移）
- [ ] 集成测试

### 阶段 3：新动作类型（预计 1-2 天）

- [ ] 实现 JsonProcessAction
- [ ] 在 Macro.ts 添加配置接口
- [ ] 在 EntryAbility 注册动作
- [ ] 单元测试

### 阶段 4：UI 适配（预计 2-3 天）

- [ ] MacroEditor.ets 添加 JSON 配置界面
- [ ] GlobalVariables.ets 显示 JSON 类型变量
- [ ] 调试面板查看 JSON 变量内容
- [ ] UI 测试

### 阶段 5：文档和优化（预计 1-2 天）

- [ ] 更新用户文档
- [ ] 添加使用示例
- [ ] 性能优化
- [ ] 错误处理完善

**总计：8-13 个工作日**

---

## 五、风险和注意事项

### 5.1 技术风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| JSONPath 解析性能 | 复杂路径可能影响性能 | 缓存解析结果、限制最大深度 |
| 类型推断不准确 | 自动推断可能出错 | 提供显式类型选项、错误提示 |
| 内存占用 | 大 JSON 对象占用内存 | 添加大小限制、清理机制 |
| 兼容性问题 | 旧宏可能无法工作 | 数据库迁移脚本、版本兼容 |

### 5.2 实施注意事项

1. **向后兼容**：确保旧宏（使用简单变量类型）继续工作
2. **错误处理**：JSON 解析失败时提供清晰的错误信息
3. **数据验证**：存储前验证 JSON 格式
4. **性能监控**：添加日志监控 JSON 操作耗时
5. **文档完善**：提供详细的 JSONPath 语法文档

---

## 六、总结

本方案提供了全面的 JSON 支持改进，主要涵盖：

1. **类型系统扩展**：支持 object/array 类型
2. **解析器增强**：JSONPath 语法、保留类型
3. **工具箱实现**：丰富的 JSON 操作函数
4. **动作增强**：HTTP、SetVariable 等支持 JSON
5. **新动作类型**：JsonProcessAction 专门处理 JSON
6. **示例和文档**：完整的用例说明

通过这些改进，应用将能够：
- 处理 API 返回的 JSON 数据
- 在动作间传递复杂对象
- 灵活查询和操作 JSON 数据
- 构建更强大的自动化工作流

---

## 附录：JSONPath 语法参考

| 语法 | 说明 | 示例 |
|------|------|------|
| `.` | 字段访问 | `user.name` |
| `[]` | 数组索引 | `items[0]` |
| `[*]` | 所有元素 | `items[*]` |
| `[?]` | 过滤器 | `items[?age>18]` |
| `..` | 递归搜索 | `store..book.price` |
| `@` | 当前对象 | `price > @.min` |

当前实现支持基础语法（`.` 和 `[]`），高级语法可在后续版本扩展。
