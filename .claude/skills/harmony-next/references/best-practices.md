# HarmonyOS Next 开发最佳实践

本文档总结 HarmonyOS Next 开发的最佳实践和常见问题解决方案。

## 性能优化

### 1. 组件渲染优化

**避免在 build() 中执行耗时操作**

```typescript
// ❌ 错误示例
@Component
struct BadExample {
  build() {
    Column() {
      // 不要在 build 中进行计算
      Text(this.heavyComputation())
    }
  }

  heavyComputation(): string {
    // 耗时计算
    return 'result';
  }
}

// ✅ 正确示例
@Component
struct GoodExample {
  @State result: string = '';

  aboutToAppear() {
    // 在生命周期中执行
    this.result = this.heavyComputation();
  }

  build() {
    Column() {
      Text(this.result)
    }
  }

  heavyComputation(): string {
    return 'result';
  }
}
```

**使用 LazyForEach 实现列表懒加载**

```typescript
class MyDataSource implements IDataSource {
  private dataArray: string[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): string {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    // 注册监听器
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    // 注销监听器
  }
}

@Component
struct LazyList {
  private data: MyDataSource = new MyDataSource();

  build() {
    List() {
      LazyForEach(this.data, (item: string) => {
        ListItem() {
          Text(item)
        }
      }, (item: string) => item)  // 提供唯一 key
    }
  }
}
```

### 2. 状态管理优化

**最小化状态变量**

```typescript
// ❌ 过度使用 @State
@Component
struct OverStateExample {
  @State firstName: string = '';
  @State lastName: string = '';
  @State fullName: string = '';  // 冗余状态

  build() {
    Column() {
      Text(this.fullName)
    }
  }
}

// ✅ 使用计算属性
@Component
struct OptimizedExample {
  @State firstName: string = '';
  @State lastName: string = '';

  get fullName(): string {
    return `${this.firstName} ${this.lastName}`;
  }

  build() {
    Column() {
      Text(this.fullName)
    }
  }
}
```

**合理选择状态管理方案**

- 父子组件: 使用 `@State` + `@Link`
- 跨多层组件: 使用 `@Provide` + `@Consume`
- 全局状态: 使用 `@StorageLink` 或状态管理库

### 3. 图片资源优化

```typescript
// 使用合适的图片尺寸
Image($r('app.media.thumbnail'))  // 缩略图
  .width(100)
  .height(100)

// 使用 objectFit 避免拉伸
Image(this.imageUrl)
  .objectFit(ImageFit.Cover)

// 异步加载大图
Image(this.largeImage)
  .alt($r('app.media.placeholder'))  // 占位图
  .onComplete(() => {
    console.info('Image loaded');
  })
```

### 4. 网络请求优化

```typescript
// 请求缓存
class RequestCache {
  private cache: Map<string, { data: any, timestamp: number }> = new Map();
  private cacheTimeout: number = 5 * 60 * 1000;  // 5分钟

  async get(url: string, fetcher: () => Promise<any>): Promise<any> {
    const cached = this.cache.get(url);
    const now = Date.now();

    if (cached && (now - cached.timestamp) < this.cacheTimeout) {
      return cached.data;
    }

    const data = await fetcher();
    this.cache.set(url, { data, timestamp: now });
    return data;
  }
}

// 请求并发控制
class RequestQueue {
  private maxConcurrent: number = 3;
  private running: number = 0;
  private queue: Array<() => Promise<any>> = [];

  async add<T>(request: () => Promise<T>): Promise<T> {
    if (this.running >= this.maxConcurrent) {
      await new Promise(resolve => {
        this.queue.push(resolve);
      });
    }

    this.running++;
    try {
      return await request();
    } finally {
      this.running--;
      if (this.queue.length > 0) {
        const next = this.queue.shift();
        next?.();
      }
    }
  }
}
```

## 代码规范

### 命名规范

```typescript
// 组件: 大驼峰
@Component
struct UserProfileCard { }

// 类: 大驼峰
class UserService { }

// 接口: 大驼峰,可选 I 前缀
interface IUserData { }

// 变量和函数: 小驼峰
let userName: string = '';
function getUserInfo() { }

// 常量: 大写下划线
const MAX_RETRY_COUNT: number = 3;
const API_BASE_URL: string = 'https://api.example.com';

// 私有成员: 下划线前缀(可选)
private _internalState: number = 0;
```

