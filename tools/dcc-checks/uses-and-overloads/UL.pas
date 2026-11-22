unit UL;

{ L: names System declares, declared again: Pos (an ordinary routine of System's, overloaded) and
  Copy (one the compiler treats specially) }

interface

function Pos(const SubStr, Str: string): string;
function Copy(const S: string; Index, Count: Integer): string;

implementation

function Pos(const SubStr, Str: string): string;
begin
  Result := 'UL.Pos';
end;

function Copy(const S: string; Index, Count: Integer): string;
begin
  Result := 'UL.Copy';
end;

end.
