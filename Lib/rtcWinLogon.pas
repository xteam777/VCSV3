{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcWinLogon;

interface

{$INCLUDE rtcDefs.inc}
{$INCLUDE rtcPortalDefs.inc}

{.$DEFINE ExtendLog}

uses
  SyncObjs,
  Windows,
  rtcLog,
  TLHelp32,
  SysUtils,
  WTSApi,

{$IFDEF RTC_LBFIX}
  rtcTSCli,
{$ENDIF RTC_LBFIX}

    rtcSystem;

const
  DESKTOP_ALL = DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
    DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or DESKTOP_WRITEOBJECTS or
    DESKTOP_READOBJECTS or DESKTOP_SWITCHDESKTOP or GENERIC_WRITE;

  WTS_CURRENT_SERVER_HANDLE = 0;

type
  _WTS_INFO_CLASS = (WTSInitialProgram, WTSApplicationName, WTSWorkingDirectory,
    WTSOEMId, WTSSessionId, WTSUserName, WTSWinStationName, WTSDomainName,
    WTSConnectState, WTSClientBuildNumber, WTSClientName, WTSClientDirectory,
    WTSClientProductId, WTSClientHardwareId, WTSClientAddress, WTSClientDisplay,
    WTSClientProtocolType, WTSIdleTime, WTSLogonTime, WTSIncomingBytes,
    WTSOutgoingBytes, WTSIncomingFrames, WTSOutgoingFrames, WTSClientInfo,
    WTSSessionInfo);
{$EXTERNALSYM _WTS_INFO_CLASS}
  WTS_INFO_CLASS = _WTS_INFO_CLASS;
  TWtsInfoClass = WTS_INFO_CLASS;


const
  TOKEN_ADJUST_SESSIONID = $0100;
{$EXTERNALSYM TOKEN_ADJUST_SESSIONID}
  SE_DEBUG_NAME = 'SeDebugPrivilege';
{$EXTERNALSYM SE_DEBUG_NAME}
  SE_TCB_NAME = 'SeTcbPrivilege';
{$EXTERNALSYM SE_TCB_NAME}
  SE_IMPERSONATE_NAME = 'SeImpersonatePrivilege';
{$EXTERNALSYM SE_IMPERSONATE_NAME}

type
  RPC_STATUS = Longint;
  I_RPC_HANDLE = Pointer;
  RPC_BINDING_HANDLE = I_RPC_HANDLE;

var
  LogAddon: String= '';
  // Call "SwitchToActiveDesktop" periodically? 
  // (required when running as a Service)
  AutoDesktopSwitch: Boolean = True;

procedure SwitchToActiveDesktop;

function rtcKillProcess(strProcess: String; ProcessId: Cardinal = 0): Integer;
function rtcGetProcessID(strProcess: String; OnlyActiveSession: boolean = False): DWORD;

function rtcStartProcess(strProcess: String; out piOut: PProcessInformation; lpDesktop: String = 'winsta0\default'): DWORD; overload;
function rtcStartProcess(strProcess: String; lpDesktop: String = 'winsta0\default'): DWORD; overload;

function RpcRevertToSelf: RPC_STATUS; stdcall; external 'rpcrt4.dll';
function RpcImpersonateClient(BindingHandle: RPC_BINDING_HANDLE): RPC_STATUS; stdcall; external 'rpcrt4.dll';

procedure StrResetLength(var S: String);
function GetUserObjectName(hUserObject: THandle): String;
function GetInputDesktopName: String;
function GetCurrentDesktopName: String;
function SetUserObjectFullAccess(hUserObject: THandle): Boolean;

implementation

uses
  rtcScrUtils;

var
  LibsLoaded: Integer = 0;

type
  EReportedException = class(Exception);

function SetUserObjectFullAccess(hUserObject: THandle): Boolean;
var
  Sd: PSecurity_Descriptor;
  Si: Security_Information;
begin
  Result := not (Win32Platform = VER_PLATFORM_WIN32_NT); //IsWinNT;
  if Result then  // Win9x/ME
    Exit;
  { TODO : Check the success of called functions }
  Sd := PSecurity_Descriptor(LocalAlloc(LPTR, SECURITY_DESCRIPTOR_MIN_LENGTH));
  InitializeSecurityDescriptor(Sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(Sd, True, nil, False);

  Si := DACL_SECURITY_INFORMATION;
  Result := SetUserObjectSecurity(hUserObject, Si, Sd);

  LocalFree(HLOCAL(Sd));
end;

procedure StrResetLength(var S: String);
begin
  SetLength(S, StrLen(PChar(S)));
end;

//function GetUserObjectName(hUserObject: THandle): String;
//var
//  buf: PChar;
//  needed: Cardinal;
//begin
//  buf := AllocMem(1024);
//  if not GetUserObjectInformation(hUserObject, UOI_NAME, buf, 1024, needed) then
//  begin
//    FreeMem(buf);
//    buf := AllocMem(needed);
//    GetUserObjectInformation(hUserObject, UOI_NAME, buf, needed, needed);
//  end;
//  Result := buf;
//  FreeMem(buf);
//end;

function GetUserObjectName(hUserObject: THandle): String;
var
//  buf: PChar;
  buf: array[0..255] of Char;
  needed: Cardinal;
begin
//  buf := AllocMem(1024);
  if not GetUserObjectInformation(hUserObject, UOI_NAME, @buf, 255, needed) then
  begin
//    FreeMem(buf);
//    buf := AllocMem(needed);
    GetUserObjectInformation(hUserObject, UOI_NAME, @buf, needed, needed);
  end;
  Result := buf;
//  FreeMem(buf);
end;

function GetInputDesktopName: String;
var
  desk: HDESK;
begin
  try
    desk := OpenInputDesktop(0, False, GENERIC_ALL);
    if desk <> 0 then
    begin
      Result := GetUserObjectName(desk);
      CloseDesktop(desk);
    end
    else
      Result := 'Winlogon';
  except
    Result := 'Winlogon';
  end;

//  SetThreadDesktop(GetThreadDesktop(GetCurrentThreadId));
end;

function GetCurrentDesktopName: String;
var
  desk: HDESK;
begin
  try
    desk := GetThreadDesktop(GetCurrentThreadId);
    if desk <> 0 then
    begin
      Result := GetUserObjectName(desk);
      CloseDesktop(desk);
    end
    else
      Result := 'Default';
  except
    Result := 'Default';
  end;
end;

function APICheck(aBool: boolean; anOperation: String): boolean;
var
  anError: String;
begin
  if not aBool then
  begin
    anError := Format('Error in %s: %s',
      [anOperation, SysErrorMessage(GetLastError)]);
    SetLastError(0);
{$IFDEF ExtendLog}xLog(anError, LogAddon); {$ENDIF}
    raise EReportedException.create(anError);
  end
  else if GetLastError <> 0 then
{$IFDEF ExtendLog}xLog(Format('%s: %s', [anOperation, SysErrorMessage(GetLastError)]), LogAddon){$ENDIF};
  SetLastError(0);
  Result := true;
end;

{function GetProcedureAddress(var P: Pointer;
  const ModuleName, ProcName: String): boolean;
var
  ModuleHandle: HMODULE;
begin
  if not Assigned(P) then
  begin
    ModuleHandle := GetModuleHandle(PChar(ModuleName));
    if ModuleHandle = 0 then
    begin
      SetLastError(0);
      ModuleHandle := LoadLibrary(PChar(ModuleName));
    end;
    if ModuleHandle <> 0 then
      P := Pointer(GetProcAddress(ModuleHandle, PChar(ProcName)));
    Result := Assigned(P);
  end
  else
    Result := true;
end;

function GetProc(var P: Pointer; ModuleName: String; ProcName: String): boolean;
begin
  Result := GetProcedureAddress(P, ModuleName, ProcName);
{$IFDEF ExtendLog}
  {xLog(Format('GetProcAddress: %s.%s - %s', [ModuleName, ProcName, BoolToStr(Result, true)]), LogAddon); {$ENDIF}
{end;}

function rtcKillProcess(strProcess: String; ProcessId: Cardinal = 0): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THANDLE;
  procEntry: TProcessEntry32;
  myPID: Cardinal;
begin
{$IFDEF ExtendLog}xLog('rtcKillProcess', LogAddon); {$ENDIF}
  Result := 0;

  strProcess := UpperCase(ExtractFileName(strProcess));
  myPID := GetCurrentProcessId;

  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  try
    procEntry.dwSize := Sizeof(procEntry);
    ContinueLoop := Process32First(FSnapshotHandle, procEntry);
    while Integer(ContinueLoop) <> 0 do
    begin
      if (procEntry.th32ProcessID <> myPID) and
        ((UpperCase(WideCharToString(procEntry.szExeFile)) = UpperCase(strProcess)) or
        (UpperCase(ExtractFileName(WideCharToString(procEntry.szExeFile))) = UpperCase(strProcess)))
        and ((ProcessId = procEntry.th32ProcessID) or (ProcessId = 0)) then
        Result := Integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE,
          BOOL(0), procEntry.th32ProcessID), 0));
      ContinueLoop := Process32Next(FSnapshotHandle, procEntry);
    end;
  finally
    CloseHandle(FSnapshotHandle);
  end;
end;

function ActiveSessionID: Cardinal;
begin
//  if Assigned(WTSGetActiveConsoleSessionId) then
    Result := WTSGetActiveConsoleSessionId
//  else
//    Result := 0;
end;

function rtcGetProcessID(strProcess: String;
  OnlyActiveSession: boolean = False): DWORD;
var
  dwSessionId, winlogonSessId: DWORD;
  hsnap: THANDLE;
  procEntry: TProcessEntry32;
  myPID: Cardinal;
  aResult: DWORD;
begin
{$IFDEF ExtendLog}xLog('rtcGetProcessID', LogAddon); {$ENDIF}
  Result := 0;
  aResult := 0;

  try
    dwSessionId := ActiveSessionID;

{$IFDEF ExtendLog}xLog(Format('dwSessionId = %d', [dwSessionId]), LogAddon);
{$ENDIF}
    hsnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hsnap = INVALID_HANDLE_VALUE) then
      Exit;
    try
      strProcess := UpperCase(ExtractFileName(strProcess));
      myPID := GetCurrentProcessId;

