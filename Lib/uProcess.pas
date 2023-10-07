unit uProcess;

interface

uses
  System.SysUtils, Winapi.Windows, System.Classes, System.Variants, rtcLog, PSApi, Math, TLHelp32, WTSApi,
  CommonData, ComCtrls, WbemScripting_TLB, ActiveX;

type
  LPPROFILEINFOA = ^PROFILEINFOA;
  {$EXTERNALSYM LPPROFILEINFOA}
  _PROFILEINFOA = record
    dwSize: DWORD;         // Set to sizeof(PROFILEINFO) before calling
    dwFlags: DWORD;        // See flags above
    lpUserName: LPSTR;     // User name (required)
    lpProfilePath: LPSTR;  // Roaming profile path (optional, can be NULL)
    lpDefaultPath: LPSTR;  // Default user profile path (optional, can be NULL)
    lpServerName: LPSTR;   // Validating domain controller name in netbios format (optional, can be NULL but group NT4 style policy won't be applied)
    lpPolicyPath: LPSTR;   // Path to the NT4 style policy file (optional, can be NULL)
    hProfile: THandle;      // Filled in by the function.  Registry key handle open to the root.
  end;
  {$EXTERNALSYM _PROFILEINFOA}
  PROFILEINFOA = _PROFILEINFOA;
  {$EXTERNALSYM PROFILEINFOA}
  TProfileInfoA = PROFILEINFOA;
  PProfileInfoA = LPPROFILEINFOA;

  LPPROFILEINFOW = ^PROFILEINFOW;
  {$EXTERNALSYM LPPROFILEINFOW}
  _PROFILEINFOW = record
    dwSize: DWORD;         // Set to sizeof(PROFILEINFO) before calling
    dwFlags: DWORD;        // See flags above
    lpUserName: LPWSTR;    // User name (required)
    lpProfilePath: LPWSTR; // Roaming profile path (optional, can be NULL)
    lpDefaultPath: LPWSTR; // Default user profile path (optional, can be NULL)
    lpServerName: LPWSTR;  // Validating domain controller name in netbios format (optional, can be NULL but group NT4 style policy won't be applied)
    lpPolicyPath: LPWSTR;  // Path to the NT4 style policy file (optional, can be NULL)
    hProfile: THandle;      // Filled in by the function.  Registry key handle open to the root.
  end;
  {$EXTERNALSYM _PROFILEINFOW}
  PROFILEINFOW = _PROFILEINFOW;
  {$EXTERNALSYM PROFILEINFOW}
  TProfileInfoW = PROFILEINFOW;
  PProfileInfoW = LPPROFILEINFOW;

  {$IFDEF UNICODE}
  PROFILEINFO = PROFILEINFOW;
  {$EXTERNALSYM PROFILEINFO}
  LPPROFILEINFO = LPPROFILEINFOW;
  {$EXTERNALSYM LPPROFILEINFO}
  TProfileInfo = TProfileInfoW;
  PProfileInfo = PProfileInfoW;
  {$ELSE}
  PROFILEINFO = PROFILEINFOA;
  {$EXTERNALSYM PROFILEINFO}
  LPPROFILEINFO = LPPROFILEINFOA;
  {$EXTERNALSYM LPPROFILEINFO}
  TProfileInfo = TProfileInfoA;
  PProfileInfo = PProfileInfoA;
  {$ENDIF UNICODE}

  PWTS_SESSION_INFOW = ^WTS_SESSION_INFOW;
  {$EXTERNALSYM PWTS_SESSION_INFOW}
  _WTS_SESSION_INFOW = record
    SessionId: DWORD;              // session id
    pWinStationName: LPWSTR;       // name of WinStation this session is connected to
    State: WTS_CONNECTSTATE_CLASS; // connection state (see enum)
  end;
  {$EXTERNALSYM _WTS_SESSION_INFOW}
  WTS_SESSION_INFOW = _WTS_SESSION_INFOW;
  {$EXTERNALSYM WTS_SESSION_INFOW}
  TWtsSessionInfoW = WTS_SESSION_INFOW;
  PWtsSessionInfoW = PWTS_SESSION_INFOW;

  PWTS_SESSION_INFOA = ^WTS_SESSION_INFOA;
  {$EXTERNALSYM PWTS_SESSION_INFOA}
  _WTS_SESSION_INFOA = record
    SessionId: DWORD;              // session id
    pWinStationName: LPSTR;        // name of WinStation this session is connected to
    State: WTS_CONNECTSTATE_CLASS; // connection state (see enum)
  end;
  {$EXTERNALSYM _WTS_SESSION_INFOA}
  WTS_SESSION_INFOA = _WTS_SESSION_INFOA;
  {$EXTERNALSYM WTS_SESSION_INFOA}
  TWtsSessionInfoA = WTS_SESSION_INFOA;
  PWtsSessionInfoA = PWTS_SESSION_INFOA;

  _WTS_PROCESS_INFO = record
    SessionId: DWORD;
    ProcessId: DWORD;
    pProcessName: LPTSTR;
    pUserSid: PSID;
  end;
  PWTS_PROCESS_INFO = ^_WTS_PROCESS_INFO;

  {$IFDEF UNICODE}
  WTS_SESSION_INFO = WTS_SESSION_INFOW;
  PWTS_SESSION_INFO = PWTS_SESSION_INFOW;
  TWtsSessionInfo = TWtsSessionInfoW;
  PWtsSessionInfo = PWtsSessionInfoW;
  {$ELSE}
  WTS_SESSION_INFO = WTS_SESSION_INFOA;
  PWTS_SESSION_INFO = PWTS_SESSION_INFOA;
  TWtsSessionInfo = TWtsSessionInfoA;
  PWtsSessionInfo = PWtsSessionInfoA;
  {$ENDIF UNICODE}

  TRunTokenTypes = (
    TTSystem,
    TTSession,
    TTExplorer,
    TTWinlogon);

  WTS_TYPE_CLASS = (WTSTypeProcessInfoLevel0, WTSTypeProcessInfoLevel1, WTSTypeSessionInfoLevel1);

