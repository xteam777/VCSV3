unit rtcHosts;

interface

uses
  SysUtils,

{$IFDEF VER120}
  FileCtrl,
{$ENDIF}
{$IFDEF VER130}
  FileCtrl,
{$ENDIF}

  rtcTypes, rtcSyncObjs,
  rtcInfo, rtcCrypt,
  rtcSrvModule, uVircessTypes;

type
  TVircessHosts = class
  private
    HostsList: TRtcRecord;

    HostsInfo: TRtcInfo;

    userCS: TRtcCritSec;

    GatewayServerList: TGatewayServerList;

    procedure doHostLogIn(uname, gateway: String; sessid: RtcString);
    procedure doHostLogIn2(uname, gateway: String; sessid: RtcString); // 2nd connnection
    procedure doHostLogOut(uname, gateway: String; sessid: RtcString);

  public
    constructor Create;
    destructor Destroy; override;

    function isHostLoggedIn(uname: String; sessid: RtcString): Boolean; overload;
    function isHostLoggedIn(uname: String): Boolean; overload;

    procedure HostLogin(uname, gateway: String; sessid: RtcString);
    procedure HostLogin2(uname, gateway: String; sessid: RtcString); // 2nd connection
    procedure HostLogout(uname, gateway: String; sessid: RtcString);

    procedure HostRegUser(uname, gateway: String; sessid: RtcString);
    procedure HostDelUser(uname: String);

    function HostExists(uname: String): Boolean;

    procedure AddGateway(GatewayRec: PGatewayServerRec);
    procedure EraseGatewayList;
    function GetAvailableGateway: PGatewayServerRec;
    function GetUserGateway(uname: String): PGatewayServerRec;

    procedure AddUserToGateway(uname, gateway: String);
    procedure DelUserFromGateway(uname, gateway: String);

    procedure SetPasswords(uname: String; sessid: RtcString; Param: TRtcFunctionInfo);
    function CheckPassword(uname, pass: String): Boolean;
  end;

implementation

{ TRtcMessengerUsers }

constructor TVircessHosts.Create;
begin
  inherited;

  HostsList := TRtcRecord.Create;
  userCS := TRtcCritSec.Create;
  HostsInfo := TRtcInfo.Create;

end;

destructor TVircessHosts.Destroy;
begin
  EraseGatewayList;

  HostsInfo.Free;
  HostsList.Free;
  userCS.Free;

  inherited;
end;

function TVircessHosts.CheckPassword(uname, pass: String): Boolean;
var
  i: Integer;
begin
  userCS.Acquire;
  Result := False;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
      raise Exception.Create('User ' + uname + ' not logged in.')
    else
      if HostsInfo.Child[uname].asRecord['Passwords'] <> nil then
        with HostsInfo.Child[uname].asRecord['Passwords'] do
          for i := 0 to Count - 1 do
            if asString[IntToStr(i)] = pass then
            begin
               Result := True;
               Break;
            end;
  finally
    userCS.Release;
  end;
end;

function TVircessHosts.GetUserGateway(uname: String): PGatewayServerRec;
var
  gateway: String;
  i: Integer;
begin
  userCS.Acquire;
  try
    if HostsInfo.Child[uname] = nil then
      Result := nil
    else
    begin
      gateway := HostsInfo.Child[uname]['Gateway'];
      for i := 0 to Length(GatewayServerList) - 1 do
        if (GatewayServerList[i].Address + ':' + GatewayServerList[i].Port) = gateway then
          Result := GatewayServerList[i];
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.EraseGatewayList;
var
  i: Integer;
begin
  userCS.Acquire;
  try
    for i := 0 to Length(GatewayServerList) - 1 do
    begin
      Dispose(GatewayServerList[i]);
    end;
    SetLength(GatewayServerList, 0);
  finally
    userCS.Release;
  end;
end;

function TVircessHosts.GetAvailableGateway: PGatewayServerRec;
var
  i: Integer;
  MaxFreeUsers: Integer;
  CurGateway: PGatewayServerRec;
begin
  if Length(GatewayServerList) = 0 then
  begin
    Result := nil;
    Exit;
  end;

  CurGateway := nil;
  MaxFreeUsers := -1;
  for i := 0 to Length(GatewayServerList) - 1 do
    if (((GatewayServerList[i].MaxUsers - GatewayServerList[i].Users.Count) > MaxFreeUsers) or (CurGateway = nil)) then
    begin
      CurGateway := GatewayServerList[i];
      MaxFreeUsers := GatewayServerList[i].MaxUsers - GatewayServerList[i].Users.Count;
    end;

  Result := CurGateway;
end;

procedure TVircessHosts.AddGateway(GatewayRec: PGatewayServerRec);
begin
  userCS.Acquire;
  try
    SetLength(GatewayServerList, Length(GatewayServerList) + 1);
    GatewayServerList[Length(GatewayServerList) - 1] := GatewayRec;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.AddUserToGateway(uname, gateway: String);
var
  i: Integer;
begin
  userCS.Acquire;
  try
    for i := 0 to Length(GatewayServerList) - 1 do
      if (GatewayServerList[i].Address + ':' + GatewayServerList[i].Port) = gateway then
        GatewayServerList[i].Users[uname] := uname;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.DelUserFromGateway(uname, gateway: String);
var
  i: Integer;
