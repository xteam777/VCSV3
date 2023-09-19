 unit rdDesktopView;

interface

{$include rtcDefs.inc}
{$ifdef RTCHost}
  {$define RTCViewer}
{$endif}

{$if CompilerVersion >= 21.0}
  {$DEFINE USE_GLASS_FORM}
{$ifend}

uses
  Windows, Messages, SysUtils, CommonData, CommonUtils, uVircessTypes, rtcLog, RmxClipbrd,
  Classes, Graphics, Controls, Forms, Types, IOUtils, DateUtils, rtcPortalHttpCli,
  Dialogs, ExtCtrls, StdCtrls, ShellAPI, ProgressDialog, rtcSystem,
  rtcpChat, Math, rtcpFileTrans, rtcpFileTransUI, uUIDataModule,
  System.ImageList, Vcl.ImgList, Vcl.ActnMan, Vcl.ActnColorMaps, System.Actions,
  Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls, rtcPortalMod,
  rtcpDesktopControl, rtcpDesktopControlUI, ChromeTabs, NFPanel, Vcl.Imaging.jpeg,
  Vcl.Samples.Spin, Vcl.Buttons, Vcl.ToolWin, Vcl.ActnCtrls, Vcl.ActnMenus,
  Vcl.ComCtrls, ChromeTabsTypes, ChromeTabsClasses, ChromeTabsControls, rtcpDesktopConst,

  {$IFDEF USE_GLASS_FORM}ChromeTabsGlassForm,{$ENDIF}

  Vcl.Imaging.pngimage, VideoRecorder, rtcInfo, rmxVideoStorage, rmxVideoFile;