const
  PI_NOUI = 1;
  PI_APPLYPOLICY = 2;

  SE_DEBUG_NAME = 'SeDebugPrivilege';
  SE_TCB_NAME = 'SeTcbPrivilege';
  SE_IMPERSONATE_NAME = 'SeImpersonatePrivilege';
  SE_ASSIGNPRIMARYTOKEN_NAME = 'SeAssignPrimaryTokenPrivilege';
  SE_INCREASE_QUOTA_NAME = 'SeIncreaseQuotaPrivilege';

  WTS_CURRENT_SERVER_HANDLE = THandle(0);
  HEAP_ZERO_MEMORY = $00000008;
  SID_REVISION     = 1; // Current revision level
  ERROR_ELEVATION_REQUIRED = 740;

  WTS_PROTOCOL_TYPE_CONSOLE = 0; // Console
  {$EXTERNALSYM WTS_PROTOCOL_TYPE_CONSOLE}
  WTS_PROTOCOL_TYPE_ICA     = 1; // ICA Protocol
  {$EXTERNALSYM WTS_PROTOCOL_TYPE_ICA}
  WTS_PROTOCOL_TYPE_RDP     = 2; // RDP Protocol
  {$EXTERNALSYM WTS_PROTOCOL_TYPE_RDP}

var
  gKernel32: HMODULE;

  {$IFDEF UNICODE}
  function VerifyVersionInfo(var LPOSVERSIONINFOEX : OSVERSIONINFOEX;dwTypeMask: DWORD;dwlConditionMask: int64): BOOL; stdcall; external kernel32 name 'VerifyVersionInfoW';
  {$ELSE}
  function VerifyVersionInfo(var LPOSVERSIONINFOEX : OSVERSIONINFOEX;dwTypeMask: DWORD;dwlConditionMask: int64): BOOL; stdcall; external kernel32 name 'VerifyVersionInfoA';
  {$ENDIF}
  function VerSetConditionMask(dwlConditionMask: ULONGLONG; dwTypeBitMask: DWORD; dwConditionMask: Byte): ULONGLONG; stdcall; external kernel32;

  function WTSEnumerateProcessesEx(hServer: THandle; var pLevel: DWORD; SessionID: DWORD; var ppSessionInfo: PWTS_PROCESS_INFO; var pCount: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSEnumerateProcessesExW';
  function IsProcessLaunched(ExeFileName: String): Boolean;
  procedure WTSFreeMemory(pMemory:pointer); stdcall; external 'Wtsapi32.dll' name 'WTSFreeMemory';
  function WTSEnumerateSessions(hServer: THandle; Reserved: DWORD; Version: DWORD; var ppSessionInfo: PWTS_SESSION_INFO; var pCount: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSEnumerateSessionsW';
  function CreateEnvironmentBlock(var lpEnvironment: Pointer; hToken: THandle; bInherit: BOOL): BOOL; stdcall; external 'userenv.dll';
  function DestroyEnvironmentBlock(lpEnvironment: Pointer): BOOL; stdcall; external 'userenv.dll';
  function UnloadUserProfile(Token: THandle; Profile: THandle): bool; stdcall; external 'userenv.dll';
  function WTSQueryUserToken(SessionId: DWORD; phToken: pHandle): bool; stdcall; external 'wtsapi32.dll';
  function GetActiveConsoleSessionID: DWORD;
  function GetCurrentSesstionState: WTS_CONNECTSTATE_CLASS;
  function ProcessStartedInSession(ProcessName: String; SessionID: Integer; var ProcessId: Cardinal): Boolean;
  function UserIsLoggedInSession(SessionID: Integer): Boolean;
  function WTSFreeMemoryEx(WTSTypeClass: WTS_TYPE_CLASS; pMemory: Pointer; NumberOfEntries: Integer): BOOL; stdcall; external 'wtsapi32.dll' name 'WTSFreeMemoryExW';

  function StartProcessAsUser(command, lpDesktop: String; SessionID: Integer; TokenType: TRunTokenTypes): Boolean;
  procedure xOutputDebugString(s: String);
  function NTSetPrivilege(sPrivilege: string; hToken: THandle; bEnabled: Boolean): Boolean;
  function IsWindowsServerPlatform: Boolean;
  function GetSystemUserName: String;
  function CreateAttachedProcess(const FileName, Params: String; WindowState: Word; var ProcessId: DWORD): Boolean;
  procedure GetLoggedInUsersSIDs(owner: TComponent; RemoteMachine, RemoteUser, RemotePassword: String; Users: TStrings);
  function GetUserProcessToken(ProcessName: String; SessionID: Integer): THandle;

implementation

procedure GetLoggedInUsersSIDs(owner: TComponent; RemoteMachine, RemoteUser, RemotePassword: String; Users: TStrings);
var
  Locator: TSWbemLocator;
  SinkClasses: TSWbemSink;

  Services:   ISWbemServices;
  ObjectSet:  ISWbemObjectSet;
  SObject,
  OutParam:    ISWbemObject;
  propSet :   ISWbemPropertySet;
  SProp,
  SProp1:      ISWbemProperty;
  propEnum,
  Enum:       IEnumVariant;
  tempObj:    OleVariant;
  Count,
  Value:      Cardinal;

  sValue,
  s:     String;
  strQuery:   WideString;
  Pos, i: Integer;
  fFound: Boolean;
begin
  Users.Clear;
  Locator:=TSWbemLocator.Create(owner);
  SinkClasses:=TSWbemSink.Create(owner);

  try
    SinkClasses.Cancel;

    if RemoteMachine='' then
      RemoteMachine:='.';// local machine
    Services := Locator.ConnectServer(RemoteMachine, 'root\CIMV2', RemoteUser, RemotePassword, '',
      '', 0, nil);

    ObjectSet := Services.InstancesOf('Win32_Process', wbemFlagReturnImmediately or wbemQueryFlagShallow, nil);

    Enum :=  (ObjectSet._NewEnum) as IEnumVariant;
    while (Enum.Next(1, tempObj, Value) = S_OK) do
    begin
      SObject := IUnknown(tempObj) as SWBemObject;
      propSet := SObject.Properties_;
      propEnum := (propSet._NewEnum) as IEnumVariant;
      while (propEnum.Next(1, tempObj, Value) = S_OK) do
      begin
        SProp := IUnknown(tempObj) as SWBemProperty;
        if SProp.Name<>'Name' then
          continue;
        // now get the value of the property
        sValue := '';
        if VarIsNull(SProp.Get_Value) then
          sValue := '<empty>'
        else
        case SProp.CIMType of
          wbemCimtypeSint8, wbemCimtypeUint8, wbemCimtypeSint16, wbemCimtypeUint16,
          wbemCimtypeSint32, wbemCimtypeUint32, wbemCimtypeSint64:
          if VarIsArray(SProp.Get_Value) then
          begin
            if VarArrayHighBound(SProp.Get_Value, 1) > 0 then
              for Count := 1 to VarArrayHighBound(SProp.Get_Value, 1) do
                sValue := sValue + ' ' + IntToStr(SProp.Get_Value[Count]);
          end
          else
            sValue := IntToStr(SProp.Get_Value);
          wbemCimtypeReal32, wbemCimtypeReal64:
            sValue := FloatToStr(SProp.Get_Value);
          wbemCimtypeBoolean:
            if SProp.Get_Value then
              sValue := 'True'
            else
              sValue := 'False';
          wbemCimtypeString, wbemCimtypeUint64:
          if VarIsArray(SProp.Get_Value) then
          begin
            if VarArrayHighBound(SProp.Get_Value, 1) > 0 then
              for Count := 1 to VarArrayHighBound(SProp.Get_Value, 1) do
                sValue := sValue + ' ' + SProp.Get_Value[Count];
          end
          else
            sValue :=  SProp.Get_Value;
          wbemCimtypeDatetime:
            sValue :=  SProp.Get_Value;
          wbemCimtypeReference:
          begin
            sValue := SProp.Get_Value;
            //This should be better implemented, but will do for now...
            Exception.Create('The result is an array of classes. This kind of data is not yet supported/implemented!');
          end;
          wbemCimtypeChar16:
            sValue := '<16-bit character>';
          wbemCimtypeObject:
            sValue := '<CIM Object>';
        else
            Exception.Create('Unknown type');
        end; {case}
        // got the value. now test for being "explorer.exe"
        if svalue<>'explorer.exe' then
          continue;

        // this is a connected user's session so add the user to the list
        OutParam:= SObject.ExecMethod_('getOwnerSID', nil, 0, nil);
        SProp1:= outParam.Properties_.Item('ReturnValue', 0);
        s:='';
        case SProp1.Get_Value of
          0:begin
//              SProp1:= outParam.Properties_.Item('User', 0);
//              s:=SProp1.Get_Value;
//              SProp1:= outParam.Properties_.Item('Domain', 0);
//              s:=s+'@'+SProp1.Get_Value;
              SProp1:= outParam.Properties_.Item('SID', 0);
              s:=SProp1.Get_Value
            end;
//          2:s:='Access denied';
//          3:s:='Insufficient privilege';
//          8:s:='Unknown failure';
//          9:s:='Path not found';
//          21:s:='Invalid parameter';
//          else s:='unknown error';
        end;

        if (Trim(s) <> '') then
        begin
          fFound := False;
          for i := 0 to users.Count - 1 do
            if users[i] = Trim(s) then
              fFound := True;

          if not fFound then
            users.Add(Trim(s));
        end;
      end; {while propEnum}
    end; {while Enum}

    strQuery := 'SELECT * FROM __InstanceCreationEvent within 5 WHERE TargetInstance' +
      ' ISA "Win32_Process"';
    Services.ExecNotificationQueryAsync(SinkClasses.DefaultInterface, strQuery, 'WQL', 0, nil, nil);
      strQuery := 'SELECT * FROM __InstanceDeletionEvent within 5 WHERE TargetInstance' +
      ' ISA "Win32_Process"';
    Services.ExecNotificationQueryAsync(SinkClasses.DefaultInterface, strQuery, 'WQL', 0, nil, nil);
  finally
  end; {try}
  Locator.Free;
  SinkClasses.Free;
  Services:=nil;// make sure the references are decreased
  ObjectSet:=nil;
  SObject:=nil;
  propSet:=nil;
  propEnum:=nil;
  SProp:=nil;
  enum:=nil;
end;

function GetSystemUserName: String;
var // Получить имя пользователя машины
  UserName: array[0..255] of Char;
  UserNameSize: DWORD;
begin
  UserNameSize := 255;
  if GetUserName(@UserName, UserNameSize) then
    Result := string(UserName)
  else
    Result := '';
end;

procedure xOutputDebugString(s: String);
begin
  OutputDebugString(PWideChar(WideString(s)));
end;

{function GetActiveConsoleSession: DWORD;
var
   pArrSessInfo, p: PWTS_SESSION_INFO;
   iNumSess: DWORD;
   i: Integer;
   pBuf: Pointer;
   ProtocolType: USHORT;
begin
  if WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, PWTS_SESSION_INFO(pArrSessInfo), iNumSess) then
  try
    p := pArrSessInfo;
    for i := 0 to iNumSess - 1 do
    begin
      if (p.SessionId < 1)
        or (p.SessionId > 65535) then
      begin
        Inc(p);
        Continue;
      end;

 //if WTSQuerySessionInformation      WTSClientName

//      UserName := '';
//      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSUserName, pBuf, iBufSize) then
//      begin
//        try
//          UserName := PChar(pBuf);
//        finally
//          WTSFreeMemory(pBuf);
//        end;
//      end; //if WTSQuerySessionInformation

      if not ProcessStartedInSession(HELPER_EXE_NAME, p.SessionId) then
//        if p.SessionId = WTSGetActiveConsoleSessionId then
//        if p.SessionId = 9 then
//        rtcStartProcess('C:\Base_1C\_vircess.com\_V11\VCL-V4\Win32\Debug\vcs_w32.exe', WTSGetActiveConsoleSessionId);
        StartProcessAsUser('C:\Base_1C\_vircess.com\_V11\VCL-V4\Demos\Clients\vcs_w32.exe', 'WinSta0\Winlogon', p.SessionId, TTWinlogon);
//        StartProcessAsUser('C:\Program Files (x86)\Vircess\vcs_w32.exe', 'WinSta0\Winlogon', p.SessionId, TTWinlogon);
//      if not ProcessStartedInSession('CALC.EXE', p.SessionId) then
//        StartProcessAsUser('calc.exe', 'Default', p.SessionId, False);
      Inc(p);
    end //for i
  finally
    WTSFreeMemory(pArrSessInfo);
  end;
end;}

function IsProcessLaunched(ExeFileName: String): Boolean;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName))
      or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName))) then
      Result := True;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
 end;

