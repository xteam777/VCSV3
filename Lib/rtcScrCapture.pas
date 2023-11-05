{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcScrCapture;

interface

{$INCLUDE rtcDefs.inc}
{$INCLUDE rtcPortalDefs.inc}
{$POINTERMATH ON}

uses
  Windows, Messages, Classes, rtcSystem, LockWindowUnit,
  SysUtils, Graphics, Controls, Forms, //rtcpDesktopHost,
  rtcInfo, rtcLog, rtcZLib, SyncObjs, rtcScrUtils, CommonData, uVircessTypes,
  //rtcXJPEGEncode,

  // cromis units
  Cromis.Comm.Custom, Cromis.Comm.IPC, Cromis.Threading,

  ServiceMgr, rtcWinLogon, rtcScreenEncoder;

var
  RTC_CAPTUREBLT: DWORD = $40000000;

type
  TRtcCaptureMode=(captureEverything, captureDesktopOnly);
  TRtcMouseControlMode=(eventMouseControl, messageMouseControl);

var
  RtcCaptureMode:TRtcCaptureMode=captureEverything;
  RtcMouseControlMode:TRtcMouseControlMode=eventMouseControl;
  RtcMouseWindowHdl:HWND=0;

type
  TRtcScreenCapture = class
  private
    ScrEnc : TRtcScreenEncoder;


   // FCaptureMask: DWORD;
    FBPPLimit, FMaxTotalSize, FScreen2Delay, FScreenBlockCount,
      FScreen2BlockCount: integer;

    FShiftDown, FCtrlDown, FAltDown: boolean;

    FMouseX, FMouseY, FMouseHotX, FMouseHotY: integer;
    FMouseVisible: boolean;
    FMouseHandle: HICON;
    FMouseIcon: TBitmap;
    FMouseIconMask: TBitmap;
    FMouseShape: integer;

    FMouseChangedShape: boolean;
    FMouseMoved: boolean;
    FMouseLastVisible: boolean;
    FMouseInit: boolean;
    FMouseUser: String;

    FLastMouseUser: String;
    FLastMouseX, FLastMouseY: integer;

    FReduce32bit, FReduce16bit, FLowReduce32bit, FLowReduce16bit: DWORD;

    FLowReduceColors: boolean;
    FLowReduceType: integer;
    FLowReduceColorPercent: integer;

    // FCaptureWidth, FCaptureHeight, FCaptureLeft, FCaptureTop, FScreenWidth,
    //  FScreenHeight, FScreenLeft, FScreenTop: longint;

    FMultiMon: boolean;

    //FPDesktopHost: TRtcPDesktopHost;

    // procedure Init;

    FServerCursor: TCursor;

    function GetBPPLimit: integer;
    procedure SetBPPLimit(const Value: integer);

    function GetMaxTotalSize: integer;
    procedure SetMaxTotalSize(const Value: integer);

    function GetReduce16bit: longword;
    function GetReduce32bit: longword;
    procedure SetReduce16bit(const Value: longword);
    procedure SetReduce32bit(const Value: longword);

    procedure Post_MouseDown(Button: TMouseButton);
    procedure Post_MouseUp(Button: TMouseButton);
    procedure Post_MouseMove(X, Y: integer);
    procedure Post_MouseWheel(Wheel: integer);

    procedure keybdevent(key: word; Down: boolean = True; Extended: boolean=False);

    procedure SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);
    procedure ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);

    procedure SetMultiMon(const Value: boolean);
    function GetLowReduce16bit: longword;
    function GetLowReduce32bit: longword;
    procedure SetLowReduce16bit(const Value: longword);
    procedure SetLowReduce32bit(const Value: longword);

    function GetLowReduceColors: boolean;
    procedure SetLowReduceColors(const Value: boolean);

    function GetLowReduceColorPercent: integer;
    procedure SetLowReduceColorPercent(const Value: integer);
   // function GetScreenBlockCount: integer;
   // procedure SetScreenBlockCount(const Value: integer);
   // function GetScreen2BlockCount: integer;
  //  procedure SetScreen2BlockCount(const Value: integer);
    function GetScreen2Delay: integer;
    procedure SetScreen2Delay(const Value: integer);
    function GetLowReduceType: integer;
    procedure SetLowReduceType(const Value: integer);

    procedure SetClipRect(const Value : TRect);
  public
    FHaveScreen: Boolean;
    FOnHaveScreenChanged: TNotifyEvent;

    constructor Create; virtual;
    destructor Destroy; override;

    procedure Clear;
   // function PackScreenImages(Data : RtcByteArray) : Cardinal;
    procedure GrabScreen(ScrDelta : PString; ScrFull : PString = NIL);
    procedure GrabMouse;
    procedure SetBitsPerPixelLimit(Value: Integer);
    procedure SetCompressImage(Value: Boolean);

    //function GetScreen: RtcString;
   // function GetScreenDelta: RtcString;

    function GetMouse: RtcString;
    function GetMouseDelta: RtcString;

    // control events
    procedure MouseDown(const user: String; X, Y: integer;
      Button: TMouseButton);
    procedure MouseUp(const user: String; X, Y: integer; Button: TMouseButton);
    procedure MouseMove(const user: String; X, Y: integer);
    procedure MouseWheel(Wheel: integer);

    procedure KeyPressW(const AText: WideString; AKey: word);
//    procedure KeyPress(const AText: RtcString; AKey: word);
    procedure KeyDown(key: word; Shift: TShiftState);
    procedure KeyUp(key: word; Shift: TShiftState);

    procedure SpecialKey(const AKey: RtcString);

    procedure LWinKey(key: word);
    procedure RWinKey(key: word);

    procedure ReleaseAllKeys;

    procedure SetAdapter(AdapterName: String);

    property ClipRect : TRect write SetClipRect;
    property BPPLimit: integer read GetBPPLimit write SetBPPLimit default 4;
    property MaxTotalSize: integer read GetMaxTotalSize write SetMaxTotalSize
      default 0;
 //   property ScreenBlockCount: integer read GetScreenBlockCount
 //     write SetScreenBlockCount default 1;
//    property Screen2BlockCount: integer read GetScreen2BlockCount
//      write SetScreen2BlockCount default 1;
    property Screen2Delay: integer read GetScreen2Delay write SetScreen2Delay
      default 0;
   // property FullScreen: boolean read GetFullScreen write SetFullScreen  default True;
  //  property ScreenRect : TRect read GetScreenRect write SetScreenRect;

    property Reduce16bit: longword read GetReduce16bit write SetReduce16bit;
    property Reduce32bit: longword read GetReduce32bit write SetReduce32bit;
    property LowReduce16bit: longword read GetLowReduce16bit
      write SetLowReduce16bit;
    property LowReduce32bit: longword read GetLowReduce32bit
      write SetLowReduce32bit;
    property LowReducedColors: boolean read GetLowReduceColors
      write SetLowReduceColors;
    property LowReduceType: integer read GetLowReduceType
      write SetLowReduceType;
    property LowReduceColorPercent: integer read GetLowReduceColorPercent
      write SetLowReduceColorPercent;


    property MultiMonitor: boolean read FMultiMon write SetMultiMon
      default False;
    property HaveScreen: Boolean read FHaveScreen;
    property OnHaveScreeenChanged: TNotifyEvent read FOnHaveScreenChanged write FOnHaveScreenChanged;
  end;

