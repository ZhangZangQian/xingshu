import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export type ThemeMode = 'auto' | 'light' | 'dark';

@Observed
export class ThemeManager {
  private static instance: ThemeManager;
  private currentThemeMode: ThemeMode = 'auto';
  private isDark: boolean = false;
  private preferences: preferences.Preferences | null = null;
  private listeners: Array<(isDark: boolean) => void> = [];

  private constructor() {}

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  async init(context: common.Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, 'theme_settings');
      this.currentThemeMode = (await this.preferences.get('themeMode', 'auto')) as ThemeMode;
      this.updateThemeStatus();
    } catch (error) {
      console.error('ThemeManager init failed:', error);
    }
  }

  getCurrentThemeMode(): ThemeMode {
    return this.currentThemeMode;
  }

  async setThemeMode(mode: ThemeMode): Promise<void> {
    if (this.currentThemeMode === mode) {
      return;
    }

    this.currentThemeMode = mode;
    
    if (this.preferences) {
      try {
        await this.preferences.put('themeMode', mode);
        await this.preferences.flush();
      } catch (error) {
        console.error('ThemeManager save failed:', error);
      }
    }

    this.updateThemeStatus();
    this.notifyListeners();
  }

  isDarkMode(): boolean {
    return this.isDark;
  }

  private updateThemeStatus(): void {
    if (this.currentThemeMode === 'auto') {
      const isSystemDark = this.checkSystemDarkMode();
      this.isDark = isSystemDark;
    } else {
      this.isDark = this.currentThemeMode === 'dark';
    }
  }

  private checkSystemDarkMode(): boolean {
    return false;
  }

  onThemeChange(callback: (isDark: boolean) => void): void {
    this.listeners.push(callback);
  }

  offThemeChange(callback: (isDark: boolean) => void): void {
    const index = this.listeners.indexOf(callback);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach(callback => {
      try {
        callback(this.isDark);
      } catch (error) {
        console.error('ThemeManager listener error:', error);
      }
    });
  }
}

export const themeManager = ThemeManager.getInstance();
