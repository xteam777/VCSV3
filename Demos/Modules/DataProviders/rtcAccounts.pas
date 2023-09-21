unit rtcAccounts;

interface

uses
  SysUtils, SendDestroyToGateway,

{$IFDEF VER120}
  FileCtrl,
{$ENDIF}
{$IFDEF VER130}
  FileCtrl,
{$ENDIF}

  rtcTypes, rtcSystem,
  rtcInfo, rtcCrypt, DateUtils,
  rtcSrvModule, uVircessTypes, rtcLog;

const
//  MSG_LIST_CRYPT_KEY:RtcString = '$RtcMessenger_UserList';
  MSG_DATA_CRYPT_KEY: RtcString = '$RtcMessenger_UserData';
  MSG_INFO_CRYPT_KEY: RtcString = '$RtcMessenger_UserInfo';

  // Sub-Folder relative to AppFileName, inside which Messenger Data files will be stored
  MSG_DATA_FOLDER: String = 'GatewayData';

type
  TGetFriendList_Func = function(uname: String): TRtcRecord of object;

  TVircessUsers = class
  private
//    UserListFileName: String;
    UserDataFileName: String;

    AccountsList: TRtcRecord;
    AccountsInfo: TRtcInfo;
    AccountsID: TRtcInfo;
    HostsList: TRtcRecord;
    HostsInfo: TRtcInfo;
    GatewaysList: TRtcRecord;
    GatewaysInfo: TRtcInfo;

    userCS: TRtcCritSec;
    accountsCS: TRtcCritSec;
    msgCS: TRtcCritSec;
    gatewayCS: TRtcCritSec;

    procedure doAccountLogIn(Account, uname: String; Friends: TRtcRecord; sessid: RtcString);
    procedure doAccountLogIn2(Account, uname: String; Friends: TRtcRecord; sessid: RtcString); // 2nd connnection
    procedure doAccountLogOut(Account, uname: String; Friends: TRtcRecord; sessid: RtcString);

    function isValidAccountName(const uname: String): Boolean;

    procedure SendData(const to_name: String; data: TRtcValueObject);

    function GetCallback(uname: String): TRtcDelayedCall;

    procedure TriggerCallback(uname: String);

    procedure doHostLogIn(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
    procedure doHostLogIn2(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString); // 2nd connnection
    procedure doHostLogOut(uname, gateway, ConsoleId: String; Friends: TRtcRecord; sessid: RtcString; DisconnectAll: Boolean = False);

    procedure NotifyAccountsOnHostLogIn(uname: String; Friends: TRtcRecord);
    procedure NotifyAccountsOnHostLogOut(uname: String; Friends: TRtcRecord; log_out: Boolean);
    procedure NotifyAccountsOnHostLockedUpdate(uname: String; Friends: TRtcRecord; LockedState: Integer; ServiceStarted: Boolean);

  public
    GetFriendList_Func: TGetFriendList_Func;
    FOnUserLogIn: TUserEvent;
    FOnUserLogOut: TUserEvent;
    FPingTimeout: Integer;
    FAccountsCount, FHostsCount, FGatewaysCount: Integer;
    ThisGatewayAddress: String;

    constructor Create;
    destructor Destroy; override;

    procedure SetCallback(uname:string; cb:TRtcDelayedCall);

//    function isAccountLoggedIn(account: String; sessid: RtcString): Boolean; overload;
//    function isAccountLoggedIn(account: String): Boolean; overload;

    procedure AccountLogin(Account, uname, upass: String; Friends: TRtcRecord; sessid: RtcString);
    procedure AccountLogin2(Account, uname, upass: String; Friends: TRtcRecord; sessid: RtcString); // 2nd connection
    procedure AccountLogout(Account, uname: String; Friends: TRtcRecord; sessid: RtcString);

//    procedure AccountRegUser(Account, uname, upass: String; Friends: TRtcRecord; sessid: RtcString);
//    procedure AccountDelUser(account: String);

    procedure AccountAddFriend(uname, friend_name: String);

//    function IsAccountExists(account: String): Boolean;

//    procedure SendText(const from_name, to_name, text: String);

    function GetData(const uname: String; lastcheck: TDateTime; var thischeck: TDateTime): TRtcArray;

    function isAccountLoggedIn(account: String; sessid: RtcString): Boolean; overload;
    function isAccountLoggedIn(account: String): Boolean; overload;

    procedure DeleteAccount(account: String);

    //////////////////////////////////////// HOSTS /////////////////////////////////////////

    function isHostLoggedIn(uname: String; sessid: RtcString): Boolean; overload;
    function isHostLoggedIn(uname: String): Boolean; overload;

    procedure HostLogin(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
    procedure HostLogin2(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString); // 2nd connection
    procedure HostLogout(uname, gateway, ConsoleId: String; Friends: TRtcRecord; sessid: RtcString);

    procedure HostRegUser(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
    procedure HostDelUser(uname: String);

    function IsHostExists(uname: String): Boolean;

    function HostIsService(uname: String): Boolean;

    procedure EraseGatewayList;
    function GetAvailableGateway: String;
    function GetUserGateway(uname: String): String;

    procedure AddUserToGateway(uname, gateway: String);
    procedure DelUserFromGateway(uname, gateway: String);

    procedure SetServiceActiveConsoleClient(uname, ConsoleId: String);
    function GetUserActiveConsoleClient(uname: String): String;
    procedure RemoveActiveConsoleClientFromService(uname: String);

    procedure SetHostLockedState(uname: String; Friends: TRtcRecord; sessid: RtcString; Param: TRtcFunctionInfo);
    function GetHostLockedState(uname: String): Integer;
    function GetHostServiceStarted(uname: String): Boolean;

    procedure SetPasswords(uname: String; sessid: RtcString; Param: TRtcFunctionInfo);
    function CheckPassword(uname, pass: String): Boolean;

    procedure SetLastHostActiveTime(uname: String; Time: TDateTime);
    procedure CheckDisconnectedHosts;
    procedure DelUserFromAccountsID(uname: String);

    function GetAccountsCount: Integer;
    function GetHostsCount: Integer;
    function GetGatewaysCount: Integer;

    procedure GatewayReLogin(address: String; MaxUsers: Integer);
    procedure GatewayLogOut(address: String);
    function isGatewayLoggedIn(address: String): Boolean;
    procedure CheckDisconnectedGateways;
    procedure DisconnectServiceClients(ServiceUserName: String);
  end;

implementation

{ TRtcMessengerUsers }

function TVircessUsers.GetAccountsCount: Integer;
var
  i: Integer;
begin
  userCS.Acquire;
  try
    Result := FAccountsCount;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetHostsCount: Integer;
var
  i: Integer;
begin
  userCS.Acquire;
  try
    Result := FHostsCount;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetGatewaysCount: Integer;
var
  i: Integer;
begin
  gatewayCS.Acquire;
  try
    Result := FGatewaysCount;
  finally
    gatewayCS.Release;
  end;
end;

constructor TVircessUsers.Create;
begin
  inherited;

  FAccountsCount := 0;
  FHostsCount := 0;
  FGatewaysCount := 0;

  AccountsList := TRtcRecord.Create;
  HostsList := TRtcRecord.Create;

  AccountsInfo := TRtcInfo.Create;
  HostsInfo := TRtcInfo.Create;

  GatewaysList := TRtcRecord.Create;
  GatewaysInfo := TRtcInfo.Create;

  AccountsID := TRtcInfo.Create;

  userCS := TRtcCritSec.Create;
  accountsCS := TRtcCritSec.Create;
  msgCS := TRtcCritSec.Create;
  gatewayCS := TRtcCritSec.Create;

  UserDataFileName := ExtractFilePath(AppFileName);
  if Copy(UserDataFileName, Length(UserDataFileName),1) <> '\' then
    UserDataFileName := UserDataFileName + '\';

  if MSG_DATA_FOLDER <> '' then
    begin
    UserDataFileName := UserDataFileName + MSG_DATA_FOLDER;
    if not DirectoryExists(UserDataFileName) then
      if not CreateDir(UserDataFileName) then
      begin
        UserDataFileName := GetTempDirectory;
        if Copy(UserDataFileName, Length(UserDataFileName), 1) <> '\' then
          UserDataFileName := UserDataFileName + '\';
        UserDataFileName := UserDataFileName + MSG_DATA_FOLDER;
        if not DirectoryExists(UserDataFileName) then
          CreateDir(UserDataFileName);
      end;
    end;

//  UserListFileName:=UserDataFileName+'\Users.list';
  UserDataFileName := UserDataFileName + '\';

  FPingTimeout := 30;

  //  LoadUserList;
end;

destructor TVircessUsers.Destroy;
begin
  EraseGatewayList;

  AccountsID.Free;
  AccountsInfo.Free;
  AccountsList.Free;
  HostsInfo.Free;
  HostsList.Free;
  GatewaysInfo.Free;
  GatewaysList.Free;
  userCS.Free;
  accountsCS.Free;
  msgCS.Free;
  gatewayCS.Free;

  inherited;
end;

procedure TVircessUsers.doAccountLogIn2(Account, uname: String; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if AccountsID.Child[Account] = nil then
    begin
      FAccountsCount := FAccountsCount + 1;

      if AccountsID.Child[Account] = nil then
        AccountsID.NewChild(Account);
      if AccountsID.Child[Account].isNull['users'] then
        AccountsID.Child[Account].NewRecord('users');

      if AccountsList.isType[Account] = rtc_Null then
        AccountsList.NewRecord(Account);

      AccountsID.Child[Account].asRecord['users'].asString[uname] := uname;
      AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] := 1;
    end
    else
    if AccountsID.Child[Account].asRecord['users'].isType[uname] = rtc_Null then
    begin
      AccountsID.Child[Account].asRecord['users'].asString[uname] := uname;
      AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] :=  AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] + 1;
    end;

    // Remember new session ID
    if AccountsInfo.Child[Account] = nil then
      raise Exception.Create('Account not logged in.')
    else
      with AccountsInfo.Child[Account] do
        asString['Session2'] := RtcString(sessid);
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.doAccountLogIn(Account, uname: string; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if AccountsID.Child[Account] = nil then
    begin
      FAccountsCount := FAccountsCount + 1;

      if AccountsID.Child[Account] = nil then
        AccountsID.NewChild(Account);
      if AccountsID.Child[Account].isNull['users'] then
        AccountsID.Child[Account].NewRecord('users');

      if AccountsList.isType[Account] = rtc_Null then
        AccountsList.NewRecord(Account);

      AccountsID.Child[Account].asRecord['users'].asString[uname] := uname;
      AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] := 1;
    end
    else
    if AccountsID.Child[Account].asRecord['users'].isType[uname] = rtc_Null then
    begin
      AccountsID.Child[Account].asRecord['users'].asString[uname] := uname;
      AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] :=  AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] + 1;
    end;

    // Remove existing info.
    AccountsInfo.SetNil(Account);
    // Remember new session ID
    with AccountsInfo.NewChild(Account) do
      asString['Session'] := sessid;
  finally
    userCS.Release;
  end;

