// โมเดลและระบบจัดเก็บคะแนนของ Time Reflex กับ Aim Trainer
// ไม่มีปุ่ม UI โดยตรง เพราะหน้าจอเกมเป็นผู้เรียกใช้ระบบนี้

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum SelectedMode { timeReflex, aimTrainer }

class AimStats {
  final int hits;
  final int misses;
  final int totalTime;

  const AimStats({this.hits = 0, this.misses = 0, this.totalTime = 0});

  double get accuracy {
    final attempts = hits + misses;
    return attempts == 0 ? 0 : hits / attempts * 100;
  }

  double get speed {
    final seconds = totalTime / 1000;
    return seconds <= 0 ? 0 : hits / seconds;
  }
}

class ScoreEntry {
  final String id;
  final String name;
  final int bestScore;
  final DateTime timestamp;

  const ScoreEntry({
    required this.id,
    required this.name,
    required this.bestScore,
    required this.timestamp,
  });

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    bestScore: json['bestScore'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bestScore': bestScore,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ScoreboardStore {
  static const _key = 'reflex_scores_db';

  static Future<List<ScoreEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values.map(ScoreEntry.fromJson).toList();
  }

  static Future<void> saveScore({
    required String id,
    required String name,
    required int score,
  }) async {
    final entries = await load();
    final index = entries.indexWhere(
      (entry) => entry.id.toLowerCase() == id.toLowerCase(),
    );
    final entry = ScoreEntry(
      id: id,
      name: name,
      bestScore: index >= 0 && entries[index].bestScore < score
          ? entries[index].bestScore
          : score,
      timestamp: DateTime.now(),
    );
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

class AimScoreEntry {
  final String id;
  final String name;
  final double bestScore;
  final int hits;
  final int totalTime;
  final double accuracy;
  final DateTime timestamp;

  const AimScoreEntry({
    required this.id,
    required this.name,
    required this.bestScore,
    required this.hits,
    required this.totalTime,
    required this.accuracy,
    required this.timestamp,
  });

  factory AimScoreEntry.fromJson(Map<String, dynamic> json) => AimScoreEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    bestScore: (json['bestScore'] as num).toDouble(),
    hits: (json['hits'] as num).toInt(),
    totalTime: (json['totalTime'] as num).toInt(),
    accuracy: (json['accuracy'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bestScore': bestScore,
    'hits': hits,
    'totalTime': totalTime,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AimScoreboardStore {
  static const _key = 'aim_scores_db';

  static Future<List<AimScoreEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values.map(AimScoreEntry.fromJson).toList();
  }

  static Future<void> saveScore({
    required String id,
    required String name,
    required double speed,
    required int hits,
    required int totalTime,
    required double accuracy,
  }) async {
    final entries = await load();
    final index = entries.indexWhere(
      (entry) => entry.id.toLowerCase() == id.toLowerCase(),
    );
    final best = index >= 0 && entries[index].bestScore > speed
        ? entries[index]
        : AimScoreEntry(
            id: id,
            name: name,
            bestScore: speed,
            hits: hits,
            totalTime: totalTime,
            accuracy: accuracy,
            timestamp: DateTime.now(),
          );
    if (index >= 0) {
      entries[index] = best;
    } else {
      entries.add(best);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
