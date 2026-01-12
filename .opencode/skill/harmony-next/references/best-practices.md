# HarmonyOS NEXT 开发最佳实践

## 性能优化

### 状态管理优化

```typescript
// ❌ 错误：使用普通属性
class MyComponent {
  count: number = 0  // 不会触发UI更新

  increment() {
    this.count++
  }
}

// ✅ 正确：使用@State装饰器
@Component
struct MyComponent {
  @State count: number = 0  // 会触发UI更新

  build() {
    Column() {
      Text(`${this.count}`)
      Button('Increment')
        .onClick(() => {
          this.count++
        })
    }
  }
}
```

### 状态变量选择

```typescript
// @State：组件内部状态
@State localData: string[] = []

// @Prop：父组件传递的只读数据
@Prop readonlyData: string

// @Link：双向数据绑定
@Link editableData: number

// @Provide/@Consume：跨层级传递
@Provide globalTheme: Theme = defaultTheme
@Consume globalTheme: Theme

// @Observed/@ObjectLink：深度监听对象
@Observed
class UserModel {
  name: string
  age: number
}

@ObjectLink user: UserModel
```

### 列表性能优化

```typescript
// ❌ 错误：使用ForEach渲染大数据量
ForEach(this.largeData, (item: Item) => {
  ListItem() {
    ItemComponent({ item: item })
  }
})

// ✅ 正确：使用LazyForEach延迟加载
LazyForEach(new DataSource(this.largeData), (item: Item) => {
  ListItem() {
    ItemComponent({ item: item })
  }
}, (item: Item) => item.id.toString())

// 实现IDataSource接口
class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []
  private data: Item[] = []

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  public getData(index: number): Item {
    return this.data[index]
  }

  public totalCount(): number {
    return this.data.length
  }
}
```

### 组件复用

```typescript
// ❌ 错误：重复创建相同组件
ForEach(this.items, (item: string) => {
  Column() {
    Text(item)
      .fontSize(16)
      .fontColor('#333333')
  }
})

// ✅ 正确：使用@Reusable装饰器
@Reusable
struct ReusableItem {
  @Prop content: string

  build() {
    Text(this.content)
      .fontSize(16)
      .fontColor('#333333')
  }
}

// 使用复用组件
ForEach(this.items, (item: string) => {
  ReusableItem({ content: item })
}, (item: string) => item)
```

### 条件渲染优化

```typescript
// ❌ 错误：使用display控制显隐
Text('Content')
  .display(this.isShow ? Visibility.Visible : Visibility.None)

// ✅ 正确：使用if条件渲染
if (this.isShow) {
  Text('Content')
}
```

### 图片优化

```typescript
// ❌ 错误：使用过大图片
Image('large_image.png')

// ✅ 正确：使用适当尺寸
Image('optimized_image.png')
  .width(100)
  .height(100)
  .objectFit(ImageFit.Cover)

// 使用WebP格式压缩
// 懒加载图片
LazyForEach(this.imageData, (image: ImageInfo) => {
  Image(image.url)
    .width('100%')
    .height(200)
    .onAppear(() => {
      // 预加载下一张
    })
}, (image: ImageInfo) => image.id)
```

## 代码质量

### 命名规范

```typescript
// 组件：使用大驼峰命名
struct UserList {}
struct UserProfilePage {}

// 变量：使用小驼峰命名
let userName: string
let userAge: number

// 常量：使用全大写命名
const MAX_RETRY_COUNT: number = 3
const API_BASE_URL: string = 'https://api.example.com'

// 类型：使用大驼峰命名
type UserStatus = 'active' | 'inactive'
interface UserProfile {
  name: string
  age: number
}

// 函数：使用小驼峰命名
function getUserData(): User {}
function handleButtonClick(): void {}
```

### 类型安全

