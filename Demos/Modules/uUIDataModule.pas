unit uUIDataModule;

interface

uses
  Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics, rtcpFileTrans, rtcpFileTransUI,
  rtcpDesktopControl, rtcpDesktopControlUI, ChromeTabsClasses, rtcPortalMod,
  Vcl.ExtCtrls, uVircessTypes, VideoRecorder, rmxVideoStorage;

type
  PImage = ^TImage;
  PLabel = ^TLabel;

  PUIDataModule = ^TUIDataModule;
  TUIDataModule = class(TDataModule)
    UI: TRtcPDesktopControlUI;
    FT_UI: TRtcPFileTransferUI;
    PFileTrans: TRtcPFileTransfer;
    TimerReconnect: TTimer;
    TimerRec: TTimer;
    procedure TimerReconnectTimer(Sender: TObject);
  protected
    procedure WndProc(var Message: TMessage); virtual;
  private
    { Private declarations }
    FHandle: THandle;
  public
    { Public declarations }
    pImage: PRtcPDesktopViewer;
    UserName, UserDesc, UserPass: String;
    FVideoRecorder: TVideoRecorder;
    FVideoWriter: TRMXVideoWriter;
    FVideoFile: String;
    FImageChanged: Boolean;
    FVideoImage: TBitmap;
    FLockVideoImage: Integer;
    FFirstImageArrived: Boolean;
    PartnerLockedState: Integer;
    PartnerServiceStarted: Boolean;
    ReconnectToPartnerStart: TReconnectToPartnerStart;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Handle: THandle read FHandle;
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

procedure TUIDataModule.WndProc(var Message: TMessage);
begin
//  if(Message.Msg = UM_TEST) then
//  begin
//    ShowMessage('Test');
//  end;
end;

constructor TUIDataModule.Create(AOwner: TComponent);
begin
  inherited;

  FHandle := AllocateHWND(WndProc);

  New(pImage);

  TimerReconnect.Enabled := False;
end;

destructor TUIDataModule.Destroy;
begin
  TimerReconnect.Enabled := False;
  TimerRec.Enabled := False;

  DeallocateHWND(FHandle);
  FreeAndNil(pImage^);

  Dispose(pImage);

  inherited;
end;

end.
