program CaseL;
{ L: a used unit redeclaring System's Pos and Copy: is System hidden? (Pos gives an Integer in
  System, a string in UL; Copy a substring in System, 'UL.Copy' in UL) }
{$APPTYPE CONSOLE}
uses UL;
begin
  Writeln('L  uses UL   Pos(''b'', ''abc'')     -> ', Pos('b', 'abc'));
  Writeln('L  uses UL   Copy(''abc'', 2, 1)   -> ', Copy('abc', 2, 1));
end.
