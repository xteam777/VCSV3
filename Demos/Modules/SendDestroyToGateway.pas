unit SendDestroyToGateway;

interface

uses
  Classes, SysUtils, rtcHTTPCli, rtcCliModule, rtcConn, rtcFunction, rtcInfo;

type
  TSendDestroyClientToGatewayThread = class(TThread)
  private
    FGateway: String;
    FClientName: String;
    FAllConnectionsById: Boolean;
    rtcClient: TRtcHttpClient;
    rtcModule: TRtcClientModule;
    rtcRes: TRtcResult;
    FResultGot: Boolean;
    { Private declarations }
  protected
    procedure Execute; override;
//    procedure ProcessMessage(MSG: TMSG);
    procedure rtcResReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure rtcResRequestAborted(Sender: TRtcConnection; Data, Result: TRtcValue);
  public
    constructor Create(CreateSuspended: Boolean; AGateway, AClientName: String; AAllConnectionsById, UseProxy: Boolean; ProxyAddr, ProxyUserName, ProxyPassword: String); overload;
    destructor Destroy; override;
  end;

implementation

constructor TSendDestroyClientToGatewayThread.Create(CreateSuspended: Boolean; AGateway, AClientName: String; AAllConnectionsById, UseProxy: Boolean; ProxyAddr, ProxyUserName, ProxyPassword: String);
begin
  inherited Create(CreateSuspended);

  FreeOnTerminate := True;

  FGateway := AGateway;
  FClientName := AClientName;
  FAllConnectionsById := AAllConnectionsById;

  FResultGot := False;

  try
    rtcClient := TRtcHttpClient.Create(nil);
    rtcClient.AutoConnect := True;
    rtcClient.MultiThreaded := False;
    if Pos(':', AGateway) > 0 then
      rtcClient.ServerAddr := Copy(AGateway, 1, Pos(':', AGateway) - 1)
    else
      rtcClient.ServerAddr := AGateway;
    rtcClient.ServerPort := '9000';
    rtcClient.Blocking := False;
    rtcClient.UseWinHttp := True;
    rtcClient.ReconnectOn.ConnectError := True;
    rtcClient.ReconnectOn.ConnectFail := True;
    rtcClient.ReconnectOn.ConnectLost := True;
    rtcClient.UseProxy := UseProxy;
    rtcClient.UserLogin.ProxyAddr := ProxyAddr;
    rtcClient.UserLogin.ProxyUserName := ProxyUserName;
    rtcClient.UserLogin.ProxyPassword := ProxyPassword;
    rtcClient.Connect();

    rtcModule := TRtcClientModule.Create(nil);
    rtcModule.Client := rtcClient;
    rtcModule.AutoRepost := 2;
    rtcModule.AutoSyncEvents := True;
    rtcModule.ModuleFileName := '/portalgategroup';
    rtcModule.SecureKey := '2240897';
    rtcModule.ForceEncryption := True;
    rtcModule.EncryptionKey := 16;
    rtcModule.Compression := cMax;

    rtcRes := TRtcResult.Create(nil);
    rtcRes.OnReturn := rtcResReturn;
    rtcRes.RequestAborted := rtcResRequestAborted;

    with rtcModule do
    try
      with Data.NewFunction('Clients.Destroy') do
      begin
        asString['UserName'] := AClientName;
        asBoolean['AllConnectionsById'] := AAllConnectionsById;
        Call(rtcRes);
//        WaitForCompletion(True, 10);
      end;
    except
      on E: Exception do
        Data.Clear;
    end;
  finally
  end;
end;

destructor TSendDestroyClientToGatewayThread.Destroy;
begin
  try
    rtcClient.Disconnect;
  finally
  end;
  try
    rtcModule.Free;
  finally
  end;
  try
    rtcClient.Free;
  finally
  end;
  try
    rtcRes.Free;
  finally
  end;
end;

procedure TSendDestroyClientToGatewayThread.Execute;
//var
//  msg: TMsg;
//  i: Integer;
begin
  while (not Terminated)
    and (not FResultGot) do
  begin
    Sleep(1)
  end;

//  for i := 0 to 10 do
//  begin
//    Application.ProcessMessages;
//    Sleep(1000);
//  end;
end;

{procedure TSendDestroyClientToGatewayThread.ProcessMessage(MSG: TMSG);
var
  Message: TMessage;
begin
  Message.Msg := Msg.message;
  Message.WParam := MSG.wParam;
  Message.LParam := MSG.lParam;
  Message.Result := 0;
  Dispatch(Message);
end;}

procedure TSendDestroyClientToGatewayThread.rtcResReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  FResultGot := True;
end;

procedure TSendDestroyClientToGatewayThread.rtcResRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  FResultGot := True;
end;

end.