const
  RMX_MAGIC_NUMBER = 777;

  procedure SendIOToHelperByIPC(QueryType: Cardinal; IOType: DWORD; dwFlags: DWORD; dx, dy: Longint; mouseData: Integer; wVk, wScan: WORD; AText: WideString);
  function NeedSendIOToHelper: Boolean;

implementation

uses Types;

procedure TRtcScreenCapture.SetBitsPerPixelLimit(Value: Integer);
begin
  ScrEnc.EncodedImageBPP := Value;
end;

procedure TRtcScreenCapture.SetCompressImage(Value: Boolean);
begin
  ScrEnc.CompressImage := Value;
end;

procedure SendIOToHelperByIPC(QueryType: Cardinal; IOType: DWORD; dwFlags: DWORD; dx, dy: Longint; mouseData: Integer; wVk, wScan: WORD; AText: WideString);
var
  SessionID: DWORD;
  Request, Response: IIPCData;
  IPCClient: TIPCClient;
  I, Len: Integer;
begin
//  if IsConsoleClient then
  if IsService then
    SessionID := ActiveConsoleSessionID
  else
    SessionID := CurrentSessionID;

  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Remox_IPC_Session_' + IntToStr(SessionID);
    IPCClient.ConnectClient(1000); //cDefaultTimeout
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.Data.WriteInteger('QueryType', QueryType);
        Request.Data.WriteInteger('IOType', IOType);
        Request.Data.WriteInteger('dwFlags', dwFlags);
        Request.Data.WriteInteger('dx', dx);
        Request.Data.WriteInteger('dy', dy);
        Request.Data.WriteInteger('mouseData', mouseData);
        Request.Data.WriteInteger('wVk', wVk);
        Request.Data.WriteInteger('wScan', wScan);
        Response := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
        begin

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

{ - RtcScreenCapture - }

function IsWinNT: boolean;
var
  OS: TOSVersionInfo;
begin
  ZeroMemory(@OS, SizeOf(OS));
  OS.dwOSVersionInfoSize := SizeOf(OS);
  GetVersionEx(OS);
  Result := OS.dwPlatformId = VER_PLATFORM_WIN32_NT;
end;


function IsMyHandle(a: HWND): TForm;
var
  i, cnt: integer;
begin
  Result := nil;
  cnt := Screen.FormCount;
  for i := 0 to cnt - 1 do
    if Screen.Forms[i].Handle = a then
    begin
      Result := Screen.Forms[i];
      Break;
    end;
end;

function okToClick(X, Y: integer): boolean;
var
  P: TPoint;
  W: HWND;
  hit: integer;
begin
  P.X := X;
  P.Y := Y;
//  W := GetWindowParent(WindowFromPoint(P));
  W := WindowFromPoint(P);
  if IsMyHandle(W) <> nil then
  begin
    hit := SendMessage(W, WM_NCHITTEST, 0, P.X + (P.Y shl 16));
    Result := not(hit in [HTCLOSE, HTMAXBUTTON, HTMINBUTTON]);

//    case hit of
//      HTCLOSE:
//        SendMessage(W, WM_SYSCOMMAND, SC_CLOSE, MakeLong(X, Y));
//      HTMAXBUTTON:
//        SendMessage(W, WM_SYSCOMMAND, SC_MAXIMIZE, MakeLong(X, Y));
//      HTMINBUTTON:
//        SendMessage(W, WM_SYSCOMMAND, SC_MINIMIZE, MakeLong(X, Y));
//    end;
  end
  else
    Result := True;
end;

function okToUnClick(X, Y: integer): boolean;
var
  P: TPoint;
  W: HWND;
  hit: integer;
  frm: TForm;
begin
  P.X := X;
  P.Y := Y;
