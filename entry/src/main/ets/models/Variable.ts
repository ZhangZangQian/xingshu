export enum VariableScope {
  GLOBAL = 'global',
  MACRO = 'macro'
}

export enum VariableType {
  STRING = 'string',
  NUMBER = 'number',
  BOOLEAN = 'boolean'
}

export type VariableValue = string | number | boolean;

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
    default:
      return false;
  }
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

  ensureVariableValueType(type, parsed);
  return parsed;
}
