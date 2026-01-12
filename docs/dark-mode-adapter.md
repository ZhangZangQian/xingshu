# HarmonyOS Next 深色模式适配指南

## 概述

本项目已完成 HarmonyOS Next 深色模式的基础配置，支持浅色、深色和自动跟随系统三种模式。

## 目录结构

```
entry/src/main/resources/
├── base/
│   └── element/
│       └── color.json          # 浅色模式颜色配置
└── dark/
    └── element/
        └── color.json          # 深色模式颜色配置
```

## 颜色配置

### 浅色模式 (base/element/color.json)

| 颜色名称 | 值 | 用途 |
|---------|-----|------|
| start_window_background | #FFFFFF | 启动窗口背景 |
| app_background | #F5F6F8 | 应用主背景 |
| page_background | #F2F2F7 | 页面背景 |
| card_background | #FFFFFF | 卡片背景 |
| text_primary | #111827 | 主要文字 |
| text_secondary | #6B7280 | 次要文字 |
| text_tertiary | #9CA3AF | 占位符、图标 |
| text_inverse | #FFFFFF | 反色文字 |
| text_link | #007AFF | 链接文字 |
| primary | #607AFB | 主色调 |
| primary_light | #26607AFB | 主色调浅色 |
| primary_faint | #19607AFB | 主色调极浅 |
| accent_blue | #007AFF | 蓝色强调 |
| accent_orange | #FF9500 | 橙色强调 |
| accent_green | #22C55E | 绿色强调 |
| accent_purple | #A855F7 | 紫色强调 |
| accent_pink | #EC4899 | 粉色强调 |
| border_default | #E5E5EA | 默认边框 |
| border_light | #F3F4F6 | 浅色边框 |
| border_subtle | #0F000000 | 细微边框 |
| shadow_default | #0D000000 | 默认阴影 |
| shadow_light | #0A000000 | 浅色阴影 |
| shadow_heavy | #14000000 | 重阴影 |
| input_background | #E5E7EB | 输入框背景 |
| button_background | #F3F4F6 | 按钮背景 |
| divider_default | #E5E5EA | 分割线 |
| overlay_background | #CCFFFFFF | 覆盖层背景 |
| overlay_bottom | #F2FFFFFF | 底部覆盖层 |

### 深色模式 (dark/element/color.json)

| 颜色名称 | 值 | 用途 |
|---------|-----|------|
| start_window_background | #000000 | 启动窗口背景 |
| app_background | #000000 | 应用主背景 |
| page_background | #000000 | 页面背景 |
| card_background | #1C1C1E | 卡片背景 |
| text_primary | #FFFFFF | 主要文字 |
| text_secondary | #EBEBF5 | 次要文字 |
| text_tertiary | #8E8E93 | 占位符、图标 |
| text_inverse | #000000 | 反色文字 |
| text_link | #0A84FF | 链接文字 |
| primary | #0A84FF | 主色调 |
| primary_light | #330A84FF | 主色调浅色 |
| primary_faint | #190A84FF | 主色调极浅 |
| accent_blue | #0A84FF | 蓝色强调 |
| accent_orange | #FF9F0A | 橙色强调 |
| accent_green | #30D158 | 绿色强调 |
| accent_purple | #BF5AF2 | 紫色强调 |
| accent_pink | #FF375F | 粉色强调 |
| border_default | #38383A | 默认边框 |
| border_light | #2C2C2E | 浅色边框 |
| border_subtle | #14FFFFFF | 细微边框 |
| shadow_default | #4D000000 | 默认阴影 |
| shadow_light | #33000000 | 浅色阴影 |
| shadow_heavy | #80000000 | 重阴影 |
| input_background | #2C2C2E | 输入框背景 |
| button_background | #2C2C2E | 按钮背景 |
| divider_default | #38383A | 分割线 |
| overlay_background | #CC1C1C1E | 覆盖层背景 |
| overlay_bottom | #F21C1C1E | 底部覆盖层 |

## 使用方法

### 1. 使用颜色资源

