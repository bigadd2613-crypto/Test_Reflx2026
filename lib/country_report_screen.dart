// หน้ารายงานสถิติผู้เล่นและประเทศที่เข้าใช้งานแอป
// ปุ่มหลัก: กลับไปหน้าก่อนหน้า และรีเฟรชข้อมูลสถิติ

// นำเข้าเครื่องมือ Flutter สำหรับสร้างหน้าจอ วิดเจ็ต สี และการนำทาง
import 'package:flutter/material.dart';

// ใช้ครอบหน้ารายงานด้วยพื้นหลังเคลื่อนไหวร่วมกับหน้าจออื่นในระบบ
import 'animated_backdrop.dart';
// ใช้โหลด กรอง สรุป และค้นหาคะแนนตามประเทศและโหมดเกม
import 'country_tracker.dart';

// หน้าจอรายงานจำนวนผู้เข้าใช้งานแยกตามประเทศ
class CountryReportScreen extends StatefulWidget {
  // สร้างหน้ารายงานโดยไม่ต้องรับข้อมูลจากหน้าก่อนหน้า เพราะโหลดจาก CountryTracker
  const CountryReportScreen({super.key});

  // สร้าง State เพื่อจัดการข้อมูลที่โหลดและตัวเลือกโหมดบนหน้าจอ
  @override
  State<CountryReportScreen> createState() => _CountryReportScreenState();
}

// State หลักของหน้ารายงาน ใช้ควบคุมข้อมูลประเทศและการเลือกโหมดคะแนน
class _CountryReportScreenState extends State<CountryReportScreen> {
  // Future ของข้อมูลการเข้าใช้งาน ใช้เป็นแหล่งข้อมูลให้ FutureBuilder แสดงผลตามสถานะ
  late Future<List<CountryVisit>> _visitsFuture;
  // false แสดงคะแนน Time Reflex Test และ true แสดงคะแนน Aim Trainer
  bool _showAimTrainer = false;

  // เรียกครั้งเดียวเมื่อหน้าจอถูกสร้างขึ้น แล้วเริ่มโหลดข้อมูลการเข้าใช้งาน
  @override
  void initState() {
    super.initState();
    // เชื่อมหน้ารายงานกับบริการ CountryTracker เพื่ออ่านข้อมูลประเทศ
    _visitsFuture = CountryTracker.loadVisits();
  }

  // โหลดข้อมูลใหม่เมื่อผู้ใช้กดปุ่มรีเฟรช
  Future<void> _refresh() async {
    // สร้าง Future ใหม่เพื่อให้ FutureBuilder โหลดและแสดงข้อมูลล่าสุด
    setState(() {
      _visitsFuture = CountryTracker.loadVisits();
    });
  }

