import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animated_backdrop.dart';
import 'data_player.dart';
import 'login_screen.dart';
import 'mode_selection_screen.dart';

enum ColorWheelGameState { idle, waitingPrompt, activeReaction, gameOver }

class ColorWheelReflexScreen extends StatefulWidget {
  final String playerName;

  const ColorWheelReflexScreen({super.key, required this.playerName});

  @override
  State<ColorWheelReflexScreen> createState() => _ColorWheelReflexScreenState();
}

class _ColorWheelReflexScreenState extends State<ColorWheelReflexScreen>
    with SingleTickerProviderStateMixin {
  static const _colors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1565C0),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
  ];
  static const _colorNames = <String>['แดง', 'ฟ้าเข้ม', 'เขียว', 'ส้ม'];
  static const _tau = pi * 2;
  static const _gameDuration = Duration(seconds: 30);

  final _random = Random();
  late final AnimationController _rotationController;
  final _stopwatch = Stopwatch();
  Timer? _phaseTimer;
  Timer? _gameTimer;
  ColorWheelGameState _gameState = ColorWheelGameState.idle;
  Duration _remaining = _gameDuration;
  int _score = 0;
  int _stage = 1;
  int? _targetColorIndex;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: _spinDurationForStage,
    );
  }

  Duration get _spinDurationForStage {
    final milliseconds = max(400, 1800 - (_stage - 1) * 100);
    return Duration(milliseconds: milliseconds);
  }

  void _startGame() {
    _phaseTimer?.cancel();
    _gameTimer?.cancel();
    _rotationController
      ..stop()
      ..value = 0;
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _score = 0;
      _stage = 1;
      _targetColorIndex = null;
      _remaining = _gameDuration;
      _gameState = ColorWheelGameState.waitingPrompt;
    });
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _gameState == ColorWheelGameState.gameOver) return;
      final elapsed = _stopwatch.elapsed;
      if (elapsed >= _gameDuration) {
        unawaited(_finishGame());
        return;
      }
      setState(() => _remaining = _gameDuration - elapsed);
    });
    _beginStage();
  }

  void _beginStage() {
    _phaseTimer?.cancel();
    _rotationController
      ..duration = _spinDurationForStage
      ..repeat();
    setState(() {
      _targetColorIndex = null;
      _gameState = ColorWheelGameState.waitingPrompt;
    });
    final delay = Duration(seconds: 2 + _random.nextInt(2));
    _phaseTimer = Timer(delay, () {
      if (!mounted || _gameState != ColorWheelGameState.waitingPrompt) return;
      setState(() {
        _targetColorIndex = _random.nextInt(_colors.length);
        _gameState = ColorWheelGameState.activeReaction;
      });
    });
  }

  int _colorAtIndicator() {
    final angle = _rotationController.value * _tau;
    final offset = (pi - angle) % _tau;
    final normalizedOffset = (offset + _tau) % _tau;
    return (normalizedOffset / (pi / 2)).floor();
  }

  void _stopAndCheck() {
    if (_gameState != ColorWheelGameState.activeReaction) return;
    _phaseTimer?.cancel();
    _rotationController.stop();
    if (_colorAtIndicator() != _targetColorIndex) {
      unawaited(_finishGame());
      return;
    }

    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _score++;
      _stage++;
      _targetColorIndex = null;
      _remaining = _gameDuration;
      _gameState = ColorWheelGameState.waitingPrompt;
    });
    _beginStage();
  }

  Future<void> _finishGame() async {
    if (_gameState == ColorWheelGameState.gameOver) return;
    _phaseTimer?.cancel();
    _gameTimer?.cancel();
    _stopwatch.stop();
    _rotationController.stop();
    if (!mounted) return;
    setState(() {
      _targetColorIndex = null;
      _gameState = ColorWheelGameState.gameOver;
    });
    await PlayerProfileStore.saveColorWheelScore(
      name: widget.playerName,
      score: _score,
      stage: _stage,
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _gameTimer?.cancel();
    _stopwatch.stop();
    _rotationController.dispose();
    super.dispose();
  }

  String get _statusMessage => switch (_gameState) {
    ColorWheelGameState.idle => 'พร้อมแล้วหรือยัง?',
    ColorWheelGameState.waitingPrompt => 'วงล้อกำลังหมุน... เตรียมตัวให้พร้อม',
    ColorWheelGameState.activeReaction =>
      'หยุดเมื่อสี${_colorNames[_targetColorIndex!]}ตรงกับลูกศร',
    ColorWheelGameState.gameOver => 'จบเกม',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color Wheel Reflex')),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey != LogicalKeyboardKey.space ||
              _gameState == ColorWheelGameState.idle ||
              _gameState == ColorWheelGameState.gameOver) {
            return KeyEventResult.ignored;
          }
          if (event is KeyDownEvent &&
              _gameState == ColorWheelGameState.activeReaction) {
            _stopAndCheck();
          }
          return KeyEventResult.handled;
        },
        child: AnimatedBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _gameState == ColorWheelGameState.gameOver
                      ? _buildResult()
                      : _buildGame(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HudValue(
            label: 'เวลาที่เหลือ',
            value: '${(_remaining.inMilliseconds / 1000).ceil()} วิ',
          ),
          _HudValue(label: 'คะแนน', value: '$_score'),
          _HudValue(label: 'ด่าน', value: '$_stage'),
        ],
      ),
      const SizedBox(height: 28),
      LayoutBuilder(
        builder: (context, constraints) {
          final diameter = min(320.0, constraints.maxWidth);
          return SizedBox(
            width: diameter,
            height: diameter + 22,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) => Transform.rotate(
                    angle: _rotationController.value * _tau,
                    child: child,
                  ),
                  child: CustomPaint(
                    size: Size.square(diameter),
                    painter: _ColorWheelPainter(colors: _colors),
                  ),
                ),
                Positioned(
                  top: diameter - 30,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 60,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: .8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      if (_gameState == ColorWheelGameState.idle)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('พร้อม'),
          ),
        )
      else if (_gameState == ColorWheelGameState.activeReaction)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _stopAndCheck,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('หยุด'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB547),
              foregroundColor: const Color(0xFF17191D),
            ),
          ),
        ),
      const SizedBox(height: 20),
      Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _gameState == ColorWheelGameState.activeReaction ? 24 : 20,
          fontWeight: FontWeight.bold,
          color: _gameState == ColorWheelGameState.activeReaction
              ? _colors[_targetColorIndex!]
              : Colors.white,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _gameState == ColorWheelGameState.activeReaction
            ? 'กดปุ่มหยุดหรือ Spacebar เพื่อตรวจสอบสีที่ลูกศรชี้'
            : 'รอคำสั่งสีสุ่ม 2–3 วินาที แล้วกดหยุดให้ทันก่อนหมดเวลา',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: .7)),
      ),
    ],
  );

  Widget _buildResult() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
      const SizedBox(height: 16),
      const Text(
        'สรุปผลเกม',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text('ผู้เล่น ${widget.playerName}'),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HudValue(label: 'แต้มที่ได้', value: '$_score'),
          _HudValue(label: 'ด่านที่ไปถึง', value: '$_stage'),
        ],
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _startGame,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('เล่นอีกรอบ'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ModeSelectionScreen(playerName: widget.playerName),
            ),
            (route) => route.isFirst,
          ),
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('เปลี่ยนโหมด'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
          icon: const Icon(Icons.home_rounded),
          label: const Text('ไปหน้าเมนู'),
        ),
      ),
    ],
  );
}

class _HudValue extends StatelessWidget {
  final String label;
  final String value;

  const _HudValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .65),
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _ColorWheelPainter extends CustomPainter {
  final List<Color> colors;

  const _ColorWheelPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < colors.length; index++) {
      paint.color = colors[index];
      canvas.drawArc(bounds, -pi / 2 + index * pi / 2, pi / 2, true, paint);
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: .8)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: .8)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * .08,
      Paint()..color = const Color(0xFF17191D),
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
