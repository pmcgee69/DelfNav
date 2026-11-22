program CaseK;
{ K: two helpers for Integer in two used units: which one is active? }
{$APPTYPE CONSOLE}
uses UK1, UK2;
var
  X: Integer;
begin
  X := 1;
  Writeln('K  uses UK1, UK2   X.Who -> ', X.Who);
end.
