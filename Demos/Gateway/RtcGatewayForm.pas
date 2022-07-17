{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit RtcGatewayForm;

interface

{$INCLUDE rtcDefs.inc}

uses
  Windows, Messages, SysUtils, uVircessTypes,
  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ShellApi,

{$IFDEF IDE_XE3up}
  UITypes,
{$ENDIF}

  rtcSystem, rtcLog, rtcCrypt,
  rtcThrPool,
  rtcSrvModule, rtcPortalGate,
  rtcDataSrv, rtcHttpSrv,
  rtcInfo, rtcConn,

  rtcGatewaySvc, rtcDataProvider,

  jpeg, ComCtrls, Buttons, WinSock, rtcFunction, Variants, rtcDataCli,
  rtcCliModule, rtcHttpCli;

const
  WM_TASKBAREVENT = WM_USER + 1;

type
  TMainForm = class(TForm)
    pTitlebar: TPanel;
    cTitleBar: TLabel;
    btnMinimize: TSpeedButton;
    btnClose: TSpeedButton;
    Pages: TPageControl;
    Page_Setup: TTabSheet;
    Page_Active: TTabSheet;
    btnLogin: TButton;
    eAddress: TEdit;
    xBindIP: TCheckBox;
    Panel2: TPanel;
    Label24: TLabel;
    btnInstall: TSpeedButton;
    btnRun: TSpeedButton;
    btnStop: TSpeedButton;
    btnUninstall: TSpeedButton;
    Label5: TLabel;
    btnLogout: TSpeedButton;
    lblStatusPanel: TPanel;
    lblStatus: TLabel;
    HttpServer1: TRtcHttpServer;
    DataProvider1: TRtcDataProvider;
    Gateway1: TRtcPortalGateway;
    btnRestartService: TSpeedButton;
    btnSaveSetup: TSpeedButton;
    hsMain1: TRtcHttpServer;
    Label1: TLabel;
    Label3: TLabel;
    eSQLServer: TEdit;
    eLogoff: TEdit;
    bLogoffUser: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    hsMain2: TRtcHttpServer;
    hsMain3: TRtcHttpServer;
    hsMain4: TRtcHttpServer;
    HttpServer2: TRtcHttpServer;
    Gateway2: TRtcPortalGateway;
    DataProvider2: TRtcDataProvider;
    HttpServer3: TRtcHttpServer;
    Gateway3: TRtcPortalGateway;
    DataProvider3: TRtcDataProvider;
    DataProvider4: TRtcDataProvider;
    Gateway4: TRtcPortalGateway;
    HttpServer4: TRtcHttpServer;
    cbMainGate: TCheckBox;
    cb80: TCheckBox;
    cb8080: TCheckBox;
    cb443: TCheckBox;
    cb5938: TCheckBox;
    tGetStatsCount: TTimer;
    Label7: TLabel;
    Label6: TLabel;
    Label4: TLabel;
    Label2: TLabel;
    l80: TLabel;
    l8080: TLabel;
    l443: TLabel;
    l5938: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    lAccounts: TLabel;
    lHosts: TLabel;
    MainGateClient: TRtcHttpClient;
    MainGateServer: TRtcHttpServer;
    eMainGate: TEdit;
    Label8: TLabel;
    lGateways: TLabel;
    eMaxUsers: TEdit;
    Label9: TLabel;
    PortalGateServer: TRtcHttpServer;
    procedure btnLoginClick(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure xSSLClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnMinimizeClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    { Private-Deklarationen }
    procedure WMTaskbarEvent(var Message: TMessage); message WM_TASKBAREVENT;
    procedure btnCloseClick(Sender: TObject);
    procedure pTitlebarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pTitlebarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pTitlebarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure xBindIPClick(Sender: TObject);
    procedure xISAPIClick(Sender: TObject);
    procedure btnInstallClick(Sender: TObject);
    procedure btnUninstallClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure DataProvider1CheckRequest(Sender: TRtcConnection);
    procedure DataProvider1DataReceived(Sender: TRtcConnection);
    procedure HttpServer1ListenError(Sender: TRtcConnection; E: Exception);
    procedure Gateway1UserLogin(const UserName: String);
    procedure Gateway1UserLogout(const UserName: String);
    procedure HttpServer1ListenLost(Sender: TRtcConnection);
    procedure btnSaveSetupClick(Sender: TObject);
    procedure btnRestartServiceClick(Sender: TObject);
    procedure rRegisterHostExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure Gateway1SessionClosing(Sender: TRtcConnection);
    procedure FormShow(Sender: TObject);
    procedure bLogoffUserClick(Sender: TObject);
    procedure GatewayUserPing(const UserName: string);
    procedure GatewayUserPingTimeout(const UserName: string);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure cb80Click(Sender: TObject);
    procedure cb8080Click(Sender: TObject);
    procedure cb443Click(Sender: TObject);
    procedure cb5938Click(Sender: TObject);
    procedure tGetStatsCountTimer(Sender: TObject);
    procedure cbMainGateClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
//    procedure OnBillingUserLogin(const UserName: String);
//    procedure OnBillingUserLogOut(const UserName: String);
  public
    { Public declarations }
    TaskBarIcon:boolean;
//    Account: TRtcAccounts;

    procedure LoadSetup;
    procedure SaveSetup;

    procedure TaskBarAddIcon;
    procedure TaskBarRemoveIcon;
    function GetLocalIP: String;

    procedure On_Error(const s:string);

    procedure StartForceUserLogoutThreadInAllGateways(AUserName: String);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.TaskBarAddIcon;
  var
    tnid: TNotifyIconData;
    xOwner: HWnd;
  begin
  if not TaskBarIcon then
    begin
    with tnid do
      begin
      cbSize := System.SizeOf(TNotifyIconData);
      Wnd := self.Handle;
      uID := 1;
      uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
      uCallbackMessage := WM_TASKBAREVENT;
      hIcon := Application.Icon.Handle;
      end;
    StrCopy(tnid.szTip, 'Vircess Gateway');
    Shell_NotifyIcon(NIM_ADD, @tnid);

    xOwner := GetWindow(self.Handle, GW_OWNER);
    If xOwner <> 0 Then
      ShowWindow(xOwner, SW_HIDE);

    TaskBarIcon := True;
    end;
  end;

procedure TMainForm.TaskBarRemoveIcon;
  var
    tnid: TNotifyIconData;
    xOwner: HWnd;
  begin
  if TaskBarIcon then
    begin
    tnid.cbSize := SizeOf(TNotifyIconData);
    tnid.Wnd := self.Handle;
    tnid.uID := 1;
    Shell_NotifyIcon(NIM_DELETE, @tnid);
    xOwner:=GetWindow(self.Handle,GW_OWNER);
    If xOwner<>0 Then
      Begin
      ShowWindow(xOwner,SW_Show);
      ShowWindow(xOwner,SW_Normal);
      End;
    TaskBarIcon:=false;
    end;
  end;

procedure TMainForm.tGetStatsCountTimer(Sender: TObject);
begin
  lAccounts.Caption := IntToStr(GetDataProvider.GetAccountsCount);
  lHosts.Caption := IntToStr(GetDataProvider.GetHostsCount);
  lGateways.Caption := IntToStr(GetDataProvider.GetGatewaysCount);

  l80.Caption := IntToStr(Gateway1.GetUsersCount);
  l8080.Caption := IntToStr(Gateway2.GetUsersCount);
  l443.Caption := IntToStr(Gateway3.GetUsersCount);
  l5938.Caption := IntToStr(Gateway4.GetUsersCount);
end;

procedure TMainForm.WMTaskbarEvent(var Message: TMessage);
  begin
  case Message.LParamLo of
    WM_LBUTTONUP,
    WM_RBUTTONUP:
          begin
          Application.Restore;
          Application.BringToFront;
          TaskBarRemoveIcon;
          end;
    end;
  end;

procedure TMainForm.FormCreate(Sender: TObject);
  begin
  Pages.ActivePage:=Page_Setup;
  Page_Active.TabVisible:=False;

  LOG_THREAD_EXCEPTIONS:=True;
  LOG_EXCEPTIONS:=True;

  RTC_THREAD_PRIORITY:=tpHigher;

  TaskBarIcon:=False;

  StartLog;

  Gateway1.InfoFileName:=ChangeFileExt(AppFileName + '1','.usr');
  Gateway2.InfoFileName:=ChangeFileExt(AppFileName + '2','.usr');
  Gateway3.InfoFileName:=ChangeFileExt(AppFileName + '3','.usr');
  Gateway4.InfoFileName:=ChangeFileExt(AppFileName + '4','.usr');
//  Gateway.SQLConnectionString := 'provider=SQLNCLI11;server=localhost;database=Vircess;uid=sa;pwd=2230897';

  LoadSetup;

//  eAddress.Text := '95.216.96.39'; //GetLocalIP;
  end;

procedure TMainForm.FormShow(Sender: TObject);
begin
//  btnLoginClick(Sender);
end;

function TMainForm.GetLocalIP: String;
var WSAData: TWSAData;
  P: PHostEnt;
  Name: PAnsiChar;
begin
  WSAStartup($0101, WSAData);
  GetHostName(Name, $FF);
  P := GetHostByName(Name);
  Result := inet_ntoa(PInAddr(P.h_addr_list^)^);
  WSACleanup;
end;

{procedure TMainForm.OnBillingUserLogin(const UserName: String);
var
  a: Integer;
  have: Boolean;
  el: TListItem;
begin
  have := False;
  for a := 0 to eBillingUsers.Items.Count - 1 do
    if eBillingUsers.Items[a].Caption = UserName then
      have := True;
  if not have then
  begin
    el := eBillingUsers.Items.Add;
    el.Caption := UserName;
    eBillingUsers.Update;
  end;
  if eBillingUsers.Items.Count = 1 then
  begin
    eBillingUsers.Enabled := True;
    eBillingUsers.Color := clWindow;
    eBillingUsers.ItemIndex := 0;
  end;

//  el := eLog.Items.Add;
//  el.Caption := DateTimeToStr(Now) + ' - ' + UserName + ' - login';
//  eLog.Update;
end;}

{procedure TMainForm.OnBillingUserLogOut(const UserName: String);
var
  a,i: Integer;
//  el: TListItem;
begin
//  i := -1;
//  for a := 0 to eBillingUsers.Items.Count - 1 do
//    if eBillingUsers.Items[a].Caption = UserName then
//    begin
//      i := a;
//      Break;
//    end;
//  if i >= 0 then
//  begin
//    if eBillingUsers.ItemIndex = i then
//    begin
//      eBillingUsers.ItemIndex := -1;
//    end;
//
//    eBillingUsers.Items.Delete(i);
//    eBillingUsers.Update;
//
//    if eBillingUsers.Items.Count = 0 then
//    begin
//      eBillingUsers.Color := clBtnFace;
//      eBillingUsers.Enabled := False;
//    end;
//  end;

//  el := eLog.Items.Add;
//  el.Caption := DateTimeToStr(Now) + ' - ' + UserName + ' - logout';
//  eLog.Update;
end;}

procedure TMainForm.StartForceUserLogoutThreadInAllGateways(AUserName: String);
begin
  Gateway1.StartForceUserLogoutThread(AUserName);
  Gateway2.StartForceUserLogoutThread(AUserName);
  Gateway3.StartForceUserLogoutThread(AUserName);
  Gateway4.StartForceUserLogoutThread(AUserName);
end;

procedure TMainForm.btnLoginClick(Sender: TObject);
  begin
  SaveSetup;

  if xBindIP.Checked and (eAddress.Text='') then
  begin
    ShowMessage('Please, uncheck the "Bind to IP" option,'#13#10+
                'or enter your Network Card''s IP Address.');
    eAddress.SetFocus;
    Exit;
  end;
//  if ePort.Text='' then
//    begin
//    ShowMessage('Please, choose a Port for your Gateway.');
//    ePort.SetFocus;
//    Exit;
//    end;
//  if xISAPI.Checked and (eISAPI.Text='') then
//    begin
//    ShowMessage('Please, enter the PATH where you want to emulate the ISAPI DLL.');
//    eISAPI.SetFocus;
//    Exit;
//    end;

  if cbMainGate.Checked then
  begin
    GetDataProvider.GatewayLogOutStart;

    if GetDataProvider.SQLConnection.Connected then
      GetDataProvider.SQLConnection.Close;

    GetDataProvider.FStartForceUserLogoutThread := StartForceUserLogoutThreadInAllGateways;
    GetDataProvider.SQLConnection.ConnectionString := 'provider=SQLNCLI11;server=' + eSQLServer.Text+ ';User ID=sa;database=Vircess;uid=sa;Persist security info=True;pwd=2230897';
    GetDataProvider.SQLConnection.Connected := True;
    GetDataProvider.ServerLink1.Server := hsMain1;
    GetDataProvider.ServerLink2.Server := hsMain2;
    GetDataProvider.ServerLink3.Server := hsMain3;
    GetDataProvider.ServerLink4.Server := hsMain4;
    GetDataProvider.MainGateServerLink.Server := MainGateServer;
  //  GetDataProvider.LogMemo := LogMemo;
  //  GetDataProvider.OnUserLogin := OnBillingUserLogin;
  //  GetDataProvider.OnUserLogOut := OnBillingUserLogOut;

    hsMain1.StopListenNow;
    hsMain2.StopListenNow;
    hsMain3.StopListenNow;
    hsMain4.StopListenNow;

    MainGateServer.StopListenNow;
    PortalGateServer.StopListenNow;

    if xBindIP.Checked then
    begin
      hsMain1.ServerAddr := RtcString(Trim(eAddress.Text));
      hsMain2.ServerAddr := RtcString(Trim(eAddress.Text));
      hsMain3.ServerAddr := RtcString(Trim(eAddress.Text));
      hsMain4.ServerAddr := RtcString(Trim(eAddress.Text));

      MainGateServer.ServerAddr := RtcString(Trim(eAddress.Text));
    end
    else
    begin
      hsMain1.ServerAddr := '';
      hsMain2.ServerAddr := '';
      hsMain3.ServerAddr := '';
      hsMain4.ServerAddr := '';

      MainGateServer.ServerAddr := '';
    end;

    if cb80.Checked then
      hsMain1.Listen();
    if cb8080.Checked then
      hsMain2.Listen();
    if cb443.Checked then
      hsMain3.Listen();
    if cb5938.Checked then
      hsMain4.Listen();

    MainGateServer.Listen();
  end
  else
  begin
    GetDataProvider.GatewayLogOutStart;

    GetDataProvider.Gateway1 := Gateway1;
    GetDataProvider.Gateway2 := Gateway2;
    GetDataProvider.Gateway3 := Gateway3;
    GetDataProvider.Gateway4 := Gateway4;

    GetDataProvider.PortalGateServerLink.Server := PortalGateServer;

    HttpServer1.StopListenNow;
    HttpServer2.StopListenNow;
    HttpServer3.StopListenNow;
    HttpServer4.StopListenNow;

    MainGateServer.StopListenNow;
    PortalGateServer.StopListenNow;

    GetDataProvider.MainGateClientModule.Client := MainGateClient;
    GetDataProvider.ThisGatewayAddress := eAddress.Text;
    GetDataProvider.ThisGatewayMaxUsers := StrToInt(eMaxUsers.Text);

    if xBindIP.Checked then
    begin
      HttpServer1.ServerAddr := RtcString(Trim(eAddress.Text));
      HttpServer2.ServerAddr := RtcString(Trim(eAddress.Text));
      HttpServer3.ServerAddr := RtcString(Trim(eAddress.Text));
      HttpServer4.ServerAddr := RtcString(Trim(eAddress.Text));
      MainGateClient.ServerAddr := RtcString(Trim(eMainGate.Text));

      PortalGateServer.ServerAddr := RtcString(Trim(eAddress.Text));
    end
    else
    begin
      HttpServer1.ServerAddr := '';
      HttpServer2.ServerAddr := '';
      HttpServer3.ServerAddr := '';
      HttpServer4.ServerAddr := '';
      MainGateClient.ServerAddr := '';

      PortalGateServer.ServerAddr := '';
    end;

    Gateway1.AutoRegisterUsers := True; //not xNoAutoRegUsers.Checked;
    Gateway2.AutoRegisterUsers := True; //not xNoAutoRegUsers.Checked;
    Gateway3.AutoRegisterUsers := True; //not xNoAutoRegUsers.Checked;
    Gateway4.AutoRegisterUsers := True; //not xNoAutoRegUsers.Checked;

    if cb80.Checked then
      HttpServer1.Listen();
    if cb8080.Checked then
      HttpServer2.Listen();
    if cb443.Checked then
      HttpServer3.Listen();
    if cb5938.Checked then
      HttpServer4.Listen();

    GetDataProvider.GatewayReloginStart;

    PortalGateServer.Listen();
  end;

  btnLogin.Enabled := False;

  lblStatus.Caption := 'Preparing the Gateway ...';
  lblStatus.Update;

//  Gateway.SQLDisconnect;

//  HttpServer.ServerPort:=RtcString(Trim(ePort.Text));

//  if xISAPI.Checked then
//    Gateway.ModuleFileName:=RtcString(Trim(eISAPI.Text))+'/gate'
//  else
//    Gateway.ModuleFileName:='/$rdgate';

//  Gateway.SQLConnect;

  btnLogout.Enabled:=True;

  if Pages.ActivePage<>Page_Active then
    begin
    Page_Active.TabVisible:=True;
    Pages.ActivePage.TabVisible:=False;
    Pages.ActivePage:=Page_Active;
    end;

//  eUsers.Clear;
//  eUsers.Enabled:=False;
//  eUsers.Color:=clBtnFace;

  // A work-around for disapearing Close and Minimize buttons ...
  cTitleBar.Refresh;
  btnMinimize.Refresh;
  btnClose.Refresh;

//  lblStatus.Caption:='Gateway running on Port '+ePort.Text;
  lblStatus.Update;
  end;

procedure TMainForm.On_Error(const s: string);
  begin
  if Pages.ActivePage<>Page_Setup then
    begin
    Page_Setup.TabVisible:=True;
    Pages.ActivePage.TabVisible:=False;
    Pages.ActivePage:=Page_Setup;
    end;

  btnLogin.Enabled:=True;
  lblStatus.Caption:=s;
  lblStatus.Update;

//  MessageBeep(0);
  end;

procedure TMainForm.btnLogoutClick(Sender: TObject);
  begin
  if cbMainGate.Checked then
  begin

    hsMain1.StopListen;
    hsMain2.StopListen;
    hsMain3.StopListen;
    hsMain4.StopListen;

    MainGateServer.StopListenNow;
    PortalGateServer.StopListenNow;

   if GetDataProvider.SQLConnection.Connected then
      GetDataProvider.SQLConnection.Close;
  end
  else
  begin
    GetDataProvider.GatewayLogOutStart;

    HttpServer1.StopListenNow;
    HttpServer2.StopListenNow;
    HttpServer3.StopListenNow;
    HttpServer4.StopListenNow;
  end;

  btnLogout.Enabled:=False;

//  Gateway.ClearUserList; //Доделать
//  eUsers.Clear;
  //Gateway.SQLDisconnect;

  if Pages.ActivePage<>Page_Setup then
    begin
    Page_Setup.TabVisible:=True;
    Pages.ActivePage.TabVisible:=False;
    Pages.ActivePage:=Page_Setup;
    end;

  btnLogin.Enabled:=True;
  lblStatus.Caption:='Click "START" to start the Gateway.';
  lblStatus.Update;
  end;

procedure TMainForm.xSSLClick(Sender: TObject);
  begin
//  if xSSL.Checked and (ePort.Text='80') then
//    ePort.Text:='443'
//  else if not xSSL.Checked and (ePort.Text='443') then
//    ePort.Text:='80';
  end;

procedure TMainForm.btnMinimizeClick(Sender: TObject);
  begin
  TaskBarAddIcon;
  Application.Minimize;
  ShowWindow(Application.Handle, SW_HIDE);
  end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSetup;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  begin
  if (Pages.ActivePage=Page_Active) {and (eUsers.Items.Count>0)} then
    begin
//    if MessageDlg('Are you sure you want to close the Gateway?'#13#10+
//                  'There are users connected to this Gateway.'#13#10+
//                  'Closing the Gateway will disconnect them all.',
//                  mtWarning,[mbNo,mbYes],0)=mrYes then
//      begin
      BtnLogoutClick(Sender);
      TaskBarRemoveIcon;
      CanClose:=True;
//      end
//    else
//      CanClose:=False;
    end
  else
    begin
    BtnLogoutClick(Sender);
    TaskBarRemoveIcon;
    CanClose:=True;
    end;
  end;

procedure TMainForm.bLogoffUserClick(Sender: TObject);
begin
//  Gateway.ForceUserLogOut(eLogoff.Text);
  StartForceUserLogoutThreadInAllGateways(eLogoff.Text);
end;

procedure TMainForm.btnCloseClick(Sender: TObject);
  begin
  Close;
  end;

var
  LMouseX,LMouseY:integer;
  LMouseD:boolean=False;

procedure TMainForm.pTitlebarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
  LMouseD:=True;
  LMouseX:=X;LMouseY:=Y;
  end;

procedure TMainForm.pTitlebarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  begin
  if LMouseD then
    SetBounds(Left+X-LMouseX,Top+Y-LMouseY,Width,Height);
  end;

procedure TMainForm.pTitlebarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
  LMouseD:=False;
  end;

procedure TMainForm.LoadSetup;
  var
    CfgFileName:String;
    s:RtcString;
    s2:RtcByteArray;
    info:TRtcRecord;
    len:int64;
    len2:longint;
  begin
  s2:=nil;
  CfgFileName:= ChangeFileExt(AppFileName,'.inf');
  len:=File_Size(CfgFileName);
  if len>5 then
    begin
    s:=Read_File(CfgFileName,len-5,5);
    if s='@VCS@' then
      begin
      s2:=Read_FileEx(CfgFileName,len-4-5,4);
      Move(s2[0],len2,4);
      if (len2=len-4-5) then
        begin
        s := Read_File(CfgFileName,len-4-5-len2,len2,rtc_ShareDenyNone);
        DeCrypt(s, 'RTC Gateway 2.0');
        try
          info:=TRtcRecord.FromCode(s);
        except
          info:=nil;

          cbMainGate.Checked := True;
          cb80.Checked := True;
          cb8080.Checked := True;
          cb443.Checked := True;
          cb5938.Checked := True;
          end;
        if assigned(info) then
          begin
          try
            cbMainGate.Checked:=info.asBoolean['MainGate'];
            eMainGate.Text:=info.asText['MainGateAddress'];
            xBindIP.Checked:=info.asBoolean['Bind'];
            eAddress.Text:=info.asText['Address'];
            eMaxUsers.Text:=info.asText['MaxUsers'];
            cb80.Checked:=info.asBoolean['Port80'];
            cb8080.Checked:=info.asBoolean['Port8080'];
            cb443.Checked:=info.asBoolean['Port443'];
            cb5938.Checked:=info.asBoolean['Port5938'];
//            xSSL.Checked:=info.asBoolean['SSL'];
//            xISAPI.Checked:=info.asBoolean['ISAPI'];
//            eISAPI.Text:=info.asText['DLL'];
//            eSecureKey.Text:=info.asText['SecureKey'];
//            xNoAutoRegUsers.Checked:=info.asBoolean['NoAutoReg'];
          finally
            info.Free;
            end;
          end;
        end;
      end;
    end;

    eAddress.Enabled := xBindIP.Checked;
    if eAddress.Enabled then
      eAddress.Color := clWindow
    else
      eAddress.Color := clGray;
    eMainGate.Enabled := not cbMainGate.Checked;
    if eMainGate.Enabled then
      eMainGate.Color := clWindow
    else
      eMainGate.Color := clGray;
  end;

procedure TMainForm.SaveSetup;
  var
    CfgFileName:String;
    infos:RtcString;
    s2:RtcByteArray;
    info:TRtcRecord;
    len2:longint;
  begin
  info:=TRtcRecord.Create;
  try
    info.asBoolean['MainGate']:=cbMainGate.Checked;
    info.asString['MainGateAddress']:=RtcString(Trim(eMainGate.Text));
    info.asBoolean['Bind']:=xBindIP.Checked;
    info.asString['Address']:=RtcString(Trim(eAddress.Text));
    info.asString['MaxUsers']:=RtcString(Trim(eMaxUsers.Text));
    info.asBoolean['Port80']:=cb80.Checked;
    info.asBoolean['Port8080']:=cb8080.Checked;
    info.asBoolean['Port443']:=cb443.Checked;
    info.asBoolean['Port5938']:=cb5938.Checked;
//    info.asBoolean['SSL']:=xSSL.Checked;
//    info.asBoolean['ISAPI']:=xISAPI.Checked;
//    info.asString['DLL']:=RtcString(Trim(eISAPI.Text));
//    info.asString['SecureKey']:=RtcString(Trim(eSecureKey.Text));
//    info.asBoolean['NoAutoReg']:=xNoAutoRegUsers.Checked;
    infos:=info.toCode;
    Crypt(infos,'RTC Gateway 2.0');
  finally
    info.Free;
    end;

  CfgFileName:= ChangeFileExt(AppFileName,'.inf');
  SetLength(s2,4);
  len2:=length(infos);
  Move(len2,s2[0],4);
  infos:=infos+RtcBytesToString(s2)+'@VCS@';
  Write_File(CfgFileName,infos);
  end;

procedure TMainForm.xBindIPClick(Sender: TObject);
  begin
  eAddress.Enabled := xBindIP.Checked;
  if eAddress.Enabled then
    eAddress.Color := clWindow
  else
    eAddress.Color := clGray;
  end;

procedure TMainForm.xISAPIClick(Sender: TObject);
  begin
//  eISAPI.Enabled:=xISAPI.Checked;
//  if eISAPI.Enabled then eISAPI.Color:=clWindow
//  else eISAPI.Color:=clGray;
  end;

procedure TMainForm.btnInstallClick(Sender: TObject);
  begin
  SaveSetup;
  ShellExecute(0,'open',PChar(String(AppFileName)),'/INSTALL',nil,SW_SHOW);
  end;

procedure TMainForm.btnUninstallClick(Sender: TObject);
  begin
  ShellExecute(0,'open',PChar(String(AppFileName)),'/UNINSTALL',nil,SW_SHOW);
  end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
//  Gateway.ForceClearGet(eLogoff.Text);
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
//  Gateway.ForceClearPut(eLogoff.Text);
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
//  Gateway.ForceMsgClear(eLogoff.Text);
end;

procedure TMainForm.cb443Click(Sender: TObject);
begin
  if cbMainGate.Checked then
  begin
    if cb443.Checked then
      hsMain3.Listen(True)
    else
      hsMain3.StopListenNow();
  end
  else
  begin
    if cb443.Checked then
      HttpServer3.Listen(True)
    else
      HttpServer3.StopListenNow();
  end;
end;

procedure TMainForm.cb5938Click(Sender: TObject);
begin
  if cbMainGate.Checked then
  begin
    if cb5938.Checked then
      hsMain4.Listen(True)
    else
      hsMain4.StopListenNow();
  end
  else
  begin
    if cb5938.Checked then
      HttpServer2.Listen(True)
    else
      HttpServer2.StopListenNow();
  end;
end;

procedure TMainForm.cb8080Click(Sender: TObject);
begin
  if cbMainGate.Checked then
  begin
    if cb8080.Checked then
      hsMain2.Listen(True)
    else
      hsMain2.StopListenNow();
  end
  else
  begin
    if cb8080.Checked then
      HttpServer2.Listen(True)
    else
      HttpServer2.StopListenNow();
  end;
end;

procedure TMainForm.cb80Click(Sender: TObject);
begin
  if cbMainGate.Checked then
  begin
    if cb80.Checked then
      hsMain1.Listen(True)
    else
      hsMain1.StopListenNow();
  end
  else
  begin
    if cb80.Checked then
      HttpServer1.Listen(True)
    else
      HttpServer1.StopListenNow();
  end;
end;

procedure TMainForm.cbMainGateClick(Sender: TObject);
begin
  eMainGate.Enabled:= not cbMainGate.Checked;
  if eMainGate.Enabled then
    eMainGate.Color := clWindow
  else
    eMainGate.Color := clGray;
end;

procedure TMainForm.btnRunClick(Sender: TObject);
  begin
  SaveSetup;
  ShellExecute(0,'open','net',PChar('start '+RTC_GATEWAYSERVICE_NAME),nil,SW_SHOW);
  end;

procedure TMainForm.btnRestartServiceClick(Sender: TObject);
  begin
  ShellExecute(0,'open','net',PChar('stop '+RTC_GATEWAYSERVICE_NAME),nil,SW_SHOW);
  Sleep(5000); // Wait 5 seconds for the Service to stop
  SaveSetup;
  ShellExecute(0,'open','net',PChar('start '+RTC_GATEWAYSERVICE_NAME),nil,SW_SHOW);
  Sleep(5000); // Wait 5 seconds for the Service to start
  Close;
  end;

procedure TMainForm.btnSaveSetupClick(Sender: TObject);
  begin
  SaveSetup;
  end;

procedure TMainForm.btnStopClick(Sender: TObject);
  begin
  ShellExecute(0, 'open', 'net', PChar('stop ' + RTC_GATEWAYSERVICE_NAME), nil, SW_SHOW);
  end;

procedure TMainForm.rRegisterHostExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
//var
//  i, j: Integer;
//  fFound: Boolean;
//  GatewayRec: PGatewayServerRec;
begin
//  if Param.asString['Action'] = 'register' then
//  begin
//    fFound := False;
//    for i := 0 to Length(GatewayServerList) - 1 do
//      if (GatewayServerList[i]^.Address = Param.asString['Address'])
//        and (GatewayServerList[i]^.Port = Param.asString['Port']) then
//        begin
//          GatewayRec := GatewayServerList[i];
//          for j := 0 to GatewayRec^.Users.Count - 1 do
//            if GatewayRec^.Users[j] = Param.asString['user'] then
//            begin
//              fFound := True;
//              Break;
//            end;
//          if not fFound then
//            GatewayRec^.Users.Add(Param.asString['user']);
//        end;
//  end
//  else if Param.asString['Action'] = 'unregister' then
//  begin
//    for i := 0 to Length(GatewayList) - 1 do
//      if (GatewayList[i]^.Address = Param.asString['Address'])
//        and (GatewayList[i]^.Port = Param.asString['Port']) then
//        GatewayRec := GatewayList[i];
//        for j := 0 to GatewayRec^.Users.Count - 1 do
//          if GatewayRec^.Users[j] = Param.asString['user'] then
//          begin
//            GatewayRec^.Users.Delete(j);
//            Break;
//          end;
//  end;
end;

procedure TMainForm.DataProvider1CheckRequest(
  Sender: TRtcConnection);
begin
  with TRtcDataServer(Sender) do
    if Request.FileName='/' then
      Accept;
end;

procedure TMainForm.DataProvider1DataReceived(
  Sender: TRtcConnection);
begin
  with TRtcDataServer(Sender) do
    if Request.Complete then
      begin
      Write('<HTML><BODY>');
      Write('Vircess Gateway is up.<BR><BR>');
      Write('</BODY></HTML>');
      end;
end;

procedure TMainForm.HttpServer1ListenError(Sender: TRtcConnection; E: Exception);
begin
  if not Sender.inMainThread then
    Sender.Sync(HttpServer1ListenError,E)
  else
    On_Error('Error: '+E.Message);
end;

procedure TMainForm.HttpServer1ListenLost(Sender: TRtcConnection);
begin
  if not Sender.inMainThread then
    Sender.Sync(HttpServer1ListenLost)
  else
    On_Error('Gateway Listener Lost');
end;

procedure TMainForm.Gateway1SessionClosing(Sender: TRtcConnection);
begin
  Tag := Tag;
end;

procedure TMainForm.Gateway1UserLogin(const UserName: String);
var
  a: Integer;
  have: Boolean;
  el: TListItem;
begin
//  have := False;
//  for a := 0 to eUsers.Items.Count - 1 do
//    if eUsers.Items[a].Caption = UserName then
//      have := True;
//  if not have then
//  begin
//    el := eUsers.Items.Add;
//    el.Caption := UserName;
//    eUsers.Update;
//  end;
//  if eUsers.Items.Count = 1 then
//  begin
//    eUsers.Enabled := True;
//    eUsers.Color := clWindow;
//    eUsers.ItemIndex := 0;
//  end;
end;

procedure TMainForm.Gateway1UserLogout(const UserName: String);
var
  a,i: Integer;
begin
//  i := -1;
//  for a := 0 to eUsers.Items.Count - 1 do
//    if eUsers.Items[a].Caption = UserName then
//    begin
//      i := a;
//      Break;
//    end;
//  if i >= 0 then
//  begin
//    if eUsers.ItemIndex = i then
//    begin
//      eUsers.ItemIndex := -1;
//    end;
//
//    eUsers.Items.Delete(i);
//    eUsers.Update;
//
//    if eUsers.Items.Count = 0 then
//    begin
//      eUsers.Color := clBtnFace;
//      eUsers.Enabled := False;
//    end;
//  end;
end;

procedure TMainForm.GatewayUserPing(const UserName: string);
//var
//  i: Integer;
//  fFound: Boolean;
begin
//  fFound := False;
//  for i := 0 to LogMemo2.Lines.Count - 1 do
//    if Copy(LogMemo2.Lines[i], 0, 16) = Copy(UserName, 0, 16) then
//    begin
//      LogMemo2.Lines[i] := UserName;
//      fFound := True;
//    end;
//  if not fFound then
//    LogMemo2.Lines.Insert(0, UserName);
end;

procedure TMainForm.GatewayUserPingTimeout(const UserName: string);
begin
//  LogMemo2.Lines.Add(UserName);
end;

end.
