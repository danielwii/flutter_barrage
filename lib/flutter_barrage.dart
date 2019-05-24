library flutter_barrage;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';

class BarrageWall extends StatefulWidget {
  final BarrageWallController controller;

  /// the bullet widget
  final Widget child;

  /// time in seconds of bullet show in screen
  final int speed;

  /// used to adjust speed for each channel
  final int speedCorrection;

  final double width;
  final double height;

  /// will not send bullets to the area is safe from bottom, default is 0
  /// used to not cover the subtitles
  final int safeBottomHeight;

  /// disable by default, will overwrite other bullets
  final bool massiveMode;

  /// used to make barrage tidy
  final double maxBulletHeight;

  /// enable debug mode, will display a debug panel with information
  final bool debug;
  final bool selfCreatedController;

  BarrageWall({
    List<Bullet> bullets,
    BarrageWallController controller,
    ValueNotifier<BarrageWallValue> barrageNotifier,
    ValueNotifier<BarrageValue> timelineNotifier,
    this.speed,
    this.child,
    this.width,
    this.height,
    this.massiveMode,
    this.maxBulletHeight,
    this.debug = false,
    this.safeBottomHeight = 0,
    this.speedCorrection = 0,
  })  : controller = controller ??
            BarrageWallController.withBarrages(
              bullets,
              barrageNotifier: barrageNotifier,
              timelineNotifier: timelineNotifier,
            ),
        selfCreatedController = controller == null {
    if (controller != null) {
      this.controller.value =
          controller.value.size == 0 ? BarrageWallValue.fromList(bullets ?? []) : controller.value;
      this.controller.barrageNotifier = controller.barrageNotifier ?? barrageNotifier;
      this.controller.timelineNotifier = controller.timelineNotifier ?? timelineNotifier;
    }
  }

  @override
  State<StatefulWidget> createState() => _BarrageState();
}

class BulletPos {
  int id;
  double position;
  double width;
  bool released = false;
  int lifetime;

  BulletPos({this.id, this.position, this.width})
      : lifetime = DateTime.now().millisecondsSinceEpoch;