function BAD_HANDLE(x: THandle): Boolean;
begin
  Result := (x = 0) or (x = INVALID_HANDLE_VALUE);
end;

function NTSetPrivilege(sPrivilege: string; hToken: THandle; bEnabled: Boolean): Boolean;
var
  TokenPriv: TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
  bCloseToken: Boolean;
  gle: Long;
begin
  Result := True;
  // Only for Windows NT/2000/XP and later.
  if not (Win32Platform = VER_PLATFORM_WIN32_NT) then
    Exit;
  Result := False;
	bCloseToken := False;

  if hToken = 0 then
  begin
    // obtain the processes token
    if not OpenProcessToken(GetCurrentProcess(),
      TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
    begin
      Result := False;
      Exit;
    end;

 		bCloseToken := True;
  end;

  try
    // Get the locally unique identifier (LUID) .
    if LookupPrivilegeValue(nil, PChar(sPrivilege),
      TokenPriv.Privileges[0].Luid) then
    begin
      TokenPriv.PrivilegeCount := 1; // one privilege to set

      case bEnabled of
        True: TokenPriv.Privileges[0].Attributes  := SE_PRIVILEGE_ENABLED;
        False: TokenPriv.Privileges[0].Attributes := 0;
      end;

      ReturnLength := 0; // replaces a var parameter
      PrevTokenPriv := TokenPriv;

      // enable or disable the privilege

      AdjustTokenPrivileges(hToken, False, TokenPriv, SizeOf(PrevTokenPriv),
        PrevTokenPriv, ReturnLength);
    end
    else
      if(bCloseToken) then
        CloseHandle(hToken);
  finally
    if(bCloseToken) then
      CloseHandle(hToken);
  end;

  // test the return value of AdjustTokenPrivileges.
  Result := (GetLastError = ERROR_SUCCESS);
  if not Result then
  begin
    gle := GetLastError;
    xOutputDebugString('NTSetPrivilege - ' + sPrivilege + ': ' + SysErrorMessage(gle));
  end;
end;

function ConvertSid(Sid: PSID; pszSidText: PChar; var dwBufferLen: DWORD): BOOL;
var
  psia: PSIDIdentifierAuthority;
  dwSubAuthorities: DWORD;
  dwSidRev: DWORD;
  dwCounter: DWORD;
  dwSidSize: DWORD;
begin
  Result := False;

  dwSidRev := SID_REVISION;

  if not IsValidSid(Sid) then Exit;

  psia := GetSidIdentifierAuthority(Sid);

  dwSubAuthorities := GetSidSubAuthorityCount(Sid)^;

  dwSidSize := (15 + 12 + (12 * dwSubAuthorities) + 1) * SizeOf(Char);

  if (dwBufferLen < dwSidSize) then
  begin
    dwBufferLen := dwSidSize;
    SetLastError(ERROR_INSUFFICIENT_BUFFER);
    Exit;
  end;

  StrFmt(pszSidText, 'S-%u-', [dwSidRev]);

  if (psia.Value[0] <> 0) or (psia.Value[1] <> 0) then
    StrFmt(pszSidText + StrLen(pszSidText),
      '0x%.2x%.2x%.2x%.2x%.2x%.2x',
      [psia.Value[0], psia.Value[1], psia.Value[2],
      psia.Value[3], psia.Value[4], psia.Value[5]])
  else
    StrFmt(pszSidText + StrLen(pszSidText),
      '%u',
      [DWORD(psia.Value[5]) +
      DWORD(psia.Value[4] shl 8) +
      DWORD(psia.Value[3] shl 16) +
      DWORD(psia.Value[2] shl 24)]);

  dwSidSize := StrLen(pszSidText);

  for dwCounter := 0 to dwSubAuthorities - 1 do
  begin
    StrFmt(pszSidText + dwSidSize, '-%u',
      [GetSidSubAuthority(Sid, dwCounter)^]);
    dwSidSize := StrLen(pszSidText);
  end;

  Result := True;
end;

function ObtainTextSid(hToken: THandle; pszSid: PChar;
    var dwBufferLen: DWORD): BOOL;
var
  dwReturnLength: DWORD;
  dwTokenUserLength: DWORD;
  tic: TTokenInformationClass;
  ptu: Pointer;
begin
  Result := False;
  dwReturnLength := 0;
  dwTokenUserLength := 0;
  tic := TokenUser;
  ptu := nil;

  if not GetTokenInformation(hToken, tic, ptu, dwTokenUserLength,
    dwReturnLength) then
  begin
    if GetLastError = ERROR_INSUFFICIENT_BUFFER then
    begin
      ptu := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwReturnLength);
      if ptu = nil then Exit;
      dwTokenUserLength := dwReturnLength;
      dwReturnLength    := 0;

      if not GetTokenInformation(hToken, tic, ptu, dwTokenUserLength,
        dwReturnLength) then Exit;
    end
     else
       Exit;
  end;

  if not ConvertSid((PTokenUser(ptu).User).Sid, pszSid, dwBufferLen) then Exit;

  if not HeapFree(GetProcessHeap, 0, ptu) then Exit;

  Result := True;
