{ Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com) }

unit rtcpFileTransEx;

interface

{$INCLUDE rtcDefs.inc}

uses
  Windows, Classes, SysUtils,
{$IFNDEF IDE_1} Variants, {$ELSE} FileCtrl, {$ENDIF}
  ShellAPI, SyncObjs,

  rtcLog, rtcSystem,
  rtcInfo, rtcPortalMod,
  rtcpFileUtils,

  rtcpFileTrans;

const
  EMPTY_TASK_ID: TGUID = '{00000000-0000-0000-0000-000000000000}';

type
  //TRtcPFileTransfer = class;
{$REGION 'TRtcAbsPFileTransferUI'}


  (*
  TRtcAbsPFileTransferUI = class(rtcpFileTrans.TRtcAbsPFileTransferUI)
  private
    FModule: TRtcPFileTransfer;
    FUserName, FUserDesc: String;
    FCleared: boolean;
    FLocked: integer;

    function GetModule: TRtcPFileTransfer;
    procedure SetModule(const Value: TRtcPFileTransfer);

    function GetUserName: String;
    procedure SetUserName(const Value: String);

  protected
    procedure Call_LogOut(Sender: TObject); virtual; abstract;
    procedure Call_Error(Sender: TObject); virtual; abstract;

    procedure Call_Init(Sender: TObject); virtual; abstract;
    procedure Call_Open(Sender: TObject); virtual; abstract;
    procedure Call_Close(Sender: TObject); virtual; abstract;

    procedure Call_ReadStart(Sender: TObject; const fname, fromfolder: String;
      size: int64); virtual; abstract;
    procedure Call_Read(Sender: TObject; const fname, fromfolder: String;
      size: int64); virtual; abstract;
    procedure Call_ReadUpdate(Sender: TObject); virtual; abstract;
    procedure Call_ReadStop(Sender: TObject; const fname, fromfolder: String;
      size: int64); virtual; abstract;
    procedure Call_ReadCancel(Sender: TObject; const fname, fromfolder: String;
      size: int64); virtual; abstract;

    procedure Call_WriteStart(Sender: TObject; const fname, tofolder: String;
      size: int64); virtual; abstract;
    procedure Call_Write(Sender: TObject; const fname, tofolder: String;
      size: int64); virtual; abstract;
    procedure Call_WriteStop(Sender: TObject; const fname, tofolder: String;
      size: int64); virtual; abstract;
    procedure Call_WriteCancel(Sender: TObject; const fname, tofolder: String;
      size: int64); virtual; abstract;

    procedure Call_CallReceived(Sender: TObject; const Data: TRtcFunctionInfo);
      virtual; abstract;

    procedure Call_FileList(Sender: TObject; const fname: String;
      const Data: TRtcDataSet); virtual; abstract;

    property Cleared: boolean read FCleared;
    property Locked: integer read FLocked write FLocked;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Prepare File Transfer
    procedure Open(Sender: TObject = nil); virtual;
    // Terminate File Transfer
    procedure Close(Sender: TObject = nil); virtual;

    // Close File Transfer and clear the "Module" property. The component is about to be freed.
    // Returns TRUE if the component may be destroyed now, FALSE if not.
    // If FALSE was returned, OnLogOut event will be triggered when the component may be destroyed.
    function CloseAndClear(Sender: TObject = nil): boolean; virtual;

    { Send (upload) file "FileName" to folder "ToFolder" (will use INBOX folder if not speficied) at user "UserName".
      If file transfer was not prepared by calling "Open", it will be after this call. }
    procedure Send(const FileName: String; const tofolder: String = '';
      Sender: TObject = nil); virtual;

    { Fetch (download) File or Folder "FileName" (specify full path) to folder "ToFolder" (will use INBOX folder if not specified).
      If file transfer was not prepared by calling "OpenFiles", it will be after this call. }
    procedure Fetch(const FileName: String; const tofolder: String = '';
      Sender: TObject = nil); virtual;

    procedure Cancel_Send(const FileName: String; const tofolder: String = '';
      Sender: TObject = nil); virtual;
    procedure Cancel_Fetch(const FileName: String; const tofolder: String = '';
      Sender: TObject = nil); virtual;

    procedure Call(const Data: TRtcFunctionInfo;
      Sender: TObject = nil); virtual;

    procedure GetFileList(const FolderName, FileMask: String;
      Sender: TObject = nil); virtual;

    procedure Cmd_NewFolder(const FolderName: String;
      Sender: TObject = nil); virtual;
    procedure Cmd_FileRename(const FileName, NewName: String;
      Sender: TObject = nil); virtual;
    procedure Cmd_FileDelete(const FileName: String;
      Sender: TObject = nil); virtual;
    procedure Cmd_FileMove(const FileName, NewName: String;
      Sender: TObject = nil); virtual;
    procedure Cmd_Execute(const FileName: String; const Params: String = '';
      Sender: TObject = nil); virtual;

  published
    { FileTransfer module used for sending and receiving data }
    property Module: TRtcPFileTransfer read GetModule write SetModule;
    { Name of the user we are communicating with }
    property UserName: String read GetUserName write SetUserName;
    property UserDesc: String read FUserDesc write FUserDesc;
  end;

  *)

