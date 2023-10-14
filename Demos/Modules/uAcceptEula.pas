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
    lEULA: TLabel;
    Label5: TLabel;
    GroupBox1: TGroupBox;
    Label8: TLabel;
    Label3: TLabel;
    Label7: TLabel;
    ePasswordConfirm: TEdit;
    ePassword: TEdit;
    cbAutomaticUpdate: TCheckBox;
    procedure lEULAClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure lEULAMouseEnter(Sender: TObject);
    procedure lEULAMouseLeave(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ePasswordChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    PasswordChanged: Boolean;
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

procedure TfAcceptEULA.ePasswordChange(Sender: TObject);
begin
  PasswordChanged := True;
end;

procedure TfAcceptEULA.FormShow(Sender: TObject);
begin
  ePassword.SetFocus;
end;

procedure TfAcceptEULA.lEULAClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'https://remox.com/eula', '', '', SW_SHOWNORMAL);
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
