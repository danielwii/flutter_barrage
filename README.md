# flutter_barrage

A barrage wall flutter plugin.
一个弹幕墙插件。

## Getting Started

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
        timelineNotifier: timelineNotifier, // send a BarrageValue notifier let bullet fires using your own timeline
        bullets: bullets,
        child: new Container(),
      ),
    )
  ],
);
```
