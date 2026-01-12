---
name: harmony-next
description: HarmonyOS NEXT应用开发专家技能。提供完整的鸿蒙原生应用开发支持，包括ArkTS语言、ArkUI框架、DevEco Studio环境搭建、UI组件开发、状态管理、路由导航、数据持久化、网络请求和性能优化。适用于：创建新HarmonyOS应用、开发ArkUI界面、实现UIAbility组件、使用ArkTS特性、处理应用生命周期、多设备适配、性能调优、调试和打包发布。
---

# HarmonyOS NEXT 开发

## 核心技术栈

- **开发语言**: ArkTS (基于TypeScript扩展的强类型语言)
- **UI框架**: ArkUI (声明式UI开发框架)
- **开发工具**: DevEco Studio 4.0+
- **支持API**: API 9-12+

## 快速开始

### 环境搭建

1. 下载DevEco Studio: https://developer.huawei.com/consumer/cn/deveco-studio/
2. 安装Node.js (推荐v16+)
3. 配置环境变量
4. 创建新项目: `File > New > Create Project`

### 项目结构

```
project/
├── AppScope/              # 全局配置
│   ├── app.json5         # 应用配置
│   └── resources/        # 全局资源
├── entry/                 # 主模块
│   ├── src/main/
│   │   ├── ets/          # ArkTS源码
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets
│   │   │   └── pages/    # 页面文件
│   │   ├── resources/    # 模块资源
│   │   └── module.json5  # 模块配置
│   ├── build-profile.json5
│   └── hvigor/           # 构建配置
├── oh_modules/           # 依赖库
└── oh-package.json5      # 包配置
```

## ArkTS 基础

### 强类型特性

```typescript
// 必需属性
name: string

// 可选属性
age?: number

// 联合类型
status: 'loading' | 'success' | 'error'

// 联合类型示例
type: 'text' | 'image' | 'video'

// 数组类型
items: string[]

// 对象类型
user: { name: string; age: number }

// 联合类型数组
items: Array<{ id: number; value: string }>
```

### 状态管理

#### @State 装饰器

```typescript
@State count: number = 0
```

#### @Prop 装饰器

```typescript
// 父组件传递数据给子组件
@Prop title: string
```

#### @Link 装饰器

```typescript
// 双向数据绑定
@Link count: number
```

#### @Provide 和 @Consume

```typescript
// 跨组件层级传递数据
@Provide count: number = 0
@Consume count: number
```

#### @Observed 和 @ObjectLink

```typescript
// 深度监听对象变化
@Observed class User { name: string; age: number }
@ObjectLink user: User
```

## ArkUI 组件开发

### 基础组件

```typescript
// 文本
Text('Hello World')

// 按钮
Button('Click me')
  .onClick(() => {
    console.log('Button clicked')
  })

// 图片
Image($r('app.media.icon'))
  .width(100)
  .height(100)

// 输入框
TextInput({ placeholder: 'Enter text' })
  .width('100%')
  .onChange((value) => {
    console.log(value)
  })
```

### 布局组件

```typescript
// 列布局 (垂直)
Column() {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')

// 行布局 (水平)
Row() {
  Text('Left')
  Text('Right')
}
.width('100%')

// 弹性布局
Flex({ direction: FlexDirection.Row }) {
  Text('Item 1').flexGrow(1)
  Text('Item 2').flexGrow(1)
}

// 栅格布局
Grid() {
  GridItem() { Text('Cell 1') }
  GridItem() { Text('Cell 2') }
}
.columnsTemplate('1fr 1fr')
.rowsTemplate('1fr 1fr')

// 列表
List() {
  ForEach(this.items, (item: string) => {
    ListItem() {
      Text(item)
    }
  })
}

// 滚动容器
Scroll() {
  Column() {
    Text('Content')
  }
}
.scrollable(ScrollDirection.Vertical)
```

### 条件渲染

```typescript
// if-else
if (this.isShow) {
  Text('Show content')
} else {
  Text('Hidden content')
}

// 三元表达式
Text(this.isShow ? 'Show' : 'Hidden')

// switch
switch (this.type) {
  case 'text':
    Text('Text content')
    break
  case 'image':
    Image($r('app.media.icon'))
    break
}
```

### 循环渲染

```typescript
ForEach(this.items, (item: string, index: number) => {
  ListItem() {
    Text(`${index}: ${item}`)
  }
}, (item: string) => item)
```

## UIAbility 生命周期

```typescript
export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    // Ability创建时调用
    console.log('onCreate')
  }

  onDestroy() {
    // Ability销毁时调用
    console.log('onDestroy')
  }

  onWindowStageCreate(windowStage) {
    // 窗口创建时调用
    windowStage.loadContent('pages/Index')
  }

  onWindowStageDestroy() {
    // 窗口销毁时调用
  }

  onForeground() {
    // Ability切换到前台
  }

  onBackground() {
    // Ability切换到后台
  }
}
```

## 页面路由

### 路由跳转

```typescript
import router from '@ohos.router'

// 跳转到新页面
router.pushUrl({
  url: 'pages/SecondPage',
  params: { id: 1 }
})

// 替换当前页面
router.replaceUrl({
  url: 'pages/SecondPage'
})

// 返回上一页
router.back()

// 返回并传递参数
router.back({
  url: 'pages/Index',
  params: { result: 'success' }
})
```

### 获取路由参数

```typescript
onPageShow() {
  const params = router.getParams() as { id: number }
  console.log(params.id)
}
```