{$ENDREGION}

  PFileInfo = ^TFileInfo;
  TFileInfo = record
    id: Integer;
    file_pos: Integer;
    finished: Boolean;
    win32err: Cardinal;

    handle         : THandle;
    CreationTime   : Int64;
    LastAccessTime : Int64;
    LastWriteTime  : Int64;
    attributes     : Cardinal;
    file_size      : Int64;
    file_path      : string;
    mode           : Integer;
    function IsDirectory: Boolean;

  end;
  TFileInfoList = array of TFileInfo;

  TStatusBatchTask = (sbtNone, sbtWaiting, sbtSending, sbtReceiving, sbtFinished, sbtCanceled);
  TTaskID = TGUID;

  TBatchTask = class
  private
    FRemoteFolder: string;
    FLocalFolder: string;
    FCurrent: Integer;
    FFileCount: Integer;
    FId: TTaskID;
    FStatus: TStatusBatchTask;
    FProgress: single;
    FSize: Int64;
    FUser: string;
    FFiles: TFileInfoList;
    FRefCount: Integer;
    FSentSize: Int64;
    FLocked: Integer;
    FErrorString: string;
    FLastChunkSize: Integer;
    FRemoveFileOnBreak: Boolean;
    procedure AddFileLits(List: TStrings);
    function GetFile(const Index: Integer): PFileInfo;
    // return total size
    function GetFileInfo0(const FilePath: string; out info: TFileInfo): Int64;
    function GetFileInfo(const FilePath: string; var Index: Integer; var infos: TFileInfoList): Int64;
    procedure SetFileCount(const Value: Integer);
    function GetLocked: Boolean;



  public
    constructor Create();
    destructor Destroy; override;
    procedure Clear;
    procedure _AddRef;
    procedure _Relase;
    procedure Lock;
    procedure Unlock;
    procedure CancelOperations;


    property User: string read FUser write FUser;
    property RemoteFolder: string read FRemoteFolder write FRemoteFolder;
    property LocalFolder: string read FLocalFolder write FLocalFolder;
    property Id: TTaskID read FId ;
    property Current: Integer read FCurrent write FCurrent;
    property Size: Int64 read FSize;
    property SentSize: Int64 read FSentSize;
    property Progress: single read FProgress;
    property Files[const Index: Integer]: PFileInfo read GetFile;
    property FileCount: Integer read FFileCount write SetFileCount;
    property Status: TStatusBatchTask read FStatus write FStatus;
    property RefCount: Integer read FRefCount;
    property Locked: Boolean read GetLocked;
    property ErrorString: string read FErrorString write FErrorString;
    // Свойство может быть актуальным только, если есть блокирующая синхронизация
    // иначе свойство не актуально, да и пол класса не актуально
    property LastChunkSize: Integer read FLastChunkSize write FLastChunkSize;
  end;

  TBatchList = class (TStringList)
  private
    FCS: TRTLCriticalSection;
    function GetTaskByIndex(const Index: Integer): TBatchTask;
  public
    procedure Lock;
    procedure Unlock;
    constructor Create; reintroduce;
    destructor Destroy; override;
    function AddTask: TBatchTask;
    procedure DeleteTask(task: TBatchTask);
    procedure Garbage();
    procedure UpdateID(const NewID: TTaskID; task: TBatchTask);

    function GetTaskByName(const Name: string): TBatchTask;
    function GetTaskById(const Id: TTaskID): TBatchTask;
    function FindTaskByName(const Name: string; out task: TBatchTask): Boolean;
    function ProccessingPresent: Boolean;
    property Tasks[const Index: Integer]: TBatchTask read GetTaskByIndex;
  end;

  TModeBatchSend = (mbsFileStart, mbsFileData, mbsFileStop, mbsTaskStart, mbsTaskFinished, mbsTaskError);

  TNotifyBatchInfo = record
    taskID: Integer;
    task_size: Integer;
    task_sent: Integer;
    file_name: string;
    file_size: Integer;
    file_sent: Integer;
  end;

  TNotifyFileBatchSend = procedure (Sender: TObject; const task: TBatchTask; mode: TModeBatchSend) of object;

  TRtcPFileTransfer = class(rtcpFileTrans.TRtcPFileTransfer)
  private
    FTaskList: TBatchList;
    FNotifyFileBatchSend: TNotifyFileBatchSend;
    procedure WriteIncomingFile(Sender: TObject;
      const UserName: String; const fn: TRtcFunctionInfo);
    procedure FinishWriteTask(const fn: TRtcFunctionInfo);
    procedure CancelWriteTask(const fn: TRtcFunctionInfo);
    procedure FinishTask(const task: TBatchTask; status: TStatusBatchTask);
    procedure SendBatchTasks(Sender: TObject);
    procedure SendTaskError(Sender: TObject; const UserName, Msg: string; TaskID: TTaskID);
    procedure CancelTaskByUser(const UserName: string);
    procedure RequestBatchFetch(Sender: TObject; const UserName: String; const fn: TRtcFunctionInfo);

  protected
    procedure Call_DataFromUser(Sender: TObject; const uname: String;
      Data: TRtcFunctionInfo); override;
    procedure Call_UserJoinedMyGroup(Sender: TObject; const group: String;
      const uname: String; uinfo: TRtcRecord); override;
    procedure Call_UserLeftMyGroup(Sender: TObject; const group: String;
      const uname: String); override;

    procedure Call_JoinedUsersGroup(Sender: TObject; const group: String;
      const uname: String; uinfo: TRtcRecord); override;
    procedure Call_LeftUsersGroup(Sender: TObject; const group: String;
      const uname: String); override;

    function SenderLoop_Check(Sender: TObject): boolean; override;
    procedure SenderLoop_Prepare(Sender: TObject); override;
    procedure SenderLoop_Execute(Sender: TObject); override;

    ///
    procedure InternalNotifyFileBatchSend(const task: TBatchTask; mode: TModeBatchSend); virtual;
    function SendBatch(const UserName: String; FileList: TStrings;
      const Root, RemoteFolder: String; WithID: TTaskID; Sender: TObject = nil): TTaskID; overload;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CancelBatch(TaskID: TTaskID);
    function SendBatch(const UserName: String; FileList: TStrings;
      const Root, RemoteFolder: String; Sender: TObject = nil): TTaskID; overload;
    function FetchBatch(const UserName: String; FileList: TStrings;
      const Root, LocalFolder: String; Sender: TObject = nil): TTaskID;
    property TaskList: TBatchList read FTaskList;
    property NotifyFileBatchSend: TNotifyFileBatchSend read FNotifyFileBatchSend write FNotifyFileBatchSend;
  end;

