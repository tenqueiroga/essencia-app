import 'package:flutter/material.dart';
import '../../app/theme/olfato_tokens.dart';

class PerfumePyramid extends StatelessWidget {
  final List<dynamic> topNotes;
  final List<dynamic> heartNotes;
  final List<dynamic> baseNotes;

  const PerfumePyramid({
    super.key,
    required this.topNotes,
    required this.heartNotes,
    required this.baseNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Visual pyramid shape
        CustomPaint(
          size: const Size(double.infinity, 200),
          painter: _PyramidPainter(),
          child: SizedBox(
            height: 200,
            child: Column(
              children: [
                // Top - smallest section
                Expanded(
                  flex: 2,
                  child: _PyramidSection(
                    label: 'TOPO',
                    notes: topNotes.take(4).toList(),
                    color: const Color(0xFFFFD700),
                    alignment: Alignment.center,
                  ),
                ),
                // Heart - medium section
                Expanded(
                  flex: 3,
                  child: _PyramidSection(
                    label: 'CORAÇÃO',
                    notes: heartNotes.take(5).toList(),
                    color: const Color(0xFFFF69B4),
                    alignment: Alignment.center,
                  ),
                ),
                // Base - largest section
                Expanded(
                  flex: 3,
                  child: _PyramidSection(
                    label: 'BASE',
                    notes: baseNotes.take(4).toList(),
                    color: const Color(0xFF8B6914),
                    alignment: Alignment.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PyramidSection extends StatelessWidget {
  final String label;
  final List<dynamic> notes;
  final Color color;
  final Alignment alignment;

  const _PyramidSection({
    required this.label,
    required this.notes,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 3),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: notes.map<Widget>((n) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                n.toString(),
                style: TextStyle(fontSize: 10, color: color),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _PyramidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top triangle - gold
    paint.color = const Color(0xFFFFD700).withValues(alpha: 0.06);
    final topPath = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.3, size.height * 0.25)
      ..lineTo(size.width * 0.7, size.height * 0.25)
      ..close();
    canvas.drawPath(topPath, paint);

    // Heart trapezoid - pink
    paint.color = const Color(0xFFFF69B4).withValues(alpha: 0.06);
    final heartPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.25)
      ..lineTo(size.width * 0.15, size.height * 0.62)
      ..lineTo(size.width * 0.85, size.height * 0.62)
      ..lineTo(size.width * 0.7, size.height * 0.25)
      ..close();
    canvas.drawPath(heartPath, paint);

    // Base trapezoid - brown
    paint.color = const Color(0xFF8B6914).withValues(alpha: 0.06);
    final basePath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.62)
      ..lineTo(size.width * 0.05, size.height)
      ..lineTo(size.width * 0.95, size.height)
      ..lineTo(size.width * 0.85, size.height * 0.62)
      ..close();
    canvas.drawPath(basePath, paint);

    // Border lines
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = OlfatoTokens.borderLight;

    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.25),
      Offset(size.width * 0.7, size.height * 0.25),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.62),
      Offset(size.width * 0.85, size.height * 0.62),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
