{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit RtcHostSvc;

interface

{$INCLUDE rtcDefs.inc}

uses
  Windows, Messages, SysUtils, Classes, SyncObjs, RunElevatedSupport, DateUtils,
  Graphics, Controls, SvcMgr, Dialogs, ExtCtrls, Cromis.Comm.Custom, Cromis.Comm.IPC,

  rtcInfo, rtcLog, rtcCrypt, rtcSystem, CommonData, Registry, uSetup,
  rtcThrPool, WTSApi, uProcess, CommonUtils, uHardware, uDMUpdate,

  rtcWinLogon, wininet, rtcScrUtils, uVircessTypes, rtcpDesktopHost, rtcpChat,
  rtcPortalMod, rtcpFileTrans, rtcPortalCli, rtcPortalHttpCli, rtcConn,
  rtcDataCli, rtcHttpCli, rtcCliModule, rtcFunction, SASLibEx;

type
  TStartThread = class(TThread)
  public
    eTimer: THandle;
    FType: String;
    procedure PermanentlyRestartHelpers;
    procedure StartClientsOnLogon;
    procedure StartClientInAllSessions(doStartHelper, doStartClient: Boolean);
    procedure StartClientInSession(SessionID: Cardinal; doStartHelper, doStartClient: Boolean);
    procedure Execute; override;
    constructor Create(ACreateSuspended: Boolean; AType: String); overload;
    destructor Destroy; overload;
  end;

  TRemoxService = class(TService)
    PClient: TRtcHttpPortalClient;
    PFileTrans: TRtcPFileTransfer;
    PChat: TRtcPChat;
    PDesktopHost: TRtcPDesktopHost;
    tPClientReconnect: TTimer;
    HostTimerModule: TRtcClientModule;
    HostTimerClient: TRtcHttpClient;
    resHostPing: TRtcResult;
    rActivate: TRtcResult;
    tHostTimerClientReconnect: TTimer;
    HostPingTimer: TTimer;
    resHostLogin: TRtcResult;
    resHostLogout: TRtcResult;
    resHostPassUpdate: TRtcResult;
    resHostTimerLogin: TRtcResult;
    resHostTimer: TRtcResult;
    tActivate: TTimer;
    resPing: TRtcResult;
    tCheckLockedState: TTimer;
    rHostLockedStateUpdate: TRtcResult;
    tCheckForNewVersion: TTimer;

    procedure ServiceShutdown(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceExecute(Sender: TService);
    procedure HostTimerClientConnect(Sender: TRtcConnection);
    procedure HostTimerClientDisconnect(Sender: TRtcConnection);
    procedure tHostTimerClientReconnectTimer(Sender: TObject);
    procedure HostPingTimerTimer(Sender: TObject);
    procedure resHostLoginReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure resHostPingReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure rActivateReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure resHostTimerReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure tPClientReconnectTimer(Sender: TObject);
    procedure PClientError(Sender: TAbsPortalClient; const Msg: string);
    procedure PClientFatalError(Sender: TAbsPortalClient; const Msg: string);
    procedure tActivateTimer(Sender: TObject);
    procedure HostTimerClientConnectError(Sender: TRtcConnection; E: Exception);
    procedure HostTimerClientConnectLost(Sender: TRtcConnection);
    procedure PClientLogOut(Sender: TAbsPortalClient);
    procedure PClientLogIn(Sender: TAbsPortalClient);
    procedure PClientStatusGet(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);
    procedure resPingReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure PClientStart(Sender: TAbsPortalClient; const Data: TRtcValue);
    procedure rActivateRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure tCheckLockedStateTimer(Sender: TObject);

  private
    { Private declarations }
    FCurStatus: Integer;
  public
    { Public declarations }
//    Running:boolean;
    Stopping: Boolean;
//    WaitLoopCount:integer;
//    WasRunning:boolean;
    UserName: String;
    myCheckTime: TDateTime;
    FPermanentPassword: String;
    FScreenLockedState: Integer;

    tDMUpdate: TDMUpdateThread;

    procedure UpdateMyPriority;
    function GetServiceController: TServiceController; override;
    procedure ActivateHost;
    procedure HostLogOut;
    function GetLastCheckUpdateTime: TDateTime;
    procedure SetLastCheckUpdateTime(AValue: TDateTime);
    procedure LoadSetup;
    procedure StartHostLogin;
    procedure msgHostTimerTimer(Sender: TObject);
//    procedure LogoutClientHosts;

    procedure ChangePort(AClient: TRtcHttpClient);
    procedure ChangePortP(AClient: TRtcHttpPortalClient);

    procedure UpdateOnSuccessCheck(Sender: TObject);

    function GetStatus: Integer;
    procedure SetStatus(Status: Integer);
    property CurStatus: Integer read GetStatus write SetStatus;

//    procedure OnSessionChange(var Msg: TMessage); message WM_WTSSESSION_CHANGE;

//    function GetServiceController:
//      {$IFDEF VER120} PServiceController;
//      {$ELSE} TServiceController; {$ENDIF} override;

//    procedure StartMyService;
//    procedure StopMyService;
    procedure SetPermanentPassword(AValue: String);

    procedure SendLockedStateToGateway;
    procedure GetDataFromHelperByIPC(QueryType: Cardinal);
    procedure SetScreenLockedState(AValue: Integer);
    property PermanentPassword: String read FPermanentPassword write SetPermanentPassword;
    property ScreenLockedState: Integer read FScreenLockedState write SetScreenLockedState;
    procedure OnExecuteRequest(const Context: ICommContext; const Request, Response: IMessageData);
  end;

const
  HELPER_EXE_NAME = 'rmx_w32.exe';
  HELPER_CONSOLE_EXE_NAME = 'rmx_x64.exe';

  STATUS_NO_CONNECTION = 0;
  STATUS_ACTIVATING_ON_MAIN_GATE = 1;
  STATUS_CONNECTING_TO_GATE = 2;
  STATUS_READY = 3;

var
  RemoxService: TRemoxService;
  HelperTempFileName, HelperConsoleTempFileName: String;
  tStartHelpers, tStartClients: TStartThread;
  ConfigLastDate: TDateTime;
  ActivationInProcess: Boolean;
  CurStatus: Integer;
  CS_Status: TCriticalSection;
  FIPCServer: TIPCServer;
//  hWnd, hWndThread: THandle;
//  tid: Cardinal;
//  FRegisteredSessionNotification: Boolean;

implementation

{$R *.DFM}

procedure TRemoxService.OnExecuteRequest(const Context: ICommContext; const Request, Response: IMessageData);
var
  reg: TRegistry;
  UpdateStatus: Integer;
  Progress: Integer;
begin
  if Request.Data.ReadInteger('QueryType') = QT_SET_SETTINGS then
  begin
    reg := TRegistry.Create;
    try
      try
        reg.Access := KEY_WRITE or KEY_WOW64_64KEY;
        reg.RootKey := HKEY_LOCAL_MACHINE;
        if not reg.OpenKey('SOFTWARE\Remox', True) then
          Exit;

        if Request.Data.Exists('PermanentPassword') then
          reg.WriteString('PermanentPassword', Request.Data.ReadString('PermanentPassword'));
        reg.WriteString('AutomaticUpdate', Request.Data.ReadString('AutomaticUpdate'));
        reg.WriteInteger('ProxyOption', Request.Data.ReadInteger('ProxyOption'));
        reg.WriteString('ProxyAddr', Request.Data.ReadString('ProxyAddr'));
        reg.WriteString('ProxyUsername', Request.Data.ReadString('ProxyUsername'));
        reg.WriteString('ProxyPassword', Request.Data.ReadString('ProxyPassword'));
        reg.CloseKey;

        LoadSetup;
      except
        Response.Data.WriteBoolean('Result', False);
        Exit;
      end;
    finally
      reg.Free;
    end;
    Response.Data.WriteBoolean('Result', True);
  end
  else
  if Request.Data.ReadInteger('QueryType') = QT_START_UPDATE then
  begin
    try
      tDMUpdate.DMUpdate.GetProgress(UpdateStatus, Progress);
      if UpdateStatus = US_READY then
        tDMUpdate.DMUpdate.StartUpdate(HostTimerClient.UseProxy, HostTimerClient.UserLogin.ProxyAddr, HostTimerClient.UserLogin.ProxyUserName, HostTimerClient.UserLogin.ProxyPassword);
    except
      Response.Data.WriteBoolean('Result', False);
      Exit;
    end;
    Response.Data.WriteBoolean('Result', True);
  end
  else
  if Request.Data.ReadInteger('QueryType') = QT_GET_UPDATE_PROGRESS then
  begin
    try
      tDMUpdate.DMUpdate.GetProgress(UpdateStatus, Progress);
    except
      Response.Data.WriteBoolean('Result', False);
      Response.Data.WriteInteger('UpdateStatus', 0);
      Response.Data.WriteInteger('Progress', 0);
      Exit;
    end;
    Response.Data.WriteBoolean('Result', True);
    Response.Data.WriteInteger('UpdateStatus', UpdateStatus);
    Response.Data.WriteInteger('Progress', Progress);
  end;
end;

procedure TRemoxService.SendLockedStateToGateway;
begin
//  XLog('SendLockedStateToGateway');

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или на сервере
//  if IsWinServer
//    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
//  begin
    if (UserName = '-')
      or (UserName = '') then
      Exit;

    with HostTimerModule do
    try
      with Data.NewFunction('Host.LockedStateUpdate') do
      begin
        Value['User'] := LowerCase(UserName);
        AsInteger['LockedState'] := ScreenLockedState;
        asBoolean['ServiceStarted'] := (Status = csRunning);
        Call(rHostLockedStateUpdate);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
//  end;
end;

procedure TRemoxService.tCheckLockedStateTimer(Sender: TObject);
//var
//  hDesktop : THandle;
//  bResult, bLocked : BOOL;
begin
//  XLog('tCheckLockedStateTimer');

  GetDataFromHelperByIPC(QT_GETDATA);

//  if (not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//    and
//  if (LowerCase(GetInputDesktopName) = 'default') then
//    ScreenLockedState := LCK_STATE_UNLOCKED
//  else
//  if {tPHostThread.FDesktopHost.HaveScreen
//    and} (GetCurrentSesstionState = WTSActive) then
//    ScreenLockedState := LCK_STATE_UNLOCKED
//  else
//    ScreenLockedState := LCK_STATE_LOCKED;

{  if IsScreenSaverRunning then
  begin
    ScreenLockedState := LCK_STATE_SCREENSAVER;
    Exit;
  end;

  hDesktop := 0;
  try
    hDesktop := OpenInputDesktop(0, False, GENERIC_ALL);
  finally
    if (hDesktop <> 0) then
      CloseDesktop(hDesktop);
  end;
  if hDesktop = 0 then //CAD window is active
    ScreenLockedState := LCK_STATE_SAS
  else
  if (GetSystemMetrics(SM_REMOTESESSION) <> 0)
    and (not PDesktopHost.HaveScreen) then
    ScreenLockedState := LCK_STATE_LOCKED
  else
  begin
    bResult := False;
    try
      bResult := SASLibEx_IsDesktopLocked(DWORD(-1), bLocked);
    finally
    end;
    if bResult
      and bLocked then //Screen is lccked
      ScreenLockedState := LCK_STATE_LOCKED
    else
      ScreenLockedState := LCK_STATE_UNLOCKED;
  end;}
end;

procedure TRemoxService.SetScreenLockedState(AValue: Integer);
//var
//  desk: String;
begin
  //XLog('SetScreenLockedState');

  if FScreenLockedState <> AValue then
  begin
//    if not (IsServiceStarted(RTC_HOSTSERVICE_NAME)
//      and IsConsoleClient) then
//    begin
      FScreenLockedState := AValue;
      SendLockedStateToGateway;
//    end
//    else
//    if FScreenLockedState <> LCK_STATE_UNLOCKED then
//    begin
//      desk := GetInputDesktopName;
//      Memo2.Lines.Add(desk + IntToStr(OpenDesktop(PChar(desk), DF_ALLOWOTHERACCOUNTHOOK, False, DESKTOP_ALL)));
//    end;

//  Memo1.Lines.Add(DateTime2Str(Now) + ' - ' + IntToStr(ScreenLockedState));
  end;
end;

procedure TRemoxService.GetDataFromHelperByIPC(QueryType: Cardinal);
var
  SessionID: DWORD;
  Request, Response: IIPCData;
  IPCClient: TIPCClient;
  I, Len: Integer;
begin
//  if IsConsoleClient then
//  if IsService then
    SessionID := ActiveConsoleSessionID;
//  else
//    SessionID := CurrentSessionID;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Session_' + IntToStr(SessionID);
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QueryType);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
          ScreenLockedState := Response.Data.ReadInteger('LockedState');

//          if IPCClient.LastError <> 0 then
//            ListBox1.Items.Add(Format('Error: Code %d', [IPCClient.LastError]));
      end;
    finally
      IPCClient.DisconnectClient;
    end;
  finally
    IPCClient.Free;
  end;
end;

function TRemoxService.GetStatus: Integer;
begin
  CS_Status.Acquire;
  try
    Result := FCurStatus;
  finally
    CS_Status.Release;
  end;
end;

procedure TRemoxService.SetStatus(Status: Integer);
begin
  CS_Status.Acquire;
  try
    FCurStatus := Status;
  finally
    CS_Status.Release;
  end;
end;

procedure TRemoxService.ServiceCreate(Sender: TObject);
begin
//  Sleep(10000);
  if (Win32MajorVersion >= 6 {vista\server 2k8}) then
    Interactive := False;

  ConfigLastDate := 0;
  CurStatus := STATUS_NO_CONNECTION;
  ActivationInProcess := False;

//  FRegisteredSessionNotification := RegisterSessionNotification(hWnd, NOTIFY_FOR_ALL_SESSIONS);
//  hWndThread := CreateThread(nil, 0, @WinMainThreadProc, nil, 0, tid);

  HelperTempFileName := GetTempDirectory + HELPER_EXE_NAME;
  HelperConsoleTempFileName := GetTempDirectory + HELPER_CONSOLE_EXE_NAME;

  Stopping := False;

//  tPClientReconnect.Enabled := True;
  tHostTimerClientReconnect.Enabled := True;

  LOG_THREAD_EXCEPTIONS := True;
  LOG_EXCEPTIONS := True;

  FScreenLockedState := LCK_STATE_UNLOCKED;

  StartLog;

  tStartHelpers := TStartThread.Create(True, 'PermanentlyRestartHelpers');
  tStartClients := TStartThread.Create(True, 'StartClientsOnLogon');

  LoadSetup;

  tDMUpdate := TDMUpdateThread.Create(False, UpdateOnSuccessCheck);
//  tDMUpdate.DMUpdate.FOnProgressChange := OnUpdateProgressChange;

  FIPCServer := TIPCServer.Create;
  FIPCServer.OnExecuteRequest := OnExecuteRequest;
  FIPCServer.ServerName := 'Remox_IPC_Service';

//  PFileTrans.FileInboxPath := ExtractFilePath(AppFileName) + '\INBOX';
end;

procedure TRemoxService.ServiceStart(Sender: TService; var Started: Boolean);
var
  s: RtcString;
begin
//  Sleep(10000);

  FIPCServer.Start;

  xLog('Service start pending');
  try
    StartHostLogin;

    Stopping := False;
//  if (Win32MajorVersion >= 6 {vista\server 2k8}) then
//  begin
//    WasRunning := False;
//    WaitLoopCount := 0;

//    rtcKillProcess(HELPER_EXE_NAME);
//    rtcKillProcess(ExtractFileName(AppFileName));
      if File_Exists(HelperTempFileName) then
        if not DeleteFile(HelperTempFileName) then
//          xLog('Can''t delete file ' + HelperTempFileName);
      if not File_Exists(HelperTempFileName) then
        CommonUtils.SaveResourceToFile('HELPER', HelperTempFileName);

      if File_Exists(HelperConsoleTempFileName) then
        if not DeleteFile(HelperConsoleTempFileName) then
//          xLog('Can''t delete file ' + HelperConsoleTempFileName);
      if not File_Exists(HelperConsoleTempFileName) then
        CommonUtils.SaveResourceToFile('HELPER', HelperConsoleTempFileName);
    finally
    end;

//    StartClientInAllSessions;

//    rtcStartProcess(AppFileName + ' -autorun -silent');
//    rtcStartProcess(AppFileName);
//    if File_Exists(ChangeFileExt(AppFileName,'.run')) then
//    begin
//      s:=Read_File(ChangeFileExt(AppFileName,'.run'));
//      rtcStartProcess(AppFileName+String(s));
//      Delete_File(ChangeFileExt(AppFileName,'.run'));
//      Started:=False;
//    end
//    else
//    begin
      xLog('');
      xLog('--------------------------');
      xLog('Remox Launcher started.');
//      timCheckProcess.Interval := 25;
//      timCheckProcess.Enabled := True;
      Started := True;
//    end;
//  end
//  else
//  begin
//    StartMyService;
//    Started := Running;
//  end;

  tStartHelpers.StartClientInAllSessions(True, False);
  tStartHelpers.Resume;
  tStartClients.StartClientInAllSessions(False, True);
  tStartClients.Resume;
end;

procedure TRemoxService.UpdateOnSuccessCheck(Sender: TObject);
begin
  SetLastCheckUpdateTime(Now);
end;

{procedure TRemoxService.LogoutClientHosts; //Сделано на гейте
var
  HWID : THardwareId;
  Users: TStringList;
  i: Integer;
begin
  HWID := THardwareId.Create(False);
  HWID.AddUserProfileName := True;

  Users := TStringList.Create;

  try
    GetLoggedInUsersSIDs(Self, '', '', '', Users);
    for i := 0 to Users.Count - 1 do
    begin
      HWID.UserProfileName := Users[i];
      HWID.GenerateHardwareId;
  //      HostTimerModule.Data.Clear;
      with HostTimerModule, Data.NewFunction('Host.LogoutByHash') do
      begin
        asString['Hash'] := HWID.HardwareIdHex;
        Call(rActivate);
      end;
    end;
  finally
    FreeAndNil(HWID);
    FreeAndNil(Users);
  end;
end;}

procedure TRemoxService.ServiceStop(Sender: TService; var Stopped: Boolean);
var
  cnt: Integer;
begin
    Stopping := True;

    FIPCServer.Stop;


//  if (Win32MajorVersion >= 6 { vista\server 2k8 } ) then
//  begin
//    timCheckProcess.Enabled := False;
    HostPingTimer.Enabled := False;

    tStartHelpers.Suspend;
    tStartClients.Suspend;

    xLog('Do kill helper processes');
    rtcKillProcess(HELPER_EXE_NAME);
    rtcKillProcess(HELPER_CONSOLE_EXE_NAME);

    if not File_Exists(ChangeFileExt(ParamStr(0), '.ncl')) then //Если это остановка службы при снятии галки автозапуска, то клиентов не закрываем
    begin
      xLog('Do kill client processes');
      rtcKillProcess(ExtractFileName(AppFileName));
    end;
    Delete_File(ChangeFileExt(ParamStr(0), '.ncl'));

    HostLogOut;
//    LogoutClientHosts;

    try
      if File_Exists(HelperTempFileName) then
        if not DeleteFile(HelperTempFileName) then
//          xLog('Can''t delete file ' + HelperTempFileName);
      if File_Exists(HelperConsoleTempFileName) then
        if not DeleteFile(HelperConsoleTempFileName) then
//          xLog('Can''t delete file ' + HelperConsoleTempFileName);
    finally
    end;

    xLog('Remox Launcher stopped.');
    Stopped := True;

//    if WasRunning or (rtcGetProcessID(AppFileName,True)>0) then
//    begin
//      rtcKillProcess(AppFileName);
//      xLog('Logging on to the Gateway to force the Host process to close.');
//      LoadSetup;
//      PClient.GParamsLoaded := True; // this will force all other Hosts to close
//      cnt:=100;
//      repeat
//        Dec(cnt);
//        Sleep(100);
//      until PClient.GParamsLoaded or (cnt<=0);
//      PClient.Active:=False;
//    end;

//    xLog('Remox Launcher stopped.');
//    Stopped:=True;
//  end
//  else
//  begin
//    StopMyService;
//    Stopped := not Running;
//  end;
end;

procedure TRemoxService.ServiceShutdown(Sender: TService);
var
  cnt:integer;
begin
  Stopping := True;
//  if (Win32MajorVersion >= 6 { vista\server 2k8 } ) then
//    begin
//    if WasRunning or
//    if (rtcGetProcessID(AppFileName,True) > 0) then
//      begin
//        xLog('Do kill helper processes');
//        rtcKillProcess(HELPER_EXE_NAME);
//        xLog('Do kill client processes');
//        rtcKillProcess(ExtractFileName(AppFileName));

//      xLog('Logging on to the Gateway to force the Host process to close.');
//      LoadSetup;
//      PClient.GParamsLoaded:=True; // this will force all other Hosts to close
//      cnt:=100;
//      repeat
//        Dec(cnt);
//        Sleep(100);
//        until PClient.GParamsLoaded or (cnt<=0);
//      PClient.Active:=False;
//      end;
    xLog('Host Launcher shut down.');
//    end
//  else
//    StopMyService;
end;

procedure TRemoxService.ServiceDestroy(Sender: TObject);
begin
  Stopping := True;

  FIPCServer.Free;

//  if (Win32MajorVersion >= 6 { vista\server 2k8 } ) then
//    begin

    // unregister session change notifications.
//    if FRegisteredSessionNotification then
//      UnRegisterSessionNotification(hWnd);

//    if WasRunning then
    xLog('Remox Launcher destroyed.');
//    end
//  else
//    StopMyService;

  tStartHelpers.Terminate;
  tStartClients.Terminate;

  tDMUpdate.Terminate;

  StopLog;

  TerminateProcess(GetCurrentProcess, ExitCode);
end;

procedure TRemoxService.ServiceExecute(Sender: TService);
begin
  repeat
    ServiceThread.ProcessRequests(False);
    Sleep(1);
  until Stopping;
end;

procedure TRemoxService.ChangePort(AClient: TRtcHttpClient);
begin
  if AClient.ServerPort = '80' then
    AClient.ServerPort := '8080'
  else
  if AClient.ServerPort = '8080' then
    AClient.ServerPort := '443'
  else
  if AClient.ServerPort = '443' then
    AClient.ServerPort := '5938'
  else
  if AClient.ServerPort = '5938' then
    AClient.ServerPort := '80';
end;

procedure TRemoxService.ChangePortP(AClient: TRtcHttpPortalClient);
begin
  if AClient.GatePort = '80' then
    AClient.GatePort := '8080'
  else
  if AClient.GatePort = '8080' then
    AClient.GatePort := '443'
  else
  if AClient.GatePort = '443' then
    AClient.GatePort := '5938'
  else
  if AClient.GatePort = '5938' then
    AClient.GatePort := '80';
end;

procedure TRemoxService.SetPermanentPassword(AValue: String);
begin
  if FPermanentPassword <> AValue then
    FPermanentPassword := AValue;
end;

constructor TStartThread.Create(ACreateSuspended: Boolean; AType: String);
begin
  inherited Create(ACreateSuspended);

  FType := AType;

//  Sleep(10000);

  eTimer := CreateEvent(nil, True, False, 'RMXTimerEvent');

  FreeOnTerminate := True;
end;

destructor TStartThread.Destroy;
begin
  CloseHandle(eTimer);

  inherited;
end;

procedure TStartThread.Execute;
begin
  if FType = 'PermanentlyRestartHelpers' then
    PermanentlyRestartHelpers
  else
  if FType = 'StartClientsOnLogon' then
    StartClientsOnLogon;
end;

procedure TStartThread.PermanentlyRestartHelpers;
//var
//  pEventFlags: DWORD;
//  i: Integer;
begin
  while not Terminated do
  begin
//    if WTSWaitSystemEvent(WTS_CURRENT_SERVER_HANDLE, {WTS_EVENT_CREATE or WTS_EVENT_LOGON or} WTS_EVENT_ALL, pEventFlags) then
      try
        ActiveConsoleSessionID := GetActiveConsoleSessionId; //Используется при получении изображения из хелпера

//        if (WTS_EVENT_CREATE and pEventFlags) = WTS_EVENT_CREATE then
//        begin
//          for i := 1 to 5 do
//          begin
            StartClientInAllSessions(True, False);
//            StartClientInAllSessions(False, True);
            Sleep(1000);
//          end;
//        end
//        else
//        if (WTS_EVENT_LOGON and pEventFlags) = WTS_EVENT_LOGON then
//        begin
//          for i := 1 to 5 do
//          begin
//            StartClientInAllSessions(False, True);
//            Sleep(5000);
//          end;
//        end;
      except
        on E: Exception do
          xLog('PermanentlyRestartHelpers Error: ' + E.Message);
      end;
  end;
end;

procedure TStartThread.StartClientsOnLogon;
var
  pEventFlags: DWORD;
//  i: Integer;
begin
  while not Terminated do
  begin
    if WTSWaitSystemEvent(WTS_CURRENT_SERVER_HANDLE, {WTS_EVENT_CREATE or WTS_EVENT_LOGON or} WTS_EVENT_ALL, pEventFlags) then
      try
        ActiveConsoleSessionID := GetActiveConsoleSessionId; //Используется при получении изображения из хелпера

//        if (WTS_EVENT_CREATE and pEventFlags) = WTS_EVENT_CREATE then
//        begin
//          for i := 1 to 5 do
//          begin
//            StartClientInAllSessions(True, False);
            StartClientInAllSessions(False, True);
            Sleep(1000);
//          end;
//        end
//        else
//        if (WTS_EVENT_LOGON and pEventFlags) = WTS_EVENT_LOGON then
//        begin
//          for i := 1 to 5 do
//          begin
//            StartClientInAllSessions(False, True);
//            Sleep(5000);
//          end;
//        end;
      except
        on E: Exception do
          xLog('StartClientsOnLogon Error: ' + E.Message);
      end;
  end;
end;

procedure TStartThread.StartClientInAllSessions(doStartHelper, doStartClient: Boolean);
var
   pArrSessInfo, p: PWTS_SESSION_INFO;
   iNumSess: DWORD;
   i: Integer;
   pBuf: Pointer;
   StartSessionID: Integer;
begin
  if Win32MajorVersion = 5 then
    StartSessionID := 0 //In Windows 2000 console session always 0
  else
    StartSessionID := 1;

  try
    if WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, PWTS_SESSION_INFO(pArrSessInfo), iNumSess) then
    try
      p := pArrSessInfo;
      for i := 0 to iNumSess - 1 do
      begin
        if (p.SessionId < StartSessionID)
          or (p.SessionId > 65535) then //65536 - is listener session
        begin
          Inc(p);
          Continue;
        end;

  //      ProtocolType := 3;
  //      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSClientProtocolType, pBuf, iBufSize) then
  //      begin
  //        try
  ////          if USHORT(pBuf^) = WTS_PROTOCOL_TYPE_CONSOLE then
  //          ProtocolType := USHORT(pBuf^);
  //        finally
  //          WTSFreeMemory(pBuf);
  //        end;
  //      end; //if WTSQuerySessionInformation      WTSClientName

  //      UserName := '';
  //      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSUserName, pBuf, iBufSize) then
  //      begin
  //        try
  //          UserName := PChar(pBuf);
  //        finally
  //          WTSFreeMemory(pBuf);
  //        end;
  //      end; //if WTSQuerySessionInformation

        StartClientInSession(p.SessionID, doStartHelper, doStartClient);

        Inc(p);
      end; //for i
    finally
      WTSFreeMemory(pArrSessInfo);
    end; //if WTSWaitSystemEvent
  except
    on E: Exception do
      xLog('StartClientInAllSessions Error: ' + E.Message);
  end;
