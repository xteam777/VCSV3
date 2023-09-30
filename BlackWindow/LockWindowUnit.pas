unit LockWindowUnit;

  {$WARN SYMBOL_PLATFORM OFF}
  {$DEFINE BLOCK_INPUT_ENABLED}
  {$DEFINE ERROR_TO_MSGBOX}
  {$DEFINE ERROR_TO_DEBUG_OUTPUT}



interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics;

const

  WM_SEND_INPUT   = WM_USER + 1;
  WM_CLOSE_WND    = WM_USER + 2;

  TIMER_ID_DATE = 1;

type

  // record for Monitor Infos
  TMonitorInfoRect = record
    BoundsRect: TRect;
    PixelsPerInch: Integer;
  end;

  // SendInput DATA
  PSendInputData = ^TSendInputData;
  TSendInputData = record
    cInputs: UINT;
    pInputs: PInput;// TInput
    cbSize: Integer;
  end;

  // extended record for TMessage
  TMessageLW = record
    message: TMessage;
    Window: HWND;
    constructor Create(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM);
  end;

  // record for SendInput
  TMessageInput = record
    Msg: Cardinal;
    WParam: WPARAM;
    pInputData: PSendInputData;
    Result: LRESULT;
  end;


  TMonitorInfoRectList = array of TMonitorInfoRect;

  TLockWindow = class
  private
    FWindow: HWND;
    FCanvas: TCanvas;
    FDateLable: string;
    FTimeLabel: string;
    FUserMessage: string;
    FColor: TColor;
    FAlphaPecent: Byte;

    FUserMessageFont,
    FDateFont,
    FTimeFont: TFont;
    FSkipOrder: Boolean;
    FDestroing: Boolean;
    procedure CreateWindow();
    procedure DestroyWindow();
    procedure DisableWindowForRecord(Disable: Boolean);
    procedure ApplyLayeredWindow(Percent: Byte);
    procedure DisableInput(Disable: Boolean);


    /// class var, alias global
    class var
      MonitorsRect: TMonitorInfoRectList;
      Instance: TLockWindow;
      LockCookie: Integer;


    class procedure UpdateMonitors();
    class function EnumMonitorsProc(hm: HMONITOR; dc: HDC; r: PRect; Data: Pointer): Boolean; stdcall; static;
    class procedure RegisterClassWindow();
    class procedure UnregisterClassWindow();
    class constructor Create;
    class destructor Destroy;

    class function WindowProc(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; static;
    class function MessegeLoopProc(w: TLockWindow): Integer; static;
    class procedure HandleException(E: Exception);


    /// instance methods
    procedure EraseBackground(DC: HDC);
    procedure Paint();
    procedure UpdateDateTime();
    procedure SetAlphaPecent(const Value: Byte);
    procedure SetColor(const Value: TColor);
    procedure Invalidate(bErase: Boolean = false);
    procedure LockCanvas(DC: HDC);
    procedure UnlockCanvas();

    // Handlers Window Message
    procedure WmEraseBackground(var Msg: TMessage); message WM_ERASEBKGND;
    procedure WmTimer(var Msg: TMessage); message WM_TIMER;
    procedure WmPaint(var Msg: TMessage); message WM_PAINT;
    procedure WmClose(var Msg: TMessageLW); message WM_CLOSE;
    procedure WmDisplayChange(var Msg: TMessage); message WM_DISPLAYCHANGE;
    procedure WmDestroy(var Msg: TMessageLW); message WM_DESTROY;
    procedure WmSendInput(var Msg: TMessageInput); message WM_SEND_INPUT;

  public
    procedure DefaultHandler(var Message); override;

    constructor Create;
    destructor Destroy; override;

    // Use these methods to manipulate the window <- thread safe
    // But you can also use Create, Free. <- not! thread safe. User is responsible
    class function Show(): TLockWindow;
    class procedure Close();
    class function SendInput(cInputs: UINT; var pInputs: TInput; cbSize: Integer): UINT;
    class function IsVisible(): Boolean;

    // User settings
    property DateLable: string read FDateLable write FDateLable;
    property TimeLabel: string read FTimeLabel write FTimeLabel;
    property UserMessage: string read FUserMessage write FUserMessage;
    property AlphaPecent: Byte read FAlphaPecent write SetAlphaPecent;
    property Color: TColor read FColor write SetColor;
  end;




implementation

uses
  Winapi.MultiMon, Vcl.Consts, Winapi.ShellScaling,
  Winapi.UxTheme, Winapi.DwmApi;



{$REGION 'WindowInBand'}


const
        ZBID_DEFAULT = 0;
        ZBID_DESKTOP = 1;
        ZBID_UIACCESS = 2;
        ZBID_IMMERSIVE_IHM = 3;
        ZBID_IMMERSIVE_NOTIFICATION = 4;
        ZBID_IMMERSIVE_APPCHROME = 5;
        ZBID_IMMERSIVE_MOGO = 6;
        ZBID_IMMERSIVE_EDGY = 7;
        ZBID_IMMERSIVE_INACTIVEMOBODY = 8;
        ZBID_IMMERSIVE_INACTIVEDOCK = 9;
        ZBID_IMMERSIVE_ACTIVEMOBODY = 10;
        ZBID_IMMERSIVE_ACTIVEDOCK = 11;
        ZBID_IMMERSIVE_BACKGROUND = 12;
        ZBID_IMMERSIVE_SEARCH = 13;
        ZBID_GENUINE_WINDOWS = 14;
        ZBID_IMMERSIVE_RESTRICTED = 15;
        ZBID_SYSTEM_TOOLS = 16;
        // Win10
        ZBID_LOCK = 17;
        ZBID_ABOVELOCK_UX = 18;

type
  TCreateWindowInBand = function(dwExStyle: DWORD; lpClassName: LPCWSTR;
    lpWindowName: LPCWSTR; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer;
    hWndParent: HWND; hMenu: HMENU; hInstance: HINST; lpParam: Pointer; dwBand: DWORD): HWND; stdcall;

function CreateWindowInBand(dwExStyle: DWORD; lpClassName: LPCWSTR;
  lpWindowName: LPCWSTR; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer;
  hWndParent: HWND; hMenu: HMENU; hInstance: HINST; lpParam: Pointer; dwBand: DWORD): HWND;

var
  FPUCW: Word;
  pCreateWindowInBand: TCreateWindowInBand;
begin
  @pCreateWindowInBand := GetProcAddress(GetModuleHandle('user32.dll'), 'CreateWindowInBand');
  Win32Check(@pCreateWindowInBand <> nil);
  FPUCW := Get8087CW;
  Result := pCreateWindowInBand(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y,
              nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam, dwBand);
  Set8087CW(FPUCW);
end;

function CheckForUIAccess(): Boolean;
var
  Token: THandle;
  dwRetLen: DWORD;
  UIAccess: DWORD;
begin
  Result := false;

	if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, Token) then
  begin
    Result := GetTokenInformation(Token, TokenUIAccess, @UIAccess, SizeOf(UIAccess), dwRetLen) and (UIAccess <> 0);
  end;