//  W := GetWindowParent(WindowFromPoint(P));
  W := WindowFromPoint(P);
  frm := IsMyHandle(W);
  if assigned(frm) then
  begin
    hit := SendMessage(W, WM_NCHITTEST, 0, P.X + (P.Y shl 16));
    Result := not(hit in [HTCLOSE, HTMAXBUTTON, HTMINBUTTON]);
    if not Result then
    begin
      case hit of
        HTCLOSE:
          if TBorderIcon.biSystemMenu in frm.BorderIcons then
            PostMessage(W, WM_SYSCOMMAND, SC_CLOSE, 0);
        HTMINBUTTON:
          if TBorderIcon.biMinimize in frm.BorderIcons then
            PostMessage(W, WM_SYSCOMMAND, SC_MINIMIZE, 0);
        HTMAXBUTTON:
          if TBorderIcon.biMaximize in frm.BorderIcons then
            if frm.WindowState = wsMaximized then
              PostMessage(W, WM_SYSCOMMAND, SC_RESTORE, 0)
            else
              PostMessage(W, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
      end;
    end;
  end
  else
    Result := True;
end;

function NeedSendIOToHelper: Boolean;
begin
  if IsService then
    Result := True
  else
  if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
    Result := True
  else
    Result := (LowerCase(GetInputDesktopName) <> 'default')
end;

constructor TRtcScreenCapture.Create;
var
  err: LongInt;
 { SessionID: DWORD;
  NameSuffix: String;}
begin
  inherited;
  {if IsService then
  begin
    SessionID := ActiveConsoleSessionID;
    NameSuffix := '_C';
  end
  else
  begin
    SessionID := CurrentSessionID;
    NameSuffix := '';
  end;}
{  hCursorInfoEventWriteBegin := DoCreateEvent(PWideChar(WideString('Global\RMX_CURINFO_WRITE_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
  hCursorInfoEventWriteEnd := DoCreateEvent(PWideChar(WideString('Global\RMX_CURINFO_WRITE_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
  tCursorInfoThrd := TCursorInfoThread.Create(False);
  tCursorInfoThrd.FreeOnTerminate := True;}
//  SimulateKBM := TSimulateKBM.Create;
  FShiftDown := False;
  FCtrlDown := False;
  FAltDown := False;
  FReduce16bit := 0;
  FReduce32bit := 0;
  FLowReduce16bit := 0;
  FLowReduce32bit := 0;
  FLowReduceColors := False;
  FLowReduceType := 0;
  FLowReduceColorPercent := 0;
  FBPPLimit := 4;
  FMaxTotalSize := 0;
  FScreenBlockCount := 1;
  FScreen2BlockCount := 1;
  FScreen2Delay := 0;
  {FFullScreen := True;
  FCaptureMask := SRCCOPY;
  FScreenWidth := 0;
  FScreenHeight := 0;
  FScreenLeft := 0;
  FScreenTop := 0;
  FCaptureLeft := 0;
  FCaptureTop := 0;
  FCaptureWidth := 0;
  FCaptureHeight := 0;}
  FMouseInit := True;
  FLastMouseUser := '';
  FLastMouseX := -1;
  FLastMouseY := -1;
  FMouseX := -1;
  FMouseY := -1;
  ScrEnc := TRtcScreenEncoder.Create;
  ScrEnc.OnHaveScreeenChanged := OnHaveScreeenChanged;
 SwitchToActiveDesktop;

end;

destructor TRtcScreenCapture.Destroy;
begin
  ScrEnc.Free;

  ReleaseAllKeys;

  //f assigned(ScrIn) then
 /// begin
 //   ScrIn.Free;
 //   ScrIn := nil;
 // end;

  inherited;
end;

{
procedure TRtcScreenCapture.Init;
begin
    if not assigned(ScrIn) then
    begin
      InitSize;
      ScrIn := TRtcScreenEncoder.Create;
      ScrIn.Setup(FBPPLimit, FScreenBlockCount, FMaxTotalSize);
      ScrIn.Reduce16bit := FReduce16bit;
      ScrIn.Reduce32bit := FReduce32bit;
      ScrIn.FullScreen := FFullScreen;
      ScrIn.ScreenRect := FScreenRect;
      ScrIn.CaptureMask := FCaptureMask;
      ScrIn.MultiMonitor := FMultiMon;
    end;
end;
 }

procedure TRtcScreenCapture.GrabScreen(ScrDelta : PString; ScrFull : PString = NIL);
begin
  ScrEnc.GrabScreen(ScrDelta, ScrFull);
 end;

{function TRtcScreenCapture.GetScreen : RtcString;
var
  Rec : TRtcRecord;
begin
  if ScreenData.isType = rtc_Record then
  begin
    Rec := ScreenData.asRecord;
    if assigned(Rec) then
      Result := Rec.toCode
    else
        Result := '';
  end else
    Result := '';
end; }
{
function TRtcScreenCapture.GetScreen: RtcString;
var
  rec: TRtcRecord;
begin
    if ScrIn.GetInitialScreenData.isType = rtc_Record then
    begin
      rec := ScrIn.GetInitialScreenData.asRecord;
      if assigned(rec) then
        Result := rec.toCode
      else
        Result := '';
    end
    else
      Result := '';
end;
}
procedure TRtcScreenCapture.SetMaxTotalSize(const Value: integer);
begin
  if FMaxTotalSize = Value then exit;

 {??????????????????????}
    FMaxTotalSize := Value;
end;

procedure TRtcScreenCapture.SetBPPLimit(const Value: integer);
begin
  if FBPPLimit = Value then exit;

  FBPPLimit := Value;
end;

procedure TRtcScreenCapture.SetScreen2Delay(const Value: integer);
begin
  if FScreen2Delay = Value then exit;

  FScreen2Delay := Value;
end;

procedure TRtcScreenCapture.SetClipRect(const Value: TRect);
var
  dif: integer;
  Rct : TRect;
begin
  if (Value.Width = 0) or (Value.Height = 0) then
  begin
    ScrEnc.ClipRect := Value;
    exit;
  end;

  Rct := Value;
  with Rct do
    if (Right - Left) mod 4 <> 0 then
    begin
      dif := 4 - ((Right - Left) mod 4);
      if Left - dif >= 0 then
        Left := Left - dif
      else
        Right := Right + dif;
    end;

  ScrEnc.ClipRect := Rct;
end;
{
procedure TRtcScreenCapture.SetFullScreen(const Value: boolean);
begin
  FullScreen := ;
end;
 }
procedure TRtcScreenCapture.SetReduce16bit(const Value: longword);
begin
  if Value <> FReduce16bit then
  begin
    FReduce16bit := Value;
    end;
end;

procedure TRtcScreenCapture.SetReduce32bit(const Value: longword);
begin
  if Value <> FReduce32bit then
  begin
    FReduce32bit := Value;
   end;
end;

procedure TRtcScreenCapture.SetLowReduce16bit(const Value: longword);
begin
  if Value <> FLowReduce16bit then
  begin
    FLowReduce16bit := Value;
   end;
end;

procedure TRtcScreenCapture.SetLowReduce32bit(const Value: longword);
begin
  if Value <> FLowReduce32bit then
  begin
    FLowReduce32bit := Value;
   end;
end;

procedure TRtcScreenCapture.SetLowReduceColors(const Value: boolean);
begin
  if Value <> FLowReduceColors then
  begin
    FLowReduceColors := Value;
   end;
end;

procedure TRtcScreenCapture.SetLowReduceType(const Value: integer);
begin
  if Value <> FLowReduceType then
  begin
    FLowReduceType := Value;
  end;
end;

procedure TRtcScreenCapture.SetLowReduceColorPercent(const Value: integer);
begin
  if Value <> FLowReduceColorPercent then
  begin
    FLowReduceColorPercent := Value;
  end;
end;

function TRtcScreenCapture.GetMaxTotalSize: integer;
begin
  Result := FMaxTotalSize;
end;

function TRtcScreenCapture.GetBPPLimit: integer;
begin
  Result := FBPPLimit;
end;

function TRtcScreenCapture.GetScreen2Delay: integer;
begin
  Result := FScreen2Delay;
end;

function TRtcScreenCapture.GetReduce16bit: longword;
begin
  Result := FReduce16bit;
end;

function TRtcScreenCapture.GetReduce32bit: longword;
begin
  Result := FReduce32bit;
end;

function TRtcScreenCapture.GetLowReduce16bit: longword;
begin
  Result := FLowReduce16bit;
end;

function TRtcScreenCapture.GetLowReduce32bit: longword;
begin
  Result := FLowReduce32bit;
end;

function TRtcScreenCapture.GetLowReduceColors: boolean;
begin
  Result := FLowReduceColors;
end;

function TRtcScreenCapture.GetLowReduceType: integer;
begin
  Result := FLowReduceType;
end;

function TRtcScreenCapture.GetLowReduceColorPercent: integer;
begin
  Result := FLowReduceColorPercent;
end;

procedure TRtcScreenCapture.Clear;
begin
  FMouseInit := True;
  ReleaseAllKeys;
end;

{IFDEF MULTIMON}
{ENDIF}
procedure TRtcScreenCapture.GrabMouse;
var
  ci: TCursorInfo;
  icinfo: TIconInfo;
  pt: TPoint;
  i: integer;
begin
  ci.cbSize := SizeOf(ci);
  if Get_CursorInfo(ci) then
  begin
    if ci.flags = CURSOR_SHOWING then
    begin
      for i := Low(TCursor) to High(TCursor) do
      begin
        if Screen.Cursors[i] = ci.hCursor then
        begin
          FServerCursor := i;
          Break;
        end;
      end;

      FMouseVisible := True;
      if FMouseInit or (ci.ptScreenPos.X <> FMouseX) or
        (ci.ptScreenPos.Y <> FMouseY) then
      begin
        FMouseMoved := True;
        FMouseX := ci.ptScreenPos.X;
        FMouseY := ci.ptScreenPos.Y;

        if (FLastMouseUser <> '') and (FMouseX = FLastMouseX) and
          (FMouseY = FLastMouseY) then
          FMouseUser := FLastMouseUser
        else
          FMouseUser := '';
      end;
      if FMouseInit or (ci.hCursor <> FMouseHandle) then
      begin
        FMouseChangedShape := True;
        FMouseHandle := ci.hCursor;
        if assigned(FMouseIcon) then
        begin
          FMouseIcon.Free;
          FMouseIcon := nil;
        end;
        if assigned(FMouseIconMask) then
        begin
          FMouseIconMask.Free;
          FMouseIconMask := nil;
        end;
        FMouseShape := 1;
        for i := crSizeAll to crDefault do
          if ci.hCursor = Screen.Cursors[i] then
          begin
            FMouseShape := i;
            Break;
          end;
        if FMouseShape = 1 then
        begin
          // send cursor image only for non-standard shapes
          if GetIconInfo(ci.hCursor, icinfo) then
          begin
            FMouseHotX := icinfo.xHotspot;
            FMouseHotY := icinfo.yHotspot;

            if icinfo.hbmMask <> INVALID_HANDLE_VALUE then
            begin
              FMouseIconMask := TBitmap.Create;
              FMouseIconMask.Handle := icinfo.hbmMask;
              FMouseIconMask.PixelFormat := pf4bit;
            end;

            if icinfo.hbmColor <> INVALID_HANDLE_VALUE then
            begin
              FMouseIcon := TBitmap.Create;
              FMouseIcon.Handle := icinfo.hbmColor;
              case FBPPLimit of
                0:
                  if FMouseIcon.PixelFormat > pf4bit then
                    FMouseIcon.PixelFormat := pf4bit;
                1:
                  if FMouseIcon.PixelFormat > pf8bit then
                    FMouseIcon.PixelFormat := pf8bit;
                2:
                  if FMouseIcon.PixelFormat > pf16bit then
                    FMouseIcon.PixelFormat := pf16bit;
              end;
            end;
          end;
        end;
      end;
      FMouseInit := False;
    end
    else
      FMouseVisible := False;
  end
  else if GetCursorPos(pt) then
  begin
    FMouseVisible := True;
    if FMouseInit or (pt.X <> FMouseX) or (pt.Y <> FMouseY) then
    begin
      FMouseMoved := True;
      FMouseX := pt.X;
      FMouseY := pt.Y;
      if (FLastMouseUser <> '') and (FMouseX = FLastMouseX) and
        (FMouseY = FLastMouseY) then
        FMouseUser := FLastMouseUser
      else
        FMouseUser := '';
    end;
    FMouseInit := False;
  end
  else
    FMouseVisible := False;
end;

function TRtcScreenCapture.GetMouseDelta: RtcString;
var
  rec: TRtcRecord;
begin
  if FMouseMoved or FMouseChangedShape or (FMouseLastVisible <> FMouseVisible)
  then
  begin
    rec := TRtcRecord.Create;
    try
      if FMouseLastVisible <> FMouseVisible then
        rec.asBoolean['V'] := FMouseVisible;
      if FMouseMoved then
      begin
        rec.asInteger['X'] := FMouseX - ScrEnc.ClipRect.Left;
        rec.asInteger['Y'] := FMouseY - ScrEnc.ClipRect.Top;
        if FMouseUser <> '' then
          rec.asText['U'] := FMouseUser;
      end;
      if FMouseChangedShape then
      begin
        if FMouseShape <= 0 then
          rec.asInteger['C'] := -FMouseShape // 0 .. -22  ->>  0 .. 22
        else
        begin
          rec.asInteger['HX'] := FMouseHotX;
          rec.asInteger['HY'] := FMouseHotY;
          if FMouseIcon <> nil then
            FMouseIcon.SaveToStream(rec.newByteStream('I'));
          if FMouseIconMask <> nil then
            FMouseIconMask.SaveToStream(rec.newByteStream('M'));
        end;
      end;
      rec.asInteger['cr'] := FServerCursor;
      Result := rec.toCode;
    finally
      rec.Free;
    end;
    FMouseMoved := False;
    FMouseChangedShape := False;
    FMouseLastVisible := FMouseVisible;
  end;
end;

function TRtcScreenCapture.GetMouse: RtcString;
begin
  FMouseChangedShape := True;
  FMouseMoved := True;
  FMouseLastVisible := not FMouseVisible;
  Result := GetMouseDelta;
end;

procedure TRtcScreenCapture.Post_MouseDown(Button: TMouseButton);
var
  inputs: array[0..0] of TInput;
  p: TPoint;
  dwFlags: DWORD;
begin
  SwitchToActiveDesktop;

  case Button of
    mbLeft:
      dwFlags := MOUSEEVENTF_LEFTDOWN;
    mbRight:
      dwFlags := MOUSEEVENTF_RIGHTDOWN;
    mbMiddle:
      dwFlags := MOUSEEVENTF_MIDDLEDOWN;
  end;

  if not NeedSendIOToHelper then
  begin
//        mouse_event(dwFlags, 0, 0, 0, 0);

      ZeroMemory(@inputs, SizeOf(TInput));
      inputs[0].Itype := INPUT_MOUSE;
      inputs[0].mi.dwFlags := dwFlags;
      inputs[0].mi.dx := FLastMouseX;
      inputs[0].mi.dy := FLastMouseY;
      inputs[0].mi.mouseData := 0;
      inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
//      SendInput(1, inputs[0], SizeOf(inputs));
      TLockWindow.SendInput(1, inputs[0], SizeOf(inputs));
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, dwFlags, FLastMouseX, FLastMouseY, 0, 0, 0, '');

//    GetCursorPos(p);
//    case Button of
//      mbLeft: PostMessage(GetChildWindowFromPoint(p.X, p.Y), WM_LBUTTONDOWN, 0, MAKELPARAM(p.X, p.Y));
//      mbRight: PostMessage(GetChildWindowFromPoint(p.X, p.Y), WM_RBUTTONDOWN, 0, MAKELPARAM(p.X, p.Y));
//      mbMiddle: PostMessage(GetChildWindowFromPoint(p.X, p.Y), WM_MBUTTONDOWN, 0, MAKELPARAM(p.X, p.Y));
//    end;
//  end;
end;

procedure TRtcScreenCapture.Post_MouseUp(Button: TMouseButton);
var
  inputs: array[0..0] of TInput;
  p: TPoint;
  dwFlags: DWORD;
begin
  SwitchToActiveDesktop;

  case Button of
    mbLeft:
      dwFlags := MOUSEEVENTF_LEFTUP;
    mbRight:
      dwFlags := MOUSEEVENTF_RIGHTUP;
    mbMiddle:
      dwFlags := MOUSEEVENTF_MIDDLEUP;
  end;

  if not NeedSendIOToHelper then
  begin//  mouse_event(dwFlags, 0, 0, 0, 0);7

    ZeroMemory(@inputs, SizeOf(TInput));
    inputs[0].Itype := INPUT_MOUSE;
    inputs[0].mi.dwFlags := dwFlags;
    inputs[0].mi.dx := 0;
    inputs[0].mi.dy := 0;
    inputs[0].mi.mouseData := 0;
    inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
//      SendInput(1, inputs[0], SizeOf(inputs));
      TLockWindow.SendInput(1, inputs[0], SizeOf(inputs));
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, dwFlags, 0, 0, 0, 0, 0, '');

//    GetCursorPos(p);
//    if Button in [mbLeft, mbRight] then
//      if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
//        case Button of
//          mbLeft:
//            Button := mbRight;
//          mbRight:
//            Button := mbLeft;
//        end;
//    case Button of
//      mbLeft: PostMessage(WindowFromPoint(p), WM_LBUTTONUP, 0, MAKELPARAM(p.X, p.Y));
//      mbRight: PostMessage(WindowFromPoint(p), WM_RBUTTONUP, 0, MAKELPARAM(p.X, p.Y));
//      mbMiddle: PostMessage(WindowFromPoint(p), WM_MBUTTONUP, 0, MAKELPARAM(p.X, p.Y));
//    end;
//  end;
end;

procedure TRtcScreenCapture.Post_MouseWheel(Wheel: integer);
var
  inputs: array[0..0] of TInput;
begin
  SwitchToActiveDesktop;

  if not NeedSendIOToHelper then
  begin
    ZeroMemory(@inputs, SizeOf(TInput));
    inputs[0].Itype := INPUT_MOUSE;
    inputs[0].mi.dwFlags := MOUSEEVENTF_WHEEL;
    inputs[0].mi.dx := 0;
    inputs[0].mi.dy := 0;
    inputs[0].mi.mouseData := DWORD(Wheel);
    inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
//      SendInput(1, inputs[0], SizeOf(inputs));
      TLockWindow.SendInput(1, inputs[0], SizeOf(inputs));
//    mouse_event(MOUSEEVENTF_WHEEL, 0, 0, DWORD(Wheel), 0);
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, MOUSEEVENTF_WHEEL, 0, 0, Wheel, 0, 0, '');
end;

procedure TRtcScreenCapture.Post_MouseMove(X, Y: integer);
var
  inputs: array[0..0] of TInput;
begin
  SwitchToActiveDesktop;

  if not NeedSendIOToHelper then
  begin
    if Screen.Width > 0 then
    begin
      X := round(X / (Screen.Width - 1) * 65535);
      Y := round(Y / (Screen.Height - 1) * 65535);


      ZeroMemory(@inputs, SizeOf(TInput));
      inputs[0].Itype := INPUT_MOUSE;
      inputs[0].mi.dwFlags := MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE;
      inputs[0].mi.dx := X;
      inputs[0].mi.dy := Y;
      inputs[0].mi.mouseData := 0;
      inputs[0].mi.dwExtraInfo := RMX_MAGIC_NUMBER;
//      SendInput(1, inputs[0], SizeOf(inputs));
      TLockWindow.SendInput(1, inputs[0], SizeOf(inputs));

      //mouse_event(MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE, X, Y, 0, 0);
    end
    else
    begin
      SetCursorPos(X, Y);

//    if GetKeyState(VK_LBUTTON) < 0 then
//      State := State + MK_LBUTTON;
//    if GetKeyState(VK_MBUTTON) < 0 then
//      State := State + MK_MBUTTON;
//    if GetKeyState(VK_RBUTTON) < 0 then
//      State := State + MK_RBUTTON;
//  PostMouseMessage(WM_MOUSEMOVE, X, Y);
    end
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_MOUSE, MOUSEEVENTF_MOVE or MOUSEEVENTF_ABSOLUTE, X, Y, 0, 0, 0, '');
end;


{procedure PostMouseMessage(Msg:Cardinal; MouseX, MouseY: integer);
  var
    hdl,chdl:HWND;
    wpt,pt:TPoint;
    r:TRect;
  begin
  pt.X:=MouseX;
  pt.Y:=MouseY;
  wpt:=pt;
  if RtcMouseWindowHdl=0 then
    hdl:=WindowFromPoint(pt)
  else
    begin
    hdl:=RtcMouseWindowHdl;
    if IsWindow(hdl) then
      begin
      GetWindowRect(hdl,r);
      repeat
        pt.X:=wpt.X-r.Left;
        pt.Y:=wpt.Y-r.Top;
        chdl:=ChildWindowFromPointEx(hdl,pt,1+4);
        if not IsWindow(chdl) then
          Break
        else if chdl=hdl then
          Break
        else
          begin
          GetWindowRect(chdl,r);
          if (wpt.x>=r.left) and (wpt.x<=r.right) and
             (wpt.y>=r.top) and (wpt.y<=r.bottom) then
            hdl:=chdl
          else
            Break;
          end;
        until False;
      end;
    end;
  if IsWindow(hdl) then
    begin
    GetWindowRect(hdl,r);
    pt.x:=wpt.X-r.left;
    pt.y:=wpt.Y-r.Top;
    PostMessageA(hdl,msg,0,MakeLong(pt.X,pt.Y));
    end;
  end;}

procedure TRtcScreenCapture.MouseDown(const user: string; X, Y: integer;
  Button: TMouseButton);
var
//  pt: TPoint;
  h: HWND;
begin
  FLastMouseUser := user;
  FLastMouseX := X + ScrEnc.ClipRect.Left;
  FLastMouseY := Y + ScrEnc.ClipRect.Top;

  if Button in [mbLeft, mbRight] then
    if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
      case Button of
        mbLeft:
          Button := mbRight;
        mbRight:
          Button := mbLeft;
      end;

  if RtcMouseControlMode=eventMouseControl then
  begin
    Post_MouseMove(FLastMouseX, FLastMouseY);
    if Button <> mbLeft then
      Post_MouseDown(Button)
    else
    if okToClick(FLastMouseX, FLastMouseY) then
      Post_MouseDown(Button);
  end
  else
  begin
//    SimulateKBM.MoveMouse(Point(FLastMouseX, FLastMouseY));
//    SimulateKBM.MouseDownXY(FLastMouseX, FLastMouseY);
//    //h := GetChildWindowFromPoint(FLastMouseX, FLastMouseY);
//    h := WindowFromPoint(Point(FLastMouseX, FLastMouseY));
////    Post_MessageMouseMove(FLastMouseX, FLastMouseY);
////    if GetActiveWindow <> h then
////      SetActiveWindow(h);
////    PostMessage(WindowFromPoint(pt), WM_ACTIVATE, WA_CLICKACTIVE, GetActiveWindow);
////    case Button of
////      mbLeft: PostMouseMessage(WM_LBUTTONDOWN,FLastMouseX,FLastMouseY);
////      mbRight: PostMouseMessage(WM_RBUTTONDOWN,FLastMouseX,FLastMouseY);
////      mbMiddle: PostMouseMessage(WM_MBUTTONDOWN,FLastMouseX,FLastMouseY);
////    end;
//
//    if Button <> mbLeft then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONDOWN, MK_LBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONDOWN, MK_RBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONDOWN, MK_MBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//      end
//    else if okToClick(FLastMouseX, FLastMouseY) then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONDOWN, MK_LBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONDOWN, MK_RBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONDOWN, MK_MBUTTON, MAKELONG(FLastMouseX, FLastMouseY));
//      end
  end;
end;

procedure TRtcScreenCapture.MouseUp(const user: string; X, Y: integer;
  Button: TMouseButton);
var
  pt: TPoint;
  h: HWND;
begin
  FLastMouseUser := user;
  FLastMouseX := X + ScrEnc.ClipRect.Left;
  FLastMouseY := Y + ScrEnc.ClipRect.Top;

  if Button in [mbLeft, mbRight] then
    if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
      case Button of
        mbLeft:
          Button := mbRight;
        mbRight:
          Button := mbLeft;
      end;

  if RtcMouseControlMode=eventMouseControl then
    begin
    Post_MouseMove(FLastMouseX, FLastMouseY);
    if Button <> mbLeft then
      Post_MouseUp(Button)
    else if okToUnClick(FLastMouseX, FLastMouseY) then
      Post_MouseUp(Button);
    end
  else
  begin
//    SimulateKBM.MoveMouse(Point(FLastMouseX, FLastMouseY));
//    SimulateKBM.MouseUpXY(FLastMouseX, FLastMouseY);
////    h := GetChildWindowFromPoint(FLastMouseX, FLastMouseY);
//    h := WindowFromPoint(Point(FLastMouseX, FLastMouseY));
////    Post_MessageMouseMove(FLastMouseX, FLastMouseY);
////    case Button of
////      mbLeft: PostMouseMessage(WM_LBUTTONUP,FLastMouseX,FLastMouseY);
////      mbRight: PostMouseMessage(WM_RBUTTONUP,FLastMouseX,FLastMouseY);
////      mbMiddle: PostMouseMessage(WM_MBUTTONUP,FLastMouseX,FLastMouseY);
////    end;
//    if Button <> mbLeft then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//      end
//    else if okToUnClick(FLastMouseX, FLastMouseY) then
//      case Button of
//        mbLeft: PostMessage(h, WM_LBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbRight: PostMessage(h, WM_RBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//        mbMiddle: PostMessage(h, WM_MBUTTONUP, 0, MAKELONG(FLastMouseX, FLastMouseY));
//      end
  end;
end;

procedure TRtcScreenCapture.MouseMove(const user: String; X, Y: integer);
begin
  if RtcMouseControlMode=eventMouseControl then
  begin
    FLastMouseUser := user;
    FLastMouseX := X + ScrEnc.ClipRect.Left;
    FLastMouseY := Y + ScrEnc.ClipRect.Top;

    Post_MouseMove(FLastMouseX, FLastMouseY);
  end
  else
  begin
    FLastMouseUser := user;
    FLastMouseX := X + ScrEnc.ClipRect.Left;
    FLastMouseY := Y + ScrEnc.ClipRect.Top;

//    SimulateKBM.MoveMouse(Point(FLastMouseX, FLastMouseY));

    //Post_MessageMouseMove(FLastMouseX, FLastMouseY);
  end;
end;

procedure TRtcScreenCapture.MouseWheel(Wheel: integer);
begin
  if RtcMouseControlMode=eventMouseControl then
    Post_MouseWheel(Wheel);
end;

procedure TRtcScreenCapture.keybdevent(key: word; Down: boolean = True; Extended: boolean=False);
var
  vk: integer;
  inputs: array[0..0] of TInput;
  dwFlags: DWORD;
begin
  vk := MapVirtualKey(key, 0);
  dwFlags := 0;
  if not Down then dwFlags := dwFlags or KEYEVENTF_KEYUP;
  if Extended then dwFlags := dwFlags or KEYEVENTF_EXTENDEDKEY;
//  keybd_event(key, vk, dwFlags, 0);

  if not NeedSendIOToHelper then
  begin
    ZeroMemory(@inputs, SizeOf(TInput));
    inputs[0].Itype := INPUT_KEYBOARD;
    inputs[0].ki.dwFlags := dwFlags;
    inputs[0].ki.wVk := key;
    inputs[0].ki.wScan := vk;
    inputs[0].ki.dwExtraInfo := RMX_MAGIC_NUMBER;
//      SendInput(1, inputs[0], SizeOf(inputs));
      TLockWindow.SendInput(1, inputs[0], SizeOf(inputs));
  end
  else
    SendIOToHelperByIPC(QT_SENDINPUT, INPUT_KEYBOARD, dwFlags, 0, 0, 0, key, vk, '');
end;

procedure TRtcScreenCapture.KeyDown(key: word; Shift: TShiftState);
var
  inputs: array[0..0] of TInput;
begin
  case key of
    VK_SHIFT:
      if FShiftDown then
        Exit
      else
        FShiftDown := True;
    VK_CONTROL:
      if FCtrlDown then
        Exit
      else
        FCtrlDown := True;
    VK_MENU:
      if FAltDown then
        Exit
      else
        FAltDown := True;
  end;

  keybdevent(key, True, (Key >= $21) and (Key <= $2E));
end;

procedure TRtcScreenCapture.KeyUp(key: word; Shift: TShiftState);
begin
  case key of
    VK_SHIFT:
      if not FShiftDown then
        Exit
      else
        FShiftDown := False;
    VK_CONTROL:
      if not FCtrlDown then
        Exit
      else
        FCtrlDown := False;
    VK_MENU:
      if not FAltDown then
        Exit
      else
        FAltDown := False;
  end;

  keybdevent(key, False, (key >= $21) and (key <= $2E));
end;

procedure TRtcScreenCapture.SetKeys(capslock, lWithShift, lWithCtrl,
  lWithAlt: boolean);
begin
  if capslock then
  begin
    // turn CAPS LOCK off
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, lWithShift);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, lWithCtrl);

  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, lWithAlt);
