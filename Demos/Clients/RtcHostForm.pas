 { Copyright (c) RealThinClient components
  - http://www.realthinclient.com }

unit RtcHostForm;

interface

{$INCLUDE rtcDefs.inc}

{$DEFINE ExtendLog}
{$DEFINE RtcViewer}

uses
  Windows, Messages, SysUtils, CommonData, System.Types, uProcess, ServiceMgr,
  Classes, Graphics, Controls, Forms, DateUtils, CommonUtils, WtsApi, uSysAccount,
  Dialogs, StdCtrls, ExtCtrls, ShellApi, BlackLayered, rdFileTransLog,
  ComCtrls, Registry, Math, RtcIdentification, SyncObjs,
  rtcSystem, rtcInfo, uMessageBox, rtcScrUtils, IOUtils,

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

  rtcpDesktopConst,
  rtcpDesktopHost, rtcpChat, rtcpFileTrans,
  rtcPortalHttpCli, rtcPortalMod, rtcPortalCli, Buttons,
  Vcl.Imaging.pngimage, Vcl.Menus, System.ImageList, Vcl.ImgList,
  rtcConn, rtcDataCli, rtcHttpCli, rtcCliModule, rtcFunction, uHardware,
  RtcRegistrationForm, RtcGroupForm, RtcDeviceForm, VirtualTrees, uVircessTypes,
  Vcl.ToolWin,
  ColorSpeedButton, AboutForm, Vcl.AppEvnts, AlignedEdit, Vcl.Imaging.jpeg, uPowerWatcher,
  Idglobal, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdTCPServer;

type
  TPortalThread = class(TThread)
  private
    FUserName: String;
    FAction: String;
    FUID: String;
    FGateway: String;
    FGatewayClient: TRtcHttpPortalClient;
    FDesktopControl: TRtcPDesktopControl;
    FFileTransfer: TRtcPFileTransfer;
    FChat: TRtcPChat;
    FNeedStopThread: Boolean;
    { Private declarations }
    function GetUniqueString: String;
  protected
    constructor Create(CreateSuspended: Boolean; AUserName, AAction, AGateway: String); overload;
    destructor Destroy; override;
    procedure Execute; override;
    procedure ProcessMessage(MSG: TMSG);
  end;

  TSendDestroyClientToGatewayThread = class(TThread)
  private
    FGateway: String;
    FClientName: String;
    FAllConnectionsById: Boolean;
    FNeedStopThread: Boolean;
    rtcClient: TRtcHttpClient;
    rtcModule: TRtcClientModule;
    rtcRes: TRtcResult;
    FResultGot: Boolean;
    { Private declarations }
  protected
    constructor Create(CreateSuspended: Boolean; AGateway, AClientName: String; AAllConnectionsById: Boolean); overload;
    destructor Destroy; override;
    procedure Execute; override;
    procedure ProcessMessage(MSG: TMSG);
    procedure rtcResReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure rtcResRequestAborted(Sender: TRtcConnection; Data, Result: TRtcValue);
  end;

  TStatusUpdateProc = procedure of Object;

  TStatusUpdateThread = class(TThread)
  private
    FStatusUpdateProc: TStatusUpdateProc;
  protected
    constructor Create(CreateSuspended: Boolean;
      StatusUpdateProc: TStatusUpdateProc); overload;
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
    PClient: TRtcHttpPortalClient;
    PFileTrans: TRtcPFileTransfer;
    PChat: TRtcPChat;
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
    PDesktopHost: TRtcPDesktopHost;
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
    Label8: TLabel;
    Label10: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label21: TLabel;
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
    pDevAcc: TPanel;
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
    pBtnDevices: TPanel;
    bDevices: TColorSpeedButton;
    iRegPassState: TImage;
    Label22: TLabel;
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
    HostPingTimer: TTimer;
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
    btnViewDesktop: TColorSpeedButton;
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
    mmiActiveConnections: TMenuItem;
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
    N6: TMenuItem;
    N11: TMenuItem;
    tActivateHost: TTimer;
    ApplicationEvents: TApplicationEvents;
    tCleanConnections: TTimer;
    tGetDirectorySize: TTimer;
    tFileSend: TTimer;
    ser_: TIdTCPServer;
    cle_: TIdTCPClient;
    rDestroyClient: TRtcResult;
    Button4: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMinimizeClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    { Private-Deklarationen }
//    procedure WMLogEvent(var Message: TMessage); message WM_LOGEVENT;
    procedure WMTaskbarEvent(var Message: TMessage); message WM_TASKBAREVENT;
    procedure WMWTSSESSIONCHANGE(var Message: TMessage); message WM_WTSSESSION_CHANGE;
//    procedure WMActivate(var Message: TMessage); message WM_ACTIVATE;
//    procedure WMBlockInput_Message(var Message: TMessage); message WM_BLOCK_INPUT_MESSAGE;
    procedure WMDragFullWindows_Message(var Message: TMessage); message WM_DRAG_FULL_WINDOWS_MESSAGE;
    // declare our DROPFILES message handler
    procedure AcceptFiles( var msg : TMessage ); message WM_DROPFILES;
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
    procedure PFileTransferLogUI(Sender: TRtcPFileTransfer; const user: String);
    procedure PChatNewUI(Sender: TRtcPChat; const user:string);

    procedure PModuleUserJoined(Sender: TRtcPModule; const user:string);
    procedure PModuleUserLeft(Sender: TRtcPModule; const user:string);

    procedure PClientStatusPut(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);
    procedure PClientStatusGet(Sender: TAbsPortalClient; Status: TRtcPHttpConnStatus);

    procedure btnGatewayClick(Sender: TObject);
    procedure eUserNameChange(Sender: TObject);
    procedure ePasswordChange(Sender: TObject);
    procedure PDesktopControlNewUI(Sender: TRtcPDesktopControl;
      const user: String);
    procedure FormShow(Sender: TObject);
    procedure eRealNameChange(Sender: TObject);
    procedure btnRestartServiceClick(Sender: TObject);
    procedure cPriority_ControlChange(Sender: TObject);
    procedure btnViewDesktopClick(Sender: TObject);
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
    procedure lDevicesClick(Sender: TObject);
//    procedure twDevicesCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
//      State: TCustomDrawState; var DefaultDraw: Boolean);
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
    procedure Label22Click(Sender: TObject);
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
    procedure resHostPingReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure HostPingTimerTimer(Sender: TObject);
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
    procedure btnViewDesktopMouseLeave(Sender: TObject);
    procedure btnViewDesktopMouseEnter(Sender: TObject);
    procedure aAboutExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tCheckLockedStateTimer(Sender: TObject);
    procedure rGetHostLockedStateReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure tConnLimitTimer(Sender: TObject);
    procedure tStatusTimer(Sender: TObject);
    procedure rGetPartnerInfoRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure Timer1Timer(Sender: TObject);
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
    procedure N6Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure tActivateHostTimer(Sender: TObject);
    procedure ApplicationEventsRestore(Sender: TObject);
    procedure tCleanConnectionsTimer(Sender: TObject);
    procedure ePartnerIDDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure TimerClientConnectError(Sender: TRtcConnection; E: Exception);
    procedure Button3Click(Sender: TObject);
    procedure resLoginRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure tGetDirectorySizeTimer(Sender: TObject);
    procedure tFileSendTimer(Sender: TObject);
    procedure ser_Execute(AContext: TIdContext);
    procedure Button4Click(Sender: TObject);

  protected

//    FAutoRun: Boolean;
    DesktopCnt: Integer;

//    Options: TrdHostSettings;
//    PassForm: TfIdentification;
//    GForm: TGroupForm;
//    DForm: TDeviceForm;
//    fReg: TRegistrationForm;
    FScreenLockedState: Integer;
    DelayedStatus: String;
    FStatusUpdateThread: TStatusUpdateThread;

//    GatewayClientsList: TList;

    PendingRequests: TList;
//    ActiveUIList: TList;
    PortalConnectionsList: TList;
    hwndNextViewer: THandle;

    function ConnectedToAllGateways: Boolean;
    function GetUniqueString: String;
    function GetUserDescription(aUserName: String): String;
    function GetUserPassword(aUserName: String): String;
    function UIIsPending(username: String): Boolean;
    function AddPendingRequest(uname, action: String): PPendingRequestItem;
    procedure DeletePendingRequest(uname, action: String);
    function GetPendingItemByUserName(uname, action: String): PPendingRequestItem;
    function PartnerIsPending(uname, action, gateway: String): Boolean; overload;
    function PartnerIsPending(uname, action: String): Boolean; overload;
    function PartnerIsPending(uname: String): Boolean; overload;
    procedure DeletePendingRequestByItem(Item: PPendingRequestItem);
    procedure DeletePendingRequests(uname: String);
    procedure DeleteAllPendingRequests;
    procedure DeleteLastPendingItem;
    function GetCurrentPendingItemUserName: String;
    procedure UpdatePendingStatus;
    function GetPendingRequestsCount: Integer;

    function CheckService(bServiceFilename: Boolean = True {False = Service Name} ): String;
//    function AddGatewayClient(GatewayClient: PRtcHttpPortalClient; DesktopControl: PRtcPDesktopControl; FileTransfer: PRtcPFileTransfer; Chat: PRtcPChat): PGatewayRec;
//    function GetGatewayRecByFileTransfer(FileTransfer: TRtcPFileTransfer): PGatewayRec;
//    function FindGatewayClient(Address: String; Port: String): PGatewayRec;
//    function GetGatewayRecByDesktopControl(DesktopControl: TRtcPDesktopControl): PGatewayRec;
//    function GetGatewayRecByChat(Chat: TRtcPChat): PGatewayRec;
//    procedure FreeGatewayRec(AGatewayRec: PGatewayRec);
//
    procedure AddPortalConnection(AThreadID: Cardinal; AHandle: THandle; AAction: String; AID: String);
    function GetPortalConnection(AAction: String; AID: String): PPortalConnection;
//    procedure SetActiveUIRecStoppedByPClient(AClient: TAbsPortalClient);
    //procedure RemovePortalConnectionByUIHandle(AUIHandle: THandle);
    procedure RemovePortalConnectionByThreadId(AThreadId: Cardinal; ACloseFUI: Boolean);
    procedure RemovePortalConnectionByUser(ID: String);
//    function GetActiveUICountByGatewayRec(AGatewayRec: PGatewayRec): Integer;

    procedure StartFileTransferring(AUser, AUserName, APassword: String; ANeedGetPass: Boolean = False);
    function CheckAccountFields: Boolean;
//    procedure CloseThisApp;
//    function IsScreenSaverRunning: Boolean;
    procedure SetScreenLockedState(AValue: Integer);
//    procedure CheckSAS(value : Boolean; name : String);

    procedure OnUIOpen(UserName, Action: String; var IsPending: Boolean);
    procedure OnUIClose(AThreadId: Cardinal);

    procedure OnCustomFormOpen(AForm: TForm);
    procedure OnCustomFormClose;

    procedure WMChangeCbChain(var Message: TWMChangeCBChain); message WM_CHANGECBCHAIN;
    procedure WMDrawClipboard(var Message: TMessage); message WM_DRAWCLIPBOARD;
    function cf_(Sender: TObject): TStringDynArray;
  public
    { Public declarations }
//    SilentMode: Boolean;
    LoggedIn: Boolean;

    ReqCnt1, ReqCnt2: Integer;
    FCurStatus: Integer;
    TaskBarIcon: Boolean;
    DevicesPanelVisible: Boolean;

    AccountName, AccountUID: String;
    HighLightedNode: PVirtualNode;

    ProxyOption: String;
    RegularPassword: String;
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

    OpenedModalForm: TForm;

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

    procedure DrawButton(Canvas:TCanvas; ARect: TRect; Node: PVirtualNode; AColor: TColor);
    procedure DrawImage(Canvas:TCanvas; NodeRect: TRect; ImageIndex: Integer);
    function NodeByUID(const aTree:TVirtualStringTree; const anUID:String): PVirtualNode;
    function NodeByID(const aTree: TVirtualStringTree; const aID: Integer): PVirtualNode;

//    procedure ConnectToPartner(GatewayRec: PGatewayRec; user, username, action: String);
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
//    procedure SettingsFormOnResult(sett: TrdClientSettings);
//    procedure SetAutoRunToRegistry(AValue: Boolean);
    procedure ShowRegularPasswordState();
    procedure FriendList_Status(uname: String; status: Integer);
    function GetUserNameByID(uname: String): String;
    procedure Locked_Status(uname: String; status: Integer);
    procedure SendPasswordsToGateway();
    procedure SendLockedStateToGateway;
    function IsValidDeviceID(const uname: String): Boolean;
    procedure ConnectToPartnerStart(user, username, pass, action: String);
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
    procedure DoExit;
//    procedure CloseAllActiveUIByGatewayClient(Sender: TAbsPortalClient);
    procedure CloseAllActiveUI;

    procedure ChangePort(AClient: TRtcHttpClient);
    procedure ChangePortP(AClient: TRtcHttpPortalClient);

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
    function ForceForegroundWindow(hwnd: THandle): Boolean;
  //  function ExecAndWait(const FileName, Params: ShortString; const WinState: Word): boolean;
  end;

//type
//  TBlankDllHookProc = procedure (switch: Boolean); stdcall;

  procedure DisablePowerChanges;
  procedure RestorePowerChanges;

const
  VCS_MAGIC_NUMBER = 777;
  MAX_CONNECTIONS_PENDING_IN_MIMUTE = 20;

  STATUS_NO_CONNECTION = 0;
  STATUS_ACTIVATING_ON_MAIN_GATE = 1;
  STATUS_CONNECTING_TO_GATE = 2;
  STATUS_READY = 3;

var
  MainForm: TMainForm;
  BlockInputHook_Keyboard, BlockInputHook_Mouse, BlockZOrderHook: HHOOK;
  CurConnectionsPendingMinuteCount: Cardinal;
  DateAllowConnectionPending: TDateTime;
  PowerStateSaved, ActivationInProcess: Boolean;
  LowPowerState, PowerOffState, ScreenSaverState: Integer;
  UseConnectionsLimit: Boolean = False;
  ChangedDragFullWindows: Boolean = False;
  OriginalDragFullWindows: LongBool = True;
//  ConnectedToAllGateways: Boolean;
  RealName, DisplayName: String;
//  FInputThread: TInputThread;
  CS_GW, CS_Status, CS_Pending, CS_ActivateHost: TCriticalSection; //CS_SetConnectedState
  T_, host_ip: String;
  bf_, bf: TStringDynArray;

implementation

{$R *.dfm}


constructor TSendDestroyClientToGatewayThread.Create(CreateSuspended: Boolean; AGateway, AClientName: String; AAllConnectionsById: Boolean);
begin
  inherited Create(CreateSuspended);

  FreeOnTerminate := True;

  FGateway := AGateway;
  FClientName := AClientName;
  FAllConnectionsById := AAllConnectionsById;

  FNeedStopThread := False;
  FResultGot := False;

  try
    rtcClient := TRtcHttpClient.Create(nil);
    rtcClient.AutoConnect := True;
    rtcClient.MultiThreaded := False;
    if Pos(':', AGateway) > 0 then
      rtcClient.ServerAddr := Copy(AGateway, 1, Pos(':', AGateway) - 1)
    else
      rtcClient.ServerAddr := AGateway;
    rtcClient.ServerPort := '9000';
    rtcClient.Blocking := True;
    rtcClient.UseWinHttp := True;
    rtcClient.ReconnectOn.ConnectError := True;
    rtcClient.ReconnectOn.ConnectFail := True;
    rtcClient.ReconnectOn.ConnectLost := True;
    rtcClient.UseProxy := MainForm.hcAccounts.UseProxy;
    rtcClient.UserLogin.ProxyAddr := MainForm.hcAccounts.UserLogin.ProxyAddr;
    rtcClient.UserLogin.ProxyUserName := MainForm.hcAccounts.UserLogin.ProxyUserName;
    rtcClient.UserLogin.ProxyPassword := MainForm.hcAccounts.UserLogin.ProxyPassword;
    rtcClient.Connect();

    rtcModule := TRtcClientModule.Create(nil);
    rtcModule.Client := rtcClient;
    rtcModule.AutoRepost := 2;
    rtcModule.AutoSyncEvents := True;
    rtcModule.ModuleFileName := '/portalgategroup';
    rtcModule.SecureKey := '2240897';
    rtcModule.ForceEncryption := True;
    rtcModule.EncryptionKey := 16;
    rtcModule.Compression := cMax;

    rtcRes := TRtcResult.Create(nil);
    rtcRes.OnReturn := rtcResReturn;
    rtcRes.RequestAborted := rtcResRequestAborted;

    with rtcModule do
    try
      with Data.NewFunction('Clients.Destroy') do
      begin
        asString['UserName'] := AClientName;
        asBoolean['AllConnectionsById'] := AAllConnectionsById;
        Call(rtcRes);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
  finally
  end;
end;

destructor TSendDestroyClientToGatewayThread.Destroy;
begin
  try
    rtcClient.Disconnect;
  finally
  end;
  try
    rtcModule.Free;
  finally
  end;
  try
    rtcClient.Free;
  finally
  end;
  try
    rtcRes.Free;
  finally
  end;
end;

procedure TSendDestroyClientToGatewayThread.Execute;
var
  msg: TMsg;
  i: Integer;
begin
  while (not Terminated)
    and (not FNeedStopThread)
    and (not FResultGot) do
  begin
    if not Windows.GetMessage(msg, 0, 0, 0) then
      Terminate;

      if not Terminated then
      begin
        if (MSG.message = WM_DESTROY) then
        begin
          FNeedStopThread := True;
        end
        else
          ProcessMessage(msg);
      end;
  end;

  for i := 0 to 10 do
  begin
    Application.ProcessMessages;
    Sleep(1000);
  end;
end;

procedure TSendDestroyClientToGatewayThread.rtcResReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  FResultGot := True;
end;

procedure TSendDestroyClientToGatewayThread.rtcResRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  FResultGot := True;
end;

procedure TSendDestroyClientToGatewayThread.ProcessMessage(MSG: TMSG);
var
  Message: TMessage;
begin
  Message.Msg := Msg.message;
  Message.WParam := MSG.wParam;
  Message.LParam := MSG.lParam;
  Message.Result := 0;
  Dispatch(Message);
end;

function TMainForm.ConnectedToAllGateways: Boolean;
begin
  CS_Status.Acquire;
  try
    Result := CurStatus >= 3;
  finally
    CS_Status.Release;
  end;
end;

constructor TStatusUpdateThread.Create(CreateSuspended: Boolean;
  StatusUpdateProc: TStatusUpdateProc);
begin
  inherited Create(CreateSuspended);

  FreeOnTerminate := True;
  FStatusUpdateProc := StatusUpdateProc;
end;

procedure TStatusUpdateThread.Execute;
begin
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

procedure TMainform.ChangePortP(AClient: TRtcHttpPortalClient);
begin
  if AClient.GatePort = '80' then
    AClient.GatePort := '8080'
  else
  if AClient.GatePort = '8080' then
    AClient.GatePort := '443'
  else
  if AClient.GatePort = '443' then
    AClient.GatePort := '5938'
  else
  if AClient.GatePort = '5938' then
    AClient.GatePort := '80';
end;

constructor TPortalThread.Create(CreateSuspended: Boolean; AUserName, AAction, AGateway: String);
begin
  inherited Create(CreateSuspended);

  FreeOnTerminate := True;

  FUserName := AUserName;
  FGateway := AGateway;
  FAction := AAction;

  FNeedStopThread := False;

  FUID := GetUniqueString;

  FGatewayClient := TRtcHttpPortalClient.Create(nil);
  FGatewayClient.Name := 'PClient_' + FUID;
  FGatewayClient.LoginUserName := MainForm.PClient.LoginUserName + '_' + FUserName + '_' + FAction + '_' + FUID; //IntToStr(GatewayClientsList.Count + 1);
  FGatewayClient.LoginUserInfo.asText['RealName'] := MainForm.PClient.LoginUserInfo.asText['RealName'];
  FGatewayClient.LoginPassword := MainForm.PClient.LoginPassword;
  FGatewayClient.AutoSyncEvents := MainForm.PClient.AutoSyncEvents;
  FGatewayClient.DataCompress := MainForm.PClient.DataCompress;
  FGatewayClient.DataEncrypt := MainForm.PClient.DataEncrypt;
  FGatewayClient.DataForceEncrypt := MainForm.PClient.DataForceEncrypt;
  FGatewayClient.DataSecureKey := MainForm.PClient.DataSecureKey;
  FGatewayClient.GateAddr := Copy(AGateway, 1, Pos(':', AGateway) - 1);
  FGatewayClient.GatePort := Copy(AGateway, Pos(':', AGateway) + 1, Length(AGateway) - Pos(':', AGateway));
  FGatewayClient.Gate_CryptPlugin := MainForm.PClient.Gate_CryptPlugin;
  FGatewayClient.Gate_ISAPI := MainForm.PClient.Gate_ISAPI;
  FGatewayClient.Gate_Proxy := MainForm.PClient.Gate_Proxy;
  FGatewayClient.Gate_ProxyAddr := MainForm.PClient.Gate_ProxyAddr;
  FGatewayClient.Gate_ProxyBypass := MainForm.PClient.Gate_ProxyBypass;
  FGatewayClient.Gate_ProxyPassword := MainForm.PClient.Gate_ProxyPassword;
  FGatewayClient.Gate_ProxyUserName := MainForm.PClient.Gate_ProxyUserName;
  FGatewayClient.Gate_SSL := MainForm.PClient.Gate_SSL;
  FGatewayClient.Gate_Timeout := MainForm.PClient.Gate_Timeout;
  FGatewayClient.Gate_WinHttp := MainForm.PClient.Gate_WinHttp;
//        FGatewayClient.GParamsLoaded := PClient.GParamsLoaded;
  FGatewayClient.GRestrictAccess := MainForm.PClient.GRestrictAccess;
  FGatewayClient.GSuperUsers := MainForm.PClient.GSuperUsers;
  FGatewayClient.GUsers := MainForm.PClient.GUsers;
  FGatewayClient.GwStoreParams := MainForm.PClient.GwStoreParams;
  FGatewayClient.MultiThreaded := MainForm.PClient.MultiThreaded;
  FGatewayClient.RetryFirstLogin := MainForm.PClient.RetryFirstLogin;
  FGatewayClient.RetryOtherCalls := MainForm.PClient.RetryOtherCalls;
  FGatewayClient.UserNotify := MainForm.PClient.UserNotify;
  FGatewayClient.UserVisible := MainForm.PClient.UserVisible;
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

  xLog('Created gateway client: ' + 'PClient_' + FUID);

  FDesktopControl := nil;
  FFileTransfer := nil;
  FChat := nil;

  if FAction = 'desk' then
  begin
    FDesktopControl := TRtcPDesktopControl.Create(nil);
    FDesktopControl.Name := 'PDesktopControl_' + FUID;
    FDesktopControl.Client := FGatewayClient;
    FDesktopControl.SendShortcuts := MainForm.PDesktopControl.SendShortcuts;
    FDesktopControl.OnNewUI := MainForm.PDesktopControlNewUI;
    FDesktopControl.Tag := ThreadID;
  end
  else
  if FAction = 'file' then
  begin
    FFileTransfer := TRtcPFileTransfer.Create(nil);
    FFileTransfer.Name := 'PFileTransfer_' + FUID;
    FFileTransfer.Client := FGatewayClient;
    FFileTransfer.AccessControl := MainForm.PFileTrans.AccessControl;
    FFileTransfer.BeTheHost := False;
    FFileTransfer.FileInboxPath := MainForm.PFileTrans.FileInboxPath;
    FFileTransfer.GAllowBrowse := MainForm.PFileTrans.GAllowBrowse;
    FFileTransfer.GAllowBrowse_Super := MainForm.PFileTrans.GAllowBrowse_Super;
    FFileTransfer.GAllowDownload := MainForm.PFileTrans.GAllowDownload;
    FFileTransfer.GAllowDownload_Super := MainForm.PFileTrans.GAllowDownload_Super;
    FFileTransfer.GAllowFileDelete := MainForm.PFileTrans.GAllowFileDelete;
    FFileTransfer.GAllowFileDelete_Super := MainForm.PFileTrans.GAllowFileDelete_Super;
    FFileTransfer.GAllowFileMove := MainForm.PFileTrans.GAllowFileMove;
    FFileTransfer.GAllowFileMove_Super := MainForm.PFileTrans.GAllowFileMove_Super;
    FFileTransfer.GAllowFileRename := MainForm.PFileTrans.GAllowFileRename;
    FFileTransfer.GAllowFolderCreate := MainForm.PFileTrans.GAllowFolderCreate;
    FFileTransfer.GAllowFolderCreate_Super := MainForm.PFileTrans.GAllowFolderCreate_Super;
    FFileTransfer.GAllowFolderDelete := MainForm.PFileTrans.GAllowFolderDelete;
    FFileTransfer.GAllowFolderDelete_Super := MainForm.PFileTrans.GAllowFolderDelete_Super;
    FFileTransfer.GAllowFolderMove := MainForm.PFileTrans.GAllowFolderMove;
    FFileTransfer.GAllowFolderMove_Super := MainForm.PFileTrans.GAllowFolderMove_Super;
    FFileTransfer.GAllowFolderRename := MainForm.PFileTrans.GAllowFolderRename;
    FFileTransfer.GAllowShellExecute := MainForm.PFileTrans.GAllowShellExecute;
    FFileTransfer.GAllowShellExecute_Super := MainForm.PFileTrans.GAllowShellExecute_Super;
    FFileTransfer.GAllowUpload := MainForm.PFileTrans.GAllowUpload;
    FFileTransfer.GAllowUpload_Super := MainForm.PFileTrans.GAllowUpload_Super;
    FFileTransfer.GUploadAnywhere := MainForm.PFileTrans.GUploadAnywhere;
    FFileTransfer.GUploadAnywhere_Super := MainForm.PFileTrans.GUploadAnywhere_Super;
    FFileTransfer.GwStoreParams := MainForm.PFileTrans.GwStoreParams;
    FFileTransfer.MaxSendChunkSize := MainForm.PFileTrans.MaxSendChunkSize;
    FFileTransfer.MinSendChunkSize := MainForm.PFileTrans.MinSendChunkSize;
    FFileTransfer.OnNewUI := MainForm.PFileTransExplorerNewUI; //Для контроля указываем эксплорер
    FFileTransfer.OnUserJoined := MainForm.PModuleUserJoined;
    FFileTransfer.OnUserLeft := MainForm.PModuleUserLeft;
    FFileTransfer.Tag := ThreadID;
  end
  else
  if FAction = 'chat' then
  begin
    FChat := TRtcPChat.Create(nil);
    FChat.Name := 'PChat_' + FUID;
    FChat.Client := FGatewayClient;
    FChat.AccessControl := MainForm.PChat.AccessControl;
    FChat.BeTheHost := False;
    FChat.GAllowJoin := MainForm.PChat.GAllowJoin;
    FChat.GAllowJoin_Super := MainForm.PChat.GAllowJoin_Super;
    FChat.GwStoreParams := MainForm.PChat.GwStoreParams;
    FChat.OnNewUI := MainForm.PChatNewUI;
    FChat.OnUserJoined := MainForm.PModuleUserJoined;
    FChat.OnUserLeft := MainForm.PModuleUserLeft;
    FChat.Tag := ThreadID;
  end;

  FGatewayClient.Active := True;

  if FAction = 'desk' then
  begin
    FDesktopControl.ChgDesktop_Begin;
    FDesktopControl.ChgDesktop_UseMouseDriver(False);
    FDesktopControl.ChgDesktop_CaptureLayeredWindows(False);
    FDesktopControl.ChgDesktop_End(FUserName);

    FDesktopControl.Open(FUserName);
  end
  else
  if FAction = 'file' then
    FFileTransfer.Open(FUserName)
  else
  if FAction = 'chat' then
    FChat.Open(FUserName);
end;

destructor TPortalThread.Destroy;
begin
  try
    FGatewayClient.Disconnect;
  finally
  end;
  try
    FGatewayClient.Active := False;
  finally
  end;
  try
    FGatewayClient.Stop;
  finally
  end;

  try
    if FDesktopControl <> nil then
      FDesktopControl.Free;
  finally
  end;
  try
    if FFileTransfer <> nil then
      FFileTransfer.Free;
  finally
  end;
  try
    if FChat <> nil then
      FChat.Free;
  finally
  end;
  try
    FGatewayClient.Free;
  finally
  end;

  TSendDestroyClientToGatewayThread.Create(False, FGateway, MainForm.PClient.LoginUserName + '_' + FUserName + '_' + FAction + '_' + FUID, False);
end;

procedure TPortalThread.Execute;
var
  msg: TMsg;
begin
  while (not Terminated)
    and (not FNeedStopThread) do
  begin
    if not Windows.GetMessage(msg, 0, 0, 0) then
      Terminate;

      if not Terminated then
      begin
        if (MSG.message = WM_DESTROY) then
        begin
          FNeedStopThread := True;
        end
        else
          ProcessMessage(msg);
      end;
  end;
end;

procedure TPortalThread.ProcessMessage(MSG: TMSG);
var
  Message: TMessage;
begin
  Message.Msg := Msg.message;
  Message.WParam := MSG.wParam;
  Message.LParam := MSG.lParam;
  Message.Result := 0;
  Dispatch(Message);
end;

function TPortalThread.GetUniqueString: String;
var
  UID: TGUID;
begin
  CreateGuid(UID);
  Result := GUIDToString(UID);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
end;

procedure TMainForm.DoPowerPause;
var
  i: Integer;
begin
//  XLog('Power pause');

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

  SetConnectedState(False); //Сначала устанавливаем первичные насройки прокси
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

  fAboutForm := TfAboutForm.Create(nil);
  try
    OnCustomFormOpen(fAboutForm);
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

  fMessageBox := TfMessageBox.Create(nil);
  try
    fMessageBox.SetText(AText);
    fMessageBox.Caption := ACaption;

    OnCustomFormOpen(fMessageBox);
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
//    Res := MessageBox(Handle, PWideChar('Удалить группу "' + DData.Name + '" и все компьютеры в ней?'), PWideChar('Remox'), MB_ICONWARNING or MB_YESNO)
    ShowMessageBox('Удалить группу "' + DData.Name + '" и все устройства в ней?', 'Remox', 'DeleteDeviceGroup', DData.UID)
  else
//    Res := MessageBox(Handle, PWideChar('Удалить устройство "' + DData.Name + '"?'), PWideChar('Remox'), MB_ICONWARNING or MB_YESNO);
    ShowMessageBox('Удалить устройство "' + DData.Name + '"?', 'Remox', 'DeleteDeviceGroup', DData.UID);

//  if Res = mrNo then
//    Exit;

//  with cmAccounts.Data.NewFunction('Account.DeleteDeviceGroup') do
//  begin
//    asString['UID'] := DData.UID;
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

  if File_Exists(ChangeFileExt(ParamStr(0), '.svc')) then
    if (File_Age(ChangeFileExt(ParamStr(0), '.svc')) >= IncSecond(Now, -3)) then //Если это старт/стоп службы
    begin
      tCheckLockedStateTimer(nil);

      SetIDContolsVisible;

//      SetHostActive;
    end
    else
      Delete_File(ChangeFileExt(ParamStr(0), '.svc'));
end;

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

procedure TMainForm.ShowRegularPasswordState();
begin
  //XLog('ShowRegularPasswordState');

  if RegularPassword <> '' then
    iRegPassState.Picture.Assign(iRegPassYes.Picture)
  else
    iRegPassState.Picture.Assign(iRegPassNo.Picture);
end;

//procedure TMainForm.WndProc(var Msg: TMessage);
//begin
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
      pmIconMenu.Popup(p.x, p.y);
      PostMessage(Handle, WM_NULL, 0, 0);
      Message.Result := 0;
    end;
  end;

//  inherited;
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
    reg.RootKey:=HKEY_CURRENT_USER;
    if reg.OpenKey('\AppEvents\Schemes\Apps\.Default\CCSelect\.current',False) then
    try
      if reg.ValueExists('') then
        if Trim(reg.ReadString(''))='' then
          reg.DeleteValue('');
    finally
      reg.CloseKey;
    end;
    if reg.OpenKey('\AppEvents\Schemes\Apps\.Default\CCSelect\.Modified',False) then
    try
      if reg.ValueExists('') then
        if Trim(reg.ReadString(''))='' then
          reg.DeleteValue('');
    finally
      reg.CloseKey;
    end;
  finally
    reg.Free;
  end;
end;

{function TMainForm.AddGatewayClient(GatewayClient: PRtcHttpPortalClient; DesktopControl: PRtcPDesktopControl; FileTransfer: PRtcPFileTransfer; Chat: PRtcPChat): PGatewayRec;
var
  GatewayRec: PGatewayRec;
begin
  CS_GW.Acquire;
  try
    New(GatewayRec);
    GatewayRec^.GatewayClient := GatewayClient;
    GatewayRec^.DesktopControl := DesktopControl;
    GatewayRec^.FileTransfer := FileTransfer;
    GatewayRec^.Chat := Chat;
    GatewayRec^.UIClosed := False;
    GatewayRec^.Stopped := False;
    GatewayClientsList.Add(GatewayRec);

    Result := GatewayRec;
  finally
    CS_GW.Release;
  end;
end;}

procedure TMainForm.AddPortalConnection(AThreadID: Cardinal; AHandle: THandle; AAction: String; AID: String);
var
  pPC: PPortalConnection;
begin
  CS_GW.Acquire;
  try
    New(pPC);
    pPC^.ThreadID := AThreadID;
    pPC^.UIHandle := AHandle;
    pPC^.Action := AAction;
    pPC^.ID := AID;
    PortalConnectionsList.Add(pPC);
  finally
    CS_GW.Release;
  end;
end;

{function TMainForm.GetGatewayRecByDesktopControl(DesktopControl: TRtcPDesktopControl): PGatewayRec;
var
  i: Integer;
begin
  Result := nil;

  CS_GW.Acquire;
  try
    for i := 1 to GatewayClientsList.Count - 1 do
      if Assigned(PGatewayRec(GatewayClientsList[i])^.DesktopControl) then
        if PGatewayRec(GatewayClientsList[i])^.DesktopControl^ = DesktopControl then
        begin
          Result := GatewayClientsList[i];
          Break;
        end;
  finally
    CS_GW.Release;
  end;
end;}

function TMainForm.GetPortalConnection(AAction: String; AID: String): PPortalConnection;
var
  i: Integer;
begin
  //XLog('GetPortalConnection');

  Result := nil;

  CS_GW.Acquire;
  try
    for i := 0 to PortalConnectionsList.Count - 1 do
      if (PPortalConnection(PortalConnectionsList[i])^.Action = AAction)
        and (PPortalConnection(PortalConnectionsList[i])^.ID = AID) then
      begin
        Result := PortalConnectionsList[i];
        Break;
      end;
  finally
    CS_GW.Release;
  end;
end;

procedure TMainForm.tCleanConnectionsTimer(Sender: TObject);
var
  i: Integer;
begin
{  xLog('tCleanConnectionsTimer');
  CS_GW.Acquire;
  try
    i := GatewayClientsList.Count - 1;
    while i >= 1 do
    begin
      if PGatewayRec(GatewayClientsList[i])^.UIClosed
        and PGatewayRec(GatewayClientsList[i])^.Stopped then
      begin
        FreeGatewayRec(GatewayClientsList[i]);

        Dispose(GatewayClientsList[i]);
        GatewayClientsList.Delete(i);
      end;

      i := i - 1;
    end;
  finally
    CS_GW.Release;
  end;}
end;

{procedure TMainForm.FreeGatewayRec(AGatewayRec: PGatewayRec);
begin
  if Assigned(AGatewayRec^.DesktopControl) then
    try
      FreeAndNil(AGatewayRec^.DesktopControl^);
    finally
    end;
  if Assigned(AGatewayRec^.FileTransfer) then
    try
      FreeAndNil(AGatewayRec^.FileTransfer^);
    finally
    end;
  if Assigned(AGatewayRec^.Chat) then
    try
      FreeAndNil(AGatewayRec^.Chat^);
    finally
    end;
  if Assigned(AGatewayRec^.GatewayClient) then
    try
      FreeAndNil(AGatewayRec^.GatewayClient^);
    finally
    end;
end;

procedure TMainForm.SetActiveUIRecStoppedByPClient(AClient: TAbsPortalClient);
var
  i: Integer;
begin
  CS_GW.Acquire;
  try
    i := GatewayClientsList.Count - 1;
    while i >= 1 do
    begin
      if (PGatewayRec(GatewayClientsList[i])^.GatewayClient^ = AClient)
        and PGatewayRec(GatewayClientsList[i])^.UIClosed then
      begin
        PGatewayRec(GatewayClientsList[i])^.Stopped := True;

        Break;
      end;

      i := i - 1;
    end;
  finally
    CS_GW.Release;
  end;

//  if GatewayClientsList.Count = 1 then
//    Application.Restore;

//  tCleanConnectionsTimer(nil);
end;}

{procedure TMainForm.RemovePortalConnectionByUIHandle(AUIHandle: THandle);
var
  i: Integer;
begin
  XLog('RemovePortalConnectionByUIHandle');

  CS_GW.Acquire;
  try
    i := PortalConnectionsList.Count - 1;
    while i >= 0 do
    begin
      if PPortalConnection(PortalConnectionsList[i])^.UIHandle = AUIHandle then
      begin
        PostThreadMessage(PPortalConnection(PortalConnectionsList[i])^.ThreadID, WM_DESTROY, 0, 0); //Закрываем поток с пклиентом
        PostMessage(PPortalConnection(PortalConnectionsList[i])^.UIHandle, WM_CLOSE, 0, 0); //Закрываем форму UI

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
end;}

procedure TMainForm.RemovePortalConnectionByThreadId(AThreadId: Cardinal; ACloseFUI: Boolean);
var
  i: Integer;
begin
  //XLog('RemovePortalConnectionByUIHandle');

  CS_GW.Acquire;
  try
    i := PortalConnectionsList.Count - 1;
    while i >= 0 do
    begin
      if PPortalConnection(PortalConnectionsList[i])^.ThreadId = AThreadId then
      begin
        PostThreadMessage(PPortalConnection(PortalConnectionsList[i])^.ThreadID, WM_DESTROY, 0, 0); //Закрываем поток с пклиентом
        if ACloseFUI then
          PostMessage(PPortalConnection(PortalConnectionsList[i])^.UIHandle, WM_CLOSE, 0, 0); //Закрываем форму UI. Нужно при отмене подключения

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

procedure TMainForm.RemovePortalConnectionByUser(ID: String);
var
  i: Integer;
begin
  //XLog('RemovePortalConnectionByUser');

  CS_GW.Acquire;
  try
    i := PortalConnectionsList.Count - 1;
    while i >= 0 do
    begin
      if PPortalConnection(PortalConnectionsList[i])^.ID = ID then
      begin
        PostThreadMessage(PPortalConnection(PortalConnectionsList[i])^.ThreadID, WM_DESTROY, 0, 0); //Закрываем поток с пклиентом
        PostMessage(PPortalConnection(PortalConnectionsList[i])^.UIHandle, WM_CLOSE, 0, 0); //Закрываем форму UI

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

{//function TMainForm.GetActiveUICountByGatewayRec(AGatewayRec: PGatewayRec): Integer;
//var
//  i: Integer;
//begin
//  Result := 0;
//  for i := 0 to ActiveUIList.Count - 1 do
//    if PActiveUIRec(ActiveUIList[i])^.GatewayRec = AGatewayRec then
//      Result := Result + 1;
//end;

function TMainForm.GetGatewayRecByChat(Chat: TRtcPChat): PGatewayRec;
var
  i: Integer;
begin
  Result := nil;

  CS_GW.Acquire;
  try
    for i := 0 to GatewayClientsList.Count - 1 do
      if Assigned(PGatewayRec(GatewayClientsList[i])^.Chat) then
        if PGatewayRec(GatewayClientsList[i])^.Chat^ = Chat then
        begin
          Result := GatewayClientsList[i];
          Break;
        end;
  finally
    CS_GW.Release;
  end;
end;

function TMainForm.GetGatewayRecByFileTransfer(FileTransfer: TRtcPFileTransfer): PGatewayRec;
var
  i: Integer;
begin
  Result := nil;

  CS_GW.Acquire;
  try
    for i := 0 to GatewayClientsList.Count - 1 do
    begin
      if Assigned(PGatewayRec(GatewayClientsList[i])^.FileTransfer) then
        if (PGatewayRec(GatewayClientsList[i])^.FileTransfer^ = FileTransfer) then
        begin
          Result := GatewayClientsList[i];
          Break;
        end;
    end;
  finally
    CS_GW.Release;
  end;
end;

//function TMainForm.FindGatewayClient(Address: String; Port: String): PGatewayRec;
//var
//  i: Integer;
//  GC: PRtcHttpPortalClient;
//begin
//  Result := nil;
//
//  for i := 0 to GatewayClientsList.Count - 1 do
//  begin
//    GC := PGatewayRec(GatewayClientsList[i])^.GatewayClient;
//    if (PGatewayRec(GatewayClientsList[i])^.GatewayClient^.GateAddr = Address)
//      and (PGatewayRec(GatewayClientsList[i])^.GatewayClient^.GatePort = Port)
//      and (PGatewayRec(GatewayClientsList[i])^.GatewayClient^ <> PClient) then
//    begin
//      Result := GatewayClientsList[i];
//      Break;
//    end;
//  end;
//end;}

procedure TMainForm.aFeedBackExecute(Sender: TObject);
var
  pAccUserName: String;
begin
  //XLog('aFeedBackExecute');

//  ShellExecute(Handle, 'Open', 'mailto:support@Remox.com', nil, nil, SW_RESTORE);
//  if LoggedIn then
//    pAccUserName := eAccountUserName.Text
//  else
//    pAccUserName := '';                    //PChar('mailto:support@remox.com?body=<BR><BR><BR>Account:' + AccountName + '<BR>Device ID:' + PClient.LoginUserInfo.asText['RealName'])
  ShellExecute(Application.Handle, 'open', 'mailto:support@remox.com', nil, nil, SW_SHOW);
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

{procedure TMainForm.CloseThisApp;
var
  i: Integer;
begin
  SaveSetup;

  tConnect.Enabled := False;

//  if(eConnected.Items.Count > 0) then
//  begin
//  if SilentMode then
//  begin
    LogOut(Self);
    HostLogOut;
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

  Visible := False;

  isClosing := True;

  for i := 0 to Length(GatewayClients) - 1 do
  begin
//      GatewayClients[i].GatewayClient.Disconnect;

    if GatewayClients[i].GatewayClient.Active then
      GatewayClients[i].GatewayClient.Active := False;
    GatewayClients[i].GatewayClient.Stop;

//      GatewayClients[i].GatewayClient.Module.WaitForCompletion(False, 2);
//      GatewayClients[i].GatewayClient.Module.SkipRequests;
  end;

  pingTimer.Enabled := False;
  HostPingTimer.Enabled := False;

//  hcAccounts.WaitForCompletion(False, 2);

//  cmAccounts.SkipRequests;
//  TimerModule.SkipRequests;
//  HostTimerModule.SkipRequests;
//
//  hcAccounts.Disconnect;
//  TimerClient.Disconnect;
//  HostTimerClient.Disconnect;

  Application.Terminate;
end;}

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

  Constraints.MinWidth := 0;
  Constraints.MaxWidth := 0;
  if DevicesPanelVisible then
  begin
    pDevAcc.Visible := True;
    ClientWidth := 840;
    bDevices.Caption := 'Мои устройства <<';
  end
  else
  begin
    pDevAcc.Visible := False;
    ClientWidth := 538;
    bDevices.Caption := 'Мои устройства >>';
    Constraints.MaxWidth := Width;
  end;

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

    Constraints.MaxWidth := Width;
  end;
  Constraints.MinWidth := Width;

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

procedure TMainForm.FormCreate(Sender: TObject);
var
  err: LongInt;
begin
  //XLog('FormCreate');

  hwndNextViewer := SetClipboardViewer(Handle);

  ActivationInProcess := False;

  CurStatus := 0;
  FStatusUpdateThread := TStatusUpdateThread.Create(False, UpdateStatus);

  OpenedModalForm := nil;
  SettingsFormOpened := False;

  tActivateHost.Enabled := False;

  isClosing := False;

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

  PFileTrans.FileInboxPath:= ExtractFilePath(AppFileName) + '\INBOX';

//  Left:=(Screen.Width-Width) div 2;
//  Top:=(Screen.Height-Height) div 2;

  LoadSetup('ALL');
  SetConnectedState(False); //Сначала устанавливаем первичные насройки прокси
//  SetStatusString('Подключение к серверу...', True);
  StartAccountLogin;
  StartHostLogin;
  ShowRegularPasswordState();
//  AutoScaleForm(MainForm);
//  Width := CurWidth;
  LoggedIn := False;
//  if not DevicesPanelVisible then
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
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  //XLog('FormDestroy');

  ChangeClipboardChain(Handle, hwndNextViewer);
  hwndNextViewer := 0;

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

  if (PClient.Gate_Proxy <> ProxyEnabled)
    or (PClient.Gate_ProxyAddr <> CurProxy) then
  begin
//    CS_GW.Acquire;
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
//    end;

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
          PClient.Gate_ProxyAddr := '';
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
begin
  //XLog('SetStatus: ' + IntToStr(CurStatus));

  CS_Status.Acquire;
  try
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
      btnViewDesktop.Caption := 'ПРЕРВАТЬ';
      btnViewDesktop.Color := RGB(232, 17, 35);
    end
    else
    begin
      btnViewDesktop.Caption := 'ПОДКЛЮЧИТЬСЯ';
      btnViewDesktop.Color := $00A39323;
    end;

    btnViewDesktop.Enabled := LoggedIn;
    btnAccountLogin.Enabled := (not LoggedIn) and ConnectedToAllGateways;

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
      HostPingTimer.Enabled := True;

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
      HostPingTimer.Enabled := False;

      eConsoleID.Text := '-';
      eUserName.Text := '-';
      ePassword.Text := '-';

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
//  //      if ProxyOption = 'Automatic' then
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

  pDevAcc.Left := 542;
  pDevAcc.Width := ClientWidth - pDevAcc.Left; //pRight.Left - pRight.Width - GetScaleValue(25);
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

procedure TMainForm.Label22Click(Sender: TObject);
begin
//  XLog('Label22Click');

  ShowSettingsForm('tsSequrity');
end;

procedure TMainForm.lDevicesClick(Sender: TObject);
begin
//  XLog('lDevicesClick');

  DevicesPanelVisible := not DevicesPanelVisible;
  ShowDevicesPanel;
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
//  end;
end;

procedure TMainForm.hcAccountsConnectFail(Sender: TRtcConnection);
begin
//  xLog('hcAccountsConnectFail');
//  SendMessage(Handle, WM_LOGEVENT, 0, LongInt(DateTime2Str(Now) + ': hcAccountsConnectFail'));

//  if not tConnect.Enabled
//    and (not SettingsUpdateInProcess) then
//  begin
//    SetStatusString('Сервер недоступен');
//    tConnect.Enabled := True;
//    SetConnectedState(False);
//  end;
end;

procedure TMainForm.hcAccountsConnectLost(Sender: TRtcConnection);
begin
//  xLog('hcAccountsConnectLost');
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
    SetConnectedState(False);
    if not isClosing then
      tHcAccountsReconnect.Enabled := True;
  end;

  tActivateHost.Enabled := False;

//  CloseAllActiveUI;
  ChangePort(hcAccounts);
end;

procedure TMainForm.hcAccountsException(Sender: TRtcConnection; E: Exception);
begin
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
    if TDeviceData(twDevices.GetNodeData(Node)^).ID = StrToInt(RemoveUserPrefix(uname)) then
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

    RemovePortalConnectionByUser(uname);
    DeletePendingRequests(uname);
  end;
end;

function TMainForm.GetUserNameByID(uname: String): String;
var
  Data: PDeviceData;
begin
//  XLog('GetUserNameByID');

  Data := GetDeviceInfo(uname);
  if Data <> nil then
    Result := Data.Name
  else
    Result := uname;
end;

procedure TMainForm.Locked_Status(uname: String; status: Integer);
var
  i: Integer;
begin
//  XLog('Locked_Status');

  CS_GW.Acquire;
  try
    for i := 0 to PortalConnectionsList.Count - 1 do
      if PPortalConnection(PortalConnectionsList[i])^.ID = uname then
      begin
//        PGatewayRec(GatewayClientsList[i])^.LockedState := status;
        PostMessage(PPortalConnection(PortalConnectionsList[i])^.UIHandle, WM_CHANGE_LOCKED_STATUS, status, 0);
      end;
  finally
    CS_GW.Release;
  end;
end;

procedure TMainForm.LoadSetup(RecordType: String);
var
  CfgFileName: String;
  s: RtcString;
  info: TRtcRecord;
begin
//  xLog('LoadSetup: ' + RecordType);

  //Registry
  if (RecordType = 'ALL')
    or (RecordType = 'ACTIVE_NODE') then
  begin
//    reg := TRegistry.Create;
//    try
//      reg.RootKey := HKEY_CURRENT_USER;
//      if reg.OpenKeyReadOnly('\Software\Remox') then
//      try
////        reg.ReadMultiSz('Data', s);
//        //  s := reg.ReadBinaryDataToString('Data');
//        len := reg.GetDataSize('Settings');
//        if len > 0 then
//        begin
//          SetLength(str_a, len);
//          reg.ReadBinaryData('Settings', str_a[1], len * SizeOf(AnsiChar));
//          s := String(str_a);
//        end
//        else
//          s := '';
////        SetLength(bytes, 789517);
////        reg.ReadBinaryData('Data', bytes, 789517);
////        s := TEncoding.UTF8.GetString(bytes);
//      finally
//        reg.CloseKey;
//      end;
//    finally
//      reg.Free;
//    end;

    CfgFileName:= GetDOSEnvVar('APPDATA') + '\Remox\Profile.dat';
    s := Read_File(CfgFileName, rtc_ShareDenyNone);

    if s <> '' then
    begin
      DeCrypt(s, 'Remox');
//      s := DecryptStr(s, 'Remox');
      try
        info := TRtcRecord.FromCode(s);
      except
        info := nil;
      end;
    end;
    if Assigned(info) then
    begin
      try
        if (RecordType = 'ALL') then
        begin
          StoreHistory := info.asBoolean['StoreHistory'];
          StorePasswords := info.asBoolean['StorePasswords'];
          DevicesPanelVisible := info.asBoolean['DevicesPanelVisible'];

  //            PClient.GateAddr:=info.asString['Address'];
  //            PClient.GatePort:=info.asString['Port'];
  //            PClient.Gate_WinHttp := info.asBoolean['WinHTTP'];
  //            PClient.Gate_SSL := info.asBoolean['SSL'];
  //            PClient.Gate_ISAPI:=info.asString['DLL'];
  //            PClient.DataSecureKey:=info.asString['SecureKey'];
  //            PClient.DataCompress:=TRtcpCompressLevel(info.asInteger['Compress']);

  //        hcAccounts.ServerAddr := info.asString['Address'];
  //        TimerClient.ServerAddr := info.asString['Address'];
  //              PClient.GateAddr := info.asString['Address']; //Устанавливается при активации

  //        HostTimerClient.ServerAddr := info.asString['Address'];

          StoreHistory := info.asBoolean['StoreHistory'];
          StorePasswords := info.asBoolean['StorePasswords'];
//          OnlyAdminChanges := info.asBoolean['OnlyAdminChanges'];

          DevicesPanelVisible := info.asBoolean['DevicesPanelVisible'];

          cbRememberAccount.Checked := info.asBoolean['RememberAccount'];
          eAccountUserName.Text := info.asString['AccountUserName'];;
          eAccountPassword.Text := info.asString['AccountPassword'];

          DateAllowConnectionPending := info.asDateTime['DateAllowConnectPending'];
        end;

        if (RecordType = 'ALL')
          or (RecordType = 'ACTIVE_NODE') then
          LastFocusedUID := info.asString['LastFocusedUID'];

  //            PClient.LoginUsername:=info.asText['UserName'];
  //            PClient.LoginPassword:=info.asText['Password'];
          { We can simply replace all data from "LoginUserInfo" with "CustomInfo",
            because this is where we have saved it. }
  //            PClient.LoginUserInfo:=info.asRecord['CustomInfo'];

  //            xSavePassword.Checked:=info.asBoolean['SavePassword'];
  //            xAutoConnect.Checked:=info.asBoolean['AutoConnect'];
  //
  //            if (PClient.GateAddr='') or (PClient.GatePort='') then
  //              btnGateway.Caption:='< Click to set up connection >'
  //            else
  //              btnGateway.Caption:=String(PClient.GateAddr+':'+PClient.GatePort);
  //
  //            if not info.isNull['Priority'] then
  //              cPriority.ItemIndex:=info.asInteger['Priority'];
      finally
        info.Free;
      end;
    end
    else
    begin
      StoreHistory := True;
      StorePasswords := True;
      DevicesPanelVisible := True;
      cbRememberAccount.Checked := True;
    end;
  end;

  //Inf file
  if (RecordType = 'ALL')
    or (RecordType = 'REGULAR_PASS') then
  begin
    CfgFileName:= ChangeFileExt(AppFileName,'.inf'); //RTC_LOG_FOLDER + ChangeFileExt(ExtractFileName(Application.ExeName), '.inf');
    s := Read_File(CfgFileName, rtc_ShareDenyNone);

    if s <> '' then
    begin
      DeCrypt(s, 'Remox');
      try
        info:=TRtcRecord.FromCode(s);
      except
        info:=nil;
        end;
    end;

    if Assigned(info) then
    begin
      if (RecordType = 'ALL')
        or (RecordType = 'REGULAR_PASS') then
        RegularPassword := info.asString['RegularPassword'];

      if (RecordType = 'ALL') then
      begin
        ProxyOption := info.asString['ProxyOption'];
        if ProxyOption = 'Automatic' then
//        begin
//          PClient.Gate_WinHttp := True;
//          hcAccounts.UseWinHTTP := True;
//          TimerClient.UseWinHTTP := True;
//          HostTimerClient.UseWinHTTP := True;
//        end
//        else
        begin
          PClient.Gate_WinHttp := True;
          hcAccounts.UseWinHTTP := True;
          TimerClient.UseWinHTTP := True;
          HostTimerClient.UseWinHTTP := True;
        end;

        //Доделать. Удалить фикс прокси?
//        info.asBoolean['Proxy'] := True;
//        info.asString['ProxyAddr'] := 'socks=127.0.0.1:9050';

        PClient.Gate_Proxy := info.asBoolean['Proxy'];
        PClient.Gate_ProxyAddr := info.asString['ProxyAddr'];
        PClient.Gate_ProxyUserName := info.asString['ProxyUsername'];
        PClient.Gate_ProxyPassword := info.asString['ProxyPassword'];

        hcAccounts.UseProxy := info.asBoolean['Proxy'];
        hcAccounts.UserLogin.ProxyAddr := info.asString['ProxyAddr'];
        hcAccounts.UserLogin.ProxyUserName := info.asString['ProxyUsername'];
        hcAccounts.UserLogin.ProxyPassword := info.asString['ProxyPassword'];

        TimerClient.UseProxy := info.asBoolean['Proxy'];
        TimerClient.UserLogin.ProxyAddr := info.asString['ProxyAddr'];
        TimerClient.UserLogin.ProxyUserName := info.asString['ProxyUsername'];
        TimerClient.UserLogin.ProxyPassword := info.asString['ProxyPassword'];

        HostTimerClient.UseProxy := info.asBoolean['Proxy'];
        HostTimerClient.UserLogin.ProxyAddr := info.asString['ProxyAddr'];
        HostTimerClient.UserLogin.ProxyUserName := info.asString['ProxyUsername'];
        HostTimerClient.UserLogin.ProxyPassword := info.asString['ProxyPassword'];
      end;
    end;
  end;

  if PClient.GateAddr = '' then
    PClient.GateAddr := '95.216.96.39';
  if hcAccounts.ServerAddr = '' then
    hcAccounts.ServerAddr := '95.216.96.39';
  if TimerClient.ServerAddr = '' then
    TimerClient.ServerAddr := '95.216.96.39';
  if HostTimerClient.ServerAddr = '' then
    HostTimerClient.ServerAddr := '95.216.96.39';

  if ProxyOption = '' then
    ProxyOption := 'Automatic';

  // Load Window Position
//  LoadWindowPosition(Self, 'MainForm');
end;

procedure TMainForm.SaveSetup;
var
  CfgFileName: String;
  infos: RtcString;
  info: TRtcRecord;
begin
//  xLog('SaveSetup');
//  if SilentMode then Exit;

  //Registry
  info := TRtcRecord.Create;
  try
    info.asBoolean['StoreHistory'] := StoreHistory;
    info.asBoolean['StorePasswords'] := StorePasswords;
    info.asBoolean['DevicesPanelVisible'] := DevicesPanelVisible;

    info.asString['Address'] := hcAccounts.ServerAddr;
  //    info.asString['Port'] := PClient.GatePort;
    info.asBoolean['WinHTTP'] := PClient.Gate_WinHttp;
    info.asBoolean['SSL'] := PClient.Gate_SSL;
  //    info.asString['DLL'] := PClient.Gate_ISAPI;

    info.asString['RegularPassword'] := RegularPassword;
//    info.asBoolean['OnlyAdminChanges'] := OnlyAdminChanges;

    info.asBoolean['DevicesPanelVisible'] := DevicesPanelVisible;

    info.asString['ProxyOption'] := ProxyOption;
    info.asBoolean['Proxy'] := PClient.Gate_Proxy;
    info.asString['ProxyAddr'] := PClient.Gate_ProxyAddr;
    info.asString['ProxyPassword'] := PClient.Gate_ProxyPassword;
    info.asString['ProxyUsername'] := PClient.Gate_ProxyUserName;

    info.asBoolean['RememberAccount'] := cbRememberAccount.Checked;
    info.asString['AccountUserName'] := Trim(eAccountUserName.Text);
    if cbRememberAccount.Checked then
      info.asString['AccountPassword'] := Trim(eAccountPassword.Text)
    else
      info.asString['AccountPassword'] := '';

    info.asString['LastFocusedUID'] := LastFocusedUID;

    info.asDateTime['DateAllowConnectPending'] := DateAllowConnectionPending;

//    info.asString['SecureKey']:=PClient.DataSecureKey;
//    info.asInteger['Compress']:=Ord(PClient.DataCompress);

//    info.asText['UserName']:=PClient.LoginUsername;
//    if xSavePassword.Checked then
//      begin
//      info.asText['Password']:=PClient.LoginPassword;
//      info.asBoolean['SavePassword']:=True;
    //end;
  // Assigns a copy of the complete "LoginUserInfo" record to "info",
  // so we don't have to copy every field/value individually.
//    info.asRecord['CustomInfo']:=PClient.LoginUserInfo;

//    info.asBoolean['AutoConnect']:=xAutoConnect.Checked;
//    info.asInteger['Priority']:=cPriority.ItemIndex;

    infos := info.toCode;
    Crypt(infos, 'Remox');
//    infos := EncryptStr(infos, 'Remox');
  finally
    info.Free;
  end;

  if not DirectoryExists(GetDOSEnvVar('APPDATA') + '\Remox') then
    CreateDir(GetDOSEnvVar('APPDATA') + '\Remox');
  CfgFileName := GetDOSEnvVar('APPDATA') + '\Remox\Profile.dat';
  Write_File(CfgFileName, infos);

//  reg := TRegistry.Create;
//  try
//    reg.RootKey := HKEY_CURRENT_USER;
////    if not reg.KeyExists('\Software\Remox\Settings\' + GetSystemUserName) then
////      reg.CreateKey('\Software\Remox\Settings\' + GetSystemUserName);
//    if reg.OpenKey('\Software\Remox', True) then
//    try
//      infos_a := AnsiString(infos);
//      reg.WriteBinaryData('Settings', infos_a[1], Length(infos_a) * SizeOf(AnsiChar));
////      reg.WriteMultiSz('Data', infos);
////      bytes := TEncoding.UTF8.GetBytes(infos);
////      reg.WriteBinaryData('Data', bytes, Length(bytes));
//    finally
//      reg.CloseKey;
//    end;
//  finally
//    reg.Free;
//  end;

  //Inf file
  info := TRtcRecord.Create;
  try
    info.asWideString['RegularPassword'] := RegularPassword;

    info.asString['ProxyOption'] := ProxyOption;
    info.asBoolean['Proxy'] := PClient.Gate_Proxy;
    info.asString['ProxyAddr'] := PClient.Gate_ProxyAddr;
    info.asWideString['ProxyPassword'] := PClient.Gate_ProxyPassword;
    info.asWideString['ProxyUsername'] := PClient.Gate_ProxyUserName;

//    info.asString['SecureKey']:=PClient.DataSecureKey;
//    info.asInteger['Compress']:=Ord(PClient.DataCompress);

//    info.asText['UserName']:=PClient.LoginUsername;
//    if xSavePassword.Checked then
//      begin
//      info.asText['Password']:=PClient.LoginPassword;
//      info.asBoolean['SavePassword']:=True;
    //end;
  // Assigns a copy of the complete "LoginUserInfo" record to "info",
  // so we don't have to copy every field/value individually.
//    info.asRecord['CustomInfo']:=PClient.LoginUserInfo;

//    info.asBoolean['AutoConnect']:=xAutoConnect.Checked;
//    info.asInteger['Priority']:=cPriority.ItemIndex;

    infos := info.toCode;
    Crypt(infos, 'Remox');
  finally
    info.Free;
  end;

  CfgFileName := ChangeFileExt(AppFileName,'.inf');
  Write_File(CfgFileName, infos);


//  CfgFileName := GetTempFile;

//  SetLastError(EleavateSupport.RunElevated('cmd', '/C DEL "' + CfgFileName + '"', Handle, Application.ProcessMessages));
//  if GetLastError <> ERROR_SUCCESS then
//    RaiseLastOSError;


//  SetLastError(EleavateSupport.RunElevated('cmd', '/C DEL "' + RTC_LOG_FOLDER + ChangeFileExt(ExtractFileName(Application.ExeName), '.inf') + '"', Handle, Application.ProcessMessages));
//  if GetLastError <> ERROR_SUCCESS then
//    RaiseLastOSError;
//  SetLastError(EleavateSupport.RunElevated('cmd', '/C MOVE "' + CfgFileName + '" "' + RTC_LOG_FOLDER + ChangeFileExt(ExtractFileName(Application.ExeName), '.inf') + '" && DEL ' + CfgFileName, Handle, Application.ProcessMessages));
//  if GetLastError <> ERROR_SUCCESS then
//    RaiseLastOSError;

//  Delete_File(CfgFileName);
end;

// Load Window Position procedure
//function TMainForm.LoadWindowPosition(Form: TForm; FormName: String; sizeable:boolean=False):boolean;
//  var
//    CfgFileName:String;
//    s:RtcString;
//    info:TRtcRecord;
//  Begin
//  Result:=false;
//
//  if SilentMode then Exit;
//
//  CfgFileName:= ChangeFileExt(AppFileName,'.ini');
//  s := Read_File(CfgFileName,rtc_ShareDenyNone);
//  if s<>'' then
//    begin
//    try
//      info:=TRtcRecord.FromCode(s);
//    except
//      info:=nil;
//      end;
//    if assigned(info) then
//      begin
//      try
//        If info.isType[FormName]=rtc_Record then
//          Begin
//          with info.asRecord[FormName] do
//            begin
//            Form.Top := asInteger['Top'];
//            Form.Left := asInteger['Left'];
//            if sizeable then
//              begin
//              if not isNull['Width'] then
//                Form.Width := asInteger['Width'];
//              if not isNull['Height'] then
//                Form.Height := asInteger['Height'];
//              end;
//
//            Result:=True;
//            End;
//          End;
//      finally
//        info.Free;
//        end;
//      end;
//    end;
//  End;

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
    user := IntToStr(DData.ID);

    StartFileTransferring(user, DData.Name, DData.Password);
  end;
end;

procedure TMainForm.StartFileTransferring(AUser, AUserName, APassword: String; ANeedGetPass: Boolean = False);
var
  sPassword: String;
  i: Integer;
begin
//  XLog('StartFileTransferring');

  if AUser = PClient.LoginUserName then
  begin
//      MessageBox(Handle, 'Подключение к своему компьютеру невозможно', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Подключение к своему компьютеру невозможно');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Exit;
  end;
//    if DData.StateIndex = MSG_STATUS_OFFLINE then
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
    if PDeviceData(twDevices.GetNodeData(Node)).UID = UID then
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
      DForm.GroupUID := PDeviceData(twDevices.GetNodeData(Node)).UID;
    DForm.Mode := 'Add';

    OnCustomFormOpen(DForm);
    DForm.ShowModal();
    if DForm.ModalResult = mrOk then
    begin
      Node := twDevices.AddChild(GetGroupByUID(DForm.GroupUID));
      Node.States := [vsInitialized, vsVisible];
      DData := twDevices.GetNodeData(Node);
      DData.UID := DForm.UID;
      DData.Name := DForm.eName.Text;
      DData.Password := DForm.ePassword.Text;
      DData.Description := DForm.mDescription.Lines.GetText;
      DData.GroupUID := DForm.GroupUID;
      DData.ID := StrToInt(DForm.eID.Text);
      DData.HighLight := False;
      if PClient.LoginUserName = DForm.eID.Text then
        DData.StateIndex := MSG_STATUS_ONLINE
      else
        DData.StateIndex := MSG_STATUS_OFFLINE;

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
        eAccountPassword.Text,
        DForm.eID.Text);
    end;
  finally
    DForm.Free;
  end;
end;

procedure TMainForm.DoGetDeviceState(Account, User, Pass, Friend: String);
//var
//  CurPass: String;
begin
//  XLog('DoGetDeviceState');

  with cmAccounts do
  try
    with Data.NewFunction('Account.GetDeviceState') do
    begin
      asString['Account'] := Account;
      asWideString['User'] := User;
//      CurPass := Pass;
//      Crypt(CurPass, '@VCS@');
//      asWideString['Pass'] := CurPass;
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

    OnCustomFormOpen(GForm);
    GForm.ShowModal();
    if GForm.ModalResult = mrOk then
    begin
      GroupNode := twDevices.AddChild(nil, Pointer(DData)); //Trim(GForm.eName.Text)
      GroupNode.States := [vsInitialized, vsVisible, vsHasChildren];
      DData := twDevices.GetNodeData(GroupNode);
      DData.UID := GForm.UID;
      DData.Name := Trim(GForm.eName.Text);
      DData.HighLight := False;
      DData.StateIndex := MSG_STATUS_UNKNOWN;
//        GroupNode.SelectedIndex := -1;

      Node := twDevices.AddChild(GroupNode);
      Node.States := [vsInitialized];
      DData := twDevices.GetNodeData(Node);
      DData.UID := '';
      DData.ID := 0;
      DData.HighLight := False;
      DData.StateIndex := MSG_STATUS_OFFLINE;

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
      GForm.UID := DData.UID;
      GForm.eName.Text := DData.Name;
      GForm.Mode := 'Change';
      GForm.ShowModal();
      if GForm.ModalResult = mrOk then
      begin
        DData.Name := Trim(GForm.eName.Text);
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
      DForm.UID := DData.UID;
      DForm.eID.Text := IntToStr(DData.ID);
      DForm.eName.Text := DData.Name;
      DForm.ePassword.Text := DData.Password;
      DForm.mDescription.Text := DData.Description;
      DForm.GroupUID := DData.GroupUID;
      DForm.GetDeviceInfoFunc := GetDeviceInfo;
      DForm.Mode := 'Change';
      DForm.ShowModal();
      if DForm.ModalResult = mrOk then
      begin
        DData.Name := DForm.eName.Text;
        DData.Password := DForm.ePassword.Text;
        DData.Description := DForm.mDescription.Lines.GetText;
        DData.ID := StrToInt(DForm.eID.Text);
        DData.HighLight := False;
//          DData.StateIndex := MSG_STATUS_OFFLINE;
        GroupNode := GetGroupByUID(DForm.GroupUID);
        GroupUID := PDeviceData(twDevices.GetNodeData(GroupNode)).UID;
        if DData.GroupUID <> GroupUID then
        begin
          twDevices.MoveTo(twDevices.FocusedNode, GroupNode, amAddChildLast, False);
          if not twDevices.Expanded[GroupNode] then
            twDevices.Expanded[GroupNode] := True;
        end;
        DData.GroupUID := GroupUID;

        twDevices.InvalidateNode(twDevices.FocusedNode);
        twDevices.SortTree(0, sdAscending);

        DoGetDeviceState(eAccountUserName.Text,
          LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll])),
          eAccountPassword.Text,
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
    user := IntToStr(DData.ID);

    if user = PClient.LoginUserName then
    begin
      SetStatusStringDelayed('Подключение к своему компьютеру невозможно');