//  doHostLogIn(uname, Friends);

  NotifyAccountsOnHostLogIn(uname, Friends);
end;

procedure TVircessUsers.NotifyAccountsOnHostLogin(uname: string; Friends: TRtcRecord);
var
  rec, rec2: TRtcRecord;
  fname: String;
  i, j: Integer;
  log_in: Boolean;
begin
  userCS.Acquire;
  try
    with Friends do //Àêêàóíòû, ó êîòîðûõ åñòü â ñïèñêå ýòîò ÈÄ
    begin
      rec := TRtcRecord.Create;
      rec2 := TRtcRecord.Create;
      try
        for i := 0 to Count - 1 do // Send "login" message to all friends.
        begin
          if AccountsID.Child[FieldName[i]] = nil then //Åñëè òåêóùèé àêêóàíò íå çàëîãèíåí
            Continue;
          for j := 0 to AccountsID.Child[FieldName[i]].asRecord['users'].Count - 1 do //Проходимся по всем ид, с которых есть логин в текущий аккаунт
          begin
            if AccountsID.Child[FieldName[i]].asRecord['users'].isNull[AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]] then
              Continue
            else
            begin
  //            fname := AccountsID.Child[FieldName[i]].Child[IntToStr(j)].FieldName[0];
              fname := AccountsID.Child[FieldName[i]].asRecord['users'][AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]];
              if fname = '' then
                Continue;

              try
                if isHostLoggedIn(fname) then // friend logged in
                begin
                  // Send ourself info that friend is logged in.
                  rec.asText['login'] := fname;
                  SendData(uname, rec);

                  // Send friend info that we're logging in.
                  rec.asText['login'] := uname;
                  SendData(fname, rec);
                end
                else
                begin
                  // Send ourself info that friend is NOT logged in.
                  rec2.asText['logout'] := fname;
                  SendData(uname, rec2);
                end;
              finally
  //              info2.Free;
              end;
            end;
          end;
        end;
      finally
        rec.Free;
        rec2.Free;
      end;
    end;
  finally
//    info.Free;
    userCS.Release;
  end;
