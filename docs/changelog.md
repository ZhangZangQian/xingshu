# 深色模式适配更新日志

## 2026-01-12

### 修复
- 修复 color.json 文件中 `rgba()` 格式不被支持的问题
- 将所有 rgba 颜色值转换为 `#AARRGGBB` 十六进制格式

### 修改的文件
- `entry/src/main/resources/base/element/color.json`
- `entry/src/main/resources/dark/element/color.json`
- `docs/dark-mode-adapter.md`

### 颜色格式转换

#### 浅色模式转换
| 原值 (rgba) | 新值 (#AARRGGBB) | 说明 |
|------------|-----------------|------|
| rgba(96, 122, 251, 0.15) | #26607AFB | primary_light |
| rgba(96, 122, 251, 0.1) | #19607AFB | primary_faint |
| rgba(0, 0, 0, 0.06) | #0F000000 | border_subtle |
| rgba(0, 0, 0, 0.05) | #0D000000 | shadow_default |
| rgba(0, 0, 0, 0.04) | #0A000000 | shadow_light |
| rgba(0, 0, 0, 0.08) | #14000000 | shadow_heavy |
| rgba(255, 255, 255, 0.8) | #CCFFFFFF | overlay_background |
| rgba(255, 255, 255, 0.95) | #F2FFFFFF | overlay_bottom |

#### 深色模式转换
| 原值 (rgba) | 新值 (#AARRGGBB) | 说明 |
|------------|-----------------|------|
| rgba(10, 132, 255, 0.2) | #330A84FF | primary_light |
| rgba(10, 132, 255, 0.1) | #190A84FF | primary_faint |
| rgba(255, 255, 255, 0.08) | #14FFFFFF | border_subtle |
| rgba(0, 0, 0, 0.3) | #4D000000 | shadow_default |
| rgba(0, 0, 0, 0.2) | #33000000 | shadow_light |
| rgba(0, 0, 0, 0.5) | #80000000 | shadow_heavy |
| rgba(28, 28, 30, 0.8) | #CC1C1C1E | overlay_background |
| rgba(28, 28, 30, 0.95) | #F21C1C1E | overlay_bottom |

### 转换公式

将 rgba(R, G, B, A) 转换为 #AARRGGBB：

```
AA = Math.floor(A * 255).toString(16).padStart(2, '0').toUpperCase()
RR = R.toString(16).padStart(2, '0').toUpperCase()
GG = G.toString(16).padStart(2, '0').toUpperCase()
BB = B.toString(16).padStart(2, '0').toUpperCase()
结果 = '#' + AA + RR + GG + BB
```

### 已知问题
无

### 下一步计划
- 开始适配 Index.ets 页面
- 适配 MacroEditor.ets 页面
- 进行全面测试
