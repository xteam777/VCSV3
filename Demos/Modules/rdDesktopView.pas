unit rdDesktopView;

interface

{$include rtcDefs.inc}
{$ifdef RTCHost}
  {$define RTCViewer}
{$endif}

uses
  Windows, Messages, SysUtils, CommonData, CommonUtils,
  Classes, Graphics, Controls, Forms, Types, IOUtils,
  Dialogs, ExtCtrls, StdCtrls, ShellAPI, ProgressDialog,

  rtcpFileTrans, rtcpChat,
  rtcpDesktopControl, rtcpDesktopControlUI, rtcPortalMod,
  rtcpDesktopConst, Buttons, Spin, System.Actions, Vcl.ActnList, Vcl.ActnMan,
  Vcl.ActnColorMaps, Vcl.ToolWin,
  Vcl.ActnCtrls, Vcl.ActnMenus, uVircessTypes, rtcLog, ClipBrd,
  Vcl.PlatformDefaultStyleActnCtrls, {AviFromBitmaps, vfw, }Vcl.Imaging.jpeg,
  System.ImageList, Vcl.ImgList, Math, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  NFPanel, rtcpFileTransUI;

type
  TrdDesktopViewer = class(TForm)
    myUI: TRtcPDesktopControlUI;
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
    tRecord: TTimer;
    aRecordPauseResume: TAction;
    aRecordStop: TAction;
    ilTopPanel: TImageList;
    panOptionsTimer: TTimer;
    aStretchScreen: TAction;
    aLockSystemOnClose: TAction;
    aOptimizeQuality: TAction;
    aOptimizeSpeed: TAction;
    pMain: TPanel;
    Scroll: TScrollBox;
    pImage: TRtcPDesktopViewer;
    panOptions: TPanel;
    ammbActions: TActionMainMenuBar;
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
    panOptionsMini: TNFPanel;
    aSendShortcuts: TAction;
    iScreenLocked: TImage;
    iPrepare: TImage;
    lState: TLabel;
    ilMiniPanel: TImageList;
    iFullScreen: TImage;
    iMinimize: TImage;
    iShowMiniPanel: TImage;
    iClose: TImage;
    iMiniPanelHide: TImage;
    iMiniPanelShow: TImage;
    iMove: TImage;
    Button1: TButton;
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
    procedure btnGetSelectedClick(Sender: TObject);
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
    procedure tRecordTimer(Sender: TObject);
    procedure aRecordPauseResumeExecute(Sender: TObject);
    procedure aRecordStopExecute(Sender: TObject);
    procedure panOptionsTimerTimer(Sender: TObject);
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
    procedure FormShow(Sender: TObject);
    procedure lHideMiniPanelClick(Sender: TObject);
    procedure lFullScreenClick(Sender: TObject);
    procedure lCloseClick(Sender: TObject);
    procedure lMinimizeClick(Sender: TObject);
    procedure aSendShortcutsExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure panOptionsMouseLeave(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure myUIRecv(Sender: TRtcPDesktopControlUI);
    procedure myUIRecvCancel(Sender: TRtcPDesktopControlUI);
    procedure myUIRecvStart(Sender: TRtcPDesktopControlUI);
    procedure myUIRecvStop(Sender: TRtcPDesktopControlUI);

  protected
    LMouseX,LMouseY:integer;
    LMouseD:boolean;

    LMouseDown,
    RMouseDown,
    LWinDown,
    RWinDown: Boolean;

    FProgressDialog: TProgressDialog;

    RecordState: TRecordState;
//    RecordThread: TRecordThrd;
    FramesCount: Integer;
    CurrentFrame: Integer;
//    Avi: TAviFromBitmaps;

    FOnUIOpen: TUIOpenEvent;
    FOnUIClose: TUICloseEvent;

    FDoStartFileTransferring: TDoStartFileTransferring;

    FLastActiveExplorerHandle: THandle;
    procedure OnProgressDialogCancel(Sender: TObject);

    procedure SetCaption;

    procedure CreateParams(var params: TCreateParams); override;

    {$IFNDEF RtcViewer}
    // declare our DROPFILES message handler
    procedure AcceptFiles(var msg: TMessage); message WM_DROPFILES;
    {$ENDIF}
    procedure DoResizeImage;
    procedure UpdateQuality;

//    procedure WndProc(var Msg : TMessage); override;

    function LeaseExpiresDateToDateTime(LeaseExpires: Integer): String;
    procedure RecordThreadOnTerminate(Sender: TObject);
    procedure ScreenRecordStart(AFileName: String);
    procedure ScreenRecordPause;
    procedure ScreenRecordResume;
    procedure ScreenRecordStop;
    procedure CheckRecordState(var msg: TMessage); message WM_SETCURRENTFRAME;
    procedure ChangeLockedState(var Message: TMessage); message WM_CHANGE_LOCKED_STATUS;
    procedure GetFilesFromHostClipboard(var Message: TMessage); message WM_GET_FILES_FROM_CLIPBOARD;
//    procedure WMActivate(var Message: TMessage); message WM_ACTIVATE;
  public
    { Public declarations }

    PFileTrans: TRtcPFileTransfer;
    PChat: TRtcPChat;
    fFirstScreen: Boolean;
    FormMinimized: Boolean;
    PartnerLockedState: Integer;
    PartnerServiceStarted: Boolean;
//    MappedFiles: array of TMappedFileRec;

    function SetShortcuts_Hook(fBlockInput: Boolean): Boolean;

    procedure InitScreen;
    procedure FullScreen;

    procedure SetFormState;

    property UI: TRtcPDesktopControlUI read myUI;
    property OnUIOpen: TUIOpenEvent read FOnUIOpen write FOnUIOpen;
    property OnUIClose: TUICloseEvent read FOnUIClose write FOnUIClose;
    property DoStartFileTransferring: TDoStartFileTransferring read FDoStartFileTransferring write FDoStartFileTransferring;
  end;


var
  panOptionsVisible: Boolean;
  MiniPanelDraggging, MiniPanelMouseDowned: Boolean;
  MiniPanelCurX: Integer;
  KeyboardShortcutsHook: HWND;
  FormHandle: HWND;

implementation

{$R *.dfm}

{ TrdDesktopViewer }

procedure TrdDesktopViewer.CreateParams(var params: TCreateParams);
begin
  inherited CreateParams(params);
  params.ExStyle := params.ExStyle or WS_EX_APPWINDOW;
  params.WndParent := GetDesktopWindow;
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

{$IFNDEF RtcViewer}
procedure TrdDesktopViewer.aBlockKeyboardMouseExecute(Sender: TObject);
begin
  aBlockKeyboardMouse.Checked := not aBlockKeyboardMouse.Checked;

  if aBlockKeyboardMouse.Checked then
    UI.Send_BlockKeyboardAndMouse
  else
    UI.Send_UnBlockKeyboardAndMouse;
end;

procedure TrdDesktopViewer.AcceptFiles( var msg : TMessage );
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
  end;

procedure TrdDesktopViewer.aScreenshotToCbrdExecute(Sender: TObject);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  Bitmap.SetSize(myUI.ScreenWidth, myUI.ScreenHeight);
  myUI.DrawScreen(Bitmap.Canvas, Bitmap.Width, Bitmap.Height);

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

    Bitmap.SetSize(myUI.ScreenWidth, myUI.ScreenHeight);
    myUI.DrawScreen(Bitmap.Canvas, Bitmap.Width, Bitmap.Height);

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
  UI.Module.SendShortcuts := aSendShortcuts.Checked;
  SetShortcuts_Hook(aSendShortcuts.Checked); //Доделать
end;

procedure TrdDesktopViewer.aShowRemoteCursorExecute(Sender: TObject);
begin
  UI.RemoteCursor := not UI.RemoteCursor;
  pImage.Repaint;

  aShowRemoteCursor.Checked := UI.RemoteCursor;
end;

procedure TrdDesktopViewer.InitScreen;
  begin
  Scroll.HorzScrollBar.Visible:=False;
  Scroll.VertScrollBar.Visible:=False;
  Scroll.VertScrollBar.Position:=0;
  Scroll.HorzScrollBar.Position:=0;

  pImage.Left:=0;
  pImage.Top:=0;
  WindowState:=wsNormal;
  BorderStyle:=bsSizeable;

  if myUI.HaveScreen then
    begin
    if myUI.ScreenWidth<Screen.Width then
      ClientWidth:=myUI.ScreenWidth
    else
      Width:=Screen.Width;
    if myUI.ScreenHeight<Screen.Height then
      ClientHeight:=myUI.ScreenHeight
    else
      Height:=Screen.Height;
    if myUI.ScreenHeight>=Screen.Height then
      begin
      Left:=0;
      Top:=0;
      WindowState:=wsMaximized;
      end
    else
      begin
      Left:=(Screen.Width-Width) div 2;
      Top:=(Screen.Height-Height) div 2;
      end;
    end;

//  if (pImage.Align<>alClient) and myUI.HaveScreen then
//    begin
//    pImage.Align:=alNone;
//    pImage.Width:=myUI.ScreenWidth;
//    pImage.Height:=myUI.ScreenHeight;
//    Scroll.HorzScrollBar.Visible:=True;
//    Scroll.VertScrollBar.Visible:=True;
//    end;

  BringToFront;

  {$IFNDEF RtcViewer}
  { tell Windows that you're accepting drag and drop files }
  if assigned(PFileTrans) then
    DragAcceptFiles( Handle, True );
  {$ENDIF}
  end;

procedure TrdDesktopViewer.lCloseClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    Close;
  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.FullScreen;
  begin
  // move to Full Screen mode
  Scroll.HorzScrollBar.Visible:=False;
  Scroll.VertScrollBar.Visible:=False;
  Scroll.VertScrollBar.Position:=0;
  Scroll.HorzScrollBar.Position:=0;

  WindowState:=wsNormal;
  BorderStyle:=bsNone;
  Left:=0;
  Top:=0;
  Width:=Screen.Width;
  Height:=Screen.Height;

  if (pImage.Align=alNone)
    and myUI.HaveScreen
    and aStretchScreen.Checked then
  begin
    pImage.Width:=myUI.ScreenWidth;
    pImage.Height:=myUI.ScreenHeight;
    Scroll.HorzScrollBar.Visible:=True;
    Scroll.VertScrollBar.Visible:=True;
    if pImage.Width<Screen.Width then
      pImage.Left:=(Screen.Width-pImage.Width) div 2
    else
      pImage.Left:=0;
    if pImage.Height<Screen.Height then
      pImage.Top:=(Screen.Height-pImage.Height) div 2
    else
      pImage.Top:=0;
  end;

  BringToFront;

  {$IFNDEF RtcViewer}
  { tell Windows that you're accepting drag and drop files }
  DragAcceptFiles( Handle, True );
  {$ENDIF}

  end;

procedure TrdDesktopViewer.aStretchScreenExecute(Sender: TObject);
begin
  aStretchScreen.Checked := not aStretchScreen.Checked;

  DoResizeImage;
end;

procedure TrdDesktopViewer.DoResizeImage;
var
  Scale: Real;
begin
  if myUI.HaveScreen then
  begin
    if iPrepare.Visible then
      SetFormState;

    if aStretchScreen.Checked then
    begin
      pImage.Align := alClient;
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
      pImage.Align := alNone;

      if (myUI.ScreenWidth <= ClientWidth)
        and (myUI.ScreenHeight <= ClientHeight) then
      begin
        pImage.Width := myUI.ScreenWidth;
        pImage.Height := myUI.ScreenHeight;
        pImage.Left := (ClientWidth - myUI.ScreenWidth) div 2;
        pImage.Top := (ClientHeight - myUI.ScreenHeight) div 2;
      end
      else
      begin
        if (myUI.ScreenWidth > ClientWidth)
          or (myUI.ScreenHeight > ClientHeight) then
        begin
          if ClientWidth / myUI.ScreenWidth < ClientHeight / myUI.ScreenHeight then
            Scale := ClientWidth / myUI.ScreenWidth
          else
            Scale := ClientHeight / myUI.ScreenHeight;
        end
        else
        begin
          if ClientWidth / myUI.ScreenWidth > ClientHeight / myUI.ScreenHeight then
            Scale := ClientWidth / myUI.ScreenWidth
          else
            Scale := ClientHeight / myUI.ScreenHeight;
        end;
        pImage.Width := Floor(ClientWidth * Scale);
        pImage.Height := Floor(ClientHeight * Scale);
        pImage.Left := (ClientWidth - pImage.Width) div 2;
        pImage.Top := (ClientHeight - pImage.Height) div 2;
      end;

      Scroll.HorzScrollBar.Visible := False;
      Scroll.VertScrollBar.Visible := False;
    end;
  end;
end;

{$ENDIF}

procedure TrdDesktopViewer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FProgressDialog.Stop;

  DesktopTimer.Enabled := False;
  Action := caFree;

  if Assigned(FOnUIClose) then
    FOnUIClose(myUI.Tag); //ThreadID

//  if not aRecordStart.Enabled then
//    Avi.Free;
end;

procedure TrdDesktopViewer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Hide;

  if aHideWallpaper.Checked then
  try
    if UI.Active then
      UI.Send_ShowDesktop;
  except
  end;

  if aLockSystemOnClose.Checked then
  try
    if UI.Active then
      UI.Send_LockSystem;
  except
  end;

  DesktopTimer.Enabled := False;
  CanClose := myUI.CloseAndClear;
end;

procedure TrdDesktopViewer.FormCreate(Sender: TObject);
begin
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_APPWINDOW);

  FProgressDialog := TProgressDialog.Create(Self);

  fFirstScreen := True;

  pMain.Color := clWhite; //$00A39323;
  Scroll.Visible := False;
  iPrepare.Visible := True;
  panOptions.Visible := False;
  panOptionsMini.Visible := False;
  iScreenLocked.Visible := False;
  lState.Caption := 'Инициализация изображения...';
  lState.Visible := True;
  lState.Left := 0;
  lState.Width := ClientWidth;
  Scroll.Visible := False;

  tRecord.Enabled := False;

  aRecordStart.Enabled := True;
  aRecordPauseResume.Enabled := False;
  aRecordPauseResume.Caption := 'Приостановить';
  aRecordStop.Enabled := False;

  RecordState := RSTATE_STOPPED;

  panOptionsVisible := True;
  MiniPanelDraggging := False;
  aStretchScreen.Checked := True;

  aOptimizeQuality.Checked := True;

  FormHandle := Handle;

  aSendShortcuts.Checked := True;
//  UI.Module.SendShortcuts := True;
  SetShortcuts_Hook(True); //Доделать

  Visible := False; //позже ставим True если не отменено в пендинге

  //PFileTrans.RemoteUserInfo[UI.UserName].asBoolean['ShowDialog'] := False;
//  PFileTrans.Open(UI.UserName, Sender);
end;

procedure TrdDesktopViewer.myUILogOut(Sender: TRtcPDesktopControlUI);
begin
//  Memo1.Lines.Add('myUILogOut');
  Close;
end;

procedure TrdDesktopViewer.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  myUI.SendMouseWheel(WheelDelta, Shift);
  Handled := True;
end;

procedure TrdDesktopViewer.FormResize(Sender: TObject);
begin
  panOptions.Left := (Width - panOptions.Width) div 2;
  panOptionsMini.Top := panOptions.Top + panOptions.Height;
  panOptionsMini.Left := panOptions.Left + panOptions.Width - panOptionsMini.Width - 15;

  DoResizeImage;

  lState.Left := 0;
  lState.Width := ClientWidth;
  lState.Top := Height * 580 div 680;
end;

procedure TrdDesktopViewer.FormShow(Sender: TObject);
begin
  UpdateQuality;
end;

procedure TrdDesktopViewer.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  begin
  case Key of
    VK_LWIN: LWinDown:=True;
    VK_RWIN: RWinDown:=True;
    end;

  if LWinDown or RWinDown then
    begin
    if Key=Ord('W') then
      begin
      pImage.Align:=alNone;
      if BorderStyle<>bsNone then
        FullScreen
      else
        InitScreen;
      Key:=0;
      Exit;
      end
    else if Key=Ord('S') then
      begin
      if aStretchScreen.Checked then
        pImage.Align := alClient
      else
        pImage.Align := alNone;
      if (myUI.ScreenWidth>=Screen.Width) or
         (myUI.ScreenHeight>=Screen.Height) then
        begin
        if BorderStyle<>bsNone then
          FullScreen
        else
          InitScreen;
        end
      else
        InitScreen;
      Exit;
      end;
    end;
  {$IFNDEF RtcViewer}
  if myUI.ControlMode<>rtcpNoControl then
    myUI.SendKeyDown(Key,Shift);
  {$ENDIF}
  Key:=0;
  end;

procedure TrdDesktopViewer.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
{$IFNDEF RtcViewer}
  var
    temp:Word;
{$ENDIF}
  begin
  if (LWinDown or RWinDown) and (Key in [Ord('S'),Ord('W')]) then
    Exit;

  case Key of
    VK_LWIN: LWinDown:=False;
    VK_RWIN: RWinDown:=False;
    end;

  {$IFNDEF RtcViewer}
  if myUI.ControlMode<>rtcpNoControl then
    begin
    temp:=Key; // a work-around for Internal Error in Delphi 7 compiler
    myUI.SendKeyUp(temp,Shift);
    end;
  {$ENDIF}
  Key:=0;
  end;

procedure TrdDesktopViewer.FormDeactivate(Sender: TObject);
begin
  myUI.Deactivated;
  LWinDown := False;
  RWinDown := False;
  LMouseDown := False;
  LMouseD := False;
  RMouseDown := False;
//  pImage.Cursor := 200; // small dot
end;

procedure TrdDesktopViewer.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FProgressDialog);

  SetShortcuts_Hook(False); //Доделать
end;

procedure TrdDesktopViewer.SetCaption;
begin
  if myUI.UserDesc <> '' then
    Caption := myUI.UserDesc// + ' - Управление' // + checkControl
  else
    Caption := RemoveUserPrefix(myUI.UserName);
end;

procedure TrdDesktopViewer.myUIOpen(Sender: TRtcPDesktopControlUI);
var
  fIsPending: Boolean;
begin
//  Memo1.Lines.Add('myUIOpen');
  if Assigned(FOnUIOpen) then
    FOnUIOpen(myUI.UserName, 'desk', fIsPending);

  if not fIsPending then
  begin
    Close;
    Exit;
  end
  else
  begin
    Show;
    BringToFront;
    //BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
  end;

//  if aStretchScreen.Checked then
    pImage.Align := alClient;
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
  SetCaption;
//  sStatus.Font.Color:=clWhite;
//  sStatus.Caption := 'Подготовка рабочего стола. Пожалуйста подождите ...';
//  sStatus.Visible := True;

  WindowState:=wsNormal;
  BorderStyle:=bsSizeable;
//  Width := 400;
//  Height := 90;
  Scroll.HorzScrollBar.Position:=0;
  Scroll.VertScrollBar.Position:=0;

//  BringToFront;
//  BringWindowToTop(Handle);

  aHideWallpaper.Checked := True;
//  UI.Send_HideDesktop(Sender);
//  aOptimalScale.Checked := UI.SmoothScale;

  {$IFNDEF RtcViewer}
  { tell Windows that you're accepting drag and drop files }
  if Assigned(PFileTrans) then
    DragAcceptFiles( Handle, True );
  {$ENDIF}
end;

procedure TrdDesktopViewer.myUIRecv(Sender: TRtcPDesktopControlUI);
begin
  FProgressDialog.TextLine1 := myUI.Recv_FileName;

  if myUI.Recv_BytesTotal > 0 then
    FProgressDialog.Position := Round(myUI.Recv_BytesComplete * 100 / myUI.Recv_BytesTotal)
  else
    FProgressDialog.Position := 0;

  if myUI.Recv_BytesTotal > 1024 * 1024 * 1024 then
    FProgressDialog.TextFooter := FormatFloat('0.00', myUI.Recv_BytesComplete / (1024 * 1024 * 1024)) + ' GB из ' + FormatFloat('0.00', myUI.Recv_BytesTotal / (1024 * 1024 * 1024)) + ' GB'
  else
  if myUI.Recv_BytesTotal > 1024 * 1024 then
    FProgressDialog.TextFooter := FormatFloat('0.00', myUI.Recv_BytesComplete / (1024 * 1024)) + ' MB из ' + FormatFloat('0.00', myUI.Recv_BytesTotal / (1024 * 1024)) + ' MB'
  else
    FProgressDialog.TextFooter := FormatFloat('0.00', myUI.Recv_BytesComplete / 1024) + ' KB из ' + FormatFloat('0.00', myUI.Recv_BytesTotal / 1024) + ' KB';
end;

procedure TrdDesktopViewer.myUIRecvCancel(Sender: TRtcPDesktopControlUI);
begin
  FProgressDialog.Stop;
end;

procedure TrdDesktopViewer.OnProgressDialogCancel(Sender: TObject);
begin
  FProgressDialog.Stop;
end;

procedure TrdDesktopViewer.myUIRecvStart(Sender: TRtcPDesktopControlUI);
begin
  if myUI.Recv_FirstTime then
  begin
    FProgressDialog.Title := 'Копирование';
    FProgressDialog.CommonAVI := TCommonAVI.aviCopyFiles;
    FProgressDialog.TextLine1 := myUI.Recv_FileName;
    FProgressDialog.TextLine2 := myUI.Recv_ToFolder;
    FProgressDialog.Max := 100;
    if myUI.Recv_BytesTotal > 0 then
      FProgressDialog.Position := Round(myUI.Recv_BytesComplete * 100 / myUI.Recv_BytesTotal)
    else
       FProgressDialog.Position := 0;
    FProgressDialog.TextCancel := 'Прерывание...';
    FProgressDialog.OnCancel := OnProgressDialogCancel;
//    FProgressDialog.AutoCalcFooter := True;
    FProgressDialog.fHwndParent := FLastActiveExplorerHandle;
    FProgressDialog.Execute;
  end;
end;

procedure TrdDesktopViewer.myUIRecvStop(Sender: TRtcPDesktopControlUI);
begin
  FProgressDialog.Stop;
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

  {$IFNDEF RtcViewer}
  { tell Windows that you're accepting drag and drop files }
  DragAcceptFiles(Handle, False);
  {$ENDIF}

  Close;
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

  {$IFNDEF RtcViewer}
  { tell Windows that you're accepting drag and drop files }
  DragAcceptFiles(Handle, False);
  {$ENDIF}

//  myUI.Active := True;
  Close;
end;

procedure TrdDesktopViewer.myUIData(Sender: TRtcPDesktopControlUI);
begin
  //Подгонка размера изображения
  if fFirstScreen and UI.HaveScreen then
  begin
//    if myUI.UserDesc <> '' then
//      Caption := myUI.UserDesc// + ' - Управление' //+ checkControl
//    else
//      Caption := myUI.UserName;// + ' - Управление'; // + checkControl;
    SetCaption;
//    sStatus.Visible:=False;
    fFirstScreen := False;
    WindowState := wsNormal;
    if myUI.ScreenWidth < Screen.Width then
      ClientWidth := myUI.ScreenWidth
    else
      ClientWidth := Screen.Width;
    if myUI.ScreenHeight < Screen.Height then
      ClientHeight := myUI.ScreenHeight
    else
      Height := Screen.Height;
//    if myUI.ScreenHeight >= Screen.Height then  //sstuman
//    begin
      Left := 0;
      Top := 0;
      WindowState := wsMaximized;
//    end  //sstuman
//    else
//    begin
//      WindowState := wsNormal;
//      Left := (Screen.Width - Width) div 2;
//      Top := (Screen.Height - Height) div 2;
//    end;
    {$IFNDEF RtcViewer}
    { tell Windows that you're accepting drag and drop files }
    if Assigned(PFileTrans) then
      DragAcceptFiles(Handle, True);
    {$ENDIF}
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
    if Button=mbLeft then LMouseDown:=True;
    if Button=mbRight then RMouseDown:=True;
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

  panSettings.Left:=10;
  panSettings.Top:=10;
  panSettings.Visible:=True;

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

procedure TrdDesktopViewer.Button1Click(Sender: TObject);
begin
//  myUI.Send('C:\Rufus\rufus.log', 'C:\Rufus\');
end;

procedure TrdDesktopViewer.btnCancelClick(Sender: TObject);
begin
  panSettings.Visible := False;
end;

procedure TrdDesktopViewer.aChatExecute(Sender: TObject);
begin
  PChat.Open(UI.UserName, Sender);
end;

procedure TrdDesktopViewer.aCtrlAltDelExecute(Sender: TObject);
begin
  UI.Send_CtrlAltDel;
end;

procedure TrdDesktopViewer.aFileTransferExecute(Sender: TObject);
begin
//  PFileTrans.Open(UI.UserName, Sender);
  if Assigned(FDoStartFileTransferring) then
    FDoStartFileTransferring(UI.UserName, UI.UserDesc, '', True);
end;

procedure TrdDesktopViewer.aFullScreenExecute(Sender: TObject);
begin
  if (myUI.ScreenWidth>=Screen.Width) or
     (myUI.ScreenHeight>=Screen.Height) then
    begin
    if aStretchScreen.Checked then
      pImage.Align := alClient
    else
      pImage.Align := alNone;
    if BorderStyle<>bsNone then
      FullScreen
    else
      InitScreen;
    end
  else
    begin
    if BorderStyle<>bsNone then
      begin
//      pImage.Align:=alNone;
      if aStretchScreen.Checked then
        pImage.Align := alClient
      else
        pImage.Align := alNone;
      FullScreen;
      end
    else
      begin
//      pImage.Align:=alClient;
      if aStretchScreen.Checked then
        pImage.Align := alClient
      else
        pImage.Align := alNone;
      InitScreen;
      end;
    end;

  aFullScreen.Checked := not aFullScreen.Checked;
end;

procedure TrdDesktopViewer.aHideWallpaperExecute(Sender: TObject);
begin
  if not aHideWallpaper.Checked then
    UI.Send_HideDesktop(Sender)
  else
    UI.Send_ShowDesktop(Sender);

  aHideWallpaper.Checked := not aHideWallpaper.Checked;
end;

procedure TrdDesktopViewer.aLockSystemExecute(Sender: TObject);
begin
  UI.Send_LockSystem(Sender);
end;

procedure TrdDesktopViewer.aLockSystemOnCloseExecute(Sender: TObject);
begin
  aLockSystemOnClose.Checked := not aLockSystemOnClose.Checked;
end;

procedure TrdDesktopViewer.aLogoffExecute(Sender: TObject);
begin
  UI.Send_LogoffSystem(Sender);
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
  if aOptimizeQuality.Checked then
  begin
    UI.ChgDesktop_Begin;
    try
      UI.ChgDesktop_ColorLimit(rdColor32bit);
//      UI.ChgDesktop_FrameRate(rdFramesMax);
//      UI.ChgDesktop_SendScreenInBlocks(rdBlocks1);
//      UI.ChgDesktop_SendScreenRefineBlocks(rdBlocks12);
  //    UI.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);
//      UI.ChgDesktop_SendScreenSizeLimit(rdBlockAnySize);
  //    if grpColorLow.ItemIndex>=0 then
  //      begin
        UI.ChgDesktop_ColorLowLimit(rd_ColorHigh);
  //      UI.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
  //      end;
    finally
      UI.ChgDesktop_End;
    end;
  end
  else
  begin
    UI.ChgDesktop_Begin;
    try
      UI.ChgDesktop_ColorLimit(rdColor8bit);
//      UI.ChgDesktop_FrameRate(rdFramesMax);
//      UI.ChgDesktop_SendScreenInBlocks(rdBlocks1);
//      UI.ChgDesktop_SendScreenRefineBlocks(rdBlocks12);
//  //    UI.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);
//      UI.ChgDesktop_SendScreenSizeLimit(rdBlockAnySize);
//  //    if grpColorLow.ItemIndex>=0 then
//  //      begin
        UI.ChgDesktop_ColorLowLimit(rd_ColorHigh);
//  //      UI.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
//  //      end;
  //      end;
    finally
      UI.ChgDesktop_End;
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
    UI.Send_PowerOffMonitor(Sender)
  else
    UI.Send_PowerOnMonitor(Sender);
end;

procedure TrdDesktopViewer.aPowerOffSystemExecute(Sender: TObject);
begin
  UI.Send_PowerOffSystem(Sender);
end;

procedure TrdDesktopViewer.aRecordPauseResumeExecute(Sender: TObject);
begin
  if aRecordPauseResume.Caption = 'Приостановить' then
    ScreenRecordPause
  else
    ScreenRecordResume;
end;

procedure TrdDesktopViewer.aRecordStartExecute(Sender: TObject);
var
  saveDialog : TSaveDialog;
begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Выберите место для сохранения';
  saveDialog.InitialDir := GetCurrentDir;
  saveDialog.Filter := 'AVI file|*.avi';
  saveDialog.DefaultExt := 'avi';
  saveDialog.FilterIndex := 1;
  saveDialog.Options := [ofOverwritePrompt, ofPathMustExist];

  if saveDialog.Execute then
  begin
    try
      if FileExists(saveDialog.FileName) then
        DeleteFile(saveDialog.FileName);
    except
      on E: Exception do
        xLog('aScreenshotToFileExecute. Error: ' + E.ClassName + '. ' + E.Message);
    end;

    ScreenRecordStart(saveDialog.FileName);
  end;

  saveDialog.Free;
end;

procedure TrdDesktopViewer.aRecordStopExecute(Sender: TObject);
begin
  ScreenRecordStop;
end;

procedure TrdDesktopViewer.RecordThreadOnTerminate(Sender: TObject);
begin

end;

function TrdDesktopViewer.LeaseExpiresDateToDateTime(LeaseExpires: Integer): String;
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
end;

procedure TrdDesktopViewer.lFullScreenClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    aFullScreenExecute(nil);
  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.lHideMiniPanelClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    panOptionsTimer.Enabled := True;
end;

procedure TrdDesktopViewer.lMinimizeClick(Sender: TObject);
begin
  if not MiniPanelDraggging then
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
  MiniPanelMouseDowned := False;
end;

procedure TrdDesktopViewer.CheckRecordState(var msg: TMessage);
begin
end;

procedure TrdDesktopViewer.ChangeLockedState(var Message: TMessage);
begin
  PartnerLockedState := Message.WParam;
  PartnerServiceStarted := Boolean(Message.LParam);
  SetFormState;
end;

procedure TrdDesktopViewer.GetFilesFromHostClipboard(var Message: TMessage);
var
  i: Integer;
begin
  FLastActiveExplorerHandle := THandle(Message.WParam);
  for i := 0 to CB_DataObject.FCount - 1 do
    myUI.Fetch(CB_DataObject.FFiles[i].filePath, String(Message.LParam));
end;

procedure TrdDesktopViewer.SetFormState;
begin
  if ((PartnerLockedState = LCK_STATE_LOCKED) or (PartnerLockedState = LCK_STATE_SAS))
    and (not PartnerServiceStarted) then
  begin
    pMain.Color := $00A39323;
    Scroll.Visible := True;
    iPrepare.Visible := False;
    panOptions.Visible := True;
    panOptionsMini.Visible := True;
    iScreenLocked.Visible := True;
    lState.Caption := 'Удаленный компьютер заблокирован';
    lState.Visible := True;
    lState.Invalidate;
    Scroll.Visible := False;
  end
  else
  begin
    pMain.Color := $00151515;
    Scroll.Visible := True;
    iPrepare.Visible := False;
    panOptions.Visible := True;
    panOptionsMini.Visible := True;
    iScreenLocked.Visible := False;
    lState.Caption := '';
    lState.Visible := False;
    lState.Invalidate;
    Scroll.Visible := True;
  end;
end;

procedure TrdDesktopViewer.ScreenRecordStart(AFileName: String);
//var
//  i: Integer;
//var
//    I          : Integer;
//    Y          : Integer;
//    H          : Integer;
//    BackBitmap : Graphics.TBitMap;
begin
//    BackBitmap             := Graphics.TBitMap.Create;
//    BackBitmap.Width       := 320;
//    BackBitmap.Height      := 240;
//    BackBitmap.PixelFormat := TPixelFormat.pf32bit;

//  FramesCount := 0;
//  CurrentFrame := 0;
//  for i := 0 to Length(MappedFiles) - 1 do
//  begin
//    UnMapViewOfFile(MappedFiles[i].pImage);
//    CloseHandle(MappedFiles[i].hFile);
//  end;
//
//  RecordThread := TRecordThrd.Create;
//  RecordThread.FreeOnTerminate := True;
//  RecordThread.FileName := AFileName;
//  RecordThread.ParentHandle := Handle;
//  RecordThread.FramesCount := @FramesCount;
//  RecordThread.CurrentFrame := @CurrentFrame;
//  RecordThread.RecordState := @RecordState;
////  RecordThread.CheckRecordStateProc := CheckRecordState;
//  RecordThread.Avi := nil;
//  RecordThread.ImageWidth := UI.GetScreen.Image.Width;
//  RecordThread.ImageHeight := UI.GetScreen.Image.Height;
//  RecordThread.OnTerminate := RecordThreadOnTerminate;
////  RecordThread.Avi := TAviFromBitmaps.CreateAviFile(
////    nil, AFileName,
////    MKFOURCC('x', 'v', 'i', 'd'),// XVID (MPEG-4) compression
////    //MKFOURCC('D', 'I', 'B', ' '),  // No compression
////    25, 1);                         // 2 frames per second
//  RecordThread.Resume;

//    Avi := TAviFromBitmaps.CreateAviFile(
//      nil, AFileName,
//      //MKFOURCC('x', 'v', 'i', 'd'),// XVID (MPEG-4) compression
//      MKFOURCC('D', 'I', 'B', ' '),  // No compression
//      25, 1);                         // 25 frames per second

  tRecord.Enabled := True;

  aRecordStart.Enabled := False;
  aRecordPauseResume.Enabled := True;
  aRecordPauseResume.Caption := 'Приостановить';
  aRecordStop.Enabled := True;

//    // First, add a blank frame
//    Avi.AppendNewFrame(BackBitmap.Handle);
//    // Then add frames with text
//    BackBitmap.Canvas.Font.Size := 20;
//    H := (BackBitmap.Canvas.TextHeight('I') * 15) div 10;
//    Y := (BackBitmap.Height div 2) - H;
//    BackBitmap.Canvas.TextOut(10, Y, 'Delphi rocks!');
//    Y := (BackBitmap.Height div 2);
//    for I := 1 to 25 do begin
//        BackBitmap.Canvas.TextOut(10, Y, IntToStr(I));
//        Avi.AppendNewFrame(BackBitmap.Handle);
//    end;
//    // Finally, add two blank frame
//    // (MediaPlayer doesn't show the last two frames)
//    BackBitmap.Canvas.FillRect(Rect(0, 0,
//      BackBitmap.Width, BackBitmap.Height));
//    Avi.AppendNewFrame(BackBitmap.Handle);
//    Avi.AppendNewFrame(BackBitmap.Handle);

//    FreeAndNil(Avi);
//    FreeAndNil(BackBitmap);

  RecordState := RSTATE_STARTED;
end;

procedure TrdDesktopViewer.tRecordTimer(Sender: TObject);
var
//  bitdc, DC: HDC;
//  BitsMem: Pointer;
//  BitmapInfo: TBitmapInfo;
//  hold: HGDIOBJ;
//  msize: Integer;
//  hbitm: HBITMAP;
//  hbitmap: THandle;
//  bitimage: Pointer;
  Bitmap: TBitmap;
  JPEG: TJPEGImage;
begin
  Bitmap := TBitmap.Create;

    Bitmap.SetSize(myUI.ScreenWidth, myUI.ScreenHeight);
    myUI.DrawScreen(Bitmap.Canvas, Bitmap.Width, Bitmap.Height);

//  Bitmap.Width := UI.GetScreen.Image.Width;
//  Bitmap.Height := UI.GetScreen.Image.Height;
//  Bitmap.Canvas.CopyRect(Rect(0, 0, UI.GetScreen.Image.Width, UI.GetScreen.Image.Height), UI.GetScreen.Image.Canvas, Rect(0, 0, UI.GetScreen.Image.Width, UI.GetScreen.Image.Height));

//  Bitmap.PixelFormat := pf24bit;
  JPEG := TJPEGImage.Create;
  JPEG.Assign(Bitmap);
  Bitmap.SaveToFile('_Screen.bmp');
  JPEG.SaveToFile('_Screen.jpg');
  JPEG.Free;
//
//  with BitmapInfo do
//    with bmiHeader do
//    begin
//      biSize := SizeOf(bmiHeader);
//      biWidth := UI.GetScreen.Image.Width;
//      biHeight := UI.GetScreen.Image.Height;
//      biPlanes:= 1;
//      biBitCount:= 24;
//      biCompression := BI_RGB;
//      msize := BytesPerScanLine(biwidth, bibitcount, SizeOf(DWORD)) * biheight;
//      biSizeImage := msize;
//      biXPelsPerMeter := 0;
//      biYPelsPerMeter := 0;
//      biClrUsed := 0;
//      biClrImportant := 0;
//    end;
//
//  hbitmap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, msize, PWideChar('ScreenFrame' + IntToStr(FramesCount))); //мапфайл для картинки
//  bitimage := MapViewOfFile(hbitmap, FILE_MAP_ALL_ACCESS, 0, 0, msize);
//
//  DC := GetDC(INVALID_HANDLE_VALUE);
//  bitdc := CreateCompatibleDC(DC);
//  hbitm := CreateDIBSection(DC, BitmapInfo, DIB_RGB_COLORS, BitsMem, hbitmap, 0);
//  ReleaseDC(INVALID_HANDLE_VALUE, DC);
//  hold := SelectObject(bitdc, hbitm);
//
//  BitBlt(bitdc, 0, 0, UI.GetScreen.Image.Width, UI.GetScreen.Image.Height, Bitmap.Canvas.Handle, 0, 0, SRCCOPY);
//
//  SelectObject(bitdc, hold);
//  DeleteObject(bitdc);
//
  FramesCount := FramesCount + 1;
  CurrentFrame := CurrentFrame + 1;
//  SetLength(MappedFiles, Length(MappedFiles) + 1);
//  MappedFiles[Length(MappedFiles) - 1].hFile := hbitmap;
//  MappedFiles[Length(MappedFiles) - 1].pImage := bitimage;

  //Write frame
//  Avi.AppendNewFrame(Bitmap.Handle);

  Bitmap.Free;
end;

procedure TrdDesktopViewer.ScreenRecordPause;
begin
  tRecord.Enabled := False;

  aRecordStart.Enabled := False;
  aRecordPauseResume.Enabled := True;
  aRecordPauseResume.Caption := 'Продолжить';
  aRecordStop.Enabled := True;

  RecordState := RSTATE_PAUSED;
end;

procedure TrdDesktopViewer.ScreenRecordResume;
begin
  tRecord.Enabled := True;

  aRecordStart.Enabled := False;
  aRecordPauseResume.Enabled := True;
  aRecordPauseResume.Caption := 'Приостановить';
  aRecordStop.Enabled := True;

//  RecordThread.Resume;

  RecordState := RSTATE_STARTED;
end;

procedure TrdDesktopViewer.ScreenRecordStop;
//var
//  i: Integer;
begin
  tRecord.Enabled := False;

  aRecordStart.Enabled := True;
  aRecordPauseResume.Enabled := False;
  aRecordPauseResume.Caption := 'Приостановить';
  aRecordStop.Enabled := False;

  RecordState := RSTATE_STARTED;
//  RecordThread.Terminate;

  FramesCount := 0;
  CurrentFrame := 0;
//  for i := 0 to Length(MappedFiles) - 1 do
//  begin
//    UnMapViewOfFile(MappedFiles[i].pImage);
//    CloseHandle(MappedFiles[i].hFile);
//  end;

//  FreeAndNil(Avi);
end;

procedure TrdDesktopViewer.aRestartSystemExecute(Sender: TObject);
begin
  UI.Send_RestartSystem(Sender);
end;

procedure TrdDesktopViewer.btnAcceptClick(Sender: TObject);
  begin
  panSettings.Visible:=False;
  UI.ChgDesktop_Begin;
  try
    if grpLayered.ItemIndex>=0 then      UI.ChgDesktop_CaptureLayeredWindows(grpLayered.ItemIndex=0);
    if grpMirror.ItemIndex>=0 then       UI.ChgDesktop_UseMirrorDriver(grpMirror.ItemIndex=0);
    if grpMouse.ItemIndex>=0 then        UI.ChgDesktop_UseMouseDriver(grpMouse.ItemIndex=0);
    if grpMonitors.ItemIndex>=0 then     UI.ChgDesktop_CaptureAllMonitors(grpMonitors.ItemIndex=0);
    if grpColor.ItemIndex>=0 then        UI.ChgDesktop_ColorLimit(TRdColorLimit(grpColor.ItemIndex));
    if grpFrame.ItemIndex>=0 then        UI.ChgDesktop_FrameRate(TRdFrameRate(grpFrame.ItemIndex));
    if grpScreenBlocks.ItemIndex>=0 then UI.ChgDesktop_SendScreenInBlocks(TrdScreenBlocks(grpScreenBlocks.ItemIndex));
    if grpScreenBlocks2.ItemIndex>=0 then UI.ChgDesktop_SendScreenRefineBlocks(TrdScreenBlocks(grpScreenBlocks2.ItemIndex));
    if grpScreen2Refine.ItemIndex>=0 then  UI.ChgDesktop_SendScreenRefineDelay(grpScreen2Refine.ItemIndex);
    if grpScreenLimit.ItemIndex>=0 then  UI.ChgDesktop_SendScreenSizeLimit(TrdScreenLimit(grpScreenLimit.ItemIndex));
    if grpColorLow.ItemIndex>=0 then
      begin
      UI.ChgDesktop_ColorLowLimit(TrdLowColorLimit(grpColorLow.ItemIndex));
      UI.ChgDesktop_ColorReducePercent(cbReduceColors.Value);
      end;
  finally
    UI.ChgDesktop_End;
    end;
  end;

procedure TrdDesktopViewer.btnGetSelectedClick(Sender: TObject);
begin
  //Доделать
  UI.Send_FileCopy;
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
  if assigned(myUI) and MyUI.InControl and (GetForegroundWindow <> Handle) then
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
    if ((panOptionsMini.Left - MiniPanelCurX + p.X + panOptionsMini.Width) < (panOptions.Left + panOptions.Width - 15))
      and ((panOptionsMini.Left - MiniPanelCurX + p.X) > (panOptions.Left + 15)) then
      panOptionsMini.Left := panOptionsMini.Left - MiniPanelCurX + p.X;
    MiniPanelCurX := p.X;
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
    //Перенести сюда события OnClick кнопок
end;

procedure TrdDesktopViewer.panOptionsMouseLeave(Sender: TObject);
begin
  SendMessage(ammbActions.Handle, WM_NULL, 0, 0);
end;

procedure TrdDesktopViewer.panOptionsTimerTimer(Sender: TObject);
begin
  if panOptionsVisible then
  begin
    panOptionsMini.Top := panOptions.Top + panOptions.Height - 1;
    panOptions.Top := panOptions.Top - 1;

    if panOptions.Top = -panOptions.Height then
    begin
      panOptionsTimer.Enabled := False;
      panOptionsVisible := False;
      iShowMiniPanel.Picture.Assign(iMiniPanelShow.Picture);
      iShowMiniPanel.Hint := 'Показать панель действий';

      MiniPanelMouseDowned := False;
      MiniPanelDraggging := False;
    end;
  end
  else
  begin
    panOptions.Top := panOptions.Top + 1;
    panOptionsMini.Top := panOptions.Top + panOptions.Height;

    if panOptions.Top = 0 then
    begin
      panOptionsTimer.Enabled := False;
      panOptionsVisible := True;
      iShowMiniPanel.Picture.Assign(iMiniPanelHide.Picture);
      iShowMiniPanel.Hint := 'Скрыть панель действий';

      MiniPanelMouseDowned := False;
      MiniPanelDraggging := False;
    end;
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


end.
