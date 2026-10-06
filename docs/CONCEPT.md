# Concept: the four properties and the quadrants

Quadranti is a weekly scheduler. Every task is rated on four properties, and
the ratings place it on a two-axis graph. Its quadrant says how to treat it.
This is a sibling of the Eisenhower matrix: the Eisenhower matrix asks
"important?" and "urgent?", while Quadranti splits each question into a real
part and a misleading part.

Code: `lib/models/task_model.dart` (formula, `Quadrant` enum),
`lib/core/quadrant_style.dart` (colours, advice text),
`lib/screens/task_editor_screen.dart` (slider help text).

## The four properties

Each is a whole number from 0 to 10 (`AppConstants.scoreMax`), clamped by the
`Task` constructor. The UI text is Korean; the meanings below are the working
definitions the editor shows. They are an interpretation of the original idea
and still need the owner's confirmation (see D1 in `DECISIONS.md`).

| Property | UI label | Working definition (editor help text) |
|---|---|---|
| effectiveness | 효과 | how much the task really moves a goal forward |
| waste | 낭비 | time and energy spent with little to show for it |
| immediacy | 즉시성 | how much it really hurts to leave it for later |
| illusion | 착각 | how much it only *looks* urgent |

New tasks start at effectiveness 5, immediacy 5, waste 0, illusion 0, which
places them in 집중 until rated.

## Axes

```
x (value, 가치)          = effectiveness - waste      range -10..10
y (real urgency, 실제 긴급도) = immediacy - illusion      range -10..10
```

`normalizedX` / `normalizedY` map each to 0..1 for drawing; `normalizedY = 1`
is the top edge, and `QuadrantPainter.positionOf` flips it for the canvas.

## Quadrants

| # | Enum | Label | Where | Advice shown | Colour |
|---|---|---|---|---|---|
| 1 | `focus` | 집중 | x >= 0, y >= 0 | 지금 바로 처리하세요 | green |
| 2 | `caution` | 주의 | x < 0, y >= 0 | 바쁘기만 한 일일 수 있어요 | orange |
| 3 | `eliminate` | 제거 | x < 0, y < 0 | 하지 않아도 되는 일이에요 | grey |
| 4 | `plan` | 계획 | x >= 0, y < 0 | 시간을 정해 두고 하세요 | blue |

A point on an axis counts toward the right and upper side, so (0, 0) is 집중.

## Known weakness of the current formula

Because each axis is a plain difference, a task falls below the x axis only
when its illusion is larger than its immediacy, and left of the y axis only
when its waste is larger than its effectiveness. A task rated "low urgency"
(immediacy 2) with no illusion still lands in the upper half. In practice
the user has to use the negative property to push a task down or left. The
sample task 장기 전략 정리 needs illusion 4 to reach 계획 for this reason.
Options are in D1 of `DECISIONS.md`. Until that is decided, keep the formula
and the tests as they are.
