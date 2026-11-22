unit UB;

interface

type
  TFoo = class
    class function Who: string;
  end;

implementation

class function TFoo.Who: string;
begin
  Result := 'UB.TFoo';
end;

end.
