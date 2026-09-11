// โมเดลและระบบจัดเก็บคะแนนของ Time Reflex กับ Aim Trainer
// ไม่มีปุ่ม UI โดยตรง เพราะหน้าจอเกมเป็นผู้เรียกใช้ระบบนี้

// ใช้แปลงข้อมูลคะแนนระหว่าง JSON และชนิดข้อมูลของ Dart
import 'dart:convert';

// ใช้เก็บคะแนนของผู้เล่นไว้ในอุปกรณ์
import 'package:shared_preferences/shared_preferences.dart';

// ตัวเลือกโหมดเกมที่หน้า ModeSelectionScreen ใช้สร้างหน้าจอที่เลือก
enum SelectedMode { timeReflex, aimTrainer }

// สถิติระหว่างเล่น Aim Trainer สำหรับคำนวณความแม่นยำและความเร็ว
class AimStats {
  // จำนวนครั้งที่ยิงเป้าถูก
  final int hits;
  // จำนวนครั้งที่ยิงพลาดหรือปล่อยเป้าหมดอายุ
  final int misses;
  // ระยะเวลาเล่นรวม หน่วยมิลลิวินาที
  final int totalTime;

  // สร้างสถิติพร้อมค่าเริ่มต้นเป็นศูนย์สำหรับรอบใหม่
  const AimStats({this.hits = 0, this.misses = 0, this.totalTime = 0});

  // คำนวณเปอร์เซ็นต์ความแม่นยำจากจำนวนครั้งที่ถูกเทียบกับการพยายามทั้งหมด
  double get accuracy {
    // รวมจำนวนครั้งที่ยิงถูกและพลาด
    final attempts = hits + misses;
    // ถ้ายังไม่มีการยิง ให้คืนค่า 0 เพื่อป้องกันการหารด้วยศูนย์
    return attempts == 0 ? 0 : hits / attempts * 100;
  }

  // คำนวณความเร็วเป็นจำนวนเป้าต่อวินาที
  double get speed {
    // แปลงเวลาจากมิลลิวินาทีเป็นวินาที
    final seconds = totalTime / 1000;
    // ถ้าเวลาไม่ถูกต้องหรือยังไม่เริ่ม ให้คืนค่า 0
    return seconds <= 0 ? 0 : hits / seconds;
  }
}

// โมเดลคะแนนสูงสุดของเกม Time Reflex Test
class ScoreEntry {
  // รหัสผู้เล่นที่ใช้ค้นหาและป้องกันข้อมูลซ้ำ
  final String id;
  // ชื่อที่แสดงบน Scoreboard
  final String name;
  // เวลาที่ดีที่สุด หน่วยมิลลิวินาที โดยค่าน้อยกว่าดีกว่า
  final int bestScore;
  // เวลาที่บันทึกหรืออัปเดตคะแนนล่าสุด
  final DateTime timestamp;

  // สร้างข้อมูลคะแนนของผู้เล่นหนึ่งรายการ
  const ScoreEntry({
    required this.id,
    required this.name,
    required this.bestScore,
    required this.timestamp,
  });

  // แปลง JSON จาก SharedPreferences กลับเป็น ScoreEntry
  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    bestScore: json['bestScore'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  // แปลง ScoreEntry เป็น Map เพื่อบันทึกลง JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bestScore': bestScore,
    'timestamp': timestamp.toIso8601String(),
  };
}

// บริการจัดเก็บคะแนนของเกม Time Reflex Test
class ScoreboardStore {
  // คีย์ที่ใช้เก็บคะแนนใน SharedPreferences
  static const _key = 'reflex_scores_db';

  // โหลดคะแนน Time Reflex Test ทั้งหมดจากอุปกรณ์
  static Future<List<ScoreEntry>> load() async {
    // เปิดพื้นที่จัดเก็บข้อมูลในเครื่อง
    final prefs = await SharedPreferences.getInstance();
    // อ่านข้อความ JSON ของรายการคะแนน
    final raw = prefs.getString(_key);
    // คืนรายการว่างหากยังไม่มีข้อมูลคะแนน
    if (raw == null) return [];
    // แปลง JSON เป็น ScoreEntry เพื่อให้ Scoreboard ใช้งานได้
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values.map(ScoreEntry.fromJson).toList();
  }

