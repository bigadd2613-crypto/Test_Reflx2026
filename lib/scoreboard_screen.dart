// หน้าแสดงคะแนนรวมของผู้เล่น แยกเป็น Time Reflex และ Aim Trainer
// ปุ่มหลัก: กลับไปหน้าก่อนหน้า และแท็บเลือกประเภทคะแนน

import 'package:flutter/material.dart';

import 'animated_backdrop.dart';
import 'data_player.dart';

class ScoreboardScreen extends StatefulWidget {
  final String currentId;

  const ScoreboardScreen({super.key, required this.currentId});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late Future<List<PlayerData>> _players;

  @override
  void initState() {
    super.initState();
    _players = PlayerProfileStore.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF101419),
        body: AnimatedBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF131A22),
                      Color(0xFF0D1117),
                      Color(0xFF101419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .22),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'กลับ',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'View all Scoreboards',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            tabBarTheme: const TabBarThemeData(
                              labelColor: Colors.white,
                              unselectedLabelColor: Color(0xFF9AA7B2),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9AA7B2),
                              ),
                            ),
                          ),
                          child: const TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: Color(0xFF2B3440),
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                            ),
                            labelPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tabs: [
                              Tab(text: 'Time Reflex'),
                              Tab(text: 'Aim Trainer'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<PlayerData>>(
                          future: _players,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return TabBarView(
                              children: [
                                _reflexBoard(snapshot.data!),
                                _aimBoard(snapshot.data!),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reflexBoard(List<PlayerData> players) {
    final entries =
        players.where((player) => player.reflexScore != null).toList()
          ..sort((a, b) => a.reflexScore!.compareTo(b.reflexScore!));

    if (entries.isEmpty) {
      return _playersWithoutScore(players, 'ยังไม่มีคะแนน Time Reflex');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _entryTile(
          index: index,
          name: entry.name,
          score: '${entry.reflexScore} ms',
          isCurrent: _isCurrent(entry.name),
        );
      },
    );
  }

  Widget _aimBoard(List<PlayerData> players) {
    final entries = players.where((player) => player.aimSpeed != null).toList()
      ..sort((a, b) => b.aimSpeed!.compareTo(a.aimSpeed!));

    if (entries.isEmpty) {
      return _playersWithoutScore(players, 'ยังไม่มีคะแนน Aim Trainer');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _entryTile(
          index: index,
          name: entry.name,
          score: '${entry.aimSpeed!.toStringAsFixed(2)} targets/s',
          detail:
              '${entry.aimAccuracy!.toStringAsFixed(1)}% accuracy • ${entry.aimHits} hits',
          isCurrent: _isCurrent(entry.name),
        );
      },
    );
  }

  bool _isCurrent(String id) =>
      id.toLowerCase() == widget.currentId.toLowerCase();

  Widget _playersWithoutScore(List<PlayerData> players, String message) =>
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (players.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'ผู้ใช้ที่บันทึกไว้',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...players.map(
              (player) => ListTile(
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white70,
                ),
                title: Text(
                  player.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'ยังไม่มีคะแนนในโหมดนี้',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _entryTile({
    required int index,
    required String name,
    required String score,
    required bool isCurrent,
    String? detail,
  }) => Container(
    decoration: BoxDecoration(
      color: isCurrent ? const Color(0xFF2B3541) : const Color(0xFF1C232B),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: false,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: index == 0 ? Colors.white : Colors.white12,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: index == 0 ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: detail == null
          ? (isCurrent
                ? const Text(
                    'ผู้เล่นปัจจุบัน',
                    style: TextStyle(color: Colors.white70),
                  )
                : null)
          : Text(
              isCurrent ? '$detail • ผู้เล่นปัจจุบัน' : detail,
              style: const TextStyle(color: Colors.white70),
            ),
      trailing: Text(
        score,
        textAlign: TextAlign.end,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
