unit UX1;

interface

function Who: string;

implementation

function Who: string;
begin
  Result := 'UX1.Who (in the interface''s uses)';
end;

end.
