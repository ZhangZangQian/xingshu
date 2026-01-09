/**
 * 宏定义数据模型
 */
export interface Macro {
  id: number;                      // 主键（自增）
  name: string;                    // 宏名称（1-50 字符）
  description?: string;            // 宏描述
  icon?: string;                   // 图标名称或路径
  enabled: boolean;                // 是否启用
  createdAt: number;               // 创建时间戳（毫秒）
  updatedAt: number;               // 更新时间戳（毫秒）

  // 关联数据（非数据库字段，运行时填充）
  triggers?: Trigger[];            // 触发器列表
  actions?: Action[];              // 动作列表
  conditions?: Condition[];        // 条件列表
}

/**
 * 宏输入数据（用于创建宏，不包含 id）
 */
export interface MacroInput {
  name: string;
  description?: string;
  icon?: string;
  enabled: boolean;
  createdAt: number;
  updatedAt: number;
}

/**
 * 触发器类型枚举
 */
export enum TriggerType {
  TIME = 'time',                   // 定时触发
  NETWORK = 'network',             // 网络状态触发
  MANUAL = 'manual',               // 手动触发
  CLIPBOARD = 'clipboard'          // 剪贴板触发（P1）
}

/**
 * 触发器数据模型
 */
export interface Trigger {
  id: number;                      // 主键
  macroId: number;                 // 关联宏 ID
  type: TriggerType;               // 触发器类型
  config: string;                  // JSON 配置（不同类型配置不同）
  enabled: boolean;                // 是否启用

  // 运行时解析的配置对象
  parsedConfig?: TimeTriggerConfig | NetworkTriggerConfig | ManualTriggerConfig;
}

/**
 * 定时触发器配置
 */
export interface TimeTriggerConfig {
  mode: 'once' | 'daily' | 'weekly' | 'interval';  // 触发模式

  // 一次性定时
  timestamp?: number;              // 触发时间戳（mode=once）

  // 每日重复
  dailyTime?: {                    // mode=daily
    hour: number;                  // 小时（0-23）
    minute: number;                // 分钟（0-59）
    second: number;                // 秒（0-59）
  };

  // 每周重复
  weeklyTime?: {                   // mode=weekly
    weekdays: number[];            // 星期几（0=周日，1=周一...6=周六）
    hour: number;
    minute: number;
    second: number;
  };

  // 自定义间隔
  intervalTime?: {                 // mode=interval
    intervalMinutes: number;       // 间隔分钟数
  };
}

/**
 * 网络状态触发器配置
 */
export interface NetworkTriggerConfig {
  triggerOn: 'wifi_connected' | 'wifi_disconnected' | 'mobile_connected' | 'network_disconnected';
}

/**
 * 手动触发器配置
 */
export interface ManualTriggerConfig {
  methods: ('button' | 'shortcut' | 'notification')[];  // 触发方式
}

/**
 * 动作类型枚举
 */
export enum ActionType {
  LAUNCH_APP = 'launch_app',               // 启动应用
  NOTIFICATION = 'notification',           // 发送通知
  HTTP_REQUEST = 'http_request',           // HTTP 请求
  CLIPBOARD_READ = 'clipboard_read',       // 读取剪贴板
  CLIPBOARD_WRITE = 'clipboard_write',     // 写入剪贴板
  OPEN_URL = 'open_url',                   // 打开 URL
  TEXT_PROCESS = 'text_process',           // 文本处理
  USER_DIALOG = 'user_dialog',             // 用户交互对话框
  SET_VARIABLE = 'set_variable',           // 设置变量
  IF_ELSE = 'if_else'
}

/**
 * 动作数据模型
 */
export interface Action {
  id: number;                      // 主键
  macroId: number;                 // 关联宏 ID
  type: ActionType;                // 动作类型
  config: string;                  // JSON 配置
  orderIndex: number;              // 执行顺序（从 0 开始）

  // 运行时解析的配置对象
  parsedConfig?: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
                 ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
                 SetVariableConfig | IfElseConfig;
}

/**
 * 启动应用动作配置
 */
export interface LaunchAppConfig {
  bundleName: string;              // 应用包名（如 com.huawei.hmos.contacts）
  abilityName?: string;            // 组件名（显式启动需要）
  parameters?: Record<string, Object>;  // 启动参数
  mode: 'explicit' | 'implicit';   // 显式/隐式启动
  action?: string;                 // 隐式启动的 action（如 ohos.want.action.VIEW）
  uri?: string;                    // 隐式启动的 URI
}

/**
 * 发送通知动作配置
 */
export interface NotificationConfig {
  title: string;                   // 通知标题
  content: string;                 // 通知内容
  icon?: string;                   // 通知图标
  enableSound: boolean;            // 是否声音
  enableVibration: boolean;        // 是否震动
}

/**
 * HTTP 请求头
 */
export interface HttpHeaders {
  'Content-Type'?: string;
  [key: string]: string | undefined;
}

/**
 * HTTP 请求动作配置
 */
export interface HttpRequestConfig {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  url: string;                     // 请求 URL
  headers?: HttpHeaders;           // 请求头
  body?: string;                   // 请求体（JSON 字符串）
  timeout?: number;                // 超时时间（毫秒，默认 30000）
  saveResponseTo?: string;         // 保存响应到变量名
}

/**
 * 剪贴板操作配置
 */
export interface ClipboardConfig {
  operation: 'read' | 'write';     // 读取/写入
  content?: string;                // 写入内容（operation=write）
  saveToVariable?: string;         // 保存读取内容到变量（operation=read）
}

/**
 * 打开 URL 配置
 */
