// ระบบบันทึกและคำนวณข้อมูลประเทศ สถิติการเข้าใช้งาน และคะแนนผู้เล่น
// ไม่มีปุ่ม UI โดยตรง เพราะถูกเรียกใช้โดยหน้า Login และ Country Report

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_database.dart';
import 'data_player.dart';

class CountryVisit {
  final String playerName;
  final String ipAddress;
  final String countryCode;
  final String countryName;
  final bool isDomestic;
  final DateTime createdAt;

  const CountryVisit({
    required this.playerName,
    required this.ipAddress,
    required this.countryCode,
    required this.countryName,
    required this.isDomestic,
    required this.createdAt,
  });

  factory CountryVisit.fromJson(Map<String, dynamic> json) => CountryVisit(
    playerName: (json['playerName'] ?? 'Unknown').toString(),
    ipAddress: (json['ipAddress'] ?? 'unknown').toString(),
    countryCode: (json['countryCode'] ?? '').toString().toUpperCase(),
    countryName: (json['countryName'] ?? 'Unknown').toString(),
    isDomestic: (json['isDomestic'] ?? false) as bool,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'ipAddress': ipAddress,
    'countryCode': countryCode,
    'countryName': countryName,
    'isDomestic': isDomestic,
    'createdAt': createdAt.toIso8601String(),
  };
}

class TopCountryStat {
  final String country;
  final int count;

  const TopCountryStat({required this.country, required this.count});
}

class DailyVisitStat {
  final String dayLabel;
  final int count;

  const DailyVisitStat({required this.dayLabel, required this.count});
}

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

class CountryTracker {
  static const _storageKey = 'country_login_history_v1';

  static Future<void> saveLogin(String playerName) async {
    final visit = await detectCurrentLocation(playerName: playerName);
    if (visit == null) return;

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

    final prefs = await SharedPreferences.getInstance();
    final history = await loadVisits();
    history.add(visit);
    await prefs.setString(
      _storageKey,
      jsonEncode(history.map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<CountryVisit>> loadVisits() async {
    if (CloudDatabase.isConfigured) {
      final rows = await CloudDatabase.select('country_visits');
      return rows.map(_fromCloud).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => CountryVisit.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

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

  static Future<CountryVisit?> detectCurrentLocation({
    required String playerName,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return null;

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final countryCode = (payload['country_code'] ?? payload['country'] ?? '')
          .toString()
          .toUpperCase();
      final countryName =
          (payload['country_name'] ?? payload['country'] ?? 'Unknown')
              .toString();
      final isDomestic =
          countryCode == 'TH' || countryName.toLowerCase() == 'thailand';

      return CountryVisit(
        playerName: playerName,
        ipAddress: (payload['ip'] ?? 'unknown').toString(),
        countryCode: countryCode,
        countryName: countryName,
        isDomestic: isDomestic,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static List<CountryVisit> filterDomestic(List<CountryVisit> visits) =>
      visits.where((visit) => visit.isDomestic).toList();

  static List<CountryVisit> filterInternational(List<CountryVisit> visits) =>
      visits.where((visit) => !visit.isDomestic).toList();

  static List<TopCountryStat> topCountries(
    List<CountryVisit> visits, {
    int limit = 10,
  }) {
    final counts = <String, int>{};

    for (final visit in visits) {
      final key = visit.countryName.trim().isEmpty
          ? 'Unknown'
          : visit.countryName;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final list =
        counts.entries
            .map(
              (entry) => TopCountryStat(country: entry.key, count: entry.value),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return list.take(limit).toList();
  }

  static List<DailyVisitStat> dailyVisits(List<CountryVisit> visits) {
    final map = <String, int>{};

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

  static Future<List<ModeBestScore>> modeLeaders(
    List<CountryVisit> visits,
  ) async {
    final players = await PlayerProfileStore.loadData();
    final latestCountryByPlayer = <String, String>{};

    for (final visit in visits) {
      final playerName = visit.playerName.trim().isEmpty
          ? 'Unknown'
          : visit.playerName;
      latestCountryByPlayer[playerName] = visit.countryName;
    }

    final reflexPlayers = players
        .where((player) => player.reflexScore != null)
        .toList();
    final aimPlayers = players
        .where((player) => player.aimSpeed != null)
        .toList();

    ModeBestScore? bestReflex;
    for (final player in reflexPlayers) {
      final country = latestCountryByPlayer[player.name] ?? 'Unknown';
      final scoreValue = player.reflexScore!.toDouble();
      if (bestReflex == null || scoreValue < bestReflex.scoreValue) {
        bestReflex = ModeBestScore(
          modeName: 'Time Reflex',
          playerName: player.name,
          countryName: country,
          scoreLabel: '${scoreValue.toStringAsFixed(0)} ms',
          scoreValue: scoreValue,
        );
      }
    }

    ModeBestScore? bestAim;
    for (final player in aimPlayers) {
      final country = latestCountryByPlayer[player.name] ?? 'Unknown';
      final scoreValue = player.aimSpeed!;
      if (bestAim == null || scoreValue > bestAim.scoreValue) {
        bestAim = ModeBestScore(
          modeName: 'Aim Trainer',
          playerName: player.name,
          countryName: country,
          scoreLabel: '${scoreValue.toStringAsFixed(2)} targets/s',
          scoreValue: scoreValue,
        );
      }
    }

    return [?bestReflex, ?bestAim];
  }

  static List<PlayerCountryStat> playerCountries(List<CountryVisit> visits) {
    final counts = <String, Map<String, int>>{};

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

    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  static List<TopPlayerStat> topPlayers(
    List<CountryVisit> visits, {
    int limit = 3,
  }) {
    final counts = <String, int>{};
    final countryByPlayer = <String, String>{};

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

  static CountrySummary summary(List<CountryVisit> visits) {
    final domestic = filterDomestic(visits).length;
    final international = filterInternational(visits).length;
    final uniqueCountries = topCountries(visits).length;
    final uniquePlayers = visits
        .map((visit) => visit.playerName)
        .toSet()
        .length;
    final topCountryStats = topCountries(visits);
    final topCountry = topCountryStats.isEmpty
        ? 'ไม่มีข้อมูล'
        : topCountryStats.first.country;
    final topCountryCount = topCountryStats.isEmpty
        ? 0
        : topCountryStats.first.count;

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
