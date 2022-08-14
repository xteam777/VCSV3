unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, ComObj, ActiveX,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls, ShlObj, rtcWinlogon,
  Vcl.StdCtrls, Vcl.Buttons, ShellApi, rtcSystem, rtcInfo, rtcCrypt, DateUtils, Registry,
  IOUtils, CommonUtils, ServiceMgr;

type
  TfMain = class(TForm)
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    iBkgTop: TImage;
    lLink: TLabel;
    pInstall: TPanel;
    rgAction: TRadioGroup;
    rbSetup: TRadioButton;
    rbRun: TRadioButton;
    pPass: TPanel;
    Label2: TLabel;
    Label4: TLabel;
    Label3: TLabel;
    Label1: TLabel;
    eConfirm: TEdit;
    ePassword: TEdit;
    pDelete: TPanel;
    Label5: TLabel;
    rn: TCheckBox;
    pBtnDel: TPanel;
    bDel: TSpeedButton;
    procedure lLinkClick(Sender: TObject);
    procedure lLinkMouseEnter(Sender: TObject);
    procedure lLinkMouseLeave(Sender: TObject);
    procedure rbSetupClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bDelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    procedure SaveSetup(pass:string; cfg: string='CSIDL_PROGRAM_FILES'; add:string='95.216.96.39');
    procedure AddToRegistry;
    function GetSpecialPath(CSIDL: Integer): String;
    function CreateShortcut(const CmdLine, Args, WorkDir, LinkFile: String): IPersistFile;
    procedure CreateShortcuts(DestinationPath: String);
    procedure DeleteShortcuts(DestinationPath: String);
    function kill_all(no_check:boolean=False): boolean;
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

procedure TfMain.bCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.bOKClick(Sender: TObject);
var
  RASFileName, HelperFileName, AppFileName, PFPath,PFPath_,TMP: String;
begin
  if not kill_all then EXIT;

  if rbRun.Checked then
  begin

    TMP:= GetTempDirectory+'\Vircess\';
    ForceDirectories(tmp);

    RASFileName := tmp + 'VcsInstall.exe';
    HelperFileName := tmp + 'vcs_w32.exe';
    AppFileName := tmp + 'Vircess.exe';

    if not File_Exists(AppFileName) then
      CommonUtils.SaveResourceToFile('APP', AppFileName);

    if not File_Exists(RASFileName) then
      CommonUtils.SaveResourceToFile('RUNASSYS', RASFileName);

    if not File_Exists(HelperFileName) then
      CommonUtils.SaveResourceToFile('HELPER', HelperFileName);


    if not FileExists(  tmp + 'Vircess.inf') then
           SaveSetup('',tmp + 'Vircess.inf');

    ShellExecute(0, 'open', PChar(RASFileName), '/user:SYSTEM vcs_w32.exe', PChar(tmp), SW_SHOWNORMAL);
    ShellExecute(0, 'open', PChar(AppFileName), nil, nil, SW_SHOWNORMAL); // /ONLYRUN //ShellExecute(0, 'open', PChar(HelperFileName), '', '', SW_SHOWNORMAL);
  end
  else //________________________________________________________________________

  begin

    if ePassword.Text <> eConfirm.Text then
    begin
      MessageBox(Handle, 'Пароль и подтверждение не совпадают', 'Установка Vircess', MB_OK + MB_ICONEXCLAMATION);
      EXIT;
    end;
    {
    rtcKillProcess('vcs_w32');
    rtcKillProcess('vcs_x64');
    rtcKillProcess('Vircess.exe');
    }
    PFPath := GetSpecialPath(CSIDL_PROGRAM_FILES)+'\Vircess\';
    if not DirectoryExists(PFPath)     then CreateDir(PFPath);

    if File_Exists(PFPath + 'Vircess.exe')    then Delete_File(PFPath + 'Vircess.exe');
    if File_Exists(PFPath + 'vcs_w32.exe')    then Delete_File(PFPath + 'vcs_w32.exe');
    if File_Exists(PFPath + 'vcs_w64.exe')    then Delete_File(PFPath + 'vcs_w64.exe');
    if File_Exists(PFPath + 'VcsInstall.exe') then Delete_File(PFPath + 'VcsInstall.exe');
    if File_Exists(PFPath + 'vcs_w32_run as SYSTEM.BAT')
                                              then Delete_File(PFPath + 'vcs_w32_run as SYSTEM.BAT');

      CommonUtils.SaveResourceToFile('APP',      PFPath + 'Vircess.exe');
      CommonUtils.SaveResourceToFile('RUNASSYS', PFPath + 'VcsInstall.exe');
      CommonUtils.SaveResourceToFile('HELPER',   PFPath + 'vcs_w32.exe');
      CommonUtils.SaveResourceToFile('BAT',      PFPath + 'vcs_w32_run as SYSTEM.BAT');

    SaveSetup(ePassword.Text);

    PFPath_ := GetSpecialPath(CSIDL_COMMON_DESKTOPDIRECTORY);
    CreateShortcuts(PFPath_);
    PFPath_ := GetSpecialPath(CSIDL_COMMON_PROGRAMS);
    if not DirectoryExists(PFPath_ + '\Vircess') then
      CreateDir(PFPath_ + '\Vircess');
      CreateShortcuts(PFPath_ + '\Vircess');

    if rn.checked then
    begin
      sleep(500);
      shellExecute(0, 'open', PChar(PFPath + 'VcsInstall.exe'), '/user:SYSTEM vcs_w32.exe',
                              PChar(PFPath), SW_SHOWNORMAL);
      sleep(500);
      shellExecute(0, 'open', PChar(PFPath + 'Vircess.exe'), nil, nil, SW_SHOWNORMAL);
    end else
      shellExecute(0, 'open', PChar('Explorer.exe'),PChar(PFPath), nil, SW_SHOWNORMAL);

