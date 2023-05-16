{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcpDesktopControlUI;

interface

{$INCLUDE rtcDefs.inc}

uses
  Windows, Classes, SysUtils,
  Graphics, Controls, ExtCtrls, Forms,
{$IFNDEF IDE_1}
  Variants,
{$ENDIF}
  rtcLog, SyncObjs, rtcScrPlayback,
  rtcInfo, rtcpDesktopControl,
{$IFDEF DEBUG}
    System.Math,
{$ENDIF}
  rtcpDesktopConst;

const
  RTCPDESKTOP_SmoothScale_Off = 0;
  RTCPDESKTOP_SmoothScale_On = 1;
  RTCPDESKTOP_ExactCursor_Off = 10;
  RTCPDESKTOP_ExactCursor_On = 11;
  RTCPDESKTOP_ControlMode_Off = 20;
  RTCPDESKTOP_ControlMode_Manual = 21;
  RTCPDESKTOP_ControlMode_Auto = 22;
  RTCPDESKTOP_ControlMode_Full = 23;
  RTCPDESKTOP_MapKeys_Off = 30;
  RTCPDESKTOP_MapKeys_On = 31;

  //+sstuman
  RTCPDESKTOP_RemoteCursor_On = 40;
  RTCPDESKTOP_RemoteCursor_Off = 41;
  //-sstuman

type
  TRtcPDesktopControlUI = class;

  TRtcPDesktopControlUIEvent = procedure(Sender: TRtcPDesktopControlUI)
    of object;

  TRtcPDesktopControlMode = (rtcpNoControl, rtcpManualControl, rtcpAutoControl,
    rtcpFullControl);

  TRtcPDesktopViewer = class(TPaintBox)
  private
    FUI: TRtcPDesktopControlUI;
    function GetUI: TRtcPDesktopControlUI;
    procedure SetUI(const Value: TRtcPDesktopControlUI);

  protected
    procedure Paint; override;
    procedure Resize; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;

    property UI: TRtcPDesktopControlUI read GetUI write SetUI;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TRtcRemoteCursorMarkStyle = (rcm_None, rcm_Circle, rcm_Square, rcm_Cross);

  TRtcRemoteCursorMark = class(TPersistent)
  private
    FColor1: TColor;
    FColor2: TColor;
    FStyle: TRtcRemoteCursorMarkStyle;
    FSize: Integer;

  public
    constructor Create;

  published
    property Style: TRtcRemoteCursorMarkStyle read FStyle write FStyle
      default rcm_None;
    property Size: Integer read FSize write FSize default 3;
    property Color1: TColor read FColor1 write FColor1 default clMaroon;
    property Color2: TColor read FColor2 write FColor2 default clRed;
  end;

  TRtcPDesktopControlUI = class(TRtcAbsPDesktopControlUI)
  private
    CS: TCriticalSection;
    FUserCnt: Integer;
    FViewer: TRtcPDesktopViewer;

    Scr: TRtcScreenPlayback;

    FHaveScreen: boolean;

    FCurPaint: boolean;
    FCurPaintX, FCurPaintY, FCurPaintW, FCurPaintH: Integer;

    {$IFDEF DEBUG}
  type
    RFrameStatInfo = record
      Total, DD, WPE, WPD, Misc, Vol : Int64;
    end;
  var
    {FPSCalcDisplayTick, FPSCalcLastTick, }
    FrameStatLastTick, FrameStatPeriod : UInt64;
    FrameStatCnt, FrameStatStartInd : Integer;
    FrameStat : array [0..10000] of RFrameStatInfo;
    FrameStatS : array [0..10] of string;
    {$ENDIF}

    FMouseDown: Integer;

    FScreenChanged, FCursorChanged,

      FShiftDown, FCtrlDown, FAltDown, FLWinDown, FRWinDown: boolean;

    Scale: double;

    LastX, LastY: Integer;

    FAutoScroll, ControlMouse, ControlKeyboard: boolean;

    FSmoothScale: boolean;
    FExactCursor: boolean;
    //+sstuman
    FRemoteCursor: Boolean;
    //-sstuman
    FControlMode: TRtcPDesktopControlMode;

    FChg_DeskCnt: Integer;
    FChg_Desktop: TRtcFunctionInfo;

    FStore_CurPaint: boolean;
    FStore_CurPaintX, FStore_CurPaintY, FStore_CurPaintW,
      FStore_CurPaintH: Integer;

    FStore_ScreenChanged, FStore_CursorChanged: boolean;

    FStore_Scale: double;

    FOnOpen: TRtcPDesktopControlUIEvent;
    FOnClose: TRtcPDesktopControlUIEvent;
    FOnData: TRtcPDesktopControlUIEvent;
    FOnError: TRtcPDesktopControlUIEvent;
    FOnLogOut: TRtcPDesktopControlUIEvent;

    FMarkRemoteCursor: TRtcRemoteCursorMark;

    procedure SetExactCursor(const Value: boolean);

    //+sstuman
    procedure SetRemoteCursor(const Value: boolean);
    //-sstuman

    procedure SetSmoothScale(const Value: boolean);
    procedure SetControlMode(const Value: TRtcPDesktopControlMode);

    function GetViewer: TRtcPDesktopViewer;
    procedure SetViewer(const Value: TRtcPDesktopViewer);

    function GetActive: boolean;
    procedure SetActive(const Value: boolean);
    function GetCursorX: Integer;
    function GetCursorY: Integer;

  protected
    procedure xOnOpen(Sender, Obj: TObject);
    procedure xOnClose(Sender, Obj: TObject);

    procedure xOnData(Sender, Obj: TObject);

    procedure xOnError(Sender, Obj: TObject);
    procedure xOnLogOut(Sender, Obj: TObject);

    procedure NotifyUI(const msg: Integer; Sender: TObject); override;

    procedure Call_LogOut(Sender: TObject); override;
    procedure Call_Error(Sender: TObject); override;

    procedure Call_Open(Sender: TObject); override;
    procedure Call_Close(Sender: TObject); override;

    procedure Call_Data(Sender: TObject;
      const ScreenData, CursorData: RtcString); override;

    procedure StoreScreenState;
    procedure RestoreScreenState;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function HaveScreen: boolean;
    function ScreenWidth: Integer;
    function ScreenHeight: Integer;

    // If Container is not specified, View-only mode is assumed and Cursor is painted on the Canvas
    // If Container is specified, it is assumed to be the control containing the Canvas
    procedure DrawScreen(Image: TCanvas; ImageWidth, ImageHeight: Integer;
      Container: TControl = nil; FullRepaint: boolean = False);

    procedure SendMouseDown(X, Y: Integer; Shift: TShiftState;
      Button: TMouseButton; Sender: TObject = nil); override;
    procedure SendMouseMove(X, Y: Integer; Shift: TShiftState;
      Sender: TObject = nil); override;
    procedure SendMouseUp(X, Y: Integer; Shift: TShiftState;
      Button: TMouseButton; Sender: TObject = nil); override;

    procedure SendMouseWheel(Wheel: Integer; Shift: TShiftState;
      Sender: TObject = nil); override;
    procedure SendKeyDown(const Key: Word; Shift: TShiftState;
      Sender: TObject = nil); override;
    procedure SendKeyUp(const Key: Word; Shift: TShiftState;
      Sender: TObject = nil); override;

    procedure Deactivated(Sender: TObject = nil);

    function InControl: boolean;

    { Commands to remotely change Desktop settings }

    { To change multiple parameters in a single call and
      avoid refreshing the screen for each parameter separately,
      call "ChgDesktop_Begin" before using other ChgDesk_ methods,
      then call "ChgDesktop_End" to send all changes. }

    procedure ChgDesktop_Begin;
    procedure ChgDesktop_ColorLimit(const Value: TrdColorLimit;
      Sender: TObject = nil);
    procedure ChgDesktop_FrameRate(const Value: TrdFrameRate;
      Sender: TObject = nil);
    procedure ChgDesktop_UseMirrorDriver(Value: boolean; Sender: TObject = nil);
    procedure ChgDesktop_UseMouseDriver(Value: boolean; Sender: TObject = nil);
    procedure ChgDesktop_SendScreenInBlocks(Value: TrdScreenBlocks;
      Sender: TObject = nil);
    procedure ChgDesktop_SendScreenRefineBlocks(Value: TrdScreenBlocks;
      Sender: TObject = nil);
    procedure ChgDesktop_SendScreenRefineDelay(Value: Integer;
      Sender: TObject = nil);
    procedure ChgDesktop_SendScreenSizeLimit(Value: TrdScreenLimit;
      Sender: TObject = nil);
    procedure ChgDesktop_CaptureAllMonitors(Value: boolean;
      Sender: TObject = nil);
    procedure ChgDesktop_CaptureLayeredWindows(Value: boolean;
      Sender: TObject = nil);
    procedure ChgDesktop_ColorLowLimit(const Value: TrdLowColorLimit;
      Sender: TObject = nil);
    procedure ChgDesktop_ColorReducePercent(const Value: Integer;
      Sender: TObject = nil);
    procedure ChgDesktop_End(Sender: TObject = nil);

    { Special commands that can be sent to the user when in Desktop Control mode }

    procedure Send_SpecialKey(const Key: RtcString; Sender: TObject = nil);

    procedure Send_CtrlAltDel(Sender: TObject = nil);

    procedure Send_FileCopy(Sender: TObject = nil);

    procedure Send_HideDesktop(Sender: TObject = nil);
    procedure Send_ShowDesktop(Sender: TObject = nil);

    //+sstuman
    procedure Send_BlockKeyboardAndMouse(Sender: TObject = nil);
    procedure Send_UnBlockKeyboardAndMouse(Sender: TObject = nil);
    procedure Send_PowerOffMonitor(Sender: TObject = nil);
    procedure Send_PowerOnMonitor(Sender: TObject = nil);
    procedure Send_PowerOffSystem(Sender: TObject = nil);
    procedure Send_LockSystem(Sender: TObject = nil);
    procedure Send_LogoffSystem(Sender: TObject = nil);
    procedure Send_RestartSystem(Sender: TObject = nil);
    //-sstuman

    procedure Send_AltTAB(Sender: TObject = nil);
    procedure Send_ShiftAltTAB(Sender: TObject = nil);
    procedure Send_CtrlAltTAB(Sender: TObject = nil);
    procedure Send_ShiftCtrlAltTAB(Sender: TObject = nil);

    { Desktop Properties }

    property ScreenChanged: boolean read FScreenChanged;
    property CursorChanged: boolean read FCursorChanged;

    property ShiftDown: boolean read FShiftDown;
    property CtrlDown: boolean read FCtrlDown;
    property AltDown: boolean read FAltDown;
    property LWinDown: boolean read FLWinDown;
    property RWinDown: boolean read FRWinDown;

    property CursorX: Integer read GetCursorX;
    property CursorY: Integer read GetCursorY;

    { TODO : Custom new propertys. }
    property Playback: TRtcScreenPlayback read Scr;
    property CirticalSection: TCriticalSection read CS;

  published
    property Active: boolean read GetActive write SetActive default False;

    property SmoothScale: boolean read FSmoothScale write SetSmoothScale
      default False;
    property ExactCursor: boolean read FExactCursor write SetExactCursor
      default False;

    //+sstuman
    property RemoteCursor: boolean read FRemoteCursor write SetRemoteCursor
      default False;
    //-sstuman

    property ControlMode: TRtcPDesktopControlMode read FControlMode
      write SetControlMode default rtcpNoControl;

    { If Screen image is inside a TControl and that TControl is inside a TScrollBox,
      you can set AutoScroll to TRUE to make scroll bars in the parent TScrollBox
      move automatically into position to keep Hosts mouse cursor visible.

      This option is most useuful when you are watching a presentation in 100% scale,
      but you do not have a large enough resolution to see the whole presenters screen,
      but it can also be very useful for auto-scrolling when you want to control a
      Host in 100% scale but it has a larger resolution than your local screen. }
    property AutoScroll: boolean read FAutoScroll write FAutoScroll
      default False;

    property MarkRemoteCursor: TRtcRemoteCursorMark read FMarkRemoteCursor
      write FMarkRemoteCursor;

    property Viewer: TRtcPDesktopViewer read GetViewer write SetViewer;

    { DesktopControl room opened.
      Sender = this TRtcPDesktopControlUI object }
    property OnOpen: TRtcPDesktopControlUIEvent read FOnOpen write FOnOpen;
    { DesktopControl room closed by user.
      Sender = this TRtcPDesktopControlUI object }
    property OnClose: TRtcPDesktopControlUIEvent read FOnClose write FOnClose;

    { Error received, chat room closed.
      Sender = this TRtcPDesktopControlUI object }
    property OnError: TRtcPDesktopControlUIEvent read FOnError write FOnError;
    { User logged out, chat room closed.
      Sender = this TRtcPDesktopControlUI object }
    property OnLogOut: TRtcPDesktopControlUIEvent read FOnLogOut
      write FOnLogOut;

    { Message received from user:
      Sender = this TRtcPDesktopControlUI object }
    property OnData: TRtcPDesktopControlUIEvent read FOnData write FOnData;
  end;

implementation
{$IFDEF DEBUG} uses rtcDebug; {$ENDIF}

{ TRtcPDesktopControlUI }

{$R RtcCursor.res}

var
  myCursorLoaded: boolean = False;

constructor TRtcPDesktopControlUI.Create(AOwner: TComponent);
begin
  inherited;

  FUserCnt := 0;
  CS := TCriticalSection.Create;
  Scr := TRtcScreenPlayback.Create;

  FMarkRemoteCursor := TRtcRemoteCursorMark.Create;

  FCurPaint := False;
  Scale := 1;
  ControlMouse := False;
  ControlKeyboard := False;
  FMouseDown := 0;
  FHaveScreen := False;
  FCursorChanged := False;
  FScreenChanged := False;
  ControlMode := rtcpNoControl;

  FChg_DeskCnt := 0;
  FChg_Desktop := nil;

  if not myCursorLoaded then
  begin
    myCursorLoaded := True;
    Screen.Cursors[200] := LoadCursor(HInstance, 'POINT_CURSOR');
  end;
end;

destructor TRtcPDesktopControlUI.Destroy;
begin
  if assigned(FChg_Desktop) then
  begin
    FChg_Desktop.Free;
    FChg_Desktop := nil;
    FChg_DeskCnt := 0;
  end;
  FMarkRemoteCursor.Free;
  Scr.Free;
  CS.Free;

  inherited;
end;

procedure TRtcPDesktopControlUI.Call_Open(Sender: TObject);
begin
  Inc(FUserCnt);
  if FUserCnt = 1 then
  begin
    CS.Acquire;
    try
      ControlMouse := False;
      ControlKeyboard := False;
      FHaveScreen := False;
      FMouseDown := 0;
      Scr.LoginUserName := '';
    finally
      CS.Release;
    end;
    if assigned(FOnOpen) then
      Module.CallEvent(Sender, xOnOpen, self);
  end;
end;

procedure TRtcPDesktopControlUI.Call_Close(Sender: TObject);
begin
  if FUserCnt > 0 then
  begin
    CS.Acquire;
    try
      ControlMouse := False;
      ControlKeyboard := False;
      FHaveScreen := False;
      FMouseDown := 0;
      Scr.LoginUserName := '';
    finally
      CS.Release;
    end;
    Dec(FUserCnt);
    if FUserCnt = 0 then
    begin
      if assigned(FOnClose) then
        Module.CallEvent(Sender, xOnClose, self);
    end;
  end;
end;

procedure TRtcPDesktopControlUI.Call_Error(Sender: TObject);
begin
  FUserCnt := 0;

  CS.Acquire;
  try
    ControlMouse := False;
    ControlKeyboard := False;
    FHaveScreen := False;
    FMouseDown := 0;
    Scr.LoginUserName := '';
  finally
    CS.Release;
  end;

  if assigned(FOnError) then
    Module.CallEvent(Sender, xOnError, self);
end;

procedure TRtcPDesktopControlUI.Call_LogOut(Sender: TObject);
begin
  FUserCnt := 0;

  CS.Acquire;
  try
    ControlMouse := False;
    ControlKeyboard := False;
    FHaveScreen := False;
    FMouseDown := 0;
    Scr.LoginUserName := '';
  finally
    CS.Release;
  end;

  if assigned(FOnLogOut) then
    Module.CallEvent(Sender, xOnLogOut, self);
end;

procedure TRtcPDesktopControlUI.StoreScreenState;
begin
  FStore_CurPaint := FCurPaint;
  FStore_CurPaintX := FCurPaintX;
  FStore_CurPaintY := FCurPaintY;
  FStore_CurPaintW := FCurPaintW;
  FStore_CurPaintH := FCurPaintH;
  FStore_ScreenChanged := FScreenChanged;
  FStore_CursorChanged := FCursorChanged;
  FStore_Scale := Scale;
end;

procedure TRtcPDesktopControlUI.RestoreScreenState;
begin
  FCurPaint := FStore_CurPaint;
  FCurPaintX := FStore_CurPaintX;
  FCurPaintY := FStore_CurPaintY;
  FCurPaintW := FStore_CurPaintW;
  FCurPaintH := FStore_CurPaintH;
  FScreenChanged := FStore_ScreenChanged;
  FCursorChanged := FStore_CursorChanged;
  Scale := FStore_Scale;
end;

procedure TRtcPDesktopControlUI.Call_Data(Sender: TObject;
  const ScreenData, CursorData: RtcString);
{$IFDEF DEBUG}
var
  Ind, i: Int64;
  F: TextFile;
  CurTick: UInt64;
  PeriodMS: double;
  VSum, VCnt: Int64;
  S : String;
{$ENDIF}
begin
  CS.Acquire;
  try
    if Scr.PaintScreen(ScreenData) then
    begin
      FScreenChanged := True;
      if not FHaveScreen then
      begin
        FHaveScreen := True;
        Scr.LoginUserName := Module.Client.LoginUserName;
      end;
    end;
    if FHaveScreen then
    begin
      if Scr.PaintCursor(CursorData) then
        FCursorChanged := True;
      StoreScreenState;
    end;

    {$IFDEF DEBUG}
   // if FPSCalcTicksCnt = 0 then
   // /begin
   //   FPSCalcTicks[FPSCalcTicksCnt] := CurTick;
    //  FPSCalcTicksCnt := 1;
   // end else
   // begin
     // if CurTick <> FPSCalcLastTick then
     // begin
      //  FPSCalcValue := (FPSCalcValue * FPSCalcFramesCnt +
       //   (1000 / (CurTick - FPSCalcLastTick))) / (FPSCalcFramesCnt + 1);

       // Inc(FPSCalcTicksCnt);
      //  FPSCalcLastTick := CurTick;
     // end;

  with FrameStat[FrameStatCnt] do
  begin
    if FrameStatLastTick = 0 then
    begin
      FrameStatLastTick := Debug.GetMCSTick;
      if Debug.FrameStatLog <> '' then
      begin
        AssignFile(F, ExtractFilePath(Application.ExeName) + Debug.FrameStatLog);
        Append(F);
        WriteLn(F, '---------------------------------------------------------------');
        CloseFile(F);
      end;
    end else
    begin
      CurTick := Debug.GetMCSTick;
      Total := CurTick - FrameStatLastTick;
      FrameStatLastTick := CurTick;
      Inc(FrameStatPeriod, Total);

      Vol := Length(ScreenData) + Length(CursorData);
      DD := Scr.CapLat;
      WPE := Scr.EncLat;
      WPD := Scr.DecLat;

      Misc := Total;
      if DD > 0 then Dec(Misc, DD);
      if WPE > 0 then Dec(Misc, WPE);
      if WPD > 0 then Dec(Misc, WPD);

      if Debug.FrameStatLog <> '' then
      begin
        AssignFile(F, ExtractFilePath(Application.ExeName) + Debug.FrameStatLog);
        Append(F);
        WriteLn(F, DateTimeToStr(Now), ' ', (DD / 1000):7:2, ' ',
          (WPE / 1000):7:2, ' ', (WPD / 1000):7:2, ' ', (Misc / 1000):7:2, ' ',
          (Total / 1000):7:2, ' ', (Vol / 1024):7:2);
        CloseFile(F);
      end;


      if FrameStatCnt >= 100 then
      begin // Удаляем первый элемент массива сдвигом влево
        for i := 1 to FrameStatCnt do
          FrameStat[i - 1] := FrameStat[i];

        Dec(FrameStatStartInd);
       // Inc(FrameStatPeriod, Total);
      end else
        Inc(FrameStatCnt);
    end;


    PeriodMS := FrameStatPeriod / 1000;
    if PeriodMS > 500 then
    begin
      VSum := 0; VCnt := 0;
      for i := FrameStatStartInd to FrameStatCnt - 1 do
      begin
        if FrameStat[i].DD < 0 then continue;
        Inc(VSum, FrameStat[i].DD);
        Inc(VCnt);
      end;
      if VCnt <= 0 then FrameStatS[0] := '' else
        FrameStatS[0] := 'DD ' + FloatToStrF(VSum / (1000 * VCnt), ffFixed, 10, 2) + ' ms';

      VSum := 0; VCnt := 0;
      for i := FrameStatStartInd to FrameStatCnt - 1 do
      begin
        if FrameStat[i].WPE < 0 then continue;
        Inc(VSum, FrameStat[i].WPE);
        Inc(VCnt);
      end;
      if VCnt <= 0 then FrameStatS[1] := '' else
        FrameStatS[1] := 'WPE ' + FloatToStrF(VSum / (1000 * VCnt), ffFixed, 10, 2) + ' ms';

      VSum := 0; VCnt := 0;
      for i := FrameStatStartInd to FrameStatCnt - 1 do
      begin
        if FrameStat[i].WPD < 0 then continue;
        Inc(VSum, FrameStat[i].WPD);
        Inc(VCnt);
      end;
      if VCnt <= 0 then FrameStatS[2] := '' else
       FrameStatS[2] := 'WPD ' + FloatToStrF(VSum / (1000 * VCnt), ffFixed, 10, 2) + ' ms';

      VSum := 0; VCnt := 0;
      for i := FrameStatStartInd to FrameStatCnt - 1 do
      begin
       // if FrameStat[i].Misc < 0 then continue;
        Inc(VSum, FrameStat[i].Misc);
        Inc(VCnt);
      end;
      if VCnt <= 0 then FrameStatS[3] := '' else
        FrameStatS[3] := 'Misc ' + FloatToStrF(VSum / (1000 * VCnt), ffFixed, 10, 2) + ' ms';

      FrameStatS[4] := '';

      S := FloatToStr(PeriodMS / (FrameStatCnt - FrameStatStartInd));//FloatToStrF(FPSCalcValue, ffFixed, 10, 2);
      FrameStatS[5] := 'Total ' + Copy(S, 1, Pos(',', S) + 2) + ' ms';

      FrameStatS[6] := '';

      VSum := 0;
      for i := FrameStatStartInd to FrameStatCnt - 1 do
        Inc(VSum, FrameStat[i].Vol);

      S := 'Traff  ';
      VSum := Round((VSum * 1000) / PeriodMS);
        VSum := VSum div 1024;
        if VSum div 1024 > 0 then S := S + IntToStr(VSum div 1024) + ' ';

      FrameStatS[7] := S + IntToStr(VSum mod 1024) + ' kb/s';

      FrameStatPeriod := 0;
      FrameStatStartInd := FrameStatCnt;
    end;
  end;
  {$ENDIF}
  finally
    CS.Release;
  end;

  if ((FScreenChanged or FCursorChanged) and
    (assigned(Viewer) or assigned(FOnData)))
    {$IFDEF DEBUG} or ((FrameStatPeriod = 0) and (FrameStatCnt > 0)) {$ENDIF}
     then Module.CallEvent(Sender, xOnData, self);
end;

procedure TRtcPDesktopControlUI.xOnClose(Sender, Obj: TObject);
begin
  FOnClose(self);
end;

procedure TRtcPDesktopControlUI.xOnError(Sender, Obj: TObject);
begin
  FOnError(self);
end;

procedure TRtcPDesktopControlUI.xOnLogOut(Sender, Obj: TObject);
begin
  FOnLogOut(self);
end;

procedure TRtcPDesktopControlUI.xOnData(Sender, Obj: TObject);
begin
  if assigned(FOnData) then
    FOnData(self);
  if assigned(Viewer) then
    DrawScreen(Viewer.Canvas, Viewer.Width, Viewer.Height, Viewer, False);
end;

procedure TRtcPDesktopControlUI.xOnOpen(Sender, Obj: TObject);
begin
  FOnOpen(self);
end;

procedure TRtcPDesktopControlUI.DrawScreen(Image: TCanvas;
  ImageWidth, ImageHeight: Integer; Container: TControl = nil;
  FullRepaint: boolean = False);
var
  P: TPoint;
  Scale2: double;
  MaxHeight, RestHeight: Integer;
  SeeCur: boolean;
  CurX1, CurY1, CurX2, CurY2: Integer;
  i, j : Integer;
  GL, GT, GR, GB : Integer;
  GVal : double;

  procedure CalcCursorPos;
  const
    INT_FAR_MARGIN = 16 { scrollbar } + 48 { margin };
    INT_NEAR_MARGIN = 48 { margin };
  begin
    SeeCur := Scr.CursorVisible and
      (assigned(Scr.CursorImage) or assigned(Scr.CursorMask)) and
      (Scr.CursorX <= Scr.Image.Width) and (Scr.CursorY <= Scr.Image.Height) and
      (Scr.CursorX >= 0) and (Scr.CursorY >= 0) and FRemoteCursor;
    if SeeCur then
    begin
//      CurX1 := round(Scale * (Scr.CursorX) - Scr.CursorHotX);
//      CurY1 := round(Scale * (Scr.CursorY) - Scr.CursorHotY);
      CurX1 := round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * (Scr.CursorX) - Scr.CursorHotX);
      CurY1 := round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * (Scr.CursorY) - Scr.CursorHotY);
      if assigned(Scr.CursorMask) then
      begin
        CurX2 := CurX1 + Scr.CursorMask.Width;
        CurY2 := CurY1 + Scr.CursorMask.Height;
      end
      else if assigned(Scr.CursorImage) then
      begin
        CurX2 := CurX1 + Scr.CursorImage.Width;
        CurY2 := CurY1 + Scr.CursorImage.Height;
      end;

      if CurX1 < 0 then
        CurX1 := 0
      else if CurX1 >= Scr.Image.Width then
        CurX1 := Scr.Image.Width - 1;
      if CurY1 < 0 then
        CurY1 := 0
      else if CurY1 >= Scr.Image.Height then
        CurY1 := Scr.Image.Height - 1;
      if CurX2 < 0 then
        CurX2 := 0
      else if CurX2 >= Scr.Image.Width then
        CurX2 := Scr.Image.Width - 1;
      if CurY2 < 0 then
        CurY2 := 0
      else if CurY2 >= Scr.Image.Height then
        CurY2 := Scr.Image.Height - 1;

      if FAutoScroll and assigned(Container) and assigned(Container.Parent) and
        (Container.Parent is TScrollBox) and (Container.Align <> alClient) then
      begin
        { we can see the curor, its moving, ensure that scrollbars move with cursor... }
        with TScrollBox(Container.Parent), TScrollBox(Container.Parent)
          .HorzScrollBar do
          if Visible then
          begin
            if Scr.CursorX - INT_NEAR_MARGIN < Position then
              Position := Scr.CursorX - INT_NEAR_MARGIN;
            if Scr.CursorX > Position + (Width - INT_FAR_MARGIN) then
              Position := Scr.CursorX - (Width - INT_FAR_MARGIN);
          end;
        with TScrollBox(Container.Parent), TScrollBox(Container.Parent)
          .VertScrollBar do
          if Visible then
          begin
            if Scr.CursorY - INT_NEAR_MARGIN < Position then
              Position := Scr.CursorY - INT_NEAR_MARGIN;
            if Scr.CursorY > Position + (Height - INT_FAR_MARGIN) then
              Position := Scr.CursorY - (Height - INT_FAR_MARGIN);
          end;
      end;
    end;
  end;

  procedure PaintCursor;
  begin
    if SeeCur then
    begin
      FCurPaint := True;

