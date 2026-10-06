import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'theme.dart';

extension QuadrantStyle on Quadrant {
  Color get color => switch (this) {
        Quadrant.focus => AppTheme.q1Color,
        Quadrant.caution => AppTheme.q2Color,
        Quadrant.eliminate => AppTheme.q3Color,
        Quadrant.plan => AppTheme.q4Color,
      };

  /// One-line advice shown next to the quadrant name.
  String get hint => switch (this) {
        Quadrant.focus => '지금 바로 처리하세요',
        Quadrant.caution => '바쁘기만 한 일일 수 있어요',
        Quadrant.eliminate => '하지 않아도 되는 일이에요',
        Quadrant.plan => '시간을 정해 두고 하세요',
      };
}
