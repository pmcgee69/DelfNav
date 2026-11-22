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

## G to L: other hiding

The user, 22 Nov: *"Is D ONLY for types? I think there is other hiding too?"*, then *"yes add G
to L, trust but verify"*.

| Case | What | Result |
|---|---|---|
| G | the program's own `Max(Double); overload` against U1's `Max(Integer); overload` | `Max(1, 2)` is U1's, `Max(1.5, 2.5)` its own: **merged**, the current unit included |
| H | UH: interface `uses UX1`, implementation `uses UX2`, each a plain `Who` | UX2's: **the implementation's `uses` is nearer** |
| I | in a method of `TC`, which has `Max(Double); overload`; uses U1 (`Max(Integer); overload`) | `Max(1, 2)` is TC's (the Integer converted): **the class's members hide the unit's, `overload` or not** |
| J | a local variable `Max`; uses U1 | E2066 on `Max(1, 2)`: **the local hides the function** |
| K, K2 | two helpers for Integer, `uses UK1, UK2` | `X.Who` is UK2's; UK1's `OnlyIn1` is E2003, undeclared: **one helper active, the last in `uses`; the other's methods are gone, not merged** |
| L | UL declares `Pos` and `Copy`; `uses UL` | both UL's: **a used unit hides `System`**, even `Copy`, which the compiler treats specially |

**The rule, as these show it.** The compiler looks from the nearest unit (the last in `uses`)
backwards. Declarations marked `overload` are gathered into one set, from every unit, in any
order (A, B). A declaration *without* `overload` is a wall: if it is the nearest, it alone
counts (C); further back, it and everything beyond it are hidden (E, F: U2's `Max(Double)` is
`overload` too, and lost behind U3's). For types, the last unit in `uses` wins (D).

The order a plain name is looked for in, nearest first: locals (J); inside a method, the class's
members, a wall even for `overload` (I); the current unit, whose `overload`s merge with the used
units' (G); the implementation section's `uses`, then the interface section's (H), each last
unit first; `System` last of all, hidden by any of them (L). Helpers: only the nearest is active
(K, K2).
