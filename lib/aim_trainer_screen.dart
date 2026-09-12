// หน้าจอเกม Aim Trainer สำหรับฝึกกดเป้าให้เร็วและแม่นยำ
// ปุ่มหลัก: เริ่มเกม, ทำซ้ำอีกรอบ, ไปหน้า Scoreboard และกลับหน้า Login

// ใช้ Timer สำหรับนับเวลาเกมและกำหนดอายุของเป้า
import 'dart:async';
// ใช้ Random และ min สำหรับสุ่มตำแหน่ง/ขนาดเป้าและจำกัดเวลาเกม
import 'dart:math';

// ใช้สร้าง Widget และควบคุมสถานะหน้าจอ Flutter
import 'package:flutter/material.dart';

// เชื่อมพื้นหลังแบบเคลื่อนไหวที่ใช้ร่วมกับหน้าจออื่นในระบบ
import 'animated_backdrop.dart';
// เชื่อมบริการจัดเก็บโปรไฟล์และคะแนนของผู้เล่น
import 'data_player.dart';
// เชื่อมปุ่มกลับไปยังหน้าล็อกอิน
import 'login_screen.dart';
// ใช้กลับไปยังหน้าเลือกโหมดการเล่น
import 'mode_selection_screen.dart';
// ใช้คลาส AimStats สำหรับคำนวณความเร็วและความแม่นยำ
import 'reflex_data.dart';
// เชื่อมไปยังหน้าตารางคะแนน
import 'scoreboard_screen.dart';

// สถานะหลักของเกม: ยังไม่เริ่ม, กำลังเล่น, หรือแสดงผลลัพธ์
enum AimState { idle, playing, result }

// หน้าจอเกม Aim Trainer ซึ่งรับชื่อผู้เล่นมาจากหน้าก่อนหน้า
class AimTrainerScreen extends StatefulWidget {
  // ชื่อที่ใช้แสดงผลและบันทึกคะแนนให้ผู้เล่นคนนี้
  final String playerName;

  // สร้างหน้าจอเกมโดยกำหนดชื่อผู้เล่นแบบบังคับ
  const AimTrainerScreen({super.key, required this.playerName});

  // สร้าง State เพื่อให้หน้าจออัปเดตเมื่อคะแนนหรือสถานะเกมเปลี่ยน
  @override
  State<AimTrainerScreen> createState() => _AimTrainerScreenState();
}

// State ที่ควบคุมกติกา การจับเวลา และการแสดงผลของ Aim Trainer
class _AimTrainerScreenState extends State<AimTrainerScreen> {
  // ระยะเวลาสูงสุดของหนึ่งรอบเกม
  static const _gameDuration = Duration(seconds: 30);
  // ระยะเวลาที่เป้าหนึ่งเป้าจะแสดงก่อนนับเป็นพลาด
  static const _targetLifespan = Duration(milliseconds: 1200);

  // ตัวสุ่มสำหรับสร้างขนาดและตำแหน่งเป้า
  final _random = Random();
  // สถานะปัจจุบันของเกม ใช้เลือก View ที่จะแสดง
  AimState _state = AimState.idle;
  // Timer สำหรับตรวจเวลารวมของเกมทุก 100 มิลลิวินาที
  Timer? _gameTimer;
  // Timer สำหรับตรวจว่าเป้าปัจจุบันหมดอายุหรือยัง
  Timer? _targetTimer;
  // เวลาเริ่มเกม ใช้คำนวณเวลาที่เล่นจริง
  DateTime? _startedAt;
  // ขนาดพื้นที่เล่นจริงจาก LayoutBuilder
  Size _arenaSize = Size.zero;
  // ตำแหน่งมุมซ้ายบนของเป้าภายในพื้นที่เล่น
  Offset _targetPosition = Offset.zero;
  // รัศมีของเป้าปัจจุบัน
  double _targetRadius = 32;
  // จำนวนครั้งที่แตะเป้าถูก
  int _hits = 0;
  // จำนวนครั้งที่แตะพลาดหรือปล่อยให้เป้าหมดอายุ
  int _misses = 0;
  // จำนวนชีวิตที่เหลือของผู้เล่น
  int _lives = 3;
  // เวลาที่แสดงบนหน้าจอระหว่างเล่น
  Duration _elapsed = Duration.zero;
  // เวลาเล่นรวมในหน่วยมิลลิวินาทีที่ส่งไปบันทึกคะแนน
  int _totalTimeMs = 0;

  // รวมข้อมูลดิบของเกมเป็นออบเจ็กต์สำหรับคำนวณสถิติ
  AimStats get _aimStats =>
      AimStats(hits: _hits, misses: _misses, totalTime: _totalTimeMs);

  // คืนค่าความแม่นยำจาก AimStats
  double get _accuracy => _aimStats.accuracy;

  // คืนค่าความเร็วการยิงจาก AimStats
  double get _speed => _aimStats.speed;