type
  TFormType = {$IFDEF USE_GLASS_FORM}
              TChromeTabsGlassForm
              {$ELSE}
              TForm
              {$ENDIF};

  PrdDesktopViewer = ^TrdDesktopViewer;
  TrdDesktopViewer = class(TFormType)
    DesktopTimer: TTimer;
    ActionManagerTop: TActionManager;
    XPColorMap1: TXPColorMap;
    aFileTransfer: TAction;
    aCtrlAltDel: TAction;
    aBlockKeyboardMouse: TAction;
    aHideWallpaper: TAction;
    aShowRemoteCursor: TAction;
    aFullScreen: TAction;
    aLogoff: TAction;
    aPowerOffMonitor: TAction;
    aChat: TAction;
    aLockSystem: TAction;
    aPowerOffSystem: TAction;
    aRestartSystem: TAction;
    aScreenshotToFile: TAction;
    aScreenshotToCbrd: TAction;
    aRecordStart: TAction;
    aRecordStop: TAction;
    aRecordCancel: TAction;
    ilTopPanel: TImageList;
    aStretchScreen: TAction;
    aLockSystemOnClose: TAction;
    aOptimizeQuality: TAction;
    aOptimizeSpeed: TAction;
    pMain: TPanel;
    Scroll: TScrollBox;
    panSettings: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label4: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    grpMirror: TComboBox;
    grpMouse: TComboBox;
    grpLayered: TComboBox;
    grpScreenBlocks: TComboBox;
    grpMonitors: TComboBox;
    grpColor: TComboBox;
    grpFrame: TComboBox;
    btnCancel: TBitBtn;
    btnAccept: TBitBtn;
    grpColorLow: TComboBox;
    cbReduceColors: TSpinEdit;
    grpScreenLimit: TComboBox;
    grpScreenBlocks2: TComboBox;
    grpScreen2Refine: TComboBox;
    aSendShortcuts: TAction;
    iScreenLocked: TImage;
    iPrepare: TImage;
    lState: TLabel;
    aRecordOpenFolder: TAction;
    aRecordCodecInfo: TAction;
    MainChromeTabs: TChromeTabs;
    TimerResize: TTimer;
    panOptions: TPanel;
    ammbActions: TActionMainMenuBar;
    panOptionsMini: TNFPanel;
    iFullScreen: TImage;
    iMinimize: TImage;
    iShowMiniPanel: TImage;
    iMove: TImage;
    iMiniPanelShow: TImage;
    iMiniPanelHide: TImage;
    tCloseForm: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDeactivate(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure myUIOpen(Sender: TRtcPDesktopControlUI);
    procedure myUIClose(Sender: TRtcPDesktopControlUI);
    procedure myUIError(Sender: TRtcPDesktopControlUI);
    procedure myUIData(Sender: TRtcPDesktopControlUI);
    procedure myUILogOut(Sender: TRtcPDesktopControlUI);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure pImageMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure ScrollMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure grpColorLowChange(Sender: TObject);
    procedure DesktopTimerTimer(Sender: TObject);
    procedure pImageDblClick(Sender: TObject);
    procedure aCtrlAltDelExecute(Sender: TObject);
    procedure aHideWallpaperExecute(Sender: TObject);
    procedure aShowRemoteCursorExecute(Sender: TObject);
    procedure aOptimalScaleExecute(Sender: TObject);
    procedure aFullScreenExecute(Sender: TObject);
    procedure aBlockKeyboardMouseExecute(Sender: TObject);
    procedure aPowerOffMonitorExecute(Sender: TObject);
    procedure aFileTransferExecute(Sender: TObject);
    procedure aChatExecute(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure aLockSystemExecute(Sender: TObject);
    procedure aLogoffExecute(Sender: TObject);
    procedure aPowerOffSystemExecute(Sender: TObject);
    procedure aRestartSystemExecute(Sender: TObject);
    procedure aScreenshotToFileExecute(Sender: TObject);
    procedure aScreenshotToCbrdExecute(Sender: TObject);
    procedure aRecordStartExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure aRecordStopExecute(Sender: TObject);
    procedure aRecordCancelExecute(Sender: TObject);
    procedure panOptionsMiniMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure panOptionsMiniMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure panOptionsMiniMouseLeave(Sender: TObject);
    procedure panOptionsMiniMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure aStretchScreenExecute(Sender: TObject);
    procedure aLockSystemOnCloseExecute(Sender: TObject);
    procedure aOptimizeSpeedExecute(Sender: TObject);
    procedure aOptimizeQualityExecute(Sender: TObject);
    procedure lHideMiniPanelClick(Sender: TObject);
    procedure lFullScreenClick(Sender: TObject);
    procedure lCloseClick(Sender: TObject);
    procedure lMinimizeClick(Sender: TObject);
    procedure aSendShortcutsExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure panOptionsMouseLeave(Sender: TObject);
//    procedure FT_UIRecvStart(Sender: TRtcPFileTransferUI);
//    procedure FT_UIRecv(Sender: TRtcPFileTransferUI);
//    procedure FT_UIRecvCancel(Sender: TRtcPFileTransferUI);
//    procedure FT_UIRecvStop(Sender: TRtcPFileTransferUI);
    procedure FT_UINotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend);
    procedure FT_UIClose(Sender: TRtcPFileTransferUI);
    procedure FT_UILogOut(Sender: TRtcPFileTransferUI);
    procedure TimerRecTimer(Sender: TObject);
    procedure aRecordOpenFolderExecute(Sender: TObject);
    procedure aRecordCodecInfoExecute(Sender: TObject);
    procedure ControlPolygons(Sender, ChromeTabsControl: TObject;
      ItemRect: TRect; ItemType: TChromeTabItemType;
      Orientation: TTabOrientation; var Polygons: IChromeTabPolygons);
    procedure MainChromeTabsButtonAddClick(Sender: TObject; var Handled: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure MainChromeTabsActiveTabChanged(Sender: TObject; ATab: TChromeTab);
    procedure MainChromeTabsButtonCloseTabClick(Sender: TObject;
      ATab: TChromeTab; var Close: Boolean);
    procedure TimerResizeTimer(Sender: TObject);
    procedure tCloseFormTimer(Sender: TObject);
  private
//    FVideoRecorder: TVideoRecorder;
//    FVideoWriter: TRMXVideoWriter;
//    FVideoFile: String;
//    FImageChanged: Boolean;
//    FVideoImage: TBitmap;
//    FLockVideoImage: Integer;
//    FFirstImageArrived: Boolean;
    procedure DoRecordAction(Action: Integer);
    procedure RecordStart();
    procedure RecordStop();
    procedure RecordCancel();
//	  procedure RecordStopWindowProc(var Message: TMessage); message WM_STOP_RECORD;
//    procedure ModalFormRecordStopActivate(Sender: TObject);
//    procedure OnGetVideoFrame(Sender: TObject);
    procedure OnSetScreenData(Sender: TObject; UserName: String; const Data: RtcString);
    procedure LockVideoImage(UIDM: TUIDataModule);
    procedure UnlockVideoImage(UIDM: TUIDataModule);
    procedure panOptionsVisibilityChange(AVisible: Boolean);
  protected
    LMouseX,LMouseY:integer;
    LMouseD:boolean;

    LMouseDown,
    RMouseDown,
    LWinDown,
    RWinDown: Boolean;

    UIModulesList: TList;
    ActiveUIModule: TUIDataModule;

    FProgressDialogsList: TList;

    FOnUIOpen: TUIOpenEvent;
    FOnUIClose: TUICloseEvent;

    FDoStartFileTransferring: TDoStartFileTransferring;

    FLastActiveExplorerHandle: THandle;
    procedure OnProgressDialogCancel(Sender: TObject);

//    procedure SetCaption;

    procedure CreateParams(var params: TCreateParams); override;

    // declare our DROPFILES message handler
//    procedure AcceptFiles(var msg: TMessage); message WM_DROPFILES;
    procedure UIHaveScreeenChanged(Sender: TObject);
    procedure DoResizeImage;
    procedure UpdateQuality;

//    procedure WndProc(var Msg : TMessage); override;

//    function LeaseExpiresDateToDateTime(LeaseExpires: Integer): String;
    procedure GetFilesFromHostClipboard(var Message: TMessage); message WM_GET_FILES_FROM_CLIPBOARD;
//    procedure WMActivate(var Message: TMessage); message WM_ACTIVATE;
  public
    { Public declarations }

//    myUI: TRtcPDesktopControlUI;
//    FT_UI: TRtcPFileTransferUI;
//    FUserName: String;
//    FUserDesc: String;
//    FUserPass: String;
    PFileTrans: TRtcPFileTransfer;
    PChat: TRtcPChat;
//    fFirstScreen: Boolean;
    FormMinimized: Boolean;
//    PartnerLockedState: Integer;
//    PartnerServiceStarted: Boolean;
//    MappedFiles: array of TMappedFileRec;
    ReconnectToPartnerStart: TReconnectToPartnerStart;

    function SetShortcuts_Hook(fBlockInput: Boolean): Boolean;

    procedure PFileTransExplorerNewUI(Sender: TRtcPFileTransfer; const user: String);

    procedure InitScreen;
    procedure FullScreen;

    procedure SetFormState;

    property OnUIOpen: TUIOpenEvent read FOnUIOpen write FOnUIOpen;
    property OnUIClose: TUICloseEvent read FOnUIClose write FOnUIClose;
    property DoStartFileTransferring: TDoStartFileTransferring read FDoStartFileTransferring write FDoStartFileTransferring;

    function AddProgressDialog(ATaskId: TTaskId; AUserName: String): PProgressDialogData;
    function GetProgressDialogData(ATaskId: TTaskId): PProgressDialogData; overload;
    function GetProgressDialogData(AProgressDialog: PProgressDialog): PProgressDialogData; overload;
    procedure RemoveProgressDialog(ATaskId: TTaskId);
    procedure RemoveProgressDialogByValue(AProgressDialog: PProgressDialog);
    procedure RemoveProgressDialogByUserName(AUserName: String);
    function GetTab(AUserName: String): TChromeTab;
    function AddNewTab(AUserName, AUserDesc, AUserPass: String; AStartLockedState: Integer; AStartServiceStarted: Boolean; AModule: TRtcPDesktopControl): TUIDataModule;
    procedure CloseTab(AUserName: String);
    procedure SetReconnectInterval(AUserName: String; AInterval: Integer);
    procedure SetActiveTab(AUserName: String);
    procedure ChangeLockedState(AUserName: String; ALockedState: Integer; AServiceStarted: Boolean);
    function GetUIDataModule(AUserName: String): TUIDataModule;
    function RemoveUIDataModule(AUserName: String): Integer;
    procedure DoReconnectToPartnerStart(user, username, pass, action: String);
  end;


const
  RECORD_START = 0;
  RECORD_STOP = 1;
  RECORD_CANCEL = 2;
  RECORD_CODEC_INFO = 3;

var
  MiniPanelDraggging, MiniPanelMouseDowned: Boolean;
  MiniPanelCurX: Integer;
  KeyboardShortcutsHook: HWND;
  FormHandle: HWND;

  //    UIDataModule: TUIDataModule;
  //  UIDataModule := TUIDataModule.Create(nil);
  //  FreeAndNil(UIDataModule);

implementation

{$R *.dfm}

{ TrdDesktopViewer }

procedure TrdDesktopViewer.CloseTab(AUserName: String);
var
  pUIItem: TUIDataModule;
  RemovedInd: Integer;
begin
  pUIItem := GetUIDataModule(AUserName);

  if Assigned(FOnUIClose) then
    FOnUIClose('desk', AUserName); //ThreadID

  RemovedInd := RemoveUIDataModule(AUserName);
  if UIModulesList.Count = 0 then
  begin
    ActiveUIModule := nil;
    tCloseForm.Enabled := True;
  end
  else
  if RemovedInd > 1 then
    ActiveUIModule := UIModulesList[RemovedInd - 1]
  else
    ActiveUIModule := UIModulesList[0];

  DoResizeImage;
end;

procedure TrdDesktopViewer.MainChromeTabsButtonCloseTabClick(Sender: TObject;
  ATab: TChromeTab; var Close: Boolean);
begin
  CloseTab(ATab.UserName);
end;

procedure TrdDesktopViewer.SetFormState;
begin
  if ActiveUIModule = nil then
  begin
    pMain.Color := $00A39323;
    Scroll.Visible := True;
    iPrepare.Visible := False;
//    panOptions.Visible := True;
//    panOptionsMini.Visible := True;
    iScreenLocked.Visible := True;
    lState.Caption := 'Удаленный компьютер заблокирован';
    lState.Top := Height * 580 div 680;
    lState.Visible := True;
    lState.Invalidate;
    Scroll.Visible := False;
  end
  else
  if (ActiveUIModule.TimerReconnect.Enabled) then
  begin
    pMain.Color := $00A39323;
    Scroll.Visible := True;
    iPrepare.Visible := False;
//    panOptions.Visible := True;
//    panOptionsMini.Visible := True;
    iScreenLocked.Visible := False;
    lState.Caption := 'Выполняется переподключение...';
    lState.Top := Height div 2;
    lState.Visible := True;
    lState.Invalidate;
    Scroll.Visible := False;
  end
  else
  if ((ActiveUIModule.PartnerLockedState = LCK_STATE_LOCKED) or (ActiveUIModule.PartnerLockedState = LCK_STATE_SAS))
    and (not ActiveUIModule.PartnerServiceStarted) then
  begin
    pMain.Color := $00A39323;
    Scroll.Visible := True;
    iPrepare.Visible := False;
//    panOptions.Visible := True;
//    panOptionsMini.Visible := True;
    iScreenLocked.Visible := True;
    lState.Caption := 'Удаленный компьютер заблокирован';
    lState.Top := Height * 580 div 680;
    lState.Visible := True;
    lState.Invalidate;
    Scroll.Visible := False;
  end
  else
  if not ActiveUIModule.UI.HaveScreen then
  begin
    pMain.Color := $00A39323;
    Scroll.Visible := True;
    iPrepare.Visible := False;
//    panOptions.Visible := True;
//    panOptionsMini.Visible := True;
    iScreenLocked.Visible := False;
    lState.Caption := 'Инициализация изображения...';
    lState.Top := Height div 2;
    lState.Visible := True;
    lState.Invalidate;
    Scroll.Visible := False;
  end
  else
  begin
    pMain.Color := $00151515;
    Scroll.Visible := True;
    iPrepare.Visible := False;
//    panOptions.Visible := True;
//    panOptionsMini.Visible := True;
    iScreenLocked.Visible := False;
    lState.Top := Height * 580 div 680;
    lState.Caption := '';
    lState.Visible := False;
    lState.Invalidate;
    Scroll.Visible := True;
  end;
end;

procedure TrdDesktopViewer.DoReconnectToPartnerStart(user, username, pass, action: String);
begin
  SetFormState;

  ReconnectToPartnerStart(user, username, pass, action);
end;

procedure TrdDesktopViewer.FullScreen;
begin
  MainChromeTabs.Visible := False;
  panOptionsVisibilityChange(False);

  // move to Full Screen mode
  Scroll.HorzScrollBar.Visible := False;
  Scroll.VertScrollBar.Visible := False;
  Scroll.VertScrollBar.Position := 0;
  Scroll.HorzScrollBar.Position := 0;

  WindowState := wsNormal;
  BorderStyle := bsNone;
  Left := 0;
  Top := 0;
  Width := Screen.Width;
  Height := Screen.Height;

  DoResizeImage;

//  if (ActiveUIModule.pImage^.Align = alNone)
//    and ActiveUIModule.UI.HaveScreen
//    and aStretchScreen.Checked then
//  begin
//    ActiveUIModule.pImage^.Width := ActiveUIModule.UI.ScreenWidth;
//    ActiveUIModule.pImage^.Height := ActiveUIModule.UI.ScreenHeight;
//    Scroll.HorzScrollBar.Visible := True;
//    Scroll.VertScrollBar.Visible := True;
//    if ActiveUIModule.pImage^.Width < Screen.Width then
//      ActiveUIModule.pImage^.Left := (Screen.Width - ActiveUIModule.pImage^.Width) div 2
//    else
//      ActiveUIModule.pImage^.Left := 0;
//    if ActiveUIModule.pImage^.Height < Screen.Height then
//      ActiveUIModule.pImage^.Top := (Screen.Height - ActiveUIModule.pImage^.Height) div 2
//    else
//      ActiveUIModule.pImage^.Top := 0;
//  end;

  BringToFront;

//  //tell Windows that you're accepting drag and drop files
//  DragAcceptFiles( Handle, True );

end;

procedure TrdDesktopViewer.InitScreen;
begin
  MainChromeTabs.Visible := True;
  panOptionsVisibilityChange(True);

  Scroll.HorzScrollBar.Visible := False;
  Scroll.VertScrollBar.Visible := False;
  Scroll.VertScrollBar.Position := 0;
  Scroll.HorzScrollBar.Position := 0;

//  ActiveUIModule.pImage^.Left:=0;
//  ActiveUIModule.pImage^.Top:=0;
  WindowState := wsMaximized;
  BorderStyle := bsSizeable;

{  if ActiveUIModule.UI.HaveScreen then
  begin
    if ActiveUIModule.UI.ScreenWidth < Screen.Width then
      ClientWidth := ActiveUIModule.UI.ScreenWidth
    else
      Width:=Screen.Width;
    if ActiveUIModule.UI.ScreenHeight < Screen.Height then
      ClientHeight := ActiveUIModule.UI.ScreenHeight
    else
      Height := Screen.Height;
    if ActiveUIModule.UI.ScreenHeight >= Screen.Height then
    begin
//      Left := 0;
//      Top := 0;
//      WindowState := wsMaximized;
    end
    else
    begin
//      Left := (Screen.Width - Width) div 2;
//      Top := (Screen.Height - Height) div 2;
    end;
  end;}

//  if (pImage.Align<>alClient) and myUI.HaveScreen then
//    begin
//    pImage.Align:=alNone;
//    pImage.Width:=myUI.ScreenWidth;
//    pImage.Height:=myUI.ScreenHeight;
//    Scroll.HorzScrollBar.Visible:=True;
//    Scroll.VertScrollBar.Visible:=True;
//    end;

  BringToFront;

  // tell Windows that you're accepting drag and drop files
//  if assigned(PFileTrans) then
//    DragAcceptFiles( Handle, True );
end;


procedure TrdDesktopViewer.Button1Click(Sender: TObject);
var
  i: Integer;
  v: String;
begin
  panOptionsMini.Update;
  panOptionsMini.BringToFront;
  panOptionsMini.Left := 1000;
  panOptionsMini.Top := 40;
//  ActiveUIModule.pImgRec^.Parent := Scroll;
//  ActiveUIModule.pImgRec^.Left :=Scroll.Width - 100;
//  ActiveUIModule.pImgRec^.Top := 10;
//  ActiveUIModule.pImgRec^.Visible := True;  Доделать
//  ActiveUIModule.pImgRec^.Picture.Bitmap.Assign(imgRecSource.Picture.Bitmap);
//  ActiveUIModule.pImgRec^.BringToFront;

//  Memo1.Lines.Clear;
//  for i := 0 to UIModulesList.Count - 1 do
//  begin
//    if TUIDataModule(UIModulesList[i]).pImage^.Visible then
//      v := 'True'
//    else
//      v := 'False';
//    Memo1.Lines.Add(TUIDataModule(UIModulesList[i]).UserName
//      + ' L: ' + IntToStr(TUIDataModule(UIModulesList[i]).pImage^.Left)
//      + ' T: ' + IntToStr(TUIDataModule(UIModulesList[i]).pImage^.Top)
//      + ' W: ' + IntToStr(TUIDataModule(UIModulesList[i]).pImage^.Width)
//      + ' H: ' + IntToStr(TUIDataModule(UIModulesList[i]).pImage^.Height)
//      + ' V: ' + v);
//  end;

//  MainChromeTabs.Visible := False;
end;

procedure TrdDesktopViewer.SetReconnectInterval(AUserName: String; AInterval: Integer);
var
  UIDM: TUIDataModule;
begin
  UIDM := GetUIDataModule(GetUserToFromUserName(AUserName));
  if UIDM <> nil then
    UIDM.TimerReconnect.Interval := AInterval;
end;

procedure TrdDesktopViewer.ChangeLockedState(AUserName: String; ALockedState: Integer; AServiceStarted: Boolean);
var
  UIDM: TUIDataModule;
begin
  UIDM := GetUIDataModule(GetUserToFromUserName(AUserName));
  if UIDM <> nil then
  begin
    UIDM.PartnerLockedState := ALockedState;
    UIDM.PartnerServiceStarted := AServiceStarted;

    if UIDM = ActiveUIModule then
      SetFormState;
  end;
end;

function TrdDesktopViewer.GetTab(AUserName: String): TChromeTab;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to MainChromeTabs.Tabs.Count - 1 do
    if MainChromeTabs.Tabs[i].UserName = AUserName then
    begin
      Result := MainChromeTabs.Tabs[i];
      Break;
    end;
end;

function TrdDesktopViewer.AddNewTab(AUserName, AUserDesc, AUserPass: String; AStartLockedState: Integer; AStartServiceStarted: Boolean; AModule: TRtcPDesktopControl): TUIDataModule;
var
  pTab: TChromeTab;
  pUIItem: TUIDataModule;
//  pViewer: TRtcPDesktopViewer;
  fIsPending, fIsReconnection: Boolean;
begin
  if Assigned(FOnUIOpen) then
    FOnUIOpen(AUserName, 'desk', fIsPending, fIsReconnection);

  pUIItem := GetUIDataModule(AUserName);
  if fIsReconnection
    and (pUIItem = nil) then
    Exit;

  if not fIsPending then //Если подключение отменено, выходим
    Exit
  else
  if not fIsReconnection then
  begin
    Show;
    BringToFront;
    //BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
  end;

  if not fIsReconnection then
  begin
    pTab := MainChromeTabs.Tabs.Add;
    pTab.UserName := AUserName;  //К которому изначально подключались (не UserToConnect, на которого перенаправило)
  end
  else
    pTab := GetTab(AUserName);
  pTab.UserDesc := AUserDesc;
  pTab.UserPass := AUserPass;
  if pTab.UserDesc <> '' then
    pTab.Caption := pTab.UserDesc
  else
    pTab.Caption := pTab.UserName;

  if not fIsReconnection then
    pUIITem := TUIDataModule.Create(Self);
  pUIItem.PartnerLockedState := AStartLockedState;
  pUIItem.PartnerServiceStarted := AStartServiceStarted;
  pUIITem.ReconnectToPartnerStart := DoReconnectToPartnerStart;
  pUIItem.TimerRec.OnTimer := TimerRecTimer;
  pUIItem.TimerReconnect.Enabled := False;

  if not fIsReconnection then
    pUIITem.pImage^ := TRtcPDesktopViewer.Create(Scroll);
  pUIITem.pImage^.Parent := Scroll;
//  pUIITem.pImage^.Align := alClient;
  pUIITem.pImage^.Color := clBlack;
  pUIITem.pImage^.RecordCircleVisible := False;
  pUIITem.pImage^.RecordInfoVisible := False;
  pUIITem.pImage^.RecordInfo := '00:00:00';
  pUIITem.pImage^.RecordTicks := 0;
  pUIITem.pImage^.Active := True;

  if not fIsReconnection then
    pUIItem.UI.Viewer := pUIITem.pImage^;
  pUIITem.UserName := AUserName;  //К которому изначально подключались (не UserToConnect, на которого перенаправило)
  pUIITem.UserDesc := AUserDesc;
  pUIITem.UserPass := AUserPass;
//  pUIItem.UI := TRtcPDesktopControlUI.Create(DesktopsForm);
  pUIItem.UI.MapKeys := True;
  pUIItem.UI.SmoothScale := True;
  pUIItem.UI.ExactCursor := True;
  pUIItem.UI.OnOpen := myUIOpen;
  pUIItem.UI.OnData := myUIData;
  pUIItem.UI.OnHaveScreeenChanged := UIHaveScreeenChanged;
  pUIItem.UI.OnError := myUIError;
  pUIItem.UI.OnLogout := myUILogout;
  pUIItem.UI.OnClose := myUIClose;
  pUIItem.UI.ControlMode := rtcpFullControl;
  pUIItem.UI.UserName := pTab.UserName;
  pUIItem.UI.UserDesc := pTab.UserDesc;
  // Always set UI.Module *after* setting UI.UserName !!!
  pUIItem.UI.Module := AModule;
//    pUIItem.UI.Tag := Sender.Tag; //ThreadID
//  if Assigned(PFileTrans.Client) then
//    PFileTrans.Close(PFileTrans.Client.LoginUserName);
//  pUIItem.PFileTrans := TRtcPFileTransfer.Create(DesktopsForm);
  pUIItem.PFileTrans.Client := AModule.Client;
  pUIItem.PFileTrans.OnNewUI := PFileTransExplorerNewUI;
  pUIItem.PFileTrans.Open(pTab.UserName, False, AModule);

  if not fIsReconnection then
    UIModulesList.Add(pUIItem);
  ActiveUIModule := pUIItem;

  MainChromeTabsActiveTabChanged(nil, pTab);
//  SetFormState;

  Result := pUIItem;
end;

procedure TrdDesktopViewer.SetActiveTab(AUserName: String);
var
  i: Integer;
begin
  for i := 0 to MainChromeTabs.Tabs.Count - 1 do
    if MainChromeTabs.Tabs[i].UserName = AUserName then
    begin
      MainChromeTabs.ActiveTabIndex := i;
      Break;
    end;
end;

procedure TrdDesktopViewer.MainChromeTabsButtonAddClick(Sender: TObject;
  var Handled: Boolean);
begin
  BringWindowToTop(MainFormHandle);
  Handled := True;
end;

function TrdDesktopViewer.RemoveUIDataModule(AUserName: String): Integer;
var
  i: Integer;
begin
  Result := -1;
  i := UIModulesList.Count - 1;
  while i >= 0 do
  begin
    if TUIDataModule(UIModulesList[i]).UserName = AUserName then
    begin
      TUIDataModule(UIModulesList[i]).UI.Active := False;
      TRtcHTTPPortalClient(TUIDataModule(UIModulesList[i]).UI.Module.Client).Active := False;
      TRtcHTTPPortalClient(TUIDataModule(UIModulesList[i]).UI.Module.Client).Stop;
      TUIDataModule(UIModulesList[i]).UI.Module.Close(AUserName);
      TUIDataModule(UIModulesList[i]).UI.CloseAndClear;
      TUIDataModule(UIModulesList[i]).FT_UI.CloseAndClear;
      TUIDataModule(UIModulesList[i]).FT_UI.Close;
      FreeAndNil(TUIDataModule(UIModulesList[i]));
      UIModulesList.Delete(i);
      FOnUIClose('desk', AUserName);

      Result := i;
      Break;
    end;

    i := i - 1;
  end;
end;

function TrdDesktopViewer.GetUIDataModule(AUserName: String): TUIDataModule;
var
  i: Integer;
begin
  Result := nil;
    for i := 0 to UIModulesList.Count - 1 do
      if TUIDataModule(UIModulesList[i]).UserName = AUserName then
      begin
        Result := UIModulesList[i];
        Break;
      end;
end;

procedure TrdDesktopViewer.MainChromeTabsActiveTabChanged(Sender: TObject;
  ATab: TChromeTab);
var
  i: Integer;
  pUIItem: TUIDataModule;
begin
  if ATab.Caption = '' then
    Exit;

  pUIItem := GetUIDataModule(ATab.UserName);
  for i := 0 to UIModulesList.Count - 1 do
    if UIModulesList[i] = pUIItem then
    begin
//      TUIDataModule(UIModulesList[i]).pImage^.Align := alClient;
      TUIDataModule(UIModulesList[i]).pImage^.Visible := True;
      TUIDataModule(UIModulesList[i]).pImage^.Active := True;

      ActiveUIModule := pUIItem;

      aRecordStart.Enabled := not Assigned(TUIDataModule(UIModulesList[i]).FVideoWriter);
      aRecordStop.Enabled := Assigned(TUIDataModule(UIModulesList[i]).FVideoWriter);
      aRecordCancel.Enabled := Assigned(TUIDataModule(UIModulesList[i]).FVideoWriter);
    end
    else
    begin
      TUIDataModule(UIModulesList[i]).pImage^.Visible := False;
      TUIDataModule(UIModulesList[i]).pImage^.Active := False;
//      TUIDataModule(UIModulesList[i]).pImage^.Align := alNone;
//      TUIDataModule(UIModulesList[i]).pImage^.Left := -1;
//      TUIDataModule(UIModulesList[i]).pImage^.Top := -1;
//      TUIDataModule(UIModulesList[i]).pImage^.Width := 1;
//      TUIDataModule(UIModulesList[i]).pImage^.Height := 1;
    end;

  DoResizeImage;

//  if PFileTrans <> nil then
//    PFileTrans.Free;

//  UI.Free;
////  UI := TRtcPDesktopControlUI.Create(Self);
////  UI.Viewer := pImage;
////  UI.MapKeys := True;
////  UI.SmoothScale := True;
////  UI.ExactCursor := True;
////  UI.OnOpen := myUIOpen;
////  UI.OnData := myUIData;
////  UI.OnError := myUIError;
////  UI.OnLogout := myUILogout;
////  UI.OnClose := myUIClose;
////  UI.ControlMode := rtcpFullControl;
//  UI.UserName := ATab.UserName;
//  UI.UserDesc := ATab.UserDesc;
//  // Always set UI.Module *after* setting UI.UserName !!!
//  UI.Module := ATab.Module;
////    DesktopsForm.UI.Tag := Sender.Tag; //ThreadID

//  FT_UI.Free;
//  FT_UI := TRtcPFileTransferUI.Create(Self);
//  FT_UI.Module := nil;
//  FT_UI.NotifyFileBatchSend := FT_UINotifyFileBatchSend;
//  FT_UI.OnLogOut := FT_UILogOut;
//  FT_UI.OnClose := FT_UIClose;

//  if Assigned(PFileTrans.Client) then
//    PFileTrans.Close(PFileTrans.Client.LoginUserName);
//  PFileTrans.Client := UI.Module.Client;
//  PFileTrans.OnNewUI := PFileTransExplorerNewUI;
//  PFileTrans.Open(UI.UserName, False, Sender);
end;

procedure TrdDesktopViewer.OnSetScreenData(Sender: TObject;
  UserName: String; const Data: RtcString);
var
  rec: TRtcRecord;
  UIDM: TUIDataModule;
begin
  UIDM := GetUIDataModule(GetUserToFromUserName(UserName));
  if Assigned(UIDM.FVideoWriter) then
    begin
      if UIDM.FFirstImageArrived then
        UIDM.FVideoWriter.WriteRTCCode(Data) else
        begin
          rec := TRtcRecord.FromCode(Data);
          try
            UIDM.FFirstImageArrived := (rec.isType['res'] = rtc_Record) and (rec.isType['scrdr'] = rtc_Array);
            if UIDM.FFirstImageArrived  then
              UIDM.FVideoWriter.WriteRTCCode(Data);
          finally
            rec.Free;
          end;
        end;
    end;
end;

procedure TrdDesktopViewer.CreateParams(var params: TCreateParams);
begin
  inherited CreateParams(params);
  params.ExStyle := params.ExStyle or WS_EX_APPWINDOW;
  params.WndParent := GetDesktopWindow;
end;

function TrdDesktopViewer.AddProgressDialog(ATaskId: TTaskId; AUserName: String): PProgressDialogData;
begin
  New(Result);
  Result^.taskId := ATaskId;
  New(Result^.ProgressDialog);
  Result^.ProgressDialog^ := TProgressDialog.Create(Self);
  Result^.UserName := AUserName;

  FProgressDialogsList.Add(Result);
end;

function TrdDesktopViewer.GetProgressDialogData(ATaskId: TTaskId): PProgressDialogData;
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

function TrdDesktopViewer.GetProgressDialogData(AProgressDialog: PProgressDialog): PProgressDialogData;
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

procedure TrdDesktopViewer.RemoveProgressDialog(ATaskId: TTaskId);
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

procedure TrdDesktopViewer.RemoveProgressDialogByValue(AProgressDialog: PProgressDialog);
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

procedure TrdDesktopViewer.RemoveProgressDialogByUserName(AUserName: String);
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

//procedure TrdDesktopViewer.WMActivate(var Message: TMessage);
//begin
//  if ((Message.WParam = WA_ACTIVE)
//    or (Message.WParam = WA_CLICKACTIVE)) then
//    SetForegroundWindow(Handle);
//end;

//procedure TrdDesktopViewer.WndProc(var Msg: TMessage);
//begin
//  case Msg.Msg of
//    WM_SYSCOMMAND:
//    begin
//      case Msg.WParam of
//      SC_MINIMIZE, SC_SCREENSAVE:
//        begin
//          Application.Minimize;
//          Msg.Result := 1;
//        end;
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
//         {and (not isClosing)} then
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

//function checkControl:string;
//begin
//  {$IFNDEF RtcViewer}
//  Result:='Control';
//  {$ELSE}
//  Result:='View';
//  {$ENDIF}
//end;

procedure TrdDesktopViewer.aBlockKeyboardMouseExecute(Sender: TObject);
begin
  aBlockKeyboardMouse.Checked := not aBlockKeyboardMouse.Checked;

  if aBlockKeyboardMouse.Checked then
    ActiveUIModule.UI.Send_BlockKeyboardAndMouse
  else
    ActiveUIModule.UI.Send_UnBlockKeyboardAndMouse;
end;

{procedure TrdDesktopViewer.AcceptFiles( var msg : TMessage );
const
  cnMaxFileNameLen = 1024;
var
  i,
  nCount     : integer;
  acFileName : array [0..cnMaxFileNameLen] of char;
  myFileName : string;
begin
  // find out how many files we're accepting
  nCount := DragQueryFile( msg.WParam,
                           $FFFFFFFF,
                           acFileName,
                           cnMaxFileNameLen );

  try
    // query Windows one at a time for the file name
    for i := 0 to nCount-1 do
      begin
      DragQueryFile( msg.WParam, i, acFileName, cnMaxFileNameLen );

      if assigned(PFileTrans) then
        begin
        myFileName:=acFileName;
        PFileTrans.Send(UI.UserName, myFileName);
        end;
      end;
  finally
    // let Windows know that you're done
    DragFinish( msg.WParam );
    end;
end;}

procedure TrdDesktopViewer.aScreenshotToCbrdExecute(Sender: TObject);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  Bitmap.SetSize(ActiveUIModule.UI.ScreenWidth, ActiveUIModule.UI.ScreenHeight);
  ActiveUIModule.UI.DrawScreen(Bitmap.Canvas, Bitmap.Width, Bitmap.Height);

//  Bitmap.Width := myUI.GetScreen.Image.Width;
//  Bitmap.Height := myUI.GetScreen.Image.Height;

//  Bitmap.Canvas.CopyRect(Rect(0,0, Bitmap.Width, Bitmap.Height), myUI.GetScreen.Image.Canvas,
//   Rect(0, 0, Bitmap.Width, Bitmap.Height));

  try
    ClipBoard.Assign(Bitmap);
  except
    on E: Exception do
      xLog('aScreenshotToCbrdExecute. Error: ' + E.ClassName + '. ' + E.Message);
  end;
  Bitmap.Free;
end;

procedure TrdDesktopViewer.aScreenshotToFileExecute(Sender: TObject);
var
  Bitmap: TBitmap;
  saveDialog : TSaveDialog;
begin
  saveDialog := TSaveDialog.Create(nil);
  saveDialog.Title := 'Выберите место для сохранения';
  saveDialog.InitialDir := GetCurrentDir;
  saveDialog.Filter := 'Bitmap file|*.bmp';
  saveDialog.DefaultExt := 'bmp';
  saveDialog.FilterIndex := 1;
  saveDialog.Options := [ofOverwritePrompt, ofPathMustExist];
  saveDialog.FileName := StringReplace(Caption + '_' + DateTimeToStr(Now), ':', '_', [rfReplaceAll]);

  if saveDialog.Execute then
  begin
    try
      if FileExists(saveDialog.FileName) then
        DeleteFile(saveDialog.FileName);
    except
      on E: Exception do
        xLog('aScreenshotToFileExecute. Error: ' + E.ClassName + '. ' + E.Message);
    end;

    Bitmap := TBitmap.Create;

    Bitmap.SetSize(ActiveUIModule.UI.ScreenWidth, ActiveUIModule.UI.ScreenHeight);
    ActiveUIModule.UI.DrawScreen(Bitmap.Canvas, Bitmap.Width, Bitmap.Height);

//    Bitmap.Width := myUI.GetScreen.Image.Width;
//    Bitmap.Height := myUI.GetScreen.Image.Height;
//    Bitmap.Canvas.CopyRect(Rect(0,0, Bitmap.Width, Bitmap.Height), myUI.GetScreen.Image.Canvas,
//      Rect(0, 0, Bitmap.Width, Bitmap.Height));
    try
      Bitmap.SaveToFile(saveDialog.FileName);
    except
      on E: Exception do
        xLog('aScreenshotToFileExecute. Error: ' + E.ClassName + '. ' + E.Message);
    end;
    Bitmap.Free;
  end;
  saveDialog.Free;
end;

procedure TrdDesktopViewer.aSendShortcutsExecute(Sender: TObject);
begin
  aSendShortcuts.Checked := not aSendShortcuts.Checked;
  ActiveUIModule.UI.Module.SendShortcuts := aSendShortcuts.Checked;
  SetShortcuts_Hook(aSendShortcuts.Checked);
end;

procedure TrdDesktopViewer.aShowRemoteCursorExecute(Sender: TObject);
begin
//  UI.RemoteCursor := not UI.RemoteCursor;
//  pImage.Repaint;
//
//  aShowRemoteCursor.Checked := UI.RemoteCursor;
end;

procedure TrdDesktopViewer.lCloseClick(Sender: TObject);
begin
//  if not MiniPanelDraggging then
//    Close;
//  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.aStretchScreenExecute(Sender: TObject);
begin
  aStretchScreen.Checked := not aStretchScreen.Checked;

  DoResizeImage;
end;

procedure TrdDesktopViewer.UIHaveScreeenChanged(Sender: TObject);
begin
  if TRtcPDesktopControlUI(Sender).HaveScreen then
    TimerResize.Enabled := True;
end;

procedure TrdDesktopViewer.DoResizeImage;
var
  Scale: Real;
begin
//    if iPrepare.Visible then
      SetFormState;

  lState.Left := 0;
  lState.Width := ClientWidth;

  panOptionsMini.Top := 0;
  ammbActions.Left := Ceil((ClientWidth - ammbActions.Width) / 2);

  if (panOptionsMini.Left < (ClientWidth * 5 div 100)) then
    panOptionsMini.Left := (ClientWidth * 5 div 100)
  else
  if (panOptionsMini.Left > (ClientWidth - ClientWidth * 5 div 100) - panOptionsMini.Width) then
    panOptionsMini.Left := ClientWidth - (ClientWidth * 5 div 100) - panOptionsMini.Width;

//  Scroll.Left := 0;
//  Scroll.Top := panOptions.Top + panOptions.Height;
//  Scroll.Width := ClientWidth;
//  Scroll.Height := ClientHeight - panOptions.Top + panOptions.Height;

  if (ActiveUIModule <> nil)
    and (ActiveUIModule.UI.HaveScreen) then
  begin
    if aStretchScreen.Checked then
    begin
      ActiveUIModule.pImage^.Align := alClient;
//      pImage.Width := myUI.ScreenWidth;
//      pImage.Height := myUI.ScreenHeight;
      Scroll.HorzScrollBar.Visible := False;
      Scroll.VertScrollBar.Visible := False;
//      if pImage.Width < Screen.Width then
//        pImage.Left := (Screen.Width - pImage.Width) div 2
//      else
//        pImage.Left := 0;
//      if pImage.Height < Screen.Height then
//        pImage.Top := (Screen.Height - pImage.Height) div 2
//      else
//        pImage.Top := 0;
    end
    else
    begin
      ActiveUIModule.pImage^.Align := alNone;

      if (ActiveUIModule.UI.ScreenWidth <= ClientWidth)
        and (ActiveUIModule.UI.ScreenHeight <= ClientHeight) then
      begin
        ActiveUIModule.pImage^.Width := ActiveUIModule.UI.ScreenWidth;
        ActiveUIModule.pImage^.Height := ActiveUIModule.UI.ScreenHeight;
        ActiveUIModule.pImage^.Left := (ClientWidth - ActiveUIModule.UI.ScreenWidth) div 2;
        ActiveUIModule.pImage^.Top := (ClientHeight - ActiveUIModule.UI.ScreenHeight) div 2;
      end
      else
      begin
        if (ActiveUIModule.UI.ScreenWidth > ClientWidth)
          or (ActiveUIModule.UI.ScreenHeight > ClientHeight) then
        begin
          if ClientWidth / ActiveUIModule.UI.ScreenWidth < ClientHeight / ActiveUIModule.UI.ScreenHeight then
            Scale := ClientWidth / ActiveUIModule.UI.ScreenWidth
          else
            Scale := ClientHeight / ActiveUIModule.UI.ScreenHeight;
        end
        else
        begin
          if ClientWidth / ActiveUIModule.UI.ScreenWidth > ClientHeight / ActiveUIModule.UI.ScreenHeight then
            Scale := ClientWidth / ActiveUIModule.UI.ScreenWidth
          else
            Scale := ClientHeight / ActiveUIModule.UI.ScreenHeight;
        end;
        ActiveUIModule.pImage^.Width := Floor(ClientWidth * Scale);
        ActiveUIModule.pImage^.Height := Floor(ClientHeight * Scale);
        ActiveUIModule.pImage^.Left := (ClientWidth - ActiveUIModule.pImage^.Width) div 2;
        ActiveUIModule.pImage^.Top := (ClientHeight - ActiveUIModule.pImage^.Height) div 2;
      end;

      Scroll.HorzScrollBar.Visible := False;
      Scroll.VertScrollBar.Visible := False;
    end;
  end;
end;

procedure TrdDesktopViewer.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;
begin
  DesktopTimer.Enabled := False;
  Action := caHide;

//  if not aRecordStart.Enabled then
//    Avi.Free;

  RecordCancel;

  SetShortcuts_Hook(False); //Доделать

  FreeAndNil(PFileTrans);

  MainChromeTabs.Tabs.Clear;

  for i := 0 to FProgressDialogsList.Count - 1 do
  begin
    FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
    Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
    Dispose(FProgressDialogsList[i]);
  end;
  FProgressDialogsList.Clear;
//  FreeAndNil(FProgressDialogsList);

  ActiveUIModule := nil;

  for i := 0 to UIModulesList.Count - 1 do
  begin
//    TUIDataModule(UIModulesList[i]).UI.CloseAndClear;
//    TUIDataModule(UIModulesList[i]).FT_UI.CloseAndClear;
    FreeAndNil(TUIDataModule(UIModulesList[i]));
  end;
  UIModulesList.Clear;
//  FreeAndNil(UIModulesList);
end;

procedure TrdDesktopViewer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  i: Integer;
begin
//  Hide;

  for i := 0 to UIModulesList.Count - 1 do
  begin
    if aHideWallpaper.Checked then
//    try
//      if ActiveUIModule.UI.Active then
        TUIDataModule(UIModulesList[i]).UI.Send_ShowDesktop;
//    except
//    end;

    if aLockSystemOnClose.Checked then
//    try
//      if ActiveUIModule.UI.Active then
        TUIDataModule(UIModulesList[i]).UI.Send_LockSystem;
//    except
//    end;

    Sleep(100);

    TUIDataModule(UIModulesList[i]).UI.Active := False;
//    TRtcHTTPPortalClient(TUIDataModule(UIModulesList[i]).UI.Module.Client).Active := False;
//    TRtcHTTPPortalClient(TUIDataModule(UIModulesList[i]).UI.Module.Client).Stop;
    try
      TUIDataModule(UIModulesList[i]).UI.Module.Close(TUIDataModule(UIModulesList[i]).UserName);
    except
    end;
    try
      TUIDataModule(UIModulesList[i]).UI.CloseAndClear;
    except
    end;
    try
      TUIDataModule(UIModulesList[i]).FT_UI.CloseAndClear;
    except
    end;
    try
      TUIDataModule(UIModulesList[i]).FT_UI.Close;
    except
    end;
//    FreeAndNil(TUIDataModule(UIModulesList[i]));
    FOnUIClose('desk', TUIDataModule(UIModulesList[i]).UserName);
  end;

  DesktopTimer.Enabled := False;
end;

procedure TrdDesktopViewer.FormCreate(Sender: TObject);
begin
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_APPWINDOW);

  {$IFDEF USE_GLASS_FORM}
  Self.ChromeTabs := MainChromeTabs;
  {$ENDIF}

  ActiveUIModule := nil;
  FProgressDialogsList := TList.Create;

//  fFirstScreen := True;

  pMain.Color := clWhite; //$00A39323;
  Scroll.Visible := False;
  iPrepare.Visible := True;
  panOptionsMini.Left := ClientWidth - (ClientWidth * 5 div 100);
  iScreenLocked.Visible := False;
  lState.Caption := 'Инициализация изображения...';
  lState.Visible := True;
  lState.Left := 0;
  lState.Width := ClientWidth;
  Scroll.Visible := False;

//  MainChromeTabs.Visible := True;

  panOptions.Visible := True;
  MiniPanelDraggging := False;
  aStretchScreen.Checked := False;

  aOptimizeSpeed.Checked := True;

  FormHandle := Handle;

  aSendShortcuts.Checked := True;
//  UI.Module.SendShortcuts := True;
  SetShortcuts_Hook(True); //Доделать

  Visible := False; //позже ставим True если не отменено в пендинге

//  PFileTrans := TRtcPFileTransfer.Create(Self);

  UIModulesList := TList.Create;
end;

procedure TrdDesktopViewer.myUILogOut(Sender: TRtcPDesktopControlUI);
begin
//  Memo1.Lines.Add('myUILogOut');
//  Close;
end;

procedure TrdDesktopViewer.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  ActiveUIModule.UI.SendMouseWheel(WheelDelta, Shift);
  Handled := True;
end;

procedure TrdDesktopViewer.FormResize(Sender: TObject);
begin
  panOptionsMini.Left := ClientWidth - (ClientWidth * 5 div 100);

  DoResizeImage;
end;

procedure TrdDesktopViewer.FT_UIClose(Sender: TRtcPFileTransferUI);
begin
  RemoveProgressDialogByUserName(Sender.UserName);
end;

procedure TrdDesktopViewer.FT_UILogOut(Sender: TRtcPFileTransferUI);
begin
  RemoveProgressDialogByUserName(Sender.UserName);
end;

procedure TrdDesktopViewer.FT_UINotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend);
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
      pPDData^.ProgressDialog^.fHwndParent := FLastActiveExplorerHandle;
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


