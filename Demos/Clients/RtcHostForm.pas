﻿ { Copyright (c) RealThinClient components
  - http://www.realthinclient.com }

unit RtcHostForm;

interface

{$INCLUDE rtcDefs.inc}

{$DEFINE ExtendLog}
{$DEFINE RtcViewer}

uses
  Windows, Messages, SysUtils, CommonData, System.Types, uProcess, ServiceMgr, Cromis.Comm.IPC, System.Hash, DisplaySettingsEx,
  Classes, Graphics, Controls, Forms, DateUtils, CommonUtils, WtsApi, uSysAccount, ClipbrdMonitor, uSetup,
  Dialogs, StdCtrls, ExtCtrls, ShellApi, rdFileTransLog, VirtualTrees.Types, SHDocVw, rtcpFileTransUI, Psapi, Winapi.SHFolder,
  Vcl.ComCtrls, Registry, Math, RtcIdentification, SyncObjs, System.Net.HTTPClient, System.Net.URLClient, ActiveX, ComObj, CommCtrl,
  rtcSystem, rtcInfo, uMessageBox, rtcScrUtils, IOUtils, uAcceptEula, ProgressDialog, ShlObj, RecvDataObject, SendDestroyToGateway,
  ChromeTabsTypes, ChromeTabsClasses, ChromeTabsControls, uUIDataModule, uChannelsUsage, uDMUpdate,

{$IFDEF IDE_XE3up}
  UITypes,
{$ENDIF}

  rtcLog, rtcCrypt,
  rtcThrPool, rtcWinLogon,
//  SasLibEx,

  RtcHostSvc, Clipbrd, RunElevatedSupport,

  rdFileTrans, rdChat, WinApi.WinSvc,

  dmSetRegion, rdSetClient, rdSetHost,
  rdDesktopView, rtcpDesktopControlUI, rtcpDesktopControl,

  rtcpDesktopConst, rtcpFileTrans,
  rtcpDesktopHost, rtcpChat,
  rtcPortalHttpCli, rtcPortalMod, rtcPortalCli, Buttons,
  Vcl.Imaging.pngimage, Vcl.Menus, System.ImageList, Vcl.ImgList,
  rtcConn, rtcDataCli, rtcHttpCli, rtcCliModule, rtcFunction, uHardware,
  RtcRegistrationForm, RtcGroupForm, RtcDeviceForm, VirtualTrees, uVircessTypes,
  Vcl.ToolWin,
  ColorSpeedButton, AboutForm, Vcl.AppEvnts, AlignedEdit, Vcl.Imaging.jpeg, uPowerWatcher,
  Idglobal, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdTCPServer, VirtualTrees.BaseAncestorVCL,
  VirtualTrees.BaseTree, VirtualTrees.AncestorVCL;

type
//  TSetHostGatewayClientActiveProc = procedure(AValue: Boolean);

  PPortalHostThread = ^TPortalHostThread;
  TPortalHostThread = class(TThread)
  private
    FDataModule: TDataModule;
    FUserName: String;
    FAction: String;
    FUID: String;
    FNeedRestartThread: Boolean;
    FGatewayClient: TRtcHttpPortalClient;
    FDesktopHost: TRtcPDesktopHost;
    FFileTransfer: TRtcPFileTransfer;
    FChat: TRtcPChat;
    FResult: TRtcResult;
    FCS: TCriticalSection;
    Gateway: String;
    Port: String;
    ProxyEnabled: Boolean;
    ProxyAddr: String;
    ProxyUserName: String;
    ProxyPassword: String;
    procedure FResultReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
  public
    constructor Create(CreateSuspended: Boolean; AUserName, AGateway, APort, AProxyAddr, AProxyUserName, AProxyPassword: String; AProxyEnabled: Boolean); overload;
    destructor Destroy; override;
    procedure Restart(AGateway: String = '');
    procedure GetFilesFromClipboard(ACurExplorerHandle: THandle; ACurExplorerDir: String);
    procedure ChangeProxyParams(AProxyEnabled: Boolean; AProxyAddr, AProxyUserName, AProxyPassword: String);
    procedure SendPing;
  protected
    procedure Execute; override;
//  protected
//    procedure ProcessMessage(MSG: TMSG);
  end;

  PPortalThread = ^TPortalThread;
  TPortalThread = class(TThread)
  private
    FDataModule: TDataModule;
    FUserName: String;
    FUserPass: String;
    FUserToConnect: String;
    FAction: String;
    FUIDFull, FUID: String;
    FGateway: String;
    FLoggedIn: Boolean;
    FAccountUID, FDeviceId, FDeviceUID: String;
    FGatewayClient: TRtcHttpPortalClient;
    FDesktopControl: TRtcPDesktopControl;
    FFileTransfer: TRtcPFileTransfer;
    FChat: TRtcPChat;
    FNeedCloseUI: Boolean;
    FResult: TRtcResult;
    { Private declarations }
    procedure SendPing;
  public
    constructor Create(CreateSuspended: Boolean; AAction, AUserName, AUserPass, AUserToConnect, AGateway: String; AStartLockedStatus: Integer; AStartServiceStarted: Boolean; UIVisible: Boolean); overload;
    destructor Destroy; override;
    procedure SetNeedCloseUI(AValue: Boolean);
  protected
    procedure Execute; override;
//    procedure WndProc(var Message: TMessage);
//    procedure ProcessMessage(MSG: TMSG);
  end;

  PPortalConnection = ^TPortalConnection;
  TPortalConnection = record
    ThreadID: Cardinal;
    Thread: TPortalThread;
    UserName: String; //Initial connection user
    UserPass: String;
    ID: String; //User to connent
    Action: String;
    DataModule: TUIDataModule;
    UIHandle: THandle;
    StartLockedState: Integer;
    StartServiceStarted: Boolean;
  end;

  TExecuteProc = procedure of Object;

  TStatusUpdateThread = class(TThread)
  private
    FStatusUpdateProc: TExecuteProc;
  protected
    constructor Create(CreateSuspended: Boolean;
      StatusUpdateProc: TExecuteProc); overload;
    procedure Execute; override;
  end;

  {TPolygon class represents a polygon. It containes points that define a polygon and
  caches fill range list for fast polygon filling.}
{  TPolygon = class
  private
    FPoints: array of TPoint;
    FStartY: Integer;
    FRangeList: TRangeListArray;

    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    function GetPoint(Index: Integer): TPoint;
    procedure SetPoint(Index: Integer; APoint: TPoint);
  protected
    //Initializes range list
    procedure RangeListNeeded;
    function GetFillRange(Y: Integer): TRangeList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AssignPoints(APoints: array of TPoint);
    procedure Offset(dx, dy: Integer);
    property Count: Integer read GetCount write SetCount;
    property Points[Index: Integer]: TPoint read GetPoint write SetPoint;
  end;}

  TMainForm = class(TForm)
    sStatus1: TShape;
    sStatus2: TShape;
    PDesktopControl: TRtcPDesktopControl;
    tHcAccountsReconnect: TTimer;
    pmIconMenu: TPopupMenu;
    miShowForm: TMenuItem;
    N1: TMenuItem;
    miSettings: TMenuItem;
    miRegularAccess: TMenuItem;
    N2: TMenuItem;
    miWebSite: TMenuItem;
    miUpdate: TMenuItem;
    miAbout: TMenuItem;
    miExitSeparator: TMenuItem;
    miExit: TMenuItem;
    pmAccount: TPopupMenu;
    miAddDevice: TMenuItem;
    miAddGroup: TMenuItem;
    N4: TMenuItem;
    miAccLogOut: TMenuItem;
    cmAccounts: TRtcClientModule;
    hcAccounts: TRtcHttpClient;
    rActivate: TRtcResult;
    ilStatus: TImageList;
    pmDevice: TPopupMenu;
    miChange: TMenuItem;
    miDelete: TMenuItem;
    miDesktopControl: TMenuItem;
    miFileTrans: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    rDeleteDevice: TRtcResult;
    bhMain: TBalloonHint;
    pmGroup: TPopupMenu;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    N9: TMenuItem;
    tInternetActive: TTimer;
    rGetPartnerInfo: TRtcResult;
    pInMain: TPanel;
    lblStatus: TLabel;
    iStatus1: TImage;
    iStatus2: TImage;
    iStatus3: TImage;
    iStatus4: TImage;
    pLeft: TPanel;
    Bevel1: TBevel;
    Label3: TLabel;
    Label4: TLabel;
    Image1: TImage;
    LabelPP1: TLabel;
    LabelPP2: TLabel;
    LabelPP3: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    LabelPP4: TLabel;
    eUserName: TAlignedEdit;
    pRight: TPanel;
    Image2: TImage;
    lDesktopControl: TLabel;
    lFileTrans: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    ePartnerID: TComboBox;
    rbDesktopControl: TRadioButton;
    rbFileTrans: TRadioButton;
    pcDevAcc: TPageControl;
    pAccount: TPanel;
    Label6: TLabel;
    Label5: TLabel;
    lRestorePassword: TLabel;
    Label11: TLabel;
    eAccountUserName: TEdit;
    eAccountPassword: TEdit;
    cbRememberAccount: TCheckBox;
    pDevices: TPanel;
    GridPanel1: TGridPanel;
    twDevices: TVirtualStringTree;
    eDeviceName: TEdit;
    iDeviceOnline: TImage;
    iDeviceOffline: TImage;
    ePassword: TAlignedEdit;
    iRegPassState: TImage;
    LabelPP5: TLabel;
    iRegPassYes: TImage;
    iRegPassNo: TImage;
    TimerClient: TRtcHttpClient;
    pingTimer: TTimer;
    resPing: TRtcResult;
    resTimerLogin: TRtcResult;
    resLogout: TRtcResult;
    resLogin: TRtcResult;
    TimerModule: TRtcClientModule;
    HostTimerClient: TRtcHttpClient;
    HostTimerModule: TRtcClientModule;
    resHostLogin: TRtcResult;
    resHostLogout: TRtcResult;
    resHostTimerLogin: TRtcResult;
    resHostTimer: TRtcResult;
    resHostPing: TRtcResult;
    resHostPassUpdate: TRtcResult;
    pmPassword: TPopupMenu;
    nNewRandomPass: TMenuItem;
    nCopyPass: TMenuItem;
    N3: TMenuItem;
    resGetState: TRtcResult;
    btnNewConnection: TColorSpeedButton;
    iAppIconOnline: TImage;
    iAppIconOffline: TImage;
    iBkgLeft: TImage;
    btnAccountLogin: TColorSpeedButton;
    rHostLockedStateUpdate: TRtcResult;
    tCheckLockedState: TTimer;
    rGetHostLockedState: TRtcResult;
    tConnLimit: TTimer;
    tStatus: TTimer;
    tIconRefresh: TTimer;
    btnAccount: TColorSpeedButton;
    mmMenu: TMainMenu;
    N5: TMenuItem;
    mmiSettings: TMenuItem;
    N10: TMenuItem;
    mmiService: TMenuItem;
    mmiSeparator2: TMenuItem;
    mmiServiceInstall: TMenuItem;
    mmiServiceStartStop: TMenuItem;
    mmiServiceUninstall: TMenuItem;
    N17: TMenuItem;
    Vircess1: TMenuItem;
    N18: TMenuItem;
    N19: TMenuItem;
    N20: TMenuItem;
    N21: TMenuItem;
    eConsoleID: TAlignedEdit;
    lConsoleID: TLabel;
    tCheckServiceStartStop: TTimer;
    tDelayedStatus: TTimer;
    tTimerClientReconnect: TTimer;
    tHostTimerClientReconnect: TTimer;
    tPClientReconnect: TTimer;
    lRegistration: TLabel;
    miLogFiles: TMenuItem;
    N11: TMenuItem;
    tActivateHost: TTimer;
    ApplicationEvents: TApplicationEvents;
    rDestroyClient: TRtcResult;
    Button4: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    bSetup: TColorSpeedButton;
    pBtnSetup: TPanel;
    bGetUpdate: TColorSpeedButton;
    rGetPartnerInfoReconnect: TRtcResult;
    tsIncomes: TTabSheet;
    tsMyDevices: TTabSheet;
    GridPanel2: TGridPanel;
    twIncomes: TVirtualStringTree;
    pBtnCloseAllIncomes: TPanel;
    bCloseAllIncomes: TColorSpeedButton;
    rManualLogout: TRtcResult;
    tFoldForm: TTimer;
    Button5: TButton;
    miChannelsUsage: TMenuItem;
    tCheckUpdateStatus: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMinimizeClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    { Private-Deklarationen }
//    procedure WMLogEvent(var Message: TMessage); message WM_LOGEVENT;
    procedure WMTaskbarEvent(var Message: TMessage); message WM_TASKBAREVENT;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMWTSSESSIONCHANGE(var Message: TMessage); message WM_WTSSESSION_CHANGE;
//    procedure WMActivate(var Message: TMessage); message WM_ACTIVATE;
//    procedure WMBlockInput_Message(var Message: TMessage); message WM_BLOCK_INPUT_MESSAGE;
    procedure WMDragFullWindows_Message(var Message: TMessage); message WM_DRAG_FULL_WINDOWS_MESSAGE;
//    procedure Broadcast_Logoff(var Message: TMessage); message WM_BROADCAST_LOGOFF;
    // declare our DROPFILES message handler
//    procedure AcceptFiles( var msg : TMessage ); message WM_DROPFILES;
    procedure WMQueryEndSession(var Msg : TWMQueryEndSession); message WM_QueryEndSession;
    procedure btnSettingsClick(Sender: TObject);
    procedure cPriorityChange(Sender: TObject);
    procedure btnInstallClick(Sender: TObject);
    procedure btnUninstallClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);

    procedure PClientLogIn(Sender: TAbsPortalClient);
    procedure PClientParams(Sender: TAbsPortalClient; const Data: TRtcValue);
    procedure PClientStart(Sender: TAbsPortalClient; const Data: TRtcValue);
    procedure PClientLogOut(Sender: TAbsPortalClient);
    procedure PClientError(Sender: TAbsPortalClient; const Msg:string);
    procedure PClientFatalError(Sender: TAbsPortalClient; const Msg:string);

    procedure PFileTransExplorerNewUI(Sender: TRtcPFileTransfer; const user:string);
    procedure PFileTransExplorerNewUI_HideMode(Sender: TRtcPFileTransfer; const user:string);
    procedure PFileTransferLogUI(Sender: TRtcPFileTransfer; const user: String);
    procedure PChatNewUI(Sender: TRtcPChat; const user:string);
    procedure PDesktopControlNewUI(Sender: TRtcPDesktopControl;
      const user: String);
    procedure PModuleUserJoined(Sender: TRtcPModule; const user:string);
    procedure PModuleUserLeft(Sender: TRtcPModule; const user:string);

    procedure PClientStatusPut(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);
    procedure PClientStatusGet(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);

    procedure btnGatewayClick(Sender: TObject);
    procedure eUserNameChange(Sender: TObject);
    procedure ePasswordChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure eRealNameChange(Sender: TObject);
    procedure btnRestartServiceClick(Sender: TObject);
    procedure cPriority_ControlChange(Sender: TObject);
    procedure btnNewConnectionClick(Sender: TObject);
    procedure xHideWallpaperClick(Sender: TObject);
    procedure xReduceColorsClick(Sender: TObject);
    procedure cbControlModeChange(Sender: TObject);
    procedure xKeyMappingClick(Sender: TObject);
    procedure xForceCursorClick(Sender: TObject);
    procedure xSmoothViewClick(Sender: TObject);
    procedure PClientUserLoggedIn(Sender: TAbsPortalClient; const User: string);
    procedure PClientUserLoggedOut(Sender: TAbsPortalClient;
      const User: string);
    procedure rbDesktopControlClick(Sender: TObject);
    procedure rbFileTransClick(Sender: TObject);
    procedure rbChatClick(Sender: TObject);
    procedure btnShowMyDesktopClick(Sender: TObject);
    procedure tHcAccountsReconnectTimer(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miWebSiteClick(Sender: TObject);
    procedure miShowFormClick(Sender: TObject);
    procedure btnAccountLoginClick(Sender: TObject);
    procedure miAccLogOutClick(Sender: TObject);
    procedure rActivateReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure lRegistrationClick(Sender: TObject);
    procedure eUserNameDblClick(Sender: TObject);
    procedure ePartnerIDKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lDesktopControlClick(Sender: TObject);
    procedure lFileTransClick(Sender: TObject);
    procedure lHelpClick(Sender: TObject);
    procedure miWebSite2DrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      Selected: Boolean);
    procedure Label11Click(Sender: TObject);
    procedure bAccount0Click(Sender: TObject);
    procedure miAddGroupClick(Sender: TObject);
    procedure rDeleteDeviceReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure miDeleteClick(Sender: TObject);
    procedure miChangeClick(Sender: TObject);
    procedure twDevicesMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure twDevicesMouseLeave(Sender: TObject);
    procedure hcAccountsDisconnect(Sender: TRtcConnection);
    procedure twDevicesMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure twDevicesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure hcAccountsConnectError(Sender: TRtcConnection; E: Exception);
    procedure hcAccountsConnectFail(Sender: TRtcConnection);
    procedure hcAccountsConnect(Sender: TRtcConnection);
    procedure hcAccountsConnectLost(Sender: TRtcConnection);
    procedure twDevicesBeforeItemPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
      var CustomDraw: Boolean);
    procedure twDevicesCompareNodes(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure eDeviceNameChange(Sender: TObject);
    procedure miAddDeviceClick(Sender: TObject);
    procedure miDesktopControlClick(Sender: TObject);
    procedure tInternetActiveTimer(Sender: TObject);
    procedure rGetPartnerInfoReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure miFileTransClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lRestorePasswordClick(Sender: TObject);
    procedure N11DrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
      Selected: Boolean);
    procedure LabelPP5Click(Sender: TObject);
    procedure pingTimerTimer(Sender: TObject);
    procedure resPingReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure resTimerLoginReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure resLoginReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure msgHostTimerTimer(Sender: TObject);
    procedure TimerModuleResponseAbort(Sender: TRtcConnection);
    procedure StartAccountLogin;
    procedure StartHostLogin;
    procedure resLogoutReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure HostTimerModuleResponseAbort(Sender: TRtcConnection);
    procedure resHostLoginReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure resHostTimerLoginReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure resHostTimerReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
//    procedure resHostPingReturn(Sender: TRtcConnection; Data,
//      Result: TRtcValue);
//    procedure HostPingTimerTimer(Sender: TObject);
    procedure nNewRandomPassClick(Sender: TObject);
    procedure nCopyPassClick(Sender: TObject);
    procedure aFeedBackExecute(Sender: TObject);
    procedure rActivateRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure eAccountUserNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure eAccountUserNameKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure twDevicesFocusChanged(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex);
    procedure btnNewConnectionMouseLeave(Sender: TObject);
    procedure btnNewConnectionMouseEnter(Sender: TObject);
    procedure aAboutExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tCheckLockedStateTimer(Sender: TObject);
    procedure rGetHostLockedStateReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure tConnLimitTimer(Sender: TObject);
    procedure tStatusTimer(Sender: TObject);
    procedure rGetPartnerInfoRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure aMinimizeExecute(Sender: TObject);
    procedure aCloseExecute(Sender: TObject);
    procedure rGetHostLockedStateRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure twDevicesGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure tIconRefreshTimer(Sender: TObject);
    procedure cbCloseClick(Sender: TObject);
    procedure cbMinClick(Sender: TObject);
    procedure bDevicesMouseEnter(Sender: TObject);
    procedure bDevicesMouseLeave(Sender: TObject);
    procedure PDesktopHostQueryAccess(Sender: TRtcPModule; const User: string;
      var Allow: Boolean);
    procedure cmMainMenuColorChange(Sender: TObject);
    procedure aServiceInstallExecute(Sender: TObject);
    procedure aServiceUninstallExecute(Sender: TObject);
    procedure aServiceStartStopExecute(Sender: TObject);
    procedure PDesktopHostHaveScreeenChanged(Sender: TObject);
    procedure twDevicesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure eConsoleIDDblClick(Sender: TObject);
    procedure tCheckServiceStartStopTimer(Sender: TObject);
    procedure tDelayedStatusTimer(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure tTimerClientReconnectTimer(Sender: TObject);
    procedure TimerClientConnect(Sender: TRtcConnection);
    procedure TimerClientDisconnect(Sender: TRtcConnection);
    procedure HostTimerClientConnect(Sender: TRtcConnection);
    procedure HostTimerClientDisconnect(Sender: TRtcConnection);
    procedure tPClientReconnectTimer(Sender: TObject);
    procedure tHostTimerClientReconnectTimer(Sender: TObject);
    procedure lRegistrationMouseEnter(Sender: TObject);
    procedure lRegistrationMouseLeave(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure pmIconMenuPopup(Sender: TObject);
    procedure hcAccountsReconnect(Sender: TRtcConnection);
    procedure hcAccountsException(Sender: TRtcConnection; E: Exception);
    procedure miLogFilesClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure tActivateHostTimer(Sender: TObject);
    procedure ApplicationEventsRestore(Sender: TObject);
    procedure ePartnerIDDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure TimerClientConnectError(Sender: TRtcConnection; E: Exception);
    procedure Button3Click(Sender: TObject);
    procedure resLoginRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure Button4Click(Sender: TObject);
    procedure bSetupMouseEnter(Sender: TObject);
    procedure bSetupMouseLeave(Sender: TObject);
    procedure bSetupClick(Sender: TObject);
    procedure bGetUpdateClick(Sender: TObject);
    procedure rGetPartnerInfoReconnectReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure twIncomesBeforeItemPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
      var CustomDraw: Boolean);
    procedure twIncomesDblClick(Sender: TObject);
    procedure twIncomesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure twIncomesMouseLeave(Sender: TObject);
    procedure twIncomesMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure bCloseAllIncomesMouseEnter(Sender: TObject);
    procedure bCloseAllIncomesMouseLeave(Sender: TObject);
    procedure bCloseAllIncomesClick(Sender: TObject);
    procedure tFoldFormTimer(Sender: TObject);
    procedure eAccountPasswordChange(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure miChannelsUsageClick(Sender: TObject);
    procedure bGetUpdateMouseEnter(Sender: TObject);
    procedure bGetUpdateMouseLeave(Sender: TObject);
    procedure tCheckUpdateStatusTimer(Sender: TObject);
  protected

//    FAutoRun: Boolean;
    DesktopCnt: Integer;

    FScreenLockedState: Integer;
//    FHostGatewayClientActive: Boolean;
    DelayedStatus: String;
    FStatusUpdateThread: TStatusUpdateThread;
    tPHostThread: TPortalHostThread;
    FUpdateAvailable: Boolean;
    FProgressDialogsList: TList;

    PendingRequests: TList;
    PortalConnectionsList: TList;

    tDMUpdate: TDMUpdateThread;

    function FormatID(AID: String): String;
    function ConnectedToAllGateways: Boolean;
    function GetUniqueString: String;
    function GetUserDescription(aUserName: String): String;
    function GetUserPassword(aUserName: String): String;
    function AddPendingRequest(uname, desc, action: String; fIsReconnection: Boolean): PPendingRequestItem;
    procedure DeletePendingRequest(uname, action: String);
    function GetPendingItem(uname: String): PPendingRequestItem; overload;
    function GetPendingItem(uname, action: String): PPendingRequestItem; overload;
    function PartnerIsPending(uname, action, gateway: String): Boolean; overload;
    function PartnerIsPending(uname, action: String; fIsReconnection: Boolean): Boolean; overload;
    function PartnerIsPending(uname: String): Boolean; overload;
    procedure ChangePendingRequestUser(action, userFrom, userTo: String);
//    procedure DeletePendingRequests(uname: String);
    procedure DeleteAllPendingRequests;
    procedure DeleteLastPendingItem;
    function GetCurrentPendingItemUserName: String;
    function GetPendingRequestsCount: Integer;

    function CheckService(bServiceFilename: Boolean = True {False = Service Name} ): String;
//
    procedure AddPortalConnection(AThread: TPortalThread; AThreadID: Cardinal; AAction, AUserName, AUserPass, AUserToConnect: String; AStartLockedState: Integer; AStartServiceStarted: Boolean);
    function GetPortalConnection(AAction: String; AUserName: String): PPortalConnection;
    procedure RemovePortalConnection(AID, AAction: String; ACloseFUI: Boolean);

    procedure StartFileTransferring(AUser, AUserName, APassword: String; ANeedGetPass: Boolean = False);
    function CheckAccountFields: Boolean;
//    function IsScreenSaverRunning: Boolean;
    procedure SetScreenLockedState(AValue: Integer);
//    procedure CheckSAS(value : Boolean; name : String);

    procedure OnUIOpen(UserName, Action: String; var IsPending, fIsReconnection: Boolean);
    procedure OnUIClose(AAction, AUserName: String);

    procedure OnCustomFormOpen(AForm: PForm);
    procedure OnCustomFormClose;

//    function GetHostGatewayClientActive: Boolean;
//    procedure SetHostGatewayClientActive(AValue: Boolean);

    procedure AddHistoryRecord(username, userdesc: String);
    procedure AddPasswordsRecord(username, userpass: String);

//    function RunHTTPCall(verb, url, path, data: String): String;
//    procedure CheckUpdates;

    procedure OnProgressDialogCancel(Sender: TObject);
    procedure OnDesktopHostNotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend);
  public
    { Public declarations }
//    SilentMode: Boolean;
    LoggedIn: Boolean;

    ReqCnt1, ReqCnt2: Integer;
    FCurStatus: Integer;
    TaskBarIcon: Boolean;

    AccountName, AccountUID: String;
    DeviceId, DeviceUID, ConsoleId, ConsoleUID: String;
    HighLightedNode: PVirtualNode;

    ProxyOption: Integer;
    PermanentPassword, SessionPassword, AccountPassword: String;
//    OnlyAdminChanges: Boolean;
    StoreHistory: Boolean;
    StorePasswords: Boolean;

    SettingsFormOpened: Boolean;

    do_notify: Boolean;
    myCheckTime: TDateTime;
//    myHostCheckTime: TDateTime;

    isClosing: Boolean;

    LastFocusedUID: String;

    FormMinimized: Boolean;

    PowerWatcher: TPowerWatcher;

    FRegisteredSessionNotification: Boolean;

    OpenedModalForm: PForm;
    PassForm: TfIdentification;

    function GetCurrentExplorerDirectory(var ADir: String; var AHandle: THandle): Boolean;
    procedure SetFilesToClipboard(var Message: TMessage); message WM_SET_FILES_TO_CLIPBOARD;
    procedure OnGetCbrdFilesData(Sender: TDataObject; AUserName: String);

    procedure DoPowerPause;
    procedure DoPowerResume;

//    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure SetIDContolsVisible;
//    procedure SetHostActive;

//    NCControls : TNCControls;

//    procedure UpdateButtons;

//    procedure make_notify(uname, ntype: string);

    // Load and Save Window Positions
//    function LoadWindowPosition(Form: TForm; FormName: String; sizeable:boolean=False):boolean;
//    procedure SaveWindowPosition(Form: TForm; FormName: String; sizeable:boolean=False);

    function PartnerNeedHideWallpaper(AUserName: String): Boolean;
    function PartnerGetQualitySetting(AUserName: String): Integer;
    procedure LoadSetup(RecordType: String);
    procedure SaveSetup;
    procedure GeneratePassword;
    procedure ActivateHost;
//    procedure ConnectToGateway;
    procedure AccountLogOut(Sender: TObject);
    procedure HostLogOut;

    procedure TaskBarAddIcon;
    procedure TaskBarIconUpdate(AIsOnline: Boolean);
    procedure TaskBarRemoveIcon;

    procedure DrawExpandButton(AStringTree: TVirtualStringTree; Canvas: TCanvas; ARect: TRect; Node: PVirtualNode; AColor: TColor);
    procedure DrawCloseButton(AStringTree: TVirtualStringTree; Canvas: TCanvas; ARect: TRect; Node: PVirtualNode; AColor: TColor);
    procedure DrawImage(AStringTree: TVirtualStringTree; Canvas: TCanvas; NodeRect: TRect; ImageIndex: Integer);
    function NodeByUID(const aTree:TVirtualStringTree; const anUID:String): PVirtualNode;
    function NodeByID(const aTree: TVirtualStringTree; const aID: String): PVirtualNode;

    procedure UpdateOnSuccessCheck(Sender: TObject);
    procedure SetConnectedState(fConnected: Boolean);
//    procedure WndProc(var Msg : TMessage); override;
    function GetSelectedGroup(): PVirtualNode;
    function GetGroupByUID(UID: String): PVirtualNode;
    procedure SetProxyFromIE;
    function GetStatus: Integer;
    procedure SetStatus(Status: Integer);
    procedure UpdateStatus;
    function AddDotsToString(sCurString: String): String;
    procedure ShowDevicesPanel;
    procedure ShowSettingsForm(APage: String);
    function GetAutoUpdateSetting: Boolean;
    function SendStartUpdateToService: Boolean;
    function SendSettingsToService(ANewPermanentPassword: String; ASendPassword, AAutomaticUpdate: Boolean): Boolean;
    function GetUpdateProgressFromService(var AUpdateStatus, AProgress: Integer): Boolean;
//    procedure SettingsFormOnResult(sett: TrdClientSettings);
//    procedure SetAutoRunToRegistry(AValue: Boolean);
    procedure ShowPermanentPasswordState();
    procedure FriendList_Status(uname: String; status: Integer);
    function GetUserNameByID(uname: String): String;
    procedure Locked_Status(uname: String; aLockedStatus: Integer; aServiceStarted: Boolean);
    procedure SendPasswordsToGateway();
    procedure SendLockedStateToGateway;
    function IsValidDeviceID(const uname: String): Boolean;
    procedure ConnectToPartnerStart(UserName, UserDesc, UserPass, Action: String);
    procedure ReconnectToPartnerStart(UserName, UserDesc, UserPass, Action: String);
    procedure OnClosePassForm(Sender: TObject);
//    function GetDeviceStatus(uname: String): Integer;
    function GetDeviceInfo(uname: String): PDeviceData;
    procedure DoAccountLogin;
    procedure DoGetDeviceState(Account, User, Pass, Friend: String);
//    function DoElevatedTask(const AHost, AParameters: String; AWait: Boolean): Cardinal;
//    procedure CreateParams(var Params: TCreateParams); override;
    property ScreenLockedState: Integer read FScreenLockedState write SetScreenLockedState;
//    function Block_UserInput_Hook(fBlockInput: Boolean): Boolean;
//    function Block_ZOrder_Hook(fBlock: Boolean): Boolean;
//    procedure SetStatusString(AStatus: String; AEnableTimer: Boolean = False);

    procedure EnableDragFullWindows;
    procedure RestoreDragFullWindows;

    procedure SetStatusStringDelayed(AStatus: string; AInterval: Integer = 2000);

    procedure ShowMessageBox(AText, ACaption, AType, AUID: string);
    procedure ShowAboutForm;
    procedure DoDeleteDeviceGroup(AUID: String);
    procedure SendManualLogoutToControl(AAction, AControlID, AHostID: String);
    procedure DoExit;
    procedure CloseAllActiveUI;

    procedure ChangePort(AClient: TRtcHttpClient);
    procedure ChangePortP(AClient: TAbsPortalClient);

    procedure DesktopHostFileTransferOnNewUI(Sender: TRtcPFileTransfer; const user: String);

    //procedure SetServiceMenuAttributes;

    property CurStatus: Integer read GetStatus write SetStatus;

      {Returns fill range list for specified Y coordinate. It calculates intersection
      points with specified scanline (at Y coordinates).}
    procedure Polygon_GetFillRange(const Points: array of TPoint; Y: Integer;
      out ARangeList: TRangeList);
    {Returns bounds of polygon}
    function Polygon_GetBounds(const Points: array of TPoint): TRect;
    {Returns True if point lies inside polygon}
    function Polygon_PtInside(const Points: array of TPoint; Pt: TPoint): Boolean;
    procedure FillPolygon(ACanvas: TCanvas; APoints: array of TPoint; AColor: TColor);

  //  procedure TransStretchDraw(ACanvas: TCanvas; const Rect: TRect; SRC: TBitmap; TransParentColor: TColor);
  //  function ExecAndWait(const FileName, Params: ShortString; const WinState: Word): boolean;
//    property HostGatewayClientActive: Boolean read FHostGatewayClientActive write SetHostGatewayClientActive;

    function AddProgressDialog(ATaskId: TTaskId; AUserName: String): PProgressDialogData;
    function GetProgressDialogData(ATaskId: TTaskId): PProgressDialogData; overload;
    function GetProgressDialogData(AProgressDialog: PProgressDialog): PProgressDialogData; overload;
    procedure RemoveProgressDialog(ATaskId: TTaskId);
    procedure RemoveProgressDialogByValue(AProgressDialog: PProgressDialog);
    procedure RemoveProgressDialogByUserName(AUserName: String);

    procedure AddIncomeConnection(AAction, AID, AUserName, AUserDesc: String);
    procedure RemoveIncomeConnection(AUserName: String);
    function GetIncomeConnectionsCount: Integer;
    function IsIncomeConnectionExists(AID, AAction: String): Boolean;
  end;

//type
//  TBlankDllHookProc = procedure (switch: Boolean); stdcall;

  procedure DisablePowerChanges;
  procedure RestorePowerChanges;
  function GetUniqueString: String;


  function GetShellWindow: HWND; stdcall; external 'user32.dll' name 'GetShellWindow';

const
  VCS_MAGIC_NUMBER = 777;
  MAX_CONNECTIONS_PENDING_IN_MIMUTE = 20;

  STATUS_NO_CONNECTION = 0;
  STATUS_ACTIVATING_ON_MAIN_GATE = 1;
  STATUS_CONNECTING_TO_GATE = 2;
  STATUS_READY = 3;
  STATUS_OLD_VERSION = 4;

  WH_MOUSE_LL = 14; // Используется для хука на низком уровне для мыши

var
  MainForm: TMainForm;
  BlockInputHook_Keyboard, BlockInputHook_Mouse, BlockZOrderHook: HHOOK;
  CurConnectionsPendingMinuteCount: Cardinal;
  DateAllowConnectionPending: TDateTime;
  PowerStateSaved, ActivationInProcess, AccountLoginInProcess: Boolean;
  LowPowerState, PowerOffState, ScreenSaverState: Integer;
  UseConnectionsLimit: Boolean = False;
  ChangedDragFullWindows: Boolean = False;
  OriginalDragFullWindows: LongBool = True;
  DeviceDisplayName: String;
  CS_GW, CS_Status, CS_Pending, CS_ActivateHost, CS_HostGateway, CS_Incoming: TCriticalSection;
  LastActiveExplorerHandle: THandle;
  CB_Monitor: TClipbrdMonitor;
  DesktopsForm: TrdDesktopViewer;

implementation

{$R *.dfm}

function TMainForm.AddProgressDialog(ATaskId: TTaskId; AUserName: String): PProgressDialogData;
begin
  New(Result);
  Result^.taskId := ATaskId;
  New(Result^.ProgressDialog);
  Result^.ProgressDialog^ := TProgressDialog.Create(Self);
  Result^.UserName := AUserName;

  FProgressDialogsList.Add(Result);
end;

function TMainForm.GetProgressDialogData(ATaskId: TTaskId): PProgressDialogData;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to FProgressDialogsList.Count - 1 do
    if PProgressDialogData(FProgressDialogsList[i])^.taskId = ATaskId then
    begin
      Result := FProgressDialogsList[i];
      Exit;
    end;
end;

function TMainForm.GetProgressDialogData(AProgressDialog: PProgressDialog): PProgressDialogData;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to FProgressDialogsList.Count - 1 do
    if PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^ = AProgressDialog^ then
    begin
      Result := FProgressDialogsList[i];
      Exit;
    end;
end;

procedure TMainForm.RemoveProgressDialog(ATaskId: TTaskId);
var
  i: Integer;
begin
  i := FProgressDialogsList.Count - 1;
  while i >= 0 do
  begin
    if PProgressDialogData(FProgressDialogsList[i])^.taskId = ATaskId then
    begin
      FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
      Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
      Dispose(FProgressDialogsList[i]);
      FProgressDialogsList.Delete(i);
      Break;
    end;

    i := i - 1;
  end;
end;

procedure TMainForm.RemoveProgressDialogByValue(AProgressDialog: PProgressDialog);
var
  i: Integer;
begin
  i := FProgressDialogsList.Count - 1;
  while i >= 0 do
  begin
    if PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog = AProgressDialog then
    begin
      FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
      Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
      Dispose(FProgressDialogsList[i]);
      FProgressDialogsList.Delete(i);
      Break;
    end;

    i := i - 1;
  end;
end;

procedure TMainForm.RemoveProgressDialogByUserName(AUserName: String);
var
  i: Integer;
begin
  i := FProgressDialogsList.Count - 1;
  while i >= 0 do
  begin
    if PProgressDialogData(FProgressDialogsList[i])^.UserName = AUserName then
    begin
      FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
      Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
      Dispose(FProgressDialogsList[i]);
      FProgressDialogsList.Delete(i);
      Break;
    end;

    i := i - 1;
  end;
end;

procedure TMainForm.DesktopHostFileTransferOnNewUI(Sender: TRtcPFileTransfer; const user: String);
var
  UI: TRtcPFileTransferUI;
begin
//  xLog('PFileTransExplorerNewUI');

  UI := TRtcPFileTransferUI.Create(nil);
  UI.NotifyFileBatchSend := OnDesktopHostNotifyFileBatchSend;
  UI.UserName := user;
  UI.UserDesc := GetUserDescription(user);
  // Always set UI.Module *after* setting UI.UserName !!!
  UI.Module := Sender;
  UI.Tag := Sender.Tag; //ThreadID
end;

function TMainForm.GetCurrentExplorerDirectory(var ADir: String; var AHandle: THandle): Boolean;
var
  ShellWindows: IShellWindows;
  spDisp: IDispatch;
  WB: IWebbrowser2;
  i: Integer;
begin
//  CoInitialize(nil);

  ADir := '';
  AHandle := 0;
  Result := False;

  //Explorer - глобальная переменная для доступа ко всем откр.окнам Explorer
//  ShellWindows := CreateComObject(CLASS_ShellWindows) as IShellWindows;
  ShellWindows := CoShellWindows.Create;

  //Цикл прохода по всем откр.в настоящий момент окнам Explorer
  for i := 0 to ShellWindows.Count - 1 do
  begin
    spDisp := ShellWindows.Item(i);
    if spDisp = nil then
      Continue;

    spDisp.QueryInterface(iWebBrowser2, WB);
    if WB = nil then
      Continue;

    //Если очередное окно пребывает сейчас в фокусе
    if GetForegroundWindow = WB.HWND then
    begin
      //Получаем адресную локацию,т.е путь к каталогу
      ADir := System.Net.URLClient.TURI.URLDecode(WB.LocationUrl);
      //Замена левосторонних слешев в пути на классич. правосторонний разделитель
      ADir := StringReplace(ADir, '/','\', [rfReplaceAll]);
      //Удаляем 1-ые лишнии 8 символов (http:///)
      Delete(ADir, 1, 8);
      //Замена URL-представления пробела %20 на нормальный символ #32
      ADir := IncludeTrailingPathDelimiter(ADir);

      AHandle := WB.HWND;
      Result := True;
    end;
  end;

//  CoUninitialize;
end;

procedure TMainForm.OnGetCbrdFilesData(Sender: TDataObject; AUserName: String);
var
  pPc: PPortalConnection;
  CurExplorerDir: String;
  CurExplorerHandle: THandle;
begin
  pPc := GetPortalConnection('desk', AUserName); //Если подключены контролем к хосту-овнеру-клибоарда, то с хоста тянем файлы
  if pPc <> nil then
  begin
    if GetCurrentExplorerDirectory(CurExplorerDir, CurExplorerHandle) then
      SendMessage(pPc^.DataModule.Handle, WM_GET_FILES_FROM_CLIPBOARD, WPARAM(CurExplorerHandle), LPARAM(CurExplorerDir));
  end
  else
  if tPHostThread <> nil then
    if tPHostThread.FFileTransfer.isSubscriber(AUserName) then  //Если мы хост, то с контроля-овнера-клибоарда тянем файлы
      if GetCurrentExplorerDirectory(CurExplorerDir, CurExplorerHandle) then
        tPHostThread.GetFilesFromClipboard(CurExplorerHandle, CurExplorerDir);
end;

procedure TMainForm.SetFilesToClipboard(var Message: TMessage);
var
  data: TClipBrdFileData;
begin
  data := TClipBrdFileData(Message.LParam);
//  OleInitialize(nil);
  CB_DataObject := TDataObject.Create(data.FUserName, data.files, data.FFilePaths, OnGetCbrdFilesData);
  OleCheck(OleSetClipboard(CB_DataObject));
//  OleUninitialize;
end;

{function TMainForm.GetHostGatewayClientActive: Boolean;
begin
  CS_HostGateway.Acquire;
  try
    Result := FHostGatewayClientActive;
  finally
    CS_HostGateway.Release;
  end;
end;

procedure TMainForm.SetHostGatewayClientActive(AValue: Boolean);
begin
  CS_HostGateway.Acquire;
  try
    FHostGatewayClientActive := AValue;
  finally
    CS_HostGateway.Release;
  end;

  tPClientReconnect.Enabled := not AValue;
end;}

function GetUniqueString: String;
var
  UID: TGUID;
begin
  CreateGuid(UID);
  Result := GUIDToString(UID);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
//  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
end;

procedure TMainForm.bSetupClick(Sender: TObject);
var
  err: LongInt;
  EleavateSupport: TEleavateSupport;
  fn{, NewPermanentPassword}: String;
//  err: LongInt;
  fAcceptEULA: TfAcceptEULA;
  fAutoUpdate: Boolean;
begin
  fAcceptEULA := TfAcceptEULA.Create(nil);
  try
    fAcceptEULA.ePassword.Text := '';
    fAcceptEULA.ePasswordConfirm.Text := '';

    if fAcceptEULA.ShowModal = mrCancel then
      Exit
    else
    if fAcceptEULA.PasswordChanged then
    begin
//      NewPermanentPassword := fAcceptEULA.ePassword.Text;
      PermanentPassword := System.Hash.THashMD5.GetHashString(fAcceptEULA.ePassword.Text {NewPermanentPassword});
//      ShowPermanentPasswordState();
      SendPasswordsToGateway;

      fAutoUpdate := fAcceptEULA.cbAutomaticUpdate.Checked;

      SaveSetup;
    end;
  finally
    FreeAndNil(fAcceptEULA);
  end;

//  if MessageBox(Handle, 'Remox будет установлен в систему. Продолжить?', 'Remox', MB_OKCANCEL) = ID_CANCEL then
//    Exit;

  with TStringList.Create do
  try
    Add('PING 127.0.0.1 -n 2 > NUL');
    Add(ParamStr(0) + ' /INSTALL');
    fn := GetTempFile + '.bat';
    Add('DEL "' + fn + '"');
    SaveToFile(fn, TEncoding.GetEncoding(866));
  finally
    Free;
  end;

  if (Win32MajorVersion >= 6 {vista\server 2k8}) then
  begin
    if not ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
    begin
      EleavateSupport := TEleavateSupport.Create(nil);
      try
        SetLastError(EleavateSupport.RunElevated(fn, '', Handle, True, Application.ProcessMessages));
        err := GetLastError;
        if err <> ERROR_SUCCESS then
          xLog('ServiceInstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
  //      SetServiceMenuAttributes;
      finally
        EleavateSupport.Free;
      end;

//      Application.Terminate;
    end;
  end;

  Application.ProcessMessages;

  SendSettingsToService(PermanentPassword {NewPermanentPassword}, True, fAutoUpdate);

  pBtnSetup.Visible := not IsServiceExisted(RTC_HOSTSERVICE_NAME);
  ShowPermanentPasswordState();
end;

procedure TMainForm.bSetupMouseEnter(Sender: TObject);
begin
  bSetup.Color := RGB(231, 84, 87);
end;

procedure TMainForm.bSetupMouseLeave(Sender: TObject);
begin
  bSetup.Color := RGB(241, 94, 97);
end;

function TMainForm.ConnectedToAllGateways: Boolean;
begin
  CS_Status.Acquire;
  try
    Result := (CurStatus >= 3) and  (CurStatus <> STATUS_OLD_VERSION);
  finally
    CS_Status.Release;
  end;
end;

procedure TMainForm.OnDesktopHostNotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend);
var
  pPDData: PProgressDialogData;
begin
//  Memo1.Lines.Add(IntToStr(Sender.Recv_FileCount) + ' - ' + Sender.Recv_FileName + ' - ' + IntToStr(Sender.Recv_BytesComplete) + ' - '+ IntToStr(Sender.Recv_BytesTotal));

  if task.Direction <> dbtFetch then
    Exit;

  case mode of
    mbsFileStart, mbsFileData, mbsFileStop:
    begin
      pPDData := GetProgressDialogData(task.Id);
      if pPDData = nil then
        Exit;

      pPDData^.ProgressDialog^.TextLine1 := task.Files[task.Current].file_path;

      pPDData^.ProgressDialog^.Position := Round(task.Progress * 100);

//      if task.size > 1024 * 1024 * 1024 then
//        FProgressDialog.TextFooter := FormatFloat('0.00', task.SentSize / (1024 * 1024 * 1024)) + ' GB из ' + FormatFloat('0.00', task.size / (1024 * 1024 * 1024)) + ' GB'
//      else
//      if Sender.Recv_BytesTotal > 1024 * 1024 then
//        FProgressDialog.TextFooter := FormatFloat('0.00', task.SentSize / (1024 * 1024)) + ' MB из ' + FormatFloat('0.00', task.size / (1024 * 1024)) + ' MB'
//      else
//        FProgressDialog.TextFooter := FormatFloat('0.00', task.SentSize / 1024) + ' KB из ' + FormatFloat('0.00', task.size / 1024) + ' KB';
    end;
    mbsTaskStart:
    begin
//      New(FProgressDialog);
      pPDData := AddProgressDialog(task.Id, task.User);

      pPDData^.ProgressDialog^.Title := 'Копирование';
      pPDData^.ProgressDialog^.CommonAVI := TCommonAVI.aviCopyFiles;
      pPDData^.ProgressDialog^.TextLine1 := task.Files[task.Current].file_path;
      pPDData^.ProgressDialog^.TextLine2 := task.LocalFolder;
      pPDData^.ProgressDialog^.Max := 100;
      pPDData^.ProgressDialog^.Position := 0;
      pPDData^.ProgressDialog^.TextCancel := 'Прерывание...';
      pPDData^.ProgressDialog^.OnCancel := OnProgressDialogCancel;
      pPDData^.ProgressDialog^.AutoCalcFooter := True;
      pPDData^.ProgressDialog^.fHwndParent := LastActiveExplorerHandle;
      pPDData^.ProgressDialog^.Execute;
    end;
    mbsTaskFinished:
    begin
      pPDData := GetProgressDialogData(task.Id);
      if pPDData = nil then
        Exit;

      pPDData^.ProgressDialog^.Stop;
      RemoveProgressDialog(task.Id);
    end;
    mbsTaskError:
    begin
      pPDData := GetProgressDialogData(task.Id);
      if pPDData = nil then
        Exit;

      pPDData^.ProgressDialog^.Stop;
      RemoveProgressDialog(task.Id);
    end;
  end;
end;

procedure TMainForm.OnProgressDialogCancel(Sender: TObject);
var
  pPDData: PProgressDialogData;
begin
  pPDData := GetProgressDialogData(PProgressDialog(@Sender));
  if pPDData <> nil then
    if tPHostThread <> nil then
      tPHostThread.FFileTransfer.CancelBatch(tPHostThread.FFileTransfer, pPDData^.taskId);

  TProgressDialog(Sender).Stop;
  RemoveProgressDialogByValue(@Sender);
end;

constructor TPortalHostThread.Create(CreateSuspended: Boolean; AUserName, AGateway, APort, AProxyAddr, AProxyUserName, AProxyPassword: String; AProxyEnabled: Boolean);
begin
  inherited Create(CreateSuspended);

//  OleInitialize(nil);

  FCS := TCriticalSection.Create;

  FreeOnTerminate := True;
  FUserName := AUserName;
  Gateway := AGateway;
  Port := APort;

  FNeedRestartThread := False;

  ProxyEnabled := AProxyEnabled;
  ProxyAddr := AProxyAddr;
  ProxyUserName := AProxyUserName;
  ProxyPassword := AProxyPassword;

  FUID := GetUniqueString;
  FUID := StringReplace(FUID, '-', '', [rfReplaceAll]);

  FDataModule := TDataModule.Create(nil);
  FResult := TRtcResult.Create(FDataModule);
  FResult.OnReturn := FResultReturn;

  FGatewayClient := TRtcHttpPortalClient.Create(FDataModule);
  FGatewayClient.Name := 'PClient_' + FUID;
  FGatewayClient.LoginUserName := AUserName;
  FGatewayClient.LoginUserInfo.asText['RealName'] := AUserName;
  FGatewayClient.LoginPassword := '';
  FGatewayClient.AutoSyncEvents := True;
  FGatewayClient.DataCompress := rtcpCompMax;
  FGatewayClient.DataEncrypt := 16;
  FGatewayClient.DataForceEncrypt := True;
  FGatewayClient.DataSecureKey := '2240897';
  FGatewayClient.GateAddr := AGateway;
  FGatewayClient.GatePort := APort;
//  FGatewayClient.GateAddr := Copy(AGateway, 1, Pos(':', AGateway) - 1);
//  FGatewayClient.GatePort := Copy(AGateway, Pos(':', AGateway) + 1, Length(AGateway) - Pos(':', AGateway));
//  FGatewayClient.Gate_CryptPlugin := ;
//  FGatewayClient.Gate_ISAPI := MainForm.PClient.Gate_ISAPI;
  FGatewayClient.Gate_Proxy := MainForm.hcAccounts.UseProxy;
  FGatewayClient.Gate_ProxyAddr := ProxyAddr;
//  FGatewayClient.Gate_ProxyBypass := MainForm.hcAccounts.UserLogin.ProxyBypass;
  FGatewayClient.Gate_ProxyPassword := MainForm.hcAccounts.UserLogin.ProxyPassword;
  FGatewayClient.Gate_ProxyUserName := MainForm.hcAccounts.UserLogin.ProxyUserName;
  FGatewayClient.Gate_SSL := MainForm.hcAccounts.UseSSL;
  FGatewayClient.Gate_Timeout := 300;
  FGatewayClient.Gate_WinHttp := False;
//        FGatewayClient.GParamsLoaded := PClient.GParamsLoaded;
//  FGatewayClient.GRestrictAccess := MainForm.PClient.GRestrictAccess;
//  FGatewayClient.GSuperUsers := MainForm.PClient.GSuperUsers;
//  FGatewayClient.GUsers := MainForm.PClient.GUsers;
  FGatewayClient.GwStoreParams := True;
  FGatewayClient.MultiThreaded := True;
  FGatewayClient.RetryFirstLogin := 0;
  FGatewayClient.RetryOtherCalls := 5;
  FGatewayClient.UserNotify := True;
  FGatewayClient.UserVisible := True;
  FGatewayClient.OnError := MainForm.PClientError;
  FGatewayClient.OnFatalError := MainForm.PClientFatalError;
  FGatewayClient.OnLogIn := MainForm.PClientLogIn;
  FGatewayClient.OnLogOut := MainForm.PClientLogOut;
  FGatewayClient.OnParams := MainForm.PClientParams;
  FGatewayClient.OnStart := MainForm.PClientStart;
  FGatewayClient.OnStatusGet := MainForm.PClientStatusGet;
  FGatewayClient.OnStatusPut := MainForm.PClientStatusPut;
  FGatewayClient.OnUserLoggedIn := MainForm.PClientUserLoggedIn;
  FGatewayClient.OnUserLoggedOut := MainForm.PClientUserLoggedOut;
  FGatewayClient.Tag := ThreadID;

  FFileTransfer := TRtcPFileTransfer.Create(FDataModule);
  FFileTransfer.Name := 'PFileTransfer_' + FUID;
  FFileTransfer.Client := FGatewayClient;
  FFileTransfer.AccessControl := False;
  FFileTransfer.BeTheHost := True;
  FFileTransfer.FileInboxPath := '';
  FFileTransfer.AccessControl := False;
{  FFileTransfer.GAllowBrowse := True; //MainForm.PFileTrans.GAllowBrowse;
//  FFileTransfer.GAllowBrowse_Super := MainForm.PFileTrans.GAllowBrowse_Super;
  FFileTransfer.GAllowDownload := True; //MainForm.PFileTrans.GAllowDownload;
//  FFileTransfer.GAllowDownload_Super := MainForm.PFileTrans.GAllowDownload_Super;
  FFileTransfer.GAllowFileDelete := True; //MainForm.PFileTrans.GAllowFileDelete;
//  FFileTransfer.GAllowFileDelete_Super := MainForm.PFileTrans.GAllowFileDelete_Super;
  FFileTransfer.GAllowFileMove := True; //MainForm.PFileTrans.GAllowFileMove;
//  FFileTransfer.GAllowFileMove_Super := MainForm.PFileTrans.GAllowFileMove_Super;
  FFileTransfer.GAllowFileRename := True; //MainForm.PFileTrans.GAllowFileRename;
  FFileTransfer.GAllowFolderCreate := True; //MainForm.PFileTrans.GAllowFolderCreate;
//  FFileTransfer.GAllowFolderCreate_Super := MainForm.PFileTrans.GAllowFolderCreate_Super;
  FFileTransfer.GAllowFolderDelete := True; //MainForm.PFileTrans.GAllowFolderDelete;
//  FFileTransfer.GAllowFolderDelete_Super := MainForm.PFileTrans.GAllowFolderDelete_Super;
  FFileTransfer.GAllowFolderMove := True; //MainForm.PFileTrans.GAllowFolderMove;
//  FFileTransfer.GAllowFolderMove_Super := MainForm.PFileTrans.GAllowFolderMove_Super;
  FFileTransfer.GAllowFolderRename := True; //MainForm.PFileTrans.GAllowFolderRename;
//  FFileTransfer.GAllowShellExecute := MainForm.PFileTrans.GAllowShellExecute;
//  FFileTransfer.GAllowShellExecute_Super := MainForm.PFileTrans.GAllowShellExecute_Super;
  FFileTransfer.GAllowUpload := True; //MainForm.PFileTrans.GAllowUpload;
//  FFileTransfer.GAllowUpload_Super := MainForm.PFileTrans.GAllowUpload_Super;
  FFileTransfer.GUploadAnywhere := True; //MainForm.PFileTrans.GUploadAnywhere;
//  FFileTransfer.GUploadAnywhere_Super := MainForm.PFileTrans.GUploadAnywhere_Super;}
  FFileTransfer.GwStoreParams := True;
  FFileTransfer.MaxSendChunkSize := 102400;
  FFileTransfer.MinSendChunkSize := 4096;
//  if UIVisible then
    FFileTransfer.OnNewUI := MainForm.PFileTransferLogUI; //Для хоста указываем лог
//  else
//    FFileTransfer.OnNewUI := MainForm.PFileTransExplorerNewUI_HideMode; //Для контроля указываем невидимый эксплорер
  FFileTransfer.OnUserJoined := MainForm.PModuleUserJoined;
  FFileTransfer.OnUserLeft := MainForm.PModuleUserLeft; //MainForm.PModuleUserLeft;
  FFileTransfer.NotifyFileBatchSend := MainForm.OnDesktopHostNotifyFileBatchSend;
  FFileTransfer.Tag := ThreadID;

  FChat := TRtcPChat.Create(FDataModule);
  FChat.Name := 'PChat_' + FUID;
  FChat.Client := FGatewayClient;
  FChat.AccessControl := False;
  FChat.BeTheHost := False;
//  FChat.GAllowJoin := MainForm.PChat.GAllowJoin;
//  FChat.GAllowJoin_Super := MainForm.PChat.GAllowJoin_Super;
  FChat.GwStoreParams := True;
  FChat.OnNewUI := MainForm.PChatNewUI;
  FChat.OnUserJoined := MainForm.PModuleUserJoined;
  FChat.OnUserLeft := MainForm.PModuleUserLeft;
  FChat.Tag := ThreadID;

  FDesktopHost := TRtcPDesktopHost.Create(FDataModule);
  FDesktopHost.Name := 'PDesktopHost_' + FUID;
  FDesktopHost.Client := FGatewayClient;
//  FDesktopHost.FileTransfer := FFileTransfer;
  FDesktopHost.AccessControl := False;
  FDesktopHost.GCaptureAllMonitors := False;
//  FDesktopHost.GCaptureLayeredWindows := False;
  FDesktopHost.GColorLimit := rdColor8bit;
  FDesktopHost.GColorLowLimit := rd_ColorHigh;
  FDesktopHost.GColorReducePercent := 0;
  FDesktopHost.GFrameRate := rdFramesMax;
  FDesktopHost.GFullScreen := True;
  FDesktopHost.GSendScreenInBlocks := rdBlocks1;
  FDesktopHost.GSendScreenRefineBlocks := rdBlocks12;
  FDesktopHost.GSendScreenRefineDelay := 0;
  FDesktopHost.GSendScreenSizeLimit := rdBlockAnySize;
  FDesktopHost.GUseMirrorDriver := False;
  FDesktopHost.GUseMouseDriver := False;
  FDesktopHost.GwStoreParams := True;
  FDesktopHost.OnHaveScreeenChanged := MainForm.PDesktopHostHaveScreeenChanged;
  FDesktopHost.OnQueryAccess := MainForm.PDesktopHostQueryAccess;
  FDesktopHost.OnUserJoined := MainForm.PModuleUserJoined;
  FDesktopHost.OnUserLeft := MainForm.PModuleUserLeft;
  FDesktopHost.Tag := ThreadID;
  FDesktopHost.FileTransfer := TRtcPFileTransfer.Create(nil);
  FDesktopHost.FileTransfer.BeTheHost := False;
  FDesktopHost.FileTransfer.OnNewUI := MainForm.DesktopHostFileTransferOnNewUI;
  FDesktopHost.FileTransfer.AccessControl := False;
{  FDesktopHost.FileTransfer.GAllowBrowse := True; //MainForm.PFileTrans.GAllowBrowse;
//  FDesktopHost.FileTransfer.GAllowBrowse_Super := MainForm.PFileTrans.GAllowBrowse_Super;
  FDesktopHost.FileTransfer.GAllowDownload := True; //MainForm.PFileTrans.GAllowDownload;
//  FDesktopHost.FileTransfer.GAllowDownload_Super := MainForm.PFileTrans.GAllowDownload_Super;
  FDesktopHost.FileTransfer.GAllowFileDelete := True; //MainForm.PFileTrans.GAllowFileDelete;
//  FDesktopHost.FileTransfer.GAllowFileDelete_Super := MainForm.PFileTrans.GAllowFileDelete_Super;
  FDesktopHost.FileTransfer.GAllowFileMove := True; //MainForm.PFileTrans.GAllowFileMove;
//  FDesktopHost.FileTransfer.GAllowFileMove_Super := MainForm.PFileTrans.GAllowFileMove_Super;
  FDesktopHost.FileTransfer.GAllowFileRename := True; //MainForm.PFileTrans.GAllowFileRename;
  FDesktopHost.FileTransfer.GAllowFolderCreate := True; //MainForm.PFileTrans.GAllowFolderCreate;
//  FDesktopHost.FileTransfer.GAllowFolderCreate_Super := MainForm.PFileTrans.GAllowFolderCreate_Super;
  FDesktopHost.FileTransfer.GAllowFolderDelete := True; //MainForm.PFileTrans.GAllowFolderDelete;
//  FDesktopHost.FileTransfer.GAllowFolderDelete_Super := MainForm.PFileTrans.GAllowFolderDelete_Super;
  FDesktopHost.FileTransfer.GAllowFolderMove := True; //MainForm.PFileTrans.GAllowFolderMove;
//  FDesktopHost.FileTransfer.GAllowFolderMove_Super := MainForm.PFileTrans.GAllowFolderMove_Super;
  FDesktopHost.FileTransfer.GAllowFolderRename := True; //MainForm.PFileTrans.GAllowFolderRename;
//  FDesktopHost.FileTransfer.GAllowShellExecute := MainForm.PFileTrans.GAllowShellExecute;
//  FDesktopHost.FileTransfer.GAllowShellExecute_Super := MainForm.PFileTrans.GAllowShellExecute_Super;
  FDesktopHost.FileTransfer.GAllowUpload := True; //MainForm.PFileTrans.GAllowUpload;
//  FDesktopHost.FileTransfer.GAllowUpload_Super := MainForm.PFileTrans.GAllowUpload_Super;
  FDesktopHost.FileTransfer.GUploadAnywhere := True; //MainForm.PFileTrans.GUploadAnywhere;
//  FDesktopHost.FileTransfer.GUploadAnywhere_Super := MainForm.PFileTrans.GUploadAnywhere_Super;}

  FGatewayClient.Active := True;
end;

destructor TPortalHostThread.Destroy;
begin
  FGatewayClient.Module.WaitForCompletion(False, 2);
  FGatewayClient.Disconnect;
  FGatewayClient.Active := False;

  FResult.Free;
  FDesktopHost.FileTransfer.Free;
  if FDesktopHost <> nil then
    FDesktopHost.Free;
  if FFileTransfer <> nil then
    FFileTransfer.Free;
  if FChat <> nil then
    FChat.Free;
  FGatewayClient.Free;
  FDataModule.Free;
  FCS.Free;

  TSendDestroyClientToGatewayThread.Create(False, Gateway, FUserName, False, MainForm.hcAccounts.UseProxy, MainForm.hcAccounts.UserLogin.ProxyAddr, MainForm.hcAccounts.UserLogin.ProxyUserName, MainForm.hcAccounts.UserLogin.ProxyPassword, False);

//  OleUninitialize;

  TerminateThread(ThreadID, ExitCode);
end;

procedure TPortalHostThread.Restart(AGateway: String = '');
begin
  FCS.Acquire;
  try
    if AGateway <> '' then
      Gateway := AGateway;
    FNeedRestartThread := True;
  finally
    FCS.Release;
  end;
end;

procedure TPortalHostThread.ChangeProxyParams(AProxyEnabled: Boolean; AProxyAddr, AProxyUserName, AProxyPassword: String);
begin
  FCS.Acquire;
  try
    FGatewayClient.Gate_Proxy := AProxyEnabled;
    FGatewayClient.Gate_ProxyAddr := AProxyAddr;
    FGatewayClient.Gate_ProxyUserName := AProxyUserName;
    FGatewayClient.Gate_ProxyPassword := AProxyPassword;
  finally
    FCS.Release;
  end;
end;

procedure TPortalHostThread.SendPing;
var
  PassRec: TRtcRecord;
begin
//  xLog('TPortalHostThread.SendPing');

  PassRec := TRtcRecord.Create;
  try
    if Trim(MainForm.SessionPassword) <> '' then
      PassRec.asString['0'] := MainForm.SessionPassword;
    if Trim(MainForm.PermanentPassword) <> '' then
      PassRec.asString['1'] := MainForm.PermanentPassword;

    with MainForm.TimerModule do
    try
      with Data.NewFunction('Host.Ping') do
      begin
        asWideString['User'] := MainForm.DeviceId;
        asString['Gateway'] := Gateway + ':' + Port;
        asRecord['Passwords'] := PassRec;
        if ActiveConsoleSessionID = CurrentSessionID then
          asString['ConsoleId'] := MainForm.ConsoleId
        else
          asString['ConsoleId'] := '';
        asInteger['LockedState'] := MainForm.ScreenLockedState;
        asBoolean['ServiceStarted'] := IsServiceStarted(RTC_HOSTSERVICE_NAME);
        asBoolean['IsService'] := IsService;
        Call(FResult);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
  finally
    FreeAndNil(PassRec);
  end;
end;

procedure TPortalHostThread.FResultReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
var
  i: Integer;
begin
//  XLog('TPortalHostThread.FResultReturn');

  if Result.isType = rtc_Exception then
  begin
//    HostLogOut;
//    LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
//    HostPingTimer.Enabled := True;

  if Result.asRecord.asBoolean['NeedHostRelogin'] then
  begin
    xLog('resHostPingReturn: NeedHostRelogin');

    MainForm.DeleteAllPendingRequests;
    MainForm.CloseAllActiveUI;

//    CS_GW.Acquire;
//    try
//      for i := 0 to GatewayClientsList.Count - 1 do
//      begin
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Module.SkipRequests;
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Module.ResetLogin;
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Module.StartCalls;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//      //  PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//      end;
//    finally
//      CS_GW.Release;
//    end;

    if (MainForm.DeviceId <> '') then
    begin
//      PClient.Disconnect;
//      PClient.Active := False;
      MainForm.tPClientReconnect.Enabled := True;
    end;

    //    CloseAllActiveUI;
//
//    for i := 0 to GatewayClientsList.Count - 1 do
//    begin
//  //    if PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active then
//  //      Continue;
//
////      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
////      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//  //    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Stop;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//    end;

//    tPClientReconnect.Enabled := True;
//    PClient.Active := True; //Доделать
//    tPClientReconnectTimer(nil);
//    hcAccounts.DisconnectNow(True);
//    SetStatusString('Сервер недоступен');     asdsad
//    SetConnectedState(False);
//    if not isClosing then
//      tHcAccountsReconnect.Enabled := True;
  end;
end;

procedure TPortalHostThread.GetFilesFromClipboard(ACurExplorerHandle: THandle; ACurExplorerDir: String);
var
  i: Integer;
  FileList: TStringList;
  temp_id: TTaskID;
begin
  FCS.Acquire;
  try
    LastActiveExplorerHandle := ACurExplorerHandle;

    FileList := TStringList.Create;
    for i := 0 to CB_DataObject.FCount - 1 do
      FileList.Add(CB_DataObject.FFiles[i].filePath);

  //  TRtcPFileTransfer(myUI.Module).NotifyFileBatchSend :=FT_UINotifyFileBatchSend;
    try
      temp_id := FFileTransfer.FetchBatch(CB_DataObject.FUserName,
                          FileList, ExtractFilePath(CB_DataObject.FFiles[0].filePath), ACurExplorerDir, FFileTransfer);
    except
  //  on E: Exception do
  //    begin
  //      add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
  //      raise;
  //    end;
    end;

//    LastActiveExplorerHandle := ACurExplorerHandle;
//    for i := 0 to CB_DataObject.FCount - 1 do
//      FDesktopHost.FileTransfer.Fetch(CB_DataObject.FUserName, CB_DataObject.FFiles[i].filePath, ACurExplorerDir);
  finally
    FileList.Free;
    FCS.Release;
  end;
end;

procedure TPortalHostThread.Execute;
var
  msg: TMsg;
  lNeedRestartThread: Boolean;
  i: Integer;
begin
  i := 0;
  while (not Terminated) do
  begin
    if i = 10 then
    begin
      SendPing;
      i := 0;
    end;

    FCS.Acquire;
    try
      lNeedRestartThread := FNeedRestartThread;
    finally
      FCS.Release;
    end;

    if lNeedRestartThread then
    begin
//      TSendDestroyClientToGatewayThread.Create(False, Gateway, FUserName, False, MainForm.hcAccounts.UseProxy, MainForm.hcAccounts.UserLogin.ProxyAddr, MainForm.hcAccounts.UserLogin.ProxyUserName, MainForm.hcAccounts.UserLogin.ProxyPassword, False);

      FGatewayClient.Disconnect;
      FGatewayClient.Stop;
      FGatewayClient.Active := False;
      FGatewayClient.GateAddr := Gateway;
      FGatewayClient.Gate_Proxy := ProxyEnabled;
      FGatewayClient.Gate_ProxyAddr := ProxyAddr;
      FGatewayClient.Gate_ProxyUserName := ProxyUserName;
      FGatewayClient.Gate_ProxyPassword := ProxyPassword;
      FGatewayClient.Active := True;

      FCS.Acquire;
      try
        FNeedRestartThread := False;
      finally
        FCS.Release;
      end;
    end;

//    if not Windows.GetMessage(msg, 0, 0, 0) then
//      Terminate;
//
//    if not Terminated then
//    begin
//      if (MSG.message = WM_CLOSE) then
//        Terminate
//      else
//        ProcessMessage(msg);
//    end;

    Sleep(100);
    i := i + 1;
  end;
end;

//procedure TPortalHostThread.ProcessMessage(MSG: TMSG);
//var
//  Message: TMessage;
//begin
//  Message.Msg := Msg.message;
//  Message.WParam := MSG.wParam;
//  Message.LParam := MSG.lParam;
//  Message.Result := 0;
//  Dispatch(Message);
//end;

constructor TStatusUpdateThread.Create(CreateSuspended: Boolean;
  StatusUpdateProc: TExecuteProc);
begin
  inherited Create(CreateSuspended);

  FreeOnTerminate := True;
  FStatusUpdateProc := StatusUpdateProc;
end;

procedure TStatusUpdateThread.Execute;
var
  i: Integer;
begin
  i := 0;
  while (not Terminated) do
  begin
    if Assigned(FStatusUpdateProc) then
      Synchronize(FStatusUpdateProc);

    Sleep(200);
  end;
end;

procedure TMainform.ChangePort(AClient: TRtcHttpClient);
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

procedure TMainform.ChangePortP(AClient: TAbsPortalClient);
begin
  if TRtcHttpPortalClient(AClient).GatePort = '80' then
    TRtcHttpPortalClient(AClient).GatePort := '8080'
  else
  if TRtcHttpPortalClient(AClient).GatePort = '8080' then
    TRtcHttpPortalClient(AClient).GatePort := '443'
  else
  if TRtcHttpPortalClient(AClient).GatePort = '443' then
    TRtcHttpPortalClient(AClient).GatePort := '5938'
  else
  if TRtcHttpPortalClient(AClient).GatePort = '5938' then
    TRtcHttpPortalClient(AClient).GatePort := '80';

  if tPHostThread <> nil then
    if TRtcHttpPortalClient(AClient) = tPHostThread.FGatewayClient then
      tPHostThread.Port := TRtcHttpPortalClient(AClient).GatePort;
end;

constructor TPortalThread.Create(CreateSuspended: Boolean; AAction, AUserName, AUserPass, AUserToConnect, AGateway: String; AStartLockedStatus: Integer; AStartServiceStarted: Boolean; UIVisible: Boolean);
begin
  inherited Create(CreateSuspended);

  MainForm.AddPortalConnection(Self, ThreadID, AAction, AUserName, AUserPass, AUserToConnect, AStartLockedStatus, AStartServiceStarted);

  FreeOnTerminate := True;

  FLoggedIn := MainForm.LoggedIn;
  FAccountUID := MainForm.AccountUID;
  FDeviceId := MainForm.DeviceId;
  FDeviceUID := MainForm.DeviceUID;

  FUserName := AUserName;
  FUserPass := AUserPass;
  FUserToConnect := AUserToConnect;
  FGateway := AGateway;
  FAction := AAction;

  FUIDFull := GetUniqueString;
  FUID := StringReplace(FUIDFull, '-', '', [rfReplaceAll]);

  FDataModule := TDataModule.Create(nil);
  FResult := TRtcResult.Create(FDataModule);

  FGatewayClient := TRtcHttpPortalClient.Create(FDataModule);
  FGatewayClient.Name := 'PClient_' + FUID;
  FGatewayClient.LoginUserName := MainForm.DeviceId + '_' + FUserToConnect + '_' + FAction + '_' + FUID; //IntToStr(GatewayClientsList.Count + 1);
  FGatewayClient.LoginUserInfo.asText['RealName'] := FDeviceId;
  FGatewayClient.LoginPassword := '';
  FGatewayClient.AutoSyncEvents := True;
  FGatewayClient.DataCompress := rtcpCompMax;
  FGatewayClient.DataEncrypt := 16;
  FGatewayClient.DataForceEncrypt := True;
  FGatewayClient.DataSecureKey := '2240897';
  FGatewayClient.GateAddr := Copy(AGateway, 1, Pos(':', AGateway) - 1);
  FGatewayClient.GatePort := Copy(AGateway, Pos(':', AGateway) + 1, Length(AGateway) - Pos(':', AGateway));
  FGatewayClient.Gate_Proxy := MainForm.hcAccounts.UseProxy;
  FGatewayClient.Gate_ProxyAddr := MainForm.hcAccounts.UserLogin.ProxyAddr;
  FGatewayClient.Gate_ProxyBypass := MainForm.hcAccounts.UserLogin.ProxyBypass;
  FGatewayClient.Gate_ProxyPassword := MainForm.hcAccounts.UserLogin.ProxyPassword;
  FGatewayClient.Gate_ProxyUserName := MainForm.hcAccounts.UserLogin.ProxyUserName;
  FGatewayClient.Gate_SSL := MainForm.hcAccounts.UseSSL;
  FGatewayClient.Gate_Timeout := 300;
  FGatewayClient.Gate_WinHttp := False;
//        FGatewayClient.GParamsLoaded := PClient.GParamsLoaded;
//  FGatewayClient.GRestrictAccess := MainForm.PClient.GRestrictAccess;
//  FGatewayClient.GSuperUsers := MainForm.PClient.GSuperUsers;
//  FGatewayClient.GUsers := MainForm.PClient.GUsers;
  FGatewayClient.GwStoreParams := True;
  FGatewayClient.MultiThreaded := True;
  FGatewayClient.RetryFirstLogin := 0;
  FGatewayClient.RetryOtherCalls := 5;
  FGatewayClient.UserNotify := True;
  FGatewayClient.UserVisible := True;
  FGatewayClient.OnError := MainForm.PClientError;
  FGatewayClient.OnFatalError := MainForm.PClientFatalError;
  FGatewayClient.OnLogIn := MainForm.PClientLogIn;
  FGatewayClient.OnLogOut := MainForm.PClientLogOut;
  FGatewayClient.OnParams := MainForm.PClientParams;
  FGatewayClient.OnStart := MainForm.PClientStart;
  FGatewayClient.OnStatusGet := MainForm.PClientStatusGet;
  FGatewayClient.OnStatusPut := MainForm.PClientStatusPut;
  FGatewayClient.OnUserLoggedIn := MainForm.PClientUserLoggedIn;
  FGatewayClient.OnUserLoggedOut := MainForm.PClientUserLoggedOut;
  FGatewayClient.Tag := ThreadID;
  FGatewayClient.Module.AutoSessions := True;
  FGatewayClient.Module.AutoSessionMode := rsm_Query;
  FGatewayClient.Module.AutoSessionsPing := 1;

  xLog('Client created: ' + 'PClient_' + FUID);

  FDesktopControl := nil;
  FFileTransfer := nil;
  FChat := nil;

  if FAction = 'desk' then
  begin
    FDesktopControl := TRtcPDesktopControl.Create(FDataModule);
    FDesktopControl.Name := 'PDesktopControl_' + FUID;
    FDesktopControl.Client := FGatewayClient;
    FDesktopControl.SendShortcuts := MainForm.PDesktopControl.SendShortcuts;
    FDesktopControl.OnNewUI := MainForm.PDesktopControlNewUI;
    FDesktopControl.Tag := ThreadID;
  end
  else
  if FAction = 'file' then
  begin
    FFileTransfer := TRtcPFileTransfer.Create(FDataModule);
    FFileTransfer.Name := 'PFileTransfer_' + FUID;
    FFileTransfer.Client := FGatewayClient;
    FFileTransfer.AccessControl := False;
    FFileTransfer.BeTheHost := False;
    FFileTransfer.FileInboxPath := '';
//    FFileTransfer.GAllowBrowse := MainForm.PFileTrans.GAllowBrowse;
//    FFileTransfer.GAllowBrowse_Super := MainForm.PFileTrans.GAllowBrowse_Super;
//    FFileTransfer.GAllowDownload := MainForm.PFileTrans.GAllowDownload;
//    FFileTransfer.GAllowDownload_Super := MainForm.PFileTrans.GAllowDownload_Super;
//    FFileTransfer.GAllowFileDelete := MainForm.PFileTrans.GAllowFileDelete;
//    FFileTransfer.GAllowFileDelete_Super := MainForm.PFileTrans.GAllowFileDelete_Super;
//    FFileTransfer.GAllowFileMove := MainForm.PFileTrans.GAllowFileMove;
//    FFileTransfer.GAllowFileMove_Super := MainForm.PFileTrans.GAllowFileMove_Super;
//    FFileTransfer.GAllowFileRename := MainForm.PFileTrans.GAllowFileRename;
//    FFileTransfer.GAllowFolderCreate := MainForm.PFileTrans.GAllowFolderCreate;
//    FFileTransfer.GAllowFolderCreate_Super := MainForm.PFileTrans.GAllowFolderCreate_Super;
//    FFileTransfer.GAllowFolderDelete := MainForm.PFileTrans.GAllowFolderDelete;
//    FFileTransfer.GAllowFolderDelete_Super := MainForm.PFileTrans.GAllowFolderDelete_Super;
//    FFileTransfer.GAllowFolderMove := MainForm.PFileTrans.GAllowFolderMove;
//    FFileTransfer.GAllowFolderMove_Super := MainForm.PFileTrans.GAllowFolderMove_Super;
//    FFileTransfer.GAllowFolderRename := MainForm.PFileTrans.GAllowFolderRename;
//    FFileTransfer.GAllowShellExecute := MainForm.PFileTrans.GAllowShellExecute;
//    FFileTransfer.GAllowShellExecute_Super := MainForm.PFileTrans.GAllowShellExecute_Super;
//    FFileTransfer.GAllowUpload := MainForm.PFileTrans.GAllowUpload;
//    FFileTransfer.GAllowUpload_Super := MainForm.PFileTrans.GAllowUpload_Super;
//    FFileTransfer.GUploadAnywhere := MainForm.PFileTrans.GUploadAnywhere;
//    FFileTransfer.GUploadAnywhere_Super := MainForm.PFileTrans.GUploadAnywhere_Super;
    FFileTransfer.GwStoreParams := True;
    FFileTransfer.MaxSendChunkSize := 102400;
    FFileTransfer.MinSendChunkSize := 4096;
    if UIVisible then
      FFileTransfer.OnNewUI := MainForm.PFileTransExplorerNewUI //Для контроля указываем эксплорер
    else
      FFileTransfer.OnNewUI := MainForm.PFileTransExplorerNewUI_HideMode; //Для контроля указываем невидимый эксплорер
    FFileTransfer.OnUserJoined := MainForm.PModuleUserJoined;
    FFileTransfer.OnUserLeft := MainForm.PModuleUserLeft;
    FFileTransfer.Tag := ThreadID;
  end
  else
  if FAction = 'chat' then
  begin
    FChat := TRtcPChat.Create(FDataModule);
    FChat.Name := 'PChat_' + FUID;
    FChat.Client := FGatewayClient;
    FChat.AccessControl := False;
    FChat.BeTheHost := False;
//    FChat.GAllowJoin := MainForm.PChat.GAllowJoin;
//    FChat.GAllowJoin_Super := MainForm.PChat.GAllowJoin_Super;
    FChat.GwStoreParams := True;
    FChat.OnNewUI := MainForm.PChatNewUI;
    FChat.OnUserJoined := MainForm.PModuleUserJoined;
    FChat.OnUserLeft := MainForm.PModuleUserLeft;
    FChat.Tag := ThreadID;
  end;

  FGatewayClient.Active := True;

  if FAction = 'desk' then
  begin
    if MainForm.PartnerNeedHideWallpaper(FUserToConnect) then
      FDesktopControl.Send_HideDesktop(FUserToConnect);

    FDesktopControl.ChgDesktop_Begin;
    if MainForm.PartnerGetQualitySetting(FUserToConnect) = DS_QUIALITY then
    begin
      FDesktopControl.ChgDesktop_BitsPerPixelLimit(32);
      FDesktopControl.ChgDesktop_CompressImage(True);
    end
    else
    if MainForm.PartnerGetQualitySetting(FUserToConnect) = DS_OPTIMAL then
    begin
      FDesktopControl.ChgDesktop_BitsPerPixelLimit(16);
      FDesktopControl.ChgDesktop_CompressImage(True);
    end
    else
    if MainForm.PartnerGetQualitySetting(FUserToConnect) = DS_SPEED then
    begin
      FDesktopControl.ChgDesktop_BitsPerPixelLimit(32);
      FDesktopControl.ChgDesktop_CompressImage(True);
    end;
    FDesktopControl.ChgDesktop_End(FUserToConnect);

{//    FDesktopControl.ChgDesktop_UseMouseDriver(False);
//    FDesktopControl.ChgDesktop_CaptureLayeredWindows(False);
    FDesktopControl.ChgDesktop_ColorLimit(rdColor8bit);
    FDesktopControl.ChgDesktop_ColorLowLimit(rd_ColorHigh);
//    FDesktopControl.ChgDesktop_FrameRate(rdFramesMax);
//    FDesktopControl.ChgDesktop_SendScreenInBlocks(rdBlocks1);
//    FDesktopControl.ChgDesktop_SendScreenRefineBlocks(rdBlocks12);
//    FDesktopControl.ChgDesktop_SendScreenSizeLimit(rdBlockAnySize);
//    if grpColorLow.ItemIndex>=0 then
//      begin
//      FDesktopControl.ChgDesktop_ColorLowLimit(rd_ColorHigh);
//      FDesktopControl.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
//    FDesktopControl.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);}

    FDesktopControl.Open(FUserToConnect);
  end
  else
  if FAction = 'file' then
    FFileTransfer.Open(FUserToConnect, UIVisible)
  else
  if FAction = 'chat' then
    FChat.Open(FUserToConnect);

  with MainForm.TimerModule do
  try
    with Data.NewFunction('Connection.Login') do
    begin
      asBoolean['IsAccount'] := FLoggedIn;
      asString['AccountUID'] := FAccountUID;
      asString['DeviceUID'] := FDeviceUID;
      asString['UserFrom'] := FDeviceId;
      asString['UserTo'] := FUserName;
      asString['Action'] := FAction;
      Call(FResult);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TPortalThread.SendPing;
begin
  with MainForm.TimerModule do
  try
    with Data.NewFunction('Connection.Ping') do
    begin
      asBoolean['IsAccount'] := FLoggedIn;
      asString['AccountUID'] := FAccountUID;
      asString['DeviceUID'] := FDeviceUID;
      asString['UserFrom'] := FDeviceId;
      asString['UserTo'] := FUserName;
      asString['Action'] := FAction;
      Call(FResult);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TPortalThread.SetNeedCloseUI(AValue: Boolean);
begin
  CS.Acquire;
  try
    FNeedCloseUI := AValue;
  finally
    CS.Release;
  end;
end;

destructor TPortalThread.Destroy;
//var
//  UIDM: TUIDataModule;
begin
  with MainForm.TimerModule do
  try
    with Data.NewFunction('Connection.Logout') do
    begin
      asBoolean['IsAccount'] := FLoggedIn;
      asString['AccountUID'] := FAccountUID;
      asString['DeviceUID'] := FDeviceUID;
      asString['UserFrom'] := FDeviceId;
      asString['UserTo'] := FUserName;
      asString['Action'] := FAction;
      Call(FResult);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;

  MainForm.TimerModule.WaitForCompletion(False, 2);

//  UIDM := DesktopsForm.GetRemovedUIDataModule(FUserName);
//  if UIDM <> nil then
//  begin
//    if UIDM.HideWallpaper then
//      UIDM.UI.Send_ShowDesktop;
//    if UIDM.LockSystemOnClose then
//      UIDM.UI.Send_LockSystem;
//  end;

//  UIDM.UI.CloseAndClear;
//  UIDM.FT_UI.CloseAndClear;

  FResult.Free;
  FGatewayClient.Stop;
  FGatewayClient.Active := False;
  FDesktopControl.Free;
  FFileTransfer.Free;
  FChat.Free;
  FGatewayClient.Free;
  FDataModule.Free;

//  if (FAction = 'file') or (FAction = 'chat') then
//    PostMessage(FUIForm.Handle, WM_CLOSE_UI, 0, 0)
//  else
  if FNeedCloseUI then
    PostMessage(DesktopsForm.Handle, WM_CLOSE_UI, WPARAM(PChar(FUserName)), LPARAM(ThreadID));

//  try
//    FGatewayClient.Disconnect;
//  finally
//  end;
//  try
//    FGatewayClient.Active := False;
//  finally
//  end;
//
//  try
//    if FDesktopControl <> nil then
//      FDesktopControl.Free;
//  finally
//  end;
//  try
//    if FFileTransfer <> nil then
//      FFileTransfer.Free;
//  finally
//  end;
//  try
//    if FChat <> nil then
//      FChat.Free;
//  finally
//  end;
//  try
//    FGatewayClient.Free;
//  finally
//  end;
//  try
//    FDataModule.Free;
//  finally
//  end;

  TSendDestroyClientToGatewayThread.Create(False, FGateway, FDeviceId + '_' + FUserName + '_' + FAction + '_' + FUID, False, MainForm.hcAccounts.UseProxy, MainForm.hcAccounts.UserLogin.ProxyAddr, MainForm.hcAccounts.UserLogin.ProxyUserName, MainForm.hcAccounts.UserLogin.ProxyPassword, False);

//  TerminateThread(ThreadID, ExitCode);
end;

{procedure TPortalThread.Execute;
var
  msg: TMsg;
begin
  while (not Terminated) do
  begin
    if not Windows.GetMessage(msg, 0, 0, 0) then
      Terminate;

      if not Terminated then
      begin
        if (MSG.message = WM_CLOSE) then
        begin
          FNeedCloseUI := Boolean(msg.wParam);
          Terminate;
        end
        else
          ProcessMessage(msg);
      end;
  end;
end;}

procedure TPortalThread.Execute;
var
  i: Integer;
begin
  i := 0;
  while not Terminated do
  begin
    if i = 10 then
    begin
//      SendPing;

      i := 0;
    end;

    Sleep(100);

    i := i + 1;
  end;
end;

{procedure TPortalThread.Execute;
var
  msg: TMsg;
begin
  while (not Terminated) do
    Sleep(1);
  msg := msg;
end;}

{procedure TPortalThread.WndProc(var Message: TMessage);
begin
  if (Message.Msg = WM_CLOSE) then
  begin
    FNeedCloseUI := Boolean(Message.wParam);
    Message.Result := 0;

    Terminate;
  end;
end;}

{procedure TPortalThread.ProcessMessage(MSG: TMSG);
var
  Message: TMessage;
begin
  Message.Msg := Msg.message;
  Message.WParam := MSG.wParam;
  Message.LParam := MSG.lParam;
  Message.Result := 0;
  Dispatch(Message);
end;}

procedure TMainForm.DoPowerPause;
var
  i: Integer;
begin
//  XLog('Power pause');

  i := 0;

//  DeleteAllPendingRequests;
//  CloseAllActiveUI;
//
//  AccountLogOut(nil);
//  HostLogOut;
end;

procedure TMainForm.DoPowerResume;
var
  i: Integer;
begin
  //XLog('Power resume');

  DeleteAllPendingRequests;
  CloseAllActiveUI;

  SetStatus(STATUS_NO_CONNECTION);

//  if tPHostThread <> nil then
//    tPHostThread.Restart; //Запустится при реактивации

//  SetConnectedState(False); //Сначала устанавливаем первичные насройки прокси
//  SetStatusString('Подключение к серверу...', True);
  StartAccountLogin;
  StartHostLogin;

//  CS_GW.Acquire;
//  try
//    for i := 0 to GatewayClientsList.Count - 1 do
//      if PGatewayRec(GatewayClientsList[i])^.GatewayClient^.LoginUserName <> '' then
//      begin
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.GParamsLoaded:=True;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//      end;
//  finally
//    CS_GW.Release;
//  end;
end;

procedure TMainForm.ShowAboutForm;
var
  fAboutForm: TfAboutForm;
begin
  //XLog('ShowAboutForm');

  try
    fAboutForm := TfAboutForm.Create(nil);
    fAboutForm.OnCustomFormClose := OnCustomFormClose;
    OnCustomFormOpen(@fAboutForm);
    fAboutForm.ShowModal;
  finally
    fAboutForm.Free;
  end;
end;

procedure TMainForm.ShowMessageBox(AText, ACaption, AType, AUID: string);
var
  fMessageBox: TfMessageBox;
begin
  //XLog('ShowMessageBox');

  try
    fMessageBox := TfMessageBox.Create(nil);
    fMessageBox.SetText(AText);
    fMessageBox.Caption := ACaption;
    fMessageBox.OnCustomFormClose := OnCustomFormClose;

    OnCustomFormOpen(@fMessageBox);
    if fMessageBox.ShowModal = mrOk then
    begin
      if AType = 'DeleteDeviceGroup' then
        DoDeleteDeviceGroup(AUID)
      else
      if AType = 'Exit' then
        DoExit;
    end;
  finally
    fMessageBox.Free;
  end;
end;

procedure TMainForm.miDeleteClick(Sender: TObject);
var
  Res: TModalResult;
  DData: PDeviceData;
begin
  //XLog('miDeleteClick');

  if twDevices.FocusedNode = nil then
    Exit;

  DData := twDevices.GetNodeData(twDevices.FocusedNode);
  if twDevices.GetNodeLevel(twDevices.FocusedNode) = 0 then
//    Res := MessageBox(Handle, PWideChar('Удалить группу "' + DData^.Name + '" и все компьютеры в ней?'), PWideChar('Remox'), MB_ICONWARNING or MB_YESNO)
    ShowMessageBox('Удалить группу "' + DData^.Name + '" и все устройства в ней?', 'Remox', 'DeleteDeviceGroup', DData^.UID)
  else
//    Res := MessageBox(Handle, PWideChar('Удалить устройство "' + DData^.Name + '"?'), PWideChar('Remox'), MB_ICONWARNING or MB_YESNO);
    ShowMessageBox('Удалить устройство "' + DData^.Name + '"?', 'Remox', 'DeleteDeviceGroup', DData^.UID);

//  if Res = mrNo then
//    Exit;

//  with cmAccounts.Data.NewFunction('Account.DeleteDeviceGroup') do
//  begin
//    asString['UID'] := DData^.UID;
//    asString['AccountUID'] := AccountUID;
//  end;
//  cmAccounts.Call(rDeleteDevice);
end;

procedure TMainForm.DoDeleteDeviceGroup(AUID: String);
begin
  //XLog('DoDeleteDeviceGroup');

  with cmAccounts do
  try
    with Data.NewFunction('Account.DeleteDeviceGroup') do
    begin
      asString['UID'] := AUID;
      asString['AccountUID'] := AccountUID;
      Call(rDeleteDevice);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.SendManualLogoutToControl(AAction, AControlID, AHostID: String);
begin
  //XLog('DoDeleteDeviceGroup');

  with cmAccounts do
  try
    with Data.NewFunction('Account.ManualLogout') do
    begin
      asString['Action'] := AAction;
      asString['ControlID'] := AControlID;
      asString['HostID'] := AHostID;
      Call(rManualLogout);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.miExitClick(Sender: TObject);
begin
  //XLog('miExitClick');

//  if ActiveUIList.Count > 0 then
//    ShowMessageBox('Имеются открытые подключения. Закрыть Remox?', 'Remox', 'Exit', '')
//  else
//  begin
    isClosing := True;
    Close;
//  end;
end;

procedure TMainForm.DoExit;
begin
  //XLog('DoExit');

  isClosing := True;
  Close;
end;

procedure TMainForm.SetStatusStringDelayed(AStatus: string; AInterval: Integer = 2000);
begin
  //XLog('SetStatusStringDelayed');

  DelayedStatus := AStatus;
  tDelayedStatus.Interval := AInterval;
  tDelayedStatus.Enabled := True;
end;

procedure TMainForm.tCheckServiceStartStopTimer(Sender: TObject);
begin
  //XLog('tCheckServiceStartStopTimer');

//  tCheckLockedStateTimer(nil);

  SetIDContolsVisible;
  ShowPermanentPasswordState;
end;

procedure TMainForm.tCheckUpdateStatusTimer(Sender: TObject);
var
  UpdateStatus, Progress: Integer;
begin
  if not FUpdateAvailable then
  begin
    tCheckUpdateStatus.Enabled := False;
    Exit;
  end;

  if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
    GetUpdateProgressFromService(UpdateStatus, Progress)
  else
    tDMUpdate.DMUpdate.GetProgress(UpdateStatus, Progress);

  if UpdateStatus = US_READY then
  begin
    tCheckUpdateStatus.Enabled := False;
    Exit;
  end;

  if UpdateStatus = US_READY then
  begin
    if FUpdateAvailable then
    begin
      bGetUpdate.Caption := 'Установить обновление';
      bGetUpdate.Font.Color := clRed;
    end
    else
    begin
      bGetUpdate.Caption := 'Последняя версия';
      bGetUpdate.Font.Color := clBlack;
    end;
  end
  else
  if UpdateStatus = US_DOWNLOADING then
  begin
    bGetUpdate.Caption := 'Загрузка ' + IntToStr(Ceil(Progress)) + '%';
    bGetUpdate.Font.Color := clBlack;
  end
  else
  if UpdateStatus = US_INSTALLING then
  begin
    bGetUpdate.Caption := 'Установка';
    bGetUpdate.Font.Color := clBlack;
  end;
end;

{procedure TMainForm.CheckUpdates;
var
  sResponse: String;
begin
  Exit;

  sResponse := RunHTTPCall('POST', 'http://remox.com', '/version', '');
  if (sResponse <> '')
    and (Length(sResponse) < 20)
    and (FileVersion(ParamStr(0)) <> sResponse) then
    FUpdateAvailable := True
  else
    FUpdateAvailable := False;
end;}

{function TMainForm.RunHTTPCall(verb, url, path, data: String): String;
var
  FHTTPClient: THTTPClient;
  LRequest: IHTTPRequest;
  LResponse: IHTTPResponse;
  LHeaders, LHeadersAuth: TNetHeaders;

  sContent: TStringStream;
begin
  Result := '';

  FHTTPClient := THTTPClient.Create;
  try
    try
      if (verb <> 'GET') then
      begin
        LRequest := FHTTPClient.GetRequest(verb, url + path);

        sContent := TStringStream.Create;
        sContent.WriteString(data);
        sContent.Position := 0;
        LRequest.SourceStream := sContent;
      end
      else
        LRequest := FHTTPClient.GetRequest(verb, url + path);

      LHeaders := [
        TNetHeader.Create('Content-Type', 'application/x-www-form-urlencoded'),
        TNetHeader.Create('Cache-Control', 'max-age=0'),
        TNetHeader.Create('Connection', 'Keep-Alive'),
        TNetHeader.Create('Keep-Alive', '90')];

      LResponse := FHTTPClient.Execute(LRequest, nil, LHeaders);

      Result := LResponse.ContentAsString;
    except
      on E: Exception do
        xLog('RunHTTPCall Error: ' + E.Message);
    end;
  finally
    FreeAndNil(sContent);
    FreeAndNil(FHTTPClient);
  end;
end;}

procedure TMainForm.SetIDContolsVisible;
var
  fIsServiceStarted: Boolean;
begin
  //XLog('SetIDContolsVisible');

  fIsServiceStarted := IsServiceStarted(RTC_HOSTSERVICE_NAME);

//  IsConsoleClient := (CurrentSessionID = GetActiveConsoleSessionId);

//  tCheckLockedState.Enabled := not (IsConsoleClient and fIsServiceStarted);
  lConsoleID.Visible := fIsServiceStarted and IsWinServer; //(not IsConsoleClient) and
  eConsoleID.Visible := fIsServiceStarted and IsWinServer; //(not IsConsoleClient) and
end;

{procedure TMainForm.SetHostActive;
begin
  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если это сервер терминалов
  if IsWinServer
    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
  begin
    PDesktopHost.GAllowView := True;
    PDesktopHost.GAllowView_Super := True;
    PDesktopHost.GAllowControl := True;
    PDesktopHost.GAllowControl_Super := True;
  end
  else
  begin
    PDesktopHost.GAllowView := False;
    PDesktopHost.GAllowView_Super := False;
    PDesktopHost.GAllowControl := False;
    PDesktopHost.GAllowControl_Super := False;
  end;
end;}

{procedure RunWithSystemToken(lpApplicationName, lpCommandLine, lpCurrentDirectory, lpDesktop: PWideChar);
var
   hToken, hUserToken: THandle;
   StartupInfo : TStartupInfoW;
   ProcessInfo : TProcessInformation;
   P : Pointer;
begin
  if NOT WTSQueryUserToken(WtsGetActiveConsoleSessionID, hUserToken) then exit;

  if not OpenProcessToken(
                         OpenProcess(PROCESS_ALL_ACCESS, False,
                         ProcessIDFromAppname32('winlogon.exe'))
                         ,
                         MAXIMUM_ALLOWED,
                         hToken) then exit;

  if CreateEnvironmentBlock(P, hUserToken, True) then
  begin
      ZeroMemory(@StartupInfo, sizeof(StartupInfo));
      StartupInfo.lpDesktop := lpDesktop;
      StartupInfo.wShowWindow := SW_SHOWNORMAL;
      if CreateProcessAsUserW(
            hToken,
            lpApplicationName,
            lpCommandLine,
            nil,
            nil,
            False,
            CREATE_UNICODE_ENVIRONMENT,
            P,
            lpCurrentDirectory,
            StartupInfo,
            ProcessInfo) then
      begin

      end;
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
      DestroyEnvironmentBlock(P);
  end;

  CloseHandle(hToken);
  CloseHandle(hUserToken);

  TerminateProcessByID(GetCurrentProcessId);
end;}

{procedure TMainForm.AppMessage(var Msg: TMsg; var Handled: Boolean);
var
//  strReason: string;
  tWork: TWorkThread;
  WindowPlacement: TWindowPlacement;
  err: BOOL;
  p: TPoint;
begin
  Handled := False;

  if Msg.Message = WM_TASKBAREVENT then
  begin
    if IsClosing then
      Exit;

    case LOWORD(Msg.LParam) of
      WM_LBUTTONDBLCLK:
      begin
        if (not IsWindowVisible(Application.Handle))
  //      if (WindowPlacement.showCmd = SW_HIDE)
          or (LOWORD(Msg.WParam) = 100) //100 - Повторный запуск exe
  //        or (WindowPlacement.showCmd = SW_SHOWMINIMIZED)
           then
        begin
          Visible := True;
          ShowWindow(Application.Handle, SW_SHOW);
          Application.Restore;
  //        Application.BringToFront;
  //        BringToFront;
  //        BringWindowToTop(Handle);
          SetForegroundWindow(Handle);
        end
        else
  //      if Message.WParamLo <> 1 then
        begin
          ShowWindow(Application.Handle, SW_HIDE);
          Visible := False;
  //        ShowWindow(Application.Handle, SW_HIDE);
        end;
      end;
      WM_RBUTTONUP:
      begin
  //      SetForegroundWindow(Handle);
        GetCursorPos(p);
        pmIconMenu.Popup(p.x, p.y);
        PostMessage(Handle, WM_NULL, 0, 0);
      end;
    end;
    Handled := True;
  end
  else
  // Check for WM_WTSSESSION_CHANGE message
  if Msg.Message = WM_WTSSESSION_CHANGE then
  begin
    case Msg.wParam of
      WTS_CONSOLE_CONNECT:
      begin
        tWork := TWorkThread.Create(True);
        tWork.FDoWork := SetIDContolsVisible;
        tWork.FreeOnTerminate := True;
        tWork.Resume;
      end;
      WTS_CONSOLE_DISCONNECT:
      begin
        tWork := TWorkThread.Create(True);
        tWork.FDoWork := SetIDContolsVisible;
        tWork.FreeOnTerminate := True;
        tWork.Resume;
      end;
//      WTS_REMOTE_CONNECT:
//        strReason := 'WTS_REMOTE_CONNECT';
//      WTS_REMOTE_DISCONNECT:
//        strReason := 'WTS_REMOTE_DISCONNECT';
//      WTS_SESSION_LOGON:
//        strReason := 'WTS_SESSION_LOGON';
//      WTS_SESSION_LOGOFF:
//        strReason := 'WTS_SESSION_LOGOFF';
//      WTS_SESSION_LOCK:
//        strReason := 'WTS_SESSION_LOCK';
//      WTS_SESSION_UNLOCK:
//        strReason := 'WTS_SESSION_UNLOCK';
//      WTS_SESSION_REMOTE_CONTROL:
//      begin
//        strReason := 'WTS_SESSION_REMOTE_CONTROL';
//        // GetSystemMetrics(SM_REMOTECONTROL);
//      end;
//    else
//      strReason := 'WTS_Unknown';
    end;
    Handled := True;
  end;
end;}

//Функция берёт строку в ANSI кодировке (Windows, CP1251)
//и возвращает её перевод в OEM кодировке (DOS, CP866)
//в виде отдельной строки.
function StrAnsiToOem(const aStr : String) : String;
var
  Len : Integer;
begin
  Result := '';
  Len := Length(aStr);
  if Len = 0 then
    Exit;
  SetLength(Result, Len);
  CharToOemBuff(PChar(aStr), PAnsiChar(Result), Len);
end;

//procedure TMainForm.SetStatusString(AStatus: String; AEnableTimer: Boolean = False);
//begin
//  XLog('SetStatusString');
//
//  CS_Status.Acquire;
//  try
//    tStatus.Enabled := AEnableTimer;
//
//    lblStatus.Caption := AStatus;
//    lblStatus.Update;
//
//    if (AStatus = 'Готов к подключению')
//      and (GetPendingRequestsCount = 0) then
//    begin
//      btnViewDesktop.Caption := 'ПОДКЛЮЧИТЬСЯ';
//      btnViewDesktop.Color := $00A39323;
//    end;
//  finally
//    CS_Status.Release;
//  end;
//end;

//procedure TMainForm.CreateParams(var Params: TCreateParams);
//begin
//  inherited;
//  if CheckWin32Version(5, 1) then
//    Params.ExStyle := Params.ExStyle or WS_EX_COMPOSITED;
//end;

//procedure TransStretchDraw(ACanvas: TCanvas; const Rect: TRect; SRC: TBitmap; TransParentColor: TColor);
//var
//  bmp, Mask: TBitmap;
//  p: PRGBTripleArray;
//  i, j: Integer;
//  r, g, b: Byte;
//begin
//  try
//    bmp := TBitmap.Create;
//    bmp.Assign(SRC);
//    Mask := TBitmap.Create;
//    Mask.Assign(SRC);
//    Mask.Mask(TransParentColor);
//
//    if BMP.PixelFormat = pf24bit then
//    begin
//      r := GetRValue(TransParentColor);
//      g := GetGValue(TransParentColor);
//      b := GetBValue(TransParentColor);
//      for j := 0 to bmp.Height - 1 do
//      begin
//        p := bmp.ScanLine[j];
//        for i := 0 to bmp.Width - 1 do
//        begin
//          if (P[i].rgbtRed = r) and (P[i].rgbtGreen = g) and (P[i].rgbtBlue = b) then
//          begin
//            p[i].rgbtRed := 0;
//            p[i].rgbtGreen := 0;
//            p[i].rgbtBlue := 0;
//          end;
//        end;
//      end;
//    end;
//
//    ACanvas.CopyMode := cmSrcCopy;//cmSrcAnd;
//    ACanvas.StretchDraw(rect, Mask);
//    ACanvas.CopyMode := cmSrcPaint;
//    ACanvas.StretchDraw(rect, bmp);
//  finally
//    Mask.free;
//    bmp.free;
//  end;
//end;

{procedure TMainForm.CheckSAS(value : Boolean; name : String);
var
  s,
  sErrValue : String;
begin
	if (not value) then
  begin
    case GetLastError() of
      776: //ERROR_REQUEST_OUT_OF_SEQUENCE
            	sErrValue := 'You need to call SASLibEx_Init first!';

			ERROR_PRIVILEGE_NOT_HELD:
				sErrValue := 'The function needs a system privilege that is not available in the process.';

			ERROR_FILE_NOT_FOUND:
				sErrValue := 'The supplied session is not available.';


			ERROR_CALL_NOT_IMPLEMENTED:
				sErrValue := 'The called function is not available in this demo (license).';


			ERROR_OLD_WIN_VERSION:
				sErrValue := 'The called function does not support the Windows system.';

    else
			sErrValue := SysErrorMessage(GetLastError());
		end;

		s := Format('The function call %s failed. '#13#10'%s',
			[name, sErrValue]);


		//MessageDlg(s,
		//	mtError, [mbOK], 0);
    xLog(s);
  end;
end;}

procedure TMainForm.ShowPermanentPasswordState();
begin
  //XLog('ShowPermanentPasswordState');

  if IsServiceStarting(RTC_HOSTSERVICE_NAME)
    or IsServiceStarted(RTC_HOSTSERVICE_NAME) then
  begin
    LabelPP2.Caption := 'Установите пароль для';
    LabelPP3.Caption := 'управления этим устройством в';
    LabelPP4.Visible := True;
    LabelPP5.Visible := True;

    if (PermanentPassword <> '') then
      iRegPassState.Picture.Assign(iRegPassYes.Picture)
    else
      iRegPassState.Picture.Assign(iRegPassNo.Picture);
  end
  else
  begin
    LabelPP2.Caption := 'Установите Remox для';
    LabelPP3.Caption := 'настройки неконтролируемого доступа';
    LabelPP4.Visible := False;
    LabelPP5.Visible := False;
    iRegPassState.Visible := False;
  end;
end;

//procedure TMainForm.WndProc(var Msg: TMessage);
//begin
//  if Msg.Msg = Broadcast_LogoffMessageID then
//  begin
//    HostLogOut;
//    Msg.Result := 1;
//  end
//  else
//    inherited;
//end;
//  case Msg.Msg of
//    WM_SYSCOMMAND:
//    begin
//      case Msg.WParam of
//      SC_RESTORE:
//        begin
//          SetForegroundWindow(Handle);
//          Msg.Result := 1;
//        end;
////      SC_MINIMIZE, SC_SCREENSAVE:
////        begin
////          Application.Minimize;
////          Msg.Result := 1;
////        end;
//      else
//        inherited;
//      end;
//    end;
//    WM_SHOWWINDOW:
//    begin
//      case BOOL(Msg.WParam) of
//      True:
//        begin
//          if Msg.LParam = SW_PARENTOPENING then
//            FormMinimized := False;
//          inherited;
//        end;
//      False:
//        begin
//          if Msg.LParam = SW_PARENTCLOSING then
//            FormMinimized := True;
//          inherited;
//        end;
//      else
//        inherited;
//      end;
//    end;
//    WM_ACTIVATE:
//    begin
//      if ((Msg.WParam = WA_ACTIVE)
//        or (Msg.WParam = WA_CLICKACTIVE))
//        and (not Visible or
//          FormMinimized)
//         and (not isClosing) then
//      begin
//        Visible := True;
//        Application.Restore;
//        SetForegroundWindow(Handle);
//        Msg.Result := 0;
//      end
//      else
//        inherited;
//    end
//    else
//      inherited;
//  end;
//end;

procedure TMainForm.WMTaskbarEvent(var Message: TMessage);
var
  WindowPlacement: TWindowPlacement;
  err: BOOL;
  p: TPoint;
begin
  //XLog('WMTaskbarEvent');

  if IsClosing then
    Exit;

  case Message.LParamLo of
    WM_LBUTTONDBLCLK:
    begin
      if (not IsWindowVisible(Application.Handle))
//      if (WindowPlacement.showCmd = SW_HIDE)
        or (Message.WParamLo = 100) //100 - Повторный запуск exe
//        or (WindowPlacement.showCmd = SW_SHOWMINIMIZED)
         then
      begin
        Visible := True;
        ShowWindow(Application.Handle, SW_SHOW);
        Application.Restore;
//        Application.BringToFront;
//        BringToFront;
//        BringWindowToTop(Handle);
        SetForegroundWindow(Handle);

        Message.Result := 0;
      end
      else
//      if Message.WParamLo <> 1 then
      begin
        ShowWindow(Application.Handle, SW_HIDE);
        Visible := False;
//        ShowWindow(Application.Handle, SW_HIDE);
        Message.Result := 0;
      end;
    end;
    WM_RBUTTONUP:
    begin
//      SetForegroundWindow(Handle);
      GetCursorPos(p);
      SetForegroundWindow(Handle);
      PostMessage(Handle, WM_NULL, 0, 0);
      pmIconMenu.Popup(p.x, p.y);
//      PostMessage(Handle, WM_NULL, 0, 0);

      Message.Result := 0;
    end;
  end;

//  inherited;
end;

procedure TMainForm.WMNCHitTest(var Message: TWMNCHitTest);
var
  P: TPoint;
  info: TTitleBarInfoEx ;
  icons: TBorderIcons;
begin
  icons := [biMinimize, biMaximize] - BorderIcons;
  if (biSystemMenu in BorderIcons) and (icons <> []) and not IsCustomStyleActive then
    begin
      P := Point(Message.XPos, Message.YPos);
      info.cbSize := SizeOf(TTitleBarInfoEx);
      if SendMessage(Handle, WM_GETTITLEBARINFOEX, 0, LPARAM(@info)) <> 0 then
        begin
          if info.rgrect[2].Contains(P) then
            Message.Result := HTMINBUTTON else
          if info.rgrect[3].Contains(P) then
            Message.Result := HTMAXBUTTON else
          if info.rgrect[5].Contains(P) then
            Message.Result := HTCLOSE;
          if ( (Message.Result = HTMINBUTTON) and (biMinimize in icons) ) or
             ( (Message.Result = HTMAXBUTTON) and (biMaximize in icons) ) then
             Message.Result := HTCAPTION;
        end;
    end;
  if Message.Result = 0 then
    inherited;
end;

//procedure TMainForm.WMLogEvent(var Message: TMessage);
//begin
//  Memo1.Lines.Add(String(Message.LParam));
//end;

procedure TMainForm.WMWTSSESSIONCHANGE(var Message: TMessage);
var
  tWork: TWorkThread;
begin
  //XLog('WMWTSSESSIONCHANGE');

  if IsClosing then
    Exit;

  case Message.WParam of
    WTS_CONSOLE_CONNECT:
    begin
      tWork := TWorkThread.Create(True);
      tWork.FDoWork := SetIDContolsVisible;
      tWork.FreeOnTerminate := True;
      tWork.Resume;

      Message.Result := 0;
    end;
    WTS_CONSOLE_DISCONNECT:
    begin
      tWork := TWorkThread.Create(True);
      tWork.FDoWork := SetIDContolsVisible;
      tWork.FreeOnTerminate := True;
      tWork.Resume;

      Message.Result := 0;
    end;
//      WTS_REMOTE_CONNECT:
//        strReason := 'WTS_REMOTE_CONNECT';
//      WTS_REMOTE_DISCONNECT:
//        strReason := 'WTS_REMOTE_DISCONNECT';
//      WTS_SESSION_LOGON:
//        strReason := 'WTS_SESSION_LOGON';
//      WTS_SESSION_LOGOFF:
//        strReason := 'WTS_SESSION_LOGOFF';
//      WTS_SESSION_LOCK:
//        strReason := 'WTS_SESSION_LOCK';
//      WTS_SESSION_UNLOCK:
//        strReason := 'WTS_SESSION_UNLOCK';
//      WTS_SESSION_REMOTE_CONTROL:
//      begin
//        strReason := 'WTS_SESSION_REMOTE_CONTROL';
//        // GetSystemMetrics(SM_REMOTECONTROL);
//      end;
//    else
//      strReason := 'WTS_Unknown';
  end;
end;

procedure EliminateListViewBeep;
var
  reg:TRegistry;
begin
  //XLog('EliminateListViewBeep');

  reg:=TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if reg.OpenKey('\AppEvents\Schemes\Apps\.Default\CCSelect\.current', False) then
    try
      if reg.ValueExists('') then
        if Trim(reg.ReadString('')) = '' then
          reg.DeleteValue('');
    finally
      reg.CloseKey;
    end;
    if reg.OpenKey('\AppEvents\Schemes\Apps\.Default\CCSelect\.Modified', False) then
    try
      if reg.ValueExists('') then
        if Trim(reg.ReadString('')) = '' then
          reg.DeleteValue('');
    finally
      reg.CloseKey;
    end;
  finally
    reg.Free;
  end;
end;

procedure TMainForm.AddPortalConnection(AThread: TPortalThread; AThreadID: Cardinal; AAction, AUserName, AUserPass, AUserToConnect: String; AStartLockedState: Integer; AStartServiceStarted: Boolean);
var
  pPC: PPortalConnection;
begin
  CS_GW.Acquire;
  try
    New(pPC);
    pPC^.ThreadID := AThreadID;
    pPC^.Thread := AThread;
    pPC^.Action := AAction;
    pPC^.UserName := AUserName;
    pPC^.UserPass := AUserPass;
    pPC^.ID := AUserToConnect;
    pPC^.StartLockedState := AStartLockedState;
    pPC^.StartServiceStarted := AStartServiceStarted;
    pPC^.DataModule := nil;
    pPC^.UIHandle := 0;
    PortalConnectionsList.Add(pPC);
  finally
    CS_GW.Release;
  end;
end;

function TMainForm.GetPortalConnection(AAction: String; AUserName: String): PPortalConnection;
var
  i: Integer;
begin
  //XLog('GetPortalConnection');

  Result := nil;

  CS_GW.Acquire;
  try
    for i := 0 to PortalConnectionsList.Count - 1 do
      if (PPortalConnection(PortalConnectionsList[i])^.Action = AAction)
        and (PPortalConnection(PortalConnectionsList[i])^.UserName = AUserName) then
      begin
        if (PPortalConnection(PortalConnectionsList[i])^.DataModule = nil)
          or (not PPortalConnection(PortalConnectionsList[i])^.DataModule.NeedFree) then
        begin
          Result := PortalConnectionsList[i];
          Break;
        end;
      end;
  finally
    CS_GW.Release;
  end;
end;

procedure TMainForm.RemovePortalConnection(AID, AAction: String; ACloseFUI: Boolean);
var
  i: Integer;
begin
  //XLog('RemovePortalConnection');

  CS_GW.Acquire;
  try
    i := PortalConnectionsList.Count - 1;
    while i >= 0 do
    begin
      if (PPortalConnection(PortalConnectionsList[i])^.ID = AID)
        and (PPortalConnection(PortalConnectionsList[i])^.Action = AAction) then
      begin
//        if (PPortalConnection(PortalConnectionsList[i])^.ThisThread <> nil) then
//        begin
////          PPortalConnection(PortalConnectionsList[i])^.ThisThread^.Terminate;
////          PPortalConnection(PortalConnectionsList[i])^.ThisThread^.WaitFor;
////          PPortalConnection(PortalConnectionsList[i])^.ThisThread^.Free;
////          PPortalConnection(PortalConnectionsList[i])^.ThisThread := nil;
//          FreeAndNil(PPortalConnection(PortalConnectionsList[i])^.ThisThread);
//        end;
        PPortalConnection(PortalConnectionsList[i])^.Thread.SetNeedCloseUI(ACloseFUI);
        PPortalConnection(PortalConnectionsList[i])^.Thread.Terminate;
        //PostThreadMessage(PPortalConnection(PortalConnectionsList[i])^.ThreadID, WM_CLOSE, WPARAM(ACloseFUI), 0); //Закрываем поток с пклиентом
//        if ACloseFUI
//          and ((PPortalConnection(PortalConnectionsList[i])^.Action = 'file') or (PPortalConnection(PortalConnectionsList[i])^.Action = 'chat')) then
//          PostMessage(PPortalConnection(PortalConnectionsList[i])^.UIHandle, WM_CLOSE, 0, 0); //Закрываем форму UI. Нужно при отмене подключения

//        Dispose(PPortalConnection(PortalConnectionsList[i])^.UIForm);
        Dispose(PortalConnectionsList[i]);
        PortalConnectionsList.Delete(i);
      end;

      i := i - 1;
    end;
  finally
    CS_GW.Release;
  end;

//  if GatewayClientsList.Count = 1 then
//    Application.Restore;
end;

procedure TMainForm.aFeedBackExecute(Sender: TObject);
var
  pAccUserName: String;
begin
  //XLog('aFeedBackExecute');

//  ShellExecute(Handle, 'Open', 'mailto:admin@remox.com', nil, nil, SW_RESTORE);
//  if LoggedIn then
//    pAccUserName := eAccountUserName.Text
//  else
//    pAccUserName := '';                    //PChar('mailto:support@remox.com?body=<BR><BR><BR>Account:' + AccountName + '<BR>Device ID:' + PClient.LoginUserInfo.asText['RealName'])
  ShellExecute(Application.Handle, 'open', 'http://remox.com/feedback', nil, nil, SW_SHOW);
end;

procedure TMainForm.aMinimizeExecute(Sender: TObject);
begin
  //XLog('aMinimizeExecute');

  Application.Minimize;
end;

procedure TMainForm.ApplicationEventsRestore(Sender: TObject);
begin
  //XLog('ApplicationEventsRestore');

  SetForegroundWindow(Handle);
end;

procedure TMainForm.aServiceInstallExecute(Sender: TObject);
//var
//  err: LongInt;
begin
//  if (Win32MajorVersion >= 6 {vista\server 2k8}) then
//  begin
//    if not ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
//    begin
//      SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/INSTALL', Handle, True, Application.ProcessMessages));
//      err := GetLastError;
//      if err <> ERROR_SUCCESS then
//        xLog('ServiceInstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
//      SetServiceMenuAttributes;
//    end;
//  end;
end;

{procedure TMainForm.SetServiceMenuAttributes;
begin
  if (Win32MajorVersion >= 6) then //vista\server 2k8
  begin
    if ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
    begin
      mmiService.Visible := True;
      mmiSeparator2.Visible := True;

      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
      begin
        mmiServiceInstall.Visible := False;
        mmiServiceStartStop.Caption := 'Остановить';
        mmiServiceStartStop.Visible := True;
        mmiServiceUninstall.Visible := True;
      end
      else
      begin
        mmiServiceInstall.Visible := False;
        mmiServiceStartStop.Caption := 'Запустить';
        mmiServiceStartStop.Visible := True;
        mmiServiceUninstall.Visible := True;
      end
    end
    else
    begin
      mmiServiceInstall.Visible := True;
      mmiServiceStartStop.Visible := False;
      mmiServiceUninstall.Visible := False;
    end;
  end
  else
  begin
    mmiService.Visible := False;
    mmiSeparator2.Visible := False;
  end;
end;}

procedure TMainForm.aServiceStartStopExecute(Sender: TObject);
//var
//  err: LongInt;
begin
{  if (Win32MajorVersion >= 6) then //vista\server 2k8
  begin
    if ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
    begin
      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
      begin
        SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/STOP', Handle, True, Application.ProcessMessages));
        err := GetLastError;
        if err <> ERROR_SUCCESS then
          xLog('erviceStartStop error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
      end
      else
      begin
        SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/START', Handle, True, Application.ProcessMessages));
        err := GetLastError;
        if err <> ERROR_SUCCESS then
          xLog('erviceStartStop error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
      end;
    end;
    SetServiceMenuAttributes;
  end;}
end;

procedure TMainForm.aServiceUninstallExecute(Sender: TObject);
//var
//  fn: String;
//  err: LongInt;
begin
{  if (Win32MajorVersion >= 6) then //vista\server 2k8
  begin
    if ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
    begin
      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
      begin
        with TStringList.Create do
        try
          if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
          Add(ParamStr(0) + ' /STOP');
          Add(ParamStr(0) + ' /UNINSTALL');
          Add('PING 127.0.0.1 -n 1 > NUL');
//          Add('START ' + ParamStr(0));
          fn := GetTempFile + '.bat';
          Add('DEL "' + fn + '"');
          SaveToFile(fn, TEncoding.GetEncoding(866));
        finally
          Free;
        end;
//      rtcStartProcess(ChangeFileExt(ParamStr(0), '.bat'));
//      SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/UNINSTALL', Handle, False, Application.ProcessMessages));
        SetLastError(EleavateSupport.RunElevated(fn, '', Handle, False, Application.ProcessMessages));
//        SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/UNINSTALL', Handle, False, Application.ProcessMessages));
        err := GetLastError;
        if err <> ERROR_SUCCESS then
          xLog('ServiceUninstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
      end
      else
      begin
        SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/UNINSTALL', Handle, True, Application.ProcessMessages));
        err := GetLastError;
        if err <> ERROR_SUCCESS then
          xLog('ServiceUninstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
      end;
      SetServiceMenuAttributes;
    end;
  end;}
end;

procedure TMainForm.cmMainMenuColorChange(Sender: TObject);
begin

end;

//procedure ScaleCtrls(Control: TWinControl; WW, PW, HH, PH: Integer);
//var
//  I: Integer;
//begin
//  for I := 0 to Control.ControlCount - 1 do
//    ChangeDims(Control.Controls[i], WW, PW, HH, PH);
//end;
//
//procedure ChangeDims(Control: TControl; WW, PW, HH, PH: Integer);
//var
//  L, T, W, H: integer;
//begin
//  if Control is TWinControl then
//    (Control as TWinControl).DisableAlign;
//  try
//    if Control is TWinControl then
//      ScaleCtrls(Control as TWinControl, WW, PW, HH, PH);
//    L := Math.Ceil((WW / PW) * Control.Left * GetScaleKoeff); //MulDiv(Control.Left, WW, PW);
////    T := MulDiv(Control.Top, HH, PH);
//    T := Math.Ceil((WW / PW) * Control.Top * GetScaleKoeff); //MulDiv(Control.Top, WW, PW);
//    W := Math.Ceil((WW / PW) * (Control.Left + Control.Width) * GetScaleKoeff) - L; //MulDiv(Control.Left + Control.Width, WW, PW) - L;
////    H := MulDiv(Control.Top + Control.Height, HH, PH) - T;
//    H := Math.Ceil((WW / PW) * (Control.Top + Control.Height) * GetScaleKoeff) - T; //MulDiv(Control.Top + Control.Height, WW, PW) - T;
//
//    if Control is TLabel then
//      TLabel(Control).Font.Size := Floor((WW / PW) * TLabel(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TEdit then
//      TEdit(Control).Font.Size := Floor((WW / PW) * TEdit(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TAlignedEdit then
//      TAlignedEdit(Control).Font.Size := Floor((WW / PW) * TAlignedEdit(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TComboBox then      //Math.Ceil
//      TComboBox(Control).Font.Size := Floor((WW / PW) * TComboBox(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TActionMainMenuBar then
//      TActionMainMenuBar(Control).Font.Size := Floor((WW / PW) * TActionMainMenuBar(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TSpeedButton then
//      TSpeedButton(Control).Font.Size := Floor((WW / PW) * TSpeedButton(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TPanel then
//      TPanel(Control).Font.Size := Floor((WW / PW) * TPanel(Control).Font.Size * GetScaleKoeff)
//    else
//    if Control is TVirtualStringTree then
//    begin
//      TVirtualStringTree(Control).Font.Size := Floor((WW / PW) * TVirtualStringTree(Control).Font.Size * GetScaleKoeff);
//      TVirtualStringTree(Control).DefaultNodeHeight := Floor((WW / PW) * TVirtualStringTree(Control).DefaultNodeHeight * GetScaleKoeff);
//    end;
////    THackControl(Control).Font.Size := (PW div WW) * THackControl(Control).Font.Size;
//    Control.SetBounds(L, T, W, H);
//    if Control.Name = 'iRegPassState' then
//      Control.Height := Control.Width;
//  finally
//    if Control is TWinControl then
//      (Control as TWinControl).EnableAlign;
//  end;
//end;

procedure TMainForm.ShowDevicesPanel;
begin
  //XLog('ShowDevicesPanel');

//  Constraints.MinWidth := 0;
//  Constraints.MaxWidth := 0;

  if LoggedIn then
  begin
    pDevices.Visible := True;
    pAccount.Visible := False;

    miAccLogOut.Caption := 'Выход (' + AccountName + ')';
  end
  else
  begin
    pDevices.Visible := False;
    pAccount.Visible := True;

    miAccLogOut.Caption := 'Выход';

//    Constraints.MaxWidth := Width;
  end;
//  Constraints.MinWidth := 852;

  FormResize(nil);
end;

//procedure TMainForm.UpdateButtons;
//const
//  cWidth = 20;
//  AwesomeIcons : Array[0..11] of Word = (
//  fa_home, fa_signal, fa_search, fa_envelope_o, fa_remove, fa_gear,
//  fa_twitter, fa_user, fa_arrow_circle_o_down, fa_arrow_circle_o_up, fa_check, fa_power_off);
//var
// iLeft, i, LImageIndex : integer;
// LNCControl : TNCButton;
//begin
//   iLeft:=5;
//   if NCControls.ShowSystemMenu then
//    iLeft:=30;
//
//   NCControls.ButtonsList.Clear;
//   NCControls.ButtonsList.BeginUpdate;
//   try
//     for i:=0 to 10 do
//     begin
//        LNCControl := NCControls.ButtonsList.Add;
//        LNCControl.Name      := Format('NCButton%d', [i+1]);
//        LNCControl.Hint      := Format('Hint for NCButton%d', [i+1]);
//        LNCControl.ShowHint  := True;
//        LNCControl.Caption   := '';
//        LNCControl.Style     := nsTranparent;
//        LNCControl.ImageStyle:= isGrayHot;
//        LNCControl.ImageAlignment := TImageAlignment.iaCenter;
//
//        LNCControl.UseFontAwesome:=True;
//
//        if LNCControl.UseFontAwesome then
//          LImageIndex:= AwesomeIcons[i]
//        else
//          LImageIndex:=i;
//
//        LNCControl.ImageIndex:=LImageIndex;
//
//        LNCControl.ImageAlignment := TImageAlignment.iaCenter;
//        LNCControl.BoundsRect  := Rect(iLeft, 5, iLeft + cWidth, 25);
//        inc(iLeft, cWidth + 2);
////        LNCControl.OnClick   := ButtonNCClick;
//     end;
//   finally
//     NCControls.ButtonsList.EndUpdate;
//   end;
//
//end;

procedure TMainForm.UpdateOnSuccessCheck(Sender: TObject);
begin
//  SetLastCheckUpdateTime(Now);
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  err: LongInt;
begin
  //XLog('FormCreate');

  FProgressDialogsList := TList.Create;

  HintWindowClass := TRmxHintWindow;

  FUpdateAvailable := False;

  SessionPassword := '';

  tDMUpdate := TDMUpdateThread.Create(False, UpdateOnSuccessCheck);

  DeviceId := '';
  DeviceUID := '';
  ConsoleId := '';
  ConsoleUID := '';

  DesktopsForm := TrdDesktopViewer.Create(Self);
  DesktopsForm.OnUIOpen := OnUIOpen;
  DesktopsForm.OnUIClose := OnUIClose;
  DesktopsForm.DoStartFileTransferring := StartFileTransferring;
  DesktopsForm.ReconnectToPartnerStart := ReconnectToPartnerStart;

  PassForm := TfIdentification.Create(Application);

  ActivationInProcess := False;
  AccountLoginInProcess := False;

  FStatusUpdateThread := TStatusUpdateThread.Create(False, UpdateStatus);
  tPHostThread := nil;

  OpenedModalForm := nil;
  SettingsFormOpened := False;

  tActivateHost.Enabled := False;

  isClosing := False;

  pBtnSetup.Visible := not IsServiceExisted(RTC_HOSTSERVICE_NAME);

//  EleavateSupport := TEleavateSupport.Create(DoElevatedTask);

//  if (Win32MajorVersion = 5 {xp}) then
//    AddExceptionToFireWall
//  else
//  if (Win32MajorVersion >= 6 {vista\server 2k8}) then
//  begin
  //Доделать. Добавлять только при установке
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '/ADDRULES', Handle, Application.ProcessMessages));
//    if GetLastError <> ERROR_SUCCESS then
//      RaiseLastOSError;
//  end;

//  GatewayClientsList := TList.Create;
  PendingRequests := TList.Create;
//  ActiveUIList := TList.Create;
  PortalConnectionsList := TList.Create;

  PowerWatcher := TPowerWatcher.Create(nil);
  PowerWatcher.OnPowerPause := DoPowerPause;
  PowerWatcher.OnPowerResume := DoPowerResume;

  //TVclStylesSystemMenu.Create(Self);
//  NCControls := TNCControls.Create(Self);
//  UpdateButtons;

//  ActionManager1.Style := PlatformVclStylesStyle;

//  if Win32MajorVersion = 10 then
//  begin
//    cbClose.ButtonLeft := 9;
//    cbClose.ButtonWidth := 45;
//    cbClose.ButtonTop := -7;
//    cbClose.ButtonHeight := 29;
//
//    cbMin.ButtonLeft := -3;
//    cbMin.ButtonWidth := 45;
//    cbMin.ButtonTop := -7;
//    cbMin.ButtonHeight := 29;
//  end;

  tHcAccountsReconnect.Enabled := True;
  tTimerClientReconnect.Enabled := True;
  tHostTimerClientReconnect.Enabled := True;
  tPClientReconnect.Enabled := False;

  MainFormHandle := Handle;

  FScreenLockedState := LCK_STATE_UNLOCKED;

  FormMinimized := False;

  do_notify := False;

  twDevices.NodeDataSize := SizeOf(TDeviceData);
  twIncomes.NodeDataSize := SizeOf(TDeviceData);

  ClientHeight := 488;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;

//  AutoScaleForm(Self);

//  Options := nil;
//  PassForm := nil;
//  GForm := nil;
//  DForm := nil;
//  fReg := nil;

  // Eliminate annoying Vista BEEP bug when using ListView
  EliminateListViewBeep;

//  Pages.ActivePage:=Page_Setup;
//  Page_Hosting.TabVisible:=False;

  { We will set all our background Threads to a higher priority,
    so we can get enough CPU time even when there are applications
    with higher priority running at 100% CPU. }
  RTC_THREAD_PRIORITY := tpHigher;

  TaskBarIcon := False;
  TaskBarAddIcon;
  ReqCnt1 := 0;
  ReqCnt2 := 0;

  StartLog;
//  xLog('Start');

//  PFileTrans.FileInboxPath:= ExtractFilePath(AppFileName) + '\INBOX';

//  Left:=(Screen.Width-Width) div 2;
//  Top:=(Screen.Height-Height) div 2;

  LoadSetup('ALL');
  SetStatus(STATUS_NO_CONNECTION);
//  SetConnectedState(False); //Сначала устанавливаем первичные насройки прокси
//  SetStatusString('Подключение к серверу...', True);
  StartAccountLogin;
  StartHostLogin;
  ShowPermanentPasswordState();
//  AutoScaleForm(MainForm);
//  Width := CurWidth;
  LoggedIn := False;
  pcDevAcc.ActivePageIndex := 0;
  ShowDevicesPanel;
//  SetHostActive;

  //cPriorityChange(nil);
  SetPriorityClass(GetCurrentProcess, NORMAL_PRIORITY_CLASS);

//  PClient.RetryOtherCalls := 5;

  //eUserName.Text:=PClient.LoginUsername;
//  ePassword.Text:=PClient.LoginPassword;
  // Custom User Info (can be anything you want/need)
//  eRealName.Text:=PClient.LoginUserInfo.asText['RealName'];

//  SilentMode := Pos('/SILENT', UpperCase(CmdLine)) > 0;

//  if SilentMode then
//  begin
//    xLog('Started in silent mode');
//    if Pos('/MINIMIZED', UpperCase(CmdLine)) > 0 then
//    begin
//      ShowWindow(Application.Handle, SW_HIDE);
//      Application.Minimize;
//    end;
//
//    miExitSeparator.Visible := False;
//    miExit.Visible := False;
//  end;

//  if Pos('-AUTORUN', UpperCase(CmdLine)) > 0 Then
//    PostMessage(Handle, WM_AUTORUN, 0, 0);

//  SetServiceMenuAttributes;

  SetIDContolsVisible;

// register the window to receive session change notifications.
  FRegisteredSessionNotification := RegisterSessionNotification(Handle, NOTIFY_FOR_THIS_SESSION);
//  Application.OnMessage := AppMessage;

// DisableAero;
  CB_Monitor := TClipbrdMonitor.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  i: Integer;
  x: String;
begin
  //XLog('FormDestroy');

  FreeAndNil(CB_Monitor);

  tDMUpdate.Terminate;

  FStatusUpdateThread.Terminate;

//  RestoreAero;

  PowerWatcher.Destroy;

  // unregister session change notifications.
  if FRegisteredSessionNotification then
    UnRegisterSessionNotification(Handle);

  PendingRequests.Free;
//  ActiveUIList.Free;
//  EleavateSupport.Free;
//  GatewayClientsList.Free;

  for i := 0 to PortalConnectionsList.Count - 1 do
    Dispose(PortalConnectionsList[i]);
  PortalConnectionsList.Free;

  if tPHostThread <> nil then
    tPHostThread.Terminate;

  TaskBarRemoveIcon;
//  if Assigned(Options) then
//  begin
//    Options.Free;
//  end;
//  if Assigned(sett) then
//  begin
//    sett.Free;
//  end;
//  if Assigned(PassForm) then
//  begin
//    PassForm.Free;
//  end;
//  if Assigned(GForm) then
//  begin
//    GForm.Free;
//  end;
//  if Assigned(DForm) then
//  begin
//    DForm.Free;
//  end;

//  PClient.Disconnect;
//  PClient.Active := False;
//  PClient.Stop;

//  CS_GW.Acquire;
//  try
//    for i := 1 to GatewayClientsList.Count - 1 do
//    begin
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Stop;
//
//      FreeGatewayRec(GatewayClientsList[i]);
//
//      Dispose(GatewayClientsList[i]);
//      GatewayClientsList.Delete(i);
//    end;
//  finally
//    CS_GW.Release;
//  end;

  i := ePartnerID.Items.Count - 1;
  while i >= 0 do
  begin
    THistoryRec(ePartnerID.Items.Objects[i]).Destroy;
    ePartnerID.Items.Delete(i);

    i := i - 1;
  end;

  for i := 0 to FProgressDialogsList.Count - 1 do
  begin
    FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
    Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
    Dispose(FProgressDialogsList[i]);
  end;
  FreeAndNil(FProgressDialogsList);

  PassForm.Free;
  DesktopsForm.Free;
end;

procedure TMainForm.FormHide(Sender: TObject);
var
  i: Integer;
begin
//  XLog('FormHide');
end;

{function TMainForm.DoElevatedTask(const AHost, AParameters: String; AWait: Boolean): Cardinal;
//  procedure InstallUpdate;
//  var
//    Msg: String;
//  begin
//    Msg := 'Hello from InstallUpdate!' + sLineBreak +
//           sLineBreak +
//           'This function is running elevated under full administrator rights.' + sLineBreak +
//           'This means that you have write-access to Program Files folder and you''re able to overwrite files (e.g. install updates).' + sLineBreak +
//           'However, note that your executable is still running.' + sLineBreak +
//           sLineBreak +
//           'IsAdministrator: '        + BoolToStr(EleavateSupport.IsAdministrator, True) + sLineBreak +
//           'IsAdministratorAccount: ' + BoolToStr(EleavateSupport.IsAdministratorAccount, True) + sLineBreak +
//           'IsUACEnabled: '           + BoolToStr(EleavateSupport.IsUACEnabled, True) + sLineBreak +
//           'IsElevated: '             + BoolToStr(EleavateSupport.IsElevated, True);
//    MessageBox(0, PChar(Msg), 'Hello from InstallUpdate!', MB_OK or MB_ICONINFORMATION);
//  end;
var
  sHost, sParams: String;
begin
  if AWait then
    ExecAndWait(AHost, AParameters, SW_HIDE)
  else
  begin
    sHost := Host;
    sParams := AParameters;
    UniqueString(sHost);
    UniqueString(sParams);
    ShellExecute(0, 'open', PChar(sHost), PChar(sParams), nil, SW_HIDE);
  end;

  Result := ERROR_SUCCESS;

//  if AParameters = '/INSTALL' then
//    InstallUpdate
//  else
//    Result := ERROR_GEN_FAILURE;
end;}

//function ExecAndWait(const FileName,
//                     Params: ShortString;
//                     const WinState: Word): boolean;
//var
//  StartInfo: TStartupInfo;
//  ProcInfo: TProcessInformation;
//  CmdLine: ShortString;
//begin
//  { Помещаем имя файла между кавычками, с соблюдением всех пробелов в именах Win9x }
//  CmdLine := '"' + Filename + '" ' + Params;
//  FillChar(StartInfo, SizeOf(StartInfo), #0);
//  with StartInfo do
//  begin
//    cb := SizeOf(StartInfo);
//    dwFlags := STARTF_USESHOWWINDOW;
//    wShowWindow := WinState;
//  end;
//  Result := CreateProcess(nil, PChar(string(CmdLine)), nil, nil, false,
//                          CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil,
//                          PChar(ExtractFilePath(Filename)),StartInfo,ProcInfo);
//  { Ожидаем завершения приложения }
//  if Result then
//  begin
//    WaitForSingleObject(ProcInfo.hProcess, INFINITE);
//    { Free the Handles }
//    CloseHandle(ProcInfo.hProcess);
//    CloseHandle(ProcInfo.hThread);
//  end;
//end;

procedure TMainForm.SetProxyFromIE;
var
  ProxyEnabled: Boolean;
  ProxyServer, CurProxy: String;
  ProxyPort, i: Integer;
begin
  //XLog('SetProxyFromIE');

  ProxyEnabled := False;
//  PClient.Gate_Proxy := False;
//  PClient.Gate_ProxyAddr := '';
//  hcAccounts.UseProxy := False;
//  hcAccounts.UserLogin.ProxyAddr := '';

  GetProxyData(ProxyEnabled, ProxyServer, ProxyPort);

  CurProxy := '';
  if ProxyEnabled
    and (ProxyServer <> '') then
      CurProxy := ProxyServer + ':' + IntToStr(ProxyPort);

  if (hcAccounts.UseProxy <> ProxyEnabled)
    or (hcAccounts.UserLogin.ProxyAddr <> CurProxy) then
  begin
{//    CS_GW.Acquire;
//    try
//      for i := 0 to GatewayClientsList.Count - 1 do
//      begin
        PClient.Disconnect;
        if (PClient.LoginUserName <> '')
          and (PClient.LoginUserName <> '') then
          PClient.Active := False;
        PClient.Gate_Proxy := ProxyEnabled;
        PClient.Gate_ProxyAddr := CurProxy;
  //      PClient.GParamsLoaded:=True;
        if (PClient.LoginUserName <> '')
          and (PClient.LoginUserName <> '') then
          PClient.Active := True;
//      end;
//    finally
//      CS_GW.Release;
//    end;}

    if tPHostThread <> nil then
    begin
      tPHostThread.ProxyEnabled := ProxyEnabled;
      if ProxyEnabled then
        tPHostThread.ProxyAddr := CurProxy
      else
        tPHostThread.ProxyAddr := '';
    end;

    hcAccounts.AutoConnect := False;
    TimerClient.AutoConnect := False;
    HostTimerClient.AutoConnect := False;
    hcAccounts.DisconnectNow(True, 0, True, True);
    TimerClient.DisconnectNow(True, 0, True, True);
    HostTimerClient.DisconnectNow(True, 0, True, True);

    hcAccounts.UseProxy := ProxyEnabled;
    TimerClient.UseProxy := ProxyEnabled;
    HostTimerClient.UseProxy := ProxyEnabled;
    if ProxyEnabled then
    begin
      hcAccounts.UserLogin.ProxyAddr := CurProxy;
      TimerClient.UserLogin.ProxyAddr := CurProxy;
      HostTimerClient.UserLogin.ProxyAddr := CurProxy;
    end
    else
    begin
//      CS_GW.Acquire;
//      try
//        for i := 0 to GatewayClientsList.Count - 1 do
//          PClient.Gate_ProxyAddr := '';
//      finally
//        CS_GW.Release;
//      end;

      hcAccounts.UserLogin.ProxyAddr := '';
      TimerClient.UserLogin.ProxyAddr := '';
      HostTimerClient.UserLogin.ProxyAddr := '';
    end;

    hcAccounts.AutoConnect := True;
    hcAccounts.Connect(True, True);
    TimerClient.AutoConnect := True;
    TimerClient.Connect(True, True);
    HostTimerClient.AutoConnect := True;
    HostTimerClient.Connect(True, True);
  end;
end;

function TMainForm.GetStatus: Integer;
begin
  CS_Status.Acquire;
  try
    Result := FCurStatus;
  finally
    CS_Status.Release;
  end;
end;

procedure TMainForm.SetStatus(Status: Integer);
begin
  CS_Status.Acquire;
  try
    FCurStatus := Status;
  finally
    CS_Status.Release;
  end;
end;

{procedure TMainForm.SetStatus(Status: Integer);
var
  bmp: TBitmap;
begin
  XLog('SetStatus: ' + IntToStr(Status));

  CS_Status.Acquire;
  try
    CurStatus := Status;

    ConnectedToAllGateways := (Status >= 3);

    if Status = 4 then
      SetStatusString('Подключение к серверу...')
    else
    if Status = 5 then
      SetStatusString('Готов к подключению');

    bmp := TBitmap.Create;
    if Status > 0 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus1.Picture.Bitmap.Assign(bmp);
    iStatus1.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if Status > 1 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus2.Picture.Bitmap.Assign(bmp);
    iStatus2.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if Status > 2 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus3.Picture.Bitmap.Assign(bmp);
    iStatus3.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if Status > 3 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus4.Picture.Bitmap.Assign(bmp);
    iStatus4.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if Status > 4 then
    begin
      ilStatus.GetBitmap(1, bmp);
      CurIconState := 'ONLINE';
      TaskBarIconUpdate(CurIconState);
    end
    else
    begin
      ilStatus.GetBitmap(0, bmp);
      CurIconState := 'OFFLINE';
      TaskBarIconUpdate(CurIconState);
    end;
    iStatus5.Picture.Bitmap.Assign(bmp);
    iStatus5.Update;
    bmp.Free;
  finally
    CS_Status.Release;
  end;
end;}

function TMainForm.AddDotsToString(sCurString: String): String;
var
  i: Integer;
  sDots: String;
begin
  i := Length(sCurString);
  sDots := '';
  while (i > 1) do
  begin
    if (Copy(sCurString, i, 1) = '.') then
    begin
      i := i - 1;
      Continue;
    end
    else
    if (Copy(sCurString, i, 1) <> '.') then
    begin
      sDots := Copy(sCurString, i + 1, Length(sCurString) - i);
      Break;
    end;

    i := i - 1;
  end;

  if Length(sDots) = 0 then
    Result := '.'
  else
  if Length(sDots) = 1 then
    Result := '..'
  else
  if Length(sDots) = 2 then
    Result := '...'
  else
  if Length(sDots) = 3 then
    Result := '....'
  else
  if Length(sDots) = 4 then
    Result := '.'
end;

procedure TMainForm.UpdateStatus;
var
  bmp: TBitmap;
  sDots: String;
  UpdateStatus: Integer;
  Progress: Double;
begin
  //XLog('SetStatus: ' + IntToStr(CurStatus));

  CS_Status.Acquire;
  try
    SetConnectedState(CurStatus >= STATUS_CONNECTING_TO_GATE);

    if DelayedStatus <> '' then
      lblStatus.Caption := DelayedStatus
    else if GetPendingRequestsCount > 0 then
    begin
      sDots := AddDotsToString(lblStatus.Caption);
      lblStatus.Caption := 'Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName);
      lblStatus.Caption := lblStatus.Caption + sDots;
    end
    else if CurStatus = STATUS_NO_CONNECTION then
    begin
      sDots := AddDotsToString(lblStatus.Caption);
      lblStatus.Caption := 'Проверка подключения';
      lblStatus.Caption := lblStatus.Caption + sDots;
    end
    else if CurStatus = STATUS_ACTIVATING_ON_MAIN_GATE then
    begin
      sDots := AddDotsToString(lblStatus.Caption);
      lblStatus.Caption := 'Активация устройства';
      lblStatus.Caption := lblStatus.Caption + sDots;
    end
    else if CurStatus = STATUS_CONNECTING_TO_GATE then
    begin
      sDots := AddDotsToString(lblStatus.Caption);
      lblStatus.Caption := 'Подключение к серверу';
      lblStatus.Caption := lblStatus.Caption + sDots;
    end
    else if CurStatus = STATUS_READY then
      lblStatus.Caption := 'Готов к подключению';

    if GetPendingRequestsCount > 0 then
    begin
      btnNewConnection.Caption := 'ПРЕРВАТЬ';
      btnNewConnection.Color := RGB(232, 17, 35);
    end
    else
    begin
      btnNewConnection.Caption := 'ПОДКЛЮЧИТЬСЯ';
      btnNewConnection.Color := $00A39323;
    end;

    btnNewConnection.Enabled := ConnectedToAllGateways;
    btnAccountLogin.Enabled := (not LoggedIn) and ConnectedToAllGateways and (not AccountLoginInProcess);

    bmp := TBitmap.Create;
    if CurStatus >= 0 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus1.Picture.Bitmap.Assign(bmp);
    iStatus1.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if CurStatus >= 1 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus2.Picture.Bitmap.Assign(bmp);
    iStatus2.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if CurStatus >= 2 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus3.Picture.Bitmap.Assign(bmp);
    iStatus3.Update;
    bmp.Free;

    bmp := TBitmap.Create;
    if CurStatus >= 3 then
      ilStatus.GetBitmap(1, bmp)
    else
      ilStatus.GetBitmap(0, bmp);
    iStatus4.Picture.Bitmap.Assign(bmp);
    iStatus4.Update;
    bmp.Free;

    TaskBarIconUpdate(CurStatus = 3);
  finally
    CS_Status.Release;
  end;
end;

procedure TMainForm.SetConnectedState(fConnected: Boolean);
var
  i: Integer;
begin
//  CS_SetConnectedState.Acquire;
//  try
    if isClosing then
      Exit;

//    if fConnected then
//      XLog('SetConnectedState: Connected')
//    else
//      XLog('SetConnectedState: Not Connected');

    if fConnected then
    begin
//      HostPingTimer.Enabled := True;

  //    ePartnerID.Enabled := True;

  //    rbDesktopControl.Enabled := True;
  //    rbFileTrans.Enabled := True;

  //    btnViewDesktop.Enabled := True;
  //    btnRegistration.Enabled := True;
  //    btnAccountLogin.Enabled := True;

  //    btnViewDesktop.Font.Color := clWhite;
  //    btnRegistration.Font.Color := clWhite;
  //    btnAccountLogin.Font.Color := clWhite;

  //    if not isClosing then
  //      for i := 0 to Length(GatewayClients) - 1 do
  //      begin
  //        if not GatewayClients[i].GatewayClient.Active then
  //          GatewayClients[i].GatewayClient.Active := True;
  //      end;
    end
    else
    begin
//      HostPingTimer.Enabled := False;

      eConsoleID.Text := '-';
      eUserName.Text := '-';
      ePassword.Text := '-';
      ConsoleId := '';

      LoggedIn := False;
      ShowDevicesPanel;

      DeleteAllPendingRequests;
      CloseAllActiveUI;

//      SetStatusString('Проверка подключения к интернету...');
//
//      SetStatus(STATUS_NO_CONNECTION);
//
//      StartAccountLogin;

//      if not IsInternetConnected then
//      begin
////        SetStatus(0);
//        SetStatusString('Отсутствует сетевое подключение');
//
//  //      if ProxyOption = PO_AUTOMATIC then
//  //      begin
//  //        SetStatusString('Определение прокси-сервера', True);
//  //        SetProxyFromIE;
//  //      end;
//        Exit;
//      end;

  //    ePartnerID.Enabled := False;

  //    rbDesktopControl.Enabled := False;
  //    rbFileTrans.Enabled := False;

  //    btnViewDesktop.Font.Color := clBlack; //$00DDDDDD;;
  //    btnRegistration.Font.Color :=  clBlack; //$00DDDDDD;
  //    btnAccountLogin.Font.Color :=  clBlack; //$00DDDDDD;
  //
  //    btnViewDesktop.Enabled := False;
  //    btnRegistration.Enabled := False;
  //    btnAccountLogin.Enabled := False;

  //    for i := 0 to Length(ActiveUIList) - 1 do
  //      if ActiveUIList[i] <> nil then
  //      begin
  //        PostMessage(ActiveUIList[i].Handle, WM_CLOSE, 0, 0);
  //        RemoveActiveUIRecByHandle(ActiveUIList[i].Handle);
  //      end;
  //    SetLength(ActiveUIList, 0);
  //
  //    AccountLogOut(nil);
  //
  //    if not isClosing then
  //      for i := 0 to Length(GatewayClients) - 1 do
  //      begin
  //        if GatewayClients[i].GatewayClient.Active then
  //          GatewayClients[i].GatewayClient.Active := False;
  //        GatewayClients[i].GatewayClient.Stop;
  //      end;
    end;
//  finally
//    CS_SetConnectedState.Release;
//  end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
//  XLog('FormResize');

  pcDevAcc.Left := 542;
  pcDevAcc.Width := ClientWidth - pcDevAcc.Left; //pRight.Left - pRight.Width - GetScaleValue(25);
  bGetUpdate.Left := pInMain.Left + pInMain.Width - bGetUpdate.Width;
//  CurWidth := Width;
end;

(* Load/Save Configuration *)

procedure TMainForm.Label11Click(Sender: TObject);
begin
//  XLog('Label11Click');

  cbRememberAccount.Checked := not cbRememberAccount.Checked;
end;

procedure TMainForm.lDesktopControlClick(Sender: TObject);
begin
//  XLog('lDesktopControlClick');

  if rbDesktopControl.Enabled then
  begin
    rbDesktopControl.Checked := True;
    rbFileTrans.Checked := False;
  end;
end;

procedure TMainForm.lFileTransClick(Sender: TObject);
begin
//  XLog('lFileTransClick');

  if rbFileTrans.Enabled then
  begin
    rbFileTrans.Checked := True;
    rbDesktopControl.Checked := False;
  end;
end;

procedure TMainForm.LabelPP5Click(Sender: TObject);
begin
//  XLog('Label22Click');

  ShowSettingsForm('tsGeneral');
end;

procedure TMainForm.lHelpClick(Sender: TObject);
//var
//  p: TPoint;
begin
//  p.X := lHelp.Left + iBkgLeft.Left;
//  p.Y := lHelp.Top + lHelp.Height + pInMain.Top;
//  p := ClientToScreen(p);
//  pmHelp.PopupComponent := lHelp;
//  pmHelp.Popup(p.X, p.Y);
end;

procedure TMainForm.GeneratePassword;
  var
    letters: array[0..55] of char;
    i: Integer;
begin
//  XLog('GeneratePassword');

  letters[0] := '0';
  letters[1] := '1';
  letters[2] := '2';
  letters[3] := '3';
  letters[4] := '4';
  letters[5] := '5';
  letters[6] := '6';
  letters[7] := '7';
  letters[8] := '8';
  letters[9] := '9';
  letters[10] := 'a';
  letters[11] := 'b';
  letters[12] := 'c';
  letters[13] := 'd';
  letters[14] := 'd';
  letters[15] := 'f';
  letters[16] := 'g';
  letters[17] := 'h';
  letters[18] := 'i';
  letters[19] := 'g';
  letters[20] := '0';
  letters[21] := '1';
  letters[22] := '2';
  letters[23] := '3';
  letters[24] := '4';
  letters[25] := '5';
  letters[26] := '6';
  letters[27] := '7';
  letters[28] := '8';
  letters[29] := '9';
  letters[30] := 'k';
  letters[31] := 'm';
  letters[32] := 'n';
  letters[33] := 'o';
  letters[34] := 'p';
  letters[35] := 'q';
  letters[36] := 'r';
  letters[37] := 's';
  letters[38] := 't';
  letters[39] := '0';
  letters[40] := '1';
  letters[41] := '2';
  letters[42] := '3';
  letters[43] := '4';
  letters[44] := '5';
  letters[45] := '6';
  letters[46] := '7';
  letters[47] := '8';
  letters[48] := '9';
  letters[49] := 'u';
  letters[50] := 'v';
  letters[51] := 'w';
  letters[52] := 'x';
  letters[53] := 'y';
  letters[54] := 'z';

  ePassword.Text := '';

  for i := 1 to 6 do
    ePassword.Text := ePassword.Text + letters[Random(54)];

  SessionPassword := System.Hash.THashMD5.GetHashString(ePassword.Text);

//  PClient.LoginPassword := Trim(ePassword.Text);
end;

procedure TMainForm.hcAccountsConnect(Sender: TRtcConnection);
begin
//  xLog('hcAccountsConnect');
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsConnect'));

  tHcAccountsReconnect.Enabled := False;

//  ActivateHost;

  tActivateHost.Enabled := True;
end;

procedure TMainForm.hcAccountsConnectError(Sender: TRtcConnection; E: Exception);
begin
  xLog('hcAccountsConnectError: ' + E.Message);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsConnectError '+ E.Message));

//  if (not tHcAccountsReconnect.Enabled)
//   and (not isClosing)
//    and (not SettingsUpdateInProcess)
//   then
//  begin
//    SetStatusString('Сервер недоступен');
//    tHcAccountsReconnect.Enabled := True;
//    SetConnectedState(False);
//  end;    \

//  tHcAccountsReconnect.Enabled := True;
end;

procedure TMainForm.hcAccountsConnectFail(Sender: TRtcConnection);
begin
  xLog('hcAccountsConnectFail');
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsConnectFail'));

//  if not tConnect.Enabled
//    and (not SettingsUpdateInProcess) then
//  begin
//    SetStatusString('Сервер недоступен');
//    tConnect.Enabled := True;
//    SetConnectedState(False);
//  end;

  tHcAccountsReconnect.Enabled := True;
end;

procedure TMainForm.hcAccountsConnectLost(Sender: TRtcConnection);
begin
  xLog('hcAccountsConnectLost');
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsConnectFail'));

//  if not tConnect.Enabled
//    and (not SettingsUpdateInProcess) then
//  begin
//    SetStatusString('Сервер недоступен');
//    tConnect.Enabled := True;
//    SetConnectedState(False);
//  end;

//  if (not tHcAccountsReconnect.Enabled)
//    and (not isClosing)
//    and (not SettingsUpdateInProcess) then
//  begin
//    SetStatusString('Сервер недоступен');
//    SetConnectedState(False);
//    if not isClosing then
//      tHcAccountsReconnect.Enabled := True;
//  end;
end;

procedure TMainForm.hcAccountsDisconnect(Sender: TRtcConnection);
begin
//  xLog('hcAccountsDisconnect');
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsDisconnect'));

//  if csDestroying in ComponentState then
//    Exit;

  if (not tHcAccountsReconnect.Enabled)
    and (not isClosing)
    and (not SettingsFormOpened) then
  begin
//    SetStatusString('Сервер недоступен');
    ActivationInProcess := False;
    SetStatus(STATUS_NO_CONNECTION);
//    SetConnectedState(False);
    if not isClosing then
      tHcAccountsReconnect.Enabled := True;
  end;

  tActivateHost.Enabled := False;

//  CloseAllActiveUI;
  ChangePort(hcAccounts);
end;

procedure TMainForm.hcAccountsException(Sender: TRtcConnection; E: Exception);
begin
  xLog('hcAccountsException: ' + E.Message);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsException' + E.Message));
end;

procedure TMainForm.hcAccountsReconnect(Sender: TRtcConnection);
begin
//  xLog('hcAccountsReconnect');
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsReconnect'));
end;

procedure TMainForm.FriendList_Status(uname: String; status: Integer);
var
  Node: PVirtualNode;
  PortalConnection: PPortalConnection;
//  username: String;
begin
//  XLog('FriendList_Status');

  Node := twDevices.GetFirst;
  while Node <> nil do
  begin
    if TDeviceData(twDevices.GetNodeData(Node)^).ID = GetUserFromFromUserName(uname) then
    begin
      TDeviceData(twDevices.GetNodeData(Node)^).StateIndex := status;
      twDevices.InvalidateNode(Node);
      Break;
    end;
    Node := twDevices.GetNext(Node);
  end;

  if status = MSG_STATUS_OFFLINE then
  begin
//    Node := NodeByID(twDevices, StrToInt(RemoveUserPrefix(uname)));
//    if Node <> nil then
//      username := TDeviceData(twDevices.GetNodeData(Node)^).Name
//    else
//      username := uname;
//    if Copy(lblStatus.Caption, 1, Length('Подключение к ' + username)) = 'Подключение к ' + username then
//      SetStatusString('Готов к подключению');

//    RemovePortalConnectionByUser(uname);
//    DeletePendingRequests(uname);
  end;
end;

function TMainForm.GetUserNameByID(uname: String): String;
var
  Data: PDeviceData;
begin
//  XLog('GetUserNameByID');

  Data := GetDeviceInfo(uname);
  if Data <> nil then
    Result := Data^.Name
  else
    Result := uname;
end;

procedure TMainForm.Locked_Status(uname: String; aLockedStatus: Integer; aServiceStarted: Boolean);
//var
//  i: Integer;
//  pPC: PPortalConnection;
begin
//  XLog('Locked_Status');

//  CS_GW.Acquire;
//  try
//    for i := 0 to PortalConnectionsList.Count - 1 do
//    begin
//      pPC := PPortalConnection(PortalConnectionsList[i]);
//      if pPC^.ID = uname then
//        PostMessage(pPC^.DMHandle, WM_CHANGE_LOCKED_STATUS, aLockedStatus, Byte(aServiceStarted));
//    end;
//  finally
//    CS_GW.Release;
//  end;

  DesktopsForm.ChangeLockedState(uname, aLockedStatus, aServiceStarted);
end;

function TMainForm.PartnerNeedHideWallpaper(AUserName: String): Boolean;
var
  reg: TRegistry;
begin
//  xLog('PartnerNeedHideDesktop');

  Result := True;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if reg.KeyExists('Software\Remox\Partners\' + AUserName) then
      if reg.OpenKey('Software\Remox\Partners\' + AUserName, False) then
      begin
        if reg.ValueExists('HideWallpaper') then
          Result := reg.ReadBool('HideWallpaper');

        reg.CloseKey;
      end;
  finally
    reg.Free;
  end;
end;

function TMainForm.PartnerGetQualitySetting(AUserName: String): Integer;
var
  reg: TRegistry;
begin
//  xLog('PartnerNeedHideDesktop');

  Result := DS_QUIALITY;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if reg.KeyExists('Software\Remox\Partners\' + AUserName) then
      if reg.OpenKey('Software\Remox\Partners\' + AUserName, False) then
      begin
        if reg.ValueExists('DisplaySetting') then
          Result := reg.ReadInteger('DisplaySetting');

        reg.CloseKey;
      end;
  finally
    reg.Free;
  end;
end;

procedure TMainForm.LoadSetup(RecordType: String);
var
  reg: TRegistry;
begin
//  xLog('LoadSetup: ' + RecordType);

  if (RecordType = 'ALL')
    or (RecordType = 'PERMANENT_PASS') then
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_LOCAL_MACHINE;
      reg.Access := KEY_READ or KEY_WOW64_64KEY;
      if reg.ValueExists('PermanentPassword') then
        PermanentPassword := reg.ReadString('PermanentPassword')
      else
        PermanentPassword := '';

      reg.CloseKey;
    finally
      reg.Free;
    end;
  end;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if reg.KeyExists('Software\Remox') then
    begin
      reg.OpenKey('Software\Remox', False);

      if (RecordType = 'ALL') then
      begin
        if reg.ValueExists('StoreHistory') then
          StoreHistory := reg.ReadBool('StoreHistory')
        else
          StoreHistory := True;
        if reg.ValueExists('StorePasswords') then
          StorePasswords := reg.ReadBool('StorePasswords')
        else
          StorePasswords := True;

        if reg.ValueExists('RememberAccount') then
          cbRememberAccount.Checked := reg.ReadBool('RememberAccount')
        else
          cbRememberAccount.Checked := True;
        if reg.ValueExists('AccountUserName') then
          eAccountUserName.Text := reg.ReadString('AccountUserName')
        else
          eAccountUserName.Text := '';
        if reg.ValueExists('AccountPassword') then
        begin
          if reg.ReadString('AccountPassword') <> '' then
            eAccountPassword.Text := 'password'
          else
            eAccountPassword.Text := '';
          AccountPassword := reg.ReadString('AccountPassword');
        end
        else
        begin
          eAccountPassword.Text := '';
          AccountPassword := '';
        end;

        if reg.ValueExists('DateAllowConnectPending') then
          DateAllowConnectionPending := reg.ReadDateTime('DateAllowConnectPending');

        if reg.ValueExists('ProxyOption') then
          ProxyOption := reg.ReadInteger('ProxyOption')
        else
          ProxyOption := PO_AUTOMATIC;
//        'socks=127.0.0.1:9050'; //Tor

        hcAccounts.UseProxy := (ProxyOption = PO_MANUAL);
        TimerClient.UseProxy := (ProxyOption = PO_MANUAL);
        HostTimerClient.UseProxy := (ProxyOption = PO_MANUAL);
        if reg.ValueExists('ProxyAddr') then
        begin
          hcAccounts.UserLogin.ProxyAddr := reg.ReadString('ProxyAddr');
          TimerClient.UserLogin.ProxyAddr := reg.ReadString('ProxyAddr');
          HostTimerClient.UserLogin.ProxyAddr := reg.ReadString('ProxyAddr');
        end
        else
        begin
          hcAccounts.UserLogin.ProxyAddr := '';
          TimerClient.UserLogin.ProxyAddr := '';
          HostTimerClient.UserLogin.ProxyAddr := '';
        end;
        if reg.ValueExists('ProxyUsername') then
        begin
          hcAccounts.UserLogin.ProxyUserName := reg.ReadString('ProxyUsername');
          TimerClient.UserLogin.ProxyUserName := reg.ReadString('ProxyUsername');
          HostTimerClient.UserLogin.ProxyUserName := reg.ReadString('ProxyUsername');
        end
        else
        begin
          hcAccounts.UserLogin.ProxyUserName := '';
          TimerClient.UserLogin.ProxyUserName := '';
          HostTimerClient.UserLogin.ProxyUserName := '';
        end;
        if reg.ValueExists('ProxyPassword') then
        begin
          hcAccounts.UserLogin.ProxyPassword := reg.ReadString('ProxyPassword');
          TimerClient.UserLogin.ProxyPassword := reg.ReadString('ProxyPassword');
          HostTimerClient.UserLogin.ProxyPassword := reg.ReadString('ProxyPassword');
        end
        else
        begin
          hcAccounts.UserLogin.ProxyPassword := '';
          TimerClient.UserLogin.ProxyPassword := '';
          HostTimerClient.UserLogin.ProxyPassword := '';
        end;
      end;

      if (RecordType = 'ALL')
        or (RecordType = 'ACTIVE_NODE') then
        if reg.ValueExists('LastFocusedUID') then
          LastFocusedUID := reg.ReadString('LastFocusedUID')
        else
          LastFocusedUID := '';
    end
    else
    begin
      StoreHistory := True;
      StorePasswords := True;
      cbRememberAccount.Checked := True;
    end;

    reg.CloseKey;
  finally
    reg.Free;
  end;

//  if tPHostThread.Gateway = '' then
//    tPHostThread.Gateway := '95.216.96.6';
  if hcAccounts.ServerAddr = '' then
    hcAccounts.ServerAddr := '95.216.96.6';
  if TimerClient.ServerAddr = '' then
    TimerClient.ServerAddr := '95.216.96.6';
  if HostTimerClient.ServerAddr = '' then
    HostTimerClient.ServerAddr := '95.216.96.6';
end;

procedure TMainForm.SaveSetup;
var
  reg: TRegistry;
begin
//  xLog('SaveSetup');

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if not reg.OpenKey('Software\Remox', True) then
      Exit;

    reg.WriteBool('StoreHistory', StoreHistory);
    reg.WriteBool('StorePasswords', StorePasswords);
    reg.WriteInteger('ProxyOption', ProxyOption);
    reg.WriteString('ProxyAddr', hcAccounts.UserLogin.ProxyAddr);
    reg.WriteString('ProxyPassword', hcAccounts.UserLogin.ProxyUserName);
    reg.WriteString('ProxyUsername', hcAccounts.UserLogin.ProxyPassword);
    reg.WriteBool('RememberAccount', cbRememberAccount.Checked);
    reg.WriteString('AccountUserName', Trim(eAccountUserName.Text));
    if cbRememberAccount.Checked then
      reg.WriteString('AccountPassword', AccountPassword)
    else
      reg.WriteString('AccountPassword', '');
    reg.WriteString('LastFocusedUID', LastFocusedUID);
    reg.WriteDateTime('DateAllowConnectPending', DateAllowConnectionPending);
  finally
    reg.Free;
  end;
end;

procedure TMainForm.miFileTransClick(Sender: TObject);
var
  user:string;
  i: Integer;
  DData: PDeviceData;
begin
//  XLog('miFileTransClick');

  if (twDevices.FocusedNode <> nil) and
     (twDevices.GetNodeLevel(twDevices.FocusedNode) <> 0) then
  begin
    DData := PDeviceData(twDevices.GetNodeData(twDevices.FocusedNode));
    user := DData^.ID;

    StartFileTransferring(user, DData^.Name, DData^.Password);
  end;
end;

procedure TMainForm.StartFileTransferring(AUser, AUserName, APassword: String; ANeedGetPass: Boolean = False);
var
  sPassword: String;
  i: Integer;
begin
//  XLog('StartFileTransferring');

  if PassForm.Active then
    Exit;

  if AUser = DeviceId then
  begin
//      MessageBox(Handle, 'Подключение к своему устройству невозможно', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Подключение к своему устройству невозможно');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Exit;
  end;
//    if DData^.StateIndex = MSG_STATUS_OFFLINE then
//    begin
//      MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
//      SetStatusString('Готов к подключению');
//      Exit;
//    end;

  if ANeedGetPass then
    sPassword := GetUserPassword(AUser)
  else
    sPassword := APassword;

  //Если ранее был сохранен верный пароль берем его, а не из списка устройств
  if StorePasswords then
  begin
    for i := 0 to ePartnerID.Items.Count - 1 do
      if THistoryRec(ePartnerID.Items.Objects[i]).user = AUser then
      begin
        sPassword := THistoryRec(ePartnerID.Items.Objects[i]).password;
        Break;
      end;
  end;

  ConnectToPartnerStart(AUser, AUserName, sPassword, 'file');
end;

{procedure TMainForm.ConnectToPartner(GatewayRec: PGatewayRec; user, username, action: String);
//var
//  i: Integer;
//  fFound: Boolean;
begin
//  //Добавим в историю при успешном логине
//  fFound := False;
//  for i := 0 to ePartnerID.Items.Count - 1 do
//    if ePartnerID.Items[i] = user then
//    begin
//      fFound := True;
//      Break;
//    end;
//  if not fFound then
//      ePartnerID.Items.Insert(0, user);

  // If the Host was using a colorful Wallpaper, without hiding the wallpaper,
  // receiving the initial Desktop Screen could take quite a while.
  // To hide the Dektop wallpaper on the Host, you can use the "Send_HideDesktop" method.
//    if xHideWallpaper.Checked then
//      PDesktopControl.Send_HideDesktop(user);

  // If you would like to change Hosts Desktop Viewer settings
  // before the initial screen is being prepared for sending by the Host,
  // this is where you could call "PDesktopControl.ChgDesktop_" methods ...
  // The example below would set the Host to use 9bit colors and 25FPS frame rate ...
//    if xReduceColors.Checked then
//      begin
//      PDesktopControl.ChgDesktop_Begin;
//      PDesktopControl.ChgDesktop_ColorLimit(rdColor8bit);
//      // PDesktopControl.ChgDesktop_FrameRate(rdFrames25);
//      PDesktopControl.ChgDesktop_UseMouseDriver
//      PDesktopControl.ChgDesktop_End(user);
//      end;

  if action = 'desk' then
  begin
    GatewayRec^.DesktopControl^.ChgDesktop_Begin;
    GatewayRec^.DesktopControl^.ChgDesktop_UseMouseDriver(False);
    GatewayRec^.DesktopControl^.ChgDesktop_CaptureLayeredWindows(False);
    GatewayRec^.DesktopControl^.ChgDesktop_End(user);

    GatewayRec^.DesktopControl^.Open(user);
  end
  else
  if action = 'file' then
    GatewayRec^.FileTransfer^.Open(user)
  else
  if action = 'chat' then
    GatewayRec^.Chat^.Open(user);
end;}

procedure TMainForm.miShowFormClick(Sender: TObject);
begin
//  XLog('miShowFormClick');

//  if not Visible then
//  begin
    Visible := True;
    Application.Restore;
    Application.BringToFront;
    BringToFront;
    BringWindowToTop(Handle);
    //TaskBarRemoveIcon;
//  end;
end;

procedure TMainForm.miWebSite2DrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; Selected: Boolean);
var
  LeftPos: Integer;
  TopPos: Integer;
  TextLength: Integer;
  Text: string;
begin
  Text := StringReplace((Sender as TMenuItem).Caption, '&', '', [rfReplaceAll]);
  if Selected then
    ACanvas.Brush.Color := RGB(204, 232, 255) //$00D2D2D2
  else
    ACanvas.Brush.Color := clWhite; //$00FFFFFF;
  ACanvas.FillRect(ARect);
  ACanvas.Font.Color := $00000000; //cl3DDkShadow;
  if (Sender as TMenuItem).Default then
    ACanvas.Font.Style := [fsBold];
  if Text <> '-' then
  begin
    TopPos := ARect.Top +
      (ARect.Bottom - ARect.Top - ACanvas.TextHeight('W')) div 2;
    TextLength := Length(Text);
      LeftPos := ARect.Left + 5 + 1;
    ACanvas.TextOut(LeftPos, TopPos, Text);
  end
  else
  begin
    TopPos := ARect.Top + (ARect.Bottom - ARect.Top) div 2;
    TextLength := Length(Text);
      LeftPos := ARect.Left + 31;
    ACanvas.Rectangle(5, TopPos - 1, ARect.Width, TopPos);
  end;
end;

procedure TMainForm.miWebSiteClick(Sender: TObject);
begin
//  XLog('miWebSiteClick');

  ShellExecute(0, 'open', PChar('http://remox.com'), '', nil, SW_SHOW);
end;

procedure TMainForm.miAccLogOutClick(Sender: TObject);
begin
//  XLog('miAccLogOutClick');

  SaveSetup;

  AccountLogOut(Sender);
end;

function TMainForm.GetSelectedGroup(): PVirtualNode;
begin
  Result := nil;
  if twDevices.FocusedNode <> nil then
    if twDevices.GetNodeLevel(twDevices.FocusedNode) = 0 then
      Result := twDevices.FocusedNode
    else
      Result := twDevices.FocusedNode.Parent;
end;

function TMainForm.GetGroupByUID(UID: String): PVirtualNode;
var
  Node: PVirtualNode;
begin
  Node := twDevices.GetFirst();
  while Node <> nil do
  begin
    if PDeviceData(twDevices.GetNodeData(Node))^.UID = UID then
    begin
      Result := Node;
      Exit;
    end;

    Node := Node.NextSibling;
  end;
end;

procedure TMainForm.miAddDeviceClick(Sender: TObject);
var
  Node: PVirtualNode;
  DData: PDeviceData;
  DForm: TDeviceForm;
begin
//  XLog('miAddDeviceClick');

  DForm := TDeviceForm.Create(Self);
  //  DForm.Parent := Self;
  //  AutoScaleForm(DForm);
  try
    DForm.twDevices := twDevices;
    DForm.CModule := @cmAccounts;
    DForm.AccountUID := AccountUID;
    DForm.user := eUserName.Text;
    DForm.GetDeviceInfoFunc := GetDeviceInfo;
    Node := GetSelectedGroup();
    if Node <> nil then
      DForm.GroupUID := PDeviceData(twDevices.GetNodeData(Node))^.UID;
    DForm.Mode := 'Add';
    DForm.OnCustomFormClose := OnCustomFormClose;

    OnCustomFormOpen(@DForm);
    DForm.ShowModal();
    if DForm.ModalResult = mrOk then
    begin
      Node := twDevices.AddChild(GetGroupByUID(DForm.GroupUID));
      Node.States := [vsInitialized, vsVisible];
      DData := twDevices.GetNodeData(Node);
      DData^.UID := DForm.UID;
      DData^.Name := DForm.eName.Text;
      DData^.Password := System.Hash.THashMD5.GetHashString(DForm.ePassword.Text);
      DData^.Description := DForm.mDescription.Lines.GetText;
      DData^.GroupUID := DForm.GroupUID;
      DData^.ID := DForm.eID.Text;
      DData^.HighLight := False;
      if DeviceId = DForm.eID.Text then
        DData^.StateIndex := MSG_STATUS_ONLINE
      else
        DData^.StateIndex := MSG_STATUS_OFFLINE;

      if not twDevices.Expanded[Node.Parent] then
        twDevices.Expanded[Node.Parent] := True;
      twDevices.ToggleNode(Node);
      twDevices.Selected[Node] := True;
      twDevices.FocusedNode := Node;
      twDevices.SortTree(0, sdAscending);
      twDevices.InvalidateNode(Node);

      twDevices.TopNode := NodeByUID(twDevices, DForm.UID);

      DoGetDeviceState(eAccountUserName.Text,
        LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll])),
        AccountPassword,
        DForm.eID.Text);
    end;
  finally
    DForm.Free;
  end;
end;

procedure TMainForm.DoGetDeviceState(Account, User, Pass, Friend: String);
begin
//  XLog('DoGetDeviceState');

  with cmAccounts do
  try
    with Data.NewFunction('Account.GetDeviceState') do
    begin
      asString['Account'] := Account;
      asWideString['User'] := User;
//      asWideString['Pass'] := Pass;
      asString['Friend'] := Friend;
      Call(resGetState);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.miAddGroupClick(Sender: TObject);
var
  GroupNode, Node: PVirtualNode;
  DData: PDeviceData;
  GForm: TGroupForm;
begin
//  XLog('miAddGroupClick');

  GForm := TGroupForm.Create(Self);
//  GForm.Parent := Self;
//  AutoScaleForm(GForm);
  try
    GForm.twDevices := twDevices;
    GForm.CModule := @cmAccounts;
    GForm.AccountUID := AccountUID;
    GForm.Mode := 'Add';
    GForm.OnCustomFormClose := OnCustomFormClose;

    OnCustomFormOpen(@GForm);
    GForm.ShowModal();
    if GForm.ModalResult = mrOk then
    begin
      GroupNode := twDevices.AddChild(nil, Pointer(DData)); //Trim(GForm.eName.Text)
      GroupNode.States := [vsInitialized, vsVisible, vsHasChildren];
      DData := twDevices.GetNodeData(GroupNode);
      DData^.UID := GForm.UID;
      DData^.Name := Trim(GForm.eName.Text);
      DData^.HighLight := False;
      DData^.StateIndex := MSG_STATUS_UNKNOWN;
//        GroupNode.SelectedIndex := -1;

      Node := twDevices.AddChild(GroupNode);
      Node.States := [vsInitialized];
      DData := twDevices.GetNodeData(Node);
      DData^.UID := '';
      DData^.ID := '';
      DData^.HighLight := False;
      DData^.StateIndex := MSG_STATUS_OFFLINE;

      twDevices.ToggleNode(GroupNode);
      twDevices.Selected[GroupNode] := True;
      twDevices.SortTree(0, sdAscending);
      twDevices.InvalidateNode(GroupNode);
    end;
  finally
    GForm.Free;
  end;
end;

procedure TMainForm.miChangeClick(Sender: TObject);
var
  DData: PDeviceData;
  GroupUID: String;
  GroupNode: PVirtualNode;
  DForm: TDeviceForm;
  GForm: TGroupForm;
begin
//  XLog('miChangeClick');

  DData := twDevices.GetNodeData(twDevices.FocusedNode);
  if twDevices.GetNodeLevel(twDevices.FocusedNode) = 0 then
  begin
    GForm := TGroupForm.Create(Self);
//    GForm.Parent := Self;
//    AutoScaleForm(GForm);
    try
      GForm.twDevices := twDevices;
      GForm.CModule := @cmAccounts;
      GForm.AccountUID := AccountUID;
      GForm.UID := DData^.UID;
      GForm.eName.Text := DData^.Name;
      GForm.Mode := 'Change';
      GForm.ShowModal();
      if GForm.ModalResult = mrOk then
      begin
        DData^.Name := Trim(GForm.eName.Text);
        twDevices.InvalidateNode(twDevices.FocusedNode);
        twDevices.SortTree(0, sdAscending);
      end;
    finally
      GForm.Free;
    end;
  end
  else
  begin
    DForm := TDeviceForm.Create(Self);
//    DForm.Parent := Self;
//    AutoScaleForm(DForm);
    try
      DForm.twDevices := twDevices;
      DForm.CModule := @cmAccounts;
      DForm.AccountUID := AccountUID;
      DForm.UID := DData^.UID;
      DForm.eID.Text := DData^.ID;
      DForm.eName.Text := DData^.Name;
      DForm.PrevPassword := DData^.Password;
      if DData^.Password <> '' then
        DForm.ePassword.Text := 'password'
      else
        DForm.ePassword.Text := '';
      DForm.mDescription.Text := DData^.Description;
      DForm.GroupUID := DData^.GroupUID;
      DForm.GetDeviceInfoFunc := GetDeviceInfo;
      DForm.Mode := 'Change';
      DForm.ShowModal();
      if DForm.ModalResult = mrOk then
      begin
        DData^.Name := DForm.eName.Text;
        if DForm.PasswordChanged then
          DData^.Password := System.Hash.THashMD5.GetHashString(DForm.ePassword.Text)
        else
          DData^.Password := DForm.PrevPassword;
        DData^.Description := DForm.mDescription.Lines.GetText;
        DData^.ID := DForm.eID.Text;
        DData^.HighLight := False;
//          DData^.StateIndex := MSG_STATUS_OFFLINE;
        GroupNode := GetGroupByUID(DForm.GroupUID);
        GroupUID := PDeviceData(twDevices.GetNodeData(GroupNode)).UID;
        if DData^.GroupUID <> GroupUID then
        begin
          twDevices.MoveTo(twDevices.FocusedNode, GroupNode, amAddChildLast, False);
          if not twDevices.Expanded[GroupNode] then
            twDevices.Expanded[GroupNode] := True;
        end;
        DData^.GroupUID := GroupUID;

        twDevices.InvalidateNode(twDevices.FocusedNode);
        twDevices.SortTree(0, sdAscending);

        DoGetDeviceState(eAccountUserName.Text,
          LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll])),
          AccountPassword,
          DForm.eID.Text);
      end;
    finally
      DForm.Free;
    end;
  end;
end;

procedure TMainForm.miDesktopControlClick(Sender: TObject);
var
  DData: PDeviceData;
  Node: PVirtualNode;
  x, y, err: Integer;
  p: TPoint;
  user, sPassword: String;
  i: Integer;
begin
//  XLog('miDesktopControlClick');

  if PassForm.Active then
    Exit;

  GetCursorPos(p);
  p := twDevices.ScreenToClient(p);
  Node := twDevices.GetNodeAt(p);
//  if (twDevices.FocusedNode <> nil) and
//     (twDevices.GetNodeLevel(twDevices.FocusedNode) <> 0) then
  if (Node <> nil) and
     (twDevices.GetNodeLevel(Node) <> 0) then
  begin
//    DData := PDeviceData(twDevices.GetNodeData(twDevices.FocusedNode));
    DData := PDeviceData(twDevices.GetNodeData(Node));
    user := DData^.ID;

    if user = DeviceId then
    begin
      SetStatusStringDelayed('Подключение к своему устройству невозможно');
//      SetStatusStringDelayed('Готов к подключению', 2000);
      Exit;
    end;
//    if DData^.StateIndex = MSG_STATUS_OFFLINE then
//    begin
//      MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
//      SetStatusString('Готов к подключению');
//      Exit;
//    end;

    sPassword := DData^.Password;

    //Если ранее был сохранен верный пароль берем его, а не из списка устройств
    if StorePasswords then
    begin
      for i := 0 to ePartnerID.Items.Count - 1 do
        if THistoryRec(ePartnerID.Items.Objects[i]).user = user then
        begin
          sPassword := THistoryRec(ePartnerID.Items.Objects[i]).password;
          Break;
        end;
    end;

    ConnectToPartnerStart(user, DData^.Name, sPassword, 'desk');
  end;
end;

// Save Window Position procedure
//procedure TMainForm.SaveWindowPosition(Form: TForm; FormName: String; sizeable:boolean);
//  Var
//    CfgFileName:String;
//    s,infos:RtcString;
//    info:TRtcRecord;
//  Begin
//  if SilentMode then Exit;
//
//  // Read old values
//  CfgFileName:= ChangeFileExt(AppFileName,'.ini');
//  s := Read_File(CfgFileName,rtc_ShareDenyNone);
//  if s='' then
//    info:=TRtcRecord.Create
//  else
//    begin
//    try
//      info:=TRtcRecord.FromCode(s);
//    except
//      info:=TRtcRecord.Create;
//      end;
//    end;
//
//  try
//    If info.isNull[FormName] then
//      info.NewRecord(FormName);
//
//    with info.asRecord[FormName] do
//      begin
//      asInteger['Top'] := Form.Top;
//      asInteger['Left']:= Form.Left;
//      if sizeable then asInteger['Width']:= Form.Width else isNull['Width']:=True;
//      if sizeable then asInteger['Height']:= Form.Height else isNull['Height']:=True;
//      end;
//
//    infos:=info.toCode;
//  finally
//    info.Free;
//    end;
//
//  Write_File(CfgFileName,infos);
//  End;

procedure TMainForm.btnAccountLoginClick(Sender: TObject);
begin
//  XLog('btnAccountLoginClick');

  if not ConnectedToAllGateways then
//  if CurStatus in [STATUS_CONNECTING_TO_GATE, STATUS_READY] then
  begin
//    MessageBox(Handle, 'Нет подключения к серверу', 'Remox', MB_ICONWARNING or MB_OK);
    if Sender <> nil then
      SetStatusStringDelayed('Нет подключения к серверу');
    Exit;
  end;

  if CheckAccountFields then
    DoAccountLogin;
end;

function TMainForm.CheckAccountFields: Boolean;
var
  sSymbols: String;
  i: Integer;
  s: String;
  HasDots: Boolean;
begin
//  XLog('CheckAccountFields');

  Result := False;

  sSymbols := '0123456789abcdefghiklmnopqrstuvwxyz';
  if Length(LowerCase(eAccountUserName.Text)) = 0 then
    Exit;

  if Length(LowerCase(eAccountUserName.Text)) < 6 then
  begin
    //bhMain.Description := 'Адрес электронной почты должен состоять из 6 и более символов';
    //bhMain.ShowHint(eAccountUserName);

//    if Visible then
//    begin
//      eAccountUserName.SetFocus;
//      eAccountUserName.SelectAll;
//    end;
//    MessageBox(Handle, 'Адрес электронной почты должен состоять из 6 и более символов', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Адрес электронной почты должен состоять из 6 и более символов');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Result := False;
    Exit;
  end;
  for i := 1 to Length(eAccountUserName.Text) do
    if (AnsiPos(LowerCase(eAccountUserName.Text[i]), sSymbols) = 0)
      and (eAccountUserName.Text[i] <> '@')
      and (eAccountUserName.Text[i] <> '.') then
    begin
//      bhMain.Description := 'Адрес электронной почты должен содержать только буквы и цифры';
//      bhMain.ShowHint(eAccountUserName);

//      if Visible then
//      begin
//        eAccountUserName.SetFocus;
//        eAccountUserName.SelectAll;
//      end;
//      MessageBox(Handle, 'Адрес электронной почты должен содержать только буквы и цифры', 'Remox', MB_ICONWARNING or MB_OK);
      SetStatusStringDelayed('Адрес электронной почты должен состоять из 6 и более символов');
//      SetStatusStringDelayed('Готов к подключению', 2000);
      Result := False;
      Exit;
    end;
  HasDots := False;
  i := AnsiPos('.', eAccountUserName.Text);
  if i <> 0 then
  begin
    s := Copy(eAccountUserName.Text, 1, i);
    if AnsiPos('.', s) <> 0 then
      HasDots := True;
  end;
  if (AnsiPos('@', LowerCase(eAccountUserName.Text)) = 0)
    or (not HasDots) then
  begin
//    bhMain.Description := 'Неверно указан адрес электронной почты';
//    bhMain.ShowHint(eAccountUserName);

//    if Visible then
//    begin
//      eAccountUserName.SetFocus;
//      eAccountUserName.SelectAll;
//    end;
//    MessageBox(Handle, 'Неверно указан адрес электронной почты', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Неверно указан адрес электронной почты');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Result := False;
    Exit;
  end;

  Result := True;
end;

procedure TMainForm.DoAccountLogin;
begin
//  xLog('DoAccountLogin');

//  btnAccountLogin.Enabled := False;
  AccountLoginInProcess := True;

  StartAccountLogin;

  with cmAccounts do
  try
    with Data.NewFunction('Account.Login') do
    begin
      Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
      asWideString['Account'] := LowerCase(eAccountUserName.Text);
      asWideString['Pass'] := AccountPassword;
      asBoolean['IsService'] := IsService;
      Call(resLogin);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;

  with TimerModule do
  try
    with Data.NewFunction('Account.Login2') do
    begin
      Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
      asWideString['Account'] := LowerCase(eAccountUserName.Text);
      asWideString['Pass'] := AccountPassword;
      asBoolean['IsService'] := IsService;
      Call(resTimerLogin);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.StartAccountLogin;
begin
//  xLog('StartAccountLogin');

//  hcAccounts.SkipRequests;
  hcAccounts.Connect(True);

//  TimerClient.SkipRequests;
  TimerClient.Connect(True);

//  do_notify := False;
end;

procedure TMainForm.StartHostLogin;
begin
//  xLog('StartHostLogin');
////  PClient.Disconnect;

//  HostTimerClient.SkipRequests;
  HostTimerClient.Connect(True);

  do_notify := False;
end;

procedure TMainForm.tActivateHostTimer(Sender: TObject);
begin
//  xLog('tActivateHostTimer');

  if (CurStatus < STATUS_CONNECTING_TO_GATE)
    and (not ActivationInProcess) then
    ActivateHost;

//  tActivateHost.Enabled := False;
end;

(* Minimize and Close buttons *)

procedure TMainForm.btnMinimizeClick(Sender: TObject);
begin
//  TaskBarAddIcon;
  Visible := False;
  Application.Minimize;
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;
  fConnected: Boolean;
begin
//  XLog('FormClose');

  DeleteAllPendingRequests;
  CloseAllActiveUI;

//  if SilentMode then
//  begin
//    Application.Minimize;
//    ShowWindow(Application.Handle, SW_HIDE);
//    Action := caNone;
//  end
//  else
//  begin
    tHcAccountsReconnect.Enabled := False;
    tTimerClientReconnect.Enabled := False;
    tHostTimerClientReconnect.Enabled := False;
    tPClientReconnect.Enabled := False;
    tIconRefresh.Enabled := False;

    pingTimer.Enabled := False;
//    HostPingTimer.Enabled := False;

    TaskBarRemoveIcon;

{    fConnected := False;
    for i := 0 to Length(GatewayClients) - 1 do
      if GatewayClients[i].GatewayClient.Connected then
        fConnected := True;

    if not fConnected then
    begin
      Halt;
      Exit;
    end;}

    Hide;
    AccountLogOut(Sender);
    HostLogOut;

//    for i := 0 to GatewayClientsList.Count - 1 do
//    begin
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//    end;
//  end;

  TerminateProcess(GetCurrentProcess, ExitCode);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
//  XLog('FormCloseQuery');

//  if FAutoRun then
//  begin
//    CanClose := False;
//    Visible := False;
//    Application.Minimize;
//    ShowWindow(Application.Handle, SW_HIDE);
//    Exit;
//  end;

  if isClosing then
  begin
    CanClose := True;
  end
  else
  begin
    CanClose := False;
    if IsWindowVisible(Application.Handle) then
    begin
      Visible := False;
      Application.Minimize;
      ShowWindow(Application.Handle, SW_HIDE);
    end;
    Exit;
  end;

  SaveSetup;

//  if(eConnected.Items.Count > 0) then
//  begin
//  if SilentMode then
//  begin
//    TaskBarRemoveIcon;
//    LogOut(Self);
//    HostLogOut;
//    CanClose := True;
//  end
//  else
////  if MessageDlg('Вы действительно хотите закрыть Remox?'#13#10+
////    'Имеются подключенные к Вам пользователи.'#13#10 +
////    'Закрытие Remox их отключит.',
////    mtWarning, [mbNo, mbYes], 0) = mrYes then
//  begin
//    TaskBarRemoveIcon;
//    LogOut(Self);
//    HostLogOut;
//    CanClose := True;
//  end;
//  else
//    CanClose := False;
//  end
//  else
//  begin
//    TaskBarRemoveIcon;
//    LogOut(Self);
//    CanClose := True;
//  end;

//  SaveWindowPosition(Self, 'MainForm', False);

//  if CanClose then
//  begin
//    Visible := False;

//+
//    hcAccounts.WaitForCompletion(False, 2);
//
//    cmAccounts.SkipRequests;
//    TimerModule.SkipRequests;
//    HostTimerModule.SkipRequests;
//
//    hcAccounts.Disconnect;
//    TimerClient.Disconnect;
//    HostTimerClient.Disconnect;
//+

//    cmAccounts.WaitForCompletion(False, 2);

//    hcAccounts.SkipRequests;
//    hcAccounts.Session.Close;
//    hcAccounts.WaitForCompletion(False, 2);

//    cmHosts.SkipRequests;
//    cmHosts.WaitForCompletion(False, 2);

//    hcAccounts.Disconnect;
//    hcHosts.Disconnect;
//    hcHosts.SkipRequests;
//    hcHosts.Session.Close;
//    hcHosts.WaitForCompletion(False, 2);

//    TimerModule.SkipRequests;
//    TimerModule.WaitForCompletion(False, 2);

//    HostTimerModule.SkipRequests;
//    HostTimerModule.WaitForCompletion(False, 2);

//    TimerClient.SkipRequests;
//    TimerClient.Disconnect;
//    TimerClient.Session.Close;
//    TimerClient.WaitForCompletion(False, 2);

//    HostTimerClient.SkipRequests;
//    HostTimerClient.Disconnect;
//    HostTimerClient.Session.Close;
//    HostTimerClient.WaitForCompletion(False, 2);

//    for i := 0 to Length(GatewayClients) - 1 do
//    begin
//      GatewayClients[i].GatewayClient.Disconnect;
//      if GatewayClients[i].GatewayClient.Active then
//      GatewayClients[i].GatewayClient.Active := False;
//      GatewayClients[i].GatewayClient.Stop;
//    end;
//  end;
end;

(* Utility code *)

procedure TMainForm.aAboutExecute(Sender: TObject);
begin
//  XLog('aAboutExecute');

  ShowAboutForm;
end;

{procedure TMainForm.AcceptFiles( var msg : TMessage );
const
  cnMaxFileNameLen = 1024;
var
  i, nCount: Integer;
  acFileName: Array [0..cnMaxFileNameLen] of Char;
  myFileName: String;
  UserName: String;
begin
//  XLog('AcceptFiles');

  try
    if not HostGatewayClientActive then
    begin
  //  MessageBeep(0);
      Exit;
    end;

    UserName := tPHostThread.FDesktopHost.LastMouseUser;
    if UserName= '' then
      Exit;

    // find out how many files we're accepting
    nCount := DragQueryFile(msg.WParam,
                             $FFFFFFFF,
                             acFileName,
                             cnMaxFileNameLen);
    // query Windows one at a time for the file name
    for i := 0 to nCount - 1 do
    begin
      DragQueryFile(msg.WParam, i, acFileName, cnMaxFileNameLen);

      myFileName := acFileName;
      tPHostThread.FFileTransfer.Send(UserName, myFileName);
    end;
  finally
    // let Windows know that you're done
    DragFinish(msg.WParam);
    msg.Result := 0;
//    inherited;
  end;
end;}

procedure TMainForm.aCloseExecute(Sender: TObject);
begin
//  XLog('aCloseExecute');

  Close;
end;

procedure TMainForm.TaskBarAddIcon;
var
  tnid: TNotifyIconData;
//    xOwner: HWnd;
begin
//  XLog('TaskBarAddIcon');

//  if SilentMode then Exit;

//  if not TaskBarIcon then
//    begin
    with tnid do
    begin
      ZeroMemory(@tnid, System.SizeOf(tnid));
      cbSize := System.SizeOf(TNotifyIconData);
      Wnd := self.Handle;
      uID := 1;
      uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
      uCallbackMessage := WM_TASKBAREVENT;
      hIcon := Application.Icon.Handle;
    end;
//    if eUserName.Text = '' then
    StrCopy(tnid.szTip, 'Remox');
//    else
//      StrCopy(tnid.szTip, PChar('Remox - ' + eUserName.Text));
    Shell_NotifyIcon(NIM_ADD, @tnid);

//    xOwner:=GetWindow(self.Handle,GW_OWNER);
//    If xOwner<>0 Then
//      ShowWindow(xOwner,SW_HIDE);

    TaskBarIcon:=True;
//  end;
end;

procedure TMainForm.TaskBarIconUpdate(AIsOnline: Boolean);
var
  tnid: TNotifyIconData;
//  Ic: TIcon;
//    xOwner: HWnd;
begin
//  XLog('TaskBarIconUpdate');

  if TaskBarIcon then
  begin
//    Ic := TIcon.Create;
//    if State = 'ONLINE' then
//      Ic.LoadFromResourceName(HInstance, 'Z_APPICONONLINE')
//    else
//      Ic.LoadFromResourceName(HInstance, 'Z_APPICONOFFLINE');
    ZeroMemory(@tnid, System.SizeOf(tnid));
    tnid.cbSize := SizeOf(TNotifyIconData);
    tnid.Wnd := self.Handle;
    tnid.uID := 1;
    tnid.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
    tnid.uCallbackMessage := WM_TASKBAREVENT;
//    tnid.hIcon := Ic.Handle;
    if AIsOnline then
      tnid.hIcon := iAppIconOnline.Picture.Icon.Handle
    else
      tnid.hIcon := iAppIconOffline.Picture.Icon.Handle;
    if eUserName.Text <> '-' then
      StrCopy(tnid.szTip, PChar('Remox - ' + eUserName.Text))
    else
      StrCopy(tnid.szTip, PChar('Remox'));
    Shell_NotifyIcon(NIM_MODIFY, @tnid);
 //   Ic.Destroy;
  //    xOwner:=GetWindow(self.Handle,GW_OWNER);
  //    If xOwner<>0 Then
  //      Begin
  //      ShowWindow(xOwner,SW_Show);
  //      ShowWindow(xOwner,SW_Normal);
  //      End;
  end;
end;

procedure TMainForm.TaskBarRemoveIcon;
var
  tnid: TNotifyIconData;
//    xOwner: HWnd;
begin
//  XLog('TaskBarRemoveIcon');

  if TaskBarIcon then
  begin
    ZeroMemory(@tnid, System.SizeOf(tnid));
    tnid.cbSize := SizeOf(TNotifyIconData);
    tnid.Wnd := self.Handle;
    tnid.uID := 1;
    tnid.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
    tnid.hIcon := Application.Icon.Handle;
    Shell_NotifyIcon(NIM_DELETE, @tnid);
//    xOwner:=GetWindow(self.Handle,GW_OWNER);
//    If xOwner<>0 Then
//      Begin
//      ShowWindow(xOwner,SW_Show);
//      ShowWindow(xOwner,SW_Normal);
//      End;
    TaskBarIcon:=false;
  end;
end;

{function TMainForm.IsScreenSaverRunning: Boolean;
begin
  SystemParametersInfo(SPI_GETSCREENSAVERRUNNING, 0, @result, 0)
end;}

procedure TMainForm.tCheckLockedStateTimer(Sender: TObject);
//var
//  hDesktop : THandle;
//  bResult, bLocked : BOOL;
begin
//  XLog('tCheckLockedStateTimer');

  if SessionIsLocked(CurrentSessionID) then
    ScreenLockedState := LCK_STATE_LOCKED
  else
  if (LowerCase(GetInputDesktopName) <> 'default') then
    ScreenLockedState := LCK_STATE_SAS
  else
    ScreenLockedState := LCK_STATE_UNLOCKED;

//  if (not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//    and
{  if (LowerCase(GetInputDesktopName) <> 'default') then
    ScreenLockedState := LCK_STATE_LOCKED
  else
  if  (GetCurrentSesstionState = WTSActive) then
    ScreenLockedState := LCK_STATE_UNLOCKED
  else
    ScreenLockedState := LCK_STATE_SAS;}
 {tPHostThread.FDesktopHost.HaveScreen
    and}
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

procedure TMainForm.SetScreenLockedState(AValue: Integer);
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

procedure TMainForm.tHcAccountsReconnectTimer(Sender: TObject);
begin
//  xLog('tHcAccountsReconnectTimer');

  if not hcAccounts.isConnected then
  begin
    hcAccounts.DisconnectNow(True);
    hcAccounts.Connect(True);
  end;

  tHcAccountsReconnect.Enabled := False;

//  PClient.Disconnect;
//  PClient.Active := False;
////  PClient.Stop;
//  TimerClient.Connect(True);

//  if not PClient.Connected then
//  begin
//    SetStatusString('Активация Remox', True);
//
////    LogOut;
//    PClient.Active := True
//  end else
//  begin
//    PClient.SendPing(Sender);
//    if not PClient.Connected then
//    begin
//      SetStatusString('Активация Remox', True);
//      PClient.Active := True
//    end else
//      tConnect.Enabled := False;
//  end;
end;

procedure TMainForm.tHostTimerClientReconnectTimer(Sender: TObject);
begin
//  xLog('tHostTimerClientReconnectTimer');

  if not HostTimerClient.isConnecting then
    HostTimerClient.Connect(True);
end;

procedure TMainForm.tConnLimitTimer(Sender: TObject);
begin
//  XLog('tConnLimitTimer');

  if DateAllowConnectionPending < Now then
  begin
    CurConnectionsPendingMinuteCount := 0;
    DateAllowConnectionPending := Now - 1;
  end;
end;

procedure TMainForm.tDelayedStatusTimer(Sender: TObject);
begin
//  XLog('tDelayedStatusTimer');

//  SetStatusString(DelayedStatus);
  DelayedStatus := '';
  tDelayedStatus.Enabled := False;
end;

procedure TMainForm.tFoldFormTimer(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
  Visible := False;

  tFoldForm.Enabled := False;
end;

procedure TMainForm.TimerClientConnect(Sender: TRtcConnection);
begin
//  xLog('TimerClientConnect');

  tTimerClientReconnect.Enabled := False;
end;

procedure TMainForm.TimerClientConnectError(Sender: TRtcConnection;
  E: Exception);
begin
//  xLog('TimerClientConnectError');
end;

procedure TMainForm.TimerClientDisconnect(Sender: TRtcConnection);
begin
//  xLog('TimerClientDisconnect');

  ChangePort(TimerClient);

  if (not isClosing)
    and (not SettingsFormOpened) then
    tTimerClientReconnect.Enabled := True;
end;

procedure TMainForm.tIconRefreshTimer(Sender: TObject);
begin
//  XLog('tIconRefreshTimer');

  if isClosing then
    Exit;

  TaskBarAddIcon;
  TaskBarIconUpdate(CurStatus = 3);
end;

procedure TMainForm.TimerModuleResponseAbort(Sender: TRtcConnection);
begin
//  with TRtcDataClient(Sender) do
//    begin
//    LogOut(nil);
////    SetStatusString('Сервер недоступен');
//    end;
end;

procedure TMainForm.tInternetActiveTimer(Sender: TObject);
var
  i: Integer;
begin
//  XLog('tInternetActiveTimer');

  if not IsInternetConnected then
  begin
    SetStatus(STATUS_NO_CONNECTION);
    hcAccounts.DisconnectNow(True);
//    SetConnectedState(False);

//    CS_GW.Acquire;
//    try
//      for i := 0 to GatewayClientsList.Count - 1 do
//      begin
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//    //    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Stop;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//      end;
//    finally
//      CS_GW.Release;
//    end;
//    PClient.Disconnect;
//    PClient.Active := False;

    if (not isClosing) then
      tHcAccountsReconnect.Enabled := True;
  end;

//  Memo2.Lines.Add('Session # ' + IntToStr(GetInteractiveSessionID()));
end;

procedure TMainForm.tPClientReconnectTimer(Sender: TObject);
var
  i: Integer;
begin
//  xLog('tPClientReconnectTimer');

  if (DeviceId <> '') then
  begin
    if (GetStatus = STATUS_READY) then
      SetStatus(STATUS_CONNECTING_TO_GATE);

    AccountLogOut(nil);

//    PClient.Disconnect;
//    PClient.Active := False;
//    PClient.Active := True;

    if tPHostThread <> nil then
      tPHostThread.Restart;

    tPClientReconnect.Enabled := False;
  end
  else
    tPClientReconnect.Enabled := True;

//  if not PClient.Active then
////    and not PClient.Connected then
//  begin
////    PClient.Disconnect;
////    PClient.Active := False;
//    PClient.Stop;
//    PClient.Active := True;
//  end;
end;

procedure TMainForm.tStatusTimer(Sender: TObject);
var
  s: String;
begin
//  XLog('tStatusTimer');

//  s := ' ';
//  if Pos(' . . . . .', lblStatus.Caption) > 0 then
//    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . . . . .', ' .', [rfReplaceAll])
//  else
//  if Pos(' . . . .', lblStatus.Caption) > 0 then
//    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . . . .', ' . . . . .', [rfReplaceAll])
//  else
//  if Pos(' . . .', lblStatus.Caption) > 0 then
//    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . . .', ' . . . .', [rfReplaceAll])
//  else
//  if Pos(' . .', lblStatus.Caption) > 0 then
//    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . .', ' . . .', [rfReplaceAll])
//  else
//  if Pos(' .', lblStatus.Caption) > 0 then
//    lblStatus.Caption := StringReplace(lblStatus.Caption, ' .', ' . .', [rfReplaceAll])
//  else
//    lblStatus.Caption := lblStatus.Caption + ' .';
end;

procedure TMainForm.tTimerClientReconnectTimer(Sender: TObject);
begin
//  xLog('tTimerClientReconnectTimer');

  if not TimerClient.isConnecting then
    TimerClient.Connect(True);
end;

procedure TMainForm.twDevicesBeforeItemPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
  var CustomDraw: Boolean);
var
  DData: PDeviceData;
  Level: Integer;
  Name: String;
begin
  DData := twDevices.GetNodeData(Node);
//  if DData^.HighLight then
//    TargetCanvas.Brush.Color := clRed;
//  else
//    TargetCanvas.Brush.Color := clWindow;

  CustomDraw := True;

  with TargetCanvas do
  begin
    Font.Color := clBlack;
    Pen.Color := cl3DDkShadow;
    if DData^.HighLight
      and (not Sender.Selected[Node]) then
    begin
      Brush.Color := RGB(229, 243, 255);//$DDDDDD;//$E0E0E0;
    end
    else
    if Sender.Selected[Node] then
    begin
      Brush.Color := RGB(204, 232, 255);//RGB(19, 174, 196);
    end
    else
    begin
      Brush.Color := $00FDFDFD;
    end;

    if Node.Parent = Sender.RootNode then
      Level := 0
    else
      Level := 1;

    FillRect(ItemRect);

    ItemRect.Left := 12 + (Level * twDevices.Indent);
    DrawImage(twDevices, TargetCanvas, ItemRect, DData^.StateIndex);

    if Level = 0 then
      ItemRect.Left := 18
    else
      ItemRect.Left := 20 + 38;

    Name := DData^.Name;
    if (DeviceId <> '') then
      if DData^.ID = DeviceId then
        if Name <> '' then
          Name := Name + ' (это устройство)'
        else
          Name := Name + '(это устройство)';

    Font.Size := Sender.Font.Size;
    if Node.Parent = Sender.RootNode then
      Font.Style := [fsBold]
    else
      Font.Style := [];
    TargetCanvas.Brush.Style := bsClear;
    TextOut(ItemRect.Left, (ItemRect.Height - TargetCanvas.TextHeight(Name)) div 2, Name);
    TargetCanvas.Brush.Style := bsSolid;

    ItemRect.Left := 2;
    if Sender.Selected[Node] then
      DrawExpandButton(twDevices, TargetCanvas, ItemRect, Node, clBlack)//clWhite)
    else
      DrawExpandButton(twDevices, TargetCanvas, ItemRect, Node, clBlack);
  end;
end;

procedure TMainForm.twDevicesCompareNodes(Sender: TBaseVirtualTree; Node1,
  Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  Dbrec1, Dbrec2: PDeviceData;
begin
  Dbrec1 := Sender.GetNodeData(Node1);
  Dbrec2 := Sender.GetNodeData(Node2);

  // Сортируем по именм
  if Column = 0 then begin
    if UpperCase(DBrec1.Name) > UpperCase(DBrec2.Name) then
      Result := 1;
    if UpperCase(DBrec1.Name) < UpperCase(DBrec2.Name) then
      Result := -1;
    if UpperCase(DBrec1.Name) = UpperCase(DBrec2.Name) then
      Result := 0;
  end;
end;

procedure TMainForm.twDevicesFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  if Node <> nil then
    LastFocusedUID := PDeviceData(twDevices.GetNodeData(twDevices.FocusedNode)).UID;
end;

procedure TMainForm.twDevicesGetHint(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: string);
//var
//  i: Integer;
//  s: String;
begin
//  if PDeviceData(twDevices.GetNodeData(Node)).ID <> 0 then
//  begin
//      s := IntToStr(PDeviceData(twDevices.GetNodeData(Node)).ID);
//      HintText := '';
//      for i := 1 to Length(s) do
//        if (i <> 1)
//          and ((i - 1) mod 3 = 0) then
//          HintText := HintText + ' ' + s[i]
//        else
//          HintText := HintText + s[i];
//  end;
end;

procedure TMainForm.DrawExpandButton(AStringTree: TVirtualStringTree; Canvas: TCanvas; ARect: TRect; Node: PVirtualNode; AColor: TColor);
var
  cx, cy: Integer;
begin
  cx := ARect.Left;
  cy := ARect.Top + Math.Ceil(ARect.Height / 2 - 4.5);
  with Canvas do
  begin
    Pen.Color := AColor;
    Brush.Color := AColor;
    if AStringTree.GetNodeLevel(Node) = 0 then
      if not AStringTree.Expanded[Node] then
      begin
        Polygon([Point(cx + 2, cy), Point(cx + 8, cy + 4), Point(cx + 2, cy + 9)]);
      end
      else
      begin
        Polygon([Point(cx + 0, cy + 2), Point(cx + 10, cy + 2), Point(cx + 5, cy + 8)]);
      end;
  end;
end;

procedure TMainForm.DrawCloseButton(AStringTree: TVirtualStringTree; Canvas: TCanvas; ARect: TRect; Node: PVirtualNode; AColor: TColor);
var
  cx, cy: Integer;
begin
  cx := ARect.Left;
  cy := ARect.Top + Math.Ceil(ARect.Height / 2 - 4.5);
  with Canvas do
  begin
    Pen.Color := AColor;
    Pen.Width := 2;
    Brush.Color := AColor;

    MoveTo(cx, cy);
    LineTo(cx + 8, cy + 8);
    MoveTo(cx, cy + 8);
    LineTo(cx + 8, cy);
  end;
end;

procedure TMainForm.DrawImage(AStringTree: TVirtualStringTree; Canvas: TCanvas; NodeRect: TRect; ImageIndex: Integer);
//var
//  bmp: TBitmap;
//  png: TPortableNetworkGraphic;
begin
  if ImageIndex >= 0 then
  begin
//    bmp := TBitmap.Create;
//    twDevices.StateImages.GetBitmap(ImageIndex, bmp);
//    Canvas.Brush.Style := bsClear;
//    bmp.TransparentColor := RGB(0, 0, 0);
//    bmp.TransparentMode := tmFixed;
//    bmp.Transparent := True;

    if ImageIndex = 0 then
      Canvas.StretchDraw(Rect(AStringTree.Indent, NodeRect.Top + 1, AStringTree.Indent + 38, NodeRect.Bottom - 2), iDeviceOnline.Picture.Graphic)
    else
      Canvas.StretchDraw(Rect(AStringTree.Indent, NodeRect.Top + 1, AStringTree.Indent + 38, NodeRect.Bottom - 2), iDeviceOffline.Picture.Graphic);

//    Canvas.Brush.Style := bsSolid;

//    bmp.Draw(Canvas, twDevices.Indent, NodeRect.Top - 2,
//                   ImageIndex, True);                                                                //24 * CurScreenHeight div EtalonScreenHeight
    //Canvas.StretchDraw(Rect(twDevices.Indent, NodeRect.Top - Math.Ceil(CurWidth * 5 / EtalonWidth), twDevices.Indent + Math.Ceil(CurWidth * 38 / EtalonWidth) * CurScreenWidth div EtalonScreenWidth, twDevices.Indent + NodeRect.Bottom - Math.Ceil(CurWidth * 5 / EtalonWidth)), bmp);
//    Canvas.StretchDraw(Rect(twDevices.Indent, NodeRect.Top, twDevices.Indent + 38, NodeRect.Bottom), bmp);

  //SmoothResize(bmp, Math.Ceil(CurWidth * 38 / EtalonWidth), Math.Ceil(CurWidth * 24 / EtalonWidth));
  //Canvas.Draw(twDevices.Indent, NodeRect.Top, bmp);
  //bmp.TransparentColor := RGB(0, 0, 0);
  //TransStretchDraw(Canvas, Rect(twDevices.Indent, NodeRect.Top, twDevices.Indent + 38, NodeRect.Bottom), bmp, RGB(255, 0, 0));

//  SetBkMode(Canvas.Handle, TRANSPARENT);


//  png := TPortableNetworkGraphic.Create;
//  bmp.Transparent:=true;
//  bmp.LoadFromFile('c:\program\data\libs\'+lib_name+'.png');
//
//  img_show_img.Stretch:=true;
//  img_show_img.Picture.Assign(bmp);

//    bmp.Free;
  end;
end;

function TMainForm.Polygon_GetBounds(const Points: array of TPoint): TRect;
var
  i: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  for i := 0 to Length(Points) - 1 do
  begin
    if i = 0 then
      Result := Rect(Points[i].X, Points[i].Y, Points[i].X, Points[i].Y)
    else
    begin
      if Points[i].X < Result.Left then
        Result.Left := Points[i].X;
      if Points[i].Y < Result.Top then
        Result.Top := Points[i].Y;
      if Points[i].X > Result.Right then
        Result.Right := Points[i].X;
      if Points[i].Y > Result.Bottom then
        Result.Bottom := Points[i].Y;
    end;
  end;
  Result.Right := Result.Right + 1;
  Result.Bottom := Result.Bottom + 1;
end;

procedure TMainForm.Polygon_GetFillRange(const Points: array of TPoint; Y: Integer;
  out ARangeList: TRangeList);
var
  {first item in list}
  AItem: pRangeItem;

  procedure AddIntersection(X: Integer; Up: Boolean);
  var
    p, p2, Prev: pRangeItem;
  begin
    New(p);
    Prev := nil;
    p^.X := X;
    p^.Up := Up;
    p^.Next := nil;
    if Assigned(AItem) then
    begin
      {insert into sorted position}
      p2 := AItem;
      while Assigned(p2) do
      begin
        if p2^.X > X then
        begin
          if Assigned(Prev) then
          begin
            Prev^.Next := p;
            p^.Next := p2;
            Break;
          end
          else
          begin
            p^.Next := p2;
            AItem := p;
            Break;
          end;
        end;
        if p2^.Next = nil then
        begin
          {add to the end}
          p2^.Next := p;
          Break;
        end;
        Prev := p2;
        p2 := p2^.Next;
      end;
    end
    else
      AItem := p;
  end;

var
  i, X, X0, Cnt: Integer;
  LastDirection: Boolean;
  p: pRangeItem;
begin
  if Length(Points) = 0 then
    Exit;
  AItem := nil;
  Cnt := 0;
  for i := 0 to Length(Points) - 2 do
  begin
    if ((Points[i].Y > Y) and (Points[i + 1].Y <= Y)) or ((Points[i].Y <= Y) and
      (Points[i + 1].Y > Y)) then
      if Points[i + 1].Y <> points[i].Y then
      begin
        X := Round(Points[i].X + ((Points[i + 1].X - Points[i].X) *
          (Y - Points[i].Y) / (Points[i + 1].Y - points[i].Y)));
        AddIntersection(X, Points[i + 1].Y > Points[i].Y);
        Inc(Cnt);
      end;
  end;
  {close polygon}
  i := Length(Points) - 1;
  if ((Points[i].Y > Y) and (Points[0].Y <= Y)) or ((Points[i].Y <= Y) and (Points[0].Y
    > Y)) then
    if Points[0].Y <> points[i].Y then
    begin
      X := Round(Points[i].X + ((Points[0].X - Points[i].X) * (Y - Points[i].Y) /
        (Points[0].Y - points[i].Y)));
      AddIntersection(X, Points[0].Y > Points[i].Y);
      Inc(Cnt);
    end;
  p := AItem;
  {calculate fill ranges}
  i := 1; {use as acumulative direction counter}
  SetLength(ARangeList, Cnt);
  Cnt := 0; {number of range items in array}
  if Assigned(AItem) then
  begin
    LastDirection := AItem^.Up; {init last direction}
    X0 := AItem^.X;
    AItem := AItem^.Next;
  end;
  while Assigned(AItem) do
  begin
    if AItem^.Up = LastDirection then
    begin
      Inc(i);
      if i = 1 then
        X0 := AItem^.X; {init start position}
    end
    else
    begin
      Dec(i);
      if i = -1 then
        X0 := AItem^.X; {init start position}
    end;
    if i = 0 then
    begin
      ARangeList[Cnt].X := X0;
      ARangeList[Cnt].Count := AItem^.X - X0;
      Inc(Cnt);
      LastDirection := AItem^.Up;
    end;
    AItem := AItem^.Next;
  end;
  {shrink list}
  SetLength(ARangeList, Cnt);
  {delete internal range list}
  while Assigned(p) do
  begin
    AItem := p;
    p := p^.Next;
    Dispose(AItem);
  end;
end;

function TMainForm.Polygon_PtInside(const Points: array of TPoint; Pt: TPoint): Boolean;
var
  RL: TRangeList;
  i: Integer;
begin
  Result := False;
  Polygon_GetFillRange(Points, Pt.Y, RL);
  for i := 0 to Length(RL) - 1 do
  begin
    Result := (Pt.X >= RL[i].X) and (Pt.X < RL[i].X + RL[i].Count);
    if Result then
      Exit;
  end;
end;

procedure TMainForm.FillPolygon(ACanvas: TCanvas; APoints: array of TPoint; AColor: TColor);
var
  i, j: Integer;
  R: TRect;
  ARangeList: TRangeList;
begin
  ACanvas.Pen.Color := AColor;
  {Find polygon bounds because we only need to calculate fill-ranges from
  top to bottom value of rectangle}
  R := Polygon_GetBounds(APoints);
  for i := R.Top to R.Bottom do
  begin
    Polygon_GetFillRange(APoints, i, ARangeList);
    {Since there can be many fill ranges for one Y, function returns a list of all}
    for j := 0 to Length(ARangeList) - 1 do
    begin
      {fill pixels inside range}
      {so far I'll just draw a line with GDI but this part can be substituted with your own draw function}
      ACanvas.MoveTo(ARangeList[j].X, i);
      ACanvas.LineTo(ARangeList[j].X + ARangeList[j].Count, i);
    end;
  end;
end;

procedure TMainForm.twDevicesKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  user, sPassword: String;
  DData: PDeviceData;
  i: Integer;
begin
//  XLog('twDevicesKeyDown');

  if Key = VK_RETURN then
  begin
    if (twDevices.FocusedNode <> nil) and
       (twDevices.GetNodeLevel(twDevices.FocusedNode) <> 0) then
    begin
      DData := PDeviceData(twDevices.GetNodeData(twDevices.FocusedNode));
      user := DData^.ID;

      if user = DeviceId then
      begin
//        MessageBox(Handle, 'Подключение к своему устройству невозможно', 'Remox', MB_ICONWARNING or MB_OK);
        SetStatusStringDelayed('Подключение к своему устройству невозможно');
//        SetStatusStringDelayed('Готов к подключению', 2000);
        Exit;
      end;

      sPassword := DData^.Password;

      //Если ранее был сохранен верный пароль берем его, а не из списка устройств
      if StorePasswords then
      begin
        for i := 0 to ePartnerID.Items.Count - 1 do
          if THistoryRec(ePartnerID.Items.Objects[i]).user = user then
          begin
            sPassword := THistoryRec(ePartnerID.Items.Objects[i]).password;
            Break;
          end;
      end;

      ConnectToPartnerStart(user, DData^.Name, sPassword, 'desk');
    end;
  end
  else
  if Key = VK_DELETE then
    miDeleteClick(twDevices);
end;

procedure TMainForm.twDevicesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Node: PVirtualNode;
begin
//  XLog('twDevicesMouseDown');

  Node := twDevices.GetNodeAt(X, Y);
  if Node <> nil then
  begin
    twDevices.Selected[Node] := True;
    twDevices.FocusedNode := Node;
//    twDevices.Repaint;
  end;

  if Button = mbRight then
    if twDevices.GetNodeLevel(twDevices.GetNodeAt(X, Y)) = 0 then
      twDevices.PopupMenu := pmGroup
    else
      twDevices.PopupMenu := pmDevice;
end;

procedure TMainForm.twDevicesMouseLeave(Sender: TObject);
//var
//  i: Integer;
//  ChildNode: TTreeNode;
begin
  if HighLightedNode <> nil then
  begin
    TDeviceData(twDevices.GetNodeData(HighLightedNode)^).HighLight := False;
    twDevices.Repaint;
  end;
//  for i := 0 to twDevices.Items.Count - 1 do
//  begin
//    if TDeviceData(twDevices.Items[i].Data^).HighLight then
//      TDeviceData(twDevices.Items[i].Data^).HighLight := False;
//    ChildNode := twDevices.Items[i].GetFirstChild;
//    while ChildNode <> nil do
//    begin
//      if TDeviceData(ChildNode.Data^).HighLight then
//        TDeviceData(ChildNode.Data^).HighLight := False;
//
//      ChildNode := ChildNode.getNextSibling;
//    end;
//  end;

end;

procedure TMainForm.twDevicesMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if HighLightedNode <> twDevices.GetNodeAt(X, Y) then
  begin
    if HighLightedNode <> nil then
      TDeviceData(twDevices.GetNodeData(HighLightedNode)^).HighLight := False;
    HighLightedNode := twDevices.GetNodeAt(X, Y);
    if HighLightedNode <> nil then
      TDeviceData(twDevices.GetNodeData(HighLightedNode)^).HighLight := True;
    twDevices.Repaint;
  end;
end;

procedure TMainForm.twDevicesMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Node: PVirtualNode;
  p: TPoint;
  DData: PDeviceData;
  cnt: Integer;
begin
  GetCursorPos(p);
  p := twIncomes.ScreenToClient(p);
  if (p.X < twIncomes.ClientWidth - 12)
    or (p.X > twIncomes.ClientWidth - 4) then
    Exit;

  Node := twIncomes.GetNodeAt(X, Y);
  if Node <> nil then
  begin
    DData := twIncomes.GetNodeData(Node);
//    TSendDestroyClientToGatewayThread.Create(False, tPHostThread.Gateway, DData^.Name, False, hcAccounts.UseProxy, hcAccounts.UserLogin.ProxyAddr, hcAccounts.UserLogin.ProxyUserName, hcAccounts.UserLogin.ProxyPassword, False);
    SendManualLogoutToControl(DData^.Action, DData^.ID, DeviceId);
    twIncomes.DeleteNode(Node);

    cnt := GetIncomeConnectionsCount;
    tsIncomes.Caption := 'Входящие подключения (' + IntToStr(cnt) + ')';
    if cnt = 0 then
      pcDevAcc.ActivePage := tsMyDevices;
  end;
end;

procedure TMainForm.twIncomesBeforeItemPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
  var CustomDraw: Boolean);
var
  DData: PDeviceData;
  Level: Integer;
begin
  DData := twIncomes.GetNodeData(Node);
//  if DData^.HighLight then
//    TargetCanvas.Brush.Color := clRed;
//  else
//    TargetCanvas.Brush.Color := clWindow;

  CustomDraw := True;

  with TargetCanvas do
  begin
    Font.Color := clBlack;
    Pen.Color := cl3DDkShadow;
    if DData^.HighLight
      and (not Sender.Selected[Node]) then
      Brush.Color := RGB(229, 243, 255) //$DDDDDD;//$E0E0E0;
    else
    if Sender.Selected[Node] then
      Brush.Color := RGB(204, 232, 255) //RGB(19, 174, 196);
    else
      Brush.Color := $00FDFDFD;

//    if Node.Parent = Sender.RootNode then
//      Level := 0
//    else
//      Level := 1;

    FillRect(ItemRect);

    ItemRect.Left := 12 + (Level * twIncomes.Indent);
    DrawImage(twIncomes, TargetCanvas, ItemRect, DData^.StateIndex);

//    if Level = 0 then
//      ItemRect.Left := 18
//    else
      ItemRect.Left := 20 + 38;

    Font.Size := Sender.Font.Size;
//    if Node.Parent = Sender.RootNode then
//      Font.Style := [fsBold]
//    else
      Font.Style := [];
    TargetCanvas.Brush.Style := bsClear;
    TextOut(ItemRect.Left, (ItemRect.Height - TargetCanvas.TextHeight(Name)) div 2, DData^.Description);
    TargetCanvas.Brush.Style := bsSolid;

    ItemRect.Left := twIncomes.ClientWidth - 12;
    if Sender.Selected[Node] then
      DrawCloseButton(twIncomes, TargetCanvas, ItemRect, Node, clBlack)//clWhite)
    else
      DrawCloseButton(twIncomes, TargetCanvas, ItemRect, Node, clBlack);
  end;
end;

procedure TMainForm.twIncomesDblClick(Sender: TObject);
//var
//  DData: PDeviceData;
//  Node: PVirtualNode;
//  x, y, err: Integer;
//  p: TPoint;
//  user, sPassword: String;
//  i: Integer;
begin
//  XLog('twIncomesDblClick');

//  GetCursorPos(p);
//  p := twDevices.ScreenToClient(p);
//  Node := twDevices.GetNodeAt(p);
////  if (twDevices.FocusedNode <> nil) and
////     (twDevices.GetNodeLevel(twDevices.FocusedNode) <> 0) then
//  if (Node <> nil) and
//     (twDevices.GetNodeLevel(Node) <> 0) then
//  begin
////    DData := PDeviceData(twDevices.GetNodeData(twDevices.FocusedNode));
//    DData := PDeviceData(twDevices.GetNodeData(Node));
//    user := IntToStr(DData^.ID);
//
//    if user = DeviceId then
//    begin
//      SetStatusStringDelayed('Подключение к своему устройству невозможно');
////      SetStatusStringDelayed('Готов к подключению', 2000);
//      Exit;
//    end;
////    if DData^.StateIndex = MSG_STATUS_OFFLINE then
////    begin
////      MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
////      SetStatusString('Готов к подключению');
////      Exit;
////    end;
//
//    sPassword := DData^.Password;
//
//    //Если ранее был сохранен верный пароль берем его, а не из списка устройств
//    if StorePasswords then
//    begin
//      for i := 0 to ePartnerID.Items.Count - 1 do
//        if THistoryRec(ePartnerID.Items.Objects[i]).user = user then
//        begin
//          sPassword := THistoryRec(ePartnerID.Items.Objects[i]).password;
//          Break;
//        end;
//    end;
//
//    ConnectToPartnerStart(user, DData^.Name, DData^.Password, 'desk');
//  end;
end;

procedure TMainForm.twIncomesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Node: PVirtualNode;
begin
//  XLog('twDevicesMouseDown');

  Node := twIncomes.GetNodeAt(X, Y);
  if Node <> nil then
  begin
    twIncomes.Selected[Node] := True;
    twIncomes.FocusedNode := Node;
//    twDevices.Repaint;
  end;

//  if Button = mbRight then
//    if twDevices.GetNodeLevel(twDevices.GetNodeAt(X, Y)) = 0 then
//      twDevices.PopupMenu := pmGroup
//    else
//      twDevices.PopupMenu := pmDevice;
end;

procedure TMainForm.twIncomesMouseLeave(Sender: TObject);
//var
//  i: Integer;
//  ChildNode: TTreeNode;
begin
  if HighLightedNode <> nil then
  begin
    TDeviceData(twIncomes.GetNodeData(HighLightedNode)^).HighLight := False;
    twIncomes.Repaint;
  end;
//  for i := 0 to twDevices.Items.Count - 1 do
//  begin
//    if TDeviceData(twDevices.Items[i].Data^).HighLight then
//      TDeviceData(twDevices.Items[i].Data^).HighLight := False;
//    ChildNode := twDevices.Items[i].GetFirstChild;
//    while ChildNode <> nil do
//    begin
//      if TDeviceData(ChildNode.Data^).HighLight then
//        TDeviceData(ChildNode.Data^).HighLight := False;
//
//      ChildNode := ChildNode.getNextSibling;
//    end;
//  end;

end;

procedure TMainForm.twIncomesMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if HighLightedNode <> twIncomes.GetNodeAt(X, Y) then
  begin
    if HighLightedNode <> nil then
      TDeviceData(twIncomes.GetNodeData(HighLightedNode)^).HighLight := False;
    HighLightedNode := twIncomes.GetNodeAt(X, Y);
    if HighLightedNode <> nil then
      TDeviceData(twIncomes.GetNodeData(HighLightedNode)^).HighLight := True;
    twIncomes.Repaint;
  end;
end;

{procedure TMainForm.WMActivate(var Message: TMessage);
begin
  if IsClosing then
    Exit;

  if ((Message.WParam = WA_ACTIVE)
    or (Message.WParam = WA_CLICKACTIVE)) then
  begin
    Application.Restore;
    SetForegroundWindow(Handle);
  end;

//  if GetForegroundWindow = Handle then
//    bDevices.Font.Color := clBlack
//  else
//    bDevices.Font.Color := clBtnShadow;

  Message.Result := 0;

//  inherited;
end;}

(* Code for all the Buttons on our Form *)

procedure TMainForm.eUserNameChange(Sender: TObject);
begin
//  PClient.LoginUsername := Trim(eUserName.Text);
// Changing "LoginUserName" will clear all LoginUserInfo parameters,
// so we should reflect this on the user interface as well ...
//  eRealName.Text:='';
end;

procedure TMainForm.eUserNameDblClick(Sender: TObject);
begin
//  XLog('eUserNameDblClick');

  if Visible then
    eUserName.SelectAll;
end;

procedure TMainForm.eAccountPasswordChange(Sender: TObject);
begin
  AccountPassword := System.Hash.THashMD5.GetHashString(eAccountPassword.Text);
end;

procedure TMainForm.eAccountUserNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Mgs: TMsg;
begin
//  XLog('eAccountUserNameKeyDown');

  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);
end;

procedure TMainForm.eAccountUserNameKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//  XLog('eAccountUserNameKeyUp');

  case Key of
    VK_RETURN:
      btnAccountLoginClick(nil);
  end;
end;

procedure TMainForm.eConsoleIDDblClick(Sender: TObject);
begin
//  XLog('eConsoleIDDblClick');

  if Visible then
    eConsoleID.SelectAll;
end;

procedure TMainForm.eDeviceNameChange(Sender: TObject);
var
  Node, CNode: PVirtualNode;
  DData: PDeviceData;
begin
  if Trim(eDeviceName.Text) <> '' then
  begin
    Node := twDevices.GetFirst();
    while Node <> nil do
    begin
      DData := twDevices.GetNodeData(Node);
      if (DData^.UID <> '') then
       if (StrPos(PWideChar(WideLowerCase(DData^.Name)), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
        or ((StrPos(PWideChar(DData^.ID), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
          and (DData^.ID <> '')) then
        Node.States := Node.States + [vsVisible]
       else
        Node.States := Node.States - [vsVisible];

      if Node.ChildCount > 0 then
      begin
        CNode := Node.FirstChild;
        while CNode <> nil do
        begin
          DData := twDevices.GetNodeData(CNode);
          if (DData^.UID <> '') then
           if (StrPos(PWideChar(WideLowerCase(String(DData^.Name))), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
            or ((StrPos(PWideChar(DData^.ID), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
              and (DData^.ID <> '')) then
           begin
            CNode.States := CNode.States + [vsVisible];
            CNode.Parent.States := CNode.Parent.States + [vsVisible];
            twDevices.Expanded[CNode.Parent] := True;
           end
           else
            CNode.States := CNode.States - [vsVisible];

          CNode := CNode.NextSibling;
        end;
      end;
      Node := Node.NextSibling;
    end;
  end
  else
  begin
    Node := twDevices.GetFirst();
    while Node <> nil do
    begin
      DData := twDevices.GetNodeData(Node);
      if (DData^.UID <> '') then
        Node.States := Node.States + [vsVisible];

      if Node.ChildCount > 0 then
      begin
        CNode := Node.FirstChild;
        while CNode <> nil do
        begin
          DData := twDevices.GetNodeData(CNode);
          if (DData^.UID <> '') then
            CNode.States := CNode.States + [vsVisible];

          CNode := CNode.NextSibling;
        end;
      end;

      Node := Node.NextSibling;
    end;
  end;

  twDevices.Repaint;
end;

procedure TMainForm.ePartnerIDDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  with TComboBox(Control), TComboBox(Control).Canvas do
  begin
    FillRect(Rect);
    Font.Size := 10;
    TextOut(Rect.Left + 2, Rect.Top + 2, Items[Index]);
  end;
end;

procedure TMainForm.ePartnerIDKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//  XLog('ePartnerIDKeyUp');

  if Key = 13 then
    btnNewConnectionClick(nil);
end;

procedure TMainForm.ePasswordChange(Sender: TObject);
begin
  //PClient.LoginPassword:=Trim(ePassword.Text);
end;

//procedure TMainForm.ConnectToGateway;
//  begin
////  if Sender<>nil then
////    begin
//    SaveSetup;
//
////    if PClient.GateAddr='' then
////      begin
////      ShowMessage('Please, enter your Gateway''s Address.');
//////      btnGateway.Click;
////      Exit;
////      end;
////    if PClient.GatePort='' then
////      begin
////      ShowMessage('Please, enter your Gateway''s Port.');
//////      btnGateway.Click;
////      Exit;
////      end;
//
////    SetStatusString('Подготовка соединения', True);
//
////    btnLogin.Enabled:=False;
//
////    PClient.Stop;
//    // PClient.Stop;
////    end
////  else
////    begin
////    PClient.Disconnect;
////    btnLogin.Enabled:=False;
////    end;
//
////  if Sender=nil then
// //   lblStatus.Caption:=lblStatus.Caption+#13#10+'Making a new Login attempt ...'
////  else
////  lblStatus.Caption:='Активация Remox', True;
////  lblStatus.Update;
//
//  ReqCnt1:=0;
//  ReqCnt2:=0;
//
////  if xAutoConnect.Checked then
////    PClient.RetryOtherCalls:=10
////  else
////    PClient.RetryOtherCalls:=3;
//
////  PClient.RetryOtherCalls:=-1;
//
////  if xAdvanced.Checked then
////    PClient.GParamsLoaded:=True
////  else
////  PClient.Active:=True;
//  end;

procedure TMainForm.AccountLogOut(Sender: TObject);
begin
//  xLog('AccountLogOut');
//  if Assigned(Options)
//     and Options.Visible then
//  begin
//    Options.ModalResult := mrClose;
//    Options.Close;
//  end;
//  if Assigned(sett)
//     and sett.Visible then
//  begin
//    sett.ModalResult := mrClose;
//    sett.Close;
//  end;
//  if Assigned(PassForm)
//     and PassForm.Visible then
//  begin
//    PassForm.ModalResult := mrClose;
//    PassForm.Close;
//  end;
//  if Assigned(GForm)
//     and GForm.Visible then
//  begin
//    GForm.ModalResult := mrClose;
//    GForm.Close;
//  end;
//  if Assigned(DForm)
//     and DForm.Visible then
//  begin
//    DForm.ModalResult := mrClose;
//    DForm.Close;
//  end;
//  if Assigned(fReg)
//     and fReg.Visible then
//  begin
//    fReg.ModalResult := mrClose;
//    fReg.Close;
//  end;
//  if Assigned(fAbout)
//     and fAbout.Visible then
//  begin
//    fAbout.ModalResult := mrClose;
//    fAbout.Close;
//  end;

  do_notify := False;

  pingTimer.Enabled := False;

  if Sender <> nil then
  begin
    with cmAccounts do
    try
      with Data.NewFunction('Account.Logout') do
      begin
        Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
        asWideString['Account'] := LowerCase(eAccountUserName.Text);
        Call(resLogout);
      end;
      WaitForCompletion(True, 1, True);
    except
      on E: Exception do
        Data.Clear;
    end;

//    cmAccounts.WaitForCompletion(False, 10);
//    xLog('ACC LOGOUT');
  end
  else
  begin
    do_notify := False;
//    pingTimer.Enabled := False;
//    HostPingTimer.Enabled := False;

//    pDevices.Visible := False;
//    pAccount.Visible := True;
//    miAccLogOut.Caption := 'Выход';
//    LoggedIn := False;

//    SetConnectedState(False);
  end;

  AccountName := '';
  AccountUID := '';
  LoggedIn := False;
  ShowDevicesPanel;
end;

procedure TMainForm.HostLogOut;
begin
//  xLog('HostLogOut');

//  HostPingTimer.Enabled := False;

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если сервер
  //Этот модуль и так не работает в службе
//  if IsWinServer
//    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
//  begin
    with TimerModule do
    try
      with Data.NewFunction('Host.Logout') do
      begin
        asWideString['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
        asBoolean['IsService'] := False;
        Call(resHostLogout);
        WaitForCompletion(True, 1, True);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;

//    xLog('HOST LOGOUT');
//  end;
end;

procedure TMainForm.lRegistrationClick(Sender: TObject);
var
  PrevRegularPass: String;
begin
//  XLog('lRegistrationClick');

//  if not ConnectedToAllGateways then
//  begin
////    MessageBox(Handle, 'Нет подключения к серверу', 'Remox', MB_ICONWARNING or MB_OK);
//    SetStatusStringDelayed('Нет подключения к серверу');
//    Exit;
//  end;

  ShellExecute(0, 'open', PChar('http://remox.com/register'), '', nil, SW_SHOW);

//  if Assigned(fReg) then
//  begin
//    fReg.Free;
//    fReg := nil;
//  end;
//  fReg := TRegistrationForm.Create(Self);
////  fReg.Parent := Self;
////  AutoScaleForm(fReg);
//  fReg.CModule := cmAccounts;
//  PrevRegularPass := PermanentPassword;
//  fReg.eDevicePassword.Text := PermanentPassword;
//  fReg.eDevicePasswordConfirm.Text := PermanentPassword;
//  fReg.ThisDeviceID := PClient.LoginUserName;
//  fReg.AccountLoginProcedure := DoAccountLogin;
//  fReg.MF_AccountName := eAccountUserName;
//  fReg.MF_AccountPass := eAccountPassword;
//
//  fReg.HTTPClient.AutoConnect := False;
//  fReg.HTTPClient.Disconnect;
//  fReg.HTTPClient.Session.Close;
//
//  fReg.HTTPClient.UseProxy := PClient.Gate_Proxy;
//  fReg.HTTPClient.UserLogin.ProxyAddr := PClient.Gate_ProxyAddr;
//
//  fReg.HTTPClient.AutoConnect := True;
//  fReg.HTTPClient.Connect(True, True);
//
//  fReg.ShowModal;
//  if fReg.ModalResult = mrOk then
//  begin
//    if PermanentPassword <> PrevRegularPass then
//    begin
//      PermanentPassword := fReg.eDevicePassword.Text;
//      ShowPermanentPasswordState();
//      SendPasswordsToGateway;
//      SaveSetup;
//    end;
//  end;
//  fReg.Free;
//  fReg := nil;
end;

procedure TMainForm.lRegistrationMouseEnter(Sender: TObject);
begin
//  XLog('lRegistrationMouseEnter');

  Screen.Cursor := crHandPoint;
end;

procedure TMainForm.lRegistrationMouseLeave(Sender: TObject);
begin
//  XLog('lRegistrationMouseLeave');

  Screen.Cursor := crDefault;
end;

procedure TMainForm.lRestorePasswordClick(Sender: TObject);
begin
//  XLog('lRestorePasswordClick');

  ShellExecute(0, 'open', PChar('http://remox.com/lostpassword'), '', nil, SW_SHOW);
end;

procedure TMainForm.xForceCursorClick(Sender: TObject);
begin
  //SaveSetup;
//  if xForceCursor.Checked then
//    PDesktopControl.NotifyUI(RTCPDESKTOP_ExactCursor_On)
//  else
//    PDesktopControl.NotifyUI(RTCPDESKTOP_ExactCursor_Off);
end;

procedure TMainForm.xHideWallpaperClick(Sender: TObject);
begin
  //SaveSetup;
//  if xSmoothView.Checked then
//    PDesktopControl.NotifyUI(RTCPDESKTOP_SmoothScale_On)
//  else
//    PDesktopControl.NotifyUI(RTCPDESKTOP_SmoothScale_Off);
end;

procedure TMainForm.xKeyMappingClick(Sender: TObject);
begin
//  {$IFNDEF RtcViewer}
//  //SaveSetup;
//  if xKeyMapping.Checked then
//    PDesktopControl.NotifyUI(RTCPDESKTOP_MapKeys_On)
//  else
//    PDesktopControl.NotifyUI(RTCPDESKTOP_MapKeys_Off);
//  {$ENDIF}
end;

procedure TMainForm.xReduceColorsClick(Sender: TObject);
begin
//  //SaveSetup;
//  if xSmoothView.Checked then
//    PDesktopControl.NotifyUI(RTCPDESKTOP_SmoothScale_On)
//  else
//    PDesktopControl.NotifyUI(RTCPDESKTOP_SmoothScale_Off);
  end;

procedure TMainForm.xSmoothViewClick(Sender: TObject);
begin
//  //SaveSetup;
//  if xSmoothView.Checked then
//    PDesktopControl.NotifyUI(RTCPDESKTOP_SmoothScale_On)
//  else
//    PDesktopControl.NotifyUI(RTCPDESKTOP_SmoothScale_Off);
end;

procedure TMainForm.btnSettingsClick(Sender: TObject);
var
  Options: TrdHostSettings;
begin
//  XLog('btnSettingsClick');
  if tPHostThread = nil then
    Exit;

  Options := TrdHostSettings.Create(self);
  try
//    Options.Parent := Self;
    Options.PClient := tPHostThread.FGatewayClient;
    Options.PDesktop := tPHostThread.FDesktopHost;
    Options.PChat := tPHostThread.FChat;
    Options.PFileTrans := tPHostThread.FFileTransfer;
    Options.OnCustomFormClose := OnCustomFormClose;
    Options.Execute;
    OnCustomFormOpen(@Options);
  finally
    Options.Free;
  end;
end;

procedure TMainForm.btnShowMyDesktopClick(Sender: TObject);
// {$IFNDEF RtcViewer}
//  var
//    user:string;
//    R:TRect;
//    selRegion:TdmSelectRegion;
  begin
//  if (eUsers.ItemIndex>=0) and
//     (eUsers.Items[eUsers.ItemIndex]<>'') then
//    begin
//    user:=eUsers.Items[eUsers.ItemIndex];
//
//    if eConnected.Items.Count=0 then
//      begin
//      if MessageDlg('Limit Visible Desktop Region?'#13#10#13#10+
//                    'Click "YES" and select a region with your mouse, or'#13#10+
//                    'Click "NO" to show your Primary Screen to remote users.',
//                    mtConfirmation,[mbYes,mbNo],0)=mrYes then
//        begin
//        WindowState:=wsMinimized;
//        try
//          Sleep(500);
//          selRegion:=TdmSelectRegion.Create(nil);
//          try
//            R:=selRegion.GrabScreen(True);
//          finally
//            SelRegion.Free;
//            end;
//        finally
//          WindowState:=wsNormal;
//          end;
//        end
//      else
//        R:=Rect(0,0,Screen.Width,Screen.Height);
//
//      PDesktopHost.ScreenRect:=R;
//      PDesktopHost.GFullScreen:=False;
//      PDesktopHost.GAllowView:=True;
//      PDesktopHost.GAllowView_Super:=True;
//      PDesktopHost.GCaptureAllMonitors:=True;
//      PDesktopHost.GUseMirrorDriver:=True;
//
//      PDesktopHost.Restart;
//      end;
//
//    PDesktopHost.Open(user);
//    end
////  else
////    MessageBeep(0);
//  end;
//  {$ELSE}
//  begin
//  //ShowMessage('This option is not available in Remox.');
  end;
//  {$ENDIF}

procedure TMainForm.bAccount0Click(Sender: TObject);
var
  p: TPoint;
begin
//  XLog('bAccount0Click');

  p.X := pcDevAcc.Left + pInMain.Left + btnAccount.Left + 5;
  p.Y := btnAccount.Height + pInMain.Top + pcDevAcc.Top + btnAccount.Top + btnAccount.Height;
  p := ClientToScreen(p);
  pmAccount.Popup(p.X, p.Y);;
end;

procedure TMainForm.bCloseAllIncomesClick(Sender: TObject);
var
  Node: PVirtualNode;
  DData: PDeviceData;
  cnt: Integer;
begin
  Node := twIncomes.GetFirst;
  while Node <> nil do
  begin
    DData := twIncomes.GetNodeData(Node);
//    TSendDestroyClientToGatewayThread.Create(False, tPHostThread.Gateway, GetUserFromFromUserName(DData^.Name), False, hcAccounts.UseProxy, hcAccounts.UserLogin.ProxyAddr, hcAccounts.UserLogin.ProxyUserName, hcAccounts.UserLogin.ProxyPassword, True);
    SendManualLogoutToControl(DData^.Action, GetUserFromFromUserName(DData^.Name), DeviceId);
    Node := twIncomes.GetNext(Node);
  end;

  twIncomes.Clear;
  twIncomes.Repaint;

  cnt := GetIncomeConnectionsCount;
  tsIncomes.Caption := 'Входящие подключения (' + IntToStr(cnt) + ')';
  if cnt = 0 then
    pcDevAcc.ActivePage := tsMyDevices;
end;

procedure TMainForm.bCloseAllIncomesMouseEnter(Sender: TObject);
begin
  bCloseAllIncomes.Color := RGB(231, 84, 87);
end;

procedure TMainForm.bCloseAllIncomesMouseLeave(Sender: TObject);
begin
  bCloseAllIncomes.Color := RGB(241, 94, 97);
end;

procedure TMainForm.bDevicesMouseEnter(Sender: TObject);
begin
  TColorSpeedButton(Sender).Color := RGB(220, 220, 220);
end;

procedure TMainForm.bDevicesMouseLeave(Sender: TObject);
begin
  TColorSpeedButton(Sender).Color := RGB(230, 230, 230);
end;

procedure TMainForm.bGetUpdateClick(Sender: TObject);
var
  UpdateStatus: Integer;
  Progress: Integer;
begin
  if FUpdateAvailable then
//    ShellExecute(Handle, 'open', 'http://remox.com/download/', '', '', SW_SHOWNORMAL);
  if IsServiceStarted(RTC_HOSTSERVICE_NAME)
    or IsServiceStarting(RTC_HOSTSERVICE_NAME) then
    SendStartUpdateToService
  else
  begin
    tDMUpdate.DMUpdate.GetProgress(UpdateStatus, Progress);
    if UpdateStatus = US_READY then
    begin
      tDMUpdate.DMUpdate.StartUpdate(hcAccounts.UseProxy, hcAccounts.UserLogin.ProxyAddr, hcAccounts.UserLogin.ProxyUserName, hcAccounts.UserLogin.ProxyPassword);
      tCheckUpdateStatus.Enabled := True;
    end;
  end;
end;

procedure TMainForm.bGetUpdateMouseEnter(Sender: TObject);
begin
  if FUpdateAvailable then
    bGetUpdate.Color := clWhite
  else
    bGetUpdate.Color := $fff3e5;
end;

procedure TMainForm.bGetUpdateMouseLeave(Sender: TObject);
begin
  bGetUpdate.Color := clBtnFace;
end;

procedure TMainForm.cPriorityChange(Sender: TObject);
//  var
//    hProcess:Cardinal;
  begin
//  hProcess:=GetCurrentProcess;
//  case cPriority.ItemIndex of
//    0:SetPriorityClass(hProcess, HIGH_PRIORITY_CLASS);
//    1:SetPriorityClass(hProcess, NORMAL_PRIORITY_CLASS);
//    2:SetPriorityClass(hProcess, IDLE_PRIORITY_CLASS);
//    end;
//  //if Sender<>nil then
//    //SaveSetup;
  end;

procedure TMainForm.cPriority_ControlChange(Sender: TObject);
begin

end;

(* Various "Windows Shell" commands *)

function TMainForm.CheckService(bServiceFilename: Boolean = True {False = Service Name} ): String;
begin
  if bServiceFilename then
    Result := AppFileName
  else
    Result := RTC_HOSTSERVICE_NAME;
end;

{procedure TMainForm.HostPingTimerTimer(Sender: TObject);
var
  PassRec: TRtcRecord;
begin
//  xLog('HostPingTimerTimer');

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если сервер
  //Эта процедура и так не работает в службе
//  if IsWinServer
//    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
//  begin
//    HostPingTimer.Enabled := False;

//    if not hcAccounts.IsConnected then
//      Exit;

//    LoadSetup('PERMANENT_PASS');

    PassRec := TRtcRecord.Create;
    try
      PassRec.asString['0'] := System.Hash.THashMD5.GetHashString(ePassword.Text);
      if Trim(PermanentPassword) <> '' then
        PassRec.asString['1'] := PermanentPassword;

      with cmAccounts do
      try
        with Data.NewFunction('Host.Ping') do
        begin
          asWideString['User'] := DeviceId;
          if tPHostThread <> nil  then
            asString['Gateway'] := tPHostThread.Gateway + ':' + tPHostThread.Port
          else
            asString['Gateway'] := '';
          asRecord['Passwords'] := PassRec;
          if ActiveConsoleSessionID = CurrentSessionID then
            asString['ConsoleId'] := ConsoleId
          else
            asString['ConsoleId'] := '';
          asInteger['LockedState'] := ScreenLockedState;
          asBoolean['ServiceStarted'] := IsServiceStarted(RTC_HOSTSERVICE_NAME);
          asBoolean['IsService'] := IsService;
          Call(resHostPing);
        end;
      except
        on E: Exception do
          Data.Clear;
      end;
    finally
      FreeAndNil(PassRec);
    end;
end;}

procedure TMainForm.HostTimerClientConnect(Sender: TRtcConnection);
begin
//  xLog('HostTimerClientConnect');

  tHostTimerClientReconnect.Enabled := False;
end;

procedure TMainForm.HostTimerClientDisconnect(Sender: TRtcConnection);
begin
//  xLog('HostTimerClientDisconnect');

  ChangePort(HostTimerClient);

  if (not isClosing)
    and (not SettingsFormOpened) then
    tHostTimerClientReconnect.Enabled := True;
end;

procedure TMainForm.HostTimerModuleResponseAbort(Sender: TRtcConnection);
begin
//  with TRtcDataClient(Sender) do
//  begin
//    LogOut(nil);
////    lblStatus.Caption := 'Error sending a request to the server. Connection lost.';
//  end;
end;

procedure TMainForm.btnInstallClick(Sender: TObject);
begin
//  SaveSetup;
////  ShellExecute(0, 'open', PChar(CheckService), '/INSTALL /SILENT', nil, SW_SHOW);
//  if not ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
//    SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/INSTALL /SILENT', Handle, Application.ProcessMessages));
end;

procedure TMainForm.btnUninstallClick(Sender: TObject);
begin
////  ShellExecute(0, 'open', PChar(CheckService), '/UNINSTALL /SILENT', nil, SW_SHOW);
//  if ServiceInstalled(nil, RTC_HOSTSERVICE_NAME) then
//    SetLastError(EleavateSupport.RunElevated(ParamStr(0), '/UNINSTALL /SILENT', Handle, Application.ProcessMessages));
end;

procedure TMainForm.btnNewConnectionClick(Sender: TObject);
var
  user, pass, action: String;
  Data: PDeviceData;
  i: Integer;
begin
//  XLog('btnViewDesktopClick');

  if not ConnectedToAllGateways then
  begin
//    MessageBox(Handle, 'Нет подключения к серверу', 'Remox', MB_ICONWARNING or MB_OK);
    if Sender <> nil then
      SetStatusStringDelayed('Нет подключения к серверу');
    Exit;
  end;

  if btnNewConnection.Caption = 'ПРЕРВАТЬ' then
  begin
    DeleteLastPendingItem;

//    if GetPendingRequestsCount > 0 then
//    begin
//      SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True);
//      btnViewDesktop.Caption := 'ПРЕРВАТЬ';
//      btnViewDesktop.Color := RGB(232, 17, 35);
//    end
//    else
//      SetStatusString('Готов к подключению');
  end
  else
  begin
    if ePartnerID.ItemIndex <> -1 then
      user := StringReplace(THistoryRec(ePartnerID.Items.Objects[ePartnerID.ItemIndex]).user, ' ', '', [rfReplaceAll])
    else
      user := StringReplace(ePartnerID.Text, ' ', '', [rfReplaceAll]);
    if rbDesktopControl.Checked then
      action := 'desk'
    else
    if rbFileTrans.Checked then
      action := 'file';
  //  else
  //  if rbChat.Checked then
  //    action := 'chat'
  //    end;

    Data := GetDeviceInfo(user);
    if Data <> nil then
    begin
      //Если ранее был сохранен верный пароль берем его, а не из списка устройств
      if StorePasswords then
      begin
        for i := 0 to ePartnerID.Items.Count - 1 do
          if THistoryRec(ePartnerID.Items.Objects[i]).user = user then
          begin
            Data.Password := THistoryRec(ePartnerID.Items.Objects[i]).password;
            Break;
          end;
      end;

      ConnectToPartnerStart(user, Data.Name, Data.Password, action);
    end
    else
    begin
      pass := '';
      //Если ранее был сохранен верный пароль берем его, а не из списка устройств
      if StorePasswords then
      begin
        for i := 0 to ePartnerID.Items.Count - 1 do
          if THistoryRec(ePartnerID.Items.Objects[i]).user = user then
          begin
            pass := THistoryRec(ePartnerID.Items.Objects[i]).password;
            Break;
          end;
      end;

      ConnectToPartnerStart(user, user, pass, action);
    end;
  end;
end;

procedure TMainForm.btnNewConnectionMouseEnter(Sender: TObject);
begin
//  XLog('btnViewDesktopMouseEnter');

  CS_Status.Acquire;
  try
    if btnNewConnection.Caption = 'ПОДКЛЮЧИТЬСЯ' then
      if TColorSpeedButton(Sender).Enabled then
        TColorSpeedButton(Sender).Color := $00B3A332
      else
        TColorSpeedButton(Sender).Color := $00A39322
    else
      if TColorSpeedButton(Sender).Enabled then
        TColorSpeedButton(Sender).Color := RGB(232, 17, 35)
      else
        TColorSpeedButton(Sender).Color := RGB(241, 112, 122);
  finally
    CS_Status.Release;
  end;
end;

procedure TMainForm.btnNewConnectionMouseLeave(Sender: TObject);
begin
//  XLog('btnViewDesktopMouseLeave');

  CS_Status.Acquire;
  try
    if btnNewConnection.Caption = 'ПОДКЛЮЧИТЬСЯ' then
      TColorSpeedButton(Sender).Color := $00A39322
    else
      TColorSpeedButton(Sender).Color := RGB(232, 17, 35);
  finally
    CS_Status.Release;
  end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
//    PClient.Disconnect;
//    PClient.Active := False;
////    PClient.Stop;
////    PClient.GParamsLoaded:=True;
//    PClient.Active := True;
end;

procedure TMainForm.Button2Click(Sender: TObject);
//var
//  i: Integer;
//  rc, rc2: TRtcRecord;
begin
//    PClient.Active := False;
////    PClient.Stop;
////    PClient.GParamsLoaded:=True;
//    PClient.Active := True;

//  PostThreadMessage(PPortalConnection(PortalConnectionsList[0])^.ThreadID, WM_UICLOSE, 0, 0);
//  rc := TRtcRecord.Create;
//  rc.AutoCreate := True;
//  rc.asInteger['b1'] := 1;
//  rc.asInteger['b2'] := 2;
//  rc2 := TRtcRecord.Create;
//  rc2.FromCode(rc.ToCode);
//  rc.Free;
//  rc2.Free;

//  for i := 0 to GatewayClientsList.Count - 1 do
//  begin
////    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
////    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//////    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Stop;
//////    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.GParamsLoaded:=True;
////    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//  end;
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
//  PPortalConnection(PortalConnectionsList[0])^.ThisThread^.Terminate;
//  PostThreadMessage(PPortalConnection(PortalConnectionsList[0])^.ThreadID, WM_DESTROY, 0, 0);
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
//  BlankOutScreen(True);

//    PClient.Disconnect;
////    PClient.Active := False;
//    PClient.Stop;
////    PClient.GParamsLoaded:=True;
//    PClient.Active := True;

//  PDesktopControl.Open('34343434');

//  TSendDestroyClientToGatewayThread.Create(False, '95.216.96.8:443', '111222333', False);

//  pd := TProgressDialog.Create(Self);
//  pd.OnCancel := OnProgressDialogCancel;
//  pd.Execute;
end;

procedure TMainForm.Button5Click(Sender: TObject);
var
  infos: TMonitorInfoList;
begin
  infos := GetMonitorListEx();
//  if tPHostThread <> nil then
//    tPHostThread.Restart;
  ActivateHost;
end;

procedure TMainForm.AddHistoryRecord(username, userdesc: String);
var
  hr: THistoryRec;
  fFound: Boolean;
  i: Integer;
begin
  if StoreHistory then
  begin
    fFound := False;
    for i := 0 to ePartnerID.Items.Count - 1 do
      if THistoryRec(ePartnerID.Items.Objects[i]).user = username then
      begin
        fFound := True;
        Break;
      end;
    if not fFound then
    begin
      hr := THistoryRec.Create;
      hr.user := username;
      hr.username := userdesc;
      hr.password := '';
      ePartnerID.Items.InsertObject(0, userdesc, hr);
    end;
  end;
end;

procedure TMainForm.AddPasswordsRecord(username, userpass: String);
var
  hr: THistoryRec;
  i: Integer;
begin
  if StorePasswords then
  begin
    for i := 0 to ePartnerID.Items.Count - 1 do
      if THistoryRec(ePartnerID.Items.Objects[i]).user = username then
      begin
        THistoryRec(ePartnerID.Items.Objects[i]).password := userpass;
        Break;
      end;
  end;
end;

function TMainForm.GetUniqueString: String;
var
  UID: TGUID;
begin
  CreateGuid(UID);
  Result := GUIDToString(UID);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
end;

procedure TMainForm.ConnectToPartnerStart(UserName, UserDesc, UserPass, Action: String);
var
//  p: TPoint;
  PortalConnection: PPortalConnection;
  s: String;
  i: Integer;
begin
//  xLog('ConnectToPartnerStart');

  if UserName = '' then
  begin
//    MessageBox(Handle, 'Введите ID компьютера, к которому хотите подключиться', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Введите ID устройства, к которому хотите подключиться');
//    SetStatusStringDelayed('Готов к подключению', 2000);
//    bhMain.ShowHint(ePartnerID);

    if Visible then
    begin
      ePartnerID.SetFocus;
      ePartnerID.SelectAll;
    end;

    Exit;
  end;
  if not IsValidDeviceID(UserName) then
  begin
//    MessageBox(Handle, 'ID компьютера может содержать только цифры', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('ID устройства может содержать только цифры');
//    SetStatusStringDelayed('Готов к подключению', 2000);

    if Visible then
    begin
      ePartnerID.SetFocus;
      ePartnerID.SelectAll;
    end;

    Exit;
  end;
  if UserName = DeviceId then
  begin
//    MessageBox(Handle, 'Подключение к своему компьютеру невозможно', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Подключение к своему устройству невозможно');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Exit;
  end;
//  if GetDeviceStatus(UserName) = MSG_STATUS_OFFLINE then
//  begin
//    MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
//      SetStatusString('Готов к подключению');
//    Exit;
//  end;
  if CurStatus = STATUS_OLD_VERSION then
  begin
//    MessageBox(Handle, 'Подключение к своему компьютеру невозможно', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Подключение невозможно. Обновите программу');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Exit;
  end;

  if UseConnectionsLimit then
  begin
    CurConnectionsPendingMinuteCount := CurConnectionsPendingMinuteCount + 1;
    if CurConnectionsPendingMinuteCount >= MAX_CONNECTIONS_PENDING_IN_MIMUTE then
    begin
      if CurConnectionsPendingMinuteCount = MAX_CONNECTIONS_PENDING_IN_MIMUTE then
      begin
        DateAllowConnectionPending := IncMinute(Now, 3);
        SaveSetup;
      end;
      DateTimeToString(s, 'dd.mm.yyyy hh:nn:ss', DateAllowConnectionPending);
//      MessageBox(Handle, PWideChar('Превышен лимит попыток. Следующая попытка не ранее ' + s), 'Remox', MB_OK);
      SetStatusStringDelayed('Превышен лимит попыток. Следующая попытка не ранее ' + s);
//      SetStatusStringDelayed('Готов к подключению', 2000);
      Exit;
    end;
  end;

//  SetStatusString('Подключение к ' + UserDesc, True);

  PortalConnection := GetPortalConnection(Action, UserName); //При повторном подключении ищем уже открытое
  if PortalConnection <> nil then
  begin
//    BringWindowToTop(ActiveUIRec^.Handle);
//    SetForegroundWindow(ActiveUIRec^.Handle);
    ForceForegroundWindow(DesktopsForm.Handle);
    DesktopsForm.SetActiveTab(UserName);
//    SetStatusString('Готов к подключению');
    Exit;
  end;

  AddPendingRequest(UserName, UserDesc, Action, False);
  SetStatusStringDelayed('');

  DoGetDeviceState(eAccountUserName.Text,
    LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll])),
    AccountPassword,
    UserName);

  with cmAccounts do
  try
    with Data.NewFunction('Host.GetUserInfo') do
    begin
      asWideString['User'] := userName;
      asWideString['Pass'] := UserPass;
      asString['Action'] := Action;
      Call(rGetPartnerInfo);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.rGetPartnerInfoReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
//  GatewayClient: PRtcHttpPortalClient;
//  DesktopControl: PRtcPDesktopControl;
//  FileTransfer: PRtcPFileTransfer;
//  Chat: PRtcPChat;
//  GatewayRec: PGatewayRec;
//  PRItem: PPendingRequestItem;
  username, sUID: String;
  PortalThread: TPortalThread;
//  PassForm: TfIdentification;
  PRItem: PPendingRequestItem;
begin
//  xLog('rGetPartnerInfoReturn');

  if Result.isType = rtc_Exception then
  begin
//  LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
  if Result.isType <> rtc_Record then
  begin
//    SetStatusString('Некорректный ответ от сервера');
  end
  else
  with Result.asRecord do
  begin
    if PassForm.Active
      and (asWideString['user'] <> PassForm.UserName) then //Ничего не подключаем если форма ввода пароля активна
    begin
      RemovePortalConnection(asWideString['user'], asString['action'], False);
      DeletePendingRequest(asWideString['user'], asString['action']);
    end
    else
    if (asString['Result'] = 'IS_OFFLINE') then
    begin
//      MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
      SetStatusStringDelayed('Партнер не в сети. Подключение невозможно');
//      SetStatusStringDelayed('Готов к подключению', 2000);

//      PRItem := GetPendingItem(asWideString['user'], asString['action']);
//      if PRItem = nil then
//        Exit;

      RemovePortalConnection(asWideString['user'], asString['action'], False);
      DeletePendingRequest(asWideString['user'], asString['action']);

      if asString['action'] = 'desk' then
        DesktopsForm.SetReconnectInterval(asWideString['user'], 10000);

//      DoGetDeviceState(eAccountUserName.Text,
//        PClient.LoginUserName,
//        AccountPassword,
//        asWideString['user']);
    end
    else
    if asString['Result'] = 'OK' then
    begin
      PRItem := GetPendingItem(asWideString['User'], asString['action']);
      if PRItem = nil then
        Exit;

      username := GetUserNameByID(asWideString['user']);

      if asWideString['UserToConnect'] <> asWideString['user'] then
        ChangePendingRequestUser(asWideString['action'], asWideString['user'], asWideString['UserToConnect']);

      if not PartnerIsPending(asWideString['user'], asString['action'], asString['Address']) then
      begin
        if (asWideString['action'] = 'desk')
          and (asInteger['LockedState'] = LCK_STATE_LOCKED)
          and (not asBoolean['ServiceStarted']) then
        begin
          SetStatusStringDelayed('Устройство партнера заблокировано. Подключение запрещено');
          DeletePendingRequest(asWideString['UserToConnect'], asString['action']);
        end
        else
        begin
//          TSendDestroyClientToGatewayThread.Create(False, asString['Address'], StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]) + '_' + asWideString['UserToConnect'] + '_' + asWideString['action'] + '_', False, hcAccounts.UseProxy, hcAccounts.UserLogin.ProxyAddr, hcAccounts.UserLogin.ProxyUserName, hcAccounts.UserLogin.ProxyPassword, False);
          PortalThread := TPortalThread.Create(False, asString['action'], asWideString['user'], asWideString['pass'], asWideString['UserToConnect'], asString['Address'], asInteger['LockedState'], asBoolean['ServiceStarted'], True); //Для каждого соединения новый клиент
          PRItem^.Gateway := asString['Address'];
          PRItem^.ThreadID := PortalThread.ThreadID;
        end;
      end;

      //Добавим в историю при успешном логине
      AddHistoryRecord(asWideString['user'], username);
      //Сохраним пароль в истории при успешном логине
      AddPasswordsRecord(asWideString['user'], asWideString['Pass']);

//      ConnectToPartner(GatewayRec, asWideString['user'], username, asString['action']);

      if asString['action'] = 'desk' then
        DesktopsForm.SetReconnectInterval(asWideString['user'], 10000); //60000
    end
    else
    if asString['Result'] = 'PASS_NOT_VALID' then
    begin
      PRItem := GetPendingItem(asWideString['user'], asString['action']);
      if PRItem = nil then
        Exit;

      if PRItem^.IsReconnection then
      begin
        DeletePendingRequest(asWideString['user'], asString['action']);
        DesktopsForm.CloseUIAndTab(asWideString['user'], True, PRItem^.ThreadID);

        Exit;
      end;

      username := GetUserNameByID(asWideString['user']);

//      PassForm.Parent := Self;

      if PassForm.UserName <> asWideString['user'] then
        PassForm.ePassword.Text := '';

//      if StorePasswords then
//      begin
//        for i := 0 to ePartnerID.Items.Count - 1 do
//          if THistoryRec(ePartnerID.Items.Objects[i]).user = asWideString['user'] then
//          begin
//            PassForm.ePassword.Text := THistoryRec(ePartnerID.Items.Objects[i]).password;
//            Break;
//          end;
//      end;

      PassForm.UserName := asWideString['user'];
      PassForm.UserDesc := username;
      PassForm.Action := asString['action'];
      PassForm.ThreadId := PRItem^.ThreadID;
      PassForm.OnCustomFormClose := OnCustomFormClose;
      PassForm.OnCloseForm := OnClosePassForm;
      OnCustomFormOpen(@PassForm);
//      DesktopsForm.SetReconnectInterval(asWideString['user'], 999999999);
      PassForm.Show;
//      mResult := PassForm.ModalResult;
//      if mResult = mrOk then
//      begin
//        ConnectToPartnerStart(asWideString['user'], username, System.Hash.THashMD5.GetHashString(PassForm.ePassword.Text), asString['action']);
////        DesktopsForm.SetReconnectInterval(asWideString['user'], 60000);
//      end
//      else
//      begin
//        begin
//          DeletePendingRequest(asWideString['user'], asString['action']);
//          DesktopsForm.CloseUIAndTab(asWideString['user'], True, PRItem^.ThreadID);
//        end;
//
////        if GetPendingRequestsCount > 0 then
////          SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
////        else
////          SetStatusString('Готов к подключению');
//      end;
    end;
  end;
end;

procedure TMainForm.OnClosePassForm(Sender: TObject);
var
  fPassform: TfIdentification;
begin
  fPassform := (Sender as TfIdentification);
  if fPassform.ModalResult = mrOk then
  begin
    ConnectToPartnerStart(fPassform.UserName, fPassform.UserDesc, System.Hash.THashMD5.GetHashString(fPassform.ePassword.Text), fPassform.Action);
//        DesktopsForm.SetReconnectInterval(asWideString['user'], 60000);
  end
  else
  begin
    DeletePendingRequest(fPassform.UserName, fPassform.Action);
    DesktopsForm.CloseUIAndTab(fPassform.UserName, True, fPassform.ThreadID);

//        if GetPendingRequestsCount > 0 then
//          SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//        else
//          SetStatusString('Готов к подключению');
  end;
end;

procedure TMainForm.ReconnectToPartnerStart(UserName, UserDesc, UserPass, Action: String);
var
  PRItem: PPendingRequestItem;
begin
  RemovePortalConnection(UserName, Action, False);

  if PartnerIsPending(UserName, Action, True) then
  begin
    PRItem := GetPendingItem(UserName, Action);
    PRItem^.IsReconnection := True;
  end
  else
    AddPendingRequest(UserName, UserDesc, Action, True);

  DoGetDeviceState(eAccountUserName.Text,
    LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll])),
    AccountPassword,
    UserName);

  with cmAccounts do
  try
    with Data.NewFunction('Host.GetUserInfo') do
    begin
      asWideString['User'] := UserName;
      asWideString['Pass'] := UserPass;
      asString['Action'] := Action;
      Call(rGetPartnerInfoReconnect);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.rGetPartnerInfoReconnectReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
//  GatewayClient: PRtcHttpPortalClient;
//  DesktopControl: PRtcPDesktopControl;
//  FileTransfer: PRtcPFileTransfer;
//  Chat: PRtcPChat;
//  GatewayRec: PGatewayRec;
//  PRItem: PPendingRequestItem;
  username, sUID: String;
  PortalThread: TPortalThread;
//  PassForm: TfIdentification;
  PRItem: PPendingRequestItem;
begin
//  xLog('rGetPartnerInfoReturn');

  if Result.isType = rtc_Exception then
  begin
//  LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
  if Result.isType <> rtc_Record then
  begin
//    SetStatusString('Некорректный ответ от сервера');
  end
  else
  with Result.asRecord do
  begin
    if asString['Result'] = 'IS_OFFLINE' then
    begin
//      SetStatusStringDelayed('Партнер не в сети. Подключение невозможно');

      RemovePortalConnection(asWideString['user'], asString['action'], False);
      DeletePendingRequest(asWideString['user'], asString['action']);
    end
    else
    if asString['Result'] = 'OK' then
    begin
      PRItem := GetPendingItem(asWideString['User'], asString['action']);
      if PRItem = nil then
        Exit;

      username := GetUserNameByID(asWideString['user']);

      if asWideString['UserToConnect'] <> asWideString['user'] then
        ChangePendingRequestUser(asWideString['action'], asWideString['user'], asWideString['UserToConnect']);

      if not PartnerIsPending(asWideString['user'], asString['action'], asString['Address']) then
      begin
        if (asWideString['action'] <> 'desk')
          and (asInteger['LockedState'] = LCK_STATE_LOCKED) then
        begin
//          SetStatusStringDelayed('Устройство партнера заблокировано. Подключение запрещено');
          DeletePendingRequest(asWideString['UserToConnect'], asString['action']);
        end
        else
        if (asWideString['action'] = 'desk')
          and (asInteger['LockedState'] = LCK_STATE_LOCKED)
          and (not asBoolean['ServiceStarted']) then
        begin
//          SetStatusStringDelayed('Устройство партнера заблокировано. Подключение запрещено');
          DeletePendingRequest(asWideString['UserToConnect'], asString['action']);
        end
        else
        begin
//        AddPendingRequest(asWideString['user'], asString['action'], asString['Address'] + ':' +  asString['Port'], 0);
          TSendDestroyClientToGatewayThread.Create(False, asString['Address'], StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]) + '_' + asWideString['UserToConnect'] + '_' + asWideString['action'] + '_', False, hcAccounts.UseProxy, hcAccounts.UserLogin.ProxyAddr, hcAccounts.UserLogin.ProxyUserName, hcAccounts.UserLogin.ProxyPassword, False);
          PortalThread := TPortalThread.Create(False, asWideString['action'], asWideString['user'], asWideString['Pass'], asWideString['UserToConnect'], asString['Address'], asInteger['LockedState'], asBoolean['ServiceStarted'], True); //Для каждого соединения новый клиент
          PRItem^.Gateway := asString['Address'];
          PRItem^.ThreadID := PortalThread.ThreadID;
        end;
      end;

      //Добавим в историю при успешном логине
      AddHistoryRecord(asWideString['user'], username);
      //Сохраним пароль в истории при успешном логине
      AddPasswordsRecord(asWideString['user'], asWideString['Pass']);

//      ConnectToPartner(GatewayRec, asWideString['user'], username, asString['action']);
    end
    else
    if asString['Result'] = 'PASS_NOT_VALID' then
    begin
      {PRItem := GetPendingItem(asWideString['user'], asString['action']); //При реконнекте PortalThread удален
      if PRItem = nil then
        Exit;

      username := GetUserNameByID(asWideString['user']);

//      try
//      PassForm.Parent := Self;

        if PassForm.UserName <> asWideString['user'] then
          PassForm.ePassword.Text := '';

//      if StorePasswords then
//      begin
//        for i := 0 to ePartnerID.Items.Count - 1 do
//          if THistoryRec(ePartnerID.Items.Objects[i]).user = asWideString['user'] then
//          begin
//            PassForm.ePassword.Text := THistoryRec(ePartnerID.Items.Objects[i]).password;
//            Break;
//          end;
//      end;

        PassForm.UserName := asWideString['user'];
        PassForm.UserDesc := username;
        PassForm.Action := asString['action'];
        PassForm.ThreadId := PRItem^.ThreadId;
        PassForm.OnCustomFormClose := OnCustomFormClose;
        PassForm.OnCloseForm := OnClosePassForm;
        OnCustomFormOpen(@PassForm);
        PassForm.Show;}
//      finally
//        PassForm.Free;
//      end;
//      if PassForm.ModalResult = mrOk then
//        ConnectToPartnerStart(asWideString['user'], username, PassForm.ePassword.Text, asString['action'])
//      else
//      begin
//      RemovePortalConnection(asWideString['user'], asString['action'], True);
      DeletePendingRequest(asWideString['user'], asString['action']);
      DesktopsForm.CloseUIAndTab(asWideString['user'], True, 0 );
      DesktopsForm.FreeUIDataModule(asWideString['user'], 0);
//      DesktopsForm.SetReconnectInterval(asWideString['user'], 0);

//        if GetPendingRequestsCount > 0 then
//          SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//        else
//          SetStatusString('Готов к подключению');
//      end;
    end;
  end;
end;

procedure TMainForm.rGetHostLockedStateRequestAborted(Sender: TRtcConnection;
  Data, Result: TRtcValue);
begin
//  XLog('rGetHostLockedStateRequestAborted');

//  SendLockedStateToGateway();
end;

procedure TMainForm.rGetHostLockedStateReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  XLog('rGetHostLockedStateReturn');

  if Result.isType = rtc_Exception then
  begin
//  LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
  if Result.isType <> rtc_Record then
  begin
//    SetStatusString('Некорректный ответ от сервера');
  end
  else
    with Result.asRecord do
      Locked_Status(asWideString['User'], asInteger['LockedState'], asBoolean['ServiceStarted']);
end;

procedure TMainForm.rGetPartnerInfoRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  Tag := Tag;
end;

//function TMainForm.GetDeviceStatus(uname: String): Integer;
//var
//  Node, CNode: PVirtualNode;
//  DData: PDeviceData;
//begin
//  Result := MSG_STATUS_UNKNOWN;
//
//  Node := twDevices.GetFirst();
//  while Node <> nil do
//  begin
//    if Node.ChildCount > 0 then
//    begin
//      CNode := Node.FirstChild;
//      while CNode <> nil do
//      begin
//        DData := twDevices.GetNodeData(CNode);
//        if (DData^.ID = StrToInt(RemoveUserPrefix(uname))) then
//        begin
//          Result := DData^.StateIndex;
//          Exit;
//        end;
//
//        CNode := CNode.NextSibling;
//      end;
//    end;
//
//    Node := Node.NextSibling;
//  end;
//end;

function TMainForm.GetDeviceInfo(uname: String): PDeviceData;
var
  Node, CNode: PVirtualNode;
  DData: PDeviceData;
begin
  Result := nil;

  if uname = '' then
    Exit
  else
  if not IsValidDeviceID(uname) then
    Exit;

  Node := twDevices.GetFirst();
  while Node <> nil do
  begin
    if Node.ChildCount > 0 then
    begin
      CNode := Node.FirstChild;
      while CNode <> nil do
      begin
        DData := twDevices.GetNodeData(CNode);
        if (DData^.ID = GetUserFromFromUserName(uname)) then
        begin
          Result := DData;
          Exit;
        end;

        CNode := CNode.NextSibling;
      end;
    end;

    Node := Node.NextSibling;
  end;
end;

procedure TMainForm.resHostLoginReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  XLog('resHostLoginReturn');

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
    msgHostTimerTimer(nil);

//    HostPingTimer.Enabled := True;
  end;
end;

{procedure TMainForm.resHostPingReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  i: Integer;
begin
//  XLog('resHostPingReturn');

  if Result.isType = rtc_Exception then
  begin
//    HostLogOut;
//    LogOut(nil);
//    lblStatus.Caption := Result.asException;
  end
  else
//    HostPingTimer.Enabled := True;

  if Result.asRecord.asBoolean['NeedHostRelogin'] then
  begin
    xLog('resHostPingReturn: NeedHostRelogin');

    DeleteAllPendingRequests;
    CloseAllActiveUI;

//    CS_GW.Acquire;
//    try
//      for i := 0 to GatewayClientsList.Count - 1 do
//      begin
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Module.SkipRequests;
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Module.ResetLogin;
//  //      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Module.StartCalls;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//        PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//      //  PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//      end;
//    finally
//      CS_GW.Release;
//    end;

    if (DeviceId <> '') then
    begin
//      PClient.Disconnect;
//      PClient.Active := False;
      tPClientReconnect.Enabled := True;
    end;

    //    CloseAllActiveUI;
//
//    for i := 0 to GatewayClientsList.Count - 1 do
//    begin
//  //    if PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active then
//  //      Continue;
//
////      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
////      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//  //    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Stop;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//    end;

//    tPClientReconnect.Enabled := True;
//    PClient.Active := True; //Доделать
//    tPClientReconnectTimer(nil);
//    hcAccounts.DisconnectNow(True);
//    SetStatusString('Сервер недоступен');     asdsad
//    SetConnectedState(False);
//    if not isClosing then
//      tHcAccountsReconnect.Enabled := True;
  end;
end;}

procedure TMainForm.resHostTimerLoginReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  if Result.isType = rtc_Exception then
//  begin
//    lblStatus.Caption := Result.asException;
//  end;
end;

procedure TMainForm.resHostTimerReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  i: Integer;
  fname: String;
  pPC:  PPortalConnection;
begin
//  XLog('resHostTimerReturn');

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

    with Result.asRecord do
      begin
      if isType['data'] = rtc_Array then
        with asArray['data'] do
        for i := 0 to Count - 1 do
          if isType[i] = rtc_Record then
            with asRecord[i] do
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
            if not isNull['login'] then // Friend logging in
              begin
                fname := asText['login'];
//                make_notify(fname, 'login');
//              if isFriend(fname) then
                FriendList_Status(fname, MSG_STATUS_ONLINE);
              end
            else if not isNull['logout'] then // Friend logging out
              begin
                fname := asText['logout'];
//                make_notify(fname, 'logout');
//              if isFriend(fname) then
                FriendList_Status(fname, MSG_STATUS_OFFLINE);
              end
            else if not isNull['manual_logout'] then // User closed incoming connection
              begin
//                fname := asText['manual_logout'];
//                make_notify(fname, 'manual_logout');
//              if isFriend(fname) then
//                FriendList_Status(fname, MSG_STATUS_OFFLINE);
                  with asRecord['manual_logout'] do
                begin
                  DeletePendingRequest(asWideString['user'], asString['action']);

                  if asString['action'] = 'desk' then
                  begin
                    pPC := GetPortalConnection(asString['action'], asWideString['user']);
                    if pPC <> nil then
                      DesktopsForm.CloseUIAndTab(asWideString['user'], True, pPC^.ThreadID);
                  end
                  else
                    RemovePortalConnection(asWideString['user'], asString['action'], True);
                end;
              end
            else if not isNull['locked'] then // Friend locked status update
              begin
                fname := asRecord['locked'].asText['user'];
                with asRecord['locked'] do
                  Locked_Status(fname, asInteger['LockedState'], asBoolean['ServiceStarted']);
              end
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
      end;

    do_notify := True;
  end
  else
  begin
    if Sender <> nil then
    begin
      // Check for new messages
      myCheckTime := 0;
      msgHostTimerTimer(nil);
      // We don't want to set do_notify to TRUE if user interaction is in progress
      PostInteractive;
    end;

    do_notify := True;
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

procedure TMainForm.cbControlModeChange(Sender: TObject);
begin
//  {$IFNDEF RtcViewer}
//  //SaveSetup;
//  case cbControlMode.ItemIndex of
//    0:PDesktopControl.NotifyUI(RTCPDESKTOP_ControlMode_Off);
//    1:PDesktopControl.NotifyUI(RTCPDESKTOP_ControlMode_Auto);
//    2:PDesktopControl.NotifyUI(RTCPDESKTOP_ControlMode_Manual);
//    3:PDesktopControl.NotifyUI(RTCPDESKTOP_ControlMode_Full);
//    end;
//  {$ENDIF}
end;

procedure TMainForm.btnRestartServiceClick(Sender: TObject);
begin
//  ShellExecute(0, 'open', 'net', PChar('stop ' + CheckService(False)), nil, SW_SHOW);
//  Sleep(5000); // Wait 5 Seconds for the Host Service to Stop
//  SaveSetup;
//  ShellExecute(0, 'open', 'net', PChar('start ' + CheckService(False)), nil, SW_SHOW);
//  Sleep(5000); // Wait 5 Seconds for the Host Service to Start
//  Close;
end;

procedure TMainForm.btnRunClick(Sender: TObject);
begin
//  SaveSetup;
////  ShellExecute(0,'open','net',PChar('net start '+CheckService(False)),nil,SW_SHOW);
//  SetLastError(EleavateSupport.RunElevated('cmd', '/c net start ' + CheckService(False), Handle, Application.ProcessMessages));
end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
////  ShellExecute(0,'open','net',PChar('net stop '+CheckService(False)),nil,SW_SHOW);
//  SetLastError(EleavateSupport.RunElevated('cmd', '/c net stop ' + CheckService(False), Handle, Application.ProcessMessages));
end;

(* Moving the Window by clicking and dragging on the Top Panel *)

procedure TMainForm.N11DrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect;
  Selected: Boolean);
var
  LeftPos: Integer;
  TopPos: Integer;
  TextLength: Integer;
  Text: string;
begin
  Text := StringReplace((Sender as TMenuItem).Caption, '&', '', [rfReplaceAll]);
  if Selected then
    ACanvas.Brush.Color := RGB(204, 232, 255) //$00D2D2D2
  else
    ACanvas.Brush.Color := clWhite; //$00FFFFFF;
  ACanvas.FillRect(ARect);
  ACanvas.Font.Color := $00000000; //cl3DDkShadow;
  if (Sender as TMenuItem).Default then
    ACanvas.Font.Style := [fsBold];
  if Text <> '-' then
  begin
    TopPos := ARect.Top +
      (ARect.Bottom - ARect.Top - ACanvas.TextHeight('W')) div 2;
    TextLength := Length(Text);
      LeftPos := ARect.Left + 5 + 1;
    ACanvas.TextOut(LeftPos, TopPos, Text);
  end
  else
  begin
    TopPos := ARect.Top + (ARect.Bottom - ARect.Top) div 2;
    TextLength := Length(Text);
//    LeftPos := ARect.Left + 31;
    ACanvas.Rectangle(5, TopPos - 1, ARect.Width, TopPos);
  end;
end;

procedure TMainForm.miChannelsUsageClick(Sender: TObject);
var
  fChannelsUsage: TfChannelsUsage;
begin
  //XLog('ShowAboutForm');

  try
    fChannelsUsage := TfChannelsUsage.Create(nil);
    fChannelsUsage.FLoggedIn := LoggedIn;
    fChannelsUsage.FAccountUID := AccountUID;
    fChannelsUsage.FDeviceUID := DeviceUID;
    fChannelsUsage.FSendManualLogoutToControl := SendManualLogoutToControl;
    fChannelsUsage.FTimerModule := TimerModule;
    fChannelsUsage.OnCustomFormClose := OnCustomFormClose;
    OnCustomFormOpen(@fChannelsUsage);
    fChannelsUsage.GetConnections;
    fChannelsUsage.ShowModal;
  finally
    fChannelsUsage.Free;
  end;
end;

procedure TMainForm.miLogFilesClick(Sender: TObject);
var
  Dir: String;
begin
//  XLog('N6Click');

//  if DirectoryExists(ExtractFilePath(Application.ExeName) + RTC_LOG_FOLDER) then
//  begin
    Dir := {ExtractFilePath(Application.ExeName) +} RTC_LOG_FOLDER;
    ShellExecute(Handle, 'open', 'explorer', LPWSTR(Dir), nil, SW_SHOWNORMAL)
//  end
//  else
//  begin
//    Dir := ExtractFilePath(Application.ExeName) + 'Logs';
//    ShellExecute(Handle, 'open', 'explorer', LPWSTR(Dir), nil, SW_SHOWNORMAL);
//  end;
end;

procedure TMainForm.nCopyPassClick(Sender: TObject);
begin
//  XLog('nCopyPassClick');

  ePassword.CopyToClipboard;
end;

procedure TMainForm.nNewRandomPassClick(Sender: TObject);
begin
//  XLog('nNewRandomPassClick');

  GeneratePassword;
  SendPasswordsToGateway;
end;

function TMainForm.NodeByUID(const aTree:TVirtualStringTree; const anUID:String): PVirtualNode;
var
  Node : PVirtualNode;
begin
  Node := aTree.GetFirst;
  while Node <> nil do
  begin
    if TDeviceData(aTree.GetNodeData(Node)^).UID = anUID then
    begin
      Result := Node;
      Exit;
    end;
    Node := aTree.GetNext(Node);
  end;
  Result := Node; //Should Return Nil if the index is not reached.
end;

function TMainForm.NodeByID(const aTree: TVirtualStringTree; const aID: String): PVirtualNode;
var
  Node : PVirtualNode;
begin
  Node := aTree.GetFirst;
  while Node <> nil do
  begin
    if TDeviceData(aTree.GetNodeData(Node)^).ID = aID then
    begin
      Result := Node;
      Exit;
    end;
    Node := aTree.GetNext(Node);
  end;
  Result := Node;//Should Return Nil if the index is not reached.
end;

procedure TMainForm.ActivateHost;
var
  HWID : THardwareId;
begin
//  xLog('ActivateHost');

  ActivationInProcess := True;

  CS_ActivateHost.Acquire;
  try
  //  StartHostLogin;

//    SetStatus(STATUS_NO_CONNECTION);
//
//    xLog('ActivateHost IsInternetConnected 1');
//
//    if not IsInternetConnected then
//      Exit
//    else
      SetStatus(STATUS_ACTIVATING_ON_MAIN_GATE);

//    xLog('ActivateHost IsInternetConnected 2');

  //  if ProxyOption = 'Automatic' then
  //  begin
  //    SetStatusString('Определение прокси-сервера', True);
  //    SetProxyFromIE;
  //  end;
//    SetStatus(2);

//    xLog('ActivateHost SetStatus 2');

//    SetStatusString('Активация Remox', True);

  //  if cmAccounts.Data = nil then
  //    Exit;

{    try
      HWID := THardwareId.Create(False);
      if (not IsService)
        or (not IsWinServer) then
      begin
        with cmAccounts do
        try
          with Data.NewFunction('Host.Activate') do
          begin
            HWID.AddUserProfileName := True;
            HWID.GenerateHardwareId;
            asString['Hash'] := HWID.HardwareIdHex;
            HWID.AddUserProfileName := False;
            HWID.GenerateHardwareId;
            asString['Hash_Console'] := HWID.HardwareIdHex;
            Call(rActivate);
          end;
        except
          on E: Exception do
            Data.Clear;
        end;
      end
      else
      begin
        with cmAccounts do
        try
          with Data.NewFunction('Host.Activate') do
          begin
            HWID.AddUserProfileName := False;
            HWID.GenerateHardwareId;
            asString['Hash'] := HWID.HardwareIdHex;
            Call(rActivate);
          end;
        except
          on E: Exception do
            Data.Clear;
        end;
      end;
    finally
     HWID.Free;
    end;}

    try
      HWID := THardwareId.Create(False);
      with cmAccounts do
      try
        with Data.NewFunction('Host.Activate') do
        begin
          HWID.AddUserProfileName := True;
          HWID.GenerateHardwareId;
          asString['Hash'] := HWID.HardwareIdHex;
          HWID.AddUserProfileName := False;
          HWID.GenerateHardwareId;
          asString['Hash_Console'] := HWID.HardwareIdHex;
          Call(rActivate);
        end;
      except
        on E: Exception do
          Data.Clear;
      end;
    finally
     HWID.Free;
    end;

  //  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': GetSystemUserName: ' + HWID.GetSystemUserName));
  finally
    CS_ActivateHost.Release;
  end;
end;

procedure TMainForm.rActivateRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  xLog('rActivateRequestAborted');

  if not ActivationInProcess then
    Exit;

//   lblStatus.Caption := Result.asException;

//  SetStatusString('Сервер недоступен');
  if (not tHcAccountsReconnect.Enabled)
    and (not isClosing) then
    tHcAccountsReconnect.Enabled := True;
//  SetConnectedState(False);
  SetStatus(STATUS_NO_CONNECTION);

  ActivationInProcess := False;
  SetStatus(STATUS_ACTIVATING_ON_MAIN_GATE);
end;

function TMainForm.FormatID(AID: String): String;
var
  i: Integer;
begin
  Result := '';

  for i := 1 to Length(AID) do
    if (i <> 1)
      and ((i - 1) mod 3 = 0) then
      Result := Result + ' ' + AID[i]
    else
      Result := Result + AID[i];
end;

procedure TMainForm.rActivateReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  PassRec: TRtcRecord;
  CurPass, sUserName, sConsoleName: String;
  MinBuildVersion, LastBuildVersion, CurBuildVersion: Integer;
begin
//  xLog('rActivateReturn');

  if not ActivationInProcess then
    Exit;

//  if LoggedIn then  //Доделать. Зачем это?
//    Exit
//  else
  if Result.isType = rtc_Exception then
  begin
//  LogOut(nil);
////    MessageBeep(0);
//    lblStatus.Caption := Result.asException;

//    lblStatus.Caption := 'Сервер недоступен';
//    lblStatus.Update;
    if (not tHcAccountsReconnect.Enabled)
      and (not isClosing) then
      tHcAccountsReconnect.Enabled := True;
    //SetConnectedState(False);
    SetStatus(STATUS_NO_CONNECTION);
  end
  else
  if Result.isType <> rtc_Record then
  begin
//    SetStatusString('Некорректный ответ от сервера');
    if (not tHcAccountsReconnect.Enabled)
      and (not isClosing) then
      tHcAccountsReconnect.Enabled := True;
//    SetConnectedState(False);
    SetStatus(STATUS_NO_CONNECTION);
  end
  else
    with Result.asRecord do
      if asBoolean['Result'] = True then
      begin
        tHcAccountsReconnect.Enabled := False;
        sUserName := '';
        sConsoleName := '';

        ConsoleId := IntToStr(asInteger['ID_Console']);

        if IsWinServer then
        begin
          DeviceId := IntToStr(asInteger['ID']);
          DeviceUID := asString['ID_UID'];
          ConsoleId := IntToStr(asInteger['ID_Console']);
          ConsoleUID := asString['ID_Console_UID'];

          DeviceDisplayName := FormatID(DeviceId);
          eUserName.Text := FormatID(DeviceId);
          eConsoleID.Text := FormatID(ConsoleId);
        end
        else
        if IsServiceStarting(RTC_HOSTSERVICE_NAME)
          or IsServiceStarted(RTC_HOSTSERVICE_NAME) then
        begin
          DeviceId := IntToStr(asInteger['ID']);
          DeviceUID := asString['ID_UID'];
          ConsoleId := IntToStr(asInteger['ID_Console']);
          ConsoleUID := asString['ID_Console_UID'];

          DeviceDisplayName := FormatID(ConsoleId);
          eUserName.Text := DeviceDisplayName;
        end
        else
        begin
          DeviceId := IntToStr(asInteger['ID']);
          DeviceUID := asString['ID_UID'];
          ConsoleId := IntToStr(asInteger['ID_Console']);
          ConsoleUID := asString['ID_Console_UID'];

          DeviceDisplayName := FormatID(DeviceId);
          eUserName.Text := DeviceDisplayName;
        end;

        MinBuildVersion := asInteger['MinBuild'];
        LastBuildVersion := asInteger['LastBuild'];
        CurBuildVersion := FileBuildVersion(ParamStr(0));
        {if CurBuildVersion < MinBuildVersion then
        begin
          FUpdateAvailable := True;
          SetStatusStringDelayed('Текущая версия устарела. Требуется обновление');
          bGetUpdate.Caption := 'Установить обновление';
          bGetUpdate.Font.Color := clRed;
          //ActivationInProcess := False; //Не сбразываем флаг. Останавливаем повторную активацию
          SetStatus(STATUS_OLD_VERSION);
          Exit;
        end
        else
        if CurBuildVersion < LastBuildVersion then
        begin
          FUpdateAvailable := True;
          SetStatusStringDelayed('Текущая версия устарела. Требуется обновление');
          bGetUpdate.Caption := 'Установить обновление';
          bGetUpdate.Font.Color := clRed;
          //ActivationInProcess := False; //Не сбразываем флаг. Останавливаем повторную активацию
          SetStatus(STATUS_OLD_VERSION);
          Exit;
        end
        else //Версия последняя}
        begin
          FUpdateAvailable := False;
          bGetUpdate.Caption := 'Последняя версия';
          bGetUpdate.Font.Color := clBlack;
        end;

{          PClient.Disconnect;
          PClient.Active := False;

          //TSendDestroyClientToGatewayThread.Create(False, asString['Gateway'], PClient.LoginUserName + '_' + asWideString['user'] + '_' + asWideString['action'] + '_', True);
          TSendDestroyClientToGatewayThread.Create(False, asString['Gateway'], PClient.LoginUserName, True);

          PClient.LoginUserName := RealName;
          PClient.LoginUserInfo.asText['RealName'] := DeviceDisplayName;
          PClient.GateAddr := asString['Gateway'];
          PClient.GatePort := '443';
//          PClient.GParamsLoaded := True;
          PClient.Active := True;}
          if TPHostThread = nil then
            tPHostThread := TPortalHostThread.Create(False, DeviceId, asString['Gateway'], '443', hcAccounts.UserLogin.ProxyAddr, hcAccounts.UserLogin.ProxyUserName, hcAccounts.UserLogin.ProxyPassword, hcAccounts.UseProxy)
          else
            tPHostThread.Restart(asString['Gateway']);

          GeneratePassword;
      //  TaskBarRemoveIcon;
      //  TaskBarAddIcon;

//        SetStatusString('Подключение к серверу...', True);

//        SetConnectedState(True);
        SetStatus(STATUS_CONNECTING_TO_GATE);
  //      LoggedIn := True;

        if cbRememberAccount.Checked then
          btnAccountLoginClick(nil);

  //      ConnectToGateway;
//        if cbRememberAccount.Checked then
//          btnAccountLoginClick(nil);

//        SetStatusString('Готов к подключению');

//        SetStatus(4);

//        pingTimer.Enabled := True;
//        HostPingTimer.Enabled := True;

//        tPClientReconnectTimer(nil);

        //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если сервер
        if IsWinServer
          or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
            and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
        begin
          PassRec := TRtcRecord.Create;
          try
            if Trim(SessionPassword) <> '' then
              PassRec.asString['0'] := SessionPassword;
            if Trim(PermanentPassword) <> '' then
              PassRec.asString['1'] := PermanentPassword;

            with TimerModule do
            try
              with Data.NewFunction('Host.Login') do
              begin
                asWideString['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
                asRecord['Passwords'] := PassRec;
                if tPHostThread <> nil then
                  asString['Gateway'] := tPHostThread.Gateway + ':' + tPHostThread.Port
                else
                  asString['Gateway'] := ''; //asString['Gateway'] + ':' + asString['Port'];
                if ActiveConsoleSessionID = CurrentSessionID then
                  asString['ConsoleId'] := ConsoleId
                else
                  asString['ConsoleId'] := '';
                asInteger['LockedState'] := ScreenLockedState;
                asBoolean['ServiceStarted'] := IsServiceStarted(RTC_HOSTSERVICE_NAME);
                asBoolean['IsService'] := False;
                Call(resHostLogin);
              end;
            except
              on E: Exception do
                Data.Clear;
            end;
            with HostTimerModule do
            try
              with Data.NewFunction('Host.Login2') do
              begin
                asWideString['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
                asRecord['Passwords'] := PassRec;
                if tPHostThread <> nil then
                  asString['Gateway'] := tPHostThread.Gateway + ':' + tPHostThread.Port
                else
                  asString['Gateway'] := ''; //asString['Gateway'] + ':' + asString['Port'];
                if ActiveConsoleSessionID = CurrentSessionID then
                  asString['ConsoleId'] := ConsoleId
                else
                  asString['ConsoleId'] := '';
                asInteger['LockedState'] := ScreenLockedState;
                asBoolean['ServiceStarted'] := IsServiceStarted(RTC_HOSTSERVICE_NAME);
                asBoolean['IsService'] := False;
                Call(resHostTimerLogin);
              end;
            except
              on E: Exception do
                Data.Clear;
            end;
          finally
            PassRec.Free;
          end;
        end;
      end
      else
      begin
//        SetStatusString('Сервер Remox не найден');
        SetStatus(STATUS_ACTIVATING_ON_MAIN_GATE);
        //SetConnectedState(False);
      end;

  ActivationInProcess := False;
end;

procedure TMainForm.SendPasswordsToGateway();
var
  PassRec: TRtcRecord;
begin
//  XLog('SendPasswordsToGateway');

  PassRec := TRtcRecord.Create;
  try
    if Trim(SessionPassword) <> '' then
      PassRec.asString['0'] := SessionPassword;
    if Trim(PermanentPassword) <> '' then
      PassRec.asString['1'] := PermanentPassword;

    with cmAccounts do
    try
      with Data.NewFunction('Host.PasswordsUpdate') do
      begin
        Value['User'] := DeviceId; //LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
        asRecord['Passwords'] := PassRec;
        Call(resHostPassUpdate);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
  finally
    PassRec.Free;
  end;
end;

procedure TMainForm.SendLockedStateToGateway;
begin
//  XLog('SendLockedStateToGateway');

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или на сервере
//  if IsWinServer
//    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
//  begin
    if (eUserName.Text = '-')
      or (eUserName.Text = '') then
      Exit;

    with cmAccounts do
    try
      with Data.NewFunction('Host.LockedStateUpdate') do
      begin
        Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
        AsInteger['LockedState'] := ScreenLockedState;
        asBoolean['ServiceStarted'] := IsServiceStarted(RTC_HOSTSERVICE_NAME);
        Call(rHostLockedStateUpdate);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
//  end;
end;

procedure TMainForm.rbChatClick(Sender: TObject);
begin
//  rbDesktopControl.Checked := False;
//  rbFileTrans.Checked := False;
end;

procedure TMainForm.rbDesktopControlClick(Sender: TObject);
begin
//  XLog('rbDesktopControlClick');

  rbFileTrans.Checked := False;
//  rbChat.Checked := False;
end;

procedure TMainForm.rbFileTransClick(Sender: TObject);
begin
//  XLog('rbFileTransClick');

  rbDesktopControl.Checked := False;
//  rbChat.Checked := False;
end;

procedure TMainForm.rDeleteDeviceReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  XLog('rDeleteDeviceReturn');

  if Result.asString = 'OK' then
  begin
    twDevices.DeleteChildren(twDevices.FocusedNode);
    twDevices.DeleteNode(twDevices.FocusedNode);
    twDevices.Repaint;
  end;
end;

procedure TMainForm.resLoginRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  AccountLoginInProcess := False;
//  btnAccountLogin.Enabled := True;
end;

procedure TMainForm.resLoginReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  sID: String;
  GroupNode, Node: PVirtualNode;
  DData: PDeviceData;
begin
//  xLog('resLoginReturn');

  if Result.isType = rtc_Exception then
  begin
    eAccountPassword.Text := '';
    AccountPassword := '';

    AccountLogOut(nil);
  //    MessageBeep(0);
//    lblStatus.Caption := Result.asException;
  end
  else
  if Result.isType <> rtc_Record then
  begin
    eAccountPassword.Text := '';
    AccountPassword := '';

    AccountLogOut(nil);
  //    MessageBeep(0);
//    SetStatusString('Некорректный ответ от сервера');
  end
  else
  with Result.asRecord do
  begin
    if asRecord['Out'].asBoolean['Result'] then
    begin
      AccountName := asRecord['Out'].asWideString['AccountName'];
      AccountUID := asRecord['Out'].asString['AccountUID'];

      LoadSetup('ACTIVE_NODE');

      twDevices.Clear;
//      twDevices.RootNodeCount := 0;
//      i := 0;
      with asDataSet['DeviceList'] do
      begin
        First;
        while not Eof do
        begin
//        twDevices.RootNodeCount := twDevices.RootNodeCount + 1;
          //Group
          GroupNode := NodeByUID(twDevices, asString['GroupUID']);
          //GroupNode := nil;
//          for i2 := 0 to twDevices. - 1 do
//            if TDeviceData(twDevices.Items[i2].Data^).UID = asString['GroupUID'] then
//            begin
//              GroupNode := twDevices.Items[i2];
//              Break;
//            end;
          if GroupNode = nil then
          begin
  //          GroupNode.Data := Pointer(DData);
            GroupNode := twDevices.AddChild(nil); //asWideString['GroupName'],
            GroupNode.States := [vsInitialized, vsVisible, vsHasChildren];
            DData := twDevices.GetNodeData(GroupNode);
            DData^.UID := asString['GroupUID'];
            DData^.Name := asWideString['GroupName'];
            DData^.HighLight := False;
            DData^.StateIndex := MSG_STATUS_UNKNOWN;
//            GroupNode.SelectedIndex := -1;

            if DData^.UID = LastFocusedUID then
              twDevices.Selected[GroupNode] := True;

            Node := twDevices.AddChild(GroupNode);
            Node.States := [vsInitialized];
            DData := twDevices.GetNodeData(Node);
            DData^.UID := '';
            DData^.ID := '';
            DData^.HighLight := False;
            DData^.StateIndex := MSG_STATUS_OFFLINE;
          end;

          if asInteger['ID'] <> 0 then
          begin
            sID := IntToStr(asInteger['ID']);
            //Node
//            Node.Data := Pointer(DData);
            Node := twDevices.AddChild(GroupNode);
            Node.States := [vsInitialized, vsVisible];
            DData := twDevices.GetNodeData(Node);
            DData^.UID := asString['UID'];
            DData^.GroupUID := asString['GroupUID'];
            DData^.ID := asString['ID'];
            DData^.Name := asWideString['Name'];
            DData^.Password := asWideString['Password'];
            DData^.Description := asWideString['Description'];
            DData^.HighLight := False;
            if DeviceId = asString['ID'] then
              DData^.StateIndex := MSG_STATUS_ONLINE
            else
              DData^.StateIndex := asInteger['StateIndex'];
//            Node.SelectedIndex := 0;

            if DData^.UID = LastFocusedUID then
            begin
              twDevices.Selected[Node] := True;
              twDevices.Expanded[Node.Parent] := True;
            end;
          end;

          Next;
        end;
      end;
    end
    else
    begin
      eAccountPassword.Text := '';
      AccountPassword := '';
  //    MessageBeep(0);
    end;

//    pAccount.Visible := False;
//    if DevicesPanelVisible then
//      pDevices.Visible := True;
  //  eDeviceName.SetFocus;
    LoggedIn := True;
    ShowDevicesPanel;

//  myUserName:=Data.asFunction.asText['user'];

//  with Result.asRecord do
//    begin
//    FriendList_Clear;
//    IgnoreList_Clear;
//
//    if isType['friends']=rtc_Record then
//      with asRecord['friends'] do
//        for i:=0 to Count-1 do
//          FriendList_Add(FieldName[i]);
//
//    if Result.asRecord.isType['ignore']=rtc_Record then
//      with asRecord['ignore'] do
//        for i:=0 to Count-1 do
//          IgnoreList_Add(FieldName[i]);
//    end;

    pingTimer.Enabled := True;

    msgHostTimerTimer(nil);

//    HostPingTimer.Enabled := True;
  end;

  AccountLoginInProcess := False;
//  btnAccountLogin.Enabled := True;
end;

procedure TMainForm.resLogoutReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  xLog('resLogoutReturn');

  AccountLogOut(nil);
end;

//procedure TMainForm.make_notify(uname, ntype: string);
//var
//  Node: PVirtualNode;
//begin
//  Node := NodeByID(twDevices, StrToInt(RemoveUserPrefix(uname)));
//  if Node = nil then
//    Exit;
//
//  if ntype = 'login' then
//  begin
//    TDeviceData(twDevices.GetNodeData(Node)^).StateIndex := MSG_STATUS_ONLINE;
//  end
//  else if ntype = 'logout' then
//  begin
//    TDeviceData(twDevices.GetNodeData(Node)^).StateIndex := MSG_STATUS_OFFLINE;
//  end;
//  twDevices.InvalidateNode(Node);
//
////  Memo1.Lines.Add(DateTimeToStr(Now) + '-' + uname + '-' + ntype);
//end;

procedure TMainForm.msgHostTimerTimer(Sender: TObject);
var
  PassRec: TRtcRecord;
begin
//  XLog('msgHostTimerTimer');

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если сервер
  //Служба работате в другом модуле
//  if IsWinServer
//    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
//  begin
    if not HostTimerClient.IsConnected then
      Exit;

    PassRec := TRtcRecord.Create;
    try
      if Trim(SessionPassword) <> '' then
        PassRec.asString['0'] := SessionPassword;
      if Trim(PermanentPassword) <> '' then
        PassRec.asString['1'] := PermanentPassword;

      with HostTimerModule do
      try
        with Data.NewFunction('GetData') do
        begin
          Value['User'] := DeviceId; //LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
          if tPHostThread <> nil then
            Value['Gateway'] := tPHostThread.Gateway + ':' + tPHostThread.Port
          else
            Value['Gateway'] := '';
          Value['Check'] := myCheckTime;
          asRecord['Passwords'] := PassRec;
          asInteger['LockedState'] := ScreenLockedState;
          asBoolean['ServiceStarted'] := IsServiceStarted(RTC_HOSTSERVICE_NAME);
          Call(resHostTimer);
        end;
      except
        on E: Exception do
          Data.Clear;
      end;
    finally
      PassRec.Free;
    end;
//  end;
end;

procedure TMainForm.resPingReturn(Sender: TRtcConnection; Data,
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

procedure TMainForm.resTimerLoginReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  xLog('resTimerLoginReturn');

  if Result.isType = rtc_Exception then
    begin
//    if myUserName<>'' then
//      begin
      AccountLogOut(nil);
//      MessageBeep(0);
//      lblStatus.Caption := Result.asException;
//      end;
    end;
end;

function TMainForm.GetUserDescription(aUserName: String): String;
var
  Node: PVirtualNode;
  pRItem: PPendingRequestItem;
begin
  pRItem := GetPendingItem(aUserName);
  if pRItem <> nil then
  begin
    Result := pRItem^.UserDesc;
    Exit;
  end;

  if not LoggedIn then
  begin
    Result := aUserName;
    Exit;
  end;

  Node := NodeByID(twDevices, GetUserFromFromUserName(aUserName));
  if Node <> nil then
    Result := TDeviceData(twDevices.GetNodeData(Node)^).Name
  else
    Result := aUserName;
end;

function TMainForm.GetUserPassword(aUserName: String): String;
var
  Node: PVirtualNode;
begin
  if not LoggedIn then
  begin
    Result := '';
    Exit;
  end;

  Node := NodeByID(twDevices, GetUserFromFromUserName(aUserName));
  if Node <> nil then
    Result := TDeviceData(twDevices.GetNodeData(Node)^).Password
  else
    Result := '';
end;

procedure TMainForm.PFileTransExplorerNewUI(Sender: TRtcPFileTransfer; const user: String);
var
  FWin: TrdFileTransfer;
//  GatewayRec: PGatewayRec;
  pPCItem: PPortalConnection;
begin
//  xLog('PFileTransExplorerNewUI');

  FWin := TrdFileTransfer.Create(Application);
  FWin.UIVisible := True;
  FWin.OnUIOpen := OnUIOpen;
  FWin.OnUIClose := OnUIClose;
//  FWin.Parent := Self;
//  FWin.ParentWindow := GetDesktopWindow;
  if Assigned(FWin) then
  begin
    FWin.UI.UserName := user;
    FWin.UI.UserDesc := GetUserDescription(user);
    // Always set UI.Module *after* setting UI.UserName !!!
    FWin.UI.Module := Sender;
    FWin.UI.Tag := Sender.Tag; //ThreadID

    pPCItem := GetPortalConnection('file', user);
    if pPCItem <> nil then
    begin
      pPCItem^.UIHandle := FWin.Handle;
      FWin.PartnerLockedState := pPCItem^.StartLockedState;
      FWin.PartnerServiceStarted := pPCItem^.StartServiceStarted;
      FWin.SetFormState;
    end;

    (*
    // Restore Window Position
    if not LoadWindowPosition(FWin,'FileTransForm-'+user) then
      LoadWindowPosition(FWin,'FileTransForm');
    *)
//    FWin.AutoExplore := True;

//    FWin.Show;
//    FWin.WindowState := wsNormal;
//    FWin.BringToFront;

//    if FWin.WindowState = wsNormal then
//    begin
//      FWin.BringToFront;
//      BringWindowToTop(FWin.Handle);
//    end;

//    GatewayRec := GetGatewayRecByFileTransfer(Sender);
//    GatewayRec^.ID := user;
//    GatewayRec^.Action := 'file';
//    GatewayRec^.UIHandle := FWin.Handle;

//    with TRtcHttpPortalClient(Sender.Client) do
//      AddActiveUI(FWin.Handle, 'file', user, FindGatewayClient(GateAddr, GatePort));

//    Application.Minimize;
  end
  else
    raise Exception.Create('Ошибка при создании окна');

//  if GetPendingRequestsCount > 0 then
//    SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//  else
//    SetStatusString('Готов к подключению');
end;

procedure TMainForm.PFileTransExplorerNewUI_HideMode(Sender: TRtcPFileTransfer; const user: String);
var
  FWin: TrdFileTransfer;
//  GatewayRec: PGatewayRec;
  pPCItem: PPortalConnection;
begin
//  xLog('PFileTransExplorerNewUI');

  FWin := TrdFileTransfer.Create(nil);
  FWin.UIVisible := False;
  FWin.OnUIOpen := OnUIOpen;
  FWin.OnUIClose := OnUIClose;
//  FWin.Parent := Self;
//  FWin.ParentWindow := GetDesktopWindow;
  if Assigned(FWin) then
  begin
    FWin.UI.UserName := user;
    FWin.UI.UserDesc := GetUserDescription(user);
    // Always set UI.Module *after* setting UI.UserName !!!
    FWin.UI.Module := Sender;
    FWin.UI.Tag := Sender.Tag; //ThreadID

    pPCItem := GetPortalConnection('file', user);
    if pPCItem <> nil then
    begin
      pPCItem^.UIHandle := FWin.Handle;
      FWin.PartnerLockedState := pPCItem^.StartLockedState;
      FWin.PartnerServiceStarted := pPCItem^.StartServiceStarted;
      FWin.SetFormState;
    end;

    (*
    // Restore Window Position
    if not LoadWindowPosition(FWin,'FileTransForm-'+user) then
      LoadWindowPosition(FWin,'FileTransForm');
    *)

//    FWin.AutoExplore := True;

//    FWin.Show;
//    FWin.WindowState := wsNormal;
//    FWin.BringToFront;

//    if FWin.WindowState = wsNormal then
//    begin
//      FWin.BringToFront;
//      BringWindowToTop(FWin.Handle);
//    end;

//    GatewayRec := GetGatewayRecByFileTransfer(Sender);
//    GatewayRec^.ID := user;
//    GatewayRec^.Action := 'file';
//    GatewayRec^.UIHandle := FWin.Handle;

//    with TRtcHttpPortalClient(Sender.Client) do
//      AddActiveUI(FWin.Handle, 'file', user, FindGatewayClient(GateAddr, GatePort));

//    Application.Minimize;
  end
  else
    raise Exception.Create('Ошибка при создании окна');

//  if GetPendingRequestsCount > 0 then
//    SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//  else
//    SetStatusString('Готов к подключению');
end;

procedure TMainForm.PFileTransferLogUI(Sender: TRtcPFileTransfer; const user: String);
var
  FWin: TrdFileTransferLog;
//  GatewayRec: PGatewayRec;
  pPCItem: PPortalConnection;
begin
//  xLog('PFileTransferLogUI');

  FWin := TrdFileTransferLog.Create(nil);
  FWin.UIVisible := Sender.UIVisible;
  FWin.OnUIOpen := OnUIOpen;
  FWin.OnUIClose := OnUIClose;
//  FWin.Parent := Self;
//  FWin.ParentWindow := GetDesktopWindow;
  if Assigned(FWin) then
  begin
    FWin.UI.UserName := user;
    FWin.UI.UserDesc := GetUserDescription(user);
    // Always set UI.Module *after* setting UI.UserName !!!
    FWin.UI.Module := Sender;
    FWin.UI.Tag := Sender.Tag; //ThreadID

    pPCItem := GetPortalConnection('file', user);
    if pPCItem <> nil then
    begin
      pPCItem^.UIHandle := FWin.Handle;
//      FWin.PartnerLockedState := pPCItem^.StartLockedState;
//      FWin.PartnerServiceStarted := pPCItem^.StartServiceStarted;
//      FWin.SetFormState;
    end;

    (*
    // Restore Window Position
    if not LoadWindowPosition(FWin,'FileTransForm-'+user) then
      LoadWindowPosition(FWin,'FileTransForm');
    *)

//    FWin.AutoExplore := True;

//    FWin.Show;
//    FWin.WindowState := wsNormal;
//    FWin.BringToFront;

//    if FWin.WindowState = wsNormal then
//    begin
//      FWin.BringToFront;
//      BringWindowToTop(FWin.Handle);
//    end;

//    GatewayRec := GetGatewayRecByFileTransfer(Sender);
//    GatewayRec^.ID := user;
//    GatewayRec^.Action := 'file';
//    GatewayRec^.UIHandle := FWin.Handle;

//    with TRtcHttpPortalClient(Sender.Client) do
//      AddActiveUI(FWin.Handle, 'file', user, FindGatewayClient(GateAddr, GatePort));

//    Application.Minimize;
  end
  else
    raise Exception.Create('Ошибка при создании окна');

//  if GetPendingRequestsCount > 0 then
//    SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//  else
//    SetStatusString('Готов к подключению');
end;

procedure TMainForm.PChatNewUI(Sender: TRtcPChat; const user:string);
var
  CWin: TrdChatForm;
//  GatewayRec: PGatewayRec;
  pPCItem: PPortalConnection;
begin
//  xLog('PChatNewUI');

  CWin := TrdChatForm.Create(nil);
  CWin.OnUIOpen := OnUIOpen;
  CWin.OnUIClose := OnUIClose;
//  CWin.Parent := Self;
//  CWin.ParentWindow := GetDesktopWindow;
  if Assigned(CWin) then
  begin
//    {$IFNDEF RtcViewer}
//    GatewayRec := GetGatewayRecByChat(Sender);
//    CWin.PDesktopControl := GatewayRec.DesktopControl^;
//    CWin.PFileTrans := GatewayRec.FileTransfer^;
//    {$ENDIF}

    CWin.UI.UserName := user;
    CWin.UI.UserDesc := GetPendingItem(user, 'chat')^.UserDesc;
    // Always set UI.Module *after* setting UI.UserName !!!
    CWin.UI.Module := Sender;
    CWin.UI.Tag := Sender.Tag; //ThreadID

    pPCItem := GetPortalConnection('chat', user);
    if pPCItem <> nil then
    begin
      pPCItem^.UIHandle := CWin.Handle;
      CWin.PartnerLockedState := pPCItem^.StartLockedState;
      CWin.PartnerServiceStarted := pPCItem^.StartServiceStarted;
      CWin.SetFormState;
    end;

    (*
    LoadWindowPosition(CWin,'ChatForm');
    *)

//    GatewayRec := GetGatewayRecByChat(Sender);
//    GatewayRec^.ID := user;
//    GatewayRec^.Action := 'chat';
//    GatewayRec^.UIHandle := CWin.Handle;

//    with TRtcHttpPortalClient(Sender.Client) do
//      AddActiveUI(CWin.Handle, 'chat', user, FindGatewayClient(GateAddr, GatePort));

//    CWin.Show;
//    if CWin.WindowState = wsNormal then
//    begin
//      CWin.BringToFront;
//      BringWindowToTop(CWin.Handle);
//    end;

//    Application.Minimize;
  end
  else
    raise Exception.Create('Ошибка при создании окна');

//  if GetPendingRequestsCount > 0 then
//    SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//  else
//    SetStatusString('Готов к подключению');
end;

procedure TMainForm.PDesktopControlNewUI(Sender: TRtcPDesktopControl; const user: String);
//  var
//    CDesk:TrdDesktopViewer;
//  begin
//  CDesk:=TrdDesktopViewer.Create(nil);
//  if assigned(CDesk) then
//    begin
//    CDesk.PFileTrans:=PFileTrans;
//
//    // MapKeys and ControlMode should stay as they are now,
//    // because this is the Host side and Hosts do not have Control.
//    CDesk.UI.ControlMode:=rtcpNoControl;
//    CDesk.UI.MapKeys:=False;
//
//    // You can set SmoothScale and ExactCursor to your prefered values,
//    // or add options to the Form so the user can choose these values,
//    // but the default values (False, False) will give you the best performance.
//    CDesk.UI.SmoothScale:=False;
//    CDesk.UI.ExactCursor:=False;
//
//    CDesk.UI.UserName:=user;
//    // Always set UI.Module *after* setting UI.UserName !!!
//    CDesk.UI.Module:=Sender;
//
//    CDesk.Show;
//    end
//  else
//    raise Exception.Create('Error creating Window');
//
//  if CDesk.WindowState=wsNormal then
//    begin
//    CDesk.BringToFront;
//    BringWindowToTop(CDesk.Handle);
//    end;
 var
//  CDesk: TrdDesktopViewer;
//  GatewayRec: PGatewayRec;
  pPCItem: PPortalConnection;
//  pTab: TChromeTab;
begin
  //xLog('PDesktopControlNewUI');

//  pPCItem := GetPortalConnection('desk', user);
//  if pPCItem <> nil then
//    if pPCItem^.UIHandle <> 0 then
//      Exit;

//  if DesktopsForm = nil then
//  begin
//    DesktopsForm := TrdDesktopViewer.Create(Self);
//    DesktopsForm.OnUIOpen := OnUIOpen;
//    DesktopsForm.OnUIClose := OnUIClose;
//    DesktopsForm.DoStartFileTransferring := StartFileTransferring;
//    DesktopsForm.ReconnectToPartnerStart := ReconnectToPartnerStart;
//
//    //  DesktopsForm.Parent := Self;
//      //DesktopsForm.ParentWindow := GetDesktopWindow;
//  end
//  else
//  begin
////    CDesk := PrdDesktopViewer(pPCItem^.UIForm);
//
////    DesktopsForm.myUI.CloseAndClear;
////    DesktopsForm.myUI.Free;
////    DesktopsForm.FT_UI.CloseAndClear;
////    DesktopsForm.FT_UI.Free;
//  end;

//  pTab := DesktopsForm.MainChromeTabs.Tabs.Add;
//  pTab.UserName := pPCItem^.UserName;  //К которому изначально подключались (не UserToConnect, на которого перенаправило)
//  pTab.UserDesc := GetUserDescription(user, 'desk');
//  pTab.UserPass := pPCItem^.UserPass;
//  if pTab.UserDesc <> '' then
//    pTab.Caption := pTab.UserDesc
//  else
//    pTab.Caption := pTab.UserName;
////  pTab.UIDataModule.UI := TRtcPDesktopControlUI.Create(DesktopsForm);
//  pTab.UIDataModule.UI.Viewer := DesktopsForm.pImage;
//  pTab.UIDataModule.UI.MapKeys := True;
//  pTab.UIDataModule.UI.SmoothScale := True;
//  pTab.UIDataModule.UI.ExactCursor := True;
//  pTab.UIDataModule.UI.OnOpen := DesktopsForm.myUIOpen;
//  pTab.UIDataModule.UI.OnData := DesktopsForm.myUIData;
//  pTab.UIDataModule.UI.OnError := DesktopsForm.myUIError;
//  pTab.UIDataModule.UI.OnLogout := DesktopsForm.myUILogout;
//  pTab.UIDataModule.UI.OnClose := DesktopsForm.myUIClose;
//  pTab.UIDataModule.UI.ControlMode := rtcpFullControl;
//  pTab.UIDataModule.UI.UserName := pTab.UserName;
//  pTab.UIDataModule.UI.UserDesc := pTab.UserDesc;
//  // Always set UI.Module *after* setting UI.UserName !!!
//  pTab.UIDataModule.UI.Module := Sender;
////    DesktopsForm.UI.Tag := Sender.Tag; //ThreadID
////  if Assigned(PFileTrans.Client) then
////    PFileTrans.Close(PFileTrans.Client.LoginUserName);
////  pTab.UIDataModule.PFileTrans := TRtcPFileTransfer.Create(DesktopsForm);
//  pTab.UIDataModule.PFileTrans.Client := Sender.Client;
//  pTab.UIDataModule.PFileTrans.OnNewUI := PFileTransExplorerNewUI;
//  pTab.UIDataModule.PFileTrans.Open(pTab.UserName, False, Sender);
//  DesktopsForm.MainChromeTabsActiveTabChanged(nil, pTab);


//  DesktopsForm.FUserName := pPCItem^.UserName;
//  DesktopsForm.FUserDesc := GetUserDescription(user, 'desk');
//  DesktopsForm.FUserPass := pPCItem^.UserPass;

//  DesktopsForm.myUI := TRtcPDesktopControlUI.Create(CDesk);
//  DesktopsForm.myUI.Viewer := CDesk.pImage;
//  DesktopsForm.myUI.OnOpen := CDesk.myUIOpen;
//  DesktopsForm.myUI.OnData := CDesk.myUIData;
//  DesktopsForm.myUI.OnError := CDesk.myUIError;
//  DesktopsForm.myUI.OnLogout := CDesk.myUILogout;
//  DesktopsForm.myUI.OnClose := CDesk.myUIClose;
//  DesktopsForm.FT_UI := TRtcPFileTransferUI.Create(CDesk);
//  DesktopsForm.FT_UI.NotifyFileBatchSend := CDesk.FT_UINotifyFileBatchSend;
//  DesktopsForm.FT_UI.OnLogOut := CDesk.FT_UILogOut;
//  DesktopsForm.FT_UI.OnClose := CDesk.FT_UIClose;

//  if Assigned(DesktopsForm) then
//  begin
//    GatewayRec := GetGatewayRecByDesktopControl(Sender);
//    CDesk.PFileTrans := GatewayRec^.FileTransfer^;
//    CDesk.PChat := GatewayRec.Chat^;

//    DesktopsForm.UI.MapKeys := True;
//    DesktopsForm.UI.SmoothScale := True;
//    DesktopsForm.UI.ExactCursor := True;
//    DesktopsForm.UI.Tag := Sender.Tag; //ThreadID
//    DesktopsForm.UI.UserName := user;
//    DesktopsForm.UI.UserDesc := GetUserDescription(user, 'desk');
//    // Always set UI.Module *after* setting UI.UserName !!!
//    DesktopsForm.UI.Module := Sender;
//
//    //{$IFNDEF RtcViewer}
////    case cbControlMode.ItemIndex of
////      0: CDesk.UI.ControlMode:=rtcpNoControl;
////      1: CDesk.UI.ControlMode:=rtcpAutoControl;
////      2: CDesk.UI.ControlMode:=rtcpManualControl;
////      3: CDesk.UI.ControlMode:=rtcpFullControl;
////      end;
//    DesktopsForm.UI.ControlMode := rtcpFullControl;
    //{$ENDIF}

    pPCItem := GetPortalConnection('desk', user);
    if pPCItem <> nil then
    //begin
      pPCItem^.DataModule := DesktopsForm.AddNewTab(pPCItem^.ID, GetUserDescription(pPCItem^.ID), pPCItem^.UserPass, pPCItem^.ThreadID, pPCItem^.StartLockedState, pPCItem^.StartServiceStarted, Sender);
//      DesktopsForm.PartnerLockedState := pPCItem^.StartLockedState;
//      DesktopsForm.PartnerServiceStarted := pPCItem^.StartServiceStarted;
//      DesktopsForm.SetFormState;
    //end;

//    GatewayRec := GetGatewayRecByDesktopControl(Sender);
//    GatewayRec^.ID := user;
//    GatewayRec^.Action := 'desk';
//    GatewayRec^.UIHandle := CDesk.Handle;

//    with TRtcHttpPortalClient(Sender.Client) do
//      AddActiveUI(CDesk.Handle, 'desk', user, FindGatewayClient(GateAddr, GatePort));

//    DesktopsForm.Show;

//    CDesk.UI.Send_HideDesktop;

//    if CDesk.WindowState = wsNormal then
//    begin
//      CDesk.BringToFront;
//      BringWindowToTop(CDesk.Handle);
//    end;

    with cmAccounts do
    try
      with Data.NewFunction('Host.GetLockedState') do
      begin
        Value['User'] := user;
        Call(rGetHostLockedState);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;

//    Application.Minimize;
//  end
//  else
//    raise Exception.Create('Ошибка при создании окна');

//  if GetPendingRequestsCount > 0 then
//    SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//  else
//    SetStatusString('Готов к подключению');
end;

procedure TMainForm.pingTimerTimer(Sender: TObject);
begin
//  xLog('pingTimerTimer');

//  pingTimer.Enabled := False;

  if not hcAccounts.IsConnected then
    Exit;

  with cmAccounts do
  try
    with Data.NewFunction('Account.Ping') do
    begin
      Call(resPing);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;
end;

procedure TMainForm.pmIconMenuPopup(Sender: TObject);
begin
//  xLog('pmIconMenuPopup');

  // Hack to fix the "by design" behaviour of popups from notification area icons.
  // See: http://support.microsoft.com/kb/135788
//  BringToFront();
//  SetForegroundWindow(Self.Handle);
end;

// Called after a successful login (not after LoadGatewayParams)
procedure TMainForm.PClientLogIn(Sender: TAbsPortalClient);
begin
  xLog('PClientLogIn: ' + Sender.Name);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': PClientLogIn'));

//  if assigned(Options) and Options.Visible then
//    Options.Close;

  DesktopCnt := 0;
//  eConnected.Clear;
//  btnLogout.Enabled:=True;

  DragAcceptFiles(Handle, False);

//  lblStatus.Caption := 'Подключен как "' + eUserName.Text + '".';
//  lblStatus.Update;

//  if FAutoRun then
//    PostMessage(Handle, WM_AUTOMINIMIZE, 0, 0);

  if tPHostThread <> nil then
    if (Sender = tPHostThread.FGatewayClient) then
    begin
  //    SetHostGatewayClientActive(True);
      tPClientReconnect.Enabled := False;
    end;
end;

procedure TMainForm.PClientParams(Sender: TAbsPortalClient; const Data: TRtcValue);
  begin
//  xLog('PClientParams');

//  if xAdvanced.Checked then
//    begin
//    xAdvanced.Checked:=False;
//    if not assigned(Options) then
//      Options:=TrdHostSettings.Create(self);
//    if assigned(Options) then
//      begin
//      Options.PClient:=PClient;
//      Options.PDesktop:=PDesktopHost;
//      Options.PChat:=PChat;
//      Options.PFileTrans:=PFileTrans;
//      Options.Execute;
//      btnLogin.Enabled:=True;
//      end;
//    end
//  else
//    begin
//    if not PDesktopHost.GFullScreen and
//        (PDesktopHost.ScreenRect.Right = PDesktopHost.ScreenRect.Left) then
//      PDesktopHost.GFullScreen := True;
//    end;
  end;

procedure TMainForm.PClientStart(Sender: TAbsPortalClient; const Data: TRtcValue);
begin
  xLog('PClientStart: ' + Sender.Name);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': PClientStart'));

//  if Pages.ActivePage<>Page_Hosting then
//    begin
//    Page_Hosting.TabVisible:=True;
//    Pages.ActivePage.TabVisible:=False;
//    Pages.ActivePage:=Page_Hosting;
//    end;
//  SetStatusString('Готов к подключению');

  if tPHostThread <> nil then
    if (Sender = tPHostThread.FGatewayClient)
      and (GetStatus = STATUS_CONNECTING_TO_GATE) then
    begin
  //    SetHostGatewayClientActive(True);
      SetStatus(STATUS_READY);

      if cbRememberAccount.Checked then
        btnAccountLoginClick(nil);
    end;

  tPClientReconnect.Enabled := False;

//  cTitleBar.Refresh;
//  btnMinimize.Refresh;
//  btnClose.Refresh;

//  tConnect.Enabled := False;
end;

//procedure TMainForm.CloseAllActiveUIByGatewayClient(Sender: TAbsPortalClient);
//var
//  i: Integer;
//begin
//  xLog('CloseAllActiveUIByGatewayClient');
//  for i := 0 to ActiveUIList.Count - 1 do
//  begin
//    if PActiveUIRec(ActiveUIList[i])^.GatewayRec.GatewayClient^ = Sender then
//    begin
//      PostMessage(PActiveUIRec(ActiveUIList[i])^.Handle, WM_CLOSE, 0, 0);
//      RemoveActiveUIRecByHandle(PActiveUIRec(ActiveUIList[i])^.Handle);
//    end;
//  end;
//
////  if Sender = PClient then
////    DeleteAllPendingRequests;
//end;

procedure TMainForm.CloseAllActiveUI;
var
  i: Integer;
begin
//  xLog('CloseAllActiveUI');
//  CS_GW.Acquire;
//  try
//    i := PortalConnectionsList.Count - 1;
//    while i >= 0 do
//    begin
//        PostThreadMessage(PPortalConnection(PortalConnectionsList[i])^.ThreadID, WM_CLOSE, WPARAM(True), 0); //Закрываем поток с пклиентом и UIDataModule
////      PostMessage(PPortalConnection(PortalConnectionsList[i])^.DataModule.Handle, WM_CLOSE, 0, 0);
//      Dispose(PortalConnectionsList[i]);
//      PortalConnectionsList.Delete(i);
//
//      i := i - 1;
//    end;
//  finally
//    CS_GW.Release;
//  end;
  DesktopsForm.Close;

  if (OpenedModalForm <> nil)
    and OpenedModalForm^.Visible
    and (OpenedModalForm^.Name <> 'fAboutForm')
      and (OpenedModalForm^.Name <> 'rdClientSettings') then
//    and (not (OpenedModalForm is TrdClientSettings))
//      and (not (OpenedModalForm is TfAboutForm)) then
  begin
//    xLog('OpenedModalForm Close Start');
    OpenedModalForm^.Close;
    OpenedModalForm := nil;
//    xLog('OpenedModalForm Close End');
  end;

//  for i := 0 to Screen.Forms.cou - 1 do
//    if Screen.Forms[i].Visible
//      and ((Screen.Forms[I].ClassName = 'TrdClientSettings')
//        or (Screen.Forms[I].ClassName = 'TfMessageBox')
//        or (Screen.Forms[I].ClassName = 'TDeviceForm')
//        or (Screen.Forms[I].ClassName = 'TGroupForm')
//        or (Screen.Forms[I].ClassName = 'TfIdentification')) then
//      Screen.Forms[I].Close;

//  DeleteAllPendingRequests;
end;

procedure TMainForm.PClientLogOut(Sender: TAbsPortalClient);
begin
  xLog('PClientLogOut: ' + Sender.Name);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': PClientLogOut'));

//  SetStatusStringDelayed('Готов к подключению', 2000);

//  if not isClosing then
//  begin
//    CloseAllActiveUIByGatewayClient(Sender);
//    tPClientReconnect.Enabled := True;
//  end;

//  TRtcHttpPortalClient(Sender).Active := True;

  if tPHostThread <> nil then
    if (Sender = tPHostThread.FGatewayClient) then
    begin
  //    SetHostGatewayClientActive(False);
  //    TRtcHttpPortalClient(Sender).Disconnect;
  //    TRtcHttpPortalClient(Sender).Active := False;
    ////  TRtcHttpPortalClient(Sender).Active := True;
      tPClientReconnect.Enabled := True;
    end;

//  Tag := Tag;
//  if assigned(Options) and Options.Visible then
//    Options.Close;

//  if Pages.ActivePage<>Page_Setup then
//    begin
//    Page_Setup.TabVisible:=True;
//    Pages.ActivePage.TabVisible:=False;
//    Pages.ActivePage:=Page_Setup;
//    end;

//  btnLogin.Enabled:=True;
//  SetStatusString('Не в сети');

//  if SilentMode then
//    PostMessage(Handle,WM_AUTOCLOSE,0,0);
end;

procedure TMainForm.PClientFatalError(Sender: TAbsPortalClient; const Msg:string);
begin
  xLog('PClientFatalError: ' + Sender.Name + ': ' + Msg);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': PClientFatalError ' + Msg));

  TRtcHttpPortalClient(Sender).Disconnect;

//  if tPHostThread <> nil then
//    tPHostThread.Restart;

//  if Msg = 'Сервер недоступен.' then
//    TRtcHttpPortalClient(Sender).Active := False;

//  Tag := Tag;
//  if assigned(Options) and Options.Visible then
//    Options.Close;

//  if not tConnect.Enabled then
//  begin
//    lblStatus.Caption := 'Сервер недоступен';
//    lblStatus.Update;
//    tConnect.Enabled := True;
//    SetConnectedState(False);
//  end;

//  PClient.Disconnect;

//  if Pages.ActivePage<>Page_Setup then
//    begin
//    Page_Setup.TabVisible:=True;
//    Pages.ActivePage.TabVisible:=False;
//    Pages.ActivePage:=Page_Setup;
//    end;

//  btnLogin.Enabled:=True;
//  lblStatus.Caption := Msg;
//  lblStatus.Update;

//  if SilentMode then
//    PostMessage(Handle, WM_AUTOCLOSE, 0,0)
////  else
////    MessageBeep(0);

//  if not isClosing then
//    if not PClient.Active then
//      PClient.Active := True;
//  if not isClosing then
//    tPClientReconnect.Enabled := True;
end;

procedure TMainForm.PClientError(Sender: TAbsPortalClient; const Msg:string);
begin
//  xLog('PClientError: ' + Sender.Name + ': ' + Msg);
//  Memo1.Lines.Add('PClientError: ' + Sender.Name + ': ' + Msg);
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': PClientError ' + Msg));

  PClientFatalError(Sender, Msg);

//  if (Sender = PClient)
//    and (Msg = 'Не удалось подключиться к серверу.') then
//    TRtcHttpPortalClient(Sender).Active := False;

  if tPHostThread <> nil then
    if (Sender = tPHostThread.FGatewayClient)
      and (Msg = 'Не удалось подключиться к серверу.') then
      ChangePortP(Sender);

//  if Msg = S_RTCP_ERROR_CONNECT then
//    tPClientReconnect.Enabled := True;

//  if (Msg <> S_RTCP_ERROR_CONNECT)
//    and (Msg <> 'Logged out') then
//  if Msg = 'Logged out' then
//  begin
//    TRtcHttpPortalClient(Sender).Disconnect;
//    TRtcHttpPortalClient(Sender).Active := False;
//  end;
//  TRtcHttpPortalClient(Sender).GParamsLoaded := True;
  if Msg <> 'Logged out' then
    TRtcHttpPortalClient(Sender).Active := True;

//  Color := Color;
//  if assigned(Options) and Options.Visible then
//    Options.Close;

//  PClientFatalError(Sender,Msg);

//  LogOut(nil);
//  tConnect.Enabled := True;

  // The difference between "OnError" and "OnFatalError" is
  // that "OnError" will make a reconnect if "Re-Login" was checked,
  // while "OnFatalError" simply closes all connections and stops.
//  if SilentMode then
//    PostMessage(Handle,WM_AUTOCLOSE,0,0)
//  else //if xAutoConnect.Checked then
//    PClient.Active:=True;

//  if not isClosing then
//    if not PClient.Active then
//      PClient.Active := True;
//  PClient.Active := True;

//  PDesktopHost.Restart;
end;

procedure TMainForm.AddIncomeConnection(AAction, AID, AUserName, AUserDesc: String);
var
  Node: PVirtualNode;
  DData: PDeviceData;
  DForm: TDeviceForm;
begin
  CS_Incoming.Acquire;
  try
    Node := twIncomes.AddChild(nil, DData);
    Node.States := [vsInitialized, vsVisible];
    DData := twDevices.GetNodeData(Node);
    DData^.ID := AID;
    DData^.Name := AUserName;
    DData^.Description := AUserDesc;
    DData^.Action := AAction;
    DData^.HighLight := False;
    DData^.StateIndex := MSG_STATUS_ONLINE;

    twIncomes.ToggleNode(Node);
    twIncomes.Selected[Node] := True;
    twIncomes.FocusedNode := Node;
    twIncomes.SortTree(0, sdAscending);
    twIncomes.InvalidateNode(Node);
  finally
    CS_Incoming.Release;
  end;

  tsIncomes.Caption := 'Входящие подключения (' + IntToStr(GetIncomeConnectionsCount) + ')';
end;

function TMainForm.GetIncomeConnectionsCount: Integer;
var
  Node: PVirtualNode;
begin
//  XLog('GetIncomeConnectionsCount');
  Result := 0;

  CS_Incoming.Acquire;
  try
    Node := twIncomes.GetFirst;
    while Node <> nil do
    begin
      Result := Result + 1;

      Node := twIncomes.GetNext(Node);
    end;
  finally
    CS_Incoming.Release;
  end;
end;

procedure TMainForm.RemoveIncomeConnection(AUserName: String);
var
  Node: PVirtualNode;
  cnt: Integer;
begin
//  XLog('RemoveIncomeConnection');

  CS_Incoming.Acquire;
  try
    Node := twIncomes.GetFirst;
    while Node <> nil do
    begin
      if TDeviceData(twIncomes.GetNodeData(Node)^).Name = AUserName then
      begin
        twIncomes.DeleteNode(Node);
        twIncomes.Repaint;

        Break;
      end;
      Node := twIncomes.GetNext(Node);
    end;
  finally
    CS_Incoming.Release;
  end;

  cnt := GetIncomeConnectionsCount;
  tsIncomes.Caption := 'Входящие подключения (' + IntToStr(cnt) + ')';
  if cnt = 0 then
    pcDevAcc.ActivePage := tsMyDevices;
end;

function TMainForm.IsIncomeConnectionExists(AID, AAction: String): Boolean;
var
  Node: PVirtualNode;
begin
//  XLog('IsIncomeConnectionExists');
  Result := False;

  CS_Incoming.Acquire;
  try
    Node := twIncomes.GetFirst;
    while Node <> nil do
    begin
      if (TDeviceData(twIncomes.GetNodeData(Node)^).ID = AID)
        and (TDeviceData(twIncomes.GetNodeData(Node)^).Action = AAction) then
      begin
        Result := True;

        Break;
      end;
      Node := twIncomes.GetNext(Node);
    end;
  finally
    CS_Incoming.Release;
  end;
end;

procedure TMainForm.PModuleUserJoined(Sender: TRtcPModule; const user:string);
var
  FullDesc, UserName, UserDesc, Action, sAction: String;
  arr: TStringDynArray;
begin
//  xLog('PModuleUserJoined');

  if Pos('_', Sender.Client.LoginUserName) > 0 then
  begin
    if Copy(Sender.Client.LoginUserName, 1, Length(DeviceId)) = DeviceId then
      Exit;
  end
  else
  begin
    if Copy(user, 1, Length(DeviceId)) = DeviceId then
      Exit;
  end;

  if Sender is TRtcPFileTransfer then
    sAction := 'Передача файлов'
  else
  if Sender is TRtcPChat then
    sAction := 'Чат'
  else
  if Sender is TRtcPDesktopHost then
  begin
    sAction := 'Управление';
    Inc(DesktopCnt);
//    if DesktopCnt = 1 then
//      DragAcceptFiles(Handle, True);
  end
  else
    sAction := '???';

  arr := user.Split(['_'], 3);
  if Length(arr) = 3 then
  begin
    UserName := arr[0];
    Action := arr[2];
  end
  else
  begin
    UserName := '';
    Action := '';
  end;
  UserDesc := GetUserDescription(UserName);
  if UserDesc <> '' then
    FullDesc := UserDesc + ' (' + sAction + ')'
  else
    FullDesc := UserName + ' (' + sAction + ')';

  if not IsIncomeConnectionExists(UserName, Action) then
  begin
    if (not Visible)
      or (IsIconic(Application.Handle)) then
    begin
      Visible := True;
      ShowWindow(Application.Handle, SW_SHOW);
      Application.Restore;
      SetForegroundWindow(Handle);
      tFoldForm.Enabled := True;
    end;

    pcDevAcc.ActivePage := tsIncomes;

    AddIncomeConnection(Action, UserName, user, FullDesc);
  end;

//  Memo1.Lines.Add(user + ' joined');

{ You can retrieve custom user information about
  all users currently connected to this Client
  by using the RemoteUserInfo property like this: }

//  uinfo := Sender.RemoteUserInfo[user];

{ What you get is a TRtcRecord containing all the
  information stored by the Client using the
  "LoginUserInfo" property before he logged in to the Gateway.
  Private user information (like the password or configuration data)
  will NOT be sent to other users. You will get here ONLY
  data that what was assigned to the "LoginUserInfo" property. }

//  try
//    if uinfo.CheckType('RealName',rtc_Text) then
//      s:=user+' ('+uinfo.asText['RealName']+') - '+s
//    else
//      s:=user+' - '+s;
//  finally
//    { When you are finished using the data, make sure
//      to FREE the object received from "RemoteUserInfo" }
//    uinfo.Free; // Do NOT forget this, or you will create a memory leak!
//    end;
//
//  el:=
//  eConnected.Items.Add(s);
//  el.Caption:=s;
//  eConnected.Update;
  end;

procedure TMainForm.PModuleUserLeft(Sender: TRtcPModule; const user:string);
//var
//  u, s, d: String;
//  a, i: Integer;
begin
//  xLog('PModuleUserLeft');

  if Pos('_', Sender.Client.LoginUserName) > 0 then
  begin
    if Copy(Sender.Client.LoginUserName, 1, Length(DeviceId)) = DeviceId then
      Exit;
  end
  else
  begin
    if Copy(user, 1, Length(DeviceId)) = DeviceId then
      Exit;
  end;

//  if Sender is TRtcPFileTransfer then
//    s := 'Передача файлов'
//  else
//  if Sender is TRtcPChat then
//    s := 'Чат'
//  else
  if Sender is TRtcPDesktopHost then
  begin
//    s := 'Управление';
    Dec(DesktopCnt);
    if DesktopCnt = 0 then
    begin
//      DragAcceptFiles(Handle, False);
      Show_Wallpaper;
    end;
  end;
//  else
//    s := '???';
//
//  u := GetUserFromFromUserName(user);
//  d := GetUserDescription(u);
//  if d <> '' then
//    s := d + ' (' + s + ')'
//  else
//    s := u + ' (' + s + ')';

  RemoveIncomeConnection(user);

//  Memo1.Lines.Add(user + ' left');

{ You can retrieve custom user information about
  all users currently connected to this Client
  by using the RemoteUserInfo property like this: }

//  uinfo:=Sender.RemoteUserInfo[user];

{ What you get is a TRtcRecord containing all the
  information stored by the Client using the
  "LoginUserInfo" property before he logged in to the Gateway.
  Private user information (like the password or configuration data)
  will NOT be sent to other users. You will get here ONLY
  data that what was assigned to the "LoginUserInfo" property. }

//  try
//    if uinfo.CheckType('RealName',rtc_Text) then
//      s:=user+' ('+uinfo.asText['RealName']+') - '+s
//    else
//      s:=user+' - '+s;
//  finally
//    { When you are finished using the data, make sure
//      to FREE the object received from "RemoteUserInfo" }
//    uinfo.Free; // Do NOT forget this, or you will create a memory leak!
//    end;
//
{  i:=-1;
  for a := 0 to eConnected.Items.Count - 1 do
    if eConnected.Items[a]=s then //.Caption
      begin
      i:=a;
      Break;
      end;
  if i>=0 then
    begin
    eConnected.Items.Delete(i);
    eConnected.Update;
    end;}
  end;

procedure TMainForm.btnGatewayClick(Sender: TObject);
begin
//  xLog('btnGatewayClick');

  ShowSettingsForm('tsNetwork');
end;

function TMainForm.GetAutoUpdateSetting: Boolean;
var
  reg: TRegistry;
begin
//  xLog('GetAutoUpdateSetting');

  Result := True;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.Access := KEY_READ or KEY_WOW64_64KEY;
    if reg.KeyExists('SOFTWARE\Remox\') then
      if reg.OpenKey('SOFTWARE\Remox\', False) then
      begin
        if reg.ValueExists('AutomaticUpdate') then
          Result := reg.ReadBool('AutomaticUpdate');

        reg.CloseKey;
      end;
  finally
    reg.Free;
  end;
end;

procedure TMainForm.ShowSettingsForm(APage: String);
var
  i: Integer;
  s: String;
  sett: TrdClientSettings;
begin
//  xLog('ShowSettingsForm');

  sett := TrdClientSettings.Create(Self);
  try
  //    sett.Parent := Self;
  //    sett.ParentWindow := Handle;
    sett.PrevProxyOption := ProxyOption;
    sett.PrevProxyAddr := hcAccounts.UserLogin.ProxyAddr;
    sett.PrevProxyUserName := hcAccounts.UserLogin.ProxyUserName;
    sett.PrevProxyPassword := hcAccounts.UserLogin.ProxyPassword;
    if PermanentPassword <> '' then
    begin
      sett.ePassword.Text := 'password';
      sett.ePasswordConfirm.Text := 'password';
    end
    else
    begin
      sett.ePassword.Text := '';
      sett.ePasswordConfirm.Text := '';
    end;
    sett.cbStoreHistory.Checked := StoreHistory;
    sett.cbStorePasswords.Checked := StorePasswords;
    sett.cbAutomaticUpdate.Checked := GetAutoUpdateSetting;
    sett.OnCustomFormClose := OnCustomFormClose;

  //    sett.cbOnlyAdminChanges.Checked := OnlyAdminChanges;
    for i := 0 to sett.tcMain.PageCount - 1 do
      if sett.tcMain.Pages[i].Name = APage then
        sett.tcMain.ActivePage := sett.tcMain.Pages[i];

    OnCustomFormOpen(@sett);
    sett.ModalResult := 0;
    sett.Execute;
    sett.ShowModal;
    SettingsFormOpened := True;
    if sett.ModalResult = mrOk then
    begin
      ProxyOption := sett.CurProxyOption;

      if sett.ConnectionParamsChanged then
      begin
        hcAccounts.AutoConnect := False;
        hcAccounts.ReconnectOn.ConnectError := False;
        hcAccounts.ReconnectOn.ConnectLost := False;
        hcAccounts.ReconnectOn.ConnectFail := False;
        hcAccounts.DisconnectNow(True);

        TimerClient.AutoConnect := False;
        TimerClient.ReconnectOn.ConnectError := False;
        TimerClient.ReconnectOn.ConnectLost := False;
        TimerClient.ReconnectOn.ConnectFail := False;
        TimerClient.DisconnectNow(True);

        HostTimerClient.AutoConnect := False;
        HostTimerClient.ReconnectOn.ConnectError := False;
        HostTimerClient.ReconnectOn.ConnectLost := False;
        HostTimerClient.ReconnectOn.ConnectFail := False;
        HostTimerClient.DisconnectNow(True);

        SetConnectedState(False);  //Доделать. Надо менять статус
        tActivateHost.Enabled := False;
        SetStatus(STATUS_NO_CONNECTION);

    //    HTTPClient^.ServerAddr := RtcString(Trim(eAddress.Text));
    //    TimerClient.ServerAddr := RtcString(Trim(eAddress.Text));
    //    HostTimerClient.ServerAddr := RtcString(Trim(eAddress.Text));

      //  PClient.Gate_Proxy := xProxy.Checked;
      //  HTTPClient^.UseProxy := xProxy.Checked;

      //  if PClient.Gate_Proxy or PClient.Gate_WinHttp then
      //    begin

        if ProxyOption = PO_AUTOMATIC then
        begin
          if tPHostThread <> nil then
            tPHostThread.ChangeProxyParams(False, '', '', '');
//          tPHostThread.ProxyEnabled := False;
//          tPHostThread.ProxyAddr := '';
//          tPHostThread.ProxyUserName := '';
//          tPHostThread.ProxyPassword := '';

          hcAccounts.UseWinHTTP := True;
          hcAccounts.UseProxy := False;
          hcAccounts.UserLogin.ProxyAddr := '';
          hcAccounts.UserLogin.ProxyUserName := '';
          hcAccounts.UserLogin.ProxyPassword := '';

          TimerClient.UseWinHTTP := True;
          TimerClient.UseProxy := False;
          TimerClient.UserLogin.ProxyAddr := '';
          TimerClient.UserLogin.ProxyUserName := '';
          TimerClient.UserLogin.ProxyPassword := '';

          HostTimerClient.UseWinHTTP := True;
          HostTimerClient.UseProxy := False;
          HostTimerClient.UserLogin.ProxyAddr := '';
          HostTimerClient.UserLogin.ProxyUserName := '';
          HostTimerClient.UserLogin.ProxyPassword := '';
        end
        else
        if ProxyOption = PO_MANUAL then
        begin
          if tPHostThread <> nil then
            tPHostThread.ChangeProxyParams(True, sett.CurProxyAddr, sett.CurProxyUserName, sett.CurProxyPassword);
//          tPHostThread.ProxyEnabled := True;
//          tPHostThread.ProxyAddr := sett.CurProxyAddr;
//          tPHostThread.ProxyUserName := sett.CurProxyUserName;
//          tPHostThread.ProxyPassword := sett.CurProxyPassword;

          hcAccounts.UseWinHTTP := True;
          hcAccounts.UseProxy := True;
          hcAccounts.UserLogin.ProxyAddr := sett.CurProxyAddr;
          hcAccounts.UserLogin.ProxyUserName := sett.CurProxyUserName;
          hcAccounts.UserLogin.ProxyPassword := sett.CurProxyPassword;

          TimerClient.UseWinHTTP := True;
          TimerClient.UseProxy := True;
          TimerClient.UserLogin.ProxyAddr := sett.CurProxyAddr;
          TimerClient.UserLogin.ProxyUserName := sett.CurProxyUserName;
          TimerClient.UserLogin.ProxyPassword := sett.CurProxyPassword;

          HostTimerClient.UseWinHTTP := True;
          HostTimerClient.UseProxy := True;
          HostTimerClient.UserLogin.ProxyAddr := sett.CurProxyAddr;
          HostTimerClient.UserLogin.ProxyUserName := sett.CurProxyUserName;
          HostTimerClient.UserLogin.ProxyPassword := sett.CurProxyPassword;
        end
        else
        if ProxyOption = PO_DIRECT then
        begin
          if tPHostThread <> nil then
            tPHostThread.ChangeProxyParams(False, '', '', '');
//          tPHostThread.ProxyEnabled := False;
//          tPHostThread.ProxyAddr := '';
//          tPHostThread.ProxyUserName := '';
//          tPHostThread.ProxyPassword := '';

          hcAccounts.UseWinHTTP := True;
          hcAccounts.UseProxy := False;
          hcAccounts.UserLogin.ProxyAddr := '';
          hcAccounts.UserLogin.ProxyUserName := '';
          hcAccounts.UserLogin.ProxyPassword := '';

          TimerClient.UseWinHTTP := True;
          TimerClient.UseProxy := False;
          TimerClient.UserLogin.ProxyAddr := '';
          TimerClient.UserLogin.ProxyUserName := '';
          TimerClient.UserLogin.ProxyPassword := '';

          HostTimerClient.UseWinHTTP := True;
          HostTimerClient.UseProxy := False;
          HostTimerClient.UserLogin.ProxyAddr := '';
          HostTimerClient.UserLogin.ProxyUserName := '';
          HostTimerClient.UserLogin.ProxyPassword := '';
        end;

        hcAccounts.AutoConnect := True;
        hcAccounts.ReconnectOn.ConnectError := True;
        hcAccounts.ReconnectOn.ConnectLost := True;
        hcAccounts.ReconnectOn.ConnectFail := True;
        hcAccounts.Connect(True, True);

        TimerClient.AutoConnect := True;
        TimerClient.ReconnectOn.ConnectError := True;
        TimerClient.ReconnectOn.ConnectLost := True;
        TimerClient.ReconnectOn.ConnectFail := True;
        TimerClient.Connect(True, True);

        HostTimerClient.AutoConnect := True;
        HostTimerClient.ReconnectOn.ConnectError := True;
        HostTimerClient.ReconnectOn.ConnectLost := True;
        HostTimerClient.ReconnectOn.ConnectFail := True;
        HostTimerClient.Connect(True, True);

        if tPHostThread <> nil then
          tPHostThread.Restart;

        tActivateHost.Enabled := True;
      end;

      if sett.PermanentPasswordChanged then
        PermanentPassword := System.Hash.THashMD5.GetHashString(sett.ePassword.Text);

      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
      begin
        if SendSettingsToService(PermanentPassword, sett.PermanentPasswordChanged, sett.cbAutomaticUpdate.Checked) then
        begin
          if sett.PermanentPasswordChanged then
          begin
            ShowPermanentPasswordState();
            SendPasswordsToGateway;
          end;
        end
        else
        begin
          MessageBox(Handle, 'Ошибка при изменении параметров. Проверьте что служба Remox запущена', 'Remox', MB_OKCANCEL);
          SettingsFormOpened := False;
          Exit;
        end;
      end;

      StoreHistory := sett.cbStoreHistory.Checked;
      StorePasswords := sett.cbStorePasswords.Checked;

  //    OnlyAdminChanges := sett.cbOnlyAdminChanges.Checked;

      SaveSetup;

//      if sett.cbAutoRun.Checked <> sett.PrevAutoRun then
//      begin
//        TaskBarRemoveIcon;
//      end;
    end;

    SettingsFormOpened := False;
  finally
    sett.Free;
  end;
end;

function TMainForm.SendStartUpdateToService: Boolean;
var
  Request, Response: IIPCData;
  IPCClient: TIPCClient;
  I, Len: Integer;
begin
  Result := False;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Service';
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QT_START_UPDATE);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
          Result := Response.Data.ReadBoolean('Result');

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

function TMainForm.SendSettingsToService(ANewPermanentPassword: String; ASendPassword, AAutomaticUpdate: Boolean): Boolean;
var
  Request, Response: IIPCData;
  IPCClient: TIPCClient;
  I, Len: Integer;
begin
  Result := False;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Service';
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QT_SET_SETTINGS);
        if ASendPassword then
          Request.Data.WriteString('PermanentPassword', ANewPermanentPassword);
        Request.Data.WriteBoolean('AutomaticUpdate', AAutomaticUpdate);
        Request.Data.WriteInteger('ProxyOption', ProxyOption);
        Request.Data.WriteString('ProxyAddr', hcAccounts.UserLogin.ProxyAddr);
        Request.Data.WriteString('ProxyUsername', hcAccounts.UserLogin.ProxyUsername);
        Request.Data.WriteString('ProxyPassword', hcAccounts.UserLogin.ProxyPassword);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
          Result := Response.Data.ReadBoolean('Result');

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

function TMainForm.GetUpdateProgressFromService(var AUpdateStatus, AProgress: Integer): Boolean;
var
  Request, Response: IIPCData;
  IPCClient: TIPCClient;
  I, Len: Integer;
begin
  Result := False;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Service';
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QT_GET_UPDATE_PROGRESS);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
        begin
          Result := Response.Data.ReadBoolean('Result');
          AUpdateStatus := Response.Data.ReadInteger('UpdateStatus');
          AProgress := Response.Data.ReadInteger('Progress');
        end;

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

{procedure TMainForm.SettingsFormOnResult(sett: TrdClientSettings);
begin
  xLog('SettingsFormOnResult');

//  if sett.ModalResult = mrOk then
//  begin
//    if sett.CurProxyOption <> ProxyOption then
//      SetStatusString('Подключение к серверу...', True);

    ProxyOption := sett.CurProxyOption;
    if sett.ePassword.Text <> sett.PrevRegularPass then
    begin
      PermanentPassword := sett.ePassword.Text;
      ShowPermanentPasswordState();
      SendPasswordsToGateway;
    end;

    StoreHistory := sett.cbStoreHistory.Checked;
    StorePasswords := sett.cbStorePasswords.Checked;

//    OnlyAdminChanges := sett.cbOnlyAdminChanges.Checked;

    SaveSetup;

    if sett.cbAutoRun.Checked <> sett.PrevAutoRun then
    begin
      TaskBarRemoveIcon;
    end;
//  end;
end;}

//procedure TMainForm.SetAutoRunToRegistry(AValue: Boolean);
//var
//  Reg: TRegistry;
//begin
//  Reg := TRegistry.Create;
//  Reg.RootKey := HKEY_LOCAL_MACHINE;
//  Reg.LazyWrite := False;
//  if AValue then
//  begin
//    Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False);
////      else reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run',False);
//    Reg.WriteString('Remox', AppFileName + ' -SILENT');
//    Reg.CloseKey
//  end
//  else
//  begin
//     Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', False);
////         else Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run',False);
//    Reg.DeleteValue('Remox');
//  end;
//  Reg.Free
//end;

procedure TMainForm.PClientStatusPut(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);
begin
//  xLog('PClientStatusPut');

  if csDestroying in ComponentState then
    Exit;

  case status of
    rtccClosed:
    begin
//      xLog('PClientStatusPut: ' + Sender.Name + ': rtccClosed');
      sStatus1.Brush.Color := clGray;
//      if not isClosing then
//      begin
//        CloseAllActiveUIByGatewayClient(Sender);
//        tPClientReconnect.Enabled := True;
//      end;
    end;
    rtccOpen:
    begin
//      xLog('PClientStatusPut: ' + Sender.Name + ': rtccOpen');
      sStatus1.Brush.Color := clNavy;
    end;
    rtccSending:
    begin
      sStatus1.Brush.Color := clGreen;
      case ReqCnt1 of
        0: sStatus1.Pen.Color := clBlack;
        1: sStatus1.Pen.Color := clGray;
        2: sStatus1.Pen.Color := clSilver;
        3: sStatus1.Pen.Color := clWhite;
        4: sStatus1.Pen.Color := clSilver;
        5: sStatus1.Pen.Color := clGray;
      end;
      Inc(ReqCnt1);
      if ReqCnt1 > 5 then
        ReqCnt1 := 0;
    end;
    rtccReceiving:
      sStatus1.Brush.Color := clLime;
    else
    begin
      sStatus1.Brush.Color := clFuchsia;
      sStatus1.Pen.Color := clRed;
    end;
  end;
  sStatus1.Update;
end;

procedure TMainForm.PClientUserLoggedIn(Sender: TAbsPortalClient;
  const User: string);
// var
//    a:integer;
//    have:boolean;
    // el:TListItem;
    // uinfo:TRtcRecord;
//    UName:String;
begin
//  xLog('PClientUserLoggedIn: ' + Sender.Name);
//  if User = eUserName.Text then //LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
//    Exit;

//  UName:=User;
{ You can retrieve custom user information about
  all users currently connected to this Client
  by using the RemoteUserInfo property like this:

   uinfo:=Sender.RemoteUserInfo[User];

  What you get is a TRtcRecord containing all the
  information stored by the Client using the
  "LoginUserInfo" property before he logged in to the Gateway.
  Private user information (like the password or configuration data)
  will NOT be sent to other users. You will get here ONLY
  data that what was assigned to the "LoginUserInfo" property.

  try
    if uinfo.CheckType('RealName',rtc_Text) then
      UName:=UName+' ('+uinfo.asText['RealName']+')';
  finally
    uinfo.Free; // You need to FREE the object received from RemoteUserInfo!
    end;
}

//  have:=False;
//  for a := 0 to eUsers.Items.Count - 1 do
//    if eUsers.Items[a]=UName then
//      have:=True;
//  if not have then
//    begin
//    //el:=
//    eUsers.Items.Add(UName);
//    //el.Caption:=UName;
//    eUsers.Update;
//    end;
//  if eUsers.Items.Count=1 then
//    begin
//    eUsers.Enabled:=True;
//    eUsers.Color:=clWindow;
//    eUsers.ItemIndex:=0;

//    btnFileTransfer.Enabled:=True;
//    btnChat.Enabled:=True;
//    btnViewDesktop.Enabled:=True;
//    btnShowMyDesktop.Enabled:=True;
//    end;
end;

procedure TMainForm.PClientUserLoggedOut(Sender: TAbsPortalClient;
  const User: string);
// var
//    a,i:integer;
//    // uinfo:TRtcRecord;
//    UName:String;
begin
//  xLog('PClientUserLoggedOut: ' + Sender.Name);
//  UName:=User;
  {Read comments in the above (PClientUserLoggedIn) method
   for more information on using the "RemoteUserInfo" property.

  uinfo:=Sender.RemoteUserInfo[User];
  try
    if uinfo.CheckType('RealName',rtc_Text) then
      UName:=UName+' ('+uinfo.asText['RealName']+')';
  finally
    uinfo.Free;
    end;}

//  i:=-1;
//  for a := 0 to eUsers.Items.Count - 1 do
//    if eUsers.Items[a]=UName then
//      begin
//      i:=a;
//      Break;
//      end;
//  if i>=0 then
//    begin
//    if eUsers.ItemIndex=i then
//      begin
//      eUsers.ItemIndex:=-1;
////      btnFileTransfer.Enabled:=False;
////      btnChat.Enabled:=False;
////      btnViewDesktop.Enabled:=False;
////      btnShowMyDesktop.Enabled:=False;
//      end;
//
//    eUsers.Items.Delete(i);
//    eUsers.Update;
//
//    if eUsers.Items.Count=0 then
//      begin
//      eUsers.Color:=clBtnFace;
//      eUsers.Enabled:=False;
//      end;
//    end;
end;

procedure TMainForm.PClientStatusGet(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);
  begin
//  xLog('PClientStatusGet');

  if csDestroying in ComponentState then
    Exit;

  case status of
    rtccClosed:
    begin
//      xLog('PClientStatusGet: ' + Sender.Name + ': rtccClosed');
      sStatus2.Brush.Color:=clRed;
      sStatus2.Pen.Color:=clMaroon;
//      if not isClosing then
//      begin
//        CloseAllActiveUIByGatewayClient(Sender);
//        tPClientReconnect.Enabled := True;
//      end;

      if tPHostThread <> nil then
        if (Sender = tPHostThread.FGatewayClient)
          and (CurStatus = STATUS_READY) then
        begin
  //        SetHostGatewayClientActive(False);
          tPClientReconnect.Enabled := True;
        end;
    end;
    rtccOpen:
    begin
//      xLog('PClientStatusGet: ' + Sender.Name + ': rtccOpen');
      sStatus2.Brush.Color:=clNavy;

//      if Sender = PClient then
//        tPClientReconnect.Enabled := False;
    end;
    rtccSending:
    begin
      sStatus2.Brush.Color:=clGreen;
      case ReqCnt2 of
        0:sStatus2.Pen.Color:=clBlack;
        1:sStatus2.Pen.Color:=clGray;
        2:sStatus2.Pen.Color:=clSilver;
        3:sStatus2.Pen.Color:=clWhite;
        4:sStatus2.Pen.Color:=clSilver;
        5:sStatus2.Pen.Color:=clGray;
        end;
      Inc(ReqCnt2);
      if ReqCnt2>5 then
        ReqCnt2:=0;
    end;
    rtccReceiving:
      sStatus2.Brush.Color:=clLime;
    else
    begin
      sStatus2.Brush.Color:=clFuchsia;
      sStatus2.Pen.Color:=clRed;
    end;
  end;
  sStatus2.Update;
end;

function TMainForm.GetPendingItem(uname: String): PPendingRequestItem;
var
  i: Integer;
begin
//  xLog('GetPendingItem');

  Result := nil;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if (PPendingRequestItem(PendingRequests[i])^.UserName = uname) then
        begin
          Result := PPendingRequestItem(PendingRequests[i]);
          Exit;
        end;
  finally
    CS_Pending.Release;
  end;
end;

function TMainForm.GetPendingItem(uname, action: String): PPendingRequestItem;
var
  i: Integer;
begin
//  xLog('GetPendingItem');

  Result := nil;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if (PPendingRequestItem(PendingRequests[i])^.UserName = uname)
        and (PPendingRequestItem(PendingRequests[i])^.Action = action) then
        begin
          Result := PPendingRequestItem(PendingRequests[i]);
          Exit;
        end;
  finally
    CS_Pending.Release;
  end;
end;

function TMainForm.AddPendingRequest(uname, desc, action: String; fIsReconnection: Boolean): PPendingRequestItem;
var
  PRItem: PPendingRequestItem;
begin
//  xLog('AddPendingRequest');

  CS_Pending.Acquire;
  try
    New(PRItem);
    PRItem^.UserName := uname;
    PRItem^.UserDesc := desc;
    PRItem^.Action := action;
    PRItem^.IsReconnection := fIsReconnection;
//    PRItem^.Gateway := gateway;
//    ThreadID := ThreadID;
    PendingRequests.Add(PRItem);
  finally
    CS_Pending.Release;
  end;

  Result := PRItem;
end;

function TMainForm.GetCurrentPendingItemUserName: String;
var
  i: Integer;
begin
  CS_Pending.Acquire;
  try
    i := PendingRequests.Count - 1;
    while i >= 0 do
    begin
      if not PPendingRequestItem(PendingRequests[i])^.IsReconnection then
      begin
        Result := PPendingRequestItem(PendingRequests[i])^.UserDesc;
        Break
      end;

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.DeleteLastPendingItem;
var
  i: Integer;
  PRItem: PPendingRequestItem;
  mUserName, mAction: String;
begin
  CS_Pending.Acquire;
  try
    i := PendingRequests.Count - 1;
    while i >= 0 do
    begin
      PRItem := PPendingRequestItem(PendingRequests[i]);
      if not PRItem^.IsReconnection then
      begin
        mUserName := PRItem^.UserName;
        mAction := PRItem^.Action;

        RemovePortalConnection(PRItem^.UserName, PRItem^.Action, True);

//        Dispose(PPendingRequestItem(PendingRequests[i])^.UIForm);
        Dispose(PendingRequests[i]);
        PendingRequests.Delete(i);

        //Делаем после удаления пендинга
        if PassForm.Active
          and (PassForm.UserName = mUserName)
          and (PassForm.Action = mAction) then
        begin
          PassForm.ModalResult := mrCancel;
          PassForm.Close;
        end;

        Break;
      end;

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.DeletePendingRequest(uname, action: String);
var
  i: Integer;
begin
//  xLog('DeletePendingRequest');

  CS_Pending.Acquire;
  try
    i := PendingRequests.Count - 1;
    while i >= 0 do
    begin
      if (PPendingRequestItem(PendingRequests[i])^.UserName = uname)
        and (PPendingRequestItem(PendingRequests[i])^.Action = action) then
      begin
//        Dispose(PPendingRequestItem(PendingRequests[i])^.UIForm);
        Dispose(PendingRequests[i]);
        PendingRequests.Delete(i);
      end;

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;

  //Делаем после удаления пендинга
  if PassForm.Active
    and (PassForm.UserName = uname)
    and (PassForm.Action = action) then
  begin
    PassForm.ModalResult := mrCancel;
    PassForm.Close;
  end;
end;

function TMainForm.PartnerIsPending(uname, action, gateway: String): Boolean;
var
  i: Integer;
begin
//  xLog('PartnerIsPending');

  Result := False;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if (PPendingRequestItem(PendingRequests[i])^.UserName = uname)
        and (PPendingRequestItem(PendingRequests[i])^.Action = action)
        and (PPendingRequestItem(PendingRequests[i])^.Gateway = gateway) then
        begin
          Result := True;
          Exit;
        end;
  finally
    CS_Pending.Release;
  end;
end;

function TMainForm.PartnerIsPending(uname, action: String; fIsReconnection: Boolean): Boolean;
var
  i: Integer;
begin
//  xLog('PartnerIsPending');

  Result := False;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if (PPendingRequestItem(PendingRequests[i])^.UserName = uname)
        and (PPendingRequestItem(PendingRequests[i])^.Action = action)
        and (PPendingRequestItem(PendingRequests[i])^.IsReconnection = fIsReconnection) then
        begin
          Result := True;
          Exit;
        end;
  finally
    CS_Pending.Release;
  end;
end;

function TMainForm.PartnerIsPending(uname: String): Boolean;
var
  i: Integer;
begin
//  xLog('PartnerIsPending');

  Result := False;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
    if PPendingRequestItem(PendingRequests[i])^.UserName = uname then
      begin
        Result := True;
        Exit;
      end;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.ChangePendingRequestUser(action, userFrom, userTo: String);
var
  i: Integer;
begin
//  xLog('ChangePendingRequestUser');

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
    if (PPendingRequestItem(PendingRequests[i])^.action = action)
      and (PPendingRequestItem(PendingRequests[i])^.UserName = userFrom) then
      begin
        PPendingRequestItem(PendingRequests[i])^.UserName := userTo;
        Exit;
      end;
  finally
    CS_Pending.Release;
  end;
end;

{procedure TMainForm.DeletePendingRequests(uname: String);
var
  i: Integer;
begin
//  xLog('DeletePendingRequests');

  CS_Pending.Acquire;
  try
    i := PendingRequests.Count - 1;
    while i >= 0 do
    begin
      if PPendingRequestItem(PendingRequests[i])^.UserName = uname then
      begin
//        Dispose(PPendingRequestItem(PendingRequests[i])^.UIForm);
        Dispose(PendingRequests[i]);
        PendingRequests.Delete(i);
      end;

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;
end;}

procedure TMainForm.DeleteAllPendingRequests;
var
  i: Integer;
begin
//  xLog('DeleteAllPendingRequests');

  CS_Pending.Acquire;
  try
    i := PendingRequests.Count - 1;
    while i >= 0 do
    begin
//      Dispose(PPendingRequestItem(PendingRequests[i])^.UIForm);
      Dispose(PendingRequests[i]);
      PendingRequests.Delete(i);

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.OnCustomFormOpen(AForm: PForm);
begin
  OpenedModalForm := AForm;
end;

procedure TMainForm.OnCustomFormClose;
begin
  OpenedModalForm := nil;
end;

procedure TMainForm.OnUIOpen(UserName, Action: String; var IsPending, fIsReconnection: Boolean);
var
  PRItem: PPendingRequestItem;
begin
//  xLog('OnUIOpen');

  if IsClosing then
    Exit;

  PRItem := GetPendingItem(UserName, Action);
  if PRItem = nil then
    Exit;

  IsPending := True;
  fIsReconnection := PRItem^.IsReconnection;
  if IsPending then
  begin
    DeletePendingRequest(UserName, Action);

////    Visible := False;
//    Application.Minimize;
////    ShowWindow(Application.Handle, SW_HIDE);
  end;
end;

procedure TMainForm.OnUIClose(AAction, AUserName: String);
begin
  //xLog('OnUIClose');

//  if IsClosing then
//    Exit;

  DeletePendingRequest(AUserName, AAction);
  RemovePortalConnection(AUserName, AAction, True);
end;

function TMainForm.GetPendingRequestsCount: Integer;
var
  i: Integer;
begin
  //xLog('GetPendingRequestsCount');

  Result := 0;
  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if not PPendingRequestItem(PendingRequests[i])^.IsReconnection then
        Result := Result + 1;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.PDesktopHostHaveScreeenChanged(Sender: TObject);
begin
  //xLog('PDesktopHostHaveScreeenChanged');

  tCheckLockedStateTimer(nil);
end;

procedure TMainForm.PDesktopHostQueryAccess(Sender: TRtcPModule;
  const User: string; var Allow: Boolean);
begin
  Tag := Tag;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  i: Integer;
begin
  //xLog('FormShow');

//  if not SilentMode then
//  begin
//      Application.Restore;
//      Application.BringToFront;
//      BringToFront;
//      BringWindowToTop(Handle);
//    if ePartnerID.Enabled then
//      ePartnerID.SetFocus;
//  end;
end;

procedure TMainForm.WMQueryEndSession(var Msg: TWMQueryEndSession);
var
  i: Integer;
begin
  //xLog('WMQueryEndSession');

 //  AccountLogOut(Self);
//  HostLogOut;
//
//  for i := 0 to Length(GatewayClients) - 1 do
//  begin
//   if GatewayClients[i].GatewayClient.Active then
//   begin
//      GatewayClients[i].GatewayClient.Module.SkipRequests;
//      GatewayClients[i].GatewayClient.Disconnect;
//      GatewayClients[i].GatewayClient.Active := False;
//      GatewayClients[i].GatewayClient.Stop;
//   end;
//  end;

  isClosing := True;
  Msg.Result := 0;

  Close;

//  inherited;
end;

procedure TMainForm.eRealNameChange(Sender: TObject);
  begin
{ You can assign any custom user information
  to the "PClient.LoginUserInfo" property before login ... }

  //PClient.LoginUserInfo.asText['RealName']:=eRealName.Text;

{ All the information passed to the Gateway by using
  the "LoginUserInfo" property will be made available
  to all other Clients through the "RemoteUserInfo" property.
  Do NOT assign vital information here (like a 2nd password).
  Only use this property for information you want to share.

  Here are a few Examples:

  PClient.LoginUserInfo.asText['Organization']:='My Big Business';
  PClient.LoginUserInfo.asDateTime['LocalTime']:=Now;
  PClient.LoginUserInfo.asBoolean['AtWork']:=True;
 }
 end;

 {TPolygon}

{procedure TPolygon.AssignPoints(APoints: array of TPoint);
begin
  SetLength(FRangeList, 0);
  SetLength(FPoints, Length(APoints));
  Move(APoints, FPoints, Length(APoints) * SizeOf(TPoint));
  //clear cache
  SetLength(FRangeList, 0);
end;

constructor TPolygon.Create;
begin
  SetLength(FPoints, 0);
  SetLength(FRangeList, 0);
  FStartY := 0;
end;

destructor TPolygon.Destroy;
begin
  SetLength(FPoints, 0);
  SetLength(FRangeList, 0);
end;

function TPolygon.GetCount: Integer;
begin
  Result := Length(FPoints);
end;

function TPolygon.GetFillRange(Y: Integer): TRangeList;
begin
  RangeListNeeded;
  SetLength(Result, 0);
  if (Y >= FStartY) and (Y < Length(FPoints) + FStartY) then
    Result := FRangeList[Y];
end;

function TPolygon.GetPoint(Index: Integer): TPoint;
begin
  Result := FPoints[Index];
end;

procedure TPolygon.Offset(dx, dy: Integer);
var
  i, j: Integer;
begin
  RangeListNeeded;
  FStartY := FStartY + dy;
  for i := 0 to Length(FRangeList) - 1 do
    for j := 0 to Length(FRangeList[i]) - 1 do
      Inc(FRangeList[i][j].X, dx);
end;

procedure TPolygon.RangeListNeeded;
var
  R: TRect;
  Y, i: Integer;
begin
  if Length(FPoints) <> Length(FRangeList) and Length(FPoints) then
  begin
    SetLength(FRangeList, Length(FPoints));
    R := Polygon_GetBounds(FPoints);
    i := 0;
    for Y := R.Top to R.Bottom do
    begin
      Polygon_GetFillRange(FPoints, Y, FRangeList[i]);
      Inc(i);
    end;
  end;
end;

procedure TPolygon.SetCount(AValue: Integer);
begin
  SetLength(FPoints, AValue);
  //Clear cache on point list change
  SetLength(FRangeList, 0);
end;

procedure TPolygon.SetPoint(Index: Integer; APoint: TPoint);
begin
  FPoints[Index] := APoint;
  //Clear cache if a point changes
  SetLength(FRangeList, 0);
end;}

function TMainForm.IsValidDeviceID(const uname: String): Boolean;
var
  a: Integer;
begin
  Result := True;
  for a := 1 to length(uname) do
    case uname[a] of
      '0'..'9': Result := True;
    else
    begin
      Result := False;
      Break;
    end;
  end;
end;

procedure TMainForm.cbCloseClick(Sender: TObject);
begin
  //xLog('cbCloseClick');

  Close;
end;

procedure TMainForm.cbMinClick(Sender: TObject);
begin
  //xLog('cbMinClick');

  Application.Minimize;
end;

{function BlockInputProc_Keyboard(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
//  ei : Integer;
  KeyboardStruct: PKBDLLHOOKSTRUCT;
begin
  if CODE <> HC_ACTION then
  begin
    Result:= CallNextHookEx(BlockInputHook_Keyboard, CODE, wParam, LParam);
    Exit;
  end;

  KeyboardStruct := Pointer(lParam);

  if KeyboardStruct^.dwExtraInfo <> VCS_MAGIC_NUMBER then
    Result := 1
  else
    Result := CallNextHookEx(BlockInputHook_Keyboard, CODE, wParam, LParam);
end;

function BlockInputProc_Mouse(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
//  ei : Integer;
  MouseStruct: PMSLLHOOKSTRUCT;
begin
  if CODE <> HC_ACTION then
  begin
    Result:= CallNextHookEx(BlockInputHook_Mouse, CODE, wParam, LParam);
    Exit;
  end;

  MouseStruct := Pointer(lParam);

  if MouseStruct^.dwExtraInfo <> VCS_MAGIC_NUMBER then
    Result := 1
  else
    Result := CallNextHookEx(BlockInputHook_Mouse, CODE, wParam, LParam);
end;

function TMainForm.Block_UserInput_Hook(fBlockInput: Boolean): Boolean;
var
  err: LongInt;
begin
  if fBlockInput then
  begin
    try
      BlockInputHook_Keyboard := SetWindowsHookEx(WH_KEYBOARD_LL, @BlockInputProc_Keyboard, hInstance, 0);
    finally
    end;
    err := GetLastError;
    if err <> 0 then
      xLog(Format('Block_UserInput_Set_Keyboard. Error: %s', [SysErrorMessage(err)]));
    Result := (BlockInputHook_Keyboard <> 0);

    try
      BlockInputHook_Mouse := SetWindowsHookEx(WH_MOUSE_LL, @BlockInputProc_Mouse, hInstance, 0);
    finally
    end;
    err := GetLastError;
    if err <> 0 then
      xLog(Format('Block_UserInput_Set_Mouse. Error: %s', [SysErrorMessage(err)]));
    Result := (BlockInputHook_Mouse <> 0);

//    try
//      SASLibEx_DisableCAD(DWORD(-1));
//    finally
//    end;
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Disable CAD. Error: %s', [SysErrorMessage(err)]));
  end
  else
  begin
    try
      Result := UnhookWindowsHookEx(BlockInputHook_Keyboard);
    finally
    end;
    err := GetLastError;
    if err <> 0 then
      xLog(Format('Block_UserInput_Unset_Keyboard. Error: %s', [SysErrorMessage(err)]));

    try
      Result := UnhookWindowsHookEx(BlockInputHook_Mouse);
    finally
    end;
    err := GetLastError;
    if err <> 0 then
      xLog(Format('Block_UserInput_Unset_Mouse. Error: %s', [SysErrorMessage(err)]));

//    try
//      SASLibEx_EnableCAD(DWORD(-1));
//    finally
//    end;
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Enable CAD. Error: %s', [SysErrorMessage(err)]));
  end;
end;

procedure TMainForm.WMBlockInput_Message(var Message: TMessage);
begin
  Block_UserInput_Hook(Message.WParam = 0);

  Message.Result := 0;

//  inherited;
end;}

procedure TMainForm.WMDragFullWindows_Message(var Message: TMessage);
begin
//  xLog('WMDragFullWindows_Message');

  if Message.WParam = 0 then
    EnableDragFullWindows
  else
    RestoreDragFullWindows;

  Message.Result := 0;

//  inherited;
end;

//procedure TMainForm.Broadcast_Logoff(var Message: TMessage);
//begin
////  xLog('Broadcast_Logoff');
//
//  HostLogOut;
//
//  Message.Result := 0;
//
////  inherited;
//end;

procedure DisablePowerChanges;
begin
//  xLog('DisablePowerChanges');

  if not PowerStateSaved then
  begin
    SystemParametersInfo(SPI_GETLOWPOWERTIMEOUT, 0, @LowPowerState, 0);
    SystemParametersInfo(SPI_GETPOWEROFFTIMEOUT, 0, @PowerOffState, 0);
    SystemParametersInfo(SPI_GETSCREENSAVETIMEOUT, 0, @ScreenSaverState, 0);
    PowerStateSaved := True;
  end;

  if LowPowerState <> 0 then
    SystemParametersInfo(SPI_SETLOWPOWERTIMEOUT, 0, nil, 0);
  if PowerOffState <> 0 then
    SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, 0, nil, 0);
  if ScreenSaverState <> 0 then
    SystemParametersInfo(SPI_SETSCREENSAVETIMEOUT, 0, nil, 0);
end;

procedure RestorePowerChanges;
begin
//  xLog('RestorePowerChanges');

  if PowerStateSaved then
  begin
    if LowPowerState <> 0 then
      SystemParametersInfo(SPI_SETLOWPOWERTIMEOUT, LowPowerState, nil, 0);
    if PowerOffState <> 0 then
      SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, PowerOffState, nil, 0);
    if ScreenSaverState <> 0 then
      SystemParametersInfo(SPI_SETSCREENSAVETIMEOUT, ScreenSaverState, nil, 0);
  end;
end;

procedure TMainForm.EnableDragFullWindows;
var
  CurrentDragFullWindows, res: Boolean;
begin
//  xLog('EnableDragFullWindows');

  if not ChangedDragFullWindows then
  begin
    res := SystemParametersInfo(SPI_GETDRAGFULLWINDOWS, 0, @CurrentDragFullWindows, 0);
    OriginalDragFullWindows := CurrentDragFullWindows;
  end;
  ChangedDragFullWindows := True;

  if not CurrentDragFullWindows then
    res := SystemParametersInfo(SPI_SETDRAGFULLWINDOWS, 1, nil, SPIF_UPDATEINIFILE);
end;

procedure TMainForm.RestoreDragFullWindows;
var
  res: Boolean;
begin
//  xLog('RestoreDragFullWindows');

  if not ChangedDragFullWindows then
    Exit;
  if OriginalDragFullWindows then
    res := SystemParametersInfo(SPI_SETDRAGFULLWINDOWS, 1, nil, SPIF_UPDATEINIFILE)
  else
    res := SystemParametersInfo(SPI_SETDRAGFULLWINDOWS, 0, nil, SPIF_UPDATEINIFILE);
  ChangedDragFullWindows := False;
end;


initialization
  CS_GW := TCriticalSection.Create;
  CS_Status := TCriticalSection.Create;
  CS_Pending := TCriticalSection.Create;
  CS_ActivateHost := TCriticalSection.Create;
  CS_HostGateway := TCriticalSection.Create;
  CS_Incoming := TCriticalSection.Create;
  Randomize;

finalization
  RestorePowerChanges;
  CS_Pending.Free;
  CS_Status := TCriticalSection.Create;
  CS_GW.Free;
  CS_ActivateHost.Free;
  CS_HostGateway.Free;
  CS_Incoming.Free;

end.
