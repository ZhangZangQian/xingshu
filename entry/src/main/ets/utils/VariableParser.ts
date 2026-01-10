import { ExecutionContextImpl } from '../models/ExecutionContext';
import { JsonUtils } from './JsonUtils';
import { ClipboardService } from '../services/ClipboardService';

enum TokenType {
  TEXT = 'TEXT',
  VARIABLE = 'VARIABLE'
}

interface Token {
  type: TokenType;
  value: string;
  startPos: number;
  endPos: number;
}

export interface ParseOptions {
  format?: 'string' | 'json' | 'preserve';
  skipMissing?: boolean;
  maxDepth?: number;
  enableLogging?: boolean;
  copyLog?: boolean;
}

export interface ResolveResult {
  result: any;
  format: 'string' | 'json' | 'object';
  tokens: Array<{ token: Token; value: any }>;
}

class VariableTokenizer {
  private static readonly VARIABLE_PATTERN = /\{([^{}]+)\}/g;

  static tokenize(input: string): Token[] {
    if (!input) return [];

    const tokens: Token[] = [];
    let lastIndex = 0;
    let match: RegExpExecArray | null;

    while ((match = this.VARIABLE_PATTERN.exec(input)) !== null) {
      if (match.index > lastIndex) {
        tokens.push({
          type: TokenType.TEXT,
          value: input.slice(lastIndex, match.index),
          startPos: lastIndex,
          endPos: match.index
        });
      }

      tokens.push({
        type: TokenType.VARIABLE,
        value: match[1],
        startPos: match.index,
        endPos: match.index + match[0].length
      });

      lastIndex = match.index + match[0].length;
    }

    if (lastIndex < input.length) {
      tokens.push({
        type: TokenType.TEXT,
        value: input.slice(lastIndex),
        startPos: lastIndex,
        endPos: input.length
      });
    }

    return tokens;
  }
}

class VariableResolver {
  static async resolve(
    tokens: Token[],
    context: ExecutionContextImpl,
    options: ParseOptions = {}
  ): Promise<ResolveResult> {
    const { format = 'string', skipMissing = true } = options;

    const resolvedTokens = await Promise.all(
      tokens.map(async (token) => {
        if (token.type === TokenType.TEXT) {
          return { token, value: token.value };
        }

        const value = await context.getVariable(token.value);
        return { token, value };
      })
    );

    if (format === 'preserve' && resolvedTokens.length === 1 &&
        resolvedTokens[0].token.type === TokenType.VARIABLE) {
      const value = resolvedTokens[0].value;
      return {
        result: value,
        format: 'object',
        tokens: resolvedTokens
      };
    }

    const stringParts = resolvedTokens.map(rt => {
      if (rt.token.type === TokenType.TEXT) {
        return rt.value;
      }
      return this.formatValue(rt.value);
    });

    const result = stringParts.join('');

    if (format === 'json') {
      return {
        result: JsonUtils.parseJSONSafely(result, result),
        format: 'json',
        tokens: resolvedTokens
      };
    }

    return {
      result,
      format: 'string',
      tokens: resolvedTokens
    };
  }

  private static formatValue(value: any): string {
    if (value === null || value === undefined) return '';
    if (typeof value === 'object') return JSON.stringify(value);
    // 对字符串值进行 JSON 转义，确保换行符、双引号等特殊字符正确转义
    return JSON.stringify(String(value)).slice(1, -1);
  }
}

export class VariableParser {
  private static readonly DEFAULT_OPTIONS: ParseOptions = {
    format: 'string',
    skipMissing: true,
    maxDepth: 5,
    enableLogging: false,
    copyLog: false
  };

  private static logBuffer: string[] = [];

  static async parse(
    input: string,
    context: ExecutionContextImpl,
    options: ParseOptions = {}
  ): Promise<string | any> {
    const opts = { ...this.DEFAULT_OPTIONS, ...options };
    const startTime = Date.now();

    const tokens = VariableTokenizer.tokenize(input);

    if (tokens.every(t => t.type === TokenType.TEXT)) {
      if (opts.enableLogging) {
        const elapsed = Date.now() - startTime;
        console.log(`[VariableParser] parse (no variables): ${elapsed}ms, input: "${input}"`);
      }
      return this.formatOutput(input, opts.format);
    }

    const result = await VariableResolver.resolve(tokens, context, opts);

    if (opts.maxDepth > 0 && this.shouldRecurse(tokens, result.tokens)) {
      const nestedResult = await this.parse(
        String(result.result),
        context,
        { ...opts, maxDepth: opts.maxDepth - 1 }
      );

      if (opts.format === 'json' && typeof nestedResult === 'string') {
        const elapsed = Date.now() - startTime;
        if (opts.enableLogging) {
          console.log(`[VariableParser] parse (nested): ${elapsed}ms, input: "${input}"`);
        }
        if (opts.copyLog) {
          const log = this.formatLog(input, tokens, result.tokens, nestedResult, 1, elapsed);
          console.log(log);
          await this.copyLogToClipboard(log);
        }
        return JsonUtils.parseJSONSafely(nestedResult, nestedResult);
      }

      const elapsed = Date.now() - startTime;
      if (opts.enableLogging) {
        console.log(`[VariableParser] parse (nested): ${elapsed}ms, input: "${input}"`);
      }
      if (opts.copyLog) {
        const log = this.formatLog(input, tokens, result.tokens, nestedResult, 1, elapsed);
        console.log(log);
        await this.copyLogToClipboard(log);
      }
      return nestedResult;
    }

    const elapsed = Date.now() - startTime;
    if (opts.enableLogging) {
      console.log(`[VariableParser] parse: ${elapsed}ms, input: "${input}", result: "${result.result}"`);
    }
    if (opts.copyLog) {
      const log = this.formatLog(input, tokens, result.tokens, result.result, 0, elapsed);
      console.log(log);
      await this.copyLogToClipboard(log);
    }

    return result.result;
  }

