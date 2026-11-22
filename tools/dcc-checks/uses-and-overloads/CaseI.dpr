program CaseI;
{ I: inside a method, the class's own overloaded Max against a used unit's overloaded Max }
{$APPTYPE CONSOLE}
uses U1;

type
  TC = class
    class function Max(A, B: Double): string; overload;
    class function Test: string;
  end;

class function TC.Max(A, B: Double): string;
begin
  Result := 'TC.Max(Double), the class''s';
end;

class function TC.Test: string;
begin
  Result := Max(1, 2);
end;

begin
  Writeln('I  in a method of TC (Max(Double) overload), uses U1   Max(1, 2) -> ', TC.Test);
end.
