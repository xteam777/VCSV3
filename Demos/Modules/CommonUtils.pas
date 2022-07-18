unit CommonUtils;

interface

uses
  SASLibEx, Windows, SysUtils, Classes, rtcLog, rtcWinLogon, FireWall, NetFwTypeLib_TLB, rtcInfo, CommonData, WinApi.WinInet;

  procedure SaveResourceToFile(AResourceName, AFileName: String);
  //function SetSoftwareSASGeneration(AValue: Integer): Integer;
  function GetDOSEnvVar(const VarName: string): string;
  procedure AddFireWallRules;
  procedure AddExceptionToFireWall;
  function IsInternetConnected: Boolean;
  function InternetGetConnectedState(lpdwFlags: LPDWORD; dwReserved:DWORD):BOOL; stdcall; external 'wininet.dll' name 'InternetGetConnectedState';
  procedure GetProxyData(var ProxyEnabled: boolean; var ProxyServer: string; var ProxyPort: integer);
  function RemoveUserPrefix(sUser: String): String;

implementation

function RemoveUserPrefix(sUser: String): String;
begin
  if Pos('_', sUser) > 0 then
    Result := Copy(sUser, 1, Pos('_', sUser) - 1)
  else
    Result := sUser;
end;

procedure GetProxyData(var ProxyEnabled: boolean; var ProxyServer: string; var ProxyPort: integer);
var
  ProxyInfo: PInternetProxyInfo;
  Len: LongWord;
  i, j: integer;
begin
  Len := 4096;
  ProxyEnabled := false;
  GetMem(ProxyInfo, Len);
  try
    if InternetQueryOption(nil, INTERNET_OPTION_PROXY, ProxyInfo, Len)
    then
      if ProxyInfo^.dwAccessType = INTERNET_OPEN_TYPE_PROXY then
      begin
        ProxyEnabled:= True;
        ProxyServer := ProxyInfo^.lpszProxy;
      end
  finally
    FreeMem(ProxyInfo);
  end;

  if ProxyEnabled and (ProxyServer <> '') then
  begin
    i := Pos('http=', ProxyServer);
    if (i > 0) then
    begin
      Delete(ProxyServer, 1, i + 4);
      j := Pos(';', ProxyServer);
      if (j > 0) then
        ProxyServer := Copy(ProxyServer, 1, j - 1);
    end;
    i := Pos(':', ProxyServer);
    if (i > 0) then
    begin
      ProxyPort := StrToIntDef(Copy(ProxyServer, i + 1, Length(ProxyServer) - i), 0);
      ProxyServer := Copy(ProxyServer, 1, i - 1)
    end
  end;
end;

function IsInternetConnected: Boolean;
var
 dwConnectionTypes: DWORD;
begin
// dwConnectionTypes := INTERNET_CONNECTION_LAN;
 Result := InternetGetConnectedState(@dwConnectionTypes, 0);
end;

procedure SaveResourceToFile(AResourceName, AFileName: String);
var
  ResStream: TResourceStream;
begin
  ResStream := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
  try
    ResStream.Position := 0;
    ResStream.SaveToFile(AFileName);
  finally
    ResStream.Free;
  end;
end;

function GetDOSEnvVar(const VarName: string): string;
var
  i: integer;
begin
  Result := '';
  try
    i := GetEnvironmentVariable(PChar(VarName), nil, 0);
    if i > 0 then
    begin
      SetLength(Result, i - 1);
      GetEnvironmentVariable(Pchar(VarName), PChar(Result), i);
    end;
  except
    Result := '';
  end;
end;

procedure AddFireWallRules;
var
  fw: TFireWall;
begin
  fw := TFireWall.Create;
  fw.RemoveRule('Remox');
  fw.AddRule('Remox', ParamStr(0), NET_FW_RULE_DIR_IN);
  fw.AddRule('Remox', ParamStr(0), NET_FW_RULE_DIR_OUT);
  fw.Free;
end;

procedure AddExceptionToFireWall;
var
  fw: TFireWall;
begin
  fw := TFireWall.Create;
  if not fw.ApplicationExists(ParamStr(0)) then
    fw.AddApplication('Remox', ParamStr(0));
  fw.Free;
end;

end.
