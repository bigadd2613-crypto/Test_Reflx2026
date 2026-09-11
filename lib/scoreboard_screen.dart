// หน้าแสดงคะแนนรวมของผู้เล่น แยกเป็น Time Reflex และ Aim Trainer
// ปุ่มหลัก: กลับไปหน้าก่อนหน้า และแท็บเลือกประเภทคะแนน

// ใช้สร้างหน้าจอ แท็บ รายการคะแนน และการนำทางของ Flutter
import 'package:flutter/material.dart';

// ใช้พื้นหลังเคลื่อนไหวของหน้าตารางคะแนน
import 'animated_backdrop.dart';
// ใช้โหลดประเทศล่าสุดของผู้เล่นแต่ละคน
import 'country_tracker.dart';
// ใช้โหลดข้อมูลโปรไฟล์และคะแนนของผู้เล่น
import 'data_player.dart';

// หน้าจอแสดงอันดับคะแนนของทั้งสองเกม
class ScoreboardScreen extends StatefulWidget {
  // ID ผู้เล่นปัจจุบันที่ใช้ไฮไลต์ในรายการคะแนน
  final String currentId;

  // สร้างหน้าตารางคะแนนพร้อมรับ ID ผู้เล่นปัจจุบัน
  const ScoreboardScreen({super.key, required this.currentId});