//      FCurPaintX := round(Scale * (Scr.CursorX) - Scr.CursorHotX);
//      FCurPaintY := round(Scale * (Scr.CursorY) - Scr.CursorHotY);
      FCurPaintX := Round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * (Scr.CursorX)- Scr.CursorHotX);
      FCurPaintY := Round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * (Scr.CursorY) - Scr.CursorHotY);
      if assigned(Scr.CursorImage) then
      begin
        FCurPaintW := Scr.CursorImage.Width;
        FCurPaintH := Scr.CursorImage.Height;
      end
      else
      begin
        FCurPaintW := 0;
        FCurPaintH := 0;
      end;
      if assigned(Scr.CursorMask) then
      begin
        if Scr.CursorMask.Width > FCurPaintW then
          FCurPaintW := Scr.CursorMask.Width;
        if Scr.CursorMask.Height > FCurPaintH then
          FCurPaintH := Scr.CursorMask.Height;
      end;

      if assigned(Scr.CursorMask) then
      begin
        if assigned(Scr.CursorImage) and
          (Scr.CursorMask.Height = Scr.CursorImage.Height) then
          BitBlt(Image.Handle, FCurPaintX, FCurPaintY, Scr.CursorMask.Width,
            Scr.CursorMask.Height, Scr.CursorMask.Canvas.Handle, 0, 0, SRCAND)
        else if Scr.CursorMask.Height > 1 then
        begin
          BitBlt(Image.Handle, FCurPaintX, FCurPaintY, Scr.CursorMask.Width,
            Scr.CursorMask.Height div 2, Scr.CursorMask.Canvas.Handle, 0,
            0, SRCAND);
          BitBlt(Image.Handle, FCurPaintX, FCurPaintY, Scr.CursorMask.Width,
            Scr.CursorMask.Height div 2, Scr.CursorMask.Canvas.Handle, 0,
            Scr.CursorMask.Height div 2, SRCINVERT);
        end;
      end;
      if assigned(Scr.CursorImage) then
      begin
        BitBlt(Image.Handle, FCurPaintX, FCurPaintY, Scr.CursorImage.Width,
          Scr.CursorImage.Height, Scr.CursorImage.Canvas.Handle, 0, 0,
          SRCPAINT);
      end;

      if (Scr.CursorUser <> Module.Client.LoginUserName) and
        (FMarkRemoteCursor.Style <> rcm_None) then
      begin
        FCurPaintX := FCurPaintX - FMarkRemoteCursor.Size;
        FCurPaintY := FCurPaintY - FMarkRemoteCursor.Size;
        FCurPaintW := FCurPaintW + FMarkRemoteCursor.Size * 2;
        FCurPaintH := FCurPaintH + FMarkRemoteCursor.Size * 2;

        Image.Brush.Style := bsSolid;
        Image.Brush.Color := FMarkRemoteCursor.FColor1; // clMaroon;
        Image.Pen.Color := FMarkRemoteCursor.FColor2; // clRed;

