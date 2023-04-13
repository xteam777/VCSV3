unit MultiFileTrans;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  rtcpFileTrans, rtcpFileTransUI{, CodeSiteLogging};

type

  TVisualEventUI = class
  private
    FFile: TRtcPFileTransferUI;
    FTrans: TRtcPFileTransfer;
    FFileName, FFolder: string;
  public
    constructor Create();
    destructor Destroy; override;
    procedure OnCallReceived(Sender: TRtcPFileTransferUI);
    procedure OnClose(Sender: TRtcPFileTransferUI);
    procedure OnError(Sender: TRtcPFileTransferUI);
    procedure OnFileList(Sender: TRtcPFileTransferUI);
    procedure OnInit(Sender: TRtcPFileTransferUI);
    procedure OnLogOut(Sender: TRtcPFileTransferUI);
    procedure OnOpen(Sender: TRtcPFileTransferUI);
    procedure OnRecv(Sender: TRtcPFileTransferUI);
    procedure OnRecvCancel(Sender: TRtcPFileTransferUI);
    procedure OnRecvStart(Sender: TRtcPFileTransferUI);
    procedure OnRecvStop(Sender: TRtcPFileTransferUI);
    procedure OnSend(Sender: TRtcPFileTransferUI);
    procedure OnSendCancel(Sender: TRtcPFileTransferUI);
    procedure OnSendStart(Sender: TRtcPFileTransferUI);
    procedure OnSendStop(Sender: TRtcPFileTransferUI);
    procedure OnSendUpdate(Sender: TRtcPFileTransferUI);

    procedure TransNewUI(Sender: TRtcPFileTransfer; const user: String);
  end;

  procedure SendMFile(const AFileName, AFolder: string; cloned: TRtcAbsPFileTransferUI);
implementation

procedure OutPutLog(const LogFmt: string; const Args: array of const);
var
  s: string;
begin
  if Length(Args) > 0 then
    s := Format(LogFmt, Args) else
    s := LogFmt;
  OutputDebugString(PChar(s));
end;

procedure SendMFile(const AFileName, AFolder: string; cloned: TRtcAbsPFileTransferUI);
var
  send: TVisualEventUI;
begin
  send := TVisualEventUI.Create;
  try
    send.FFileName := AFileName;
    send.FFolder := AFolder;
    send.FTrans.FileInboxPath  := cloned.Module.FileInboxPath;
    send.FTrans.Client := cloned.Module.Client;
    send.FTrans.Open(cloned.UserName, cloned.Module.UIVisible);

  send.FFile.UserName := cloned.UserName;
  send.FFile.Module := send.FTrans;
  send.FFile.send(AFileName, AFolder);



    if send <> nil then
      begin
        send := nil;
      end;
  finally
//    send.Free;
  end;
end;

{ TVisualEventUI }

constructor TVisualEventUI.Create;
begin
  inherited;
  FFile := TRtcPFileTransferUI.Create(nil);
  FFile.OnInit         := OnInit;
  FFile.OnOpen         := OnOpen;
  FFile.OnClose        := OnClose;
  FFile.OnError        := OnError;
  FFile.OnLogOut       := OnLogOut;
  FFile.OnSendStart    := OnSendStart;
  FFile.OnSend         := OnSend;
  FFile.OnSendUpdate   := OnSendUpdate;
  FFile.OnSendStop     := OnSendStop;
  FFile.OnSendCancel   := OnSendCancel;
  FFile.OnRecvStart    := OnRecvStart;
  FFile.OnRecv         := OnRecv;
  FFile.OnRecvStop     := OnRecvStop;
  FFile.OnRecvCancel   := OnRecvCancel;
  FFile.OnCallReceived := OnCallReceived;
  FFile.OnFileList     := OnFileList;

  FTrans := TRtcPFileTransfer.Create(nil);
  FTrans.OnNewUI               := TransNewUI;
  FTrans.AccessControl         := true;
  FTrans.GAllowDownload        := true;
  FTrans.GAllowBrowse_Super    := true;
  FTrans.GAllowUpload          := true;
  FTrans.GAllowUpload_Super    := true;
  FTrans.GUploadAnywhere       := true;
  FTrans.GUploadAnywhere_Super := true;

end;

destructor TVisualEventUI.Destroy;
begin
  FFile.Free;
  FTrans.Free;
  inherited;
end;

procedure TVisualEventUI.OnCallReceived(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnCallReceived ', []);
end;

procedure TVisualEventUI.OnClose(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnClose ', []);
end;

procedure TVisualEventUI.OnError(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnError ', []);
end;

procedure TVisualEventUI.OnFileList(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnFileList ', []);
end;

procedure TVisualEventUI.OnInit(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnInit ', []);
end;

procedure TVisualEventUI.OnLogOut(Sender: TRtcPFileTransferUI);
begin
OutPutLog('TVisualEventUI.OnLogOut ', []);
end;

procedure TVisualEventUI.OnOpen(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnOpen ', []);
end;

procedure TVisualEventUI.OnRecv(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnRecv ', []);
end;

procedure TVisualEventUI.OnRecvCancel(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnRecvCancel ', []);
end;

procedure TVisualEventUI.OnRecvStart(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnRecvStart ', []);
end;

procedure TVisualEventUI.OnRecvStop(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnRecvStop ', []);
end;

procedure TVisualEventUI.OnSend(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnSend: ->'+ sLineBreak +
  '  FileName: %s '+ sLineBreak +
  '  FromFolder: %s '+ sLineBreak +
  '  FileOut: %d '+ sLineBreak +
  '  FileSize: %d '+ sLineBreak +

  '  FileCount: %d '+ sLineBreak +
  '  FirstTime: %s '+ sLineBreak +
  '  StartTime: %d '+ sLineBreak +
  '  BytesComplete: %d '+ sLineBreak +
  '  BytesPrepared: %d '+ sLineBreak +
  '  BytesTotal: %d '+ sLineBreak +
  '  KBit: %d '+ sLineBreak +
  '  ETA: %s '+ sLineBreak +
  '  TotalTime: %s' + sLineBreak+
  ' < ---',
    [
      Sender.Send_FileName,
      Sender.Send_FromFolder,
      Sender.Send_FileOut,
      Sender.Send_FileSize,
      Sender.Send_FileCount,
      BoolToStr(Sender.Send_FirstTime, true),
      Sender.Send_StartTime,
      Sender.Send_BytesComplete,
      Sender.Send_BytesPrepared,
      Sender.Send_BytesTotal,
      Sender.Send_KBit,
      Sender.Send_ETA,
      Sender.Send_TotalTime
    ]);
end;

procedure TVisualEventUI.OnSendCancel(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnSendCancel ', []);
end;

procedure TVisualEventUI.OnSendStart(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnSendStart ', []);
end;

procedure TVisualEventUI.OnSendStop(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnSendStop ', []);
end;

procedure TVisualEventUI.OnSendUpdate(Sender: TRtcPFileTransferUI);
begin
  OutPutLog('TVisualEventUI.OnSendUpdate ', []);
end;

procedure TVisualEventUI.TransNewUI(Sender: TRtcPFileTransfer;
  const user: String);
begin
  FFile.UserName := user;
  FFile.Module := Sender;
//  FFile.send(FFileName, FFolder);
end;

end.
