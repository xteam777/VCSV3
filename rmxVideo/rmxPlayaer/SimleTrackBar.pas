unit SimleTrackBar;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms;

type
  TTrackBarEx = class (TGraphicControl)
  private
    FMax: Integer;
    FMin: Integer;
    FPosition: Integer;
    FProgress: Double;
    FMousePressed: Boolean;
    FOnChange: TNotifyEvent;
    FOnShowHint: TShowHintEvent;
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(const Value: Integer);
    procedure TrackMousePosition(X, Y: Integer);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure Change; dynamic;
    procedure RecalcProgress;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Max: Integer read FMax write SetMax;
    property Min: Integer read FMin write SetMin;
    property Position: Integer read FPosition write SetPosition;
    property OnShowHint: TShowHintEvent read FOnShowHint write FOnShowHint;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    // mouse well not implemented
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;



  end;

implementation

{ TTrackBarEx }

procedure TTrackBarEx.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TTrackBarEx.CMHintShow(var Message: TCMHintShow);
var
  CanShow: Boolean;
begin
  inherited;
  CanShow := not Boolean(Message.Result);
  if Assigned(FOnShowHint) then
    begin
      FOnShowHint(Message.HintInfo^.HintStr, CanShow, Message.HintInfo^);
      Message.Result := Integer(not CanShow);
    end
  else if CanShow then
    Message.HintInfo.HintStr := 'Position: '+ FPosition.ToString;

end;

procedure TTrackBarEx.CMMouseEnter(var Message: TMessage);
begin
  inherited;
end;

constructor TTrackBarEx.Create(AOwner: TComponent);
begin
  inherited;
  FMax := 100;
  FMin := 0;
  Color := $00FF910E;
end;

destructor TTrackBarEx.Destroy;
begin

  inherited;
end;

procedure TTrackBarEx.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  FMousePressed := Button = mbLeft;
  if FMousePressed then
    TrackMousePosition(X, Y);

end;

procedure TTrackBarEx.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FMousePressed then
    TrackMousePosition(X, Y);

end;

procedure TTrackBarEx.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if FMousePressed then
    TrackMousePosition(X, Y);
  FMousePressed := false;
  Change;
end;


procedure TTrackBarEx.Paint;
var
  progress_w: Integer;
  r: TRect;
begin
  inherited;
  progress_w := Round(Width * FProgress);
  r := Rect(0, 0, Width, Height);
  Canvas.Brush.Color := clGrayText;
  Canvas.FillRect(r);

  r.Width := progress_w;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(r);


end;

procedure TTrackBarEx.RecalcProgress;
begin
  if FPosition <> 0 then
    FProgress := FPosition / (Max - Min)  else
    FProgress := 0;
end;

procedure TTrackBarEx.SetMax(const Value: Integer);
begin
  if FMax <> Value then
    begin
      FMax := Value;
      RecalcProgress;
      Change;
      Invalidate;
    end;
end;

procedure TTrackBarEx.SetMin(const Value: Integer);
begin
  if FMin <> Value then
    begin
      FMin := Value;
      RecalcProgress;
      Change;
      Invalidate;
    end;
end;

procedure TTrackBarEx.SetPosition(const Value: Integer);
begin
  if (FPosition <> Value)  and (Value >= FMin) and (Value <= FMax) then
    begin
      FPosition := Value;
      RecalcProgress;
      Change;
      Invalidate;
    end;
end;

procedure TTrackBarEx.TrackMousePosition(X, Y: Integer);
begin
      FProgress := X / Width;
      FPosition := Round(FProgress * (FMax-FMin));
      InvalidateRect(Parent.Handle, BoundsRect, false)
//      Invalidate;

end;


end.