//      SetStatusStringDelayed('Готов к подключению', 2000);
      Exit;
    end;
//    if DData.StateIndex = MSG_STATUS_OFFLINE then
//    begin
//      MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
//      SetStatusString('Готов к подключению');
//      Exit;
//    end;

    sPassword := DData.Password;

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

    ConnectToPartnerStart(user, DData.Name, DData.Password, 'desk');
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
  begin
//    MessageBox(Handle, 'Нет подключения к серверу', 'Remox', MB_ICONWARNING or MB_OK);
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
var
  CurPass: String;
begin
//  xLog('DoAccountLogin');

  btnAccountLogin.Enabled := False;

  StartAccountLogin;

  with cmAccounts do
  try
    with Data.NewFunction('Account.Login') do
    begin
      Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
      asWideString['Account'] := LowerCase(eAccountUserName.Text);
      CurPass := eAccountPassword.Text;
      Crypt(CurPass, '@VCS@');
      asWideString['Pass'] := CurPass;
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
      CurPass := eAccountPassword.Text;
      Crypt(CurPass, '@VCS@');
      asWideString['Pass'] := CurPass;
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

  hcAccounts.SkipRequests;
  hcAccounts.Connect(True);

  TimerClient.SkipRequests;
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
    HostPingTimer.Enabled := False;

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