//    if not ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then showmessage('-');
//      ShellExecute(0, 'open', PChar(PFPath + '\Vircess\Vircess.exe'), '/INSTALL', '', SW_HIDE);
//    ShellExecute(0, 'open', PChar(PFPath + '\Vircess\Vircess.exe'), '/START', '', SW_HIDE);
//    ShellExecute(0, 'open', PChar(PFPath + '\Vircess\Vircess.exe'), '/ONLYRUN', '', SW_SHOWNORMAL);
  end;

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
 if pBtnDel.visible then
    bOK.caption:= 'ПЕРЕУСТАНОВИТЬ' else
    bOK.caption:= 'УСТАНОВИТЬ';
    ePassword.SetFocus;
  end
  else
    bOK.Caption := 'ЗАПУСТИТЬ';
    rn.visible:= rbSetup.Checked;
end;

procedure TfMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=27 then Close;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
 pBtnDel.visible:= directoryExists(GetSpecialPath(CSIDL_PROGRAM_FILES)+'\Vircess\');

 if pBtnDel.visible then
    bOK.caption:= 'ПЕРЕУСТАНОВИТЬ' else
    bOK.caption:= 'УСТАНОВИТЬ';

 if sender = nil then EXIT;
end;

function TfMain.kill_all(no_check:boolean=False): boolean;
begin
  result:= False;
  if no_check or (rtcGetProcessID('Vircess.exe')<>0) then
  begin
    if MessageBox(Handle, 'Перед продолжением необходимо закрыть программу Vircess и сопуствующие процессы.'#13#13'Продолжить ?', 'Vircess', MB_ICONQUESTION + MB_OKCANCEL)<>IDOK then EXIT;
    rtcKillProcess('Vircess.exe');
    rtcKillProcess('vcs_w32.exe');
    rtcKillProcess('vcs_x64.exe'); sleep(500);

  if (rtcGetProcessID('vcs_w32.exe')<>0) or (rtcGetProcessID('vcs_w64.exe')<>0) then
  begin
     MessageBox(Handle, 'Текущий диалог должен быть открыт с повышенными привилегиями.'#13'Перезапустите мастер от имени администратора', 'Vircess', MB_ICONWARNING + MB_OK);
     if no_check then HALT;
  end;

  end;
  result:= True;
end;

procedure TfMain.bDelClick(Sender: TObject);
begin
  if not kill_all(True) then EXIT;
  sleep(500);
  if DirectoryExists(GetSpecialPath(CSIDL_PROGRAM_FILES)+'\Vircess\') then
  begin
     TDirectory.Delete(GetSpecialPath(CSIDL_PROGRAM_FILES)+'\Vircess\', True);
  end;

  DeleteShortcuts(GetSpecialPath(CSIDL_COMMON_DESKTOPDIRECTORY));
  DeleteShortcuts(GetSpecialPath(CSIDL_COMMON_PROGRAMS) + '\Vircess');
  FormShow(nil);
end;

procedure TfMain.SaveSetup(pass:string; cfg: string='CSIDL_PROGRAM_FILES'; add:string='95.216.96.39');
var
  infos: RtcString;
  s2: RtcByteArray;
  info: TRtcRecord;
  len2: LongInt;
begin
  info := TRtcRecord.Create;
  try
    info.asString['Address'] :=  add;
    info.asBoolean['WinHTTP'] := True;

    info.asString['RegularPassword'] := pass; //ePassword.Text;//

    info.asBoolean['StoreHistory'] := True;
    info.asBoolean['StorePasswords'] := True;
    info.asBoolean['OnlyAdminChanges'] := False;

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

  if Cfg = 'CSIDL_PROGRAM_FILES' then
     Cfg:= GetSpecialPath(CSIDL_PROGRAM_FILES) + '\Vircess\Vircess.inf';

  SetLength(s2, 4);
  len2 := Length(infos);
  Move(len2, s2[0], 4);
  infos := infos + RtcBytesToString(s2) + '@VCS@';
  Write_File(Cfg, infos);
end;




end.
