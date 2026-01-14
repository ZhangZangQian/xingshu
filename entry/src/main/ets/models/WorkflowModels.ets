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

export interface ConfigDisplayItem {
  displayType: 'text' | 'button' | 'tag' | 'icon-tag' | 'avatar-tag';
  label: string;
  configKey?: string;
  style?: ConfigDisplayStyle;
  validation?: ConfigValidation;
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
