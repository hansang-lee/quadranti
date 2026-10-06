import 'package:flutter/material.dart';
import '../core/quadrant_style.dart';
import '../models/task_model.dart';

/// Explains the four properties and the quadrants. Wording follows
/// docs/CONCEPT.md; keep the two in step.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        );
    Widget property(String name, String sign, String text) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(sign)),
          title: Text(name),
          subtitle: Text(text),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('사용법')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          heading('태스크마다 네 가지를 0–10으로 매겨요'),
          property('효과', '+', '이 일이 목표에 실제로 기여하는 정도'),
          property('낭비', '−', '들이는 시간·에너지 대비 남는 게 없는 정도'),
          property('즉시성', '+', '지금 처리하지 않으면 실제로 문제가 되는 정도'),
          property('착각', '−', '급해 보이지만 사실은 급하지 않은 정도'),
          heading('두 축으로 계산해요'),
          const Text('가치 = 효과 − 낭비 (가로축, 오른쪽일수록 가치 있음)\n'
              '실제 긴급도 = 즉시성 − 착각 (세로축, 위쪽일수록 급함)'),
          const SizedBox(height: 8),
          Text(
            '낭비나 착각을 매기지 않으면 태스크는 위·오른쪽에 머물러요. '
            '덜 중요하거나 덜 급한 일이라면 그쪽 점수를 올려 주세요.',
            style: theme.textTheme.bodySmall,
          ),
          heading('네 사분면'),
          for (final q in [Quadrant.focus, Quadrant.plan, Quadrant.caution, Quadrant.eliminate])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: q.color,
                foregroundColor: Colors.white,
                child: Text('${q.number}'),
              ),
              title: Text(q.label),
              subtitle: Text('${_where(q)} — ${q.hint}'),
            ),
          heading('한 주 단위로 관리해요'),
          const Text('위쪽 화살표로 주를 넘기고, 제목을 누르면 이번 주로 돌아와요. '
              '끝내지 못한 일은 다음 주로 옮길 수 있어요. '
              '데이터는 이 기기에만 저장되니 가끔 메뉴의 백업 내보내기를 해 두세요.'),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('guideDone'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  static String _where(Quadrant q) => switch (q) {
        Quadrant.focus => '가치 있고 급한 일',
        Quadrant.caution => '급하지만 가치가 낮은 일',
        Quadrant.eliminate => '가치도 낮고 급하지도 않은 일',
        Quadrant.plan => '가치 있지만 급하지 않은 일',
      };
}