end;

procedure TRtcScreenCapture.ResetKeys(capslock, lWithShift, lWithCtrl,
  lWithAlt: boolean);
begin
  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, FAltDown);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, FCtrlDown);

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, FShiftDown);

  if capslock then
  begin
    // turn CAPS LOCK on
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;
end;

//procedure TRtcScreenCapture.KeyPress(const AText: RtcString; AKey: word);
//var
//  a: integer;
//  lScanCode: Smallint;
//  lWithAlt, lWithCtrl, lWithShift: boolean;
//  capslock: boolean;
//begin
//  for a := 1 to length(AText) do
//  begin
//{$IFDEF RTC_BYTESTRING}
//    lScanCode := VkKeyScanA(AText[a]);
//{$ELSE}
//    lScanCode := VkKeyScanW(AText[a]);
//{$ENDIF}
//    if lScanCode = -1 then
//    begin
//      if not(AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
//      then
//      begin
//        keybdevent(AKey);
//        keybdevent(AKey, False);
//      end;
//    end
//    else
//    begin
//      lWithShift := lScanCode and $100 <> 0;
//      lWithCtrl := lScanCode and $200 <> 0;
//      lWithAlt := lScanCode and $400 <> 0;
//
//      lScanCode := lScanCode and $F8FF;
//      // remove Shift, Ctrl and Alt from the scan code
//
//      capslock := GetKeyState(VK_CAPITAL) > 0;
//
//      SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
//
//      keybdevent(lScanCode);
//      keybdevent(lScanCode, False);
//
//      ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
//    end;
//  end;
//end;

