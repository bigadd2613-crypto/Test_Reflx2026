// วิดเจ็ตพื้นหลังลายเส้นเคลื่อนไหวที่ใช้ตกแต่งหลายหน้าจอ
// ไม่มีปุ่ม UI โดยตรง เพราะทำหน้าที่แสดงผลพื้นหลังให้วิดเจ็ตลูก

import 'package:flutter/material.dart';

class AnimatedBackdrop extends StatefulWidget {
  // วิดเจ็ตพื้นหลังแบบ Stateful เพื่อเก็บสถานะและควบคุมแอนิเมชันของพื้นหลัง
  // หน้าต่าง ๆ เช่น AimTrainerScreen สามารถครอบเนื้อหาของตนเองด้วยวิดเจ็ตนี้ได้
  // เนื้อหาของหน้าจอผู้เรียก ซึ่งจะแสดงอยู่ด้านหน้าพื้นหลังที่วาดโดยคลาสนี้
  final Widget child;

  // รับเนื้อหาจากหน้าจออื่นและส่งต่อให้แสดงในชั้นบนของพื้นหลัง
  const AnimatedBackdrop({super.key, required this.child});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  // สร้าง State เพื่อให้วิดเจ็ตควบคุม AnimationController ได้ตลอดอายุการใช้งาน
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  // สร้างพื้นหลังและวาง child ของหน้าจอผู้เรียกไว้ด้านบน
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF080808), Color(0xFF1B1B1B), Color(0xFF050505)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    // วาดไล่สีเข้มเป็นพื้นฐานให้ทุกหน้าที่ใช้ AnimatedBackdrop มีธีมเดียวกัน
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _BackdropPainter(_controller.value),
        child: child,
      ),
      // ใช้ child เดิมเป็นเนื้อหาของหน้าจอ เช่น เกม Aim Trainer หรือหน้าอื่น
      child: widget.child,
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  final double progress;

  // CustomPainter สำหรับวาดเส้นทแยงและแสงเลื่อนบนพื้นหลังด้วย Canvas
  const _BackdropPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final drift = progress * 96;
    for (var x = -size.height + drift; x < size.width; x += 48) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    for (var y = -size.width + drift; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width), paint);
    }
    final light = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0x99FFFFFF), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 2));
    final lightX = (size.width + 240) * progress - 120;
    canvas.drawRect(Rect.fromLTWH(lightX, size.height * .28, 240, 2), light);
  }

  // สั่งให้ Flutter วาดพื้นหลังใหม่เฉพาะเมื่อ progress ของแอนิเมชันเปลี่ยน
  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
