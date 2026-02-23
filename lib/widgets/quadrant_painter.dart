import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class QuadrantPainter extends CustomPainter {
  final List<Task> tasks;
  final double maxRange;

  QuadrantPainter({required this.tasks, this.maxRange = AppConstants.defaultMaxRange});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = AppConstants.axisStrokeWidth;

    // Draw Axes
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint); // X-axis
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint); // Y-axis

    // Draw Quadrant Labels (Simplified)
    _drawText(canvas, "Focus (Q1)", Offset(size.width * 0.75, size.height * 0.25));
    _drawText(canvas, "Caution (Q2)", Offset(size.width * 0.25, size.height * 0.25));
    _drawText(canvas, "Eliminate (Q3)", Offset(size.width * 0.25, size.height * 0.75));
    _drawText(canvas, "Plan (Q4)", Offset(size.width * 0.75, size.height * 0.75));

    // Plot Tasks
    for (var task in tasks) {
      final taskPaint = Paint()..color = _getColorForQuadrant(task.quadrant);
      
      // Coordinate transformation
      // Task.normalizedX is 0..1. Map it to 0..size.width
      // In Flutter canvas, Y increases downwards.
      // Task.y is positive UP. Task.normalizedY is 0..1 (0 is Bottom, 1 is Top).
      // Wait, let's re-check `Task.normalizedY`.
      // y = immediacy - illusion. Max y = 10 (Top). normalizedY = (10+10)/20 = 1.0.
      // So normalizedY 1.0 corresponds to TOP of the graph.
      // Flutter canvas: 0 is TOP.
      // So canvasY should be (1.0 - normalizedY) * height.
      
      double dx = task.normalizedX * size.width;
      double dy = (1.0 - task.normalizedY) * size.height;
      
      canvas.drawCircle(Offset(dx, dy), AppConstants.pointRadius, taskPaint);
    }
  }
  
  Color _getColorForQuadrant(int q) {
    switch (q) {
      case 1: return AppTheme.Q1Color;
      case 2: return AppTheme.Q2Color;
      case 3: return AppTheme.Q3Color;
      case 4: return AppTheme.Q4Color;
      default: return Colors.black;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black26, fontSize: 16, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant QuadrantPainter oldDelegate) {
    return oldDelegate.tasks != tasks;
  }
}
