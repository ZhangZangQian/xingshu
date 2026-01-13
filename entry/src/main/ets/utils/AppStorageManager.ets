/**
 * 应用全局状态管理
 * 使用 AppStorage 实现底部导航栏的全局状态
 */

// 定义当前选中的 Tab 索引
// 0: My Flows
// 1: Gallery
// 2: Settings
AppStorage.setOrCreate('activeTab', 0);

// 定义导航路径常量
export interface NavigationPages {
  MY_FLOWS: number;
  GALLERY: number;
  SETTINGS: number;
}

export const NAVIGATION_PAGES: NavigationPages = {
  MY_FLOWS: 0,
  GALLERY: 1,
  SETTINGS: 2
};

// 获取当前激活的 Tab
export function getActiveTab(): number {
  return AppStorage.get('activeTab') as number;
}
// 设置当前激活的 Tab
export function setActiveTab(index: number): void {
  AppStorage.set('activeTab', index);
}