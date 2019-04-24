import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_barrage/flutter_barrage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Barrage Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Flutter Barrage Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    Random random = new Random();
    List<Bullet> bullets = List<Bullet>.generate(100, (i) {
      final showTime = random.nextInt(60000); // in 60s
      return Bullet(child: Text('$i-$showTime}'), showTime: showTime);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 200,
              width: MediaQuery.of(context).size.width,
              height:
                  MediaQuery.of(context).size.width * MediaQuery.of(context).size.aspectRatio + 200,
              child: BarrageWall(
                debug: true,
                /*
                  timelineNotifier: timelineNotifier, // send a BarrageValue notifier let bullet fires using your own timeline*/
                bullets: bullets,
                child: new Container(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
