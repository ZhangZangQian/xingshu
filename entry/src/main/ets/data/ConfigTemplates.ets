import {
  ConfigDisplayItem,
  ConfigDisplayStyle,
  ConfigValidation,
  ConfigEditorType,
  OptionsSource,
  ActionCardGroup,
  ActionCardDefinition,
  ConfigOption
} from '../models/WorkflowModels';

const timeStyle1: ConfigDisplayStyle = { backgroundColor: '#FFF0D6', textColor: '#FF9500' };
const timeStyle2: ConfigDisplayStyle = { backgroundColor: '#FFF0D6', textColor: '#FF9500' };
const timeValidation: ConfigValidation = { type: 'string', required: true };

const weatherStyle: ConfigDisplayStyle = {
  backgroundColor: '#EFF6FF',
  textColor: '#2563EB',
  borderColor: '#BFDBFE',
  icon: '\u26C5'
};

const scriptingStyle1: ConfigDisplayStyle = {
  backgroundColor: '#FEF3C7',
  textColor: '#D97706',
  borderColor: '#FDE68A'
  // icon: '\u26C5'
};

const scriptingStyle2: ConfigDisplayStyle = {
  backgroundColor: '#F3F4F6',
  textColor: '#000000',
  borderColor: '#E5E7EB'
};

const scriptingValidation: ConfigValidation = { type: 'number', min: -100, max: 100 };

const musicStyle: ConfigDisplayStyle = {
  backgroundColor: '#FDF2F8',
  textColor: '#EC4899',
  borderColor: '#FBCFE8',
  icon: '\u{1F3B5}'
};

const wifiStyle: ConfigDisplayStyle = {
  backgroundColor: '#DBEAFE',
  textColor: '#2563EB',
  borderColor: '#BFDBFE',
  icon: '\u{1F503}'
};

const displayStyle: ConfigDisplayStyle = {
  backgroundColor: '#F3F4F6',
  textColor: '#374151',
  borderColor: '#E5E7EB',
  icon: '\u{1F4F1}'
};

const volumeStyle: ConfigDisplayStyle = {
  backgroundColor: '#FEF3C7',
  textColor: '#D97706',
  borderColor: '#FDE68A',
  icon: '\u{1F50A}'
};

const messageStyle: ConfigDisplayStyle = {
  backgroundColor: '#D1FAE5',
  textColor: '#059669',
  borderColor: '#A7F3D0'
};