end;

{$ENDREGION}

const
  WND_CLASS_NAME = 'RMX_LOCK_WINDOW_CLASS';


resourcestring
  rsUserMessageEN = 'The computer is locked. '+sLineBreak+
                    'Do not turn off or restart your computer.'+sLineBreak+
                    'Wait for the operator to finish.';
  rsUserMessageDE = 'Der Computer ist gesperrt.'+sLineBreak+
                    'Schalten Sie Ihren Computer nicht aus und starten Sie ihn nicht neu.'+sLineBreak+
                    'Warten Sie, bis der Operator fertig ist.';
  rsUserMessageRU = 'Компьютор заблокирован.'+sLineBreak+
                    'Не выключайте и не перзагружайте компьютер.'+sLineBreak+
                    'Дождидесь окончания работ оператора.';
  rsUserMessageUA = 'Комп''ютер заблоковано.'+sLineBreak+
                    'Не вимикайте та не перезавантажуйте комп''ютер.'+sLineBreak+
                    'Дочекайтесь закінчення робіт оператора.';



{ **************************************************************************** }
{                               TLockWindow                                    }
{ **************************************************************************** }

//==============================================================================

class procedure TLockWindow.Close;
var
  w: TLockWindow;
begin
  if Assigned(Instance) then
    begin
      w := InterlockedExchangePointer(Pointer(Instance), nil);
      if Assigned(w) then
        w.Free;
    end;
end;

class function TLockWindow.Show: TLockWindow;
begin
  Result := nil;
  if Assigned(Instance) then exit;

  while InterlockedExchange(LockCookie, 1) <> 0 do
    begin
      SwitchToThread;
    end;
  try
    // double check after entry into block
    if not Assigned(Instance) then
      Instance := TLockWindow.Create;
    Result := Instance;
  finally
    InterlockedExchange(LockCookie, 0);
  end;