implementation

uses
  System.IOUtils, NTImport, Vcl.Forms;

type
  TBatchFuncType = (
                    BATCH_FUNC_TYPE_UNKNOWN,
                    BATCH_FUNC_TYPE_START,
                    BATCH_FUNC_TYPE_WAIT,
                    BATCH_FUNC_TYPE_DATA,
                    BATCH_FUNC_TYPE_CANCEL,
                    BATCH_FUNC_TYPE_FINISH,
                    BATCH_FUNC_TYPE_ERROR,
                    BATCH_FUNC_TYPE_FETCH
                   );

const
  BATCH_FUNC_NAME_UNKNOWN = 'func_unknown';
  BATCH_FUNC_NAME_START  = 'send_batch_file_start';
  BATCH_FUNC_NAME_WAIT   = 'send_batch_file_wait';
  BATCH_FUNC_NAME_DATA   = 'send_batch_file_data';
  BATCH_FUNC_NAME_CANCEL = 'send_batch_file_cancel';
  BATCH_FUNC_NAME_FINISH = 'send_batch_file_finish';
  BATCH_FUNC_NAME_ERROR  = 'send_batch_file_error';
  BATCH_FUNC_NAME_FETCH  = 'send_batch_file_fetch';


  LIST_BUTCH_FUNCS: array [TBatchFuncType] of string = (
      BATCH_FUNC_NAME_UNKNOWN,
      BATCH_FUNC_NAME_START,
      BATCH_FUNC_NAME_WAIT,
      BATCH_FUNC_NAME_DATA,
      BATCH_FUNC_NAME_CANCEL,
      BATCH_FUNC_NAME_FINISH,
      BATCH_FUNC_NAME_ERROR,
      BATCH_FUNC_NAME_FETCH
    );

function  BatchFuncTypeToName(ButchFuncType: TBatchFuncType): string;
begin
  Result := LIST_BUTCH_FUNCS[ButchFuncType]
end;

function NameToButchFuncType(const Name: string): TBatchFuncType;
begin
  for Result := Low(TBatchFuncType) to High(TBatchFuncType) do
    if LIST_BUTCH_FUNCS[Result] = Name then exit;
  Result := BATCH_FUNC_TYPE_UNKNOWN;
end;


procedure OutPutLog(const LogFmt: string; const Args: array of const);
var
  s: string;
begin
  if Length(Args) > 0 then
    s := Format(LogFmt, Args) else
    s := LogFmt;
  OutputDebugString(PChar(s));
end;



{ **************************************************************************** }
{                               TRtcPFileTransfer                              }
{ **************************************************************************** }


procedure TRtcPFileTransfer.Call_DataFromUser(Sender: TObject;
  const uname: String; Data: TRtcFunctionInfo);
var
  fn: TRtcFunctionInfo;
  task: TBatchTask;
begin
  if not isSubscriber(uname) or not MayUploadFiles(uname) then
    begin
      inherited;
      exit;
    end;

  case NameToButchFuncType(Data.FunctionName) of


    BATCH_FUNC_TYPE_START:
      begin
        if not FTaskList.FindTaskByName(Data.asText['task_id'], task) then
          begin
            task                    := FTaskList.AddTask;
            FTaskList.UpdateID(TGUID.Create(Data.asText['task_id']), task);
            task.LocalFolder        := Data.asText['to_folder'];
            task.User               := uname;
          end;
        task.FSize              := Data.asInteger['task_size'];
        task.FileCount          := Data.asInteger['file_count'];
        task.FRemoveFileOnBreak := true;

        fn := TRtcFunctionInfo.Create;
        try

          fn.FunctionName             := BATCH_FUNC_NAME_WAIT;
          fn.asText['task_id']        := Data.asText['task_id'];
          fn.asInteger['file_index']  := Data.asInteger['file_index'];
          fn.asLargeInt['file_pos']   := 0 ;
          task.Status                 := sbtReceiving;
          InternalNotifyFileBatchSend(task, mbsTaskStart);
        except
          fn.Free;
          raise
        end;
        Client.SendToUser(Sender, uname, fn);
      end;

    BATCH_FUNC_TYPE_WAIT:
      begin
        if not FTaskList.FindTaskByName(Data.asText['task_id'], task) then exit;
        task.Status := sbtSending;
        InternalNotifyFileBatchSend(task, mbsTaskStart);
      end;

    BATCH_FUNC_TYPE_DATA:
      begin
        WriteIncomingFile(Sender, uname, Data);
      end;

    BATCH_FUNC_TYPE_FINISH:
      begin
        FinishWriteTask(Data);
      end;

    BATCH_FUNC_TYPE_ERROR:
      begin
        if not FTaskList.FindTaskByName(Data.asText['task_id'], task) then exit;
        if task.Status = sbtReceiving then
          CancelWriteTask(Data)
        else if task.Status = sbtSending  then
          begin
              fn := TRtcFunctionInfo.Create;
              try
                fn.FunctionName := BATCH_FUNC_NAME_CANCEL;
                fn.asText['task_id']         := task.Id.ToString;
                Client.SendToUser(Self, task.User, fn);
              except
                fn.Free;
                raise;
              end;
              task.ErrorString := Data.asText['message'];
              InternalNotifyFileBatchSend(task, mbsTaskError);
              FinishTask(task, sbtCanceled);
          end;
      end;

    BATCH_FUNC_TYPE_CANCEL:
      begin
        CancelWriteTask(Data);
      end;

    BATCH_FUNC_TYPE_FETCH:
      begin
        RequestBatchFetch(Sender, uname, Data);
      end

    else
      inherited;
  end;

