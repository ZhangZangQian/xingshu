# 系统 API 使用指南

本文档提供 HarmonyOS Next 常用系统 API 的使用指南。

## 目录

- [网络通信](#网络通信)
- [数据存储](#数据存储)
- [文件管理](#文件管理)
- [媒体处理](#媒体处理)
- [设备能力](#设备能力)
- [通知和提示](#通知和提示)
- [权限管理](#权限管理)

## 网络通信

### HTTP 请求

使用 `@ohos.net.http` 模块进行网络请求。

```typescript
import http from '@ohos.net.http';

// 基础用法
let httpRequest = http.createHttp();

httpRequest.request(
  'https://api.example.com/users',
  {
    method: http.RequestMethod.GET,
    header: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer token'
    },
    connectTimeout: 60000,
    readTimeout: 60000
  }
).then((response: http.HttpResponse) => {
  if (response.responseCode === 200) {
    let data = JSON.parse(response.result as string);
    console.info('Success:', JSON.stringify(data));
  }
}).catch((err) => {
  console.error('Error:', JSON.stringify(err));
}).finally(() => {
  httpRequest.destroy();
});

// POST 请求
httpRequest.request(
  'https://api.example.com/users',
  {
    method: http.RequestMethod.POST,
    header: {
      'Content-Type': 'application/json'
    },
    extraData: JSON.stringify({
      name: 'Alice',
      age: 25
    })
  }
).then((response) => {
  console.info('Created:', response.result);
}).catch((err) => {
  console.error('Error:', err);
});
```

### WebSocket

使用 `@ohos.net.webSocket` 模块建立 WebSocket 连接。

```typescript
import webSocket from '@ohos.net.webSocket';

let ws = webSocket.createWebSocket();

// 连接
ws.connect('wss://example.com/socket', (err, value) => {
  if (!err) {
    console.info('WebSocket connected');
  }
});

// 接收消息
ws.on('message', (err, value) => {
  console.info('Received:', value);
});

// 发送消息
ws.send('Hello Server', (err) => {
  if (!err) {
    console.info('Message sent');
  }
});

// 关闭连接
ws.on('close', (err, value) => {
  console.info('WebSocket closed:', value.code, value.reason);
});

// 主动关闭
ws.close((err) => {
  if (!err) {
    console.info('Connection closed');
  }
});
```

## 数据存储

### Preferences (用户首选项)

轻量级键值存储,适合保存配置项、token 等。

```typescript
import preferences from '@ohos.data.preferences';

// 初始化
let pref: preferences.Preferences;

async function initPreferences(context) {
  pref = await preferences.getPreferences(context, 'appStorage');
}

// 存储数据
async function saveData() {
  await pref.put('username', 'Alice');
  await pref.put('age', 25);
  await pref.put('isVip', true);
  await pref.flush();  // 持久化到磁盘
}

// 读取数据
async function loadData() {
  let username = await pref.get('username', '');
  let age = await pref.get('age', 0);
  let isVip = await pref.get('isVip', false);
  console.info(`User: ${username}, Age: ${age}, VIP: ${isVip}`);
}

// 删除数据
async function deleteData() {
  await pref.delete('username');
  await pref.flush();
}

// 清空所有数据
async function clearAll() {
  await pref.clear();
  await pref.flush();
}

// 监听数据变化
pref.on('change', (key: string) => {
  console.info('Key changed:', key);
});
```

### 关系型数据库

使用 `@ohos.data.relationalStore` 进行结构化数据存储。

```typescript
import relationalStore from '@ohos.data.relationalStore';

// 数据库配置
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'AppDatabase.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

// 创建表
const CREATE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    age INTEGER,
    email TEXT
  )
`;

// 初始化数据库
let store: relationalStore.RdbStore;

async function initDatabase(context) {
  store = await relationalStore.getRdbStore(context, STORE_CONFIG);
  await store.executeSql(CREATE_TABLE_SQL);
}

// 插入数据
async function insertUser(name: string, age: number, email: string) {
  const valueBucket: relationalStore.ValuesBucket = {
    name: name,
    age: age,
    email: email
  };
  let rowId = await store.insert('users', valueBucket);
  console.info('Inserted row:', rowId);
}

// 查询数据
async function queryUsers() {
  let predicates = new relationalStore.RdbPredicates('users');
  predicates.orderByAsc('id');

  let resultSet = await store.query(predicates, ['id', 'name', 'age', 'email']);

  let users = [];
  while (resultSet.goToNextRow()) {
    users.push({
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      age: resultSet.getLong(resultSet.getColumnIndex('age')),
      email: resultSet.getString(resultSet.getColumnIndex('email'))
    });
  }
  resultSet.close();
  return users;
}

// 更新数据
async function updateUser(id: number, newAge: number) {
  const valueBucket: relationalStore.ValuesBucket = {
    age: newAge
  };

  let predicates = new relationalStore.RdbPredicates('users');
  predicates.equalTo('id', id);

  let rows = await store.update(valueBucket, predicates);
  console.info('Updated rows:', rows);
}

// 删除数据
async function deleteUser(id: number) {
  let predicates = new relationalStore.RdbPredicates('users');
  predicates.equalTo('id', id);

  let rows = await store.delete(predicates);
  console.info('Deleted rows:', rows);
}
```

## 文件管理

### 文件操作

使用 `@ohos.file.fs` 进行文件操作。

```typescript
import fs from '@ohos.file.fs';

// 获取应用文件路径
let filesDir = context.filesDir;  // 内部存储目录
let cacheDir = context.cacheDir;  // 缓存目录

// 写入文件
async function writeFile(filePath: string, content: string) {
  try {
    let file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    fs.writeSync(file.fd, content);
    fs.closeSync(file);
    console.info('File written successfully');
  } catch (err) {
    console.error('Write file error:', err);
  }
}

// 读取文件
async function readFile(filePath: string): Promise<string> {
  try {
    let file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
    let stat = fs.statSync(filePath);
    let buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);

    let decoder = new util.TextDecoder('utf-8');
    return decoder.decodeWithStream(new Uint8Array(buffer));
  } catch (err) {
    console.error('Read file error:', err);
    return '';
  }
}

// 复制文件
async function copyFile(srcPath: string, destPath: string) {
  try {
    fs.copyFileSync(srcPath, destPath);
    console.info('File copied');
  } catch (err) {
    console.error('Copy error:', err);
  }
}

// 删除文件
async function deleteFile(filePath: string) {
  try {
    fs.unlinkSync(filePath);
    console.info('File deleted');
  } catch (err) {
    console.error('Delete error:', err);
  }
}

// 创建目录
async function createDirectory(dirPath: string) {
  try {
    fs.mkdirSync(dirPath);
    console.info('Directory created');
  } catch (err) {
    console.error('Mkdir error:', err);
  }
}

// 列出目录
async function listDirectory(dirPath: string): Promise<string[]> {
  try {
    return fs.listFileSync(dirPath);
  } catch (err) {
    console.error('List error:', err);
    return [];
  }
}

// 检查文件是否存在
function fileExists(filePath: string): boolean {
  try {
    let stat = fs.statSync(filePath);
    return stat.isFile();
  } catch (err) {
    return false;
  }
}
```

## 媒体处理

### 图片处理

使用 `@ohos.multimedia.image` 处理图片。

```typescript
import image from '@ohos.multimedia.image';

// 创建 PixelMap
async function createPixelMap(context, resourceId: Resource): Promise<image.PixelMap> {
  let resourceMgr = context.resourceManager;
  let imageData = await resourceMgr.getMediaContent(resourceId);

  let imageSource = image.createImageSource(imageData);
  let pixelMap = await imageSource.createPixelMap();
  return pixelMap;
}

// 缩放图片
async function scaleImage(pixelMap: image.PixelMap, width: number, height: number) {
  await pixelMap.scale(width / pixelMap.getImageInfo().size.width,
                       height / pixelMap.getImageInfo().size.height);
}

// 裁剪图片
async function cropImage(pixelMap: image.PixelMap, x: number, y: number, width: number, height: number) {
  await pixelMap.crop({ x, y, size: { width, height } });
}

// 旋转图片
async function rotateImage(pixelMap: image.PixelMap, angle: number) {
  await pixelMap.rotate(angle);
}

// 保存图片
async function saveImage(pixelMap: image.PixelMap, filePath: string) {
  let packOpts: image.PackingOption = {
    format: 'image/jpeg',
    quality: 90
  };

  let imagePacker = image.createImagePacker();
  let data = await imagePacker.packing(pixelMap, packOpts);

  let file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
  fs.writeSync(file.fd, data);
  fs.closeSync(file);
}
```

### 音频播放

使用 `@ohos.multimedia.audio` 播放音频。

```typescript
import media from '@ohos.multimedia.media';

let audioPlayer: media.AudioPlayer;

// 创建播放器
function createAudioPlayer() {
  audioPlayer = media.createAudioPlayer();

  // 监听事件
  audioPlayer.on('play', () => {
    console.info('Audio started');
  });

  audioPlayer.on('pause', () => {
    console.info('Audio paused');
  });

  audioPlayer.on('stop', () => {
    console.info('Audio stopped');
  });

  audioPlayer.on('finish', () => {
    console.info('Playback finished');
  });

  audioPlayer.on('error', (err) => {
    console.error('Audio error:', err);
  });
}

// 播放音频
async function playAudio(url: string) {
  audioPlayer.src = url;
  audioPlayer.play();
}

// 暂停
function pauseAudio() {
  audioPlayer.pause();
}

// 停止
function stopAudio() {
  audioPlayer.stop();
}

// 跳转
function seekAudio(timeMs: number) {
  audioPlayer.seek(timeMs);
}

// 释放资源
function releaseAudioPlayer() {
  audioPlayer.release();
}
```

## 设备能力

### 位置服务

使用 `@ohos.geoLocationManager` 获取位置信息。

```typescript
import geoLocationManager from '@ohos.geoLocationManager';

// 单次定位
async function getCurrentLocation() {
  let requestInfo: geoLocationManager.CurrentLocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    scenario: geoLocationManager.LocationRequestScenario.UNSET,
    maxAccuracy: 0,
    timeoutMs: 10000
  };

  try {
    let location = await geoLocationManager.getCurrentLocation(requestInfo);
    console.info(`Lat: ${location.latitude}, Lon: ${location.longitude}`);
    return location;
  } catch (err) {
    console.error('Location error:', err);
  }
}

// 持续定位
function startLocationUpdates(callback: (location) => void) {
  let requestInfo: geoLocationManager.LocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.ACCURACY,
    scenario: geoLocationManager.LocationRequestScenario.UNSET,
    timeInterval: 5,
    distanceInterval: 0,
    maxAccuracy: 0
  };

  geoLocationManager.on('locationChange', requestInfo, (location) => {
    callback(location);
  });
}

// 停止定位
function stopLocationUpdates() {
  geoLocationManager.off('locationChange');
}
```

### 传感器

使用 `@ohos.sensor` 访问设备传感器。

```typescript
import sensor from '@ohos.sensor';

// 加速度传感器
function startAccelerometer(callback: (data) => void) {
  sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
    callback({
      x: data.x,
      y: data.y,
      z: data.z
    });
  }, { interval: 100000000 });  // 单位:纳秒
}

// 陀螺仪
function startGyroscope(callback: (data) => void) {
  sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
    callback({
      x: data.x,
      y: data.y,
      z: data.z
    });
  });
}