//  if Sender.Recv_BytesTotal = Sender.Recv_BytesComplete then
//    FProgressDialog.Stop;
end;

{procedure TrdDesktopViewer.FT_UIRecv(Sender: TRtcPFileTransferUI);
begin
//  Memo1.Lines.Add(IntToStr(Sender.Recv_FileCount) + ' - ' + Sender.Recv_FileName + ' - ' + IntToStr(Sender.Recv_BytesComplete) + ' - '+ IntToStr(Sender.Recv_BytesTotal));
  FProgressDialog.TextLine1 := FT_UI.Recv_FileName;

  if FT_UI.Recv_BytesTotal > 0 then
    FProgressDialog.Position := Round(FT_UI.Recv_BytesComplete * 100 / FT_UI.Recv_BytesTotal)
  else
    FProgressDialog.Position := 0;

  if FT_UI.Recv_BytesTotal > 1024 * 1024 * 1024 then
    FProgressDialog.TextFooter := FormatFloat('0.00', FT_UI.Recv_BytesComplete / (1024 * 1024 * 1024)) + ' GB из ' + FormatFloat('0.00', FT_UI.Recv_BytesTotal / (1024 * 1024 * 1024)) + ' GB'
  else
  if FT_UI.Recv_BytesTotal > 1024 * 1024 then
    FProgressDialog.TextFooter := FormatFloat('0.00', FT_UI.Recv_BytesComplete / (1024 * 1024)) + ' MB из ' + FormatFloat('0.00', FT_UI.Recv_BytesTotal / (1024 * 1024)) + ' MB'
  else
    FProgressDialog.TextFooter := FormatFloat('0.00', FT_UI.Recv_BytesComplete / 1024) + ' KB из ' + FormatFloat('0.00', FT_UI.Recv_BytesTotal / 1024) + ' KB';
end;

procedure TrdDesktopViewer.FT_UIRecvCancel(Sender: TRtcPFileTransferUI);
begin
  FProgressDialog.Stop;
end;

procedure TrdDesktopViewer.FT_UIRecvStart(Sender: TRtcPFileTransferUI);
begin
  if FT_UI.Recv_FirstTime then
  begin
    FProgressDialog.Title := 'Копирование';
    FProgressDialog.CommonAVI := TCommonAVI.aviCopyFiles;
    FProgressDialog.TextLine1 := FT_UI.Recv_FileName;
    FProgressDialog.TextLine2 := FT_UI.Recv_ToFolder;
    FProgressDialog.Max := 100;
    FProgressDialog.Position := 0;
    FProgressDialog.TextCancel := 'Прерывание...';
    FProgressDialog.OnCancel := OnProgressDialogCancel;
//    FProgressDialog.AutoCalcFooter := True;
    FProgressDialog.fHwndParent := FLastActiveExplorerHandle;
    FProgressDialog.Execute;
  end;
end;

procedure TrdDesktopViewer.FT_UIRecvStop(Sender: TRtcPFileTransferUI);
begin
  FProgressDialog.Stop
end;}

