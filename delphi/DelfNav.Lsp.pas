unit DelfNav.Lsp;

{ delfnav's language server (delfnav --lsp): go to definition, declaration, type definition and
  implementation, and find references, from DelfNav.Index, for any editor that speaks LSP. It
  runs beside Delphi's own DelphiLSP, which does completion, signature help and the compiler's
  errors; this one claims only what DelphiLSP doesn't do, or can't (22 Nov: DelphiLSP's
  implementation goes from a method's declaration to its body, never from an interface or an
  abstract method to the classes; it has no references).

  TNavServer is meant to be extended: delphipp's server adds its rules (diagnostics, code
  actions) by overriding Capabilities, Opened, Closed and HandleOther. JSON-RPC over stdin and
  stdout, Content-Length framed. Positions are LSP's: lines, and columns in UTF-16 units, which
  is what a Delphi string counts.

  Split out of delphipp's DelphiPP.Lsp (the user, 22 Nov: "delfnav", delphipp using it). }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.JSON, System.SyncObjs,
  System.Generics.Collections, DelfNav.Index;

type
  // DelfNav.Index's queries: Implementations, Definitions, TypeDefinitions
  TFinder = function(const Path, Text: string; Line, Character: Integer;
    WaitMs: Cardinal): TArray<TImplTarget>;

  TNavServer = class
  private
    FIn, FOut : THandle;
    FBuffer   : array[0..65535] of Byte;
    FHave, FAt: Integer;
    FWriteLock: TCriticalSection;
    FTexts    : TDictionary<string, string>;   // each open file's newest text, for queries
    // the last find references, when it stopped on its budget: asked again at the same place,
    // it goes on from there and answers all found so far (requests come one at a time)
    FRefsKey  : string;
    FRefsSoFar: TArray<TImplTarget>;
    FRefsNext : Integer;
    function NextByte(out B: Byte): Boolean;
    function ReadLine(out Line: string): Boolean;
    function ReadMessage: TJSONObject;
    function LocationsAt(Params: TJSONObject; Find: TFinder): TJSONArray;
    procedure Handle(Msg: TJSONObject);
  protected
    FLock: TCriticalSection;   // FTexts, and whatever a descendant keeps beside it
    // the name in messages and in initialize's serverInfo
    function Name: string; virtual;
    // initialize's capabilities: navigation's; a descendant adds its own
    procedure Capabilities(Caps: TJSONObject); virtual;
    // a file opened or changed (its whole text), and closed
    procedure Opened(const Uri, Text: string); virtual;
    procedure Closed(const Uri: string); virtual;
    // a request or notification navigation doesn't know: True if handled
    function HandleOther(const Method: string; Id: TJSONValue; Params: TJSONObject): Boolean; virtual;
    // called once before the first message is read, and after the last
    procedure Starting; virtual;
    procedure Stopping; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Send(Msg: TJSONObject);                         // takes Msg and frees it
    procedure Reply(Id: TJSONValue; Value: TJSONValue);       // takes Value
    procedure Notify(const Method: string; Params: TJSONObject);
    procedure Say(MessageType: Integer; const Text: string);  // window/showMessage
    procedure Log(MessageType: Integer; const Text: string);  // window/logMessage
    procedure Run;
  end;

function Num(N: Integer): TJSONNumber;
// file:///D:/a%20b/X.dpr -> D:\a b\X.dpr; file://server/share/X.dpr -> \\server\share\X.dpr
function PathOf(const Uri: string): string;
// D:\a b\X.pas -> file:///D:/a%20b/X.pas; \\server\share\X.pas -> file://server/share/X.pas
function UriOf(const Path: string): string;

// serve navigation on stdin and stdout until the editor says exit, or closes stdin
procedure Serve;

implementation

uses
  System.Character, System.IOUtils;

function Num(N: Integer): TJSONNumber;
begin
  Exit( TJSONNumber.Create(N) );
end;

