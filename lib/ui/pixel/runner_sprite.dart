import 'dart:async';

import 'package:flutter/material.dart';

import 'gb_palette.dart';

/// 16×16 ランナースプライト(走り2フレーム)。
/// `.`=透明, `D`=gbDarkest, `M`=gbDark, `L`=gbLight
const runnerFrames = [
  [
    '................',
    '.....DDDD.......',
    '....DDDDDD......',
    '....DMMMMM......',
    '....DMLMMM......',
    '.....MMMM.......',
    '......MM....M...',
    '....DDDDD..MM...',
    '...MDDDDDDM.....',
    '...M.DDDDD......',
    '.....MMMM.......',
    '....MM..MM......',
    '...MM....MM.....',
    '..MM......MM....',
    '..DD.......MM...',
    '.DDD.......DDD..',
  ],
  [
    '................',
    '.....DDDD.......',
    '....DDDDDD......',
    '....DMMMMM......',
    '....DMLMMM......',
    '.....MMMM.......',
    '......MM........',
    '....DDDDDM......',
    '...MDDDDDDM.....',
    '....DDDDDD......',
    '.....MMMM.......',
    '.....MMMM.......',
    '......MMM.......',
    '......MM........',
    '.....DMM........',
    '....DDD.........',
  ],
];

const _frameColors = {
  'D': Gb.darkest,
  'M': Gb.dark,
  'L': Gb.light,
};

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.frame);

  final List<String> frame;

  @override
  void paint(Canvas canvas, Size size) {
    // 整数倍スケールでにじみを防ぐ
    final scale = (size.shortestSide / 16).floorToDouble().clamp(1.0, 64.0);
    final paintBox = Paint()..isAntiAlias = false;
    final offsetX = (size.width - 16 * scale) / 2;
    final offsetY = (size.height - 16 * scale) / 2;

    for (var y = 0; y < frame.length; y++) {
      final row = frame[y];
      for (var x = 0; x < row.length; x++) {
        final color = _frameColors[row[x]];
        if (color == null) continue;
        paintBox.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
              offsetX + x * scale, offsetY + y * scale, scale, scale),
          paintBox,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) =>
      oldDelegate.frame != frame;
}

/// 走りアニメーション付きランナースプライト。
class RunnerSprite extends StatefulWidget {
  const RunnerSprite({super.key, this.size = 96, this.running = true});

  final double size;
  final bool running;

  @override
  State<RunnerSprite> createState() => _RunnerSpriteState();
}

class _RunnerSpriteState extends State<RunnerSprite> {
  Timer? _timer;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _setupTimer();
  }

  @override
  void didUpdateWidget(RunnerSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) _setupTimer();
  }

  void _setupTimer() {
    _timer?.cancel();
    if (widget.running) {
      _timer = Timer.periodic(const Duration(milliseconds: 240), (_) {
        setState(() => _frame = (_frame + 1) % runnerFrames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _SpritePainter(runnerFrames[_frame]),
    );
  }
}

/// GBスクリーン風パネル。ドット絵コンテンツはこの上に載せる。
class GbScreen extends StatelessWidget {
  const GbScreen({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Gb.lightest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Gb.darkest, width: 3),
      ),
      padding: padding ?? const EdgeInsets.all(8),
      child: child,
    );
  }
}
