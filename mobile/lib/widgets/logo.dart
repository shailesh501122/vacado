import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Vacado pin-drop logo mark.
class VacadoMark extends StatelessWidget {
  final double size;
  final Color color;
  const VacadoMark({super.key, this.size = 40, this.color = VTokens.green});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(color: color),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(w * .5, h * .1)
      ..cubicTo(w * .15, h * .1, w * .12, h * .55, w * .42, h * .82)
      ..lineTo(w * .5, h * .92)
      ..lineTo(w * .58, h * .82)
      ..cubicTo(w * .88, h * .55, w * .85, h * .1, w * .5, h * .1)
      ..close();
    canvas.drawPath(path, paint);

    final inner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * .5, h * .4), w * .09, inner);

    final stem = Paint()
      ..color = Colors.white
      ..strokeWidth = w * .04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final stemPath = Path()
      ..moveTo(w * .55, h * .35)
      ..cubicTo(w * .55, h * .28, w * .62, h * .25, w * .68, h * .25);
    canvas.drawPath(stemPath, stem);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
