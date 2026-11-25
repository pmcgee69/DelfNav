@echo off
rem Compiles each case with dcc64 and runs it; LineCount doesn't compile, on purpose: the line
rem dcc names is its result. From a RAD Studio command prompt, or anywhere dcc64 is on the PATH.
rem The cases are written by make.py, byte for byte. The results, Delphi 13, 25 Nov 2026: README.md.
setlocal
cd /d "%~dp0"
echo === LineCount: E2003 on line 5 if a lone CR is a line break, 4 if not
dcc64 -Q -B -E. -NSSystem LineCount.dpr | findstr /c:"Error" /c:"Fatal"
for %%c in (CommentEnd CommentEndLF) do (
  echo === %%c: prints "after" if the lone line ending ends the // comment
  if exist "%~dp0%%c.exe" del "%~dp0%%c.exe"
  dcc64 -Q -B -E. -NSSystem %%c.dpr | findstr /c:"Error" /c:"Fatal"
  if exist "%~dp0%%c.exe" "%~dp0%%c.exe"
)
