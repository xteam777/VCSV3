Unit Wtsapi;

interface

{
Copyright(c) By Thomas Stutz
Date: 10. April 2002
Version: 1.0.0
}

uses
  Windows, SysUtils;

const
  WINSTATIONNAME_LENGTH = 32;
  USERNAME_LENGTH = 20;
  DOMAIN_LENGTH = 17;

type
  //WTS_CONNECTSTATE_CLASS - Session connect state
  _WTS_CONNECTSTATE_CLASS = (
    WTSActive,              // User logged on to WinStation
    WTSConnected,           // WinStation connected to client
    WTSConnectQuery,        // In the process of connecting to client
    WTSShadow,              // Shadowing another WinStation
    WTSDisconnected,        // WinStation logged on without client
    WTSIdle,                // Waiting for client to connect
    WTSListen,              // WinStation is listening for connection
    WTSReset,               // WinStation is being reset
    WTSDown,                // WinStation is down due to error
    WTSInit);               // WinStation in initialization
  {$EXTERNALSYM _WTS_CONNECTSTATE_CLASS}
  WTS_CONNECTSTATE_CLASS = _WTS_CONNECTSTATE_CLASS;
  {$EXTERNALSYM WTS_CONNECTSTATE_CLASS}
  TWtsConnectStateClass = WTS_CONNECTSTATE_CLASS;

  PWTS_SESSION_INFO = ^WTS_SESSION_INFO;
  WTS_SESSION_INFO = record
    SessionId: DWORD;              // session id
    pWinStationName: LPSTR;        // name of WinStation this session is connected to
    State: WTS_CONNECTSTATE_CLASS; // connection state (see enum)
  end;

  WTS_INFO_CLASS = (
    WTSInitialProgram,
    WTSApplicationName,
    WTSWorkingDirectory,
    WTSOEMId,
    WTSSessionId,
    WTSUserName,
    WTSWinStationName,
    WTSDomainName,
    WTSConnectState,
    WTSClientBuildNumber,
    WTSClientName,
    WTSClientDirectory,
    WTSClientProductId,
    WTSClientHardwareId,
    WTSClientAddress, //Returns pointer to a WTS_CLIENT_ADDRESS - structure
    WTSClientDisplay,
    WTSClientProtocolType,
    WTSIdleTime,
    WTSLogonTime,
    WTSIncomingBytes,
    WTSOutgoingBytes,
    WTSIncomingFrames,
    WTSOutgoingFrames,
    WTSClientInfo,
    WTSSessionInfo,
    WTSSessionInfoEx,
    WTSConfigInfo,
    WTSValidationInfo,
    WTSSessionAddressV4,
    WTSIsRemoteSession);

  WTSINFOEX_LEVEL_W = record
    SessionId: ULONG;
    SessionState: WTS_CONNECTSTATE_CLASS;
    SessionFlags: LONG;
    WinStationName: array[0..WINSTATIONNAME_LENGTH + 1] of WCHAR;
    UserName: array[0..USERNAME_LENGTH + 1] of WCHAR;
    DomainName: array[0..DOMAIN_LENGTH + 1] of WCHAR;
    LogonTime: LARGE_INTEGER;
    ConnectTime: LARGE_INTEGER;
    DisconnectTime: LARGE_INTEGER;
    LastInputTime: LARGE_INTEGER;
    CurrentTime: LARGE_INTEGER;
    IncomingBytes: DWORD;
    OutgoingBytes: DWORD;
    IncomingFrames: DWORD;
    OutgoingFrames: DWORD;
    IncomingCompressedBytes: DWORD;
    OutgoingCompressedBytes: DWORD;
  end;

  WTSINFOEXW = record
    Level: DWORD;
    Data: WTSINFOEX_LEVEL_W;
  end;
  PWTSINFOEXW = ^WTSINFOEXW;

  PWTS_CLIENT_ADDRESS = ^WTS_CLIENT_ADDRESS;
  WTS_CLIENT_ADDRESS = record
    AddressFamily: DWORD;           // AF_INET, AF_IPX, AF_NETBIOS, AF_UNSPEC
    Address: array [0..19] of BYTE; // client network address
  end;

