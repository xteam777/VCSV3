unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, LockFormUnit;

type
  TMainForm = class(TForm)
    btnMake: TButton;
    btnReset: TButton;
    chkDisableInput: TCheckBox;
    btnClose: TButton;
    edPercent: TEdit;
    btnDisableRecord: TButton;
    btnSHowForm: TButton;
    btnShowModal: TButton;
    procedure btnMakeClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnDisableRecordClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnSHowFormClick(Sender: TObject);
    procedure btnShowModalClick(Sender: TObject);
  private
    { Private declarations }
    FLockForm: TLockForm;
  protected
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}



procedure TMainForm.btnCloseClick(Sender: TObject);
begin
  if Assigned(FLockForm) then
    begin
      FLockForm.Close;
    end;
end;

procedure TMainForm.btnDisableRecordClick(Sender: TObject);
begin
  if not Assigned(FLockForm) then
    FLockForm := TLockForm.Create(Self);
  FLockForm.Show;
  FLockForm.DisableWindowForRecord(true);
end;

procedure TMainForm.btnMakeClick(Sender: TObject);
begin
  if not Assigned(FLockForm) then
    FLockForm := TLockForm.Create(Self) else
    FLockForm.ResetLayeredWindow;
  FLockForm.Show;
  FLockForm.ApplyLayeredWindow(chkDisableInput.Checked, StrToInt(edPercent.Text));

end;

procedure TMainForm.btnResetClick(Sender: TObject);
begin
  if Assigned(FLockForm) then
    begin
      FLockForm.ResetLayeredWindow;
      FLockForm.DisableWindowForRecord(false);
    end;
end;


procedure TMainForm.btnSHowFormClick(Sender: TObject);
begin
  if not Assigned(FLockForm) then
    FLockForm := TLockForm.Create(Self);
  FLockForm.Show;
end;

procedure TMainForm.btnShowModalClick(Sender: TObject);
begin
  if not Assigned(FLockForm) then
    FLockForm := TLockForm.Create(Self);
  FLockForm.ShowModal;
end;

end.
