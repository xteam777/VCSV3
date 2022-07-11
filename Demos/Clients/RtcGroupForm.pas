unit RtcGroupForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.ExtCtrls, Vcl.StdCtrls, rtcCliModule,
  rtcInfo, rtcConn, rtcFunction, Vcl.ComCtrls, VirtualTrees;

type
  TGroupForm = class(TForm)
    Label6: TLabel;
    eName: TEdit;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    Panel2: TPanel;
    rAddGroup: TRtcResult;
    rChangeGroup: TRtcResult;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bOKClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure rAddGroupReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure rChangeGroupReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
  private
    { Private declarations }
  public
    { Public declarations }
    CModule: TRtcClientModule;
    twDevices: TVirtualStringTree;
    ActionResult: TModalResult;
    Mode: String;
    UID: String;
    AccountUID: String;
  end;

var
  GroupForm: TGroupForm;

implementation

{$R *.dfm}

procedure TGroupForm.bCloseClick(Sender: TObject);
begin
  ActionResult := mrCancel;
  Close;
end;

procedure TGroupForm.bOKClick(Sender: TObject);
begin
  if Trim(eName.Text) = '' then
  begin
    MessageBox(Handle, 'Не указано название группы', 'VIRCESS', MB_ICONWARNING or MB_OK);
    eName.SetFocus;
    Exit;
  end;

  if Mode = 'Add' then
  begin
    with CModule.Data.NewFunction('Account.AddGroup') do
    begin
      asWideString['Name'] := eName.Text;
      asString['AccountUID'] := AccountUID;
    end;
    CModule.Call(rAddGroup);
  end
  else
  begin
    with CModule.Data.NewFunction('Account.ChangeGroup') do
    begin
      asWideString['Name'] := eName.Text;
      asString['UID'] := UID;
      asString['AccountUID'] := AccountUID;
    end;
    CModule.Call(rChangeGroup);
  end
end;

procedure TGroupForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    bOK.Click
  else if Key = VK_ESCAPE then
    bClose.Click;
end;

procedure TGroupForm.FormShow(Sender: TObject);
begin
  eName.SetFocus;
end;

procedure TGroupForm.rAddGroupReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  UID := Result.asString;
  ActionResult := mrOk;
  Close;
end;

procedure TGroupForm.rChangeGroupReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  ActionResult := mrOk;
  Close;
end;

end.