end;

class function TLockWindow.SendInput(cInputs: UINT; var pInputs: TInput;
  cbSize: Integer): UINT;
var
  data: TSendInputData;
  wnd: HWND;
begin
  if not Assigned(Instance) then
    wnd := 0 else
    wnd := Instance.FWindow;

  if wnd <> 0 then
    begin
      data.cInputs := cInputs;
      data.pInputs := @pInputs;
      data.cbSize  := cbSize;
      Result := SendMessage(wnd, WM_SEND_INPUT, 0, LPARAM(@data))
    end
  else
    begin
      Result := Winapi.Windows.SendInput(cInputs, pInputs, cbSize);
    end;

end;

class function TLockWindow.IsVisible: Boolean;
begin
  Result := Assigned(Instance);
end;




//==============================================================================
// instance methods

procedure TLockWindow.ApplyLayeredWindow(Percent: Byte);
begin
  if FWindow <> 0 then
    Win32Check(SetLayeredWindowAttributes(FWindow, 0, (255 * Percent) div 100, LWA_ALPHA));
end;

constructor TLockWindow.Create;
var
  t: THandle;
begin
  inherited Create;
  case Lo(GetUserDefaultUILanguage) of
    LANG_RUSSIAN:   FUserMessage := rsUserMessageRU;
    LANG_ENGLISH:   FUserMessage := rsUserMessageEN;
    LANG_DUTCH:     FUserMessage := rsUserMessageDE;
    LANG_UKRAINIAN: FUserMessage := rsUserMessageUA;
  else
    FUserMessage := rsUserMessageEN;
  end;
  FAlphaPecent := 70;
  FColor := $00001932;
  FUserMessageFont := TFont.Create;
  FDateFont := TFont.Create;
  FTimeFont := TFont.Create;

  FUserMessageFont.Color := clAqua;
  FUserMessageFont.Name := 'Segoe UI Light';
  FUserMessageFont.Size := 18;
  FUserMessageFont.Style := [];

  FDateFont.Color := clWhite;
  FDateFont.Name := 'Segoe UI Light';
  FDateFont.Size := 26;
  FDateFont.Style := [fsBold];

  FTimeFont.Color := clWhite;
  FTimeFont.Name := 'Segoe UI Light';
  FTimeFont.Size := 50;
  FTimeFont.Style := [fsBold];

  FCanvas := TCanvas.Create;
  t := BeginThread(nil, 0, @MessegeLoopProc, Pointer(Self), 0, PCardinal(0)^);
  Win32Check(t <> 0);
  CloseHandle(t);
end;

class constructor TLockWindow.Create;
begin
  UpdateMonitors;
  RegisterClassWindow;
end;

procedure TLockWindow.CreateWindow;
var
  ExStyle: Cardinal;
  Style: Cardinal;
begin
  FSkipOrder := true;
  UpdateDateTime();
  ExStyle := WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOOLWINDOW or WS_EX_TOPMOST ;
  Style   := WS_POPUP;

  if not CheckForUIAccess then
    begin
      FWindow := CreateWindowEx(ExStyle, WND_CLASS_NAME, PChar(string(TLockWindow.ClassName)),
                  Style, 0, 0, GetSystemMetrics(SM_CXVIRTUALSCREEN), GetSystemMetrics(SM_CYVIRTUALSCREEN),
                  GetDesktopWindow(), 0, HInstance, nil);
    end else
    begin
      FWindow := CreateWindowInBand(ExStyle, WND_CLASS_NAME, PChar(string(TLockWindow.ClassName)),
                  Style, 0, 0, GetSystemMetrics(SM_CXVIRTUALSCREEN), GetSystemMetrics(SM_CYVIRTUALSCREEN),
                  0, 0, HInstance, nil, ZBID_UIACCESS);
    end;


  Win32Check(FWindow <> 0);
  SetLastError(0);
  SetWindowLongPtr(FWindow, GWL_USERDATA, NativeInt(Self));
  Win32Check(GetLastError() = 0);


  ApplyLayeredWindow(FAlphaPecent);
  DisableWindowForRecord(true);
  DisableInput(true);

  ShowWindow(FWindow, SW_SHOWNORMAL);
  UpdateWindow(FWindow);

  if SetTimer(FWindow, TIMER_ID_DATE, 1000, nil) = 0 then
      raise EOutOfResources.Create(SNoTimers);

