# A lone CR, and a lone LF: line breaks to Delphi?

What Delphi's compiler does with a line ending that isn't CRLF, checked with dcc64 (Delphi 13,
25 Nov 2026). The question came from delfc, Delf's translator, which reads CRLF, LF and a lone CR
all as one line break: if dcc didn't, delfc's line numbers would drift from Delphi's after a lone
CR. The user: *"check the lone CR with dcc64"*. The corpus has them: before 25 Nov, 17 of its
77,548 Delphi sources had a lone CR, spring4d's `SQLite3.pas` one among 786 CRLFs.

`make.py` writes the cases byte for byte (`.gitattributes` keeps git from converting them);
`run.cmd` compiles and runs them.

| Case | What | Result |
|---|---|---|
| LineCount | line 3, `begin // …`, ends in a lone CR; an undeclared name two lines on | `LineCount.dpr(5) Error: E2003`: **the lone CR counts as a line** |
| CommentEnd | `// a comment, then a lone CR` + CR + `Writeln('after');`, one physical line | prints `after`: **the lone CR ends the `//` comment** |
| CommentEndLF | the same with a lone LF | prints `after` |

**So to Delphi CRLF, LF and a lone CR are alike: each one line break**, for its line numbers
and for where a `//` comment ends. delfc's reading of all three as `\n` agrees with it.