//        case FMarkRemoteCursor.Style of
//          rcm_Circle:
//            Image.Ellipse(round(Scale * Scr.CursorX) - FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorY) - FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorX) + FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorY) + FMarkRemoteCursor.Size);
//          rcm_Square:
//            Image.Rectangle(round(Scale * Scr.CursorX) - FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorY) - FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorX) + FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorY) + FMarkRemoteCursor.Size);
//        else
//          begin
//            Image.MoveTo(round(Scale * Scr.CursorX) - FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorY));
//            Image.LineTo(round(Scale * Scr.CursorX) + FMarkRemoteCursor.Size,
//              round(Scale * Scr.CursorY));
//            Image.MoveTo(round(Scale * Scr.CursorX), round(Scale * Scr.CursorY)
//              - FMarkRemoteCursor.Size);
//            Image.LineTo(round(Scale * Scr.CursorX), round(Scale * Scr.CursorY)
//              + FMarkRemoteCursor.Size);
//            Image.Rectangle(round(Scale * Scr.CursorX) - 1,
//              round(Scale * Scr.CursorY) - 1, round(Scale * Scr.CursorX) + 1,
//              round(Scale * Scr.CursorY) + 1);
//          end;
//        end;

        case FMarkRemoteCursor.Style of
          rcm_Circle:
            Image.Ellipse(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) - FMarkRemoteCursor.Size,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY) - FMarkRemoteCursor.Size,
              round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) + FMarkRemoteCursor.Size,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY) + FMarkRemoteCursor.Size);
          rcm_Square:
            Image.Rectangle(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) - FMarkRemoteCursor.Size,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY) - FMarkRemoteCursor.Size,
              round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) + FMarkRemoteCursor.Size,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY) + FMarkRemoteCursor.Size);
        else
          begin
            Image.MoveTo(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) - FMarkRemoteCursor.Size,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY));
            Image.LineTo(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) + FMarkRemoteCursor.Size,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY));
            Image.MoveTo(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX), round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY)
              - FMarkRemoteCursor.Size);
            Image.LineTo(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX), round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY)
              + FMarkRemoteCursor.Size);
            Image.Rectangle(round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) - 1,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY) - 1, round((ImageWidth - Scale * Scr.Image.Width) / 2 + Scale * Scr.CursorX) + 1,
              round((ImageHeight - Scale * Scr.Image.Height) / 2 + Scale * Scr.CursorY) + 1);
          end;
        end;
      end;
    end;
  end;