```typescript
// ❌ 错误：使用any类型
let data: any = fetchData()

// ✅ 正确：使用具体类型
let data: UserData[] = fetchData()

// ❌ 错误：不检查类型
function processValue(value: unknown) {
  console.log(value.toUpperCase())
}

// ✅ 正确：使用类型守卫
function processValue(value: unknown) {
  if (typeof value === 'string') {
    console.log(value.toUpperCase())
  }
}

// ✅ 更好：定义明确的类型
interface ProcessableValue {
  toUpperCase(): string
}

function processValue(value: ProcessableValue) {
  console.log(value.toUpperCase())
}
```

### 错误处理

```typescript
// ❌ 错误：不处理异常
const data = JSON.parse(jsonString)

// ✅ 正确：使用try-catch
try {
  const data = JSON.parse(jsonString)
} catch (error) {
  if (error instanceof SyntaxError) {
    console.error('JSON解析错误:', error.message)
    // 显示错误提示给用户
    promptAction.showToast({
      message: '数据格式错误',
      duration: 2000
    })
  }
}

// ✅ 异步错误处理
async function fetchData(): Promise<UserData> {
  try {
    const response = await httpRequest.request(url, options)
    if (response.responseCode === 200) {
      return JSON.parse(response.result.toString()) as UserData
    } else {
      throw new Error(`请求失败: ${response.responseCode}`)
    }
  } catch (error) {
    console.error('获取数据失败:', error)
    throw error
  }
}
```

### 内存管理

```typescript
// ❌ 错误：不清理订阅
class MyComponent {
  private timer: number = -1
  private subscriber: EventEmitter = new EventEmitter()

  aboutToAppear() {
    this.timer = setInterval(() => {
      console.log('Tick')
    }, 1000)

    this.subscriber.on('data', this.handleData)
  }
}

// ✅ 正确：清理资源
class MyComponent {
  private timer: number = -1
  private subscriber: EventEmitter = new EventEmitter()

  aboutToAppear() {
    this.timer = setInterval(() => {
      console.log('Tick')
    }, 1000)

    this.subscriber.on('data', this.handleData)
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }

    // 清理订阅
    this.subscriber.off('data', this.handleData)
  }

  private handleData(data: unknown): void {
    console.log(data)
  }
}
```

## 架构设计

### 分层架构

```
├── pages/              # UI层
│   ├── HomePage.ets
│   └── DetailPage.ets
├── viewmodels/         # 视图模型层
│   ├── HomeViewModel.ets
│   └── DetailViewModel.ets
├── services/           # 服务层
│   ├── UserService.ets
│   └── ApiService.ets
├── models/             # 数据模型层
│   ├── User.ets
│   └── ApiResponse.ets
├── utils/              # 工具层
│   ├── HttpUtil.ets
│   └── StorageUtil.ets
└── constants/          # 常量层
    ├── ApiConstants.ets
    └── AppConstants.ets
```

### MVVM模式

```typescript
// Model
class User {
  id: number
  name: string
  email: string
}

// ViewModel
@Observed
class UserViewModel {
  @Track users: User[] = []
  @Track isLoading: boolean = false
  @Track errorMessage: string = ''

  async loadUsers(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      this.users = await UserService.getUsers()
    } catch (error) {
      this.errorMessage = '加载失败'
    } finally {
      this.isLoading = false
    }
  }
}

// View
@Component
struct UserListPage {
  @ObjectLink viewModel: UserViewModel

  build() {
    Column() {
      if (this.viewModel.isLoading) {
        LoadingProgress()
      } else if (this.viewModel.errorMessage) {
        Text(this.viewModel.errorMessage)
      } else {
        List() {
          ForEach(this.viewModel.users, (user: User) => {
            ListItem() {
              Text(user.name)
            }
          }, (user: User) => user.id.toString())
        }
      }
    }
    .onAppear(() => {
      this.viewModel.loadUsers()
    })
  }
}
```

### 依赖注入

