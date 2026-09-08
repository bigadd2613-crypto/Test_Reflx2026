// หน้าเลือกโหมดการทดสอบหลังจากผู้เล่นเข้าสู่ระบบ
// ปุ่มหลัก: เลือก Time Reflex Test/Aim Trainer, เข้าสู่โหมดที่เลือก,
// ดู Scoreboard และเปลี่ยนผู้เล่น

import 'package:flutter/material.dart';

import 'animated_backdrop.dart';
import 'aim_trainer_screen.dart';
import 'home_screen.dart';
import 'reflex_data.dart';
import 'scoreboard_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  final String playerName;

  const ModeSelectionScreen({super.key, required this.playerName});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  SelectedMode? selectedMode;

  void _openSelectedMode() {
    final mode = selectedMode;
    if (mode == null) return;
    final page = mode == SelectedMode.timeReflex
        ? ReflexTestScreen(playerName: widget.playerName)
        : AimTrainerScreen(playerName: widget.playerName);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกโหมดการทดสอบ'),
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
                icon: Icons.touch_app_rounded,
                color: Colors.white,
                title: 'Time Reflex Test',
                description: 'กดให้ไวทันทีที่หน้าจอเปลี่ยนเป็นสีเขียว',
                selected: selectedMode == SelectedMode.timeReflex,
                onPressed: () =>
                    setState(() => selectedMode = SelectedMode.timeReflex),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.ads_click_rounded,
                color: Colors.white,
                title: 'Aim Trainer',
                description: 'ยิงเป้าให้แม่นและเร็วที่สุดภายในเวลาที่กำหนด',
                selected: selectedMode == SelectedMode.aimTrainer,
                onPressed: () =>
                    setState(() => selectedMode = SelectedMode.aimTrainer),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: selectedMode == null ? null : _openSelectedMode,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('เข้าสู่โหมดที่เลือก'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onPressed;

  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? const Color(0xFF303030) : const Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected ? color : Colors.transparent,
        width: 1.5,
      ),
    ),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(width: 18),
            Expanded(
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
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
