export enum TriggerCategory {
  BASIC_ENV = 'basic_env',
  DEVICE_STATE = 'device_state',
  HARMONY_ECOSYSTEM = 'harmony_ecosystem',
  USER_INTENT = 'user_intent'
}

export enum TriggerType {
  TIME_DATE = 'time_date',
  LOCATION = 'location',
  WIFI = 'wifi',
  BLUETOOTH = 'bluetooth',
  BATTERY = 'battery',
  APP_STATE = 'app_state',
  NFC = 'nfc',
  CLIPBOARD = 'clipboard',
  SUPER_TERMINAL = 'super_terminal',
  WEARABLE = 'wearable',
  HICAR = 'hicar',
  SMART_HOME = 'smart_home',
  WIDGET = 'widget',
  VOICE = 'voice',
  GESTURE = 'gesture'
}

export interface ConfigOption {
  label: string;
  value: string;
}

export interface TriggerConfig {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'select' | 'location' | 'time';
  label: string;
  placeholder?: string;
  defaultValue?: string | number | boolean;
  options?: ConfigOption[];
}

export interface TriggerItem {
  id: string;
  category: TriggerCategory;
  type: TriggerType;
  name: string;
  icon: string;
  iconColor: string;
  description: string;
  configs?: TriggerConfig[];
  harmonyFeature?: boolean;
}

export enum ActionCategory {
  SYSTEM_CONTROL = 'system_control',
  APP_SERVICE = 'app_service',
  CROSS_DEVICE = 'cross_device',
  FILE_PROCESSING = 'file_processing'
}

export enum ActionType {
  WIFI_BLUETOOTH = 'wifi_bluetooth',
  DISPLAY = 'display',
  VOLUME_NOTIFY = 'volume_notify',
  UTILITIES = 'utilities',
  WECHAT = 'wechat',
  ALIPAY = 'alipay',
  MAP = 'map',
  MEDIA = 'media',
  TASK_TRANSFER = 'task_transfer',
  REMOTE_CALL = 'remote_call',
  CROSS_CLIPBOARD = 'cross_clipboard',
  HICAR_CONTROL = 'hicar_control',
  FILE_OPERATIONS = 'file_operations',
  GALLERY_OPERATIONS = 'gallery_operations'
}

export interface ActionConfig {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'select' | 'file' | 'text' | 'textarea';
  label: string;
  placeholder?: string;
  defaultValue?: string | number | boolean;
  options?: ConfigOption[];
}

export interface ActionItem {
  id: string;
  category: ActionCategory;
  type: ActionType;
  name: string;
  icon: string;
  iconColor: string;
  description: string;
  configs?: ActionConfig[];
  harmonyFeature?: boolean;
}

export enum LogicNodeType {
  IF_ELSE = 'if_else',
  REPEAT = 'repeat',
  WAIT = 'wait',
  EXIT = 'exit',
  MENU = 'menu',
  SET_VARIABLE = 'set_variable',
  GET_INPUT = 'get_input',
  CALCULATOR = 'calculator',
  HTTP_REQUEST = 'http_request',
  REGEX = 'regex',
  JSON_PARSE = 'json_parse',
  RUN_SCRIPT = 'run_script'
}

export enum LogicCategory {
  FLOW_CONTROL = 'flow_control',
  VARIABLE_DATA = 'variable_data',
  ADVANCED = 'advanced'
}

export interface LogicConfig {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'select' | 'code' | 'textarea';
  label: string;
  placeholder?: string;
  defaultValue?: string | number | boolean;
  options?: ConfigOption[];
}

export interface LogicNode {
  id: string;
  category: LogicCategory;
  type: LogicNodeType;
  name: string;
  icon: string;
  iconColor: string;
  description: string;
  configs?: LogicConfig[];
  supportNested?: boolean;
}

export interface WorkflowNode {
  id: string;
  type: 'trigger' | 'action' | 'condition' | 'nested';
  itemId: string;
  itemType: TriggerType | ActionType | LogicNodeType;
  title: string;
  icon: string;
  iconColor: string;
  description?: string;
  config?: Map<string, Object>;
  children?: WorkflowNode[];
}

export interface Workflow {
  id: string;
  name: string;
  description?: string;
  icon: string;
  iconColor: string;
  createdAt: number;
  updatedAt: number;
  isEnabled: boolean;
  triggerCount: number;
  actionCount: number;
  nodes: WorkflowNode[];
}

export interface WorkflowStats {
  totalWorkflows: number;
  enabledWorkflows: number;
  triggerCount: number;
  actionCount: number;
}

export interface ConfigAvatarStyle {
  letter: string;
  bgColor: string;
  textColor: string;
}

export interface ConfigDisplayStyle {
  backgroundColor?: string;
  textColor?: string;
  borderColor?: string;
  icon?: string;
  avatar?: ConfigAvatarStyle;
}

export interface ConfigValidation {
  type: 'string' | 'number' | 'boolean';
  required?: boolean;
  pattern?: string;
  min?: number;
  max?: number;
}

// ConfigDisplayItem 保持为 interface，因为模板数据是静态的
export interface ConfigDisplayItem {
  displayType: 'text' | 'button' | 'tag' | 'icon-tag' | 'avatar-tag';
  label: string;
  configKey?: string;
  style?: ConfigDisplayStyle;
  validation?: ConfigValidation;
  editorType?: ConfigEditorType;
  optionsSource?: OptionsSource;
  placeholder?: string;
}

// 编辑器类型
export type ConfigEditorType =
  | 'text'           // 文本输入
  | 'number'         // 数字输入
  | 'select'         // 下拉选择
  | 'time'           // 时间选择器
  | 'date'           // 日期选择器
  | 'variable'       // 变量选择器（从上下文获取）
  | 'location'       // 位置选择器
  | 'file'           // 文件选择器
  | 'none';          // 纯展示，不可编辑

// 选项数据来源
export interface OptionsSource {
  type: 'static' | 'context' | 'api';
  // static: 使用 ConfigOption[] 静态选项
  staticOptions?: ConfigOption[];
  // context: 从上下文获取（如前置卡片输出变量）
  contextKey?: string;  // 如 'variables', 'outputs'
  // api: 从接口获取（预留）
  apiEndpoint?: string;
}

// 变量信息接口
export interface VariableInfo {
  id: string;
  name: string;
  type: 'string' | 'number' | 'boolean' | 'object';
  icon?: string;
  source?: string;  // 来源：'用户定义' | 'XX卡片输出'
  value?: string | number | boolean;
}

// 多卡片动作组（如 if-else 结构）
export interface ActionCardGroup {
  groupId: string;
  groupType: 'if_else' | 'repeat' | 'switch';  // 可扩展
  cards: ActionCardDefinition[];  // 组内卡片定义
}

// 卡片定义
export interface ActionCardDefinition {
  cardType: 'start' | 'middle' | 'end';  // if / else / end_if
  title: string;
  icon: string;
  iconColor: string;
  configDisplay?: ConfigDisplayItem[];
  acceptChildren?: boolean;  // 是否接受子动作
}

// export interface ConfigValidation {
//   type: 'string' | 'number' | 'boolean';
//   required?: boolean;
//   pattern?: string;
//   min?: number;
//   max?: number;
// }

// export interface ConfigAvatarStyle {
//   letter: string;
//   bgColor: string;
//   textColor: string;
// }

// export interface ConfigDisplayStyle {
//   backgroundColor?: string;
//   textColor?: string;
//   borderColor?: string;
//   icon?: string;
//   avatar?: ConfigAvatarStyle;
// }
