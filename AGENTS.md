# AI 代理开发指南

本文件包含 HarmonyOS Next 自动化工作流应用的开发规范、构建命令和代码风格指南。

## 环境要求

- **DevEco Studio**: 5.0.3+
- **HarmonyOS SDK**: API 21+ (6.0.1)
- **开发语言**: ArkTS (TypeScript 超集)
- **UI 框架**: ArkUI 声明式框架
- **测试框架**: Hypium (@ohos/hypium, @ohos/hamock)

## 构建命令

### 基础构建
```bash
# 清理构建产物
hvigor clean

# 构建项目（Debug）
hvigor assembleHap --mode debug

# 构建项目（Release）
hvigor assembleHap --mode release

# 编译并安装到设备
hvigor installHap
```

### 代码检查
```bash
# 运行 ESLint 检查
hvigor lint

# 修复可自动修复的问题
hvigor lint --fix
```

### 测试命令
```bash
# 运行所有单元测试
hvigor test

# 运行本地单元测试
hvigor test --module entry --type local

# 运行 UI 自动化测试
hvigor test --module entry --type ui

# 运行特定测试文件
hvigor test --class entry/src/test/LocalUnit.test.ets

# 运行特定测试用例（支持正则匹配）
hvigor test --filter "assertContain"
```

在 DevEco Studio 中：
- `Shift + F10` 运行应用
- `Ctrl + Shift + F10` 调试应用
- 右键测试文件选择 "Run 'xxx'" 运行单个测试

## HarmonyOS Next 最新开发知识 (2025)

### ArkTS 核心特性
- **声明式 UI**: 使用 `@Component` 和 `@Builder` 装饰器定义 UI
- **响应式状态**: 使用 `@State`、`@Prop`、`@Link`、`@StorageLink` 管理状态
- **组件生命周期**: `aboutToAppear()`、`aboutToDisappear()`、`onPageShow()` 等
- **原生性能**: ArkTS 编译为原生代码，执行效率接近原生应用
- **TypeScript 兼容**: 完全继承 TS 类型系统，支持泛型、接口、枚举

### ArkUI 框架最佳实践
- **组件化开发**: 将大页面拆分为小组件，提高复用性
- **资源引用**: 使用 `$r('app.color.xxx')` 和 `$r('app.string.xxx')` 引用资源
- **布局容器**: 优先使用 Flex、Grid、Stack 等弹性布局
- **性能优化**: 避免不必要的 `@State` 状态，使用 `@Reusable` 组件复用
- **深色模式**: 支持系统主题自动切换，使用语义化颜色变量

### Hypium 测试框架
- **单元测试**: 使用 `describe`、`it`、`expect` 编写测试用例
- **断言方法**: `assertEqual()`、`assertContain()`、`assertTrue()` 等
- **生命周期钩子**: `beforeAll()`、`beforeEach()`、`afterEach()`、`afterAll()`
- **过滤执行**: 使用过滤器参数运行特定测试用例

## 代码风格规范

### 导入顺序
```typescript
// 1. HarmonyOS 系统模块
import router from '@ohos.router';
import { describe, it, expect } from '@ohos/hypium';

// 2. 第三方依赖
import { someLibrary } from 'library-name';

// 3. 应用内部模块（相对路径）
import { IndexPage } from './IndexPage';
import { AppColors } from '../utils/AppColors';
```

### 命名约定
- **组件 (Struct)**: 大驼峰命名，例如 `MacroEditor`、`ShortcutCard`
- **类**: 大驼峰命名，例如 `AppColors`、`DataManager`
- **接口/类型**: 大驼峰命名，例如 `ActionItem`、`ShortcutConfig`
- **方法/函数**: 小驼峰命名，例如 `loadMockData()`、`updateCounts()`
- **变量/属性**: 小驼峰命名，例如 `shortcutId`、`title`
- **常量**: 全大写下划线分隔，但本项目使用静态类属性，如 `AppColors.primary`
- **私有成员**: 无下划线前缀，ArkTS 不支持显式私有关键字
- **资源文件**: 蛇形命名，例如 `page_background`、`text_primary`

### 组件定义规范
```typescript
@Entry          // 仅用于页面入口组件
@Component      // 用于可复用组件
struct ComponentName {
  // 装饰器：状态变量按类型分组
  @State localState: string = '';        // 本地状态
  @Prop readonlyProp: string;            // 只读属性（从父组件传入）
  @Link linkedState: number;            // 双向绑定
  @StorageLink('key') storageState: boolean; // 全局存储

  // 公共方法
  build() {
    Column() {
      // UI 结构
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CustomBuilder(param: string) {
    // 子组件构建器
  }
}
```

### 状态管理规范
- **本地状态**: 使用 `@State`，仅在组件内有效
- **父子通信**: 父传子用 `@Prop`，子传父用 `@Link` 或回调函数
- **全局状态**: 使用 `@StorageLink` 配合 `AppStorage` 管理跨页面状态
- **避免过度响应**: 静态内容不需要用 `@State` 包装

