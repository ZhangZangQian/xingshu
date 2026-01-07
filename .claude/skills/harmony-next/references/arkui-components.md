# ArkUI 组件完整清单

本文档提供 HarmonyOS Next ArkUI 组件的详细清单和使用说明。

## 目录

- [基础组件](#基础组件)
- [容器组件](#容器组件)
- [列表组件](#列表组件)
- [导航组件](#导航组件)
- [媒体组件](#媒体组件)
- [表单组件](#表单组件)
- [画布组件](#画布组件)

## 基础组件

### Text - 文本显示

显示一段文本内容。

```typescript
Text('Hello World')
  .fontSize(16)
  .fontColor(Color.Black)
  .fontWeight(FontWeight.Bold)
  .textAlign(TextAlign.Center)
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .decoration({ type: TextDecorationType.Underline, color: Color.Red })
```

**常用属性**:
- `fontSize`: 字体大小
- `fontColor`: 字体颜色
- `fontWeight`: 字体粗细
- `textAlign`: 文本对齐
- `maxLines`: 最大行数
- `textOverflow`: 文本溢出处理

### Button - 按钮

触发操作的按钮组件。

```typescript
// 文本按钮
Button('点击我')
  .type(ButtonType.Normal)
  .fontSize(16)
  .fontColor(Color.White)
  .backgroundColor('#007DFF')
  .borderRadius(8)
  .width(120)
  .height(40)
  .onClick(() => {
    console.info('Button clicked');
  })

// 包含子组件的按钮
Button() {
  Row() {
    Image($r('app.media.icon')).width(20).height(20)
    Text('自定义').margin({ left: 5 })
  }
}
```

**类型**:
- `ButtonType.Normal`: 普通按钮
- `ButtonType.Capsule`: 胶囊型按钮
- `ButtonType.Circle`: 圆形按钮

### Image - 图片

显示图片资源。

```typescript
// 本地资源
Image($r('app.media.icon'))
  .width(100)
  .height(100)
  .objectFit(ImageFit.Cover)
  .borderRadius(8)

// 网络图片
Image('https://example.com/image.jpg')
  .alt($r('app.media.placeholder'))  // 占位图
  .onComplete(() => {
    console.info('Image loaded');
  })
  .onError(() => {
    console.error('Image load failed');
  })
```

**适配模式(objectFit)**:
- `ImageFit.Cover`: 保持宽高比,覆盖显示区域
- `ImageFit.Contain`: 保持宽高比,完整显示图片
- `ImageFit.Fill`: 拉伸填充
- `ImageFit.ScaleDown`: 等比缩小

### Toggle - 开关

开关组件,支持多种类型。

```typescript
// 开关
Toggle({ type: ToggleType.Switch, isOn: this.isOn })
  .onChange((isOn: boolean) => {
    this.isOn = isOn;
  })

// 复选框
Toggle({ type: ToggleType.Checkbox, isOn: this.checked })
  .onChange((isOn: boolean) => {
    this.checked = isOn;
  })

// 按钮型
Toggle({ type: ToggleType.Button, isOn: this.selected })
  .selectedColor('#007DFF')
  .onChange((isOn: boolean) => {
    this.selected = isOn;
  })
```

### Progress - 进度条

显示进度的组件。

```typescript
// 线性进度条
Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
  .width('80%')
  .color('#007DFF')

// 环形进度条
Progress({ value: 50, total: 100, type: ProgressType.Ring })
  .width(100)
  .style({ strokeWidth: 10 })

// 刻度进度条
Progress({ value: 30, total: 100, type: ProgressType.ScaleRing })
  .width(120)
```

## 容器组件

### Column - 垂直布局

子组件垂直排列。

```typescript
Column({ space: 10 }) {
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.width('100%')
.height(200)
.alignItems(HorizontalAlign.Start)  // 水平对齐
.justifyContent(FlexAlign.SpaceBetween)  // 垂直分布
```

**对齐方式(alignItems)**:
- `HorizontalAlign.Start/Center/End`

**分布方式(justifyContent)**:
- `FlexAlign.Start/Center/End/SpaceBetween/SpaceAround/SpaceEvenly`

### Row - 水平布局

子组件水平排列。

```typescript
Row({ space: 10 }) {
  Text('Left')
  Text('Center')
  Text('Right')
}
.width('100%')
.height(50)
.alignItems(VerticalAlign.Center)  // 垂直对齐
.justifyContent(FlexAlign.SpaceBetween)
```

### Stack - 层叠布局

子组件层叠显示。

```typescript
Stack({ alignContent: Alignment.BottomEnd }) {
  Image($r('app.media.bg'))
    .width('100%')
    .height(200)

  Text('水印')
    .fontSize(12)
    .fontColor(Color.White)
    .padding(8)
    .backgroundColor('#80000000')
}
.width('100%')
```

**对齐方式**:
- `Alignment.TopStart/Top/TopEnd`
- `Alignment.Start/Center/End`
- `Alignment.BottomStart/Bottom/BottomEnd`

### Flex - 弹性布局

弹性容器组件。

```typescript
Flex({
  direction: FlexDirection.Row,
  wrap: FlexWrap.Wrap,
  justifyContent: FlexAlign.SpaceBetween,
  alignItems: ItemAlign.Center
}) {
  Text('Item 1')
    .flexGrow(1)      // 放大比例
    .flexShrink(0)    // 缩小比例
    .flexBasis(100)   // 基准大小

  Text('Item 2')
    .flexGrow(2)

  Text('Item 3')
}
.width('100%')
```

### RelativeContainer - 相对布局

相对定位布局容器。

```typescript
RelativeContainer() {
  Text('A')
    .id('textA')
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      left: { anchor: '__container__', align: HorizontalAlign.Start }
    })

  Text('B')
    .id('textB')
    .alignRules({
      top: { anchor: 'textA', align: VerticalAlign.Bottom },
      left: { anchor: 'textA', align: HorizontalAlign.Start }
    })
    .margin({ top: 10 })
}
```

## 列表组件

### List - 列表

可滚动的列表容器。

```typescript
List({ space: 10, initialIndex: 0 }) {
  ForEach(this.dataList, (item: DataItem, index: number) => {
    ListItem() {
      Row() {
        Text(item.title)
          .fontSize(16)
        Blank()
        Text(item.value)
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
    .swipeAction({ end: this.deleteButton() })  // 滑动删除
  })
}
.width('100%')
.height('100%')
.edgeEffect(EdgeEffect.Spring)  // 边缘效果
.onScrollIndex((start: number, end: number) => {
  console.info(`Visible range: ${start} - ${end}`);
})

@Builder deleteButton() {
  Button('删除')
    .backgroundColor(Color.Red)
    .onClick(() => {
      // 删除逻辑
    })
}
```

### Grid - 网格

网格布局容器。

```typescript
Grid() {
  ForEach(this.items, (item: string, index: number) => {
    GridItem() {
      Column() {
        Image($r('app.media.icon'))
          .width(60)
          .height(60)
        Text(item)
          .fontSize(14)
          .margin({ top: 8 })
      }
      .width('100%')
      .height(120)
      .justifyContent(FlexAlign.Center)
    }
  })
}
.columnsTemplate('1fr 1fr 1fr')  // 3列
.rowsGap(10)
.columnsGap(10)
.width('100%')
.height('100%')
```

### WaterFlow - 瀑布流

瀑布流布局容器。

```typescript
WaterFlow() {
  ForEach(this.items, (item: WaterFlowItem) => {
    FlowItem() {
      Column() {
        Image(item.image)
          .width('100%')
          .objectFit(ImageFit.Cover)
        Text(item.title)
          .padding(8)
      }
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
    .width('100%')
    .height(item.height)
  })
}
.columnsTemplate('1fr 1fr')
.columnsGap(10)
.rowsGap(10)
```

### Swiper - 轮播

轮播容器组件。

```typescript
Swiper() {
  ForEach(this.images, (img: string) => {
    Image(img)
      .width('100%')
      .height(200)
      .objectFit(ImageFit.Cover)
  })
}
.loop(true)                    // 循环播放
.autoPlay(true)                // 自动播放
.interval(3000)                // 间隔时间
.vertical(false)               // 滑动方向
.indicator(true)               // 显示指示器
.indicatorStyle({              // 指示器样式
  color: '#80FFFFFF',
  selectedColor: '#FFFFFF',
  size: 8,
  bottom: 10
})
.onChange((index: number) => {
  this.currentIndex = index;
})
```

## 导航组件

### Navigation - 导航容器

推荐的路由导航组件。

```typescript
@Entry
@Component
struct NavigationExample {
  private navStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.navStack) {
      // 主页内容
      Column() {
        Button('跳转到详情')
          .onClick(() => {
            this.navStack.pushPath({
              name: 'DetailPage',
              param: { id: 123 }
            });
          })
      }
    }
    .title('首页')
    .titleMode(NavigationTitleMode.Mini)
    .menus([
      { value: '搜索', icon: $r('app.media.search') },
      { value: '更多', icon: $r('app.media.more') }
    ])
    .toolBar({
      items: [
        { value: '首页', icon: $r('app.media.home') },
        { value: '发现', icon: $r('app.media.discover') },
        { value: '我的', icon: $r('app.media.profile') }
      ]
    })
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: Object) {
    if (name === 'DetailPage') {
      DetailPageContent({ params: param })
    }
  }
}
```

### Tabs - 标签页

选项卡容器组件。

```typescript
@Entry
@Component
struct TabsExample {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  build() {
    Tabs({
      index: this.currentIndex,
      controller: this.tabsController
    }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBuilder('首页', 0, $r('app.media.home')))

      TabContent() {
        DiscoverPage()
      }
      .tabBar(this.tabBuilder('发现', 1, $r('app.media.discover')))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.tabBuilder('我的', 2, $r('app.media.profile')))
    }
    .barPosition(BarPosition.End)  // 标签栏位置
    .vertical(false)
    .scrollable(true)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }

  @Builder
  tabBuilder(title: string, index: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#007DFF' : '#999999')
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
    }
  }
}
```

## 媒体组件

### Video - 视频

视频播放组件。

```typescript
@State videoController: VideoController = new VideoController();

Video({
  src: 'https://example.com/video.mp4',
  controller: this.videoController
})
  .width('100%')
  .height(300)
  .autoPlay(false)
  .controls(true)
  .onStart(() => {
    console.info('Video started');
  })
  .onPause(() => {
    console.info('Video paused');
  })
  .onFinish(() => {
    console.info('Video finished');
  })
  .onError(() => {
    console.error('Video error');
  })

// 控制播放
Button('播放')
  .onClick(() => {
    this.videoController.start();
  })
```

## 表单组件

### TextInput - 文本输入

单行文本输入框。

```typescript
TextInput({ placeholder: '请输入用户名', text: this.username })
  .type(InputType.Normal)
  .maxLength(20)
  .fontSize(16)
  .placeholderColor('#999999')
  .backgroundColor('#F5F5F5')
  .borderRadius(8)
  .padding(12)
  .onChange((value: string) => {
    this.username = value;
  })
  .onSubmit(() => {
    console.info('Submit:', this.username);
  })
```

**输入类型**:
- `InputType.Normal`: 普通文本
- `InputType.Password`: 密码
- `InputType.Email`: 邮箱
- `InputType.Number`: 数字
- `InputType.PhoneNumber`: 电话号码

### TextArea - 多行文本

多行文本输入框。

```typescript
TextArea({ placeholder: '请输入内容', text: this.content })
  .width('100%')
  .height(150)
  .maxLength(500)
  .fontSize(16)
  .onChange((value: string) => {
    this.content = value;
  })
```

### Radio - 单选按钮

单选按钮组件。

```typescript
@State selectedGender: string = 'male';

Row() {
  Radio({ value: 'male', group: 'gender' })
    .checked(this.selectedGender === 'male')
    .onChange((isChecked: boolean) => {
      if (isChecked) {
        this.selectedGender = 'male';
      }
    })
  Text('男').margin({ left: 8 })

  Radio({ value: 'female', group: 'gender' })
    .checked(this.selectedGender === 'female')
    .onChange((isChecked: boolean) => {
      if (isChecked) {
        this.selectedGender = 'female';
      }
    })
    .margin({ left: 20 })
  Text('女').margin({ left: 8 })
}
```

### Checkbox - 复选框

复选框组件。

```typescript
@State isAgreed: boolean = false;

Row() {
  Checkbox()
    .select(this.isAgreed)
    .selectedColor('#007DFF')
    .onChange((value: boolean) => {
      this.isAgreed = value;
    })

  Text('我已阅读并同意服务条款')
    .fontSize(14)
    .margin({ left: 8 })
}
```

### Slider - 滑动条

滑动选择组件。

```typescript
@State sliderValue: number = 50;

Column() {
  Text(`当前值: ${this.sliderValue}`)
    .fontSize(16)

  Slider({
    value: this.sliderValue,
    min: 0,
    max: 100,
    step: 1,
    style: SliderStyle.OutSet
  })
    .blockColor('#007DFF')
    .trackColor('#E5E5E5')
    .selectedColor('#007DFF')
    .showTips(true)
    .onChange((value: number) => {
      this.sliderValue = Math.floor(value);
    })
}
```

### Picker - 选择器

选择器组件。

```typescript
// 文本选择器
@State selectedCity: string = '北京';
private cities: string[] = ['北京', '上海', '广州', '深圳'];

TextPicker({ range: this.cities, selected: 0 })
  .onChange((value: string, index: number) => {
    this.selectedCity = value;
  })

// 日期选择器
@State selectedDate: Date = new Date();

DatePicker({
  start: new Date('2020-01-01'),
  end: new Date('2030-12-31'),
  selected: this.selectedDate
})
  .onChange((value: DatePickerResult) => {
    this.selectedDate = new Date(value.year, value.month, value.day);
  })
```

## 画布组件

### Canvas - 画布

提供画布绘制能力。

```typescript
@State canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

Canvas(this.canvasContext)
  .width('100%')
  .height(300)
  .backgroundColor('#F5F5F5')
  .onReady(() => {
    // 绘制矩形
    this.canvasContext.fillStyle = '#007DFF';
    this.canvasContext.fillRect(20, 20, 100, 100);

    // 绘制圆形
    this.canvasContext.beginPath();
    this.canvasContext.arc(200, 70, 50, 0, 2 * Math.PI);
    this.canvasContext.fillStyle = '#FF0000';
    this.canvasContext.fill();

    // 绘制文字
    this.canvasContext.font = '20px sans-serif';
    this.canvasContext.fillStyle = '#000000';
    this.canvasContext.fillText('Hello Canvas', 20, 200);
  })
```

## 通用属性

所有组件都支持的通用属性:

### 尺寸
- `width(value)`: 宽度
- `height(value)`: 高度
- `size({ width, height })`: 同时设置宽高
- `padding(value)`: 内边距
- `margin(value)`: 外边距

### 外观
- `backgroundColor(color)`: 背景色
- `backgroundImage(src)`: 背景图
- `borderRadius(value)`: 圆角
- `border({ width, color, style })`: 边框
- `opacity(value)`: 不透明度

### 位置
- `position({ x, y })`: 绝对定位
- `offset({ x, y })`: 相对偏移
- `zIndex(value)`: 层级

### 变换
- `scale({ x, y })`: 缩放
- `rotate({ angle })`: 旋转
- `translate({ x, y })`: 平移

### 事件
- `onClick(callback)`: 点击事件
- `onTouch(callback)`: 触摸事件
- `onAppear(callback)`: 挂载事件
- `onDisappear(callback)`: 卸载事件

## 组件生命周期

```typescript
@Component
struct LifecycleExample {
  aboutToAppear() {
    // 组件即将挂载
    console.info('aboutToAppear');
  }

  aboutToDisappear() {
    // 组件即将卸载
    console.info('aboutToDisappear');
  }

  build() {
    Text('Lifecycle')
      .onAppear(() => {
        // 组件挂载完成
        console.info('onAppear');
      })
      .onDisappear(() => {
        // 组件卸载完成
        console.info('onDisappear');
      })
  }
}
```
