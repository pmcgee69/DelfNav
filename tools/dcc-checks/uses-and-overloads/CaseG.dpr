program CaseG;
{ G: the current unit's overload against a used unit's overload: merged, or the used one hidden? }
{$APPTYPE CONSOLE}
uses U1;

function Max(A, B: Double): string; overload;
begin
  Result := 'CaseG.Max(Double), its own';
end;

begin
  Writeln('G  own Max(Double) overload, uses U1   Max(1, 2)     -> ', Max(1, 2));
  Writeln('G  own Max(Double) overload, uses U1   Max(1.5, 2.5) -> ', Max(1.5, 2.5));
end.
