unit rdSetClient;

interface

uses
  Windows, Messages, SysUtils, uVircessTypes,
  Variants, Classes, Graphics, Controls, Forms, RunElevatedSupport,
  Dialogs, StdCtrls, Buttons, ServiceMgr, CommonData,

  rtcTypes, rtcConn, rtcHttpCli, rtcPortalCli, rtcPortalHttpCli, Vcl.ComCtrls,
  Vcl.ExtCtrls, WinSvc, Vcl.AppEvnts, rtcInfo, ShellApi, Registry, Math,
  ColorSpeedButton, rtcSystem, rtcLog, CommonUtils;

type
  TrdClientSettings = class;

  TExecuteProcedure = procedure of object;
  TStateProcedure = procedure(fConnected: Boolean) of object;
  TEnableTimersProcedure = procedure(fEnable: Boolean) of object;

  TrdClientSettings = class(TForm)
    tcSettings: TPageControl;
    tsNetwork: TTabSheet;
    gProxy: TGroupBox;
    Label1: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    eProxyAddr: TEdit;
    eProxyUsername: TEdit;
    eProxyPassword: TEdit;
    tsSequrity: TTabSheet;
    rbNoProxy: TRadioButton;
    rbAutomatic: TRadioButton;
    rbManual: TRadioButton;
    eProxyPort: TEdit;
    Label2: TLabel;
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    cbOnlyAdminChanges: TCheckBox;
    ApplicationEvents1: TApplicationEvents;
    cbAutoRun: TCheckBox;
    cbStoreHistory: TCheckBox;
    cbStorePasswords: TCheckBox;
    GroupBox1: TGroupBox;
    Label7: TLabel;
    Label6: TLabel;
    ePassword: TEdit;
    ePasswordConfirm: TEdit;

    procedure xSSLClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure xProxyClick(Sender: TObject);
    procedure rbNoProxyClick(Sender: TObject);
    procedure rbAutomaticClick(Sender: TObject);
    procedure rbManualClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure cbAutoRunKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbStoreHistoryClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    { Private declarations }

  public
    { Public declarations }
    ProxyOption, CurProxyOption: String;
    PClient: PRtcHTTPPortalClient;
    HTTPClient, TimerClient, TimerClient2: PRtcHTTPClient;
    NetParamsChanged: Boolean;
    StateProcedure: TStateProcedure;
    PrevAutoRun: Boolean;
    FOnCustomFormClose: TOnCustomFormEvent;

    procedure Setup;
    function ConnectionParamsChanged: Boolean;
//    function CheckService(bServiceFilename: Boolean = True {False = Service Name} ): String;

    function Execute: Boolean;
    function IsRegistryAutoRun: Boolean;
    procedure SetRegistryAutoRun(Value: Boolean);
    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
  end;

implementation

{$R *.dfm}

procedure TrdClientSettings.xSSLClick(Sender: TObject);
  begin
//  if xSSL.Checked and (ePort.Text = '80') then
//    ePort.Text := '443'
//  else if not xSSL.Checked and (ePort.Text = '443') then
//    ePort.Text := '80';
  end;

procedure TrdClientSettings.Setup;
var
  i: Integer;
begin
  CurProxyOption := ProxyOption;
  if ProxyOption = 'NoProxy' then
  begin
    rbNoProxy.Checked := True;
    rbAutomatic.Checked := False;
    rbManual.Checked := False;
  end
  else if ProxyOption = 'Automatic' then
  begin
    rbNoProxy.Checked := False;
    rbAutomatic.Checked := True;
    rbManual.Checked := False;
  end
  else if ProxyOption = 'Manual' then
  begin
    rbNoProxy.Checked := False;
    rbAutomatic.Checked := False;
    rbManual.Checked := True;
  end;

//  eAddress.Text := String(HTTPClient^.ServerAddr);
//  ePort.Text:=String(PClient.GatePort);

//  if PClient.Gate_Proxy or PClient.Gate_WinHttp then
//    begin
  i := Pos(':', PClient^.Gate_ProxyAddr);
  if i > 0 then
  begin
    eProxyAddr.Text := Copy(PClient^.Gate_ProxyAddr, 0, i - 1);
    eProxyPort.Text := Copy(PClient^.Gate_ProxyAddr, i + 1, Length(PClient^.Gate_ProxyAddr) - i);
  end
  else
    eProxyAddr.Text := PClient^.Gate_ProxyAddr;
  eProxyUsername.Text := PClient^.Gate_ProxyUserName;
  eProxyPassword.Text := PClient^.Gate_ProxyPassword;
