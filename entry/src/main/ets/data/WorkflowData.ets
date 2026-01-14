import {
  TriggerItem,
  TriggerCategory,
  TriggerType,
  ActionItem,
  ActionCategory,
  ActionType,
  LogicNode,
  LogicCategory,
  LogicNodeType,
  TriggerConfig,
  ActionConfig,
  LogicConfig,
  ConfigOption
} from '../models/WorkflowModels';

const createStringConfig = (key: string, label: string, placeholder?: string): TriggerConfig => {
  const config: TriggerConfig = {
    key: key,
    type: 'string',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createSelectConfig = (key: string, label: string, defaultValue: string, options: ConfigOption[]): TriggerConfig => {
  const config: TriggerConfig = {
    key: key,
    type: 'select',
    label: label,
    defaultValue: defaultValue,
    options: options
  };
  return config;
};

const createTimeConfig = (key: string, label: string, defaultValue: string): TriggerConfig => {
  const config: TriggerConfig = {
    key: key,
    type: 'time',
    label: label,
    defaultValue: defaultValue
  };
  return config;
};

const createNumberConfig = (key: string, label: string, defaultValue: number): TriggerConfig => {
  const config: TriggerConfig = {
    key: key,
    type: 'number',
    label: label,
    defaultValue: defaultValue
  };
  return config;
};

const createNumberConfigAction = (key: string, label: string, defaultValue: number): ActionConfig => {
  const config: ActionConfig = {
    key: key,
    type: 'number',
    label: label,
    defaultValue: defaultValue
  };
  return config;
};

const createSelectConfigAction = (key: string, label: string, defaultValue: string, options: ConfigOption[]): ActionConfig => {
  const config: ActionConfig = {
    key: key,
    type: 'select',
    label: label,
    defaultValue: defaultValue,
    options: options
  };
  return config;
};

const createStringConfigAction = (key: string, label: string, placeholder?: string): ActionConfig => {
  const config: ActionConfig = {
    key: key,
    type: 'string',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createTextareaConfigAction = (key: string, label: string, placeholder?: string): ActionConfig => {
  const config: ActionConfig = {
    key: key,
    type: 'textarea',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createFileConfigAction = (key: string, label: string, placeholder?: string): ActionConfig => {
  const config: ActionConfig = {
    key: key,
    type: 'file',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createTextConfigAction = (key: string, label: string, placeholder?: string): ActionConfig => {
  const config: ActionConfig = {
    key: key,
    type: 'text',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createSelectConfigLogic = (key: string, label: string, defaultValue: string, options: ConfigOption[]): LogicConfig => {
  const config: LogicConfig = {
    key: key,
    type: 'select',
    label: label,
    defaultValue: defaultValue,
    options: options
  };
  return config;
};

const createStringConfigLogic = (key: string, label: string, placeholder?: string): LogicConfig => {
  const config: LogicConfig = {
    key: key,
    type: 'string',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createNumberConfigLogic = (key: string, label: string, defaultValue: number): LogicConfig => {
  const config: LogicConfig = {
    key: key,
    type: 'number',
    label: label,
    defaultValue: defaultValue
  };
  return config;
};

const createCodeConfigLogic = (key: string, label: string, placeholder?: string): LogicConfig => {
  const config: LogicConfig = {
    key: key,
    type: 'code',
    label: label,
    placeholder: placeholder
  };
  return config;
};

const createTextareaConfigLogic = (key: string, label: string, placeholder?: string): LogicConfig => {
  const config: LogicConfig = {
    key: key,
    type: 'textarea',
    label: label,
    placeholder: placeholder
  };
  return config;
};

export const TRIGGER_DATA: TriggerItem[] = [
  {
    id: 'time_date',
    category: TriggerCategory.BASIC_ENV,
    type: TriggerType.TIME_DATE,
    name: '时间/日期',
    icon: '\u23F0',
    iconColor: '#F59E0B',
    description: '具体时间、日出/日落、工作日/节假日',
    configs: [
      createSelectConfig('timeType', '时间类型', 'specific', [{ label: '具体时间', value: 'specific' }, { label: '日出', value: 'sunrise' }, { label: '日落', value: 'sunset' }]),
      createTimeConfig('time', '时间', '07:00'),
      createSelectConfig('weekdays', '重复', 'daily', [{ label: '每天', value: 'daily' }, { label: '工作日', value: 'weekdays' }, { label: '周末', value: 'weekends' }])
    ]
  },
  {
    id: 'location',
    category: TriggerCategory.BASIC_ENV,
    type: TriggerType.LOCATION,
    name: '地理位置',
    icon: '\uD83D\uDCCD',
    iconColor: '#10B981',
    description: '到达/离开某地、半径范围',
    configs: [
      createSelectConfig('action', '动作', 'arrive', [{ label: '到达', value: 'arrive' }, { label: '离开', value: 'leave' }]),
      createStringConfig('locationName', '地点名称', '如：公司'),
      createNumberConfig('radius', '半径（米）', 500)
    ]
  },
  {
    id: 'wifi',
    category: TriggerCategory.BASIC_ENV,
    type: TriggerType.WIFI,
    name: 'Wi-Fi 状态',
    icon: '\uD83D\uDCF6',
    iconColor: '#3B82F6',
    description: '连接/断开指定SSID',
    configs: [
      createSelectConfig('action', '动作', 'connect', [{ label: '连接', value: 'connect' }, { label: '断开', value: 'disconnect' }]),
      createStringConfig('ssid', 'Wi-Fi名称', '如：家里Wi-Fi')
    ]
  },
  {
    id: 'bluetooth',
    category: TriggerCategory.BASIC_ENV,
    type: TriggerType.BLUETOOTH,
    name: '蓝牙连接',
    icon: '\uD83D\uDC50',
    iconColor: '#8B5CF6',
    description: '连接/断开指定设备',
    configs: [
      createSelectConfig('action', '动作', 'connect', [{ label: '连接', value: 'connect' }, { label: '断开', value: 'disconnect' }]),
      createStringConfig('deviceName', '设备名称', '如：车载蓝牙')
    ]
  },
  {
    id: 'battery',
    category: TriggerCategory.DEVICE_STATE,
    type: TriggerType.BATTERY,
    name: '电源/电量',
    icon: '\uD83D\uDD0B',
    iconColor: '#EF4444',
    description: '充电中、断电、电量 < X%',
    configs: [
      createSelectConfig('condition', '条件', 'below', [{ label: '充电中', value: 'charging' }, { label: '断电', value: 'discharging' }, { label: '电量低于', value: 'below' }]),
      createNumberConfig('threshold', '电量阈值（%）', 20)
    ]
  },
  {
    id: 'app_state',
    category: TriggerCategory.DEVICE_STATE,
    type: TriggerType.APP_STATE,
    name: '应用状态',
    icon: '\uD83D\uDC4E',
    iconColor: '#EC4899',
    description: '打开/关闭指定App',
    configs: [
      createSelectConfig('action', '动作', 'open', [{ label: '打开', value: 'open' }, { label: '关闭', value: 'close' }]),
      createStringConfig('packageName', '应用包名', '如：com.ss.android.ugc.aweme')
    ]
  },
  {
    id: 'nfc',
    category: TriggerCategory.DEVICE_STATE,
    type: TriggerType.NFC,
    name: 'NFC 标签',
    icon: '\uD83D\uDCBF',
    iconColor: '#F59E0B',
    description: '扫描特定 Tag ID',
    harmonyFeature: true,
    configs: [
      createStringConfig('tagId', 'NFC标签ID', '扫描标签获取ID')
    ]
  },
  {
    id: 'clipboard',
    category: TriggerCategory.DEVICE_STATE,
    type: TriggerType.CLIPBOARD,
    name: '剪贴板',
    icon: '\uD83D\uDCCB',
    iconColor: '#6B7280',
    description: '包含特定关键词/正则匹配',
    configs: [
      createSelectConfig('matchType', '匹配类型', 'keyword', [{ label: '关键词', value: 'keyword' }, { label: '正则表达式', value: 'regex' }]),
      createStringConfig('pattern', '匹配内容', '如：快递单号')
    ]
  },
  {
    id: 'super_terminal',
    category: TriggerCategory.HARMONY_ECOSYSTEM,
    type: TriggerType.SUPER_TERMINAL,
    name: '超级终端',
    icon: '\uD83D\uDE80',
    iconColor: '#8B5CF6',
    description: '设备接入/断开',
    harmonyFeature: true,
    configs: [
      createSelectConfig('action', '动作', 'connect', [{ label: '接入', value: 'connect' }, { label: '断开', value: 'disconnect' }]),
      createSelectConfig('deviceType', '设备类型', 'tablet', [{ label: '平板', value: 'tablet' }, { label: '智慧屏', value: 'tv' }, { label: 'PC', value: 'pc' }])
    ]
  },
  {
    id: 'wearable',
    category: TriggerCategory.HARMONY_ECOSYSTEM,
    type: TriggerType.WEARABLE,
    name: '穿戴设备',
    icon: '\u231A',
    iconColor: '#10B981',
    description: '睡眠状态、心率阈值、锻炼状态',
    harmonyFeature: true,
    configs: [
      createSelectConfig('type', '类型', 'sleep', [{ label: '睡眠状态', value: 'sleep' }, { label: '心率阈值', value: 'heart_rate' }, { label: '锻炼状态', value: 'exercise' }]),
      createSelectConfig('condition', '条件', 'awake', [{ label: '入睡', value: 'asleep' }, { label: '醒来', value: 'awake' }])
    ]
  },
  {
    id: 'hicar',
    category: TriggerCategory.HARMONY_ECOSYSTEM,
    type: TriggerType.HICAR,
    name: 'Hicar (车机)',
    icon: '\uD83D\uDE97',
    iconColor: '#3B82F6',
    description: '车辆启动、熄火、连接Hicar',
    harmonyFeature: true,
    configs: [
      createSelectConfig('event', '事件', 'connect', [{ label: '启动', value: 'start' }, { label: '熄火', value: 'stop' }, { label: '连接', value: 'connect' }])
    ]
  },
  {
    id: 'smart_home',
    category: TriggerCategory.HARMONY_ECOSYSTEM,
    type: TriggerType.SMART_HOME,
    name: '智能家居',
    icon: '\uD83C\uDFE1',
    iconColor: '#F59E0B',
    description: '设备状态变化（开/关/数值）',
    harmonyFeature: true,
    configs: [
      createSelectConfig('deviceType', '设备类型', 'lock', [{ label: '智能门锁', value: 'lock' }, { label: '灯光', value: 'light' }, { label: '窗帘', value: 'curtain' }]),
      createSelectConfig('state', '状态', 'on', [{ label: '开启', value: 'on' }, { label: '关闭', value: 'off' }])
    ]
  },
  {
    id: 'widget',
    category: TriggerCategory.USER_INTENT,
    type: TriggerType.WIDGET,
    name: '桌面卡片',
    icon: '\uD83D\uDCCA',
    iconColor: '#8B5CF6',
    description: '点击卡片特定按钮',
    harmonyFeature: true,
    configs: [
      createStringConfig('buttonId', '按钮ID')
    ]
  },
  {
    id: 'voice',
    category: TriggerCategory.USER_INTENT,
    type: TriggerType.VOICE,
    name: '语音唤醒',
    icon: '\uD83D\uDDE3',
    iconColor: '#10B981',
    description: '特定指令词',
    harmonyFeature: true,
    configs: [
      createStringConfig('command', '指令词', '如：我要开会了')
    ]
  },
  {
    id: 'gesture',
    category: TriggerCategory.USER_INTENT,
    type: TriggerType.GESTURE,
    name: '手势/物理',
    icon: '\uD83D\uDC4D',
    iconColor: '#F59E0B',
    description: '摇一摇、背部轻敲',
    configs: [
      createSelectConfig('type', '手势类型', 'shake', [{ label: '摇一摇', value: 'shake' }, { label: '背部轻敲', value: 'knock' }]),
      createSelectConfig('intensity', '强度', 'heavy', [{ label: '轻微', value: 'light' }, { label: '剧烈', value: 'heavy' }])
    ]
  }
];

export const ACTION_DATA: ActionItem[] = [
  {
    id: 'wifi_bluetooth',
    category: ActionCategory.SYSTEM_CONTROL,
    type: ActionType.WIFI_BLUETOOTH,
    name: '无线管控',
    icon: '\uD83D\uDCF1',
    iconColor: '#3B82F6',
    description: '开关 Wi-Fi / 蓝牙 / 5G / 飞行模式 / 热点',
    configs: [
      createSelectConfigAction('target', '目标', 'wifi', [{ label: 'Wi-Fi', value: 'wifi' }, { label: '蓝牙', value: 'bluetooth' }, { label: '5G', value: '5g' }, { label: '飞行模式', value: 'airplane' }, { label: '热点', value: 'hotspot' }]),
      createSelectConfigAction('action', '动作', 'toggle', [{ label: '开启', value: 'on' }, { label: '关闭', value: 'off' }, { label: '切换', value: 'toggle' }])
    ]
  },
  {
    id: 'display',
    category: ActionCategory.SYSTEM_CONTROL,
    type: ActionType.DISPLAY,
    name: '显示/外观',
    icon: '\uD83D\uDCC4',
    iconColor: '#6B7280',
    description: '亮度调节、深色模式、息屏显示、锁定屏幕',
    configs: [
      createSelectConfigAction('type', '类型', 'brightness', [{ label: '亮度', value: 'brightness' }, { label: '深色模式', value: 'dark_mode' }, { label: '息屏显示', value: 'always_on' }, { label: '锁定屏幕', value: 'lock_screen' }]),
      createNumberConfigAction('value', '亮度值（0-100）', 50)
    ]
  },
  {
    id: 'volume_notify',
    category: ActionCategory.SYSTEM_CONTROL,
    type: ActionType.VOLUME_NOTIFY,
    name: '音量/通知',
    icon: '\uD83D\uDD0A',
    iconColor: '#F59E0B',
    description: '铃声/媒体音量、震动模式、朗读文本 (TTS)',
    configs: [
      createSelectConfigAction('type', '类型', 'media', [{ label: '铃声音量', value: 'ringtone' }, { label: '媒体音量', value: 'media' }, { label: '震动模式', value: 'vibration' }, { label: '朗读文本', value: 'tts' }]),
      createNumberConfigAction('value', '音量值（0-100）', 30),
      createTextareaConfigAction('text', '朗读文本', '输入要朗读的内容')
    ]
  },
  {
    id: 'utilities',
    category: ActionCategory.SYSTEM_CONTROL,
    type: ActionType.UTILITIES,
    name: '实用工具',
    icon: '\uD83D\uDD27',
    iconColor: '#6B7280',
    description: '截图、录屏、开启手电筒、倒计时',
    configs: [
      createSelectConfigAction('type', '类型', 'screenshot', [{ label: '截图', value: 'screenshot' }, { label: '录屏', value: 'screen_record' }, { label: '手电筒', value: 'flashlight' }, { label: '倒计时', value: 'timer' }]),
      createNumberConfigAction('duration', '时长（秒）', 5)
    ]
  },
  {
    id: 'wechat',
    category: ActionCategory.APP_SERVICE,
    type: ActionType.WECHAT,
    name: '微信 (WeChat)',
    icon: '\uD83D\uDCAC',
    iconColor: '#07C160',
    description: '扫一扫、付款码、发送预设文本、打开朋友圈',
    configs: [
      createSelectConfigAction('type', '类型', 'pay', [{ label: '扫一扫', value: 'scan' }, { label: '付款码', value: 'pay' }, { label: '发送消息', value: 'send_message' }, { label: '朋友圈', value: 'moments' }]),
      createTextareaConfigAction('message', '消息内容', '输入预设文本')
    ]
  },
  {
    id: 'alipay',
    category: ActionCategory.APP_SERVICE,
    type: ActionType.ALIPAY,
    name: '支付宝 (Alipay)',
    icon: '\uD83D\uDCB8',
    iconColor: '#1677FF',
    description: '乘车码、健康码、收能量、转账',
    configs: [
      createSelectConfigAction('type', '类型', 'bus_code', [{ label: '乘车码', value: 'bus_code' }, { label: '健康码', value: 'health_code' }, { label: '收能量', value: 'collect_energy' }, { label: '转账', value: 'transfer' }])
    ]
  },
  {
    id: 'map',
    category: ActionCategory.APP_SERVICE,
    type: ActionType.MAP,
    name: '导航 (Map)',
    icon: '\uD83D\uDFE9',
    iconColor: '#F59E0B',
    description: '发起导航(回家/公司)、查询路况、周边搜索',
    configs: [
      createSelectConfigAction('type', '类型', 'home', [{ label: '回家', value: 'home' }, { label: '去公司', value: 'work' }, { label: '指定地点', value: 'custom' }]),
      createStringConfigAction('address', '目的地', '输入地址或地点名称')
    ]
  },
  {
    id: 'media',
    category: ActionCategory.APP_SERVICE,
    type: ActionType.MEDIA,
    name: '媒体 (Media)',
    icon: '\uD83C\uDFB5',
    iconColor: '#EC4899',
    description: '播放/暂停、下一首、打开特定歌单',
    configs: [
      createSelectConfigAction('type', '类型', 'play', [{ label: '播放', value: 'play' }, { label: '暂停', value: 'pause' }, { label: '下一首', value: 'next' }, { label: '打开歌单', value: 'playlist' }]),
      createStringConfigAction('playlistName', '歌单名称', '输入歌单名称')
    ]
  },
  {
    id: 'task_transfer',
    category: ActionCategory.CROSS_DEVICE,
    type: ActionType.TASK_TRANSFER,
    name: '任务流转',
    icon: '\uD83D\uDD01',
    iconColor: '#8B5CF6',
    description: '发送当前URL/文件到指定设备(TV/Pad/PC)',
    harmonyFeature: true,
    configs: [
      createSelectConfigAction('type', '类型', 'url', [{ label: '当前URL', value: 'url' }, { label: '文件', value: 'file' }]),
      createSelectConfigAction('deviceType', '目标设备', 'tablet', [{ label: '平板', value: 'tablet' }, { label: '智慧屏', value: 'tv' }, { label: 'PC', value: 'pc' }])
    ]
  },
  {
    id: 'remote_call',
    category: ActionCategory.CROSS_DEVICE,
    type: ActionType.REMOTE_CALL,
    name: '远程调用',
    icon: '\uD83D\uDCF7',
    iconColor: '#3B82F6',
    description: '调用其他设备摄像头/麦克风',
    harmonyFeature: true,
    configs: [
      createSelectConfigAction('type', '类型', 'camera', [{ label: '摄像头', value: 'camera' }, { label: '麦克风', value: 'microphone' }]),
      createStringConfigAction('deviceId', '设备ID', '选择或输入设备ID')
    ]
  },
  {
    id: 'cross_clipboard',
    category: ActionCategory.CROSS_DEVICE,
    type: ActionType.CROSS_CLIPBOARD,
    name: '跨端剪贴板',
    icon: '\uD83D\uDCCB',
    iconColor: '#10B981',
    description: '获取/设置云剪贴板内容',
    harmonyFeature: true,
    configs: [
      createSelectConfigAction('action', '动作', 'get', [{ label: '获取', value: 'get' }, { label: '设置', value: 'set' }]),
      createTextareaConfigAction('text', '剪贴板内容', '输入要设置的文本')
    ]
  },
  {
    id: 'hicar_control',
    category: ActionCategory.CROSS_DEVICE,
    type: ActionType.HICAR_CONTROL,
    name: 'Hicar 控制',
    icon: '\uD83D\uDE97',
    iconColor: '#3B82F6',
    description: '开空调、开关窗、寻车、解锁',
    harmonyFeature: true,
    configs: [
      createSelectConfigAction('action', '动作', 'ac', [{ label: '开空调', value: 'ac' }, { label: '开关窗', value: 'window' }, { label: '寻车', value: 'find_car' }, { label: '解锁', value: 'unlock' }]),
      createNumberConfigAction('value', '空调温度', 24)
    ]
  },
  {
    id: 'file_operations',
    category: ActionCategory.FILE_PROCESSING,
    type: ActionType.FILE_OPERATIONS,
    name: '文件操作',
    icon: '\uD83D\uDCCE',
    iconColor: '#6B7280',
    description: '保存文件、压缩/解压、转换格式(如PDF转图)',
    configs: [
      createSelectConfigAction('type', '类型', 'save', [{ label: '保存文件', value: 'save' }, { label: '压缩', value: 'compress' }, { label: '解压', value: 'decompress' }, { label: '格式转换', value: 'convert' }]),
      createFileConfigAction('source', '源文件', '选择文件'),
      createStringConfigAction('targetFormat', '目标格式', '如：jpg, png, pdf')
    ]
  },
  {
    id: 'gallery_operations',
    category: ActionCategory.FILE_PROCESSING,
    type: ActionType.GALLERY_OPERATIONS,
    name: '相册操作',
    icon: '\uD83D\uDBC7',
    iconColor: '#EC4899',
    description: '保存图片到相册、删除最近照片、获取最新照片',
    configs: [
      createSelectConfigAction('type', '类型', 'save', [{ label: '保存图片', value: 'save' }, { label: '删除最近', value: 'delete_recent' }, { label: '获取最新', value: 'get_latest' }]),
      createNumberConfigAction('count', '数量', 1)
    ]
  }
];

export const LOGIC_DATA: LogicNode[] = [
  {
    id: 'if_else', //TODO 与其他Action Id 数据类型不一致，导致解析失败，获取不到配置项
    category: LogicCategory.FLOW_CONTROL,
    type: LogicNodeType.IF_ELSE,
    name: '如果 (If / Else)',
    icon: '\u2795',
    iconColor: '#F59E0B',
    description: '判断条件是否满足（如：如果现在是晚上）',
    supportNested: true,
    configs: [
      createStringConfigLogic('condition', '条件表达式', '如：temperature > 30'),
      createStringConfigLogic('variable', '变量名', '如：temperature'),
      createSelectConfigLogic('operator', '操作符', '>', [{ label: '大于', value: '>' }, { label: '小于', value: '<' }, { label: '等于', value: '==' }, { label: '不等于', value: '!=' }]),
      createNumberConfigLogic('value', '比较值', 0)
    ]
  },
  {
    id: 'repeat',
    category: LogicCategory.FLOW_CONTROL,
    type: LogicNodeType.REPEAT,
    name: '重复 (Repeat)',
    icon: '\uD83D\uDD01',
    iconColor: '#8B5CF6',
    description: '循环执行某段动作 X 次',
    supportNested: true,
    configs: [
      createNumberConfigLogic('times', '重复次数', 3)
    ]
  },
  {
    id: 'wait',
    category: LogicCategory.FLOW_CONTROL,
    type: LogicNodeType.WAIT,
    name: '等待 (Wait)',
    icon: '\u23F3',
    iconColor: '#6B7280',
    description: '暂停流程 X 秒/分钟',
    configs: [
      createNumberConfigLogic('duration', '时长', 5),
      createSelectConfigLogic('unit', '单位', 'seconds', [{ label: '秒', value: 'seconds' }, { label: '分钟', value: 'minutes' }])
    ]
  },
  {
    id: 'exit',
    category: LogicCategory.FLOW_CONTROL,
    type: LogicNodeType.EXIT,
    name: '退出 (Exit)',
    icon: '\uD83D\uDD34',
    iconColor: '#EF4444',
    description: '强制结束当前工作流',
    configs: []
  },
  {
    id: 'menu',
    category: LogicCategory.FLOW_CONTROL,
    type: LogicNodeType.MENU,
    name: '菜单 (Menu)',
    icon: '\uD83D\uDCCB',
    iconColor: '#3B82F6',
    description: '弹出一个选项菜单供用户选择',
    configs: [
      createTextareaConfigLogic('options', '选项（每行一个）', '选项1\n选项2\n选项3')
    ]
  },
  {
    id: 'set_variable',
    category: LogicCategory.VARIABLE_DATA,
    type: LogicNodeType.SET_VARIABLE,
    name: '设置变量',
    icon: '\uD83D\uDCDD',
    iconColor: '#10B981',
    description: '存储文本、数字或文件路径',
    configs: [
      createStringConfigLogic('name', '变量名', '如：myVariable'),
      createTextareaConfigLogic('value', '变量值', '输入值'),
      createSelectConfigLogic('type', '类型', 'string', [{ label: '文本', value: 'string' }, { label: '数字', value: 'number' }, { label: '文件路径', value: 'file' }])
    ]
  },
  {
    id: 'get_input',
    category: LogicCategory.VARIABLE_DATA,
    type: LogicNodeType.GET_INPUT,
    name: '获取输入',
    icon: '\uD83D\uDD11',
    iconColor: '#F59E0B',
    description: '弹窗请求用户输入文本/数字',
    configs: [
      createStringConfigLogic('title', '标题', '输入提示'),
      createStringConfigLogic('defaultValue', '默认值', '默认输入内容')
    ]
  },
  {
    id: 'calculator',
    category: LogicCategory.VARIABLE_DATA,
    type: LogicNodeType.CALCULATOR,
    name: '计算器',
    icon: '\u2794',
    iconColor: '#8B5CF6',
    description: '进行加减乘除运算',
    configs: [
      createStringConfigLogic('variable', '结果变量名', '如：result'),
      createStringConfigLogic('expression', '表达式', '如：a + b * 2')
    ]
  },
  {
    id: 'http_request',
    category: LogicCategory.ADVANCED,
    type: LogicNodeType.HTTP_REQUEST,
    name: '网络请求 (HTTP)',
    icon: '\uD83D\uDEE0',
    iconColor: '#3B82F6',
    description: 'GET / POST / PUT 请求，支持自定义Header',
    configs: [
      createSelectConfigLogic('method', '方法', 'GET', [{ label: 'GET', value: 'GET' }, { label: 'POST', value: 'POST' }, { label: 'PUT', value: 'PUT' }]),
      createStringConfigLogic('url', 'URL', 'https://api.example.com/data'),
      createTextareaConfigLogic('headers', 'Headers (JSON)', '{"Authorization": "Bearer token"}'),
      createTextareaConfigLogic('body', '请求体 (JSON)', '{"key": "value"}')
    ]
  },
  {
    id: 'regex',
    category: LogicCategory.ADVANCED,
    type: LogicNodeType.REGEX,
    name: '正则表达式',
    icon: '\uD83D\uDD0D',
    iconColor: '#10B981',
    description: '文本提取、替换',
    configs: [
      createSelectConfigLogic('action', '动作', 'extract', [{ label: '提取', value: 'extract' }, { label: '替换', value: 'replace' }]),
      createStringConfigLogic('pattern', '正则表达式', '如：\\d+'),
      createStringConfigLogic('input', '输入文本', '要处理的文本'),
      createStringConfigLogic('replacement', '替换内容', '替换为')
    ]
  },
  {
    id: 'json_parse',
    category: LogicCategory.ADVANCED,
    type: LogicNodeType.JSON_PARSE,
    name: 'JSON 解析',
    icon: '\uD83D\uDCDC',
    iconColor: '#EC4899',
    description: '解析网络请求返回的数据字典',
    configs: [
      createTextareaConfigLogic('jsonString', 'JSON字符串', '{"key": "value"}'),
      createStringConfigLogic('keyPath', '键路径', '如：data.items[0].name')
    ]
  },
  {
    id: 'run_script',
    category: LogicCategory.ADVANCED,
    type: LogicNodeType.RUN_SCRIPT,
    name: '运行脚本',
    icon: '\uD83D\uDCBB',
    iconColor: '#6B7280',
    description: '支持简单的 JavaScript 或 Python (可选)',
    configs: [
      createSelectConfigLogic('language', '语言', 'javascript', [{ label: 'JavaScript', value: 'javascript' }, { label: 'Python', value: 'python' }]),
      createCodeConfigLogic('code', '代码', '输入脚本代码')
    ]
  }
];

export interface TriggerCategoryLabels {
  basic_env: string;
  device_state: string;
  harmony_ecosystem: string;
  user_intent: string;
}

export interface ActionCategoryLabels {
  system_control: string;
  app_service: string;
  cross_device: string;
  file_processing: string;
}

export interface LogicCategoryLabels {
  flow_control: string;
  variable_data: string;
  advanced: string;
}

export interface CategoryLabels {
  trigger: TriggerCategoryLabels;
  action: ActionCategoryLabels;
  logic: LogicCategoryLabels;
}

export const CATEGORY_LABELS: CategoryLabels = {
  trigger: {
    basic_env: '基础环境',
    device_state: '设备状态',
    harmony_ecosystem: '鸿蒙生态',
    user_intent: '用户意图'
  },
  action: {
    system_control: '系统控制',
    app_service: '应用服务',
    cross_device: '跨端流转',
    file_processing: '文件处理'
  },
  logic: {
    flow_control: '流程控制',
    variable_data: '变量/数据',
    advanced: '高级能力'
  }
};
