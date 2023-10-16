unit PlayerUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  FLoatPanelVCL, Vcl.Buttons, AcceleratedPaintBox, PlayImage, System.Actions,
  Vcl.ActnList, Vcl.ComCtrls, ConvertUnit, SimleTrackBar;

type
  TPlayerForm = class(TForm)
    pnlCommon: TPanel;
    btnSlide: TSpeedButton;
    btnPlay: TSpeedButton;
    ActionList: TActionList;
    actPlay: TAction;
    actStop: TAction;
    actPause: TAction;
    actForward: TAction;
    actBackward: TAction;
    actOpenFile: TAction;
    actConvert: TAction;
    btnPause: TSpeedButton;
    btnStop: TSpeedButton;
    btnForward: TSpeedButton;
    btnBackward: TSpeedButton;
    btnOpenFile: TSpeedButton;
    btnConvert: TSpeedButton;
    lblTime: TLabel;
    FileOpenDialog: TFileOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnSlideClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure actPauseExecute(Sender: TObject);
    procedure actOpenFileExecute(Sender: TObject);
    procedure actConvertExecute(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure actForwardExecute(Sender: TObject);
    procedure actBackwardExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FFLoatPanel: TFloatPanelVCL;
    F2DCanvas: TCustomAcceleratedPaintBox;
    FPlayer: TPlayerHandler;
    FFileName: string;
    FLastFrame: TBitmap;
    FPlayerSetProgress: Boolean;
    FTRackBar: TTrackBarEx;
    procedure PaintImage(Sender: TObject; Bitmap: TBitmap; const Progress: TRMXPlayerProgress);
    procedure OnApplyRegion(Sender: TObject; ctrl: TControl; var r: TRect);
    function PlayerTimerToStr(cur, max: Int64): string; overload;
    function PlayerTimerToStr(val: Int64): string; overload;
    function IsPanelPlayerVisible: Boolean;
    procedure OnPaintPaintBox(Sender: TObject);
    procedure UpdateUserActions;
    procedure PaintFileNameOnTarget(Opacity: Single);
    procedure OnShowHintTrackBar(var HintStr: string; var CanShow: Boolean;
      var HintInfo: Vcl.Controls.THintInfo);
  public
    { Public declarations }
    procedure OnPanelSlideFinish(Sender: TObject);
    property FileName: string read FFileName write FFileName;
    procedure OpenFile(AFileName: String);
  end;

var
  PlayerForm: TPlayerForm;

implementation

{$DEFINE FLOAT_PANEL_ALTOP}

{$R *.dfm}

procedure TPlayerForm.actBackwardExecute(Sender: TObject);
begin
  if FPlayer.Running then
    FPlayer.Position := FPlayer.Position - FPlayer.FPS * 2

end;

procedure TPlayerForm.actConvertExecute(Sender: TObject);
var
  cvt: TConvertForm;
begin
  cvt := TConvertForm.Create(nil);
  try
    cvt.edSrc.Text := FFileName;
    cvt.ShowModal;
  finally
    cvt.Free;
  end;
end;

procedure TPlayerForm.actForwardExecute(Sender: TObject);
begin
  if FPlayer.Running then
    FPlayer.Position := FPlayer.Position + FPlayer.FPS * 2
end;

procedure TPlayerForm.actOpenFileExecute(Sender: TObject);
begin
  if FileOpenDialog.Execute then
    begin
      FFileName := FileOpenDialog.FileName;

      FPlayer.Stop;
      FPlayer.Play(FFileName);

      UpdateActions;
    end;
end;

procedure TPlayerForm.OpenFile(AFileName: String);
begin
  Show;

  FFileName := AFileName;

  FPlayer.Stop;
  FPlayer.Play(FFileName);

  UpdateActions;
end;

procedure TPlayerForm.actPauseExecute(Sender: TObject);
begin
  FPlayer.Pause := not FPlayer.Pause;
  UpdateActions;
end;

procedure TPlayerForm.actStopExecute(Sender: TObject);
begin
  FPlayer.Stop;
  UpdateActions;
end;

procedure TPlayerForm.btnPlayClick(Sender: TObject);
begin
  FPlayer.Stop;
  FPlayer.Play(FFileName);
  UpdateActions;
end;

procedure TPlayerForm.btnSlideClick(Sender: TObject);
begin
  FFLoatPanel.StopValue := FFLoatPanel.Top - (pnlCommon.Height * FFLoatPanel.Tag);
  FFLoatPanel.StartAnimate;
end;

procedure TPlayerForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TPlayerForm.FormCreate(Sender: TObject);
const
  DEF_COFFY_COLOR = $00001932;
begin
  // trackbar settings
  FTRackBar := TTrackBarEx.Create(Self);
  FTRackBar.Parent      := pnlCommon;
  FTRackBar.BoundsRect  := Rect(btnConvert.BoundsRect.Right + 2, btnConvert.Top + 3,
                                lblTime.Left - 6, btnConvert.Height-3);//
  FTRackBar.Anchors     := FTRackBar.Anchors + [akRight];
  FTRackBar.OnChange    := TrackBarChange;
  FTRackBar.OnShowHint  := OnShowHintTrackBar;



  // move controls to the float panel
  FFLoatPanel            := TFloatPanelVCL.Create(Self);
  FFLoatPanel.Parent     := Self;
  FFLoatPanel.BoundsRect := pnlCommon.BoundsRect;
  FFLoatPanel.Top        := 0;
  FFLoatPanel.Height     := FFLoatPanel.Height + btnSlide.Height + 2;
  pnlCommon.Parent       := FFLoatPanel;
  pnlCommon.Align        := alTop; // pnlCommon.Left := 0;
  btnSlide.Parent        := FFLoatPanel;
  btnSlide.Left          := FFLoatPanel.Width - (btnSlide.Width ) - 1;


  // settings slider
  FFLoatPanel.StartFromCurrent := true;
  FFLoatPanel.Duration         := 1000;
  FFLoatPanel.OnFinish         := OnPanelSlideFinish;
  FFLoatPanel.Tag              := 1;

  F2DCanvas         := TCustomAcceleratedPaintBox.Create(nil);
  F2DCanvas.Parent  := Self;
  F2DCanvas.Align   := alClient;
  F2DCanvas.OnPaint := OnPaintPaintBox;
  F2DCanvas.HandleNeeded;
  F2DCanvas.D2DCanvas.Clear(DEF_COFFY_COLOR);


  FPlayer          := TPlayerHandler.Create;
  FPlayer.OnFrame  := PaintImage;

  FFLoatPanel.OnApplyRegion := OnApplyRegion;
  {$ifdef DEBUG}
 //   FFLoatPanel.DrawFrame := true;
    FFileName := 'Video_2023_07_30_005708.rmxv';
  {$endif}
  {$ifndef FLOAT_PANEL_ALTOP}
  FFLoatPanel.ApplyRegions;
  {$endif}
  FFLoatPanel.BringToFront;


  UpdateActions;

end;


procedure TPlayerForm.FormDestroy(Sender: TObject);
begin
  F2DCanvas.Free;
  FPlayer.Free;
  FLastFrame.Free;
end;

procedure TPlayerForm.FormResize(Sender: TObject);
begin
  {$ifdef FLOAT_PANEL_ALTOP}
    FFLoatPanel.BoundsRect := Rect(0, FFLoatPanel.Top, ClientWidth, FFLoatPanel.Height);
    btnSlide.Left          := FFLoatPanel.Width - (btnSlide.Width ) - 1;
    FFLoatPanel.ApplyRegions;
  {$else}
    FFLoatPanel.Left := (ClientWidth + FFLoatPanel.Width) div 2 - FFLoatPanel.Width;
  {$endif}
end;

function TPlayerForm.IsPanelPlayerVisible: Boolean;
begin
  Result := (FFLoatPanel.Tag > 0) or FFLoatPanel.Running;
end;

procedure TPlayerForm.OnApplyRegion(Sender: TObject; ctrl: TControl;
  var r: TRect);
begin
  // check if Button, reduce 1 pixel
 // if (ctrl = btnSlide) then
    InflateRect(r, -1, -1);

end;

procedure TPlayerForm.OnPaintPaintBox(Sender: TObject);
var
  bmp: TBitmap;
begin
  if not FPlayer.Running then
    begin
      bmp := FPlayer.CurrentFrame;
      if Assigned(bmp) then
        F2DCanvas.D2DCanvas.StretchDraw(ClientRect, bmp)
      else
      if Assigned(FLastFrame) then
        F2DCanvas.D2DCanvas.StretchDraw(ClientRect, FLastFrame)
    end;

end;

procedure TPlayerForm.OnPanelSlideFinish(Sender: TObject);
begin
  FFLoatPanel.Tag := - FFLoatPanel.Tag;
  if FFLoatPanel.Tag < 0 then
    btnSlide.Caption := 'q'
    else
    btnSlide.Caption := 'p'
end;

procedure TPlayerForm.OnShowHintTrackBar(var HintStr: string;
  var CanShow: Boolean; var HintInfo: Vcl.Controls.THintInfo);
begin
  HintStr := PlayerTimerToStr( FPlayer.PositionToTime(FTRackBar.Position)  );
end;

procedure TPlayerForm.PaintFileNameOnTarget(Opacity: Single);
var
  s: string;
  r: TRect;
begin

  F2DCanvas.D2DCanvas.Font.Color  := clWhite;
//  F2DCanvas.D2DCanvas.Font.Style  := [fsBold];
  F2DCanvas.D2DCanvas.Font.Size   := 12;
  F2DCanvas.D2DCanvas.Brush.Style := bsClear;
  F2DCanvas.D2DCanvas.Font.Brush.Handle.SetOpacity(Opacity);
  s := FFileName;
  r := Rect(10, ClientHeight-50, ClientWidth, ClientHeight);
  F2DCanvas.D2DCanvas.TextRect(r, s, [tfPathEllipsis, tfEndEllipsis]);

end;

procedure TPlayerForm.PaintImage(Sender: TObject; Bitmap: TBitmap; const Progress: TRMXPlayerProgress);
const
  DEF_TIME_TEXT_VISIBLE = 2500;
  DEF_MIN_TIME_TEXT_OPACITY = 1000;
var
  opacity: single;
begin
  if FPlayer.Running and IsPanelPlayerVisible then
    begin
      FPlayerSetProgress := true;
      FTRackBar.Max := Progress.frames_max;
      FTRackBar.Min := Progress.frames_min;
      FTRackBar.Position := Progress.frames_pos;
      FPlayerSetProgress := false;
      lblTime.Caption := PlayerTimerToStr(Progress.time_pos, Progress.time_duration);
    end;

  if Progress.frames_pos = Progress.frames_max then
    begin
      if not Assigned(FLastFrame) then
        FLastFrame := TBitmap.Create;
      FLastFrame.Assign(Bitmap);
    end;


  F2DCanvas.D2DCanvas.BeginDraw;

  F2DCanvas.D2DCanvas.StretchDraw(ClientRect, Bitmap);
  if Progress.time_pos < DEF_TIME_TEXT_VISIBLE then
    begin
      opacity := 1.0;
      if Progress.time_pos > DEF_MIN_TIME_TEXT_OPACITY then
        opacity := 1.0 - (Progress.time_pos - DEF_MIN_TIME_TEXT_OPACITY) /
                         (DEF_TIME_TEXT_VISIBLE - DEF_MIN_TIME_TEXT_OPACITY);
      PaintFileNameOnTarget(opacity);
    end;

  F2DCanvas.D2DCanvas.EndDraw;
end;

function TPlayerForm.PlayerTimerToStr(val: Int64): string;
begin
  Result := Format('%2.2d:%2.2d',[val div 1000, (val mod 1000) div 10]);
end;

function TPlayerForm.PlayerTimerToStr(cur, max: Int64): string;
begin
  Result := Format('%2.2d:%2.2d/%2.2d:%2.2d',[cur div 1000, (cur mod 1000) div 10,
                                              max div 1000, (max mod 1000) div 10]);
//  Result := Format('%2.2d:%2.2d/%2.2d:%2.2d', [(cur mod 3600) div 60, (cur mod 3600) mod 60,
//                                               (max mod 3600) div 60, (max mod 3600) mod 60]
end;


procedure TPlayerForm.TrackBarChange(Sender: TObject);
var
  saved_pause: Boolean;
begin
  if not FPlayerSetProgress and FPlayer.Running then
    begin
      saved_pause := FPlayer.Pause;
      FPlayer.Pause := true;
      FPlayer.Position := FTRackBar.Position;
      F2DCanvas.Invalidate;
      FPlayer.Pause := saved_pause;

    end;

end;

procedure TPlayerForm.UpdateUserActions;
begin

  actPlay.Enabled     := not FPlayer.Running and FileExists(FFileName);
  actStop.Enabled     := FPlayer.Running;
  actPause.Enabled    := FPlayer.Running;
  actForward.Enabled  := FPlayer.Running;
  actBackward.Enabled := FPlayer.Running;
  actOpenFile.Enabled := not FPlayer.Running;
  actConvert.Enabled  := not FPlayer.Running;

end;


end.