export interface OpenUrlConfig {
  url: string;                     // URL 地址
  openWith: 'browser' | 'app';     // 使用浏览器/应用打开
}

/**
 * 文本处理配置
 */
export interface TextProcessConfig {
  operation: 'regex_extract' | 'replace' | 'split' | 'uppercase' | 'lowercase' | 'url_encode' | 'url_decode';
  input: string;                   // 输入文本（可使用变量 {varName}）

  // regex_extract
  pattern?: string;                // 正则表达式
  groupIndex?: number;             // 捕获组索引（默认 0）

  // replace
  searchValue?: string;            // 搜索值
  replaceValue?: string;           // 替换值

  // split
  separator?: string;              // 分隔符

  saveToVariable?: string;         // 保存结果到变量
}

/**
 * 用户交互对话框配置
 */
export interface UserDialogConfig {
  type: 'confirm' | 'single_select' | 'multi_select' | 'text_input';

  // 所有类型通用
  title: string;                   // 对话框标题
  message?: string;                // 提示信息

  // single_select / multi_select
  options?: string[];              // 选项列表

  // text_input
  placeholder?: string;            // 输入框占位符
  defaultValue?: string;           // 默认值

  saveToVariable?: string;         // 保存用户输入到变量
}

/**
 * 设置变量动作配置
 */
export interface SetVariableConfig {
  variableName: string;            // 变量名
  value: string;                   // 变量值（支持变量引用，如 {clipboard}）
  scope: 'runtime' | 'global' | 'macro';  // 变量作用域
}

/**
 * 条件数据模型
 */
export interface Condition {
  id: number;                      // 主键
  macroId: number;                 // 关联宏 ID
  field: string;                   // 比较字段（变量名或系统变量）
  operator: ConditionOperator;     // 运算符
  value: string;                   // 比较值
}

/**
 * 条件运算符枚举
 */
export enum ConditionOperator {
  EQUALS = '==',
  NOT_EQUALS = '!=',
  GREATER_THAN = '>',
  LESS_THAN = '<',
  GREATER_EQUAL = '>=',
  LESS_EQUAL = '<=',
  CONTAINS = 'contains',
  REGEX = 'regex'
}

/**
 * 执行日志数据模型
 */
export interface ExecutionLog {
  id: number;                      // 主键
  macroId: number;                 // 关联宏 ID
  triggerType: string;             // 触发器类型
  status: 'success' | 'failed' | 'partial';  // 执行状态
  errorMessage?: string;           // 错误信息
  executedAt: number;              // 执行时间戳（毫秒）
  duration: number;                // 执行时长（毫秒）
}

/**
 * 执行上下文（运行时使用）
 */
export interface ExecutionContext {
  macroId: number;                 // 当前执行的宏 ID
  triggerType: TriggerType;        // 触发类型
  variables: Map<string, Object>;  // 变量存储
  startTime: number;               // 开始执行时间戳

  // 辅助方法
  setVariable(name: string, value: Object): void;
  getVariable(name: string): Object | undefined;
  getSystemVariable(name: string): Object | undefined;  // 获取系统变量
}

/**
 * 系统变量定义
 */
export interface SystemVariables {
  date: string;                    // 当前日期（YYYY-MM-DD）
  time: string;                    // 当前时间（HH:mm:ss）
  timestamp: number;               // 当前时间戳
  clipboard: string;               // 剪贴板内容
  network_type: string;            // 当前网络类型
  battery_level: number;           // 当前电量百分比
}

/**
 * 动作执行日志数据模型
 */
export interface ActionExecutionLog {
  id: number;                      // 主键
  executionLogId: number;          // 关联的执行日志 ID
  actionId: number;                 // 关联的动作 ID
  actionType: ActionType;          // 动作类型
  actionOrderIndex: number;         // 动作执行顺序
  inputData?: string;               // 输入数据（JSON 格式）
  outputData?: string;             // 输出数据（JSON 格式）
  status: 'success' | 'failed';    // 执行状态
  errorMessage?: string;           // 错误信息
  duration: number;                // 执行时长（毫秒）
  executedAt: number;              // 执行时间戳（毫秒）
}

/**
 * 动作执行结果
 */
export interface ActionExecutionResult {
  status: 'success' | 'failed';   // 执行状态
  inputData?: Record<string, any>; // 输入数据
  outputData?: Record<string, any>; // 输出数据
  errorMessage?: string;           // 错误信息
  duration: number;                // 执行时长（毫秒）
}

/**
 * 执行日志扩展信息（包含关联数据）
 */
export interface ExecutionLogDetail extends ExecutionLog {
  macro?: Macro;                    // 关联的宏信息
  actionLogs?: ActionExecutionLog[]; // 动作执行日志
}

/**
 * IF_ELSE 分支动作配置
 */
export interface IfElseConfig {
  branches: Branch[];  // 分支列表（顺序执行，第一个匹配的分支会被执行）
}

/**
 * 分支定义
 */
export interface Branch {
  name?: string;                   // 分支名称（可选，用于调试和UI显示）
  conditions?: BranchCondition[];  // 分支条件（为空表示 else 分支）
  actions: ActionConfig[];         // 分支内的动作列表
}

/**
 * 分支条件（简化版）
 */
export interface BranchCondition {
  field: string;                   // 比较字段（变量名）
  operator: ConditionOperator;     // 运算符
  value: string;                   // 比较值
  logicOperator?: 'AND' | 'OR';    // 与下一个条件的逻辑关系（默认 AND）
}

/**
 * 动作配置（用于嵌套在分支中）
 */
export interface ActionConfig {
  type: ActionType;
  config: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
  ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
  SetVariableConfig | IfElseConfig;  // 支持嵌套
}