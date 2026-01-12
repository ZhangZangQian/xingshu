# ArkUI 组件参考

## 基础组件

### Text

文本显示组件。

```typescript
Text('Hello World')
  .fontSize(20)
  .fontColor('#333333')
  .fontWeight(FontWeight.Bold)
  .textAlign(TextAlign.Center)
  .width('100%')
  .height(50)
```

**属性**:
- `fontSize`: 字体大小
- `fontColor`: 字体颜色
- `fontWeight`: 字体粗细
- `textAlign`: 文本对齐方式
- `textDecoration`: 文本装饰（下划线、删除线等）
- `maxLines`: 最大行数
- `textOverflow`: 文本溢出处理

### Button

按钮组件。

```typescript
Button('Click Me')
  .type(ButtonType.Normal)
  .width(120)
  .height(40)
  .fontSize(16)
  .onClick(() => {
    console.log('Button clicked')
  })

// 不同类型的按钮
Button('Normal').type(ButtonType.Normal)
Button('Capsule').type(ButtonType.Capsule)
Button('Circle').type(ButtonType.Circle)
```

**类型**:
- `ButtonType.Normal`: 普通按钮
- `ButtonType.Capsule`: 胶囊按钮
- `ButtonType.Circle`: 圆形按钮

### Image

图片显示组件。

```typescript
// 本地资源
Image($r('app.media.icon'))
  .width(100)
  .height(100)
  .objectFit(ImageFit.Cover)

// 网络图片
Image('https://example.com/image.png')
  .width('100%')
  .height(200)

// Base64图片
Image('data:image/png;base64,...')
  .width(100)
  .height(100)
```

**objectFit 模式**:
- `ImageFit.Cover`: 覆盖
- `ImageFit.Contain`: 包含
- `ImageFit.Fill`: 填充
- `ImageFit.None`: 不调整
- `ImageFit.ScaleDown`: 缩小

### TextInput

文本输入框。

```typescript
TextInput({ placeholder: 'Enter your name' })
  .width('100%')
  .height(50)
  .fontSize(16)
  .onChange((value: string) => {
    console.log(value)
  })
  .onSubmit(() => {
    console.log('Submitted')
  })

// 密码输入
TextInput({ placeholder: 'Enter password' })
  .type(InputType.Password)

// 数字输入
TextInput({ placeholder: 'Enter number' })
  .type(InputType.Number)
```

**输入类型**:
- `InputType.Normal`: 普通输入
- `InputType.Password`: 密码输入
- `InputType.Number`: 数字输入
- `InputType.Email`: 邮箱输入
- `InputType.Phone`: 电话输入

### TextArea

多行文本输入。

```typescript
TextArea({ placeholder: 'Enter your message' })
  .width('100%')
  .height(100)
  .fontSize(16)
  .onChange((value: string) => {
    console.log(value)
  })
```

### Checkbox

复选框。

```typescript
Checkbox({ name: 'agree' })
  .select(this.isAgreed)
  .onChange((value: boolean) => {
    this.isAgreed = value
  })

CheckboxGroup({ group: 'options' })
  .onSelect((indexes: number[]) => {
    console.log(indexes)
  })
```

### Radio

单选按钮。

```typescript
Radio({ value: 'option1', group: 'radioGroup' })
  .checked(this.selectedOption === 'option1')
  .onChange((isChecked: boolean) => {
    if (isChecked) {
      this.selectedOption = 'option1'
    }
  })
```

### Switch

开关。

```typescript
Switch({ type: SwitchType.Switch })
  .checked(this.isEnabled)
  .onChange((value: boolean) => {
    this.isEnabled = value
  })

// 复选框类型
Switch({ type: SwitchType.Checkbox })
  .selected(this.isChecked)
```

### Slider

滑动条。

```typescript
Slider({
  value: this.progress,
  min: 0,
  max: 100,
  step: 1
})
  .width('100%')
  .showTips(true)
  .onChange((value: number) => {
    this.progress = value
  })
```