{$IFDEF ExtendLog}xLog(Format('strProcess = %s', [strProcess]), LogAddon);
{$ENDIF}
      procEntry.dwSize := Sizeof(TProcessEntry32);
      if (not Process32First(hsnap, procEntry)) then
      begin
        Exit;
      end;

      repeat
        if (procEntry.th32ProcessID <> myPID) and
          ((UpperCase(WideCharToString(procEntry.szExeFile)) = strProcess) or
          (UpperCase(ExtractFileName(WideCharToString(procEntry.szExeFile))) = strProcess)) then
        begin
          winlogonSessId := 0;
          aResult := procEntry.th32ProcessID;
{$IFDEF ExtendLog}xLog(Format('OnlyActiveSession = %s', [BoolToStr(OnlyActiveSession, true)]), LogAddon); {$ENDIF}
          if not OnlyActiveSession then
          begin
{$IFDEF ExtendLog}xLog(Format('Result = %d', [Result]), LogAddon);
{$ENDIF}
            Result := procEntry.th32ProcessID;
            break;
          end
          else
          begin
            if ProcessIdToSessionId(procEntry.th32ProcessID, winlogonSessId)
            then
            begin
{$IFDEF ExtendLog}xLog(Format('winlogonSessId = %d', [winlogonSessId]), LogAddon); {$ENDIF}
              if (winlogonSessId = dwSessionId) then
              begin
                Result := procEntry.th32ProcessID;
{$IFDEF ExtendLog}xLog(Format('Result = %d', [Result]), LogAddon); {$ENDIF}
                break;
              end;
            end;
          end;
        end;
      until (not Process32Next(hsnap, procEntry));
      // fallback to using the process from another session if available
      if Result = 0 then
        Result := aResult;
    finally
      CloseHandle(hsnap);
    end;
  finally
    SetLastError(0);
  end;
