unit U1;

interface

function Max(A, B: Integer): string; overload;

implementation

function Max(A, B: Integer): string;
begin
  Result := 'U1.Max(Integer)';
end;

end.
