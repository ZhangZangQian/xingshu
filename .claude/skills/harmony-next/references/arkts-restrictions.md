# ArkTS 语法限制和常见编译错误

ArkTS 是基于 TypeScript 的严格子集，有许多 JavaScript/TypeScript 特性不被支持。本文档总结实际开发中最常遇到的语法限制和解决方案。

## 1. 对象字面量限制

### ❌ 错误：未声明类型的对象字面量

```typescript
// 错误：Object literal must correspond to some explicitly declared class or interface
this.configData['headers'] = {};

const options = { name: 'test', value: 123 };

const result = items.map(item => ({
  id: item.id,
  name: item.name
}));
```

### ✅ 正确：显式类型声明

```typescript
// 方式1：使用中间变量
const emptyHeaders: Record<string, string> = {};
this.configData['headers'] = emptyHeaders;

// 方式2：内联类型声明
interface Option {
  name: string;
  value: number;
}
const options: Option = { name: 'test', value: 123 };

// 方式3：forEach + 显式类型
const result: ResultItem[] = [];
items.forEach(item => {
  const resultItem: ResultItem = {
    id: item.id,
    name: item.name
  };
  result.push(resultItem);
});
```

**规则**：所有对象字面量 `{}` 必须对应明确的类或接口类型。

---

## 2. 解构赋值限制

### ❌ 错误：不支持解构赋值

```typescript
// 错误：Destructuring variable declarations are not supported
const { isValid, errors } = validationResult;

const [first, ...rest] = array;

function process({ name, age }: User) { }
```

### ✅ 正确：直接访问属性

```typescript
// 使用中间变量
const validationResult = VariableFlowAnalyzer.validateAction(...);
const isValid = validationResult.isValid;
const errors = validationResult.errors;

// 或直接访问
if (validationResult.isValid) {
  // ...
}

// 数组解构改为索引访问
const first = array[0];
const rest = array.slice(1);

// 函数参数直接使用对象
function process(user: User) {
  const name = user.name;
  const age = user.age;
}
```

**规则**：完全不支持解构语法，包括对象解构和数组解构。

---

## 3. @Builder 方法限制

### ❌ 错误：@Builder 中使用非 UI 语句

```typescript
@Builder
buildFormContent() {
  // 错误：Only UI component syntax can be written here
  switch (this.action.type) {
    case ActionType.TEXT_PROCESS:
      this.buildTextProcessForm();
      break;
    case ActionType.HTTP_REQUEST:
      this.buildHttpRequestForm();
      break;
  }

  // 错误：不能声明变量
  const nextViewModel = this.actionViewModels[index + 1];
}
```

### ✅ 正确：仅使用 if-else 和 UI 组件

```typescript
@Builder
buildFormContent() {
  // 使用 if-else 链
  if (this.action.type === ActionType.TEXT_PROCESS) {
    this.buildTextProcessForm();
  } else if (this.action.type === ActionType.HTTP_REQUEST) {
    this.buildHttpRequestForm();
  } else if (this.action.type === ActionType.USER_DIALOG) {
    this.buildUserDialogForm();
  }

  // 直接在条件中访问，不声明变量
  if (this.actionViewModels[index + 1].inputVariables.includes(...)) {
    // UI 代码
  }
}
```

**规则**：`@Builder` 装饰的方法只能包含：
- UI 组件（Text, Column, Row 等）
- if-else 语句（不能用 switch）
- 调用其他 @Builder 方法
- 不能声明变量、使用 for 循环等

---

## 4. build() 方法限制

### ❌ 错误：在 build() 中声明变量

```typescript
build() {
  Column() {
    // 错误：Only UI component syntax can be written here
    const isActive = this.status === 'active';

    if (isActive) {
      Text('活动中')
    }
  }
}
```

### ✅ 正确：直接使用表达式或状态变量

```typescript
build() {
  Column() {
    // 方式1：直接在条件中使用表达式
    if (this.status === 'active') {
      Text('活动中')
    }

    // 方式2：使用计算属性（在类中定义）
    if (this.isActive) {
      Text('活动中')
    }
  }
}

// 类中定义 getter
get isActive(): boolean {
  return this.status === 'active';
}
```

