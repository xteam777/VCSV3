unit AboutForm;

interface

uses WinApi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.Imaging.jpeg, uVircessTypes;

type
  TfAboutForm = class(TForm)
    ProgramIcon: TImage;
    Copyright: TLabel;
    Comments: TLabel;
    Version: TLabel;
    ProductName: TLabel;
    bOK: TButton;
    procedure bOKClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
var
  i: Integer;
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose(Handle);

  Action := caFree;
end;

procedure TfAboutForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    bOKClick(Sender);
end;

end.
 
