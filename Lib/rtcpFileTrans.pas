{ Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com) }

unit rtcpFileTrans;

interface

{$INCLUDE rtcDefs.inc}

uses
  Windows, Classes, SysUtils,
{$IFNDEF IDE_1} Variants, {$ELSE} FileCtrl, {$ENDIF}
  ShellAPI, SyncObjs, IOUtils, NTImport, Vcl.Forms,

  rtcLog, rtcSystem,
  rtcInfo, rtcPortalMod,
  rtcpFileUtils;

const
  RTCP_DEFAULT_MAXCHUNKSIZE = 100 * 1024; // 100 KB
  RTCP_DEFAULT_MINCHUNKSIZE = 4 * 1024; // 4 KB
  EMPTY_TASK_ID: TGUID = '{00000000-0000-0000-0000-000000000000}';

type
  TRtcPFileTransfer = class;

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

  TModeBatchSend = (mbsFileStart, mbsFileData, mbsFileStop, mbsTaskStart, mbsTaskFinished, mbsTaskError, mbNone);

  TNotifyBatchInfo = record
    taskID: Integer;
    task_size: Integer;
    task_sent: Integer;
    file_name: string;
    file_size: Integer;
    file_sent: Integer;
  end;

  TNotifyFileBatchSend = procedure (Sender: TObject; const task: TBatchTask; mode: TModeBatchSend) of object;

  TRtcAbsPFileTransferUI = class(TRtcPortalComponent)
  private
    FModule: TRtcPFileTransfer;
    FUserName, FUserDesc: String;
    FCleared: boolean;
    FLocked: integer;
    FNotifyFileBatchSend: TNotifyFileBatchSend;

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

    //MFT+
    property NotifyFileBatchSend: TNotifyFileBatchSend read FNotifyFileBatchSend write FNotifyFileBatchSend;
    procedure Call_NotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend); virtual; abstract;
    //MFT-

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

  TRtcPFileTransUserEvent = procedure(Sender: TRtcPFileTransfer;
    const user: String) of object;
  TRtcPFileTransFolderEvent = procedure(Sender: TRtcPFileTransfer;
    const user: String; const FileName, path: String; const size: int64)
    of object;
  TRtcPFileTransCallEvent = procedure(Sender: TRtcPFileTransfer;
    const user: String; const Data: TRtcFunctionInfo) of object;
  TRtcPFileTransListEvent = procedure(Sender: TRtcPFileTransfer;
    const user: String; const FolderName: String; const Data: TRtcDataSet)
    of object;

  TRtcPFileTransfer = class(TRtcPModule)
  private
    CSUI: TCriticalSection;
    UIs: TRtcInfo;

    AmHost: TRtcRecord;

    FAllowFileDelete, FAllowFileMove, FAllowFileRename, FAllowFolderCreate,
      FAllowFolderDelete, FAllowFolderMove, FAllowFolderRename,
      FAllowShellExecute, FAllowSuperFileDelete, FAllowSuperFileMove,
      FAllowSuperFileRename, FAllowSuperFolderCreate, FAllowSuperFolderDelete,
      FAllowSuperFolderMove, FAllowSuperFolderRename,
      FAllowSuperShellExecute: boolean;

    FAllowUpload, FAllowDownload, FAllowSuperUpload, FAllowSuperDownload,
      FAllowUploadAnywhere, FAllowSuperUploadAnywhere, FAllowBrowse,
      FAllowSuperBrowse: boolean;

    loop_tosendfile: boolean;
    loop_update: TRtcArray;

    WantToSendFiles, PrepareFiles, UpdateFiles: TRtcRecord;
    SendingFiles: TRtcArray;
    File_Sending: boolean;
    File_Senders: integer;

    FOnFileTransInit: TRtcPFileTransUserEvent;
    FOnFileTransOpen: TRtcPFileTransUserEvent;
    FOnFileTransClose: TRtcPFileTransUserEvent;

    FOnFileReadStart: TRtcPFileTransFolderEvent;
    FOnFileRead: TRtcPFileTransFolderEvent;
    FOnFileReadUpdate: TRtcPFileTransFolderEvent;
    FOnFileReadStop: TRtcPFileTransFolderEvent;
    FOnFileReadCancel: TRtcPFileTransFolderEvent;

    FOnFileWriteStart: TRtcPFileTransFolderEvent;
    FOnFileWrite: TRtcPFileTransFolderEvent;
    FOnFileWriteStop: TRtcPFileTransFolderEvent;
    FOnFileWriteCancel: TRtcPFileTransFolderEvent;

    FOnCallReceived: TRtcPFileTransCallEvent;
    FOnFileList: TRtcPFileTransListEvent;

    FOnNewUI: TRtcPFileTransUserEvent;

    FFileInboxPath: String;
    FMaxSendBlock: longint;
    FMinSendBlock: longint;
    FAccessControl: boolean;
    FGatewayParams: boolean;

    FHostMode: boolean;

    FUIVisible: Boolean;

    //+MFT
    FTaskList: TBatchList;
    FNotifyFileBatchSend: TNotifyFileBatchSend;
    procedure WriteIncomingFile(Sender: TObject;
      const UserName: String; const fn: TRtcFunctionInfo);
    procedure FinishWriteTask(Sender: TObject; const fn: TRtcFunctionInfo);
    procedure CancelWriteTask(Sender: TObject; const fn: TRtcFunctionInfo);
    procedure FinishTask(Sender: TObject; const task: TBatchTask; status: TStatusBatchTask);
    procedure SendBatchTasks(Sender: TObject);
    procedure SendTaskError(Sender: TObject; const UserName, Msg: string; TaskID: TTaskID);
    procedure CancelTaskByUser(Sender: TObject; const UserName: string);
    procedure RequestBatchFetch(Sender: TObject; const UserName: String; const fn: TRtcFunctionInfo);
    //-MFT

    procedure InitData;

    function LockUI(const UserName: String): TRtcAbsPFileTransferUI;
    procedure UnlockUI(UI: TRtcAbsPFileTransferUI);

    function StartSendingFile(const UserName: String; const path: String;
      idx: integer): boolean;
    function CancelFileSending(Sender: TObject; const uname, FileName, folder: String): int64;
    procedure StopFileSending(Sender: TObject; const uname: String);

    procedure Event_LogOut(Sender: TObject);
    procedure Event_Error(Sender: TObject);

    procedure Event_FileTransInit(Sender: TObject; const user: String);
    procedure Event_FileTransOpen(Sender: TObject; const user: String);
    procedure Event_FileTransClose(Sender: TObject; const user: String);

    procedure Event_FileReadStart(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);
    procedure Event_FileRead(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);
    procedure Event_FileReadUpdate(Sender: TObject; const user: String);
    procedure Event_FileReadStop(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);
    procedure Event_FileReadCancel(Sender: TObject; const user: String;
      const fname, fromfolder: String; size: int64);

    procedure Event_FileWriteStart(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);
    procedure Event_FileWrite(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);
    procedure Event_FileWriteStop(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);
    procedure Event_FileWriteCancel(Sender: TObject; const user: String;
      const fname, tofolder: String; size: int64);

    procedure Event_CallReceived(Sender: TObject; const user: String;
      const Data: TRtcFunctionInfo);
    procedure Event_FileList(Sender: TObject; const user: String;
      const FolderName: String; const Data: TRtcDataSet);

    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const FileName, folder: String; size: int64);
      overload;
    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String); overload;
    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const Data: TRtcFunctionInfo); overload;
    procedure CallFileEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const FolderName: String;
      const Data: TRtcDataSet); overload;

    function GetAllowDownload: boolean;
    function GetAllowSuperDownload: boolean;
    function GetAllowSuperUpload: boolean;
    function GetAllowUpload: boolean;

    procedure SetAllowDownload(const Value: boolean);
    procedure SetAllowSuperDownload(const Value: boolean);
    procedure SetAllowSuperUpload(const Value: boolean);
    procedure SetAllowUpload(const Value: boolean);

    function GetAllowSuperUploadAnywhere: boolean;
    function GetAllowUploadAnywhere: boolean;
    procedure SetAllowSuperUploadAnywhere(const Value: boolean);
    procedure SetAllowUploadAnywhere(const Value: boolean);

    function GetAllowBrowse: boolean;
    function GetAllowSuperBrowse: boolean;
    procedure SetAllowBrowse(const Value: boolean);
    procedure SetAllowSuperBrowse(const Value: boolean);

    { Start sending all Files and Folder which have been waiting in our "WantToSend" buffer }
    procedure SendWaiting(const UserName: String; Sender: TObject = nil);
    function GetAllowFileDelete: boolean;
    function GetAllowFileMove: boolean;
    function GetAllowFileRename: boolean;
    function GetAllowFolderCreate: boolean;
    function GetAllowFolderDelete: boolean;
    function GetAllowFolderMove: boolean;
    function GetAllowFolderRename: boolean;
    function GetAllowShellExecute: boolean;
    function GetAllowSuperFileDelete: boolean;
    function GetAllowSuperFileMove: boolean;
    function GetAllowSuperFileRename: boolean;
    function GetAllowSuperFolderCreate: boolean;
    function GetAllowSuperFolderDelete: boolean;
    function GetAllowSuperFolderMove: boolean;
    function GetAllowSuperFolderRename: boolean;
    function GetAllowSuperShellExecute: boolean;
    procedure SetAllowFileDelete(const Value: boolean);
    procedure SetAllowFileMove(const Value: boolean);
    procedure SetAllowFileRename(const Value: boolean);
    procedure SetAllowFolderCreate(const Value: boolean);
    procedure SetAllowFolderDelete(const Value: boolean);
    procedure SetAllowFolderMove(const Value: boolean);
    procedure SetAllowFolderRename(const Value: boolean);
    procedure SetAllowShellExecute(const Value: boolean);
    procedure SetAllowSuperFileDelete(const Value: boolean);
    procedure SetAllowSuperFileMove(const Value: boolean);
    procedure SetAllowSuperFileRename(const Value: boolean);
    procedure SetAllowSuperFolderCreate(const Value: boolean);
    procedure SetAllowSuperFolderDelete(const Value: boolean);
    procedure SetAllowSuperFolderMove(const Value: boolean);
    procedure SetAllowSuperFolderRename(const Value: boolean);
    procedure SetAllowSuperShellExecute(const Value: boolean);

  protected

    procedure xOnFileTransInit(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileTransOpen(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileTransClose(Sender, Obj: TObject; Data: TRtcValue);

    procedure xOnFileReadStart(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileRead(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileReadUpdate(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileReadStop(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileReadCancel(Sender, Obj: TObject; Data: TRtcValue);

    procedure xOnFileWriteStart(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileWrite(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileWriteStop(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileWriteCancel(Sender, Obj: TObject; Data: TRtcValue);

    procedure xOnCallReceived(Sender, Obj: TObject; Data: TRtcValue);
    procedure xOnFileList(Sender, Obj: TObject; Data: TRtcValue);

    procedure xOnNewUI(Sender, Obj: TObject; Data: TRtcValue);

  protected
    //+MFT
    procedure InternalNotifyFileBatchSend(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend); virtual;
    function SendBatch(const UserName: String; FileList: TStrings;
      const Root, RemoteFolder: String; WithID: TTaskID; Sender: TObject = nil): TTaskID; overload;
    //-MFT

    function SenderLoop_Check(Sender: TObject): boolean; override;
    procedure SenderLoop_Prepare(Sender: TObject); override;
    procedure SenderLoop_Execute(Sender: TObject); override;

    procedure Call_Start(Sender: TObject; Data: TRtcValue); override;
    procedure Call_Params(Sender: TObject; Data: TRtcValue); override;

    procedure Call_Error(Sender: TObject; Data: TRtcValue); override;
    procedure Call_FatalError(Sender: TObject; Data: TRtcValue); override;

    // procedure Call_LogIn(Sender:TObject); override;
    procedure Call_LogOut(Sender: TObject); override;

    // procedure Call_BeforeData(Sender:TObject); override;
    // procedure Call_AfterData(Sender:TObject); override;

    // procedure Call_UserLoggedIn(Sender:TObject; const uname:String); override;
    // procedure Call_UserLoggedOut(Sender:TObject; const uname:String); override;

    procedure Call_UserJoinedMyGroup(Sender: TObject; const group: String;
      const uname: String; uinfo:TRtcRecord); override;
    procedure Call_UserLeftMyGroup(Sender: TObject; const group: String;
      const uname: String); override;

    procedure Call_JoinedUsersGroup(Sender: TObject; const group: String;
      const uname: String; uinfo:TRtcRecord); override;
    procedure Call_LeftUsersGroup(Sender: TObject; const group: String;
      const uname: String); override;

    procedure Call_DataFromUser(Sender: TObject; const uname: String;
      Data: TRtcFunctionInfo); override;

    procedure AddUI(UI: TRtcAbsPFileTransferUI);
    procedure RemUI(UI: TRtcAbsPFileTransferUI);

    // Functions for checking user access rights ...
    function MayUploadFiles(const user: String): boolean;
    function MayUploadAnywhere(const user: String): boolean;
    function MayDownloadFiles(const user: String): boolean;
    function MayBrowseFiles(const user: string): boolean;

    function MayMoveFiles(const user: string): boolean;
    function MayRenameFiles(const user: string): boolean;
    function MayDeleteFiles(const user: string): boolean;
    function MayShellExecute(const user: string): boolean;

    function MayMoveFolders(const user: string): boolean;
    function MayRenameFolders(const user: string): boolean;
    function MayDeleteFolders(const user: string): boolean;
    function MayCreateFolders(const user: string): boolean;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    //+MFT
    procedure CancelBatch(Sender: TObject; TaskID: TTaskID);
    function SendBatch(const UserName: String; FileList: TStrings;
      const Root, RemoteFolder: String; Sender: TObject = nil): TTaskID; overload;
    function FetchBatch(const UserName: String; FileList: TStrings;
      const Root, LocalFolder: String; Sender: TObject = nil): TTaskID;
    property TaskList: TBatchList read FTaskList;
    property NotifyFileBatchSend: TNotifyFileBatchSend read FNotifyFileBatchSend write FNotifyFileBatchSend;
    //-MFT

    // Prepare File Transfer with user "username"
    procedure Open(const UserName: String; UIVisible: Boolean; Sender: TObject = nil);
    // Terminate File Transfer with user "username"
    procedure Close(const UserName: String; Sender: TObject = nil);

    { Send (upload) File or Folder "FileName" (specify full path) to folder "ToFolder" (will use INBOX folder if not specified) at user "UserName".
      If file transfer was not prepared by calling "OpenFiles", it will be after this call. }
    procedure Send(const UserName: String; const FileName: String;
      const tofolder: String = ''; Sender: TObject = nil);

    { Fetch (download) File or Folder "FileName" (specify full path) from user "username" to folder "ToFolder" (will use INBOX folder if not specified).
      If file transfer was not prepared by calling "OpenFiles", it will be after this call. }
    procedure Fetch(const UserName: String; const FileName: String;
      const tofolder: String = ''; Sender: TObject = nil);

    procedure Cancel_Send(const UserName: String; const FileName: string;
      const tofolder: String = ''; Sender: TObject = nil);
    procedure Cancel_Fetch(const UserName: String; const FileName: string;
      const tofolder: String = ''; Sender: TObject = nil);

    procedure Cmd_NewFolder(const UserName: String; const FolderName: String;
      Sender: TObject = nil);
    procedure Cmd_FileRename(const UserName: String;
      const FileName, NewName: String; Sender: TObject = nil);
    procedure Cmd_FileDelete(const UserName: String; const FileName: String;
      Sender: TObject = nil);
    procedure Cmd_FileMove(const UserName: String;
      const FileName, NewName: String; Sender: TObject = nil);
    procedure Cmd_Execute(const UserName: String; const FileName: String;
      const Params: String = ''; Sender: TObject = nil);

    procedure Call(const UserName: String; const Data: TRtcFunctionInfo;
      Sender: TObject = nil);

    procedure GetFileList(const UserName: String;
      const FolderName, FileMask: String; Sender: TObject = nil);

  published
    { FileTransfer has 2 sides. For two clients to be able to exchange files,
      at least one side has to have BeTheHost property set to True.
      You can NOT send files between two clients if they both have BeTheHost=False.
      On the other hand, if two clients have BeTheHost=True, the one to initiate
      file transfer will become the host for the duration of file transfer. }
    property BeTheHost: boolean read FHostMode write FHostMode default False;

    property UIVisible: Boolean read FUIVisible write FUIVisible default False;

    { Set to TRUE if you wish to store access right parameters on the Gateway
      and load parameters from the Gateway after Activating the component.
      When gwStoreParams is FALSE, parameter changes will NOT be sent to the Gateway,
      nor will current parameters stored on the Gateway be loaded on start. }
    property GwStoreParams: boolean read FGatewayParams write FGatewayParams
      default False;

    { Allow Users to Browse through out files remotely ?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowBrowse: boolean read GetAllowBrowse write SetAllowBrowse
      default True;
    { Allow Super Users to Browse through out files remotely ?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowBrowse_Super: boolean read GetAllowSuperBrowse
      write SetAllowSuperBrowse default True;

    { Allow users to Download our files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowDownload: boolean read GetAllowDownload
      write SetAllowDownload default True;
    { Allow Super users to Download our files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowDownload_Super: boolean read GetAllowSuperDownload
      write SetAllowSuperDownload default True;

    { Allow users to Upload their files to us?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowUpload: boolean read GetAllowUpload write SetAllowUpload
      default True;
    { Allow Super users to Upload their files to us?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowUpload_Super: boolean read GetAllowSuperUpload
      write SetAllowSuperUpload default True;

    { Allow users to Upload their files to any folder accessible from our PC?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GUploadAnywhere: boolean read GetAllowUploadAnywhere
      write SetAllowUploadAnywhere default False;
    { Allow Super users to Upload their files to any folder accessible from our PC?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GUploadAnywhere_Super: boolean read GetAllowSuperUploadAnywhere
      write SetAllowSuperUploadAnywhere default False;

    { Allow users to MOVE my local files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFileMove: boolean read GetAllowFileMove
      write SetAllowFileMove default False;
    { Allow Super users to MOVE my local files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFileMove_Super: boolean read GetAllowSuperFileMove
      write SetAllowSuperFileMove default False;

    { Allow users to RENAME my local files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFileRename: boolean read GetAllowFileRename
      write SetAllowFileRename default False;
    { Allow Super users to MOVE my local files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFileRename_Super: boolean read GetAllowSuperFileRename
      write SetAllowSuperFileRename default False;

    { Allow users to DELETE my local files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFileDelete: boolean read GetAllowFileDelete
      write SetAllowFileDelete default False;
    { Allow Super users to DELETE my local files?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFileDelete_Super: boolean read GetAllowSuperFileDelete
      write SetAllowSuperFileDelete default False;

    { Allow users to CREATE Folders on my PC?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderCreate: boolean read GetAllowFolderCreate
      write SetAllowFolderCreate default False;
    { Allow Super users to CREATE Folders on my PC?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderCreate_Super: boolean read GetAllowSuperFolderCreate
      write SetAllowSuperFolderCreate default False;

    { Allow users to MOVE my local Folders?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderMove: boolean read GetAllowFolderMove
      write SetAllowFolderMove default False;
    { Allow Super users to MOVE my local Folders?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderMove_Super: boolean read GetAllowSuperFolderMove
      write SetAllowSuperFolderMove default False;

    { Allow users to RENAME my local Folders?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderRename: boolean read GetAllowFolderRename
      write SetAllowFolderRename default False;
    { Allow Super users to MOVE my local Folders?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderRename_Super: boolean read GetAllowSuperFolderRename
      write SetAllowSuperFolderRename default False;

    { Allow users to DELETE my local Folders?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderDelete: boolean read GetAllowFolderDelete
      write SetAllowFolderDelete default False;
    { Allow Super users to DELETE my local Folders?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowFolderDelete_Super: boolean read GetAllowSuperFolderDelete
      write SetAllowSuperFolderDelete default False;

    { Allow users to execute SHELL Commands on my PC?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowShellExecute: boolean read GetAllowShellExecute
      write SetAllowShellExecute default False;
    { Allow Super users to execute SHELL Commands on my PC?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowShellExecute_Super: boolean read GetAllowSuperShellExecute
      write SetAllowSuperShellExecute default False;

    { Set to FALSE if you want to ignore Access right settings and allow all actions,
      regardless of user lists and AllowUpload/Download parameters set by this user. }
    property AccessControl: boolean read FAccessControl write FAccessControl
      default True;

    { Folder in which all received files will be stored.
      Will be set to the current app folder+'INBOX' if left undefined. }
    property FileInboxPath: String read FFileInboxPath write FFileInboxPath;

    { Minimum chunk size (in bytes) worth sending in a loop, if we have already some data to send. }
    property MinSendChunkSize: longint read FMinSendBlock write FMinSendBlock
      default RTCP_DEFAULT_MINCHUNKSIZE;

    { Large files are split in smaller chunks. Maximum allowed chunk size is MaxSendChunkSize bytes.
      Any file larger than MaxSendChunkSize will be split in chunks of MaxSendChunkSize when sending.
      Using larger chunks may improve performance, but it can also increase the risk of a file
      never reaching it's destination if the connection is not good enough to hold for so long.
      By splitting files in smaller chunks, you allow the connection to close and be reopened
      between each file chunk, so the ammount of data that needs to be re-sent is lower. }
    property MaxSendChunkSize: longint read FMaxSendBlock write FMaxSendBlock
      default RTCP_DEFAULT_MAXCHUNKSIZE;

    { On the Host side: User with username = "user" is asking for access to our Files.

      On the Control side: User with username = "user" has invited us to see his Files.
      This event can be used on the Control side to notify the user that a Host has allowed him
      access to his Files and allow the Control to either accept Hosts invitation to view files
      or terminate the File Transfer session by setting "Allow" to FALSE, before the File Transfer opens.
      This event is most useful if you change the default implementation to allow the Host to
      invite a Control to see his files instead of the Control being the one to ask for access.

      Note that ONLY users with granted access will trigger this event. If you have already limited
      access to this Host by using the AllowUsersList, users who are NOT on that list will be ignored
      and no events will be triggered for them. So ... you could leave this event empty (not implemented)
      if you want to allow access to all users with granted access rights, or you could implement this event
      to set the "Allow" parmeter (passed into the event as TRUE) saying if this user may access our Desktop.

      If you implement this event, make sure it will not take longer than 20 seconds to complete, because
      this code is executed from the context of a connection component responsible for receiving data from
      the Gateway and if this component does not return to the Gateway before time runs out, the client will
      be disconnected from the Gateway. If you implement this event by using a dialog for the user, that dialog
      will have to auto-close whithin no more than 20 seconds automatically, selecting what ever you find apropriate. }
    property OnQueryAccess;
    { We have a new File Transfer user, username = "user";
      You can use this event to maintain a list of active File Transfer users. }
    property OnUserJoined;
    { "User" no longer has File Transfer open with us.
      You can use this event to maintain a list of active File Transfer users. }
    property OnUserLeft;

    { This event will be triggered when a FileTransferUI component is required, but still not assigned for this user.
      You should create a new FileTransferUI component in this event and assign *this* component to it's Module property.
      The FileTransferUI component will then take care of processing all events received from that user. }
    property OnNewUI: TRtcPFileTransUserEvent read FOnNewUI write FOnNewUI;

    { *Optional* Events - can be used for general monitoring. }
    property On_FileTransInit: TRtcPFileTransUserEvent read FOnFileTransInit
      write FOnFileTransInit;
    property On_FileTransOpen: TRtcPFileTransUserEvent read FOnFileTransOpen
      write FOnFileTransOpen;
    property On_FileTransClose: TRtcPFileTransUserEvent read FOnFileTransClose
      write FOnFileTransClose;

    property On_FileSendStart: TRtcPFileTransFolderEvent read FOnFileReadStart
      write FOnFileReadStart;
    property On_FileSend: TRtcPFileTransFolderEvent read FOnFileRead
      write FOnFileRead;
    property On_FileSendUpdate: TRtcPFileTransFolderEvent read FOnFileReadUpdate
      write FOnFileReadUpdate;
    property On_FileSendStop: TRtcPFileTransFolderEvent read FOnFileReadStop
      write FOnFileReadStop;
    property On_FileSendCancel: TRtcPFileTransFolderEvent read FOnFileReadCancel
      write FOnFileReadCancel;

    property On_FileRecvStart: TRtcPFileTransFolderEvent read FOnFileWriteStart
      write FOnFileWriteStart;
    property On_FileRecv: TRtcPFileTransFolderEvent read FOnFileWrite
      write FOnFileWrite;
    property On_FileRecvStop: TRtcPFileTransFolderEvent read FOnFileWriteStop
      write FOnFileWriteStop;
    property On_FileRecvCancel: TRtcPFileTransFolderEvent
      read FOnFileWriteCancel write FOnFileWriteCancel;

    property On_CallReceived: TRtcPFileTransCallEvent read FOnCallReceived
      write FOnCallReceived;
    property On_FileList: TRtcPFileTransListEvent read FOnFileList
      write FOnFileList;
  end;

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

implementation

//+MFT
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
//-MFT

constructor TRtcPFileTransfer.Create(AOwner: TComponent);
begin
  inherited;
  CSUI := TCriticalSection.Create;
  UIs := TRtcInfo.Create;

  FHostMode := False;

  FAccessControl := True;
  FAllowBrowse := True;
  FAllowSuperBrowse := True;
  FAllowUpload := True;
  FAllowDownload := True;
  FAllowSuperUpload := True;
  FAllowSuperDownload := True;
  FAllowUploadAnywhere := False;
  FAllowSuperUploadAnywhere := False;

  FMinSendBlock := RTCP_DEFAULT_MINCHUNKSIZE;
  FMaxSendBlock := RTCP_DEFAULT_MAXCHUNKSIZE;

  AmHost := TRtcRecord.Create;
  SendingFiles := TRtcArray.Create;
  UpdateFiles := TRtcRecord.Create;
  PrepareFiles := TRtcRecord.Create;
  WantToSendFiles := TRtcRecord.Create;
  File_Senders := 0;
  File_Sending := False;

  //+MFT
  FTaskList := TBatchList.Create;
  //-MFT
end;

destructor TRtcPFileTransfer.Destroy;
var
  i: integer;
  x: String;
begin
  CSUI.Acquire;
  try
    for i := 0 to UIs.Count - 1 do
    begin
      x := UIs.FieldName[i];
      if UIs.asBoolean[x] and assigned(UIs.asPtr[x]) then
        TRtcAbsPFileTransferUI(UIs.asPtr[x]).Module := nil;
    end;
    UIs.Clear;
  finally
    CSUI.Release;
  end;

  UIs.Free;
  CSUI.Free;

  WantToSendFiles.Free;
  PrepareFiles.Free;
  SendingFiles.Free;
  UpdateFiles.Free;
  AmHost.Free;

  //+MFT
  FTaskList.Free;
  //-MFT

  inherited;
end;

procedure TRtcPFileTransfer.AddUI(UI: TRtcAbsPFileTransferUI);
begin
  CSUI.Acquire;
  try
    if UIs.asBoolean[UI.UserName] then
      if assigned(UIs.asPtr[UI.UserName]) and (UIs.asPtr[UI.UserName] <> UI) then
        TRtcAbsPFileTransferUI(UIs.asPtr[UI.UserName]).Module := nil;

    UIs.asBoolean[UI.UserName] := True;
    UIs.asPtr[UI.UserName] := UI;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPFileTransfer.RemUI(UI: TRtcAbsPFileTransferUI);
begin
  CSUI.Acquire;
  try
    UIs.asBoolean[UI.UserName] := False;
    UIs.asPtr[UI.UserName] := nil;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPFileTransfer.InitData;
begin
  CS.Acquire;
  try
    SendingFiles.Clear;
    UpdateFiles.Clear;
    PrepareFiles.Clear;
    WantToSendFiles.Clear;
    AmHost.Clear;

    File_Senders := 0;
    File_Sending := False;
  finally
    CS.Release;
  end;
end;

function TRtcPFileTransfer.StartSendingFile(const UserName: String;
  const path: String; idx: integer): boolean;
var
  k: integer;
begin
  CS.Acquire;
  try
    if (PrepareFiles.isType[UserName] = rtc_Array) and
      (PrepareFiles.asArray[UserName].isType[idx] = rtc_Record) and
      (PrepareFiles.asArray[UserName].asRecord[idx].asText['path'] = path) then
    begin
      Result := True;
      File_Sending := True;
      Inc(File_Senders);

      k := SendingFiles.Count;
      SendingFiles.asObject[k] := PrepareFiles.asArray[UserName].asObject[idx];
      PrepareFiles.asArray[UserName].asObject[idx] := nil;
    end
    else
      Result := False;
  finally
    CS.Release;
  end;
end;

procedure TRtcPFileTransfer.Open(const UserName: String; UIVisible: Boolean; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  if BeTheHost then
    Client.AddUserToMyGroup(Sender, UserName, 'file')
  else
  begin
    // data to send to the user ...
    fn := TRtcFunctionInfo.Create;
    fn.FunctionName := 'files';
    fn.asBoolean['v'] := UIVisible;
    Client.SendToUser(Sender, UserName, fn);
  end;
end;

procedure TRtcPFileTransfer.Close(const UserName: String;
  Sender: TObject = nil);
begin
  StopFileSending(Sender, UserName);
  if AmHost.asBoolean[UserName] then
  begin
    AmHost.asBoolean[UserName] := False;
    Client.RemoveUserFromMyGroup(Sender, UserName, 'file');
  end
  else
    Client.LeaveUserGroup(Sender, UserName, 'file');
end;

procedure TRtcPFileTransfer.Call(const UserName: String;
  const Data: TRtcFunctionInfo; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'call';
  fn.asObject['i'] := Data;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.GetFileList(const UserName: String;
  const FolderName, FileMask: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'list';
  fn.asText['file'] := FolderName;
  if FileMask <> '' then
    fn.asText['mask'] := FileMask;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Send(const UserName: String; const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
  idx: integer;
  dts: TRtcRecord;
begin
  if not MayDownloadFiles(UserName) then
    Exit;

  if not isSubscriber(UserName) then
  begin
    CS.Acquire;
    try
      if WantToSendFiles.isType[UserName] = rtc_Null then
        WantToSendFiles.newArray(UserName);

      idx := WantToSendFiles.asArray[UserName].Count;
      with WantToSendFiles.asArray[UserName].newRecord(idx) do
      begin
        asText['file'] := FileName;
        asText['to'] := tofolder;
      end;
    finally
      CS.Release;
    end;

    Open(UserName, UIVisible, Sender);
  end
  else
  begin
    dts := TRtcRecord.Create;
    try
      dts.asText['user'] := UserName;
      dts.asText['path'] := ExtractFileName(FileName);
      dts.asText['folder'] := ExtractFilePath(FileName);
      dts.asText['to'] := tofolder;
      dts.asLargeInt['size'] := File_Content(FileName, dts.newDataSet('files'));
    except
      dts.Free;
      raise;
    end;

    CS.Acquire;
    try
      if PrepareFiles.isType[UserName] = rtc_Null then
        PrepareFiles.newArray(UserName);

      idx := PrepareFiles.asArray[UserName].Count;
      PrepareFiles.asArray[UserName].asObject[idx] := dts;

      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'putfile';
      fn.asInteger['id'] := idx;
      fn.asText['path'] := ExtractFileName(FileName);
      fn.asText['to'] := tofolder;
      fn.asLargeInt['size'] := dts.asLargeInt['size'];
    finally
      CS.Release;
    end;

    if assigned(fn) then
      Client.SendToUser(Sender, UserName, fn);
  end;
end;

procedure TRtcPFileTransfer.Fetch(const UserName: String;
  const FileName: String; const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  if not MayUploadFiles(UserName) then
    Exit;

  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'getfile';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cancel_Send(const UserName, FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fname, ffolder: String;
  fn: TRtcFunctionInfo;
  fsize: int64;
begin
  fname := ExtractFileName(FileName);
  if fname=FileName then
    ffolder:=''
  else
    ffolder := ExtractFilePath(FileName);
  fsize := CancelFileSending(Sender, UserName, fname, ffolder);

  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'abort';
  fn.asText['file'] := fname;
  fn.asText['to'] := tofolder;
  fn.asLargeInt['size'] := fsize;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cancel_Fetch(const UserName, FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'cancel';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cmd_Execute(const UserName, FileName,
  Params: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'run';
  fn.asText['file'] := FileName;
  fn.asText['par'] := Params;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cmd_FileDelete(const UserName, FileName: String;
  Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'del';
  fn.asText['file'] := FileName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cmd_FileMove(const UserName, FileName,
  NewName: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'mov';
  fn.asText['file'] := FileName;
  fn.asText['new'] := NewName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cmd_FileRename(const UserName, FileName,
  NewName: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'ren';
  fn.asText['file'] := FileName;
  fn.asText['new'] := NewName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.Cmd_NewFolder(const UserName, FolderName: String;
  Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'filecmd';
  fn.asString['c'] := 'md';
  fn.asText['dir'] := FolderName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPFileTransfer.SendWaiting(const UserName: String;
  Sender: TObject = nil);
var
  tosend: TRtcArray;
  idx: integer;
begin
  CS.Acquire;
  try
    tosend := nil;
    if WantToSendFiles.isType[UserName] = rtc_Array then
    begin
      tosend := WantToSendFiles.asArray[UserName];
      WantToSendFiles.Extract(UserName);
    end;
  finally
    CS.Release;
  end;

  if assigned(tosend) then
    try
      for idx := 0 to tosend.Count - 1 do
        Send(UserName, tosend.asRecord[idx].asText['file'],
          tosend.asRecord[idx].asText['to'], Sender);
    finally
      tosend.Free;
    end;
end;

procedure TRtcPFileTransfer.Call_Start(Sender: TObject; Data: TRtcValue);
begin
  InitData;
end;

procedure TRtcPFileTransfer.Call_Params(Sender: TObject; Data: TRtcValue);
begin
  if FGatewayParams then
    if Data.isType = rtc_Record then
      with Data.asRecord do
      begin
        FAllowBrowse := not asBoolean['NoBrowseFiles'];
        FAllowSuperBrowse := not asBoolean['NoSuperBrowseFiles'];
        FAllowDownload := not asBoolean['NoDownloadFiles'];
        FAllowUpload := not asBoolean['NoUploadFiles'];

        FAllowSuperDownload := not asBoolean['NoSuperDownloadFiles'];
        FAllowSuperUpload := not asBoolean['NoSuperUploadFiles'];
        FAllowUploadAnywhere := asBoolean['UploadAnywhere'];
        FAllowSuperUploadAnywhere := asBoolean['SuperUploadAnywhere'];

        FAllowFileDelete := asBoolean['FileDelete'];
        FAllowFileMove := asBoolean['FileMove'];
        FAllowFileRename := asBoolean['FileRename'];

        FAllowFolderCreate := asBoolean['FolderCreate'];
        FAllowFolderDelete := asBoolean['FolderDelete'];
        FAllowFolderMove := asBoolean['FolderMove'];
        FAllowFolderRename := asBoolean['FolderRename'];
        FAllowShellExecute := asBoolean['ShellExecute'];

        FAllowSuperFileDelete := asBoolean['SuperFileDelete'];
        FAllowSuperFileMove := asBoolean['SuperFileMove'];
        FAllowSuperFileRename := asBoolean['SuperFileRename'];

        FAllowSuperFolderCreate := asBoolean['SuperFolderCreate'];
        FAllowSuperFolderDelete := asBoolean['SuperFolderDelete'];
        FAllowSuperFolderMove := asBoolean['SuperFolderMove'];
        FAllowSuperFolderRename := asBoolean['SuperFolderRename'];
        FAllowSuperShellExecute := asBoolean['SuperShellExecute'];
      end;
end;

procedure TRtcPFileTransfer.Call_LogOut(Sender: TObject);
begin
  Event_LogOut(Sender);
end;

procedure TRtcPFileTransfer.Call_Error(Sender: TObject; Data: TRtcValue);
begin
  Event_Error(Sender);
end;

procedure TRtcPFileTransfer.Call_FatalError(Sender: TObject; Data: TRtcValue);
begin
  Event_Error(Sender);
end;

procedure TRtcPFileTransfer.Call_UserJoinedMyGroup(Sender: TObject;
  const group, uname: String; uinfo:TRtcRecord);
begin
  inherited;

  if (group = 'file') then
    if setSubscriber(uname, True) then
    begin
      AmHost.asBoolean[uname] := True;
      Event_NewUser(Sender, uname, uinfo);
      Event_FileTransOpen(Sender, uname);

      SendWaiting(uname, Sender);
    end;
end;

procedure TRtcPFileTransfer.Call_JoinedUsersGroup(Sender: TObject;
  const group, uname: String; uinfo:TRtcRecord);
begin
  inherited;

  if (group = 'file') then
    if not isSubscriber(uname) then
      if (MayUploadFiles(uname) or MayDownloadFiles(uname)) and
        Event_QueryAccess(Sender, uname) then
      begin
        if setSubscriber(uname, True) then
        begin
          Event_NewUser(Sender, uname, uinfo);
          Event_FileTransOpen(Sender, uname);

          SendWaiting(uname, Sender);
        end;
      end
      else
        Close(uname, Sender);
end;

procedure TRtcPFileTransfer.Call_UserLeftMyGroup(Sender: TObject;
  const group, uname: String);
begin
  if (group = 'file') then
    if setSubscriber(uname, False) then
    begin
      AmHost.asBoolean[uname] := False;
      StopFileSending(Sender, uname);
      Event_FileTransClose(Sender, uname);
      Event_OldUser(Sender, uname);
    end;

  inherited;

  //+MFT
  if (group = 'file') then
    CancelTaskByUser(Sender, uname);
  //-MFT
end;

procedure TRtcPFileTransfer.Call_LeftUsersGroup(Sender: TObject;
  const group, uname: String);
begin
  if (group = 'file') then
    if setSubscriber(uname, False) then
    begin
      StopFileSending(Sender, uname);
      Event_FileTransClose(Sender, uname);
      Event_OldUser(Sender, uname);
    end;
    
  inherited;

  //+MFT
  if (group = 'file') then
    CancelTaskByUser(Sender, uname);
  //-MFT
end;

procedure TRtcPFileTransfer.Call_DataFromUser(Sender: TObject;
  const uname: String; Data: TRtcFunctionInfo);
var
  r: TRtcFunctionInfo;
  tofolder, tofile: String;
  s: RtcString;
  loop: integer;
  WriteOK,ReadOK:boolean;

  //+MFT
  fn: TRtcFunctionInfo;
  task: TBatchTask;
  //-MFT

  function allZeroes:boolean;
    var
      a:integer;
    begin
    if length(s)=0 then 
      Result:=False
    else
      begin
      Result:=True;
      for a:=1 to length(s) do
        if s[a]<>#0 then
          begin
          Result:=False;
          Break;
          end;
      end;
    end;
  procedure WriteNow(const tofile:String);
    begin
    loop:=0; ReadOK:=False;
    repeat
      Inc(loop);
      WriteOK:=Write_File(tofile, s, rtc_ShareDenyNone);
      if WriteOK then
        begin
        ReadOK:=Read_File(tofile)=s;
        if not ReadOK then
          begin
          Log('"'+tofile+'" - '+IntToStr(loop)+'. Read FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
          Sleep(100);
          end;
        end
      else
        begin
        Log('"'+tofile+'" - '+IntToStr(loop)+'. Write FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
        Sleep(100);
        end;
      until (WriteOK and ReadOK) or (loop>=10);
    end;
  procedure WriteNowAt(const tofile:String);
    begin
    loop:=0; ReadOK:=False;
    repeat
      Inc(loop);
      WriteOK:=Write_File(tofile, s, Data.asLargeInt['at'], rtc_ShareDenyNone);
      if WriteOK then
        begin
        ReadOK:=Read_File(tofile, Data.asLargeInt['at'], length(s))=s;
        if not ReadOK then
          begin
          Log('"'+tofile+'" - '+IntToStr(loop)+'. Read FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
          Sleep(100);
          end;
        end
      else
        begin
        Log('"'+tofile+'" - '+IntToStr(loop)+'. Write FAIL @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
        Sleep(100);
        end;
      until (WriteOK and ReadOK) or (loop>=10);
    end;
begin
  if Data.FunctionName = 'file' then // user is sending us a file
  begin
    if isSubscriber(uname) and MayUploadFiles(uname) then
    begin
      s := Data.asString['data'];

      if MayUploadAnywhere(uname) then
        tofolder := Data.asText['to']
      else
        tofolder := '';
      if tofolder = '' then
        tofile := FFileInboxPath
      else
        tofile := tofolder;
      if Copy(tofile, length(tofile), 1) <> '\' then
        tofile := tofile + '\';
      tofile := tofile + Data.asText['file'];

      if not DirectoryExists(ExtractFilePath(tofile)) then
        ForceDirectories(ExtractFilePath(tofile));

      if (length(s)>0) or // content received, or ...
         (Copy(tofile, length(tofile), 1) <> '\') then // NOT a folder
        begin
        if allZeroes then
          Log('"'+tofile+'" - ZERO DATA @'+Data.asString['at']+' ('+IntToStr(length(s))+')','FILES');
        // write file content
        if Data.asLargeInt['at'] = 0 then
          // overwrite old file on first write access
          begin
          WriteNow(tofile);
          if not (WriteOK and ReadOK) then
            WriteNow(tofile+'.{ACCESS_DENIED}');
          end
        else
          // append to the end later
          begin
          if (File_Size(tofile)<>Data.asLargeInt['at']) then
            begin
            if File_Size(tofile+'.{ACCESS_DENIED}')=Data.asLargeInt['at'] then
              WriteNowAt(tofile+'.{ACCESS_DENIED}')
            else if (File_Size(tofile)>Data.asLargeInt['at']) then
              Log('"'+tofile+'" - DOUBLE DATA @'+Data.asString['at']+' /'+IntToStr(File_Size(tofile))+' ('+IntToStr(length(s))+')','FILES')
            else
              Log('"'+tofile+'" - MISSING DATA @'+Data.asString['at']+' /'+IntToStr(File_Size(tofile))+' ('+IntToStr(length(s))+')','FILES');
            end
          else
            begin
            WriteNowAt(tofile);
            if not (WriteOK and ReadOK) then
              WriteNowAt(tofile+'.{ACCESS_DENIED}');
            end;
          end;
        end;

      // set file attributes
      if not Data.isNull['fattr'] then
        FileSetAttr(tofile, Data.asInteger['fattr']);

      // set file age
      if not Data.isNull['fage'] then
        FileSetDate(tofile, DateTimeToFileDate(Data.asDateTime['fage']));

      if Data.asBoolean['stop'] then
        Event_FileWriteStop(Sender, uname, Data.asText['path'], tofolder,
          length(s))
      else
        Event_FileWrite(Sender, uname, Data.asText['path'], tofolder,
          length(s));
    end;
  end
  else if Data.FunctionName = 'putfile' then // user wants to send us a file
  begin
    if isSubscriber(uname) and MayUploadFiles(uname) then
    begin
      // tell user we are ready to accept his file
      r := TRtcFunctionInfo.Create;
      r.FunctionName := 'pfile';
      r.asInteger['id'] := Data.asInteger['id'];
      r.asText['path'] := Data.asText['path'];
      Client.SendToUser(Sender, uname, r);
      if MayUploadAnywhere(uname) then
        tofolder := Data.asText['to']
      else
        tofolder := '';
      Event_FileWriteStart(Sender, uname, Data.asText['path'], tofolder,
        Data.asLargeInt['size']);
    end;
  end
  else if Data.FunctionName = 'pfile' then
  begin
    if isSubscriber(uname) then
    // user is letting us know that we may start sending the file
      StartSendingFile(uname, Data.asText['path'], Data.asInteger['id']);
  end
  else if Data.FunctionName = 'getfile' then
  begin
    if isSubscriber(uname) then
      Send(uname, Data.asText['file'], Data.asText['to'], Sender);
  end
  else if Data.FunctionName = 'filecmd' then
  begin
    if isSubscriber(uname) then
    begin
      s := Data.asString['c']; // command
      if s = 'call' then
        Event_CallReceived(Sender, uname, Data.asFunction['i'])
      else if s = 'abort' then
      begin
        if MayUploadAnywhere(uname) then
          tofolder := Data.asText['to']
        else
          tofolder := '';
        Event_FileWriteCancel(Sender, uname, Data.asText['file'], tofolder,
          Data.asLargeInt['size']);
      end
      else if s = 'cancel' then
        Cancel_Send(uname, Data.asText['file'], Data.asText['to'], Sender)
      else if s = 'list' then
      begin
        if MayBrowseFiles(uname) then
        begin
          r := TRtcFunctionInfo.Create;
          r.FunctionName := 'filecmd';
          r.asString['c'] := 'flist';
          r.asText['file'] := Data.asText['file'];
          GetFilesList(Data.asText['file'], Data.asText['mask'],
            r.newDataSet('data'));
          Client.SendToUser(Sender, uname, r);
        end;
      end
      else if s = 'flist' then
      begin
        Event_FileList(Sender, uname, Data.asText['file'],
          Data.asDataSet['data']);
      end
      else if s = 'run' then
      begin
        if MayShellExecute(uname) then
          try
            ShellExecuteW(0, 'open', PWideChar(Data.asText['file']),
              PWideChar(Data.asText['par']), nil, SW_SHOW);
          except
            // ignore all exceptions
          end;
      end
      else if s = 'del' then
      begin
        if MayDeleteFolders(uname) then
          try
            if DirectoryExists(Data.asText['file']) then
              DelFolderTree(Data.asText['file']);
          except
            // ignore all exceptions
          end;
        if MayDeleteFiles(uname) then
          try
            if File_Exists(Data.asText['file']) then
              Delete_File(Data.asText['file']);
          except
            // ignore all exceptions
          end;
      end
      else if s = 'mov' then
      begin
        if MayMoveFolders(uname) then
          try
            if DirectoryExists(Data.asText['file']) then
              MoveFileW(PWideChar(Data.asText['file']),
                PWideChar(Data.asText['new']));
          except
            // ignore all exceptions
          end;
        if MayMoveFiles(uname) then
          try
            if File_Exists(Data.asText['file']) then
              MoveFileW(PWideChar(Data.asText['file']),
                PWideChar(Data.asText['new']));
          except
          end;
      end
      else if s = 'ren' then
      begin
        if MayRenameFolders(uname) then
          try
            if DirectoryExists(Data.asText['file']) then
              if ExtractFilePath(Data.asText['file'])
                = ExtractFilePath(Data.asText['new']) then
                MoveFileW(PWideChar(Data.asText['file']),
                  PWideChar(Data.asText['new']));
          except
            // ignore all exceptions
          end;
        if MayRenameFiles(uname) then
          try
            if File_Exists(Data.asText['file']) then
              Rename_File(Data.asText['file'], Data.asText['new']);
          except
            // ignore all exceptions
          end;
      end
      else if s = 'md' then
      begin
        if MayCreateFolders(uname) then
          try
            ForceDirectories(Data.asText['dir']);
          except
            // ignore all exceptions
          end;
      end;
    end;
  end
  else if Data.FunctionName = 'files' then
  begin
    UIVisible := Data.asBoolean['v'];
    // New "File Transfer" subscriber ...
    if BeTheHost then
      // Allow subscriptions only if "CanUpload/DownloadFiles" is enabled.
      if MayUploadFiles(uname) or MayDownloadFiles(uname) then
        if Event_QueryAccess(Sender, uname) then
        begin
          Client.AddUserToMyGroup(Sender, uname, 'file');
          Event_FileTransInit(Sender, uname);
        end;
  end;

  //+MFT
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
          InternalNotifyFileBatchSend(Sender, task, mbsTaskStart);
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
        InternalNotifyFileBatchSend(Sender, task, mbsTaskStart);
      end;

    BATCH_FUNC_TYPE_DATA:
      begin
        WriteIncomingFile(Sender, uname, Data);
      end;

    BATCH_FUNC_TYPE_FINISH:
      begin
        FinishWriteTask(Sender, Data);
      end;

    BATCH_FUNC_TYPE_ERROR:
      begin
        if not FTaskList.FindTaskByName(Data.asText['task_id'], task) then exit;
        if task.Status = sbtReceiving then
          CancelWriteTask(Sender, Data)
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
              InternalNotifyFileBatchSend(Sender, task, mbsTaskError);
              FinishTask(Sender, task, sbtCanceled);
          end;
      end;

    BATCH_FUNC_TYPE_CANCEL:
      begin
        CancelWriteTask(Sender, Data);
      end;

    BATCH_FUNC_TYPE_FETCH:
      begin
        RequestBatchFetch(Sender, uname, Data);
      end

    else
      inherited;
  end;
  //-MFT
end;

function TRtcPFileTransfer.MayDownloadFiles(const user: String): boolean;
begin
  if FAccessControl then
    Result := (FAllowDownload and Client.inUserList[user]) or
      (FAllowSuperDownload and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayUploadFiles(const user: String): boolean;
begin
  if FAccessControl then
    Result := (FAllowUpload and Client.inUserList[user]) or
      (FAllowSuperUpload and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayUploadAnywhere(const user: String): boolean;
begin
  if FAccessControl then
    Result := (FAllowUploadAnywhere and Client.inUserList[user]) or
      (FAllowSuperUploadAnywhere and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayBrowseFiles(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowBrowse and Client.inUserList[user]) or
      (FAllowSuperBrowse and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayCreateFolders(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFolderCreate and Client.inUserList[user]) or
      (FAllowSuperFolderCreate and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayDeleteFiles(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFileDelete and Client.inUserList[user]) or
      (FAllowSuperFileDelete and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayDeleteFolders(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFolderDelete and Client.inUserList[user]) or
      (FAllowSuperFolderDelete and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayMoveFiles(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFileMove and Client.inUserList[user]) or
      (FAllowSuperFileMove and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayMoveFolders(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFolderMove and Client.inUserList[user]) or
      (FAllowSuperFolderMove and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayRenameFiles(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFileRename and Client.inUserList[user]) or
      (FAllowSuperFileRename and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayRenameFolders(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowFolderRename and Client.inUserList[user]) or
      (FAllowSuperFolderRename and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.MayShellExecute(const user: string): boolean;
begin
  if FAccessControl then
    Result := (FAllowShellExecute and Client.inUserList[user]) or
      (FAllowSuperShellExecute and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPFileTransfer.SenderLoop_Check(Sender: TObject): boolean;
begin
  loop_update := nil;
  loop_tosendfile := False;

  CS.Acquire;
  try
    Result := File_Sending;
  finally
    CS.Release;
  end;

  //+MFT
  Result := Result or FTaskList.ProccessingPresent;
  //-MFT
end;

procedure TRtcPFileTransfer.SenderLoop_Prepare(Sender: TObject);
var
  a: integer;
  uname: String;
begin
  CS.Acquire;
  try
    if File_Sending then
    begin
      if UpdateFiles.Count > 0 then
      begin
        loop_update := TRtcArray.Create;
        for a := 0 to UpdateFiles.Count - 1 do
        begin
          uname := UpdateFiles.FieldName[a];
          if UpdateFiles.asBoolean[uname] then
          begin
            UpdateFiles.asBoolean[uname] := False;
            loop_update.asText[loop_update.Count] := uname;
          end;
        end;
        UpdateFiles.Clear;
      end;

      if File_Senders > 0 then
        loop_tosendfile := True
      else
        File_Sending := False;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPFileTransfer.SenderLoop_Execute(Sender: TObject);
var
  sr: TRtcRecord;
  fn: TRtcFunctionInfo;

  a: integer;

  maxRead, maxSend, sendNow: int64;

  myStop, myRead: boolean;

  s: RtcString;
  myUser: String;

  myPath, myFolder, myFile, myDest: String;

  myReadSize, mySize, myLoc: int64;

  dts: TRtcDataSet;

  function SendNextFile: boolean;
  var
    idx: integer;
    fstart: TRtcArray;
    frec: TRtcRecord;
  begin
    myStop := False;
    myRead := False;
    fn := nil;

    fstart := nil;
    try
      CS.Acquire;
      try
        for idx := 0 to SendingFiles.Count - 1 do
          if SendingFiles.isType[idx] = rtc_Record then
            with SendingFiles.asRecord[idx] do
              if not asBoolean['start'] then
              begin
                asBoolean['start'] := True;
                if not assigned(fstart) then
                  fstart := TRtcArray.Create;
                frec := fstart.newRecord(fstart.Count);
                frec.asText['user'] := asText['user'];
                frec.asText['path'] := asText['path'];
                frec.asText['folder'] := asText['folder'];
                frec.asText['to'] := asText['to'];
                frec.asLargeInt['size'] := asLargeInt['size'];
              end;
      finally
        CS.Release;
      end;
    except
      on E: Exception do
      begin
        Log('SEND.LOOP1', E);
        raise;
      end;
    end;

    if assigned(fstart) then
      try
        for idx := 0 to fstart.Count - 1 do
          with fstart.asRecord[idx] do
            Event_FileReadStart(Sender, asText['user'], asText['path'],
              asText['folder'], asLargeInt['size']);
      finally
        fstart.Free;
      end;

    CS.Acquire;
    try
      if SendingFiles.Count > 0 then
      begin
        idx := SendingFiles.Count - 1;
        while SendingFiles.isNull[idx] do
        begin
          Dec(idx);
          if idx < 0 then
            Break;
        end;
      end
      else
        idx := -1;

      if idx >= 0 then
      begin
        try
          sr := SendingFiles.asRecord[idx];

          myUser := sr.asText['user'];
          myFolder := sr.asText['folder'];
          myPath := sr.asText['path'];
          myDest := sr.asText['to'];

          UpdateFiles.asBoolean[myUser] := True;

          dts := sr.asDataSet['files'];
          dts.Last;

          myFile := dts.asText['name'];

          // re-calculate file size before sending it
          if dts.asLargeInt['sent'] = 0 then
            dts.asLargeInt['size'] := File_Size(myFolder + myFile);

          mySize := dts.asLargeInt['size'];
          myLoc := dts.asLargeInt['sent'];

          fn := TRtcFunctionInfo.Create;
          fn.FunctionName := 'file';
          fn.asText['file'] := myFile;
          fn.asText['path'] := myPath;
          if myDest <> '' then
            fn.asText['to'] := myDest;

        except
          on E: Exception do
          begin
            Log('SEND.READ1', E);
            raise;
          end;
        end;

        try
          if myLoc < mySize then
          begin
            sendNow := mySize - myLoc;
            if sendNow > maxRead then
              sendNow := maxRead;

            s := Read_File(myFolder + myFile, myLoc, sendNow);

            if length(s) > 0 then
            begin
              myRead := True;
              myReadSize := length(s);

              dts.asLargeInt['sent'] := myLoc + myReadSize;

              fn.asString['data'] := s;
              fn.asLargeInt['at'] := myLoc;

              maxRead := maxRead - myReadSize;
              maxSend := maxSend - length(fn.asString['data']);

              if dts.asLargeInt['sent'] = mySize then
              begin
                fn.asDateTime['fage'] := dts.asDateTime['age'];
                fn.asInteger['fattr'] := dts.asInteger['attr'];
                dts.Delete;
                if dts.RowCount = 0 then
                begin
                  myStop := True;
                  SendingFiles.isNull[idx] := True;
                  Dec(File_Senders);
                  fn.asBoolean['stop'] := True;
                end;
              end;
            end
            else
            begin
              fn.asDateTime['fage'] := dts.asDateTime['age'];
              fn.asInteger['fattr'] := dts.asInteger['attr'];
              dts.Delete;
              if dts.RowCount = 0 then
              begin
                myStop := True;
                SendingFiles.isNull[idx] := True;
                Dec(File_Senders);
                fn.asBoolean['stop'] := True;
              end;
            end;
          end
          else
          begin
            fn.asDateTime['fage'] := dts.asDateTime['age'];
            fn.asInteger['fattr'] := dts.asInteger['attr'];
            dts.Delete;
            if dts.RowCount = 0 then
            begin
              myStop := True;
              SendingFiles.isNull[idx] := True;
              Dec(File_Senders);
              fn.asBoolean['stop'] := True;
            end;
          end;

        except
          on E: Exception do
          begin
            Log('SEND.READ2', E);
            raise;
          end;
        end;

      end;
    finally
      CS.Release;
    end;

    if assigned(fn) then
    begin
      Client.SendToUser(Sender, myUser, fn);

      if myRead then
        Event_FileRead(Sender, myUser, myPath, myFolder, myReadSize);

      if myStop then
        Event_FileReadStop(Sender, myUser, myPath, myFolder, 0);

      Result := True;
    end
    else
      Result := False;
  end;

begin
//  Client.SendPing(Sender);

  if assigned(loop_update) then
    try
      for a := 0 to loop_update.Count - 1 do
        Event_FileReadUpdate(Sender, loop_update.asText[a]);
    finally
      loop_update.Free;
    end;

  if loop_tosendfile then
  begin
    maxRead := FMaxSendBlock; // read max 100 KB of data at once
    maxSend := FMaxSendBlock div 2; // send max 50 KB of compressed data at once
    repeat
      if not SendNextFile then
        Break;
    until (maxRead < FMinSendBlock) or (maxSend < FMinSendBlock);
  end;

  //+MFT
  SendBatchTasks(Sender);
  //-MFT
end;

procedure TRtcPFileTransfer.StopFileSending(Sender: TObject;
  const uname: String);
var
  idx: integer;
begin
  CS.Acquire;
  try
    PrepareFiles.isNull[uname] := True;
    UpdateFiles.isNull[uname] := True;
    if File_Senders > 0 then
    begin
      for idx := SendingFiles.Count - 1 downto 0 do
      begin
        if SendingFiles.isType[idx] = rtc_Record then
        begin
          if SendingFiles.asRecord[idx].asText['user'] = uname then
          begin
            SendingFiles.isNull[idx] := True;
            Dec(File_Senders);
            if File_Senders = 0 then
            begin
              SendingFiles.Clear;
              Exit;
            end;
          end;
        end;
      end;
    end;
  finally
    CS.Release;
  end;
end;

function TRtcPFileTransfer.CancelFileSending(Sender:TObject; const uname, FileName,
  folder: String): int64;
var
  fsize: int64;
  idx: integer;

begin
  Result := 0;
  CS.Acquire;
  try
    if (PrepareFiles.Count > 0) then
    begin
      for idx := PrepareFiles.Count - 1 downto 0 do
        if (PrepareFiles.isType[uname] = rtc_Array) and
          (PrepareFiles.asArray[uname].isType[idx] = rtc_Record) and
          (PrepareFiles.asArray[uname].asRecord[idx].asText['path'] = FileName) and
          ( (PrepareFiles.asArray[uname].asRecord[idx].asText['folder'] = folder) or
            (folder = '') ) then
        begin
          // Result:=Result+PrepareFiles.asArray[uname].asRecord[idx].asLargeInt['size'];
          PrepareFiles.asArray[uname].isNull[idx] := True;
        end;
    end;
    if File_Senders > 0 then
    begin
      for idx := SendingFiles.Count - 1 downto 0 do
      begin
        if (SendingFiles.isType[idx] = rtc_Record) and
          (SendingFiles.asRecord[idx].asText['user'] = uname) and
          (SendingFiles.asRecord[idx].asText['path'] = FileName) and
          ( (SendingFiles.asRecord[idx].asText['folder'] = folder) or
            (folder = '') ) then
        begin
          fsize := SendingFiles.asRecord[idx].asLargeInt['size'] -
            SendingFiles.asRecord[idx].asLargeInt['sent'];
          Result := Result + fsize;
          SendingFiles.isNull[idx] := True;

          Dec(File_Senders);
          Event_FileReadCancel(Sender, uname, FileName, folder, fsize);

          if (File_Senders = 0) then
          begin
            SendingFiles.Clear;
            Exit;
          end;
        end;
      end;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPFileTransfer.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String;
  const FileName, folder: String; size: int64);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    with Msg.newRecord do
    begin
      asText['user'] := user;
      asText['path'] := FileName;
      asText['folder'] := folder;
      asLargeInt['size'] := size;
    end;
    CallEvent(Sender, Event, Msg);
  finally
    Msg.Free;
  end;
end;

procedure TRtcPFileTransfer.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    Msg.asText := user;
    CallEvent(Sender, Event, Msg);
  finally
    Msg.Free;
  end;
end;

procedure TRtcPFileTransfer.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String; const Data: TRtcFunctionInfo);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    with Msg.newRecord do
    begin
      asText['user'] := user;
      asObject['data'] := Data; // temporary set pointer
    end;
    CallEvent(Sender, Event, Msg);
    Msg.asRecord.asObject['data'] := nil; // clear pointer
  finally
    Msg.Free;
  end;
end;

procedure TRtcPFileTransfer.CallFileEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user, FolderName: String;
  const Data: TRtcDataSet);
var
  Msg: TRtcValue;
begin
  Msg := TRtcValue.Create;
  try
    with Msg.newRecord do
    begin
      asText['user'] := user;
      asText['folder'] := FolderName;
      asObject['data'] := Data; // temporary set pointer
    end;
    CallEvent(Sender, Event, Msg);
    Msg.asRecord.asObject['data'] := nil; // clear pointer
  finally
    Msg.Free;
  end;
end;

function TRtcPFileTransfer.LockUI(const UserName: String)
  : TRtcAbsPFileTransferUI;
begin
  CSUI.Acquire;
  try
    Result := TRtcAbsPFileTransferUI(UIs.asPtr[UserName]);
    if assigned(Result) then
      Result.Locked := Result.Locked + 1;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPFileTransfer.UnlockUI(UI: TRtcAbsPFileTransferUI);
var
  toFree: boolean;
begin
  CSUI.Acquire;
  try
    UI.Locked := UI.Locked - 1;
    toFree := UI.Cleared and (UI.Locked = 0);
  finally
    CSUI.Release;
  end;
  if toFree then
    UI.Call_LogOut(nil);
end;

procedure TRtcPFileTransfer.Event_Error(Sender: TObject);
var
  UI: TRtcAbsPFileTransferUI;
  i: integer;
  user: String;
begin
  for i := 0 to UIs.Count - 1 do
  begin
    user := UIs.FieldName[i];
    UI := LockUI(user);
    if assigned(UI) then
      try
        UI.Call_Error(Sender);
      finally
        UnlockUI(UI);
      end;
  end;
end;

procedure TRtcPFileTransfer.Event_LogOut(Sender: TObject);
var
  UI: TRtcAbsPFileTransferUI;
  i: integer;
  user: String;
begin
  for i := 0 to UIs.Count - 1 do
  begin
    user := UIs.FieldName[i];
    UI := LockUI(user);
    if assigned(UI) then
      try
        UI.Call_LogOut(Sender);
      finally
        UnlockUI(UI);
      end;
  end;
end;

procedure TRtcPFileTransfer.Event_FileTransInit(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPFileTransferUI;
  Msg: TRtcValue;
begin
  if assigned(FOnFileTransInit) then
    CallFileEvent(Sender, xOnFileTransInit, user);

  UI := LockUI(user);
  if assigned(UI) then
  begin
    try
      UI.Call_Init(Sender);
    finally
      UnlockUI(UI);
    end;
  end
  else if assigned(FOnNewUI) then
  begin
    Msg := TRtcValue.Create;
    try
      Msg.asText := user;
      CallEvent(Sender, xOnNewUI, Msg);
    finally
      Msg.Free;
    end;
    UI := LockUI(user);
    if assigned(UI) then
      try
        UI.Call_Init(Sender);
      finally
        UnlockUI(UI);
      end;
  end;
end;

procedure TRtcPFileTransfer.Event_FileTransOpen(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPFileTransferUI;
  Msg: TRtcValue;
begin
  if assigned(FOnFileTransOpen) then
    CallFileEvent(Sender, xOnFileTransOpen, user);

  UI := LockUI(user);
  if assigned(UI) then
  begin
    try
      UI.Call_Open(Sender);
    finally
      UnlockUI(UI);
    end;
  end
  else if assigned(FOnNewUI) then
  begin
    Msg := TRtcValue.Create;
    try
      Msg.asText := user;
      CallEvent(Sender, xOnNewUI, Msg);
    finally
      Msg.Free;
    end;
    UI := LockUI(user);
    if assigned(UI) then
      try
        UI.Call_Open(Sender);
      finally
        UnlockUI(UI);
      end;
  end;
end;

procedure TRtcPFileTransfer.Event_FileTransClose(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileTransClose) then
    CallFileEvent(Sender, xOnFileTransClose, user);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_Close(Sender);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileReadStart(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileReadStart) then
    CallFileEvent(Sender, xOnFileReadStart, user, fname, fromfolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_ReadStart(Sender, fname, fromfolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileRead(Sender: TObject; const user: String;
  const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileRead) then
    CallFileEvent(Sender, xOnFileRead, user, fname, fromfolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_Read(Sender, fname, fromfolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileReadUpdate(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileReadUpdate) then
    CallFileEvent(Sender, xOnFileReadUpdate, user);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_ReadUpdate(Sender);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileReadStop(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileReadStop) then
    CallFileEvent(Sender, xOnFileReadStop, user, fname, fromfolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_ReadStop(Sender, fname, fromfolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileReadCancel(Sender: TObject;
  const user, fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileReadCancel) then
    CallFileEvent(Sender, xOnFileReadCancel, user, fname, fromfolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_ReadCancel(Sender, fname, fromfolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileWriteStart(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileWriteStart) then
    CallFileEvent(Sender, xOnFileWriteStart, user, fname, tofolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_WriteStart(Sender, fname, tofolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileWrite(Sender: TObject; const user: String;
  const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileWrite) then
    CallFileEvent(Sender, xOnFileWrite, user, fname, tofolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_Write(Sender, fname, tofolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileWriteStop(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileWriteStop) then
    CallFileEvent(Sender, xOnFileWriteStop, user, fname, tofolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_WriteStop(Sender, fname, tofolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileWriteCancel(Sender: TObject;
  const user, fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileWriteCancel) then
    CallFileEvent(Sender, xOnFileWriteCancel, user, fname, tofolder, size);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_WriteCancel(Sender, fname, tofolder, size);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_CallReceived(Sender: TObject;
  const user: String; const Data: TRtcFunctionInfo);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnCallReceived) then
    CallFileEvent(Sender, xOnCallReceived, user, Data);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_CallReceived(Sender, Data);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPFileTransfer.Event_FileList(Sender: TObject;
  const user, FolderName: String; const Data: TRtcDataSet);
var
  UI: TRtcAbsPFileTransferUI;
begin
  if assigned(FOnFileList) then
    CallFileEvent(Sender, xOnFileList, user, FolderName, Data);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_FileList(Sender, FolderName, Data);
    finally
      UnlockUI(UI);
    end;
end;

function TRtcPFileTransfer.GetAllowDownload: boolean;
begin
  Result := FAllowDownload;
end;

function TRtcPFileTransfer.GetAllowSuperDownload: boolean;
begin
  Result := FAllowSuperDownload;
end;

function TRtcPFileTransfer.GetAllowUpload: boolean;
begin
  Result := FAllowUpload;
end;

function TRtcPFileTransfer.GetAllowSuperUpload: boolean;
begin
  Result := FAllowSuperUpload;
end;

function TRtcPFileTransfer.GetAllowUploadAnywhere: boolean;
begin
  Result := FAllowUploadAnywhere;
end;

function TRtcPFileTransfer.GetAllowSuperUploadAnywhere: boolean;
begin
  Result := FAllowSuperUploadAnywhere;
end;

function TRtcPFileTransfer.GetAllowBrowse: boolean;
begin
  Result := FAllowBrowse;
end;

function TRtcPFileTransfer.GetAllowSuperBrowse: boolean;
begin
  Result := FAllowSuperBrowse;
end;

function TRtcPFileTransfer.GetAllowFileDelete: boolean;
begin
  Result := FAllowFileDelete;
end;

function TRtcPFileTransfer.GetAllowFileMove: boolean;
begin
  Result := FAllowFileMove;
end;

function TRtcPFileTransfer.GetAllowFileRename: boolean;
begin
  Result := FAllowFileRename;
end;

function TRtcPFileTransfer.GetAllowFolderCreate: boolean;
begin
  Result := FAllowFolderCreate;
end;

function TRtcPFileTransfer.GetAllowFolderDelete: boolean;
begin
  Result := FAllowFolderDelete;
end;

function TRtcPFileTransfer.GetAllowFolderMove: boolean;
begin
  Result := FAllowFolderMove;
end;

function TRtcPFileTransfer.GetAllowFolderRename: boolean;
begin
  Result := FAllowFolderRename;
end;

function TRtcPFileTransfer.GetAllowShellExecute: boolean;
begin
  Result := FAllowShellExecute;
end;

function TRtcPFileTransfer.GetAllowSuperFileDelete: boolean;
begin
  Result := FAllowSuperFileDelete;
end;

function TRtcPFileTransfer.GetAllowSuperFileMove: boolean;
begin
  Result := FAllowSuperFileMove;
end;

function TRtcPFileTransfer.GetAllowSuperFileRename: boolean;
begin
  Result := FAllowSuperFileRename;
end;

function TRtcPFileTransfer.GetAllowSuperFolderCreate: boolean;
begin
  Result := FAllowSuperFolderCreate;
end;

function TRtcPFileTransfer.GetAllowSuperFolderDelete: boolean;
begin
  Result := FAllowSuperFolderDelete;
end;

function TRtcPFileTransfer.GetAllowSuperFolderMove: boolean;
begin
  Result := FAllowSuperFolderMove;
end;

function TRtcPFileTransfer.GetAllowSuperFolderRename: boolean;
begin
  Result := FAllowSuperFolderRename;
end;

function TRtcPFileTransfer.GetAllowSuperShellExecute: boolean;
begin
  Result := FAllowSuperShellExecute;
end;

procedure TRtcPFileTransfer.SetAllowDownload(const Value: boolean);
begin
  if Value <> FAllowDownload then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoDownloadFiles',
        TRtcBooleanValue.Create(not Value));
    FAllowDownload := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowUpload(const Value: boolean);
begin
  if Value <> FAllowUpload then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoUploadFiles', TRtcBooleanValue.Create(not Value));
    FAllowUpload := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowUploadAnywhere(const Value: boolean);
begin
  if Value <> FAllowUploadAnywhere then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'UploadAnywhere', TRtcBooleanValue.Create(Value));
    FAllowUploadAnywhere := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperDownload(const Value: boolean);
begin
  if Value <> FAllowSuperDownload then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperDownloadFiles',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperDownload := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperUpload(const Value: boolean);
begin
  if Value <> FAllowSuperUpload then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperUploadFiles',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperUpload := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperUploadAnywhere(const Value: boolean);
begin
  if Value <> FAllowSuperUploadAnywhere then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperUploadAnywhere',
        TRtcBooleanValue.Create(Value));
    FAllowSuperUploadAnywhere := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowBrowse(const Value: boolean);
begin
  if Value <> FAllowBrowse then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoBrowseFiles', TRtcBooleanValue.Create(not Value));
    FAllowBrowse := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperBrowse(const Value: boolean);
begin
  if Value <> FAllowSuperBrowse then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperBrowseFiles',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperBrowse := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFileDelete(const Value: boolean);
begin
  if Value <> FAllowFileDelete then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FileDelete', TRtcBooleanValue.Create(Value));
    FAllowFileDelete := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFileMove(const Value: boolean);
begin
  if Value <> FAllowFileMove then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FileMove', TRtcBooleanValue.Create(Value));
    FAllowFileMove := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFileRename(const Value: boolean);
begin
  if Value <> FAllowFileRename then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FileRename', TRtcBooleanValue.Create(Value));
    FAllowFileRename := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFolderCreate(const Value: boolean);
begin
  if Value <> FAllowFolderCreate then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FolderCreate', TRtcBooleanValue.Create(Value));
    FAllowFolderCreate := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFolderDelete(const Value: boolean);
begin
  if Value <> FAllowFolderDelete then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FolderDelete', TRtcBooleanValue.Create(Value));
    FAllowFolderDelete := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFolderMove(const Value: boolean);
begin
  if Value <> FAllowFolderMove then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FolderMove', TRtcBooleanValue.Create(Value));
    FAllowFolderMove := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowFolderRename(const Value: boolean);
begin
  if Value <> FAllowFolderRename then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FolderRename', TRtcBooleanValue.Create(Value));
    FAllowFolderRename := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowShellExecute(const Value: boolean);
begin
  if Value <> FAllowShellExecute then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ShellExecute', TRtcBooleanValue.Create(Value));
    FAllowShellExecute := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFileDelete(const Value: boolean);
begin
  if Value <> FAllowSuperFileDelete then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFileDelete', TRtcBooleanValue.Create(Value));
    FAllowSuperFileDelete := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFileMove(const Value: boolean);
begin
  if Value <> FAllowSuperFileMove then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFileMove', TRtcBooleanValue.Create(Value));
    FAllowSuperFileMove := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFileRename(const Value: boolean);
begin
  if Value <> FAllowSuperFileRename then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFileRename', TRtcBooleanValue.Create(Value));
    FAllowSuperFileRename := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFolderCreate(const Value: boolean);
begin
  if Value <> FAllowSuperFolderCreate then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFolderCreate', TRtcBooleanValue.Create(Value));
    FAllowSuperFolderCreate := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFolderDelete(const Value: boolean);
begin
  if Value <> FAllowSuperFolderDelete then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFolderDelete', TRtcBooleanValue.Create(Value));
    FAllowSuperFolderDelete := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFolderMove(const Value: boolean);
begin
  if Value <> FAllowSuperFolderMove then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFolderMove', TRtcBooleanValue.Create(Value));
    FAllowSuperFolderMove := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperFolderRename(const Value: boolean);
begin
  if Value <> FAllowSuperFolderRename then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperFolderRename', TRtcBooleanValue.Create(Value));
    FAllowSuperFolderRename := Value;
  end;
end;

procedure TRtcPFileTransfer.SetAllowSuperShellExecute(const Value: boolean);
begin
  if Value <> FAllowSuperShellExecute then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'SuperShellExecute', TRtcBooleanValue.Create(Value));
    FAllowSuperShellExecute := Value;
  end;
end;

procedure TRtcPFileTransfer.xOnFileTransInit(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileTransInit(self, Data.asText);
end;

procedure TRtcPFileTransfer.xOnFileTransOpen(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileTransOpen(self, Data.asText);
end;

procedure TRtcPFileTransfer.xOnFileTransClose(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileTransClose(self, Data.asText);
end;

procedure TRtcPFileTransfer.xOnFileReadStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileRead(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileRead(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileReadUpdate(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadUpdate(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileReadStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileReadCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileWriteStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileWrite(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileWrite(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileWriteStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnFileWriteCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPFileTransfer.xOnCallReceived(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnCallReceived(self, Data.asRecord.asText['user'],
    Data.asRecord.asFunction['data']);
end;

procedure TRtcPFileTransfer.xOnFileList(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileList(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['folder'], Data.asRecord.asDataSet['data']);
end;

procedure TRtcPFileTransfer.xOnNewUI(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnNewUI(self, Data.asText);
end;

{ TRtcAbsPFileTransferUI }

constructor TRtcAbsPFileTransferUI.Create(AOwner: TComponent);
begin
  inherited;
  FModule := nil;
  FUserName := '';
end;

destructor TRtcAbsPFileTransferUI.Destroy;
begin
  Module := nil;
  inherited;
end;

procedure TRtcAbsPFileTransferUI.Open(Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Open(UserName, FModule.UIVisible, Sender);
end;

procedure TRtcAbsPFileTransferUI.Close(Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Close(UserName, Sender);
end;

function TRtcAbsPFileTransferUI.CloseAndClear(Sender: TObject = nil): boolean;
begin
  if (UserName <> '') and assigned(FModule) and not FCleared then
  begin
    Module.RemUI(self);
    Result := Locked = 0;
    FModule.Close(UserName, Sender);
    if not Result then
      FCleared := True
    else
      FModule := nil;
  end
  else
    Result := True;
end;

procedure TRtcAbsPFileTransferUI.Send(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Send(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPFileTransferUI.Fetch(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Fetch(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cancel_Fetch(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cancel_Fetch(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cancel_Send(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cancel_Send(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPFileTransferUI.Call(const Data: TRtcFunctionInfo;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Call(UserName, Data, Sender);
end;

procedure TRtcAbsPFileTransferUI.GetFileList(const FolderName, FileMask: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.GetFileList(UserName, FolderName, FileMask, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cmd_Execute(const FileName, Params: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_Execute(UserName, FileName, Params, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cmd_FileDelete(const FileName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_FileDelete(UserName, FileName, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cmd_FileMove(const FileName, NewName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_FileMove(UserName, FileName, NewName, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cmd_FileRename(const FileName, NewName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_FileRename(UserName, FileName, NewName, Sender);
end;

procedure TRtcAbsPFileTransferUI.Cmd_NewFolder(const FolderName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_NewFolder(UserName, FolderName, Sender);
end;

function TRtcAbsPFileTransferUI.GetModule: TRtcPFileTransfer;
begin
  Result := FModule;
end;

procedure TRtcAbsPFileTransferUI.SetModule(const Value: TRtcPFileTransfer);
begin
  if assigned(Value) and (UserName = '') then
    raise Exception.Create('Set "UserName" before linking to RtcPFileTransfer');
  if Value <> FModule then
  begin
    if assigned(Module) and not FCleared then
      Module.RemUI(self);
    FCleared := False;
    FModule := Value;
    if assigned(Module) then
      Module.AddUI(self);
  end;
end;

function TRtcAbsPFileTransferUI.GetUserName: String;
begin
  Result := FUserName;
end;

procedure TRtcAbsPFileTransferUI.SetUserName(const Value: String);
begin
  if assigned(Module) and (Value = '') then
    raise Exception.Create
      ('Can not clear "UserName" while linked to RtcPFileTransfer');
  if Value <> FUserName then
  begin
    if assigned(Module) then
      Module.RemUI(self);
    FUserName := Value;
    if assigned(Module) then
      Module.AddUI(self);
  end;
end;

//+MFT
procedure TRtcPFileTransfer.CancelBatch(Sender: TObject; TaskID: TTaskID);
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
      FinishTask(Sender, task, sbtCanceled);
    except
      fn.Free;
      raise;
    end;

end;

procedure TRtcPFileTransfer.CancelTaskByUser(Sender: TObject; const UserName: string);
var
  i: Integer;
begin
  FTaskList.Lock;
  try
    for i := FTaskList.Count-1 downto 0 do
      begin
        if FTaskList.Tasks[i].User = UserName then
          FinishTask(Sender, FTaskList.Tasks[i], sbtCanceled);
      end;
  finally
    FTaskList.Unlock
  end;
  FTaskList.Garbage
end;

procedure TRtcPFileTransfer.CancelWriteTask(Sender: TObject; const fn: TRtcFunctionInfo);
var
  task: TBatchTask;
begin
  if FTaskList.FindTaskByName(fn.asText['task_id'], task) then
    begin
      FinishTask(Sender, task, sbtCanceled);
      InternalNotifyFileBatchSend(Sender, task, mbsTaskFinished);
      FTaskList.Garbage;
    end;
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

procedure TRtcPFileTransfer.FinishTask(Sender: TObject; const task: TBatchTask; status: TStatusBatchTask);
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

procedure TRtcPFileTransfer.FinishWriteTask(Sender: TObject; const fn: TRtcFunctionInfo);
var
  task: TBatchTask;
begin
  if FTaskList.FindTaskByName(fn.asText['task_id'], task) then
    begin
      FinishTask(Sender, task, sbtFinished);
      InternalNotifyFileBatchSend(Sender, task, mbsTaskFinished);
      FTaskList.Garbage;
    end;
end;

procedure TRtcPFileTransfer.InternalNotifyFileBatchSend(Sender: TObject; const task: TBatchTask;
  mode: TModeBatchSend);
var
  UI: TRtcAbsPFileTransferUI;
  i: integer;
begin
  UI := LockUI(task.FUser);
  if assigned(UI) then
    try
      UI.Call_NotifyFileBatchSend(Sender, task, mode);
    finally
      UnlockUI(UI);
    end;

  if not Assigned(FNotifyFileBatchSend) then exit;

  TThread.Synchronize(TThread.CurrentThread,
    procedure ()
    begin
      task._AddRef;
      try
        FNotifyFileBatchSend(Sender, task, mode)
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
                    InternalNotifyFileBatchSend(Sender, task, mbsFileStart);

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
              InternalNotifyFileBatchSend(Sender, task, mbsFileData);
              if f.finished then
                InternalNotifyFileBatchSend(Sender, task, mbsFileStop);
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
                  InternalNotifyFileBatchSend(Sender, task, mbsTaskFinished);
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
          InternalNotifyFileBatchSend(Sender, task, mbsTaskError);
        finally
          task._Relase;
        end;
        raise;
      end;
  end;

  FTaskList.Garbage;
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
          InternalNotifyFileBatchSend(Sender, task, mbsFileStart);
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
      InternalNotifyFileBatchSend(Sender, task, mbsFileData);
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
        InternalNotifyFileBatchSend(Sender, task, mbsFileStop);
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
//-MFT

end.
