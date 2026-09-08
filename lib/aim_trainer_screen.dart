// หน้าจอเกม Aim Trainer สำหรับฝึกกดเป้าให้เร็วและแม่นยำ
// ปุ่มหลัก: เริ่มเกม, ทำซ้ำอีกรอบ, ไปหน้า Scoreboard และกลับหน้า Login

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'animated_backdrop.dart';
import 'data_player.dart';
import 'login_screen.dart';
import 'reflex_data.dart';
import 'scoreboard_screen.dart';

enum AimState { idle, playing, result }

class AimTrainerScreen extends StatefulWidget {
  final String playerName;

  const AimTrainerScreen({super.key, required this.playerName});

  @override
  State<AimTrainerScreen> createState() => _AimTrainerScreenState();
}

class _AimTrainerScreenState extends State<AimTrainerScreen> {
  static const _gameDuration = Duration(seconds: 30);
  static const _targetLifespan = Duration(milliseconds: 1200);

  final _random = Random();
  AimState _state = AimState.idle;
  Timer? _gameTimer;
  Timer? _targetTimer;
  DateTime? _startedAt;
  Size _arenaSize = Size.zero;
  Offset _targetPosition = Offset.zero;
  double _targetRadius = 32;
  int _hits = 0;
  int _misses = 0;
  int _lives = 3;
  Duration _elapsed = Duration.zero;
  int _totalTimeMs = 0;

  AimStats get _aimStats =>
      AimStats(hits: _hits, misses: _misses, totalTime: _totalTimeMs);

  double get _accuracy => _aimStats.accuracy;

  double get _speed => _aimStats.speed;