end;

procedure TVircessUsers.doAccountLogOut(Account, uname: String; Friends: TRtcRecord; sessid: RtcString);
var
  log_out: Boolean;
//  cb: TRtcDelayedCall;
begin
//  cb := nil;
  log_out := False;
  userCS.Acquire;
  try
    if AccountsID.Child[Account] <> nil then
    begin
      if not AccountsID.Child[Account].asRecord['users'].isNull[uname] then
        AccountsID.Child[Account].asRecord['users'].isNull[uname] := True;
      if AccountsID.Child[Account].asRecord['users'].asInteger['UsersCount'] = 0 then
        DeleteAccount(Account);
    end;

    // If logged in under this session ID, remove info
    if AccountsInfo.Child[Account] <> nil then
//      if AccountsInfo.Child[Account]['session'] = sessid then
      begin
  //      cb := GetCallback(uname);
        AccountsInfo.SetNil(Account);
        log_out := True;
      end;
  finally
    userCS.Release;
  end;

  if uname <> '' then
    NotifyAccountsOnHostLogOut(uname, Friends, log_out);

//  if log_out then
//  begin
//    // Triger Callback after Logout, to signal the second connection to check user status.
//    // This will end in "user not logged in" exception and close the connection.
//    if assigned(cb) then
//      cb.WakeUp;
//
//    try
//      with Friends do
//      begin
//        rec := TRtcRecord.Create;
//        try
//        for i := 0 to Count - 1 do // for all Friends in out list ...
//        begin
//          for j := 0 to AccountsID.Child[FieldName[i]].asRecord['users'].Count - 1 do
//          begin
//            if AccountsID.Child[FieldName[i]].asRecord['users'].isNull[AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]] then
//              Continue
//            else
//            begin
//  //            fname := AccountsID.Child[FieldName[i]].Child[IntToStr(j)].FieldName[0];
//              fname := AccountsID.Child[FieldName[i]].asRecord['users'][AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]];
//                if isHostLoggedIn(fname) then // friend logged in
//              begin
//                // Send friend info that we're logging out.
//                rec.asText['logout'] := uname;
//                SendData(fname, rec);
//              end;
//            end;
//          end;
//        end;
//      finally
//        rec.Free;
//      end;
//    end;
//  finally
////    info.Free;
//    end;
//  end;
end;

procedure TVircessUsers.NotifyAccountsOnHostLogOut(uname: String; Friends: TRtcRecord; log_out: Boolean);
var
  rec: TRtcRecord;
  log_in: Boolean;
  cb: TRtcDelayedCall;
  i, j: Integer;
  fname: String;
begin
  if Friends = nil then
    Exit;

  userCS.Acquire;
  try
    if log_out then
    begin
      // Triger Callback after Logout, to signal the second connection to check user status.
      // This will end in "user not logged in" exception and close the connection.
      if assigned(cb) then
        cb.WakeUp;

      try
        with Friends do //Аккаунты, у которых есть в списке этот ИД
        begin
          rec := TRtcRecord.Create;
          try
          for i := 0 to Count - 1 do // for all Friends in out list ...
          begin
            if AccountsID.Child[FieldName[i]] = nil then
              Continue;

            for j := 0 to AccountsID.Child[FieldName[i]].asRecord['users'].Count - 1 do
            begin
              if AccountsID.Child[FieldName[i]].asRecord['users'].isNull[AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]] then
                Continue
              else
              begin
    //            fname := AccountsID.Child[FieldName[i]].Child[IntToStr(j)].FieldName[0];
                fname := AccountsID.Child[FieldName[i]].asRecord['users'][AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]];
                if isHostLoggedIn(fname) then // friend logged in
                begin
                  // Send friend info that we're logging out.
                  rec.asText['logout'] := uname;
                  SendData(fname, rec);
                end;
              end;
            end;
          end;
        finally
          rec.Free;
        end;
      end;
    finally
  //    info.Free;
      end;
    end;
  finally
    userCS.Release;
  end;
end;

//function TVircessUsers.isAccountLoggedIn(account: String; sessid: RtcString): Boolean;
//begin
//  userCS.Acquire;
//  try
//    Result := False;
//    // If logged in under this session ID, return True
//    if AccountsInfo.Child[account] <> nil then
//      if (AccountsInfo.Child[account]['session'] = sessid) or
//         (AccountsInfo.Child[account]['session2'] = sessid) then
//        Result := True;
//  finally
//    userCS.Release;
//  end;
//end;
//
//function TVircessUsers.isAccountLoggedIn(account: String): Boolean;
//begin
//  userCS.Acquire;
//  try
//    Result := AccountsInfo.Child[account] <> nil;
//  finally
//    userCS.Release;
//  end;
//end;

procedure TVircessUsers.NotifyAccountsOnHostLockedUpdate(uname: String; Friends: TRtcRecord; LockedState: Integer; ServiceStarted: Boolean);
var
  rec: TRtcRecord;
  log_in: Boolean;
  cb: TRtcDelayedCall;
  i, j: Integer;
  fname: String;
begin
  try
    userCS.Acquire;
    // Triger Callback after Logout, to signal the second connection to check user status.
    // This will end in "user not logged in" exception and close the connection.
    if assigned(cb) then
      cb.WakeUp;

    with Friends do
    begin
      rec := TRtcRecord.Create;
      try
        for i := 0 to Count - 1 do // for all Friends in out list ...
        begin
          if AccountsID.Child[FieldName[i]] = nil then
            Continue;

          for j := 0 to AccountsID.Child[FieldName[i]].asRecord['users'].Count - 1 do
          begin
            if AccountsID.Child[FieldName[i]].asRecord['users'].isNull[AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]] then
              Continue
            else
            begin
  //            fname := AccountsID.Child[FieldName[i]].Child[IntToStr(j)].FieldName[0];
              fname := AccountsID.Child[FieldName[i]].asRecord['users'][AccountsID.Child[FieldName[i]].asRecord['users'].FieldName[j]];
              userCS.Acquire;
              try
                log_in := HostsInfo.Child[fname] <> nil;
              finally
                userCS.Release;
              end;
              if log_in then // friend logged in
              begin
                // Send friend info that we're locak updated.

                rec.AutoCreate := True;
                with rec.asRecord['locked'] do
                begin
                  asText['user'] := uname;
                  asInteger['LockedState'] := LockedState;
                  asBoolean['ServiceStarted'] := ServiceStarted;
  //              rec.asText['locked'] := uname;
                  SendData(fname, rec);
                end;
              end;
            end;
          end;
        end;
      finally
        rec.Free;
      end;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.SetCallback(uname: String; cb: TRtcDelayedCall);
