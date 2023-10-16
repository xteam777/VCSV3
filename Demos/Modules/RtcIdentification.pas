unit RtcIdentification;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.jpeg, uVircessTypes,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.AppEvnts, Vcl.Imaging.pngimage;

type
  TfIdentification = class(TForm)
    Image1: TImage;
    Label4: TLabel;
    Label6: TLabel;
    ePassword: TEdit;
    ApplicationEvents1: TApplicationEvents;
    bOK: TButton;
    bClose: TButton;
    procedure FormShow(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure ePasswordKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FOnCustomFormClose: TOnCustomFormEvent;
    FOnCloseForm: TNotifyEvent;
  public
    { Public declarations }
    UserName, UserDesc, Action: String;
    Active: Boolean;
    ThreadId: Cardinal;

    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
    property OnCloseForm: TNotifyEvent read FOnCloseForm write FOnCloseForm;
  end;

var
  fIdentification: TfIdentification;

implementation

{$R *.dfm}

procedure TfIdentification.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  if Msg.message = WM_KEYUP then
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
        Handled := True;
    end;
end;

procedure TfIdentification.bCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Close;
end;

procedure TfIdentification.bOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
  Close;
end;

procedure TfIdentification.ePasswordKeyDown(Sender: TObject; var Key: Word;
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

procedure TfIdentification.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose;

  FOnCloseForm(Self);
end;

procedure TfIdentification.FormCreate(Sender: TObject);
begin
  Active := False;
end;

procedure TfIdentification.FormShow(Sender: TObject);
begin
  ePassword.SetFocus;
  ePassword.SelectAll;
end;

end.
