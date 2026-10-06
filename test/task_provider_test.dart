import 'package:flutter_test/flutter_test.dart';
import 'package:quadranti/providers/task_provider.dart';

void main() {
  test('sample data is seeded once', () {
    final provider = TaskProvider()
      ..loadSampleData()
      ..loadSampleData();
    expect(provider.tasks, hasLength(4));
  });

  test('sample data covers all four quadrants', () {
    final provider = TaskProvider()..loadSampleData();
    expect(provider.tasks.map((t) => t.quadrant).toSet(), {1, 2, 3, 4});
  });

  test('removeTask drops only the matching id', () {
    final provider = TaskProvider()..loadSampleData();
    provider.removeTask('2');
    expect(provider.tasks.map((t) => t.id), ['1', '3', '4']);
  });
}