end;

function GetTokenUserSID(hToken: THandle): String;
var
  dwBufferLen: DWORD;
  szSid: array[0..260] of Char;
//  tmp: DWORD;
//  userName: String;
//  sidNameSize: DWORD;
begin
{	tmp := 0;
//	sidNameSize := 64;
//	std::vector<WCHAR> sidName;
//	sidName.resize(sidNameSize);
//
//	DWORD sidDomainSize = 64;
//	std::vector<WCHAR> sidDomain;
//	sidDomain.resize(sidNameSize);

//	DWORD userTokenSize = 1024;
//	std::vector<WCHAR> tokenUserBuf;
//	tokenUserBuf.resize(userTokenSize);

	TOKEN_USER *userToken = (TOKEN_USER*)&tokenUserBuf.front();

	if(GetTokenInformation(hToken, TokenUser, userToken, userTokenSize, &tmp)) then
	begin
		WCHAR *pSidString = NULL;
		if(ConvertSidToStringSid(userToken->User.Sid, &pSidString))
			userName = pSidString;
		if(NULL != pSidString)
			LocalFree(pSidString);
	end;
//	else
//		_ASSERT(0);}

//	Result := userName;

  ZeroMemory(@szSid, SizeOf(szSid));
  dwBufferLen := SizeOf(szSid);

  if ObtainTextSid(hToken, szSid, dwBufferLen) then
    Result := szSid
  else
    Result := '';
end;

function GetUserSessionToken(SessionID: Integer): THandle;
var
   hToken: THandle;
begin
//https://github.com/murrayju/CreateProcessAsUser/blob/master/ProcessExtensions/ProcessExtensions.cs
  if not WTSQueryUserToken(SessionID, @Result) then
    Result := 0;
end;

{function GetExplorerUserProcessToken(SessionID: Integer): THandle;
var
   pArrProcessInfo, p: PWTS_PROCESS_INFO;
   iNumProc: DWORD;
   i: Integer;
   pLevel, dwPid: DWORD;
   hProcess,
   hToken: THandle;
begin
  pLevel := 0;
  iNumProc := 0;
  if WTSEnumerateProcessesEx(WTS_CURRENT_SERVER_HANDLE, pLevel, SessionID, PWTS_PROCESS_INFO(pArrProcessInfo), iNumProc) then
  try
    p := pArrProcessInfo;
    for i := 0 to iNumProc - 1 do
    begin
      if UpperCase(p.pProcessName) = 'EXPLORER.EXE' then
      begin
  			hToken := 0;
        hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, p.ProcessId);
        if hProcess > 0 then
        begin
          if (OpenProcessToken(hProcess, TOKEN_QUERY or TOKEN_READ or TOKEN_IMPERSONATE or TOKEN_QUERY_SOURCE or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_EXECUTE, hToken)) then
					begin
						CloseHandle(hProcess);
						Result := hToken;
            Exit;
					end
          else
			      CloseHandle(hToken);
        end;

        CloseHandle(hProcess);
      end;

      Inc(p);
    end
  finally
    WTSFreeMemoryEx(WTSTypeProcessInfoLevel0, pArrProcessInfo, iNumProc);
    pArrProcessInfo := nil;
    p := nil;
  end;

  Result := 0;
end;}

