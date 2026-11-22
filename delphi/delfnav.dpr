program delfnav;

{ delfnav: go to definition, implementation, type definition and find references for Delphi,
  from a tree-sitter index of the workspace's units (DelfNav.Index). In an editor that speaks
  LSP, beside Delphi's own DelphiLSP:

    delfnav --lsp         the language server, on stdin and stdout
    delfnav --version }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TreeSitter.Api,
  DelfNav.Index in 'DelfNav.Index.pas',
  DelfNav.Lsp in 'DelfNav.Lsp.pas';

const
  Version = '0.1.0';

begin
  try
    // --lsp, as editors write it: FindCmdLineSwitch takes one '-' off, and '-lsp' isn't 'lsp'
    const A = ParamStr(1);
    if (ParamCount = 1) and ((A = '--lsp') or (A = '-lsp')) then
      Serve
    else if (ParamCount = 1) and ((A = '--version') or (A = '-version')) then
      Writeln('delfnav ', Version)
    else
    begin
      Writeln('delfnav ', Version, ': go to definition, implementation and references for Delphi');
      Writeln('  delfnav --lsp       the language server, on stdin and stdout');
      Writeln('  delfnav --version');
      ExitCode := 2;
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'delfnav: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
