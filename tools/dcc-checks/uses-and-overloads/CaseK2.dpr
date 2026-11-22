program CaseK2;
{ K2: is the hidden helper's method still reachable? UK1 has OnlyIn1, UK2 doesn't }
{$APPTYPE CONSOLE}
uses UK1, UK2;
var
  X: Integer;
begin
  X := 1;
  Writeln('K2 uses UK1, UK2   X.OnlyIn1 -> ', X.OnlyIn1);
end.
