import preferences from '@ohos.data.preferences';
import { Workflow, WorkflowStats, ConfigDisplayItem, ConfigOption } from '../models/WorkflowModels';
import { getConfigDisplayTemplate } from '../data/ConfigTemplates';
import { ACTION_DATA, TRIGGER_DATA, LOGIC_DATA } from '../data/WorkflowData';

const PREF_NAME = 'workflow_preferences';
const KEY_WORKFLOWS = 'workflows_list';
const KEY_WORKFLOW_PREFIX = 'workflow_';

export class WorkflowDataManager {
  private static instance: WorkflowDataManager;
  private preferences: preferences.Preferences | null = null;
  private workflows: Workflow[] = [];
  private isInitialized: boolean = false;

  private constructor() {}

  public static getInstance(): WorkflowDataManager {
    if (!WorkflowDataManager.instance) {
      WorkflowDataManager.instance = new WorkflowDataManager();
    }
    return WorkflowDataManager.instance;
  }

  public async init(context: Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      this.preferences = await preferences.getPreferences(context, PREF_NAME);
      await this.loadWorkflows();
      this.isInitialized = true;
      console.info('[WorkflowDataManager] Initialized successfully');
    } catch (error) {
      console.error('[WorkflowDataManager] Init failed:', error);
      throw new Error('WorkflowDataManager init failed: ' + (error as Error).message);
    }
  }

  private async loadWorkflows(): Promise<void> {
    if (!this.preferences) {
      console.warn('[WorkflowDataManager] Preferences not initialized');
      return;
    }

    try {
      const workflowIds = await this.preferences.get(KEY_WORKFLOWS, '[]') as string;
      const idArray: string[] = JSON.parse(workflowIds);

      this.workflows = [];
      for (const id of idArray) {
        const workflowJson = await this.preferences.get(KEY_WORKFLOW_PREFIX + id, '{}') as string;
        const workflow: Workflow = JSON.parse(workflowJson);
        this.workflows.push(workflow);
      }

      console.info(`[WorkflowDataManager] Loaded ${this.workflows.length} workflows`);
    } catch (error) {
      console.error('[WorkflowDataManager] Load workflows failed:', error);
      this.workflows = [];
    }
  }

  private async saveWorkflowIds(): Promise<void> {
    if (!this.preferences) {
      return;
    }

    try {
      const ids = this.workflows.map(w => w.id);
      await this.preferences.put(KEY_WORKFLOWS, JSON.stringify(ids));
      await this.preferences.flush();
    } catch (error) {
      console.error('[WorkflowDataManager] Save workflow IDs failed:', error);
    }
  }

  private async saveWorkflowToPrefs(workflow: Workflow): Promise<void> {
    if (!this.preferences) {
      return;
    }

    try {
      const key = KEY_WORKFLOW_PREFIX + workflow.id;
      await this.preferences.put(key, JSON.stringify(workflow));
      await this.preferences.flush();
    } catch (error) {
      console.error('[WorkflowDataManager] Save workflow failed:', error);
    }
  }

  public getWorkflows(): Workflow[] {
    return [...this.workflows];
  }

  public getWorkflow(id: string): Workflow | undefined {
    return this.workflows.find(w => w.id === id);
  }

  public async createWorkflow(workflow: Workflow): Promise<void> {
    if (!workflow.id) {
      workflow.id = Date.now().toString();
    }

    if (!workflow.createdAt) {
      workflow.createdAt = Date.now();
    }

    workflow.updatedAt = Date.now();

    this.workflows.push(workflow);
    await this.saveWorkflowToPrefs(workflow);
    await this.saveWorkflowIds();

    console.info(`[WorkflowDataManager] Created workflow: ${workflow.id}`);
  }

  public async updateWorkflow(workflow: Workflow): Promise<void> {
    const index = this.workflows.findIndex(w => w.id === workflow.id);
    if (index === -1) {
      console.warn(`[WorkflowDataManager] Workflow not found: ${workflow.id}`);
      return;
    }

    workflow.updatedAt = Date.now();
    this.workflows[index] = workflow;

    await this.saveWorkflowToPrefs(workflow);

    console.info(`[WorkflowDataManager] Updated workflow: ${workflow.id}`);
  }

  public async deleteWorkflow(id: string): Promise<void> {
    const index = this.workflows.findIndex(w => w.id === id);
    if (index === -1) {
      console.warn(`[WorkflowDataManager] Workflow not found: ${id}`);
      return;
    }

    this.workflows.splice(index, 1);

    if (this.preferences) {
      try {
        const key = KEY_WORKFLOW_PREFIX + id;
        await this.preferences.delete(key);
        await this.preferences.flush();
        await this.saveWorkflowIds();
      } catch (error) {
        console.error('[WorkflowDataManager] Delete workflow failed:', error);
      }
    }

    console.info(`[WorkflowDataManager] Deleted workflow: ${id}`);
  }

  public getStats(): WorkflowStats {
    const totalWorkflows = this.workflows.length;
    const enabledWorkflows = this.workflows.filter(w => w.isEnabled).length;
    const triggerCount = this.workflows.reduce((sum, w) => sum + w.triggerCount, 0);
    const actionCount = this.workflows.reduce((sum, w) => sum + w.actionCount, 0);

    return {
      totalWorkflows,
      enabledWorkflows,
      triggerCount,
      actionCount
    };
  }

  public async toggleWorkflowEnabled(id: string): Promise<void> {
    const workflow = this.getWorkflow(id);
    if (!workflow) {
      return;
    }

    workflow.isEnabled = !workflow.isEnabled;
    await this.updateWorkflow(workflow);

    console.info(`[WorkflowDataManager] Toggled workflow ${id} to ${workflow.isEnabled}`);
  }

  public   async duplicateWorkflow(id: string): Promise<Workflow | undefined> {
    const original = this.getWorkflow(id);
    if (!original) {
      return undefined;
    }

    const originalJson = JSON.stringify(original);
    const parsed = JSON.parse(originalJson) as Workflow;

    const duplicate: Workflow = {
      id: parsed.id,
      name: parsed.name,
      description: parsed.description,
      icon: parsed.icon,
      iconColor: parsed.iconColor,
      createdAt: parsed.createdAt,
      updatedAt: parsed.updatedAt,
      isEnabled: parsed.isEnabled,
      triggerCount: parsed.triggerCount,
      actionCount: parsed.actionCount,
      nodes: parsed.nodes
    };

    duplicate.id = Date.now().toString();
    duplicate.name = `${original.name} (副本)`;
    duplicate.createdAt = Date.now();
    duplicate.updatedAt = Date.now();

    await this.createWorkflow(duplicate);
    return duplicate;
  }

  public clearCache(): void {
    this.workflows = [];
  }

  public async refresh(): Promise<void> {
    await this.loadWorkflows();
  }

  public getActionConfigDisplay(itemId: string, config?: Record<string, string | number | boolean>): ConfigDisplayItem[] | undefined {
    const template = getConfigDisplayTemplate(itemId);
    if (!template) {
      return undefined;
    }

    const display: ConfigDisplayItem[] = template.map(item => {
      const displayItem: ConfigDisplayItem = {
        displayType: item.displayType,
        label: item.label,
        configKey: item.configKey,
        style: undefined,
        validation: undefined
      };

      if (item.style) {
        displayItem.style = {
          backgroundColor: item.style.backgroundColor,
          textColor: item.style.textColor,
          borderColor: item.style.borderColor,
          icon: item.style.icon,
          avatar: item.style.avatar
        };
      }

      if (item.validation) {
        displayItem.validation = {
          type: item.validation.type,
          required: item.validation.required,
          pattern: item.validation.pattern,
          min: item.validation.min,
          max: item.validation.max
        };
      }

      if (config && item.configKey) {
        const value = config[item.configKey];
        if (value !== undefined) {
          const displayValue = this.getDisplayValue(itemId, item.configKey, value);
          displayItem.label = displayValue !== undefined ? displayValue : String(value);
        }
      }

      return displayItem;
    });

    return display;
  }

  private getDisplayValue(itemId: string, configKey: string, value: string | number | boolean): string | undefined {
    const action = ACTION_DATA.find(a => a.id === itemId);
    if (action && action.configs) {
      const configDef = action.configs.find(c => c.key === configKey);
      if (configDef && configDef.options) {
        const option = configDef.options.find(opt => opt.value === String(value));
        return option ? option.label : undefined;
      }
    }

    const logic = LOGIC_DATA.find(l => l.id === itemId);
    if (logic && logic.configs) {
      const configDef = logic.configs.find(c => c.key === configKey);
      if (configDef && configDef.options) {
        const option = configDef.options.find(opt => opt.value === String(value));
        return option ? option.label : undefined;
      }
    }

    const trigger = TRIGGER_DATA.find(t => t.id === itemId);
    if (trigger && trigger.configs) {
      const configDef = trigger.configs.find(c => c.key === configKey);
      if (configDef && configDef.options) {
        const option = configDef.options.find(opt => opt.value === String(value));
        return option ? option.label : undefined;
      }
    }

    return undefined;
  }

  public getTriggerConfigDisplay(itemId: string, config?: Record<string, string | number | boolean>): ConfigDisplayItem[] | undefined {
    const template = getConfigDisplayTemplate(itemId);
    if (!template) {
      return undefined;
    }

    const display: ConfigDisplayItem[] = template.map(item => {
      const displayItem: ConfigDisplayItem = {
        displayType: item.displayType,
        label: item.label,
        configKey: item.configKey,
        style: undefined,
        validation: undefined
      };

      if (item.style) {
        displayItem.style = {
          backgroundColor: item.style.backgroundColor,
          textColor: item.style.textColor,
          borderColor: item.style.borderColor,
          icon: item.style.icon,
          avatar: item.style.avatar
        };
      }

      if (item.validation) {
        displayItem.validation = {
          type: item.validation.type,
          required: item.validation.required,
          pattern: item.validation.pattern,
          min: item.validation.min,
          max: item.validation.max
        };
      }

      if (config && item.configKey) {
        const value = config[item.configKey];
        if (value !== undefined) {
          const displayValue = this.getDisplayValue(itemId, item.configKey, value);
          displayItem.label = displayValue !== undefined ? displayValue : String(value);
        }
      }

      return displayItem;
    });

    return display;
  }

  private getDefaultConfigValues(itemId: string): Record<string, Object> {
    const config: Record<string, Object> = {};

    const action = ACTION_DATA.find(a => a.id === itemId);
    if (action && action.configs) {
      action.configs.forEach(c => {
        if (c.defaultValue !== undefined) {
          config[c.key] = c.defaultValue;
        }
      });
    }

    const trigger = TRIGGER_DATA.find(t => t.id === itemId);
    if (trigger && trigger.configs) {
      trigger.configs.forEach(c => {
        if (c.defaultValue !== undefined) {
          config[c.key] = c.defaultValue;
        }
      });
    }

    const logic = LOGIC_DATA.find(l => l.id === itemId);
    if (logic && logic.configs) {
      logic.configs.forEach(c => {
        if (c.defaultValue !== undefined) {
          config[c.key] = c.defaultValue;
        }
      });
    }

    return config;
  }
}