function GetUserProcessToken(ProcessName: String; SessionID: Integer): THandle;
var
   pArrProcessInfo, p: PWTS_PROCESS_INFO;
   iNumProc: DWORD;
   i: Integer;
   pLevel, dwPid: DWORD;
   hProcess,
   hToken: THandle;
begin
  pLevel := 0;
  iNumProc := 0;
  if WTSEnumerateProcessesEx(WTS_CURRENT_SERVER_HANDLE, pLevel, SessionID, PWTS_PROCESS_INFO(pArrProcessInfo), iNumProc) then
  try
    p := pArrProcessInfo;
    for i := 0 to iNumProc - 1 do
    begin
      if UpperCase(p.pProcessName) = 'TASKMGR.EXE' then
      begin
  			hToken := 0;
        hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, p.ProcessId);
        if hProcess > 0 then
        begin
          if (OpenProcessToken(hProcess, TOKEN_QUERY or TOKEN_READ or TOKEN_IMPERSONATE or TOKEN_QUERY_SOURCE or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_EXECUTE, hToken)) then
					begin
						CloseHandle(hProcess);
						Result := hToken;
            Exit;
					end
          else
			      CloseHandle(hToken);
        end;

        CloseHandle(hProcess);
      end;

      Inc(p);
    end
  finally
    WTSFreeMemoryEx(WTSTypeProcessInfoLevel0, pArrProcessInfo, iNumProc);
    pArrProcessInfo := nil;
    p := nil;
  end;

  Result := 0;
end;

{function GetWinlogonUserProcessToken(SessionID: Integer): THandle;
var
   pArrProcessInfo, p: PWTS_PROCESS_INFO;
   iNumProc: DWORD;
   i: Integer;
   pLevel, dwPid: DWORD;
   hProcess,
   hToken: THandle;
begin
  pLevel := 0;
  iNumProc := 0;
  if WTSEnumerateProcessesEx(WTS_CURRENT_SERVER_HANDLE, pLevel, SessionID, PWTS_PROCESS_INFO(pArrProcessInfo), iNumProc) then
  try
    p := pArrProcessInfo;
    for i := 0 to iNumProc - 1 do
    begin
      if UpperCase(p.pProcessName) = 'WINLOGON.EXE' then
      begin
  			hToken := 0;
        hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, p.ProcessId);
        if hProcess > 0 then
        begin
          if (OpenProcessToken(hProcess, TOKEN_QUERY or TOKEN_READ or TOKEN_IMPERSONATE or TOKEN_QUERY_SOURCE or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_EXECUTE, hToken)) then
					begin
						CloseHandle(hProcess);
						Result := hToken;
            Exit;
					end
          else
			      CloseHandle(hToken);
        end;

        CloseHandle(hProcess);
      end;

      Inc(p);
    end
  finally
    WTSFreeMemoryEx(WTSTypeProcessInfoLevel0, pArrProcessInfo, iNumProc);
    pArrProcessInfo := nil;
    p := nil;
  end;

  Result := 0;
end;}

