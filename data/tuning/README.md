# data/tuning

Tuning resources: every balance, timing and layout number the game reads (PLAN.md section 5, Tuning). The debug panel edits these live.

- `packing_tuning.tres`: the moves a round gets and what each crane action costs. The fields are described in `core/packing/packing_tuning.gd`.
- `presentation.tres`: spot sizes, colours, timings, screen margins and touch distances. The fields are described in `ui/common/presentation_tuning.gd`.

Every value in both files is a starter value.

Owner: the designer. Agents may add files named `example_*` and never change a value in an existing file.