**规则**：`build()` 方法内只能写 UI 组件语法，不能声明变量、使用 for 循环等。

---

## 5. 数组方法限制

### ❌ 错误：map 返回对象字面量

```typescript
// 错误：Object literal must correspond to some explicitly declared class
const options = variables.map(v => ({
  name: v.name,
  type: 'macro',
  description: `类型: ${v.type}`
}));
```

### ✅ 正确：使用 forEach + 显式类型

```typescript
const options: VariableOption[] = [];
variables.forEach(v => {
  const option: VariableOption = {
    name: v.name,
    type: 'macro',
    description: `类型: ${v.type}`
  };
  options.push(option);
});
```

**规则**：避免在 `.map()` 中返回对象字面量，改用 `forEach` + 显式类型声明。

---

## 6. 类型断言限制

### ❌ 错误：as const 断言

```typescript
// 错误："as const" assertions are not supported
const colors = ['red', 'green', 'blue'] as const;

const config = {
  name: 'test',
  type: 'macro' as const
};
```

### ✅ 正确：使用明确的类型定义

```typescript
// 方式1：使用 enum
enum Color {
  Red = 'red',
  Green = 'green',
  Blue = 'blue'
}
const colors: Color[] = [Color.Red, Color.Green, Color.Blue];

// 方式2：使用联合类型
type ConfigType = 'macro' | 'global' | 'system';
const config: { name: string; type: ConfigType } = {
  name: 'test',
  type: 'macro'
};
```

**规则**：不支持 `as const` 断言，使用 `enum` 或联合类型替代。

---

## 7. 静态方法限制

### ❌ 错误：静态方法中使用 this

```typescript
export class Helper {
  // 错误：Using "this" inside stand-alone functions is not supported
  static fromVariables(variables: Variable[]): Option[] {
    return variables.map(v => ({
      name: v.name,
      description: this.getTypeLabel(v.type)  // 错误
    }));
  }

  static getTypeLabel(type: string): string {
    return type;
  }
}
```

### ✅ 正确：使用类名调用

```typescript
export class Helper {
  static fromVariables(variables: Variable[]): Option[] {
    const result: Option[] = [];
    variables.forEach(v => {
      const option: Option = {
        name: v.name,
        description: Helper.getTypeLabel(v.type)  // 使用类名
      };
      result.push(option);
    });
    return result;
  }

  static getTypeLabel(type: string): string {
    return type;
  }
}
```

**规则**：静态方法内部调用其他静态方法必须使用类名，不能使用 `this`。

---

## 8. JSON 序列化限制

### ❌ 错误：嵌套对象字面量

```typescript
// 错误：Object literal must correspond to some explicitly declared class
const action: Action = {
  type: ActionType.HTTP_REQUEST,
  config: JSON.stringify({
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },  // 嵌套对象
    body: {
      workflow_id: '123',
      parameters: { url: 'https://...' }  // 深层嵌套
    }
  })
};
```

### ✅ 正确：使用字符串字面量或类型声明

```typescript
// 方式1：直接使用 JSON 字符串
const action: Action = {
  type: ActionType.HTTP_REQUEST,
  config: '{"method":"POST","headers":{"Content-Type":"application/json"},"body":{"workflow_id":"123"}}'
};

// 方式2：先定义类型化的配置对象
interface HttpConfig {
  method: string;
  headers: Record<string, string>;
  body: string;
}
const httpConfig: HttpConfig = {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: '{"workflow_id":"123"}'
};
const action: Action = {
  type: ActionType.HTTP_REQUEST,
  config: JSON.stringify(httpConfig)
};
```

**规则**：避免在 `JSON.stringify()` 中使用多层嵌套的对象字面量，改用字符串字面量或先定义类型。

---

## 9. ForEach 限制

### ❌ 错误：不正确的 keyGenerator

```typescript
// 错误：keyGenerator 返回值不稳定
ForEach(this.items, (item: Item) => {
  Text(item.name)
}, (item: Item) => Math.random().toString())  // 不稳定的 key
```

### ✅ 正确：使用稳定的唯一标识