export const CONFIG_DISPLAY_TEMPLATES: Record<string, ConfigDisplayItem[]> = {
  'time_date': [
    {
      displayType: 'button',
      label: 'At',
      configKey: 'timeType',
      style: timeStyle1,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: '具体时间', value: 'specific' },
          { label: '日出', value: 'sunrise' },
          { label: '日落', value: 'sunset' }
        ]
      }
    } as ConfigDisplayItem,
    {
      displayType: 'button',
      label: '7:00 AM',
      configKey: 'timeValue',
      style: timeStyle2,
      validation: timeValidation,
      editorType: 'time',
      placeholder: '选择时间'
    } as ConfigDisplayItem,
    {
      displayType: 'button',
      label: 'Daily',
      configKey: 'repeat',
      style: timeStyle1,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: '每天', value: 'daily' },
          { label: '工作日', value: 'weekdays' },
          { label: '周末', value: 'weekends' },
          { label: '自定义', value: 'custom' }
        ]
      }
    } as ConfigDisplayItem
  ],

  'weather': [
    {
      displayType: 'text',
      label: 'at',
      editorType: 'none'
    } as ConfigDisplayItem,
    {
      displayType: 'icon-tag',
      label: 'Current Location',
      configKey: 'location',
      style: weatherStyle,
      editorType: 'location'
    } as ConfigDisplayItem
  ],

  'if_else': [
    {
      displayType: 'icon-tag',
      label: '选择变量',
      configKey: 'variable',
      style: scriptingStyle1,
      editorType: 'variable',
      optionsSource: {
        type: 'context',
        contextKey: 'variables'
      },
      placeholder: '选择变量'
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '大于',
      configKey: 'operator',
      style: scriptingStyle2,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: '大于', value: '>' },
          { label: '小于', value: '<' },
          { label: '等于', value: '==' },
          { label: '不等于', value: '!=' },
          { label: '大于等于', value: '>=' },
          { label: '小于等于', value: '<=' }
        ]
      }
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '0',
      configKey: 'value',
      style: scriptingStyle2,
      editorType: 'number',
      validation: scriptingValidation,
      placeholder: '输入数值'
    } as ConfigDisplayItem
  ],

  'media': [
    {
      displayType: 'text',
      label: 'Playlist:',
      editorType: 'none'
    } as ConfigDisplayItem,
    {
      displayType: 'button',
      label: 'Morning Vibes',
      configKey: 'playlistName',
      style: musicStyle,
      editorType: 'text',
      placeholder: '输入歌单名称'
    } as ConfigDisplayItem
  ],

  'wifi_bluetooth': [
    {
      displayType: 'icon-tag',
      label: 'Wi-Fi',
      configKey: 'target',
      style: wifiStyle,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: 'Wi-Fi', value: 'wifi' },
          { label: '蓝牙', value: 'bluetooth' },
          { label: '5G', value: '5g' },
          { label: '飞行模式', value: 'airplane' },
          { label: '热点', value: 'hotspot' }
        ]
      }
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: 'Toggle',
      configKey: 'action',
      style: scriptingStyle2,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: '开启', value: 'on' },
          { label: '关闭', value: 'off' },
          { label: '切换', value: 'toggle' }
        ]
      }
    } as ConfigDisplayItem
  ],

  'display': [
    {
      displayType: 'icon-tag',
      label: 'Brightness',
      configKey: 'type',
      style: displayStyle,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: '亮度', value: 'brightness' },
          { label: '深色模式', value: 'dark_mode' },
          { label: '息屏显示', value: 'always_on' },
          { label: '锁定屏幕', value: 'lock_screen' }
        ]
      }
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '50%',
      configKey: 'value',
      style: scriptingStyle2,
      editorType: 'number',
      placeholder: '0-100'
    } as ConfigDisplayItem
  ],

  'volume_notify': [
    {
      displayType: 'icon-tag',
      label: 'Media Volume',
      configKey: 'type',
      style: volumeStyle,
      editorType: 'select',
      optionsSource: {
        type: 'static',
        staticOptions: [
          { label: '铃声音量', value: 'ringtone' },
          { label: '媒体音量', value: 'media' },
          { label: '震动模式', value: 'vibration' },
          { label: '朗读文本', value: 'tts' }
        ]
      }
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '30%',
      configKey: 'value',
      style: scriptingStyle2,
      editorType: 'number',
      placeholder: '0-100'
    } as ConfigDisplayItem
  ]
};

// If-Else 多卡片组定义
export const ACTION_CARD_GROUPS: Record<string, ActionCardGroup> = {
  'if_else': {
    groupId: 'if_else',
    groupType: 'if_else',
    cards: [
      {
        cardType: 'start',
        title: '如果',
        icon: '➕',
        iconColor: '#F59E0B',
        configDisplay: CONFIG_DISPLAY_TEMPLATES['if_else'],
        acceptChildren: true
      },
      {
        cardType: 'middle',
        title: '否则',
        icon: '➖',
        iconColor: '#6B7280',
        acceptChildren: true
      },
      {
        cardType: 'end',
        title: '结束',
        icon: '⬛',
        iconColor: '#9CA3AF',
        acceptChildren: false
      }
    ]
  },
  'repeat': {
    groupId: 'repeat',
    groupType: 'repeat',
    cards: [
      {
        cardType: 'start',
        title: '重复',
        icon: '🔁',
        iconColor: '#8B5CF6',
        acceptChildren: true
      },
      {
        cardType: 'end',
        title: '结束重复',
        icon: '⬛',
        iconColor: '#9CA3AF',
        acceptChildren: false
      }
    ]
  }
};

export function getConfigDisplayTemplate(itemId: string): ConfigDisplayItem[] | undefined {
  return CONFIG_DISPLAY_TEMPLATES[itemId];
}

export function getActionCardGroup(groupType: string): ActionCardGroup | undefined {
  return ACTION_CARD_GROUPS[groupType];
}

