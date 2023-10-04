unit uUIDataModule;

interface

uses
  Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics, rtcpFileTrans, rtcpFileTransUI,
  rtcpDesktopControl, rtcpDesktopControlUI, ChromeTabsClasses, rtcPortalMod, Vcl.ComCtrls, Vcl.Forms,
  Vcl.ExtCtrls, uVircessTypes, VideoRecorder, rmxVideoStorage, CommonData, ProgressDialog;

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
    procedure FT_UIClose(Sender: TRtcPFileTransferUI);
    procedure FT_UILogOut(Sender: TRtcPFileTransferUI);
    procedure FT_UINotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend);
  protected
    FProgressDialogsList: TList;
    FLastActiveExplorerHandle: THandle;
    procedure WndProc(var Message: TMessage); virtual;
    procedure GetFilesFromHostClipboard(var Message: TMessage); //message WM_GET_FILES_FROM_CLIPBOARD;
    function AddProgressDialog(ATaskId: TTaskId; AUserName: String): PProgressDialogData;
    function GetProgressDialogData(ATaskId: TTaskId): PProgressDialogData; overload;
    function GetProgressDialogData(AProgressDialog: PProgressDialog): PProgressDialogData; overload;
    procedure RemoveProgressDialog(ATaskId: TTaskId);
    procedure RemoveProgressDialogByValue(AProgressDialog: PProgressDialog);
    procedure RemoveProgressDialogByUserName(AUserName: String);
    procedure OnProgressDialogCancel(Sender: TObject);
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
//    RestoreBackgroundOnExit: Boolean;
    LockSystemOnClose, ShowRemoteCursor, SendShortcuts, BlockKeyboardMouse, PowerOffMonitor, StretchScreen, HideWallpaper: Boolean;
    DisplaySetting: Integer;
    NeedFree: Boolean;
    ThreadID: Cardinal;
    pMainForm: PForm;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Handle: THandle read FHandle;
  end;

var
  UIDataModule: TUIDataModule;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TUIDataModule.FT_UINotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend);
var
  pPDData: PProgressDialogData;
begin
//  Memo1.Lines.Add(IntToStr(Sender.Recv_FileCount) + ' - ' + Sender.Recv_FileName + ' - ' + IntToStr(Sender.Recv_BytesComplete) + ' - '+ IntToStr(Sender.Recv_BytesTotal));

  if task.Direction <> dbtFetch then
    Exit;

  case mode of
    mbsFileStart, mbsFileData, mbsFileStop:
    begin
      pPDData := GetProgressDialogData(task.Id);
      if pPDData = nil then
        Exit;

      pPDData^.ProgressDialog^.TextLine1 := task.Files[task.Current].file_path;

      pPDData^.ProgressDialog^.Position := Round(task.Progress * 100);

//      if task.size > 1024 * 1024 * 1024 then
//        FProgressDialog.TextFooter := FormatFloat('0.00', task.SentSize / (1024 * 1024 * 1024)) + ' GB из ' + FormatFloat('0.00', task.size / (1024 * 1024 * 1024)) + ' GB'
//      else
//      if Sender.Recv_BytesTotal > 1024 * 1024 then
//        FProgressDialog.TextFooter := FormatFloat('0.00', task.SentSize / (1024 * 1024)) + ' MB из ' + FormatFloat('0.00', task.size / (1024 * 1024)) + ' MB'
//      else
//        FProgressDialog.TextFooter := FormatFloat('0.00', task.SentSize / 1024) + ' KB из ' + FormatFloat('0.00', task.size / 1024) + ' KB';
    end;
    mbsTaskStart:
    begin
//      New(FProgressDialog);
      pPDData := AddProgressDialog(task.Id, task.User);

      pPDData^.ProgressDialog^.Title := 'Копирование';
      pPDData^.ProgressDialog^.CommonAVI := TCommonAVI.aviCopyFiles;
      pPDData^.ProgressDialog^.TextLine1 := task.Files[task.Current].file_path;
      pPDData^.ProgressDialog^.TextLine2 := task.LocalFolder;
      pPDData^.ProgressDialog^.Max := 100;
      pPDData^.ProgressDialog^.Position := 0;
      pPDData^.ProgressDialog^.TextCancel := 'Прерывание...';
      pPDData^.ProgressDialog^.OnCancel := OnProgressDialogCancel;
      pPDData^.ProgressDialog^.AutoCalcFooter := True;
      pPDData^.ProgressDialog^.fHwndParent := FLastActiveExplorerHandle;
      pPDData^.ProgressDialog^.Execute;
    end;
    mbsTaskFinished:
    begin
      pPDData := GetProgressDialogData(task.Id);
      if pPDData = nil then
        Exit;

      pPDData^.ProgressDialog^.Stop;
      RemoveProgressDialog(task.Id);
    end;
    mbsTaskError:
    begin
      pPDData := GetProgressDialogData(task.Id);
      if pPDData = nil then
        Exit;

      pPDData^.ProgressDialog^.Stop;
      RemoveProgressDialog(task.Id);
    end;
  end;


//  if Sender.Recv_BytesTotal = Sender.Recv_BytesComplete then
//    FProgressDialog.Stop;
end;

procedure TUIDataModule.FT_UIClose(Sender: TRtcPFileTransferUI);
begin
  RemoveProgressDialogByUserName(Sender.UserName);
end;

procedure TUIDataModule.FT_UILogOut(Sender: TRtcPFileTransferUI);
begin
  RemoveProgressDialogByUserName(Sender.UserName);