begin
  CS.Acquire;
  try
    // By restoring screen state as it was with last data received,
    // we can ensure that this method can be used any number of times with the same results.
    // The last to call this function will set values for the next run.
    RestoreScreenState;
//    if assigned(Container) then
    begin
      if (ControlMouse or ControlKeyboard) then
      begin
        if (FMouseDown = 0) then
        begin
          if (assigned(Container.Owner)) and (Container.Owner is TWinControl)
            //and FRemoteCursor
            and (GetForegroundWindow <> TWinControl(Container.Owner).Handle) //sstuman
          then
          begin
            // You lose control when Desktop Control window is not in the foreground
//            Container.Cursor := 200;
            Deactivated;
          end
          else if Container is TWinControl then
          begin
            GetCursorPos(P);
            if (ControlMode <> rtcpFullControl) and
              (WindowFromPoint(P) <> TWinControl(Container).Handle) then
            begin
              // in Manual and Auto control mode, you lose control when you move your mouse outside the window
//              Container.Cursor := 200;
              Deactivated;
            end;
          end
          else if assigned(Container.Parent) and
            (Container.Parent is TWinControl) then
          begin
            GetCursorPos(P);
            if (ControlMode <> rtcpFullControl) and
              (WindowFromPoint(P) <> Container.Parent.Handle) then
            begin
              // in Auto control mode, you lose control when you move your mouse outside the window