end;

procedure TRtcPFileTransfer.Call_JoinedUsersGroup(Sender: TObject; const group,
  uname: String; uinfo: TRtcRecord);
begin
  inherited;

end;

procedure TRtcPFileTransfer.Call_LeftUsersGroup(Sender: TObject; const group,
  uname: String);
begin
  inherited;
  if (group = 'file') then
    CancelTaskByUser(uname);
end;

procedure TRtcPFileTransfer.Call_UserJoinedMyGroup(Sender: TObject; const group,
  uname: String; uinfo: TRtcRecord);
begin
  inherited;
  //
end;

procedure TRtcPFileTransfer.Call_UserLeftMyGroup(Sender: TObject; const group,
  uname: String);
begin
  inherited;
  if (group = 'file') then
    CancelTaskByUser(uname);
end;

procedure TRtcPFileTransfer.CancelBatch(TaskID: TTaskID);
var
  i: Integer;
  task: TBatchTask;
  fn: TRtcFunctionInfo;
  f: PFileInfo;
begin
  if not FTaskList.FindTaskByName(TaskID.ToString, task) then exit;

    fn := TRtcFunctionInfo.Create;
    try
      fn.FunctionName := BATCH_FUNC_NAME_CANCEL;
      fn.asText['task_id']         := task.Id.ToString;
      Client.SendToUser(Self, task.User, fn);
      FinishTask(task, sbtCanceled);
    except
      fn.Free;
      raise;
    end;

end;

procedure TRtcPFileTransfer.CancelTaskByUser(const UserName: string);
var
  i: Integer;
begin
  FTaskList.Lock;
  try
    for i := FTaskList.Count-1 downto 0 do
      begin
        if FTaskList.Tasks[i].User = UserName then
          FinishTask(FTaskList.Tasks[i], sbtCanceled);
      end;
  finally
    FTaskList.Unlock
  end;
  FTaskList.Garbage
end;

procedure TRtcPFileTransfer.CancelWriteTask(const fn: TRtcFunctionInfo);
var
  task: TBatchTask;
begin
  if FTaskList.FindTaskByName(fn.asText['task_id'], task) then
    begin
      FinishTask(task, sbtCanceled);
      InternalNotifyFileBatchSend(task, mbsTaskFinished);
      FTaskList.Garbage;
    end;
end;

constructor TRtcPFileTransfer.Create(AOwner: TComponent);
begin
  inherited;
  FTaskList := TBatchList.Create;
end;

destructor TRtcPFileTransfer.Destroy;
begin
  FTaskList.Free;
  inherited;
end;

function TRtcPFileTransfer.FetchBatch(const UserName: String;
  FileList: TStrings; const Root, LocalFolder: String; Sender: TObject): TTaskID;
var
  fn: TRtcFunctionInfo;
  task: TBatchTask;
begin
  if FileList.Count = 0 then
    raise Exception.Create('FileList is empty');

  if not MayUploadFiles(UserName) then
    raise Exception.Create('Not allowed');


  task             := FTaskList.AddTask;
  task.user        := UserName;
  task.LocalFolder := LocalFolder;
  Result           := task.Id;


  fn := TRtcFunctionInfo.Create;
  try
    fn.FunctionName        := BATCH_FUNC_NAME_FETCH;
    fn.asText['task_id']   := task.Id.ToString;
    fn.asText['root']      := Root;
    fn.asText['files']     := FileList.Text;
    fn.asText['to_folder'] := LocalFolder;
  except
    fn.Free;
    raise;
  end;

  Client.SendToUser(Sender, UserName, fn);

end;

procedure TRtcPFileTransfer.FinishTask(const task: TBatchTask; status: TStatusBatchTask);
var
  i: Integer;
begin

  task.Lock;
  try
    task.Status := status;
    task.CancelOperations;
    task._Relase;
  finally
    task.Unlock;
  end;

end;

procedure TRtcPFileTransfer.FinishWriteTask(const fn: TRtcFunctionInfo);
var
  task: TBatchTask;
begin
  if FTaskList.FindTaskByName(fn.asText['task_id'], task) then
    begin
      FinishTask(task, sbtFinished);
      InternalNotifyFileBatchSend(task, mbsTaskFinished);
      FTaskList.Garbage;
    end;
end;

procedure TRtcPFileTransfer.InternalNotifyFileBatchSend(const task: TBatchTask;
  mode: TModeBatchSend);
