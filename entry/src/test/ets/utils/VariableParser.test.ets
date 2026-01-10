import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { VariableParser } from '../../../main/ets/utils/VariableParser';
import { ExecutionContextImpl } from '../../../main/ets/models/ExecutionContext';

class MockExecutionContext extends ExecutionContextImpl {
  constructor() {
    super(1, 'manual' as any);
  }

  async getVariable(name: string): Promise<Object | undefined> {
    if (name === 'name') return '张三';
    if (name === 'age') return 25;
    if (name === 'user') return { name: '李四', age: 30 };
    if (name === 'order') return { id: 'ORDER-123', items: [{ price: 100 }, { price: 200 }] };
    if (name === 'nested') return { a: { b: { c: 'deep' } } };
    if (name === 'list') return [1, 2, 3];
    if (name === 'empty_string') return '';
    if (name === 'null_value') return null;
    if (name === 'undefined_value') return undefined;
    if (name === 'outer') return '{inner}';
    if (name === 'inner') return '{deep}';
    if (name === 'deep') return 'final_value';
    if (name === 'json_config') return '{"key":"value"}';
    if (name === 'regex_pattern') return '\\d{3}';
    if (name === 'json_with_var') return '{"template":"Hello {name}"}';
    return undefined;
  }
}

export default function variableParser2Test() {
  describe('VariableParser', () => {
    let context: MockExecutionContext;

    beforeAll(() => {
      context = new MockExecutionContext();
    });

    describe('parse - 基础功能', () => {
      it('应该解析单个变量', async () => {
        const result = await VariableParser.parse('Hello {name}', context);
        expect(result).assertEqual('Hello 张三');
      });

      it('应该解析多个变量', async () => {
        const result = await VariableParser.parse('{name} is {age} years old', context);
        expect(result).assertEqual('张三 is 25 years old');
      });

      it('应该处理无变量的字符串', async () => {
        const result = await VariableParser.parse('Hello World', context);
        expect(result).assertEqual('Hello World');
      });

      it('应该处理空字符串', async () => {
        const result = await VariableParser.parse('', context);
        expect(result).assertEqual('');
      });

      it('应该处理 null 输入', async () => {
        const result = await VariableParser.parse(null as any, context);
        expect(result).assertEqual(null);
      });

      it('应该处理 undefined 输入', async () => {
        const result = await VariableParser.parse(undefined as any, context);
        expect(result).assertEqual(undefined);
      });
    });

    describe('parse - 对象变量', () => {
      it('应该解析对象变量并序列化', async () => {
        const result = await VariableParser.parse('User: {user}', context);
        expect(result).assertEqual('User: {"name":"李四","age":30}');
      });

      it('应该解析数组变量并序列化', async () => {
        const result = await VariableParser.parse('List: {list}', context);
        expect(result).assertEqual('List: [1,2,3]');
      });
    });

    describe('parse - 特殊值处理', () => {
      it('应该处理空字符串变量', async () => {
        const result = await VariableParser.parse('Value: {empty_string}', context);
        expect(result).assertEqual('Value: ');
      });

      it('应该处理 null 变量', async () => {
        const result = await VariableParser.parse('Value: {null_value}', context);
        expect(result).assertEqual('Value: ');
      });

      it('应该处理未找到的变量', async () => {
        const result = await VariableParser.parse('Value: {not_found}', context);
        expect(result).assertEqual('Value: {not_found}');
      });
    });

    describe('parse - JSON 格式', () => {
      it('应该解析为 JSON 对象', async () => {
        const result = await VariableParser.parse('{"name":"{name}","age":{age}}', context, { format: 'json' });
        expect(JSON.stringify(result)).assertEqual('{"name":"张三","age":25}');
      });

      it('应该解析为 JSON 数组', async () => {
        const result = await VariableParser.parse('["{name}",{age}]', context, { format: 'json' });
        expect(JSON.stringify(result)).assertEqual('["张三",25]');
      });
    });

    describe('parse - preserve 格式', () => {
      it('preserve 模式下单个变量应返回原值', async () => {
        const result = await VariableParser.parse('{name}', context, { format: 'preserve' });
        expect(result).assertEqual('张三');
      });

      it('preserve 模式下对象变量应返回对象', async () => {
        const result = await VariableParser.parse('{user}', context, { format: 'preserve' });
        expect(typeof result).assertEqual('object');
        expect((result as any).name).assertEqual('李四');
      });

      it('preserve 模式下混合文本应返回字符串', async () => {
        const result = await VariableParser.parse('Hello {name}', context, { format: 'preserve' });
        expect(result).assertEqual('Hello 张三');
      });
    });

    describe('parse - 嵌套变量', () => {
      it('应该解析嵌套变量', async () => {
        context.setVariable('outer', 'name');
        const result = await VariableParser.parse('{outer}', context);
        expect(result).assertEqual('张三');
      });

      it('应该限制嵌套深度', async () => {
        context.setVariable('lvl1', '{lvl2}');
        context.setVariable('lvl2', '{lvl3}');
        context.setVariable('lvl3', '{lvl4}');
        context.setVariable('lvl4', 'final');
        const result = await VariableParser.parse('{lvl1}', context, { maxDepth: 3 });
        expect(result).assertEqual('final');
      });

      it('应该防止无限循环', async () => {
        context.setVariable('loop', '{loop}');
        const result = await VariableParser.parse('{loop}', context, { maxDepth: 5 });
        expect(typeof result).assertEqual('string');
      });

      it('应该正确解析三层嵌套变量', async () => {
        const result = await VariableParser.parse('{outer}', context);
        expect(result).assertEqual('final_value');
      });
    });

    describe('parse - 改进的递归检测', () => {
      it('JSON 字符串不应触发递归', async () => {
        const result = await VariableParser.parse('{json_config}', context);
        expect(result).assertEqual('{"key":"value"}');
      });

      it('正则表达式不应触发递归', async () => {
        const result = await VariableParser.parse('Pattern: {regex_pattern}', context);
        expect(result).assertEqual('Pattern: \\d{3}');
      });

      it('JSON 字符串中的花括号不应误判', async () => {
        const result = await VariableParser.parse('{json_with_var}', context);
        expect(result).assertEqual('{"template":"Hello {name}"}');
      });

      it('嵌套变量仍然正常工作', async () => {
        const result = await VariableParser.parse('{outer}', context, { maxDepth: 5, enableLogging: true });
        expect(result).assertEqual('final_value');
      });
    });

    describe('parse - 日志复制功能', () => {
      it('应该复制详细日志到剪贴板', async () => {
        const result = await VariableParser.parse('Hello {name}', context, {
          enableLogging: true,
          copyLog: true
        });
        expect(result).assertEqual('Hello 张三');

        const lastLog = VariableParser.getLastLog();
        expect(lastLog).assertLarger(0);
        expect(lastLog).assertContain('VariableParser Log');
        expect(lastLog).assertContain('Input:');
        expect(lastLog).assertContain('Result:');
      });

      it('应该保留历史日志', async () => {
        VariableParser.clearLogs();

        await VariableParser.parse('Hello {name}', context, { copyLog: true });
        await VariableParser.parse('{age} years old', context, { copyLog: true });

        const lastLog = VariableParser.getLastLog();
        expect(lastLog).assertContain('{age}');
      });

      it('应该清空日志', () => {
        VariableParser.clearLogs();
        const log = VariableParser.getLastLog();
        expect(log).assertEqual('');
      });

      it('日志格式应该包含所有信息', async () => {
        const result = await VariableParser.parse('{name} is {age}', context, {
          enableLogging: true,
          copyLog: true
        });
        expect(result).assertEqual('张三 is 25');

        const lastLog = VariableParser.getLastLog();
        expect(lastLog).assertContain('Timestamp:');
        expect(lastLog).assertContain('Duration:');
        expect(lastLog).assertContain('Depth:');
        expect(lastLog).assertContain('Input:');
        expect(lastLog).assertContain('Tokens:');
        expect(lastLog).assertContain('Result:');
        expect(lastLog).assertContain('Result Type:');
      });
    });

    describe('extractVariables', () => {
      it('应该提取单个变量', () => {
        const result = VariableParser.extractVariables('Hello {name}');
        expect(result.length).assertEqual(1);
        expect(result[0]).assertEqual('name');
      });

      it('应该提取多个变量', () => {
        const result = VariableParser.extractVariables('{a} and {b} and {c}');
        expect(result.length).assertEqual(3);
        expect(result).assertContain('a');
        expect(result).assertContain('b');
        expect(result).assertContain('c');
      });

      it('应该处理重复变量', () => {
        const result = VariableParser.extractVariables('{a} and {a}');
        expect(result.length).assertEqual(2);
        expect(result[0]).assertEqual('a');
        expect(result[1]).assertEqual('a');
      });

      it('应该处理空字符串', () => {
        const result = VariableParser.extractVariables('');
        expect(result.length).assertEqual(0);
      });

      it('应该处理无变量的字符串', () => {
        const result = VariableParser.extractVariables('Hello World');
        expect(result.length).assertEqual(0);
      });

      it('应该处理连续变量', () => {
        const result = VariableParser.extractVariables('{a}{b}{c}');
        expect(result.length).assertEqual(3);
      });

      it('应该处理空变量名', () => {
        const result = VariableParser.extractVariables('{}');
        expect(result.length).assertEqual(1);
        expect(result[0]).assertEqual('');
      });

      it('应该处理带特殊字符的变量名', () => {
        const result = VariableParser.extractVariables('{user_name}');
        expect(result.length).assertEqual(1);
        expect(result[0]).assertEqual('user_name');
      });

      it('应该处理嵌套大括号', () => {
        const result = VariableParser.extractVariables('{a{b}c}');
        expect(result.length).assertEqual(0);
      });
    });

    describe('isValidVariableName', () => {
      it('应该接受有效的变量名 - 简单', () => {
        expect(VariableParser.isValidVariableName('name')).assertTrue();
      });

      it('应该接受有效的变量名 - 带数字', () => {
        expect(VariableParser.isValidVariableName('var1')).assertTrue();
      });

      it('应该接受有效的变量名 - 带下划线', () => {
        expect(VariableParser.isValidVariableName('var_name')).assertTrue();
      });

      it('应该接受有效的变量名 - 带点号', () => {
        expect(VariableParser.isValidVariableName('user.name')).assertTrue();
      });

      it('应该接受有效的变量名 - 大写字母', () => {
        expect(VariableParser.isValidVariableName('UserName')).assertTrue();
      });

      it('应该拒绝无效的变量名 - 数字开头', () => {
        expect(VariableParser.isValidVariableName('1var')).assertFalse();
      });

      it('应该拒绝无效的变量名 - 特殊字符', () => {
        expect(VariableParser.isValidVariableName('var-name')).assertFalse();
      });

      it('应该拒绝无效的变量名 - 空字符串', () => {
        expect(VariableParser.isValidVariableName('')).assertFalse();
      });

      it('应该拒绝无效的变量名 - null', () => {
        expect(VariableParser.isValidVariableName(null as any)).assertFalse();
      });

      it('应该拒绝无效的变量名 - undefined', () => {
        expect(VariableParser.isValidVariableName(undefined as any)).assertFalse();
      });
    });

    describe('边界情况', () => {
      it('应该处理变量在开头', async () => {
        const result = await VariableParser.parse('{name} World', context);
        expect(result).assertEqual('张三 World');
      });

      it('应该处理变量在结尾', async () => {
        const result = await VariableParser.parse('Hello {name}', context);
        expect(result).assertEqual('Hello 张三');
      });

      it('应该处理连续变量', async () => {
        context.setVariable('a', 'A');
        context.setVariable('b', 'B');
        const result = await VariableParser.parse('{a}{b}', context);
        expect(result).assertEqual('AB');
      });

      it('应该处理空变量值', async () => {
        const result = await VariableParser.parse('Start{}End', context);
        expect(result).assertEqual('Start{}End');
      });

      it('应该处理嵌套大括号', async () => {
        const result = await VariableParser.parse('Hello {a{b}c}', context);
        expect(result).assertEqual('Hello {a{b}c}');
      });

      it('应该处理大数字', async () => {
        context.setVariable('big', 9999999999999);
        const result = await VariableParser.parse('Value: {big}', context);
        expect(result).assertEqual('Value: 9999999999999');
      });

      it('应该处理浮点数', async () => {
        context.setVariable('pi', 3.14159);
        const result = await VariableParser.parse('Pi: {pi}', context);
        expect(result).assertEqual('Pi: 3.14159');
      });

      it('应该处理布尔值', async () => {
        context.setVariable('flag', true);
        const result = await VariableParser.parse('Flag: {flag}', context);
        expect(result).assertEqual('Flag: true');
      });
    });

    describe('性能测试', () => {
      it('应该快速处理简单变量', async () => {
        const start = Date.now();
        for (let i = 0; i < 1000; i++) {
          await VariableParser.parse('Hello {name}', context);
        }
        const elapsed = Date.now() - start;
        expect(elapsed).assertLarger(0);
        expect(elapsed).assertLess(5000);
      });

      it('应该快速处理复杂变量', async () => {
        const input = '{a}{b}{c}{d}{e}{f}{g}{h}{i}{j}';
        for (let i = 0; i < 10; i++) {
          context.setVariable(String.fromCharCode(97 + i), `value${i}`);
        }
        const start = Date.now();
        for (let i = 0; i < 1000; i++) {
          await VariableParser.parse(input, context);
        }
        const elapsed = Date.now() - start;
        expect(elapsed).assertLarger(0);
        expect(elapsed).assertLess(5000);
      });
    });
  });
}
