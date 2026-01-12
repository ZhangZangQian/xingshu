import { Folder } from '../models/Macro';

/**
 * 默认文件夹图标
 */
export const DEFAULT_FOLDER_ICON = 'folder';

/**
 * 内置文件夹
 */
export const BUILTIN_FOLDERS = {
  ALL_MACROS: { id: 0, name: '我的宏', icon: 'house_fill' },
  UNASSIGNED: { id: -1, name: '未分类', icon: 'folder' }
} as const;

/**
 * 预定义的文件夹图标选项
 */
export const FOLDER_ICONS = [
  { name: '默认', value: 'folder' },
  { name: '工作', value: 'briefcase' },
  { name: '家庭', value: 'house' },
  { name: '游戏', value: 'gamecontroller' },
  { name: '社交', value: 'person.2' },
  { name: '学习', value: 'book' },
  { name: '效率', value: 'bolt' },
  { name: '娱乐', value: 'play' },
  { name: '健康', value: 'heart' },
  { name: '金融', value: 'dollarsign' }
];
