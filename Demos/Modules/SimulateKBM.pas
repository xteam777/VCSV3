unit SimulateKBM;

interface

uses
  Windows, Messages, SysUtils;

type
  TSimulateKBM = class
  private
    FMouseDown: Boolean;
    FLastWindowFocus: HWND;
    procedure FocusWindow(W: HWND);
    procedure OutMessage(W: HWND; Msg: Cardinal; wParam, lParam: Integer);
  public
    function WhereIsMouse: TPoint;
    procedure MoveMouse(ScreenDest: TPoint);
    procedure MouseDown;
    procedure MouseDownXY(X, Y: Integer);
    procedure MouseUp;
    procedure MouseUpXY(X, Y: Integer);
    procedure MouseClick;
    procedure MouseRightClick;
    procedure MouseDblClick;
    procedure KbdTypeText(const S: string);
  end;

implementation

type
  TLParam = packed record
    case B:Boolean of
      true: (x, y: SmallInt);
      false: (Value: LongInt);
  end;

{ TSimulateKBM }
procedure TSimulateKBM.FocusWindow(W: HWND);
var
  CurrWindowThreadID: LongWord;
  ThisThreadID: LongWord;
begin
  FLastWindowFocus:= W;
  CurrWindowThreadID:= GetWindowThreadProcessId(W, nil);
  ThisThreadID:= GetCurrentThreadId;
  if ThisThreadID = CurrWindowThreadID then
    SetFocus(W)
  else if AttachThreadInput(ThisThreadID, CurrWindowThreadID, True) then
    try
      SetFocus(W);
    finally
      AttachThreadInput(ThisThreadID, CurrWindowThreadID, False);
    end
end;
procedure TSimulateKBM.KbdTypeText(const S: string);
  procedure SendText(const Text: string);
  var
    KbdFocusWindow: HWND;
    I: Integer;
  begin
    KbdFocusWindow:= GetFocus;
    if KbdFocusWindow = 0 then
      KbdFocusWindow:= FLastWindowFocus;
    if KbdFocusWindow <> 0 then
      for I:= 1 to Length(Text) do
        OutMessage(KbdFocusWindow, WM_CHAR, Byte(Text[I]), 0);
  end;
var
  CurrWindow: HWND;
  CurrWindowThreadID: LongWord;
  ThisThreadID: LongWord;
begin
  CurrWindow:= GetForegroundWindow;
  CurrWindowThreadID:= GetWindowThreadProcessId(CurrWindow, nil);
  ThisThreadID:= GetCurrentThreadId;
  if ThisThreadID = CurrWindowThreadID then
    SendText(S)
  else if AttachThreadInput(ThisThreadID, CurrWindowThreadID, True) then
    try
      SendText(S);
    finally
      AttachThreadInput(ThisThreadID, CurrWindowThreadID, False);
    end
end;
procedure TSimulateKBM.MouseClick;
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  if GetCursorPos(P) then
  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        FocusWindow(W);
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_LButtonDown, MK_LBUTTON, LParam.Value);
        OutMessage(W, WM_LButtonUp, MK_LBUTTON, LParam.Value);
      end;
    end;
  end;
  FMouseDown:= False;
end;
procedure TSimulateKBM.MouseDblClick;
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  if GetCursorPos(P) then
  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        FocusWindow(W);
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_LBUTTONDOWN, MK_LBUTTON, LParam.Value);
        OutMessage(W, WM_LBUTTONUP, MK_LBUTTON, LParam.Value);
        OutMessage(W, WM_LBUTTONDBLCLK, MK_LBUTTON, LParam.Value);
        OutMessage(W, WM_LBUTTONUP, MK_LBUTTON, LParam.Value);
      end;
    end;
  end;
  FMouseDown:= False;
end;

procedure TSimulateKBM.MouseDown;
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  if GetCursorPos(P) then
  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        FocusWindow(W);
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_LButtonDown, MK_LBUTTON, LParam.Value);
        FMouseDown:= True;
      end;
    end;
  end;
end;

procedure TSimulateKBM.MouseDownXY(X, Y: Integer);
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  P.X := X;
  P.Y := Y;
//  if GetCursorPos(P) then
//  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        FocusWindow(W);
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_LButtonDown, MK_LBUTTON, LParam.Value);
        FMouseDown:= True;
      end;
    end;
//  end;
end;

procedure TSimulateKBM.MouseRightClick;
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  if GetCursorPos(P) then
  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        FocusWindow(W);
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_RButtonDown, MK_RBUTTON, LParam.Value);
        OutMessage(W, WM_RButtonUp, MK_RBUTTON, LParam.Value);
      end;
    end;
  end;
  FMouseDown:= False;
end;

procedure TSimulateKBM.MouseUp;
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  if GetCursorPos(P) then
  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_LButtonUp, MK_LBUTTON, LParam.Value);
      end;
    end;
  end;
  FMouseDown:= False;
end;

procedure TSimulateKBM.MouseUpXY;
var
  P: TPoint;
  W: HWND;
  LParam: TLParam;
begin
  P.X := X;
  P.Y := Y;
//  if GetCursorPos(P) then
//  begin
    W:= WindowFromPoint(P);
    if W <> 0 then
    begin
      if ScreenToClient(W, P) then
      begin
        LParam.X:= P.X;
        LParam.Y:= P.Y;
        OutMessage(W, WM_LButtonUp, MK_LBUTTON, LParam.Value);
      end;
    end;
//  end;
  FMouseDown:= False;
end;

procedure TSimulateKBM.MoveMouse(ScreenDest: TPoint);
var
  W: HWND;
  P: TPoint;
  Keys: Word;
  LParam: TLParam;
begin
//  SetCursorPos(ScreenDest.X, ScreenDest.Y);
  W:= WindowFromPoint(ScreenDest);
  if W <> 0 then
  begin
    P:= ScreenDest;
    if ScreenToClient(W, P) then
    begin
      LParam.X:= P.X;
      LParam.Y:= P.Y;
      if FMouseDown then
        Keys:= MK_LBUTTON
      else
        Keys:= 0;
      OutMessage(W, WM_MOUSEMOVE, Keys, LParam.Value);
    end;
  end;
end;
procedure TSimulateKBM.OutMessage(W: HWND; Msg: Cardinal; wParam,
  lParam: Integer);
const
  WaitTime = 20000; {20 seconds}
var
  MsgResult: Cardinal;
begin
  // First send to message que, if full or some other problem then do the timeout one.
  if not PostMessage(W, Msg, wParam, lParam) then
    if not BOOL(SendMessageTimeOut(W, Msg, wParam, lParam, SMTO_NORMAL, WaitTime, MsgResult)) then
      raise Exception.Create(SysErrorMessage(GetLastError));
end;
function TSimulateKBM.WhereIsMouse: TPoint;
begin
  GetCursorPos(Result);
end;
end.
