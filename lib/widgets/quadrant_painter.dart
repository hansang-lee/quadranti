import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/task_model.dart';
import '../core/constants.dart';
import '../core/quadrant_style.dart';
import '../core/theme.dart';

class QuadrantPainter extends CustomPainter {
  final List<Task> tasks;

  /// Colour for axes, grid and text (the theme's onSurface).
  final Color ink;

  /// Background colour, used to outline the dots.
  final Color surface;

  QuadrantPainter({required this.tasks, this.ink = Colors.black, this.surface = Colors.white});

  /// Where [task] is drawn in a canvas of [size]. Task.normalizedY is 1.0 at
  /// the top, while canvas y grows downwards, hence the flip.
  static Offset positionOf(Task task, Size size) =>
      Offset(task.normalizedX * size.width, (1.0 - task.normalizedY) * size.height);

  /// Tasks grouped by graph position. Scores are whole numbers, so tasks
  /// rated alike land on exactly the same point and are drawn as one.
  /// Groups and their members keep the order of [tasks].
  static List<List<Task>> groupByPosition(List<Task> tasks) {
    final groups = <(double, double), List<Task>>{};
    for (final task in tasks) {
      groups.putIfAbsent((task.x, task.y), () => []).add(task);
    }
    return groups.values.toList();
  }

  /// The tasks at the point closest to [tap], if one is within [radius]
  /// pixels; empty otherwise.
  static List<Task> tasksAt(List<Task> tasks, Size size, Offset tap, {double radius = 20}) {
    var best = const <Task>[];
    var bestDistance = radius;
    for (final group in groupByPosition(tasks)) {
      final d = (positionOf(group.first, size) - tap).distance;
      if (d <= bestDistance) {
        best = group;
        bestDistance = d;
      }
    }
    return best;
  }

  /// At most this many titles are listed next to a shared point; the rest
  /// are summarised as "외 n개".
  static const int maxLabelsPerPoint = 3;

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
      ..color = ink.withValues(alpha: 0.12)
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
      ..color = ink.withValues(alpha: 0.54)
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
    final caption = TextStyle(color: ink.withValues(alpha: 0.54), fontSize: 11);
    _drawText(canvas, '가치 →', Offset(size.width - 4, center.dy + 4), style: caption, anchor: Alignment.topRight);
    _drawText(canvas, '실제 긴급도 ↑', Offset(center.dx + 4, 4), style: caption, anchor: Alignment.topLeft);

    // Tasks: one dot per position (in the colour of its first open task),
    // titles stacked beside it, finished tasks faded.
    const lineHeight = 13.0;
    for (final group in groupByPosition(tasks)) {
      final position = positionOf(group.first, size);
      final allDone = group.every((t) => t.done);
      final alpha = allDone ? 0.35 : 1.0;
      canvas.drawCircle(
        position,
        AppConstants.pointRadius,
        Paint()..color = group.first.quadrant.color.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        position,
        AppConstants.pointRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = surface.withValues(alpha: alpha),
      );

      final shown = group.length > maxLabelsPerPoint ? group.take(maxLabelsPerPoint - 1).toList() : group;
      final lines = [
        for (final t in shown) (t.title, t.done),
        if (shown.length < group.length) ('외 ${group.length - shown.length}개', false),
      ];
      // Labels go on the side facing the centre so they stay inside the canvas.
      final right = position.dx < center.dx;
      for (var i = 0; i < lines.length; i++) {
        final (text, done) = lines[i];
        final dy = (i - (lines.length - 1) / 2) * lineHeight;
        _drawText(
          canvas,
          text,
          position + Offset(right ? AppConstants.pointRadius + 4 : -AppConstants.pointRadius - 4, dy),
          style: TextStyle(
            color: ink.withValues(alpha: done ? 0.3 : 0.87),
            fontSize: 11,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
          anchor: right ? Alignment.centerLeft : Alignment.centerRight,
          maxWidth: size.width * 0.4,
        );
      }
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

  /// Screen-reader text for the tasks at one point.
  static String semanticLabel(List<Task> group) {
    final q = group.first.quadrant;
    final titles = group.map((t) => t.done ? '${t.title} (완료)' : t.title).join(', ');
    return '$titles. ${q.label} 사분면, 가치 ${_signed(group.first.x)}, 실제 긴급도 ${_signed(group.first.y)}';
  }

  static String _signed(double v) => v > 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);

  /// One semantics node per dot, so screen readers can find tasks on the
  /// canvas. Activating them is left to the list view.
  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) => [
        for (final group in groupByPosition(tasks))
          CustomPainterSemantics(
            key: ValueKey(group.first.id),
            rect: Rect.fromCircle(center: positionOf(group.first, size), radius: 20),
            properties: SemanticsProperties(label: semanticLabel(group), textDirection: TextDirection.ltr),
          ),
      ];

  @override
  bool shouldRebuildSemantics(covariant QuadrantPainter oldDelegate) => oldDelegate.tasks != tasks;

  @override
  bool shouldRepaint(covariant QuadrantPainter oldDelegate) {
    return oldDelegate.tasks != tasks || oldDelegate.ink != ink || oldDelegate.surface != surface;
  }
}
