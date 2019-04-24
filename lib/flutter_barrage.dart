library flutter_barrage;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';

class BarrageWall extends StatefulWidget {
  final BarrageWallController controller;
  final Widget child;
  final int speed;
  final double width;
  final double height;
  final bool debug;

  BarrageWall({
    List<Bullet> bullets,
    BarrageWallController controller,
    ValueNotifier<BarrageWallValue> barrageNotifier,
    ValueNotifier<BarrageValue> timelineNotifier,
    this.speed = 8,
    this.child,
    this.width,
    this.height,
    this.debug = false,
  }) : controller = controller ??
            BarrageWallController.withBarrages(
              bullets,
              barrageNotifier: barrageNotifier,
              timelineNotifier: timelineNotifier,
            );

  @override
  State<StatefulWidget> createState() => _BarrageState();
}

class _BarrageState extends State<BarrageWall> with TickerProviderStateMixin {
  BarrageWallController _controller;
  Map<AnimationController, Widget> _widgets = new LinkedHashMap();
  Random _random = new Random();
  int _processed = 0;
  double _width;
  double _height;
  Timer _cleaner;

  animationCleaner(AnimationStatus status) {}

  void _handleBullets(
    BuildContext context, {
    List<Bullet> bullets,
    double width,
    double height,
    double end,
  }) {
    end ??= width * 2;
    bullets.forEach((Bullet bullet) {
      AnimationController controller;

      controller = AnimationController(
          duration: Duration(seconds: widget.speed ?? 5), vsync: this);
      Animation<double> animation =
          new Tween<double>(begin: 0, end: end).animate(controller..forward());

      final top = _random.nextInt(height.toInt()).toDouble();
      final fixedWidth = width + _random.nextInt(20).toDouble();
      final bulletWidget = AnimatedBuilder(
        animation: animation,
        child: bullet.child,
        builder: (BuildContext context, Widget child) {
          return Transform.translate(
            offset: Offset(fixedWidth - animation.value, top),
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
      _handleBullets(
        context,
        bullets: _controller.barrageNotifier.value.waitingList,
        width: _width,
        height: _height,
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

    _cleaner = Timer.periodic(Duration(seconds: 10), (timer) {
      _widgets.removeWhere((controller, widget) {
        if (controller.isCompleted) {
          controller.dispose();
          return true;
        }
        return false;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.barrageNotifier.removeListener(handleBullets);
    _controller.dispose();
    _cleaner?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, snapshot) {
      if (widget.width == null) _width = widget.width ?? snapshot.maxWidth;
      if (widget.height == null) _height = widget.height ?? snapshot.maxHeight;

      return Stack(
        fit: StackFit.loose,
        children: <Widget>[
          widget.debug
              ? Container(
                  decoration: BoxDecoration(
                      color: Colors.lightGreenAccent.withOpacity(0.8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text('${_controller.barrageNotifier.value}',
                          style: Theme.of(context).textTheme.title),
                      Text('${_controller.timelineNotifier?.value}',
                          style: Theme.of(context).textTheme.title),
                      Text('Timeline: ${_controller.timeline}',
                          style: Theme.of(context).textTheme.title),
                      Text('Bullets: ${_widgets.length}',
                          style: Theme.of(context).textTheme.title),
                    ],
                  ),
                )
              : const SizedBox(),
          widget.child,
        ]..addAll(_widgets.values ?? const SizedBox()),
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
        _map.putIfAbsent(
            key, () => TreeSet<T>(comparator: comparator)..add(value));
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

  BarrageValue copyWith({int timeline, bool isPlaying}) => BarrageValue(
      timeline: timeline ?? this.timeline,
      isPlaying: isPlaying ?? this.isPlaying);

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
      : bullets = HashList<Bullet>(
            keyCalculator: (t) => Duration(milliseconds: t.showTime).inMinutes)
          ..appendByMinutes(bullets),
        size = bullets.length,
        processedSize = 0;

  BarrageWallValue(
      {this.bullets,
      this.showedTimeBefore = 0,
      this.waitingList = const [],
      this.size = 0,
      this.processedSize = 0});

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

  BarrageWallController(
      {ValueNotifier<BarrageWallValue> barrageNotifier, this.timelineNotifier})
      : barrageNotifier = barrageNotifier ?? ValueNotifier(BarrageWallValue()),
        super(BarrageWallValue.fromList([]));

  BarrageWallController.withBarrages(List<Bullet> bullets,
      {ValueNotifier<BarrageWallValue> barrageNotifier, this.timelineNotifier})
      : barrageNotifier = barrageNotifier ?? ValueNotifier(BarrageWallValue()),
        super(BarrageWallValue.fromList(bullets ?? []));

  Future<void> initialize() async {
    final Completer<void> initializingCompleter = Completer<void>();

    if (timelineNotifier == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 100),
          (Timer timer) async {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        if (value.size == value.processedSize) {
          timer.cancel();
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

  tryFire() {
    final key = Duration(milliseconds: timeline).inMinutes;
    final exists = value.bullets._map.containsKey(key);

    if (exists) {
      final toBePrecessed = value.bullets._map[key].where((barrage) {
        return barrage.showTime > value.showedTimeBefore &&
            barrage.showTime <= timeline;
      }).toList(growable: false);

      if (toBePrecessed.isNotEmpty) {
        value = value.copyWith(
            showedTimeBefore: timeline,
            waitingList: toBePrecessed,
            processedSize: toBePrecessed.length);
        barrageNotifier.value = value;
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _timer?.cancel();
    }
    _isDisposed = true;
    timelineNotifier.removeListener(_handleTimelineNotifier);
    barrageNotifier.dispose();
    super.dispose();
  }
}

class Bullet implements Comparable<Bullet> {
  final Widget child;

  /// in milliseconds
  final int showTime;

  const Bullet({@required this.child, @required this.showTime});

  @override
  String toString() {
    return 'Barrage{showTime: $showTime}';
  }

  @override
  int compareTo(Bullet other) {
    return showTime.compareTo(other.showTime);
  }
}