procedure TrdDesktopViewer.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_LWIN: LWinDown := True;
    VK_RWIN: RWinDown := True;
    end;

  if LWinDown or RWinDown then
    begin
    if Key = Ord('W') then
    begin
      ActiveUIModule.pImage^.Align := alNone;
      if BorderStyle <> bsNone then
        FullScreen
      else
        InitScreen;
      Key := 0;
      Exit;
    end
    else if Key = Ord('S') then
    begin
//      if aStretchScreen.Checked then
//        ActiveUIModule.pImage^.Align := alClient
//      else
//        ActiveUIModule.pImage.Align := alNone;
      if (ActiveUIModule.UI.ScreenWidth >= Screen.Width) or
         (ActiveUIModule.UI.ScreenHeight >= Screen.Height) then
      begin
        if BorderStyle <> bsNone then
          FullScreen
        else
          InitScreen;
        end
      else
        InitScreen;

      DoResizeImage;

      Exit;
    end;
  end;
  if ActiveUIModule.UI.ControlMode <> rtcpNoControl then
    ActiveUIModule.UI.SendKeyDown(Key, Shift);
  Key := 0;
end;

procedure TrdDesktopViewer.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  temp:Word;
begin
  if (LWinDown or RWinDown) and (Key in [Ord('S'), Ord('W')]) then
    Exit;

  case Key of
    VK_LWIN: LWinDown := False;
    VK_RWIN: RWinDown := False;
    end;

  if ActiveUIModule.UI.ControlMode <> rtcpNoControl then
  begin
    temp := Key; // a work-around for Internal Error in Delphi 7 compiler
    ActiveUIModule.UI.SendKeyUp(temp, Shift);
  end;
  Key := 0;