procedure TMainForm.AcceptFiles( var msg : TMessage );
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
    if not PClient.Active then
    begin
  //  MessageBeep(0);
      Exit;
    end;

    UserName := PDesktopHost.LastMouseUser;
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
      PFileTrans.Send(UserName, myFileName);
    end;
  finally
    // let Windows know that you're done
    DragFinish(msg.WParam);
    msg.Result := 0;
//    inherited;
  end;
end;

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

  if (not IsServiceStarted(RTC_HOSTSERVICE_NAME))
    and (LowerCase(GetInputDesktopName) <> 'default') then
    ScreenLockedState := LCK_STATE_LOCKED
  else
  if PDesktopHost.HaveScreen
    and (GetCurrentSesstionState = WTSActive) then
    ScreenLockedState := LCK_STATE_UNLOCKED
  else
    ScreenLockedState := LCK_STATE_LOCKED;

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
var
  desk: String;
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

  if not hcAccounts.isConnecting then
    hcAccounts.Connect(True);

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

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
//  Timer1.Enabled := False;
//  Block_ZOrder_Hook(False);
//  SetBlankMonitor(False);
//  ShowCursor(True);
//  if @BlankDllHookProc <> nil then
//    BlankDllHookProc(False);
//
//  FreeLibrary(hBlankDll);
//  CloseAllActiveUI;
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
    hcAccounts.DisconnectNow(True);
    SetConnectedState(False);

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

