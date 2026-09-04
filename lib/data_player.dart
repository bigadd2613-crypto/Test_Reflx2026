import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_database.dart';

class PlayerData {
  final String name;
  final int? reflexScore;
  final double? aimSpeed;
  final int aimHits;
  final int aimTotalTime;
  final double? aimAccuracy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlayerData({
    required this.name,
    this.reflexScore,
    this.aimSpeed,
    this.aimHits = 0,
    this.aimTotalTime = 0,
    this.aimAccuracy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
    name: json['name'] as String,
    reflexScore: (json['reflexScore'] as num?)?.toInt(),
    aimSpeed: (json['aimSpeed'] as num?)?.toDouble(),
    aimHits: (json['aimHits'] as num?)?.toInt() ?? 0,
    aimTotalTime: (json['aimTotalTime'] as num?)?.toInt() ?? 0,
    aimAccuracy: (json['aimAccuracy'] as num?)?.toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'reflexScore': reflexScore,
    'aimSpeed': aimSpeed,
    'aimHits': aimHits,
    'aimTotalTime': aimTotalTime,
    'aimAccuracy': aimAccuracy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class PlayerProfileStore {
  static const _key = 'player_data_db';

  static Future<List<PlayerData>> loadData() async {
    if (CloudDatabase.isConfigured) {
      final rows = await CloudDatabase.select('players');
      return rows.map(_fromCloud).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values.map(PlayerData.fromJson).toList();
  }

  static Future<List<String>> loadPlayers() async {
    final players = await loadData();
    return players.map((player) => player.name).toList();
  }

  static Future<void> savePlayer(String name) async {
    final data = await loadData();
    final now = DateTime.now();
    final existingIndex = data.indexWhere(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    if (existingIndex >= 0) {
      data[existingIndex] = PlayerData(
        name: data[existingIndex].name,
        reflexScore: data[existingIndex].reflexScore,
        aimSpeed: data[existingIndex].aimSpeed,
        aimHits: data[existingIndex].aimHits,
        aimTotalTime: data[existingIndex].aimTotalTime,
        aimAccuracy: data[existingIndex].aimAccuracy,
        createdAt: data[existingIndex].createdAt,
        updatedAt: now,
      );
    } else {
      data.add(PlayerData(name: name, createdAt: now, updatedAt: now));
    }
    if (CloudDatabase.isConfigured) {
      await CloudDatabase.upsert(
        'players',
        data[existingIndex >= 0 ? existingIndex : data.length - 1].toCloud(),
        onConflict: 'name',
      );
    } else {
      await _saveData(data);
    }
  }

  static Future<void> saveReflexScore({
    required String name,
    required int score,
  }) async {
    final data = await _ensurePlayer(name);
    final index = data.indexWhere(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    final player = data[index];
    data[index] = PlayerData(
      name: player.name,
      reflexScore: player.reflexScore == null || score < player.reflexScore!
          ? score
          : player.reflexScore,
      aimSpeed: player.aimSpeed,
      aimHits: player.aimHits,
      aimTotalTime: player.aimTotalTime,
      aimAccuracy: player.aimAccuracy,
      createdAt: player.createdAt,
      updatedAt: DateTime.now(),
    );
    if (CloudDatabase.isConfigured) {
      await CloudDatabase.upsert(
        'players',
        data[index].toCloud(),
        onConflict: 'name',
      );
    } else {
      await _saveData(data);
    }
  }

  static Future<void> saveAimScore({
    required String name,
    required double speed,
    required int hits,
    required int totalTime,
    required double accuracy,
  }) async {
    final data = await _ensurePlayer(name);
    final index = data.indexWhere(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    final player = data[index];
    if (player.aimSpeed != null && player.aimSpeed! >= speed) return;
    data[index] = PlayerData(
      name: player.name,
      reflexScore: player.reflexScore,
      aimSpeed: speed,
      aimHits: hits,
      aimTotalTime: totalTime,
      aimAccuracy: accuracy,
      createdAt: player.createdAt,
      updatedAt: DateTime.now(),
    );
    if (CloudDatabase.isConfigured) {
      await CloudDatabase.upsert(
        'players',
        data[index].toCloud(),
        onConflict: 'name',
      );
    } else {
      await _saveData(data);
    }
  }

  static Future<List<PlayerData>> _ensurePlayer(String name) async {
    final data = await loadData();
    final exists = data.any(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) {
      final now = DateTime.now();
      data.add(PlayerData(name: name, createdAt: now, updatedAt: now));
    }
    return data;
  }

  static Future<void> _saveData(List<PlayerData> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(data.map((player) => player.toJson()).toList()),
    );
  }

  static PlayerData _fromCloud(Map<String, dynamic> row) => PlayerData(
    name: row['name'] as String,
    reflexScore: (row['reflex_score'] as num?)?.toInt(),
    aimSpeed: (row['aim_speed'] as num?)?.toDouble(),
    aimHits: (row['aim_hits'] as num?)?.toInt() ?? 0,
    aimTotalTime: (row['aim_total_time'] as num?)?.toInt() ?? 0,
    aimAccuracy: (row['aim_accuracy'] as num?)?.toDouble(),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );
}

extension on PlayerData {
  Map<String, dynamic> toCloud() => {
    'name': name,
    'reflex_score': reflexScore,
    'aim_speed': aimSpeed,
    'aim_hits': aimHits,
    'aim_total_time': aimTotalTime,
    'aim_accuracy': aimAccuracy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
