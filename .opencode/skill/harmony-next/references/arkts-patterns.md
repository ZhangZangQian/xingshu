# ArkTS 编码模式

## 类型定义

### 基础类型

```typescript
// 字符串
let name: string = 'Hello'

// 数字
let age: number = 25
let price: number = 19.99

// 布尔值
let isActive: boolean = true

// 数组
let items: string[] = ['a', 'b', 'c']
let numbers: Array<number> = [1, 2, 3]

// 元组
let tuple: [string, number] = ['hello', 123]

// 枚举
enum Status {
  Loading = 'loading',
  Success = 'success',
  Error = 'error'
}
```

### 高级类型

```typescript
// 联合类型
type Status = 'loading' | 'success' | 'error'

// 交叉类型
type Name = { name: string }
type Age = { age: number }
type Person = Name & Age

// 类型别名
type ID = string | number
type User = { id: ID; name: string }

// 接口
interface User {
  id: number
  name: string
  age?: number
  [key: string]: any
}

// 泛型
function identity<T>(arg: T): T {
  return arg
}

const result = identity<string>('hello')

// 泛型接口
interface Box<T> {
  value: T
}

const box: Box<string> = { value: 'hello' }
```

### 装饰器

```typescript
// @State - 组件内部状态
@State count: number = 0

// @Prop - 父子组件单向传递
@Prop title: string

// @Link - 双向数据绑定
@Link isActive: boolean

// @Provide/@Consume - 跨层级传递
@Provide themeColor: string = '#FF0000'
@Consume themeColor: string

// @ObjectLink/@Observed - 对象深度监听
@Observed
class User {
  name: string
  age: number
}

@ObjectLink user: User

// @Builder - 构建器方法
@Builder
CustomButton(text: string) {
  Button(text)
    .onClick(() => {
      console.log(text)
    })
}

// @Styles - 样式复用
@Styles
globalStyle() {
  .width('100%')
  .height(100)
  .backgroundColor('#FF0000')
}

// @Extend - 扩展组件样式
@Extend(Text)
function textStyle() {
  .fontSize(16)
  .fontColor('#333333')
}
```

## 函数模式

### 箭头函数

```typescript
// 普通箭头函数
const add = (a: number, b: number): number => {
  return a + b
}

// 简化写法
const multiply = (a: number, b: number): number => a * b

// 单参数
const double = (x: number): number => x * 2

// 无参数
const greet = (): void => console.log('Hello')
```

### 回调函数

```typescript
// 定义回调类型
type Callback = (data: string) => void

// 使用回调
function fetchData(callback: Callback) {
  setTimeout(() => {
    callback('Data loaded')
  }, 1000)
}

fetchData((data: string) => {
  console.log(data)
})
```

### Promise

```typescript
// 返回Promise
function asyncFunction(): Promise<string> {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve('Success')
    }, 1000)
  })
}

// async/await
async function main() {
  try {
    const result = await asyncFunction()
    console.log(result)
  } catch (error) {
    console.error(error)
  }
}
```

## 类模式

### 类定义

```typescript
class User {
  private id: number
  public name: string
  protected age: number

  constructor(id: number, name: string, age: number) {
    this.id = id
    this.name = name
    this.age = age
  }

  public getDetails(): string {
    return `${this.name}, ${this.age} years old`
  }

  private validateAge(): boolean {
    return this.age >= 0
  }
}
```

### 继承

```typescript
class Animal {
  protected name: string

  constructor(name: string) {
    this.name = name
  }

  public speak(): void {
    console.log(`${this.name} makes a sound`)
  }
}

class Dog extends Animal {
  private breed: string

  constructor(name: string, breed: string) {
    super(name)
    this.breed = breed
  }

  public speak(): void {
    console.log(`${this.name} barks`)
  }

  public fetch(): void {
    console.log(`${this.name} fetches the ball`)
  }
}
```

### 抽象类

```typescript
abstract class Shape {
  abstract area(): number
  abstract perimeter(): number

  public describe(): void {
    console.log(`Area: ${this.area()}, Perimeter: ${this.perimeter()}`)
  }
}

class Rectangle extends Shape {
  private width: number
  private height: number

  constructor(width: number, height: number) {
    super()
    this.width = width
    this.height = height
  }

  area(): number {
    return this.width * this.height
  }

  perimeter(): number {
    return 2 * (this.width + this.height)
  }
}
```

## 模块化

### 导出导入

```typescript
// export.ts
export const PI = 3.14159

export function add(a: number, b: number): number {
  return a + b
}

export class Calculator {
  add(a: number, b: number): number {
    return a + b
  }
}

// import.ts
import { PI, add, Calculator } from './export'

console.log(PI)
const result = add(1, 2)
const calc = new Calculator()

// 默认导出
export default function defaultExport(): void {
  console.log('Default export')
}

// 导入默认导出
import defaultExport from './export'
```

### 动态导入

```typescript
// 动态导入模块
async function loadModule() {
  const module = await import('./heavyModule')
  module.someFunction()
}
```

## 异常处理

```typescript
try {
  // 可能抛出异常的代码
  const data = JSON.parse(jsonString)
} catch (error) {
  if (error instanceof SyntaxError) {
    console.error('JSON解析错误:', error.message)
  } else {
    console.error('未知错误:', error)
  }
} finally {
  // 总是执行的代码
  console.log('操作完成')
}

// 抛出自定义异常
throw new Error('自定义错误信息')
```

## 工具函数

```typescript
// 深拷贝
function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj))
}

// 防抖
function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: number | null = null
  return function(this: any, ...args: Parameters<T>) {
    if (timeout) {
      clearTimeout(timeout)
    }
    timeout = setTimeout(() => {
      func.apply(this, args)
    }, wait)
  }
}

// 节流
function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean
  return function(this: any, ...args: Parameters<T>) {
    if (!inThrottle) {
      func.apply(this, args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}
```

## 数组操作

```typescript
// map - 转换数组
const doubled = numbers.map((n: number) => n * 2)

// filter - 过滤数组
const evens = numbers.filter((n: number) => n % 2 === 0)

// reduce - 归约数组
const sum = numbers.reduce((acc: number, curr: number) => acc + curr, 0)

// find - 查找元素
const found = numbers.find((n: number) => n > 10)

// some - 是否存在满足条件
const hasEven = numbers.some((n: number) => n % 2 === 0)

// every - 是否都满足条件
const allPositive = numbers.every((n: number) => n > 0)

// sort - 排序
const sorted = [...numbers].sort((a: number, b: number) => a - b)
```

## 对象操作

```typescript
// 对象解构
const { name, age } = user

// 数组解构
const [first, second] = items

// 对象展开
const newUser = { ...user, email: 'test@example.com' }

// 数组展开
const newItems = [...items, 'new item']

// 对象属性访问
const name1 = user['name']
const name2 = user.name

// 动态属性
const key = 'name'
const value = user[key as keyof typeof user]
```

## 类型守卫

```typescript
// typeof
function isString(value: unknown): value is string {
  return typeof value === 'string'
}

// instanceof
function isError(error: unknown): error is Error {
  return error instanceof Error
}

// in 操作符
function hasName(obj: unknown): obj is { name: string } {
  return typeof obj === 'object' && obj !== null && 'name' in obj
}

// 自定义类型守卫
function isUser(obj: unknown): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'name' in obj &&
    typeof (obj as any).id === 'number' &&
    typeof (obj as any).name === 'string'
  )
}
```
