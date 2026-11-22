# delfnav

**Go to implementation, definition, type definition and find references for Delphi**, from a
[tree-sitter](https://tree-sitter.github.io/) index of your units, in the Delphi IDE and in any
editor that speaks LSP. It works on plain `.pas`: no Delf, no preprocessor, no compiler run.

In Delphi, Ctrl+click on `x.DoSomething()` takes you to the interface. delfnav takes you to the
classes that implement it, and from a virtual method to each override:

| Asked at | Delphi's own DelphiLSP | delfnav |
|---|---|---|
| `x.DoSomething()`, `x` an interface | the interface's declaration | **each class's method** (`TBase.DoSomething`, `TDerived.DoSomething`, and `TOther.Run`, which a method resolution clause maps to it) |
| a virtual or abstract method | its declaration | **each override** |
| Find References | not offered | **every use**, across the units |
| Go to Type Definition | not offered | where the name's type is declared |

Checked against DelphiLSP itself, 22 Nov 2026: [`tools/delphilsp-probe`](tools/delphilsp-probe/README.md).
DelphiLSP's "implementation" is the old Ctrl+Shift+Up/Down, a method's declaration to its body.

## In the Delphi IDE

`DelfNavIDE.bpl`, an IDE package, beside the IDE's own Code Insight:

- **Ctrl+Shift+click** a method's name, or right-click it and choose **Go to Implementation**:
  one implementation goes straight there, more show a menu.
- **Find References (delfnav)**: every use, in the Messages view.
- **Find Declaration (delfnav)** and **Go to Type Definition (delfnav)**, for when the IDE's own
  can't tell (a unit opened with no project, say).

The index is the active project's: the `.pas` files in its folder and below, and in each folder
of its search path, read in the background. Try it on
[`examples/go-to-implementation`](examples/go-to-implementation/README.md).

## In an editor: `delfnav --lsp`

A language server on stdin and stdout, meant to run **beside** DelphiLSP, not instead of it:
it claims only implementation, definition, declaration, type definition and references, and
leaves completion, signature help and the compiler's errors to DelphiLSP.

**Zed**, for now: delphipp's Zed extension runs `delphipp.exe --lsp`, which has delfnav's
navigation built in (delphipp uses delfnav). A Zed extension for delfnav alone is to come.

## Building

With Delphi 13 (dcc32 and dcc64 on the PATH, as in a RAD Studio command prompt):

```
delphi\get-treesitter4d.cmd     once: TreeSitter4D, its units and its compiled C
delphi\build.cmd                delphi\bin\delfnav.exe and NavSweep.exe (Win64; "win32" for Win32)
delphi\ide\build.cmd            delphi\ide\bin\win32\DelfNavIDE.bpl and ...\win64\DelfNavIDE.bpl
```

Install the package from the IDE (Component > Install Packages > Add): the `win32` one in the
32-bit IDE (`bin\bds.exe`), the `win64` one in the 64-bit IDE (`bin64\bds.exe`). delphipp's
`DelphiPPIDE.bpl` contains delfnav's units too: install one or the other, not both.

`NavSweep.exe <folder>` asks the index the way an editor would, over a whole repository, and
counts and times the answers: the check run over 42 repositories before each change.

## What it is, and isn't

A sketch, not the compiler: overloads are told apart by the number of arguments and the types
it can see (literals, enum values, typed variables; where it can't tell, it offers each one that
fits), no `as` or `with`, generic constraints unchecked. Program files (`.dpr`) aren't indexed,
only units.

## Where it came from

Split out of [delphipp](https://github.com/pmcgee69/delphi-preprocessor-starter) (its
go-to-implementation branch) on 22 Nov 2026, the files' history kept: the commits before that
date are delphipp's. Named for [Delf](https://github.com/pmcgee69), Delphi with a stricter type
system, of which delfnav is a part that needs none of it. Reads Delphi with
[TreeSitter4D](https://github.com/pmcgee69/TreeSitter4D) and Alexander Liberov's
tree-sitter-delphi13 grammar (MIT).

MIT licence: [LICENSE](LICENSE).
