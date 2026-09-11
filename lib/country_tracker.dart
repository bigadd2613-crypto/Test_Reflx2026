// ระบบบันทึกและคำนวณข้อมูลประเทศ สถิติการเข้าใช้งาน และคะแนนผู้เล่น
// ไม่มีปุ่ม UI โดยตรง เพราะถูกเรียกใช้โดยหน้า Login และ Country Report

// ใช้แปลงข้อมูลประวัติการเข้าใช้งานระหว่าง JSON และชนิดข้อมูลของ Dart
import 'dart:convert';

// ใช้เรียกบริการ ipapi.co เพื่อตรวจ IP และประเทศของผู้เล่น
import 'package:http/http.dart' as http;
// ใช้เก็บประวัติภายในเครื่องเมื่อยังไม่ได้ตั้งค่า Supabase
import 'package:shared_preferences/shared_preferences.dart';

// ใช้ตรวจสอบการเชื่อมต่อและอ่าน/เขียนข้อมูลกับ Supabase
import 'cloud_database.dart';
// ใช้โหลดข้อมูลผู้เล่นและคะแนนของแต่ละโหมดเกม
import 'data_player.dart';

// โมเดลข้อมูลการเข้าใช้งานหนึ่งครั้งของผู้เล่น
class CountryVisit {
  // ชื่อผู้เล่นที่เข้าใช้งาน
  final String playerName;
  // IP ที่ตรวจพบจากบริการระบุตำแหน่ง
  final String ipAddress;
  // รหัสประเทศ เช่น TH
  final String countryCode;
  // ชื่อประเทศที่ใช้แสดงในรายงาน
  final String countryName;
  // ระบุว่าการเข้าใช้งานมาจากประเทศไทยหรือไม่
  final bool isDomestic;
  // วันและเวลาที่บันทึกการเข้าใช้งาน
  final DateTime createdAt;

  // สร้างข้อมูลการเข้าใช้งานโดยบังคับให้มีค่าครบทุกฟิลด์
  const CountryVisit({
    required this.playerName,
    required this.ipAddress,
    required this.countryCode,
    required this.countryName,
    required this.isDomestic,
    required this.createdAt,
  });

  // แปลงข้อมูล JSON ที่อ่านจากเครื่องหรือแหล่งข้อมูลอื่นให้เป็น CountryVisit
  factory CountryVisit.fromJson(Map<String, dynamic> json) => CountryVisit(
    playerName: (json['playerName'] ?? 'Unknown').toString(),
    ipAddress: (json['ipAddress'] ?? 'unknown').toString(),
    countryCode: (json['countryCode'] ?? '').toString().toUpperCase(),
    countryName: (json['countryName'] ?? 'Unknown').toString(),
    isDomestic: (json['isDomestic'] ?? false) as bool,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  // แปลง CountryVisit เป็น Map เพื่อจัดเก็บเป็น JSON หรือส่งต่อไปฐานข้อมูล
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'ipAddress': ipAddress,
    'countryCode': countryCode,
    'countryName': countryName,
    'isDomestic': isDomestic,
    'createdAt': createdAt.toIso8601String(),
  };
}

// สถิติจำนวนผู้เข้าใช้งานแยกตามประเทศ
class TopCountryStat {
  final String country;
  final int count;

  const TopCountryStat({required this.country, required this.count});
}

// สถิติจำนวนผู้เข้าใช้งานแยกตามวัน
class DailyVisitStat {
  final String dayLabel;
  final int count;

  const DailyVisitStat({required this.dayLabel, required this.count});
}

// สถิติจำนวนการเข้าใช้งานของผู้เล่นแต่ละคนและประเทศหลัก
class PlayerCountryStat {
  final String playerName;
  final String countryName;
  final int count;

  const PlayerCountryStat({
    required this.playerName,
    required this.countryName,
    required this.count,
  });
}

