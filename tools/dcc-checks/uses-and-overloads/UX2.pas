unit UX2;

interface

function Who: string;

implementation

function Who: string;
begin
  Result := 'UX2.Who (in the implementation''s uses)';
end;

end.