  // สร้าง State สำหรับโหลดและแสดงข้อมูลคะแนน
  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardData {
  // รายการโปรไฟล์ผู้เล่นที่โหลดจาก PlayerProfileStore
  final List<PlayerData> players;
  // แผนที่ชื่อผู้เล่นกับประเทศล่าสุดที่พบจาก CountryTracker
  final Map<String, String> countryByPlayer;

  // รวมข้อมูลคะแนนและประเทศไว้เป็นชุดเดียวสำหรับหน้าจอ
  const _ScoreboardData({required this.players, required this.countryByPlayer});

  // คืนชื่อประเทศของผู้เล่น หากไม่พบให้ใช้ Unknown
  String countryFor(String playerName) =>
      countryByPlayer[playerName.toLowerCase()] ?? 'Unknown';
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  // จำกัดจำนวนรายการอันดับสูงสุดที่แสดงบนหน้าจอ
  static const _maxScoreboardEntries = 100;

  // Future ของข้อมูลที่ต้องโหลดก่อนสร้างรายการคะแนน
  late Future<_ScoreboardData> _scoreboardData;

  // เริ่มโหลดข้อมูลทันทีเมื่อหน้าจอถูกสร้าง
  @override
  void initState() {
    super.initState();
    _scoreboardData = _loadScoreboardData();
  }

  // โหลดข้อมูลผู้เล่นและประวัติประเทศพร้อมกันเพื่อใช้สร้าง Scoreboard
  Future<_ScoreboardData> _loadScoreboardData() async {
    // ลดเวลาโหลดด้วยการเรียกบริการข้อมูลทั้งสองชุดพร้อมกัน
    final results = await Future.wait([
      PlayerProfileStore.loadData(),
      CountryTracker.loadVisits(),
    ]);
    // แยกผลลัพธ์กลับเป็นรายการผู้เล่นและประวัติการเข้าใช้งาน
    final players = results[0] as List<PlayerData>;
    final visits = results[1] as List<CountryVisit>;
    // เก็บประเทศล่าสุดของผู้เล่นแต่ละคนโดยใช้ชื่อเป็นคีย์
    final countryByPlayer = <String, String>{};
    // เรียงประวัติจากเก่าไปใหม่ เพื่อให้รายการท้ายสุดเป็นประเทศล่าสุด
    final orderedVisits = [...visits]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // วนประวัติเพื่อบันทึกประเทศล่าสุดของผู้เล่นแต่ละคน
    for (final visit in orderedVisits) {
      final playerKey = visit.playerName.trim().toLowerCase();
      if (playerKey.isNotEmpty) {
        countryByPlayer[playerKey] = visit.countryName.trim().isEmpty
            ? 'Unknown'
            : visit.countryName.trim();
      }
    }

    // รวมข้อมูลทั้งหมดส่งกลับให้ FutureBuilder ใช้แสดงผล
    return _ScoreboardData(players: players, countryByPlayer: countryByPlayer);
  }

  // สร้างโครงหน้าตารางคะแนนและแท็บของทั้งสองเกม
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // กำหนดสีพื้นฐานให้หน้าตารางคะแนน
        backgroundColor: const Color(0xFF101419),
        // ครอบเนื้อหาด้วยพื้นหลังเคลื่อนไหว
        body: AnimatedBackdrop(
          child: SafeArea(
            // กันเนื้อหาไม่ให้ชนขอบจอหรือพื้นที่ระบบ
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DecoratedBox(
                // สร้างแผงหลักด้วยไล่สี ขอบมน และเงา
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
                  // ตัดเนื้อหาให้พอดีกับขอบมนของแผงหลัก
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  child: Column(
                    children: [
                      Container(
                        // แถบหัวหน้าจอและปุ่มย้อนกลับ
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                        child: Row(
                          children: [
                            IconButton(
                              // กลับไปยังหน้าก่อนหน้าผ่าน Navigator
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
                        // จัดระยะห่างและ Theme เฉพาะส่วน TabBar
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
                            // แท็บสำหรับสลับระหว่างคะแนนสองโหมด
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
                        // ขยายพื้นที่สำหรับรายการคะแนนที่โหลดเสร็จแล้ว
                        child: FutureBuilder<_ScoreboardData>(
                          // รอข้อมูลจาก PlayerProfileStore และ CountryTracker
                          future: _scoreboardData,
                          builder: (context, snapshot) {
                            // แสดงตัวโหลดระหว่างรอข้อมูล
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            // ใช้ข้อมูลที่โหลดเสร็จสร้าง TabBarView ของแต่ละเกม
                            final data = snapshot.data!;
                            return TabBarView(
                              children: [_reflexBoard(data), _aimBoard(data)],
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

  Widget _reflexBoard(_ScoreboardData data) {
    // ดึงเฉพาะผู้เล่นที่มีคะแนน Time Reflex
    final players = data.players;
    // เรียงคะแนนจากเวลาน้อยไปมาก เพราะใช้เวลาน้อยกว่าถือว่าดีกว่า
    final entries =
        players.where((player) => player.reflexScore != null).toList()
          ..sort((a, b) => a.reflexScore!.compareTo(b.reflexScore!));
    // จำกัดจำนวนรายการตามจำนวนสูงสุดที่กำหนด
    final topEntries = entries.take(_maxScoreboardEntries).toList();

    // แสดงรายชื่อผู้เล่นแทนเมื่อยังไม่มีคะแนนในโหมดนี้
    if (topEntries.isEmpty) {
      return _playersWithoutScore(players, 'ยังไม่มีคะแนน Time Reflex');
    }

    return ListView.separated(
      // แสดงรายการคะแนนแบบเลื่อนพร้อมระยะห่างระหว่างรายการ
      padding: const EdgeInsets.all(16),
      itemCount: topEntries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        // สร้างรายการอันดับของผู้เล่นแต่ละคน
        final entry = topEntries[index];
        return _entryTile(
          index: index,
          name: entry.name,
          score: '${entry.reflexScore} ms',
          country: data.countryFor(entry.name),
          isCurrent: _isCurrent(entry.name),
        );
      },
    );
  }

  Widget _aimBoard(_ScoreboardData data) {
    // ดึงเฉพาะผู้เล่นที่มีคะแนน Aim Trainer
    final players = data.players;
    // เรียงความเร็วจากมากไปน้อย เพราะความเร็วสูงกว่าถือว่าดีกว่า
    final entries = players.where((player) => player.aimSpeed != null).toList()
      ..sort((a, b) => b.aimSpeed!.compareTo(a.aimSpeed!));
    // จำกัดจำนวนรายการอันดับที่จะแสดง
    final topEntries = entries.take(_maxScoreboardEntries).toList();

    // แสดงรายชื่อผู้เล่นแทนเมื่อยังไม่มีคะแนนในโหมดนี้
    if (topEntries.isEmpty) {
      return _playersWithoutScore(players, 'ยังไม่มีคะแนน Aim Trainer');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topEntries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        // สร้างรายการอันดับพร้อมความแม่นยำและจำนวนครั้งที่ยิงถูก
        final entry = topEntries[index];
        return _entryTile(
          index: index,
          name: entry.name,
          score: '${entry.aimSpeed!.toStringAsFixed(2)} targets/s',
          country: data.countryFor(entry.name),
          detail:
              '${entry.aimAccuracy!.toStringAsFixed(1)}% accuracy • ${entry.aimHits} hits',
          isCurrent: _isCurrent(entry.name),
        );
      },
    );
  }

  // ตรวจว่าชื่อในรายการตรงกับผู้เล่นปัจจุบันหรือไม่โดยไม่สนใจตัวพิมพ์
  bool _isCurrent(String id) =>
      id.toLowerCase() == widget.currentId.toLowerCase();

  // แสดงผู้เล่นที่มีโปรไฟล์แต่ยังไม่มีคะแนนของโหมดที่เลือก
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

  // สร้างแถวคะแนนหนึ่งรายการพร้อมอันดับ ชื่อ ประเทศ และรายละเอียด
  Widget _entryTile({
    required int index,
    required String name,
    required String score,
    required String country,
    required bool isCurrent,
    String? detail,
  }) => Container(
    // ใช้สีต่างกันเพื่อไฮไลต์ผู้เล่นปัจจุบัน
    decoration: BoxDecoration(
      color: isCurrent ? const Color(0xFF2B3541) : const Color(0xFF1C232B),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: ListTile(
      // แสดงรายละเอียดของผู้เล่นในแถวเดียว
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: false,
      leading: CircleAvatar(
        // แสดงหมายเลขอันดับ โดยอันดับหนึ่งใช้สีเด่น
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
          // แสดงข้อความผู้เล่นปัจจุบันหรือรายละเอียดสถิติรอง
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
      trailing: RichText(
        // แสดงคะแนนและประเทศชิดด้านขวาของรายการ
        textAlign: TextAlign.end,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: '$score  '),
            ..._countrySpans(country),
          ],
        ),
      ),
    ),
  );

  // สร้าง TextSpan ของชื่อประเทศ โดยประเทศไทยจะแสดงสีตามธงชาติ
  List<TextSpan> _countrySpans(String country) {
    // ประเทศอื่นแสดงชื่อด้วยสีปกติ
    if (country.toLowerCase() != 'thailand') {
      return [TextSpan(text: country)];
    }

    // สีแต่ละช่วงของตัวอักษรเพื่อจำลองแถบสีธงชาติไทย
    const flagColors = [
      Color(0xFFED1C24),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color.fromARGB(255, 0, 30, 255),
      Color.fromARGB(255, 0, 30, 255),
      Color.fromARGB(255, 0, 30, 255),
      Color(0xFFFFFFFF),
      Color(0xFFED1C24),
    ];

    // แยกตัวอักษรประเทศเพื่อกำหนดสีทีละตำแหน่ง
    return [
      for (var index = 0; index < country.length; index++)
        TextSpan(
          text: country[index],
          style: TextStyle(color: flagColors[index]),
        ),
    ];
  }
}
