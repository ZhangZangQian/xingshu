export enum VariableScope {
  GLOBAL = 'global',
  MACRO = 'macro'
}

export enum VariableType {
  STRING = 'string',
  NUMBER = 'number',
  BOOLEAN = 'boolean',
  OBJECT = 'object',
  ARRAY = 'array'
}

export type VariableValue =
  | string
  | number
  | boolean
  | Record<string, any>
  | any[];

export interface Variable {
  id: number;
  scope: VariableScope;
  macroId?: number;
  name: string;
  type: VariableType;
  value: VariableValue;
  createdAt: number;
  updatedAt: number;
}

export interface VariableInput {
  scope: VariableScope;
  macroId?: number;
  name: string;
  type: VariableType;
  value: VariableValue;
  createdAt: number;
  updatedAt: number;
}

export function isVariableValueTypeMatch(type: VariableType, value: unknown): value is VariableValue {
  switch (type) {
    case VariableType.STRING:
      return typeof value === 'string';
    case VariableType.NUMBER:
      return typeof value === 'number' && Number.isFinite(value);
    case VariableType.BOOLEAN:
      return typeof value === 'boolean';
    case VariableType.OBJECT:
      return isJSONObject(value);
    case VariableType.ARRAY:
      return isJSONArray(value);
    default:
      return false;
  }
}

export function isJSONObject(value: unknown): value is Record<string, any> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function isJSONArray(value: unknown): value is any[] {
  return Array.isArray(value);
}

export function ensureVariableValueType(type: VariableType, value: unknown): asserts value is VariableValue {
  if (!isVariableValueTypeMatch(type, value)) {
    throw new Error('变量值类型不匹配');
  }
}

export function serializeVariableValue(value: VariableValue): string {
  return JSON.stringify(value);
}

export function deserializeVariableValue(type: VariableType, value: string): VariableValue {
  let parsed: unknown;
  try {
    parsed = JSON.parse(value);
  } catch (error) {
    throw new Error('变量值 JSON 解析失败');
  }

  switch (type) {
    case VariableType.STRING:
      if (typeof parsed !== 'string') throw new Error('Expected string');
      return parsed;
    case VariableType.NUMBER:
      if (typeof parsed !== 'number') throw new Error('Expected number');
      return parsed;
    case VariableType.BOOLEAN:
      if (typeof parsed !== 'boolean') throw new Error('Expected boolean');
      return parsed;
    case VariableType.OBJECT:
      if (!isJSONObject(parsed)) throw new Error('Expected object');
      return parsed;
    case VariableType.ARRAY:
      if (!isJSONArray(parsed)) throw new Error('Expected array');
      return parsed;
    default:
      throw new Error(`Unknown type: ${type}`);
  }
}
