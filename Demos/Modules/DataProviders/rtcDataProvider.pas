unit rtcDataProvider;

interface

{$include rtcDefs.inc}

uses
  SysUtils, Classes,

  {$IFDEF VER120}
  Forms, // D4
  {$ENDIF}
  {$IFDEF VER130}
  Forms, // D5
  {$ENDIF}

  rtcCrypt, rtcInfo,
  rtcFunction, rtcSrvModule,

  rtcConn, rtcDataSrv, uVircessTypes,

  rtcAccounts, Data.DB, Data.Win.ADODB, Variants, Vcl.ExtCtrls, Vcl.StdCtrls,
  rtcSystem, rtcLog, SyncObjs, rtcDataCli, rtcCliModule, rtcHttpCli, rtcPortalGate;

type
  TStartForceUserLogoutThread = procedure(AUserName: String; AAllConnectionsById: Boolean) of Object;

  TDoWorkProc = procedure of object;
  TCheckDisconnectedThread = class(TThread)
  protected
    FDoWork: TDoWorkProc;
    procedure Execute; override;
  end;
  TGatewayReloginThread = class(TThread)
  protected
    FDoSendGatewayRelogin: TDoWorkProc;
    FDoSendGatewayLogOut: TDoWorkProc;
    procedure Execute; override;
  end;

  TData_Provider = class(TDataModule)
    Module1: TRtcServerModule;
    GatewayFunctions: TRtcFunctionGroup;
    AccountLogin: TRtcFunction;
    AccountSendText: TRtcFunction;
    HostGetData: TRtcFunction;
    ServerLink1: TRtcDataServerLink;
    AccountGetDeviceState: TRtcFunction;
    AccountDelFriend: TRtcFunction;
    AccountLogOut: TRtcFunction;
    AccountLogin2: TRtcFunction;
    AccountPing: TRtcFunction;
    SQLConnection: TADOConnection;
    AccountAddGroup: TRtcFunction;
    AccountDeleteGroup: TRtcFunction;
    AccountAddDevice: TRtcFunction;
    AccountChangeDevice: TRtcFunction;
    AccountChangeGroup: TRtcFunction;
    AccountAddAccount: TRtcFunction;
    HostLogin: TRtcFunction;
    HostLogOut: TRtcFunction;
    HostActivate: TRtcFunction;
    HostLogin2: TRtcFunction;
    HostGetUserInfo: TRtcFunction;
    HostPing: TRtcFunction;
    HostPassUpdate: TRtcFunction;
    AccountEmailIsExists: TRtcFunction;
    HostLockedStateUpdate: TRtcFunction;
    GetLockedState: TRtcFunction;
    Module2: TRtcServerModule;
    ServerLink2: TRtcDataServerLink;
    ServerLink3: TRtcDataServerLink;
    Module3: TRtcServerModule;
    Module4: TRtcServerModule;
    ServerLink4: TRtcDataServerLink;
    MainGateServerGroup: TRtcFunctionGroup;
    MainGateServerModule: TRtcServerModule;
    MainGateClientModule: TRtcClientModule;
    MainGateServerLink: TRtcDataServerLink;
    MainGateClientLink: TRtcDataClientLink;
    GateRelogin: TRtcFunction;
    GateLogout: TRtcFunction;
    rGateLogOut: TRtcResult;
    ClientsDestroy: TRtcFunction;
    PortalGateServerLink: TRtcDataServerLink;
    PortalGateServerModule: TRtcServerModule;
    PortalGateServerGroup: TRtcFunctionGroup;
    rGateRelogin: TRtcResult;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Module1SessionClose(Sender: TRtcConnection);

    procedure AccountLoginExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountRegisterExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountSendTextExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostGetDataExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountGetDeviceStateExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountDelFriendExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountLogOutExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountLogin2Execute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountPingExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);

    procedure AccountAddGroupExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountDeleteGroupExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountChangeGroupExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountAddDeviceExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure AccountChangeDeviceExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure AccountAddAccountExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostActivateExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostGetUserInfoExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
//    procedure HostModuleSessionClose(Sender: TRtcConnection);
    procedure HostLoginExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure HostLogin2Execute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure HostRegisterExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostPassUpdateExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostLogOutExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure HostPingExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure AccountEmailIsExistsExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostLockedStateUpdateExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure GetLockedStateExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure GateReloginExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure GateLogoutExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure ClientsDestroyExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
  private
    FOnUserLogin: TUserEvent;
    FOnUserLogOut: TUserEvent;
    function DoHostLogin(Sender: TRtcConnection; uname, gateway: String; isService: Boolean; Param: TRtcFunctionInfo): Boolean;
    function DoGatewayReLogin(Sender: TRtcConnection; address: String; maxUsers: Integer; Param: TRtcFunctionInfo): Boolean;
  protected
    procedure CheckLogin(Sender: TRtcConnection; const account, uname, pass: String);
    procedure HostCheckLogin(Sender: TRtcConnection; const uname, gateway: String; isService: Boolean; Param: TRtcFunctionInfo);
    function LoadUserInfo(account, RealName, AccountUID: String): TRtcRecord;
    function AccountIsValid(name, pwd: String; var RealName, AccountUID: String): Boolean;
    function AccountIsExists(email: String): Boolean;
  public
    { Public declarations }
    ThisGatewayAddress: String;
    ThisGatewayMaxUsers: Integer;

    Gateway1, Gateway2, Gateway3, Gateway4: TRtcPortalGateway;

    Users: TVircessUsers;
