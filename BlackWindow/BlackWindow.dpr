program BlackWindow;

uses
  Vcl.Forms,
  LockFormUnit in 'LockFormUnit.pas' {LockForm},
  MainUnit in 'MainUnit.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