function PathOf(const Uri: string): string;
begin
  var S := Uri;
  if S.StartsWith('file:', True) then
    S := S.Substring(5);
  var Host := '';
  if S.StartsWith('//') then
  begin
    S := S.Substring(2);
    const Slash = S.IndexOf('/');
    if Slash < 0 then
    begin
      Host := S;
      S := '';
    end
    else
    begin
      Host := S.Substring(0, Slash);
      S := S.Substring(Slash);
    end;
  end;
  // percent escapes are UTF-8 bytes
  var Bytes: TBytes;
  var I := 0;
  while I < S.Length do
  begin
    const C = S.Chars[I];
    var Code: Integer;
    if (C = '%') and (I + 2 < S.Length) and TryStrToInt('$' + S.Substring(I + 1, 2), Code) then
    begin
      Bytes := Bytes + [Byte(Code)];
      Inc(I, 3);
    end
    else
    begin
      Bytes := Bytes + TEncoding.UTF8.GetBytes(string(C));
      Inc(I);
    end;
  end;
  var Path := TEncoding.UTF8.GetString(Bytes);
  // /D:/x or /D|/x is a drive's
  if (Path.Length >= 3) and (Path.Chars[0] = '/') and Path.Chars[1].IsLetter and
     ((Path.Chars[2] = ':') or (Path.Chars[2] = '|')) then
    Path := Path.Chars[1] + ':' + Path.Substring(3);
  if (Host <> '') and not SameText(Host, 'localhost') then
    Path := '//' + Host + Path;
  Exit( Path.Replace('/', PathDelim) );
end;