end;

procedure TStartThread.StartClientInSession(SessionID: Cardinal; doStartHelper, doStartClient: Boolean);
var
  ProcessId: Cardinal;
  hUser: THandle;
begin
//HelperConsoleTempFileName := 'C:\_vircess\VCSV3\Demos\Clients\rmx_x64.exe';
//HelperTempFileName := 'C:\_vircess\VCSV3\Demos\Clients\rmx_w32.exe';

//doStartHelper := False;

  if doStartHelper then
  begin
    if not File_Exists(HelperConsoleTempFileName) then
      CommonUtils.SaveResourceToFile('HELPER', HelperConsoleTempFileName);
//    if ProcessStartedInSession(HELPER_CONSOLE_EXE_NAME, SessionID, ProcessId) then
//      rtcKillProcess(HELPER_CONSOLE_EXE_NAME, ProcessId);
    if not ProcessStartedInSession(HELPER_CONSOLE_EXE_NAME, SessionID, ProcessId) then
      StartProcessAsUser(HelperConsoleTempFileName, 'Winlogon', SessionID, TTSystem);

    if not File_Exists(HelperTempFileName) then
      CommonUtils.SaveResourceToFile('HELPER', HelperTempFileName);
//    if ProcessStartedInSession(HELPER_EXE_NAME, SessionId, ProcessId) then
//      rtcKillProcess(HELPER_EXE_NAME, ProcessId);
    if not ProcessStartedInSession(HELPER_EXE_NAME, SessionId, ProcessId) then
      StartProcessAsUser(HelperTempFileName, 'Winlogon', SessionId, TTSystem);
  end;

  if doStartClient then
  begin
    while True do
    begin
      hUser := GetUserProcessToken('EXPLORER.EXE', SessionID);
      if hUser = 0 then
        Sleep(100)
      else
        Break;
    end;

    if not ProcessStartedInSession(ExtractFileName(AppFileName), SessionId, ProcessId)
      and UserIsLoggedInSession(SessionId) then
      StartProcessAsUser(AppFileName + ' /SILENT', 'Default', SessionId, TTExplorer); // Процесс из Program Files должен сразу запускаться с правами администратора
  end;