  // เพิ่มหรืออัปเดตคะแนน Time Reflex Test ของผู้เล่น
  static Future<void> saveScore({
    required String id,
    required String name,
    required int score,
  }) async {
    // โหลดคะแนนเดิมเพื่อเปรียบเทียบกับคะแนนใหม่
    final entries = await load();
    // ค้นหาคะแนนเดิมโดยไม่สนใจตัวพิมพ์เล็ก/ใหญ่ของ ID
    final index = entries.indexWhere(
      (entry) => entry.id.toLowerCase() == id.toLowerCase(),
    );
    // เก็บคะแนนที่ใช้เวลาน้อยกว่า เพราะ Time Reflex ค่าน้อยกว่าดีกว่า
    final entry = ScoreEntry(
      id: id,
      name: name,
      bestScore: index >= 0 && entries[index].bestScore < score
          ? entries[index].bestScore
          : score,
      timestamp: DateTime.now(),
    );
    // แทนที่ข้อมูลเดิมหรือเพิ่มผู้เล่นใหม่ลงรายการ
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    // เปิดพื้นที่จัดเก็บก่อนเขียนคะแนนทั้งหมดกลับเป็น JSON
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}

// โมเดลคะแนนสูงสุดของเกม Aim Trainer
class AimScoreEntry {
  // รหัสผู้เล่นสำหรับค้นหาและป้องกันรายการซ้ำ
  final String id;
  // ชื่อผู้เล่นที่แสดงใน Scoreboard
  final String name;
  // ความเร็วที่ดีที่สุด หน่วยเป้าต่อวินาที โดยค่ามากกว่าดีกว่า
  final double bestScore;
  // จำนวนเป้าที่ยิงถูกในรอบที่บันทึก
  final int hits;
  // เวลาเล่นรวมของรอบที่บันทึก หน่วยมิลลิวินาที
  final int totalTime;
  // เปอร์เซ็นต์ความแม่นยำของรอบที่บันทึก
  final double accuracy;
  // เวลาที่บันทึกหรืออัปเดตคะแนนล่าสุด
  final DateTime timestamp;

  // สร้างข้อมูลคะแนน Aim Trainer หนึ่งรายการ
  const AimScoreEntry({
    required this.id,
    required this.name,
    required this.bestScore,
    required this.hits,
    required this.totalTime,
    required this.accuracy,
    required this.timestamp,
  });

  // แปลง JSON จาก SharedPreferences กลับเป็น AimScoreEntry
  factory AimScoreEntry.fromJson(Map<String, dynamic> json) => AimScoreEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    bestScore: (json['bestScore'] as num).toDouble(),
    hits: (json['hits'] as num).toInt(),
    totalTime: (json['totalTime'] as num).toInt(),
    accuracy: (json['accuracy'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  // แปลง AimScoreEntry เป็น Map เพื่อบันทึกลง JSON
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

// บริการจัดเก็บคะแนนของเกม Aim Trainer
class AimScoreboardStore {
  // คีย์ที่ใช้เก็บคะแนน Aim Trainer ใน SharedPreferences
  static const _key = 'aim_scores_db';

  // โหลดคะแนน Aim Trainer ทั้งหมดจากอุปกรณ์
  static Future<List<AimScoreEntry>> load() async {
    // เปิดพื้นที่จัดเก็บข้อมูลในเครื่อง
    final prefs = await SharedPreferences.getInstance();
    // อ่านข้อความ JSON ของรายการคะแนน
    final raw = prefs.getString(_key);
    // คืนรายการว่างหากยังไม่มีข้อมูลคะแนน
    if (raw == null) return [];
    // แปลง JSON เป็น AimScoreEntry เพื่อใช้ใน Scoreboard และ Login
    final values = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return values.map(AimScoreEntry.fromJson).toList();
  }

  // เพิ่มหรืออัปเดตคะแนน Aim Trainer ของผู้เล่น
  static Future<void> saveScore({
    required String id,
    required String name,
    required double speed,
    required int hits,
    required int totalTime,
    required double accuracy,
  }) async {
    // โหลดคะแนนเดิมเพื่อเปรียบเทียบกับความเร็วใหม่
    final entries = await load();
    // ค้นหาคะแนนเดิมโดยไม่สนใจตัวพิมพ์เล็ก/ใหญ่ของ ID
    final index = entries.indexWhere(
      (entry) => entry.id.toLowerCase() == id.toLowerCase(),
    );
    // เก็บคะแนนที่ความเร็วสูงกว่า เพราะ Aim Trainer ค่าสูงกว่าดีกว่า
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
    // แทนที่ข้อมูลเดิมหรือเพิ่มรายการของผู้เล่นใหม่
    if (index >= 0) {
      entries[index] = best;
    } else {
      entries.add(best);
    }
    // เปิดพื้นที่จัดเก็บก่อนเขียนคะแนนทั้งหมดเป็น JSON
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