const
  AF_INET      = 2; // internetwork: UDP, TCP, etc.
  AF_NS        = 6; // XEROX NS protocols
  AF_IPX       = AF_NS; // IPX protocols: IPX, SPX, etc.
  AF_NETBIOS   = 17; // NetBios-style addresses
  AF_UNSPEC    = 0; // unspecified

  //  Specifies the current server
  WTS_CURRENT_SERVER_HANDLE = THandle(0);
  // The WM_WTSSESSION_CHANGE message notifies applications of changes in session state.
  WM_WTSSESSION_CHANGE = $2B1;

  // WTS_EVENT - Event flags for WTSWaitSystemEvent
  WTS_EVENT_NONE        = $00000000; // return no event
  WTS_EVENT_CREATE      = $00000001; // new WinStation created
  WTS_EVENT_DELETE      = $00000002; // existing WinStation deleted
  WTS_EVENT_RENAME      = $00000004; // existing WinStation renamed
  WTS_EVENT_CONNECT     = $00000008; // WinStation connect to client
  WTS_EVENT_DISCONNECT  = $00000010; // WinStation logged on without client
  WTS_EVENT_LOGON       = $00000020; // user logged on to existing WinStation
  WTS_EVENT_LOGOFF      = $00000040; // user logged off from existing WinStation
  WTS_EVENT_STATECHANGE = $00000080; // WinStation state change
  WTS_EVENT_LICENSE     = $00000100; // license state change
  WTS_EVENT_ALL         = $7fffffff; // wait for all event types
  WTS_EVENT_FLUSH       = DWORD($80000000); // unblock all waiters

  // wParam values:
  WTS_CONSOLE_CONNECT = 1;
  WTS_CONSOLE_DISCONNECT = 2;
  WTS_REMOTE_CONNECT = 3;
  WTS_REMOTE_DISCONNECT = 4;
  WTS_SESSION_LOGON = 5;
  WTS_SESSION_LOGOFF = 6;
  WTS_SESSION_LOCK = 7;
  WTS_SESSION_UNLOCK = 8;
  WTS_SESSION_REMOTE_CONTROL = 9;

  // Only session notifications involving the session attached to by the window
  // identified by the hWnd parameter value are to be received.
  NOTIFY_FOR_THIS_SESSION = 0;
  // All session notifications are to be received.
  NOTIFY_FOR_ALL_SESSIONS = 1;


  function WTSQueryUserToken(SessionId: DWORD; phToken: THandle): BOOL; stdcall; external 'wtsapi32.dll';
  function RegisterSessionNotification(Wnd: HWND; dwFlags: DWORD): Boolean;
  function UnRegisterSessionNotification(Wnd: HWND): Boolean;
  function GetCurrentSessionID: Integer;
  function WTSWaitSystemEvent(hServer: THandle; EventMask: DWORD; var pEventFlags: DWORD): BOOL; stdcall; external 'wtsapi32.dll' name 'WTSWaitSystemEvent';
  function WTSEnumerateSessions(hServer: THandle; Reserved: DWORD; Version: DWORD; var ppSessionInfo: PWTS_SESSION_INFO; var pCount: DWORD): BOOL; stdcall; external 'wtsapi32.dll' name 'WTSEnumerateSessionsW';
  function WTSQuerySessionInformation(hServer: THandle; SessionId: DWORD; WTSInfoClass: WTS_INFO_CLASS; var ppBuffer: Pointer; var pBytesReturned: DWORD): BOOL; stdcall; external 'wtsapi32.dll' name 'WTSQuerySessionInformationW';
  procedure WTSFreeMemory(pMemory: pointer); stdcall; external 'wtsapi32.dll' name 'WTSFreeMemory';
  function WTSOpenServer(ServerName: PChar): THandle; stdcall; external 'wtsapi32.dll' name 'WTSOpenServerW';
  procedure WTSCloseServer(hServer: THandle); stdcall; external 'wtsapi32.dll' name 'WTSCloseServer';
  function SessionIsLocked(SessionID: DWORD): Boolean;

  //function GetWTSString(SessionId: Cardinal; wtsInfo: _WTS_INFO_CLASS): String;

implementation

{function GetCurrentUserName: String;
var
  aDWord: DWORD;
begin
  aDWord := DWORD(-1);
  if InitProcLibs and Assigned(WTSOpenServer) then
    Result := GetWTSString(aDWord, WTSUserName)
  else
    Result := String(Get_UserName);
end;

function GetWTSString(SessionId: Cardinal; wtsInfo: WTS_INFO_CLASS): String;
var
  Ptr: Pointer;
  R: Cardinal;
  hSvr: THANDLE;
begin
  R := 0;
  Ptr := nil;
  hSvr := WTSOpenServer(nil);
  try
    if WTSQuerySessionInformation(0, SessionId, DWORD(wtsInfo), Ptr, R) and
      (R > 1) then
      Result := String(PAnsiChar(Ptr))
    else
    begin
      Result := String(Get_UserName);
    end;
    WTSFreeMemory(Ptr);
  finally
    if hSvr <> 0 then
      WTSCloseServer(hSvr);
  end;
end;}


function SessionIsLocked(SessionID: DWORD): Boolean;
const
  WTS_CURRENT_SERVER_HANDLE = 0;
//  WTSSessionInfoEx = 25;
  WTS_SESSIONSTATE_LOCK = $00000000;
  WTS_SESSIONSTATE_UNLOCK = $00000001;
  WTS_SESSIONSTATE_UNKNOWN = $FFFFFFFF;
var
  Ptr: Pointer;
  BytesReturned: Cardinal;
  hSvr: THANDLE;
  pInfo: PWTSINFOEXW;
  SessionFlags: LongInt;
  dwFlags: LONG;
