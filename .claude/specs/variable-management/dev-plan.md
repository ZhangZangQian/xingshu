# 变量管理功能 - 开发计划

## 概述
为宏自动化系统添加完整的变量管理功能,支持全局变量和宏内部变量两种作用域,提供独立的全局变量管理页面和编辑器内的宏变量管理界面,并在动作配置中支持变量提示和快速插入。

## 任务拆解

### 任务 1: 数据层实现
- **ID**: task-1
- **描述**: 实现变量的数据模型和数据库持久化层,包括 Variable 模型定义、variable 表创建、完整的 CRUD 接口和数据解析方法
- **文件范围**:
  - 新建文件: `entry/src/main/ets/models/Variable.ts`
  - 扩展文件: `entry/src/main/ets/services/DatabaseService.ts`
- **依赖关系**: 无 (独立任务)
- **测试命令**: `hvigor test --mode module -p module=entry@default -p product=default --filter="Variable|DatabaseService"`
- **测试要点**:
  - Variable 模型的类型定义 (VariableScope, VariableType 枚举)
  - variable 表的成功创建 (id, scope, macro_id, name, type, value, created_at, updated_at 字段)
  - 创建变量 (insertVariable) 成功返回 rowId
  - 查询全局变量 (getGlobalVariables) 返回正确结果
  - 查询宏变量 (getVariablesByMacroId) 返回指定宏的变量列表
  - 按名称查询变量 (getVariableByName) 支持作用域过滤
  - 更新变量 (updateVariable) 正确修改值和类型
  - 删除变量 (deleteVariable) 级联删除宏变量
  - 变量值 JSON 序列化和反序列化
  - 边界情况: 重复名称处理、作用域隔离验证、类型转换错误处理

### 任务 2: 运行期集成
- **ID**: task-2
- **描述**: 扩展执行上下文 (ExecutionContext) 和宏引擎 (MacroEngine),实现变量的加载、解析和作用域管理,支持 system → global → macro 的三级变量解析顺序
- **文件范围**:
  - 扩展文件: `entry/src/main/ets/models/ExecutionContext.ts`
  - 扩展文件: `entry/src/main/ets/services/MacroEngine.ts`
  - 可能涉及: `entry/src/main/ets/utils/VariableParser.ts` (已存在)
- **依赖关系**: 依赖 task-1 (需要 Variable 模型和数据库接口)
- **测试命令**: `hvigor test --mode module -p module=entry@default -p product=default --filter="ExecutionContext|MacroEngine"`
- **测试要点**:
  - ExecutionContext 初始化时加载全局变量和宏变量
  - getVariable 方法按优先级解析: system → macro → global
  - 宏执行前加载变量到上下文 (loadVariables 方法)
  - 动作执行中通过 context.getVariable 正确获取变量
  - 变量值的类型转换 (String/Number/Boolean)
  - VariableParser 集成: 解析配置中的 {variable_name} 占位符
  - 变量作用域隔离: 宏 A 无法访问宏 B 的内部变量
  - 运行时变量修改不影响数据库 (可选持久化)
  - 系统变量 (date, time, clipboard) 与自定义变量共存
  - 错误处理: 变量不存在时返回 undefined 或默认值

### 任务 3: 全局变量管理页面
- **ID**: task-3
- **描述**: 创建独立的全局变量管理页面,提供完整的 CRUD 界面,包括变量列表展示、创建/编辑对话框、删除确认、类型选择和值校验
- **文件范围**:
  - 新建文件: `entry/src/main/ets/pages/GlobalVariables.ets`
  - 扩展文件: `entry/src/main/ets/pages/Index.ets` (添加全局变量入口按钮)
  - 更新文件: `entry/src/main/resources/base/profile/main_pages.json` (添加路由)
- **依赖关系**: 依赖 task-1 (需要 DatabaseService 的变量 CRUD 接口)
- **测试命令**: `hvigor test --mode module -p module=entry@default -p product=default --filter="GlobalVariables"`
- **测试要点**:
  - 页面路由正确注册,从 Index 页跳转成功
  - 变量列表正确加载和展示 (名称、类型、值)
  - 创建变量对话框: 输入验证 (名称非空、值类型匹配)
  - 类型选择器: String/Number/Boolean 三种类型切换
  - 编辑变量: 回填原值,修改后保存
  - 删除变量: 显示确认对话框,删除成功后刷新列表
  - 空状态提示: 无全局变量时显示"暂无全局变量"
  - UI 状态管理: @State 正确触发界面刷新
  - 错误提示: Toast 显示操作结果 (成功/失败)
  - 值类型校验: Number 类型输入非数字时提示错误
  - Boolean 类型使用 Toggle 组件展示和编辑

