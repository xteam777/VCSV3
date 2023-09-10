unit uUIDataModule;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, rtcpFileTrans, rtcpFileTransUI,
  rtcpDesktopControl, rtcpDesktopControlUI, ChromeTabsClasses, rtcPortalMod,
  Vcl.ExtCtrls, uVircessTypes;

type
  PUIDataModule = ^TUIDataModule;
  TUIDataModule = class(TDataModule)
    UI: TRtcPDesktopControlUI;
    FT_UI: TRtcPFileTransferUI;
    PFileTrans: TRtcPFileTransfer;
    TimerReconnect: TTimer;
    procedure TimerReconnectTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    pImage: PRtcPDesktopViewer;
    UserName, UserDesc, UserPass: String;
    ReconnectToPartnerStart: TReconnectToPartnerStart;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  UIDataModule: TUIDataModule;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TUIDataModule.TimerReconnectTimer(Sender: TObject);
begin
  ReconnectToPartnerStart(UserName, UserDesc, UserPass,  'desk');
end;

constructor TUIDataModule.Create(AOwner: TComponent);
begin
  inherited;

  New(pImage);

  TimerReconnect.Enabled := False;
end;

destructor TUIDataModule.Destroy;
begin
  FreeAndNil(pImage^);
  Dispose(pImage);

  inherited;

//  UI.Viewer := nil;
//  UI.Module := nil;
//  FT_UI.Module := nil;
//  PFileTrans.Client := nil;

//  UI.Free;
//  FT_UI.Free;
//  PFileTrans.Free;
//  pImage.Free;
end;

end.
