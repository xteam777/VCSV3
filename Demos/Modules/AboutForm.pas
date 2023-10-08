unit AboutForm;

interface

uses WinApi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.Imaging.jpeg, uVircessTypes, CommonData, Vcl.Imaging.pngimage;

type
  TfAboutForm = class(TForm)
    ProgramIcon: TImage;
    Copyright: TLabel;
    Comments: TLabel;
    lVersion: TLabel;
    ProductName: TLabel;
    bOK: TButton;
    procedure bOKClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FOnCustomFormClose: TOnCustomFormEvent;
  public
    { Public declarations }
    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
  end;

var
  fAboutForm: TfAboutForm;

implementation

{$R *.dfm}

procedure TfAboutForm.bOKClick(Sender: TObject);
begin
  Close;
end;

procedure TfAboutForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose;

  Action := caFree;
end;

procedure TfAboutForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    bOKClick(Sender);
end;

procedure TfAboutForm.FormShow(Sender: TObject);
begin
  lVersion.Caption := 'ver. ' + RMX_VERSION;
end;

end.
 