  static extractVariables(input: string): string[] {
    const tokens = VariableTokenizer.tokenize(input);
    return tokens
      .filter(t => t.type === TokenType.VARIABLE)
      .map(t => t.value);
  }

  static isValidVariableName(name: string): boolean {
    if (!name || typeof name !== 'string') return false;
    return /^[a-zA-Z][a-zA-Z0-9_\.]*$/.test(name);
  }

  private static formatOutput(value: any, format: ParseOptions['format']): any {
    if (format === 'json' && typeof value === 'string') {
      return JsonUtils.parseJSONSafely(value, value);
    }
    return value;
  }

  private static shouldRecurse(
    originalTokens: Token[],
    resolvedTokens: Array<{ token: Token; value: any }>
  ): boolean {
    const variableTokens = originalTokens.filter(t => t.type === TokenType.VARIABLE);

    if (variableTokens.length === 0) {
      return false;
    }

    for (const resolvedToken of resolvedTokens) {
      if (resolvedToken.token.type === TokenType.VARIABLE) {
        const value = resolvedToken.value;

        if (typeof value === 'string') {
          const nestedTokens = VariableTokenizer.tokenize(value);
          const hasVariables = nestedTokens.some(t => t.type === TokenType.VARIABLE);

          if (hasVariables) {
            if (this.DEFAULT_OPTIONS.enableLogging) {
              console.log(`[VariableParser] shouldRecurse: true, variable: "${resolvedToken.token.value}", value: "${value}"`);
            }
            return true;
          }
        }
      }
    }

    return false;
  }

  private static formatLog(
    input: string,
    tokens: Token[],
    resolvedTokens: Array<{ token: Token; value: any }>,
    result: any,
    depth: number = 0,
    duration: number = 0
  ): string {
    const timestamp = new Date().toISOString();
    const indent = '  '.repeat(depth);

    let log = `=== VariableParser Log ===\n`;
    log += `Timestamp: ${timestamp}\n`;
    log += `Duration: ${duration}ms\n`;
    log += `Depth: ${depth}\n`;
    log += `\n`;

    log += `${indent}Input: "${input}"\n`;
    log += `${indent}Tokens: ${tokens.length}\n`;

    tokens.forEach((token, index) => {
      const resolvedValue = resolvedTokens[index]?.value;
      const type = token.type === TokenType.TEXT ? 'TEXT' : 'VARIABLE';
      const displayValue = typeof resolvedValue === 'string' && resolvedValue.length > 100
        ? resolvedValue.substring(0, 100) + '...'
        : String(resolvedValue);

      if (token.type === TokenType.VARIABLE) {
        log += `${indent}  [${index + 1}] ${type}: {${token.value}}\n`;
        if (resolvedValue !== undefined) {
          log += `${indent}       → ${displayValue}\n`;
        } else {
          log += `${indent}       → undefined (not found)\n`;
        }
      } else {
        const displayText = token.value.length > 100
          ? token.value.substring(0, 100) + '...'
          : token.value;
        log += `${indent}  [${index + 1}] ${type}: "${displayText}"\n`;
      }
    });

    log += `\n`;
    log += `${indent}Result: ${JSON.stringify(result, null, 2)}\n`;
    log += `${indent}Result Type: ${typeof result}\n`;
    log += `========================\n`;

    return log;
  }

  private static async copyLogToClipboard(log: string): Promise<void> {
    try {
      this.logBuffer.push(log);
      const clipboardService = ClipboardService.getInstance();
      await clipboardService.writeText(log);
      console.log(`[VariableParser] Log copied to clipboard (${log.length} chars)`);
    } catch (error) {
      console.error(`[VariableParser] Failed to copy log to clipboard:`, error);
    }
  }

  public static getLastLog(): string {
    return this.logBuffer.length > 0
      ? this.logBuffer[this.logBuffer.length - 1]
      : '';
  }

  public static clearLogs(): void {
    this.logBuffer = [];
  }
}