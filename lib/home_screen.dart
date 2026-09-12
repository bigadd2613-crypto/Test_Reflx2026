// หน้าจอเกม Time Reflex Test สำหรับวัดเวลาตอบสนองของผู้เล่น
// ปุ่มหลัก: เริ่มเกม, ทำซ้ำอีกรอบ, ไปหน้า Scoreboard และกลับหน้า Login

// ใช้ Timer สำหรับหน่วงเวลาก่อนเปลี่ยนสถานะให้กด
import 'dart:async';
// ใช้สุ่มเวลารอและหาค่าต่ำสุดของจำนวนรอบ
import 'dart:math';

// ใช้สร้างหน้าจอและวิดเจ็ตของเกม Flutter
import 'package:flutter/material.dart';

// ใช้พื้นหลังเคลื่อนไหวร่วมกับหน้าจอเกมอื่น
import 'animated_backdrop.dart';
// ใช้บันทึกคะแนนของผู้เล่นหลังจบเกม
import 'data_player.dart';
// ใช้นำทางกลับไปยังหน้าล็อกอิน
import 'login_screen.dart';
// ใช้กลับไปยังหน้าเลือกโหมดการเล่น
import 'mode_selection_screen.dart';
// ใช้เปิดหน้าตารางคะแนน
import 'scoreboard_screen.dart';

// สถานะของเกม: พร้อมเริ่ม รอไฟเขียว ให้กด หรือแสดงผลลัพธ์
enum ReflexState { idle, waiting, action, result }

// หน้าจอเกม Time Reflex Test ที่รับชื่อผู้เล่นจากหน้า Login
class ReflexTestScreen extends StatefulWidget {
  // ชื่อผู้เล่นที่ใช้แสดงและบันทึกคะแนน
  final String playerName;

  // สร้างหน้าจอโดยบังคับให้มีชื่อผู้เล่น
  const ReflexTestScreen({super.key, required this.playerName});

  // สร้าง State เพื่อควบคุมสถานะและเวลาของเกม
  @override
  State<ReflexTestScreen> createState() => _ReflexTestScreenState();
}

class _ReflexTestScreenState extends State<ReflexTestScreen> {
  // จำนวนรอบที่ต้องเล่นก่อนสรุปผล
  static const _totalRounds = 3;

  // สถานะปัจจุบันของเกม ใช้กำหนดสี ข้อความ และการรับการแตะ
  ReflexState _state = ReflexState.idle;
  // รายการเวลาตอบสนองของแต่ละรอบ หน่วยมิลลิวินาที
  final List<int> _times = [];
  // Timer สำหรับรอเวลาสุ่มก่อนให้ผู้เล่นกด
  Timer? _timer;
  // เวลาเริ่มสถานะ action เพื่อคำนวณเวลาตอบสนอง
  DateTime? _startTime;
  // ข้อความแนะนำสถานะปัจจุบันของเกม
  String _notice = '';

  // คำนวณหมายเลขรอบปัจจุบันและไม่ให้เกินจำนวนรอบทั้งหมด
  int get _round => min(_times.length + 1, _totalRounds);