### 文件组织

```
src/main/ets/
├── entryability/
│   └── EntryAbility.ets
├── pages/
│   ├── Index.ets
│   └── DetailPage.ets
├── components/
│   ├── common/              # 通用组件
│   │   ├── Button.ets
│   │   └── Card.ets
│   └── business/            # 业务组件
│       └── UserCard.ets
├── viewmodel/               # 数据模型
│   └── UserViewModel.ets
├── services/                # 业务逻辑
│   └── UserService.ets
├── utils/                   # 工具函数
│   ├── HttpUtil.ets
│   └── DateUtil.ets
└── constants/               # 常量定义
    └── AppConstants.ets
```

### 注释规范

```typescript
/**
 * 用户信息组件
 * @param user 用户数据
 * @param onEdit 编辑回调
 */
@Component
export struct UserInfoCard {
  @Prop user: UserData;
  private onEdit?: (user: UserData) => void;

  build() {
    // 实现...
  }
}

/**
 * 获取用户信息
 * @param userId 用户 ID
 * @returns 用户数据
 * @throws ApiError 请求失败时抛出
 */
async function getUserInfo(userId: string): Promise<UserData> {
  // 实现...
}
```

## 常见问题

### 1. 状态不更新

**问题**: 修改了状态变量,但 UI 没有刷新

**原因**: 只有被 `@State` 等装饰器修饰的变量变化才会触发 UI 更新

```typescript
// ❌ 错误
@Component
struct BadExample {
  @State user: User = new User();

  build() {
    Column() {
      Text(this.user.name)
      Button('修改')
        .onClick(() => {
          this.user.name = 'New Name';  // 不会触发更新
        })
    }
  }
}

// ✅ 方案1: 使用 @Observed + @ObjectLink
@Observed
class User {
  name: string = '';
}

@Component
struct GoodExample {
  @State user: User = new User();

  build() {
    Column() {
      Text(this.user.name)
      Button('修改')
        .onClick(() => {
          this.user.name = 'New Name';  // 会触发更新
        })
    }
  }
}

// ✅ 方案2: 重新赋值
@Component
struct AlternativeExample {
  @State user: User = new User();

  build() {
    Column() {
      Text(this.user.name)
      Button('修改')
        .onClick(() => {
          this.user = { ...this.user, name: 'New Name' };
        })
    }
  }
}
```

### 2. 页面跳转参数丢失

**问题**: 使用 router 跳转时参数接收不到

**解决**: 在目标页面的 `aboutToAppear` 中获取参数

```typescript
import router from '@ohos.router';

@Entry
@Component
struct DetailPage {
  @State userId: string = '';

  aboutToAppear() {
    // 在这里获取参数
    const params = router.getParams() as { userId: string };
    this.userId = params?.userId || '';
  }

  build() {
    Column() {
      Text(`User ID: ${this.userId}`)
    }
  }
}
```

### 3. 网络请求跨域问题

**问题**: HTTP 请求被拦截

**解决**: 在 `module.json5` 中配置网络权限

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### 4. 图片加载失败

**问题**: 本地图片显示不出来

**解决方案**:

```typescript
// 使用 $r 引用资源
Image($r('app.media.icon'))  // 正确

// 使用相对路径(不推荐)
Image('resources/base/media/icon.png')  // 可能失败
```

### 5. List 滚动性能差

**问题**: 长列表滚动卡顿

**解决**: 使用 LazyForEach + 组件复用

```typescript
@Component
struct OptimizedList {
  private data: MyDataSource = new MyDataSource();

  build() {
    List() {
      LazyForEach(this.data, (item: string, index: number) => {
        ListItem() {
          // 使用轻量级组件
          Text(item)
            .width('100%')
            .padding(12)
        }
        .reuseId('list-item')  // 启用复用
      }, (item: string) => item)
    }
    .cachedCount(5)  // 缓存数量
  }
}
```

## 安全最佳实践

### 1. 敏感信息存储