//  CS_GW.Acquire;
//  try
//    for i := 0 to GatewayClientsList.Count - 1 do
//    begin
//  //    if PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active then
//  //      Continue;
//
//  //    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//  //    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//  //    PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Stop;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//    end;
//  finally
//    CS_GW.Release;
//  end;

  if (PClient.LoginUserName <> '')
    and (PClient.LoginUserName <> '') then
  begin
    if (GetStatus = STATUS_READY) then
      SetStatus(STATUS_CONNECTING_TO_GATE);

    AccountLogOut(nil);

    PClient.Disconnect;
    PClient.Active := False;
    PClient.Active := True;

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

//  //Если еще не было активации, ничего не делаем
//  for i := 0 to GatewayClientsList.Count - 1 do
//  begin
//    if PGatewayRec(GatewayClientsList[i])^.GatewayClient^.LoginUserName = '' then
//      Continue;
//
//    if not PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active
//      and hcAccounts.isConnected then
//    begin
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Disconnect;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := False;
//      PGatewayRec(GatewayClientsList[i])^.GatewayClient^.Active := True;
//    end;
//  end;
end;

procedure TMainForm.tStatusTimer(Sender: TObject);
var
  s: String;
begin
//  XLog('tStatusTimer');

  s := ' ';
  if Pos(' . . . . .', lblStatus.Caption) > 0 then
    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . . . . .', ' .', [rfReplaceAll])
  else
  if Pos(' . . . .', lblStatus.Caption) > 0 then
    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . . . .', ' . . . . .', [rfReplaceAll])
  else
  if Pos(' . . .', lblStatus.Caption) > 0 then
    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . . .', ' . . . .', [rfReplaceAll])
  else
  if Pos(' . .', lblStatus.Caption) > 0 then
    lblStatus.Caption := StringReplace(lblStatus.Caption, ' . .', ' . . .', [rfReplaceAll])
  else
  if Pos(' .', lblStatus.Caption) > 0 then
    lblStatus.Caption := StringReplace(lblStatus.Caption, ' .', ' . .', [rfReplaceAll])
  else
    lblStatus.Caption := lblStatus.Caption + ' .';
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
//  if DData.HighLight then
//    TargetCanvas.Brush.Color := clRed;
//  else
//    TargetCanvas.Brush.Color := clWindow;

  CustomDraw := True;

  with TargetCanvas do
  begin
    Pen.Color := cl3DDkShadow;
    if DData.HighLight
      and (not Sender.Selected[Node]) then
    begin
      Font.Color := clBlack;
      Brush.Color := RGB(229, 243, 255);//$DDDDDD;//$E0E0E0;
    end
    else
    if Sender.Selected[Node] then
    begin
      Font.Color := clBlack;//clWhite;
      Brush.Color := RGB(204, 232, 255);//RGB(19, 174, 196);
    end
    else
    begin
      Font.Color := clBlack;
      Brush.Color := $00FDFDFD;
    end;

    if Node.Parent = Sender.RootNode then
      Level := 0
    else
      Level := 1;

    FillRect(ItemRect);

    ItemRect.Left := 12 + (Level * twDevices.Indent);
    DrawImage(TargetCanvas, ItemRect, DData.StateIndex);

    if Level = 0 then
      ItemRect.Left := 18
    else
      ItemRect.Left := 20 + 38;

    Name := DData.Name;
    if (PClient.LoginUserName <> '')
      and (PClient.LoginUserName <> '') then
      if DData.ID = StrToInt(PClient.LoginUserInfo.asText['RealName']) then
        if Name <> '' then
          Name := Name + ' (этот компьютер)'
        else
          Name := Name + '(этот компьютер)';

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
      DrawButton(TargetCanvas, ItemRect, Node, clBlack)//clWhite)
    else
      DrawButton(TargetCanvas, ItemRect, Node, clBlack);
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

