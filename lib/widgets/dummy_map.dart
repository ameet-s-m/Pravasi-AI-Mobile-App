// lib/widgets/dummy_map.dart
import 'package:flutter/material.dart';

class DummyMap extends StatelessWidget {
  final int lines;
  const DummyMap({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DummyMapPainter(lines),
      size: Size.infinite,
    );
  }
}

class _DummyMapPainter extends CustomPainter {
  final int lines;
  _DummyMapPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final paints = [
      Paint()..color = Colors.red..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
      Paint()..color = Colors.green..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
      Paint()..color = Colors.blue..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    ];

    final w = size.width;
    final h = size.height;

    final paths = <Path>[
      Path()..moveTo(0, h * 0.75)..quadraticBezierTo(w * 0.25, h * 0.5, w * 0.5, h * 0.8)..quadraticBezierTo(w * 0.75, h * 1.05, w, h * 0.7),
      Path()..moveTo(0, h * 0.5)..quadraticBezierTo(w * 0.2, h * 0.3, w * 0.45, h * 0.45)..quadraticBezierTo(w * 0.7, h * 0.6, w, h * 0.4),
      Path()..moveTo(0, h * 0.25)..quadraticBezierTo(w * 0.3, h * 0.45, w * 0.6, h * 0.2)..quadraticBezierTo(w * 0.8, h * 0.05, w, h * 0.25),
    ];

    for (var i = 0; i < lines && i < paints.length; i++) {
      canvas.drawPath(paths[i], paints[i]);
    }

    final nodePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final x = w * (i / 4);
      final y = h * (0.2 + (i % 2) * 0.5 * 0.9);
      canvas.drawCircle(Offset(x, y), 4, paints[i % paints.length]);
      canvas.drawCircle(Offset(x + 10, y - 6), 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}