end;

function get_winlogon_handle: THANDLE;
var
  hProcess: THANDLE;
  hTokenThis: THANDLE;
  ID: DWORD;
  id_session: THANDLE;
begin
  ID := rtcGetProcessID('winlogon.exe', true);
  id_session := ActiveSessionID;
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, False, ID);
  if (hProcess > 0) then
  begin
    OpenProcessToken(hProcess, TOKEN_ASSIGN_PRIMARY or TOKEN_ALL_ACCESS,
      hTokenThis);
    DuplicateTokenEx(hTokenThis, TOKEN_ASSIGN_PRIMARY or TOKEN_ALL_ACCESS, nil,
      SecurityImpersonation, TokenPrimary, Result);
    SetTokenInformation(Result, TokenSessionId, @id_session, Sizeof(DWORD));
    CloseHandle(hTokenThis);
    CloseHandle(hProcess);
  end;
end;

{$IFNDEF IDE_2009up}

type
  PTokenUser = ^TTokenUser;

  _TOKEN_USER = record
    User: TSIDAndAttributes;
  end;
{$EXTERNALSYM _TOKEN_USER}

  TTokenUser = _TOKEN_USER;
  TOKEN_USER = _TOKEN_USER;
{$EXTERNALSYM TOKEN_USER}
{$ENDIF}

