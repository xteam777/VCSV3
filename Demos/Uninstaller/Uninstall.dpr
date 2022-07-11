program Uninstall;

{$R *.dres}

uses
  Vcl.Forms,
  Windows,
  uMain in 'uMain.pas' {fMain};

{$R *.res}

function VircessIsRunned: Boolean;
begin
  Result := False;
end;

begin
  if VircessIsRunned then
  begin
    while True do
    begin
      case MessageBox(0, 'Перед установкой необходимо закрыть Vircess', 'Установка Vircess', MB_RETRYCANCEL) of
        ID_CANCEL:
          Exit;
        ID_RETRY:
          if not VircessIsRunned then
            Exit;         
      end;      
    end;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
