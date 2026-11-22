@echo off
rem Builds delfnav.exe (the language server) and NavSweep.exe (the corpus sweep) with Delphi
rem alone.  build.cmd: Win64, into delphi\bin;  build.cmd win32: into delphi\bin\win32.
rem Run get-treesitter4d.cmd once first. From a RAD Studio command prompt, or anywhere dcc64
rem and dcc32 are on the PATH.
setlocal
cd /d "%~dp0"
if not exist TreeSitter4D\delphi\TreeSitter.Api.pas (
  echo TreeSitter4D isn't here yet: run get-treesitter4d.cmd first
  exit /b 1
)
set DCC=dcc64
set OUT=bin
if /i "%~1"=="win32" (
  set DCC=dcc32
  set OUT=bin\win32
)
if not exist %OUT%\dcu mkdir %OUT%\dcu
rem an editor may be running delfnav.exe, which Windows won't let dcc overwrite but will let us
rem rename: the old one runs on until the editor restarts it, and is deleted next time
del /q %OUT%\delfnav.old-*.exe 2>nul
if exist %OUT%\delfnav.exe move /y %OUT%\delfnav.exe %OUT%\delfnav.old-%RANDOM%.exe >nul
for %%p in (DelfNav NavSweep) do (
  %DCC% -Q -B -E%OUT% -NU%OUT%\dcu "-NSSystem;Winapi" -UTreeSitter4D\delphi %%p.dpr || exit /b 1
)
del /q %OUT%\delfnav.old-*.exe 2>nul
echo built: %OUT%\delfnav.exe, %OUT%\NavSweep.exe
