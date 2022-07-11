unit rtcHostsProvider;

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

  rtcHosts, Data.DB, Data.Win.ADODB, Variants;

type
//  THostLoginProcedure = procedure(uname: string; Friends: TRtcRecord) of object;
//  TGetFriendListFunction = function (uname: String): TRtcRecord of object;

  THosts_Provider = class(TDataModule)
    Module: TRtcServerModule;
    HostsFunctions: TRtcFunctionGroup;
    HostLogin: TRtcFunction;
    HostRegister: TRtcFunction;
    HostGetData: TRtcFunction;
    ServerLink: TRtcDataServerLink;
    HostLogOut: TRtcFunction;
    HostLogin2: TRtcFunction;
    HostPing: TRtcFunction;
    SQLConnection: TADOConnection;
    HostGetUserConnectionInfo: TRtcFunction;
    HostActivate: TRtcFunction;
    HostPassUpdate: TRtcFunction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure ModuleSessionClose(Sender: TRtcConnection);

    procedure HostLoginExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostRegisterExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostGetDataExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostLogOutExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostLogin2Execute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostPingExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostGetUserConnectionInfoExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure HostActivateExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
    procedure HostPassUpdateExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
  protected
    procedure HostCheckLogin(Sender: TRtcConnection; const uname, gateway: String);
  public
    { Public declarations }
    Hosts: TVircessHosts;

//    GetFriendListFunction: TGetFriendListFunction;
//    HostLoginProcedure: THostLoginProcedure;

    procedure FillGatewayList;
  end;

function GetHostsProvider(FreePrior: Boolean): THosts_Provider;

implementation

{$R *.dfm}

var
  Hosts_Provider: THosts_Provider;


procedure THosts_Provider.HostActivateExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo;
      Result: TRtcValue);
var
  SP: TADOStoredProc;
  GatewayRec: PGatewayServerRec;
begin
    if not SQLConnection.Connected then
      SQLConnection.Connected := True;
  try
    SP := TADOStoredProc.Create(nil);
    SP.Connection := SQLConnection;
    SP.ProcedureName := 'GetDeviceID';
    SP.Parameters.Refresh;
    SP.Parameters.ParamByName('@Hash').Value := Param.asString['Hash'];
    SP.Parameters.ParamByName('@ID').Value := 0;
    SP.ExecProc;

    with Result.NewRecord do
    begin
      asInteger['ID'] := SP.Parameters.ParamByName('@ID').Value;
      GatewayRec := Hosts.GetAvailableGateway;
      if GatewayRec <> nil then
      begin
        asBoolean['Result'] := True;
        asString['Gateway'] := GatewayRec^.Address;
        asString['Port'] := GatewayRec^.Port;
      end
      else
        asBoolean['Result'] := False;
    end;
  finally
    SP.Free;
  end;
end;

procedure THosts_Provider.FillGatewayList;
var
  SP: TADOStoredProc;
  GatewayRec: PGatewayServerRec;
begin
  SP := TADOStoredProc.Create(nil);
  SP.Connection := GetHostsProvider(False).SQLConnection;
  SP.ProcedureName := 'GetGatewayList';
  SP.Parameters.Refresh;
  SP.Open;

  if SP.RecordCount > 0 then
  begin
    while not SP.Eof do
    begin
      New(GatewayRec);
      GatewayRec^.Users := TRtcRecord.Create;
      GatewayRec^.Users.AutoCreate := True;
      GatewayRec^.Address := SP.FieldByName('Address').Value;
      GatewayRec^.Port := SP.FieldByName('Port').Value;
      GatewayRec^.MaxUsers := SP.FieldByName('MaxUsers').Value;

      Hosts.AddGateway(GatewayRec);

      SP.Next;
    end;
  end;
  SP.Free;
end;

procedure THosts_Provider.HostGetUserConnectionInfoExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  GatewayRec: PGatewayServerRec;
begin
  if not Hosts.isLoggedIn(Param.asString['User']) then
  with Result.NewRecord do
  begin
    asBoolean['Result'] := False;
      asString['User'] := Param.asString['User'];
    Exit;
  end;

  GatewayRec := Hosts.GetUserGateway(Param.asString['User']);
  with Result.NewRecord do
  begin
    asBoolean['Result'] := Hosts.CheckPassword(Param.asString['User'], Param.asString['Pass']);
    if GatewayRec <> nil then
    begin
      asString['User'] := Param.asString['User'];
      asString['Action'] := Param.asString['Action'];
      asString['Address'] := GatewayRec.Address;
      asString['Port'] := GatewayRec.Port;
    end;
  end;