end;

function TUIDataModule.AddProgressDialog(ATaskId: TTaskId; AUserName: String): PProgressDialogData;
begin
  New(Result);
  Result^.taskId := ATaskId;
  New(Result^.ProgressDialog);
  Result^.ProgressDialog^ := TProgressDialog.Create(Owner);
  Result^.UserName := AUserName;

  FProgressDialogsList.Add(Result);
end;

function TUIDataModule.GetProgressDialogData(ATaskId: TTaskId): PProgressDialogData;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to FProgressDialogsList.Count - 1 do
    if PProgressDialogData(FProgressDialogsList[i])^.taskId = ATaskId then
    begin
      Result := FProgressDialogsList[i];
      Exit;
    end;
end;

function TUIDataModule.GetProgressDialogData(AProgressDialog: PProgressDialog): PProgressDialogData;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to FProgressDialogsList.Count - 1 do
    if PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^ = AProgressDialog^ then
    begin
      Result := FProgressDialogsList[i];
      Exit;
    end;
end;

procedure TUIDataModule.RemoveProgressDialog(ATaskId: TTaskId);
var
  i: Integer;
begin
  i := FProgressDialogsList.Count - 1;
  while i >= 0 do
  begin
    if PProgressDialogData(FProgressDialogsList[i])^.taskId = ATaskId then
    begin
      FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
      Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
      Dispose(FProgressDialogsList[i]);
      FProgressDialogsList.Delete(i);
      Break;
    end;

    i := i - 1;
  end;
end;

procedure TUIDataModule.RemoveProgressDialogByValue(AProgressDialog: PProgressDialog);
var
  i: Integer;
begin
  i := FProgressDialogsList.Count - 1;
  while i >= 0 do
  begin
    if PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog = AProgressDialog then
    begin
      FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
      Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
      Dispose(FProgressDialogsList[i]);
      FProgressDialogsList.Delete(i);
      Break;
    end;

    i := i - 1;
  end;
end;

procedure TUIDataModule.RemoveProgressDialogByUserName(AUserName: String);
var
  i: Integer;
begin
  i := FProgressDialogsList.Count - 1;
  while i >= 0 do
  begin
    if PProgressDialogData(FProgressDialogsList[i])^.UserName = AUserName then
    begin
      FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
      Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
      Dispose(FProgressDialogsList[i]);
      FProgressDialogsList.Delete(i);
      Break;
    end;

    i := i - 1;
  end;
end;

procedure TUIDataModule.OnProgressDialogCancel(Sender: TObject);
var
  pPDData: PProgressDialogData;
begin
  pPDData := GetProgressDialogData(PProgressDialog(@Sender));
  if pPDData <> nil then
    FT_UI.Module.CancelBatch(FT_UI.Module, pPDData^.taskId);

  TProgressDialog(Sender).Stop;
  RemoveProgressDialogByValue(@Sender);
end;

procedure TUIDataModule.GetFilesFromHostClipboard(var Message: TMessage);
var
  i: Integer;
  FileList: TStringList;
  temp_id: TTaskID;
begin
  try
    FLastActiveExplorerHandle := THandle(Message.WParam);

    FileList := TStringList.Create;
    for i := 0 to CB_DataObject.FCount - 1 do
      FileList.Add(CB_DataObject.FFiles[i].filePath);

  //  TRtcPFileTransfer(myUI.Module).NotifyFileBatchSend :=FT_UINotifyFileBatchSend;
    try
      temp_id := FT_UI.Module.FetchBatch(FT_UI.UserName,
                          FileList, ExtractFilePath(CB_DataObject.FFiles[0].filePath), String(Message.LParam), nil);
    except
  //  on E: Exception do
  //    begin
  //      add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
  //      raise;
  //    end;
    end;
  finally
    FileList.Free;
  end;

//  for i := 0 to CB_DataObject.FCount - 1 do
//    FT_UI.Fetch(CB_DataObject.FFiles[i].filePath, String(Message.LParam));
end;

procedure TUIDataModule.TimerReconnectTimer(Sender: TObject);
begin
  ReconnectToPartnerStart(UserName, UserDesc, UserPass,  'desk');
end;

procedure TUIDataModule.WndProc(var Message: TMessage);
begin
  if (Message.Msg = WM_GET_FILES_FROM_CLIPBOARD) then
    GetFilesFromHostClipboard(Message);
end;

constructor TUIDataModule.Create(AOwner: TComponent);
begin
  inherited;

  FHandle := AllocateHWND(WndProc);

  New(pImage);

  TimerReconnect.Enabled := False;
  FProgressDialogsList := TList.Create;
end;

destructor TUIDataModule.Destroy;
var
  i: Integer;
begin
  TimerReconnect.Enabled := False;
  TimerRec.Enabled := False;

//  UI.Active := False;
//  UI.Module.Close(UserName);
//  UI.CloseAndClear;
//  UI.Close;
//  FT_UI.CloseAndClear;
//  FT_UI.Close;

  DeallocateHWND(FHandle);
  FreeAndNil(pImage^);

  Dispose(pImage);

  for i := 0 to FProgressDialogsList.Count - 1 do
  begin
    FreeAndNil(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog^);
    Dispose(PProgressDialogData(FProgressDialogsList[i])^.ProgressDialog);
    Dispose(FProgressDialogsList[i]);
  end;
  FProgressDialogsList.Clear;
  FreeAndNil(FProgressDialogsList);

  inherited;
end;

end.