//              Container.Cursor := 200;
              Deactivated;
            end;
          end;
        end;
      end;
//      else if Container.Cursor <> 200 then
//        Container.Cursor := 200;
    end;

    if HaveScreen and (FullRepaint or ScreenChanged or CursorChanged) then
    begin
      if (ImageWidth <> Scr.Image.Width) or (ImageHeight <> Scr.Image.Height)
      then
      begin
        Scale := ImageWidth / Scr.Image.Width;
        Scale2 := ImageHeight / Scr.Image.Height;
        if Scale2 < Scale then
          Scale := Scale2;
      end
      else
        Scale := 1;

      if Scale = 1 then
      begin
        if ScreenChanged or FullRepaint then
        begin
          FScreenChanged := False;
          FCursorChanged := False;
          FCurPaint := False;
          CalcCursorPos;
          if SeeCur then
          begin
            if CurY1 > 0 then
              BitBlt(Image.Handle, Round((ImageWidth - Scr.Image.Width) / 2), Round((ImageHeight - Scr.Image.Height) / 2), Scr.Image.Width, CurY1,
                Scr.Image.Canvas.Handle, 0, 0, SRCCOPY);
            if CurY2 < Scr.Image.Height then
              BitBlt(Image.Handle, Round((ImageWidth - Scr.Image.Width) / 2), CurY2 + Round((ImageHeight - Scr.Image.Height) / 2) + 1, Scr.Image.Width,
                Scr.Image.Height - CurY2, Scr.Image.Canvas.Handle, 0,
                CurY2 + 1, SRCCOPY);
            if CurX1 > 0 then
              BitBlt(Image.Handle, Round((ImageWidth - Scr.Image.Width) / 2), CurY1 + Round((ImageHeight - Scr.Image.Height) / 2), CurX1, CurY2 - CurY1 + 1,
                Scr.Image.Canvas.Handle, 0, CurY1, SRCCOPY);
            if CurX2 < Scr.Image.Width then
              BitBlt(Image.Handle, CurX2 + Round((ImageWidth - Scr.Image.Width) / 2) + 1, CurY1 + Round((ImageHeight - Scr.Image.Height) / 2), Scr.Image.Width - CurX2,
                CurY2 - CurY1 + 1, Scr.Image.Canvas.Handle, CurX2 + 1,
                CurY1, SRCCOPY);

            BitBlt(Image.Handle, CurX1 + Round((ImageWidth - Scr.Image.Width) / 2), CurY1 + Round((ImageHeight - Scr.Image.Height) / 2), CurX2 - CurX1 + 1,
              CurY2 - CurY1 + 1, Scr.Image.Canvas.Handle, CurX1, CurY1,
              SRCCOPY);
          end
          else
          begin
            RestHeight := Scr.Image.Height;
            while RestHeight > 0 do
            begin
              MaxHeight := RestHeight;
              if MaxHeight > 32 then
                MaxHeight := 32;
              BitBlt(Image.Handle, 0, Scr.Image.Height - RestHeight,
                Scr.Image.Width, MaxHeight, Scr.Image.Canvas.Handle, 0,
                Scr.Image.Height - RestHeight, SRCCOPY);
              RestHeight := RestHeight - MaxHeight;
            end;
          end;
        end
        else // only Cursor changed
        begin
          FCursorChanged := False;
          if FCurPaint then // repaint image at old cursor position
          begin
            BitBlt(Image.Handle, FCurPaintX, FCurPaintY, FCurPaintW, FCurPaintH,
              Scr.Image.Canvas.Handle, FCurPaintX, FCurPaintY, SRCCOPY);
            FCurPaint := False;
          end;
          CalcCursorPos;
        end;
      end
      else if Scale > 1 then
      begin
        FScreenChanged := False;
        FCursorChanged := False;
        FCurPaint := False;
        CalcCursorPos;
        //sstuman
        StretchBlt(Image.Handle, Round((ImageWidth - Scale * Scr.Image.Width) / 2),
          Round((ImageHeight - Scale * Scr.Image.Height) / 2), round(Scr.Image.Width * Scale),
          round(Scr.Image.Height * Scale), Scr.Image.Canvas.Handle, 0, 0,
          Scr.Image.Width, Scr.Image.Height, SRCCOPY);
      end
      else
      begin
        FScreenChanged := False;
        FCursorChanged := False;
        FCurPaint := False;
        CalcCursorPos;
        if FSmoothScale then
          SetStretchBltMode(Image.Handle, HALFTONE);

        StretchBlt(Image.Handle, Round((ImageWidth - Scale * Scr.Image.Width) / 2), Round((ImageHeight - Scale * Scr.Image.Height) / 2), round(Scr.Image.Width * Scale),
          round(Scr.Image.Height * Scale), Scr.Image.Canvas.Handle, 0, 0,
          Scr.Image.Width, Scr.Image.Height, SRCCOPY);

        if FSmoothScale then
          SetStretchBltMode(Image.Handle, COLORONCOLOR);
      end;

      if ImageWidth > round(Scr.Image.Width * Scale) then
      begin
      //Color
