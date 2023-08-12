unit FLoatPanelVCL;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TTypePanelAnimation = (tpaMoveLeft, tpaMoveTop, tpaMoveDown, tpaMoveRight);
  TOnApplyRegion = procedure (Sender: TObject; ctrl: TControl; var r: TRect) of object;

  TFloatPanelVCL = class (TCustomControl)
  private
    FTimer: TTimer;
    FTickCount: Integer;
    FDuration: single;
    FInverse: Boolean;
    FTime: single;
    FRunning: Boolean;
    FDelayTime: single;
    FDelay: single;
    FEnabledAnimation: Boolean;
    FAutoReverse: Boolean;
    FSavedInverse: Boolean;
    FPause: Boolean;
    FLoop: Boolean;
    FStartFloat: single;
    FStopFloat: single;
    FTypeAnimation: TTypePanelAnimation;
    FStartFromCurrent: Boolean;

    FTimerTime: Cardinal;
    FOnFinish: TNotifyEvent;
    FOnApplyRegion: TOnApplyRegion;
    FDrawFrame: Boolean;
    FRegionIsApplied: Boolean;


    procedure ProcessTick(time, deltaTime: Single);
    procedure OnTimer(Sender: TObject);
    procedure SetDrawFrame(const Value: Boolean);
  protected
    procedure ProcessAnimation; virtual;
    procedure FirstFrame; virtual;
    procedure DoFinish; virtual;
    function GetNormalizedTime: Single;
    procedure Paint; override;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplyRegions;
    procedure StartAnimate;
    procedure StopAnimate;
    property Duration: Single read FDuration write FDuration;
    property StartValue: Single read FStartFloat write FStartFloat;
    property StartFromCurrent: Boolean read FStartFromCurrent write FStartFromCurrent;
    property StopValue: Single read FStopFloat write FStopFloat;
    property TypeAnimation: TTypePanelAnimation read FTypeAnimation write FTypeAnimation;
    property AutoReverse: Boolean read FAutoReverse write FAutoReverse;
    property Running: Boolean read FRunning;
    property Pause: Boolean read FPause write FPause;
    property Loop: Boolean read FLoop write FLoop;
    property Delay: Single read FDelay write FDelay;
    property Inverse: Boolean read FInverse write FInverse;
    property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
    property OnApplyRegion: TOnApplyRegion read FOnApplyRegion write FOnApplyRegion;
    property DrawFrame: Boolean read FDrawFrame write SetDrawFrame;

  end;



implementation

function Win32CheckError(RetVal: BOOL): BOOL;
begin
  if not RetVal then RaiseLastOSError;
  Result := RetVal;
end;

{ TFloatPanelVCL }

function InterpolateLinear(t, B, C, D: Single): Single;
begin
  Result := C * t / D + B;
end;



function InterpolateSingle(const Start, Stop, T: Single): Single;
begin
  Result := Start + (Stop - Start) * T;
end;

procedure TFloatPanelVCL.Paint;
const
  XorColor = $00FFD8CE;
begin
//  inherited;
  if {(csDesigning in ComponentState) or }FDrawFrame  then
  begin

//    Canvas.Font := Font;
//    Canvas.Brush.Color := Color;

      with Canvas do
      begin
         // Pen.Style := psDot;
          Pen.Mode := pmXor;
          Pen.Color := XorColor;
          Brush.Style := bsClear;
          Rectangle(0, 0, ClientWidth, ClientHeight);
      end;

  end;
  //if Assigned(FOnPaint) then FOnPaint(Self);

end;

procedure TFloatPanelVCL.ProcessAnimation;
begin
  case FTypeAnimation of
    tpaMoveLeft: Left := Round(InterpolateSingle(FStartFloat, FStopFloat, GetNormalizedTime));
    tpaMoveTop: Top := Round(InterpolateSingle(FStartFloat, FStopFloat, GetNormalizedTime));
    tpaMoveDown: Top := Round(InterpolateSingle(FStartFloat, FStopFloat, GetNormalizedTime));
    tpaMoveRight: Left := Round(InterpolateSingle(FStartFloat, FStopFloat, GetNormalizedTime));
  end;


end;

