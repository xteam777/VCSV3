unit rtcTSCli;

interface

{$INCLUDE rtcPortalDefs.inc}
{$INCLUDE rtcDefs.inc}

USES
  Windows,
  SysUtils,
  rtcLog;

  function LockWorkStation: BOOL; stdcall; external 'user32.dll' name 'LockWorkStation';
  function WinStationConnect(hServer: THANDLE; SessionID: ULONG; TargetSessionID: ULONG; pPassword: PWideChar; bWait: Boolean): Boolean; stdcall; external 'winsta.dll' name 'WinStationConnectW';
  function WTSGetActiveConsoleSessionId: DWORD; stdcall; external  'Kernel32.dll';

  function IsWorkstationLocked: Boolean;
//  function inConsoleSession: Boolean;
//  procedure SetConsoleSession(pSessionId: DWORD = $FFFFFFFF);

implementation

function IsWorkstationLocked: Boolean;
var
  hDesktop: HDESK;
begin
  Result := False;
  hDesktop := OpenDesktop('default', 0, False, DESKTOP_SWITCHDESKTOP);
  if hDesktop <> 0 then
  begin
    Result := not SwitchDesktop(hDesktop);
    CloseDesktop(hDesktop);
  end;
end;

{FUNCTION GetProcedureAddress(VAR P: Pointer; CONST ModuleName, ProcName: String;
  VAR pModule: HMODULE): Boolean;
VAR
  ModuleHandle: HMODULE;
BEGIN
  IF NOT Assigned(P) THEN
  BEGIN
    ModuleHandle := GetModuleHandle(PChar(ModuleName));
    IF ModuleHandle = 0 THEN
      ModuleHandle := LoadLibrary(PChar(ModuleName));
    IF ModuleHandle <> 0 THEN
      P := Pointer(GetProcAddress(ModuleHandle, PChar(ProcName)));
    Result := Assigned(P);
  END
  ELSE
    Result := True;
END;

FUNCTION InitProcLibs: Boolean;
BEGIN
  IF LibsLoaded > 0 THEN
    Result := True
  ELSE IF LibsLoaded < 0 THEN
    Result := False
  ELSE
  BEGIN
    LibsLoaded := -1;
    IF GetProcedureAddress(@ProcessIdToSessionId, 'kernel32.dll',
      'ProcessIdToSessionId', gKernel32) AND
      GetProcedureAddress(@LockWorkStation, 'user32.dll', 'LockWorkStation',
      gUser32) THEN
      LibsLoaded := 1;
    Result := LibsLoaded = 1;
  END;
// $IFDEF ExtendLog
XLog(Format('rtcTSCli.InitProclibs = %s', [BoolToStr(Result, True)]), LogAddon);
//$ENDIF
END;

PROCEDURE DeInitProcLibs;
BEGIN
  IF LibsLoaded = 1 THEN
  BEGIN
    FreeLibrary(gWinSta);
    FreeLibrary(gKernel32);
    FreeLibrary(gUser32);
  END;
END;

FUNCTION ProcessSessionId: DWORD;
BEGIN
  Result := 0;
  IF (LibsLoaded = 1) THEN
  BEGIN
    IF NOT ProcessIdToSessionId(GetCurrentProcessId(), Result) THEN
      Result := $FFFFFFFF
  END;
  // $ifdef ExtendLog
  XLog(Format('ProcessSessionId = %d', [result]), LogAddon);
  //$endif
END;

FUNCTION ConsoleSessionId: DWORD;
BEGIN
  IF (LibsLoaded = 1) THEN
    Result := WTSGetActiveConsoleSessionId
  ELSE
    Result := 0;
  // $ifdef ExtendLog
  XLog(Format('ConsoleSessionId = %d', [result]), LogAddon);
  //$endif
END;

FUNCTION inConsoleSession: Boolean;
BEGIN
  Result := ConsoleSessionId = ProcessSessionId;
  // $ifdef ExtendLog
  XLog(Format('inConsoleSession = %s', [booltostr(result, true)]), LogAddon);
  //$endif
END;

PROCEDURE SetConsoleSession(pSessionId: DWORD = $FFFFFFFF);
BEGIN
// $IFDEF ExtendLog
XLog(Format('SetConsoleSession(%d)', [pSessionId]), LogAddon);
//$ENDIF
  IF (LibsLoaded = 1) THEN
  BEGIN
    IF (pSessionId = $FFFFFFFF) THEN
      pSessionId := ProcessSessionId;
// $IFDEF ExtendLog
XLog(Format('WinStationConnect(%d, %d)', [pSessionId, ConsoleSessionId]), LogAddon);
//$ENDIF
    IF WinStationConnect(0, pSessionId, ConsoleSessionId, '', False) THEN
//$IFDEF FORCELOGOUT
      LockWorkStation;
//$ELSE FORCELOGOUT
      ;
//$ENDIF FORCELOGOUT
  END;
END;}

initialization

//InitProcLibs;

finalization

//DeInitProcLibs;

end.
