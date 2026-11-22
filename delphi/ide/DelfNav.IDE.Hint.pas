unit DelfNav.IDE.Hint;

{ A hint in a fixed-width font, as it shows code: THintWindow.CalcHintRect sets the hint font
  back each time (the user, 7 Nov, the first hover: proportional, ragged indents). Go to
  implementation's hovers (DelfNav.IDE), and delphipp's rules' (DelphiPP.IDE). In the editor's
  own font and size (the user, 7 Nov: "text is kinda small").

  A tab in a line dims the rest of it (the user, 22 Nov, of the directives and the overload count
  on the hover's second line: "dimmed is prob good, let's try"). The window paints the text as
  ever, with spaces where the dimmed part goes, then draws that part over them: the font is
  fixed-width, so the columns hold. }

interface

uses
  System.Types, System.Classes, Vcl.Controls;

type
  TCodeHint = class(THintWindow)
  private
    FRaw: string;                     // the text with its tabs: what Paint dims
  protected
    procedure Paint; override;
  public
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect; override;
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
  end;

implementation

uses
  System.SysUtils, System.UITypes, Winapi.Windows, Vcl.Graphics, ToolsAPI;

const
  Gap = '   ';                        // what a tab stands for

// the text as the window shows it before dimming: each tab and the rest of its line as spaces
function Spaced(const Hint: string): string;
begin
  const Lines = Hint.Split([sLineBreak]);
  var Parts: TArray<string>;
  SetLength(Parts, Length(Lines));
  for var I := 0 to High(Lines) do
  begin
    const P = Lines[I].IndexOf(#9);
    if P < 0 then
      Parts[I] := Lines[I]
    else
      Parts[I] := Lines[I].Substring(0, P) + Gap + StringOfChar(' ', Lines[I].Length - P - 1);
  end;
  Result := string.Join(sLineBreak, Parts);
end;

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
  DrawText(Canvas.Handle, Spaced(AHint), -1, Result, DT_CALCRECT or DT_LEFT or DT_NOPREFIX);
  Inc(Result.Right, 6);
  Inc(Result.Bottom, 2);
end;

procedure TCodeHint.ActivateHint(Rect: TRect; const AHint: string);
begin
  FRaw := AHint;
  inherited ActivateHint(Rect, Spaced(AHint));
end;

procedure TCodeHint.Paint;
begin
  inherited;
  if not FRaw.Contains(#9) then
    Exit;
  // halfway from the text's colour to the background's
  const Fg = ColorToRGB(Canvas.Font.Color);
  const Bg = ColorToRGB(Canvas.Pixels[1, 1]);
  Canvas.Font.Color := RGB((GetRValue(Fg) + GetRValue(Bg)) div 2, (GetGValue(Fg) + GetGValue(Bg)) div 2,
                           (GetBValue(Fg) + GetBValue(Bg)) div 2);
  Canvas.Brush.Style := bsClear;
  const H = Canvas.TextHeight('Wy');
  const Lines = FRaw.Split([sLineBreak]);
  for var I := 0 to High(Lines) do
  begin
    const P = Lines[I].IndexOf(#9);
    if P >= 0 then
      Canvas.TextOut(2 + Canvas.TextWidth(Lines[I].Substring(0, P) + Gap), 2 + I * H,
                     Lines[I].Substring(P + 1));
  end;
  Canvas.Font.Color := Fg;
end;

end.