//    end
//  else
//    begin
//    eProxyAddr.Text:='';
//    eProxyUsername.Text:='';
//    eProxyPassword.Text:='';
//    end;
end;

procedure TrdClientSettings.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  if Msg.message = WM_KEYUP then
    case Msg.wParam of
      VK_RETURN:
        begin
          btnOKClick(nil);
          Handled := True;
        end;
      VK_ESCAPE:
        begin
          btnCancelClick(nil);
          Handled := True;
        end;
      15:
        Handled := True;
    end;
end;

procedure TrdClientSettings.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Hide;
end;

function TrdClientSettings.ConnectionParamsChanged: Boolean;
var
  s: String;
begin
  if Trim(eProxyAddr.Text) + ':' + Trim(eProxyPort.Text) <> ':' then
    s := Trim(eProxyAddr.Text) + ':' + Trim(eProxyPort.Text)
  else
    s := '';

  Result := //(HTTPClient^.ServerAddr <> Trim(eAddress.Text))
    //or
    (CurProxyOption <> ProxyOption)
    or (PClient^.Gate_ProxyAddr <> s)
    or (PClient^.Gate_ProxyUserName <> Trim(eProxyUsername.Text))
    or (PClient^.Gate_ProxyPassword <> Trim(eProxyPassword.Text));
end;

//function TrdClientSettings.CheckService(bServiceFilename: Boolean = True {False = Service Name} ): String;
//begin
//  if bServiceFilename then
//    Result := ParamStr(0)
//  else
//    Result := RTC_HOSTSERVICE_NAME;
//end;

procedure TrdClientSettings.btnOKClick(Sender: TObject);
var
  i: Integer;
  fn: String;
  err: LongInt;
  EleavateSupport: TEleavateSupport;
begin
  if ePassword.Text <> ePasswordConfirm.Text then
  begin
    MessageBox(Handle, '������ � ������������� ������ �� ���������', 'VIRCESS', MB_ICONWARNING or MB_OK);
    if Visible then
      ePassword.SetFocus;
    Exit;
  end;
  if ProxyOption = 'Manual' then
  begin
    if Trim(eProxyAddr.Text) = ''then
    begin
      MessageBox(Handle, '�� ������ ����� ������-�������', 'VIRCESS', MB_ICONWARNING or MB_OK);
      eProxyAddr.SetFocus;
      Exit;
    end;
    if Trim(eProxyPort.Text) = ''then
    begin
      MessageBox(Handle, '�� ������ ���� ������-�������', 'VIRCESS', MB_ICONWARNING or MB_OK);
      eProxyPort.SetFocus;
      Exit;
    end;
  end;

  if PrevAutoRun <> cbAutoRun.Checked then
    if (Win32MajorVersion >= 6) then //vista\server 2k8
    begin
      if cbAutoRun.Checked then
        begin
          //������� ����-����. ��� ����� ������� ����������� ��� �������
          with TStringList.Create do
          begin
            SaveToFile(ChangeFileExt(ParamStr(0), '.ncl'));
            Free;
          end;

