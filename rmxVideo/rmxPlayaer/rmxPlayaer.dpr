program rmxPlayaer;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  FLoatPanelVCL in 'FloatPanel\FLoatPanelVCL.pas',
  AcceleratedPaintBox in 'AcceleratedPaintBox.pas',
  PlayImage in 'PlayImage.pas',
  rtcScrPlayback in '..\..\Lib\rtcScrPlayback.pas',
  ConvertUnit in 'Convert\ConvertUnit.pas' {ConvertForm},
  SimleTrackBar in 'SimleTrackBar.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