function GetLocalSystemProcessToken: THandle;
var
  gle: DWORD;
  pids: array [0..1024] of DWORD;
  cbNeeded: DWORD;
  dwPid, i: DWORD;
  name: String;
  hProcess, hToken: THandle;
  BufferSize, cProcesses: Cardinal;
begin
	cbNeeded := 0;
  BufferSize := 1024;

	if (not EnumProcesses(@pids, BufferSize, cbNeeded)) then
	begin
		xOutputDebugString('Can''t enumProcesses - Failed to get token for user.');
		Result := 0;
    Exit
	end;

	// Calculate how many process identifiers were returned.
  cProcesses := cbNeeded div sizeof(DWORD) - 1;
  i := 0;
	while i < cProcesses do
	begin
		gle := 0;
		dwPid := pids[i];
		hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, dwPid);
		if hProcess > 0 then
		begin
			hToken := 0;
			if (OpenProcessToken(hProcess, TOKEN_QUERY or TOKEN_READ or TOKEN_IMPERSONATE or TOKEN_QUERY_SOURCE or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_EXECUTE, hToken)) then
			begin
				try
				begin
					name := GetTokenUserSID(hToken);

					if(name = 'S-1-5-18') then //Well known SID for Local System
					begin
						CloseHandle(hProcess);
						Result := hToken;
            Exit;
					end;
				end;
				except
//					_ASSERT(0);
				end;
			end
			else
				gle := GetLastError();
			CloseHandle(hToken);
		end
		else
			gle := GetLastError();
		CloseHandle(hProcess);

    i := i + 1;
	end;

  xOutputDebugString('Failed to get token for local system account');
	Result := 0;
end;

procedure Duplicate(var h: THANDLE);
var
  hDupe: THandle;
  gle: DWORD;
begin
	hDupe := 0;
	if(DuplicateTokenEx(h, {TOKEN_ALL_ACCESS} MAXIMUM_ALLOWED, nil, SecurityImpersonation, TokenPrimary, hDupe)) then
  begin
		CloseHandle(h);
		h := hDupe;
		hDupe := 0;
	end
	else
	begin
		gle := GetLastError();
		xOutputDebugString(Format('Error duplicating a user token (%d)', [gle]));
	end;
end;

function GetUserHandle(var hUser: THandle; bLoadedProfile: Boolean; profile: PROFILEINFO; SessionID: Integer; TokenType: TRunTokenTypes): Boolean;
var
  gle: DWORD;
begin
  gle := 0;

  if(BAD_HANDLE(hUser)) then //might already have hUser from a previous call
  begin
    NTSetPrivilege(SE_DEBUG_NAME, 0, True); //helps with OpenProcess, required for GetLocalSystemProcessToken
    if TokenType = TTSystem then
      hUser := GetLocalSystemProcessToken()
    else
    if TokenType = TTSession then
      hUser := GetUserSessionToken(SessionID)
    else
    if TokenType = TTExplorer then
    begin
//      while True do
//      begin
        hUser := GetUserProcessToken('EXPLORER.EXE', SessionID);
//        if hUser = 0 then
//          Sleep(100)
//        else
//          Break;
//      end;
    end
    else
    if TokenType = TTWinlogon then
    begin
//      while True do
//      begin
        hUser := GetUserProcessToken('WINLOGON.EXE', SessionID);
//        if hUser = 0 then
//          Sleep(100)
//        else
//          Break;
//      end;
    end;

    if BAD_HANDLE(hUser) then
    begin
      xOutputDebugString('Not able to get token');
      Result := false;
      Exit;
    end;
//    else
//      xOutputDebugString('Got user handle');

    Duplicate(hUser);
  end;
  Result := True;
end;

{function GetProcedureAddress(var P: Pointer; const ModuleName, ProcName: String;
  var pModule: HMODULE): Boolean;
var
  ModuleHandle: HMODULE;
begin
  if not Assigned(P) then
  begin
    ModuleHandle := GetModuleHandle(PChar(ModuleName));
    if ModuleHandle = 0 then
      ModuleHandle := LoadLibrary(PChar(ModuleName));
    if ModuleHandle <> 0 then
      P := Pointer(GetProcAddress(ModuleHandle, PChar(ProcName)));
    Result := Assigned(P);
  end
  else
    Result := True;
end;}

function GetActiveConsoleSessionID: DWORD;
var
  SessionId, Count, iBufSize, i: DWORD;
  pSessionInfo, p: PWTS_SESSION_INFO;
  hMod: HMODULE;
  pBuf: Pointer;
  ProtocolType: USHORT;
  ConnectState: WTS_CONNECTSTATE_CLASS;
begin
	// Get the active session ID.
	SessionId := 0;
	pSessionInfo := nil;
	Count := 0;

	if (WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, pSessionInfo, Count)) then
	begin
    i := 0;
    p := pSessionInfo;
//    xOutputDebugString('Sessions count = ' + IntToStr(Count));
		while i < Count do
    begin
      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSClientProtocolType, pBuf, iBufSize) then
      begin
        try
          ProtocolType := USHORT(pBuf^);
        finally
          WTSFreeMemory(pBuf);
        end;
      end;
      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSConnectState, pBuf, iBufSize) then
      begin
        try
          ConnectState := WTS_CONNECTSTATE_CLASS(pBuf^);
        finally
          WTSFreeMemory(pBuf);
        end;
      end;
      if (ProtocolType = WTS_PROTOCOL_TYPE_CONSOLE)
  			and (ConnectState = WTSActive)
        and (p.SessionId <= 65535) then
        begin
	  			SessionId := p.SessionId;
          Break;
        end;

      i := i + 1;
      Inc(p);
		end;
		WTSFreeMemory(pSessionInfo);
	end
  else
    xOutputDebugString('WTSEnumerateSessions Error: ' + IntToStr(GetLastError));

	if(SessionId = 0) then
    try
		  SessionId := WTSGetActiveConsoleSessionId;  //В службе не срабатывает???
    finally
    end;
  if (SessionId = 0) then
    xOutputDebugString('WTSGetActiveConsoleSessionId not supported on this OS');

	Result := SessionId;
end;

