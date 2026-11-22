program CaseJ;
{ J: a local variable named Max against a used unit's function Max: the call should not compile }
{$APPTYPE CONSOLE}
uses U1;

procedure Run;
var
  Max: Integer;
begin
  Max := 5;
  Writeln('J  local var Max, uses U1   Max(1, 2) -> ', Max(1, 2));
end;

begin
  Run;
end.
