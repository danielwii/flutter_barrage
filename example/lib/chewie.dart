import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_barrage/flutter_barrage.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
  ValueNotifier<BarrageValue> timelineNotifier;
  VideoPlayerController videoPlayerController;
  BarrageWallController barrageWallController;
  ChewieController chewieController;

  @override
  void initState() {
    super.initState();
    timelineNotifier = ValueNotifier(BarrageValue());
    videoPlayerController = VideoPlayerController.network(
        'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_10mb.mp4')
      ..addListener(() {
        timelineNotifier.value = timelineNotifier.value.copyWith(
          timeline: videoPlayerController.value.position.inMilliseconds,
          isPlaying: videoPlayerController.value.isPlaying,
        );
      });
    barrageWallController = BarrageWallController(
      timelineNotifier: timelineNotifier,
    );

    Random random = new Random();
    List<Bullet> bullets = List<Bullet>.generate(1000, (i) {
      final showTime = random.nextInt(60000); // in 60s
      return Bullet(
          child: Container(
            margin: EdgeInsets.all(2),
            color: Colors.black,
            child: Container(
                padding: EdgeInsets.all(2), color: Colors.white, child: Text('$i-$showTime')),
          ),
          showTime: showTime);
    });
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: false,
      overlay: BarrageWall(
          debug: true,
          safeBottomHeight: 60, // do not send bullets to the safe area
          /*
          speed: 8,*/
          speedCorrection: 3000,
          controller: barrageWallController,
          /*
          timelineNotifier: timelineNotifier,*/
          bullets: bullets,
          child: const SizedBox()),
    );
  }

  @override
  void dispose() {
    super.dispose();
    timelineNotifier?.dispose();
    barrageWallController?.dispose();
    videoPlayerController?.dispose();
    chewieController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          if (orientation == Orientation.landscape) {
            return Chewie(controller: chewieController);
          }

          return SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 9,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: 20,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width *
                                MediaQuery.of(context).size.aspectRatio +
                            300,
                        child: Chewie(controller: chewieController),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          /*
                          controller: textEditingController,*/
                          maxLength: 20,
                          onSubmitted: (text) {
                            /*
                            textEditingController.clear();*/
                            barrageWallController.send([new Bullet(child: Text(text))]);
                          })),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