// 光线传感器
function startLight(callback: (intensity: number) => void) {
  sensor.on(sensor.SensorId.AMBIENT_LIGHT, (data: sensor.LightResponse) => {
    callback(data.intensity);
  });
}

// 停止传感器
function stopSensor(sensorId: sensor.SensorId) {
  sensor.off(sensorId);
}
```

### 振动

使用 `@ohos.vibrator` 控制设备振动。

```typescript
import vibrator from '@ohos.vibrator';

// 短振动
async function vibrateShort() {
  try {
    await vibrator.startVibration({
      type: 'time',
      duration: 100
    }, {
      usage: 'touch'
    });
  } catch (err) {
    console.error('Vibrate error:', err);
  }
}

// 自定义振动
async function vibratePattern() {
  try {
    await vibrator.startVibration({
      type: 'preset',
      effectId: 'haptic.clock.timer',
      count: 1
    }, {
      usage: 'notification'
    });
  } catch (err) {
    console.error('Vibrate error:', err);
  }
}

// 停止振动
async function stopVibrate() {
  try {
    await vibrator.stopVibration();
  } catch (err) {
    console.error('Stop vibrate error:', err);
  }
}
```

## 通知和提示

### Toast 提示

使用 `@ohos.promptAction` 显示 Toast。

```typescript
import promptAction from '@ohos.promptAction';