### Progress

进度条。

```typescript
Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
  .width('100%')
  .height(20)
  .color('#FF0000')

// 环形进度条
Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
  .width(100)
  .height(100)
```

### LoadingProgress

加载进度。

```typescript
LoadingProgress()
  .width(50)
  .height(50)
  .color('#FF0000')
```

## 布局组件

### Column

列布局（垂直方向）。

```typescript
Column() {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.width('100%')
.height('100%')
.justifyContent(FlexAlign.Center)
.alignItems(HorizontalAlign.Center)
```

**对齐方式**:
- `justifyContent`: 主轴对齐
- `alignItems`: 交叉轴对齐

### Row

行布局（水平方向）。

```typescript
Row() {
  Text('Left')
  Blank()
  Text('Right')
}
.width('100%')
.padding({ left: 16, right: 16 })
```

### Flex

弹性布局。

```typescript
Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
  Text('Item 1').flexGrow(1)
  Text('Item 2').flexGrow(1)
  Text('Item 3').flexGrow(1)
}
.width('100%')
```

**direction**:
- `FlexDirection.Row`: 水平
- `FlexDirection.Column`: 垂直
- `FlexDirection.RowReverse`: 水平反向
- `FlexDirection.ColumnReverse`: 垂直反向

### Stack

层叠布局。

```typescript
Stack() {
  Text('Background')
    .fontSize(24)
    .fontColor('#999999')
  Text('Foreground')
    .fontSize(32)
    .fontColor('#FF0000')
}
.width(200)
.height(200)
.alignContent(Alignment.Center)
```

### Grid

栅格布局。

```typescript
Grid() {
  ForEach(this.items, (item: string) => {
    GridItem() {
      Text(item)
    }
  })
}
.columnsTemplate('1fr 1fr 1fr')
.rowsTemplate('1fr 1fr')
.columnsGap(10)
.rowsGap(10)
```

### List

列表。

```typescript
List() {
  ForEach(this.items, (item: string, index: number) => {
    ListItem() {
      Text(item)
    }
  }, (item: string) => item)
}
.width('100%')
.height('100%')
.divider({ strokeWidth: 1, color: '#EEEEEE' })
```

### Scroll

滚动容器。

```typescript
Scroll() {
  Column() {
    ForEach(this.items, (item: string) => {
      Text(item)
        .fontSize(16)
        .height(50)
    })
  }
}
.width('100%')
.height(300)
.scrollable(ScrollDirection.Vertical)
.scrollBar(BarState.Auto)
```

## 容器组件

### Divider

分隔线。

```typescript
Divider()
  .color('#EEEEEE')
  .strokeWidth(1)
  .vertical(false)
```

### Tabs

标签页。

```typescript
@State currentTab: number = 0

Tabs({ barPosition: BarPosition.Start }) {
  TabContent() {
    Text('Content 1')
  }
  .tabBar(this.TabBuilder('Tab 1', 0))

  TabContent() {
    Text('Content 2')
  }
  .tabBar(this.TabBuilder('Tab 2', 1))
}
.onChange((index: number) => {
  this.currentTab = index
})

@Builder
TabBuilder(title: string, index: number) {
  Column() {
    Text(title)
      .fontSize(this.currentTab === index ? 18 : 16)
      .fontColor(this.currentTab === index ? '#FF0000' : '#666666')
  }
}
```

### Navigation

导航容器。

```typescript
Navigation() {
  Column() {
    Text('Home Page')
  }
}
.title('Navigation')
.hideBackButton(true)
```

### Refresh

下拉刷新。

```typescript
Refresh({ refreshing: this.isRefreshing, offset: 100 }) {
  List() {
    ForEach(this.items, (item: string) => {
      ListItem() {
        Text(item)
      }
    })
  }
}
.onRefreshing(() => {
  this.isRefreshing = true
  setTimeout(() => {
    this.isRefreshing = false
  }, 2000)
})
```