begin
  userCS.Acquire;
  try
    for i := 0 to Length(GatewayServerList) - 1 do
      if (GatewayServerList[i].Address + ':' + GatewayServerList[i].Port) = gateway then
        GatewayServerList[i].Users.isNull[uname] := True;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.doHostLogIn2(uname, gateway: String; sessid: RtcString);
begin
  userCS.Acquire;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
//      raise Exception.Create('User ' + uname + ' not logged in.')
      HostRegUser(uname, gateway, sessid)
    else
    begin
      with HostsInfo.Child[uname] do
      begin
        asString['Session2'] := RtcString(sessid);
        asString['Gateway'] := RtcString(gateway);
      end;
      AddUserToGateway(uname, RtcString(gateway));
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.SetPasswords(uname: String; sessid: RtcString; Param: TRtcFunctionInfo);
var
  i: Integer;
begin
  userCS.Acquire;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
      raise Exception.Create('User ' + uname + ' not logged in.')
    else
      if HostsInfo.Child[uname].asRecord['Passwords'] = nil then
        HostsInfo.Child[uname].NewRecord('Passwords');
      with HostsInfo.Child[uname].asRecord['Passwords'] do
        for i := 0 to Param.asRecord['Passwords'].Count - 1 do
        begin
          asString[IntToStr(i)] := Param.asRecord['Passwords'][IntToStr(i)];
        end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.doHostLogIn(uname, gateway: string; sessid: RtcString);
begin
  userCS.Acquire;
  try
    // Remove existing info.
    if HostsInfo.Child[uname] <> nil then
      DelUserFromGateway(uname, HostsInfo.Child[uname]['Gateway']);
    HostsInfo.SetNil(uname);
    // Remember new session ID
    with HostsInfo.NewChild(uname) do
    begin
      asString['Session'] := sessid;
      asString['Gateway'] := RtcString(gateway);
    end;
    AddUserToGateway(uname, RtcString(gateway));
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.doHostLogOut(uname, gateway: String; sessid: RtcString);
begin
  userCS.Acquire;
  try
  // If logged in under this session ID, remove info
  if HostsInfo.Child[uname] <> nil then
    if HostsInfo.Child[uname]['session'] = sessid then
    begin
      DelUserFromGateway(uname, gateway);
      DelUserFromGateway(uname, HostsInfo.Child[uname]['gateway']);
      HostsInfo.SetNil(uname);
    end;
  finally
    userCS.Release;
  end;
end;

function TVircessHosts.isHostLoggedIn(uname: String; sessid: RtcString):boolean;
begin
  userCS.Acquire;
  try
    Result := False;
    // If logged in under this session ID, return True
    if HostsInfo.Child[uname] <> nil then
      if (HostsInfo.Child[uname]['session'] = sessid) or
         (HostsInfo.Child[uname]['session2'] = sessid) then
        Result := True;
  finally
    userCS.Release;
  end;
end;

function TVircessHosts.isHostLoggedIn(uname: String):boolean;
begin
  userCS.Acquire;
  try
    Result := HostsInfo.Child[uname] <> nil;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.HostLogin(uname, gateway: String; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if uname='' then
      raise Exception.Create('Username required for Login.')
    else
    begin
      if HostsList.isType[uname] <> rtc_Record then // user doesn't exist
        //raise Exception.Create('User "'+uname+'" not registered.')
        HostRegUser(uname, gateway, sessid)
    else
    begin
      with HostsList.asRecord[uname] do
//        if asText['pass']<>upass then
//          raise Exception.Create('Wrong password for user "'+uname+'".')
//        else
          doHostLogIn(uname, gateway, sessid);
      end;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.HostLogin2(uname, gateway: String; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if uname='' then
      raise Exception.Create('Username required for Login.')
    else
      begin
      if HostsList.isType[uname] <> rtc_Record then // user doesn't exist
        //raise Exception.Create('User "'+uname+'" not registered.')
        HostRegUser(uname, gateway, sessid)
      else
      begin
//        with UserList.asRecord[uname] do
//          if asText['pass']<>upass then
//            raise Exception.Create('Wrong password for user "'+uname+'".')
//          else
        doHostLogIn2(uname, gateway, sessid);
      end;
    end;
  finally
    userCS.Release;
  end;
end;

function TVircessHosts.HostExists(uname:string):boolean;
begin
  userCS.Acquire;
  try
    Result := False;
    if uname <> '' then
      if HostsList.isType[uname] = rtc_Record then // user exists
        Result := True;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.HostRegUser(uname, gateway: String; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if uname='' then
      raise Exception.Create('Username required to Register.')
    else
    begin
//    if UserList.isType[uname] <> rtc_Null then
      if not HostsList.isNull[uname] then
        doHostLogIn(uname, gateway, sessid)
//        raise Exception.Create('Username "' + uname + '" already taken. Can not register a new user with the same name.')
      else // user doesn't exists
      begin
        with HostsList.NewRecord(uname) do
        begin
          doHostLogIn(uname, gateway, sessid);
        end;
      end;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.HostDelUser(uname: String);
begin
  userCS.Acquire;
  try
    HostsList.isNull[uname] := True; // das entfernt den Record aus UserList
  //    SaveUserList; // Das speichert die neue UserList
  finally
    userCS.Release;
  end;
end;

procedure TVircessHosts.HostLogout(uname, gateway: String; sessid: RtcString);
begin
  doHostLogOut(uname, gateway, sessid);
end;


end.
