unit U3;

interface

function Max(A, B: Double): string;   // no overload directive

implementation

function Max(A, B: Double): string;
begin
  Result := 'U3.Max(Double), not overload';
end;

end.