  updateWith({int id, double position, double width = 0}) {
    if (id == this.id) {
      this.position = position;
      this.width = width > 0 ? width : this.width;
    } else {
      if (this.position > position) {
        this.id = id;
        this.position = position;
        this.width = width > 0 ? width : this.width;
        this.released = false;
        this.lifetime = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  bool get hasExtraSpace => position > width + 8;

  @override
  String toString() {
    return 'BulletPos{id: $id, position: $position, width: $width, released: $released}';
  }
}

class _BarrageState extends State<BarrageWall> with TickerProviderStateMixin {
  BarrageWallController _controller;
  Map<AnimationController, Widget> _widgets = new LinkedHashMap();
  Random _random = new Random();
  int _processed = 0;
  double _width;
  double _height;
  Timer _cleaner;

  int _maxBulletHeight;
  int _usedChannel = 0;
  int _totalChannels;
  int _channelMask;
  Map<dynamic, BulletPos> _lastBullets = {};
  List<int> _speedCorrectionForChannels = [];

  int _calcSafeHeight(double height) => height.isInfinite
      ? context.size.height.toInt()
      : (height - (_controller.safeBottomHeight ?? widget.safeBottomHeight)).toInt();

  /// null means no available channels exists
  int _nextChannel() {
    final _randomSeed = _totalChannels - 1;

    if (_usedChannel ^ _channelMask == 0) {
      return null;
    }

    var times = 1;
    var channel = _random.nextInt(_randomSeed);
    var channelCode = 1 << channel;

    while (_usedChannel & channelCode != 0 && _usedChannel ^ _channelMask != 0) {
      times++;
      channel = channel >= _totalChannels ? 0 : channel + 1;
      channelCode = 1 << channel;

      /// return random channel if no channels available and massive mode is enabled
      if (times > _totalChannels) {
        if (widget.massiveMode == true) {
          return _random.nextInt(_randomSeed);
        }
        return null;
      }
    }
    _usedChannel |= (1 << channel);
    return channel;
  }

  _releaseChannels() {
    for (int i = 0; i < _lastBullets.length; i++) {
      final channel = _lastBullets.keys.elementAt(i);
      var isNotReleased = !_lastBullets[channel].released;
      var liveTooLong = false; // now - _lastBullets[channel].lifetime > 3000;
      if (liveTooLong || (isNotReleased && _lastBullets[channel].hasExtraSpace)) {
        _lastBullets[channel].released = true;
        _usedChannel &= _channelMask ^ 1 << channel;
      }
    }
  }

  void _handleBullets(
    BuildContext context, {
    List<Bullet> bullets,
    double width,
    double end,
  }) {
    // cannot get the width of widget when not rendered, make a twice longer width for now
    end ??= width * 2;

    bullets.forEach((Bullet bullet) {
      AnimationController controller;

      _releaseChannels();
      final nextChannel = _nextChannel();
      if (nextChannel != null) {}

      /// discard bullets do not have available channel and massive mode is not enabled too
      if (nextChannel == null) {
        return;
      }

      final showTimeInMilliseconds =
          (widget.speed ?? 5) * 2 * 1000 - _speedCorrectionForChannels[nextChannel];
      controller = AnimationController(
          duration: Duration(milliseconds: showTimeInMilliseconds), vsync: this);
      Animation<double> animation =
          new Tween<double>(begin: 0, end: end).animate(controller..forward());

      final channelHeightPos = nextChannel * _maxBulletHeight;

      /// make bullets not showed up in same time
      final fixedWidth = width + _random.nextInt(20).toDouble();
      final bulletWidget = AnimatedBuilder(
        animation: animation,
        child: bullet.child,
        builder: (BuildContext context, Widget child) {
          var widgetWidth = 0.0;
          if (animation.isCompleted) {
            return const SizedBox();
          }

          if (context.findRenderObject() != null) {
            final RenderBox box = context.findRenderObject();

            if (box != null && RenderObject.debugActiveLayout == null) {
              widgetWidth = box?.size?.width;
            }

            if (box != null &&
                RenderObject.debugActiveLayout == null &&
                animation.value > (fixedWidth + widgetWidth)) {
              return const SizedBox();
            }
          }

          final widthPos = fixedWidth - animation.value;

          _releaseChannels();
          if (!_lastBullets.containsKey(nextChannel)) {
            _lastBullets[nextChannel] =
                BulletPos(id: context.hashCode, position: animation.value, width: widgetWidth);
          }

          _lastBullets[nextChannel]?.updateWith(
            id: context.hashCode,
            position: animation.value,
            width: widgetWidth,
          );

          return Transform.translate(
            offset: Offset(widthPos, channelHeightPos.toDouble()),
            child: child,
          );
        },
      );
      _widgets.putIfAbsent(controller, () => bulletWidget);
    });
  }

  @override
  void didUpdateWidget(BarrageWall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller != null && widget.controller == null) {
        _controller = widget.controller;
      }
    }
  }

  void handleBullets() {
    if (_processed != _controller.barrageNotifier.value.processedSize) {
      if (_width == null || _height == null) {
        return;
      }

      if (_totalChannels == null) {
        _maxBulletHeight = widget.maxBulletHeight ?? 16;
        _totalChannels = _calcSafeHeight(_height) ~/ _maxBulletHeight;
        _channelMask = (2 << _totalChannels) - 1;

        List<int>.generate(_totalChannels + 1, (i) {
          _speedCorrectionForChannels
              .add(widget.speedCorrection > 0 ? _random.nextInt(widget.speedCorrection) : 0);
        });
      }

      _handleBullets(
        context,
        bullets: _controller.barrageNotifier.value.waitingList,
        width: _width,
      );
      _processed += _controller.barrageNotifier.value.waitingList.length;
      setState(() {});
    }
  }

  @override
  void initState() {
    _controller = widget.controller;
    _controller.initialize();

    _controller.barrageNotifier.addListener(handleBullets);

    /*
    _cleaner = Timer.periodic(Duration(seconds: 10), (timer) {
      _widgets.removeWhere((controller, widget) {
        if (controller.isCompleted) {
          controller.dispose();
          return true;
        }
        return false;
      });
    });*/

    super.initState();
  }

  @override
  void dispose() {
    if (widget.selfCreatedController) {
      _controller.barrageNotifier.removeListener(handleBullets);
      _controller.dispose();
    }
    _cleaner?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, snapshot) {
      _width = widget.width ?? snapshot.maxWidth;
      _height = widget.height ?? snapshot.maxHeight;

      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.debug
              ? Container(
                  color: Colors.lightBlueAccent.withOpacity(0.7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text('BarrageNotifier: ${_controller.barrageNotifier.value}'),
                      Text('TimelineNotifier: ${_controller.timelineNotifier?.value}'),
                      Text('Timeline: ${_controller.timeline}'),
                      Text('Bullets: ${_widgets.length}'),
                      Text('UsedChannels: ${_usedChannel.toRadixString(2)}'),
                    ],
                  ),
                )
              : const SizedBox(),
          widget.child,
          Stack(
            fit: StackFit.loose,
            children: <Widget>[]..addAll(_widgets.values ?? const SizedBox()),
          ),
        ],
      );
    });
  }
}

typedef int KeyCalculator<T>(T t);

class HashList<T> {
  /// key is the showTime in minutes
  Map<int, TreeSet<T>> _map = new HashMap();
  final Comparator<T> comparator;
  final KeyCalculator<T> keyCalculator;

  HashList({@required this.keyCalculator, this.comparator});

  void appendByMinutes(List<T> values) {
    values.forEach((value) {
      int key = keyCalculator(value);
      if (_map.containsKey(key)) {
        _map[key].add(value);
      } else {
        _map.putIfAbsent(key, () => TreeSet<T>(comparator: comparator)..add(value));
      }
    });
  }