  // สร้างโครงหน้ารายงานทั้งหมดและจัดการการเปลี่ยนสถานะของหน้าจอ
  @override
  Widget build(BuildContext context) {
    // จัดการแท็บประเทศและต่างประเทศให้ TabBar กับ TabBarView ทำงานร่วมกัน
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // กำหนดสีพื้นฐานของหน้ารายงาน
        backgroundColor: const Color(0xFF101419),
        // ใช้พื้นหลังเคลื่อนไหวจาก animated_backdrop.dart ครอบเนื้อหาหน้านี้
        body: AnimatedBackdrop(
          child: SafeArea(
            // ป้องกันเนื้อหาไม่ให้ชนกับขอบจอหรือพื้นที่ของระบบ
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DecoratedBox(
                // สร้างแผงหลักด้วยพื้นหลังไล่สี ขอบมน และเงา
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
                  // ตัดเนื้อหาด้านในให้เป็นไปตามขอบมนของแผงหลัก
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  child: Column(
                    children: [
                      // แถบหัวหน้าจอที่มีปุ่มย้อนกลับและชื่อรายงาน
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                        child: Row(
                          children: [
                            IconButton(
                              // กลับไปหน้าก่อนหน้าผ่าน Navigator
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
                                'Location Report',
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
                        // จัดระยะห่างรอบตัวควบคุมแท็บประเทศ
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Theme(
                          // ปรับสีและรูปแบบตัวอักษรของ TabBar เฉพาะหน้านี้
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
                            // แสดงแท็บสำหรับข้อมูลในประเทศและต่างประเทศ
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
                              Tab(text: 'ประเทศ'),
                              Tab(text: 'ต่างประเทศ'),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        // วางตัวเลือกโหมดเกมไว้ใต้แท็บประเทศ
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: SegmentedButton<bool>(
                          // กำหนดตัวเลือกโหมด Time Reflex Test และ Aim Trainer
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Time Reflex Test'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Aim Trainer'),
                            ),
                          ],
                          selected: {_showAimTrainer},
                          // เก็บโหมดที่ผู้ใช้เลือก แล้วสั่งให้หน้าจอแสดงผลใหม่
                          onSelectionChanged: (selection) {
                            setState(() => _showAimTrainer = selection.first);
                          },
                        ),
                      ),
                      Expanded(
                        // ขยายพื้นที่ให้เนื้อหารายงานใช้พื้นที่ที่เหลือของหน้าจอ
                        child: FutureBuilder<List<CountryVisit>>(
                          // รอข้อมูลที่โหลดจาก CountryTracker ก่อนสร้างรายงาน
                          future: _visitsFuture,
                          builder: (context, snapshot) {
                            // แสดงวงกลมโหลดระหว่างรอข้อมูลจากแหล่งข้อมูล
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            // ใช้รายการว่างแทนกรณีไม่มีข้อมูลหรือโหลดข้อมูลไม่ได้
                            final visits = snapshot.data ?? <CountryVisit>[];
                            // กรองเฉพาะข้อมูลการเข้าใช้งานจากประเทศเดียวกับระบบ
                            final domesticVisits =
                                CountryTracker.filterDomestic(visits);
                            // กรองเฉพาะข้อมูลการเข้าใช้งานจากต่างประเทศ
                            final internationalVisits =
                                CountryTracker.filterInternational(visits);

                            // เชื่อมแต่ละแท็บกับ Dashboard ของข้อมูลที่กรองแล้ว
                            return TabBarView(
                              children: [
                                _dashboardContent(
                                  visits: domesticVisits,
                                  emptyText: 'ยังไม่มีข้อมูลประเทศ',
                                ),
                                _dashboardContent(
                                  visits: internationalVisits,
                                  emptyText: 'ยังไม่มีข้อมูลต่างประเทศ',
                                ),
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
        // ปุ่มลอยสำหรับเรียกโหลดข้อมูลรายงานใหม่
        floatingActionButton: FloatingActionButton(
          onPressed: _refresh,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          child: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }

  Widget _dashboardContent({
    required List<CountryVisit> visits,
    required String emptyText,
  }) {
    // แสดงข้อความแทน Dashboard เมื่อไม่มีข้อมูลในหมวดประเทศนั้น
    if (visits.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // ขอข้อมูลสรุป เช่น จำนวนครั้ง ประเทศ และผู้เล่น จาก CountryTracker
    final summary = CountryTracker.summary(visits);
    // สร้างรายการเนื้อหาที่เลื่อนดูได้ในแต่ละแท็บ
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // แสดงการ์ดสรุปข้อมูลหลักเรียงตามพื้นที่ที่มี
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              label: 'รวม',
              value: '${summary.totalVisits}',
              icon: Icons.people_alt_rounded,
            ),
            _statCard(
              label: 'ประเทศ',
              value: '${summary.uniqueCountries}',
              icon: Icons.public_rounded,
            ),
            _statCard(
              label: 'ผู้เล่น',
              value: '${summary.uniquePlayers}',
              icon: Icons.person_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // แสดงชื่อรายการอันดับตามโหมดเกมที่เลือก
        _panelTitle(
          _showAimTrainer ? 'Top 10 Aim Trainer' : 'Top 10 Time Reflex Test',
        ),
        // โหลดอันดับคะแนนของโหมดที่เลือกสำหรับข้อมูลประเทศปัจจุบัน
        FutureBuilder<List<ModeBestScore>>(
          future: CountryTracker.modeLeaders(
            visits,
            aimTrainer: _showAimTrainer,
          ),
          builder: (context, modeSnapshot) {
            // ซ่อนพื้นที่อันดับไว้ก่อนเมื่อข้อมูลยังโหลดไม่เสร็จ
            if (!modeSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            // ดึงรายการอันดับที่โหลดเสร็จแล้วมาแสดง
            final leaders = modeSnapshot.data!;

            // แจ้งผู้ใช้เมื่อยังไม่มีคะแนนของโหมดที่เลือก
            if (leaders.isEmpty) {
              return const Text(
                'ยังไม่มีข้อมูลคะแนนของโหมดนี้',
                style: TextStyle(color: Colors.white70),
              );
            }

            // แสดงผู้เล่น 10 อันดับแรกพร้อมประเทศและคะแนน
            return Column(
              children: leaders.take(10).toList().asMap().entries.map((entry) {
                final leader = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C232B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2B3541),
                        child: Text(
                          '#${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leader.playerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              leader.countryName,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        leader.scoreLabel,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    // กำหนดขนาดการ์ดสถิติให้คงที่เพื่อจัดวางหลายการ์ดใน Wrap
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C232B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            // แสดงไอคอนที่สื่อความหมายของสถิติ
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3541),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              // วางชื่อสถิติและค่าจริงไว้ในพื้นที่ที่เหลือของการ์ด
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelTitle(String title) {
    // สร้างหัวข้อของแผงอันดับคะแนนตามโหมดที่ผู้ใช้เลือก
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
