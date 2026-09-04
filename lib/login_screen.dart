import 'package:flutter/material.dart';

import 'animated_backdrop.dart';
import 'country_report_screen.dart';
import 'country_tracker.dart';
import 'data_player.dart';
import 'mode_selection_screen.dart';
import 'reflex_data.dart';
import 'scoreboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  Future<void> _start() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหรือ ID ก่อนเริ่มทดสอบ')),
      );
      return;
    }
    setState(() => _loading = true);
    final registeredPlayers = await PlayerProfileStore.loadPlayers();
    final reflexEntries = await ScoreboardStore.load();
    final aimEntries = await AimScoreboardStore.load();
    final duplicate = [
      ...registeredPlayers,
      ...reflexEntries.map((entry) => entry.id),
      ...aimEntries.map((entry) => entry.id),
    ].any((player) => player.toLowerCase() == name.toLowerCase());
    if (!mounted) return;
    setState(() => _loading = false);
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ชื่อนี้ถูกใช้งานแล้ว กรุณาใช้ชื่อหรือ ID อื่น'),
        ),
      );
      return;
    }
    await PlayerProfileStore.savePlayer(name);
    await CountryTracker.saveLogin(name);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModeSelectionScreen(playerName: name)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBackdrop(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
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
                    'เตรียมนิ้วให้พร้อม กดทันทีที่หน้าจอเปลี่ยนเป็นสีเขียว',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _start(),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อหรือ ID ผู้เล่น',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _start,
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
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
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
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
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
                  const Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: Colors.white),
                      Text('3 รอบ • ใช้ค่ามัธยฐานเป็นคะแนนสุดท้าย'),
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