```typescript
// 服务接口
interface IUserService {
  getUser(id: number): Promise<User>
}

// 服务实现
class UserService implements IUserService {
  async getUser(id: number): Promise<User> {
    // 实现逻辑
    return {} as User
  }
}

// 服务容器
class ServiceContainer {
  private static instance: ServiceContainer
  private services: Map<string, any> = new Map()

  private constructor() {}

  static getInstance(): ServiceContainer {
    if (!ServiceContainer.instance) {
      ServiceContainer.instance = new ServiceContainer()
    }
    return ServiceContainer.instance
  }

  register<T>(name: string, service: T): void {
    this.services.set(name, service)
  }

  get<T>(name: string): T {
    return this.services.get(name) as T
  }
}

// 使用
const container = ServiceContainer.getInstance()
container.register('userService', new UserService())

const userService = container.get<IUserService>('userService')
const user = await userService.getUser(1)
```

## 可维护性

### 代码复用

```typescript
// ❌ 错误：重复代码
Button('Button 1')
  .width(100)
  .height(40)
  .fontSize(16)
  .backgroundColor('#FF0000')
  .fontColor('#FFFFFF')
  .borderRadius(8)

Button('Button 2')
  .width(100)
  .height(40)
  .fontSize(16)
  .backgroundColor('#FF0000')
  .fontColor('#FFFFFF')
  .borderRadius(8)

// ✅ 正确：使用@Styles或自定义组件
@Styles
primaryButtonStyle() {
  .width(100)
  .height(40)
  .fontSize(16)
  .backgroundColor('#FF0000')
  .fontColor('#FFFFFF')
  .borderRadius(8)
}

Button('Button 1')
  .primaryButtonStyle()

Button('Button 2')
  .primaryButtonStyle()

// 或使用自定义组件
struct PrimaryButton {
  @Prop text: string
  @Prop onClick?: () => void

  build() {
    Button(this.text)
      .width(100)
      .height(40)
      .fontSize(16)
      .backgroundColor('#FF0000')
      .fontColor('#FFFFFF')
      .borderRadius(8)
      .onClick(() => {
        this.onClick?.()
      })
  }
}

// 使用
PrimaryButton({ text: 'Button 1' })
PrimaryButton({ text: 'Button 2' })
```

### 常量管理

```typescript
// constants/ApiConstants.ets
export const API_BASE_URL = 'https://api.example.com'
export const API_TIMEOUT = 10000

export const API_ENDPOINTS = {
  LOGIN: '/api/login',
  REGISTER: '/api/register',
  GET_USER: '/api/user',
  UPDATE_USER: '/api/user'
}

// constants/AppConstants.ets
export const PAGE_ROUTES = {
  HOME: 'pages/HomePage',
  DETAIL: 'pages/DetailPage',
  PROFILE: 'pages/ProfilePage'
}

export const STORAGE_KEYS = {
  USER_TOKEN: 'user_token',
  USER_INFO: 'user_info',
  SETTINGS: 'app_settings'
}
```

### 工具函数

```typescript
// utils/HttpUtil.ets
export class HttpUtil {
  static async request<T>(
    url: string,
    options: HttpRequestOptions = {}
  ): Promise<T> {
    const httpRequest = http.createHttp()
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          ...options.header
        },
        extraData: options.data,
        ...options
      })
      if (response.responseCode === 200) {
        return JSON.parse(response.result.toString()) as T
      } else {
        throw new Error(`请求失败: ${response.responseCode}`)
      }
    } finally {
      httpRequest.destroy()
    }
  }
}

// utils/StorageUtil.ets
export class StorageUtil {
  private static preferences: preferences.Preferences

  static async init(context: Context): Promise<void> {
    this.preferences = await preferences.getPreferences(context, 'app_storage')
  }

  static async get<T>(key: string, defaultValue: T): Promise<T> {
    try {
      const value = await this.preferences.get(key, defaultValue)
      return value as T
    } catch (error) {
      return defaultValue
    }
  }

  static async set(key: string, value: unknown): Promise<void> {
    await this.preferences.put(key, value)
    await this.preferences.flush()
  }

  static async remove(key: string): Promise<void> {
    await this.preferences.delete(key)
    await this.preferences.flush()
  }
}
```