  void _startGame() {
    if (_arenaSize.width <= 0 || _arenaSize.height <= 0) return;
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    setState(() {
      _state = AimState.playing;
      _hits = 0;
      _misses = 0;
      _lives = 3;
      _elapsed = Duration.zero;
      _totalTimeMs = 0;
      _startedAt = DateTime.now();
    });
    _spawnTarget();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _startedAt == null) return;
      final elapsed = DateTime.now().difference(_startedAt!);
      if (elapsed >= _gameDuration) {
        _finishGame();
      } else {
        setState(() => _elapsed = elapsed);
      }
    });
  }

  void _spawnTarget() {
    if (_arenaSize.width <= _targetRadius * 2 ||
        _arenaSize.height <= _targetRadius * 2 ||
        _state != AimState.playing) {
      return;
    }
    _targetTimer?.cancel();
    setState(() {
      _targetRadius = (26 + _random.nextInt(23)).toDouble();
      final maxX = _arenaSize.width - _targetRadius * 2;
      final maxY = _arenaSize.height - _targetRadius * 2;
      _targetPosition = Offset(
        _random.nextDouble() * maxX,
        _random.nextDouble() * maxY,
      );
    });
    _targetTimer = Timer(_targetLifespan, _targetExpired);
  }

  void _targetExpired() {
    if (_state != AimState.playing) return;
    _misses++;
    _lives--;
    if (_lives <= 0) {
      _finishGame();
    } else {
      _spawnTarget();
    }
  }

  void _handleArenaTap(TapDownDetails details) {
    if (_state == AimState.idle) {
      _startGame();
      return;
    }
    if (_state != AimState.playing) return;

    final center = Offset(
      _targetPosition.dx + _targetRadius,
      _targetPosition.dy + _targetRadius,
    );
    final distance = (details.localPosition - center).distance;
    if (distance <= _targetRadius) {
      _hits++;
      _spawnTarget();
    } else {
      _misses++;
      _lives--;
      if (_lives <= 0) {
        _finishGame();
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _finishGame() async {
    if (_state != AimState.playing) return;
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    final elapsed = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    _totalTimeMs = min(elapsed.inMilliseconds, _gameDuration.inMilliseconds);
    setState(() {
      _elapsed = Duration(milliseconds: _totalTimeMs);
      _state = AimState.result;
    });
    await PlayerProfileStore.saveAimScore(
      name: widget.playerName,
      speed: _speed,
      hits: _hits,
      totalTime: _totalTimeMs,
      accuracy: _accuracy,
    );
  }

  void _reset() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    setState(() {
      _state = AimState.idle;
      _elapsed = Duration.zero;
      _totalTimeMs = 0;
      _hits = 0;
      _misses = 0;
      _lives = 3;
    });
  }

  String _formatTime(Duration duration) {
    return '${duration.inSeconds.toString().padLeft(2, '0')}.'
        '${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aim Trainer'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScoreboardScreen(currentId: widget.playerName),
              ),
            ),
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Scoreboard',
          ),
        ],
      ),
      body: AnimatedBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: _state == AimState.result ? _resultView() : _gameView(),
          ),
        ),
      ),
    );
  }

  Widget _gameView() => Column(
    children: [
      _statsBar(),
      const SizedBox(height: 14),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _arenaSize = Size(constraints.maxWidth, constraints.maxHeight);
            final isPlaying = _state == AimState.playing;
            return GestureDetector(
              onTapDown: _handleArenaTap,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF182124),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  children: [
                    if (!isPlaying)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.ads_click_rounded,
                              size: 62,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'พร้อมยิงหรือยัง?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'แตะพื้นที่นี้เพื่อเริ่มเกม 30 วินาที',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPlaying)
                      Positioned(
                        left: _targetPosition.dx,
                        top: _targetPosition.dy,
                        width: _targetRadius * 2,
                        height: _targetRadius * 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66FFFFFF),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF182124),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 14),
      if (_state == AimState.idle)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('เริ่มเกม'),
          ),
        )
      else
        Text(
          'แตะเป้าให้ทันก่อนหมดเวลา',
          style: TextStyle(color: Colors.white.withValues(alpha: .6)),
        ),
    ],
  );

  Widget _statsBar() => Row(
    children: [
      _stat('TIME', _formatTime(_elapsed), Icons.timer_outlined),
      _stat('HITS', '$_hits', Icons.ads_click_rounded),
      _stat(
        'SPEED',
        '${_state == AimState.result ? _speed.toStringAsFixed(2) : (_elapsed.inMilliseconds == 0 ? '0.00' : (_hits / (_elapsed.inMilliseconds / 1000)).toStringAsFixed(2))}/s',
        Icons.speed_rounded,
      ),
      _stat(
        'LIVES',
        '$_lives',
        Icons.favorite_rounded,
        color: const Color(0xFFFF6B6B),
      ),
    ],
  );

  Widget _stat(String label, String value, IconData icon, {Color? color}) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, size: 19, color: color ?? const Color(0xFFFFB547)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: .5),
              ),
            ),
          ],
        ),
      );

  Widget _resultView() => ListView(
    children: [
      const SizedBox(height: 20),
      const Text(
        'Aim Trainer จบเกม',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'สรุปผลงานของ ${widget.playerName}',
        style: TextStyle(color: Colors.white.withValues(alpha: .65)),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF303030),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              'SPEED',
              style: TextStyle(color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              '${_speed.toStringAsFixed(2)} targets/s',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _resultRow('Hits', '$_hits'),
      _resultRow('Misses', '$_misses'),
      _resultRow('Accuracy', '${_accuracy.toStringAsFixed(1)}%'),
      _resultRow('Total time', '${(_totalTimeMs / 1000).toStringAsFixed(2)} s'),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('ทำซ้ำอีกรอบ'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreboardScreen(currentId: widget.playerName),
          ),
        ),
        icon: const Icon(Icons.leaderboard_outlined),
        label: const Text('ไปหน้า Scoreboard'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        ),
        icon: const Icon(Icons.login_rounded),
        label: const Text('กลับไปหน้า Login'),
      ),
    ],
  );

  Widget _resultRow(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(
      value,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}
