# Process Monitor (Sysinternals) around DelphiLSP: what it reads, when, and how its processes
# start, end and crash. Each step asks for administrator rights (Process Monitor needs them).
#
#   .\capture.ps1 start <Procmon64.exe> <out-folder>   recording begins (out-folder\lsp.pml)
#   ... in the IDE: open the project, wait for "CodeInsight: Done" ...
#   .\capture.ps1 stop  <Procmon64.exe> <out-folder>   recording ends; out-folder\lsp.csv written
#   python lsif.py      <out-folder>\lsp.csv           the .lsif reads: per file, when and how much
#   python lifecycle.py <out-folder>\lsp.csv           DelphiLSP's processes: starts, exits, crashes
#
# The capture is everything the machine does (hundreds of MB a minute): keep it short, and delete
# it after. Crash details are also in Windows' Application log (event 1000, "DelphiLSP.exe").
param(
  [Parameter(Mandatory)] [ValidateSet('start', 'stop')] [string] $Step,
  [Parameter(Mandatory)] [string] $Procmon,
  [Parameter(Mandatory)] [string] $Out
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Out | Out-Null
$pml = Join-Path $Out 'lsp.pml'
$csv = Join-Path $Out 'lsp.csv'
if ($Step -eq 'start') {
  $sig = Get-AuthenticodeSignature $Procmon
  if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
    throw "$Procmon isn't Microsoft-signed: not running it"
  }
  Start-Process -FilePath $Procmon -Verb RunAs -ArgumentList '/AcceptEula', '/Quiet', '/Minimized', '/BackingFile', "`"$pml`""
  Write-Output "recording into $pml: open the project in the IDE, wait for 'CodeInsight: Done', then stop"
}
else {
  Start-Process -FilePath $Procmon -Verb RunAs -Wait -ArgumentList '/Terminate'
  Start-Process -FilePath $Procmon -Verb RunAs -Wait -ArgumentList '/AcceptEula', '/Quiet', '/Minimized', '/OpenLog', "`"$pml`"", '/SaveAs', "`"$csv`""
  Write-Output "written: $csv"
}
