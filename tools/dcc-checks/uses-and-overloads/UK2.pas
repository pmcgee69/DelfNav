unit UK2;

interface

type
  TIntHelper2 = record helper for Integer
    function Who: string;
  end;

implementation

function TIntHelper2.Who: string;
begin
  Result := 'UK2''s helper';
end;

end.