### UI 构建规范
- **链式调用**: 样式方法按类别分组：尺寸 -> 位置 -> 外观 -> 事件
- **语义化命名**: Builder 函数使用描述性名称，如 `TabBarBuilder`、`ShortcutCard`
- **资源引用**: 颜色使用 `AppColors.primary`，字符串使用 `$r('app.string.xxx')`
- **单位使用**: 尺寸使用 `'100%'`、`'48vp'`，字体使用 `fontSize(16)`
- **条件渲染**: 使用 `if`、`else` 语句，避免复杂的三元表达式

### 类型定义规范
```typescript
// 接口定义使用简明描述
interface ActionItem {
  id: number;
  type: 'trigger' | 'action' | 'condition' | 'nested';
  title: string;
  icon: string;
  iconColor: string;
  description?: string;       // 可选属性
  children?: ActionItem[];   // 自引用类型
}

// 枚举用于固定选项
enum ActionType {
  TRIGGER = 'trigger',
  ACTION = 'action',
  CONDITION = 'condition',
  NESTED = 'nested'
}
```

### 错误处理规范
```typescript
// 使用 try-catch 处理异步操作
async loadData() {
  try {
    const data = await fetchSomeData();
    this.processData(data);
  } catch (error) {
    console.error('Load data failed:', error);
    // 显示用户友好的错误提示
    this.showErrorToast('加载数据失败，请重试');
  }
}

// 路由参数获取需要类型检查
aboutToAppear() {
  const params = router.getParams() as Record<string, Object>;
  if (params && params['id']) {
    this.id = params['id'] as string;
  }
}
```

### 注释规范
- **文件头**: 简要说明文件用途（仅在复杂文件中添加）
- **复杂逻辑**: 必须添加注释说明算法思路
- **TODO/FIXME**: 使用 `// TODO: 说明` 或 `// FIXME: 说明` 标记待办项
- **不要注释显而易见的内容**: 如 `// 设置宽度` `.width('100%')`

### 代码格式化
- **缩进**: 使用 2 空格
- **行宽**: 建议不超过 120 字符
- **空行**: 方法之间空 1 行，逻辑块之间空 1 行
- **尾随逗号**: 对象/数组元素使用尾随逗号便于维护

### 性能优化建议
- **懒加载**: 列表使用 `ForEach` 或 `LazyForEach`，大数据集优先后者
- **组件复用**: 使用 `@Reusable` 装饰器标记可复用组件
- **避免不必要渲染**: 状态拆分，只将需要响应的数据用 `@State` 标记
- **计算属性**: 复杂计算使用 getter 方法或 `@Computed`（如果支持）
- **图片优化**: 使用 $media 引用资源，支持多分辨率

### 安全规范
- **不存储敏感信息**: 密码、令牌等使用 Preferences 加密存储
- **输入验证**: 所有用户输入必须验证和清理
- **权限申请**: 使用权限管理 API 动态申请权限
- **网络安全**: HTTPS 通信，证书验证

## 项目结构说明

```
entry/src/main/ets/
├── entryability/       # 应用入口
│   └── EntryAbility.ets
├── pages/              # 页面组件
│   ├── Index.ets      # 首页
│   └── MacroEditor.ets # 编辑器
├── components/         # 可复用组件
│   ├── CommonComponents.ets
│   └── ThemeSwitcher.ets
└── utils/              # 工具类
    └── AppColors.ets   # 颜色常量

entry/src/test/         # 单元测试
entry/src/ohosTest/     # UI 测试
```

## 常见任务

### 添加新页面
1. 在 `entry/src/main/ets/pages/` 创建 `NewPage.ets`
2. 在 `entry/src/main/resources/base/profile/main_pages.json` 注册页面路由
3. 使用 `router.pushUrl({ url: 'pages/NewPage' })` 跳转

### 添加新组件
1. 在 `entry/src/main/ets/components/` 创建 `NewComponent.ets`
2. 使用 `@Component struct NewComponent` 定义
3. 在父组件中导入并使用 `<NewComponent />`

### 运行特定测试
```bash
# 通过类名过滤
hvigor test --class LocalUnit

# 通过测试用例名称过滤
hvigor test --filter "测试用例名称"
```

### 检查代码风格
```bash
# 运行 ESLint
hvigor lint

# 自动修复
hvigor lint --fix
```

## 注意事项

1. **HarmonyOS Next 原生开发**：本项目使用 ArkTS 原生开发，不是 WebView 混合应用
2. **资源管理**：颜色、字符串等资源统一放在 `resources/base/` 目录下
3. **深色模式**：使用语义化颜色变量，支持系统主题自动切换
4. **类型安全**：充分利用 TypeScript 类型检查，避免 `any` 类型
5. **测试覆盖**：重要逻辑必须编写单元测试，使用 hypium 框架

## 参考资料

- [HarmonyOS Next 官方文档](https://developer.huawei.com/consumer/cn/develop/)
- [ArkTS 语言规范](https://developer.huawei.com/consumer/cn/arkts/)
- [Hypium 测试框架指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/unit-test-0000001617625766-V2)
- 项目文档目录：`docs/`
