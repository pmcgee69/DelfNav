"""Programs with a lone CR, for dcc64: does it count as a line break, and does it end a // comment?"""
import pathlib

D = pathlib.Path(__file__).parent

# 1. line numbers: a lone CR ends line 3; the undeclared name is on line 5 if CR counts, 4 if not
(D / 'LineCount.dpr').write_bytes(
    b"program LineCount;\r\n"          # 1
    b"{$APPTYPE CONSOLE}\r\n"          # 2
    b"begin // a lone CR follows\r"    # 3, ended by a lone CR
    b"  Writeln('one');\r\n"           # 4 if CR counts, else still 3
    b"  NoSuchName;\r\n"               # 5 if CR counts, else 4
    b"end.\r\n")

# 2. a // comment ended by a lone CR: if CR ends it, the Writeln runs and prints "after";
#    if not, the Writeln is part of the comment and nothing prints
(D / 'CommentEnd.dpr').write_bytes(
    b"program CommentEnd;\r\n"
    b"{$APPTYPE CONSOLE}\r\n"
    b"begin\r\n"
    b"  // a comment, then a lone CR\r  Writeln('after');\r\n"
    b"  Writeln('end');\r\n"
    b"end.\r\n")

# 3. the same with a lone LF, for comparison
(D / 'CommentEndLF.dpr').write_bytes(
    b"program CommentEndLF;\r\n"
    b"{$APPTYPE CONSOLE}\r\n"
    b"begin\r\n"
    b"  // a comment, then a lone LF\n  Writeln('after');\r\n"
    b"  Writeln('end');\r\n"
    b"end.\r\n")
print('written')