function UriOf(const Path: string): string;
begin
  var S := Path.Replace('\', '/');
  var Prefix := 'file:///';
  if S.StartsWith('//') then
    Prefix := 'file:';
  Result := Prefix;
  for var B in TEncoding.UTF8.GetBytes(S) do
    if CharInSet(Char(B), ['A'..'Z', 'a'..'z', '0'..'9', '-', '.', '_', '~', '/', ':']) then
      Result := Result + Char(B)
    else
      Result := Result + '%' + IntToHex(B, 2);
end;

{ TNavServer }

constructor TNavServer.Create;
begin
  inherited Create;
  FIn  := GetStdHandle(STD_INPUT_HANDLE);
  FOut := GetStdHandle(STD_OUTPUT_HANDLE);
  FWriteLock := TCriticalSection.Create;
  FLock      := TCriticalSection.Create;
  FTexts     := TDictionary<string, string>.Create;
end;

destructor TNavServer.Destroy;
begin
  FTexts.Free;
  FLock.Free;
  FWriteLock.Free;
  inherited;
end;

function TNavServer.Name: string;
begin
  Exit( 'delfnav' );
end;

procedure TNavServer.Capabilities(Caps: TJSONObject);
begin
  Caps.AddPair('implementationProvider', TJSONBool.Create(True));
  Caps.AddPair('definitionProvider', TJSONBool.Create(True));
  Caps.AddPair('declarationProvider', TJSONBool.Create(True));
  Caps.AddPair('typeDefinitionProvider', TJSONBool.Create(True));
  Caps.AddPair('referencesProvider', TJSONBool.Create(True));
end;

procedure TNavServer.Opened(const Uri, Text: string);
begin
end;

procedure TNavServer.Closed(const Uri: string);
begin
end;

function TNavServer.HandleOther(const Method: string; Id: TJSONValue; Params: TJSONObject): Boolean;
begin
  Exit( False );
end;

procedure TNavServer.Starting;
begin
end;

procedure TNavServer.Stopping;
begin
end;

function TNavServer.NextByte(out B: Byte): Boolean;
begin
  if FAt >= FHave then
  begin
    var Got: DWORD := 0;
    // a closed pipe is the end of input, as a read of nothing is
    if not ReadFile(FIn, FBuffer, SizeOf(FBuffer), Got, nil) or (Got = 0) then
      Exit( False );
    FHave := Got;
    FAt   := 0;
  end;
  B := FBuffer[FAt];
  Inc(FAt);
  Exit( True );
end;

// a header line, without its CR LF; False at the end of input
function TNavServer.ReadLine(out Line: string): Boolean;
begin
  var Bytes: TBytes;
  var B: Byte;
  var Any := False;
  while NextByte(B) do
  begin
    Any := True;
    if B = 10 then
      Break;
    Bytes := Bytes + [B];
  end;
  Line := TEncoding.ASCII.GetString(Bytes).Trim;
  Exit( Any );
end;

// the next message, or nil at the end of input
function TNavServer.ReadMessage: TJSONObject;
begin
  var Size := -1;
  var Line: string;
  repeat
    if not ReadLine(Line) then
      Exit( nil );
    const Colon = Line.IndexOf(':');
    if (Colon > 0) and SameText(Line.Substring(0, Colon).Trim, 'Content-Length') then
      Size := StrToIntDef(Line.Substring(Colon + 1).Trim, -1);
  until Line = '';
  if Size < 0 then
    Exit( TJSONObject.Create );     // no body: nothing to do, read on
  var Body: TBytes;
  SetLength(Body, Size);
  for var I := 0 to Size - 1 do
    if not NextByte(Body[I]) then
      Exit( nil );
  const Value = TJSONObject.ParseJSONValue(Body, 0, True);
  if Value is TJSONObject then
    Exit( TJSONObject(Value) );
  Value.Free;
  Exit( TJSONObject.Create );
end;

procedure TNavServer.Send(Msg: TJSONObject);
begin
  try
    const Body = TEncoding.UTF8.GetBytes(Msg.ToJSON);
    const Head = TEncoding.ASCII.GetBytes(Format('Content-Length: %d'#13#10#13#10, [Length(Body)]));
    const All = Head + Body;
    FWriteLock.Enter;
    try
      var Done := 0;
      while Done < Length(All) do
      begin
        var Wrote: DWORD := 0;
        if not WriteFile(FOut, All[Done], Length(All) - Done, Wrote, nil) then
          Exit;     // the editor has gone
        Inc(Done, Wrote);
      end;
    finally
      FWriteLock.Leave;
    end;
  finally
    Msg.Free;
  end;
end;

procedure TNavServer.Reply(Id: TJSONValue; Value: TJSONValue);
begin
  if Id = nil then
  begin
    Value.Free;     // a notification wants no reply
    Exit;
  end;
  var Msg := TJSONObject.Create;
  Msg.AddPair('jsonrpc', '2.0');
  Msg.AddPair('id', TJSONValue(Id.Clone));
  Msg.AddPair('result', Value);
  Send(Msg);
end;

procedure TNavServer.Notify(const Method: string; Params: TJSONObject);
begin
  var Msg := TJSONObject.Create;
  Msg.AddPair('jsonrpc', '2.0');
  Msg.AddPair('method', Method);
  Msg.AddPair('params', Params);
  Send(Msg);
end;

procedure TNavServer.Say(MessageType: Integer; const Text: string);
begin
  var P := TJSONObject.Create;
  P.AddPair('type', Num(MessageType));
  P.AddPair('message', Text);
  Notify('window/showMessage', P);
end;

procedure TNavServer.Log(MessageType: Integer; const Text: string);
begin
  var P := TJSONObject.Create;
  P.AddPair('type', Num(MessageType));
  P.AddPair('message', Text);
  Notify('window/logMessage', P);
end;

// textDocument/implementation: a Location for each implementing method, none when the name
// under the cursor isn't a call on an interface; textDocument/definition (and declaration):
// where the name is declared; textDocument/typeDefinition: where its type is; with Find nil,
// textDocument/references
function TNavServer.LocationsAt(Params: TJSONObject; Find: TFinder): TJSONArray;
begin
  Result := TJSONArray.Create;
  const Uri = Params.GetValue<string>('textDocument.uri');
  var Text: string;
  FLock.Enter;
  try
    if not FTexts.TryGetValue(Uri, Text) then
      Text := '';
  finally
    FLock.Leave;
  end;
  const Path = PathOf(Uri);
  if (Text = '') and FileExists(Path) then
    Text := TFile.ReadAllText(Path);
  const Line = Params.GetValue<Integer>('position.line');
  const Character = Params.GetValue<Integer>('position.character');
  var Targets: TArray<TImplTarget>;
  if Assigned(Find) then
    Targets := Find(Path, Text, Line, Character, 30000)
  else
  begin
    // the other files open in the editor as it has them
    var Open := TDictionary<string, string>.Create;
    FLock.Enter;
    try
      for var Pair in FTexts do
        Open.AddOrSetValue(PathOf(Pair.Key).ToLower, Pair.Value);
    finally
      FLock.Leave;
    end;
    try
      var Decl := False;
      if Params.GetValue('context') is TJSONObject then
        Params.TryGetValue<Boolean>('context.includeDeclaration', Decl);
      // half a second at a time (the user, 21 Nov: "a time budget like 0.5sec"); the same
      // place asked again goes on where it stopped
      const Key = Format('%s|%d|%d|%s', [Uri, Line, Character, BoolToStr(Decl)]);
      var First := 0;
      var SoFar: TArray<TImplTarget> := nil;
      if (Key = FRefsKey) and (FRefsNext > 0) then
      begin
        First := FRefsNext;
        SoFar := FRefsSoFar;
      end;
      var More: TRefsMore;
      Targets := SoFar + References(Path, Text, Line, Character, Decl,
        function(P: string): string
        begin
          if not Open.TryGetValue(P.ToLower, Result) then
            Result := '';
        end, 30000, 500, First, More);
      FRefsKey   := Key;
      FRefsSoFar := Targets;
      FRefsNext  := More.Next;
      if More.Common then
        Say(3, Name + ': a name every unit uses (Integer, string, TObject ...): its uses aren''t listed')
      else if More.Next >= 0 then
        Say(3, Format('%s: %d found so far, %d of %d units read: Find All References again for more',
          [Name, Length(Targets), More.Read, More.Total]));
    finally
      Open.Free;
    end;
  end;
  for var T in Targets do
  begin
    var At := TJSONObject.Create;
    At.AddPair('line', Num(T.Line - 1));
    At.AddPair('character', Num(T.Col));
    var Upto := TJSONObject.Create;
    Upto.AddPair('line', Num(T.Line - 1));
    Upto.AddPair('character', Num(T.Col + T.Len));
    var Range := TJSONObject.Create;
    Range.AddPair('start', At);
    Range.AddPair('end', Upto);
    var L := TJSONObject.Create;
    L.AddPair('uri', UriOf(T.Path));
    L.AddPair('range', Range);
    Result.AddElement(L);
  end;
end;

procedure TNavServer.Handle(Msg: TJSONObject);
begin
  const MethodValue = Msg.GetValue('method');
  if MethodValue = nil then
    Exit;     // a reply to us: we ask nothing
  const Method = MethodValue.Value;
  var Id := Msg.GetValue('id');
  if Id is TJSONNull then
    Id := nil;
  // params may be missing, or null (as a shutdown's often is): either is no params
  var Params: TJSONObject;
  if Msg.GetValue('params') is TJSONObject then
    Params := TJSONObject(Msg.GetValue('params'))
  else
  begin
    Msg.RemovePair('params').Free;
    Params := TJSONObject.Create;
    Msg.AddPair('params', Params);
  end;

  if Method = 'initialize' then
  begin
    var Sync := TJSONObject.Create;
    Sync.AddPair('openClose', TJSONBool.Create(True));
    Sync.AddPair('change', Num(1));
    Sync.AddPair('save', TJSONObject.Create);    // didSave: the index reads that file again
    var Caps := TJSONObject.Create;
    Caps.AddPair('textDocumentSync', Sync);
    Capabilities(Caps);
    // the workspace's units, indexed in the background
    var Root := '';
    if Params.GetValue('rootUri') is TJSONString then
      Root := PathOf(Params.GetValue<string>('rootUri'))
    else if (Params.GetValue('workspaceFolders') is TJSONArray) and
            (TJSONArray(Params.GetValue('workspaceFolders')).Count > 0) then
      Root := PathOf(TJSONArray(Params.GetValue('workspaceFolders')).Items[0].GetValue<string>('uri'));
    if (Root <> '') and DirectoryExists(Root) then
      IndexFolder(Root);
    var Info := TJSONObject.Create;
    Info.AddPair('name', Name);
    var R := TJSONObject.Create;
    R.AddPair('capabilities', Caps);
    R.AddPair('serverInfo', Info);
    Reply(Id, R);
  end
  else if Method = 'shutdown' then
    Reply(Id, TJSONNull.Create)
  else if (Method = 'textDocument/didOpen') or (Method = 'textDocument/didChange') then
  begin
    const Uri = Params.GetValue<string>('textDocument.uri');
    var Text: string;
    if Method = 'textDocument/didOpen' then
      Text := Params.GetValue<string>('textDocument.text')
    else
    begin
      const Changes = Params.GetValue('contentChanges') as TJSONArray;
      Text := Changes.Items[Changes.Count - 1].GetValue<string>('text');
    end;
    FLock.Enter;
    try
      FTexts.AddOrSetValue(Uri, Text);
    finally
      FLock.Leave;
    end;
    Opened(Uri, Text);
  end
  else if Method = 'textDocument/didSave' then
    Reindex(PathOf(Params.GetValue<string>('textDocument.uri')))
  else if Method = 'textDocument/didClose' then
  begin
    const Uri = Params.GetValue<string>('textDocument.uri');
    FLock.Enter;
    try
      FTexts.Remove(Uri);
    finally
      FLock.Leave;
    end;
    Closed(Uri);
    // closed unsaved, its edits may be in the index: as saved again
    Reindex(PathOf(Uri));
  end
  else if Method = 'textDocument/implementation' then
    Reply(Id, LocationsAt(Params, Implementations))
  else if (Method = 'textDocument/definition') or (Method = 'textDocument/declaration') then
    Reply(Id, LocationsAt(Params, Definitions))
  else if Method = 'textDocument/typeDefinition' then
    Reply(Id, LocationsAt(Params, TypeDefinitions))
  else if Method = 'textDocument/references' then
    Reply(Id, LocationsAt(Params, nil))
  else if HandleOther(Method, Id, Params) then
    // a descendant's
  else if Id <> nil then
  begin
    var Err := TJSONObject.Create;
    Err.AddPair('code', Num(-32601));
    Err.AddPair('message', 'no ' + Method);
    var Msg2 := TJSONObject.Create;
    Msg2.AddPair('jsonrpc', '2.0');
    Msg2.AddPair('id', TJSONValue(Id.Clone));
    Msg2.AddPair('error', Err);
    Send(Msg2);
  end;
end;

procedure TNavServer.Run;
begin
  Starting;
  while True do
  begin
    const Msg = ReadMessage;
    if Msg = nil then
      Break;
    try
      const Method = Msg.GetValue('method');
      if (Method <> nil) and (Method.Value = 'exit') then
        Break;
      try
        Handle(Msg);
      except
        // a message we can't read is logged and skipped, not the end of the server
        on E: Exception do
          Log(1, Format('%s: %s: %s', [Name, E.ClassName, E.Message]));
      end;
    finally
      Msg.Free;
    end;
  end;
  Stopping;
end;

procedure Serve;
begin
  var Server := TNavServer.Create;
  // stdout is the protocol's: a stray Writeln goes to stderr, the editor's log
  TTextRec(Output).Handle := TTextRec(ErrOutput).Handle;
  Server.Run;
  // not freed: the index's background threads may still be reading, and the process is ending
end;

end.
