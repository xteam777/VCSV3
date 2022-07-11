unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, ComObj, ActiveX,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls, ShlObj, rtcWinlogon, uVircessTypes,
  Vcl.StdCtrls, Vcl.Buttons, ShellApi, rtcSystem, CommonUtils, rtcInfo, rtcCrypt, DateUtils, ServiceMgr, Registry;

type
  TfMain = class(TForm)
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    iBkgTop: TImage;
    lLink: TLabel;
    pDelete: TPanel;
    Label5: TLabel;
    procedure lLinkClick(Sender: TObject);
    procedure lLinkMouseEnter(Sender: TObject);
    procedure lLinkMouseLeave(Sender: TObject);
    procedure rbSetupClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
  private
    { Private declarations }
    procedure SaveSetup;
    procedure AddToRegistry;
    function GetSpecialPath(CSIDL: Integer): String;
    function CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: String): IPersistFile;
    procedure CreateShortcuts(DestinationPath: String);
    procedure DeleteShortcuts(DestinationPath: String);
  public
    { Public declarations }
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

function TfMain.GetSpecialPath(CSIDL: Integer): String;
var
  Buffer: Array[0..MAX_PATH] of Char;
begin
  if ShGetSpecialFolderPath(Application.Handle, Buffer, CSIDL, False) then
    Result := Buffer
  else
    Result := '';
end;

function TfMain.CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: String): IPersistFile;
var
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  WideFile: WideString;
begin
  MyObject := CreateComObject(CLSID_ShellLink);
  MySLink := MyObject as IShellLink;
  MyPFile := MyObject as IPersistFile;
  with MySLink do
  begin
    SetPath(PChar(CmdLine));
    SetArguments(PChar(Args));
    SetWorkingDirectory(PChar(WorkDir));
  end;
  WideFile := LinkFile;
  MyPFile.Save(PWChar(WideFile), False);
  Result := MyPFile;
end;

procedure TfMain.CreateShortcuts(DestinationPath: String);
var
  DestPath, FPPath: String;
begin
  DestPath := Format('%s\%s.lnk', [DestinationPath, 'Vircess']);
  FPPath := GetSpecialPath(CSIDL_PROGRAM_FILES);

  if not FileExists(DestPath) then
    CreateShortcut(FPPath + '\Vircess\Vircess.exe', '', FPPath, DestPath);
end;

procedure TfMain.DeleteShortcuts(DestinationPath: String);
var
  FPath: String;
begin
  FPath := Format('%s\%s.lnk', [DestinationPath, 'Vircess']);

  if FileExists(FPath) then
    DeleteFile(FPath);
end;

procedure TfMain.AddToRegistry;
var
  reg: TRegistry;
  path: String;
begin
  path := GetSpecialPath(CSIDL_PROGRAM_FILES) + '\Vircess\Vircess.exe';

  reg := TRegistry.Create(KEY_READ or KEY_WRITE or KEY_CREATE_SUB_KEY or KEY_WOW64_64KEY);
  reg.RootKey := HKEY_LOCAL_MACHINE;
  reg.CreateKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Vircess');
  reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Vircess', False);
  reg.WriteString('DisplayIcon', path);
  reg.WriteString('DisplayName', 'Vircess');
  reg.WriteString('Publisher', 'Vircess');
  reg.WriteString('UninstallString', path + ' /DELETE');
  reg.WriteString('URLInfoAbout', 'vircess.com');
  reg.CloseKey;
end;

procedure TfMain.SaveSetup;
var
  CfgFileName: String;
  infos: RtcString;
  s2: RtcByteArray;
  info: TRtcRecord;
  len2: LongInt;