## 安全性

### 数据验证

```typescript
// 验证用户输入
function validateEmail(email: string): boolean {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

function validatePassword(password: string): boolean {
  // 至少8位，包含字母和数字
  const regex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/
  return regex.test(password)
}

// 使用验证
if (!validateEmail(inputEmail)) {
  promptAction.showToast({
    message: '邮箱格式不正确',
    duration: 2000
  })
  return
}
```

### 权限管理

```typescript
// 请求权限
async function requestPermissions(context: Context, permissions: string[]): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager()
  const result = await atManager.requestPermissionsFromUser(context, permissions)
  const authResults = result.authResults

  for (let i = 0; i < authResults.length; i++) {
    if (authResults[i] !== 0) {
      return false
    }
  }
  return true
}

// 使用
const permissions = ['ohos.permission.INTERNET', 'ohos.permission.GET_NETWORK_INFO']
const granted = await requestPermissions(context, permissions)
if (!granted) {
  console.error('权限请求被拒绝')
}
```

### 数据加密

```typescript
// 加密敏感数据
import cryptoFramework from '@ohos.security.cryptoFramework'

async function encryptData(data: string, key: string): Promise<string> {
  const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256')
  const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
  // 加密逻辑
  return encryptedData
}

async function decryptData(encryptedData: string, key: string): Promise<string> {
  const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256')
  const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
  // 解密逻辑
  return decryptedData
}
```

## 测试

### 单元测试

```typescript
// 测试工具函数
import { describe, it, expect } from '@ohos/hypium'

export default function userUtilsTest() {
  describe('userUtilsTest', () => {
    it('validateEmail_validEmail_returnsTrue', () => {
      const result = validateEmail('test@example.com')
      expect(result).assertTrue()
    })

    it('validateEmail_invalidEmail_returnsFalse', () => {
      const result = validateEmail('invalid-email')
      expect(result).assertFalse()
    })
  })
}
```

### UI测试

```typescript
// 测试UI交互
import { Driver, BY } from '@ohos.uitest'

export default function userInterfaceTest() {
  it('clickButton_navigatesToDetailPage', async () => {
    const driver = Driver.create()
    await driver.delayMs(1000)

    // 查找按钮并点击
    const button = await driver.findComponent(BY.text('Go to Detail'))
    await button.click()

    // 验证导航
    const page = await driver.findComponent(BY.text('Detail Page'))
    expect(page).not.toBeNull()
  })
}
```

## 调试技巧

### 日志输出

```typescript
// 使用hilog输出日志
import hilog from '@ohos.hilog'

class Logger {
  private static DOMAIN: number = 0x0001
  private static TAG: string = 'MyApp'

  static debug(message: string, ...args: unknown[]): void {
    hilog.debug(this.DOMAIN, this.TAG, message, ...args)
  }

  static info(message: string, ...args: unknown[]): void {
    hilog.info(this.DOMAIN, this.TAG, message, ...args)
  }

  static warn(message: string, ...args: unknown[]): void {
    hilog.warn(this.DOMAIN, this.TAG, message, ...args)
  }

  static error(message: string, ...args: unknown[]): void {
    hilog.error(this.DOMAIN, this.TAG, message, ...args)
  }
}

// 使用
Logger.info('User logged in: %{public}s', userName)
Logger.error('API request failed: %{public}d', errorCode)
```

### 性能分析

```typescript
// 使用HiTrace分析性能
import hiTraceMeter from '@ohos.hiTraceMeter'

function expensiveOperation(): void {
  const traceId = hiTraceMeter.startTrace('expensive_operation')
  try {
    // 执行操作
    doSomething()
  } finally {
    hiTraceMeter.finishTrace('expensive_operation', traceId)
  }
}
```
