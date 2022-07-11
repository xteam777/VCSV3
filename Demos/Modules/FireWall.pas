unit FireWall;

interface

uses NetFwTypeLib_TLB, System.Classes, ActiveX, ComObj, System.SysUtils;

type
  TFireWallIPVersion  = (
                          Version4          = $00000000,
                          Version6          = $00000001,
                          VersionAny        = $00000002,
                          VersionMax        = $00000003
                        );
  TFireWallScope      = (
                          ScopeAll          = $00000000,
                          ScopeLocalSubnet  = $00000001,
                          ScopeCustom       = $00000002,
                          ScopeMax          = $00000003
                        );
  TFireWallProtocol   = (
                          ProtocolTCP = $00000006,
                          ProtocolUDP = $00000011
                        );

  TAuhtorizedApp = class
  private
    fName,
    fRemoteAddress,
    fProcessImageFileName : String;
    fEnabled              : Boolean;
    fIpVersion            : TFireWallIPVersion;
    fScope                : TFireWallScope;
  public
    constructor Create(
                        const AName,
                              ARemoteAddresses,
                              AProcessImageFileName : String;
                        const AEnabled : Boolean;
                        const AScope : TFireWallScope;
                        const AIpVersion : TFireWallIPVersion
                       );

    property Name                 : String              read fName;
    property RemoteAddresses      : String              read fRemoteAddress;
    property ProcessImageFileName : String              read fProcessImageFileName;
    property Enabled              : Boolean             read fEnabled;
    property Scope                : TFireWallScope      read fScope;
    property IpVersion            : TFireWallIPVersion  read fIpVersion;
  end;

  TOpenPort = class
  private
    fName,
    fRemoteAddress        : String;
    fEnabled,
    fBuiltIn              : Boolean;
    fIpVersion            : TFireWallIPVersion;
    fScope                : TFireWallScope;
    fProtocol             : TFireWallProtocol;
    fPort                 : Integer;
  public
    constructor Create(
                        const AName,
                              ARemoteAddresses : String;
                        const AEnabled : Boolean;
                        const AScope : TFireWallScope;
                        const AIpVersion : TFireWallIPVersion;
                        const AProtocol : TFireWallProtocol;
                        const APort : Integer
                       );

    property Name                 : String              read fName;
    property RemoteAddresses      : String              read fRemoteAddress;
    property Enabled              : Boolean             read fEnabled;
    property Scope                : TFireWallScope      read fScope;
    property IpVersion            : TFireWallIPVersion  read fIpVersion;

    property Protocol             : TFireWallProtocol   read fProtocol;
    property Port                 : Integer             read fPort;
  end;

  TFireWall = class
  private
    fFireWall                : INetFwMgr;
    fLocalPolicy             : INetFwPolicy;
    fProfile                 : INetFwProfile;
    fRemoteAdminSettings     : INetFwRemoteAdminSettings;
    fIcmpSettings            : INetFwIcmpSettings;
    fGloballyOpenPorts       : INetFwOpenPorts;
    fServices                : INetFwServices;
    fAuthorizedApplications  : INetFwAuthorizedApplications;

    function GetFireWallEnabled : Boolean;
    procedure SetFireWallEnabled(const Value : Boolean);

    function GetAllowExceptions : Boolean;
    procedure SetAllowExceptions(const Value : Boolean);

    function GetAllowNotifications : Boolean;
    procedure SetAllowNotifications(const Value : Boolean);

    function GetAuthorizedApplications : TStrings;
    function GetOpenPorts : TStrings;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Restore;
    function ApplicationExists(const APath : String) : Boolean;
    function PortExists(const APort : Integer; const AProtocol : TFireWallProtocol) : Boolean;

    procedure AddApplication(const AName, APath : String);
    procedure RemoveApplication(const APath : String);

    procedure AddPort(const AName : String; const APort : Integer; const APortProtocol : TFireWallProtocol);
    procedure RemovePort(const APort : Integer; const APortProtocol : TFireWallProtocol);

    procedure AddRule(const Caption, Executable: String; Direction: Integer);
    procedure RemoveRule(const Caption: String);

    property Enabled                : Boolean   read GetFireWallEnabled     write SetFireWallEnabled;
    property AllowExceptions        : Boolean   read GetAllowExceptions     write SetAllowExceptions;
    property AllowNotifications     : Boolean   read GetAllowNotifications  write SetAllowNotifications;

    property AuthorizedApplications : TStrings  read GetAuthorizedApplications;
    property OpenPorts              : TStrings  read GetOpenPorts;
  end;

implementation

{ TFireWall }