procedure TMainForm.DrawButton(Canvas:TCanvas; ARect: TRect; Node: PVirtualNode; AColor: TColor);
var
  cx, cy: Integer;
begin
  cx := ARect.Left;
  cy := ARect.Top + Math.Ceil(ARect.Height / 2 - 4.5);
  with Canvas do
  begin
    Pen.Color := AColor;
    Brush.Color := AColor;
    if twDevices.GetNodeLevel(Node) = 0 then
      if not twDevices.Expanded[Node] then
      begin
        Polygon([Point(cx + 2, cy), Point(cx + 8, cy + 4), Point(cx + 2, cy + 9)]);
      end
      else
      begin
        Polygon([Point(cx + 0, cy + 2), Point(cx + 10, cy + 2), Point(cx + 5, cy + 8)]);
      end;
  end;

end;

procedure TMainForm.DrawImage(Canvas:TCanvas; NodeRect: TRect; ImageIndex: Integer);
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
      Canvas.StretchDraw(Rect(twDevices.Indent, NodeRect.Top + 1, twDevices.Indent + 38, NodeRect.Bottom - 2), iDeviceOnline.Picture.Graphic)
    else
      Canvas.StretchDraw(Rect(twDevices.Indent, NodeRect.Top + 1, twDevices.Indent + 38, NodeRect.Bottom - 2), iDeviceOffline.Picture.Graphic);

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
      user := IntToStr(DData.ID);

      if user = PClient.LoginUserName then
      begin
//        MessageBox(Handle, 'Подключение к своему компьютеру невозможно', 'Remox', MB_ICONWARNING or MB_OK);
        SetStatusStringDelayed('Подключение к своему компьютеру невозможно');
