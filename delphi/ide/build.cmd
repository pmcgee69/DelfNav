@echo off
rem Builds the IDE package, DelfNavIDE.bpl, for both of Delphi 13's IDEs:
rem   bin\win32\DelfNavIDE.bpl   for the 32-bit IDE (Studio\37.0\bin\bds.exe)
rem   bin\win64\DelfNavIDE.bpl   for the 64-bit IDE (Studio\37.0\bin64\bds.exe)
rem Run ..\get-treesitter4d.cmd once first. Close the IDE first if it has the package loaded:
rem Windows keeps a loaded .bpl from being written.
setlocal
cd /d "%~dp0"
if not exist ..\TreeSitter4D\delphi\TreeSitter.Api.pas (
  echo TreeSitter4D isn't here yet: run ..\get-treesitter4d.cmd first
  exit /b 1
)
for %%p in (win32 win64) do (
  if not exist bin\%%p\dcu mkdir bin\%%p\dcu
)
dcc32 -Q -B -LEbin\win32 -LNbin\win32 -NUbin\win32\dcu "-NSSystem;Winapi;Vcl" DelfNavIDE.dpk || exit /b 1
dcc64 -Q -B -LEbin\win64 -LNbin\win64 -NUbin\win64\dcu "-NSSystem;Winapi;Vcl" DelfNavIDE.dpk || exit /b 1
echo built: bin\win32\DelfNavIDE.bpl, bin\win64\DelfNavIDE.bpl
