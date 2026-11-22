unit UH;

{ H: a name in the interface's uses (UX1) and the implementation's (UX2): which does code in the
  implementation section see? }

interface

uses UX1;

function Test: string;

implementation

uses UX2;

function Test: string;
begin
  Result := Who;
end;

end.