  // เริ่มเกมรอบใหม่และรีเซ็ตข้อมูลจากรอบก่อนหน้า
  void _startGame() {
    // ป้องกันการเริ่มเกมก่อนพื้นที่เล่นถูกวัดขนาด
    if (_arenaSize.width <= 0 || _arenaSize.height <= 0) return;
    // ยกเลิก Timer เก่าก่อนเริ่มรอบใหม่เพื่อไม่ให้ทำงานซ้อนกัน
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    // เปลี่ยนสถานะและล้างสถิติของรอบก่อนหน้า
    setState(() {
      _state = AimState.playing;
      _hits = 0;
      _misses = 0;
      _lives = 3;
      _elapsed = Duration.zero;
      _totalTimeMs = 0;
      _startedAt = DateTime.now();
    });
    // สร้างเป้าแรกทันทีหลังเริ่มเกม
    _spawnTarget();
    // ตรวจเวลารวมของเกมเป็นระยะและจบรอบเมื่อครบ 30 วินาที
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      // ถ้าหน้าถูกปิดหรือไม่มีเวลาเริ่มเกมแล้ว ให้หยุดการประมวลผลรอบนี้
      if (!mounted || _startedAt == null) return;
      // คำนวณเวลาที่ผ่านไปจากเวลาจริงของเครื่อง
      final elapsed = DateTime.now().difference(_startedAt!);
      // เมื่อครบเวลา ให้ปิดเกมและบันทึกผล
      if (elapsed >= _gameDuration) {
        _finishGame();
      } else {
        // อัปเดตตัวจับเวลาบนหน้าจอระหว่างเล่น
        setState(() => _elapsed = elapsed);
      }
    });
  }

  // สุ่มเป้าหมายใหม่ภายในขอบเขตของพื้นที่เล่น
  void _spawnTarget() {
    // ไม่สร้างเป้าถ้าพื้นที่เล็กเกินไปหรือเกมไม่ได้อยู่ในสถานะเล่น
    if (_arenaSize.width <= _targetRadius * 2 ||
        _arenaSize.height <= _targetRadius * 2 ||
        _state != AimState.playing) {
      return;
    }
    // ยกเลิกเวลาของเป้าเก่าก่อนสร้างเป้าใหม่
    _targetTimer?.cancel();
    // สุ่มขนาดและตำแหน่ง โดยบังคับให้เป้าไม่ล้นขอบสนาม
    setState(() {
      _targetRadius = (26 + _random.nextInt(23)).toDouble();
      final maxX = _arenaSize.width - _targetRadius * 2;
      final maxY = _arenaSize.height - _targetRadius * 2;
      _targetPosition = Offset(
        _random.nextDouble() * maxX,
        _random.nextDouble() * maxY,
      );
    });
    // ถ้าไม่ยิงภายในเวลาที่กำหนด จะเรียก _targetExpired
    _targetTimer = Timer(_targetLifespan, _targetExpired);
  }

  // จัดการกรณีผู้เล่นปล่อยให้เป้าหมดอายุ
  void _targetExpired() {
    // เป้าหมดอายุไม่มีผลถ้าเกมจบไปแล้ว
    if (_state != AimState.playing) return;
    // นับเป็นการพลาดและลดจำนวนชีวิต
    _misses++;
    _lives--;
    // ถ้าชีวิตหมด ให้จบเกม มิฉะนั้นสร้างเป้าใหม่
    if (_lives <= 0) {
      _finishGame();
    } else {
      _spawnTarget();
    }
  }

  // รับตำแหน่งการแตะในสนามและตรวจว่าโดนเป้าหรือไม่
  void _handleArenaTap(TapDownDetails details) {
    // การแตะสนามครั้งแรกในสถานะ idle จะเริ่มเกม
    if (_state == AimState.idle) {
      _startGame();
      return;
    }
    // ไม่รับการแตะเมื่อเกมไม่ได้กำลังเล่น
    if (_state != AimState.playing) return;

    // แปลงตำแหน่งเป้าจากมุมซ้ายบนเป็นจุดศูนย์กลาง
    final center = Offset(
      _targetPosition.dx + _targetRadius,
      _targetPosition.dy + _targetRadius,
    );
    // วัดระยะจากจุดแตะถึงศูนย์กลางเพื่อใช้ตัดสินว่าโดนเป้าหรือไม่
    final distance = (details.localPosition - center).distance;
    // แตะภายในรัศมีเป้าถือว่ายิงถูกและสร้างเป้าใหม่
    if (distance <= _targetRadius) {
      _hits++;
      _spawnTarget();
    } else {
      // แตะนอกเป้าถือว่ายิงพลาดและเสียชีวิตหนึ่งครั้ง
      _misses++;
      _lives--;
      if (_lives <= 0) {
        // ถ้าชีวิตหมด ให้จบเกมทันที
        _finishGame();
      } else {
        // อัปเดตจำนวนชีวิตบนหน้าจอโดยยังเล่นต่อ
        setState(() {});
      }
    }
  }

  // จบเกม ยกเลิก Timer เปลี่ยนเป็นหน้าผลลัพธ์ และบันทึกคะแนน
  Future<void> _finishGame() async {
    // ป้องกันการจบเกมซ้ำจาก Timer หลายตัว
    if (_state != AimState.playing) return;
    // หยุด Timer ทั้งเวลารวมและอายุเป้า
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    // คำนวณเวลาจริงและจำกัดไม่ให้เกินเวลาที่กำหนด
    final elapsed = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    _totalTimeMs = min(elapsed.inMilliseconds, _gameDuration.inMilliseconds);
    // เปลี่ยนหน้าจอเป็นผลลัพธ์พร้อมค่าที่คำนวณเสร็จแล้ว
    setState(() {
      _elapsed = Duration(milliseconds: _totalTimeMs);
      _state = AimState.result;
    });
    // ส่งคะแนนไปยัง PlayerProfileStore เพื่อเก็บในระบบข้อมูลผู้เล่น
    await PlayerProfileStore.saveAimScore(
      name: widget.playerName,
      speed: _speed,
      hits: _hits,
      totalTime: _totalTimeMs,
      accuracy: _accuracy,
    );
  }

  // รีเซ็ตเกมกลับสู่หน้าพร้อมเริ่ม โดยล้าง Timer และสถิติทั้งหมด
  void _reset() {
    // ยกเลิก Timer ที่อาจยังเหลือจากรอบก่อน
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

  // แปลง Duration เป็นรูปแบบวินาที.มิลลิวินาทีสำหรับแสดงบนแถบสถิติ
  String _formatTime(Duration duration) {
    return '${duration.inSeconds.toString().padLeft(2, '0')}.'
        '${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}';
  }

  // ปล่อยทรัพยากร Timer เมื่อ Widget ถูกนำออกจากหน้าจอ
  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    super.dispose();
  }

  // สร้างโครงหน้าจอหลักและเลือกหน้าผลลัพธ์หรือหน้าเล่นตามสถานะ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ชื่อเกมที่แสดงด้านบนของหน้าจอ
        title: const Text('Aim Trainer'),
        backgroundColor: Colors.transparent,
        actions: [
          // ปุ่มเปิดหน้าตารางคะแนนของผู้เล่นปัจจุบัน
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
      // ครอบเนื้อหาด้วยพื้นหลังเคลื่อนไหวจาก animated_backdrop.dart
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

  // สร้างหน้าเล่นเกม ประกอบด้วยแถบสถิติ สนาม และปุ่มเริ่มเกม
  Widget _gameView() => Column(
    children: [
      // แสดงเวลา จำนวนครั้งที่ยิงถูก ความเร็ว และชีวิต
      _statsBar(),
      const SizedBox(height: 14),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // เก็บขนาดสนามจริงเพื่อใช้จำกัดตำแหน่งเป้า
            _arenaSize = Size(constraints.maxWidth, constraints.maxHeight);
            // ใช้สถานะนี้ตัดสินว่าจะวาดเป้าหรือข้อความเริ่มเกม
            final isPlaying = _state == AimState.playing;
            return GestureDetector(
              // ส่งการแตะเข้าสู่ตรรกะตรวจเป้าและเริ่มเกม
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
                    // แสดงคำแนะนำเมื่อยังไม่ได้เริ่มเกม
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
                      // วางเป้า ณ ตำแหน่งสุ่มที่ _spawnTarget กำหนด
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
        // ปุ่มเริ่มเกมเรียกใช้ตรรกะเดียวกับการแตะสนามครั้งแรก
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
        // ข้อความช่วยระหว่างเล่นหรือก่อนแสดงผลลัพธ์
        Text(
          'แตะเป้าให้ทันก่อนหมดเวลา',
          style: TextStyle(color: Colors.white.withValues(alpha: .6)),
        ),
    ],
  );
  // สร้างแถบข้อมูลสถานะเกมด้านบนสนาม

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

  // สร้างช่องสถิติหนึ่งช่อง พร้อมไอคอน ค่า และชื่อข้อมูล
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

  // สร้างหน้าสรุปคะแนนหลังเกมจบ
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
      // ปุ่มเริ่มรอบใหม่ โดยกลับไปยังสถานะ idle
      FilledButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('ทำซ้ำอีกรอบ'),
      ),
      const SizedBox(height: 12),
      // ปุ่มกลับไปหน้าเลือกโหมดโดยใช้ชื่อผู้เล่นเดิม
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModeSelectionScreen(playerName: widget.playerName),
          ),
        ),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('เปลี่ยนโหมดการเล่น'),
      ),
      const SizedBox(height: 12),
      // ปุ่มล้างเส้นทางเดิมและกลับไปเริ่มต้นที่หน้า Login
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

  // แถวแสดงชื่อสถิติและค่าผลลัพธ์ในหน้าสรุป
  Widget _resultRow(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(
      value,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    ),
  );
}