```typescript
// 使用唯一 ID
ForEach(this.items, (item: Item) => {
  Text(item.name)
}, (item: Item) => item.id.toString())

// 使用索引（适用于静态列表）
ForEach(this.items, (item: Item, index: number) => {
  Text(item.name)
}, (item: Item, index: number) => index.toString())
```

**规则**：`ForEach` 的 keyGenerator 必须返回稳定的唯一标识，推荐使用 `id` 或 `index`。

---

## 10. CustomDialog 限制

### ❌ 错误：传递 @Link 参数不正确

```typescript
// 错误：未使用 $ 语法
this.dialogController = new CustomDialogController({
  builder: MyDialog({
    data: this.editingData,  // 错误：@Link 参数需要 $
    onSave: (result) => { }
  })
});
```

### ✅ 正确：使用 $ 语法传递 @Link

```typescript
this.dialogController = new CustomDialogController({
  builder: MyDialog({
    data: $editingData,  // 使用 $ 传递 @Link 参数
    onSave: (result) => { }
  }),
  autoCancel: false,
  customStyle: true
});

// 对话框定义
@CustomDialog
export struct MyDialog {
  controller: CustomDialogController;
  @Link data: MyData;  // @Link 装饰器
  onSave?: (result: MyData) => void;
}
```

**规则**：传递给 `@Link` 装饰的参数时必须使用 `$` 语法。

---

## 常见错误代码对照表

| 错误代码 | 错误信息 | 原因 | 解决方案 |
|---------|---------|------|---------|
| 10605038 | Object literal must correspond to some explicitly declared class | 对象字面量缺少类型 | 添加显式类型声明 |
| 10605074 | Destructuring variable declarations are not supported | 使用了解构赋值 | 改为直接访问属性 |
| 10605142 | "as const" assertions are not supported | 使用了 as const | 改用 enum 或联合类型 |
| 10605093 | Using "this" inside stand-alone functions is not supported | 静态方法用了 this | 使用类名调用 |
| 10905209 | Only UI component syntax can be written here | build/Builder 中有非 UI 语句 | 移除变量声明、switch 等 |

---

## 开发建议

### 1. 代码检查清单

在提交代码前检查：

- [ ] 所有 `{}` 都有明确的类型声明
- [ ] 没有使用解构赋值
- [ ] `@Builder` 方法只包含 UI 组件和 if-else
- [ ] `build()` 方法没有变量声明
- [ ] 静态方法使用类名而非 `this`
- [ ] `ForEach` 有稳定的 keyGenerator
- [ ] `@Link` 参数使用 `$` 语法传递

### 2. 常用模式

**模式1：类型安全的配置对象**

```typescript
interface Config {
  key: string;
  value: Object;
}

// 创建配置
const config: Config = {
  key: 'setting',
  value: 'enabled'
};

// 修改配置
const updatedConfig: Config = {
  key: config.key,
  value: 'disabled'
};
```

**模式2：安全的数组转换**

```typescript
function convertArray<T, R>(items: T[], converter: (item: T) => R): R[] {
  const result: R[] = [];
  items.forEach(item => {
    result.push(converter(item));
  });
  return result;
}

// 使用
const options = convertArray(variables, (v) => {
  const option: VariableOption = {
    name: v.name,
    type: 'macro'
  };
  return option;
});
```

**模式3：条件渲染优化**

```typescript
// 在类中定义 getter
get isVisible(): boolean {
  return this.status === 'active' && this.count > 0;
}

// build() 中直接使用
build() {
  Column() {
    if (this.isVisible) {
      Text('显示内容')
    }
  }
}
```

### 3. 调试技巧

遇到编译错误时：

1. **查看错误代码**：根据上面的对照表快速定位问题类型
2. **查看行号**：编译器会指出具体位置
3. **检查嵌套层级**：深层嵌套的对象字面量最容易出错
4. **使用中间变量**：复杂表达式拆分成多步，每步显式声明类型

---

## 更新日志

- 2026-01-07：基于实际项目编译错误创建文档
  - 添加对象字面量、解构赋值、@Builder 限制
  - 添加常见错误代码对照表
  - 补充开发建议和常用模式