end;


procedure TLockWindow.DefaultHandler(var Message);
begin
  with TMessageLW(Message) do
    TMessage(Message).Result := DefWindowProc(Window, message.Msg, message.WParam, message.LParam);
end;

destructor TLockWindow.Destroy;
begin

  DestroyWindow;
  FCanvas.Handle := 0;
  FCanvas.Free;
  FUserMessageFont.Free;
  FDateFont.Free;
  FTimeFont.Free;

  inherited;
end;

class destructor TLockWindow.Destroy;
begin
  UnregisterClassWindow;
  inherited;
end;

procedure TLockWindow.DestroyWindow;
begin
  if FWindow = 0 then exit;
  FDestroing := true;
  Win32Check(KillTimer(FWindow, TIMER_ID_DATE));
  SendMessage(FWindow, WM_CLOSE, 0, 0);
end;

procedure TLockWindow.DisableInput(Disable: Boolean);
begin
  {$IFDEF BLOCK_INPUT_ENABLED}
    { TODO 1 -cWARN : Check Error - BlockInput. }
//    BlockInput(Disable);
    //Win32Check(BlockInput(Disable));

  {$ENDIF}
    var r: Boolean := false;
    var s: string := Format('TID: %x, BlockInput(%s): %s', [GetCurrentThreadId, BoolToStr(Disable, true), BoolToStr(r, true)]);
    OutputDebugString(PChar(s));

end;

procedure TLockWindow.DisableWindowForRecord(Disable: Boolean);
const
  WDA_EXCLUDEFROMCAPTURE = $00000011;
  WDA_NONE = 0;
  DWA_AFFINITY: array [Boolean] of DWORD = (WDA_NONE, WDA_EXCLUDEFROMCAPTURE);
begin
  if FWindow <> 0 then
    Win32Check(SetWindowDisplayAffinity(FWindow, DWA_AFFINITY[Disable]));
end;

procedure TLockWindow.EraseBackground(DC: HDC);
begin
  if DC = 0 then exit;

  LockCanvas(DC);
  try
      FCanvas.Brush.Color := FColor;
      FCanvas.FillRect(FCanvas.ClipRect);
  finally
    UnlockCanvas()
  end;
end;

procedure TLockWindow.Invalidate(bErase: Boolean);
begin
  if FWindow <> 0 then
    InvalidateRect(FWindow, nil, bErase);
end;

procedure TLockWindow.LockCanvas(DC: HDC);
begin
  FCanvas.Lock;
  FCanvas.Handle := DC;
end;

procedure TLockWindow.UpdateDateTime;
var
  P: PChar;
begin
  GetMem(P, 256);
  try
    Win32Check(GetTimeFormatEx(PChar(LOCALE_NAME_USER_DEFAULT), 0, nil, 'HH:mm:ss', P, 256) > 0);
    FTimeLabel := P;
    Win32Check(GetDateFormatEx(PChar(LOCALE_NAME_USER_DEFAULT),  0, nil, 'dddd, d MMMM', P, 256, nil) > 0);
    FDateLable := P;
  finally
    FreeMem(P);
  end;
  Invalidate;
end;

procedure TLockWindow.Paint;

  procedure UpdateFontSize(Font: TFont; Size: Integer; PixelsPerInch: Integer);
  begin
    if Font.PixelsPerInch <> PixelsPerInch then
      begin
        Font.PixelsPerInch := PixelsPerInch;
        Font.Size := Size;
      end;
  end;

var
  DC, MemDC, WorkDC: HDC;
  PS: TPaintStruct;
  Rect: TRect;
  sz: TSize;
  I, top: Integer;
  PaintBuffer: HPAINTBUFFER;