## 数据持久化

### Preferences (轻量级存储)

```typescript
import preferences from '@ohos.data.preferences'

// 获取Preferences实例
const preferences = await preferences.getPreferences(context, 'myStore')

// 保存数据
await preferences.put('key', 'value')
await preferences.flush()

// 读取数据
const value = await preferences.get('key', 'default')
```

### 关系型数据库

```typescript
import relationalStore from '@ohos.data.relationalStore'

// 创建数据库
const store = await relationalStore.getRdbStore(context, {
  name: 'MyDatabase.db',
  securityLevel: relationalStore.SecurityLevel.S1
})

// 创建表
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)'
)

// 插入数据
await store.insert('users', { name: 'John' })

// 查询数据
const resultSet = await store.querySql('SELECT * FROM users')
```

## 网络请求

### HTTP 请求

```typescript
import http from '@ohos.net.http'

// 创建请求对象
const httpRequest = http.createHttp()

// 发送GET请求
const response = await httpRequest.request(
  'https://api.example.com/data',
  {
    method: http.RequestMethod.GET,
    header: { 'Content-Type': 'application/json' }
  }
)

// 发送POST请求
const response = await httpRequest.request(
  'https://api.example.com/data',
  {
    method: http.RequestMethod.POST,
    header: { 'Content-Type': 'application/json' },
    extraData: JSON.stringify({ key: 'value' })
  }
)

// 销毁请求对象
httpRequest.destroy()
```

## 资源引用

```typescript
// 引用字符串资源
$r('app.string.app_name')

// 引用颜色资源
$r('app.color.primary')

// 引用图片资源
$r('app.media.icon')

// 引用样式资源
$r('app.style.title_style')
```

## 动画

```typescript
// 属性动画
Text('Animated Text')
  .opacity(this.opacityValue)
  .onClick(() => {
    animateTo({ duration: 300 }, () => {
      this.opacityValue = this.opacityValue === 1 ? 0 : 1
    })
  })

// 显式动画
Button('Animate')
  .onClick(() => {
    animateTo({
      duration: 1000,
      curve: Curve.EaseInOut
    }, () => {
      this.width = this.width === 100 ? 200 : 100
    })
  })

// 组件转场
if (this.isShow) {
  Text('Content')
    .transition({
      type: TransitionType.All,
      opacity: 0,
      translate: { x: 100 }
    })
}
```

## 性能优化

### 状态优化

```typescript
// 使用@State而非普通属性
@State data: string[] = []

// 使用@Prop替代@State传递只读数据
@Prop items: string[]

// 使用@Link实现双向绑定
@Link count: number

// 使用@Provide/@Consume跨层级传递
@Provide globalData: string = ''
@Consume globalData: string
```

### 组件优化

```typescript
// 使用@Builder构建器减少重复代码
@Builder BuildHeader(title: string) {
  Text(title)
    .fontSize(20)
    .fontWeight(FontWeight.Bold)
}

// 使用@Reusable装饰器实现组件复用
@Reusable
struct ReusableItem {
  @Prop content: string

  build() {
    Text(this.content)
  }
}
```

### 渲染优化

```typescript
// 使用LazyForEach延迟加载
LazyForEach(this.dataSource, (item: string) => {
  ListItem() {
    Text(item)
  }
}, (item: string) => item)

// 使用if替代display:none
if (this.isShow) {
  Text('Content')
}

// 使用key优化列表渲染
ForEach(this.items, (item: Item) => {
  ListItem() {
    Text(item.name)
  }
}, (item: Item) => item.id.toString())
```

## 权限管理

### 配置权限

在 `module.json5` 中添加权限声明：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

### 动态请求权限

```typescript
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'

// 请求权限
const permissions = ['ohos.permission.INTERNET']
const atManager = abilityAccessCtrl.createAtManager()
await atManager.requestPermissionsFromUser(context, permissions)

// 检查权限状态
const status = await atManager.checkAccessToken(tokenID, 'ohos.permission.INTERNET')
```

## 调试技巧

### 日志输出

```typescript
hilog.info(0x0000, 'TAG', 'Info message')
hilog.debug(0x0000, 'TAG', 'Debug message')
hilog.warn(0x0000, 'TAG', 'Warning message')
hilog.error(0x0000, 'TAG', 'Error message')
```

### DevEco Studio 调试

1. 设置断点
2. 点击 Debug 按钮
3. 使用 Debug 工具栏控制执行
4. 查看变量值和调用栈

## 打包发布

### 构建HAP包

1. `Build > Build Hap(s)/APP(s) > Build Hap(s)`
2. 在 `entry/build/default/outputs/default/` 找到 HAP 文件

### 发布到应用市场

1. 登录华为开发者联盟
2. 创建应用
3. 上传 HAP 包
4. 填写应用信息
5. 提交审核

## 常见问题

### 性能问题

- 使用状态变量时注意范围，避免不必要的重渲染
- 列表数据量大时使用 LazyForEach
- 图片使用适当尺寸和格式

### 内存泄漏

- 及时销毁订阅和定时器
- 使用 WeakRef 避免循环引用
- 页面销毁时清理资源

### 多设备适配

- 使用资源限定符适配不同屏幕尺寸
- 使用百分比或 vp 单位
- 使用 Grid 和 Flex 布局实现响应式设计

## 参考资料

- [HarmonyOS NEXT官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/application-dev-guide-V5)
- [ArkTS语言规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-get-started-V5)
- [ArkUI组件参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/arkui-ts-V5)