  @override
  String toString() {
    return 'HashList{$_map}';
  }
}

class BarrageValue {
  final int timeline;
  final bool isPlaying;

  BarrageValue({this.timeline = -1, this.isPlaying = false});

  BarrageValue copyWith({int timeline, bool isPlaying}) =>
      BarrageValue(timeline: timeline ?? this.timeline, isPlaying: isPlaying ?? this.isPlaying);

  @override
  String toString() {
    return 'BarrageValue{timeline: $timeline, isPlaying: $isPlaying}';
  }
}

class BarrageWallValue {
  final HashList<Bullet> bullets;
  final int showedTimeBefore;
  final int size;
  final int processedSize;
  final List<Bullet> waitingList;

  BarrageWallValue.fromList(List<Bullet> bullets,
      {this.showedTimeBefore = 0, this.waitingList = const []})
      : bullets =
            HashList<Bullet>(keyCalculator: (t) => Duration(milliseconds: t.showTime).inMinutes)
              ..appendByMinutes(bullets),
        size = bullets.length,
        processedSize = 0;

  BarrageWallValue({
    this.bullets,
    this.showedTimeBefore = 0,
    this.waitingList = const [],
    this.size = 0,
    this.processedSize = 0,
  });

  BarrageWallValue copyWith({
    int showedTimeBefore,
    int lastProcessedTime,
    List<Bullet> waitingList,
    int processedSize,
  }) =>
      BarrageWallValue(
        bullets: bullets ?? this.bullets,
        showedTimeBefore: showedTimeBefore ?? this.showedTimeBefore,
        waitingList: waitingList ?? this.waitingList,
        size: this.size,
        processedSize: this.processedSize + processedSize,
      );

  @override
  String toString() {
    return 'BarrageWallValue{showedTimeBefore: $showedTimeBefore, size: $size, processed: $processedSize, waitings: ${waitingList.length}}';
  }
}

class BarrageWallController extends ValueNotifier<BarrageWallValue> {
  ValueNotifier<BarrageWallValue> barrageNotifier;
  ValueNotifier<BarrageValue> timelineNotifier;
  Timer _timer;
  bool _isDisposed = false;
  int timeline = 0;
  int safeBottomHeight;

  BarrageWallController({
    List<Bullet> bullets,
    ValueNotifier<BarrageWallValue> barrageNotifier,
    this.timelineNotifier,
  })  : barrageNotifier = barrageNotifier ?? ValueNotifier(BarrageWallValue()),
        super(BarrageWallValue.fromList(bullets ?? const []));

  BarrageWallController.withBarrages(List<Bullet> bullets,
      {ValueNotifier<BarrageWallValue> barrageNotifier, this.timelineNotifier})
      : barrageNotifier = barrageNotifier ?? ValueNotifier(BarrageWallValue()),
        super(BarrageWallValue.fromList(bullets ?? const []));

  Future<void> initialize() async {
    final Completer<void> initializingCompleter = Completer<void>();

    if (timelineNotifier == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer timer) async {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (value.size == value.processedSize) {
          /*
          timer.cancel();*/
          return;
        }

        timeline += 100;
        tryFire();
      });
    } else {
      timelineNotifier.addListener(_handleTimelineNotifier);
    }

    initializingCompleter.complete();
    return initializingCompleter.future;
  }

  void _handleTimelineNotifier() {
    timeline = timelineNotifier.value.timeline;
    tryFire();
  }

  tryFire({List<Bullet> bullets = const []}) {
    final key = Duration(milliseconds: timeline).inMinutes;
    final exists = value.bullets._map.containsKey(key);

    if (exists || bullets.isNotEmpty) {
      List<Bullet> toBePrecessed = value.bullets._map[key]
              ?.where((barrage) =>
                  barrage.showTime > value.showedTimeBefore && barrage.showTime <= timeline)
              ?.toList() ??
          [];

      if (toBePrecessed.isNotEmpty || bullets.isNotEmpty) {
        value = value.copyWith(
            showedTimeBefore: timeline,
            waitingList: toBePrecessed..addAll(bullets ?? []),
            processedSize: toBePrecessed.length);

        barrageNotifier.value = value;
      }
    }
  }

  send(List<Bullet> bullets) {
    tryFire(bullets: bullets);
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _timer?.cancel();
    }
    _isDisposed = true;
    timelineNotifier?.removeListener(_handleTimelineNotifier);
    barrageNotifier.dispose();
    super.dispose();
  }
}

class Bullet implements Comparable<Bullet> {
  final Widget child;

  /// in milliseconds
  final int showTime;

  const Bullet({@required this.child, this.showTime});

  @override
  String toString() {
    return 'Barrage{showTime: $showTime}';
  }

  @override
  int compareTo(Bullet other) {
    return showTime.compareTo(other.showTime);
  }
}