begin
  MemDC := 0;
  PaintBuffer := 0;
  DC := BeginPaint(FWindow, PS);
  if DC = 0 then exit;

  try
    WorkDC := DC;
    if DwmCompositionEnabled then
      begin
        PaintBuffer := BeginBufferedPaint(DC, PS.rcPaint, BPBF_COMPOSITED, nil, MemDC);
        if PaintBuffer <> 0 then
          WorkDC := MemDC;
      end;


    if PS.fErase then
      EraseBackground(WorkDC);

    LockCanvas(WorkDC);
    try

      for I := 0 to Length(MonitorsRect)-1 do
        begin

          Rect := MonitorsRect[i].BoundsRect; //FCanvas.ClipRect;

          // Draw UserMessage
          FCanvas.Font := FUserMessageFont;
          UpdateFontSize(FCanvas.Font, FCanvas.Font.Size, MonitorsRect[i].PixelsPerInch);

          sz := FCanvas.TextExtent(FUserMessage);
          top := Rect.CenterPoint.Y - Round(sz.Height * 5.95);
          if top > 0 then Rect.Top := top;
          FCanvas.TextRect(Rect, FUserMessage, [tfCenter]);

          // Draw Time
          FCanvas.Font := FTimeFont;
          UpdateFontSize(FCanvas.Font, FCanvas.Font.Size, MonitorsRect[i].PixelsPerInch);
          sz := FCanvas.TextExtent(FTimeLabel);
          Rect.Left := Rect.Left + 20;
          Rect.Top := Rect.Bottom - sz.cy * 2;
          FCanvas.TextOut(Rect.Left, Rect.Top, FTimeLabel);

          // Draw Date
          FCanvas.Font := FDateFont;
          UpdateFontSize(FCanvas.Font, FCanvas.Font.Size, MonitorsRect[i].PixelsPerInch);
          OffsetRect(Rect, 0, sz.cy + 2);
          FCanvas.TextOut(Rect.Left, Rect.Top, FDateLable);
        end;

    finally
      UnlockCanvas;
    end;

  finally
    if MemDC <> 0 then
      EndBufferedPaint(PaintBuffer, True);
    EndPaint(FWindow, PS);
  end;
end;

procedure TLockWindow.SetAlphaPecent(const Value: Byte);
begin
  if FAlphaPecent <> Value then
    begin
      ApplyLayeredWindow(Value);
      FAlphaPecent := Value;
    end;
end;

procedure TLockWindow.SetColor(const Value: TColor);
begin
  if (FColor <> Value) then
    begin
      FColor := Value;
      Invalidate(true);
    end;
end;

procedure TLockWindow.UnlockCanvas;
begin
  FCanvas.Handle := 0;
  FCanvas.Unlock;
end;

procedure TLockWindow.WmClose(var Msg: TMessageLW);
begin
  // prevetn close, return 0, else call DefProc (destroy window)
  if FDestroing  and (Msg.Window = FWindow) then
    DefaultHandler(Msg) else
    Msg.message.Result := 0;
end;

procedure TLockWindow.WmDestroy(var Msg: TMessageLW);
begin
  if Msg.Window = FWindow then
    begin
      Msg.message.Result := 0;
      DisableInput(false);
      PostQuitMessage(0);
    end
  else
    DefaultHandler(Msg);
end;

procedure TLockWindow.WmDisplayChange(var Msg: TMessage);
var
  Wnd: HWND;
begin
  UpdateMonitors;
  Wnd := FWindow;
  KillTimer(wnd, TIMER_ID_DATE);
  CreateWindow();
  SendMessage(wnd, WM_CLOSE, 0, 0);
end;

procedure TLockWindow.WmEraseBackground(var Msg: TMessage);
begin
  Msg.Result := 0;
end;

procedure TLockWindow.WmPaint(var Msg: TMessage);
begin
  Msg.Result := 0;
  Paint();
end;

procedure TLockWindow.WmSendInput(var Msg: TMessageInput);
begin
  Msg.Result :=
    Winapi.Windows.SendInput(Msg.pInputData.cInputs, Msg.pInputData.pInputs^, Msg.pInputData.cbSize);
end;

procedure TLockWindow.WmTimer(var Msg: TMessage);
begin
  Msg.Result := 0;
  UpdateDateTime();
end;


//==============================================================================
// Get Monitor Count and DPI
type
  TDataCallbackMonitor = record
    list: TMonitorInfoRectList;
    index: Integer;
  end;

class procedure TLockWindow.UpdateMonitors;
var
  data: TDataCallbackMonitor;
begin
  SetLength(MonitorsRect, GetSystemMetrics(SM_CMONITORS));
  data.list := MonitorsRect;
  data.index := 0;
  EnumDisplayMonitors(0, nil, @EnumMonitorsProc, LPARAM(@data));
end;

class function TLockWindow.EnumMonitorsProc(hm: HMONITOR; dc: HDC; r: PRect;
  Data: Pointer): Boolean;