begin
  userCS.Acquire;
  try
    if HostsInfo.Child[uname] <> nil then
      HostsInfo.Child[uname].asPtr['callback'] := cb;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetCallback(uname: String): TRtcDelayedCall;
begin
  Result := nil;

  userCS.Acquire;
  try
    if HostsInfo.Child[uname] <> nil then
    begin
      Result := TRtcDelayedCall(HostsInfo.Child[uname].asPtr['callback']);
      if Assigned(Result) then
        // We can not call the calback function more than once,
        // so we will clear its assignment here.
        HostsInfo.Child[uname].asPtr['callback'] := nil;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.TriggerCallback(uname: String);
var
  cb:TRtcDelayedCall;
begin
  cb := GetCallback(uname);
  if assigned(cb) then
    cb.WakeUp;
end;

procedure TVircessUsers.AccountLogin(Account, uname, upass: String; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if Account = '' then
      raise Exception.Create('Account name required for Login.')
    else
    if upass = '' then
      raise Exception.Create('Password required for Login.')
    else
    begin
//      if AccountsList.isType[Account] <> rtc_Record then // user doesn't exist
//        //raise Exception.Create('User "'+uname+'" not registered.')
//        AccountRegUser(Account, uname, upass, Friends, sessid)
//      else
//        begin
////        with UserList.asRecord[uname] do
////          if asText['pass'] <> upass then
////            raise Exception.Create('Wrong password for user "' + uname + '".')
////          else
            doAccountLogIn(Account, uname, Friends, sessid);
//        end;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.AccountLogin2(Account, uname, upass: String; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if Account = '' then
      raise Exception.Create('Account name required for Login.')
    else if upass = '' then
      raise Exception.Create('Password required for Login.')
    else
      begin
//      if AccountsList.isType[Account] <> rtc_Record then // user doesn't exist
//        //raise Exception.Create('User "'+uname+'" not registered.')
//        AccountRegUser(Account, uname, upass, Friends, sessid)
//      else
//        begin
//  //        with UserList.asRecord[uname] do
//  //          if asText['pass']<>upass then
//  //            raise Exception.Create('Wrong password for user "'+uname+'".')
//  //          else
          doAccountLogIn2(Account, uname, Friends, sessid);
//        end;
      end;
  finally
    userCS.Release;
  end;
end;

//function TVircessUsers.IsAccountExists(account: String): Boolean;
//begin
//  userCS.Acquire;
//  try
//    Result := False;
//    if account <> '' then
//      if AccountsList.isType[account] = rtc_Record then // user exists
//        Result := True;
//  finally
//    userCS.Release;
//  end;
//end;

//procedure TVircessUsers.AccountRegUser(Account, uname, upass: String; Friends: TRtcRecord; sessid: RtcString);
//begin
//  userCS.Acquire;
//  try
//    if account = '' then
//      raise Exception.Create('Account name required to Register.')
//    else if upass = '' then
//      raise Exception.Create('Password required to Register.')
//    else if not isValidAccountName(account) then
//      raise Exception.Create('"' + account + '" is not a valid account name.')
//    else
//    begin
////    //if UserList.isType[uname] <> rtc_Null then
////    if AccountsList.isType[account] = rtc_Null then
//////      raise Exception.Create('Username "' + uname + '" already taken. Can not register a new user with the same name.')
//////      doAccountLogIn(Account, uname, Friends, sessid)
//////    else // user doesn't exists
//////      begin
////        with AccountsList.NewRecord(account) do
////        begin
//////          asText['pass']:=upass;
//////          SaveUserList;
//          doAccountLogIn(Account, uname, Friends, sessid);
////        end;
//////      end;
//    end;
//  finally
//    userCS.Release;
//  end;
//end;

//procedure TVircessUsers.AccountDelUser(account: String);
//begin
//  userCS.Acquire;
//  try
//    AccountsList.isNull[account] := True; // das entfernt den Record aus UserList
////    SaveUserList; // Das speichert die neue UserList
//  finally
//    userCS.Release;
//  end;
//end;

procedure TVircessUsers.AccountLogout(Account, uname: String; Friends: TRtcRecord; sessid: RtcString);
begin
  doAccountLogOut(Account, uname, Friends, sessid);
//  AccountDelUser(account);
end;

procedure TVircessUsers.SendData(const to_name: String; data: TRtcValueObject);
var
  mydata: TRtcValue;
  s: RtcString;
  fname: String;
begin
  s := data.toCode;
  Crypt(s, MSG_DATA_CRYPT_KEY);

  mydata := TRtcValue.Create;
  try
    mydata.asString := s;
    s := mydata.toCode;
  finally
    mydata.Free;
  end;
  fname := UserDataFileName + 'User.' + to_name + '.msg.data';

  msgCS.Acquire;
  try
    Write_File(fname, s, File_Size(fname));
  finally
    msgCS.Release;
  end;

  TriggerCallback(to_name);
end;

function TVircessUsers.GetData(const uname: String; lastcheck: TDateTime; var thischeck: TDateTime): TRtcArray;
var
  fname: String;
  s, code: RtcString;
  old: Boolean;
  at, i: Integer;
  rec: TRtcValue;
begin
  thischeck := 0;
  Result := nil;

  old := True;

  { On first call, before we start reading newly received data, we will rename the
  original ".data" file to ".old", so that we can read the file without having to
  worry about concurrent file access, in case someone sends us a new message while
  we're getting the "old" data. This function will return he content of the old file
  together with the "old" file age, so we can delete the old file on next call,
  only if file time is less or equal to "lastcheck" time. If last send operation failed,
  we will be able to resend the "old" file, without loosing anything. }

  // Delete Old file if file is older or equal to "lastcheck" time
  fname := UserDataFileName + 'User.' + uname + '.msg.old';
  if not File_Exists(fname) then
  begin
    fname := UserDataFileName + 'User.' + uname + '.msg.data';
    old := False;
  end
  else
  if File_Age(fname) <= lastcheck then
  begin
    Delete_File(fname);
    fname := UserDataFileName + 'User.' + uname + '.msg.data';
    old := False;
  end;

  msgCS.Acquire;
  try
    if not File_Exists(fname) then // nothing to get
      Exit
    else
    begin
      if old then
        // resending old file, update time
        thischeck := File_Age(fname)
      else
      begin
        // sending new file, rename file to ".old" and update time
        Rename_File(fname, UserDataFileName + 'User.' + uname + '.msg.old');
        fname := UserDataFileName + 'User.' + uname + '.msg.old';
        thischeck := File_Age(fname);
      end;
    end;
  finally
    msgCS.Release;
  end;

  // Read file content and create an array of mesages
  s := Read_File(fname);
  at := 0;
  i := 0;

  Result := TRtcArray.Create;
  while at < Length(s) do
  begin
    rec := TRtcValue.FromCode(s, at);
    try
      code := rec.asString;
    finally
      rec.Free;
    end;
    DeCrypt(code, MSG_DATA_CRYPT_KEY);
    Result.asCode[i] := code;
    Inc(i);
  end;
end;

procedure TVircessUsers.AccountAddFriend(uname, friend_name: String);
var
//  info,
  rec: TRtcRecord;
begin
  userCS.Acquire;
  try
//    if not IsHostExists(friend_name) then
//      Exit;
  //    raise Exception.Create('User "' + friend_name + '" not registered.');

    rec := TRtcRecord.Create;
    try
      // Send me info about friend's status.
      if isHostLoggedIn(friend_name) then
        rec.asText['login'] := friend_name
      else
        rec.asText['logout'] := friend_name;
      SendData(uname, rec);
  //    // Send friend info about my status.
  //    rec.asText['login'] := uname;
  //    SendData(friend_name, rec);
    finally
      rec.Free;
    end;

  //  rec := TRtcRecord.Create;
  //  try
  //    rec.asText['addfriend'] := uname;
  //    SendData(friend_name, rec);
  //  finally
  //    rec.Free;
  //    end;
  finally
    userCS.Release;
  end;
end;

//procedure TVircessAccounts.DelFriend(uname, friend_name: String);
//  var
//    info,rec:TRtcRecord;
//  begin
//  if not Exists(friend_name) then
//    raise Exception.Create('User "'+friend_name+'" not registered.');
//
//  info:=LoadInfo(uname);
//  try
//    info.asRecord['friends'].isNull[friend_name]:=True;
//    SaveInfo(uname,info);
//  finally
//    info.Free;
//    end;
//
//  rec:=TRtcRecord.Create;
//  try
//    rec.asText['delfriend']:=uname;
//    SendData(friend_name, rec);
//  finally
//    rec.Free;
//    end;
//  end;

//procedure TVircessAccounts.SendText(const from_name, to_name, text: String);
//var
//  rec:TRtcRecord;
//begin
//  rec := TRtcRecord.Create;
//  try
//    rec.asText['from'] := from_name;
//    rec.asText['text'] := text;
//    SendData(to_name, rec);
//  finally
//    rec.Free;
//  end;
//end;

function TVircessUsers.isValidAccountName(const uname: String): Boolean;
var
  a: Integer;
begin
  Result := True;
  for a := 1 to Length(uname) do
    case uname[a] of
      'a'..'z','A'..'Z','0'..'9','_','.': Result := True;
//    else
//    if Ord(uname[a]) < 128 then
//    begin
//      Result := False;
//      Break;
//    end;
  end;
end;

function TVircessUsers.isAccountLoggedIn(account: String; sessid: RtcString): Boolean;
begin
  userCS.Acquire;
  try
    Result := False;
    // If logged in under this session ID, return True
    if AccountsInfo.Child[account] <> nil then
//      if (AccountsInfo.Child[account]['session'] = sessid) or
//         (AccountsInfo.Child[account]['session2'] = sessid) then
        Result := True;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.isAccountLoggedIn(account: String):boolean;
begin
  userCS.Acquire;
  try
    Result := AccountsInfo.Child[account] <> nil;
  finally
    userCS.Release;
  end;
end;

///////////////////////////////////////////// HOSTS ////////////////////////////////////////////

procedure TVircessUsers.SetLastHostActiveTime(uname: String; Time: TDateTime);
begin
  userCS.Acquire;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
      Exit
      //raise Exception.Create('User ' + uname + ' not logged in.')
    else
//      if HostsInfo.Child[uname].is_Type['LastActive'] = nil then
//        HostsInfo.Child[uname].NewString('LastActive');

      HostsInfo.Child[uname].asDateTime['LastActive'] := Time;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.CheckPassword(uname, pass: String): Boolean;
var
  i: Integer;
begin
  userCS.Acquire;
  try
    Result := False;
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
      Exit //raise Exception.Create('User ' + uname + ' not logged in.')
    else
      if HostsInfo.Child[uname].asRecord['Passwords'] <> nil then
        with HostsInfo.Child[uname].asRecord['Passwords'] do
          for i := 0 to Count - 1 do
            if (is_Type[IntToStr(i)] <> rtc_Null)
              and (asString[IntToStr(i)] = pass)
              and (Trim(pass) <> '') then
            begin
               Result := True;
               Break;
            end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.doHostLogIn2(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
//      raise Exception.Create('User ' + uname + ' not logged in.')
      HostRegUser(uname, gateway, ConsoleId, isService, Friends, sessid)
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

  SetLastHostActiveTime(uname, Now);
end;

procedure TVircessUsers.SetPasswords(uname: String; sessid: RtcString; Param: TRtcFunctionInfo);
var
  i: Integer;
  CurPass: String;
begin
  if Param.isType['Passwords'] = rtc_Null then
    Exit;

  userCS.Acquire;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
      Exit
      //raise Exception.Create('User ' + uname + ' not logged in.')
    else
      if HostsInfo.Child[uname].asRecord['Passwords'] = nil then
        HostsInfo.Child[uname].NewRecord('Passwords');

      for i := 0 to Param.asRecord['Passwords'].Count - 1 do
      begin
        CurPass := Param.asRecord['Passwords'][IntToStr(i)];
        DeCrypt(CurPass, '@VCS@');
        HostsInfo.Child[uname].asRecord['Passwords'].asString[IntToStr(i)] := CurPass;
      end;
      for i := Param.asRecord['Passwords'].Count to HostsInfo.Child[uname].asRecord['Passwords'].Count - 1 do
        HostsInfo.Child[uname].asRecord['Passwords'].is_Null[IntToStr(i)] := True;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.SetServiceActiveConsoleClient(uname, ConsoleId: String);
begin
  if uname = ConsoleId then
    Exit;
  if ConsoleId = '' then
    Exit;

  userCS.Acquire;
  try
    //Óêàçûâàåì õîñòó èä åãî êîíñîëè
    if HostsInfo.Child[uname] = nil then
      Exit
    else
      HostsInfo.Child[uname].asString['ConsoleId'] := ConsoleId;

    //Óêàçûâàåì ñëóæáå åå àêòèâíûé êîíñîëüíûé êëèåíò
    if HostsInfo.Child[ConsoleId] = nil then
      Exit
    else
      HostsInfo.Child[ConsoleId].asString['ActiveConsoleClientId'] := uname;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetUserActiveConsoleClient(uname: String): String;
begin
  Result:= '';

  userCS.Acquire;
  try
    //Ïîëó÷àåì èä êîíñîëè õîñòà
    if HostsInfo.Child[uname] = nil then
      Exit
    else
      Result := HostsInfo.Child[uname].asString['ActiveConsoleClientId'];
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.RemoveActiveConsoleClientFromService(uname: String);
var
  ConsoleId: String;
begin
  if uname = ConsoleId then
    Exit;
  if ConsoleId = '' then
    Exit;

  userCS.Acquire;
  try
    //Ïîëó÷àåì èä êîíñîëè õîñòà
    if HostsInfo.Child[uname] = nil then
      Exit
    else
      ConsoleId := HostsInfo.Child[uname].asString['ConsoleId'];

    if ConsoleId = '' then
      Exit;

    //Óáèðàåì ó ñëóæáû åå àêòèâíîãî êîíñîëüíîãî êëèåíòà åñëè ýòîò ïåðåäàííûé õîñò
    if HostsInfo.Child[ConsoleId] = nil then
      Exit
    else
    if HostsInfo.Child[ConsoleId].asString['ActiveConsoleClientId'] = uname then
      HostsInfo.Child[ConsoleId].asString['ActiveConsoleClientId'] := '';
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.SetHostLockedState(uname: String; Friends: TRtcRecord; sessid: RtcString; Param: TRtcFunctionInfo);
var
  cb: TRtcDelayedCall;
begin
  if (uname = '')
    or (uname = '-') then
    Exit;

  userCS.Acquire;
  try
    // Remember new session ID
    if HostsInfo.Child[uname] = nil then
      Exit
      //raise Exception.Create('User ' + uname + ' not logged in.')
    else
    begin
     if HostsInfo.Child[uname].isType['LockedState'] = rtc_Null then
        HostsInfo.Child[uname].NewInteger('LockedState');

      HostsInfo.Child[uname].asInteger['LockedState'] := Param.asInteger['LockedState'];

     if HostsInfo.Child[uname].isType['ServiceStarted'] = rtc_Null then
        HostsInfo.Child[uname].NewBoolean('ServiceStarted');

      HostsInfo.Child[uname].asBoolean['ServiceStarted'] := Param.asBoolean['ServiceStarted'];
    end;

    // Get callback info, if exists
    cb := GetCallback(uname);
  finally
    userCS.Release;
  end;

  // Trigger calback, if it was set (second connectin was open and is now waiting).
  // This will signal the waiting connection to execute,
  // which will end in an exception "not logged in" and close the connection.
  if assigned(cb) then
    cb.WakeUp;

  NotifyAccountsOnHostLockedUpdate(uname, Friends, Param['LockedState'], Param['ServiceStarted']);
end;

procedure TVircessUsers.doHostLogIn(uname, gateway, ConsoleId: string; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
var
  cb: TRtcDelayedCall;
begin
  userCS.Acquire;
  try
    // Remove existing info.
    if HostsInfo.Child[uname] <> nil then
      DelUserFromGateway(uname, gateway);
//    else
//      FHostsCount := FHostsCount + 1;

    // Get callback info, if exists
    cb := GetCallback(uname);
    // Remove existing info
    HostsInfo.SetNil(uname);
    // Remember new session ID
    with HostsInfo.NewChild(uname) do
    begin
      asBoolean['isService'] := isService;
      asString['Session'] := sessid;
      asString['Gateway'] := RtcString(gateway);
    end;
    AddUserToGateway(uname, RtcString(gateway));

    SetLastHostActiveTime(uname, Now);

    NotifyAccountsOnHostLogIn(uname, Friends);

    if Assigned(FOnUserLogIn) then
      FOnUserLogIn(uname);
  finally
    userCS.Release;
  end;

  // Trigger calback, if it was set (second connectin was open and is now waiting).
  // This will signal the waiting connection to execute,
  // which will end in an exception "not logged in" and close the connection.
  if assigned(cb) then
    cb.WakeUp;
end;

procedure TVircessUsers.doHostLogOut(uname, gateway, ConsoleId: String; Friends: TRtcRecord; sessid: RtcString; DisconnectAll: Boolean = False);
var
  log_out: Boolean;
  cb: TRtcDelayedCall;
begin
  xLog('rtcAccounts doHostLogOut Start ' + uname);
  cb := nil;
  log_out := False;

  userCS.Acquire;
  try
  // If logged in under this session ID, remove info
  if HostsInfo.Child[uname] <> nil then
//    if (HostsInfo.Child[uname]['session'] = sessid)
//      or DisconnectAll then
    begin
//      Gateway1.StartForceUserLogoutThread(uname, True);
//      Gateway2.StartForceUserLogoutThread(uname, True);
//      Gateway3.StartForceUserLogoutThread(uname, True);
//      Gateway4.StartForceUserLogoutThread(uname, True);

      if DisconnectAll then
      begin
        TSendDestroyClientToGatewayThread.Create(False, HostsInfo.Child[uname]['gateway'], uname, True, False, '', '', '');
        DelUserFromGateway(uname, HostsInfo.Child[uname]['gateway']) //Param gateway = ''
      end
      else
      begin
        TSendDestroyClientToGatewayThread.Create(False, gateway, uname + '_', False, False, '', '', '');
        DelUserFromGateway(uname, gateway);
      end;

      DelUserFromAccountsID(uname);
      RemoveActiveConsoleClientFromService(uname);

      FHostsCount := FHostsCount - 1;

      if (HostsInfo.Child[uname]['session'] = sessid)
        or DisconnectAll then
      begin
        cb := GetCallback(uname);
//        HostsInfo.SetNil(uname);
        log_out := True;
      end;

      HostDelUser(uname);

      NotifyAccountsOnHostLogOut(uname, Friends, log_out);

      if Assigned(FOnUserLogOut) then
        FOnUserLogOut(uname);
    end;
  finally
    userCS.Release;
  end;
  xLog('rtcAccounts doHostLogOut End ' + uname);
end;

function TVircessUsers.isHostLoggedIn(uname: String; sessid: RtcString): Boolean;
begin
  userCS.Acquire;
  try
    Result := False;
    // If logged in under this session ID, return True
{    if HostsInfo.Child[uname] <> nil then
//      if (HostsInfo.Child[uname]['session'] = sessid) or
//         (HostsInfo.Child[uname]['session2'] = sessid) then
        Result := True;}
    Result := HostsList.is_Type[uname] <> rtc_Null;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.isHostLoggedIn(uname: String):boolean;
begin
  userCS.Acquire;
  try
//    Result := HostsInfo.Child[uname] <> nil;
    Result := HostsList.is_Type[uname] <> rtc_Null;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.HostLogin(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if uname = '' then
      raise Exception.Create('Username required for Login.')
    else
    begin
      if HostsList.isType[uname] <> rtc_Record then // user doesn't exist
        //raise Exception.Create('User "'+uname+'" not registered.')
        HostRegUser(uname, gateway, ConsoleId, isService, Friends, sessid)
      else
  //    begin
//        with HostsList.asRecord[uname] do
  //        if asText['pass']<>upass then
  //          raise Exception.Create('Wrong password for user "'+uname+'".')
  //        else
            doHostLogIn(uname, gateway, ConsoleId, isService, Friends, sessid);
  //    end;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.HostLogin2(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if uname='' then
      raise Exception.Create('Username required for Login.')
    else
      begin
      if HostsList.isType[uname] <> rtc_Record then // user doesn't exist
        //raise Exception.Create('User "'+uname+'" not registered.')
        HostRegUser(uname, gateway, ConsoleId, isService, Friends, sessid)
      else
      begin
//        with UserList.asRecord[uname] do
//          if asText['pass']<>upass then
//            raise Exception.Create('Wrong password for user "'+uname+'".')
//          else
        doHostLogIn2(uname, gateway, ConsoleId, isService, Friends, sessid);
      end;
    end;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.IsHostExists(uname: String): Boolean;
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

function TVircessUsers.HostIsService(uname: String): Boolean;
begin
  userCS.Acquire;
  try
    Result := False;

    if uname <> '' then
      if HostsInfo.Child[uname] <> nil then // user exists
        Result := HostsInfo.Child[uname].asBoolean['IsService'];
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.HostRegUser(uname, gateway, ConsoleId: String; isService: Boolean; Friends: TRtcRecord; sessid: RtcString);
begin
  userCS.Acquire;
  try
    if uname = '' then
      raise Exception.Create('Username required to Register.')
    else
    begin
      if HostsInfo.Child[uname] = nil then
      begin
        if HostsList.isType[uname] = rtc_Null then
          HostsList.NewRecord(uname);
        if HostsInfo.Child[uname] = nil then
          HostsInfo.NewChild(uname);

        FHostsCount := FHostsCount + 1;
      end;
//      if not HostsList.isNull[uname] then
//        doHostLogIn(uname, gateway, Friends, sessid)
//        raise Exception.Create('Username "' + uname + '" already taken. Can not register a new user with the same name.')
//      else // user doesn't exists
//      begin
//        with HostsList.NewRecord(uname) do
        //begin
          doHostLogIn(uname, gateway, ConsoleId, isService, Friends, sessid);
        //end;
      end;
//    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.HostDelUser(uname: String);
begin
  userCS.Acquire;
  try
    HostsList.isNull[uname] := True; // das entfernt den Record aus UserList
    HostsInfo.SetNil(uname);
  //    SaveUserList; // Das speichert die neue UserList
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.DeleteAccount(account: String);
begin
  accountsCS.Acquire;
  try
    AccountsID.isNull[account] := True; // das entfernt den Record aus AccountsID
    AccountsID.SetNil(account);
  //    SaveUserList; // Das speichert die neue UserList

    AccountsInfo.isNull[account] := True; // das entfernt den Record aus AccountsID
    AccountsInfo.SetNil(account);

    FAccountsCount := FAccountsCount - 1;
  finally
    accountsCS.Release;
  end;
end;

procedure TVircessUsers.HostLogout(uname, gateway, ConsoleId: String; Friends: TRtcRecord; sessid: RtcString);
begin
  doHostLogOut(uname, gateway, ConsoleId, Friends, sessid);
end;

procedure TVircessUsers.CheckDisconnectedHosts;
var
  i: Integer;
begin
  userCS.Acquire;
  try  ;
    i := HostsList.Count - 1;
    while (i >= 0) do
    begin
      if HostsList.FieldName[i] = '' then
      begin
        i := i - 1;
        Continue;
      end;

      if HostsInfo.Child[HostsList.FieldName[i]] <> nil then
        if (IncSecond(HostsInfo.Child[HostsList.FieldName[i]].asDateTime['LastActive'], FPingTimeout) < Now) then
            begin
              xLog('HostLogOutExecute by CheckDisconnectedHosts ' + HostsList.FieldName[i]);
              doHostLogOut(HostsList.FieldName[i], '', '', GetFriendList_Func(HostsList.FieldName[i]), '', True);
            end;

        i := i - 1;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.DisconnectServiceClients(ServiceUserName: String);
var
  i: Integer;
begin
  userCS.Acquire;
  try
    i := HostsList.Count - 1;
    while (i >= 0) do
    begin
      if HostsList.FieldName[i] = '' then
      begin
        i := i - 1;
        Continue;
      end;

      if HostsInfo.Child[HostsList.FieldName[i]] <> nil then
        if HostsInfo.Child[HostsList.FieldName[i]].asString['ConsoleId'] = ServiceUserName then
            begin
              xLog('HostLogOutExecute by DisconnectServiceClients ' + HostsList.FieldName[i]);
              doHostLogOut(HostsList.FieldName[i], '', '', GetFriendList_Func(HostsList.FieldName[i]), '', True);
            end;

        i := i - 1;
    end;
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.CheckDisconnectedGateways;
var
  i: Integer;
begin
  gatewayCS.Acquire;
  try
    i := GatewaysList.Count - 1;
    while (i >= 0) do
    begin
      if GatewaysList.FieldName[i] = '' then
      begin
        i := i - 1;
        Continue;
      end;

      if GatewaysInfo.Child[GatewaysList.FieldName[i]] <> nil then
        if (IncSecond(GatewaysInfo.Child[GatewaysList.FieldName[i]].asDateTime['LastActive'], FPingTimeout) < Now) then
            begin
              xLog('GatewayLogOutExecute by CheckDisconnectedGateways ' + GatewaysList.FieldName[i]);
              GatewayLogOut(GatewaysList.FieldName[i]);
            end;

        i := i - 1;
    end;
  finally
    gatewayCS.Release;
  end;
end;

procedure TVircessUsers.DelUserFromAccountsID(uname: String);
var
  i: Integer;
begin
  userCS.Acquire;
  try
    for i := 0 to AccountsList.Count - 1 do
    begin
      if AccountsID.Child[AccountsList.FieldName[i]] = nil then
        Continue;

      if AccountsID.Child[AccountsList.FieldName[i]].isType['users'] = rtc_Null then
        Continue;

      if AccountsID.Child[AccountsList.FieldName[i]].asRecord['users'].isType[uname] <> rtc_Null then
      begin
        AccountsID.Child[AccountsList.FieldName[i]].asRecord['users'].isNull[uname] := True;
        AccountsID.Child[AccountsList.FieldName[i]].asRecord['users'].asInteger['UsersCount'] := AccountsID.Child[AccountsList.FieldName[i]].asRecord['users'].asInteger['UsersCount'] - 1;

        if AccountsID.Child[AccountsList.FieldName[i]].asRecord['users'].asInteger['UsersCount'] = 0 then
          doAccountLogOut(AccountsList.FieldName[i],  uname, nil, '');
      end;
    end;
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetUserGateway(uname: String): String;
var
  i: Integer;
begin
  userCS.Acquire;
  try
    if HostsInfo.Child[uname] = nil then
      Result := ''
    else
      Result := HostsInfo.Child[uname]['Gateway'];
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetHostLockedState(uname: String): Integer;
begin
  userCS.Acquire;
  try
    if HostsInfo.Child[uname] = nil then
      Result := LCK_STATE_UNLOCKED
    else
      Result := HostsInfo.Child[uname].asInteger['LockedState'];
  finally
    userCS.Release;
  end;
end;

function TVircessUsers.GetHostServiceStarted(uname: String): Boolean;
begin
  userCS.Acquire;
  try
    if HostsInfo.Child[uname] = nil then
      Result := False
    else
      Result := HostsInfo.Child[uname].asBoolean['ServiceStarted'];
  finally
    userCS.Release;
  end;
end;

procedure TVircessUsers.EraseGatewayList;
var
  i: Integer;
begin
  gatewayCS.Acquire;
  try
    for i := 0 to GatewaysList.Count - 1 do
    begin
      if GatewaysInfo.Child[GatewaysList.FieldName[i]] <> nil then
      begin
        GatewaysList.isNull[GatewaysList.FieldName[i]] := True;
        GatewaysInfo.Child[GatewaysList.FieldName[i]].SetNil('users');
        GatewaysInfo.SetNil(GatewaysList.FieldName[i]);
      end;
    end;
    GatewaysList.Clear;
    GatewaysInfo.Clear;
  finally
    gatewayCS.Release;
  end;
end;

function TVircessUsers.GetAvailableGateway: String;
var
  i, j, UserCount: Integer;
  MaxFreeUsers: Integer;
begin
  gatewayCS.Acquire;

  Result := '';
  try
    if GatewaysList.Count = 0 then
      Exit;

    MaxFreeUsers := -1;
    for i := 0 to GatewaysList.Count - 1 do
    begin
      UserCount := 0;

      if GatewaysInfo.Child[GatewaysList.FieldName[i]] = nil then
        Continue;

      for j := 0 to GatewaysInfo.Child[GatewaysList.FieldName[i]].asRecord['users'].Count - 1 do
        if GatewaysInfo.Child[GatewaysList.FieldName[i]].asRecord['users'].is_Type[GatewaysInfo.Child[GatewaysList.FieldName[i]].asRecord['users'].FieldName[j]] <> rtc_Null then
          UserCount := UserCount + 1;

      if (((GatewaysInfo.Child[GatewaysList.FieldName[i]].asInteger['maxUsers'] - UserCount) > MaxFreeUsers) or (Result = '')) then
      begin
        Result := GatewaysList.FieldName[i];
        MaxFreeUsers := GatewaysInfo.Child[GatewaysList.FieldName[i]].asInteger['maxUsers'] - UserCount;
      end;
    end;
  finally
    gatewayCS.Release;
  end;
end;

procedure TVircessUsers.AddUserToGateway(uname, gateway: String);
var
  i: Integer;
begin
  gatewayCS.Acquire;
  try
    for i := 0 to GatewaysList.Count - 1 do
      if GatewaysList.isType[GatewaysList.FieldName[i]] = rtc_Null then
        Continue;

      if GatewaysList.FieldName[i] = gateway then
        GatewaysList[GatewaysList.FieldName[i]].asRecord['users'].asString[uname] := uname;
  finally
    gatewayCS.Release;
  end;
end;

procedure TVircessUsers.DelUserFromGateway(uname, gateway: String);
var
  i: Integer;
begin
  gatewayCS.Acquire;
  try
    for i := 0 to GatewaysList.Count - 1 do
      if GatewaysList.isType[GatewaysList.FieldName[i]] = rtc_Null then
        Continue;

      if GatewaysList.FieldName[i] = gateway then
        GatewaysList[GatewaysList.FieldName[i]].asRecord['users'].is_Null[uname] := True;
  finally
    gatewayCS.Release;
  end;
end;

procedure TVircessUsers.GatewayReLogin(address: String; MaxUsers: Integer);
var
  cb: TRtcDelayedCall;
begin
  gatewayCS.Acquire;
  try
    if GatewaysInfo.Child[address] = nil then
    begin
//      if GatewaysList.isType[address] = rtc_Null then
        GatewaysList.NewRecord(address);
        GatewaysInfo.NewChild(address);

      GatewaysInfo.Child[address].asInteger['maxUsers'] := MaxUsers;
      GatewaysInfo.Child[address].NewRecord('users').AutoCreate := True;

      FGatewaysCount := FGatewaysCount + 1;
    end;

    GatewaysInfo.Child[address].asDateTime['LastActive'] := Now;

//    NotifyAccountsOnHostLogIn(uname, Friends);

//    if Assigned(FOnUserLogIn) then
//      FOnUserLogIn(uname);
  finally
    gatewayCS.Release;
  end;
end;

procedure TVircessUsers.GatewayLogOut(address: String);
var
  cb: TRtcDelayedCall;
begin
  gatewayCS.Acquire;
  try
    if GatewaysInfo.Child[address] <> nil then
    begin
      if GatewaysList.isType[address] <> rtc_Null then
        GatewaysList.isNull[address] := True;

      GatewaysInfo.Child[address].SetNil('users');
      GatewaysInfo.SetNil(address);
      FGatewaysCount := FGatewaysCount - 1;
    end;



//    GatewaysInfo.Child[address].asDateTime['LastActive'] := Now;

//    NotifyAccountsOnHostLogIn(uname, Friends);

//    if Assigned(FOnUserLogIn) then
//      FOnUserLogIn(uname);
  finally
    gatewayCS.Release;
  end;
end;

function TVircessUsers.isGatewayLoggedIn(address: String): Boolean;
begin
  gatewayCS.Acquire;
  try
    Result := GatewaysInfo.Child[address] <> nil;
  finally
    gatewayCS.Release;
  end;
end;


end.