//          with TStringList.Create do
//          try
//            if (not ServiceInstalled(nil, RTC_HOSTSERVICE_NAME)) then
//              Add(ParamStr(0) + ' /INSTALL');
//            Add(ParamStr(0) + ' /START');
//            Add('PING 127.0.0.1 -n 1 > NUL');
//            fn := GetTempFile;
//            Rename_File(fn, fn + '.bat');
//            fn := fn + '.bat';
//            Add('DEL "' + fn + '"');
//            SaveToFile(fn, TEncoding.GetEncoding(866));
//          finally
//            Free;
//          end;
//          ShellExecute(Handle, 'open', PWideChar(WideString(fn)), nil, nil, SW_HIDE);
          EleavateSupport := TEleavateSupport.Create(nil);
          try
            SetLastError(EleavateSupport.RunElevated(ParamStr(0), ' /INSTALL', Handle, False, Application.ProcessMessages));
            err := GetLastError;
            if (err <> ERROR_SUCCESS)
              and (err <> ERROR_INVALID_FUNCTION) then
            begin
              xLog('ServiceInstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
              Exit;
            end;
          finally
            EleavateSupport.Free;
          end;
//          if CreateServices(RTC_HOSTSERVICE_NAME, RTC_HOSTSERVICE_DISPLAY_NAME, ParamStr(0)) then
//            StartServices(RTC_HOSTSERVICE_NAME);
        end
        else
        begin
//          with TStringList.Create do
//          try
//            if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
//              Add(ParamStr(0) + ' /STOP /NOCLOSE');
//            Add(ParamStr(0) + ' /UNINSTALL /NOCLOSE');
//            Add('PING 127.0.0.1 -n 1 > NUL');
////              Add('START ' + ParamStr(0));
//            fn := GetTempFile;
//            Rename_File(fn, fn + '.bat');
//            fn := fn + '.bat';
//            Add('DEL "' + fn + '"');
//            SaveToFile(fn, TEncoding.GetEncoding(866));
//          finally
//            Free;
//          end;
//          ShellExecute(Handle, 'open', PWideChar(WideString(fn)), nil, nil, SW_HIDE);
          EleavateSupport := TEleavateSupport.Create(nil);
          try
            SetLastError(EleavateSupport.RunElevated(ParamStr(0), ' /UNINSTALL', Handle, False, Application.ProcessMessages));
            err := GetLastError;
            if (err <> ERROR_SUCCESS)
              and (err <> ERROR_INVALID_FUNCTION) then
            begin
              xLog('ServiceUninstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
              Exit;
            end;
          finally
            EleavateSupport.Free;
          end;
//          UninstallService(RTC_HOSTSERVICE_NAME, 0)
        end;
    end
    else
      SetRegistryAutoRun(cbAutoRun.Checked);

  NetParamsChanged := ConnectionParamsChanged();

  if NetParamsChanged then
  begin
    if PClient^.Active then
    begin
//        PGatewayRec(GatewayClientsList^[i]).GatewayClient^.Module.SkipRequests;
      PClient^.Disconnect;
      PClient^.Active := False;
//        PGatewayRec(GatewayClientsList^[i]).GatewayClient^.Stop;
    end;

    HTTPClient^.AutoConnect := False;
    HTTPClient^.ReconnectOn.ConnectError := False;
    HTTPClient^.ReconnectOn.ConnectLost := False;
    HTTPClient^.ReconnectOn.ConnectFail := False;
    HTTPClient^.DisconnectNow(True);

    TimerClient^.AutoConnect := False;
    TimerClient^.ReconnectOn.ConnectError := False;
    TimerClient^.ReconnectOn.ConnectLost := False;
    TimerClient^.ReconnectOn.ConnectFail := False;
    TimerClient^.DisconnectNow(True);

    TimerClient2^.AutoConnect := False;
    TimerClient2^.ReconnectOn.ConnectError := False;
    TimerClient2^.ReconnectOn.ConnectLost := False;
    TimerClient2^.ReconnectOn.ConnectFail := False;
    TimerClient2^.DisconnectNow(True);

    StateProcedure(False);  //��������. ���� ������ ������

//    HTTPClient^.ServerAddr := RtcString(Trim(eAddress.Text));
//    TimerClient^.ServerAddr := RtcString(Trim(eAddress.Text));
//    TimerClient2^.ServerAddr := RtcString(Trim(eAddress.Text));

  //  PClient.Gate_Proxy := xProxy.Checked;
  //  HTTPClient^.UseProxy := xProxy.Checked;

  //  if PClient.Gate_Proxy or PClient.Gate_WinHttp then
  //    begin

    if CurProxyOption = 'Automatic' then
    begin
      PClient^.Gate_WinHttp := True;
      PClient^.Gate_Proxy := False;
      PClient^.Gate_ProxyAddr := '';
      PClient^.Gate_ProxyUserName := '';
      PClient^.Gate_ProxyPassword := '';

      HTTPClient^.UseWinHTTP := True;
      HTTPClient^.UseProxy := False;
      HTTPClient^.UserLogin.ProxyAddr := '';
      HTTPClient^.UserLogin.ProxyUserName := '';
      HTTPClient^.UserLogin.ProxyPassword := '';

      TimerClient^.UseWinHTTP := True;
      TimerClient^.UseProxy := False;
      TimerClient^.UserLogin.ProxyAddr := '';
      TimerClient^.UserLogin.ProxyUserName := '';
      TimerClient^.UserLogin.ProxyPassword := '';

      TimerClient2^.UseWinHTTP := True;
      TimerClient2^.UseProxy := False;
      TimerClient2^.UserLogin.ProxyAddr := '';
      TimerClient2^.UserLogin.ProxyUserName := '';
      TimerClient2^.UserLogin.ProxyPassword := '';
    end
    else
    if CurProxyOption = 'Manual' then
    begin
      PClient^.Gate_WinHttp := False;
      PClient^.Gate_Proxy := True;
      PClient^.Gate_ProxyAddr := Trim(eProxyAddr.Text) + ':' + Trim(eProxyPort.Text);
      PClient^.Gate_ProxyUserName := Trim(eProxyUsername.Text);
      PClient^.Gate_ProxyPassword := Trim(eProxyPassword.Text);

      HTTPClient^.UseWinHTTP := False;
      HTTPClient^.UseProxy := True;
      HTTPClient^.UserLogin.ProxyAddr := Trim(eProxyAddr.Text);
      HTTPClient^.UserLogin.ProxyUserName := Trim(eProxyUsername.Text);
      HTTPClient^.UserLogin.ProxyPassword := Trim(eProxyPassword.Text);

      TimerClient^.UseWinHTTP := False;
      TimerClient^.UseProxy := True;
      TimerClient^.UserLogin.ProxyAddr := Trim(eProxyAddr.Text);
      TimerClient^.UserLogin.ProxyUserName := Trim(eProxyUsername.Text);
      TimerClient^.UserLogin.ProxyPassword := Trim(eProxyPassword.Text);

      TimerClient2^.UseWinHTTP := False;
      TimerClient2^.UseProxy := True;
      TimerClient2^.UserLogin.ProxyAddr := Trim(eProxyAddr.Text);
      TimerClient2^.UserLogin.ProxyUserName := Trim(eProxyUsername.Text);
      TimerClient2^.UserLogin.ProxyPassword := Trim(eProxyPassword.Text);
    end
    else
    begin
      PClient^.Gate_WinHttp := False;
      PClient^.Gate_Proxy := False;
      PClient^.Gate_ProxyAddr := '';
      PClient^.Gate_ProxyUserName := '';
      PClient^.Gate_ProxyPassword := '';

      HTTPClient^.UseWinHTTP := False;
      HTTPClient^.UseProxy := False;
      HTTPClient^.UserLogin.ProxyAddr := '';
      HTTPClient^.UserLogin.ProxyUserName := '';
      HTTPClient^.UserLogin.ProxyPassword := '';

      TimerClient^.UseWinHTTP := False;
      TimerClient^.UseProxy := False;
      TimerClient^.UserLogin.ProxyAddr := '';
      TimerClient^.UserLogin.ProxyUserName := '';
      TimerClient^.UserLogin.ProxyPassword := '';

      TimerClient2^.UseWinHTTP := False;
      TimerClient2^.UseProxy := False;
      TimerClient2^.UserLogin.ProxyAddr := '';
      TimerClient2^.UserLogin.ProxyUserName := '';
      TimerClient2^.UserLogin.ProxyPassword := '';
    end;

    PClient^.Active := True;

    HTTPClient^.AutoConnect := True;
    HTTPClient^.ReconnectOn.ConnectError := True;
    HTTPClient^.ReconnectOn.ConnectLost := True;
    HTTPClient^.ReconnectOn.ConnectFail := True;
    HTTPClient^.Connect(True, True);

    TimerClient^.AutoConnect := True;
    TimerClient^.ReconnectOn.ConnectError := True;
    TimerClient^.ReconnectOn.ConnectLost := True;
    TimerClient^.ReconnectOn.ConnectFail := True;
    TimerClient^.Connect(True, True);

    TimerClient2^.AutoConnect := True;
    TimerClient2^.ReconnectOn.ConnectError := True;
    TimerClient2^.ReconnectOn.ConnectLost := True;
    TimerClient2^.ReconnectOn.ConnectFail := True;
    TimerClient2^.Connect(True, True);
  end;

  ModalResult := mrOk;

  Hide;
end;

procedure TrdClientSettings.cbAutoRunKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
//var
//  Mgs: TMsg;
begin
//  if (Key = VK_RETURN)
//    or (Key = VK_ESCAPE) then
//    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);
//
//  if Key = VK_RETURN then
//    btnOKClick(Sender)
//  else if Key = VK_ESCAPE then
//    btnCancelClick(Sender);
end;

procedure TrdClientSettings.cbStoreHistoryClick(Sender: TObject);
begin
  if cbStoreHistory.Checked then
    cbStorePasswords.Enabled := True
  else
  begin
    cbStorePasswords.Enabled := False;
    cbStorePasswords.Checked := False;
  end;
end;

function TrdClientSettings.Execute: Boolean;
begin
  Setup;
  xProxyClick(nil);
end;

procedure TrdClientSettings.SetRegistryAutoRun(Value: Boolean);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_WRITE);
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.LazyWrite := False;
  Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False);
