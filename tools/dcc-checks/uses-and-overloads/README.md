# Overloads across units, and which of two same-named types wins

What Delphi's compiler does with a name declared in more than one used unit, checked with dcc64
(Delphi 13, 22 Nov 2026) before DelfNav's index is built on it. The user: *"overloads all apply
from all units touched"*, then *"run the test anyway. trust but verify. :)"*.

`run.cmd` compiles and runs each case.

| Unit | Declares |
|---|---|
| U1 | `function Max(A, B: Integer): string; overload;` |
| U2 | `function Max(A, B: Double): string; overload;` |
| U3 | `function Max(A, B: Double): string;` (no `overload`) |
| UA, UB | each a class `TFoo` |

| Case | `uses` | `Max(1, 2)` | `Max(1.5, 2.5)` |
|---|---|---|---|
| A | U1, U2 | U1's | U2's |
| B | U2, U1 | U1's | U2's |
| C | U1, U3 | U3's | U3's |
| E, E2 | U3, U1 | U1's | E2250: no overloaded version fits |
| F | U2, U3, U1 | U1's | E2250: U2's is not reached |
| D | UA, UB | `TFoo` is UB's | |

**The rule, as these show it.** The compiler looks from the nearest unit (the last in `uses`)
backwards. Declarations marked `overload` are gathered into one set, from every unit, in any
order (A, B). A declaration *without* `overload` is a wall: if it is the nearest, it alone
counts (C); further back, it and everything beyond it are hidden (E, F: U2's `Max(Double)` is
`overload` too, and lost behind U3's). For types, the last unit in `uses` wins (D).
