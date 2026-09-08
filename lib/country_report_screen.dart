// หน้ารายงานสถิติผู้เล่นและประเทศที่เข้าใช้งานแอป
// ปุ่มหลัก: กลับไปหน้าก่อนหน้า และรีเฟรชข้อมูลสถิติ

import 'package:flutter/material.dart';

import 'animated_backdrop.dart';
import 'country_tracker.dart';

class CountryReportScreen extends StatefulWidget {
  const CountryReportScreen({super.key});

  @override
  State<CountryReportScreen> createState() => _CountryReportScreenState();
}

class _CountryReportScreenState extends State<CountryReportScreen> {
  late Future<List<CountryVisit>> _visitsFuture;
  bool _showAimTrainer = false;

  @override
  void initState() {
    super.initState();
    _visitsFuture = CountryTracker.loadVisits();
  }

  Future<void> _refresh() async {
    setState(() {
      _visitsFuture = CountryTracker.loadVisits();
    });
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
                              Tab(text: 'ประเทศ'),
                              Tab(text: 'ต่างประเทศ'),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: SegmentedButton<bool>(
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
                          onSelectionChanged: (selection) {
                            setState(() => _showAimTrainer = selection.first);
                          },
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<CountryVisit>>(
                          future: _visitsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final visits = snapshot.data ?? <CountryVisit>[];
                            final domesticVisits =
                                CountryTracker.filterDomestic(visits);
                            final internationalVisits =
                                CountryTracker.filterInternational(visits);

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

    final summary = CountryTracker.summary(visits);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        _panelTitle(
          _showAimTrainer ? 'Top 10 Aim Trainer' : 'Top 10 Time Reflex Test',
        ),
        FutureBuilder<List<ModeBestScore>>(
          future: CountryTracker.modeLeaders(
            visits,
            aimTrainer: _showAimTrainer,
          ),
          builder: (context, modeSnapshot) {
            if (!modeSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final leaders = modeSnapshot.data!;

            if (leaders.isEmpty) {
              return const Text(
                'ยังไม่มีข้อมูลคะแนนของโหมดนี้',
                style: TextStyle(color: Colors.white70),
              );
            }

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
