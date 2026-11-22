unit UK1;

interface

type
  TIntHelper1 = record helper for Integer
    function Who: string;
    function OnlyIn1: string;
  end;

implementation

function TIntHelper1.Who: string;
begin
  Result := 'UK1''s helper';
end;

function TIntHelper1.OnlyIn1: string;
begin
  Result := 'UK1''s helper, OnlyIn1';
end;

end.
