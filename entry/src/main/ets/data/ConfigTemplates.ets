import { ConfigDisplayItem, ConfigDisplayStyle, ConfigValidation } from '../models/WorkflowModels';

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
      style: timeStyle1
    } as ConfigDisplayItem,
    {
      displayType: 'button',
      label: '7:00 AM',
      configKey: 'timeValue',
      style: timeStyle2,
      validation: timeValidation
    } as ConfigDisplayItem,
    {
      displayType: 'button',
      label: 'Daily',
      configKey: 'repeat',
      style: timeStyle1
    } as ConfigDisplayItem
  ],

  'weather': [
    {
      displayType: 'text',
      label: 'at'
    } as ConfigDisplayItem,
    {
      displayType: 'icon-tag',
      label: 'Current Location',
      configKey: 'location',
      style: weatherStyle
    } as ConfigDisplayItem
  ],

  'if_else': [
    {
      displayType: 'text',
      label: 'If'
    } as ConfigDisplayItem,
    {
      displayType: 'icon-tag',
      label: 'Variable',
      configKey: 'variable',
      style: scriptingStyle1
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '>',
      configKey: 'operator',
      style: scriptingStyle2
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '0',
      configKey: 'value',
      style: scriptingStyle2
    } as ConfigDisplayItem
  ],

  'media': [
    {
      displayType: 'text',
      label: 'Playlist:'
    } as ConfigDisplayItem,
    {
      displayType: 'button',
      label: 'Morning Vibes',
      configKey: 'playlistName',
      style: musicStyle
    } as ConfigDisplayItem
  ],

  'wifi_bluetooth': [
    {
      displayType: 'icon-tag',
      label: 'Wi-Fi',
      configKey: 'target',
      style: wifiStyle
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: 'Toggle',
      configKey: 'action',
      style: scriptingStyle2
    } as ConfigDisplayItem
  ],

  'display': [
    {
      displayType: 'icon-tag',
      label: 'Brightness',
      configKey: 'type',
      style: displayStyle
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '50%',
      configKey: 'value',
      style: scriptingStyle2
    } as ConfigDisplayItem
  ],

  'volume_notify': [
    {
      displayType: 'icon-tag',
      label: 'Media Volume',
      configKey: 'type',
      style: volumeStyle
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '30%',
      configKey: 'value',
      style: scriptingStyle2
    } as ConfigDisplayItem
  ]
};

export function getConfigDisplayTemplate(itemId: string): ConfigDisplayItem[] | undefined {
  return CONFIG_DISPLAY_TEMPLATES[itemId];
}
