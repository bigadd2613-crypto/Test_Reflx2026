// หน้าแรกสำหรับกรอกชื่อหรือ ID เพื่อเริ่มใช้งานแอป
// ปุ่มหลัก: เริ่มทดสอบ, ดู Scoreboard ทั้งหมด และดูสถิติประเทศ

// ใช้สร้างหน้าจอ ฟอร์ม ปุ่ม ข้อความ และการนำทางของ Flutter
import 'package:flutter/material.dart';

// ใช้พื้นหลังเคลื่อนไหวของหน้า Login
import 'animated_backdrop.dart';
// ใช้เปิดหน้ารายงานสถิติประเทศ
import 'country_report_screen.dart';
// ใช้บันทึกข้อมูลการเข้าใช้งานและตำแหน่งประเทศ
import 'country_tracker.dart';
// ใช้ตรวจและบันทึกโปรไฟล์ผู้เล่น
import 'data_player.dart';
// ใช้เปิดหน้าเลือกโหมดเกมหลัง Login สำเร็จ
import 'mode_selection_screen.dart';
// ใช้โหลดคะแนน Time Reflex Test เพื่อตรวจชื่อซ้ำ
import 'reflex_data.dart';
// ใช้เปิดหน้าตารางคะแนนและตรวจคะแนน Aim Trainer
import 'scoreboard_screen.dart';

// หน้าจอเริ่มต้นสำหรับกรอกชื่อหรือ ID ผู้เล่น
class LoginScreen extends StatefulWidget {
  // สร้างหน้า Login โดยไม่ต้องรับข้อมูลจากหน้าก่อนหน้า
  const LoginScreen({super.key});

  // สร้าง State เพื่อจัดการข้อความในช่องกรอกและสถานะการโหลด
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ควบคุมข้อความชื่อผู้เล่นที่กรอกใน TextField
  final _nameController = TextEditingController();
  // ใช้ปิดปุ่มและแสดงวงโหลดระหว่างตรวจสอบข้อมูล
  bool _loading = false;

