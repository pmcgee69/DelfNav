@echo off
rem Compiles each case with dcc64 and runs it; a case that doesn't compile shows dcc's error,
rem which is its result (E and F). From a RAD Studio command prompt, or anywhere dcc64 is on
rem the PATH. The results, Delphi 13, 22 Nov 2026: README.md.
setlocal
cd /d "%~dp0"
for %%c in (CaseA CaseB CaseC CaseD CaseE CaseE2 CaseF) do (
  if exist "%~dp0%%c.exe" del "%~dp0%%c.exe"
  dcc64 -Q -B -NSSystem %%c.dpr | findstr /c:"Error" /c:"Fatal"
  if exist "%~dp0%%c.exe" "%~dp0%%c.exe"
)