begin
  if not Assigned(FNotifyFileBatchSend) then exit;

  TThread.Synchronize(TThread.CurrentThread,
    procedure ()
    begin
      task._AddRef;
      try
        FNotifyFileBatchSend(Self, task, mode)
      finally
        task._Relase;
      end;
    end
    );
end;

procedure TRtcPFileTransfer.RequestBatchFetch(Sender: TObject;
  const UserName: String; const fn: TRtcFunctionInfo);
var
  Files: TStringList;
begin
  Files := TStringList.Create();
  try
    Files.Text := fn.asText['files'];
    SendBatch(UserName, Files, fn.asText['root'], fn.asText['to_folder'], TGUID.Create(fn.asText['task_id']), Sender);
  finally
    Files.Free;
  end;
end;

function TRtcPFileTransfer.SendBatch(const UserName: String;
  FileList: TStrings; const Root, RemoteFolder: String; Sender: TObject): TTaskID;
begin
  Result := SendBatch(UserName, FileList, Root, RemoteFolder, EMPTY_TASK_ID, Sender);
end;

function TRtcPFileTransfer.SendBatch(const UserName: String; FileList: TStrings;
  const Root, RemoteFolder: String; WithID: TTaskID; Sender: TObject): TTaskID;
var
  fn: TRtcFunctionInfo;
  task: TBatchTask;
begin
  if FileList.Count = 0 then
    raise Exception.Create('FileList is empty');


  if not MayDownloadFiles(UserName) then
    raise Exception.Create('Not allowed');
  if not isSubscriber(UserName) then
    raise Exception.Create('not IsSubscriber');

  task := FTaskList.AddTask;
  if WithID <> EMPTY_TASK_ID then    //  TGuid.Empty
    FTaskList.UpdateID(WithID, task);

  task.user         := UserName;
  task.RemoteFolder := RemoteFolder;
  task.LocalFolder  := Root;
  task.AddFileLits(FileList);
  Result := task.Id;


  fn := TRtcFunctionInfo.Create;
  try

    fn.FunctionName := BATCH_FUNC_NAME_START;
    fn.asText['task_id']            := task.Id.ToString;
    fn.asInteger['file_count']      := task.FileCount;
    fn.asInteger['file_index']      := task.Current;
    fn.asText['to_folder']          := RemoteFolder;
    fn.asLargeInt['task_size']      := task.Size;
    fn.asLargeInt['file_pos']       := 0 ;
    task.Status := sbtWaiting;
  except
    fn.Free;
    raise;
  end;

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.SendBatchTasks;

  function GetNextTask(var index: Integer; var task: TBatchTask): Boolean;
  begin
    Result := false;
    if FTaskList.Count = 0 then exit;

    FTaskList.Lock;
    if Index < 0 then Index := 0 else
      Inc(Index);
    try
    while index < FTaskList.Count do
      begin
        task := FTaskList.Tasks[index];
        if not task.Locked and (task.Status = sbtSending) then
          begin
            task.Lock;
            Result := true;
            break;
          end;
        Inc(index);
      end;
    finally
      FTaskList.Unlock;
    end;
  end;

var
  i, SendBytes: Integer;
  task: TBatchTask;
  f: PFileInfo;
  fn: TRtcFunctionInfo;
  dwRead: Integer;
  b: TArray<Byte>;
begin

  fn := nil;
  task := nil;

  try

  if (FTaskList.Count = 0) then exit;
  i := -1;
  while GetNextTask(i, task)  do
    try
      //while task.Current < task.FileCount do
      if task.Current < task.FileCount then
        begin
          fn := TRtcFunctionInfo.Create;
          fn.FunctionName      := BATCH_FUNC_NAME_DATA;
          fn.asText['task_id'] := task.Id.ToString;
          fn.asInteger['file_index'] := task.Current;

          f := task.Files[task.Current];
          // open file
          if f.handle = 0 then
            begin
              f.finished := f.IsDirectory;
              if not f.IsDirectory then
                f.handle := FileOpen(f.file_path, fmOpenRead);
              if f.handle = INVALID_HANDLE_VALUE then
                begin
                  f.win32err := GetLastError;
                  f.finished := true;
                  RaiseLastOSError(f.win32err, sLineBreak + f.file_path);
                end
              else
                begin

                  fn.asText['file_name']            := ExtractFileName(f.file_path);
                  fn.asText['relative_path']        := ExtractRelativePath(task.LocalFolder, f.file_path);
                  fn.asText['to_folder']            := task.RemoteFolder;
                  fn.asLargeInt['file_size']        := f.file_size;
                  fn.asLargeInt['creation_time']    := f.CreationTime;
                  fn.asLargeInt['last_access_time'] := f.LastAccessTime;
                  fn.asLargeInt['last_write_time']  := f.LastWriteTime;
                  fn.asInteger['attributes']        := f.attributes;
                  if not f.IsDirectory then
                    InternalNotifyFileBatchSend(task, mbsFileStart);

                end;
            end;

          // read and send
          dwRead := 0;
          if not f.IsDirectory then
            begin
              SendBytes := f.file_size - f.file_pos;
              if SendBytes > MaxSendChunkSize then
                SendBytes := MaxSendChunkSize;
              task.LastChunkSize := SendBytes;

              SetLength(b, SendBytes);
              dwRead := FileRead(f.handle, b[0], SendBytes);
              if dwRead = -1 then
                begin
                  f.win32err := GetLastError;
                  f.finished := true;
                  FileClose(f.handle);
                  f.handle := 0;
                  SetLastError(f.win32err);
                  RaiseLastOSError(f.win32err, sLineBreak + f.file_path);
                end;

              task.FSentSize := task.SentSize + dwRead;
              if task.Size > 0 then
                task.FProgress := task.SentSize / task.Size ;

              if dwRead <> SendBytes then
                SetLength(b, dwRead);
              fn.asByteArray['file_data']  :=  RtcByteArray(b);
              fn.asLargeInt['file_dwRead'] := dwRead;
              fn.asLargeInt['file_pos']    := f.file_pos;

              f.file_pos := f.file_pos + dwRead;
              f.finished := f.file_pos = f.file_size;
              InternalNotifyFileBatchSend(task, mbsFileData);
              if f.finished then
                InternalNotifyFileBatchSend(task, mbsFileStop);
            end;

          // send packet
          Client.SendToUser(Sender, task.User, fn);
          fn := nil;
          // close, go to next file
          if f.finished or (f.win32err <> 0) then
            begin
              if (f.handle <> 0) and (f.handle <> INVALID_HANDLE_VALUE) then
                FileClose(f.handle);
              f.handle := 0;

              if task.Current  = task.FileCount-1 then
                begin
                  task.Status := sbtFinished;
                  InternalNotifyFileBatchSend(task, mbsTaskFinished);
                end;
              task.Current := task.Current + 1;
            end;

         // break
        end;


        if task.Current = task.FileCount then
          begin
            fn := TRtcFunctionInfo.Create;
            fn.FunctionName := BATCH_FUNC_NAME_FINISH;
            fn.asText['task_id']  := task.Id.ToString;
            Client.SendToUser(Sender, task.User, fn);
            fn := nil;

            task._Relase;

          end;
    finally
      task.Unlock;
    end;

  except
    on E: Exception do
      begin
        if fn <> nil then
          fn.Free;
        task.Status := sbtNone;
        try
          SendTaskError(Sender, task.User, E.Message, task.Id);
          task.ErrorString := E.Message;
          InternalNotifyFileBatchSend(task, mbsTaskError);
        finally
          task._Relase;
        end;
        raise;
      end;
  end;

  FTaskList.Garbage;