在 ArkTS 组件中，使用 `$r('app.color.颜色名称')` 引用颜色资源，系统会自动根据当前模式切换对应的颜色值。

```typescript
// 示例：使用颜色资源
Text('Hello World')
  .backgroundColor($r('app.color.card_background'))
  .fontColor($r('app.color.text_primary'))
```

### 2. 使用 AppColors 工具类

提供了 `AppColors` 工具类，方便在代码中引用颜色资源。

```typescript
import { AppColors } from '../utils/AppColors';

// 使用
Text('Hello')
  .backgroundColor(AppColors.card_background)
  .fontColor(AppColors.text_primary)
```

### 3. 主题管理

使用 `ThemeManager` 管理应用的主题模式。

```typescript
import { themeManager, ThemeMode } from '../utils/ThemeManager';

// 获取当前主题模式
const mode = themeManager.getCurrentThemeMode();

// 设置主题模式
await themeManager.setThemeMode('dark');

// 检查是否为深色模式
if (themeManager.isDarkMode()) {
  // 深色模式逻辑
}

// 监听主题变化
themeManager.onThemeChange((isDark: boolean) => {
  console.log('Theme changed:', isDark);
});
```

### 4. 主题切换组件

提供了现成的主题切换组件 `ThemeSwitcher`，可以在设置页面使用。

```typescript
import { ThemeSwitcher } from '../components/ThemeSwitcher';

// 在页面中使用
Column() {
  ThemeSwitcher()
}
```

## 适配步骤

### 第一步：修改颜色引用

将所有硬编码的颜色值替换为颜色资源引用。

```typescript
// 修改前
.backgroundColor('#F5F6F8')
.fontColor('#111827')

// 修改后
.backgroundColor($r('app.color.app_background'))
.fontColor($r('app.color.text_primary'))
```

### 第二步：使用 AppColors 工具类（推荐）

在文件顶部导入 `AppColors`：

```typescript
import { AppColors } from '../utils/AppColors';
```

然后替换所有颜色引用：

```typescript
.backgroundColor(AppColors.app_background)
.fontColor(AppColors.text_primary)
```

### 第三步：测试不同模式

1. 使用 `ThemeSwitcher` 组件切换主题
2. 验证所有页面在浅色、深色、自动模式下的显示效果
3. 检查文字对比度、边框、阴影等细节

## 颜色对照表

| 用途 | 浅色模式 | 深色模式 |
|-----|---------|---------|
| 主背景 | #F5F6F8 | #000000 |
| 卡片背景 | #FFFFFF | #1C1C1E |
| 主要文字 | #111827 | #FFFFFF |
| 次要文字 | #6B7280 | #EBEBF5 |
| 边框 | #E5E5EA | #38383A |
| 分割线 | #E5E5EA | #38383A |
| 主色调 | #607AFB | #0A84FF |

## 注意事项

1. **颜色格式**：color.json 中的颜色值必须使用 `#RRGGBB` 或 `#AARRGGBB` 格式，不支持 `rgba()` 格式
   - `#AARRGGBB` 格式：AA=透明度（00-FF），RR=红色，GG=绿色，BB=蓝色
   - 转换公式：`alpha * 255` = 十六进制透明度值
   - 示例：`rgba(96, 122, 251, 0.15)` → `#26607AFB`
     - 0.15 × 255 = 38 → 0x26
     - 96 → 0x60
     - 122 → 0x7A
     - 251 → 0xFB
2. **渐变色**：渐变色不能通过资源配置自动切换，需要根据主题模式动态设置
3. **图片资源**：图片资源可以通过在 `resources/dark/media/` 目录下放置同名深色版本图片来自动切换
4. **透明度**：深色模式下的透明度值可能需要调整，建议使用预定义的颜色资源
5. **测试覆盖**：确保在所有主要页面都进行了深色模式适配测试

## 参考资源

- [HarmonyOS Next 深色模式适配官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-dark-light-color-adaptation)
- [深色模式适配最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-dark-mode-adaptation)
