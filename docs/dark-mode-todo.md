# 深色模式适配状态

## 已完成

- [x] 创建基础颜色资源配置（浅色 + 深色）
- [x] 创建 ThemeManager 主题管理工具类
- [x] 创建 AppColors 颜色工具类
- [x] 创建 ThemeSwitcher 主题切换组件
- [x] 编写深色模式适配文档
- [x] 编写快速迁移指南

## 待适配页面

### Pages

- [ ] `entry/src/main/ets/pages/Index.ets` - 主页面
  - [ ] Header 组件
  - [ ] SearchBar 组件
  - [ ] ShortcutsList 组件
  - [ ] ShortcutCard 组件
  - [ ] BottomNavigation 组件
  - [ ] TabItem 组件

- [ ] `entry/src/main/ets/pages/MacroEditor.ets` - 宏编辑器
  - [ ] Header 组件
  - [ ] Content 组件
  - [ ] TriggerSection 组件
  - [ ] ActionsSection 组件
  - [ ] TriggerCard 组件
  - [ ] ActionCard 组件
  - [ ] ConditionBlock 组件
  - [ ] NestedActionCard 组件
  - [ ] EndIfCard 组件
  - [ ] AddActionButton 组件
  - [ ] GradientOverlay 组件
  - [ ] BottomPanel 组件

### Components

- [ ] `entry/src/main/ets/components/ThemeSwitcher.ets` - 主题切换器（已完成基本实现）

## 颜色使用统计

### Index.ets 颜色使用情况

| 颜色值 | 使用位置 | 已映射到 AppColors |
|--------|---------|------------------|
| #F5F6F8 | 主背景 | app_background |
| #FFFFFF | 卡片背景、底部导航 | card_background |
| #111827 | 主标题 | text_primary |
| #6B7280 | 次要文字、标签 | text_secondary |
| #9CA3AF | 图标、按钮文字 | text_tertiary |
| #607AFB | 主色调、激活状态 | primary |
| #007AFF | 链接、按钮 | accent_blue |
| #E5E7EB | 搜索框背景 | input_background |
| #E5E5EA | 边框、分割线 | border_default |
| #F3F4F6 | 按钮背景 | button_background |

### MacroEditor.ets 颜色使用情况

| 颜色值 | 使用位置 | 已映射到 AppColors |
|--------|---------|------------------|
| #F2F2F7 | 页面背景 | page_background |
| #FFFFFF | 卡片、面板背景 | card_background |
| #000000 | 主标题 | text_primary |
| #6B7280 | 描述文字 | text_secondary |
| #9CA3AF | 次要图标 | text_tertiary |
| #8E8E93 | 标签文字 | text_tertiary |
| #007AFF | 链接、按钮 | accent_blue |
| #FF9500 | 橙色强调 | accent_orange |
| #E5E5EA | 边框、分割线 | border_default |
| #D1D5DB | 更多按钮 | text_tertiary |

## 渐变色处理

以下渐变色需要根据主题动态设置：

### Index.ets
- [ ] Morning Briefing: `['#FB923C', '#F59E0B']`
- [ ] Fast Charge: `['#34D399', '#0D9488']`
- [ ] Music Mix: `['#D946EF', '#9333EA']`
- [ ] Work Mode: `['#06B6D4', '#2563EB']`
- [ ] Home ETA: `['#3B82F6', '#4F46E5']`
- [ ] Quick Note: `['#FBBF24', '#FB923C']`
- [ ] Laundry Timer: `['#94A3B8', '#475569']`
- [ ] Calculate Tip: `['#4ADE80', '#059669']`

### MacroEditor.ets
- [ ] GradientOverlay: `[['#F2F2F7', 0.0], ['rgba(242, 242, 247, 0.8)', 0.5], ['rgba(242, 242, 247, 0.0)', 1.0]]`

## 阴影配置

以下阴影需要映射到 AppColors：

### Index.ets
- [ ] `rgba(0, 0, 0, 0.05)` → AppColors.shadow_default
- [ ] `rgba(0, 0, 0, 0.08)` → AppColors.shadow_heavy

### MacroEditor.ets
- [ ] `rgba(0, 0, 0, 0.04)` → AppColors.shadow_light
- [ ] `rgba(0, 0, 0, 0.08)` → AppColors.shadow_heavy

## 适配优先级

### P0 - 核心页面
1. Index.ets - 主页面，用户首次进入的页面
2. MacroEditor.ets - 编辑器页面，核心功能页面

### P1 - 重要组件
1. 导航栏
2. 搜索栏
3. 卡片组件

### P2 - 辅助组件
1. 按钮组件
2. 标签组件
3. 分割线

## 测试计划

### 单元测试
- [ ] 测试 ThemeManager 的主题切换功能
- [ ] 测试颜色资源的正确加载
- [ ] 测试主题持久化存储

### 集成测试
- [ ] 测试页面在浅色模式下的显示
- [ ] 测试页面在深色模式下的显示
- [ ] 测试页面在自动模式下的切换
- [ ] 测试主题切换时的过渡动画

### 视觉测试
- [ ] 检查文字对比度是否符合无障碍标准
- [ ] 检查边框和阴影的可见性
- [ ] 检查渐变色在不同模式下的视觉效果
- [ ] 检查动画和过渡效果

## 已知问题

### 暂无

## 下一步行动

1. 适配 Index.ets 页面
2. 适配 MacroEditor.ets 页面
3. 进行全面测试
4. 优化深色模式下的视觉体验
5. 添加主题切换动画

## 备注

- 所有颜色资源已配置完成
- 工具类已创建并可用
- 文档已完善，可以开始适配工作
- 建议优先适配 Index.ets 页面，作为示例参考
