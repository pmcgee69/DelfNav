program CaseA;
{$APPTYPE CONSOLE}
uses U1, U2;
begin
  Writeln('A  uses U1, U2   Max(1, 2)     -> ', Max(1, 2));
  Writeln('A  uses U1, U2   Max(1.5, 2.5) -> ', Max(1.5, 2.5));
end.