## 交互组件

### AlertDialog

对话框。

```typescript
AlertDialog.show({
  title: '提示',
  message: '确定要删除吗？',
  primaryButton: {
    value: '取消',
    action: () => {
      console.log('取消')
    }
  },
  secondaryButton: {
    value: '确定',
    action: () => {
      console.log('确定')
    }
  }
})
```

### Toast

提示信息。

```typescript
promptAction.showToast({
  message: '操作成功',
  duration: 2000
})
```

### Menu

菜单。

```typescript
Menu() {
  MenuItem({ content: 'Option 1' })
  MenuItem({ content: 'Option 2' })
}
.bindMenu(this.isShowMenu)
```

### Popup

弹出框。

```typescript
Button('Show Popup')
  .bindPopup(this.showPopup, {
    builder: this.PopupBuilder,
    onStateChange: (e) => {
      if (!e.isVisible) {
        this.showPopup = false
      }
    }
  })

@Builder
PopupBuilder() {
  Column() {
    Text('Popup Content')
      .fontSize(16)
  }
  .width(200)
  .height(100)
  .backgroundColor('#FFFFFF')
}
```

## 选择器组件

### DatePicker

日期选择器。

```typescript
DatePicker({
  start: new Date('2020-01-01'),
  end: new Date('2030-12-31'),
  selected: this.selectedDate
})
  .onChange((value: DatePickerResult) => {
    console.log(value.year, value.month, value.day)
  })
```

### TimePicker

时间选择器。

```typescript
TimePicker({
  selected: this.selectedTime
})
  .onChange((value: TimePickerResult) => {
    console.log(value.hour, value.minute)
  })
```

### Select

下拉选择器。

```typescript
Select(this.options)
  .selected(0)
  .value('Please select')
  .font({ size: 16 })
  .selectedOptionFont({ size: 16 })
  .optionFont({ size: 14 })
  .onSelect((index: number) => {
    console.log('Selected:', index)
  })
```

## 富媒体组件

### Video

视频播放器。

```typescript
Video({
  src: this.videoUrl,
  controller: this.videoController
})
.width('100%')
.height(200)
.autoPlay(false)
.controls(true)
.loop(false)
.muted(false)
.objectFit(ImageFit.Cover)
.onStart(() => {
  console.log('Video started')
})
.onFinish(() => {
  console.log('Video finished')
})
```

### Canvas

画布。

```typescript
Canvas(this.context)
  .width('100%')
  .height(200)
  .onReady(() => {
    this.context.fillStyle = '#FF0000'
    this.context.fillRect(10, 10, 100, 100)
  })
```

### Web

网页浏览。

```typescript
Web({ src: this.url, controller: this.controller })
  .width('100%')
  .height('100%')
  .domStorageAccess(true)
  .javaScriptAccess(true)
  .onPageEnd(() => {
    console.log('Page loaded')
  })
```

## 其他组件

### Badge

徽标。

```typescript
Badge({
  count: this.notificationCount,
  maxCount: 99
}) {
  Text('Messages')
}

// 自定义徽标
Badge({
  value: 'New',
  position: BadgePosition.RightTop
}) {
  Text('Label')
}
```

### Counter

计数器。

```typescript
Counter() {
  Text('Counter')
}
.onInc(() => {
  console.log('Increment')
})
.onDec(() => {
  console.log('Decrement')
})
```

### Gauge

仪表盘。

```typescript
Gauge({ value: 60, min: 0, max: 100 })
  .width(200)
  .height(200)
  .colors([[0x317AF7, 1], [0xE5E5E5, 1]])
  .startAngle(210)
  .endAngle(150)
```

### ImageSpan

文本中嵌入图片。

```typescript
Text() {
  ImageSpan($r('app.media.icon'))
    .width(20)
    .height(20)
  Span('Text with image')
}
.fontSize(16)
```
