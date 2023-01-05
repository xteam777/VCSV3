unit uAccepsEula;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfAcceptEULA = class(TForm)
    bOK: TButton;
    bClose: TButton;
    Label6: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    ePassword: TEdit;
    ePasswordConfirm: TEdit;
    Label3: TLabel;
    Label7: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fAcceptEULA: TfAcceptEULA;

implementation

{$R *.dfm}

end.