```typescript
// ❌ 不要硬编码
const API_KEY = 'sk-1234567890abcdef';

// ✅ 使用 Preferences 存储
import preferences from '@ohos.data.preferences';

async function saveApiKey(context, apiKey: string) {
  let pref = await preferences.getPreferences(context, 'secure');
  await pref.put('api_key', apiKey);
  await pref.flush();
}
```

### 2. 输入验证

```typescript
// 验证邮箱
function validateEmail(email: string): boolean {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

// 验证手机号
function validatePhone(phone: string): boolean {
  const regex = /^1[3-9]\d{9}$/;
  return regex.test(phone);
}

// 防止 XSS
function escapeHtml(text: string): string {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}
```

### 3. 网络安全

```typescript
// 使用 HTTPS
const API_URL = 'https://api.example.com';  // ✅
// const API_URL = 'http://api.example.com';  // ❌

// 验证证书
let httpRequest = http.createHttp();
httpRequest.request(API_URL, {
  method: http.RequestMethod.GET,
  expectDataType: http.HttpDataType.STRING,
  usingProtocol: http.HttpProtocol.HTTP2,  // 使用 HTTP/2
  // 其他配置...
});
```

## 调试技巧

### 1. 日志输出

```typescript
// 使用不同级别的日志
console.debug('调试信息');
console.info('一般信息');
console.warn('警告信息');
console.error('错误信息');

// 格式化输出
console.info('User:', JSON.stringify(user, null, 2));

// 性能计时
console.time('operation');
// 执行操作...
console.timeEnd('operation');
```

### 2. 条件断点

```typescript
function processData(items: DataItem[]) {
  for (let i = 0; i < items.length; i++) {
    // 在 DevEco Studio 中设置条件断点: i === 10
    processItem(items[i]);
  }
}
```

### 3. 使用 Previewer

```typescript
// 提供预览数据
@Component
@Preview
struct UserCardPreview {
  build() {
    UserCard({
      user: {
        name: '张三',
        avatar: $r('app.media.avatar'),
        age: 25
      }
    })
  }
}
```

## 测试建议

### 单元测试

```typescript
import { describe, it, expect } from '@ohos/hypium';

describe('UserService', () => {
  it('should get user info', async () => {
    let service = new UserService();
    let user = await service.getUserInfo('123');
    expect(user.id).assertEqual('123');
  });

  it('should handle error', async () => {
    let service = new UserService();
    try {
      await service.getUserInfo('invalid');
      expect(false).assertTrue();  // 不应该执行到这里
    } catch (err) {
      expect(err).assertInstanceOf(ApiError);
    }
  });
});
```

## 发布注意事项

### 1. 版本管理

```json5
// app.json5
{
  "app": {
    "bundleName": "com.example.app",
    "vendor": "example",
    "versionCode": 1000000,  // 数字版本号,递增
    "versionName": "1.0.0",  // 语义化版本号
    // ...
  }
}
```

### 2. 资源优化

- 压缩图片资源
- 删除未使用的资源
- 使用矢量图(SVG)代替位图
- 启用资源混淆

### 3. 代码混淆

```json5
// build-profile.json5
{
  "buildOption": {
    "arkOptions": {
      "obfuscation": {
        "ruleOptions": {
          "enable": true,
          "files": ["obfuscation-rules.txt"]
        }
      }
    }
  }
}
```

## 性能监控

```typescript
// 监控页面加载时间
@Entry
@Component
struct PerformanceMonitor {
  private loadStartTime: number = 0;

  aboutToAppear() {
    this.loadStartTime = Date.now();
  }

  onPageShow() {
    const loadTime = Date.now() - this.loadStartTime;
    console.info(`Page load time: ${loadTime}ms`);

    // 上报性能数据
    this.reportPerformance('page_load', loadTime);
  }

  reportPerformance(metric: string, value: number) {
    // 上报到分析平台
  }

  build() {
    // ...
  }
}
```

## 总结

遵循这些最佳实践可以帮助你:

1. 提升应用性能和用户体验
2. 减少 bug 和维护成本
3. 提高代码可读性和可维护性
4. 确保应用安全性
5. 加快开发效率

持续学习 HarmonyOS 官方文档,关注最新的 API 更新和最佳实践建议。