end;

procedure TrdDesktopViewer.FormDeactivate(Sender: TObject);
begin
  if (ActiveUIModule <> nil) then
    ActiveUIModule.UI.Deactivated;

  LWinDown := False;
  RWinDown := False;
  LMouseDown := False;
  LMouseD := False;
  RMouseDown := False;
//  pImage.Cursor := 200; // small dot
end;

procedure TrdDesktopViewer.FormDestroy(Sender: TObject);
//var
//  i: Integer;
begin
//  for i := 0 to FProgressDialogsList.Count - 1 do
//  begin
//    FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
//    Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
//    Dispose(FProgressDialogsList[i]);
//  end;
//  FProgressDialogsList.Clear;
  FreeAndNil(FProgressDialogsList);

//  for i := 0 to UIModulesList.Count - 1 do
//  begin
////    TUIDataModule(UIModulesList[i]).UI.CloseAndClear;
////    TUIDataModule(UIModulesList[i]).FT_UI.CloseAndClear;
//    FreeAndNil(TUIDataModule(UIModulesList[i]));
//  end;
//  UIModulesList.Clear;
  FreeAndNil(UIModulesList);
end;

{procedure TrdDesktopViewer.SetCaption;
begin
  if myUI.UserDesc <> '' then
    Caption := myUI.UserDesc// + ' - Управление' // + checkControl
  else
    Caption := GetUserFromFromUserName(myUI.UserName);
end;}

procedure TrdDesktopViewer.myUIOpen(Sender: TRtcPDesktopControlUI);
//var
//  fIsPending: Boolean;
begin
//  Memo1.Lines.Add('myUIOpen');
//  if Assigned(FOnUIOpen) then
//    FOnUIOpen(Sender.UserName, 'desk', fIsPending);

//  if not fIsPending then //Если подключение отменено закрываем
//  begin
//    Close;
//    Exit;
//  end
//  else
//  begin
//    Show;
//    BringToFront;
//    //BringWindowToTop(Handle);
//    SetForegroundWindow(Handle);
//  end;

  //pImage.Align := alClient; //Доделать


//  if aStretchScreen.Checked then
//    pImage.Align := alClient;
//  else
//    pImage.Align := alNone;

//  if myUI.UserDesc <> '' then
//    Caption := myUI.UserDesc// + ' - Управление' // + checkControl
//  else
//  begin
//    if Pos(myUI.UserName, '_') > 0 then
//      Caption := Copy(myUI.UserName, 1, Pos(myUI.UserName, '_') - 1)
//    else
//      Caption := myUI.UserName;
//  end;
//  SetCaption;
//  sStatus.Font.Color:=clWhite;
//  sStatus.Caption := 'Подготовка рабочего стола. Пожалуйста подождите ...';
//  sStatus.Visible := True;

  WindowState := wsMaximized;
  BorderStyle := bsSizeable;
//  Width := 400;
//  Height := 90;
  Scroll.HorzScrollBar.Position := 0;
  Scroll.VertScrollBar.Position := 0;

//  BringToFront;
//  BringWindowToTop(Handle);

  aHideWallpaper.Checked := True;
  Sender.Send_HideDesktop(Sender);
//  aOptimalScale.Checked := UI.SmoothScale;

  //tell Windows that you're accepting drag and drop files
//  if Assigned(PFileTrans) then
//    DragAcceptFiles( Handle, True );

//    UpdateQuality;

  DoResizeImage;
end;

procedure TrdDesktopViewer.OnProgressDialogCancel(Sender: TObject);
var
  pPDData: PProgressDialogData;
begin
  pPDData := GetProgressDialogData(PProgressDialog(@Sender));
  if pPDData <> nil then
    ActiveUIModule.FT_UI.Module.CancelBatch(ActiveUIModule.FT_UI.Module, pPDData^.taskId);

  TProgressDialog(Sender).Stop;
  RemoveProgressDialogByValue(@Sender);
end;

procedure TrdDesktopViewer.myUIClose(Sender: TRtcPDesktopControlUI);
begin
//  Memo1.Lines.Add('myUIClose');
  DesktopTimer.Enabled := False;
//  pImage.Align := alNone;

//  Caption := Caption + ' - Closed by Host';
//  sStatus.Font.Color := clRed;
//  sStatus.Caption := 'Desktop session closed by Host.';
//  sStatus.Visible := True;

//  WindowState := wsNormal;
//  BorderStyle := bsSizeable;
//  Width := 400;
//  Height := 90;
//  Scroll.HorzScrollBar.Position := 0;
//  Scroll.VertScrollBar.Position := 0;
//  MessageBeep(0);

  //tell Windows that you're accepting drag and drop files
  //DragAcceptFiles(Handle, False);

  ActiveUIModule.TimerReconnect.Enabled := True;
//  Close;
end;

procedure TrdDesktopViewer.myUIError(Sender: TRtcPDesktopControlUI);
begin
//  Memo1.Lines.Add('myUIError');
  DesktopTimer.Enabled := False;
//  pImage.Align := alNone;

//  Caption:=Caption+' - Disconnected';
//  sStatus.Font.Color := clRed;
//  sStatus.Caption := 'Desktop session terminated.';
//  sStatus.Visible := True;

//  WindowState := wsNormal;
//  BorderStyle := bsSizeable;
////  Width := 400;
////  Height := 90;
//  Scroll.HorzScrollBar.Position := 0;
//  Scroll.VertScrollBar.Position := 0;
////  MessageBeep(0);

  //tell Windows that you're accepting drag and drop files
//  DragAcceptFiles(Handle, False);

//  myUI.Active := True;
//  Close; //Доделать
end;

procedure TrdDesktopViewer.myUIData(Sender: TRtcPDesktopControlUI);
var
  UIDM: TUIDataModule;
begin
  UIDM := TUIDataModule(TTimer(Sender).Owner);

  UIDM.FImageChanged := True;
  if Assigned(UIDM.FVideoRecorder) then
    begin
      LockVideoImage(UIDM);
      try
        UIDM.FVideoImage.Canvas.Draw(0, 0, Sender.Playback.Image);
      finally
        UnlockVideoImage(UIDM);
      end;
    end;

  //Подгонка размера изображения
  if (UIDM <> nil) and {fFirstScreen and} Sender.HaveScreen then
  begin
//    if myUI.UserDesc <> '' then
//      Caption := myUI.UserDesc// + ' - Управление' //+ checkControl
//    else
//      Caption := myUI.UserName;// + ' - Управление'; // + checkControl;
//    SetCaption;
//    sStatus.Visible:=False;
//    fFirstScreen := False;
//    WindowState := wsMaximized;
//    if Sender.ScreenWidth < ActiveUIModule.pImage.ClientWidth then
//      ClientWidth := Sender.ScreenWidth
//    else
//      ClientWidth := Screen.Width;
//    if Sender.ScreenHeight < ClientHeight then
//      ClientHeight := Sender.ScreenHeight
//    else
//      Height := Screen.Height;
//    if myUI.ScreenHeight >= Screen.Height then  //sstuman
//    begin
//      Left := 0;
//      Top := 0;

//    end  //sstuman
//    else
//    begin
//      WindowState := wsNormal;
//      Left := (Screen.Width - Width) div 2;
//      Top := (Screen.Height - Height) div 2;
//    end;
    //tell Windows that you're accepting drag and drop files
//    if Assigned(PFileTrans) then
//      DragAcceptFiles(Handle, True);
    DesktopTimer.Enabled := True;
  end;
end;

procedure TrdDesktopViewer.ScrollMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
//  if MyUI.ControlMode = rtcpNoControl then
//    Exit;

  //if not (panSettings.Visible or panOptions.Visible) then
  //  begin
    //Доделать
//    btnCycle.Down := BorderStyle=bsNone;
//    if btnCycle.Down then
//      btnCycle.Hint:='To Windowed mode'
//    else
//      btnCycle.Hint:='To Full Screen mode';
//    btnSmoothScale.Down:=UI.SmoothScale;
//    aBlockKeyboard.Checked := UI.MapKeys;
//    aBlockMouse.Checked := UI.ExactCursor;
//    panOptions.Left := (Width - panOptions.Width) div 2;
//    panOptions.Top := 0;
//    panOptionsMini.Top := panOptions.Top + panOptions.Height;
//    panOptionsMini.Left := panOptions.Left + panOptions.Width - panOptionsMini.Width - 15;
//    panOptions.Visible := True;
  //  end;