procedure TFloatPanelVCL.ApplyRegions;
var
  rg_ctrl, rg0, rg, rg_temp: HRGN;
  r_ctrl, r0: TRect;
  i: Integer;
begin
  rg      := 0;
  rg0     := 0;
  rg_temp := 0;
  rg_ctrl := 0;

  r0 := ClientRect;
  try
    rg  := CreateRectRgn(0, 0, 0, 0);
    Win32CheckError(rg <> 0);
    rg0 := CreateRectRgn(r0.Left, r0.Top, r0.Right, r0.Bottom);
    Win32CheckError(rg0 <> 0);
    rg_temp := CreateRectRgn(0, 0, 0, 0);
    Win32CheckError(rg_temp <> 0);

   for I := 0 to ControlCount-1  do
      begin
        r_ctrl := Controls[i].BoundsRect;

        if Assigned(FOnApplyRegion) then
          FOnApplyRegion(Self, Controls[i], r_ctrl);

        rg_ctrl := CreateRectRgn(r_ctrl.Left, r_ctrl.Top, r_ctrl.Right, r_ctrl.Bottom);
        Win32CheckError(rg_ctrl <> 0);
        Win32CheckError(CombineRgn(rg_temp, rg0, rg_ctrl, RGN_AND) <> ERROR);
        Win32CheckError(CombineRgn(rg, rg, rg_temp, RGN_OR) <> ERROR);
        DeleteObject(rg_ctrl);
        rg_ctrl := 0;
      end;

    if FDrawFrame then
      begin
        InflateRect(r0, -1, -1);
        rg_ctrl := CreateRectRgn(r0.Left, r0.Top, r0.Right, r0.Bottom);
        Win32CheckError(rg_ctrl <> 0);
        Win32CheckError(CombineRgn(rg_temp, rg0, rg_ctrl, RGN_XOR) <> ERROR);
        Win32CheckError(CombineRgn(rg, rg, rg_temp, RGN_OR) <> ERROR);
        DeleteObject(rg_ctrl);
        rg_ctrl := 0;
      end;


    Win32CheckError(SetWindowRgn(Handle, rg, true) <> 0);
    FRegionIsApplied := true;
  except
    if rg <> 0 then
      DeleteObject(rg);
    if rg0 <> 0 then
      DeleteObject(rg0);
    if rg_temp <> 0 then
      DeleteObject(rg_temp);
    if rg_ctrl <> 0 then
      DeleteObject(rg_ctrl);
    raise;
  end;

  // clean
  if rg0 <> 0 then
    DeleteObject(rg0);
  if rg_temp <> 0 then
    DeleteObject(rg_temp);
end;

constructor TFloatPanelVCL.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := false;
  FTimer.OnTimer := OnTimer;
  FTimer.Interval := Trunc(1000 / 60 / 10) * 10;    // frame rate
  FTypeAnimation := tpaMoveTop;
  if (csDesigning in ComponentState) then
    begin
      SetDrawFrame( true );
    end;
//  Color := clRed;
end;

procedure TFloatPanelVCL.DoFinish;
begin
  if Assigned(FOnFinish) then
    FOnFinish(Self);
end;

procedure TFloatPanelVCL.FirstFrame;
begin
  if not FStartFromCurrent then exit;

  case FTypeAnimation of
    tpaMoveLeft: FStartFloat := Left;
    tpaMoveTop: FStartFloat := Top;
    tpaMoveDown: FStartFloat := Top;
    tpaMoveRight: FStartFloat := Left;
  end;
end;

function TFloatPanelVCL.GetNormalizedTime: Single;
begin
  Result := 0;
  if (FDuration > 0) and (FDelayTime <= 0) then
  begin
    Result := InterpolateLinear(FTime, 0, 1, FDuration);
  end;
end;

procedure TFloatPanelVCL.OnTimer(Sender: TObject);
var
  delta, NewTime: Cardinal;
begin
  NewTime := GetTickCount;
  delta := NewTime - FTimerTime;
  FTimerTime := NewTime;
  ProcessTick(FTimerTime, delta);
end;

procedure TFloatPanelVCL.ProcessTick(time, deltaTime: Single);
begin
  inherited;
  if [csDesigning, csDestroying] * ComponentState <> [] then
    Exit;

