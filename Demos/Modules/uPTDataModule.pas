unit uPTDataModule;

interface

uses
  System.SysUtils, System.Classes, rtcSystem, rtcInfo, rtcConn, rtcFunction,
  Vcl.ExtCtrls, rtcPortalMod, rtcPortalCli, rtcPortalHttpCli;

type
  TPTDataModule = class(TDataModule)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PTDataModule: TPTDataModule;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