//  if not (panSettings.Visible or panOptions.Visible) then
//    begin
//    btnCycle.Down := BorderStyle=bsNone;
//    if btnCycle.Down then btnCycle.Hint:='To Windowed mode'
//    else btnCycle.Hint:='To Full Screen mode';
//    btnSmoothScale.Down:=UI.SmoothScale;
//    aBlockKeyboard.Checked := UI.MapKeys;
//    aBlockMouse.Checked := UI.ExactCursor;
//    panOptions.Left:=10;
//    panOptions.Top:=10;
//    panOptions.Visible:=True;
//    end;
end;

procedure TrdDesktopViewer.pImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
//  if MyUI.ControlMode = rtcpNoControl then
//    begin
//    if LMouseD then
//      SetBounds(Left+X-LMouseX,Top+Y-LMouseY,Width,Height);
//    end;
//  else if not (LMouseDown or RMouseDown) then
//    begin
////    if panOptions.Visible then
////      begin
////      if (Y + pImage.Left > panOptions.Height + 15) or (X + pImage.Top > panOptions.Width + 15) then
////        begin
////        panOptions.Visible := False;
////        panSettings.Visible := False;
////        // Hints will bring the main window to Top.
////        // Need to fix this for Full Screen mode.
//////        BringToFront;
//////        BringWindowToTop(Handle);
////        end;
////      end
////    else if not panSettings.Visible then
////      if ( ((Y<5) and (X<5)) or ((Y<2) and (X<panOptions.Width)) ) and
////         ( (pImage.Left<=5) or (pImage.Top<=5) ) then
//    else
//    if not panSettings.Visible then
//      if (Y < 20) and ((X >= panOptions.Left)) and (X <= panOptions.Left + panOptions.Width) then
//      ScrollMouseMove(Sender, Shift, X, Y);
//    end;
end;

procedure TrdDesktopViewer.pImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
//  if myUI.ControlMode=rtcpNoControl then
//    begin
//    if Button=mbLeft then
//      begin
//      LMouseD:=True;
//      LMouseX:=X;LMouseY:=Y;
//      end;
//    end
//  else
//    begin
    if Button = mbLeft then
      LMouseDown := True;
    if Button = mbRight then
      RMouseDown := True;
//    if (panOptions.Visible or panSettings.Visible) then
//      begin
//      // if the user clicks somewhere on the screen, auto-cancel the Settings panel
//      panOptions.Visible:=False;
//      panSettings.Visible:=False;
//      end;
//    end;
end;

procedure TrdDesktopViewer.btnSettingsClick(Sender: TObject);
begin
//  panOptions.Visible:=False;

  panSettings.Left := 10;
  panSettings.Top := 10;
  panSettings.Visible := True;

//  // Clear Host Settings
//  grpScreenBlocks.ItemIndex:=-1;
//  grpScreenBlocks2.ItemIndex:=-1;
//  grpScreen2Refine.ItemIndex:=-1;
//  grpScreenLimit.ItemIndex:=-1;
//  grpLayered.ItemIndex:=-1;
//  grpMirror.ItemIndex:=-1;
//  grpMouse.ItemIndex:=-1;
//  grpMonitors.ItemIndex:=-1;
//  grpColor.ItemIndex:=-1;
//  grpFrame.ItemIndex:=-1;
//  grpColorLow.ItemIndex:=-1;
//  cbReduceColors.Value:=0;
//  cbReduceColors.Enabled:=False;
//  cbReduceColors.Color:=clBtnFace;
end;

procedure TrdDesktopViewer.btnCancelClick(Sender: TObject);
begin
  panSettings.Visible := False;
end;

procedure TrdDesktopViewer.aChatExecute(Sender: TObject);
begin
  PChat.Open(ActiveUIModule.UI.UserName, Sender);
end;

procedure TrdDesktopViewer.aCtrlAltDelExecute(Sender: TObject);
begin
  ActiveUIModule.UI.Send_CtrlAltDel;
end;

procedure TrdDesktopViewer.aFileTransferExecute(Sender: TObject);
begin
  if Assigned(FDoStartFileTransferring) then
    FDoStartFileTransferring(ActiveUIModule.UI.UserName, ActiveUIModule.UI.UserDesc, '', True);
end;

procedure TrdDesktopViewer.aFullScreenExecute(Sender: TObject);
begin
  if (ActiveUIModule.UI.ScreenWidth >= Screen.Width) or
     (ActiveUIModule.UI.ScreenHeight >= Screen.Height) then
  begin
    if BorderStyle <> bsNone then
      FullScreen
    else
      InitScreen;
    end
  else
  begin
    if BorderStyle <> bsNone then
    begin
      FullScreen;
    end
    else
    begin
      InitScreen;
    end;
  end;

//  if aStretchScreen.Checked then
//    ActiveUIModule.pImage^.Align := alClient
//  else
//    ActiveUIModule.pImage^.Align := alNone;

  DoResizeImage;

  aFullScreen.Checked := not aFullScreen.Checked;
end;

procedure TrdDesktopViewer.aHideWallpaperExecute(Sender: TObject);
begin
  if not aHideWallpaper.Checked then
    ActiveUIModule.UI.Send_HideDesktop(Sender)
  else
    ActiveUIModule.UI.Send_ShowDesktop(Sender);

  aHideWallpaper.Checked := not aHideWallpaper.Checked;
end;

procedure TrdDesktopViewer.aLockSystemExecute(Sender: TObject);
begin
  ActiveUIModule.UI.Send_LockSystem(Sender);
end;

procedure TrdDesktopViewer.aLockSystemOnCloseExecute(Sender: TObject);
begin
  aLockSystemOnClose.Checked := not aLockSystemOnClose.Checked;
end;

procedure TrdDesktopViewer.aLogoffExecute(Sender: TObject);
begin
  ActiveUIModule.UI.Send_LogoffSystem(Sender);
end;

procedure TrdDesktopViewer.aOptimalScaleExecute(Sender: TObject);
begin
//  UI.SmoothScale := not UI.SmoothScale;
//  pImage.Repaint;
//
//  aOptimalScale.Checked := UI.SmoothScale;
end;

procedure TrdDesktopViewer.UpdateQuality;
begin
  if ActiveUIModule = nil then
    Exit;

  if aOptimizeQuality.Checked then
  begin
    ActiveUIModule.UI.ChgDesktop_Begin;
    try
      ActiveUIModule.UI.ChgDesktop_ColorLimit(rdColor32bit);
//      UI.ChgDesktop_FrameRate(rdFramesMax);
//      UI.ChgDesktop_SendScreenInBlocks(rdBlocks1);
//      UI.ChgDesktop_SendScreenRefineBlocks(rdBlocks12);
  //    UI.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);
//      UI.ChgDesktop_SendScreenSizeLimit(rdBlockAnySize);
  //    if grpColorLow.ItemIndex>=0 then
  //      begin
        ActiveUIModule.UI.ChgDesktop_ColorLowLimit(rd_ColorHigh);
  //      UI.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
  //      end;
    finally
      ActiveUIModule.UI.ChgDesktop_End;
    end;
  end
  else
  begin
    ActiveUIModule.UI.ChgDesktop_Begin;
    try
      ActiveUIModule.UI.ChgDesktop_ColorLimit(rdColor8bit);
//      UI.ChgDesktop_FrameRate(rdFramesMax);
//      UI.ChgDesktop_SendScreenInBlocks(rdBlocks1);
//      UI.ChgDesktop_SendScreenRefineBlocks(rdBlocks12);
//  //    UI.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);
//      UI.ChgDesktop_SendScreenSizeLimit(rdBlockAnySize);
//  //    if grpColorLow.ItemIndex>=0 then
//  //      begin
        ActiveUIModule.UI.ChgDesktop_ColorLowLimit(rd_ColorHigh);
//  //      UI.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
//  //      end;
  //      end;
    finally
      ActiveUIModule.UI.ChgDesktop_End;
    end;
  end;
end;

procedure TrdDesktopViewer.aOptimizeQualityExecute(Sender: TObject);
begin
  if not aOptimizeQuality.Checked then
  begin
    aOptimizeQuality.Checked := not aOptimizeQuality.Checked;
    aOptimizeSpeed.Checked := not aOptimizeQuality.Checked;

    UpdateQuality;
  end;
end;

procedure TrdDesktopViewer.aOptimizeSpeedExecute(Sender: TObject);
begin
  if not aOptimizeSpeed.Checked then
  begin
    aOptimizeSpeed.Checked := not aOptimizeSpeed.Checked;
    aOptimizeQuality.Checked := not aOptimizeSpeed.Checked;

    UpdateQuality;
  end;
end;

procedure TrdDesktopViewer.aPowerOffMonitorExecute(Sender: TObject);
begin
  aPowerOffMonitor.Checked := not aPowerOffMonitor.Checked;
  aBlockKeyboardMouse.Checked := aPowerOffMonitor.Checked;
  aBlockKeyboardMouse.Enabled := not aPowerOffMonitor.Checked;

  if aPowerOffMonitor.Checked then
    ActiveUIModule.UI.Send_PowerOffMonitor(Sender)
  else
    ActiveUIModule.UI.Send_PowerOnMonitor(Sender);
end;

procedure TrdDesktopViewer.aPowerOffSystemExecute(Sender: TObject);
begin
  ActiveUIModule.UI.Send_PowerOffSystem(Sender);
end;

procedure TrdDesktopViewer.aRecordStopExecute(Sender: TObject);
begin
  DoRecordAction(RECORD_STOP);
end;

//procedure TrdDesktopViewer.aRecordStartExecute(Sender: TObject);
//var
//  saveDialog : TSaveDialog;
//begin
//  saveDialog := TSaveDialog.Create(self);
//  saveDialog.Title := 'Выберите место для сохранения';
//  saveDialog.InitialDir := GetCurrentDir;
//  saveDialog.Filter := 'AVI file|*.avi';
//  saveDialog.DefaultExt := 'avi';
//  saveDialog.FilterIndex := 1;
//  saveDialog.Options := [ofOverwritePrompt, ofPathMustExist];
//
//  if saveDialog.Execute then
//  begin
//    try
//      if FileExists(saveDialog.FileName) then
//        DeleteFile(saveDialog.FileName);
//    except
//      on E: Exception do
//        xLog('aScreenshotToFileExecute. Error: ' + E.ClassName + '. ' + E.Message);
//    end;
//
//    ScreenRecordStart(saveDialog.FileName);
//  end;
//
//  saveDialog.Free;
//end;

procedure TrdDesktopViewer.RecordStart;
var
  rec: TRtcRecord;
  fn: TRtcFunctionInfo;
begin
  if Assigned(ActiveUIModule.FVideoWriter) then
    raise Exception.Create('Video is recording');
  ActiveUIModule.FVideoFile := IncludeTrailingPathDelimiter(RecordsFolder);
  ForceDirectories(ActiveUIModule.FVideoFile);
  ActiveUIModule.FVideoFile := ActiveUIModule.FVideoFile + 'Video_' + FormatDateTime('YYYY_MM_DD_HHNNSS', Now) + '.rmxv';
  ActiveUIModule.FVideoWriter := TRMXVideoWriter.Create(ActiveUIModule.FVideoFile, TRMXVideoFileWin);
  ActiveUIModule.FFirstImageArrived := false;
  ActiveUIModule.UI.Playback.ScreenDecoder.OnSetScreenData := OnSetScreenData;
  // data to send to the user ...
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'restart_desk';
  ActiveUIModule.UI.Module.Client.SendToUser(ActiveUIModule.UI.Module, ActiveUIModule.UI.UserName, fn);
end;

procedure TrdDesktopViewer.RecordStop;
var
  frm: TForm;
  w: TRMXVideoWriter;
begin
  if not Assigned(ActiveUIModule.FVideoWriter) then
    Exit;

  ActiveUIModule.UI.Playback.ScreenDecoder.OnSetScreenData := nil;
  w := ActiveUIModule.FVideoWriter;
  ActiveUIModule.FVideoWriter := nil;
  w.Free;
end;

procedure TrdDesktopViewer.RecordCancel;
begin
//  if not Assigned(FVideoRecorder) then exit;
//  FVideoRecorder.Terminate;
  if (ActiveUIModule = nil)
    or (not Assigned(ActiveUIModule.FVideoWriter)) then
    Exit;

  RecordStop;
  DeleteFile(ActiveUIModule.FVideoFile);
end;