constructor TFireWall.Create;
begin
  inherited;

  CoInitialize(nil);

  fFireWall := CreateOLEObject('HNetCfg.FwMgr') as INetFwMgr;
  if fFireWall <> nil then
  begin
    fLocalPolicy             := fFireWall.LocalPolicy;
    fProfile                 := fFireWall.LocalPolicy.CurrentProfile;
    fRemoteAdminSettings     := fFireWall.LocalPolicy.CurrentProfile.RemoteAdminSettings;
    fIcmpSettings            := fFireWall.LocalPolicy.CurrentProfile.IcmpSettings;
    fGloballyOpenPorts       := fFireWall.LocalPolicy.CurrentProfile.GloballyOpenPorts;
    fServices                := fFireWall.LocalPolicy.CurrentProfile.Services;
    fAuthorizedApplications  := fFireWall.LocalPolicy.CurrentProfile.AuthorizedApplications;
  end else raise Exception.Create('Брандмауэр недоступен!');
end;

destructor TFireWall.Destroy;
begin
  fFireWall                := nil;
  fLocalPolicy             := nil;
  fProfile                 := nil;
  fRemoteAdminSettings     := nil;
  fIcmpSettings            := nil;
  fGloballyOpenPorts       := nil;
  fServices                := nil;
  fAuthorizedApplications  := nil;

  CoUninitialize;

  inherited;
end;


procedure TFireWall.AddApplication(const AName, APath: String);
var
  app : INetFwAuthorizedApplication;
begin
  if Trim(AName) = '' then
    raise Exception.Create('Пожалуйста, укажите имя.!');

  if not FileExists(APath) then
    raise Exception.Create('Указанный файл не найден.!');

  if not AllowExceptions then
    raise Exception.Create('Возможность добавление приложений отключена.!');

  app := CreateOleObject('HNetCfg.FwAuthorizedApplication') as INetFwAuthorizedApplication;
  try
    app.Name := AName;
    app.ProcessImageFileName := APath;
    app.IpVersion := TOleEnum(VersionAny);
    app.RemoteAddresses := '*';
    app.Scope := TOleEnum(ScopeAll);
    app.Enabled := true;

    fAuthorizedApplications.Add(app);
  finally
    app := nil;
  end;
end;

procedure TFireWall.AddPort(const AName: String; const APort: Integer;
  const APortProtocol: TFireWallProtocol);
var
  port : INetFwOpenPort;
begin
  if Trim(AName) = '' then
    raise Exception.Create('Пожалуйста, укажите имя.!');

  port := CreateOleObject('HNetCfg.FwOpenPort') as INetFwOpenPort;
  try
    port.Name := AName;
    port.IpVersion := TOleEnum(VersionAny);
    port.Protocol := TOleEnum(APortProtocol);
    port.Scope := TOleEnum(ScopeAll);
    port.Port := APort;
    port.RemoteAddresses := '*';
    port.Enabled := true;

    fGloballyOpenPorts.Add(port);
  finally
    port := nil;
  end;
end;

function TFireWall.ApplicationExists(const APath : String): Boolean;
var
  sList     : TStrings;
  iCounter  : Integer;
begin
  Result := false;

  sList := AuthorizedApplications;

  if sList <> nil then
    for iCounter := 0 to sList.Count - 1 do
      if sList.Objects[iCounter] <> nil then
        if sList.Objects[iCounter] is TAuhtorizedApp then
          if TAuhtorizedApp(sList.Objects[iCounter]).ProcessImageFileName = APath then
          begin
            Result := true;
            Break;
          end;
end;

procedure TFireWall.AddRule(const Caption, Executable: String; Direction: Integer);
const
  NET_FW_PROFILE2_DOMAIN  = 1;
  NET_FW_PROFILE2_PRIVATE = 2;
  NET_FW_PROFILE2_PUBLIC  = 4;

  NET_FW_IP_PROTOCOL_TCP = 6;
  NET_FW_ACTION_ALLOW    = 1;
var
  fwPolicy2      : OleVariant;
  RulesObject    : OleVariant;
  NewRule        : OleVariant;
begin
  fwPolicy2 := CreateOleObject('HNetCfg.FwPolicy2');
  RulesObject := fwPolicy2.Rules;
  NewRule := CreateOleObject('HNetCfg.FWRule') as INetFWRule;
  NewRule.Name := Caption;
  NewRule.Description := Caption;
  NewRule.Direction := Direction;
  NewRule.Applicationname := Executable;
  NewRule.Protocol := NET_FW_IP_PROTOCOL_ANY;
  NewRule.Grouping := Caption;
  NewRule.Enabled := True;
  NewRule.Profiles := NET_FW_PROFILE2_PRIVATE or NET_FW_PROFILE2_PUBLIC or NET_FW_PROFILE2_DOMAIN;
  NewRule.Action := NET_FW_ACTION_ALLOW;
  RulesObject.Add(NewRule);
end;

procedure TFireWall.RemoveRule(const Caption: String);
const
  NET_FW_PROFILE2_PRIVATE = 2;
  NET_FW_PROFILE2_PUBLIC  = 4;
var
  Profile: Integer;
  Policy2: OleVariant;
  RObject: OleVariant;
begin
  Profile := NET_FW_PROFILE2_PRIVATE or NET_FW_PROFILE2_PUBLIC;
  Policy2 := CreateOleObject('HNetCfg.FwPolicy2');
  RObject := Policy2.Rules;
  RObject.Remove(Caption);