end;

function TRtcPFileTransfer.SenderLoop_Check(Sender: TObject): boolean;
begin
  Result := inherited SenderLoop_Check(Sender) or FTaskList.ProccessingPresent;
end;

procedure TRtcPFileTransfer.SenderLoop_Execute(Sender: TObject);
begin
  inherited;
  SendBatchTasks(Sender);
end;

procedure TRtcPFileTransfer.SenderLoop_Prepare(Sender: TObject);
begin
  inherited;
end;

procedure TRtcPFileTransfer.SendTaskError(Sender: TObject; const UserName, Msg: string; TaskID: TTaskID);
var
  fn: TRtcFunctionInfo;
begin
  fn := nil;
      fn := TRtcFunctionInfo.Create;
      try
        fn.FunctionName := BATCH_FUNC_NAME_ERROR;
        fn.asText['task_id']  := TaskID.ToString;
        fn.asText['message']  := Msg;
        Client.SendToUser(Sender, UserName, fn);
      except
        fn.Free;
        raise;
      end;

end;

procedure TRtcPFileTransfer.WriteIncomingFile(Sender: TObject;
      const UserName: String; const fn: TRtcFunctionInfo);
var
  task: TBatchTask;
  f: PFileInfo;
  dwWrite: Integer;
  b: TArray<Byte>;
begin

  if not FTaskList.FindTaskByName(fn.asText['task_id'], task) then exit;
  task.Lock;
  try
  f := task.Files[fn.asInteger['file_index']];
  if f.handle = 0 then
    begin

      f.file_size      := fn.asLargeInt['file_size'];
      f.CreationTime   := fn.asLargeInt['creation_time'];
      f.LastAccessTime := fn.asLargeInt['last_access_time'];
      f.LastWriteTime  := fn.asLargeInt['last_write_time'];
      f.file_pos       := fn.asLargeInt['file_pos'];
      f.attributes     := fn.asInteger['attributes'];
      f.file_path      := fn.asText['to_folder'] + fn.asText['relative_path'];
      f.finished       := f.IsDirectory;
      f.mode           := fmCreate;

      if not f.IsDirectory then
        begin
          //Event_FileWriteStart(Sender, UserName, f.file_path, task.LocalFolder, f.file_size);
          f.handle := FileCreate(f.file_path);
          InternalNotifyFileBatchSend(task, mbsFileStart);
        end
      else
        begin
          ForceDirectories(f.file_path);
          f.handle := CreateFile(PChar(f.file_path), GENERIC_READ or GENERIC_WRITE,
                FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
                FILE_WRITE_ATTRIBUTES or FILE_FLAG_BACKUP_SEMANTICS , 0);

        end;
      if f.handle = INVALID_HANDLE_VALUE then
        begin
          f.win32err := GetLastError;
          f.finished := true;
          f.handle := 0;
          SendTaskError(Sender, task.User, SysErrorMessage(f.win32err), task.Id);
        end;
    end;

  dwWrite := 0;
  if not f.finished then
    begin

      b := TArray<Byte>(fn.asByteArray['file_data']);
      dwWrite := FileWrite(f.handle, b[0], Length(b));

    end;

  if dwWrite = -1 then
    begin
      f.win32err := GetLastError;
      f.finished := true;
      CloseHandle(f.handle);
      f.handle := 0;
      SetLastError(f.win32err);
      SendTaskError(Sender, task.User, SysErrorMessage(f.win32err), task.Id);
    end
  else if dwWrite > 0 then
    begin
      f.file_pos := f.file_pos + dwWrite;
      f.finished := f.file_pos = f.file_size;
      task.LastChunkSize := dwWrite;
      task.FSentSize := task.SentSize + dwWrite;
      if task.Size > 0 then
        task.FProgress := task.SentSize / task.Size ;
      InternalNotifyFileBatchSend(task, mbsFileData);
    end;

  if f.finished then
    begin

      if f.handle <> 0 then
        begin
          SetFileTime(f.handle, @f.CreationTime, @f.LastAccessTime, @f.LastWriteTime);
          CloseHandle(f.handle);
        end;
      f.handle := 0;
      SetFileAttributes(PChar(f.file_path), f.attributes);
      if not f.IsDirectory then
        InternalNotifyFileBatchSend(task, mbsFileStop);
    end;
  finally
    task.Unlock;
  end;

