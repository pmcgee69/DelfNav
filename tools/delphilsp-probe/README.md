# What DelphiLSP answers

`ask.py` starts a private `DelphiLSP.exe` (Delphi 13's language server, not the IDE's running
copy), gives it a project the way Embarcadero's VS Code extension does (`initialize`, then
`workspace/didChangeConfiguration` with a `.delphilsp.json`), opens a file and asks for
definition, implementation and references at the places given.

```
python ask.py <project>.delphilsp.json Probe.dpr 56:13:"call through interface" 58:5:"virtual call"
```

Lines and columns are 1-based. A `.delphilsp.json` is what the IDE writes beside a project when its
Code Insight option to generate one is on (registry `Code Insight\...LSP.Pascal`, `CodeInsightLSPGenerate`); for `Probe.dpr`, copy one and set
`settings.project` to `Probe.dpr`'s `file:///` URI. Results, 22 Nov 2026: see
[`../../examples/go-to-implementation/README.md`](../../examples/go-to-implementation/README.md),
"Beside DelphiLSP". `SERVER=<an exe> python ask.py ...` asks another server instead, started with
`--lsp` (DelfNav's `delfnav.exe`, delphipp's `delphipp.exe`), so the answers can be compared.

## Watching DelphiLSP load: `procmon\`

How long DelphiLSP takes to open a project, and what it reads, from the outside:

- **`capture.ps1`**: [Process Monitor](https://learn.microsoft.com/sysinternals/downloads/procmon)
  recording while the project opens (`start`, then `stop`, which writes a CSV; both ask for
  administrator rights, and it refuses a `Procmon64.exe` that isn't Microsoft-signed).
- **`lsif.py lsp.csv`**: each `.lsif` file DelphiLSP read, with when it started and finished, the
  bytes, and how many were being read at once.
- **`lifecycle.py lsp.csv`**: DelphiLSP's processes (the server, its `Agent0` and `Agent1`) as
  they start, exit, and crash (a `WerFault.exe` started for one).
- **`video_timeline.py <ffmpeg.exe> <video> <folder>`**: from a screen recording instead, the
  CodeInsight status line at 5 frames a second (its progress bar, and when the text changes), to
  time a load without Process Monitor. Where the status line is, in pixels, is set at its top for
  the recording it was written for (1336 x 1350): another recording needs those set again.

What they found, 22 Nov 2026 (Delphi 13, 37.0.60952): `Agent0` reads `lib\win32\release\lsif.idx`
(156 MB), then seven `.lsif` files **in parallel**, 486 MB of them in 10.0 s (`rtl` 335 MB alone);
and each time the server exits, **both agents crash**, an access violation in the compiler DLL
they host (`dcc32370.dll` at `0x00172745`), one of 339 DelphiLSP crashes in that machine's event
log since Nov 2025, nearly all that one kind, in every build since Delphi 12.