// ข้อมูลผู้เล่นที่ติดอันดับตามจำนวนการเข้าใช้งาน
class TopPlayerStat {
  final String playerName;
  final String countryName;
  final int count;
  final int rank;

  const TopPlayerStat({
    required this.playerName,
    required this.countryName,
    required this.count,
    required this.rank,
  });
}

// ข้อมูลคะแนนสูงสุดของผู้เล่นในแต่ละโหมดเกม
class ModeBestScore {
  final String modeName;
  final String playerName;
  final String countryName;
  final String scoreLabel;
  final double scoreValue;

  const ModeBestScore({
    required this.modeName,
    required this.playerName,
    required this.countryName,
    required this.scoreLabel,
    required this.scoreValue,
  });
}

// ข้อมูลสรุปรวมที่หน้า CountryReportScreen ใช้แสดงเป็นการ์ดสถิติ
class CountrySummary {
  final int totalVisits;
  final int domesticVisits;
  final int internationalVisits;
  final int uniqueCountries;
  final int uniquePlayers;
  final String topCountry;
  final int topCountryCount;

  const CountrySummary({
    required this.totalVisits,
    required this.domesticVisits,
    required this.internationalVisits,
    required this.uniqueCountries,
    required this.uniquePlayers,
    required this.topCountry,
    required this.topCountryCount,
  });
}

// บริการกลางสำหรับบันทึกและคำนวณข้อมูลประเทศของระบบ
class CountryTracker {
  // ชื่อคีย์ที่ใช้เก็บประวัติใน SharedPreferences
  static const _storageKey = 'country_login_history_v1';

  // ตรวจตำแหน่งของผู้เล่นแล้วบันทึกประวัติการ Login
  static Future<void> saveLogin(String playerName) async {
    // เรียก API ภายนอกเพื่อสร้างข้อมูลประเทศและ IP ปัจจุบัน
    final visit = await detectCurrentLocation(playerName: playerName);
    // ถ้าตรวจตำแหน่งไม่สำเร็จ จะหยุดโดยไม่บันทึกข้อมูล
    if (visit == null) return;

    // ถ้ามี Supabase ให้บันทึกข้อมูลลงตารางออนไลน์ country_visits
    if (CloudDatabase.isConfigured) {
      await CloudDatabase.insert('country_visits', {
        'player_name': visit.playerName,
        'ip_address': visit.ipAddress,
        'country_code': visit.countryCode,
        'country_name': visit.countryName,
        'is_domestic': visit.isDomestic,
        'created_at': visit.createdAt.toIso8601String(),
      });
      return;
    }

    // หากไม่มี Supabase ให้ใช้ฐานข้อมูลภายในเครื่องแทน
    final prefs = await SharedPreferences.getInstance();
    // โหลดประวัติเดิมแล้วเพิ่มข้อมูลการเข้าใช้งานครั้งปัจจุบัน
    final history = await loadVisits();
    history.add(visit);
    // แปลงประวัติทั้งหมดเป็น JSON แล้วเก็บไว้ด้วยคีย์ของระบบ
    await prefs.setString(
      _storageKey,
      jsonEncode(history.map((item) => item.toJson()).toList()),
    );
  }