function rtcStartProcess(strProcess: String;
  out piOut: PProcessInformation; lpDesktop: String = 'winsta0\default'): DWORD;
var
  pi: TProcessInformation;
  si: STARTUPINFO;
  winlogonPid, dwSessionId: DWORD;
  hUserToken, hUserTokenDup, hPToken, hProcess: THANDLE;
  dwCreationFlags: DWORD;
  tp: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
  // lpEnv: Pointer;

begin
{$IFDEF ExtendLog}xLog('rtcStartProcess', LogAddon); {$ENDIF}
  { start process as elevated by cloning existing process, as we're running as admin... }
  Result := 0;
  try
    hProcess := 0;
    hUserToken := 0;
    hUserTokenDup := 0;
    hPToken := 0;
    try
      winlogonPid := rtcGetProcessID('winlogon.exe', true);
      APICheck(winlogonPid > 0, 'rtcGetProcessID');

      { get user token for winlogon and duplicate it... (this gives us admin rights) }
      dwSessionId := 0;
      if (Win32MajorVersion >= 6 { vista\server 2k8 } ) then
      begin
        dwSessionId := ActiveSessionID;
        APICheck(dwSessionId > 0, 'WTSGetActiveConsoleSessionId');
      end;

      if not WTSQueryUserToken(dwSessionId, hUserToken) then
      begin
{$IFDEF ExtendLog}xLog('Fallback ...', LogAddon); {$ENDIF}
        hUserToken := get_winlogon_handle;
{$IFDEF ExtendLog}xLog(Format('Fallback result: %d', [hUserToken]), LogAddon); {$ENDIF}
      end
      else
{$IFDEF ExtendLog}xLog(Format('WTSQueryUserToken result: %d', [hUserToken]), LogAddon); {$ENDIF}
      APICheck(hUserToken <> 0, 'usertoken error');

      dwCreationFlags := NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE;
      ZeroMemory(@si, Sizeof(STARTUPINFO));
      si.cb := Sizeof(STARTUPINFO);
      //si.lpDesktop := PChar('winsta0\default');
      si.lpDesktop := PChar(lpDesktop);
      ZeroMemory(@pi, Sizeof(pi));

      hProcess := OpenProcess(MAXIMUM_ALLOWED, False, winlogonPid);
      APICheck(hProcess > 0, 'OpenProcess');

      APICheck(OpenProcessToken(hProcess, TOKEN_ASSIGN_PRIMARY or
        TOKEN_ALL_ACCESS, hPToken), 'OpenProcessToken');
      APICheck(LookupPrivilegeValue(nil, SE_DEBUG_NAME, tp.Privileges[0].Luid),
        'LookupPrivilegeValue');
      tp.PrivilegeCount := 1;
      tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

      APICheck(LookupPrivilegeValue(nil, SE_TCB_NAME, tp.Privileges[0].Luid),
        'LookupPrivilegeValue');
      tp.PrivilegeCount := 1;
      tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

      APICheck(LookupPrivilegeValue(nil, SE_IMPERSONATE_NAME, tp.Privileges[0].Luid),
        'LookupPrivilegeValue');
      tp.PrivilegeCount := 1;
      tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

      APICheck(DuplicateTokenEx(hPToken, MAXIMUM_ALLOWED, nil,
        SecurityIdentification, TokenPrimary, hUserTokenDup),
        'DuplicateTokenEx');

      APICheck(SetTokenInformation(hUserTokenDup, TokenSessionId,
        Pointer(@dwSessionId), Sizeof(DWORD)), 'SetTokenInformation');
      APICheck(AdjustTokenPrivileges(hUserTokenDup, False, tp,
        Sizeof(TOKEN_PRIVILEGES), nil, ReturnLength), 'AdjustTokenPrivileges');

      { lpEnv := nil;
        try           // causes RtlCreateEnvironmentEx exceptions in win7 64
        Log('hUserTokenDup = '+inttostr(hUserTokenDup));
        if APICheck(CreateEnvironmentBlock(lpEnv, hUserTokenDup, TRUE), 'CreateEnvironmentBlock') then
        dwCreationFlags := dwCreationFlags or CREATE_UNICODE_ENVIRONMENT; //or STARTF_USESHOWWINDOW
        except
        end; }

      { launch the process in the client's logon session... }
      si.wShowWindow := SW_HIDE;
      SetLastError(0);
{$IFDEF ExtendLog}xLog(Format('CreateProcessAsUser: %s', [strProcess]), LogAddon); {$ENDIF}
      APICheck(CreateProcessAsUser(hUserTokenDup, // client's access token
        nil, // file to execute
        PChar(strProcess), // command line (exe and parameters)
        nil, // pointer to process SECURITY_ATTRIBUTES
        nil, // pointer to thread SECURITY_ATTRIBUTES
        False, // handles are not inheritable
        dwCreationFlags, // creation flags
        nil, // pointer to new environment block
        PChar(ExtractFilePath(strProcess)), // name of current directory
        si, // pointer to STARTUPINFO structure
        pi) // receives information about new process
        , 'CreateProcessAsUser');
      try
        Result := pi.dwThreadId;
        if piOut <> nil then
          piOut^ := pi;
      finally
        if piOut = nil then
        begin
          CloseHandle(pi.hProcess);
          CloseHandle(pi.hThread);
        end;
      end;
    finally
      { perform all the close handles tasks... }
      if hProcess > 0 then
        CloseHandle(hProcess);
      if hUserToken > 0 then
        CloseHandle(hUserToken);
      if hUserTokenDup > 0 then
        CloseHandle(hUserTokenDup);
      if hPToken > 0 then
        CloseHandle(hPToken);
    end;
  except
    on e: Exception do
    begin
      if not(e is EReportedException) then
        xLog(Format('Error: %s', [e.Message]), LogAddon);
      // eat all other exceptions as we're running in a service
    end;
  end;
end;

function rtcStartProcess(strProcess: String; lpDesktop: String = 'winsta0\default'):DWORD;
var piOut: PProcessInformation;
begin
  piOut:=nil;
  Result:=rtcStartProcess(strProcess,piOut);
end;

var
  CS: TCriticalSection;

  // Find the visible window station and switch to it
  // This would allow the service to be started non-interactive
  // Needs more supporting code & a redesign of the server core to
  // work, with better partitioning between server & UI components.

var
  home_window_station: HWINSTA;

function WinStationEnumProc(name: LPTSTR; param: LPARAM): BOOL; stdcall;
var
  station: HWINSTA;
  oldstation: HWINSTA;
  flags: USEROBJECTFLAGS;
  tmp: Cardinal;
  err: LongInt;
begin
  try
    RpcImpersonateClient(nil);
    station := OpenWindowStation(name, True, {GENERIC_ALL} MAXIMUM_ALLOWED);
    err := GetLastError;
    xLog('OpenWindowStation Name = ' + name + ' Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

    oldstation := GetProcessWindowStation;
    tmp := 0;
    if not GetUserObjectInformation(station, UOI_FLAGS, @flags,
      Sizeof(flags), tmp) then
      Result := True
    else
    begin
      if (flags.dwFlags and WSF_VISIBLE) <> 0 then
      begin
        if (SetProcessWindowStation(station)) then
        begin
    err := GetLastError;
    xLog('SetProcessWindowStation Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

          if (oldstation <> home_window_station) then
            CloseWindowStation(oldstation);
          Result := False; // success !!!
        end
        else
        begin
    err := GetLastError;
    xLog('SetProcessWindowStation Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

          CloseWindowStation(station);
          Result := True;
        end;
      end
      else
        Result := True;
    end;
  except
    Result := True;
  end;
end;

procedure SelectInputWinStation;
var
  flags: USEROBJECTFLAGS;
  tmp: Cardinal;
  err: LongInt;
  name: array[0..255] of Char;
  DesktopName: String;
  Count: DWORD;
begin
  home_window_station := 0;
  try
    tmp := 0;
    home_window_station := GetProcessWindowStation;
//    xLog('Home WinSta NAME = ' + GetUserObjectName(home_window_station));

    if not GetUserObjectInformation(home_window_station, UOI_FLAGS, @flags,
      Sizeof(flags), tmp) or ((flags.dwFlags and WSF_VISIBLE) = 0) then
    begin
      if EnumWindowStations(@WinStationEnumProc, 0) then
        home_window_station := 0;
    end;
  except
    home_window_station := 0;
  end;
end;

procedure SelectHomeWinStation;
var
  station: HWINSTA;
begin
  if home_window_station <> 0 then
  begin
    station := GetProcessWindowStation();
    SetProcessWindowStation(home_window_station);
    CloseWindowStation(station);
  end;
end;

//Если клиент запущен под SYSTEM. Иначе бессмысленно
procedure SwitchToActiveDesktop;
var
  InputDesktop, CurDesktop: HDESK;
//  name: array[0..255] of Char;
//  DesktopName: String;
//  Count: DWORD;
//  err: LongInt;
begin
  if not AutoDesktopSwitch then Exit;

  CS.Acquire;
  try
    SelectInputWinStation;

    InputDesktop := OpenInputDesktop(DF_ALLOWOTHERACCOUNTHOOK, False, READ_CONTROL or WRITE_DAC or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or DESKTOP_JOURNALPLAYBACK);
      {DESKTOP_ALL} {DESKTOP_CREATEMENU or
                          DESKTOP_CREATEWINDOW or
                          DESKTOP_ENUMERATE or
                          DESKTOP_HOOKCONTROL or
                          DESKTOP_WRITEOBJECTS or
                          DESKTOP_READOBJECTS or
                          DESKTOP_SWITCHDESKTOP or
                          GENERIC_WRITE} //MAXIMUM_ALLOWED);

//    err := GetLastError;
//    xLog('OpenInputDesktop LogonDesktop Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

    CurDesktop := GetThreadDesktop(GetCurrentThreadID);

    if (InputDesktop <> 0) and (GetUserObjectName(InputDesktop) <> GetUserObjectName(CurDesktop)) then
    begin
//      xLog('Try to Change ' + GetUserObjectName(CurDesktop) + ' to ' + GetUserObjectName(LogonDesktop));
      SetThreadDesktop(InputDesktop);
//      err := GetLastError;
//      xLog('Current desktop is ' + GetUserObjectName(GetThreadDesktop(GetCurrentThreadID)) + ' with error ' + IntToStr(err));
    end;
    CloseDesktop(CurDesktop);
    CloseDesktop(InputDesktop);
  finally
    CS.Release;
  end;
end;

initialization

LogAddon := 'Logon';
CS := TCriticalSection.Create;
SelectInputWinStation;

finalization

SelectHomeWinStation;
FreeAndNil(CS);
LogAddon := '';

end.