{procedure TrdDesktopViewer.RecordStopWindowProc(var Message: TMessage);
var
  temp: TObject;
begin
  temp := FVideoRecorder;
  FVideoRecorder := nil;
  temp.Free;
  FVideoImage.Free;
  FVideoImage := nil;
  Message.Result := 0;
  TForm(Message.LParam).ModalResult := mrOk;
end;

procedure TrdDesktopViewer.ModalFormRecordStopActivate(Sender: TObject);
begin
  PostMessage(Handle, WM_STOP_RECORD, 0, LPARAM(Sender));
end;

procedure TrdDesktopViewer.OnGetVideoFrame(Sender: TObject);
begin
  if not Assigned(FVideoRecorder) then
    Exit;
//    FVideoRecorder.AddVideoFrame(FVideoImage);
  LockVideoImage;
  try
    TVideoRecorder(Sender).AddVideoFrame(FVideoImage, FImageChanged);
    FImageChanged := false;
  finally
    UnlockVideoImage;
  end;
end;}

procedure TrdDesktopViewer.LockVideoImage(UIDM: TUIDataModule);
begin
  while InterlockedExchange(UIDM.FLockVideoImage, 1) <> 0 do
    SwitchToThread;
end;

procedure TrdDesktopViewer.UnlockVideoImage(UIDM: TUIDataModule);
begin
  InterlockedExchange(UIDM.FLockVideoImage, 0);
end;

procedure TrdDesktopViewer.aRecordStartExecute(Sender: TObject);
begin
  DoRecordAction(RECORD_START);
end;

procedure TrdDesktopViewer.DoRecordAction(Action: Integer);
var
  frm: TForm;
begin
  if Action = RECORD_START then
    begin
      RecordStart();

      if ActiveUIModule <> nil then
      begin
        ActiveUIModule.pImage^.RecordCircleVisible := True;
        ActiveUIModule.pImage^.RecordTicks := 0;
        ActiveUIModule.pImage^.RecordInfo := '00:00:00';
        ActiveUIModule.pImage^.RecordInfoVisible := True;
        ActiveUIModule.pImage^.RecordTicks := NativeInt(GetTickCount);
        ActiveUIModule.pImage^.RecordCircleVisible := True;
        ActiveUIModule.TimerRec.Enabled := True;
      end;
    end
  else
  if Action = RECORD_STOP then
    begin
      RecordStop();

      if ActiveUIModule <> nil then
      begin
        ActiveUIModule.pImage^.RecordCircleVisible := False;
        ActiveUIModule.pImage^.RecordInfoVisible := False;
        ActiveUIModule.TimerRec.Enabled := False;
      end;

//      MessageBox(Handle, PChar('Record finished'), PChar(Application.Title), MB_ICONINFORMATION or MB_OK);
    end
  else
  if Action = RECORD_CANCEL then
    begin
      if MessageBox(Handle, PChar('Do you want to cancel desktop recording?'),
        PChar(Application.Title), MB_ICONASTERISK or MB_YESNO) <> IDYES  then
        Exit;

      RecordCancel();

      if ActiveUIModule <> nil then
      begin
        ActiveUIModule.pImage^.RecordCircleVisible := False;
        ActiveUIModule.pImage^.RecordInfoVisible := False;
        ActiveUIModule.TimerRec.Enabled := False;
      end;

//      MessageBox(Handle, PChar('Record canceled'), PChar(Application.Title), MB_ICONINFORMATION or MB_OK);
    end
  else
  if Action = RECORD_CODEC_INFO then
    begin
      frm := TForm.Create(Self);
      try
        frm.Position := poScreenCenter;
        frm.Width := 600;
        frm.Height := 400;
        frm.Caption := 'Information about specific installed video compressors';
        with TMemo.Create(frm) do
          begin
            Font.Name := 'Consolas';
            Align := alClient;
            Parent := frm;
            ScrollBars := ssBoth;
            TVideoRecorderAVIVFW.ExtractCodecInfo(Lines);
          end;
        frm.ShowModal
      finally
        frm.Free;
      end;
    end;

  aRecordStart.Enabled := not Assigned(ActiveUIModule.FVideoWriter);
  aRecordStop.Enabled := Assigned(ActiveUIModule.FVideoWriter);
  aRecordCancel.Enabled := Assigned(ActiveUIModule.FVideoWriter);
end;

procedure TrdDesktopViewer.aRecordCancelExecute(Sender: TObject);
begin
  DoRecordAction(RECORD_CANCEL);
end;

procedure TrdDesktopViewer.aRecordCodecInfoExecute(Sender: TObject);
begin
  DoRecordAction(RECORD_CODEC_INFO);
end;

