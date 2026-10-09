import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// The Shatranj piece set - hand-drawn vector silhouettes in ivory-and-jet
/// with gold rims. No font dependence, no emoji, identical everywhere.
class ChessPiecePainter extends CustomPainter {
  final String piece;
  ChessPiecePainter(this.piece);

  bool get _white => piece == piece.toUpperCase();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.save();
    canvas.translate(w / 2, h * 0.02);
    final bw = w * 0.78;
    final kind = piece.toUpperCase();

    final body = Path();
    switch (kind) {
      case 'P':
        _ball(canvas, body, bw, h, cy: h * 0.19, r: bw * 0.26);
        _stem(body, bw * 0.17, h * 0.24, h * 0.60);
        _base(body, bw, h * 0.64, h * 0.86);
        _fill(canvas, body);
      case 'R':
        _crenels(body, bw, h * 0.05, h * 0.22);
        _stem(body, bw * 0.48, h * 0.24, h * 0.60);
        _base(body, bw, h * 0.64, h * 0.86);
        _fill(canvas, body);
      case 'N':
        _knight(canvas, body, bw, h);
      case 'B':
        body.moveTo(-bw * 0.30, h * 0.26);
        body.quadraticBezierTo(-bw * 0.42, h * 0.10, 0, h * 0.05);
        body.quadraticBezierTo(bw * 0.42, h * 0.10, bw * 0.30, h * 0.26);
        body.quadraticBezierTo(bw * 0.15, h * 0.34, 0, h * 0.34);
        body.quadraticBezierTo(-bw * 0.15, h * 0.34, -bw * 0.30, h * 0.26);
        _fill(canvas, body);
        _stem(body, bw * 0.15, h * 0.36, h * 0.60);
        _base(body, bw, h * 0.64, h * 0.86);
        _fill(canvas, body);
        _ball(canvas, Path(), bw, h, cy: h * 0.185, r: bw * 0.06, jewel: true);
      case 'Q':
        _crown(body, bw, h * 0.09, h * 0.26, points: 5);
        _fill(canvas, body);
        _stem(body, bw * 0.20, h * 0.30, h * 0.60);
        _base(body, bw, h * 0.64, h * 0.86);
        _fill(canvas, body);
        _ball(canvas, Path(), bw, h, cy: h * 0.065, r: bw * 0.055, jewel: true);
      case 'K':
        _crown(body, bw, h * 0.12, h * 0.26, points: 3);
        _fill(canvas, body);
        _stem(body, bw * 0.22, h * 0.30, h * 0.60);
        _base(body, bw, h * 0.64, h * 0.86);
        _fill(canvas, body);
        final cross = Path()
          ..addRect(Rect.fromCenter(center: Offset(0, h * 0.07), width: bw * 0.06, height: h * 0.13))
          ..addRect(Rect.fromCenter(center: Offset(0, h * 0.07), width: bw * 0.17, height: h * 0.045));
        _fill(canvas, cross, jewel: true);
    }
    canvas.restore();
  }

  void _ball(Canvas canvas, Path p, double bw, double h,
      {required double cy, required double r, bool jewel = false}) {
    if (p.getBounds().isEmpty) {
      p = Path()..addOval(Rect.fromCircle(center: Offset(0, cy), radius: r));
    }
    _fill(canvas, p, jewel: jewel);
  }

  void _stem(Path p, double width, double y0, double y1) {
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2, y0, width, y1 - y0), const Radius.circular(4)));
  }

  void _base(Path p, double bw, double y0, double y1) {
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-bw * 0.42, y0, bw * 0.84, (y1 - y0) * 0.42),
        const Radius.circular(6)));
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-bw * 0.50, y0 + (y1 - y0) * 0.38, bw, (y1 - y0) * 0.62),
        const Radius.circular(8)));
  }

  void _crenels(Path p, double bw, double y0, double y1) {
    final seg = bw * 0.84 / 7;
    p.moveTo(-bw * 0.42, y1);
    p.lineTo(-bw * 0.42, y0 + (y1 - y0) * 0.42);
    for (var i = 0; i < 7; i++) {
      if (i.isEven) {
        p.lineTo(-bw * 0.42 + seg * i, y0 + (y1 - y0) * 0.42);
        p.lineTo(-bw * 0.42 + seg * i, y0);
        p.lineTo(-bw * 0.42 + seg * (i + 1), y0);
        p.lineTo(-bw * 0.42 + seg * (i + 1), y0 + (y1 - y0) * 0.42);
      } else {
        p.lineTo(-bw * 0.42 + seg * (i + 1), y0 + (y1 - y0) * 0.42);
      }
    }
    p.lineTo(bw * 0.42, y1);
    p.close();
  }

  void _crown(Path p, double bw, double y0, double y1, {int points = 5}) {
    final mid = y0 + (y1 - y0) * 0.6, bot = y1;
    final half = bw * 0.44;
    p.moveTo(-half, bot);
    p.lineTo(-half * 0.97, mid);
    final step = (half * 2) / points;
    for (var i = 0; i < points; i++) {
      p.lineTo(-half + step * i + step / 2, y0);
      p.lineTo(-half + step * (i + 1), mid);
    }
    p.lineTo(half, bot);
    p.close();
  }

  void _knight(Canvas canvas, Path p, double bw, double h) {
    p.moveTo(-bw * 0.34, h * 0.30);
    p.quadraticBezierTo(-bw * 0.52, h * 0.24, -bw * 0.40, h * 0.10);
    p.quadraticBezierTo(-bw * 0.34, h * 0.03, -bw * 0.18, h * 0.05);
    p.lineTo(-bw * 0.10, -h * 0.01);
    p.lineTo(-bw * 0.02, h * 0.05);
    p.quadraticBezierTo(bw * 0.30, h * 0.06, bw * 0.34, h * 0.28);
    p.quadraticBezierTo(bw * 0.40, h * 0.52, bw * 0.30, h * 0.60);
    p.lineTo(bw * 0.12, h * 0.60);
    p.quadraticBezierTo(-bw * 0.20, h * 0.55, -bw * 0.34, h * 0.30);
    p.close();
    _fill(canvas, p);
    final mane = Path()
      ..moveTo(bw * 0.28, h * 0.26)
      ..quadraticBezierTo(bw * 0.47, h * 0.36, bw * 0.35, h * 0.56)
      ..quadraticBezierTo(bw * 0.27, h * 0.50, bw * 0.25, h * 0.40)
      ..close();
    _fill(canvas, mane);
    final base = Path();
    _base(base, bw, h * 0.62, h * 0.86);
    _fill(canvas, base);
  }

  void _fill(Canvas canvas, Path p, {bool jewel = false}) {
    if (p.getBounds().isEmpty) return;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: jewel
            ? [const Color(0xFFE8C96A), const Color(0xFFB08D2E)]
            : _white
                ? [const Color(0xFFFBF3DC), const Color(0xFFD9C89A)]
                : [const Color(0xFF2A2416), const Color(0xFF0D0B06)],
      ).createShader(p.getBounds());
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.gold.withValues(alpha: 0.85);
    canvas.drawShadow(p, Colors.black.withValues(alpha: 0.6), 2.2, true);
    canvas.drawPath(p, fill);
    canvas.drawPath(p, rim);
  }

  @override
  bool shouldRepaint(covariant ChessPiecePainter old) => old.piece != piece;
}