//        Image.Brush.Color := clBlack;
//        Image.Pen.Color := clBlack;
        Image.Brush.Color := FViewer.Color;
        Image.Pen.Color := FViewer.Color;
        Image.Brush.Style := bsSolid;
        Image.Rectangle(round(Scr.Image.Width * Scale) + Round((ImageWidth - Scale * Scr.Image.Width) / 2), 0, ImageWidth,
          ImageHeight);
      end;

      if ImageHeight > round(Scr.Image.Height * Scale) then
      begin
        //Color
//        Image.Brush.Color := clBlack;
//        Image.Pen.Color := clBlack;
        Image.Brush.Color := FViewer.Color;
        Image.Pen.Color := FViewer.Color;
        Image.Brush.Style := bsSolid;
        Image.Rectangle(0, round(Scr.Image.Height * Scale) + Round((ImageHeight - Scale * Scr.Image.Height) / 2), ImageWidth,
          ImageHeight);
      end;

      if not Scr.CursorVisible then
      begin
        if assigned(Container) then
        begin
          if Container.Cursor <> 200 then
          begin
//            Container.Cursor := 200;
            GetCursorPos(P);
            SetCursorPos(P.X, P.Y);
          end;
        end;
      end
      else if not assigned(Container) then
        PaintCursor
      else if (Scr.CursorUser <> Module.Client.LoginUserName) then
      begin
        PaintCursor;
        if Container.Cursor <> 200 then
        begin
//          Container.Cursor := 200;
          GetCursorPos(P);
          SetCursorPos(P.X, P.Y);

          if (FMouseDown = 0) and (ControlMode = rtcpAutoControl) then
            Deactivated;
        end;
      end
      else
      begin
        if ControlMouse and (Scr.CursorStd or not FExactCursor) and
          (Scr.CursorUser = Module.Client.LoginUserName) then
        begin
          // cursor is where we have placed it
          if Scr.CursorStd then
          begin
            if Container.Cursor <> Scr.CursorShape then
            begin
              Container.Cursor := Scr.CursorShape;

              //+sstuman
              if Scr.CursorShape < 0 then
                Container.Cursor := crDefault;
              //-sstuman

              GetCursorPos(P);
              SetCursorPos(P.X, P.Y);
            end;
          end
          else
          begin
            if Container.Cursor <> crDefault then
            begin
              Container.Cursor := crDefault;
              GetCursorPos(P);
              SetCursorPos(P.X, P.Y);
            end;
          end;
        end
        else
        begin
          PaintCursor;
          if ControlMouse and Scr.CursorStd then
          begin
            if Container.Cursor <> Scr.CursorShape then
            begin
              Container.Cursor := Scr.CursorShape;
              GetCursorPos(P);
              SetCursorPos(P.X, P.Y);
            end;
          end
          else
          begin
            if Container.Cursor <> 200 then
            begin
//              Container.Cursor := 200;
              GetCursorPos(P);
              SetCursorPos(P.X, P.Y);
            end;
          end;
        end;
      end;
    end
    else if not HaveScreen then
    begin
      if assigned(Container) then
      begin
//        Container.Cursor := 200;
        Scale := 1;
      end;
    end;
    {$IFDEF DEBUG}
     CS.Acquire;

     if Assigned(Viewer) then
        with Viewer, Viewer.Canvas do
        begin
         // Brush.Color := clWhite;
    //  Image.Brush.Style := bsSolid;
            Brush.Color := $000000;

            //FPSStr := '1234567890';
          TextFlags := 0;//ETO_CLIPPED;

          Viewer.Canvas.Font.Size := Debug.FrameStatFontSize;//ClipRect.Height div 50;
          Font.Color := $0080ff;
          for i := 0 to 7 do
          begin
            if i in [4, 6] then continue;

            TextOut(
            //TextOutA(Handle,
              Max(ClipRect.Left, ClipRect.Right - Viewer.Canvas.Font.Size * 12),
              Max(ClipRect.Top, ClipRect.Bottom - Round(Viewer.Canvas.Font.Size * 1.5 *
                (9 - i))), FrameStatS[i]);

            GL := ClipRect.Right - Viewer.Canvas.Font.Size * 12 - 150;
            GT := ClipRect.Bottom - Round(Viewer.Canvas.Font.Size * (1.5 * (9 - i))) + 2;
            GR := ClipRect.Right - Viewer.Canvas.Font.Size * 12 - 50;
            GB := ClipRect.Bottom - Round(Viewer.Canvas.Font.Size * (1.5 * (9 - i) - 1.5)) - 2;

           // Brush.Color := $000000;
           // FillRect(TRect.Create(GL, GT, GR, GB));

            Brush.Color := $0080ff;
            FrameRect(TRect.Create(GL, GT, GR, GB));

            Pen.Color := $0080ff;

            for j := 0 to FrameStatCnt - 1 do
            begin
              MoveTo(GL + j, GB - 1);

              case i of
                0 : GVal := FrameStat[j].DD / 100000;
                1 : GVal := FrameStat[j].WPE / 100000;
                2 : GVal := FrameStat[j].WPD / 100000;
                3 : GVal := FrameStat[j].Misc / 100000;
                5 : GVal := FrameStat[j].Total / 100000;
                7 : GVal := FrameStat[j].Vol / (1024 * 1024);
              end;
              LineTo(GL + j, GB - Round((GB - GT) * Min(GVal, 1)) - 1);
            end;

            Brush.Color := $000000;
          end;
            //  PAnsiChar(FPSStr), Length(FPSStr));
        end;

      CS.Release;
    {$ENDIF}
  finally
    CS.Release;
  end;

  if FRemoteCursor then
    PaintCursor;

//  Image.Brush.Color := clWhite;
//  Image.FillRect(Rect(0, 0, 250, 15));
//  Image.TextOut(0, 0, 'Cur X: ' + IntToStr(FCurPaintX) + ' Cur Y: ' + IntToStr(FCurPaintY) + ' Last X: ' + IntToStr(FCurPaintX) + ' Last Y: ' + IntToStr(FCurPaintY));
end;

function TRtcPDesktopControlUI.ScreenHeight: Integer;
begin
  CS.Acquire;
  try
    if HaveScreen then
      Result := Scr.Image.Height
    else
      Result := 0;
  finally
    CS.Release;
  end;
end;

function TRtcPDesktopControlUI.ScreenWidth: Integer;
begin
  CS.Acquire;
  try
    if HaveScreen then
      Result := Scr.Image.Width
    else
      Result := 0;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopControlUI.SendMouseDown(X, Y: Integer; Shift: TShiftState;
  Button: TMouseButton; Sender: TObject);
begin
  CS.Acquire;
  try
    if not HaveScreen then
      Exit;
    if (ControlMode <> rtcpNoControl) and not ControlMouse then
    begin
      ControlMouse := True;
      if not ControlKeyboard then
        ControlStart(Sender);
    end;
    if not ControlMouse then
      Exit;
  finally
    CS.Release;
  end;

  //sstuman FViewer.Width / Scr.Image.Width
  inherited SendMouseDown(round(((X - (FViewer.Width - Scale * Scr.Image.Width) / 2)) / Scale), round((Y - (FViewer.Height - Scale * Scr.Image.Height) / 2) / Scale), Shift,
    Button, Sender);
