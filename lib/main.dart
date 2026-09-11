// จุดเริ่มต้นของแอปและการตั้งค่า Theme ของ Flutter
// แสดงหน้า LoginScreen เป็นหน้าแรก จึงไม่มีปุ่ม UI โดยตรงในไฟล์นี้

// นำเข้าเครื่องมือ Material ของ Flutter สำหรับสร้างแอปและกำหนด Theme
import 'package:flutter/material.dart';

// เชื่อมหน้า Login ซึ่งเป็นหน้าแรกที่ผู้ใช้เห็นเมื่อเปิดแอป
import 'login_screen.dart';

// ฟังก์ชันเริ่มต้นของโปรแกรม Dart ที่ถูกเรียกเมื่อเปิดแอป
void main() {
  // สร้างและติดตั้งวิดเจ็ตหลักของแอปลงบนหน้าจอ Flutter
  runApp(const MyApp());
}

// วิดเจ็ตหลักแบบ Stateless สำหรับกำหนดโครงสร้างระดับแอป
class MyApp extends StatelessWidget {
  // สร้างวิดเจ็ตแอปโดยไม่มีสถานะภายใน
  const MyApp({super.key});

  // สร้าง MaterialApp และกำหนดการตั้งค่ากลางให้ทุกหน้าจอใช้ร่วมกัน
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ชื่อแอปที่ใช้เป็นข้อมูลระบุตัวแอปของระบบ Flutter
      title: 'Time Test',
      // ซ่อนป้าย DEBUG มุมขวาบนของแอป
      debugShowCheckedModeBanner: false,
      // กำหนดสีและรูปแบบกลางที่หน้าจอ Login และหน้าจอเกมนำไปใช้ต่อ
      theme: ThemeData(
        // เปิดใช้ Material 3 สำหรับวิดเจ็ตและรูปแบบปุ่มรุ่นใหม่
        useMaterial3: true,
        // กำหนดสีพื้นหลังเริ่มต้นของ Scaffold ในทุกหน้า
        scaffoldBackgroundColor: const Color(0xFF07090B),
        // สร้างชุดสีแบบโหมดมืดจากสีหลักของระบบ
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C9BFF),
          brightness: Brightness.dark,
        ),
        // กำหนดรูปแบบ AppBar กลางให้โปร่งใสและไม่มีเงา
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      // กำหนด LoginScreen เป็นหน้าแรกและจุดเริ่มต้นของเส้นทางในระบบ
      home: const LoginScreen(),
    );
  }
}