//    else Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run',False);
  if Value then
    Reg.WriteString('Vircess', ParamStr(0))
  else
    Reg.DeleteValue('Vircess');
  Reg.CloseKey;
  Reg.Free;
end;

function TrdClientSettings.IsRegistryAutoRun: Boolean;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ);
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.LazyWrite := False;
  Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False);
//    else Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run',False);
  Result := (Reg.ReadString('Vircess') = ParamStr(0));
  Reg.CloseKey;
  Reg.Free
end;

procedure TrdClientSettings.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose(Handle);
end;

procedure TrdClientSettings.FormCreate(Sender: TObject);
var
  ElevateSupport: TEleavateSupport;
begin
  ElevateSupport := TEleavateSupport.Create(nil);
  try
    try
      cbAutoRun.Enabled := ElevateSupport.IsAdministrator;
    except
      cbAutoRun.Enabled := False;
    end;
  finally
    ElevateSupport.Free;
  end;
end;

procedure TrdClientSettings.FormShow(Sender: TObject);
//var
//  IsAdmin: Boolean;
begin
//  IsAdmin := RunedAsAdmin;
//  if IsAdmin then
//    cbOnlyAdminChanges.Enabled := True
//  else
//  begin
//    cbOnlyAdminChanges.Enabled := False;
//
//    if cbOnlyAdminChanges.Checked then
//    begin
//      ePassword.Enabled := False;
//      ePasswordConfirm.Enabled := False;
//    end;
//  end;

  if (Win32MajorVersion >= 6 {vista\server 2k8}) then
    cbAutoRun.Checked := IsServiceStarted(RTC_HOSTSERVICE_NAME)
  else
    cbAutoRun.Checked := IsRegistryAutoRun;
  PrevAutoRun := cbAutoRun.Checked;

  xProxyClick(nil);

  if (tcSettings.ActivePage.Name = 'tsSequrity')
    and Visible then
  begin
    ePassword.SetFocus;
    ePassword.SelectAll;
  end;

  cbStoreHistoryClick(nil);
