import { ConfigDisplayItem, ConfigDisplayStyle, ConfigValidation } from '../models/WorkflowModels';

const timeStyle1: ConfigDisplayStyle = { backgroundColor: '#FFF0D6', textColor: '#FF9500' };
const timeStyle2: ConfigDisplayStyle = { backgroundColor: '#FFF0D6', textColor: '#FF9500' };
const timeValidation: ConfigValidation = { type: 'string', required: true };

const weatherStyle: ConfigDisplayStyle = {
  backgroundColor: '#EFF6FF',
  textColor: '#2563EB',
  borderColor: '#BFDBFE',
  icon: '\uF56E'
};

const scriptingStyle1: ConfigDisplayStyle = {
  backgroundColor: '#FEF3C7',
  textColor: '#D97706',
  borderColor: '#FDE68A',
  icon: '\uF595'
};

const scriptingStyle2: ConfigDisplayStyle = {
  backgroundColor: '#F3F4F6',
  textColor: '#000000',
  borderColor: '#E5E7EB'
};

const scriptingValidation: ConfigValidation = { type: 'number', min: -100, max: 100 };

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

  'scripting': [
    {
      displayType: 'text',
      label: 'If'
    } as ConfigDisplayItem,
    {
      displayType: 'icon-tag',
      label: 'Temperature',
      configKey: 'variable',
      style: scriptingStyle1
    } as ConfigDisplayItem,
    {
      displayType: 'text',
      label: 'is greater than'
    } as ConfigDisplayItem,
    {
      displayType: 'tag',
      label: '30°C',
      configKey: 'threshold',
      style: scriptingStyle2,
      validation: scriptingValidation
    } as ConfigDisplayItem
  ]
};

export function getConfigDisplayTemplate(itemId: string): ConfigDisplayItem[] | undefined {
  return CONFIG_DISPLAY_TEMPLATES[itemId];
}
