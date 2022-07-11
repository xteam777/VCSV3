unit RtcGroupForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.ExtCtrls, Vcl.StdCtrls, rtcCliModule,
  rtcInfo, rtcConn, rtcFunction, Vcl.ComCtrls, VirtualTrees, Vcl.AppEvnts, uVircessTypes,
  rtcSystem;

type
  TGroupForm = class(TForm)
    Label6: TLabel;
    eName: TEdit;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    rAddGroup: TRtcResult;
    rChangeGroup: TRtcResult;
    ApplicationEvents1: TApplicationEvents;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bOKClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure rAddGroupReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure rChangeGroupReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FOnCustomFormClose: TOnCustomFormEvent;
  public
    { Public declarations }
    CModule: TRtcClientModule;
    twDevices: TVirtualStringTree;
    Mode: String;
    UID: String;
    AccountUID: String;

    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
  end;

var
  GroupForm: TGroupForm;

implementation

{$R *.dfm}

procedure TGroupForm.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  case Msg.message of
  WM_KEYDOWN:
    case Msg.wParam of
      VK_RETURN:
        begin
          Handled := True;
        end;
      VK_ESCAPE:
        begin
          Handled := True;
        end;
      15:
        Handled := True
    end;
  WM_KEYUP:
    case Msg.wParam of
      VK_RETURN:
        begin
          bOKClick(nil);
          Handled := True;
        end;
      VK_ESCAPE:
        begin
          bCloseClick(nil);
          Handled := True;
        end;
      15:
        Handled := True
    end;
  end;
end;

procedure TGroupForm.bCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Close;
end;

procedure TGroupForm.bOKClick(Sender: TObject);
begin
  if Trim(eName.Text) = '' then
  begin
    MessageBox(Handle, '�� ������� �������� ������', 'VIRCESS', MB_ICONWARNING or MB_OK);
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
  end;

  ModalResult := mrOk;
  Close;
end;

procedure TGroupForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose(Handle);
end;

procedure TGroupForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Mgs: TMsg;
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);

  if Key = VK_RETURN then
    bOKClick(Sender)
  else if Key = VK_ESCAPE then
    bCloseClick(Sender);
end;

procedure TGroupForm.FormShow(Sender: TObject);
begin
  eName.SetFocus;
end;

procedure TGroupForm.rAddGroupReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  UID := Result.asString;
  ModalResult := mrOk;
  Close;
end;

procedure TGroupForm.rChangeGroupReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  ModalResult := mrOk;
  Close;
end;

end.
