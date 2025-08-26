// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class HalfCircleProgress extends StatelessWidget {
  final double progress; // between 0.0 and 1.0
  final double radius;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final String label;
  final Widget? widget;

  const HalfCircleProgress({
    super.key,
    required this.progress,
    this.radius = 100, // <- Circle radius
    this.strokeWidth = 12,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.progressColor = Colors.blue,
    required this.label,
    this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (radius * 2).w,
      height: radius.h,
      child: CustomPaint(
        painter: _HalfCirclePainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          progressColor: progressColor,
        ),
        child:
            widget ??
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
      ),
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _HalfCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final startAngle = math.pi;
    final sweepAngle = math.pi * progress;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, math.pi, false, backgroundPaint);
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