function GetCurrentSesstionState: WTS_CONNECTSTATE_CLASS;
var
  iBufSize: DWORD;
  pBuf: Pointer;
begin
  Result := WTSActive;
  if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, CurrentSessionID, WTSConnectState, pBuf, iBufSize) then
  begin
    try
      Result := WTS_CONNECTSTATE_CLASS(pBuf^);
    finally
      WTSFreeMemory(pBuf);
    end;
  end;
end;

function PrepForInteractiveProcess(var hUser: THandle; var origSessionID: DWORD; var bPreped: Boolean; sessionID: DWORD): Boolean;
var
  targetSessionID, returnedLen: DWORD;
begin
	bPreped := True;

	Duplicate(hUser);
	hUser := hUser;

	targetSessionID := sessionID;

	xOutputDebugString(Format('Using SessionID %u', [targetSessionID]));

	returnedLen := 0;
	GetTokenInformation(hUser, TokenSessionId, @origSessionID, sizeof(origSessionID), returnedLen);

	NTSetPrivilege(SE_TCB_NAME, hUser, True);

	if(not SetTokenInformation(hUser, TokenSessionId, @targetSessionID, sizeof(targetSessionID))) then
		xOutputDebugString('Failed to set interactive token');

	Result := True;
end;

procedure CleanUpInteractiveProcess(hUser: THandle; var origSessionID: DWORD);
begin
	SetTokenInformation(hUser, TokenSessionId, @origSessionID, sizeof(origSessionID));

	//// Allow logon SID full access to interactive window station.
	//RemoveAceFromWindowStation(hwinsta, pSid);

	//// Allow logon SID full access to interactive desktop.
	//RemoveAceFromDesktop(hdesk, pSid);

	//// Free the buffer for the logon SID.
	//if (pSid)
	//	FreeLogonSID(&pSid);
	//pSid = NULL;

	//// Close the handles to the interactive window station and desktop.
	//if (hwinsta)
	//	CloseWindowStation(hwinsta);
	//hwinsta = NULL;

	//if (hdesk)
	//	CloseDesktop(hdesk);
	//hdesk = NULL;
end;

function UserIsLoggedInSession(SessionID: Integer): Boolean;
var
  buf: Pointer;
  Buflen: DWORD;
begin
  Result := False;

  if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, SessionID, WTSUserName, buf, Buflen) then
  begin
    try
      Result := (PChar(buf) <> '');
    finally
      WTSFreeMemory(buf);
    end;
  end;
end;

function ProcessStartedInSession(ProcessName: String; SessionID: Integer; var ProcessId: Cardinal): Boolean;
var
   pArrProcessInfo, p: PWTS_PROCESS_INFO;
   iNumProc: DWORD;
   i: Integer;
   pLevel: DWORD;
begin
  Result := False;
  pLevel := 0;
  ProcessId := 0;
  iNumProc := 0;
  if WTSEnumerateProcessesEx(WTS_CURRENT_SERVER_HANDLE, pLevel, SessionID, pArrProcessInfo, iNumProc) then
  try
    p := pArrProcessInfo;
    for i := 0 to iNumProc - 1 do
    begin
      if UpperCase(p.pProcessName) = UpperCase(ProcessName) then
      begin
        ProcessId := p.ProcessId;
        Result := True;
        Break;
      end;
      Inc(p);
    end;
  finally
    WTSFreeMemoryEx(WTSTypeProcessInfoLevel0, pArrProcessInfo, iNumProc);
    pArrProcessInfo := nil;
    p := nil;
  end;
end;

function CreateAttachedProcess(const FileName, Params: String; WindowState: Word; var ProcessId: DWORD): Boolean;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CmdLine: string;
begin
  CmdLine := '"' + FileName + '" ' + Params;
  FillChar(SUInfo, SizeOf(SUInfo), #0);
  with SUInfo do
  begin
    cb:= SizeOf(SUInfo);
    dwFlags:= CREATE_NO_WINDOW;
    wShowWindow := WindowState;
  end;

  Result := CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_NEW_PROCESS_GROUP or NORMAL_PRIORITY_CLASS, nil, PChar(ExtractFilePath(FileName)), SUInfo, ProcInfo);
  ProcessId := ProcInfo.dwProcessId;
end;

function StartProcessAsUser(command, lpDesktop: String; SessionID: Integer; TokenType: TRunTokenTypes): Boolean;
var
  gle, dwFlags, origSessionID: DWORD;
  bLoadedProfile, bLaunched, bImpersonated: Boolean;
  profile: TProfileInfo;
  hUser: THandle;
  si: STARTUPINFO;
  pi: PROCESS_INFORMATION;
  startingDir: LPCWSTR;
  launchGLE: DWORD;
  b, bPreped: Boolean;
  pEnvironment: Pointer;
  hCmdPipe: THandle;
begin
	//Launching as one of:
	//1. System Account
	//2. Specified account (or limited account)
	//3. As current process

  xOutputDebugString('Starting ' + ExtractFileName(command) + ' in session ' + IntToStr(SessionID));

  hCmdPipe := 0;
	gle := 0;
  hUser := INVALID_HANDLE_VALUE;

	bLoadedProfile := False;
  ZeroMemory(@profile, Sizeof(TProfileInfo));
	profile.dwSize := SizeOf(profile);
	profile.lpUserName := '';
	profile.dwFlags := PI_NOUI;

	if (not GetUserHandle(hUser, bLoadedProfile, profile, SessionID, TokenType)) then
  begin
		Result := False;
    Exit;
  end;

  ZeroMemory(@pi, Sizeof(PROCESS_INFORMATION));

  ZeroMemory(@si, Sizeof(STARTUPINFO));
	si.cb := SizeOf(si);
	si.dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEOFFFEEDBACK;
	si.wShowWindow := SW_SHOW;
//#ifdef _DEBUG
//	else
//		Log(L"DEBUG: Not using redirected IO", false);
//#endif

	startingDir := nil;

	launchGLE := 0;

  bPreped := False;
  b := PrepForInteractiveProcess(hUser, origSessionID, bPreped, SessionID);
  if (not b) then
    xOutputDebugString('Failed to PrepForInteractiveProcess');

  if (lpDesktop = '') then
    si.lpDesktop := 'WinSta0\Default'
  else
    si.lpDesktop := PChar(lpDesktop);
