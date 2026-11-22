unit DelfNav.IDE.Hint;

{ A hint in a fixed-width font, as it shows code: THintWindow.CalcHintRect sets the hint font
  back each time (the user, 7 Nov, the first hover: proportional, ragged indents). Go to
  implementation's hovers (DelfNav.IDE), and delphipp's rules' (DelphiPP.IDE). In the editor's
  own font and size (the user, 7 Nov: "text is kinda small"). }

interface

uses
  System.Types, System.Classes, Vcl.Controls;

type
  TCodeHint = class(THintWindow)
  public
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect; override;
  end;

implementation

uses
  Winapi.Windows, ToolsAPI;

function TCodeHint.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect;
begin
  inherited;                                        // the hint font, at the screen's scale
  Canvas.Font.Name := 'Consolas';
  try
    const Options = (BorlandIDEServices as IOTAEditorServices).GetEditOptions('Borland.EditOptions.Pascal');
    if Options <> nil then
    begin
      if Options.FontName <> '' then
        Canvas.Font.Name := Options.FontName;
      if Options.FontSize > 0 then
        Canvas.Font.Size := Options.FontSize;
    end;
  except
    // the hint font's size, in Consolas
  end;
  Result := Rect(0, 0, MaxWidth, 0);
  DrawText(Canvas.Handle, AHint, -1, Result, DT_CALCRECT or DT_LEFT or DT_NOPREFIX);
  Inc(Result.Right, 6);
  Inc(Result.Bottom, 2);
end;

end.
