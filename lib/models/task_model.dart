import '../core/constants.dart';

class Task {
  final String id;
  String title;
  String description;
  
  // 4 properties: Immediacy, Effectiveness, Waste, Illusion
  double immediacy;
  double effectiveness;
  double waste;
  double illusion;
  
  double maxRange;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.immediacy = 5.0,
    this.effectiveness = 5.0,
    this.waste = 0.0,
    this.illusion = 0.0,
    this.maxRange = AppConstants.defaultMaxRange,
  });

  // Calculate coordinates relative to the center (0,0)
  // X = Effectiveness - Waste
  // Y = Immediacy - Illusion
  double get x => effectiveness - waste;
  double get y => immediacy - illusion;

  // Normalized coordinates for UI plotting (0.0 to 1.0 range)
  // Assuming the graph spans from -maxRange to +maxRange on both axes.
  // normalizedX = (x + maxRange) / (2 * maxRange)
  double get normalizedX => (x + maxRange) / (maxRange * 2);
  double get normalizedY => (y + maxRange) / (maxRange * 2);

  // Quadrant determinator
  // 1: Top-Right (High Effect, High Immediate) -> "Focus"
  // 2: Top-Left (Low Effect, High Immediate) -> "Caution / Busy Trap"
  // 3: Bottom-Left (Low Effect, Low Immediate) -> "Eliminate"
  // 4: Bottom-Right (High Effect, Low Immediate) -> "Plan"
  int get quadrant {
    if (x >= 0 && y >= 0) return 1;
    if (x < 0 && y >= 0) return 2;
    if (x < 0 && y < 0) return 3;
    return 4;
  }
}