  // เริ่มรอบใหม่และสุ่มเวลารอก่อนเปลี่ยนเป็นสีเขียว
  void _beginRound() {
    // ยกเลิก Timer เดิมเพื่อไม่ให้รอบเก่าทำงานซ้อนกัน
    _timer?.cancel();
    // เปลี่ยนสถานะเป็นกำลังรอและเตือนผู้เล่นว่ายังห้ามกด
    setState(() {
      _state = ReflexState.waiting;
      _notice = 'อย่าเพิ่งกด';
    });
    // สุ่มเวลารอระหว่าง 1 ถึง 5 วินาที
    final delay = 1000 + Random().nextInt(4001);
    // เมื่อครบเวลารอ ให้เปลี่ยนเป็นสถานะ action และเริ่มจับเวลา
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _state = ReflexState.action;
        _startTime = DateTime.now();
        _notice = 'กดเลย!';
      });
    });
  }

  // รับการแตะสนามและตรวจว่าแตะเร็วเกินไปหรือแตะหลังไฟเขียว
  Future<void> _tapTarget() async {
    // หากกดระหว่างรอ ให้ยกเลิกรอบนี้และแจ้งว่ากดเร็วเกินไป
    if (_state == ReflexState.waiting) {
      _timer?.cancel();
      setState(() {
        _state = ReflexState.idle;
        _notice = 'กดเร็วเกินไป! ลองรอบนี้ใหม่';
      });
      return;
    }
    // รับเฉพาะการแตะในสถานะ action ที่มีเวลาเริ่มต้นแล้ว
    if (_state != ReflexState.action || _startTime == null) return;
    // คำนวณเวลาตั้งแต่ไฟเขียวจนถึงเวลาที่ผู้เล่นแตะ
    final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
    // เก็บเวลารอบนี้และเปลี่ยนสถานะเป็นผลลัพธ์หรือรอบถัดไป
    setState(() {
      _times.add(elapsed);
      _state = _times.length == _totalRounds
          ? ReflexState.result
          : ReflexState.idle;
      _notice = _times.length == _totalRounds
          ? 'ครบ $_totalRounds รอบแล้ว'
          : 'รอบต่อไปพร้อมเมื่อไหร่กดปุ่มได้เลย';
    });
    // เมื่อครบ 3 รอบ ให้เรียงเวลาและบันทึกค่ามัธยฐานเป็นคะแนนผู้เล่น
    if (_times.length == _totalRounds) {
      final sorted = [..._times]..sort();
      await PlayerProfileStore.saveReflexScore(
        name: widget.playerName,
        score: sorted[1],
      );
    }
  }

  // ล้างเวลาทั้งหมดและกลับไปยังสถานะพร้อมเริ่มเกมใหม่
  void _reset() {
    // ยกเลิก Timer ที่อาจเหลือจากรอบก่อน
    _timer?.cancel();
    setState(() {
      _times.clear();
      _state = ReflexState.idle;
      _notice = '';
    });
  }

  // คืนทรัพยากร Timer เมื่อออกจากหน้าจอเกม
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // สร้างหน้าจอเกมและเลือกแสดงสนามหรือผลลัพธ์ตามสถานะ
  @override
  Widget build(BuildContext context) {
    // ตรวจสถานะเพื่อเลือกสีและข้อความของสนามเกม
    final isWaiting = _state == ReflexState.waiting;
    final isAction = _state == ReflexState.action;
    // เรียงเวลาสำหรับคำนวณและแสดงค่ามัธยฐาน
    final sorted = [..._times]..sort();
    final median = sorted.length == _totalRounds ? sorted[1] : null;

    return Scaffold(
      appBar: AppBar(
        // แสดงหมายเลขรอบปัจจุบันด้านบนหน้าจอ
        title: Text('รอบ $_round / $_totalRounds'),
        backgroundColor: Colors.transparent,
        actions: [
          // เปิดหน้า Scoreboard พร้อมส่งชื่อผู้เล่นเพื่อไฮไลต์ข้อมูล
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
      // ใช้พื้นหลังเคลื่อนไหวจาก animated_backdrop.dart
      body: AnimatedBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: _state == ReflexState.result
                // เมื่อเล่นครบ แสดงผลลัพธ์และค่ามัธยฐาน
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
                        // สนามหลักรับการแตะเพื่อเริ่มจับเวลาหรือบันทึกผล
                        child: GestureDetector(
                          onTap: _tapTarget,
                          child: AnimatedContainer(
                            // ทำให้สีสนามเปลี่ยนอย่างนุ่มนวลตามสถานะเกม
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
                                    // แสดงไอคอนตามว่ากำลังรอหรือกดได้
                                    isAction
                                        ? Icons.touch_app_rounded
                                        : Icons.pan_tool_outlined,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    // แสดงคำสั่งให้ผู้เล่นตามสถานะปัจจุบัน
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
                          // เริ่มรอบเมื่อเกมอยู่ในสถานะ idle เท่านั้น
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

  // เลือกข้อความแสดงความคิดเห็นจากค่ามัธยฐานของผู้เล่น
  String _scoreComment(int median) {
    // คะแนนต่ำกว่า 200 ms แสดงว่าตอบสนองได้เร็วมาก
    if (median < 200) return 'โปรละเห้ยมันตันแค่201 พี่ชาย)';
    // ตรวจค่าระหว่าง 200 ถึง 300 ms แล้วแสดงข้อความตามเกณฑ์
    if (median >= 200 && median <= 300) return 'Reflxของนายมันก็เออเจ๋งละกัน';
    // ตรวจค่ามากกว่า 300 ถึง 400 ms แล้วแสดงข้อความตามเกณฑ์
    if (median > 300 && median <= 400) return 'Reflxของนายมันยังธรรมดามากเลยละ';
    // คะแนนตั้งแต่ 401 ms ขึ้นไป แนะนำให้ฝึกเพิ่มเติม
    return 'Reflxพี่ชายมันกาจอก กาจอกจัง';
  }

  // สร้างหน้าสรุปผลหลังผู้เล่นเล่นครบทุกกระดาน
  Widget _resultView(List<int> sorted, int median) {
    // คำนวณข้อความที่จะแสดงถัดจากค่ามัธยฐาน
    final comment = _scoreComment(median);

    return ListView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
              if (comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF55D68A),
                  ),
                ),
              ],
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
          // ล้างข้อมูลเดิมและเริ่มเกมใหม่
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ทำซ้ำอีกรอบ'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          // กลับไปหน้าเลือกโหมดโดยใช้ชื่อผู้เล่นเดิม
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ModeSelectionScreen(playerName: widget.playerName),
            ),
          ),
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('เปลี่ยนโหมดการเล่น'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          // ล้างเส้นทางหน้าปัจจุบันแล้วกลับไปหน้า Login
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
}