end;



{ **************************************************************************** }
{                               TBatchList                                     }
{ **************************************************************************** }



function TBatchList.AddTask: TBatchTask;
begin
  Result := TBatchTask.Create;
  Lock;
  try
    AddObject(Result.id.ToString, Result);
  finally
    Unlock;
  end;
end;

constructor TBatchList.Create;
begin
  inherited Create(true);
  Duplicates := dupIgnore;
  Sorted := true;
  CaseSensitive := false;
  FCS.Initialize;
end;

procedure TBatchList.DeleteTask(task: TBatchTask);
var
  i: Integer;
begin
  if task = nil then exit;

  Lock;
  try
    i := IndexOf(task.Id.ToString);
    if i <> -1 then
      Delete(i);
  finally
    Unlock;
  end;
end;

destructor TBatchList.Destroy;
begin
  FCS.Free;
  inherited;
end;

function TBatchList.FindTaskByName(const Name: string;
  out task: TBatchTask): Boolean;
var
  Index: Integer;
begin
  Result := Find(Name, Index);
  if Result then
    task := GetTaskByIndex(Index);
end;

procedure TBatchList.Garbage;
var
  I: Integer;
  task: TBatchTask;
begin
  Lock;
  try
    for I := Count-1 downto 0 do
      begin
        task := GetTaskByIndex(I);
        if (task.RefCount = 0) and (not task.Locked)  then
          Delete(I);
      end;
  finally
    Unlock
  end;
end;

function TBatchList.GetTaskById(const Id: TTaskID): TBatchTask;
begin
  Result := GetTaskByName(Id.ToString)
end;

function TBatchList.GetTaskByIndex(const Index: Integer): TBatchTask;
begin
  Result := TBatchTask(Objects[Index]);
end;

function TBatchList.GetTaskByName(const Name: string): TBatchTask;
var
  Index: Integer;
begin
  if not Find(Name, Index) then
    raise Exception.CreateFmt('Task not found %s', [Name])
  else
    Result := GetTaskByIndex(Index)
end;

procedure TBatchList.Lock;
begin
  FCS.Enter;
end;

function TBatchList.ProccessingPresent: Boolean;
var
  I: Integer;
begin
  Lock;
  try
    Result := false;
    for I := 0 to Count-1 do
        if (Tasks[i].Status = sbtSending) and (Tasks[i].RefCount > 0) then
          begin
            Result := true;
            break;
          end;
  finally
    Unlock;
  end;
end;



procedure TBatchList.Unlock;
begin
  FCS.Leave;
end;

procedure TBatchList.UpdateID(const NewID: TTaskID; task: TBatchTask);
var
  i: Integer;
begin
  Lock;
  try
    i := IndexOf(NewID.ToString);
    if i <> -1 then
      raise Exception.CreateFmt('TaskID %s alredy exists', [Strings[i]]);
    i := IndexOf(task.Id.ToString);
    if i = -1 then
      raise Exception.CreateFmt('Task %s is not valid', [task.Id.ToString]);
    Sorted     := false;
    task.FId   := NewID;
    Strings[i] := NewID.ToString;
    Sorted     := true;
  finally
    Unlock;
  end;
end;

{ **************************************************************************** }
{                               TBatchTask                                     }
{ **************************************************************************** }



procedure TBatchTask.AddFileLits(List: TStrings);
var
  i: Integer;
  lfiles: TFileInfoList;
  cnt: Integer;
  sz: Int64;

begin
  if FFileCount > 0 then raise EAbort.Create('Task not empty');
  cnt := 0;
  sz := 0;
  for I := 0 to List.Count-1 do
    begin
      if DirectoryExists(List[i], false) then
        sz := sz + GetFileInfo(List[i], cnt, lfiles) else
        begin
          if Length(lfiles) >= cnt then
            SetLength(lfiles, GrowCollection(cnt, cnt + 1));
          sz := sz + GetFileInfo0(List[i], lfiles[cnt]);
          Inc(cnt);
        end;

//      FFiles[i].id := I;
//      FFiles[i].file_path := List[i];
//      FFiles[i].size := File_Content(List[i], )
    end;



  SetLength(lfiles, cnt);
  FFiles := lfiles;
  FFileCount := cnt;
  FSize := sz;

  // Check before if an error occurred
  for I := 0 to Length(FFiles)-1 do
    if FFiles[i].win32err <> 0 then
      RaiseLastOSError(FFiles[i].win32err, sLineBreak + FFiles[i].file_path);

end;

