// คลาสเชื่อมต่อฐานข้อมูลออนไลน์ผ่าน Supabase REST API
// ไม่มีปุ่ม UI โดยตรง เพราะทำหน้าที่อ่านและบันทึกข้อมูลให้หน้าจอต่าง ๆ

// ใช้แปลงข้อมูลระหว่างรูปแบบ JSON กับชนิดข้อมูลของ Dart
import 'dart:convert';

// ใช้ส่งคำขอ HTTP ไปยัง Supabase REST API
import 'package:http/http.dart' as http;

// คลาสตัวกลางสำหรับให้หน้าจอและบริการข้อมูลเรียกใช้ฐานข้อมูล Supabase
class CloudDatabase {
  // อ่าน URL ของโปรเจกต์ Supabase จากตัวแปรตอน build หรือ run แอป
  static const _url = String.fromEnvironment('SUPABASE_URL');
  // อ่านคีย์สาธารณะสำหรับยืนยันคำขอจากแอปไปยัง Supabase
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // ตรวจสอบว่ามีการตั้งค่าข้อมูลเชื่อมต่อ Supabase ครบทั้งสองค่า
  // หน้าจอหรือบริการอื่นสามารถใช้ค่านี้ตัดสินใจว่าจะอ่าน/บันทึกข้อมูลออนไลน์หรือไม่
  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  // สร้าง Header มาตรฐานที่แนบไปกับทุกคำขอ Supabase
  static Map<String, String> get _headers => {
    // ระบุคีย์ของโปรเจกต์ให้ Supabase ตรวจสอบคำขอ
    'apikey': _anonKey,
    // ส่งคีย์ในรูปแบบ Bearer Token สำหรับการยืนยันตัวตนของ REST API
    'Authorization': 'Bearer $_anonKey',
    // แจ้งว่าข้อมูลที่ส่งไปมีรูปแบบ JSON
    'Content-Type': 'application/json',
  };

  // สร้าง URL สำหรับเข้าถึงตารางที่ระบุใน Supabase REST API
  // query ใช้ส่งพารามิเตอร์ เช่น select หรือ on_conflict ไปกับ URL
  static Uri _table(String table, [Map<String, String>? query]) {
    // รวม URL โปรเจกต์กับเส้นทาง REST API และชื่อตาราง
    final base = '$_url/rest/v1/$table';
    // แปลง query parameters เป็นส่วนท้ายของ URL ที่ส่งไปยัง Supabase
    return Uri.parse(base).replace(queryParameters: query);
  }

  // อ่านข้อมูลทั้งหมดจากตารางที่ระบุ แล้วคืนค่าเป็นรายการ Map ให้ส่วนอื่นของระบบใช้
  static Future<List<Map<String, dynamic>>> select(String table) async {
    // ส่งคำขอ GET เพื่อขอข้อมูลทุกคอลัมน์จากตาราง
    final response = await http.get(
      _table(table, {'select': '*'}),
      headers: _headers,
    );
    // ตรวจสอบว่า Supabase ตอบกลับด้วยสถานะสำเร็จก่อนอ่านข้อมูล
    _ensureSuccess(response);
    // แปลงข้อความ JSON ที่ตอบกลับมาเป็นรายการข้อมูลของ Dart
    final decoded = jsonDecode(response.body);
    // แปลงแต่ละรายการให้เป็น Map<String, dynamic> แล้วคืนให้ผู้เรียก
    return (decoded as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // เพิ่มข้อมูลใหม่หรืออัปเดตข้อมูลเดิมในตารางตามคอลัมน์ที่กำหนดใน onConflict
  static Future<void> upsert(
    String table,
    Map<String, dynamic> values, {
    required String onConflict,
  }) async {
    // ส่งคำขอ POST พร้อมระบุคอลัมน์ที่ใช้ตรวจข้อมูลซ้ำ
    final response = await http.post(
      _table(table, {'on_conflict': onConflict}),
      headers: {
        // ใช้ Header มาตรฐานสำหรับการยืนยันตัวตนและชนิดข้อมูล
        ..._headers,
        // สั่งให้ Supabase รวมข้อมูลซ้ำและไม่ส่งข้อมูลแถวกลับมา
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      // แปลงข้อมูลจาก Map เป็น JSON ก่อนส่งไปยังฐานข้อมูล
      body: jsonEncode(values),
    );
    // ตรวจสอบว่าการเพิ่มหรืออัปเดตข้อมูลสำเร็จ
    _ensureSuccess(response);
  }

  // เพิ่มข้อมูลใหม่หนึ่งรายการลงในตารางที่ระบุ
  static Future<void> insert(String table, Map<String, dynamic> values) async {
    // ส่งคำขอ POST ไปยังตารางโดยใช้ Header มาตรฐานและไม่รับแถวข้อมูลกลับมา
    final response = await http.post(
      _table(table),
      headers: {..._headers, 'Prefer': 'return=minimal'},
      // แปลงข้อมูลที่จะบันทึกเป็น JSON
      body: jsonEncode(values),
    );
    // ตรวจสอบว่าการเพิ่มข้อมูลสำเร็จหรือไม่
    _ensureSuccess(response);
  }

  // ตรวจสอบรหัสสถานะ HTTP และแจ้งข้อผิดพลาดให้ส่วนที่เรียกใช้งานทราบ
  static void _ensureSuccess(http.Response response) {
    // สถานะ 200 ถึง 299 ถือว่าเป็นการตอบกลับที่สำเร็จ
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // หยุดการทำงานและส่งรหัสสถานะพร้อมรายละเอียดจาก Supabase
      throw StateError(
        'Cloud database error ${response.statusCode}: ${response.body}',
      );
    }
  }
}