//    LogMemo: TMemo;
    tCDHostsThread, tCDGatewaysThread: TCheckDisconnectedThread;
    tGWReloginThread: TGatewayReloginThread;

    FStartForceUserLogoutThread: TStartForceUserLogoutThread;

    function GetFriendList(uname: String): TRtcRecord;
    procedure SetOnUserLogIn(AValue: TUserEvent);
    procedure SetOnUserLogOut(AValue: TUserEvent);
    property OnUserLogin: TUserEvent read FOnUserLogin write SetOnUserLogIn;
    property OnUserLogOut: TUserEvent read FOnUserLogOut write SetOnUserLogOut;
//    procedure DoLogoffUser(uname: String);
//    procedure doHostLogIn(uname: string; Friends: TRtcRecord);
    procedure AddParam(StoredProc: TADOStoredProc;
      ParamName: WideString; DataType: TDataType; Direction: TParameterDirection; ParamValue: OleVariant);
    function GetAccountsCount: Integer;
    function GetHostsCount: Integer;
    function GetGatewaysCount: Integer;
    procedure SendGatewayRelogin;
    procedure SendGatewayLogOut;
    procedure GatewayReloginStart;
    procedure GatewayLogOutStart;
  end;

function GetDataProvider: TData_Provider;

var
  Data_Provider: TData_Provider;
  CS_DB: TCriticalSection;

implementation

{$R *.dfm}

//procedure TData_Provider.FillGatewayList;
//var
//  GatewayRec: PGatewayServerRec;
//begin
//  New(GatewayRec);
//  GatewayRec^.Users := TRtcRecord.Create;
//  GatewayRec^.Users.AutoCreate := True;
//  GatewayRec^.Address := SP.FieldByName('Address').Value;
//  GatewayRec^.Port := SP.FieldByName('Port').Value;
//  GatewayRec^.MaxUsers := SP.FieldByName('MaxUsers').Value;
//
//  Users.AddGateway(GatewayRec);
//end;

function TData_Provider.DoGatewayReLogin(Sender: TRtcConnection; address: String; maxUsers: Integer; Param: TRtcFunctionInfo): Boolean;
begin
  with TRtcDataServer(Sender) do
  begin
    if (Trim(address) = '') then
    begin
      Result := False;
      raise Exception.Create('Address required for Login.');
    end;

    Users.GatewayReLogin(address, maxUsers);

    Session['$MSG:GatewayLogin'] := 'OK';
    Session['$MSG:GatewayAddress'] := Param['Address'];

    Result := True;
  end;
end;

procedure TData_Provider.GateLogoutExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    if Session <> nil then
//      if Session['$MSG:GatewayLogin'] = 'OK' then
//        if Session['$MSG:Address'] = Param['Address'] then
          if Users.isGatewayLoggedIn(Param.asText['Address']) then
          begin
//xLog('GatewayLogOutExecute ' + Param.asText['Address']);
            Users.GatewayLogOut(Param.asText['Address']);
            Session['$MSG:GatewayLogin']:= '';
            Session['$MSG:GatewayAddress']:= '';
          end;
end;

procedure TData_Provider.GateReloginExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  if DoGatewayReLogin(Sender, Param['Address'], Param['MaxUsers'], Param) then
    Result.asString := 'OK';
end;

function TData_Provider.GetAccountsCount: Integer;
begin
  Result := Users.GetAccountsCount;
end;

function TData_Provider.GetHostsCount: Integer;
begin
  Result := Users.GetHostsCount;
end;

function TData_Provider.GetGatewaysCount: Integer;
begin
  Result := Users.GetGatewaysCount;
end;

procedure TCheckDisconnectedThread.Execute;
begin
  while not Terminated do
  begin
    if Assigned(FDoWork) then
      FDoWork;
    Sleep(1000);
  end;
end;

procedure TGatewayReloginThread.Execute;
begin
  while not Terminated do
  begin
    if Assigned(FDoSendGatewayRelogin) then
      FDoSendGatewayRelogin;
    Sleep(1000);
  end;

  if Assigned(FDoSendGatewayLogOut) then
    FDoSendGatewayLogOut;
end;

//procedure TAccounts_Provider.doHostLogIn(uname: string; Friends: TRtcRecord);
//begin
//  Accounts.doHostLogIn(uname, Friends);
//end;

procedure TData_Provider.SetOnUserLogIn(AValue: TUserEvent);
begin
  FOnUserLogIn := AValue;
  Users.FOnUserLogIn := AValue;
end;

procedure TData_Provider.SetOnUserLogOut(AValue: TUserEvent);
begin
  FOnUserLogOut := AValue;
  Users.FOnUserLogOut := AValue;
end;

function TData_Provider.GetFriendList(uname: String): TRtcRecord;
var
  SP: TADOStoredProc;
  i: Integer;
begin
  Result := TRtcRecord.Create;
  Result.AutoCreate := True;

  if uname = '' then
    Exit;

  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;
    try
      SP := TADOStoredProc.Create(nil);
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'GetAccountsByDeviceID';
        SP.Prepared := True;
        SP.Parameters.Refresh;
        //AddParam(SP, '@ID', ftString, pdInput, StrToInt(uname));
        SP.Parameters.ParamByName('@ID').Value := StrToInt(uname);
        SP.Open;

        for i := 0 to SP.RecordCount - 1 do
        begin
          Result.asBoolean[SP.FieldByName('Name').Value] := True;
          SP.Next;
        end;
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.GetLockedStateExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    with Result.NewRecord do
    begin
      asString['User'] := Param['User'];
      asInteger['State'] := Users.GetHostLockedState(Param['User']);
    end;