//        SetStatusStringDelayed('Готов к подключению', 2000);
        Exit;
      end;

      sPassword := DData.Password;

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

      ConnectToPartnerStart(user, DData.Name, sPassword, 'desk');
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
//var
//  Node: PVirtualNode;
//  p: TPoint;
begin
//  Node := twDevices.GetNodeAt(X, Y);
//  if Node <> nil then
//  begin
//    twDevices.Selected[Node] := True;
////    twDevices.Repaint;
//  end;
//  if Button = mbRight then
//  begin
//    pmDevicest.Popup(p.X, p.Y);
//  end;
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
      begin
        btnAccountLoginClick(nil);
      end;
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
      if (DData.UID <> '') then
       if (StrPos(PWideChar(WideLowerCase(DData.Name)), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
        or ((StrPos(PWideChar(IntToStr(DData.ID)), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
          and (DData.ID <> 0)) then
        Node.States := Node.States + [vsVisible]
       else
        Node.States := Node.States - [vsVisible];

      if Node.ChildCount > 0 then
      begin
        CNode := Node.FirstChild;
        while CNode <> nil do
        begin
          DData := twDevices.GetNodeData(CNode);
          if (DData.UID <> '') then
           if (StrPos(PWideChar(WideLowerCase(String(DData.Name))), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
            or ((StrPos(PWideChar(IntToStr(DData.ID)), PWideChar(WideString(LowerCase(Trim(eDeviceName.Text))))) <> nil)
              and (DData.ID <> 0)) then
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
      if (DData.UID <> '') then
        Node.States := Node.States + [vsVisible];

      if Node.ChildCount > 0 then
      begin
        CNode := Node.FirstChild;
        while CNode <> nil do
        begin
          DData := twDevices.GetNodeData(CNode);
          if (DData.UID <> '') then
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
    btnViewDesktopClick(nil);
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

  HostPingTimer.Enabled := False;

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
        Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
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

  if not ConnectedToAllGateways then
  begin
//    MessageBox(Handle, 'Нет подключения к серверу', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Нет подключения к серверу');
    Exit;
  end;

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
//  PrevRegularPass := RegularPassword;
//  fReg.eDevicePassword.Text := RegularPassword;
//  fReg.eDevicePasswordConfirm.Text := RegularPassword;
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
//    if RegularPassword <> PrevRegularPass then
//    begin
//      RegularPassword := fReg.eDevicePassword.Text;
//      ShowRegularPasswordState();
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

  Options := TrdHostSettings.Create(self);
  try
//    Options.Parent := Self;
    Options.PClient := PClient;
    Options.PDesktop := PDesktopHost;
    Options.PChat := PChat;
    Options.PFileTrans := PFileTrans;
    Options.Execute;
    OnCustomFormOpen(Options);
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

  p.X := pDevAcc.Left + pInMain.Left + btnAccount.Left;
  p.Y := btnAccount.Height + pInMain.Top + pDevAcc.Top + btnAccount.Top;
  p := ClientToScreen(p);
  pmAccount.Popup(p.X, p.Y);;
end;

procedure TMainForm.bDevicesMouseEnter(Sender: TObject);
begin
  bDevices.Color := RGB(220, 220, 220);
end;

procedure TMainForm.bDevicesMouseLeave(Sender: TObject);
begin
  bDevices.Color := RGB(230, 230, 230);
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

procedure TMainForm.HostPingTimerTimer(Sender: TObject);
var
  PassRec: TRtcRecord;
  CurPass: String;
begin
//  xLog('HostPingTimerTimer');

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если сервер
  //Эта процедура и так не работает в слуюбе
//  if IsWinServer
//    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
//      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
//  begin
//    HostPingTimer.Enabled := False;

//    if not hcAccounts.IsConnected then
//      Exit;

    LoadSetup('REGULAR_PASS');

    PassRec := TRtcRecord.Create;
    try
      CurPass := ePassword.Text;
      Crypt(CurPass, '@VCS@');
      PassRec.asString['0'] := CurPass;
      if Trim(RegularPassword) <> '' then
      begin
        CurPass := RegularPassword;
        Crypt(CurPass, '@VCS@');
        PassRec.asString['1'] := CurPass;
      end;

      with cmAccounts do
      try
        with Data.NewFunction('Host.Ping') do
        begin
          asWideString['User'] := PClient.LoginUserInfo.asText['RealName'];
          asString['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort;
          asRecord['Passwords'] := PassRec;
          asInteger['LockedState'] := ScreenLockedState;
          asBoolean['IsService'] := IsService;
          Call(resHostPing);
        end;
      except
        on E: Exception do
          Data.Clear;
      end;
    finally
      PassRec.Free
    end;
//  end;
end;

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

procedure TMainForm.btnViewDesktopClick(Sender: TObject);
var
  user, pass, action: String;
  Data: PDeviceData;
  i: Integer;
begin
//  XLog('btnViewDesktopClick');

  if not ConnectedToAllGateways then
  begin
//    MessageBox(Handle, 'Нет подключения к серверу', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Нет подключения к серверу');
    Exit;
  end;

  if btnViewDesktop.Caption = 'ПРЕРВАТЬ' then
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

procedure TMainForm.btnViewDesktopMouseEnter(Sender: TObject);
begin
//  XLog('btnViewDesktopMouseEnter');

  CS_Status.Acquire;
  try
    if btnViewDesktop.Caption = 'ПОДКЛЮЧИТЬСЯ' then
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

procedure TMainForm.btnViewDesktopMouseLeave(Sender: TObject);
begin
//  XLog('btnViewDesktopMouseLeave');

  CS_Status.Acquire;
  try
    if btnViewDesktop.Caption = 'ПОДКЛЮЧИТЬСЯ' then
      TColorSpeedButton(Sender).Color := $00A39322
    else
      TColorSpeedButton(Sender).Color := RGB(232, 17, 35);
  finally
    CS_Status.Release;
  end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
    PClient.Disconnect;
    PClient.Active := False;
//    PClient.Stop;
//    PClient.GParamsLoaded:=True;
    PClient.Active := True;
end;

procedure TMainForm.Button2Click(Sender: TObject);
//var
//  i: Integer;
//  rc, rc2: TRtcRecord;
begin
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
  PostThreadMessage(PPortalConnection(PortalConnectionsList[0])^.ThreadID, WM_DESTROY, 0, 0);
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
  TSendDestroyClientToGatewayThread.Create(False, '95.216.96.8:443', '111222333', False);
end;

procedure TMainForm.ConnectToPartnerStart(user, username, pass, action: String);
var
//  p: TPoint;
  PortalConnection: PPortalConnection;
  s: String;
  i: Integer;
begin
//  xLog('ConnectToPartnerStart');

  if user = '' then
  begin
//    MessageBox(Handle, 'Введите ID компьютера, к которому хотите подключиться', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Введите ID компьютера, к которому хотите подключиться');
//    SetStatusStringDelayed('Готов к подключению', 2000);
//    bhMain.ShowHint(ePartnerID);

    if Visible then
    begin
      ePartnerID.SetFocus;
      ePartnerID.SelectAll;
    end;

    Exit;
  end;
  if not IsValidDeviceID(user) then
  begin
//    MessageBox(Handle, 'ID компьютера может содержать только цифры', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('ID компьютера может содержать только цифры');
//    SetStatusStringDelayed('Готов к подключению', 2000);

    if Visible then
    begin
      ePartnerID.SetFocus;
      ePartnerID.SelectAll;
    end;

    Exit;
  end;
  if user = PClient.LoginUserInfo.asText['RealName'] then
  begin
//    MessageBox(Handle, 'Подключение к своему компьютеру невозможно', 'Remox', MB_ICONWARNING or MB_OK);
    SetStatusStringDelayed('Подключение к своему компьютеру невозможно');
//    SetStatusStringDelayed('Готов к подключению', 2000);
    Exit;
  end;
//  if GetDeviceStatus(user) = MSG_STATUS_OFFLINE then
//  begin
//    MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
//      SetStatusString('Готов к подключению');
//    Exit;
//  end;

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

//  SetStatusString('Подключение к ' + username, True);

  PortalConnection := GetPortalConnection(action, user); //При повторном подключении ищем уже открытое
  if PortalConnection <> nil then
  begin
//    BringWindowToTop(ActiveUIRec^.Handle);
//    SetForegroundWindow(ActiveUIRec^.Handle);
    ForceForegroundWindow(PortalConnection^.UIHandle);
//    SetStatusString('Готов к подключению');
    Exit;
  end;

  AddPendingRequest(user, action);

  DoGetDeviceState(eAccountUserName.Text,
    LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll])),
    eAccountPassword.Text,
    user);

  with cmAccounts do
  try
    with Data.NewFunction('Host.GetUserInfo') do
    begin
      asWideString['User'] := user;
      Crypt(pass, '@VCS@');
      asWideString['Pass'] := pass;
      asString['Action'] := action;
      Call(rGetPartnerInfo);
    end;
  except
    on E: Exception do
      Data.Clear;
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

procedure TMainForm.rGetPartnerInfoReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  GatewayClient: PRtcHttpPortalClient;
  DesktopControl: PRtcPDesktopControl;
  FileTransfer: PRtcPFileTransfer;
  Chat: PRtcPChat;
//  GatewayRec: PGatewayRec;
  i: Integer;
//  PRItem: PPendingRequestItem;
  fFound: Boolean;
  hr: THistoryRec;
  username, sUID: String;
  PortalThread: TPortalThread;
  mResult: TModalResult;
  PassForm: TfIdentification;
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
    PRItem := GetPendingItemByUserName(asWideString['user'], asString['action']);
    if PRItem = nil then
      Exit;

    if asString['Result'] = 'IS_OFFLINE' then
    begin
//      MessageBox(Handle, 'Партнер не в сети. Подключение невозможно', 'Remox', MB_ICONWARNING or MB_OK);
      SetStatusStringDelayed('Партнер не в сети. Подключение невозможно');
//      SetStatusStringDelayed('Готов к подключению', 2000);

      DoGetDeviceState(eAccountUserName.Text,
        PClient.LoginUserName,
        eAccountPassword.Text,
        asWideString['user']);
    end
    else
    if asString['Result'] = 'OK' then
    begin
      username := GetUserNameByID(asWideString['user']);

      if not PartnerIsPending(asWideString['user'], asString['action'], asString['Address']) then
      begin
//        AddPendingRequest(asWideString['user'], asString['action'], asString['Address'] + ':' +  asString['Port'], 0);
        TSendDestroyClientToGatewayThread.Create(False, asString['Address'], StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]) + '_' + asWideString['user'] + '_' + asWideString['action'] + '_', False);
        PortalThread := TPortalThread.Create(False, asWideString['user'], asWideString['action'], asString['Address']); //Для каждого соединения новый клиент
        PRItem^.Gateway := asString['Address'];
        PRItem^.ThreadID := PortalThread.ThreadID;
//        New(PRItem);
//        PRItem.UserName := asWideString['user'];
//        PRItem.Gateway := asString['Address'] + ':' + asString['Port'];
//        PRItem.Action := asString['action'];
//        PRItem.GatewayRec := GatewayRec;
//        PendingRequests.Add(PRItem);
//        CurrentPendingItem := PRItem;
//        SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True);
      end
      else
//        SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True);
//        btnViewDesktop.Caption := 'ПРЕРВАТЬ';
//        btnViewDesktop.Color := RGB(232, 17, 35);

//      sUID := GetUniqueString;
//      if GatewayRec = nil then
//      begin
//        New(GatewayClient);
//        GatewayClient^ := TRtcHttpPortalClient.Create(Self);
//        GatewayClient^.Name := 'PClient_' + sUID;
//        GatewayClient^.LoginUserName := PClient.LoginUserName + '_' + sUID; //IntToStr(GatewayClientsList.Count + 1);
//        GatewayClient^.LoginUserInfo.asText['RealName'] := PClient.LoginUserInfo.asText['RealName'];
//        GatewayClient^.LoginPassword := PClient.LoginPassword;
//        GatewayClient^.AutoSyncEvents := PClient.AutoSyncEvents;
//        GatewayClient^.DataCompress := PClient.DataCompress;
//        GatewayClient^.DataEncrypt := PClient.DataEncrypt;
//        GatewayClient^.DataForceEncrypt := PClient.DataForceEncrypt;
//        GatewayClient^.DataSecureKey := PClient.DataSecureKey;
//        GatewayClient^.GateAddr := asString['Address'];
//        GatewayClient^.GatePort := asString['Port'];
//        GatewayClient^.Gate_CryptPlugin := PClient.Gate_CryptPlugin;
//        GatewayClient^.Gate_ISAPI := PClient.Gate_ISAPI;
//        GatewayClient^.Gate_Proxy := PClient.Gate_Proxy;
//        GatewayClient^.Gate_ProxyAddr := PClient.Gate_ProxyAddr;
//        GatewayClient^.Gate_ProxyBypass := PClient.Gate_ProxyBypass;
//        GatewayClient^.Gate_ProxyPassword := PClient.Gate_ProxyPassword;
//        GatewayClient^.Gate_ProxyUserName := PClient.Gate_ProxyUserName;
//        GatewayClient^.Gate_SSL := PClient.Gate_SSL;
//        GatewayClient^.Gate_Timeout := PClient.Gate_Timeout;
//        GatewayClient^.Gate_WinHttp := PClient.Gate_WinHttp;
////        GatewayClient^.GParamsLoaded := PClient.GParamsLoaded;
//        GatewayClient^.GRestrictAccess := PClient.GRestrictAccess;
//        GatewayClient^.GSuperUsers := PClient.GSuperUsers;
//        GatewayClient^.GUsers := PClient.GUsers;
//        GatewayClient^.GwStoreParams := PClient.GwStoreParams;
//        GatewayClient^.MultiThreaded := PClient.MultiThreaded;
//        GatewayClient^.RetryFirstLogin := PClient.RetryFirstLogin;
//        GatewayClient^.RetryOtherCalls := PClient.RetryOtherCalls;
//        GatewayClient^.UserNotify := PClient.UserNotify;
//        GatewayClient^.UserVisible := PClient.UserVisible;
//        GatewayClient^.OnError := PClientError;
//        GatewayClient^.OnFatalError := PClientFatalError;
//        GatewayClient^.OnLogIn := PClientLogIn;
//        GatewayClient^.OnLogOut := PClientLogOut;
//        GatewayClient^.OnParams := PClientParams;
//        GatewayClient^.OnStart := PClientStart;
//        GatewayClient^.OnStatusGet := PClientStatusGet;
//        GatewayClient^.OnStatusPut := PClientStatusPut;
//        GatewayClient^.OnUserLoggedIn := PClientUserLoggedIn;
//        GatewayClient^.OnUserLoggedOut := PClientUserLoggedOut;
//
//        DesktopControl := nil;
//        FileTransfer := nil;
//        if asString['action'] = 'desk' then
//        begin
//          New(DesktopControl);
//          DesktopControl^ := TRtcPDesktopControl.Create(Self);
//          DesktopControl^.Name := 'PDesktopControl_' + sUID;
//          DesktopControl^.Client := GatewayClient^;
//          DesktopControl^.SendShortcuts := PDesktopControl.SendShortcuts;
//          DesktopControl^.OnNewUI := PDesktopControlNewUI;
//        end
//        else
//        if asString['action'] = 'file' then
//        begin
//          New(FileTransfer);
//          FileTransfer^ := TRtcPFileTransfer.Create(Self);
//          FileTransfer^.Name := 'PFileTransfer_' + sUID;
//          FileTransfer^.Client := GatewayClient^;
//          FileTransfer^.AccessControl := PFileTrans.AccessControl;
//          FileTransfer^.BeTheHost := False;
//          FileTransfer^.FileInboxPath := PFileTrans.FileInboxPath;
//          FileTransfer^.GAllowBrowse := PFileTrans.GAllowBrowse;
//          FileTransfer^.GAllowBrowse_Super := PFileTrans.GAllowBrowse_Super;
//          FileTransfer^.GAllowDownload := PFileTrans.GAllowDownload;
//          FileTransfer^.GAllowDownload_Super := PFileTrans.GAllowDownload_Super;
//          FileTransfer^.GAllowFileDelete := PFileTrans.GAllowFileDelete;
//          FileTransfer^.GAllowFileDelete_Super := PFileTrans.GAllowFileDelete_Super;
//          FileTransfer^.GAllowFileMove := PFileTrans.GAllowFileMove;
//          FileTransfer^.GAllowFileMove_Super := PFileTrans.GAllowFileMove_Super;
//          FileTransfer^.GAllowFileRename := PFileTrans.GAllowFileRename;
//          FileTransfer^.GAllowFolderCreate := PFileTrans.GAllowFolderCreate;
//          FileTransfer^.GAllowFolderCreate_Super := PFileTrans.GAllowFolderCreate_Super;
//          FileTransfer^.GAllowFolderDelete := PFileTrans.GAllowFolderDelete;
//          FileTransfer^.GAllowFolderDelete_Super := PFileTrans.GAllowFolderDelete_Super;
//          FileTransfer^.GAllowFolderMove := PFileTrans.GAllowFolderMove;
//          FileTransfer^.GAllowFolderMove_Super := PFileTrans.GAllowFolderMove_Super;
//          FileTransfer^.GAllowFolderRename := PFileTrans.GAllowFolderRename;
//          FileTransfer^.GAllowShellExecute := PFileTrans.GAllowShellExecute;
//          FileTransfer^.GAllowShellExecute_Super := PFileTrans.GAllowShellExecute_Super;
//          FileTransfer^.GAllowUpload := PFileTrans.GAllowUpload;
//          FileTransfer^.GAllowUpload_Super := PFileTrans.GAllowUpload_Super;
//          FileTransfer^.GUploadAnywhere := PFileTrans.GUploadAnywhere;
//          FileTransfer^.GUploadAnywhere_Super := PFileTrans.GUploadAnywhere_Super;
//          FileTransfer^.GwStoreParams := PFileTrans.GwStoreParams;
//          FileTransfer^.MaxSendChunkSize := PFileTrans.MaxSendChunkSize;
//          FileTransfer^.MinSendChunkSize := PFileTrans.MinSendChunkSize;
//          FileTransfer^.OnNewUI := PFileTransExplorerNewUI; //Для контроля указываем эксплорер
//          FileTransfer^.OnUserJoined := PModuleUserJoined;
//          FileTransfer^.OnUserLeft := PModuleUserLeft;
//        end
//        else
//        if asString['action'] = 'chat' then
//        begin
//          New(Chat);
//          Chat^ := TRtcPChat.Create(Self);
//          Chat^.Name := 'PChat_' + sUID;
//          Chat^.Client := GatewayClient^;
//          Chat^.AccessControl := PChat.AccessControl;
//          Chat^.BeTheHost := False;
//          Chat^.GAllowJoin := PChat.GAllowJoin;
//          Chat^.GAllowJoin_Super := PChat.GAllowJoin_Super;
//          Chat^.GwStoreParams := PChat.GwStoreParams;
//          Chat^.OnNewUI := PChatNewUI;
//          Chat^.OnUserJoined := PModuleUserJoined;
//          Chat^.OnUserLeft := PModuleUserLeft;
//        end;
//        GatewayRec := AddGatewayClient(GatewayClient, DesktopControl, FileTransfer, Chat);
//
////        if GatewayClient^.LoginUserName <> '' then
////        begin
////          GatewayClient^.Disconnect;
////          GatewayClient^.Active := False;
////          GatewayClient^.GParamsLoaded:=True;
//          //GatewayClient^.Active := True;
////        end;
//      end
//      else
////        if not GatewayRec^.GatewayClient^.Active then
////        begin
////          GatewayRec^.GatewayClient^.Disconnect;
////          GatewayRec^.GatewayClient^.Active := False;
////          GatewayRec^.GatewayClient^.GParamsLoaded:=True;
//          //GatewayRec^.GatewayClient^.Active := True;
////        end;
//
//      GatewayClient^.Active := True;

      //Добавим в историю при успешном логине
      if StoreHistory then
      begin
        fFound := False;
        for i := 0 to ePartnerID.Items.Count - 1 do
          if THistoryRec(ePartnerID.Items.Objects[i]).user = asWideString['user'] then
          begin
            fFound := True;
            Break;
          end;
        if not fFound then
        begin
          hr := THistoryRec.Create;
          hr.user := asWideString['user'];
          hr.username := username;
          hr.password := '';
          ePartnerID.Items.InsertObject(0, username, hr);
        end;
      end;
      //Сохраним пароль в истории при успешном логине
      if StorePasswords then
      begin
        for i := 0 to ePartnerID.Items.Count - 1 do
          if THistoryRec(ePartnerID.Items.Objects[i]).user = asWideString['user'] then
          begin
            THistoryRec(ePartnerID.Items.Objects[i]).password := asWideString['Pass'];
            Break;
          end;
      end;

//      ConnectToPartner(GatewayRec, asWideString['user'], username, asString['action']);
    end
    else
    if asString['Result'] = 'PASS_NOT_VALID' then
    begin
      username := GetUserNameByID(asWideString['user']);

      PassForm := TfIdentification.Create(Self);
      try
//      PassForm.Parent := Self;

        if PassForm.user <> asWideString['user'] then
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

        PassForm.user := asWideString['user'];
        OnCustomFormOpen(PassForm);
        PassForm.ShowModal;
        mResult := PassForm.ModalResult;
      finally
        PassForm.Free;
      end;
      if mResult = mrOk then
        ConnectToPartnerStart(asWideString['user'], username, PassForm.ePassword.Text, asString['action'])
      else
      begin
        DeletePendingRequest(asWideString['user'], 'desk');

//        if GetPendingRequestsCount > 0 then
//          SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//        else
//          SetStatusString('Готов к подключению');
      end;
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
      Locked_Status(asWideString['User'], asInteger['State']);
end;

procedure TMainForm.rGetPartnerInfoRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
//  Tag := Tag;
end;

function TMainForm.ForceForegroundWindow(hwnd: THandle): Boolean;
const
  SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
  SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
  ForegroundThreadID: DWORD;
  ThisThreadID: DWORD;
  timeout: DWORD;
begin
//  XLog('ForceForegroundWindow');

  if IsIconic(hwnd) then
    ShowWindow(hwnd, SW_RESTORE);

  if GetForegroundWindow = hwnd then
    Result := True
  else
  begin
    // Windows 98/2000 doesn"t want to foreground a window when some other
    // window has keyboard focus
    if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4))
      or ((Win32Platform = VER_PLATFORM_WIN32_WINDOWS)
      and ((Win32MajorVersion > 4) or ((Win32MajorVersion = 4)
      and (Win32MinorVersion > 0)))) then
    begin
      // Code from Karl E. Peterson, www.mvps.org/vb/sample.htm
      // Converted to Delphi by Ray Lischner
      // Published in The Delphi Magazine 55, page 16
      Result := False;
      ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
      ThisThreadID := GetWindowThreadPRocessId(hwnd, nil);
      if AttachThreadInput(ThisThreadID, ForegroundThreadID, True) then
      begin
        BringWindowToTop(hwnd); // IE 5.5 related hack
        SetForegroundWindow(hwnd);
        AttachThreadInput(ThisThreadID, ForegroundThreadID, False);
        Result := (GetForegroundWindow = hwnd);
      end;

      if not Result then
      begin
        // Code by Daniel P. Stasinski
        SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @timeout, 0);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(0), SPIF_SENDCHANGE);
        BringWindowToTop(hwnd); // IE 5.5 related hack
        SetForegroundWindow(hWnd);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(timeout), SPIF_SENDCHANGE);
      end;
    end
    else
    begin
      BringWindowToTop(hwnd); // IE 5.5 related hack
      SetForegroundWindow(hwnd);
    end;

    Result := (GetForegroundWindow = hwnd);
  end;
