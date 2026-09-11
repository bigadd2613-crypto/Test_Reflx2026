// หน้าเลือกโหมดการทดสอบหลังจากผู้เล่นเข้าสู่ระบบ
// ปุ่มหลัก: เลือก Time Reflex Test/Aim Trainer, เข้าสู่โหมดที่เลือก,
// ดู Scoreboard และเปลี่ยนผู้เล่น

// ใช้สร้างหน้าจอ การ์ด ปุ่ม และการนำทางของ Flutter
import 'package:flutter/material.dart';

// ใช้พื้นหลังเคลื่อนไหวร่วมกับหน้าจอเกมอื่น
import 'animated_backdrop.dart';
// ใช้เปิดเกม Aim Trainer เมื่อผู้เล่นเลือกโหมดนี้
import 'aim_trainer_screen.dart';
// ใช้เปิดเกม Time Reflex Test เมื่อผู้เล่นเลือกโหมดนี้
import 'home_screen.dart';
// ใช้ชนิดข้อมูล SelectedMode สำหรับเก็บโหมดที่เลือก
import 'reflex_data.dart';
// ใช้เปิดหน้าตารางคะแนนของผู้เล่น
import 'scoreboard_screen.dart';

// หน้าสำหรับเลือกโหมดเกมหลังจากผู้เล่นผ่านหน้า Login
class ModeSelectionScreen extends StatefulWidget {
  // ชื่อผู้เล่นที่ส่งต่อมาจาก LoginScreen และส่งต่อไปยังเกม
  final String playerName;

  // สร้างหน้าเลือกโหมดโดยบังคับให้มีชื่อผู้เล่น
  const ModeSelectionScreen({super.key, required this.playerName});

  // สร้าง State เพื่อจำโหมดที่ผู้เล่นเลือก
  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  // เก็บโหมดปัจจุบันที่ผู้เล่นเลือกจากการ์ดทั้งสองใบ
  SelectedMode? selectedMode;

  // เปิดหน้าจอเกมตามโหมดที่ผู้เล่นเลือก
  void _openSelectedMode() {
    // อ่านโหมดที่เลือกไว้ก่อนสร้างหน้าจอถัดไป
    final mode = selectedMode;
    // หากยังไม่ได้เลือกโหมด จะไม่อนุญาตให้นำทางต่อ
    if (mode == null) return;
    // สร้างหน้าจอเกมที่ตรงกับโหมด และส่งชื่อผู้เล่นไปให้เกม
    final page = mode == SelectedMode.timeReflex
        ? ReflexTestScreen(playerName: widget.playerName)
        : AimTrainerScreen(playerName: widget.playerName);
    // เพิ่มหน้าจอเกมที่เลือกเข้า Navigator stack
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // สร้างโครงหน้าจอเลือกโหมดและปุ่มนำทางต่าง ๆ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // แสดงชื่อหน้าที่ผู้เล่นกำลังเลือกโหมด
        title: const Text('เลือกโหมดการทดสอบ'),
        backgroundColor: Colors.transparent,
        actions: [
          // เปิด Scoreboard และส่งชื่อผู้เล่นปัจจุบันไปไฮไลต์ข้อมูล
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
      // ครอบเนื้อหาด้วยพื้นหลังเคลื่อนไหวจาก AnimatedBackdrop
      body: AnimatedBackdrop(
        child: SafeArea(
          // ป้องกันเนื้อหาไม่ให้ชนขอบจอหรือพื้นที่ของระบบ
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'สวัสดี ${widget.playerName}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'เลือกสนามที่อยากทดสอบวันนี้',
                style: TextStyle(color: Colors.white.withValues(alpha: .65)),
              ),
              const SizedBox(height: 28),
              _ModeCard(
                // การ์ดสำหรับเลือกเกม Time Reflex Test
                icon: Icons.touch_app_rounded,
                color: Colors.white,
                title: 'Time Reflex Test',
                description: 'กดให้ไวทันทีที่หน้าจอเปลี่ยนเป็นสีเขียว',
                selected: selectedMode == SelectedMode.timeReflex,
                // เปลี่ยน selectedMode เมื่อผู้เล่นแตะการ์ดนี้
                onPressed: () =>
                    setState(() => selectedMode = SelectedMode.timeReflex),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                // การ์ดสำหรับเลือกเกม Aim Trainer
                icon: Icons.ads_click_rounded,
                color: Colors.white,
                title: 'Aim Trainer',
                description: 'ยิงเป้าให้แม่นและเร็วที่สุดภายในเวลาที่กำหนด',
                selected: selectedMode == SelectedMode.aimTrainer,
                // เปลี่ยน selectedMode เมื่อผู้เล่นแตะการ์ดนี้
                onPressed: () =>
                    setState(() => selectedMode = SelectedMode.aimTrainer),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  // เปิดเกมที่เลือก และปิดปุ่มไว้จนกว่าจะเลือกโหมด
                  onPressed: selectedMode == null ? null : _openSelectedMode,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('เข้าสู่โหมดที่เลือก'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                // ย้อนกลับไปหน้า Login เพื่อเปลี่ยนผู้เล่น
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('เปลี่ยนผู้เล่น'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  // ไอคอนที่สื่อความหมายของโหมดเกม
  final IconData icon;
  // สีของไอคอนและกรอบเมื่อการ์ดถูกเลือก
  final Color color;
  // ชื่อโหมดที่แสดงบนการ์ด
  final String title;
  // คำอธิบายกติกาของโหมด
  final String description;
  // ระบุว่าการ์ดนี้เป็นโหมดที่กำลังเลือกอยู่หรือไม่
  final bool selected;
  // ฟังก์ชันที่เรียกเมื่อผู้เล่นแตะการ์ด
  final VoidCallback onPressed;

  // รับข้อมูลที่จำเป็นสำหรับสร้างการ์ดโหมดแต่ละใบ
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.selected,
    required this.onPressed,
  });

  // สร้างหน้าตาของการ์ดและส่งเหตุการณ์แตะกลับไปยังหน้าหลัก
  @override
  Widget build(BuildContext context) => Card(
    // เปลี่ยนสีพื้นหลังเพื่อแสดงสถานะที่ผู้เล่นเลือก
    color: selected ? const Color(0xFF303030) : const Color(0xFF1A1A1A),
    // แสดงกรอบสีเมื่อการ์ดถูกเลือก
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected ? color : Colors.transparent,
        width: 1.5,
      ),
    ),
    // ทำให้ทั้งการ์ดสามารถรับการแตะและแสดงเอฟเฟกต์กด
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // แสดงไอคอนของโหมดเกม
            Icon(icon, size: 42, color: color),
            const SizedBox(width: 18),
            Expanded(
              // จัดวางชื่อโหมดและคำอธิบายให้ใช้พื้นที่ที่เหลือ
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                ],
              ),
            ),
            // แสดงลูกศรเพื่อบอกว่าการ์ดสามารถเลือกได้
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
