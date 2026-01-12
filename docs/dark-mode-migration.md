# 深色模式适配快速迁移指南

## 迁移步骤

### 1. 导入工具类

在需要适配深色模式的页面文件顶部导入：

```typescript
import { AppColors } from '../utils/AppColors';
```

### 2. 替换颜色值

将硬编码的颜色值替换为 `AppColors` 常量。

#### 常用颜色映射

| 用途 | 原值（浅色） | AppColors 常量 |
|-----|------------|---------------|
| 应用背景 | #F5F6F8 | AppColors.app_background |
| 页面背景 | #F2F2F7 | AppColors.page_background |
| 卡片背景 | #FFFFFF | AppColors.card_background |
| 主要文字 | #111827 | AppColors.text_primary |
| 次要文字 | #6B7280 | AppColors.text_secondary |
| 占位符/图标 | #9CA3AF | AppColors.text_tertiary |
| 链接/按钮 | #007AFF | AppColors.text_link |
| 主色调 | #607AFB | AppColors.primary |
| 边框 | #E5E5EA | AppColors.border_default |
| 分割线 | #E5E5EA | AppColors.divider_default |
| 输入框背景 | #E5E7EB | AppColors.input_background |
| 按钮背景 | #F3F4F6 | AppColors.button_background |

#### 替换示例

```typescript
// 替换前
Column() {
  Text('Title')
    .fontSize(28)
    .fontWeight(FontWeight.Bold)
    .fontColor('#111827')

  Text('Description')
    .fontSize(14)
    .fontColor('#6B7280')
}
.width('100%')
.padding(16)
.backgroundColor('#FFFFFF')
.borderRadius(12)

// 替换后
Column() {
  Text('Title')
    .fontSize(28)
    .fontWeight(FontWeight.Bold)
    .fontColor(AppColors.text_primary)

  Text('Description')
    .fontSize(14)
    .fontColor(AppColors.text_secondary)
}
.width('100%')
.padding(16)
.backgroundColor(AppColors.card_background)
.borderRadius(12)
```

### 3. 处理渐变色

渐变色需要根据主题模式动态设置。在组件中添加主题状态：

```typescript
import { themeManager } from '../utils/ThemeManager';

@Entry
@Component
struct MyComponent {
  @State isDark: boolean = false;

  aboutToAppear() {
    this.isDark = themeManager.isDarkMode();
    
    // 监听主题变化
    themeManager.onThemeChange((isDark: boolean) => {
      this.isDark = isDark;
    });
  }

  build() {
    Row() {
      Text('Gradient Text')
    }
    .width('100%')
    .height(44)
    .linearGradient({
      angle: 135,
      colors: this.isDark 
        ? [['#0A84FF', 0.0], ['#5856D6', 1.0]]  // 深色渐变
        : [['#607AFB', 0.0], ['#9333EA', 1.0]]  // 浅色渐变
    })
  }
}
```

### 4. 批量替换脚本

可以使用以下正则表达式批量查找替换：

**查找背景色：**
```
\.backgroundColor\('#[0-9A-Fa-f]{6}'\)
```

**替换为颜色资源（需手动确认）：**
```
.backgroundColor(AppColors.app_background)
```

**查找文字颜色：**
```
\.fontColor\('#[0-9A-Fa-f]{6}'\)
```

## 完整示例

### Index.ets 页面适配示例

```typescript
import router from '@ohos.router';
import { AppColors } from '../utils/AppColors';
import { themeManager } from '../utils/ThemeManager';

@Entry
@Component
struct Index {
  @State searchText: string = '';
  @State isDark: boolean = false;

  aboutToAppear() {
    this.isDark = themeManager.isDarkMode();
    themeManager.onThemeChange((isDark: boolean) => {
      this.isDark = isDark;
    });
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SearchBar()
        this.ShortcutsList()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.app_background)

      this.BottomNavigation()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Row() {
      Text('My Shortcuts')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text_primary)

      Button() {
        Row() {
          Text('+')
            .fontSize(24)
            .fontColor(AppColors.primary)
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor(AppColors.primary_faint)
      .borderRadius(999)
      .width(40)
      .height(40)
      .stateEffect(true)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 48, bottom: 8 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  SearchBar() {
    Row() {
      Row() {
        Text('\uD83D\uDD0E')
          .fontSize(20)
          .fontColor(AppColors.text_tertiary)
          .margin({ left: 16, right: 12 })

        TextInput({ placeholder: 'Search your library...', text: this.searchText })
          .placeholderColor(AppColors.text_secondary)
          .backgroundColor('transparent')
          .border({ width: 0 })
          .layoutWeight(1)
          .fontSize(14)
          .fontColor(AppColors.text_primary)
          .onChange((value: string) => {
            this.searchText = value;
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor(AppColors.input_background)
      .borderRadius(12)
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 4, color: AppColors.shadow_default, offsetY: 2 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
  }

  // ... 其他方法类似替换
}
```

## 检查清单

适配完成后，检查以下项目：

- [ ] 所有 `.backgroundColor()` 已替换为 AppColors
- [ ] 所有 `.fontColor()` 已替换为 AppColors
- [ ] 所有边框颜色 `.border({ color: ... })` 已替换
- [ ] 所有阴影颜色 `.shadow({ color: ... })` 已替换
- [ ] 渐变色已根据主题动态设置
- [ ] 在浅色模式下测试所有页面
- [ ] 在深色模式下测试所有页面
- [ ] 在自动模式下测试（切换系统主题）
- [ ] 文字对比度符合无障碍标准
- [ ] 边框和阴影在深色模式下清晰可见

## 常见问题

### Q: 渐变色如何适配？

A: 渐变色需要在组件中添加 `isDark` 状态，根据主题状态返回不同的渐变配置。参考"处理渐变色"部分。

### Q: 图片如何适配？

A: 在 `entry/src/main/resources/dark/media/` 目录下放置同名深色版本图片，系统会自动切换。

### Q: 半透明颜色如何处理？

A: 使用预定义的颜色资源（如 `primary_faint`、`shadow_light` 等），它们已经针对深浅模式进行了优化。

### Q: 第三方库的样式如何适配？

A: 如果第三方库支持主题配置，使用颜色资源传入；否则需要通过 CSS 变量或其他方式动态设置。

## 下一步

适配完成后：

1. 运行应用并切换主题模式测试
2. 检查每个页面的显示效果
3. 优化深色模式下的视觉体验
4. 提交代码并创建 Pull Request

需要帮助？查看完整的 [深色模式适配指南](./dark-mode-adapter.md)。