// 显示 Toast
function showToast(message: string) {
  promptAction.showToast({
    message: message,
    duration: 2000,
    bottom: 100
  });
}

// 显示对话框
async function showDialog(title: string, message: string) {
  let result = await promptAction.showDialog({
    title: title,
    message: message,
    buttons: [
      { text: '取消', color: '#999999' },
      { text: '确定', color: '#007DFF' }
    ]
  });

  if (result.index === 1) {
    console.info('User confirmed');
  }
}

// 显示操作菜单
async function showActionSheet(options: string[]) {
  let result = await promptAction.showActionMenu({
    title: '请选择操作',
    buttons: options.map(opt => ({ text: opt }))
  });

  console.info('Selected:', result.index);
}
```

### 通知

使用 `@ohos.notificationManager` 发送通知。

```typescript
import notificationManager from '@ohos.notificationManager';

// 发送基础通知
async function sendNotification(title: string, text: string) {
  let notificationRequest: notificationManager.NotificationRequest = {
    id: 1,
    content: {
      contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: title,
        text: text
      }
    }
  };

  try {
    await notificationManager.publish(notificationRequest);
    console.info('Notification sent');
  } catch (err) {
    console.error('Notification error:', err);
  }
}

// 发送进度通知
async function sendProgressNotification(title: string, progress: number) {
  let notificationRequest: notificationManager.NotificationRequest = {
    id: 2,
    content: {
      contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
      longText: {
        title: title,
        text: `进度: ${progress}%`,
        longText: '',
        progressBar: {
          progress: progress,
          progressMax: 100,
          isProgressIndeterminate: false
        }
      }
    }
  };

  await notificationManager.publish(notificationRequest);
}

