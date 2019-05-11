# flutter_barrage

A barrage wall flutter plugin.
一个弹幕墙插件。

## Getting Started

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
