import 'package:flutter/material.dart';

class AnimatedBackdrop extends StatefulWidget {
  final Widget child;

  const AnimatedBackdrop({super.key, required this.child});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF080808), Color(0xFF1B1B1B), Color(0xFF050505)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _BackdropPainter(_controller.value),
        child: child,
      ),
      child: widget.child,
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  final double progress;

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

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