end;

procedure TRemoxService.HostLogOut;
begin
  with HostTimerModule,Data.NewFunction('Host.Logout') do
  begin
    asWideString['User'] := UserName;
    asBoolean['IsService'] := True;
    Call(resHostLogout);
  end;
//  xLog('SERVICE HOST LOGOUT');
end;

procedure TRemoxService.StartHostLogin;
begin
//  xLog('StartHostLogin');
//  HostTimerClient.SkipRequests;
//  HostTimerClient.Session.Close;

  HostTimerClient.Connect(True);
end;

function TRemoxService.GetLastCheckUpdateTime: TDateTime;
var
  reg: TRegistry;
begin
//  xLog('GetAutoUpdateSetting');

  Result := EncodeDate(1970, 1, 1);

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if reg.KeyExists('SOFTWARE\Remox\') then
      if reg.OpenKey('SOFTWARE\Remox\', False) then
      begin
        if reg.ValueExists('LaskCheckUpdate') then
          Result := reg.ReadDateTime('LaskCheckUpdate');

        reg.CloseKey;
      end;
  finally
    reg.Free;
  end;
end;

procedure TRemoxService.SetLastCheckUpdateTime(AValue: TDateTime);
var
  reg: TRegistry;
begin
//  xLog('SetLastCheckUpdateTime');

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.Access := KEY_WRITE or KEY_WOW64_64KEY;
    if reg.KeyExists('SOFTWARE\Remox\') then
      if reg.OpenKey('SOFTWARE\Remox\', False) then
      begin
        reg.WriteDateTime('LaskCheckUpdate', AValue);

        reg.CloseKey;
      end;
  finally
    reg.Free;
  end;
end;

procedure TRemoxService.LoadSetup;
var
  reg: TRegistry;
  ProxyOption: Integer;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if not reg.OpenKey('Software\Remox', False) then
      Exit;

    if reg.ValueExists('PermanentPassword') then
      PermanentPassword := reg.ReadString('PermanentPassword')
    else
      PermanentPassword := '';

    if reg.ValueExists('ProxyOption') then
      ProxyOption := reg.ReadInteger('ProxyOption')
    else
      ProxyOption := PO_AUTOMATIC;

    PClient.Gate_Proxy := (ProxyOption = PO_MANUAL);
    HostTimerClient.UseProxy := (ProxyOption = PO_MANUAL);
    if reg.ValueExists('ProxyAddr') then
    begin
      PClient.Gate_ProxyAddr := reg.ReadString('ProxyAddr');
      HostTimerClient.UserLogin.ProxyAddr := reg.ReadString('ProxyAddr');
    end
    else
    begin
      PClient.Gate_ProxyAddr := '';
      HostTimerClient.UserLogin.ProxyAddr := '';
    end;
    if reg.ValueExists('ProxyUsername') then
    begin
      PClient.Gate_ProxyUserName := reg.ReadString('ProxyUsername');
      HostTimerClient.UserLogin.ProxyUserName := reg.ReadString('ProxyUsername');
    end
    else
    begin
      PClient.Gate_ProxyUserName := '';
      HostTimerClient.UserLogin.ProxyUserName := '';
    end;
    if reg.ValueExists('ProxyPassword') then
    begin
      PClient.Gate_ProxyPassword := reg.ReadString('ProxyPassword');
      HostTimerClient.UserLogin.ProxyPassword := reg.ReadString('ProxyPassword');
    end
    else
    begin
      PClient.Gate_ProxyPassword := '';
      HostTimerClient.UserLogin.ProxyPassword := '';
    end;

    reg.CloseKey;
  finally
    reg.Free;
  end;
end;

procedure TRemoxService.rActivateRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  ActivationInProcess := False;
end;

procedure TRemoxService.rActivateReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  i: Integer;
  PassRec: TRtcRecord;
  CurPass: String;
  MinBuildVersion, LastBuildVersion, CurBuildVersion: Integer;
  FUpdateAvailable: Boolean;
  UpdateStatus, Progress: Integer;
begin
  if Result.isType = rtc_Exception then
  begin
    if (not tHostTimerClientReconnect.Enabled) then
      tHostTimerClientReconnect.Enabled := True;
  end
  else
  if Result.isType <> rtc_Record then
  begin
    if (not tHostTimerClientReconnect.Enabled) then
      tHostTimerClientReconnect.Enabled := True;
  end
  else
  with Result.asRecord do
    if asBoolean['Result'] = True then
    begin
      tHostTimerClientReconnect.Enabled := False;
      UserName := IntToStr(asInteger['ID']);

//      xLog('ID = ' + UserName);

      MinBuildVersion := asInteger['MinBuild'];
      LastBuildVersion := asInteger['LastBuild'];
      CurBuildVersion := FileBuildVersion(ParamStr(0));

      FUpdateAvailable := False;
      if IncDay(GetLastCheckUpdateTime, 1) <= Now then
      begin
        if CurBuildVersion < MinBuildVersion then
        begin
          FUpdateAvailable := True;

          //ActivationInProcess := False; //Не сбразываем флаг. Останавливаем повторную активацию
  //        Exit;
        end
        else
        if CurBuildVersion < LastBuildVersion then
        begin
          FUpdateAvailable := True;

          //ActivationInProcess := False; //Не сбразываем флаг. Останавливаем повторную активацию
  //        Exit;
        end
        else //Версия последняя
        begin
          FUpdateAvailable := False;
  //        bGetUpdate.Caption := '        Последняя версия';
  //        bGetUpdate.Font.Color := clBlack;
        end;

        tDMUpdate.DMUpdate.GetProgress(UpdateStatus, Progress);
        if UpdateStatus = US_READY then
          tDMUpdate.DMUpdate.StartUpdate(HostTimerClient.UseProxy, HostTimerClient.UserLogin.ProxyAddr, HostTimerClient.UserLogin.ProxyUserName, HostTimerClient.UserLogin.ProxyPassword);
      end;

      PClient.Disconnect;
      PClient.Active := False;
      PClient.LoginUserName := UserName;
      PClient.GateAddr := asString['Gateway'];
      PClient.GatePort := '443';
      PClient.Active := True;

      SetStatus(STATUS_CONNECTING_TO_GATE);

      HostPingTimer.Enabled := True;

      PassRec := TRtcRecord.Create;
      try
        CurPass := PermanentPassword;
        Crypt(CurPass, '@VCS@');
        PassRec.asString['0'] := CurPass;

        with HostTimerModule, Data.NewFunction('Host.Login') do
        begin
          asString['User'] := LowerCase(UserName);
          asRecord['Passwords'] := PassRec;
          asString['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort; //asString['Gateway'] + ':' + asString['Port'];
          asInteger['LockedState'] := ScreenLockedState;
          asBoolean['ServiceStarted'] := (Status = csRunning);
          asBoolean['IsService'] := True;
          Call(resHostLogin);
        end;
//        with HostTimerModule, Data.NewFunction('Host.Login2') do
//        begin
//          asString['User'] := LowerCase(UserName);
//          asRecord['Passwords'] := PassRec;
//          asString['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort; //asString['Gateway'] + ':' + asString['Port'];
//          asInteger['LockedState'] := ScreenLockedState;
//          asBoolean['ServiceStarted'] := (Status = csRunning);
//          asBoolean['IsService'] := True;
//          Call(resHostTimerLogin);
//        end;
      finally
        PassRec.Free;
      end;
    end
    else
    begin
        SetStatus(STATUS_ACTIVATING_ON_MAIN_GATE);
//      SetStatusString('Сервер Remox не найден');
//      SetStatus(1);
    end;

  ActivationInProcess := False;

//  xLog('SERVICE HOST LOGIN');
end;

procedure TRemoxService.resHostLoginReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  if Result.isType = rtc_Exception then
  begin
//  LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
  if Result.isType <> rtc_String then
  begin
//  LogOut(nil);
//      SetStatusString('Некорректный ответ от сервера');
  end
  else
  begin
    HostTimerClient.Connect;
//    msgHostTimerTimer(nil);

    HostPingTimer.Enabled := True;
  end;
end;

procedure TRemoxService.resHostPingReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  if Result.isType = rtc_Exception then
  begin
    xLog(Result.asException);
//    HostLogOut;
//    LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
//    HostPingTimer.Enabled := True;

  if Result.asRecord.asBoolean['NeedHostRelogin'] then
  begin
    PClient.Disconnect;
    PClient.Active := False;
    PClient.Active := True;
//    tPClientReconnectTimer(nil);
//    hcAccounts.DisconnectNow(True);
//    SetStatusString('Сервер недоступен');     asdsad
//    SetConnectedState(False);
//    if not isClosing then
//      tHcAccountsReconnect.Enabled := True;
  end;
end;

procedure TRemoxService.resHostTimerReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  i: Integer;
  fname: String;
begin
  if Result.isType = rtc_Exception then
  begin
//    if myUserName<>'' then
//      begin
//    LogOut(nil);
//      MessageBeep(0);
//    lblStatus.Caption := Result.asException;
//      end;
  end
  else
  if not Result.isNull then // data arrived
  begin
    if Sender <> nil then
    begin
      with Result.asRecord do
        myCheckTime := asDateTime['check'];
      // Check for new messages
      msgHostTimerTimer(nil);
      // User interaction is needed, need to Post the event for user interaction
      PostInteractive;
    end;

//    with Result.asRecord do
//      begin
//      if isType['data'] = rtc_Array then
//        with asArray['data'] do
//        for i := 0 to Count - 1 do
//          if isType[i] = rtc_Record then
//            with asRecord[i] do
//            if not isNull['text'] then // Text message
//              begin
//              fname:=asText['from'];
//              if not isIgnore(fname) then
//                begin
//                if isFriend(fname) then
//                  begin
//                  chat:=TChatForm.getForm(fname,do_notify);
//                  chat.AddMessage(fname, asText['text'], RTC_ADDMSG_FRIEND);
//                  end
//                else
//                  begin
//                  MessageBeep(0);
//                  if MessageDlg('User "'+fname+'" has sent you a message,'#13#10+
//                                   'but he/she is not on your Friends list.'#13#10+
//                                   'Accept the message and add "'+fname+'" to your Friends list?',
//                              mtConfirmation,[mbYes,mbNo],0)=mrYes then
//                    begin
//                    chat:=TChatForm.getForm(fname,do_notify);
//                    chat.AddMessage(fname, asText['text'], RTC_ADDMSG_FRIEND);
//                    with ClientModule, Data.NewFunction('AddFriend') do
//                      begin
//                      Value['User']:=myUserName;
//                      Value['Name']:=fname;
//                      Call(resUpdate);
//                      end;
//                    FriendList_Add(fname);
//                    end
//                  else if MessageDlg('Add "'+fname+'" to your IGNORE list?',
//                                     mtWarning,[mbYes,mbNo],0)=mrYes then
//                    begin
//                    with ClientModule, Data.NewFunction('AddIgnore') do
//                      begin
//                      Value['User']:=myUserName;
//                      Value['Name']:=fname;
//                      Call(resUpdate);
//                      end;
//                    IgnoreList_Add(fname);
//                    end;
//                  end;
//                end;
//              end
 //           else
//            if not isNull['login'] then // Friend logging in
//              begin
//                fname := asText['login'];
////                make_notify(fname, 'login');
////              if isFriend(fname) then
//                FriendList_Status(fname, MSG_STATUS_ONLINE);
//              end
//            else if not isNull['logout'] then // Friend logging out
//              begin
//                fname := asText['logout'];
////                make_notify(fname, 'logout');
////              if isFriend(fname) then
//                FriendList_Status(fname, MSG_STATUS_OFFLINE);
//              end
//            else if not isNull['locked'] then // Friend locked status update
//              begin
//                fname := asRecord['locked'].asText['user'];
//                Locked_Status(fname, asRecord['locked'].asInteger['state']);
//              end
//            else if not isNull['addfriend'] then // Added as Friend
//              begin
//              fname:=asText['addfriend'];
//              if not isIgnore(fname) then
//                begin
//                MessageBeep(0);
//                if isFriend(fname) then
//                  ShowMessage('User "'+fname+'" added you as a Friend.')
//                else
//                  begin
//                  MessageBeep(0);
//                  if MessageDlg('User "'+fname+'" added you as a Friend.'#13#10+
//                              'Add "'+fname+'" to your Friends list?',
//                              mtConfirmation,[mbYes,mbNo],0)=mrYes then
//                    begin
//                    with ClientModule, Data.NewFunction('AddFriend') do
//                      begin
//                      Value['User']:=myUserName;
//                      Value['Name']:=fname;
//                      Call(resUpdate);
//                      end;
//                    FriendList_Add(fname);
//                    end
//                  else if MessageDlg('Add "'+fname+'" to your IGNORE list?',
//                                     mtWarning,[mbYes,mbNo],0)=mrYes then
//                    begin
//                    with ClientModule, Data.NewFunction('AddIgnore') do
//                      begin
//                      Value['User']:=myUserName;
//                      Value['Name']:=fname;
//                      Call(resUpdate);
//                      end;
//                    IgnoreList_Add(fname);
//                    end;
//                  end;
//                end;
//              end
//            else if not isNull['addignore'] then // Added as Ignore
//              begin
//              fname:=asText['addignore'];
//              if not isIgnore(fname) then
//                begin
//                MessageBeep(0);
//                if MessageDlg('User "'+fname+'" has chosen to IGNORE you.'#13#10+
//                              'Add "'+fname+'" to your IGNORE list?',
//                              mtWarning,[mbYes,mbNo],0)=mrYes then
//                  begin
//                  with ClientModule, Data.NewFunction('AddIgnore') do
//                    begin
//                    Value['User']:=myUserName;
//                    Value['Name']:=fname;
//                    Call(resUpdate);
//                    end;
//                  IgnoreList_Add(fname);
//                  end;
//                end;
//              end
//            else if not isNull['delfriend'] then // Removed as Friend
//              begin
//              fname:=asText['delfriend'];
//              if isFriend(fname) and not isIgnore(fname) then
//                begin
//                MessageBeep(0);
//                if MessageDlg('User "'+fname+'" removed you as a Friend.'#13#10+
//                              'Remove "'+fname+'" from your Friends list?',
//                              mtConfirmation,[mbYes,mbNo],0)=mrYes then
//                  begin
//                  with ClientModule, Data.NewFunction('DelFriend') do
//                    begin
//                    Value['User']:=myUserName;
//                    Value['Name']:=fname;
//                    Call(resUpdate);
//                    end;
//                  FriendList_Del(fname);
//                  end;
//                end;
//              end
//            else if not isNull['delignore'] then // Removed as Ignore
//              begin
//              fname:=asText['delignore'];
//              if not isIgnore(fname) then
//                begin
//                MessageBeep(0);
//                ShowMessage('User "'+fname+'" has removed you from his IGNORE list.');
//                end;
//              end;
//      end;

//    do_notify := True;
//  end
//  else
//  begin
//    if Sender <> nil then
//    begin
//      // Check for new messages
//      myCheckTime := 0;
//      msgHostTimerTimer(nil);
//      // We don't want to set do_notify to TRUE if user interaction is in progress
//      PostInteractive;
//    end;

//    do_notify := True;
  end;
//begin
//  if Result.isType = rtc_Exception then
//  begin
////    if myUserName<>'' then
////      begin
////      LogOut(nil);
////      MessageBeep(0);
//    lblStatus.Caption := Result.asException;
////      end;
//  end
//  else
//  if not Result.isNull then // data arrived
//  begin
//    if Sender <> nil then
//    begin
//      with Result.asRecord do
//        myHostCheckTime := asDateTime['check'];
//      // Check for new messages
//      msgHostTimerTimer(nil);
//      // User interaction is needed, need to Post the event for user interaction
//      PostInteractive;
//    end;
//  end
//  else
//  begin
//    if Sender <> nil then
//    begin
//      // Check for new messages
//      myHostCheckTime := 0;
//      msgHostTimerTimer(nil);
//      // We don't want to set do_notify to TRUE if user interaction is in progress
//      PostInteractive;
//    end;
//  end;
end;

procedure TRemoxService.resPingReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  if Result.isType = rtc_Exception then
//    begin
//      AccountLogOut(nil);
////      MessageBeep(0);
////      lblStatus.Caption := Result.asException;
//    end
//  else
//    pingTimer.Enabled := True;
end;

procedure TRemoxService.msgHostTimerTimer(Sender: TObject);
var
  PassRec: TRtcRecord;
  CurPass: String;
begin
//  LoadSetup('ALL'); //Обновление пароля и прокси

  PassRec := TRtcRecord.Create;
  try
    CurPass := PermanentPassword;
    Crypt(CurPass, '@VCS@');
    PassRec.asString['0'] := CurPass;
    with HostTimerModule, Data.NewFunction('GetData') do
    begin
      Value['User'] := UserName;
      Value['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort;
      Value['Check'] := myCheckTime;
      asRecord['Passwords'] := PassRec;
      asInteger['LockedState'] := ScreenLockedState;
      asBoolean['ServiceStarted'] := (Status = csRunning);
      Call(resHostTimer);
    end;
  finally
    PassRec.Free;
  end;
end;

procedure TRemoxService.PClientError(Sender: TAbsPortalClient;
  const Msg: string);
begin
  xLog('PClientError: ' + Msg);

  PClientFatalError(Sender, Msg);

  if (Sender = PClient)
    and (Msg = 'Не удалось подключиться к серверу.') then
    ChangePortP(PClient);

  if Msg <> 'Logged out' then
    TRtcHttpPortalClient(Sender).Active := True;

//  PDesktopHost.Restart;
end;

procedure TRemoxService.PClientFatalError(Sender: TAbsPortalClient;
  const Msg: string);
begin
  tPClientReconnect.Enabled := True;
//  PClient.Disconnect;
//  if Msg = 'Сервер недоступен.' then
//    PClient.Active := False;
end;

procedure TRemoxService.PClientLogIn(Sender: TAbsPortalClient);
begin
  tPClientReconnect.Enabled := False;
end;

procedure TRemoxService.PClientLogOut(Sender: TAbsPortalClient);
begin
  tPClientReconnect.Enabled := True;
end;

procedure TRemoxService.PClientStart(Sender: TAbsPortalClient;
  const Data: TRtcValue);
begin
  if (GetStatus = STATUS_CONNECTING_TO_GATE) then
  begin
    SetStatus(STATUS_READY);
  end;

  tPClientReconnect.Enabled := False;
end;

procedure TRemoxService.PClientStatusGet(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);
begin
  case Status of
    rtccClosed:
      tPClientReconnect.Enabled := True;
  end;
end;

procedure TRemoxService.ActivateHost;
var
  HWID : THardwareId;
begin
  ActivationInProcess := True;

  SetStatus(STATUS_ACTIVATING_ON_MAIN_GATE);

  try
    HWID := THardwareId.Create(False);
    try
      HWID.AddUserProfileName := False;
      HWID.GenerateHardwareId;
//      HostTimerModule.Data.Clear;
      with HostTimerModule, Data.NewFunction('Host.Activate') do
      begin
        asString['Hash'] := HWID.HardwareIdHex;
        Call(rActivate);
      end;

      tActivate.Enabled := False;
    except
      on E: Exception do
      begin
        xLog('Call rActivate: ' + E.Message);
        tActivate.Enabled := True;
      end;
    end;
  finally
   HWID.Free;
  end;
end;

{procedure TVircess_Service.OnSessionChange(var Msg: TMessage);
var
  strReason: String;
  doStart: Boolean;
begin
  Msg.Result := 0;
  // Check for WM_WTSSESSION_CHANGE message
  if Msg.Msg = WM_WTSSESSION_CHANGE then
  begin
    case Msg.wParam of
      WTS_CONSOLE_CONNECT:
      begin
        strReason := 'WTS_CONSOLE_CONNECT';
        doStart := True;
      end;
      WTS_CONSOLE_DISCONNECT:
        strReason := 'WTS_CONSOLE_DISCONNECT';
      WTS_REMOTE_CONNECT:
      begin
        strReason := 'WTS_REMOTE_CONNECT';
        doStart := True;
      end;
      WTS_REMOTE_DISCONNECT:
        strReason := 'WTS_REMOTE_DISCONNECT';
      WTS_SESSION_LOGON:
        strReason := 'WTS_SESSION_LOGON';
      WTS_SESSION_LOGOFF:
        strReason := 'WTS_SESSION_LOGOFF';
      WTS_SESSION_LOCK:
        strReason := 'WTS_SESSION_LOCK';
      WTS_SESSION_UNLOCK:
        strReason := 'WTS_SESSION_UNLOCK';
      WTS_SESSION_REMOTE_CONTROL:
      begin
        strReason := 'WTS_SESSION_REMOTE_CONTROL';
        // GetSystemMetrics(SM_REMOTECONTROL);
      end;
      else
        strReason := 'WTS_Unknown';
    end;
    // Write strReason to a Memo
//    Memo1.Lines.Add(strReason + ' ' + IntToStr(msg.Lparam));

  if doStart then
  begin
    if not File_Exists(HelperTempFileName) then
      CommonUtils.SaveResourceToFile('HELPER', HelperTempFileName);
    if not ProcessStartedInSession(HELPER_EXE_NAME, msg.Lparam) then
      StartProcessAsSystem(HelperTempFileName, 'Winlogon', msg.Lparam, TTSystem);
    if not ProcessStartedInSession(ExtractFileName(AppFileName), msg.Lparam) then
      StartProcessAsSystem(AppFileName, 'Default', msg.Lparam, TTSession);
  end;
  end;
end;}

{function PlainWinProc(hWnd: THandle; Msg: UINT;
  wParam, lParam: Cardinal): Cardinal; export; stdcall;
var
  Rect: TRect;
begin
  Result := 0;
  case Msg of
    WM_WTSSESSION_CHANGE:
    begin
      if (wParam = WTS_CONSOLE_CONNECT)
        or (wParam = WTS_REMOTE_CONNECT) then
      begin
        if not File_Exists(HelperTempFileName) then
          CommonUtils.SaveResourceToFile('HELPER', HelperTempFileName);
        if not ProcessStartedInSession(HELPER_EXE_NAME, lParam) then
          StartProcessAsSystem(HelperTempFileName, 'Winlogon', lParam, TTSystem);
        if not ProcessStartedInSession(ExtractFileName(AppFileName), lParam) then
          StartProcessAsSystem(AppFileName, 'Default', lParam, TTSession);
      end;
    end;
    WM_DESTROY:
      PostQuitMessage(0);
    else
      Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;
end;

function WinMainThreadProc(pParam: Pointer): DWORD; stdcall;
var
  Msg: TMsg;
  WndClassEx: TWndClassEx;
begin
  // initialize the window class structure
  WndClassEx.cbSize := SizeOf(TWndClassEx);
  WndClassEx.lpszClassName := 'TVircessService';
  WndClassEx.style := CS_VREDRAW or CS_HREDRAW;
  WndClassEx.hInstance := HInstance;
  WndClassEx.lpfnWndProc := @PlainWinProc;
  WndClassEx.cbClsExtra := 0;
  WndClassEx.cbWndExtra := 0;
//  WndClassEx.hIcon := LoadIcon (hInstance, MakeIntResource ('MAINICON'));
//  WndClassEx.hIconSm  := LoadIcon (hInstance, MakeIntResource ('MAINICON'));
//  WndClassEx.hCursor := LoadCursor (0, idc_Arrow);;
//  WndClassEx.hbrBackground := GetStockObject(WHITE_BRUSH);
  WndClassEx.lpszMenuName := nil;
  // register the class
  if RegisterClassEx (WndClassEx) = 0 then
    xLog('Invalid class registration')
  else
  begin
    hWnd := CreateWindowEx (                       //Range check error!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      WS_EX_OVERLAPPEDWINDOW, // extended styles
      WndClassEx.lpszClassName, // class name
      'Vircess Service', // title
      WS_OVERLAPPEDWINDOW, // styles
      CW_USEDEFAULT, 0, // position
      CW_USEDEFAULT, 0, // size
      0, // parent window
      0, // menu
      HInstance, // instance handle
      nil); // initial parameters
    if hWnd = 0 then
      xLog('Window not created')
    else
    begin
//      ShowWindow (hWnd, SW_HIDE);
      while GetMessage(Msg, 0, 0, 0) do
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
    end;
  end;
end;}

{procedure Delay(msecs: Longint);
var
 targettime: Longint;
 Msg: TMsg;
begin
 targettime := GetTickCount + msecs;
 while targettime > GetTickCount do
   if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
   begin
     If Msg.message = WM_QUIT Then
     begin
       PostQuitMessage(msg.wparam);
       Break;
     end;
     TranslateMessage(Msg);
     DispatchMessage(Msg);
   end;
end;}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  RemoxService.Controller(CtrlCode);
end;

function TRemoxService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TRemoxService.HostPingTimerTimer(Sender: TObject);
var
  PassRec: TRtcRecord;
  CurPass: String;
begin
//  LoadSetup('ALL'); //Обновление пароля и прокси

  PassRec := TRtcRecord.Create;
  try
    CurPass := PermanentPassword;
    Crypt(CurPass, '@VCS@');
    PassRec.asString['0'] := CurPass;
    with HostTimerModule, Data.NewFunction('Host.Ping') do
    begin
      asString['User'] := UserName;
      asString['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort;
      asRecord['Passwords'] := PassRec;
      asInteger['LockedState'] := ScreenLockedState;
      asBoolean['ServiceStarted'] := (Status = csRunning);
      asBoolean['IsService'] := IsService;
      Call(resHostPing);
    end;
  finally
    PassRec.Free
  end;
  with HostTimerModule, Data.NewFunction('Account.Ping') do
    Call(resPing);
end;

procedure TRemoxService.HostTimerClientConnect(Sender: TRtcConnection);
begin
  tHostTimerClientReconnect.Enabled := False;

  tActivate.Enabled := True;
end;

procedure TRemoxService.HostTimerClientConnectError(Sender: TRtcConnection;
  E: Exception);
begin
  tHostTimerClientReconnect.Enabled := True;

  tActivate.Enabled := False;

  xLog('HostTimerClientError: ' + E.Message);
end;

procedure TRemoxService.HostTimerClientConnectLost(Sender: TRtcConnection);
begin
  tHostTimerClientReconnect.Enabled := True;

  tActivate.Enabled := False;
end;

procedure TRemoxService.HostTimerClientDisconnect(Sender: TRtcConnection);
begin
  if (not tHostTimerClientReconnect.Enabled) then
  begin
    ActivationInProcess := False;
    SetStatus(STATUS_NO_CONNECTION);
    tHostTimerClientReconnect.Enabled := True;
  end;

  tActivate.Enabled := False;

  ChangePort(HostTimerClient);
end;

//function TVircess_Service.GetServiceController: {$IFDEF VER120} PServiceController; {$ELSE} TServiceController; {$ENDIF}
//begin
//  Result := {$IFDEF VER120}@{$ENDIF}ServiceController;
//end;

procedure TRemoxService.UpdateMyPriority;
var
  hProcess:Cardinal;
begin
//  if MyPriority>=0 then
//	begin
    hProcess := GetCurrentProcess;
//    case MyPriority of
//      0: SetPriorityClass(hProcess, HIGH_PRIORITY_CLASS);
//      1:
      SetPriorityClass(hProcess, NORMAL_PRIORITY_CLASS);
//      2: SetPriorityClass(hProcess, IDLE_PRIORITY_CLASS);
//    end;
//  end;
end;

procedure TRemoxService.tActivateTimer(Sender: TObject);
begin
  if (CurStatus < STATUS_CONNECTING_TO_GATE)
    and (not ActivationInProcess) then
    ActivateHost;
end;

procedure TRemoxService.tHostTimerClientReconnectTimer(Sender: TObject);
begin
  HostTimerClient.Connect(True);
end;

procedure TRemoxService.tPClientReconnectTimer(Sender: TObject);
begin
//  if PClient.LoginUserName = '' then
//    Exit;
//
  if (PClient.LoginUserName <> '')
    and (PClient.LoginUserName <> '') then
  begin
    if (GetStatus = STATUS_READY) then
      SetStatus(STATUS_CONNECTING_TO_GATE);

    PClient.Disconnect;
    PClient.Active := False;
    PClient.Active := True;

    tPClientReconnect.Enabled := False;
  end
  else
    tPClientReconnect.Enabled := True;

//
//  if not PClient.Active then
////    and not PClient.Connected then
//  begin
////    PClient.Disconnect;
////    PClient.Active := False;
//    PClient.Active := True;
//  end;
end;

{procedure TVircess_Service.timCheckProcessTimer(Sender: TObject);
var
   pArrSessInfo, p: PWTS_SESSION_INFO;
   iNumSess: DWORD;
   i: Integer;
   pBuf: Pointer;
   StartSessionID: Integer;
begin
  if Win32MajorVersion = 5 then
    StartSessionID := 0 //In Windows 2000 console session always 0
  else
    StartSessionID := 1;

  while (not Stopping)
    and (not Terminated) do
  begin
    if WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, PWTS_SESSION_INFO(pArrSessInfo), iNumSess) then
    try
      p := pArrSessInfo;
      for i := 0 to iNumSess - 1 do
      begin
        if (p.SessionId < StartSessionID)
          or (p.SessionId > 65535) then //65536 - is listener session
        begin
          Inc(p);
          Continue;
        end;

  //      ProtocolType := 3;
  //      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSClientProtocolType, pBuf, iBufSize) then
  //      begin
  //        try
  ////          if USHORT(pBuf^) = WTS_PROTOCOL_TYPE_CONSOLE then
  //          ProtocolType := USHORT(pBuf^);
  //        finally
  //          WTSFreeMemory(pBuf);
  //        end;
  //      end; //if WTSQuerySessionInformation      WTSClientName

  //      UserName := '';
  //      if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE, p.SessionId, WTSUserName, pBuf, iBufSize) then
  //      begin
  //        try
  //          UserName := PChar(pBuf);
  //        finally
  //          WTSFreeMemory(pBuf);
  //        end;
  //      end; //if WTSQuerySessionInformation

        if not File_Exists(HelperTempFileName) then
          CommonUtils.SaveResourceToFile('HELPER', HelperTempFileName);
        if not ProcessStartedInSession(HELPER_EXE_NAME, p.SessionId) then
          StartProcessAsSystem(HelperTempFileName, 'Winlogon', p.SessionId, TTSystem);
        if not ProcessStartedInSession(ExtractFileName(AppFileName), p.SessionId)
          and UserIsLoggedInSession(p.SessionId) then
//          if (p.SessionId = WTSGetActiveConsoleSessionId) then //Если сеанс консольный то запускаем от имени системы
//            StartProcessAsSystem(AppFileName + ' /SILENT', 'Default', p.SessionId, TTSystem)
//          else //Если нет, то от имени пользователя
            StartProcessAsSystem(AppFileName + ' /SILENT', 'Default', p.SessionId, TTExplorer);
        Inc(p);
      end; //for i
    finally
      WTSFreeMemory(pArrSessInfo);
    end; //if WTSWaitSystemEvent
  end;
end;}

//        if (p.SessionId = WTSGetActiveConsoleSessionId) then //Если сеанс консольный то запускаем от имени системы
//          StartProcessAsSystem(AppFileName + ' /SILENT', 'Default', p.SessionId, TTSystem)
//        else //Если нет, то от имени пользователя

{ Remox Host Launcher implementation for Windows Vista ... }
//procedure TVircess_Service.timCheckProcessTimer(Sender: TObject);
//var
//  iProcessID: DWORD;
//begin

{  // check if Vircess Host process exists, start it if it does not exist.
  timCheckProcess.Enabled:=False;
  try
    iProcessID := rtcGetProcessID(AppFileName,True);
    if iProcessID = 0 then
      begin
      if WasRunning then
        begin
        xLog('Remox was closed, wait for Windows Explorer to close.');
        WasRunning:=False;
        WaitLoopCount:=25;
        if rtcGetProcessID('explorer.exe')<=0 then
          begin
          WaitLoopCount:=0;
          timCheckProcess.Interval:=1000; //10000
          end
        else
          timCheckProcess.Interval:=1000;
        timCheckProcess.Enabled:=True;
        end
      else if WaitLoopCount>0 then
        begin
        Dec(WaitLoopCount);
        if rtcGetProcessID('explorer.exe')<=0 then
          begin
          WaitLoopCount:=0;
          timCheckProcess.Interval:=1000; //10000
          end
        else
          timCheckProcess.Interval:=1000;
        timCheckProcess.Enabled:=True;
        end
      else if rtcGetProcessID('winlogon.exe')<=0 then
        begin
        xLog('Waiting for WinLogon ...');
        timCheckProcess.Interval:=1000;
        timCheckProcess.Enabled:=True;
        end
      else
        begin
        xLog('STARTING a new Remox instance ...');
//        rtcStartProcess(AppFileName+' -autorun -silent');
        rtcStartProcess(AppFileName);
        timCheckProcess.Interval:=1000;
        timCheckProcess.Enabled:=True;
        end;
      end
    else
      begin
      if not WasRunning then
        begin
        xLog('Remox instance is running.');
        WasRunning:=True;
        end;
      if File_Exists(ChangeFileExt(AppFileName,'.cad')) then
        begin
        xLog('Processing <Ctrl-Alt-Del>');
        Delete_File(ChangeFileExt(AppFileName,'.cad'));
        Post_CtrlAltDel(True);
        end;
      timCheckProcess.Interval:=2000;
      timCheckProcess.Enabled:=True;
      end;
  except
    on E:Exception do
      begin
      xLog('ERROR: '+E.ClassName+' - '+E.Message);
      timCheckProcess.Interval:=2000;
      timCheckProcess.Enabled:=True;
      end;
    end;}
//end;

{ Normal Remox Host Service implementation ... }

{procedure TVircess_Service.StartMyService;
var
  IDREsult: String;
begin
  if not running then
  begin
    StartLog;
    try
      LOG_THREAD_EXCEPTIONS:=True;
      LOG_EXCEPTIONS:=True;

      // We will set all our background Threads to a higher priority,
      //  so we can get enough CPU time even when there are applications
      //  with higher priority running at 100% CPU time.
      RTC_THREAD_PRIORITY:=tpHigher;

      xLog('CREATING Remox MODULES ...');

      UpdateMyPriority;

      xLog('MAKING FIRST LOGIN ATTEMPT ...');
//
//      PClient.Active:=True;
//      running := True;
    except
      on E:Exception do
        Log('Error '+E.ClassName+': '+E.Message);
    end;
  end;
end;

procedure TVircess_Service.StopMyService;
  begin
  if running then
    begin
//    tConnect.Enabled := False;
//    try
//      PClient.Active:=False;
//    except
//    end;
//    try
//    except
//    end;

    running := False;
    end;
  end;}

initialization
  CS_Status := TCriticalSection.Create;

finalization
  CS_Status.Free;

end.

