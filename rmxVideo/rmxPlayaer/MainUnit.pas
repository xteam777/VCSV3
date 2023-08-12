unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  FLoatPanelVCL, Vcl.Buttons, AcceleratedPaintBox, PlayImage, System.Actions,
  Vcl.ActnList, Vcl.ComCtrls, ConvertUnit;

type
  TMainForm = class(TForm)
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
    tbPlay: TTrackBar;
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
  private
    { Private declarations }
    FFLoatPanel: TFloatPanelVCL;
    F2DCanvas: TCustomAcceleratedPaintBox;
    FPlayer: TPlayerHandler;
    FFileName: string;
    FLastFrame: TBitmap;
    procedure PaintImage(Sender: TObject; Bitmap: TBitmap; const Progress: TRMXPlayerProgress);
    procedure OnApplyRegion(Sender: TObject; ctrl: TControl; var r: TRect);
    procedure ResetFocusTrackBar;
    function PlayerTimerToStr(cur, max: Int64): string;
    function IsPanelPlayerVisible: Boolean;
    procedure OnPaintPaintBox(Sender: TObject);
    procedure UpdateActions;
    procedure PaintFileNameOnTarget(Opacity: Single);
  public
    { Public declarations }
    procedure OnPanelSlideFinish(Sender: TObject);
    property FileName: string read FFileName write FFileName;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.actConvertExecute(Sender: TObject);
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

procedure TMainForm.actOpenFileExecute(Sender: TObject);

begin
  if FileOpenDialog.Execute then
    begin
      FFileName := FileOpenDialog.FileName;
      UpdateActions;
    end;
end;

procedure TMainForm.actPauseExecute(Sender: TObject);
begin
  FPlayer.Pause := not FPlayer.Pause;
  UpdateActions;
end;

procedure TMainForm.actStopExecute(Sender: TObject);
begin
  FPlayer.Stop;
  UpdateActions;
end;

procedure TMainForm.btnPlayClick(Sender: TObject);
begin
  FPlayer.Stop;
  FPlayer.Play(FFileName);
  UpdateActions;
end;

procedure TMainForm.btnSlideClick(Sender: TObject);
begin
  FFLoatPanel.StopValue := FFLoatPanel.Top - (pnlCommon.Height * FFLoatPanel.Tag);
  FFLoatPanel.StartAnimate;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
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
  F2DCanvas.D2DCanvas.Clear($00001932);


  FPlayer          := TPlayerHandler.Create;
  FPlayer.OnFrame  := PaintImage;

  FFLoatPanel.OnApplyRegion := OnApplyRegion;
  {$ifdef DEBUG}
    FFLoatPanel.DrawFrame := true;
    FFileName := 'Video_2023_07_30_005708.rmxv';
    FFileName := 'k:\PROJECTS\RMX_FM\other_trash\RMX_FM-rec_desk\rmxVideo\bin\Video_2023_07_30_005708.rmxv';
  {$endif}
  FFLoatPanel.ApplyRegions;
  FFLoatPanel.BringToFront;

  ResetFocusTrackBar;
  UpdateActions;

end;


procedure TMainForm.FormDestroy(Sender: TObject);
begin
  F2DCanvas.Free;
  FPlayer.Free;
  FLastFrame.Free;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  FFLoatPanel.Left := (ClientWidth + FFLoatPanel.Width) div 2 - FFLoatPanel.Width;
end;

function TMainForm.IsPanelPlayerVisible: Boolean;
begin
  Result := (FFLoatPanel.Tag > 0) or FFLoatPanel.Running;
end;

procedure TMainForm.OnApplyRegion(Sender: TObject; ctrl: TControl;
  var r: TRect);
begin
  // check if Button, reduce 1 pixel
 // if (ctrl = btnSlide) then
    InflateRect(r, -1, -1);

end;

procedure TMainForm.OnPaintPaintBox(Sender: TObject);
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

procedure TMainForm.OnPanelSlideFinish(Sender: TObject);
begin
  FFLoatPanel.Tag := - FFLoatPanel.Tag;
  if FFLoatPanel.Tag < 0 then
    btnSlide.Caption := '6'
    else
    btnSlide.Caption := '5'
end;

procedure TMainForm.PaintFileNameOnTarget(Opacity: Single);
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

procedure TMainForm.PaintImage(Sender: TObject; Bitmap: TBitmap; const Progress: TRMXPlayerProgress);
const
  DEF_TIME_TEXT_VISIBLE = 2500;
  DEF_MIN_TIME_TEXT_OPACITY = 1000;
var
  opacity: single;
begin
  if FPlayer.Running and IsPanelPlayerVisible then
    begin
      tbPlay.Max := Progress.frames_max;
      tbPlay.Min := Progress.frames_min;
      tbPlay.Position := Progress.frames_pos;
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

function TMainForm.PlayerTimerToStr(cur, max: Int64): string;
begin
  Result := Format('%2.2d:%2.2d/%2.2d:%2.2d',[cur div 1000, (cur mod 1000) div 10,
                                              max div 1000, (max mod 1000) div 10]);
//  Result := Format('%2.2d:%2.2d/%2.2d:%2.2d', [(cur mod 3600) div 60, (cur mod 3600) mod 60,
//                                               (max mod 3600) div 60, (max mod 3600) mod 60]
end;

procedure TMainForm.ResetFocusTrackBar;
begin
  SendMessage(tbPlay.Handle, WM_UPDATEUISTATE, UIS_CLEAR OR UISF_HIDEFOCUS, 0);
end;

procedure TMainForm.UpdateActions;
begin

  actPlay.Enabled     := not FPlayer.Running and FileExists(FFileName);
  actStop.Enabled     := FPlayer.Running;
  actPause.Enabled    := FPlayer.Running;
  actOpenFile.Enabled := not FPlayer.Running;
  actConvert.Enabled  := not FPlayer.Running;

end;

end.
