# DelfNav

**Go to implementation, definition, type definition and find references for Delphi**, from a
[tree-sitter](https://tree-sitter.github.io/) index of your units, in the Delphi IDE and in any
editor that speaks LSP. It works on plain `.pas` and `.dpr`: no Delf, no preprocessor, no
compiler run.

In Delphi, Ctrl+click on `x.DoSomething()` takes you to the interface. DelfNav takes you to the
classes that implement it, and from a virtual method to each override:

| Asked at | Delphi's own DelphiLSP | DelfNav |
|---|---|---|
| `x.DoSomething()`, `x` an interface | the interface's declaration | **each class's method** (`TBase.DoSomething`, `TDerived.DoSomething`, and `TOther.Run`, which a method resolution clause maps to it) |
| a virtual or abstract method | its declaration | **each override** |
| Find References | not offered | **every use**, across the units |
| Go to Type Definition | not offered | where the name's type is declared |

Checked against DelphiLSP itself, 22 Nov 2026: [`tools/delphilsp-probe`](tools/delphilsp-probe/README.md).
DelphiLSP's "implementation" is the old Ctrl+Shift+Up/Down, a method's declaration to its body.

**Load times, side by side** (22 Nov 2026, one machine). DelphiLSP opening a VCL project loads
prebuilt LSIF indexes of the libraries (`lib\win32\...\*.lsif`): `xmlrtl`, `vcl` and `rtl`,
486 MB, in about **9.4 s** (timed from a screen recording, frame by frame at 0.2 s; they seem to
load in parallel). DelfNav parsing the same libraries' source (556 units, one at a time):
**8.2 s** warm, 15.4 s cold. Delphi's LSIF files hold definitions and hovers only: no
implementations, no references.

## In the Delphi IDE

`DelfNavIDE.bpl`, an IDE package, beside the IDE's own Code Insight:

- **Ctrl+Shift+click** a method's name, or right-click it and choose **Go to Implementation**:
  one implementation goes straight there, more show a menu.
- **Find References (DelfNav)**: every use, in the Messages view.
- **Find Declaration (DelfNav)** and **Go to Type Definition (DelfNav)**, for when the IDE's own
  can't tell (a unit opened with no project, say).

The index is the active project's: the `.pas` and `.dpr` files in its folder and below, and in each folder
of its search path, read in the background. Try it on
[`examples/go-to-implementation`](examples/go-to-implementation/README.md).

## In an editor: `delfnav --lsp`

A language server on stdin and stdout, meant to run **beside** DelphiLSP, not instead of it:
it claims only implementation, definition, declaration, type definition and references, and
leaves completion, signature help and the compiler's errors to DelphiLSP.

**Zed**, for now: delphipp's Zed extension runs `delphipp.exe --lsp`, which has DelfNav's
navigation built in (delphipp uses DelfNav). A Zed extension for DelfNav alone is to come.

## Building

With Delphi 13 (dcc32 and dcc64 on the PATH, as in a RAD Studio command prompt):

```
delphi\get-treesitter4d.cmd     once: TreeSitter4D, its units and its compiled C
delphi\build.cmd                delphi\bin\delfnav.exe and NavSweep.exe (Win64; "win32" for Win32)
delphi\ide\build.cmd            delphi\ide\bin\win32\DelfNavIDE.bpl and ...\win64\DelfNavIDE.bpl
```

Install the package from the IDE (Component > Install Packages > Add): the `win32` one in the
32-bit IDE (`bin\bds.exe`), the `win64` one in the 64-bit IDE (`bin64\bds.exe`). delphipp's
`DelphiPPIDE.bpl` (the rules) *requires* `DelfNavIDE.bpl`: the two install together, DelfNavIDE
first. delphipp's `delphi\ide\build.cmd install` builds both from its submodule and puts them in
the IDE's package folder, where Windows finds DelfNavIDE whenever DelphiPPIDE loads.

`NavSweep.exe <folder>` asks the index the way an editor would, over a whole repository, and
counts and times the answers: the check run over 42 repositories before each change.

## What it is, and isn't

A sketch, not the compiler: overloads are told apart by the number of arguments and the types
it can see (literals, enum values, typed variables; where it can't tell, it offers each one that
fits), no `as` or `with`, generic constraints unchecked. Programs (`.dpr`) are indexed after the
units: a program's own types and routines are found from inside it, and where a unit declares
the same name, it's the unit's.

## Where it came from

Split out of [delphipp](https://github.com/pmcgee69/delphi-preprocessor-starter) (its
go-to-implementation branch) on 22 Nov 2026, the files' history kept: the commits before that
date are delphipp's. Named for [Delf](https://github.com/pmcgee69/DelfPascal), Delphi with a stricter type
system, of which DelfNav is a part that needs none of it. Reads Delphi with
[TreeSitter4D](https://github.com/pmcgee69/TreeSitter4D) and Alexander Liberov's
tree-sitter-delphi13 grammar (MIT).

MIT licence: [LICENSE](LICENSE).