  // โหลดประวัติการเข้าใช้งานจาก Supabase หรือจากเครื่องตามการตั้งค่าระบบ
  static Future<List<CountryVisit>> loadVisits() async {
    // อ่านข้อมูลจากตารางออนไลน์เมื่อ Supabase พร้อมใช้งาน
    if (CloudDatabase.isConfigured) {
      final rows = await CloudDatabase.select('country_visits');
      return rows.map(_fromCloud).toList();
    }

    // อ่านข้อมูล JSON ที่เก็บไว้ใน SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    // ไม่มีข้อมูลที่จัดเก็บไว้ จึงคืนรายการว่างให้หน้ารายงาน
    if (raw == null || raw.isEmpty) return [];

    // แปลงข้อความ JSON เป็นข้อมูล Dart
    final decoded = jsonDecode(raw);
    // ป้องกันข้อมูลผิดรูปแบบที่ไม่ใช่ List
    if (decoded is! List) return [];

    // แปลงแต่ละรายการกลับเป็น CountryVisit ให้ส่วนอื่นของระบบใช้งาน
    return decoded
        .whereType<Map>()
        .map((item) => CountryVisit.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // แปลงชื่อคอลัมน์แบบ snake_case จาก Supabase เป็น CountryVisit
  static CountryVisit _fromCloud(Map<String, dynamic> row) => CountryVisit(
    playerName: (row['player_name'] ?? 'Unknown').toString(),
    ipAddress: (row['ip_address'] ?? 'unknown').toString(),
    countryCode: (row['country_code'] ?? '').toString().toUpperCase(),
    countryName: (row['country_name'] ?? 'Unknown').toString(),
    isDomestic: row['is_domestic'] == true,
    createdAt:
        DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );

  // เรียกบริการภายนอกเพื่อตรวจ IP ประเทศ และเวลาปัจจุบันของผู้เล่น
  static Future<CountryVisit?> detectCurrentLocation({
    required String playerName,
  }) async {
    try {
      // ส่งคำขอ GET ไปยัง ipapi.co พร้อมขอผลลัพธ์เป็น JSON
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'Accept': 'application/json'},
      );

      // ถ้าบริการตอบกลับไม่ใช่สถานะสำเร็จ ให้ถือว่าตรวจตำแหน่งไม่สำเร็จ
      if (response.statusCode != 200) return null;

      // แปลงข้อมูลตำแหน่งจากข้อความ JSON เป็น Map
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      // อ่านรหัสประเทศและแปลงเป็นตัวพิมพ์ใหญ่เพื่อใช้เปรียบเทียบ
      final countryCode = (payload['country_code'] ?? payload['country'] ?? '')
          .toString()
          .toUpperCase();
      final countryName =
          (payload['country_name'] ?? payload['country'] ?? 'Unknown')
              .toString();
      // ตรวจว่าผู้เล่นอยู่ประเทศไทยเพื่อใช้แบ่งกลุ่มในรายงาน
      final isDomestic =
          countryCode == 'TH' || countryName.toLowerCase() == 'thailand';

      // รวมข้อมูลที่ตรวจพบเป็นประวัติการเข้าใช้งานหนึ่งรายการ
      return CountryVisit(
        playerName: playerName,
        ipAddress: (payload['ip'] ?? 'unknown').toString(),
        countryCode: countryCode,
        countryName: countryName,
        isDomestic: isDomestic,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      // ป้องกันข้อผิดพลาดจากเครือข่ายไม่ให้ทำให้หน้า Login หรือรายงานหยุดทำงาน
      return null;
    }
  }

  // คัดเฉพาะรายการที่มาจากประเทศไทย
  static List<CountryVisit> filterDomestic(List<CountryVisit> visits) =>
      visits.where((visit) => visit.isDomestic).toList();

  // คัดเฉพาะรายการที่มาจากต่างประเทศ
  static List<CountryVisit> filterInternational(List<CountryVisit> visits) =>
      visits.where((visit) => !visit.isDomestic).toList();

  // นับจำนวนการเข้าใช้งานตามประเทศและคืนประเทศที่มีจำนวนสูงสุดตาม limit
  static List<TopCountryStat> topCountries(
    List<CountryVisit> visits, {
    int limit = 10,
  }) {
    // เก็บจำนวนครั้งของแต่ละประเทศด้วยชื่อประเทศเป็นคีย์
    final counts = <String, int>{};

    // วนดูประวัติทั้งหมดเพื่อสะสมจำนวนครั้ง
    for (final visit in visits) {
      final key = visit.countryName.trim().isEmpty
          ? 'Unknown'
          : visit.countryName;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    // แปลงผลรวมเป็นโมเดล จัดเรียงจากมากไปน้อย แล้วจำกัดจำนวนผลลัพธ์
    final list =
        counts.entries
            .map(
              (entry) => TopCountryStat(country: entry.key, count: entry.value),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return list.take(limit).toList();
  }

  // สรุปจำนวนการเข้าใช้งานในแต่ละวันและเรียงจากวันล่าสุด
  static List<DailyVisitStat> dailyVisits(List<CountryVisit> visits) {
    final map = <String, int>{};

    // รวมจำนวนรายการตามวันที่แปลงเป็นเวลาท้องถิ่น
    for (final visit in visits) {
      final day = visit.createdAt.toLocal();
      final label =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      map[label] = (map[label] ?? 0) + 1;
    }

    final items =
        map.entries
            .map(
              (entry) =>
                  DailyVisitStat(dayLabel: entry.key, count: entry.value),
            )
            .toList()
          ..sort((a, b) => b.dayLabel.compareTo(a.dayLabel));

    return items;
  }

  // ค้นหาผู้เล่นที่มีคะแนนดีที่สุดของโหมด Aim Trainer หรือ Time Reflex Test
  static Future<List<ModeBestScore>> modeLeaders(
    List<CountryVisit> visits, {
    required bool aimTrainer,
  }) async {
    // โหลดคะแนนผู้เล่นจาก PlayerProfileStore
    final players = await PlayerProfileStore.loadData();
    // จับคู่ชื่อผู้เล่นกับประเทศล่าสุดที่พบในประวัติ
    final latestCountryByPlayer = <String, String>{};

    for (final visit in visits) {
      final playerName = visit.playerName.trim().isEmpty
          ? 'Unknown'
          : visit.playerName;
      latestCountryByPlayer[playerName] = visit.countryName;
    }

    // เลือกเฉพาะผู้เล่นที่มีประวัติประเทศและมีคะแนนของโหมดที่เลือก
    final modePlayers = players
        .where(
          (player) =>
              latestCountryByPlayer.containsKey(player.name) &&
              (aimTrainer
                  ? player.aimSpeed != null
                  : player.reflexScore != null),
        )
        .toList();

    // สร้างข้อมูลอันดับพร้อมชื่อโหมด รูปแบบคะแนน และค่าที่ใช้จัดเรียง
    final leaders = <ModeBestScore>[];
    for (final player in modePlayers) {
      final country = latestCountryByPlayer[player.name] ?? 'Unknown';
      final scoreValue = aimTrainer
          ? player.aimSpeed!
          : player.reflexScore!.toDouble();
      leaders.add(
        ModeBestScore(
          modeName: aimTrainer ? 'Aim Trainer' : 'Time Reflex Test',
          playerName: player.name,
          countryName: country,
          scoreLabel: aimTrainer
              ? '${scoreValue.toStringAsFixed(2)} targets/s'
              : '${scoreValue.toStringAsFixed(0)} ms',
          scoreValue: scoreValue,
        ),
      );
    }

    // Aim Trainer ยิ่งเร็ว/จำนวนเป้าต่อวินาทีมากยิ่งดี
    // Time Reflex Test ใช้เวลาน้อยกว่ายิ่งดี
    leaders.sort(
      (a, b) => aimTrainer
          ? b.scoreValue.compareTo(a.scoreValue)
          : a.scoreValue.compareTo(b.scoreValue),
    );
    return leaders;
  }

  // รวมจำนวนการเข้าใช้งานของผู้เล่นแต่ละคนและเลือกประเทศหลักของผู้เล่น
  static List<PlayerCountryStat> playerCountries(List<CountryVisit> visits) {
    final counts = <String, Map<String, int>>{};

    // นับจำนวนครั้งของผู้เล่นแยกตามประเทศ
    for (final visit in visits) {
      final key = visit.playerName.trim().isEmpty
          ? 'Unknown'
          : visit.playerName;
      counts.putIfAbsent(key, () => <String, int>{});
      final countryKey = visit.countryName.trim().isEmpty
          ? 'Unknown'
          : visit.countryName;
      counts[key]![countryKey] = (counts[key]![countryKey] ?? 0) + 1;
    }

    // แปลงข้อมูลที่นับได้เป็นรายการสถิติของผู้เล่น
    final result = <PlayerCountryStat>[];
    for (final entry in counts.entries) {
      final topCountry = entry.value.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mainCountry = topCountry.isNotEmpty
          ? topCountry.first.key
          : 'Unknown';
      result.add(
        PlayerCountryStat(
          playerName: entry.key,
          countryName: mainCountry,
          count: entry.value.values.fold(0, (sum, value) => sum + value),
        ),
      );
    }

    // เรียงผู้เล่นตามจำนวนการเข้าใช้งานจากมากไปน้อย
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  // จัดอันดับผู้เล่นที่เข้าใช้งานระบบมากที่สุด
  static List<TopPlayerStat> topPlayers(
    List<CountryVisit> visits, {
    int limit = 3,
  }) {
    // เก็บจำนวนครั้งและประเทศของผู้เล่นแต่ละคน
    final counts = <String, int>{};
    final countryByPlayer = <String, String>{};

    // สะสมข้อมูลจำนวนครั้งที่ผู้เล่นแต่ละคนเข้าใช้งาน
    for (final visit in visits) {
      final playerName = visit.playerName.trim().isEmpty
          ? 'Unknown'
          : visit.playerName;
      final countryName = visit.countryName.trim().isEmpty
          ? 'Unknown'
          : visit.countryName;

      counts[playerName] = (counts[playerName] ?? 0) + 1;
      countryByPlayer[playerName] ??= countryName;
    }

    // สร้างรายการอันดับชั่วคราวแล้วเรียงจากจำนวนมากไปน้อย
    final ordered =
        counts.entries
            .map(
              (entry) => TopPlayerStat(
                playerName: entry.key,
                countryName: countryByPlayer[entry.key] ?? 'Unknown',
                count: entry.value,
                rank: 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    // กำหนดลำดับจริงเริ่มจาก 1 และคืนเฉพาะจำนวนตาม limit
    return ordered
        .asMap()
        .entries
        .map(
          (entry) => TopPlayerStat(
            playerName: entry.value.playerName,
            countryName: entry.value.countryName,
            count: entry.value.count,
            rank: entry.key + 1,
          ),
        )
        .take(limit)
        .toList();
  }

  // สร้างข้อมูลสรุปที่ CountryReportScreen ใช้แสดงภาพรวมของรายงาน
  static CountrySummary summary(List<CountryVisit> visits) {
    // นับจำนวนการเข้าใช้งานในประเทศและต่างประเทศ
    final domestic = filterDomestic(visits).length;
    final international = filterInternational(visits).length;
    // นับจำนวนประเทศและผู้เล่นที่ไม่ซ้ำกัน
    final uniqueCountries = topCountries(visits).length;
    final uniquePlayers = visits
        .map((visit) => visit.playerName)
        .toSet()
        .length;
    // ค้นหาประเทศที่มีจำนวนการเข้าใช้งานมากที่สุด
    final topCountryStats = topCountries(visits);
    final topCountry = topCountryStats.isEmpty
        ? 'ไม่มีข้อมูล'
        : topCountryStats.first.country;
    final topCountryCount = topCountryStats.isEmpty
        ? 0
        : topCountryStats.first.count;

    // รวมค่าทั้งหมดเป็น CountrySummary เพื่อส่งให้หน้ารายงาน
    return CountrySummary(
      totalVisits: visits.length,
      domesticVisits: domestic,
      internationalVisits: international,
      uniqueCountries: uniqueCountries,
      uniquePlayers: uniquePlayers,
      topCountry: topCountry,
      topCountryCount: topCountryCount,
    );
  }
}