end;

procedure TrdClientSettings.rbAutomaticClick(Sender: TObject);
begin
  rbNoProxy.Checked := False;
  rbManual.Checked := False;
  CurProxyOption := 'Automatic';

  xProxyClick(nil);
end;

procedure TrdClientSettings.rbManualClick(Sender: TObject);
begin
  rbNoProxy.Checked := False;
  rbAutomatic.Checked := False;
  CurProxyOption := 'Manual';

  xProxyClick(nil);

  if Visible then
    eProxyAddr.SetFocus;
end;

procedure TrdClientSettings.rbNoProxyClick(Sender: TObject);
begin
  rbAutomatic.Checked := False;
  rbManual.Checked := False;
  CurProxyOption := 'NoProxy';

  xProxyClick(nil);
end;

procedure TrdClientSettings.xProxyClick(Sender: TObject);
  begin
  if CurProxyOption = 'Manual' then
  begin
    eProxyAddr.Color := clWindow;
    eProxyPort.Color := clWindow;
    eProxyUsername.Color := clWindow;
    eProxyPassword.Color := clWindow;

    eProxyAddr.Enabled := True;
    eProxyPort.Enabled := True;
    eProxyUsername.Enabled := True;
    eProxyPassword.Enabled := True;
  end
  else
  begin
    eProxyAddr.Color := clMenu;
    eProxyPort.Color := clMenu;
    eProxyUsername.Color := clMenu;
    eProxyPassword.Color := clMenu;

    eProxyAddr.Enabled := False;
    eProxyPort.Enabled := False;
    eProxyUsername.Enabled := False;
    eProxyPassword.Enabled := False;
  end;
end;

end.