var
  info: TMonitorInfo;
  data_callback: ^TDataCallbackMonitor absolute Data;
  Ydpi, Xdpi: Cardinal;
begin
  info.cbSize := SizeOf(TMonitorInfo);
  Win32Check(GetMonitorInfo(hm, @info));
  data_callback^.list[data_callback^.index].BoundsRect := info.rcMonitor;
  Ydpi := 0;
  if GetDpiForMonitor(hm, MDT_EFFECTIVE_DPI, Ydpi, Xdpi) = S_OK then
    data_callback^.list[data_callback^.index].PixelsPerInch := Ydpi else
    data_callback^.list[data_callback^.index].PixelsPerInch := GetDeviceCaps(DC, LOGPIXELSY);
  Inc(data_callback^.index);
  Result := true;
end;

//==============================================================================
// Register\UnRegister class window


class procedure TLockWindow.RegisterClassWindow;
var
  wndClass: TWndClassEx;
begin
  FillChar(wndClass, SizeOf(wndClass), 0);
  wndClass.cbSize        := SizeOf(TWndClassEx);
  wndClass.lpfnWndProc   := @WindowProc;
  wndClass.hInstance     := hInstance;
  wndClass.lpszClassName := WND_CLASS_NAME;
  wndClass.style         := CS_VREDRAW + CS_HREDRAW;
  wndClass.hCursor       := LoadCursor(0, IDC_ARROW);
  wndClass.hIcon         := LoadIcon(0, IDI_APPLICATION);
  Win32Check(Winapi.Windows.RegisterClassEx(wndClass) <> 0);
end;

class procedure TLockWindow.UnregisterClassWindow;
begin
  Winapi.Windows.UnregisterClass(WND_CLASS_NAME, hInstance)
end;

//==============================================================================
// Window Proc
class function TLockWindow.WindowProc(Wnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT;
var
  w: TLockWindow;
  message: TMessageLW;
begin
  Result := 0;

  NativeInt(w) := GetWindowLongPtr(Wnd, GWL_USERDATA);

  if Assigned(w) then
  begin
    try
      message := TMessageLW.Create(Wnd, Msg, wParam, lParam);
      w.Dispatch(message);
      Result := message.message.Result;

    except
      on e: Exception do
        begin
          w.HandleException(e);
        end;
    end;

  end

  else
    begin
      Result := DefWindowProc(Wnd, Msg, wParam, lParam);
    end;


end;

//==============================================================================
// class methods MessegeLoopProc, own thread proc

class function TLockWindow.MessegeLoopProc(w: TLockWindow): Integer;
var
  msg: TMsg;
begin
  Result := 0;
  try

    if TOSVersion.Check(6, 0) then
      BufferedPaintInit;
    try

      w.CreateWindow();
      while GetMessage(msg, 0, 0, 0) do
        begin
          //if TranslateAccelerator(w.FWindow, 0, msg) <> 0 then Continue;
          TranslateMessage(msg);
          DispatchMessage(msg);
        end;

    finally
      if TOSVersion.Check(6, 0) then
        BufferedPaintUnInit;
    end;



  except
    on e: Exception do
      begin
        TLockWindow.HandleException(e);
        Result := -1;
      end;
  end;

end;

//==============================================================================
// class methods HandleException

class procedure TLockWindow.HandleException(E: Exception);
{$IFDEF ERROR_TO_DEBUG_OUTPUT}
var
  Buffer: array[0..1023] of Char;
{$ENDIF}
begin
  if E is EAbort then exit;

  {$IFDEF ERROR_TO_MSGBOX}
    System.SysUtils.ShowException(E, ExceptAddr);
  {$ENDIF}

  {$IFDEF ERROR_TO_DEBUG_OUTPUT}
    ExceptionErrorMessage(ExceptObject, ExceptAddr, Buffer, Length(Buffer));
    OutputDebugString(Buffer);
  {$ENDIF}


//lines below can be deleted

//  TThread.Current.Synchronize(procedure()
//  begin
//
//  end
//  );
end;


{ **************************************************************************** }
{                               TMessageLW                                     }
{ **************************************************************************** }

constructor TMessageLW.Create(Wnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM);
begin
  Self.Window         := Wnd;
  Self.message.Msg    := Msg;
  Self.message.WParam := wParam;
  Self.message.LParam := lParam;
  Self.message.Result := 0;
end;


end.
