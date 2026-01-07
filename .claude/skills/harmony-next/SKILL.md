---
name: harmony-next
description: HarmonyOS Next 应用开发助手,用于基于 API 12+ 创建和开发纯鸿蒙原生应用。适用场景:(1)创建 HarmonyOS Next 项目和页面,(2)使用 ArkTS 开发组件和业务逻辑,(3)实现 ArkUI 界面布局和交互,(4)状态管理和路由导航,(5)集成系统 API(网络、存储、媒体等),(6)调试和性能优化。当用户提及鸿蒙、HarmonyOS、ArkTS、ArkUI、DevEco Studio 相关开发任务时触发。
---

# HarmonyOS Next 应用开发

HarmonyOS Next (鸿蒙星河版) 是华为推出的纯血鸿蒙操作系统,完全基于自研鸿蒙内核,不再兼容 Android。本 skill 提供基于 API 12+ 的完整开发指南。

## 核心概念

### 开发语言和框架

- **ArkTS**: HarmonyOS 开发语言,基于 TypeScript 扩展,强类型、声明式
- **ArkUI**: 声明式 UI 框架,采用组件化开发模式
- **DevEco Studio**: 官方 IDE,基于 IntelliJ IDEA 定制

### Stage 模型架构

Stage 模型是 HarmonyOS Next 的应用模型,核心概念:

- **UIAbility**: 应用的 UI 入口,包含生命周期管理
- **AbilityStage**: 应用模块级别的生命周期管理
- **WindowStage**: 窗口管理,与 UIAbility 配合使用
- **ExtensionAbility**: 扩展能力,如 Widget、ServiceExtension

## 项目结构

```
HarmonyOSApp/
├── AppScope/                     # 应用全局配置
│   ├── app.json5                # 应用配置(bundleName, versionCode等)
│   └── resources/               # 全局资源
├── entry/                       # 主模块(HAP)
│   ├── src/main/
│   │   ├── ets/                # ArkTS 源码
│   │   │   ├── entryability/   # UIAbility 入口
│   │   │   │   └── EntryAbility.ets
│   │   │   ├── pages/          # 页面
│   │   │   │   └── Index.ets
│   │   │   ├── components/     # 自定义组件
│   │   │   ├── common/         # 公共工具类
│   │   │   └── viewmodel/      # 数据模型
│   │   ├── resources/          # 资源文件
│   │   │   ├── base/           # 默认资源
│   │   │   ├── en_US/          # 英文资源
│   │   │   └── zh_CN/          # 中文资源
│   │   └── module.json5        # 模块配置
│   └── build-profile.json5     # 构建配置
├── oh_modules/                  # 三方依赖
└── hvigorfile.ts               # 构建脚本
```

## ArkTS 语法要点

**⚠️ 重要**：ArkTS 是 TypeScript 的严格子集，有许多语法限制。详见 `references/arkts-restrictions.md`

### 关键语法限制（必读）

ArkTS **不支持**以下常见 JavaScript/TypeScript 特性：

1. **解构赋值** - `const { a, b } = obj` ❌
2. **对象字面量无类型** - `const obj = {}` 必须声明类型 ❌
3. **@Builder 中使用 switch** - 只能用 if-else ❌
4. **build() 中声明变量** - 只能写 UI 组件 ❌
5. **静态方法用 this** - 必须用类名 ❌
6. **as const 断言** - 改用 enum 或联合类型 ❌

```typescript
// ❌ 错误示例
const { isValid } = result;  // 不支持解构
this.data = {};  // 对象字面量无类型
const items = list.map(x => ({ id: x.id }));  // map 返回对象字面量

// ✅ 正确写法
const isValid = result.isValid;  // 直接访问
const emptyData: Record<string, string> = {};  // 显式类型
this.data = emptyData;
const items: Item[] = [];  // forEach + 显式类型
list.forEach(x => {
  const item: Item = { id: x.id };
  items.push(item);
});
```

完整限制和解决方案请查看 **`references/arkts-restrictions.md`**

### 状态管理装饰器

```typescript
// @State - 组件内部状态,变化触发 UI 刷新
@State message: string = 'Hello';

// @Prop - 父传子单向同步
@Prop title: string;

// @Link - 父子双向绑定
@Link count: number;

// @Provide/@Consume - 跨层级传递
@Provide('theme') theme: string = 'dark';
@Consume('theme') theme: string;

// @Observed/@ObjectLink - 嵌套对象响应式
@Observed
class Person {
  name: string = '';
  age: number = 0;
}
@ObjectLink person: Person;

// @StorageLink/@StorageProp - 应用全局状态
@StorageLink('token') token: string = '';
```

**性能建议**: 父子组件场景优先使用 @State+@Link,避免不必要的 @Provide/@Consume

### 自定义组件