### 任务 4: 编辑器变量管理与插入器
- **ID**: task-4
- **描述**: 在宏编辑器中添加宏内部变量管理区域,并创建变量选择器对话框,支持在动作配置时快速插入变量占位符 (使用 Gemini 后端辅助生成 UI 代码)
- **文件范围**:
  - 扩展文件: `entry/src/main/ets/pages/MacroEditor.ets`
  - 新建文件: `entry/src/main/ets/components/VariablePickerDialog.ets`
- **依赖关系**: 依赖 task-1 (数据层) 和 task-3 (UI 设计模式参考)
- **测试命令**: `hvigor test --mode module -p module=entry@default -p product=default --filter="MacroEditor|VariablePickerDialog"`
- **测试要点**:
  - MacroEditor 新增"宏变量"区域,与触发器/动作平级
  - 宏变量列表展示当前宏的所有内部变量
  - 宏变量 CRUD: 创建、编辑、删除功能完整
  - VariablePickerDialog 组件: 显示所有可用变量 (system + global + macro)
  - 变量分类展示: 系统变量/全局变量/宏变量分组显示
  - 点击变量时插入 {variable_name} 到配置输入框
  - 动作配置输入框旁添加"插入变量"按钮
  - 对话框关闭后焦点正确返回输入框
  - 变量实时提示: 输入 { 时显示候选变量 (可选增强功能)
  - 保存宏时同时保存宏变量 (insertVariable 批量操作)
  - 编辑模式: 正确加载和回填宏变量
  - UI 响应式: ForEach 正确渲染变量列表

## 验收标准
- [ ] 全局变量和宏变量可以成功创建、编辑、删除
- [ ] variable 表正确创建,包含所有必需字段和索引
- [ ] 变量值支持 String、Number、Boolean 三种类型,类型校验正确
- [ ] 全局变量页面功能完整,UI 交互流畅
- [ ] 宏编辑器中可以管理宏内部变量
- [ ] 变量选择器对话框正确显示所有作用域的变量
- [ ] 动作配置中可以快速插入变量占位符
- [ ] 变量解析顺序正确 (system → macro → global)
- [ ] 宏执行时正确加载和解析变量
- [ ] 变量作用域隔离正确,宏变量不会泄漏到其他宏
- [ ] 所有单元测试通过
- [ ] 代码覆盖率 ≥90%

## 技术要点

### 数据库设计
```sql
CREATE TABLE IF NOT EXISTS variable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scope TEXT NOT NULL CHECK(scope IN ('global', 'macro')),
  macro_id INTEGER,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('string', 'number', 'boolean')),
  value TEXT NOT NULL,  -- JSON 序列化存储
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (macro_id) REFERENCES macro(id) ON DELETE CASCADE,
  UNIQUE(scope, macro_id, name)  -- 确保同一作用域内变量名唯一
);

CREATE INDEX IF NOT EXISTS idx_variable_scope ON variable(scope);
CREATE INDEX IF NOT EXISTS idx_variable_macro_id ON variable(macro_id);
```

### 变量解析优先级
1. **System 变量** (最高优先级): date, time, timestamp, clipboard, network_type, battery_level
2. **Macro 变量** (中优先级): 当前宏的内部变量
3. **Global 变量** (最低优先级): 跨宏共享的全局变量

### UI 模式约定
- 使用 `@State` 管理页面状态
- 使用 `Scroll` + `ForEach` 渲染列表
- 使用 `promptAction.showDialog` 显示编辑对话框
- 使用 `promptAction.showToast` 显示操作结果
- 变量值输入框根据类型动态切换 (TextInput / NumberInput / Toggle)

### 错误处理策略
- 变量名重复: Toast 提示"变量名已存在"
- 类型转换失败: Toast 提示"值类型不匹配"
- 数据库操作失败: Logger.error 记录,Toast 提示用户
- 变量不存在: getVariable 返回 undefined,不抛出异常

### 性能优化建议
- ExecutionContext 初始化时一次性加载所有变量,避免执行期多次查询数据库
- 变量列表分页加载 (全局变量数量可能较多)
- 变量值使用 JSON 序列化,支持复杂类型扩展 (未来可能支持 Array/Object)

### 测试覆盖重点
- 数据层: CRUD 接口的正确性、边界条件、错误处理
- 运行期: 变量解析优先级、作用域隔离、占位符替换
- UI 层: 状态管理、用户交互、表单验证、路由跳转
- 集成测试: 端到端流程 (创建变量 → 配置动作 → 执行宏 → 验证结果)