end;

function TFireWall.GetAllowExceptions: Boolean;
begin
  Result := false;

  if fProfile <> nil then
    Result := not fProfile.ExceptionsNotAllowed;
end;

function TFireWall.GetAllowNotifications: Boolean;
begin
  Result := false;

  if fProfile <> nil then
    Result := fProfile.NotificationsDisabled;
end;

function TFireWall.GetAuthorizedApplications: TStrings;
var
  apps      : IEnumVariant;
  app       : OleVariant;
  dummy     : Cardinal;
  iCounter  : Integer;
begin
  Result := TStringList.Create;

  apps := fAuthorizedApplications._NewEnum as IEnumVariant;
  while (apps.Next(1, app, dummy) = S_OK) do
  begin
    Result.AddObject(
             app.Name,
             TAuhtorizedApp.Create(
                                   app.Name,
                                   app.RemoteAddresses,
                                   app.ProcessImageFileName,
                                   app.Enabled,
                                   TFireWallScope(app.Scope),
                                   TFireWallIPVersion(app.IpVersion)
                                           )
                    );
  end;

  apps := nil;
end;

function TFireWall.GetFireWallEnabled: Boolean;
begin
  Result := false;

  if fProfile <> nil then
    Result := fProfile.FirewallEnabled;
end;

function TFireWall.GetOpenPorts: TStrings;
var
  ports     : IEnumVariant;
  port      : OleVariant;
  dummy     : Cardinal;
  iCounter  : Integer;
begin
  Result := TStringList.Create;

  ports := fProfile.GloballyOpenPorts._NewEnum as IEnumVariant;
  while (ports.Next(1, port, dummy) = S_OK) do
  begin
    Result.AddObject(
             port.Name,
             TOpenPort.Create(
                                port.Name,
                                port.RemoteAddresses,
                                port.Enabled,
                                TFireWallScope(port.Scope),
                                TFireWallIpVersion(port.IpVersion),
                                TFireWallProtocol(port.Protocol),
                                Integer(port.Port)
                                       )
                    );
  end;

  ports := nil;
end;

function TFireWall.PortExists(const APort: Integer; const AProtocol : TFireWallProtocol): Boolean;
var
  sList     : TStrings;
  iCounter  : Integer;
begin
  Result := false;

  sList := OpenPorts;

  if sList <> nil then
    for iCounter := 0 to sList.Count - 1 do
      if sList.Objects[iCounter] <> nil then
        if sList.Objects[iCounter] is TOpenPort then
          if (TOpenPort(sList.Objects[iCounter]).Port = APort) and
             (TOpenPort(sList.Objects[iCounter]).Protocol = AProtocol) then
             begin
              Result := true;
              Exit;
             end;
end;

procedure TFireWall.RemoveApplication(const APath : String);
begin
  if not FileExists(APath) then
    raise Exception.Create('Указанный файл не найден.!');

  if fAuthorizedApplications <> nil then
    fAuthorizedApplications.Remove(APath);
end;

procedure TFireWall.RemovePort(const APort: Integer;
  const APortProtocol: TFireWallProtocol);
begin
  if fGloballyOpenPorts <> nil then
    fGloballyOpenPorts.Remove(APort, TOleEnum(APortProtocol));
end;

procedure TFireWall.Restore;
begin
  if fFireWall <> nil then
    fFireWall.RestoreDefaults;
end;

procedure TFireWall.SetAllowExceptions(const Value: Boolean);
begin
  if fProfile <> nil then
    fProfile.ExceptionsNotAllowed := Value;
end;

procedure TFireWall.SetAllowNotifications(const Value: Boolean);
begin
  if fProfile <> nil then
    fProfile.NotificationsDisabled := Value;
end;

procedure TFireWall.SetFireWallEnabled(const Value: Boolean);
begin
  if fProfile <> nil then
    fProfile.FirewallEnabled := Value;
end;

{ TAuhtorizedApp }

constructor TAuhtorizedApp.Create(const AName, ARemoteAddresses,
  AProcessImageFileName: String; const AEnabled: Boolean;
  const AScope: TFireWallScope; const AIpVersion: TFireWallIPVersion);
begin
  inherited Create;

  fName := AName;
  fRemoteAddress := ARemoteAddresses;
  fProcessImageFileName := AProcessImageFileName;
  fEnabled := AEnabled;
  fScope := AScope;
  fIpVersion := AIpVersion;
end;

{ TOpenPort }

constructor TOpenPort.Create(const AName, ARemoteAddresses: String;
  const AEnabled : Boolean; const AScope: TFireWallScope;
  const AIpVersion: TFireWallIPVersion; const AProtocol: TFireWallProtocol;
  const APort: Integer);
begin
  inherited Create;

  fName := AName;
  fRemoteAddress := ARemoteAddresses;
  fEnabled := AEnabled;
  fScope := AScope;
  fIpVersion := AIpVersion;
  fProtocol := AProtocol;
  fPort := APort;
end;


end.