//  inherited SendMouseDown(round(X * Scr.Image.Width / FViewer.Width), round(Y * Scr.Image.Height / FViewer.Height), Shift,
//    Button, Sender);
  LastX := X;
  LastY := Y;
  case Button of
    mbLeft:
      FMouseDown := FMouseDown or 1;
    mbRight:
      FMouseDown := FMouseDown or 2;
    mbMiddle:
      FMouseDown := FMouseDown or 4;
  end;
end;

procedure TRtcPDesktopControlUI.SendMouseMove(X, Y: Integer; Shift: TShiftState;
  Sender: TObject);
begin
  CS.Acquire;
  try
    if not HaveScreen then
      Exit;
    if (ControlMode = rtcpFullControl) and not ControlMouse then
    begin
      LastX := -1;
      LastY := -1;
      ControlMouse := True;
      if not ControlKeyboard then
        ControlStart(Sender);
    end;
    if not ControlMouse then
      Exit;
  finally
    CS.Release;
  end;

  if (LastX <> X) or (LastY <> Y) then
  begin
  //sstuman
  inherited SendMouseMove(round(((X - (FViewer.Width - Scale * Scr.Image.Width) / 2)) / Scale), round((Y - (FViewer.Height - Scale * Scr.Image.Height) / 2) / Scale), Shift,
      Sender);
//  inherited SendMouseMove(round(X * Scr.Image.Width / FViewer.Width), round(Y * Scr.Image.Height / FViewer.Height), Shift, Sender);
  LastX := X;
  LastY := Y;
  end;
end;

procedure TRtcPDesktopControlUI.SendMouseUp(X, Y: Integer; Shift: TShiftState;
  Button: TMouseButton; Sender: TObject);
begin
  CS.Acquire;
  try
    if not HaveScreen then
      Exit;
    if not ControlMouse then
      Exit;
  finally
    CS.Release;
  end;

  //sstuman
  inherited SendMouseUp(round(((X - (FViewer.Width - Scale * Scr.Image.Width) / 2)) / Scale), round((Y - (FViewer.Height - Scale * Scr.Image.Height) / 2) / Scale), Shift,
    Button, Sender);
//  inherited SendMouseUp(round(X * Scr.Image.Width / FViewer.Width), round(Y * Scr.Image.Height / FViewer.Height), Shift,
//    Button, Sender);
  LastX := X;
  LastY := Y;

  case Button of
    mbLeft:
      FMouseDown := FMouseDown and not 1;
    mbRight:
      FMouseDown := FMouseDown and not 2;
    mbMiddle:
      FMouseDown := FMouseDown and not 4;
  end;
end;

procedure TRtcPDesktopControlUI.SendKeyDown(const Key: Word; Shift: TShiftState;
  Sender: TObject);
begin
  CS.Acquire;
  try
    if not HaveScreen then
      Exit;
    if (ControlMode <> rtcpNoControl) and not ControlKeyboard then
    begin
      ControlKeyboard := True;
      if not ControlMouse then
        ControlStart(Sender);
    end;
    if not ControlKeyboard then
      Exit;
  finally
    CS.Release;
  end;

  case Key of
    VK_SHIFT:
      FShiftDown := True;
    VK_CONTROL:
      FCtrlDown := True;
    VK_MENU:
      FAltDown := True;
    VK_LWIN:
      FLWinDown := True;
    VK_RWIN:
      FRWinDown := True;
  end;
  inherited SendKeyDown(Key, Shift, Sender);
end;

procedure TRtcPDesktopControlUI.SendKeyUp(const Key: Word; Shift: TShiftState;
  Sender: TObject);
begin
  CS.Acquire;
  try
    if not HaveScreen then
      Exit;
    if (ControlMode <> rtcpNoControl) and not ControlKeyboard then
    begin
      ControlKeyboard := True;
      if not ControlMouse then
        ControlStart(Sender);
    end;
    if not ControlKeyboard then
      Exit;
  finally
    CS.Release;
  end;

  case Key of
    VK_SHIFT:
      FShiftDown := False;
    VK_CONTROL:
      FCtrlDown := False;
    VK_MENU:
      FAltDown := False;
    VK_LWIN:
      FLWinDown := False;
    VK_RWIN:
      FRWinDown := False;
  end;

  if Key = VK_TAB then // we don't get "TAB down" events
    inherited SendKeyDown(Key, Shift, Sender);

  inherited SendKeyUp(Key, Shift, Sender);
end;

procedure TRtcPDesktopControlUI.SendMouseWheel(Wheel: Integer;
  Shift: TShiftState; Sender: TObject);
begin
  CS.Acquire;
  try
    if not HaveScreen then
      Exit;
    if (ControlMode <> rtcpNoControl) and not ControlMouse then
    begin
      ControlMouse := True;
      if not ControlKeyboard then
        ControlStart(Sender);
    end;
    if not ControlMouse then
      Exit;
  finally
    CS.Release;
  end;
  inherited SendMouseWheel(Wheel, Shift, Sender);
end;

procedure TRtcPDesktopControlUI.Deactivated(Sender: TObject = nil);
begin
  if ControlKeyboard or ControlMouse then
  begin
    ControlMouse := False;
    FMouseDown := 0;
    if ControlKeyboard then
    begin
      ControlKeyboard := False;
      if FLWinDown then
      begin
        FLWinDown := False;
        inherited SendKeyUp(VK_LWIN, [], Sender);
      end;
      if FRWinDown then
      begin
        FRWinDown := False;
        inherited SendKeyUp(VK_RWIN, [], Sender);
      end;
      if FShiftDown then
      begin
        FShiftDown := False;
        inherited SendKeyUp(VK_SHIFT, [], Sender);
      end;
      if FCtrlDown then
      begin
        FCtrlDown := False;
        inherited SendKeyUp(VK_CONTROL, [], Sender);
      end;
      if FAltDown then
      begin
        FAltDown := False;
        inherited SendKeyUp(VK_MENU, [], Sender);
        inherited SendKeyDown(VK_MENU, [], Sender);
        inherited SendKeyUp(VK_MENU, [], Sender);
      end;
    end;
    ControlStop(Sender);
  end
  else
  begin
    FLWinDown := False;
    FRWinDown := False;
    FShiftDown := False;
    FCtrlDown := False;
    FAltDown := False;
    FMouseDown := 0;
  end;
end;

function TRtcPDesktopControlUI.HaveScreen: boolean;
begin
  CS.Acquire;
  try
    Result := FHaveScreen;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopControlUI.SetExactCursor(const Value: boolean);
begin
  FExactCursor := Value;
  // force screen refresh
  if HaveScreen and (assigned(Viewer) or assigned(FOnData)) then
    Module.CallEvent(nil, xOnData, self);
end;

procedure TRtcPDesktopControlUI.SetRemoteCursor(const Value: boolean);
begin
  FRemoteCursor := Value;

//  Scr.CursorVisible := Value;

  // force screen refresh
  if HaveScreen and (assigned(Viewer) or assigned(FOnData)) then
    Module.CallEvent(nil, xOnData, self);
end;

procedure TRtcPDesktopControlUI.SetSmoothScale(const Value: boolean);
begin
  FSmoothScale := Value;
  // force screen refresh
  if HaveScreen and (assigned(Viewer) or assigned(FOnData)) then
    Module.CallEvent(nil, xOnData, self);
end;

procedure TRtcPDesktopControlUI.SetControlMode(const Value
  : TRtcPDesktopControlMode);
begin
  FControlMode := Value;
  // force screen refresh
  if HaveScreen and (assigned(Viewer) or assigned(FOnData)) then
    Module.CallEvent(nil, xOnData, self);
end;

function TRtcPDesktopControlUI.GetViewer: TRtcPDesktopViewer;
begin
  Result := FViewer;
end;

procedure TRtcPDesktopControlUI.SetViewer(const Value: TRtcPDesktopViewer);
begin
  if (Value <> FViewer) then
  begin
    if assigned(FViewer) then
      FViewer.UI := nil;
    FViewer := Value;
    if assigned(FViewer) then
      FViewer.UI := self;
  end;
