// หน้าจอเกม Time Reflex Test สำหรับวัดเวลาตอบสนองของผู้เล่น
// ปุ่มหลัก: เริ่มเกม, ทำซ้ำอีกรอบ, ไปหน้า Scoreboard และกลับหน้า Login

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'animated_backdrop.dart';
import 'data_player.dart';
import 'login_screen.dart';
import 'scoreboard_screen.dart';

enum ReflexState { idle, waiting, action, result }

class ReflexTestScreen extends StatefulWidget {
  final String playerName;
  const ReflexTestScreen({super.key, required this.playerName});

  @override
  State<ReflexTestScreen> createState() => _ReflexTestScreenState();
}

class _ReflexTestScreenState extends State<ReflexTestScreen> {
  static const _totalRounds = 3;

  ReflexState _state = ReflexState.idle;
  final List<int> _times = [];
  Timer? _timer;
  DateTime? _startTime;
  String _notice = '';

  int get _round => min(_times.length + 1, _totalRounds);

  void _beginRound() {
    _timer?.cancel();
    setState(() {
      _state = ReflexState.waiting;
      _notice = 'อย่าเพิ่งกด';
    });
    final delay = 1000 + Random().nextInt(4001);
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _state = ReflexState.action;
        _startTime = DateTime.now();
        _notice = 'กดเลย!';
      });
    });
  }

  Future<void> _tapTarget() async {
    if (_state == ReflexState.waiting) {
      _timer?.cancel();
      setState(() {
        _state = ReflexState.idle;
        _notice = 'กดเร็วเกินไป! ลองรอบนี้ใหม่';
      });
      return;
    }
    if (_state != ReflexState.action || _startTime == null) return;
    final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
    setState(() {
      _times.add(elapsed);
      _state = _times.length == _totalRounds
          ? ReflexState.result
          : ReflexState.idle;
      _notice = _times.length == _totalRounds
          ? 'ครบ $_totalRounds รอบแล้ว'
          : 'รอบต่อไปพร้อมเมื่อไหร่กดปุ่มได้เลย';
    });
    if (_times.length == _totalRounds) {
      final sorted = [..._times]..sort();
      await PlayerProfileStore.saveReflexScore(
        name: widget.playerName,
        score: sorted[1],
      );
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _times.clear();
      _state = ReflexState.idle;
      _notice = '';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = _state == ReflexState.waiting;
    final isAction = _state == ReflexState.action;
    final sorted = [..._times]..sort();
    final median = sorted.length == _totalRounds ? sorted[1] : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('รอบ $_round / $_totalRounds'),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: _state == ReflexState.result
                ? _resultView(sorted, median!)
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        widget.playerName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .65),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _tapTarget,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isAction
                                  ? const Color(0xFF21C997)
                                  : isWaiting
                                  ? const Color(0xFFE04F4F)
                                  : const Color(0xFF20292B),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAction
                                        ? Icons.touch_app_rounded
                                        : Icons.pan_tool_outlined,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    isAction
                                        ? 'กด!'
                                        : isWaiting
                                        ? 'รอสีเขียว'
                                        : 'พร้อมหรือยัง?',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _notice.isEmpty
                                        ? 'กดปุ่มเพื่อเริ่มจับเวลา'
                                        : _notice,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _state == ReflexState.idle
                              ? _beginRound
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            _times.isEmpty ? 'พร้อม' : 'เริ่มรอบถัดไป',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _resultView(List<int> sorted, int median) => ListView(
    children: [
      const SizedBox(height: 26),
      const Text(
        'ผลการทดสอบ',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'ค่ามัธยฐานของ $_totalRounds รอบคือ',
        style: TextStyle(color: Colors.white.withValues(alpha: .65)),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF303030),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              'FINAL SCORE',
              style: TextStyle(color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              '$median ms',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      ..._times.asMap().entries.map(
        (item) => ListTile(
          leading: CircleAvatar(child: Text('${item.key + 1}')),
          title: Text('${item.value} ms'),
          trailing: item.value == median
              ? const Chip(label: Text('Median'))
              : null,
        ),
      ),
      const SizedBox(height: 12),
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
}