procedure TRtcScreenCapture.KeyPressW(const AText: WideString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
    lScanCode := VkKeyScanW(AText[a]);

    if lScanCode = -1 then
    begin
      if not (AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;

procedure TRtcScreenCapture.LWinKey(key: word);
begin
  SetKeys(False, False, False, False);
  keybdevent(VK_LWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_LWIN, False);
  ResetKeys(False, False, False, False);
end;

procedure TRtcScreenCapture.RWinKey(key: word);
begin
  SetKeys(False, False, False, False);
  keybdevent(VK_RWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_RWIN, False);
  ResetKeys(False, False, False, False);
end;

procedure TRtcScreenCapture.SpecialKey(const AKey: RtcString);
var
  capslock: Boolean;
  err: Integer;
  res: Boolean;
  file_name1, file_name2, s: String;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;

  if AKey = 'CAD' then
  begin
    XLog('Simulate CAD');
//    ExecuteCtrlAltDel;
    SendIOToHelperByIPC(QT_SENDCAD, 0, 0, 0, 0, 0, 0, 0, '');
    // Ctrl+Alt+Del
{    if (Win32MajorVersion >= 6) then //vista\server 2k8
    begin
      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
        ExecuteCtrlAltDel
      else
      begin
        file_name1 := GetTempFile + '.exe'; //Доделать через SAS
        SaveResourceToFile('RUNASSYS', file_name1);

        file_name2 := GetTempFile + '.bat';
        s := file_name1 + ' "' + AppFileName + '" /CAD' + #13#10;
        s := s + 'DEL ' + file_name1 + #13#10;
        s := s + 'DEL ' + file_name2 + #13#10;
        s := s + 'PAUSE';
        Write_File(file_name2, s);
        ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);
      end;

//      EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//      SetLastError(EleavateSupport.RunElevated(file_name2, '', Application.Handle, Application.ProcessMessages));
//      err := GetLastError;
//      if err <> ERROR_SUCCESS then
//        XLog(SysErrorMessage(err));
    end
    else
      WinExec('taskmgr.exe', SW_SHOW);}

//    if UpperCase(Get_UserName) = 'SYSTEM' then
//    begin
//      XLog('Executing CtrlAltDel as SYSTEM user ...');
//      SetKeys(capslock, False, False, False);
//      if not Post_CtrlAltDel then
//        begin
//        XLog('CtrlAltDel execution failed as SYSTEM user');
//        if rtcGetProcessID(AppFileName) > 0 then
//          begin
//          XLog('Sending CtrlAltDel request to Host Service ...');
//          Write_File(ChangeFileExt(AppFileName, '.cad'), '');
//          end;
//        end
//      else
//        XLog('CtrlAltDel execution successful');
//      ResetKeys(capslock, False, False, False);
//    end
//    else
//    begin
//      if rtcGetProcessID(AppFileName) > 0 then
//        begin
//        XLog('Sending CtrlAltDel request to Host Service ...');
//        Write_File(ChangeFileExt(AppFileName, '.cad'), '');
//        end
//      else
//        begin
//        XLog('Emulating CtrlAltDel as "'+Get_UserName+'" user ...');
//        SetKeys(capslock, False, True, True);
//        keybdevent(VK_ESCAPE);
//        keybdevent(VK_ESCAPE, False);
//        ResetKeys(capslock, False, True, True);
//        end;
//    end;
  end
  else if AKey = 'COPY' then
  begin
    // Ctrl+C
    if IsService then
      SendIOToHelperByIPC(QT_SENDCOPY, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, True, False);
      keybdevent(Ord('C'));
      keybdevent(Ord('C'), False);
      ResetKeys(capslock, False, True, False);
    end;
  end
  else if AKey = 'AT' then
  begin
    // Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, False, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, False, False, True);
    end;
  end
  else if AKey = 'SAT' then
  begin
    // Shift+Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDSAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, True, False, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, True, False, True);
    end;
  end
  else if AKey = 'CAT' then
  begin
    // Ctrl+Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDCAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, True, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, False, True, True);
    end;
  end
  else if AKey = 'SCAT' then
  begin
    // Shift+Ctrl+Alt+Tab
    if IsService then
      SendIOToHelperByIPC(QT_SENDSCAT, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, True, True, True);
      keybdevent(VK_TAB);
      keybdevent(VK_TAB, False);
      ResetKeys(capslock, True, True, True);
    end;
  end
  else if AKey = 'WIN' then
  begin
    // Windows
    if IsService then
      SendIOToHelperByIPC(QT_SENDWIN, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, False, False);
      keybdevent(VK_LWIN);
      keybdevent(VK_LWIN, False);
      ResetKeys(capslock, False, False, False);
    end;
  end
  else if AKey = 'RWIN' then
  begin
    // Windows
    if IsService then
      SendIOToHelperByIPC(QT_SENDRWIN, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
      SetKeys(capslock, False, False, False);
      keybdevent(VK_RWIN);
      keybdevent(VK_RWIN, False);
      ResetKeys(capslock, False, False, False);
    end;
  end
  else if AKey = 'HDESK' then
  begin
    // Hide Wallpaper
    if IsService then
      SendIOToHelperByIPC(QT_SENDHDESK, 0, 0, 0, 0, 0, 0, 0, '')
    else
      Hide_Wallpaper;
  end
  else if AKey = 'SDESK' then
  begin
    // Show Wallpaper
    if IsService then
      SendIOToHelperByIPC(QT_SENDSDESK, 0, 0, 0, 0, 0, 0, 0, '')
    else
      Show_Wallpaper;
  end;
  {else if AKey = 'BKM' then
  begin
    // Block Keyboard and Mouse
    if IsService then
      SendIOToHelperByIPC(QT_SENDBKM, 0, 0, 0, 0, 0, 0, 0, '')
    else
      SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);


//    file_name1 := GetTempFile + '.exe';
//    SaveResourceToFile('RUNASSYS', file_name1);
//
//    file_name2 := GetTempFile + '.bat';
//    s := file_name1 + ' "' + AppFileName + '" -DCAD' + #13#10;
//    s := s + 'DEL ' + file_name1 + #13#10;
//    s := s + 'DEL ' + file_name2 + #13#10;
//    s := s + 'PAUSE';
//    Write_File(file_name2, s);
//    ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);

    //Block_UserInput_Hook(True);

////    Block_UserInput(True);
//    EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '-BKM', Application.Handle, Application.ProcessMessages));
//    err := GetLastError;
//    if err <> ERROR_SUCCESS then
//      XLog(SysErrorMessage(err));
  end
  else if AKey = 'UBKM' then
  begin
    // UnBlock Keyboard and Mouse
    if IsService then
      SendIOToHelperByIPC(QT_SENDUBKM, 0, 0, 0, 0, 0, 0, 0, '')
    else
      SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);

//    file_name1 := GetTempFile + '.exe';
//    SaveResourceToFile('RUNASSYS', file_name1);
//
//    file_name2 := GetTempFile + '.bat';
//    s := file_name1 + ' "' + AppFileName + '" -ECAD' + #13#10;
//    s := s + 'DEL ' + file_name1 + #13#10;
//    s := s + 'DEL ' + file_name2 + #13#10;
//    s := s + 'PAUSE';
//    Write_File(file_name2, s);
//    ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);

    //Block_UserInput_Hook(False);
////    Block_UserInput(False);
//    EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '-UBKM', Application.Handle, Application.ProcessMessages));
//    err := GetLastError;
//    if err <> ERROR_SUCCESS then
//      XLog(SysErrorMessage(err));
  end
  else if AKey = 'OFFMON' then
  begin
    // Power Off Monitor
    if IsService then
      SendIOToHelperByIPC(QT_SENDOFFMON, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
//      TLockWindow.Show();
    end;


//    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(2));
//    SendMessage(MainFormHandle, WM_ZORDER_MESSAGE, 0, 0);
//    Hide_Cursor;

//    ThreadHandle2 := CreateThread(nil, 0, @BlackWindow, nil, 0, &dwTId);
//    if ThreadHandle2 <> 0 then
//      CloseHandle(ThreadHandle2);
//    m_Black_window_active := True;

//    SetProcessShutdownParameters($100, 0);
//    res := SystemParametersInfo(SPI_GETPOWEROFFTIMEOUT, 0, @m_OldPowerOffTimeout, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, 3600, nil, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFACTIVE, 1, nil, 0);
//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(2));

//    Block_UserInput_Hook(True);
    //PowerOffMonitor;
  end
  else if AKey = 'ONMON' then
  begin
    // Power On Monitor
    if IsService then
      SendIOToHelperByIPC(QT_SENDONMON, 0, 0, 0, 0, 0, 0, 0, '')
    else
    begin
//      TLockWindow.Close();
    end;


//    Show_Cursor;
//    SendMessage(MainFormHandle, WM_ZORDER_MESSAGE, 1, 0);
//    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));

//    if m_OldPowerOffTimeout <> 0 then
//      res := SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, m_OldPowerOffTimeout, nil, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFACTIVE, 0, nil, 0);
//    m_OldPowerOffTimeout := 0;
//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));

//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));
//		//win8 require mouse move
//		mouse_event(MOUSEEVENTF_MOVE, 0, 1, 0, 0);
//		Sleep(40);
//		mouse_event(MOUSEEVENTF_MOVE, 0, DWORD(-1), 0, 0);
//
//    PostMessage(FindWindow(('blackscreen'), 0), WM_CLOSE, 0, 0);
//    m_Black_window_active := False;

//    Block_UserInput_Hook(False);
    //PowerOnMonitor;
  end
  else if AKey = 'OFFSYS' then
  begin
    // Power Off System
    PowerOffSystem;
  end
  else if AKey = 'LCKSYS' then
  begin
    // Lock System
    if IsService then
      SendIOToHelperByIPC(QT_SENDLCKSYS, 0, 0, 0, 0, 0, 0, 0, '')
    else
      LockSystem;
  end
  else if AKey = 'LOGOFF' then
  begin
    // Logoff
    if IsService then
      SendIOToHelperByIPC(QT_SENDLOGOFF, 0, 0, 0, 0, 0, 0, 0, '')
    else
      LogoffSystem;
  end
  else if AKey = 'RSTRT' then
  begin
    // Restart
    RestartSystem;
  end;}
end;

//function BlockInputProc_Keyboard(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
//var
//  ei : Integer;
//  KeyboardStruct: PKBDLLHOOKSTRUCT;
//begin
//  if CODE <> HC_ACTION then
//  begin
//    Result:= CallNextHookEx(BlockInputHook_Keyboard, CODE, wParam, LParam);
//    Exit;
//  end;
//
//  KeyboardStruct := Pointer(lParam);
//  if KeyboardStruct^.dwExtraInfo <> RMX_MAGIC_NUMBER then
//    Result := 1
//  else
//  Result := CallNextHookEx(BlockInputHook_Keyboard, CODE, wParam, LParam);
//end;
//
//function BlockInputProc_Mouse(CODE: DWORD; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
//var
//  ei : Integer;
//  MouseStruct: PMSLLHOOKSTRUCT;
//begin
//  if CODE <> HC_ACTION then
//  begin
//    Result:= CallNextHookEx(BlockInputHook_Mouse, CODE, wParam, LParam);
//    Exit;
//  end;
//
//  MouseStruct := Pointer(lParam);
//  if MouseStruct^.dwExtraInfo <> RMX_MAGIC_NUMBER then
//    Result := 1
//  else
//  Result := CallNextHookEx(BlockInputHook_Mouse, CODE, wParam, LParam);
//end;

//function TRtcScreenCapture.Block_UserInput_Hook(fBlockInput: Boolean): Boolean;
//var
//  err: LongInt;
//begin
//  if fBlockInput then
//  begin
//    BlockInputHook_Keyboard := SetWindowsHookEx(WH_KEYBOARD_LL, @BlockInputProc_Keyboard, hInstance, 0);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Set_Keyboard. Error: %s', [SysErrorMessage(err)]));
//    Result := (BlockInputHook_Keyboard <> 0);
//
//    BlockInputHook_Mouse := SetWindowsHookEx(WH_MOUSE_LL, @BlockInputProc_Mouse, hInstance, 0);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Set_Mouse. Error: %s', [SysErrorMessage(err)]));
//    Result := (BlockInputHook_Mouse <> 0);
//
//    SASLibEx_DisableCAD(DWORD(-1));
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Disable CAD. Error: %s', [SysErrorMessage(err)]));
//  end
//  else
//  begin
//    Result := UnhookWindowsHookEx(BlockInputHook_Keyboard);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Unset_Keyboard. Error: %s', [SysErrorMessage(err)]));
//
//    Result := UnhookWindowsHookEx(BlockInputHook_Mouse);
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Block_UserInput_Unset_Mouse. Error: %s', [SysErrorMessage(err)]));
//
//    SASLibEx_EnableCAD(DWORD(-1));
//    err := GetLastError;
//    if err <> 0 then
//      xLog(Format('Enable CAD. Error: %s', [SysErrorMessage(err)]));
//  end;
//end;

procedure TRtcScreenCapture.SetAdapter(AdapterName: String);
begin
  ScrEnc.SetAdapter(AdapterName);
end;

procedure TRtcScreenCapture.ReleaseAllKeys;
begin
  if FShiftDown then
    KeyUp(VK_SHIFT, []);
  if FAltDown then
    KeyUp(VK_MENU, []);
  if FCtrlDown then
    KeyUp(VK_CONTROL, []);
end;

procedure TRtcScreenCapture.SetMultiMon(const Value: boolean);
begin
{$IFDEF MULTIMON}
  if FMultiMon <> Value then
  begin
    FMultiMon := Value;
  end;
{$ENDIF}
end;

initialization

if not IsWinNT then
  RTC_CAPTUREBLT := 0;

end.