//			si.lpDesktop = 'winsta0\Winlogon';
  //Log(StrFormat(L"Using desktop: %s", si.lpDesktop), false);
  //http://blogs.msdn.com/b/winsdk/archive/2009/07/14/launching-an-interactive-process-from-windows-service-in-windows-vista-and-later.aspx
  //indicates desktop names are case sensitive

//#ifdef _DEBUG
//	Log(StrFormat('DEBUG: PAExec using desktop %s', si.lpDesktop == NULL ? default : si.lpDesktop), false);
//#endif

	dwFlags := CREATE_SUSPENDED or CREATE_NEW_CONSOLE {or DETACHED_PROCESS};

	pEnvironment := nil;
  if (CreateEnvironmentBlock(pEnvironment, hUser, True)) then
  begin
    dwFlags := dwFlags or CREATE_UNICODE_ENVIRONMENT; // or PROFILE_USER
  end
  else
  begin
	  xOutputDebugString('CreateEnvironmentBlock: Error: ' + IntToStr(GetLastError()));

    pEnvironment := nil;
  end;

//#ifdef _DEBUG
//	gle = GetLastError();
//	Log(L"DEBUG: CreateEnvironmentBlock", gle);
//#endif

//	std::wstring user, domain;
//	GetUserDomain(settings.user.c_str(), user, domain);

//#ifdef _DEBUG
//	Log(StrFormat(L"DEBUG: U:%s D:%s P:%s bP:%d Env:%s WD:%s",
//		user, domain, settings.password, settings.bDontLoadProfile,
//		pEnvironment ? L"true" : L"null", startingDir ? startingDir : L"null"), false);
//#endif

	bLaunched := False;

  if (BAD_HANDLE(hUser)) then
    xOutputDebugString('Have bad user handle');

  NTSetPrivilege(SE_IMPERSONATE_NAME, 0, True);
  bImpersonated := ImpersonateLoggedOnUser(hUser);
  if (not bImpersonated) then
  begin
    xOutputDebugString('Failed to impersonate');
//			_ASSERT(bImpersonated);
  end;
  NTSetPrivilege(SE_ASSIGNPRIMARYTOKEN_NAME, 0, True);
  NTSetPrivilege(SE_INCREASE_QUOTA_NAME, 0, True);
  UniqueString(command);
  bLaunched := CreateProcessAsUser(hUser, nil, PChar(command), nil, nil, True, dwFlags, pEnvironment, startingDir, si, pi);
  launchGLE := GetLastError();
  if not bLaunched then
    xOutputDebugString('CreateProcessAsUser ' + command + ' err = ' + IntToStr(launchGLE) + ' ' + SysErrorMessage(launchGLE));

//#ifdef _DEBUG
//		if (0 != launchGLE)
//			Log(StrFormat('Launch (launchGLE=%u) params: user=[x%X] path=[%s] flags=[x%X], pEnv=[%s], dir=[%s], stdin=[x%X], stdout=[x%X], stderr=[x%X]',
//				launchGLE, (DWORD)settings.hUser, path, dwFlags, pEnvironment ? env : null, startingDir ? startingDir : 'null',
//				(DWORD)si.hStdInput, (DWORD)si.hStdOutput, (DWORD)si.hStdError), false);
//#endif

	RevertToSelf();

	if (bLaunched) then
	begin
		SetPriorityClass(pi.hProcess, 0);
		ResumeThread(pi.hThread);
		CloseHandle(pi.hThread);
	end
	else
	begin
		xOutputDebugString('Failed to start ' + command);
		if (launchGLE = ERROR_ELEVATION_REQUIRED) then
      xOutputDebugString('HINT: Helper probably needs to be "Run As Administrator"');
	end;

	if (bPreped) then
		CleanUpInteractiveProcess(hUser, origSessionID);

	if (pEnvironment <> nil) then
		DestroyEnvironmentBlock(pEnvironment);
	pEnvironment := nil;

	if (bLoadedProfile) then
		UnloadUserProfile(hUser, profile.hProfile);

	if (not BAD_HANDLE(hUser)) then
	begin
		CloseHandle(hUser);
		hUser := INVALID_HANDLE_VALUE;
	end;

	Result := bLaunched;
end;

function IsWindowsServerPlatform: Boolean;
const
  VER_NT_SERVER      = $0000003;
  VER_EQUAL          = 1;
  VER_GREATER_EQUAL  = 3;
var
  osvi             : OSVERSIONINFOEX;
  dwlConditionMask : DWORDLONG;
  op               : Integer;
begin
  dwlConditionMask := 0;
  op := VER_GREATER_EQUAL;

  ZeroMemory(@osvi, sizeof(OSVERSIONINFOEX));
  osvi.dwOSVersionInfoSize := sizeof(OSVERSIONINFOEX);
  osvi.dwMajorVersion := 5;
  osvi.dwMinorVersion := 0;
  osvi.wServicePackMajor := 0;
  osvi.wServicePackMinor := 0;
  osvi.wProductType := VER_NT_SERVER;

  dwlConditionMask := VerSetConditionMask(dwlConditionMask, VER_MAJORVERSION, op);
  dwlConditionMask := VerSetConditionMask(dwlConditionMask, VER_MINORVERSION, op);
  dwlConditionMask := VerSetConditionMask(dwlConditionMask, VER_SERVICEPACKMAJOR, op);
  dwlConditionMask := VerSetConditionMask(dwlConditionMask, VER_SERVICEPACKMINOR, op);
  dwlConditionMask := VerSetConditionMask(dwlConditionMask, VER_PRODUCT_TYPE, VER_EQUAL);

  Result := VerifyVersionInfo(osvi,VER_MAJORVERSION OR VER_MINORVERSION OR
    VER_SERVICEPACKMAJOR OR VER_SERVICEPACKMINOR OR VER_PRODUCT_TYPE, dwlConditionMask);
end;

end.
