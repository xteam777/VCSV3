unit uAcceptEula;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ShellApi;

type
  TfAcceptEULA = class(TForm)
    bOK: TButton;
    bClose: TButton;
    Label6: TLabel;
    Label1: TLabel;
    ePassword: TEdit;
    ePasswordConfirm: TEdit;
    Label3: TLabel;
    Label7: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label8: TLabel;
    procedure Label4Click(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
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

procedure TfAcceptEULA.Label4Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://remox.com/eula', '', '', SW_SHOWNORMAL);
end;

end.