  // ตรวจสอบชื่อผู้เล่น บันทึกข้อมูล และเปิดหน้าเลือกโหมดการทดสอบ
  Future<void> _start() async {
    // ตัดช่องว่างหัวท้ายของชื่อก่อนนำไปตรวจสอบและบันทึก
    final name = _nameController.text.trim();
    // ป้องกันไม่ให้เริ่มระบบโดยไม่กรอกชื่อหรือ ID
    if (name.isEmpty) {
      // แจ้งเตือนผู้ใช้ผ่าน SnackBar ที่ด้านล่างหน้าจอ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหรือ ID ก่อนเริ่มทดสอบ')),
      );
      return;
    }
    // เปลี่ยนปุ่มเป็นสถานะกำลังโหลดระหว่างอ่านข้อมูลจากระบบ
    setState(() => _loading = true);
    // โหลดชื่อผู้เล่นที่บันทึกไว้ใน PlayerProfileStore
    final registeredPlayers = await PlayerProfileStore.loadPlayers();
    // โหลดคะแนน Time Reflex Test ที่มีอยู่แล้ว
    final reflexEntries = await ScoreboardStore.load();
    // โหลดคะแนน Aim Trainer ที่มีอยู่แล้ว
    final aimEntries = await AimScoreboardStore.load();
    // รวมชื่อจากทุกแหล่งข้อมูลเพื่อป้องกันชื่อซ้ำทั้งระบบ
    final duplicate = [
      ...registeredPlayers,
      ...reflexEntries.map((entry) => entry.id),
      ...aimEntries.map((entry) => entry.id),
    ].any((player) => player.toLowerCase() == name.toLowerCase());
    // ตรวจว่าหน้ายังอยู่ก่อนเรียก setState หลังการทำงานแบบ async
    if (!mounted) return;
    // ปิดสถานะโหลดก่อนแสดงผลการตรวจสอบ
    setState(() => _loading = false);
    // ถ้าชื่อซ้ำ ให้แจ้งเตือนและหยุดการ Login
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ชื่อนี้ถูกใช้งานแล้ว กรุณาใช้ชื่อหรือ ID อื่น'),
        ),
      );
      return;
    }
    // สร้างหรือบันทึกโปรไฟล์ผู้เล่นใน PlayerProfileStore
    await PlayerProfileStore.savePlayer(name);
    // บันทึกประวัติ Login และประเทศผ่าน CountryTracker
    await CountryTracker.saveLogin(name);
    // ป้องกันการนำทางถ้าหน้าถูกปิดระหว่างรอบันทึกข้อมูล
    if (!mounted) return;
    // เปิดหน้าเลือกโหมดเกมและส่งชื่อผู้เล่นไปให้หน้าถัดไป
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModeSelectionScreen(playerName: name)),
    );
  }

  // คืนทรัพยากรของ TextEditingController เมื่อออกจากหน้า Login
  @override
  void dispose() {
    // คืนทรัพยากรของช่องกรอกชื่อเมื่อออกจากหน้านี้
    _nameController.dispose();
    super.dispose();
  }

  // สร้างหน้าแรกสำหรับกรอกชื่อและเลือกดูข้อมูลต่าง ๆ
  @override
  Widget build(BuildContext context) => Scaffold(
    // วางพื้นหลังเคลื่อนไหวไว้ด้านหลังเนื้อหาทั้งหมดของหน้า Login
    body: AnimatedBackdrop(
      child: SafeArea(
        // กันเนื้อหาไม่ให้ชนขอบจอหรือพื้นที่ของระบบ
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // จำกัดความกว้างของฟอร์มให้เหมาะกับจอขนาดใหญ่
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 52),
                  const SizedBox(height: 20),
                  const Text(
                    'TIME TEST',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'วัดความไวของปฏิกิริยา',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'วัดReflxของคุณว่าวัยรุ่นหรือวัยชรา',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    // เชื่อมช่องกรอกกับ controller เพื่ออ่านชื่อใน _start
                    controller: _nameController,
                    // เปิดแป้นพิมพ์ให้กรอกชื่อทันทีเมื่อเข้าหน้า
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    // กดปุ่ม Done บนแป้นพิมพ์เพื่อเรียกขั้นตอนเริ่มระบบ
                    onSubmitted: (_) => _start(),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อหรือ ID ผู้เล่น',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // ปุ่มเริ่มทดสอบ: ตรวจสอบชื่อและไปหน้าเลือกโหมด
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      // ปิดปุ่มขณะกำลังโหลด และเรียกตรวจสอบชื่อเมื่อกด
                      onPressed: _loading ? null : _start,
                      // แสดงวงโหลดระหว่างตรวจข้อมูล หรือไอคอนเริ่มเมื่อพร้อม
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'เริ่มทดสอบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ปุ่มดู Scoreboard: เปิดหน้าคะแนนรวมของผู้เล่นทั้งหมด
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      // เปิด Scoreboard โดยไม่มีผู้เล่นปัจจุบันให้ไฮไลต์
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScoreboardScreen(currentId: ''),
                        ),
                      ),
                      icon: const Icon(Icons.leaderboard_outlined),
                      label: const Text('ดู Scoreboard ทั้งหมด'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ปุ่มดูสถิติประเทศ: เปิดรายงานผู้เล่นในประเทศและต่างประเทศ
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      // เปิดรายงานจำนวนผู้เล่นและประเทศที่เข้าใช้งาน
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CountryReportScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('ดูสถิติประเทศ'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // คำอธิบายกติกาของแต่ละโหมด พร้อมไอคอนแยกกัน
                  const Column(
                    // แสดงกติกาโดยย่อของทั้งสองโหมดให้ผู้เล่นเลือกก่อนเริ่ม
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Time Reflex Test: กด 3 รอบ • ใช้ค่าคะแนนตรงกลางที่สุดเป็นผลลัพธ์',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.ads_click_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aim Trainer: ยิงเป้าเป็นเวลา 30 วินาที • ใช้ค่าคะแนนสูงสุดเป็นผลลัพธ์',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
