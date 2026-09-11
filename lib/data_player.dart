// โมเดลข้อมูลผู้เล่นและระบบบันทึก/โหลดโปรไฟล์ผู้เล่น
// ไม่มีปุ่ม UI โดยตรง เพราะถูกเรียกใช้โดยหน้า Login และ Scoreboard

// ใช้แปลงข้อมูลผู้เล่นระหว่าง JSON และชนิดข้อมูลของ Dart
import 'dart:convert';

// ใช้เก็บข้อมูลผู้เล่นในเครื่องเมื่อยังไม่ได้เชื่อม Supabase
import 'package:shared_preferences/shared_preferences.dart';

// ใช้ตรวจสอบสถานะฐานข้อมูลและส่งข้อมูลผู้เล่นไปยัง Supabase
import 'cloud_database.dart';

// โมเดลข้อมูลโปรไฟล์และคะแนนของผู้เล่นแต่ละคน
class PlayerData {
  // ชื่อผู้เล่น ใช้เป็นตัวระบุหลักของโปรไฟล์
  final String name;
  // คะแนนที่ดีที่สุดของเกม Time Reflex Test หน่วยมิลลิวินาที
  final int? reflexScore;
  // ความเร็วที่ดีที่สุดของ Aim Trainer หน่วยเป้าต่อวินาที
  final double? aimSpeed;
  // จำนวนเป้าที่ผู้เล่นยิงถูกในรอบ Aim Trainer ที่ดีที่สุด
  final int aimHits;
  // ระยะเวลาของรอบ Aim Trainer ที่ดีที่สุด หน่วยมิลลิวินาที
  final int aimTotalTime;
  // ความแม่นยำของรอบ Aim Trainer ที่ดีที่สุด
  final double? aimAccuracy;
  // วันเวลาที่สร้างโปรไฟล์
  final DateTime createdAt;
  // วันเวลาที่แก้ไขข้อมูลล่าสุด
  final DateTime updatedAt;

  // สร้างข้อมูลผู้เล่น โดยกำหนดค่าเริ่มต้นให้สถิติ Aim Trainer เป็นศูนย์
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

  // แปลงข้อมูล JSON จาก SharedPreferences ให้เป็น PlayerData
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

  // แปลง PlayerData เป็น Map เพื่อบันทึกเป็น JSON ในเครื่อง
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

// บริการกลางสำหรับโหลดและบันทึกโปรไฟล์ผู้เล่นกับคะแนนเกม
class PlayerProfileStore {
  // คีย์ที่ใช้เก็บรายการผู้เล่นใน SharedPreferences
  static const _key = 'player_data_db';

  // โหลดโปรไฟล์ทั้งหมดจาก Supabase หรือฐานข้อมูลภายในเครื่อง
  static Future<List<PlayerData>> loadData() async {
    // หากตั้งค่า Supabase แล้ว ให้อ่านข้อมูลจากตาราง players
    if (CloudDatabase.isConfigured) {
      final rows = await CloudDatabase.select('players');
      return rows.map(_fromCloud).toList();
    }
    // หากไม่มี Supabase ให้เปิดพื้นที่เก็บข้อมูลภายในเครื่อง
    final prefs = await SharedPreferences.getInstance();
    // อ่านข้อความ JSON ที่บันทึกไว้ด้วยคีย์ของระบบ
    final raw = prefs.getString(_key);
    // คืนรายการว่างเมื่อยังไม่มีผู้เล่นถูกบันทึก
    if (raw == null) return [];
    // แปลง JSON เป็นรายการ Map แล้วสร้างเป็น PlayerData แต่ละคน
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values.map(PlayerData.fromJson).toList();
  }

  // โหลดเฉพาะรายชื่อผู้เล่นสำหรับหน้า Login หรือรายการเลือกผู้เล่น
  static Future<List<String>> loadPlayers() async {
    // โหลดข้อมูลเต็มก่อน แล้วดึงเฉพาะชื่อออกมา
    final players = await loadData();
    return players.map((player) => player.name).toList();
  }

