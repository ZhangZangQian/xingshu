import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import common from '@ohos.app.ability.common';
import Logger from '../utils/Logger';

/**
 * 权限管理服务
 * 封装权限申请和检查逻辑
 */
export class PermissionService {
  private static instance: PermissionService;
  private atManager: abilityAccessCtrl.AtManager;

  private constructor() {
    this.atManager = abilityAccessCtrl.createAtManager();
  }

  public static getInstance(): PermissionService {
    if (!PermissionService.instance) {
      PermissionService.instance = new PermissionService();
    }
    return PermissionService.instance;
  }

  /**
   * 检查权限是否已授予
   */
  async checkPermission(permission: Permissions, context: common.UIAbilityContext): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const tokenId = bundleInfo.appInfo.accessTokenId;

      const grantStatus = await this.atManager.checkAccessToken(tokenId, permission);
      const granted = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      Logger.info('PermissionService', `Permission ${permission} check result: ${granted}`);
      return granted;
    } catch (error) {
      Logger.error('PermissionService', `Failed to check permission ${permission}`, error as Error);
      return false;
    }
  }

  /**
   * 申请单个权限
   */
  async requestPermission(permission: Permissions, context: common.UIAbilityContext): Promise<boolean> {
    try {
      // 先检查是否已授予
      const alreadyGranted = await this.checkPermission(permission, context);
      if (alreadyGranted) {
        Logger.info('PermissionService', `Permission ${permission} already granted`);
        return true;
      }

      // 申请权限
      Logger.info('PermissionService', `Requesting permission: ${permission}`);
      const grantStatus = await this.atManager.requestPermissionsFromUser(context, [permission]);

      const granted = grantStatus.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      if (granted) {
        Logger.info('PermissionService', `Permission ${permission} granted`);
      } else {
        Logger.warn('PermissionService', `Permission ${permission} denied`);
      }

      return granted;
    } catch (error) {
      Logger.error('PermissionService', `Failed to request permission ${permission}`, error as Error);
      return false;
    }
  }

  /**
   * 批量申请权限
   */
  async requestPermissions(permissions: Permissions[], context: common.UIAbilityContext): Promise<boolean> {
    try {
      // 过滤已授予的权限
      const permissionsToRequest: Permissions[] = [];
      for (const permission of permissions) {
        const granted = await this.checkPermission(permission, context);
        if (!granted) {
          permissionsToRequest.push(permission);
        }
      }

      if (permissionsToRequest.length === 0) {
        Logger.info('PermissionService', 'All permissions already granted');
        return true;
      }

      // 批量申请
      Logger.info('PermissionService', `Requesting ${permissionsToRequest.length} permissions`);
      const grantStatus = await this.atManager.requestPermissionsFromUser(context, permissionsToRequest);

      // 检查是否全部授予
      const allGranted = grantStatus.authResults.every(
        result => result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      );

      if (allGranted) {
        Logger.info('PermissionService', 'All permissions granted');
      } else {
        Logger.warn('PermissionService', 'Some permissions denied');
      }

      return allGranted;
    } catch (error) {
      Logger.error('PermissionService', 'Failed to request permissions', error as Error);
      return false;
    }
  }

  /**
   * 检查并申请必需权限
   * 用于应用启动时集中申请权限
   */
  async checkAndRequestRequiredPermissions(context: common.UIAbilityContext): Promise<boolean> {
    const requiredPermissions: Permissions[] = [
      'ohos.permission.INTERNET',
      'ohos.permission.GET_WIFI_INFO'
    ];

    Logger.info('PermissionService', 'Checking required permissions');
    return await this.requestPermissions(requiredPermissions, context);
  }
}