end;

procedure TData_Provider.AddParam(StoredProc: TADOStoredProc;
  ParamName: WideString; DataType: TDataType; Direction: TParameterDirection; ParamValue: OleVariant);
var
  Param: TParameter;
begin
  Param := StoredProc.Parameters.AddParameter;
  Param.Name := ParamName;
  Param.DataType := DataType;
  Param.Direction := Direction;
  Param.Value := ParamValue;
end;

procedure TData_Provider.HostActivateExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
  UserGateway: String;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;
    try
      SP := TADOStoredProc.Create(nil);
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'GetDeviceID';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@Hash', ftString, pdInput, Param.asString['Hash']);
//        AddParam(SP, '@Hash_Console', ftString, pdInput, Param.asString['Hash_Console']);
//        AddParam(SP, '@ID', ftString, pdOutput, 0);
//        AddParam(SP, '@ID_Console', ftString, pdOutput, 0);
        SP.Parameters.ParamByName('@Hash').Value := Param.asString['Hash'];
        SP.Parameters.ParamByName('@Hash_Console').Value := Param.asString['Hash_Console'];
        SP.Parameters.ParamByName('@ID').Value := 0;
        SP.Parameters.ParamByName('@ID_Console').Value := 0;
        SP.ExecProc;

        with Result.NewRecord do
        begin
          asInteger['ID'] := SP.Parameters.ParamByName('@ID').Value;
          asInteger['ID_Console'] := SP.Parameters.ParamByName('@ID_Console').Value;
          UserGateway := Users.GetAvailableGateway;
          if UserGateway <> '' then
          begin
            asBoolean['Result'] := True;
            asString['Gateway'] := UserGateway;
          end
          else
            asBoolean['Result'] := False;
        end;
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.HostGetUserInfoExecute(
  Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
var
  CurPass: String;
  UserGateway: String;
begin
  CurPass := Param.asString['Pass'];
  DeCrypt(CurPass, '@VCS@');

  if not Users.isHostLoggedIn(Param.asString['User']) then
    with Result.NewRecord do
    begin
      asString['Result'] := 'IS_OFFLINE';
      asString['User'] := Param.asString['User'];
      asString['Pass'] := CurPass;

      Exit;
    end;

  UserGateway := Users.GetUserGateway(Param.asString['User']);
  with Result.NewRecord do
  begin
    if Users.CheckPassword(Param.asString['User'], CurPass) then
      asString['Result'] := 'OK'
    else
      asString['Result'] := 'PASS_NOT_VALID';
    asString['User'] := Param.asString['User'];
    asString['Action'] := Param.asString['Action'];
    if UserGateway <> '' then
      asString['Address'] := UserGateway;
    asString['Pass'] := CurPass;
    asInteger['LockedState'] := Users.GetHostLockedState(Param.asString['User']);
  end;
end;

procedure TData_Provider.HostLockedStateUpdateExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    Users.SetHostLockedState(Param['User'], GetFriendList(Param['User']), Session.ID, Param);
end;

procedure TData_Provider.HostLogin2Execute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  FriendList: TRtcRecord;
//  b: Boolean;
begin
  try
    with TRtcDataServer(Sender) do
    begin
      FriendList := GetFriendList(Param['User']);

//      b := Users.CheckPassword('100001125', '555');

      Users.HostLogin2(Param['user'], Param['Gateway'], Param['IsService'], FriendList, Session.ID);

      Users.SetPasswords(Param['user'], Session.ID, Param);

//      b := Users.CheckPassword('100001125', '555');

      Users.SetHostLockedState(Param['user'], FriendList, Session.ID, Param);

      Session['$MSG:Login'] := 'OK';
      Session['$MSG:User'] := Param['User'];
      Session['$MSG:Gateway'] := Param['Gateway'];
    end;
  finally
    FriendList.Free;
  end;

  //if DoHostLogin2(Sender, Param['User'], Param['Gateway'], Param) then
  Result.asString := 'OK';
end;

procedure TData_Provider.HostLoginExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  if Assigned(FStartForceUserLogoutThread) then
    FStartForceUserLogoutThread(Param['User'], True);

  if DoHostLogin(Sender, Param['User'], Param['Gateway'], Param['IsService'], Param) then
    Result.asString := 'OK';
end;

function TData_Provider.DoHostLogin(Sender: TRtcConnection; uname, gateway: String; isService: Boolean; Param: TRtcFunctionInfo): Boolean;
var
  FriendList: TRtcRecord;
//  b: Boolean;
begin
  with TRtcDataServer(Sender) do
  begin
    if (Trim(uname) = '')
      or (Trim(uname) = '-') then
    begin
      Result := False;
      raise Exception.Create('Username required for Login.');
    end;

    try
      FriendList := GetFriendList(uname);

//      b := Users.CheckPassword('100001125', '555');

      Users.HostLogin(uname, gateway, isService, FriendList, Session.ID);

  //    HostLoginProcedure(Param['User'], GetFriendListFunction(Param['User']));

      Users.SetPasswords(uname, Session.ID, Param);

//      b := Users.CheckPassword('100001125', '555');

      Users.SetHostLockedState(uname, FriendList, Session.ID, Param);

      Session['$MSG:HostLogin'] := 'OK';
      Session['$MSG:User'] := Param['User'];
      Session['$MSG:Gateway'] := Param['Gateway'];

//      if Assigned(FOnUserLogin) then
//        FOnUserLogin(Param['User']);

      Result := True;
    finally
      FriendList.Free;
    end;
  end;
end;

procedure TData_Provider.HostLogOutExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    if Session <> nil then
//      if Session['$MSG:HostLogin'] = 'OK' then
//        if Session['$MSG:User'] = Param['user'] then
          if Users.isHostLoggedIn(Param.asText['user'], Session.ID) then
          begin
//xLog('HostLogOutExecute ' + Param.asText['user']);
            Users.HostLogOut(Param.asText['user'], Session['$MSG:Gateway'], GetFriendList(Param.asText['user']), Session.ID);
            Session['$MSG:HostLogin']:= '';
            Session['$MSG:User']:= '';
            Session['$MSG:Gateway']:= '';
          end;

  if Assigned(FStartForceUserLogoutThread) then
    FStartForceUserLogoutThread(Param['User'], True);
end;

//procedure TData_Provider.DoLogoffUser(uname: String);
//begin
//  if Users.isHostLoggedIn(Param.asText['user'], Session.ID) then
//  begin
//    Users.HostLogOut(Session['$MSG:User'], Session['$MSG:Gateway'], GetFriendList(Session['$MSG:User']), Session.ID);
//    Session['$MSG:HostLogin']:= '';
//    Session['$MSG:User']:= '';
//    Session['$MSG:Gateway']:= '';
//
//    if Assigned(FOnUserLogOut) then
//      FOnUserLogOut(Param['User']);
//  end;
//end;

procedure TData_Provider.HostPassUpdateExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    Users.SetPasswords(Param['User'], Session.ID, Param);
end;

procedure TData_Provider.HostPingExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
//  i: Integer;
//  fFound: Boolean;
  UserName: String;
//  b: Boolean;
begin
  if Param['user'] = '-' then
    Exit;

//  b := Users.CheckPassword('100001125', '555');

  with TRtcDataServer(Sender) do
    with Result.NewRecord do
    if not Users.isHostLoggedIn(Param['User']) then
    begin
      asBoolean['NeedHostRelogin'] := True;
      if Assigned(FStartForceUserLogoutThread) then
        FStartForceUserLogoutThread(Param['User'], True);
    end
    else
      asBoolean['NeedHostRelogin'] := False;

  HostCheckLogin(Sender, Param['User'], Param['Gateway'], Param['IsService'], Param);

  Users.SetPasswords(Param['User'], Sender.Session.ID, Param);

//  b := Users.CheckPassword('100001125', '555');

  Users.SetLastHostActiveTime(Param['User'], Now);

//  UserName := 'Ping - ' + Param['User'] + ' - ' + DateTimeToStr(Now);

//  fFound := False;
//  for i := 0 to LogMemo.Lines.Count - 1 do
//    if Copy(LogMemo.Lines[i], 0, 16) = Copy(UserName, 0, 16) then
//    begin
//      LogMemo.Lines[i] := UserName;
//      fFound := True;
//    end;
//  if not fFound then
//    LogMemo.Lines.Insert(0, UserName);
end;

procedure TData_Provider.HostCheckLogin(Sender: TRtcConnection; const uname, gateway: String; isService: Boolean; Param: TRtcFunctionInfo);
//var
//  FriendList: TRtcRecord;
begin
  with TRtcDataServer(Sender) do
    begin
      if Session = nil then
        raise Exception.Create('No session for this client.')
//      else if (Session['$MSG:HostLogin'] <> 'OK') then
//        raise Exception.Create('Not logged in.')
//        User.RegUser(uname, gateway, Session.ID)
//      else if Session['$MSG:User'] <> uname then
//        raise Exception.Create('Login error. Wrong username.')
      else
      if not Users.isHostLoggedIn(uname, Session.ID) then
      begin
        DoHostLogin(Sender, uname, gateway, isService, Param);
//        raise Exception.Create('Logged out.');
//        Users.HostRegUser(uname, gateway, GetFriendList(uname), Session.ID);
        //Users.HostLogin(uname, gateway, GetFriendList(uname), Session.ID);
      end;
    end;
end;

procedure TData_Provider.HostRegisterExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
//  with TRtcDataServer(Sender) do
//  begin
//    if Param['User'] = '' then
//      raise Exception.Create('Username required to Register.');
//
//    Users.RegUser(Param['User'], Param['Gateway'], Session.ID);
//
//  //    Result.asObject:=User.LoadInfo(Param['user']);
//
//    Result.asString := 'OK';
//
//    Session['$MSG:HostLogin'] := 'OK';
//    Session['$MSG:User'] := Param['User'];
//    Session['$MSG:Gateway'] := Param['Gateway'];
//  end;
end;

function TData_Provider.AccountIsValid(name, pwd: String; var RealName, AccountUID: String): Boolean;
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    SP := TADOStoredProc.Create(nil);
    try
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'AccountIsValid';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@Email', ftWideString, pdInput, name);
//        AddParam(SP, '@Password', ftWideString, pdInput, pwd);
//        AddParam(SP, '@IsValid', ftInteger, pdOutput, 0);
//        AddParam(SP, '@Name', ftString, pdOutput, '');
//        AddParam(SP, '@AccountUID', ftGUID, pdOutput, '{00000000-0000-0000-0000-000000000000}');
        SP.Parameters.ParamByName('@Email').Value := name;
        SP.Parameters.ParamByName('@Password').Value := pwd;
        SP.Parameters.ParamByName('@IsValid').Value := 0;
        SP.Parameters.ParamByName('@Name').Value := '';
        SP.Parameters.ParamByName('@AccountUID').Value := SP.Parameters.ParamValues['@AccountUID'];
        //SP.Parameters.Command.ParamCheck := True;
        SP.ExecProc;

        Result := (SP.Parameters.ParamByName('@IsValid').Value = 1);
        RealName := SP.Parameters.ParamByName('@Name').Value;
        AccountUID := VarToStr(SP.Parameters.ParamByName('@AccountUID').Value);
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

function TData_Provider.LoadUserInfo(account, RealName, AccountUID: String): TRtcRecord;
var
  SP: TADOStoredProc;
  i: Integer;
begin
  Result := TRtcRecord.Create;
  Result.AutoCreate := True;

  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    SP := TADOStoredProc.Create(nil);
    try
      try
        with Result do
        begin
          with NewRecord('Out') do
          begin
            asString['AccountUID'] := AccountUID;
            asWideString['AccountName'] := RealName;

            SP.Connection := SQLConnection;
            SP.ProcedureName := 'GetAccountDevices';
            SP.Prepared := True;
            SP.Parameters.Refresh;
//            AddParam(SP, '@AccountUID', ftGUID, pdInput, AccountUID);
            SP.Parameters.ParamByName('@AccountUID').DataType := ftGuid;
            SP.Parameters.ParamByName('@AccountUID').Value := AccountUID;
            SP.Open;

            asBoolean['Result'] := True;
          end;
          if SP.RecordCount > 0 then
          begin
            with NewDataSet('DeviceList') do
            begin
              FieldType['ID'] := ft_Integer;
              FieldType['UID'] := ft_String;
              FieldType['Name'] := ft_WideString;
              FieldType['Description'] := ft_WideString;
              FieldType['GroupUID'] := ft_String;
              FieldType['GroupName'] := ft_WideString;
              FieldType['StateIndex'] := ft_Integer;
              SP.FindFirst;
              for i := 0 to SP.RecordCount - 1 do
              begin
                Append;

                asInteger['ID'] := SP.FieldByName('ID').Value;
                asString['UID'] := VarToStr(SP.FieldByName('UID').Value);
                asWideString['Name'] := SP.FieldByName('Name').Value;
                asWideString['Password'] := SP.FieldByName('Password').Value;
                asWideString['Description'] := SP.FieldByName('Description').Value;
                asString['GroupUID'] := VarToStr(SP.FieldByName('GroupUID').Value);
                asWideString['GroupName'] := SP.FieldByName('GroupName').Value;
                if Users.isHostLoggedIn(VarToStr(SP.FieldByName('ID').Value)) then
                  asInteger['StateIndex'] := MSG_STATUS_ONLINE
                else
                  asInteger['StateIndex'] := MSG_STATUS_OFFLINE;
                SP.Next;
              end;
            end;
          end;
        end;
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

function TData_Provider.AccountIsExists(email: String): Boolean;
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;
    try
      try
        SP := TADOStoredProc.Create(nil);
        SP.Connection := GetDataProvider.SQLConnection;
        SP.ProcedureName := 'AccountIsExists';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@Email', ftWideString, pdInput, email);
//        AddParam(SP, '@IsExists', ftInteger, pdOutput, 0);
        SP.Parameters.ParamByName('@Email').Value := email;
        SP.Parameters.ParamByName('@IsExists').Value := 0;
        SP.ExecProc;

        Result := (SP.Parameters.ParamByName('@IsExists').Value = 1);
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.AccountAddAccountExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    try
      SP := TADOStoredProc.Create(nil);
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'AddAccount';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@Email', ftWideString, pdInput, Param.asString['Email']);
//        AddParam(SP, '@Name', ftWideString, pdInput, Param.asString['Name']);
//        AddParam(SP, '@Password', ftWideString, pdInput, Param.asString['Pass']);
//        AddParam(SP, '@GroupName', ftWideString, pdInput, 'Мои компьютеры');
//        AddParam(SP, '@DeviceID', ftString, pdInput, Param.asString['DeviceID']);
//        AddParam(SP, '@DeviceName', ftWideString, pdInput, Param.asString['DeviceName']);
//        AddParam(SP, '@DevicePass', ftWideString, pdInput, Param.asString['DevicePass']);
//        AddParam(SP, '@IsExists', ftInteger, pdOutput, 0);
//        AddParam(SP, '@UID', ftGUID, pdOutput, SP.Parameters.ParamValues['@UID']);
        SP.Parameters.ParamByName('@Email').Value := Param.asString['Email'];
        SP.Parameters.ParamByName('@Name').Value := Param.asWideString['Name'];
        SP.Parameters.ParamByName('@Password').Value := Param.asWideString['Pass'];
        SP.Parameters.ParamByName('@GroupName').Value := 'Мои компьютеры';
        SP.Parameters.ParamByName('@DeviceID').Value := Param.asString['DeviceID'];
        SP.Parameters.ParamByName('@DeviceName').Value := Param.asWideString['DeviceName'];
        SP.Parameters.ParamByName('@DevicePass').Value := Param.asWideString['DevicePass'];
        SP.Parameters.ParamByName('@IsExists').Value := 0;
        SP.Parameters.ParamByName('@UID').Value := SP.Parameters.ParamValues['@UID'];
        SP.ExecProc;

        if SP.Parameters.ParamByName('@IsExists').Value then
          Result.asString := 'BUSY'
        else
          Result.asString := SP.Parameters.ParamByName('@UID').Value;
      except
        on E: Exception do
          raise Exception(E.Message);
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.AccountAddDeviceExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    SP := TADOStoredProc.Create(nil);
    try
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'AddAccountDevice';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@Name', ftWideString, pdInput, Param.asString['Name']);
//        AddParam(SP, '@Password', ftWideString, pdInput, Param.asString['Password']);
//        AddParam(SP, '@DeviceID', ftString, pdInput, Param.asString['DeviceID']);
//        AddParam(SP, '@GroupUID', ftString, pdInput, Param.asString['GroupUID']);
//        AddParam(SP, '@Description', ftWideString, pdInput, Param.asString['Description']);
//        AddParam(SP, '@AccountUID', ftString, pdInput, Param.asString['AccountUID']);
//        AddParam(SP, '@UID', ftGUID, pdOutput, SP.Parameters.ParamValues['@UID']);
        SP.Parameters.ParamByName('@Name').Value := Param.asWideString['Name'];
        SP.Parameters.ParamByName('@Password').Value := Param.asWideString['Password'];
        SP.Parameters.ParamByName('@DeviceID').Value := Param.asString['DeviceID'];
        SP.Parameters.ParamByName('@GroupUID').Value := Param.asString['GroupUID'];
        SP.Parameters.ParamByName('@Description').Value := Param.asWideString['Description'];
        SP.Parameters.ParamByName('@AccountUID').Value := Param.asString['AccountUID'];
        SP.Parameters.ParamByName('@UID').Value := SP.Parameters.ParamValues['@UID'];
        SP.ExecProc;

        Result.asString := SP.Parameters.ParamByName('@UID').Value;
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.AccountAddGroupExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

  SP := TADOStoredProc.Create(nil);
  try
    try
      SP.Connection := SQLConnection;
      SP.ProcedureName := 'AddDeviceGroup';
      SP.Prepared := True;
      SP.Parameters.Refresh;
//      AddParam(SP, '@Name', ftWideString, pdInput, Param.asString['Name']);
//      AddParam(SP, '@AccountUID', ftGUID, pdInput, Param.asString['AccountUID']);
//      AddParam(SP, '@UID', ftGUID, pdOutput, '{00000000-0000-0000-0000-000000000000}');
      SP.Parameters.ParamByName('@Name').Value := Param.asWideString['Name'];
      SP.Parameters.ParamByName('@AccountUID').Value := Param.asString['AccountUID'];
      SP.Parameters.ParamByName('@UID').Value := SP.Parameters.ParamValues['@UID'];
      SP.ExecProc;

      Result.asString := SP.Parameters.ParamByName('@UID').Value;
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
  finally
    SP.Free;
  end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.AccountChangeDeviceExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    SP := TADOStoredProc.Create(nil);
    try
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'ChangeAccountDevice';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@UID', ftGUID, pdInput, Param.asString['UID']);
//        AddParam(SP, '@Name', ftWideString, pdInput, Param.asString['Name']);
//        AddParam(SP, '@Password', ftWideString, pdInput, Param.asString['Password']);
//        AddParam(SP, '@DeviceID', ftString, pdInput, Param.asInteger['DeviceID']);
//        AddParam(SP, '@Description', ftWideString, pdInput, Param.asString['Description']);
//        AddParam(SP, '@GroupUID', ftGUID, pdInput, Param.asString['GroupUID']);
//        AddParam(SP, '@AccountUID', ftGUID, pdInput, Param.asString['AccountUID']);
        SP.Parameters.ParamByName('@UID').Value := Param.asString['UID'];
        SP.Parameters.ParamByName('@Name').Value := Param.asWideString['Name'];
        SP.Parameters.ParamByName('@Password').Value := Param.asWideString['Password'];
        SP.Parameters.ParamByName('@DeviceID').Value := Param.asInteger['DeviceID'];
        SP.Parameters.ParamByName('@Description').Value := Param.asWideString['Description'];
        SP.Parameters.ParamByName('@GroupUID').Value := Param.asString['GroupUID'];
        SP.Parameters.ParamByName('@AccountUID').Value := Param.asString['AccountUID'];
        SP.ExecProc;

        Result.asString := 'OK';
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.AccountChangeGroupExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    SP := TADOStoredProc.Create(nil);
    try
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'ChangeDeviceGroup';
        SP.Parameters.Refresh;
//        AddParam(SP, '@UID', ftGUID, pdInput, Param.asString['UID']);
//        AddParam(SP, '@Name', ftWideString, pdInput, Param.asString['Name']);
//        AddParam(SP, '@AccountUID', ftGUID, pdInput, Param.asString['AccountUID']);
        SP.Parameters.ParamByName('@UID').Value := Param.asString['UID'];
        SP.Parameters.ParamByName('@Name').Value := Param.asWideString['Name'];
        SP.Parameters.ParamByName('@AccountUID').Value := Param.asString['AccountUID'];
        SP.ExecProc;

        Result.asString := 'OK';
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

procedure TData_Provider.AccountDeleteGroupExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TADOStoredProc;
begin
  CS_DB.Acquire;
  try
//    if not SQLConnection.Connected then
//    begin
//      SQLConnection.Connected := False;
//      SQLConnection.Connected := True;
//    end;
    SQLConnection.Open;

    SP := TADOStoredProc.Create(nil);
    try
      try
        SP.Connection := SQLConnection;
        SP.ProcedureName := 'DeleteDeviceGroup';
        SP.Prepared := True;
        SP.Parameters.Refresh;
//        AddParam(SP, '@UID', ftGUID, pdInput, Param.asString['UID']);
//        AddParam(SP, '@AccountUID', ftGUID, pdInput, Param.asString['AccountUID']);
        SP.Parameters.ParamByName('@UID').Value := Param.asString['UID'];
        SP.Parameters.ParamByName('@AccountUID').Value := Param.asString['AccountUID'];
        SP.ExecProc;

        Result.asString := 'OK';
      except
        on E: Exception do
        begin
          raise Exception(E.Message);
          xLog(E.Message);
        end;
      end;
    finally
      SP.Free;
    end;
  finally
    CS_DB.Release;
  end;
end;

function GetDataProvider: TData_Provider;
begin
  if not Assigned(Data_Provider) then
    TData_Provider.Create(nil);
  Result := Data_Provider;
end;

procedure TData_Provider.DataModuleCreate(Sender: TObject);
begin
  tGWReloginThread := nil;

  Data_Provider := self;
  Users := TVircessUsers.Create;
  Users.GetFriendList_Func := GetFriendList;

  tCDHostsThread := TCheckDisconnectedThread.Create(True);
  tCDHostsThread.FDoWork := Users.CheckDisconnectedHosts;
  tCDHostsThread.FreeOnTerminate := True;
  tCDHostsThread.Resume;

  tCDGatewaysThread := TCheckDisconnectedThread.Create(True);
  tCDGatewaysThread.FDoWork := Users.CheckDisconnectedGateways;
  tCDGatewaysThread.FreeOnTerminate := True;
  tCDGatewaysThread.Resume;
end;

procedure TData_Provider.SendGatewayRelogin;
begin
  with MainGateClientModule do
  try
    with Data.NewFunction('Gateway.Relogin') do
    begin
      asString['Address'] := ThisGatewayAddress;
      asInteger['MaxUsers'] := ThisGatewayMaxUsers;
      Call(rGateRelogin);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TData_Provider.SendGatewayLogOut;
begin
  with MainGateClientModule do
  try
    with Data.NewFunction('Gateway.LogOut') do
    begin
      asString['Address'] := ThisGatewayAddress;
      Call(rGateLogout);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TData_Provider.GatewayReloginStart;
begin
  tGWReloginThread := TGatewayReloginThread.Create(True);
  tGWReloginThread.FDoSendGatewayRelogin := SendGatewayRelogin;
  tGWReloginThread.FDoSendGatewayLogOut := SendGatewayLogOut;
  tGWReloginThread.FreeOnTerminate := True;
  tGWReloginThread.Resume;
end;

procedure TData_Provider.GatewayLogOutStart;
begin
  if Assigned(tGWReloginThread) then
  begin
    tGWReloginThread.Terminate;
    tGWReloginThread := nil;
  end;
end;

procedure TData_Provider.DataModuleDestroy(Sender: TObject);
begin
  tCDHostsThread.Terminate;
  tCDGatewaysThread.Terminate;

  SQLConnection.Close;
  SQLConnection.Free;
  Users.Free;
  Data_Provider := nil;
end;

//procedure TData_Provider.HostModuleSessionClose(Sender: TRtcConnection);
//begin
//  with TRtcDataServer(Sender) do
//    if (Session <> nil) then
//      if (Session.isType['$MSG:HostLogin'] <> rtc_Null) then
//        if (Session['$MSG:HostLogin'] = 'OK') then
//          Users.HostLogOut(Session['$MSG:User'], Session['$MSG:Gateway'], GetFriendList(Session['$MSG:User']), Session.ID);
//end;

procedure TData_Provider.Module1SessionClose(Sender: TRtcConnection);
begin
//  with TRtcDataServer(Sender) do
//    if (Session <> nil) then
//    begin
//      if (Session.isType['$MSG:AccountLogin'] <> rtc_Null) then
//        if (Session['$MSG:AccountLogin'] = 'OK') then
//          Users.AccountLogOut(Session['$MSG:Account'], Session['$MSG:User'], GetFriendList(Session['$MSG:User']), Session.ID);
//
//      if (Session.isType['$MSG:HostLogin'] <> rtc_Null) then
//        if (Session['$MSG:HostLogin'] = 'OK') then
//          Users.HostLogOut(Session['$MSG:User'], Session['$MSG:Gateway'], GetFriendList(Session['$MSG:User']), Session.ID);
//    end;
end;

procedure TData_Provider.AccountLoginExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
var
  RealName, AccountUID, CurPass: String;
begin
  with TRtcDataServer(Sender) do
  begin
    CurPass := Param['Pass'];
    DeCrypt(CurPass, '@VCS@');

    if Param['Account'] = '' then
      raise Exception.Create('Username required for Login.')
//    else if Param['Pass'] = '' then
//      raise Exception.Create('Password required for Login.')
    else if not AccountIsValid(Param['Account'], CurPass, RealName, AccountUID) then
        raise Exception.Create('Username or password is not valid.');

    Users.AccountLogin(Param['Account'], Param['User'], CurPass, GetFriendList(Param['User']), Session.ID);

//    Result.asObject := User.LoadInfo(Param['User']);
    Result.asObject := LoadUserInfo(Param['Account'], RealName, AccountUID);

//    Result.asString := 'OK';

    Session['$MSG:AccountLogin'] := 'OK';
    Session['$MSG:User'] := Param['User'];
    Session['$MSG:Account'] := Param['Account'];
  end;
end;

procedure TData_Provider.AccountLogin2Execute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
var
  RealName, AccountUID, CurPass: String;
begin
  with TRtcDataServer(Sender) do
  begin
    CurPass := Param['Pass'];
    DeCrypt(CurPass, '@VCS@');

    if Param['account'] = '' then
      raise Exception.Create('Username required for Login.')
//    else if CurPass = '' then
//      raise Exception.Create('Password required for Login.')
    else if not AccountIsValid(Param['Account'], CurPass, RealName, AccountUID) then
        raise Exception.Create('Username or password is not valid.');

    Users.AccountLogin2(Param['Account'], Param['User'], CurPass, GetFriendList(Param['User']), Session.ID);

    Session['$MSG:AccountLogin'] := 'OK';
    Session['$MSG:User'] := Param['User'];
    Session['$MSG:Account'] := Param['Account'];
  end;
end;

procedure TData_Provider.AccountRegisterExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
//  with TRtcDataServer(Sender) do
//  begin
//    if Param['Account'] = '' then
//      raise Exception.Create('Username required to Register.')
//    else if Param['Pass'] = '' then
//      raise Exception.Create('Password required to Register.')
//    else if AccountIsExists(Param['Account']) then
//      Result.asString := 'BUSY';
////      raise Exception.Create('"' + Param['Account'] + '" is busy.');
//
//    Accounts.RegUser(Param['Account'], Param['User'], Param['Pass'], GetFriendList(Param['User']), Session.ID);
//
//  //    Result.asObject:=User.LoadInfo(Param['user']);
//
//    Result.asString := 'OK';
//
//    Session['$MSG:AccountLogin'] := 'OK';
//    Session['$MSG:User'] := Param['User'];
//    Session['$MSG:Account'] := Param['Account'];
//  end;
end;

procedure TData_Provider.CheckLogin(Sender: TRtcConnection; const account, uname, pass: String);
begin
  with TRtcDataServer(Sender) do
  begin
    if Session = nil then
      raise Exception.Create('No session for this client.')
//    else if (Session['$MSG:AccountLogin'] <> 'OK') then
//      raise Exception.Create('Not logged in.')
//      User.RegUser(account, uname, pass, GetFriendList(uname), Session.ID)
//    else if Session['$MSG:User'] <> uname then
//      raise Exception.Create('Login error. Wrong username.')
//    else if not User.isLoggedIn(uname, Session.ID) then
//      raise Exception.Create('Logged out.');
//      User.RegUser(account, uname, pass, GetFriendList(uname), Session.ID);
  end;
end;

procedure TData_Provider.ClientsDestroyExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  Gateway1.StartForceUserLogoutThread(Param.asString['UserName'], Param.asBoolean['AllConnectionsById']);
  Gateway2.StartForceUserLogoutThread(Param.asString['UserName'], Param.asBoolean['AllConnectionsById']);
  Gateway3.StartForceUserLogoutThread(Param.asString['UserName'], Param.asBoolean['AllConnectionsById']);
  Gateway4.StartForceUserLogoutThread(Param.asString['UserName'], Param.asBoolean['AllConnectionsById']);

  Result.asString := 'OK';
end;

procedure TData_Provider.AccountSendTextExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
//  CheckLogin(Sender, Param['user']);
//  user.SendText(Param.asText['user'], Param.asText['to'], Param.asText['text']);
end;

procedure TData_Provider.HostGetDataExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
var
  thischeck: TDateTime;
  arr: TRtcArray;
  cb: TRtcDelayedCall;
begin
  if (Param['user'] = '-')
    or (not Users.isHostLoggedIn(Param['user'])) then
    Exit;

  Users.SetLastHostActiveTime(Param['user'], Now);

  cb := nil;

  //HostCheckLogin(Sender, Param['User'], Param['Gateway'], Param);

  if not Param.asBoolean['delayed'] then
  begin
    { Set "delayed" parameter to TRUE, before preparing the call,
      because only changes we do to Param before we send it to
      the PrepareDelayedCall function will be memorized, while
      any changes we do to Param afterwards will be discarded. }
    Param.asBoolean['delayed'] := true;
    { Prepare delayed call, which will be triggered in 10 seconds
      in case the callback function is not used until then. }
    cb := PrepareDelayedCall(10000, Param, HostGetDataExecute);
    Users.SetCallback(Param['user'], cb);
  end;

  arr := Users.GetData(Param['user'], Param['check'], thischeck);
  if assigned(arr) then
  begin
    // don't need delayed call, new data is ready to be sent now!
    Users.SetCallback(Param['user'], nil);
    if assigned(cb) then
      CancelDelayedCall(cb);

    with Result.NewRecord do
    begin
      asObject['data'] := arr;
      asDateTime['check'] := thischeck;
    end;
  end
  else
  if assigned(cb) then
    PostDelayedCall(cb)
  else
    Users.SetCallback(Param['user'], nil);
end;

procedure TData_Provider.AccountGetDeviceStateExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
//  CheckLogin(Sender, Param['Account'], Param['User'], Param['Pass']);
  Users.AccountAddFriend(Param['User'], Param['Friend']);
end;

procedure TData_Provider.AccountDelFriendExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
//  CheckLogin(Sender, Param['user']);
//  user.DelFriend(Param['user'], Param['name']);
end;

procedure TData_Provider.AccountEmailIsExistsExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  Result.asBoolean := AccountIsExists(Param.asString['Email']);
end;

procedure TData_Provider.AccountLogOutExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    if Session <> nil then
      if Session['$MSG:AccountLogin'] = 'OK' then
        if Session['$MSG:User'] = Param['user'] then
          if Users.isAccountLoggedIn(Param.asText['account'], Session.ID) then
          begin
            Users.AccountLogOut(Session['$MSG:Account'], Session['$MSG:User'], GetFriendList(Session['$MSG:User']), Session.ID);
            Session['$MSG:AccountLogin']:='';
            Session['$MSG:User']:='';
            Session['$MSG:Account'] := '';
          end;
end;

procedure TData_Provider.AccountPingExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  //Nothing to do
end;

initialization
  CS_DB := TCriticalSection.Create;

finalization
  CS_DB.Free;
  if Assigned(Data_Provider) then
  begin
    Data_Provider.Free;
    Data_Provider := nil;
  end;

end.