```typescript
@Component
export struct CustomCard {
  @Prop title: string = '';
  @State isExpanded: boolean = false;
  private content?: string;
  private onTap?: () => void;

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Image(this.isExpanded ? $r('app.media.arrow_up') : $r('app.media.arrow_down'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(() => {
        this.isExpanded = !this.isExpanded;
        this.onTap?.();
      })

      if (this.isExpanded && this.content) {
        Text(this.content)
          .margin({ top: 12 })
          .fontSize(14)
      }
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}
```

## 常用组件和布局

### 容器组件

```typescript
// Column - 垂直布局
Column({ space: 10 }) {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')
.alignItems(HorizontalAlign.Center)

// Row - 水平布局
Row({ space: 10 }) {
  Button('Left')
  Button('Right')
}
.justifyContent(FlexAlign.SpaceBetween)

// Stack - 层叠布局
Stack({ alignContent: Alignment.Bottom }) {
  Image($r('app.media.bg'))
  Text('标题').backgroundColor('#80000000')
}

// Flex - 弹性布局
Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
  Text('Item 1').flexGrow(1)
  Text('Item 2').flexShrink(1)
}
```

### 列表组件

```typescript
// List - 列表(支持懒加载)
List({ space: 10 }) {
  ForEach(this.dataList, (item: DataItem) => {
    ListItem() {
      Text(item.title)
    }
  })
}
.width('100%')
.height('100%')
.edgeEffect(EdgeEffect.Spring)

// Grid - 网格
Grid() {
  ForEach(this.items, (item: string) => {
    GridItem() {
      Text(item)
    }
  })
}
.columnsTemplate('1fr 1fr 1fr')
.rowsGap(10)
.columnsGap(10)

// Swiper - 轮播
Swiper() {
  ForEach(this.images, (img: string) => {
    Image(img)
  })
}
.autoPlay(true)
.interval(3000)
.indicator(true)
```

### Tabs 组件

```typescript
@Entry
@Component
struct TabsExample {
  @State currentIndex: number = 0;

  build() {
    Tabs({ index: this.currentIndex }) {
      TabContent() {
        Text('首页内容')
      }.tabBar('首页')

      TabContent() {
        Text('发现内容')
      }.tabBar('发现')

      TabContent() {
        Text('我的')
      }.tabBar('我的')
    }
    .vertical(false)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
```

## 路由导航

### Navigation 组件(推荐)

Navigation 是 HarmonyOS Next 推荐的路由方案,支持深层导航栈:

```typescript
@Entry
@Component
struct MainPage {
  private navStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.navStack) {
      Column() {
        Button('跳转到详情')
          .onClick(() => {
            this.navStack.pushPath({ name: 'DetailPage', param: { id: 123 } });
          })
      }
    }
    .title('首页')
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: Object) {
    if (name === 'DetailPage') {
      DetailPage({ params: param })
    }
  }
}

@Component
export struct DetailPage {
  private navStack?: NavPathStack;
  private params?: Object;

  build() {
    NavDestination() {
      Column() {
        Text('详情页')
        Button('返回')
          .onClick(() => {
            this.navStack?.pop();
          })
      }
    }
    .title('详情')
  }
}
```

配置路由表 `route_map.json`:

```json
{
  "routerMap": [
    {
      "name": "DetailPage",
      "pageSourceFile": "src/main/ets/pages/DetailPage.ets",
      "buildFunction": "DetailPageBuilder"
    }
  ]
}
```

### Router API(传统方式)

```typescript
import router from '@ohos.router';

// 跳转
router.pushUrl({
  url: 'pages/DetailPage',
  params: { id: 123, name: 'example' }
});

// 返回
router.back();

// 替换
router.replaceUrl({ url: 'pages/HomePage' });

// 获取参数
@State params: Object = router.getParams();
```

## UIAbility 生命周期

```typescript
import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  // 1. 创建时回调
  onCreate(want, launchParam) {
    console.info('[EntryAbility] onCreate');
    // 初始化应用全局资源
  }

  // 2. 窗口阶段创建
  onWindowStageCreate(windowStage: window.WindowStage) {
    console.info('[EntryAbility] onWindowStageCreate');

    // 设置主窗口并加载页面
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('Failed to load content', JSON.stringify(err));
        return;
      }
      console.info('Succeeded in loading content');
    });

    // 订阅窗口事件
    windowStage.on('windowStageEvent', (data) => {
      console.info('windowStageEvent:', data);
    });
  }

  // 3. 前台
  onForeground() {
    console.info('[EntryAbility] onForeground');
    // 申请系统资源,如定位、通知等
  }

  // 4. 后台
  onBackground() {
    console.info('[EntryAbility] onBackground');
    // 释放资源,保存状态
  }

  // 5. 窗口阶段销毁
  onWindowStageDestroy() {
    console.info('[EntryAbility] onWindowStageDestroy');
    // 释放 UI 资源
  }

  // 6. 销毁
  onDestroy() {
    console.info('[EntryAbility] onDestroy');
    // 释放所有资源
  }
}
```

## 网络请求