begin
	Result := False;
  BytesReturned := 0;
  Ptr := nil;
  hSvr := WTSOpenServer(nil);
  try
    if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, SessionId, WTSSessionInfoEx, Ptr, BytesReturned) then
      if (BytesReturned > 1) then
      begin
        pInfo := PWTSINFOEXW(Ptr);
        if pInfo^.Level = 1 then
          dwFlags := pInfo^.Data.SessionFlags;
        if (Win32MajorVersion <> 6.1) then //Windows 7 & Windows Server 2008 R2
          Result := (dwFlags = WTS_SESSIONSTATE_LOCK)
        else
          Result := (dwFlags = WTS_SESSIONSTATE_UNLOCK);
      end;
    WTSFreeMemory(Ptr);
  finally
    if hSvr <> 0 then
      WTSCloseServer(hSvr);
  end;

//	 && DllCall("wtsapi32\WTSQuerySessionInformation", "Ptr", WTS_CURRENT_SERVER_HANDLE, "UInt", SessionID, "UInt", WTSSessionInfoEx, "Ptr*", sesInfo, "Ptr*", BytesReturned)) then
//   begin
//		SessionFlags := NumGet(sesInfo + 0, 16, 'Int')
//		// "Windows Server 2008 R2 and Windows 7: Due to a code defect, the usage of the WTS_SESSIONSTATE_LOCK and WTS_SESSIONSTATE_UNLOCK flags is reversed."
//    if A_OSVersion <> 'WIN_7' then
//		  Result := SessionFlags := WTS_SESSIONSTATE_LOCK
//    else
//      SessionFlags := WTS_SESSIONSTATE_UNLOCK;
//		DllCall("wtsapi32\WTSFreeMemory", "Ptr", sesInfo)
//	end;
end;

function RegisterSessionNotification(Wnd: HWND; dwFlags: DWORD): Boolean;
// The RegisterSessionNotification function registers the specified window
// to receive session change notifications.
// Parameters:
// hWnd: Handle of the window to receive session change notifications.
// dwFlags: Specifies which session notifications are to be received:
// (NOTIFY_FOR_THIS_SESSION, NOTIFY_FOR_ALL_SESSIONS)
type
  TWTSRegisterSessionNotification = function(Wnd: HWND; dwFlags: DWORD): BOOL; stdcall;
var
  hWTSapi32dll: THandle;
  WTSRegisterSessionNotification: TWTSRegisterSessionNotification;
begin
  Result := False;
  hWTSAPI32DLL := LoadLibrary('Wtsapi32.dll');
  if (hWTSAPI32DLL > 0) then
  begin
    try
      @WTSRegisterSessionNotification := GetProcAddress(hWTSAPI32DLL, 'WTSRegisterSessionNotification');
      if Assigned(WTSRegisterSessionNotification) then
        Result := WTSRegisterSessionNotification(Wnd, dwFlags);
    finally
    if hWTSAPI32DLL > 0 then
      FreeLibrary(hWTSAPI32DLL);
    end;
  end;
end;

function UnRegisterSessionNotification(Wnd: HWND): Boolean;
// The RegisterSessionNotification function unregisters the specified window
// Parameters:
// hWnd: Handle to the window
type
  TWTSUnRegisterSessionNotification = function(Wnd: HWND): BOOL; stdcall;
var
  hWTSapi32dll: THandle;
  WTSUnRegisterSessionNotification: TWTSUnRegisterSessionNotification;
begin
  Result := False;
  hWTSAPI32DLL := LoadLibrary('Wtsapi32.dll');
  if (hWTSAPI32DLL > 0) then
  begin
    try
      @WTSUnRegisterSessionNotification := GetProcAddress(hWTSAPI32DLL, 'WTSUnRegisterSessionNotification');
      if Assigned(WTSUnRegisterSessionNotification) then
        Result := WTSUnRegisterSessionNotification(Wnd);
    finally
    if hWTSAPI32DLL > 0 then
      FreeLibrary(hWTSAPI32DLL);
    end;
  end;
end;

function GetCurrentSessionID: Integer;
// Getting the session id from the current process
type
  TProcessIdToSessionId = function(dwProcessId: DWORD; pSessionId: DWORD): BOOL; stdcall;
var
  ProcessIdToSessionId: TProcessIdToSessionId;
  hWTSapi32dll: THandle;
  Lib : THandle;
  pSessionId : DWord;
begin
  Result := -1;
  Lib := GetModuleHandle('Kernel32');
  if Lib <> 0 then
  begin
    ProcessIdToSessionId := GetProcAddress(Lib, '1ProcessIdToSessionId');
    if Assigned(ProcessIdToSessionId) then
    begin
      ProcessIdToSessionId(GetCurrentProcessId(), DWORD(@pSessionId));
      Result:= pSessionId;
    end;
  end;
end;

end.