// 取消通知
async function cancelNotification(id: number) {
  await notificationManager.cancel(id);
}
```

## 权限管理

### 申请权限

```typescript
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';

// 检查权限
async function checkPermission(permission: string): Promise<boolean> {
  let atManager = abilityAccessCtrl.createAtManager();
  let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);

  try {
    let grantStatus = await atManager.checkAccessToken(bundleInfo.appInfo.accessTokenId, permission);
    return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (err) {
    console.error('Check permission error:', err);
    return false;
  }
}

// 申请权限
async function requestPermissions(context, permissions: string[]) {
  let atManager = abilityAccessCtrl.createAtManager();

  try {
    let data = await atManager.requestPermissionsFromUser(context, permissions);
    for (let i = 0; i < data.permissions.length; i++) {
      console.info(`Permission: ${data.permissions[i]}, Result: ${data.authResults[i]}`);
    }
  } catch (err) {
    console.error('Request permissions error:', err);
  }
}

// 常用权限示例
const PERMISSIONS = {
  LOCATION: 'ohos.permission.LOCATION',
  CAMERA: 'ohos.permission.CAMERA',
  MICROPHONE: 'ohos.permission.MICROPHONE',
  READ_MEDIA: 'ohos.permission.READ_MEDIA',
  WRITE_MEDIA: 'ohos.permission.WRITE_MEDIA',
  INTERNET: 'ohos.permission.INTERNET'
};
```

## 最佳实践

### 错误处理

```typescript
// 统一错误处理
class ApiError extends Error {
  code: number;

  constructor(code: number, message: string) {
    super(message);
    this.code = code;
    this.name = 'ApiError';
  }
}

async function safeApiCall<T>(apiFunc: () => Promise<T>): Promise<T> {
  try {
    return await apiFunc();
  } catch (err) {
    console.error('API Error:', JSON.stringify(err));
    throw new ApiError(err.code || -1, err.message || 'Unknown error');
  }
}
```

### 资源释放

```typescript
// 确保资源正确释放
class ResourceManager {
  private resources: any[] = [];

  register(resource: any) {
    this.resources.push(resource);
  }

  async releaseAll() {
    for (let resource of this.resources) {
      if (resource.release) {
        await resource.release();
      }
      if (resource.destroy) {
        await resource.destroy();
      }
    }
    this.resources = [];
  }
}
```

### 性能优化

```typescript
// 使用节流
function throttle<T extends (...args: any[]) => void>(func: T, delay: number): T {
  let lastCall = 0;
  return ((...args) => {
    const now = Date.now();
    if (now - lastCall >= delay) {
      lastCall = now;
      func(...args);
    }
  }) as T;
}

// 使用防抖
function debounce<T extends (...args: any[]) => void>(func: T, delay: number): T {
  let timeoutId: number;
  return ((...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func(...args), delay);
  }) as T;
}
```
