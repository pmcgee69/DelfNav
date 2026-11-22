program CaseB;
{$APPTYPE CONSOLE}
uses U2, U1;
begin
  Writeln('B  uses U2, U1   Max(1, 2)     -> ', Max(1, 2));
  Writeln('B  uses U2, U1   Max(1.5, 2.5) -> ', Max(1.5, 2.5));
end.
