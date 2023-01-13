# flutter_barrage

A barrage wall flutter plugin.
一个弹幕墙插件。

## Getting Started

#### BarrageWall 参数

* **List<Bullet> bullets** - 初始化的弹幕列表
* **BarrageWallController controller** - 用于初始化后批量发送弹幕的 controller
* **ValueNotifier<BarrageValue> timelineNotifier** - 用于连接媒体的当前播放进度 
* **int speed** - 速度，从屏幕右侧到左侧的时间，默认 5
* **child** - 用于填充的容器
* **double width** - 容器宽度
* **double height** - 容器高度
* **bool massiveMode** - 海量模式，默认关闭，此时当所有通道都被占用时弹幕将被丢弃，不会产生覆盖的情况。当开启式会实时显示所有弹幕，所有通道被占用时会覆盖之前的弹幕。
* **double maxBulletHeight** - 弹幕的最大高度，用于计算通道，默认 16。
* **int speedCorrectionInMilliseconds** - 默认 3000，用于调整不同通道的速度，不同的通道会在这个值的范围内找到一个随机值并调整当前通道的速度
* **bool debug** - 调试模式，会显示一个数据面板
* **int safeBottomHeight** - 默认 0，用于保证在最下方有一个不会显示弹幕的空间，避免挡住字幕

[more examples - 详细用法请查看 examples](https://github.com/danielwii/flutter_barrage/tree/master/example)

* show barrage only

```dart
List<Bullet> bullets = List<Bullet>.generate(100, (i) {
  final showTime = random.nextInt(60000); // in 60s
  return Bullet(child: Text('$i-$showTime}'), showTime: showTime);
});
Stack(
  children: <Widget>[
    Positioned(
      top: 200,
      width: MediaQuery.of(context).size.width,
      height:
          MediaQuery.of(context).size.width * MediaQuery.of(context).size.aspectRatio + 200,
      child: BarrageWall(
        massiveMode: false, // disabled by default
        timelineNotifier: timelineNotifier, // send a BarrageValue notifier let bullet fires using your own timeline
        bullets: bullets,
        child: new Container(),
      ),
    )
  ],
);
```

* show barrage with send bullet function

```dart
Column(
  children: <Widget>[
    Expanded(
      flex: 9,
      child: Stack(
        children: <Widget>[
          Positioned(
//                    top: 20,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width *
                    MediaQuery.of(context).size.aspectRatio +
                100,
            child: BarrageWall(
              debug: true, // show debug panel
              speed: 4, // speed of bullet show in screen (seconds)
              /*
              speed: 8,
              speedCorrectionInMilliseconds: 3000,*/
              /*
                timelineNotifier: timelineNotifier, // send a BarrageValue notifier let bullet fires using your own timeline*/
              bullets: bullets,
              child: new Container(),
              controller: barrageWallController,
            ),
          ),
        ],
      ),
    ),
    Expanded(
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
//                    controller: textEditingController,
              maxLength: 20,
              onSubmitted: (text) {
//                      textEditingController.clear();
                barrageWallController.send([new Bullet(child: Text(text))]);
              })),
    ),
  ],
)
```