```typescript
import http from '@ohos.net.http';

// 封装网络请求
class HttpUtil {
  static async request(url: string, method: http.RequestMethod, data?: Object): Promise<Object> {
    let httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url, {
        method: method,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: data
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string);
      } else {
        throw new Error(`Request failed: ${response.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  static get(url: string): Promise<Object> {
    return this.request(url, http.RequestMethod.GET);
  }

  static post(url: string, data: Object): Promise<Object> {
    return this.request(url, http.RequestMethod.POST, data);
  }
}

// 使用示例
HttpUtil.get('https://api.example.com/users')
  .then((data) => {
    console.info('Success:', JSON.stringify(data));
  })
  .catch((err) => {
    console.error('Error:', err);
  });
```

## 数据持久化

### Preferences(轻量级键值存储)

适用于 token、配置项等简单数据:

```typescript
import preferences from '@ohos.data.preferences';

class PreferencesUtil {
  private static pref: preferences.Preferences;

  static async init(context) {
    this.pref = await preferences.getPreferences(context, 'myStore');
  }

  static async put(key: string, value: preferences.ValueType) {
    await this.pref.put(key, value);
    await this.pref.flush(); // 持久化到磁盘
  }

  static async get(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
    return await this.pref.get(key, defaultValue);
  }

  static async delete(key: string) {
    await this.pref.delete(key);
    await this.pref.flush();
  }

  static async clear() {
    await this.pref.clear();
    await this.pref.flush();
  }
}

// 使用
await PreferencesUtil.put('username', 'Alice');
let username = await PreferencesUtil.get('username', '');
```

### 关系型数据库(推荐使用参考文档)

详见 `references/data-persistence.md`

## 动画效果

### 属性动画

```typescript
@State scaleValue: number = 1;

Image($r('app.media.icon'))
  .scale({ x: this.scaleValue, y: this.scaleValue })
  .animation({
    duration: 300,
    curve: Curve.EaseInOut,
    iterations: 1
  })
  .onClick(() => {
    this.scaleValue = this.scaleValue === 1 ? 1.2 : 1;
  })
```

### 显式动画

```typescript
Button('动画')
  .onClick(() => {
    animateTo({
      duration: 500,
      curve: Curve.Smooth
    }, () => {
      this.rotateAngle += 90;
      this.opacity = this.opacity === 1 ? 0.5 : 1;
    })
  })
```

### 转场动画

```typescript
@State isShow: boolean = true;

if (this.isShow) {
  Text('显示/隐藏')
    .transition({
      type: TransitionType.Insert,
      opacity: 0,
      translate: { y: 100 }
    })
    .transition({
      type: TransitionType.Delete,
      opacity: 0,
      scale: { x: 0, y: 0 }
    })
}
```

## 开发最佳实践

### 1. 性能优化

- 避免在 `build()` 中执行耗时操作
- 使用 `LazyForEach` 实现列表懒加载
- 合理使用状态管理,减少不必要的 UI 刷新
- 图片资源优化(使用合适尺寸,考虑 WebP 格式)

### 2. 代码规范

- 组件命名使用大驼峰: `CustomButton`
- 变量和函数使用小驼峰: `userName`, `getUserInfo()`
- 常量使用大写下划线: `MAX_COUNT`
- 使用 TypeScript 严格类型检查

### 3. 调试技巧

- 使用 `console.info/error/debug` 输出日志
- DevEco Studio 断点调试
- Previewer 实时预览 UI
- 连接真机或模拟器调试

### 4. 安全注意事项

- 敏感信息不要硬编码,使用 Preferences 加密存储
- 网络请求使用 HTTPS
- 校验用户输入,防止注入攻击
- 权限申请遵循最小化原则

## 参考资源

详细文档请查看:

- **`references/arkts-restrictions.md`** - ⚠️ ArkTS 语法限制和常见编译错误（必读）
- `references/arkui-components.md` - ArkUI 组件完整清单和详细用法
- `references/system-apis.md` - 系统 API 使用指南(媒体、设备、通知等)
- `references/data-persistence.md` - 数据持久化方案(数据库、文件等)
- `references/best-practices.md` - 开发最佳实践和常见问题

## 工具脚本

- `scripts/create_page.py` - 快速创建页面模板
- `scripts/create_component.py` - 创建自定义组件模板

## 重要提示

1. HarmonyOS Next 不支持 Android 应用,需使用 ArkTS 重新开发
2. API 12+ 为当前主流版本(2025年)
3. **⚠️ ArkTS 语法严格限制**（详见 `references/arkts-restrictions.md`）：
   - 不支持解构赋值 `const { a } = obj` ❌
   - 对象字面量 `{}` 必须有显式类型声明 ❌
   - @Builder 方法只能用 if-else，不能用 switch ❌
   - build() 方法不能声明变量 ❌
   - 静态方法调用用类名，不能用 this ❌
4. 组件必须使用 `@Component` 装饰器
5. 入口页面使用 `@Entry` 装饰器
6. 状态变量必须初始化
7. UI 操作只能在主线程执行
8. Navigation 路由方案是长期演进方向,优先使用
9. **遇到编译错误 10605038/10605074 等，请查阅 `references/arkts-restrictions.md`**
