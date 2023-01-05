unit uAcceptEula;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ShellApi, Vcl.ExtCtrls;

type
  TfAcceptEULA = class(TForm)
    Panel1: TPanel;
    bOK: TButton;
    bClose: TButton;
    Label6: TLabel;
    Label1: TLabel;
    ePassword: TEdit;
    ePasswordConfirm: TEdit;
    Label3: TLabel;
    Label7: TLabel;
    lEULA: TLabel;
    Label5: TLabel;
    Label8: TLabel;
    procedure lEULAClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure lEULAMouseEnter(Sender: TObject);
    procedure lEULAMouseLeave(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fAcceptEULA: TfAcceptEULA;

implementation

{$R *.dfm}

procedure TfAcceptEULA.bCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Hide;
end;

procedure TfAcceptEULA.bOKClick(Sender: TObject);
begin
  if ePassword.Text <> ePasswordConfirm.Text then
  begin
    MessageBox(Handle, 'Пароль и подтверждение пароля не совпадают', 'Remox', MB_ICONWARNING or MB_OK);
    if Visible then
      ePassword.SetFocus;
    Exit;
  end;

  ModalResult := mrOk;
  Hide;
end;

procedure TfAcceptEULA.lEULAClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://remox.com/eula', '', '', SW_SHOWNORMAL);
end;

procedure TfAcceptEULA.lEULAMouseEnter(Sender: TObject);
begin
  Screen.Cursor := crHandPoint;
end;

procedure TfAcceptEULA.lEULAMouseLeave(Sender: TObject);
begin
  Screen.Cursor := crDefault;
end;

end.