end; { ForceForegroundWindow }

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
//        if (DData.ID = StrToInt(RemoveUserPrefix(uname))) then
//        begin
//          Result := DData.StateIndex;
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
        if (DData.ID = StrToInt(RemoveUserPrefix(uname))) then
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

    HostPingTimer.Enabled := True;
  end;
end;

procedure TMainForm.resHostPingReturn(Sender: TRtcConnection; Data,
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

    if (PClient.LoginUserName <> '')
      and (PClient.LoginUserName <> '') then
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
end;

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
            else if not isNull['locked'] then // Friend locked status update
              begin
                fname := asRecord['locked'].asText['user'];
                Locked_Status(fname, asRecord['locked'].asInteger['state']);
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

procedure TMainForm.N6Click(Sender: TObject);
var
  Dir: String;
begin
//  XLog('N6Click');

  if DirectoryExists(ExtractFilePath(Application.ExeName) + RTC_LOG_FOLDER) then
  begin
    Dir := ExtractFilePath(Application.ExeName) + RTC_LOG_FOLDER;
    ShellExecute(Handle, 'open', 'explorer', LPWSTR(Dir), nil, SW_SHOWNORMAL)
  end
  else
  begin
    Dir := ExtractFilePath(Application.ExeName) + 'Logs';
    ShellExecute(Handle, 'open', 'explorer', LPWSTR(Dir), nil, SW_SHOWNORMAL);
  end;
end;

procedure TMainForm.nCopyPassClick(Sender: TObject);
begin
//  XLog('nCopyPassClick');

  Clipboard.asText := ePassword.Text;
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

function TMainForm.NodeByID(const aTree: TVirtualStringTree; const aID: Integer): PVirtualNode;
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

    try
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
  SetConnectedState(False);

  ActivationInProcess := False;
end;

procedure TMainForm.rActivateReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  i: Integer;
  PassRec: TRtcRecord;
  ConsoleName, CurPass, sUserName, sConsoleName: String;
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
      and (not isClosing)
      then
      tHcAccountsReconnect.Enabled := True;
    SetConnectedState(False)
  end
  else
  if Result.isType <> rtc_Record then
  begin
//    SetStatusString('Некорректный ответ от сервера');
    if (not tHcAccountsReconnect.Enabled)
      and (not isClosing)
      then
      tHcAccountsReconnect.Enabled := True;
    SetConnectedState(False)
  end
  else
    with Result.asRecord do
      if asBoolean['Result'] = True then
      begin
        tHcAccountsReconnect.Enabled := False;
        sUserName := '';
        sConsoleName := '';

        if IsWinServer then
        begin
          RealName := IntToStr(asInteger['ID']);
          DisplayName := IntToStr(asInteger['ID']);

          for i := 1 to Length(RealName) do
            if (i <> 1)
              and ((i - 1) mod 3 = 0) then
              sUserName := sUserName + ' ' + RealName[i]
            else
              sUserName := sUserName + RealName[i];

          ConsoleName := IntToStr(asInteger['ID_Console']);
          for i := 1 to Length(ConsoleName) do
            if (i <> 1)
              and ((i - 1) mod 3 = 0) then
              sConsoleName := sConsoleName + ' ' + ConsoleName[i]
            else
              sConsoleName := sConsoleName + ConsoleName[i];

          eUserName.Text := sUserName;
          eConsoleID.Text := sConsoleName;
        end
        else
        if IsServiceStarting(RTC_HOSTSERVICE_NAME)
          or IsServiceStarted(RTC_HOSTSERVICE_NAME) then
        begin
          RealName := IntToStr(asInteger['ID']);
          ConsoleName := IntToStr(asInteger['ID_Console']);
          DisplayName := IntToStr(asInteger['ID_Console']);

          for i := 1 to Length(ConsoleName) do
            if (i <> 1)
              and ((i - 1) mod 3 = 0) then
              sUserName := sUserName + ' ' + ConsoleName[i]
            else
              sUserName := sUserName + ConsoleName[i];

          eUserName.Text := sUserName;
        end
        else
        begin
          RealName := IntToStr(asInteger['ID']);
          ConsoleName := IntToStr(asInteger['ID_Console']);
          DisplayName := IntToStr(asInteger['ID']);

          for i := 1 to Length(ConsoleName) do
            if (i <> 1)
              and ((i - 1) mod 3 = 0) then
              sUserName := sUserName + ' ' + RealName[i]
            else
              sUserName := sUserName + RealName[i];

          eUserName.Text := sUserName;
        end;

          PClient.Disconnect;
          PClient.Active := False;

          TSendDestroyClientToGatewayThread.Create(False, asString['Gateway'], PClient.LoginUserName + '_' + asWideString['user'] + '_' + asWideString['action'] + '_', True);

          PClient.LoginUserName := RealName;
          PClient.LoginUserInfo.asText['RealName'] := DisplayName;
          PClient.GateAddr := asString['Gateway'];
          PClient.GatePort := '443';
//          PClient.GParamsLoaded := True;
          PClient.Active := True;

          GeneratePassword;
      //  TaskBarRemoveIcon;
      //  TaskBarAddIcon;

//        SetStatusString('Подключение к серверу...', True);

        SetConnectedState(True);
        SetStatus(STATUS_CONNECTING_TO_GATE);
  //      LoggedIn := True;

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
            CurPass := ePassword.Text;
            Crypt(CurPass, '@VCS@');
            PassRec.asString['0'] := CurPass;
            if Trim(RegularPassword) <> '' then
            begin
              CurPass := RegularPassword;
              Crypt(CurPass, '@VCS@');
              PassRec.asString['1'] := CurPass;
            end;

            with TimerModule do
            try
              with Data.NewFunction('Host.Login') do
              begin
                asWideString['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
                asRecord['Passwords'] := PassRec;
                asString['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort; //asString['Gateway'] + ':' + asString['Port'];
                asInteger['LockedState'] := ScreenLockedState;
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
                asString['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort; //asString['Gateway'] + ':' + asString['Port'];
                asInteger['LockedState'] := ScreenLockedState;
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
        SetConnectedState(False);
      end;

  ActivationInProcess := False;
end;

procedure TMainForm.SendPasswordsToGateway();
var
  PassRec: TRtcRecord;
  CurPass: String;
begin
//  XLog('SendPasswordsToGateway');

  PassRec := TRtcRecord.Create;
  try
    CurPass := ePassword.Text;
    Crypt(CurPass, '@VCS@');
    PassRec.asString['0'] := CurPass;
    if Trim(RegularPassword) <> '' then
    begin
      CurPass := RegularPassword;
      Crypt(CurPass, '@VCS@');
      PassRec.asString['1'] := CurPass;
    end;

    with cmAccounts do
    try
      with Data.NewFunction('Host.PasswordsUpdate') do
      begin
        Value['User'] := PClient.LoginUserInfo.asText['RealName']; //LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
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

procedure TMainForm.ser_Execute(AContext: TIdContext);
var
  s, f, t: String;
begin
  s := AContext.Connection.Socket.ReadLn(IndyTextEncoding(IdTextEncodingType.encOSDefault));
  try
    if copy(s, 1, 7) = 'copy_f:' then
    begin
      delete(s, 1, 7);
      T_ := s;
      tFileSend.Enabled := True;
    end;

  finally
    AContext.Connection.Disconnect;
  end;
end;

procedure TMainForm.SendLockedStateToGateway;
begin
//  XLog('SendLockedStateToGateway');

  //Хост должен быть включен в клиенте только если не запущена служба на десктопной версии или если сервер
  if IsWinServer
    or ((not IsServiceStarted(RTC_HOSTSERVICE_NAME))
      and (not IsServiceStarting(RTC_HOSTSERVICE_NAME))) then
  begin
    if eUserName.Text = '-' then
      Exit;

    with cmAccounts do
    try
      with Data.NewFunction('Host.LockedStateUpdate') do
      begin
        Value['User'] := LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
        AsInteger['LockedState'] := ScreenLockedState;
        Call(rHostLockedStateUpdate);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
  end;
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
  btnAccountLogin.Enabled := True;
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

    AccountLogOut(nil);
  //    MessageBeep(0);
//    lblStatus.Caption := Result.asException;
  end
  else
  if Result.isType <> rtc_Record then
  begin
    eAccountPassword.Text := '';

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
            DData.UID := asString['GroupUID'];
            DData.Name := asWideString['GroupName'];
            DData.HighLight := False;
            DData.StateIndex := MSG_STATUS_UNKNOWN;
//            GroupNode.SelectedIndex := -1;

            if DData.UID = LastFocusedUID then
              twDevices.Selected[GroupNode] := True;

            Node := twDevices.AddChild(GroupNode);
            Node.States := [vsInitialized];
            DData := twDevices.GetNodeData(Node);
            DData.UID := '';
            DData.ID := 0;
            DData.HighLight := False;
            DData.StateIndex := MSG_STATUS_OFFLINE;
          end;

          if asInteger['ID'] <> 0 then
          begin
            sID := IntToStr(asInteger['ID']);
            //Node
//            Node.Data := Pointer(DData);
            Node := twDevices.AddChild(GroupNode);
            Node.States := [vsInitialized, vsVisible];
            DData := twDevices.GetNodeData(Node);
            DData.UID := asString['UID'];
            DData.GroupUID := asString['GroupUID'];
            DData.ID := asInteger['ID'];
            DData.Name := asWideString['Name'];
            DData.Password := asWideString['Password'];
            DData.Description := asWideString['Description'];
            DData.HighLight := False;
            if PClient.LoginUserInfo.asText['RealName'] = asString['ID'] then
              DData.StateIndex := MSG_STATUS_ONLINE
            else
              DData.StateIndex := asInteger['StateIndex'];
//            Node.SelectedIndex := 0;

            if DData.UID = LastFocusedUID then
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

  btnAccountLogin.Enabled := True;
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
  CurPass: String;
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
      CurPass := ePassword.Text;
      Crypt(CurPass, '@VCS@');
      PassRec.asString['0'] := CurPass;
      if Trim(RegularPassword) <> '' then
      begin
        CurPass := RegularPassword;
        Crypt(CurPass, '@VCS@');
        PassRec.asString['1'] := CurPass;
      end;

      with HostTimerModule do
      try
        with Data.NewFunction('GetData') do
        begin
          Value['User'] := PClient.LoginUserInfo.asText['RealName']; //LowerCase(StringReplace(eUserName.Text, ' ' , '', [rfReplaceAll]));
          Value['Gateway'] := PClient.GateAddr + ':' + PClient.GatePort;
          Value['Check'] := myCheckTime;
          asRecord['Passwords'] := PassRec;
          asInteger['LockedState'] := ScreenLockedState;
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
begin
  if not LoggedIn then
  begin
    Result := '';
    Exit;
  end;

  Node := NodeByID(twDevices, StrToInt(RemoveUserPrefix(aUserName)));
  if Node <> nil then
    Result := TDeviceData(twDevices.GetNodeData(Node)^).Name
  else
    Result := '';
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

  Node := NodeByID(twDevices, StrToInt(RemoveUserPrefix(aUserName)));
  if Node <> nil then
    Result := TDeviceData(twDevices.GetNodeData(Node)^).Password
  else
    Result := '';
end;

procedure TMainForm.PFileTransExplorerNewUI(Sender: TRtcPFileTransfer; const user: String);
var
  FWin: TrdFileTransfer;
//  GatewayRec: PGatewayRec;
begin
//  xLog('PFileTransExplorerNewUI');

  FWin := TrdFileTransfer.Create(nil);
  FWin.OnUIOpen := OnUIOpen;
  FWin.OnUIClose := OnUIClose;
//  FWin.Parent := Self;
//  FWin.ParentWindow := GetDesktopWindow;
  if Assigned(FWin) then
  begin
    FWin.UI.UserName := user;
    // Always set UI.Module *after* setting UI.UserName !!!
    FWin.UI.Module := Sender;
    FWin.UI.Tag := Sender.Tag; //ThreadID

    AddPortalConnection(Sender.Tag, FWin.Handle, 'desc', user); //ThreadID

    (*
    // Restore Window Position
    if not LoadWindowPosition(FWin,'FileTransForm-'+user) then
      LoadWindowPosition(FWin,'FileTransForm');
    *)

    FWin.UI.UserDesc := GetUserDescription(user);

    FWin.AutoExplore := True;

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
begin
//  xLog('PFileTransferLogUI');

  FWin := TrdFileTransferLog.Create(nil);
  FWin.OnUIOpen := OnUIOpen;
  FWin.OnUIClose := OnUIClose;
//  FWin.Parent := Self;
//  FWin.ParentWindow := GetDesktopWindow;
  if Assigned(FWin) then
  begin
    FWin.UI.UserName := user;
    // Always set UI.Module *after* setting UI.UserName !!!
    FWin.UI.Module := Sender;
    FWin.UI.Tag := Sender.Tag; //ThreadID

    AddPortalConnection(Sender.Tag, FWin.Handle, 'desc', user); //ThreadID

    (*
    // Restore Window Position
    if not LoadWindowPosition(FWin,'FileTransForm-'+user) then
      LoadWindowPosition(FWin,'FileTransForm');
    *)

    FWin.UI.UserDesc := GetUserDescription(user);

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
  SetForegroundWindow(Self.Handle);
end;

procedure TMainForm.PChatNewUI(Sender: TRtcPChat; const user:string);
var
  CWin: TrdChatForm;
//  GatewayRec: PGatewayRec;
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
    // Always set UI.Module *after* setting UI.UserName !!!
    CWin.UI.Module := Sender;
    CWin.UI.Tag := Sender.Tag; //ThreadID

    AddPortalConnection(Sender.Tag, CWin.Handle, 'desc', user); //ThreadID

    CWin.UI.UserDesc := GetUserDescription(user);

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

  if (Sender = PClient)
    and (GetStatus = STATUS_CONNECTING_TO_GATE) then
  begin
    SetStatus(STATUS_READY);

    if cbRememberAccount.Checked then
      btnAccountLoginClick(nil);
  end;

//  lblStatus.Caption := 'Подключен как "' + eUserName.Text + '".';
//  lblStatus.Update;

//  if FAutoRun then
//    PostMessage(Handle, WM_AUTOMINIMIZE, 0, 0);

  tPClientReconnect.Enabled := False;
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
    if not PDesktopHost.GFullScreen and
        (PDesktopHost.ScreenRect.Right = PDesktopHost.ScreenRect.Left) then
      PDesktopHost.GFullScreen := True;
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
  CS_GW.Acquire;
  try
    i := PortalConnectionsList.Count - 1;
    while i >= 0 do
    begin
      PostMessage(PPortalConnection(PortalConnectionsList[i])^.UIHandle, WM_CLOSE, 0, 0);
      Dispose(PortalConnectionsList[i]);
      PortalConnectionsList.Delete(i);

      i := i - 1;
    end;
  finally
    CS_GW.Release;
  end;

  if (OpenedModalForm <> nil)
    and OpenedModalForm.Showing
    and (not (OpenedModalForm is TrdClientSettings))
      and (not (OpenedModalForm is TfAboutForm)) then
  begin
//    xLog('OpenedModalForm Close Start');
    OpenedModalForm.Close;
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

  if Sender = PClient then
  begin
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

  if (Sender = PClient)
    and (Msg = 'Не удалось подключиться к серверу.') then
    ChangePortP(PClient);

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

procedure TMainForm.PModuleUserJoined(Sender: TRtcPModule; const user:string);
  var
    s:string;
//    el:TListItem;
//    uinfo:TRtcRecord;
  begin
  if Sender is TRtcPFileTransfer then
    s:='Передача файлов'
  else if Sender is TRtcPChat then
    s:='Чат'
  else if Sender is TRtcPDesktopHost then
    begin
    s:='Управление';
    Inc(DesktopCnt);
    if DesktopCnt=1 then
      begin
      DragAcceptFiles(Handle, True);
      end;
    end
  else s:='???';
  s := user + ' ' + s;

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
  var
    s:string;
    a,i:integer;
//    uinfo:TRtcRecord;
  begin
//  xLog('PModuleUserLeft');

  if Sender is TRtcPFileTransfer then
    s:='Передача файлов'
  else if Sender is TRtcPChat then
    s:='Чат'
  else if Sender is TRtcPDesktopHost then
    begin
    s:='Управление';
    Dec(DesktopCnt);
    if DesktopCnt=0 then
      begin
      DragAcceptFiles(Handle,False);
      Show_Wallpaper;
      end;
    end
  else s:='???';
  s := user + ' ' + s;

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
    sett.ProxyOption := ProxyOption;
    sett.PClient := @PClient;
    sett.HTTPClient := @hcAccounts;
    sett.TimerClient := @TimerClient;
    sett.TimerClient2 := @HostTimerClient;
    sett.StateProcedure := SetConnectedState;
    sett.ePassword.Text := RegularPassword;
    sett.ePasswordConfirm.Text := RegularPassword;
    sett.cbStoreHistory.Checked := StoreHistory;
    sett.cbStorePasswords.Checked := StorePasswords;

  //    sett.cbOnlyAdminChanges.Checked := OnlyAdminChanges;
    for i := 0 to sett.tcSettings.PageCount - 1 do
      if sett.tcSettings.Pages[i].Name = APage then
        sett.tcSettings.ActivePage := sett.tcSettings.Pages[i];

    OnCustomFormOpen(sett);
    sett.ModalResult := 0;
    sett.Execute;
    sett.ShowModal;
    SettingsFormOpened := True;
    if sett.ModalResult = mrOk then
    begin
      ProxyOption := sett.CurProxyOption;
      if sett.ePassword.Text <> RegularPassword then
      begin
        RegularPassword := sett.ePassword.Text;
        ShowRegularPasswordState();
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
    end;
    SettingsFormOpened := False;
  finally
    sett.Free;
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
      RegularPassword := sett.ePassword.Text;
      ShowRegularPasswordState();
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
      xLog('PClientStatusPut: ' + Sender.Name + ': rtccClosed');
      sStatus1.Brush.Color := clGray;
//      if not isClosing then
//      begin
//        CloseAllActiveUIByGatewayClient(Sender);
//        tPClientReconnect.Enabled := True;
//      end;
    end;
    rtccOpen:
    begin
      xLog('PClientStatusPut: ' + Sender.Name + ': rtccOpen');
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
      xLog('PClientStatusGet: ' + Sender.Name + ': rtccClosed');
      sStatus2.Brush.Color:=clRed;
      sStatus2.Pen.Color:=clMaroon;
//      if not isClosing then
//      begin
//        CloseAllActiveUIByGatewayClient(Sender);
//        tPClientReconnect.Enabled := True;
//      end;

      if Sender = PClient then
        tPClientReconnect.Enabled := True;
    end;
    rtccOpen:
    begin
      xLog('PClientStatusGet: ' + Sender.Name + ': rtccOpen');
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

function TMainForm.GetPendingItemByUserName(uname, action: String): PPendingRequestItem;
var
  i: Integer;
begin
//  xLog('GetPendingItemByUserName');

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

function TMainForm.PartnerIsPending(uname, action: String): Boolean;
var
  i: Integer;
begin
//  xLog('PartnerIsPending');

  Result := False;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if (PPendingRequestItem(PendingRequests[i])^.UserName = uname)
        and (PPendingRequestItem(PendingRequests[i])^.Action = action) then
        begin
          Result := True;
          Exit;
        end;
  finally
    CS_Pending.Release;
  end;
end;

function TMainForm.UIIsPending(username: String): Boolean;
var
  i: Integer;
begin
//  xLog('UIIsPending');

  Result := False;

  CS_Pending.Acquire;
  try
    for i := 0 to PendingRequests.Count - 1 do
      if (PPendingRequestItem(PendingRequests[i])^.UserName = username) then
      begin
        Result := True;
        Break;
      end;
  finally
    CS_Pending.Release;
  end;
end;

function TMainForm.AddPendingRequest(uname, action: String): PPendingRequestItem;
var
  PRItem: PPendingRequestItem;
begin
//  xLog('AddPendingRequest');

  CS_Pending.Acquire;
  try
    New(PRItem);
    PRItem.UserName := uname;
    PRItem.Action := action;
//    PRItem.Gateway := gateway;
//    ThreadID := ThreadID;
    PendingRequests.Add(PRItem);
  finally
    CS_Pending.Release;
  end;

  UpdatePendingStatus;

  Result := PRItem;
end;

function TMainForm.GetCurrentPendingItemUserName: String;
begin
  CS_Pending.Acquire;
  try
    if PendingRequests.Count > 0 then
      Result := PPendingRequestItem(PendingRequests[PendingRequests.Count - 1])^.UserName;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.DeleteLastPendingItem;
begin
  CS_Pending.Acquire;
  try
    if PendingRequests.Count > 0 then
    begin
      Dispose(PendingRequests[PendingRequests.Count - 1]);
      PendingRequests.Delete(PendingRequests.Count - 1);
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
        Dispose(PendingRequests[i]);
        PendingRequests.Delete(i);
      end;

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;

  UpdatePendingStatus;
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

procedure TMainForm.DeletePendingRequestByItem(Item: PPendingRequestItem);
var
  i: Integer;
begin
//  xLog('DeletePendingRequestByItem');

  CS_Pending.Acquire;
  try
    i := PendingRequests.IndexOf(Item);
    if i >= 0 then
    begin
      PostThreadMessage(PPendingRequestItem(PendingRequests[i])^.ThreadID, WM_DESTROY, 0, 0);
      Dispose(PendingRequests[i]);
      PendingRequests.Delete(i);
    end;
  finally
    CS_Pending.Release;
  end;

  UpdatePendingStatus;
end;

procedure TMainForm.DeletePendingRequests(uname: String);
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
        Dispose(PendingRequests[i]);
        PendingRequests.Delete(i);
      end;

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;

  UpdatePendingStatus;
end;

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
      Dispose(PendingRequests[i]);
      PendingRequests.Delete(i);

      i := i - 1;
    end;
  finally
    CS_Pending.Release;
  end;

  UpdatePendingStatus;
end;

procedure TMainForm.OnCustomFormOpen(AForm: TForm);
begin
  OpenedModalForm := AForm;
end;

procedure TMainForm.OnCustomFormClose;
begin
  OpenedModalForm := nil;
end;

procedure TMainForm.OnUIOpen(UserName, Action: String; var IsPending: Boolean);
begin
//  xLog('OnUIOpen');

  if IsClosing then
    Exit;

  IsPending := UIIsPending(UserName);
  if IsPending then
  begin
    DeletePendingRequest(UserName, Action);

////    Visible := False;
//    Application.Minimize;
////    ShowWindow(Application.Handle, SW_HIDE);
  end;
end;

procedure TMainForm.OnUIClose(AThreadId: Cardinal);
begin
  //xLog('OnUIClose');

//  if IsClosing then
//    Exit;

  RemovePortalConnectionByThreadId(AThreadId, False);

//  RemoveActiveUIRecByHandle(AHandle);
end;

function TMainForm.GetPendingRequestsCount: Integer;
begin
  //xLog('GetPendingRequestsCount');

  CS_Pending.Acquire;
  try
    Result := PendingRequests.Count;
  finally
    CS_Pending.Release;
  end;
end;

procedure TMainForm.UpdatePendingStatus;
begin
  //xLog('UpdatePendingStatus');

  CS_Status.Acquire;
  try
    if GetPendingRequestsCount > 0 then
    begin
//      SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True);
      btnViewDesktop.Caption := 'ПРЕРВАТЬ';
      btnViewDesktop.Color := RGB(232, 17, 35);
    end
    else
    begin
//      SetStatusString('Готов к подключению');
      btnViewDesktop.Caption := 'ПОДКЛЮЧИТЬСЯ';
      btnViewDesktop.Color := $00A39323;
    end;
  finally
    CS_Status.Release;
  end;
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
  CDesk: TrdDesktopViewer;
//  GatewayRec: PGatewayRec;
begin
  //xLog('PDesktopControlNewUI');

  CDesk := TrdDesktopViewer.Create(nil);
  CDesk.OnUIOpen := OnUIOpen;
  CDesk.OnUIClose := OnUIClose;
  CDesk.DoStartFileTransferring := StartFileTransferring;
//  CDesk.Parent := Self;
  //CDesk.ParentWindow := GetDesktopWindow;
  if Assigned(CDesk) then
  begin
//    GatewayRec := GetGatewayRecByDesktopControl(Sender);
//    CDesk.PFileTrans := GatewayRec^.FileTransfer^;
//    CDesk.PChat := GatewayRec.Chat^;

    CDesk.UI.MapKeys := True;
    CDesk.UI.SmoothScale := True;
    CDesk.UI.ExactCursor := True;
    CDesk.UI.Tag := Sender.Tag; //ThreadID

    AddPortalConnection(Sender.Tag, CDesk.Handle, 'desc', user); //ThreadID

    //{$IFNDEF RtcViewer}
//    case cbControlMode.ItemIndex of
//      0: CDesk.UI.ControlMode:=rtcpNoControl;
//      1: CDesk.UI.ControlMode:=rtcpAutoControl;
//      2: CDesk.UI.ControlMode:=rtcpManualControl;
//      3: CDesk.UI.ControlMode:=rtcpFullControl;
//      end;
    CDesk.UI.ControlMode := rtcpFullControl;
    //{$ENDIF}

    CDesk.UI.UserName := user;
    // Always set UI.Module *after* setting UI.UserName !!!
    CDesk.UI.Module := Sender;

    CDesk.UI.UserDesc := GetUserDescription(user);

//    GatewayRec := GetGatewayRecByDesktopControl(Sender);
//    GatewayRec^.ID := user;
//    GatewayRec^.Action := 'desk';
//    GatewayRec^.UIHandle := CDesk.Handle;

//    with TRtcHttpPortalClient(Sender.Client) do
//      AddActiveUI(CDesk.Handle, 'desk', user, FindGatewayClient(GateAddr, GatePort));

//    CDesk.Show;

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
  end
  else
    raise Exception.Create('Ошибка при создании окна');

//  if GetPendingRequestsCount > 0 then
//    SetStatusString('Подключение к ' + GetUserNameByID(GetCurrentPendingItemUserName), True)
//  else
//    SetStatusString('Готов к подключению');
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

//+++++++++++++++++++++++++++++++++++++++++++++++CLIPBOARD COPYING+++++++++++++++++++++++++++++++++++++++++++++++//
function GetFileSize(const FileName: String): LongInt;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0 then
    result := SearchRec.size
  else
    result := -1;
  FindClose(SearchRec);
end;

procedure TMainForm.tGetDirectorySizeTimer(Sender: TObject);
var s,_: string;
    i: integer;

 function getDirSize(d: String): Int64;
 var
    ff: TStringDynArray; s: String;
 begin
    result := 0;
    ff := TDirectory.GetFiles(d, '*', TSearchOption.soAllDirectories);
    for s in ff do
    begin
      Application.ProcessMessages;
      result:= result + GetFileSize(s)
    end;
 end;

begin
  tGetDirectorySize.Enabled:= False;
  try
    s:= '';
    for i:=0 to high(bf) do
    begin
      Application.ProcessMessages;

      s:= s + bf[i];
      if i < high(bf) then
         s:= s + '|';

      if directoryExists(bf[i]) then
        _:= _ + bf[i] + '*' + getDirsize(bf[i]).tostring
      else
        _:= _ + bf[i] + '*' + getfilesize(bf[i]).tostring;

      if i < high(bf) then
         _:= _ + '|';
    end;

    cle_.Host := HOST_IP;
    cle_.Connect;
    try
      cle_.Socket.WriteLn('f:' + s, IndyTextEncoding(IdTextEncodingType.encOSDefault));
      cle_.Socket.WriteLn('s:' + _, IndyTextEncoding(IdTextEncodingType.encOSDefault));
    finally
      cle_.Disconnect;
    end;
  except
  end;
end;

procedure TMainForm.tFileSendTimer(Sender: TObject);
var ff: TStringList;
  s: String;
  cn, i: Integer;
  h: HWND;
begin
  tFileSend.Enabled:= False;

  if FindWindow('TrdFileBrowser', nil) <> 0 then
  begin
    ff := TStringList.Create;
    for i := 0 to High(bf) do
      ff.Add(bf[i]);

    h := FindWindow('TrdFileTransfer',nil);
    if h <> 0 then
      SetWindowPos(h, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);

    for i := 0 to ff.count - 1 do
//    if FileExists(ff[i]) or
//      (DirectoryExists(ff[i])) then
//      MyUI.Send(ff[i], T_);
    ff.free;

    if h <> 0 then
      SetWindowPos(h, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);
  end
  else
    MessageBox(Handle, PChar('Вначале включите режим передачи файлов "File Explorer"'), 'Remox', MB_TOPMOST + MB_ICONWARNING + MB_OK);
end;

procedure TMainForm.WMChangeCbChain(var Message: TWMChangeCBChain);
begin
  with Message do
  begin
    // If the next window is closing, repair the chain.
    if Remove = hwndNextViewer then
      hwndNextViewer := Next
    // Otherwise, pass the message to the next link.
    else
      if hwndNextViewer <> 0 then
        SendMessage(hwndNextViewer, Msg, Remove, Next);
  end;
end;

procedure TMainForm.WMDrawClipboard(var Message: TMessage);
var
  i: Integer;
begin
  try
    bf:= cf_(nil);
    if high(bf)>-1 then
    begin
      setlength(bf_,length(bf));
      for i:=0 to high(bf) do
        bf_[i]:= bf[i];
    end
    else
    begin
      setlength(bf,length(bf_));
      for i:=0 to high(bf_) do
        bf[i]:= bf_[i];
    end;
  except
  end;

  with Message do
   SendMessage(hwndNextViewer, Msg, WParam, LParam);
end;

function TMainForm.cf_(Sender: TObject): TStringDynArray;
var
  f: THandle;
  buffer: array [0..MAX_PATH] of Char;
  i, numFiles: Integer;
begin
  setLength(result, 0);

  try
    try
      Clipboard.Open;
    except
    end;
    try
      f := Clipboard.GetAsHandle(CF_HDROP);
      if f <> 0 then
      begin
        numFiles := DragQueryFile(f, $FFFFFFFF, nil, 0);
        for i := 0 to numfiles - 1 do
        begin
          buffer[0] := #0;
          DragQueryFile(f, i, buffer, SizeOf(buffer));

          if fileexists(buffer) or (directoryExists(buffer)) then
          begin
            setLength(result, Length(result)+1);
            result[high(result)]:= buffer;
          end;
        end;
      end;
    finally
      try
        Clipboard.Close;
      except
      end;

      if length(result) > 0 then
        if getforegroundwindow <> findwindow('TrdDesktopViewer', 'rdDesktopViewer') then
          tGetDirectorySize.Enabled:= True;
    end;
  except
  end;
end;
//-----------------------------------------------CLIPBOARD COPYING-----------------------------------------------//

initialization
  CS_GW := TCriticalSection.Create;
  CS_Status := TCriticalSection.Create;
  CS_Pending := TCriticalSection.Create;
  CS_ActivateHost := TCriticalSection.Create;
//  CS_SetConnectedState := TCriticalSection.Create;
  Randomize;

finalization
  RestorePowerChanges;
  CS_Pending.Free;
  CS_Status := TCriticalSection.Create;
  CS_GW.Free;
  CS_ActivateHost.Free;
//  CS_SetConnectedState.Free;

end.