end;

function GetHostsProvider(FreePrior: Boolean):THosts_Provider;
begin
//  if FreePrior
//    and Assigned(Hosts_Provider) then
//    Hosts_Provider.Free;
  if not assigned(Hosts_Provider) then
    THosts_Provider.Create(nil);
  Result := Hosts_Provider;
end;

procedure THosts_Provider.DataModuleCreate(Sender: TObject);
begin
  Hosts_Provider := Self;
  Hosts := TVircessHosts.Create;
end;

procedure THosts_Provider.DataModuleDestroy(Sender: TObject);
begin
  SQLConnection.Connected := False;
  Hosts.Free;
  Hosts_Provider := nil;
end;

procedure THosts_Provider.ModuleSessionClose(Sender: TRtcConnection);
begin
  with TRtcDataServer(Sender) do
    if (Session <> nil) then
      if (Session.isType['$MSG:HostLogin'] <> rtc_Null) then
        if (Session['$MSG:HostLogin'] = 'OK') then
          Hosts.LogOut(Session['$MSG:User'], Session['$MSG:Gateway'], Session.ID);
end;

procedure THosts_Provider.HostLoginExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
  begin
    if Param['User'] = '' then
      raise Exception.Create('Username required for Login.');

    Hosts.Login(Param['User'], Param['Gateway'], Session.ID);

//    HostLoginProcedure(Param['User'], GetFriendListFunction(Param['User']));

    Hosts.SetPasswords(Param['User'], Session.ID, Param);

    Result.asString := 'OK';

//    Result.asString := 'OK';

    Session['$MSG:HostLogin'] := 'OK';
    Session['$MSG:User'] := Param['User'];
    Session['$MSG:Gateway'] := Param['Gateway'];
  end;
end;

procedure THosts_Provider.HostLogin2Execute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
  begin
    if Param['User'] = '' then
      raise Exception.Create('Username required for Login.');

    Hosts.Login2(Param['User'], Param['Gateway'], Session.ID);

    Hosts.SetPasswords(Param['User'], Session.ID, Param);

    Session['$MSG:HostLogin'] := 'OK';
    Session['$MSG:User'] := Param['User'];
    Session['$MSG:Gateway'] := Param['Gateway'];
  end;
end;

procedure THosts_Provider.HostRegisterExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
  begin
    if Param['User'] = '' then
      raise Exception.Create('Username required to Register.');

    Hosts.RegUser(Param['User'], Param['Gateway'], Session.ID);

  //    Result.asObject:=User.LoadInfo(Param['user']);

    Result.asString := 'OK';

    Session['$MSG:HostLogin'] := 'OK';
    Session['$MSG:User'] := Param['User'];
    Session['$MSG:Gateway'] := Param['Gateway'];
  end;
end;

procedure THosts_Provider.HostPassUpdateExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    Hosts.SetPasswords(Param['User'], Session.ID, Param);
end;

procedure THosts_Provider.HostCheckLogin(Sender: TRtcConnection; const uname, gateway: String);
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
//      else if not User.isLoggedIn(uname, Session.ID) then
//        raise Exception.Create('Logged out.');
//        User.RegUser(uname, gateway, Session.ID);
    end;
end;

procedure THosts_Provider.HostGetDataExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    HostCheckLogin(Sender, Param['User'], Param['Gateway']);

  with Result.NewRecord do
  begin
    asObject['data'] := TRtcArray.Create;
    asDateTime['check'] := Now;
  end;
end;

procedure THosts_Provider.HostLogOutExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  with TRtcDataServer(Sender) do
    if Session <> nil then
      if Session['$MSG:HostLogin'] = 'OK' then
        if Session['$MSG:User'] = Param['user'] then
          if Hosts.isLoggedIn(Param.asText['user'], Session.ID) then
          begin
            Hosts.LogOut(Session['$MSG:User'], Session['$MSG:Gateway'], Session.ID);
            Session['$MSG:HostLogin']:= '';
            Session['$MSG:User']:= '';
            Session['$MSG:Gateway']:= '';
          end;
end;

procedure THosts_Provider.HostPingExecute(Sender: TRtcConnection; Param: TRtcFunctionInfo; Result: TRtcValue);
begin
// Nothing to do.
end;

initialization
finalization
if assigned(Hosts_Provider) then
  begin
  Hosts_Provider.Free;
  Hosts_Provider := nil;
  end;
end.