//  if Supports(Parent, IControl, Control) and (not Control.Visible) then
//    Stop;

  if (not FRunning) or FPause then
    Exit;

  if (FDelay > 0) and (FDelayTime <> 0) then
  begin
    if FDelayTime > 0 then
    begin
      FDelayTime := FDelayTime - deltaTime;
      if FDelayTime <= 0 then
      begin
        FDelayTime := 0;
        if FInverse then
          FTime := FDuration
        else
          FTime := 0;
        FirstFrame;
        ProcessAnimation;;
        //DoProcess;
      end;
    end;
    Exit;
  end;

  if FInverse then
    FTime := FTime - deltaTime
  else
    FTime := FTime + deltaTime;
  if FTime >= FDuration then
  begin
    FTime := FDuration;
    if FLoop then
    begin
      if FAutoReverse then
      begin
        FInverse := True;
        FTime := FDuration;
      end
      else
        FTime := 0;
    end
    else
      if FAutoReverse and (FTickCount = 0) then
      begin
        Inc(FTickCount);
        FInverse := True;
        FTime := FDuration;
      end
      else
        FRunning := False;
  end
  else if FTime <= 0 then
  begin
    FTime := 0;
    if FLoop then
    begin
      if FAutoReverse then
      begin
        FInverse := False;
        FTime := 0;
      end
      else
        FTime := FDuration;
    end
    else
      if FAutoReverse and (FTickCount = 0) then
      begin
        Inc(FTickCount);
        FInverse := False;
        FTime := 0;
      end
      else
        FRunning := False;
  end;

  ProcessAnimation;;
  //DoProcess;

  if not FRunning then
  begin
    if FAutoReverse then
      FInverse := FSavedInverse;
    FTimer.Enabled := false;
    DoFinish;
  end;

end;

procedure TFloatPanelVCL.SetDrawFrame(const Value: Boolean);
begin
  if FDrawFrame <> Value then
    begin
      FDrawFrame := Value;
      Padding.SetBounds(1, 1, 1, 1);
      if FRegionIsApplied then
        ApplyRegions;
    end
  else
    Padding.SetBounds(0, 0, 0, 0);
end;

procedure TFloatPanelVCL.StartAnimate;
var
  SaveDuration: Single;
begin
  if not FLoop then
    FTickCount := 0;
  if FAutoReverse then
  begin
    if FRunning then
      FInverse := FSavedInverse
    else
      FSavedInverse := FInverse;
  end;
  if (Abs(FDuration) < 0.001) {or (Root = nil)} or (csDesigning in ComponentState) then
  begin
    { immediate animation }
    SaveDuration := FDuration;
    try
      FDelayTime := 0;
      FDuration := 1;
      if FInverse then
        FTime := 0
      else
        FTime := FDuration;
      FRunning := True;
      ProcessAnimation;
//      DoProcess;
      FRunning := False;
      FTime := 0;
      DoFinish;
    finally
      FDuration := SaveDuration;
    end;
  end
  else
  begin
    FDelayTime := FDelay;
    FRunning := True;
    if FInverse then
      FTime := FDuration
    else
      FTime := 0;
    if FDelay = 0 then
    begin
      FirstFrame;
      ProcessAnimation;
      //DoProcess;
    end;
    FTimerTime := GetTickCount;
    FTimer.Enabled := true;
    FEnabledAnimation := True;
//    if AniThread = nil then
//      FAniThread := TAniThread.Create;
//
//    TAniThread(AniThread).AddAnimation(Self);
//    if not AniThread.Enabled then
//      Stop
//    else
//      FEnabledAnimation := True;
  end;

end;

procedure TFloatPanelVCL.StopAnimate;
begin
  if not FRunning then
    Exit;

  FTimer.Enabled := false;
//  if AniThread <> nil then
//    TAniThread(AniThread).RemoveAnimation(Self);

  if FAutoReverse then
    FInverse := FSavedInverse;

  if FInverse then
    FTime := 0
  else
    FTime := FDuration;
  ProcessAnimation;;
//  DoProcess;
  FRunning := False;
  DoFinish;
end;

procedure TFloatPanelVCL.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
  Message.Result := 1;
end;

end.