begin
  info := TRtcRecord.Create;
  try
    info.asString['Address'] := '95.216.96.39';
    info.asBoolean['WinHTTP'] := True;

    info.asWideString['RegularPassword'] := ePassword.Text;
    info.asBoolean['StoreHistory'] := True;
    info.asBoolean['StorePasswords'] := True;
    info.asBoolean['OnlyAdminChanges'] := True;

    info.asBoolean['DevicesPanelVisible'] := True;

    info.asString['ProxyOption'] := 'Automatic';
    info.asBoolean['Proxy'] := False;
    info.asString['ProxyAddr'] := '';
    info.asString['ProxyPassword'] := '';
    info.asString['ProxyUsername'] := '';

    info.asBoolean['RememberAccount'] := True;
    info.asString['AccountUserName'] := '';
    info.asString['AccountPassword'] := '';

    info.asString['LastFocusedUID'] := '';

    info.asDateTime['DateAllowConnectPending'] := IncDay(Now, -1);

    infos := info.toCode;
    Crypt(infos, 'Vircess');
  finally
    info.Free;
  end;

  CfgFileName := GetSpecialPath(CSIDL_PROGRAM_FILES) + '\Vircess\Vircess.inf';

  SetLength(s2, 4);
  len2 := Length(infos);
  Move(len2, s2[0], 4);
  infos := infos + RtcBytesToString(s2) + '@VCS@';
  Write_File(CfgFileName, infos);
end;

procedure TfMain.bCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.bOKClick(Sender: TObject);
var
  RASFileName, HelperFileName, AppFileName, PFPath: String;
begin
//    rtcKillProcess('vcs_w32');
//    rtcKillProcess('vcs_x64');
//    rtcKillProcess('Vircess.exe');

//”‰‡ÎËÚ¸ Ù‡ÈÎ˚ Ë ÔÓ‰Ô‡ÔÍË
    if File_Exists(PFPath + '\Vircess\Vircess.exe') then
      Delete_File(PFPath + '\Vircess\Vircess.exe');
//    if File_Exists(PFPath + '\Vircess\Vircess.svc') then
//      Delete_File(PFPath + '\Vircess\Vircess.svc');
//    if File_Exists(PFPath + '\Vircess\Vircess.inf') then
//      Delete_File(PFPath + '\Vircess\Vircess.inf');
//      Delete_File(PFPath + '\Vircess\Vircess.svc');
//    if File_Exists(PFPath + '\Vircess\Vircess.ncl') then
//      Delete_File(PFPath + '\Vircess\Vircess.ncl');
    PFPath := GetSpecialPath(CSIDL_PROGRAM_FILES);
    if not DirectoryExists(PFPath + '\Vircess') then
      CreateDir(PFPath + '\Vircess');
//    CommonUtils.SaveResourceToFile('APP', PFPath + '\Vircess\Vircess.exe');

    SaveSetup;

    PFPath := GetSpecialPath(CSIDL_COMMON_DESKTOPDIRECTORY);
    CreateShortcuts(PFPath);

    PFPath := GetSpecialPath(CSIDL_COMMON_PROGRAMS);
    if not DirectoryExists(PFPath + '\Vircess') then
      CreateDir(PFPath + '\Vircess');
    CreateShortcuts(PFPath + '\Vircess');

//    if not ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
//      ShellExecute(0, 'open', PChar(PFPath + '\Vircess\Vircess.exe'), '/INSTALL', '', SW_HIDE);
//    ShellExecute(0, 'open', PChar(PFPath + '\Vircess\Vircess.exe'), '/START', '', SW_HIDE);
//    ShellExecute(0, 'open', PChar(PFPath + '\Vircess\Vircess.exe'), '/ONLYRUN', '', SW_SHOWNORMAL);

  Close;
end;

procedure TfMain.lLinkClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar('http://vircess.com'), '', nil, SW_SHOW);
end;

procedure TfMain.lLinkMouseEnter(Sender: TObject);
begin
  Screen.Cursor := crHandPoint;
end;


procedure TfMain.lLinkMouseLeave(Sender: TObject);
begin
  Screen.Cursor := crDefault;
end;

procedure TfMain.rbSetupClick(Sender: TObject);
begin
  pPass.Visible := rbSetup.Checked;
  if rbSetup.Checked then
  begin
    bOK.Caption := '”—“¿ÕŒ¬»“‹';
    ePassword.SetFocus;
  end
  else
    bOK.Caption := '«¿œ”—“»“‹';
end;

end.
