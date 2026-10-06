import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../core/constants.dart';
import '../core/quadrant_style.dart';
import '../core/theme.dart';

class QuadrantPainter extends CustomPainter {
  final List<Task> tasks;

  QuadrantPainter({required this.tasks});

  /// Where [task] is drawn in a canvas of [size]. Task.normalizedY is 1.0 at
  /// the top, while canvas y grows downwards, hence the flip.
  static Offset positionOf(Task task, Size size) =>
      Offset(task.normalizedX * size.width, (1.0 - task.normalizedY) * size.height);

  /// The task drawn closest to [point], if one is within [radius] pixels.
  /// Later tasks are drawn on top, so they win ties.
  static Task? taskAt(List<Task> tasks, Size size, Offset point, {double radius = 20}) {
    Task? best;
    var bestDistance = radius;
    for (final task in tasks) {
      final d = (positionOf(task, size) - point).distance;
      if (d <= bestDistance) {
        best = task;
        bestDistance = d;
      }
    }
    return best;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Quadrant backgrounds
    final half = Size(size.width / 2, size.height / 2);
    for (final (q, origin) in [
      (Quadrant.focus, Offset(center.dx, 0)),
      (Quadrant.caution, Offset.zero),
      (Quadrant.eliminate, Offset(0, center.dy)),
      (Quadrant.plan, center),
    ]) {
      canvas.drawRect(origin & half, Paint()..color = q.color.withValues(alpha: 0.06));
    }

    // Grid, one line per score step
    final grid = Paint()
      ..color = Colors.black12
      ..strokeWidth = AppConstants.gridStrokeWidth;
    final steps = (AppConstants.scoreMax * 2).toInt();
    for (var i = 1; i < steps; i++) {
      final dx = size.width * i / steps;
      final dy = size.height * i / steps;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }

    // Axes
    final axis = Paint()
      ..color = Colors.black54
      ..strokeWidth = AppConstants.axisStrokeWidth;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axis);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axis);

    // Quadrant labels
    for (final (q, at) in [
      (Quadrant.focus, Offset(size.width * 0.75, size.height * 0.25)),
      (Quadrant.caution, Offset(size.width * 0.25, size.height * 0.25)),
      (Quadrant.eliminate, Offset(size.width * 0.25, size.height * 0.75)),
      (Quadrant.plan, Offset(size.width * 0.75, size.height * 0.75)),
    ]) {
      _drawText(canvas, q.label, at,
          style: TextStyle(color: q.color.withValues(alpha: 0.35), fontSize: 20, fontWeight: FontWeight.bold));
    }

    // Axis captions
    const caption = TextStyle(color: Colors.black54, fontSize: 11);
    _drawText(canvas, '가치 →', Offset(size.width - 4, center.dy + 4), style: caption, anchor: Alignment.topRight);
    _drawText(canvas, '실제 긴급도 ↑', Offset(center.dx + 4, 4), style: caption, anchor: Alignment.topLeft);

    // Tasks: finished ones faded, each labelled with its title
    for (final task in tasks) {
      final alpha = task.done ? 0.35 : 1.0;
      final position = positionOf(task, size);
      canvas.drawCircle(
        position,
        AppConstants.pointRadius,
        Paint()..color = task.quadrant.color.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        position,
        AppConstants.pointRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: alpha),
      );
      // Labels go on the side facing the centre so they stay inside the canvas.
      final right = position.dx < center.dx;
      _drawText(
        canvas,
        task.title,
        position + Offset(right ? AppConstants.pointRadius + 4 : -AppConstants.pointRadius - 4, 0),
        style: TextStyle(
          color: Colors.black87.withValues(alpha: alpha),
          fontSize: 11,
          decoration: task.done ? TextDecoration.lineThrough : null,
        ),
        anchor: right ? Alignment.centerLeft : Alignment.centerRight,
        maxWidth: size.width * 0.4,
      );
    }
  }

  /// Draws [text] so that its [anchor] point sits at [at].
  void _drawText(
    Canvas canvas,
    String text,
    Offset at, {
    required TextStyle style,
    Alignment anchor = Alignment.center,
    double maxWidth = double.infinity,
  }) {
    final textPainter = TextPainter(
      // Canvas text sees no DefaultTextStyle, so set the family here.
      text: TextSpan(text: text, style: style.copyWith(fontFamily: AppTheme.fontFamily)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final offset = Offset(
      (anchor.x + 1) / 2 * textPainter.width,
      (anchor.y + 1) / 2 * textPainter.height,
    );
    textPainter.paint(canvas, at - offset);
  }

  @override
  bool shouldRepaint(covariant QuadrantPainter oldDelegate) {
    return oldDelegate.tasks != tasks;
  }
}
