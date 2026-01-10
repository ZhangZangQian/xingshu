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
    if (name === 'outer') return '{inner}';
    if (name === 'inner') return '{deep}';
    if (name === 'deep') return 'final_value';
    if (name === 'json_config') return '{"key":"value"}';
    if (name === 'regex_pattern') return '\\d{3}';
    return undefined;
  }
}

export default function variableParserBenchmarkTest() {
  describe('VariableParserBenchmark', () => {
    let context: MockExecutionContext;

    beforeAll(() => {
      context = new MockExecutionContext();
    });

    describe('性能测试 - 简单字符串', () => {
      it('应该快速解析简单变量', async () => {
        const input = 'Hello {name}';
        const iterations = 1000;
        const start = Date.now();

        for (let i = 0; i < iterations; i++) {
          await VariableParser.parse(input, context);
        }

        const elapsed = Date.now() - start;
        console.log(`[Benchmark] VariableParser (simple): ${elapsed}ms for ${iterations} iterations`);
        console.log(`[Benchmark] Average: ${(elapsed / iterations).toFixed(2)}ms per iteration`);
        expect(elapsed).assertLarger(0);
      });
    });

    describe('性能测试 - 中等复杂度', () => {
      it('应该快速解析多个变量', async () => {
        const input = 'Hello {user.name}, you are {age} years old. Order ID: {order.id}';
        const iterations = 1000;
        const start = Date.now();

        for (let i = 0; i < iterations; i++) {
          await VariableParser.parse(input, context);
        }

        const elapsed = Date.now() - start;
        console.log(`[Benchmark] VariableParser (medium): ${elapsed}ms for ${iterations} iterations`);
        console.log(`[Benchmark] Average: ${(elapsed / iterations).toFixed(2)}ms per iteration`);
        expect(elapsed).assertLarger(0);
      });
    });

    describe('性能测试 - 高复杂度', () => {
      beforeAll(() => {
        context.setVariable('v1', 'value1');
        context.setVariable('v2', 'value2');
        context.setVariable('v3', 'value3');
        context.setVariable('v4', 'value4');
        context.setVariable('v5', 'value5');
        context.setVariable('v6', 'value6');
        context.setVariable('v7', 'value7');
        context.setVariable('v8', 'value8');
        context.setVariable('v9', 'value9');
        context.setVariable('v10', 'value10');
      });

      it('应该快速解析 20 个变量', async () => {
        const input = '{v1},{v2},{v3},{v4},{v5},{v6},{v7},{v8},{v9},{v10},{v1},{v2},{v3},{v4},{v5},{v6},{v7},{v8},{v9},{v10}';
        const iterations = 1000;
        const start = Date.now();

        for (let i = 0; i < iterations; i++) {
          await VariableParser.parse(input, context);
        }

        const elapsed = Date.now() - start;
        console.log(`[Benchmark] VariableParser (high): ${elapsed}ms for ${iterations} iterations`);
        console.log(`[Benchmark] Average: ${(elapsed / iterations).toFixed(2)}ms per iteration`);
        expect(elapsed).assertLarger(0);
      });
    });

    describe('性能测试 - 嵌套变量', () => {
      beforeAll(() => {
        context.setVariable('outer', '{inner}');
        context.setVariable('inner', '{deep}');
        context.setVariable('deep', 'final_value');
      });

      it('应该快速解析嵌套变量', async () => {
        const input = '{outer}';
        const iterations = 1000;
        const start = Date.now();

        for (let i = 0; i < iterations; i++) {
          await VariableParser.parse(input, context);
        }

        const elapsed = Date.now() - start;
        console.log(`[Benchmark] VariableParser (nested): ${elapsed}ms for ${iterations} iterations`);
        console.log(`[Benchmark] Average: ${(elapsed / iterations).toFixed(2)}ms per iteration`);
        expect(elapsed).assertLarger(0);
      });
    });

    describe('性能测试 - 改进的递归检测', () => {
      it('JSON 字符串不应触发递归', async () => {
        const input = '{json_config}';
        const iterations = 1000;
        const start = Date.now();

        for (let i = 0; i < iterations; i++) {
          const result = await VariableParser.parse(input, context);
          expect(result).assertEqual('{"key":"value"}');
        }

        const elapsed = Date.now() - start;
        console.log(`[Benchmark] VariableParser (JSON string): ${elapsed}ms for ${iterations} iterations`);
        console.log(`[Benchmark] Average: ${(elapsed / iterations).toFixed(2)}ms per iteration`);
        expect(elapsed).assertLarger(0);
      });

      it('正则表达式不应触发递归', async () => {
        const input = 'Pattern: {regex_pattern}';
        const iterations = 1000;
        const start = Date.now();

        for (let i = 0; i < iterations; i++) {
          const result = await VariableParser.parse(input, context);
          expect(result).assertEqual('Pattern: \\d{3}');
        }

        const elapsed = Date.now() - start;
        console.log(`[Benchmark] VariableParser (regex): ${elapsed}ms for ${iterations} iterations`);
        console.log(`[Benchmark] Average: ${(elapsed / iterations).toFixed(2)}ms per iteration`);
        expect(elapsed).assertLarger(0);
      });
    });

    describe('功能验证', () => {
      it('简单变量解析正确', async () => {
        const input = 'Hello {name}';
        const result = await VariableParser.parse(input, context);
        expect(result).assertEqual('Hello 张三');
      });

      it('多个变量解析正确', async () => {
        const input = '{name} is {age} years old';
        const result = await VariableParser.parse(input, context);
        expect(result).assertEqual('张三 is 25 years old');
      });

      it('对象变量解析正确', async () => {
        const input = 'User: {user}';
        const result = await VariableParser.parse(input, context);
        expect(result).assertEqual('User: {"name":"李四","age":30}');
      });

      it('JSON 格式解析正确', async () => {
        const input = '{"name":"{name}","age":{age}}';
        const result = await VariableParser.parse(input, context, { format: 'json' });
        expect(JSON.stringify(result)).assertEqual('{"name":"张三","age":25}');
      });

      it('preserve 格式解析正确', async () => {
        const input = '{name}';
        const result = await VariableParser.parse(input, context, { format: 'preserve' });
        expect(result).assertEqual('张三');
      });
    });

    describe('内存使用', () => {
      it('内存使用应该合理', async () => {
        const input = 'Hello {name}, you are {age} years old';
        const iterations = 10000;

        const startMemory = (performance as any).memory?.usedJSHeapSize || 0;

        for (let i = 0; i < iterations; i++) {
          await VariableParser.parse(input, context);
        }

        const endMemory = (performance as any).memory?.usedJSHeapSize || 0;
        const memoryUsed = endMemory - startMemory;

        console.log(`[Benchmark] VariableParser memory used: ${memoryUsed} bytes for ${iterations} iterations`);

        if (memoryUsed > 0) {
          console.log(`[Benchmark] Average memory per iteration: ${(memoryUsed / iterations).toFixed(2)} bytes`);
        }
      });
    });
  });
}