procedure TrdDesktopViewer.aRecordOpenFolderExecute(Sender: TObject);
//var
//  dlg: TFileOpenDialog;
begin
//  dlg := TFileOpenDialog.Create(nil);
//  try
//    dlg.DefaultFolder := RecordsFolder;
//    dlg.FileName      := RecordsFolder;
//    dlg.Options       := dlg.Options + [fdoPickFolders];
//    if dlg.Execute then
//      edRecordFolder.Text := dlg.FileName;
//  finally
//    dlg.Free;
//  end;
  if not DirectoryExists(ExtractFilePath(Application.ExeName) + '\' + RecordsFolder) then
    ForceDirectories(ExtractFilePath(Application.ExeName) + '\' + RecordsFolder);
  ShellExecute(Handle, 'open', PWideChar(WideString(ExtractFilePath(Application.ExeName) + '\' + RecordsFolder)), '', '', SW_SHOWNORMAL);
end;

{function TrdDesktopViewer.LeaseExpiresDateToDateTime(LeaseExpires: Integer): String;
var
  Remain: Integer;
begin
//var
//  UnixTime: Double;
//  TimeZoneInformation: TTimeZoneInformation;
//  utime: TDateTime;
//begin
//    UnixTime := StrToInt(Edit1.Text) - 6 * 3600;    // -6 is for Central Standard Time
//    utime:=StrToDate('1/1/1970') + (UnixTime / (24 * 3600));
//    case GetTimeZoneInformation(TimeZoneInformation) of
//        TIME_ZONE_ID_DAYLIGHT: utime := utime -
//(TimeZoneInformation.DaylightBias / (24 * 60));
//        else utime := utime - (TimeZoneInformation.Bias / (24 * 60));
//      end;
//    edit2.Text:=DateTimeToStr(utime);

  Result := '';
  Remain := LeaseExpires div 25;
  Result := Result + IntToStr(Remain div 86400) + ':';
  Remain := Remain - Remain div 86400;
  Result := Result + Format('%2.2d', [Remain div 3600]) + ':';
  Remain := Remain - Remain div 3600;
  Result := Result + Format('%2.2d', [Remain div 60]) + ':';
  Remain := Remain - Remain div 60;
  Result := Result + Format('%2.2d', [Remain]);
end;}

procedure TrdDesktopViewer.lFullScreenClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    aFullScreenExecute(nil);
  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.lHideMiniPanelClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    panOptionsVisibilityChange(not panOptions.Visible);

  DoResizeImage;

  if ActiveUIModule <> nil then
    ActiveUIModule.UI.DrawScreen(ActiveUIModule.pImage^.Canvas, ActiveUIModule.pImage^.Width, ActiveUIModule.pImage^.Height);
end;

procedure TrdDesktopViewer.lMinimizeClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.ControlPolygons(Sender,
  ChromeTabsControl: TObject; ItemRect: TRect; ItemType: TChromeTabItemType;
  Orientation: TTabOrientation; var Polygons: IChromeTabPolygons);
var
  ChromeTabControl: TBaseChromeTabsControl;
  TabTop: Integer;
begin
  if (ItemType = itTab) and
     (ChromeTabsControl is TBaseChromeTabsControl) then
  begin
    ChromeTabControl := ChromeTabsControl as TBaseChromeTabsControl;

    Polygons := TChromeTabPolygons.Create;

    TabTop := 0;

//    if (ChromeTabControl is TChromeTabControl) and
//       (not TChromeTabControl(ChromeTabControl).ChromeTab.GetActive) then
//      Inc(TabTop, 3);

    Polygons.AddPolygon(ChromeTabControl.NewPolygon(ChromeTabControl.BidiControlRect,
                                                    [Point(0, RectHeight(ItemRect)),
                                                     Point(0, TabTop),
                                                     Point(RectWidth(ItemRect), TabTop),
                                                     Point(RectWidth(ItemRect), RectHeight(ItemRect))],
                                 Orientation),
                                 nil,
                                 nil);
  end;
end;

procedure TrdDesktopViewer.GetFilesFromHostClipboard(var Message: TMessage);
var
  i: Integer;
  FileList: TStringList;
  temp_id: TTaskID;
begin
  try
    FLastActiveExplorerHandle := THandle(Message.WParam);

    FileList := TStringList.Create;
    for i := 0 to CB_DataObject.FCount - 1 do
      FileList.Add(CB_DataObject.FFiles[i].filePath);

  //  TRtcPFileTransfer(myUI.Module).NotifyFileBatchSend :=FT_UINotifyFileBatchSend;
    try
      temp_id := ActiveUIModule.FT_UI.Module.FetchBatch(ActiveUIModule.FT_UI.UserName,
                          FileList, ExtractFilePath(CB_DataObject.FFiles[0].filePath), String(Message.LParam), nil);
    except
  //  on E: Exception do
  //    begin
  //      add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
  //      raise;
  //    end;
    end;
  finally
    FileList.Free;
  end;

//  for i := 0 to CB_DataObject.FCount - 1 do
//    FT_UI.Fetch(CB_DataObject.FFiles[i].filePath, String(Message.LParam));
end;

procedure TrdDesktopViewer.aRestartSystemExecute(Sender: TObject);
begin
  ActiveUIModule.UI.Send_RestartSystem(Sender);
end;

procedure TrdDesktopViewer.btnAcceptClick(Sender: TObject);
begin
  panSettings.Visible := False;
  ActiveUIModule.UI.ChgDesktop_Begin;
  try
    if grpLayered.ItemIndex >= 0 then      ActiveUIModule.UI.ChgDesktop_CaptureLayeredWindows(grpLayered.ItemIndex = 0);
    if grpMirror.ItemIndex >= 0 then       ActiveUIModule.UI.ChgDesktop_UseMirrorDriver(grpMirror.ItemIndex = 0);
    if grpMouse.ItemIndex >= 0 then        ActiveUIModule.UI.ChgDesktop_UseMouseDriver(grpMouse.ItemIndex = 0);
    if grpMonitors.ItemIndex >= 0 then     ActiveUIModule.UI.ChgDesktop_CaptureAllMonitors(grpMonitors.ItemIndex = 0);
    if grpColor.ItemIndex >= 0 then        ActiveUIModule.UI.ChgDesktop_ColorLimit(TRdColorLimit(grpColor.ItemIndex));
    if grpFrame.ItemIndex >= 0 then        ActiveUIModule.UI.ChgDesktop_FrameRate(TRdFrameRate(grpFrame.ItemIndex));
    if grpScreenBlocks.ItemIndex >= 0 then ActiveUIModule.UI.ChgDesktop_SendScreenInBlocks(TrdScreenBlocks(grpScreenBlocks.ItemIndex));
    if grpScreenBlocks2.ItemIndex >= 0 then ActiveUIModule.UI.ChgDesktop_SendScreenRefineBlocks(TrdScreenBlocks(grpScreenBlocks2.ItemIndex));
    if grpScreen2Refine.ItemIndex >= 0 then  ActiveUIModule.UI.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);
    if grpScreenLimit.ItemIndex >= 0 then  ActiveUIModule.UI.ChgDesktop_SendScreenSizeLimit(TrdScreenLimit(grpScreenLimit.ItemIndex));
    if grpColorLow.ItemIndex >= 0 then
      begin
      ActiveUIModule.UI.ChgDesktop_ColorLowLimit(TrdLowColorLimit(grpColorLow.ItemIndex));
      ActiveUIModule.UI.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
      end;
  finally
    ActiveUIModule.UI.ChgDesktop_End;
    end;
end;

procedure TrdDesktopViewer.pImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
//  if MyUI.ControlMode = rtcpNoControl then
//  begin
//    if Button = mbLeft then
//      LMouseD := False;
//  end
//  else
//  begin
    if Button = mbLeft then
      LMouseDown := False;
    if Button = mbRight then
      RMouseDown := False;
//  end;
end;

procedure TrdDesktopViewer.grpColorLowChange(Sender: TObject);
begin
  cbReduceColors.Enabled := grpColorLow.ItemIndex > 0;
  if cbReduceColors.Enabled then
    cbReduceColors.Color := clWindow
  else
    cbReduceColors.Color := clBtnFace;
end;

procedure TrdDesktopViewer.DesktopTimerTimer(Sender: TObject);
begin
  if assigned(ActiveUIModule.UI) and ActiveUIModule.UI.InControl and (GetForegroundWindow <> Handle) then
    FormDeactivate(nil);
end;

procedure TrdDesktopViewer.panOptionsMiniMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
begin
  MiniPanelDraggging := False;

  MiniPanelMouseDowned := True;
  p.X := X;
  p.Y := Y;
  p := panOptionsMini.ClientToScreen(p);
  MiniPanelCurX := p.X;
end;

procedure TrdDesktopViewer.panOptionsMiniMouseLeave(Sender: TObject);
begin
  MiniPanelDraggging := False;
  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.panOptionsMiniMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
begin
  GetCursorPos(p);
  if (WindowFromPoint(p) <> panOptionsMini.Handle)
    and (WindowFromPoint(p) <> panOptions.Handle)
    and (WindowFromPoint(p) <> ammbActions.Handle)
    and (WindowFromPoint(p) <> Scroll.Handle) then
  begin
    MiniPanelDraggging := False;
    MiniPanelMouseDowned := False;
  end
  else
  if MiniPanelMouseDowned then
  begin
    MiniPanelDraggging := True;
    p.X := X;
    p.Y := Y;
    p := panOptionsMini.ClientToScreen(p);
    if ((panOptionsMini.Left - MiniPanelCurX + p.X + panOptionsMini.Width) < (ClientWidth - panOptionsMini.Width - ClientWidth * 5 div 100))
      and ((panOptionsMini.Left - MiniPanelCurX + p.X) > (ClientWidth * 5 div 100)) then
      panOptionsMini.Left := panOptionsMini.Left - MiniPanelCurX + p.X;
    MiniPanelCurX := p.X;

//    if ActiveUIModule <> nil then
//      ActiveUIModule.UI.DrawScreen(ActiveUIModule.pImage^.Canvas, ActiveUIModule.pImage^.Width, ActiveUIModule.pImage^.Height);
  end;
end;

procedure TrdDesktopViewer.panOptionsMiniMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
begin
  MiniPanelMouseDowned := False;
  MiniPanelDraggging := False;

  p.X := X;
  p.Y := Y;
  p := panOptionsMini.ClientToScreen(p);
  if p.X = MiniPanelCurX then
    //Перенести сюда события OnClick кнопок?
end;

procedure TrdDesktopViewer.panOptionsMouseLeave(Sender: TObject);
begin
  SendMessage(ammbActions.Handle, WM_NULL, 0, 0);
end;

procedure TrdDesktopViewer.panOptionsVisibilityChange(AVisible: Boolean);
begin
  panOptions.Visible := AVisible;
  if not panOptions.Visible then
  begin
    iShowMiniPanel.Picture.Assign(iMiniPanelShow.Picture);
    iShowMiniPanel.Hint := 'Показать панель действий';

    MiniPanelMouseDowned := False;
    MiniPanelDraggging := False;
  end
  else
  begin
    iShowMiniPanel.Picture.Assign(iMiniPanelHide.Picture);
    iShowMiniPanel.Hint := 'Скрыть панель действий';

    MiniPanelMouseDowned := False;
    MiniPanelDraggging := False;
  end;
end;

procedure TrdDesktopViewer.pImageDblClick(Sender: TObject);
var
  cw, ch:integer;
begin
//if myUI.ControlMode = rtcpNoControl then
//  if BorderStyle = bsSizeable then
//  begin
//    cw := ClientWidth;
//    ch := ClientHeight;
//    BorderStyle := bsNone;
//    ClientWidth := cw;
//    ClientHeight := ch;
//  end
//  else
//  begin
//    cw := ClientWidth;
//    ch := ClientHeight;
//    BorderStyle := bsSizeable;
//    ClientWidth := cw;
//    ClientHeight := ch;
//  end;
end;

//procedure PostKeyExHWND(hWindow: HWnd; key: Word; const shift: TShiftState;
//   specialkey: Boolean);
// {************************************************************
// * Procedure PostKeyEx
// *
// * Parameters:
// *  hWindow: target window to be send the keystroke
// *  key    : virtual keycode of the key to send. For printable
// *           keys this is simply the ANSI code (Ord(character)).
// *  shift  : state of the modifier keys. This is a set, so you
// *           can set several of these keys (shift, control, alt,
// *           mouse buttons) in tandem. The TShiftState type is
// *           declared in the Classes Unit.
// *  specialkey: normally this should be False. Set it to True to
// *           specify a key on the numeric keypad, for example.
// *           If this parameter is true, bit 24 of the lparam for
// *           the posted WM_KEY* messages will be set.
// * Description:
// *  This procedure sets up Windows key state array to correctly
// *  reflect the requested pattern of modifier keys and then posts
// *  a WM_KEYDOWN/WM_KEYUP message pair to the target window. Then
// *  Application.ProcessMessages is called to process the messages
// *  before the keyboard state is restored.
// * Error Conditions:
// *  May fail due to lack of memory for the two key state buffers.
// *  Will raise an exception in this case.
// * NOTE:
// *  Setting the keyboard state will not work across applications
// *  running in different memory spaces on Win32 unless AttachThreadInput
// *  is used to connect to the target thread first.
// *Created: 02/21/96 16:39:00 by P. Below
// ************************************************************}
//
// type
//   TBuffers = array [0..1] of TKeyboardState;
// var
//   pKeyBuffers: ^TBuffers;
//   lParam: LongInt;
// begin
//   (* check if the target window exists *)
//   if IsWindow(hWindow) then
//   begin
//     (* set local variables to default values *)
//     pKeyBuffers := nil;
//     lParam := MakeLong(0, MapVirtualKey(key, 0));
//
//     (* modify lparam if special key requested *)
//     if specialkey then
//       lParam := lParam or $1000000;
//
//     (* allocate space for the key state buffers *)
//     New(pKeyBuffers);
//     try
//       (* Fill buffer 1 with current state so we can later restore it.
//          Null out buffer 0 to get a "no key pressed" state. *)
//       GetKeyboardState(pKeyBuffers^[1]);
//       FillChar(pKeyBuffers^[0], SizeOf(TKeyboardState), 0);
//
//       (* set the requested modifier keys to "down" state in the buffer*)
//       if ssShift in shift then
//         pKeyBuffers^[0][VK_SHIFT] := $80;
//       if ssAlt in shift then
//       begin
//         (* Alt needs special treatment since a bit in lparam needs also be set *)
//         pKeyBuffers^[0][VK_MENU] := $80;
//         lParam := lParam or $20000000;
//       end;
//       if ssCtrl in shift then
//         pKeyBuffers^[0][VK_CONTROL] := $80;
//       if ssLeft in shift then
//         pKeyBuffers^[0][VK_LBUTTON] := $80;
//       if ssRight in shift then
//         pKeyBuffers^[0][VK_RBUTTON] := $80;
//       if ssMiddle in shift then
//         pKeyBuffers^[0][VK_MBUTTON] := $80;
//
//       (* make out new key state array the active key state map *)
//       SetKeyboardState(pKeyBuffers^[0]);
//       (* post the key messages *)
//       if ssAlt in Shift then
//       begin
//         PostMessage(hWindow, WM_SYSKEYDOWN, key, lParam);
//         PostMessage(hWindow, WM_SYSKEYUP, key, lParam or $C0000000);
//       end
//       else
//       begin
//         PostMessage(hWindow, WM_KEYDOWN, key, lParam);
//         PostMessage(hWindow, WM_KEYUP, key, lParam or $C0000000);
//       end;
//       (* process the messages *)
//       Application.ProcessMessages;
//
//       (* restore the old key state map *)
//       SetKeyboardState(pKeyBuffers^[1]);
//     finally
//       (* free the memory for the key state buffers *)
//       if pKeyBuffers <> nil then
//         Dispose(pKeyBuffers);
//     end; { If }
//   end;
// end; { PostKeyEx }

function KeyboardShortcutsProc(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
type
  TBuffers = array [0..1] of TKeyboardState;
const
  LLKHF_EXTENDED = $0001;
var
  KeyboardStruct: PKBDLLHOOKSTRUCT;
  pKeyBuffers: ^TBuffers;
  lParam2: DWORD;
begin
  if CODE <> HC_ACTION then
  begin
    Result:= CallNextHookEx(KeyboardShortcutsHook, CODE, wParam, LParam);
    Exit;
  end;

  if GetForegroundWindow = FormHandle then
  begin
    KeyboardStruct := Pointer(lParam);

    (* set local variables to default values *)
    pKeyBuffers := nil;
    lParam2 := MakeLong(0, MapVirtualKey(KeyboardStruct.vkCode, 0));

    (* modify lparam if special key requested *)
    if KeyboardStruct.flags and LLKHF_EXTENDED = LLKHF_EXTENDED then
      lParam2 := lParam2 or $1000000;

    (* allocate space for the key state buffers *)
    New(pKeyBuffers);
    try
      (* Fill buffer 1 with current state so we can later restore it.
         Null out buffer 0 to get a "no key pressed" state. *)
      GetKeyboardState(pKeyBuffers^[1]);
      FillChar(pKeyBuffers^[0], SizeOf(TKeyboardState), 0);

      if pKeyBuffers^[0][VK_MENU] <> 0 then
        lParam2 := lParam2 or $20000000;

//      if (WParam = WM_KEYUP)
//        or (WParam = WM_SYSKEYUP) then
//        lParam2 := lParam2 or $C0000000;
    finally
       (* free the memory for the key state buffers *)
       if pKeyBuffers <> nil then
         Dispose(pKeyBuffers);
    end;

    if (KeyboardStruct.vkCode = VK_TAB)
      and (WParam = WM_KEYDOWN) then
      //Do nothing
    else
      SendMessage(FormHandle, WParam, KeyboardStruct.vkCode, lParam2);
    Result := 1;
  end
  else
    Result := CallNextHookEx(KeyboardShortcutsHook, CODE, wParam, LParam);
end;

function TrdDesktopViewer.SetShortcuts_Hook(fBlockInput: Boolean): Boolean;
var
  err: LongInt;
begin
  if fBlockInput then
  begin
    try
      KeyboardShortcutsHook := SetWindowsHookEx(WH_KEYBOARD_LL, @KeyboardShortcutsProc, hInstance, 0);
    finally
    end;
    err := GetLastError;
    if err <> 0 then
      xLog(Format('SetShortcuts. Error: %s', [SysErrorMessage(err)]));
    Result := (KeyboardShortcutsHook <> 0);
  end
  else
  begin
    try
      Result := UnhookWindowsHookEx(KeyboardShortcutsHook);
    finally
    end;
    err := GetLastError;
    if err <> 0 then
      xLog(Format('SetShortcuts. Error: %s', [SysErrorMessage(err)]));
  end;
end;

procedure TrdDesktopViewer.tCloseFormTimer(Sender: TObject);
begin
  tCloseForm.Enabled := False;
  Close;
end;

procedure TrdDesktopViewer.TimerRecTimer(Sender: TObject);
var
  UIDM: TUIDataModule;
begin
  UIDM := TUIDataModule(TTimer(Sender).Owner);
  if Assigned(UIDM.FVideoWriter) then
    UIDM.pImage^.RecordCircleVisible := not UIDM.pImage^.RecordCircleVisible
  else
    UIDM.pImage^.RecordCircleVisible := False;
  UIDM.pImage^.RecordInfo := FormatDateTime('HH:NN:SS', IncMilliSecond(0, NativeInt(GetTickCount) - NativeInt(UIDM.pImage^.RecordTicks)));
  UIDM.pImage^.RecordInfoVisible := Assigned(UIDM.FVideoWriter);
end;

procedure TrdDesktopViewer.TimerResizeTimer(Sender: TObject);
begin
  TimerResize.Enabled := False;
  DoResizeImage;
end;

procedure TrdDesktopViewer.PFileTransExplorerNewUI(Sender: TRtcPFileTransfer; const user: String);
var
  pUIItem: TUIDataModule;
begin
  pUIItem := GetUIDataModule(user);

  pUIItem.FT_UI.UserName := user;
  pUIItem.FT_UI.UserDesc := user;
  // Always set UI.Module *after* setting UI.UserName !!!
  pUIItem.FT_UI.Module := Sender;
  pUIItem.FT_UI.Module.AccessControl := False;
end;


end.