end;

function TRtcPDesktopControlUI.GetActive: boolean;
begin
  Result := FUserCnt > 0;
end;

procedure TRtcPDesktopControlUI.SetActive(const Value: boolean);
begin
  if Value then
    Open
  else
    Close;
end;

procedure TRtcPDesktopControlUI.NotifyUI(const msg: Integer; Sender: TObject);
begin
  case msg of
    RTCPDESKTOP_SmoothScale_On:
      SmoothScale := True;
    RTCPDESKTOP_SmoothScale_Off:
      SmoothScale := False;
    RTCPDESKTOP_ExactCursor_On:
      ExactCursor := True;
    RTCPDESKTOP_ExactCursor_Off:
      ExactCursor := False;
    RTCPDESKTOP_ControlMode_Off:
      ControlMode := rtcpNoControl;
    RTCPDESKTOP_ControlMode_Manual:
      ControlMode := rtcpManualControl;
    RTCPDESKTOP_ControlMode_Auto:
      ControlMode := rtcpAutoControl;
    RTCPDESKTOP_ControlMode_Full:
      ControlMode := rtcpFullControl;
    RTCPDESKTOP_MapKeys_On:
      MapKeys := True;
    RTCPDESKTOP_MapKeys_Off:
      MapKeys := False;
    RTCPDESKTOP_RemoteCursor_On:
      RemoteCursor := True;
    RTCPDESKTOP_RemoteCursor_Off:
      RemoteCursor := False;
  end;
end;

procedure TRtcPDesktopControlUI.Send_AltTAB(Sender: TObject);
begin
  Module.Send_AltTAB(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_CtrlAltDel(Sender: TObject);
begin
  Module.Send_CtrlAltDel(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_CtrlAltTAB(Sender: TObject);
begin
  Module.Send_CtrlAltDel(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_FileCopy(Sender: TObject);
begin
  Module.Send_FileCopy(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_HideDesktop(Sender: TObject);
begin
  Module.Send_HideDesktop(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_BlockKeyboardAndMouse(Sender: TObject);
begin
  Module.Send_BlockKeyboardAndMouse(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_UnBlockKeyboardAndMouse(Sender: TObject);
begin
  Module.Send_UnBlockKeyboardAndMouse(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_PowerOffMonitor(Sender: TObject);
begin
  Module.Send_PowerOffMonitor(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_PowerOnMonitor(Sender: TObject);
begin
  Module.Send_PowerOnMonitor(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_PowerOffSystem(Sender: TObject);
begin
  Module.Send_PowerOffSystem(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_LockSystem(Sender: TObject);
begin
  Module.Send_LockSystem(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_LogoffSystem(Sender: TObject);
begin
  Module.Send_LogoffSystem(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_RestartSystem(Sender: TObject);
begin
  Module.Send_RestartSystem(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_ShiftAltTAB(Sender: TObject);
begin
  Module.Send_ShiftAltTAB(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_ShiftCtrlAltTAB(Sender: TObject);
begin
  Module.Send_ShiftCtrlAltTAB(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_ShowDesktop(Sender: TObject);
begin
  Module.Send_ShowDesktop(UserName, Sender);
end;

procedure TRtcPDesktopControlUI.Send_SpecialKey(const Key: RtcString;
  Sender: TObject);
begin
  Module.Send_SpecialKey(UserName, Key, Sender);
end;

procedure TRtcPDesktopControlUI.ChgDesktop_Begin;
begin
  Inc(FChg_DeskCnt);
  if FChg_DeskCnt = 1 then
  begin
    FChg_Desktop := TRtcFunctionInfo.Create;
    FChg_Desktop.FunctionName := 'chgdesk';
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_End(Sender: TObject = nil);
begin
  Dec(FChg_DeskCnt);
  if FChg_DeskCnt = 0 then
  begin
    if assigned(Module) and assigned(Module.Client) then
    begin
      Module.Client.SendToUser(Sender, UserName, FChg_Desktop);
      FChg_Desktop := nil;
    end
    else
    begin
      FChg_Desktop.Free;
      FChg_Desktop := nil;
    end;
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_CaptureAllMonitors(Value: boolean;
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['monitors'] := Value;
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_CaptureLayeredWindows(Value: boolean;
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['layered'] := Value;
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_ColorLimit
  (const Value: TrdColorLimit; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['color'] := Ord(Value);
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_ColorLowLimit
  (const Value: TrdLowColorLimit; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['colorlow'] := Ord(Value);
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_ColorReducePercent
  (const Value: Integer; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['colorpercent'] := Value;
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_FrameRate(const Value: TrdFrameRate;
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['frame'] := Ord(Value);
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_SendScreenInBlocks
  (Value: TrdScreenBlocks; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scrblocks'] := Ord(Value);
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_SendScreenRefineBlocks
  (Value: TrdScreenBlocks; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scrblocks2'] := Ord(Value);
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_SendScreenRefineDelay(Value: Integer;
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scr2delay'] := Value;
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_SendScreenSizeLimit
  (Value: TrdScreenLimit; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scrlimit'] := Ord(Value);
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_UseMirrorDriver(Value: boolean;
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['mirror'] := Value;
  finally
    ChgDesktop_End(Sender);
  end;
end;

procedure TRtcPDesktopControlUI.ChgDesktop_UseMouseDriver(Value: boolean;
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['mouse'] := Value;
  finally
    ChgDesktop_End(Sender);
  end;
end;

function TRtcPDesktopControlUI.GetCursorX: Integer;
begin
  if assigned(Scr) then
    Result := Scr.CursorX
  else
    Result := -1;
end;

function TRtcPDesktopControlUI.GetCursorY: Integer;
begin
  if assigned(Scr) then
    Result := Scr.CursorY
  else
    Result := -1;
end;

function TRtcPDesktopControlUI.InControl: boolean;
begin
  CS.Acquire;
  try
    Result := ControlMouse or ControlKeyboard;
  finally
    CS.Release;
  end;
end;

{ TRtcPDesktopViewer }

constructor TRtcPDesktopViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque]; //+sstuman

//  Canvas.Brush.Color := Color;
//  Canvas.Pen.Color := Color;
//  Canvas.FillRect(Rect(0, 0, Width, Height));
end;

destructor TRtcPDesktopViewer.Destroy;
begin
  if assigned(UI) then
    UI.Viewer := nil;
  inherited;
end;

function TRtcPDesktopViewer.GetUI: TRtcPDesktopControlUI;
begin
  Result := FUI;
end;

procedure TRtcPDesktopViewer.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if assigned(UI) then
    UI.SendMouseDown(X, Y, Shift, Button);
end;

procedure TRtcPDesktopViewer.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if assigned(UI) then
    UI.SendMouseMove(X, Y, Shift);
end;

procedure TRtcPDesktopViewer.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if assigned(UI) then
    UI.SendMouseUp(X, Y, Shift, Button);
end;

procedure TRtcPDesktopViewer.Paint;
begin
  inherited;
  if assigned(UI) and UI.HaveScreen then
    UI.DrawScreen(Canvas, Width, Height, self, True);
end;

procedure TRtcPDesktopViewer.Resize;
begin
  inherited;
  if assigned(UI) and UI.HaveScreen then
    UI.DrawScreen(Canvas, Width, Height, self, True);
end;

procedure TRtcPDesktopViewer.SetUI(const Value: TRtcPDesktopControlUI);
begin
  if Value <> FUI then
  begin
    FUI := Value;
    if assigned(UI) and UI.HaveScreen then
      UI.DrawScreen(Canvas, Width, Height, self, True);
  end;
end;

{ TRtcRemoteCursorMark }

constructor TRtcRemoteCursorMark.Create;
begin
  inherited;
  FStyle := rcm_None;
  FColor1 := clMaroon;
  FColor2 := clRed;
  FSize := 3;
end;


end.