procedure TBatchTask.CancelOperations;
var
  I: Integer;
begin
  for I := 0 to FFileCount-1 do
    begin
      if (FFiles[i].handle <> 0) then
        begin
          CloseHandle(FFiles[i].handle);
          if (FFiles[i].mode = fmCreate) and FRemoveFileOnBreak then
            DeleteFile(FFiles[i].file_path);
        end;
      FFiles[i].handle := 0;
    end;
end;

procedure TBatchTask.Clear;
begin
  CancelOperations;
  FFileCount := 0;
  SetLength(FFiles, 0);
end;

constructor TBatchTask.Create;
begin
  inherited;
  FId := TGUID.NewGuid;
  FRefCount := 1;
end;

destructor TBatchTask.Destroy;
begin
  Clear;
  inherited;
end;

function TBatchTask.GetFile(const Index: Integer): PFileInfo;
begin
  Result := @FFiles[Index];
end;

function TBatchTask.GetFileInfo(const FilePath: string; var Index: Integer;
  var infos: TFileInfoList): Int64;
const
  CUR_DIR    = '.';
  PARENT_DIR = '..';
  PATERN     = '*';
  RECURSIVE  = true;
var
  SearchRec: TSearchRec;
  ret: Boolean;
begin
  Result := 0;
  if FindFirst(TPath.Combine(FilePath, '*'), faAnyFile, SearchRec) = 0 then // DO NOT LOCALIZE
    try
      repeat
        if Length(infos) >= Index then
          SetLength(infos, GrowCollection(Index, Index + 1));
        FillChar(infos[Index], SizeOf(infos[Index]), 0);
        infos[Index].CreationTime   := Int64(SearchRec.FindData.ftCreationTime);
        infos[Index].LastAccessTime := Int64(SearchRec.FindData.ftLastAccessTime);
        infos[Index].LastWriteTime  := Int64(SearchRec.FindData.ftLastWriteTime);
        infos[Index].attributes     := SearchRec.FindData.dwFileAttributes;
        infos[Index].file_size      := SearchRec.Size;
        if (SearchRec.Name <> CUR_DIR) and (SearchRec.Name <> PARENT_DIR) then
          infos[Index].file_path      := TPath.Combine(FilePath, SearchRec.Name) else
          infos[Index].file_path      := FilePath;
        if SearchRec.Attr and faDirectory = 0 then
          Result := Result + SearchRec.Size;

        Inc(Index);
        // go recursive in subdirectories
        if RECURSIVE and (SearchRec.Attr and faDirectory <> 0) and
           (SearchRec.Name <> CUR_DIR) and
           (SearchRec.Name <> PARENT_DIR) then
          Result := Result + GetFileInfo(infos[Index-1].file_path, Index, infos);

      until (FindNext(SearchRec) <> 0);
    finally
      FindClose(SearchRec);
    end;
end;

function TBatchTask.GetFileInfo0(const FilePath: string;
  out info: TFileInfo): Int64;
var
  status: NTSTATUS;
  IoStatusBlock: TIoStatusBlock;
  file_info: TFileNetworkOpenInformation ;
  hFile: THandle;
begin
  Result := 0;
  FillChar(info, SizeOf(info), 0);
  info.file_path := FilePath;
  hFile := CreateFile(PChar(FilePath), GENERIC_READ,
      FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS , 0);
  if hFile = INVALID_HANDLE_VALUE then
    begin
      info.win32err := GetLastError;
      info.handle   := 0;
      exit;
    end;
  status := NtQueryInformationFile(hFile, @IoStatusBlock,
                @file_info, SizeOf(file_info), FileNetworkOpenInformation);
  if status <> 0 then
    begin
      info.win32err := GetLastError;
      CloseHandle(hFile);
      info.handle := 0;
      exit;
    end;

  CloseHandle(hFile);
  info.handle         := 0;
  info.file_size      := Int64(file_info.EndOfFile);
  info.attributes     := file_info.FileAttributes;
  info.CreationTime   := Int64(file_info.CreationTime);
  info.LastAccessTime := Int64(file_info.LastAccessTime);
  info.LastWriteTime  := Int64(file_info.LastWriteTime);
  info.file_path      := FilePath;
  Result := info.file_size;

end;



function TBatchTask.GetLocked: Boolean;
begin
  Result := FLocked > 0;
end;

procedure TBatchTask.Lock;
begin
  while InterlockedExchange(FLocked, 1) <> 0 do
    begin
      if MainThreadID = GetCurrentThreadId then
        Application.ProcessMessages else
        SwitchToThread;
    end;
end;

procedure TBatchTask.SetFileCount(const Value: Integer);
var
  i: Integer;
begin
  if FFileCount <> Value then
    begin
      for I := Value-1 to FFileCount-1 do
        begin
          if FFiles[i].handle <> 0 then
            CloseHandle(FFiles[i].handle);
          FFiles[i].handle := 0;
        end;
      SetLength(FFiles, Value);
      FFileCount := Value

    end;
end;

procedure TBatchTask.Unlock;
begin
  InterlockedExchange(FLocked, 0);
end;

procedure TBatchTask._AddRef;
begin
  InterlockedIncrement(FRefCount)
end;

procedure TBatchTask._Relase;
begin
  InterlockedDecrement(FRefCount)
end;

{ **************************************************************************** }
{                               TFileInfo                                      }
{ **************************************************************************** }


function TFileInfo.IsDirectory: Boolean;
begin
  Result := Self.attributes and faDirectory <> 0
end;

end.
