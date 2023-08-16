unit uMessageBox;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.ExtCtrls, Vcl.StdCtrls, Math, uVircessTypes;

type
  TfMessageBox = class(TForm)
    lText: TLabel;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    procedure bOKClick(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOnCustomFormClose: TOnCustomFormEvent;
  public
    procedure SetText(AText: String);

    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
  end;

var
  fMessageBox: TfMessageBox;

implementation

{$R *.dfm}

procedure TfMessageBox.SetText(AText: String);
begin
  lText.Caption := AText;
end;

procedure TfMessageBox.bCloseClick(Sender: TObject);
begin
  Close;
  ModalResult := mrClose;
end;

procedure TfMessageBox.bOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
  Hide;
end;

procedure TfMessageBox.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose;

  Action := caFree;
end;

end.