  // สร้างผู้เล่นใหม่หรืออัปเดตเวลาเข้าใช้งานของผู้เล่นเดิม
  static Future<void> savePlayer(String name) async {
    // โหลดข้อมูลเดิมเพื่อค้นหาผู้เล่นและรักษาคะแนนเดิมไว้
    final data = await loadData();
    // ใช้เวลาปัจจุบันเป็นเวลาแก้ไขข้อมูล
    final now = DateTime.now();
    // ค้นหาโดยไม่สนใจตัวพิมพ์เล็ก/ใหญ่ของชื่อ
    final existingIndex = data.indexWhere(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    // ถ้ามีผู้เล่นเดิม ให้ปรับเฉพาะ updatedAt และคงคะแนนเดิมไว้
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
      // ถ้าเป็นชื่อใหม่ ให้สร้างโปรไฟล์พร้อมเวลาสร้างและแก้ไข
      data.add(PlayerData(name: name, createdAt: now, updatedAt: now));
    }
    // บันทึกข้อมูลผู้เล่นไปยัง Supabase เมื่อระบบออนไลน์พร้อมใช้งาน
    if (CloudDatabase.isConfigured) {
      await CloudDatabase.upsert(
        'players',
        data[existingIndex >= 0 ? existingIndex : data.length - 1].toCloud(),
        onConflict: 'name',
      );
    } else {
      // มิฉะนั้นบันทึกข้อมูลทั้งหมดไว้ใน SharedPreferences
      await _saveData(data);
    }
  }

  // บันทึกคะแนน Time Reflex Test เฉพาะเมื่อเป็นคะแนนที่ใช้เวลาน้อยกว่าเดิม
  static Future<void> saveReflexScore({
    required String name,
    required int score,
  }) async {
    // ตรวจสอบให้แน่ใจว่ามีโปรไฟล์ของผู้เล่นก่อนอัปเดตคะแนน
    final data = await _ensurePlayer(name);
    // ค้นหาตำแหน่งข้อมูลผู้เล่นในรายการ
    final index = data.indexWhere(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    // อ่านข้อมูลเดิมเพื่อคงคะแนนและสถิติของโหมดอื่นไว้
    final player = data[index];
    // เก็บคะแนนใหม่เมื่อยังไม่มีคะแนนเดิม หรือคะแนนใหม่ใช้เวลาน้อยกว่า
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
    // ใช้ Supabase หรือ SharedPreferences ตามการตั้งค่าระบบ
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

  // บันทึกคะแนน Aim Trainer เฉพาะเมื่อความเร็วใหม่สูงกว่าสถิติเดิม
  static Future<void> saveAimScore({
    required String name,
    required double speed,
    required int hits,
    required int totalTime,
    required double accuracy,
  }) async {
    // สร้างโปรไฟล์ให้ผู้เล่นก่อนบันทึกคะแนน หากยังไม่มีข้อมูล
    final data = await _ensurePlayer(name);
    final index = data.indexWhere(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    // อ่านข้อมูลเดิมเพื่อคงคะแนน Time Reflex Test ไว้
    final player = data[index];
    // ถ้าความเร็วเดิมดีกว่าหรือเท่ากับคะแนนใหม่ ไม่ต้องบันทึกทับ
    if (player.aimSpeed != null && player.aimSpeed! >= speed) return;
    // รวมคะแนน Aim Trainer ใหม่กับข้อมูลโปรไฟล์เดิม
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
    // บันทึกไปยังฐานข้อมูลออนไลน์เมื่อ Supabase ถูกตั้งค่า
    if (CloudDatabase.isConfigured) {
      await CloudDatabase.upsert(
        'players',
        data[index].toCloud(),
        onConflict: 'name',
      );
    } else {
      // บันทึกลงเครื่องเมื่อยังไม่ได้เชื่อมต่อ Supabase
      await _saveData(data);
    }
  }

  // ตรวจว่าผู้เล่นมีอยู่ในรายการหรือไม่ และเพิ่มโปรไฟล์ใหม่ถ้ายังไม่มี
  static Future<List<PlayerData>> _ensurePlayer(String name) async {
    // โหลดโปรไฟล์ปัจจุบันก่อนตรวจสอบชื่อ
    final data = await loadData();
    final exists = data.any(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    // ถ้าไม่พบชื่อ ให้เพิ่มโปรไฟล์เปล่าสำหรับรอรับคะแนน
    if (!exists) {
      final now = DateTime.now();
      data.add(PlayerData(name: name, createdAt: now, updatedAt: now));
    }
    return data;
  }

  // แปลงรายการผู้เล่นทั้งหมดเป็น JSON แล้วบันทึกลง SharedPreferences
  static Future<void> _saveData(List<PlayerData> data) async {
    // เปิดพื้นที่จัดเก็บข้อมูลภายในเครื่อง
    final prefs = await SharedPreferences.getInstance();
    // แปลง PlayerData ทุกคนเป็น JSON และเขียนทับข้อมูลเดิม
    await prefs.setString(
      _key,
      jsonEncode(data.map((player) => player.toJson()).toList()),
    );
  }

  // แปลงชื่อคอลัมน์แบบ snake_case จาก Supabase เป็น PlayerData
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

// ส่วนขยายสำหรับแปลง PlayerData เป็นชื่อคอลัมน์ที่ตาราง Supabase ใช้
extension on PlayerData {
  // สร้าง Map สำหรับส่งข้อมูลผู้เล่นไปยัง CloudDatabase.upsert
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
