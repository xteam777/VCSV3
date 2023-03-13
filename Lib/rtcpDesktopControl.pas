{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcpDesktopControl;

interface

{$INCLUDE rtcDefs.inc}
{$INCLUDE rtcPortalDefs.inc}
{$IFDEF UNICODE}
  {$DEFINE RTC_UNICODE}
{$ENDIF}

uses
  Windows, Classes, SysUtils, Controls, rtcSystem, rtcpFileUtils,
{$IFNDEF IDE_1}
  Variants,
{$ENDIF}
  rtcLog, SyncObjs, rtcScrUtils,
  rtcInfo, rtcPortalMod,

  rtcpDesktopConst;

//FileTrans+
const
  RTCP_DEFAULT_MAXCHUNKSIZE = 100 * 1024; // 100 KB
  RTCP_DEFAULT_MINCHUNKSIZE = 4 * 1024; // 4 KB
//FileTrans-

type
  // forward
  TRtcPDesktopControl = class;

//FileTrans+
  TRtcPFileTransFolderEvent = procedure(Sender: TRtcPDesktopControl;
    const user: String; const FileName, path: String; const size: int64)
    of object;
  TRtcPFileTransCallEvent = procedure(Sender: TRtcPDesktopControl;
    const user: String; const Data: TRtcFunctionInfo) of object;
//FileTrans-


  TRtcAbsPDesktopControlUI = class(TRtcPortalComponent)
  private
    FModule: TRtcPDesktopControl;
    FUserName, FUserDesc: String;
    FMapKeys: boolean;
    FCleared: boolean;
    FLocked: integer;

    //FileTrans+
    FHostMode: boolean;

    FMaxSendBlock: longint;
    FMinSendBlock: longint;

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
    //FileTrans-

    function GetModule: TRtcPDesktopControl;
    procedure SetModule(const Value: TRtcPDesktopControl);

    function GetUserName: String;
    procedure SetUserName(const Value: String);

  protected
    procedure Call_LogOut(Sender: TObject); virtual; abstract;
    procedure Call_Error(Sender: TObject); virtual; abstract;

    procedure Call_Open(Sender: TObject); virtual; abstract;
    procedure Call_Close(Sender: TObject); virtual; abstract;

    procedure Call_Data(Sender: TObject;
      const ScreenData, CursorData: RtcString); virtual; abstract;

    procedure NotifyUI(const msg: integer; Sender: TObject = nil);
      virtual; abstract;

    property Cleared: boolean read FCleared;
    property Locked: integer read FLocked write FLocked;

    //FileTrans+
    procedure Call_Init(Sender: TObject); virtual; abstract;

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
    //FileTrans-

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Open Desktop
    procedure Open(Sender: TObject = nil); virtual;
    // Close Desktop
    procedure Close(Sender: TObject = nil); virtual;

    // Close Desktop and clear the "Module" property. The component is about to be freed.
    // Returns TRUE if the component may be destroyed now, FALSE if not.
    // If FALSE was returned, OnLogOut event will be triggered when the component may be destroyed.
    function CloseAndClear(Sender: TObject = nil): boolean; virtual;

    procedure SendMouseDown(X, Y: integer; Shift: TShiftState;
      Button: TMouseButton; Sender: TObject = nil); virtual;
    procedure SendMouseUp(X, Y: integer; Shift: TShiftState;
      Button: TMouseButton; Sender: TObject = nil); virtual;
    procedure SendMouseMove(X, Y: integer; Shift: TShiftState;
      Sender: TObject = nil); virtual;
    procedure SendMouseWheel(Wheel: integer; Shift: TShiftState;
      Sender: TObject = nil); virtual;

    procedure SendKeyDown(const Key: Word; Shift: TShiftState;
      Sender: TObject = nil); virtual;
    procedure SendKeyUp(const Key: Word; Shift: TShiftState;
      Sender: TObject = nil); virtual;

    procedure ControlStart(Sender: TObject = nil); virtual;
    procedure ControlStop(Sender: TObject = nil); virtual;

    //fileTrans+
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
    //FileTrans-

    //+sstuman
    procedure SendFilesToCopyList(sFilesDirs, sFilesDirsSizes: String; Sender: TObject);  virtual;
    //-sstuman

  published
    { Chat Module used for sending and receiving messages. }
    property Module: TRtcPDesktopControl read GetModule write SetModule;
    { Name of the Chat room owner }
    property UserName: String read GetUserName write SetUserName;
    property UserDesc: String read FUserDesc write FUserDesc;

    { Map local Keys to remote Keys (ASCII) wherever possible instead of sending scan codes? }
    property MapKeys: boolean read FMapKeys write FMapKeys default False;

  end;

  TRtcPDesktopEvent = procedure(Sender: TRtcPDesktopControl; const user: String)
    of object;
  TRtcPDesktopDataEvent = procedure(Sender: TRtcPDesktopControl;
    const user: String; const ScreenData, CursorData: RtcString) of object;

  TRtcPDesktopControl = class(TRtcPModule)
  private
    CSUI: TCriticalSection;
    UIs: TRtcInfo;

    InControl: TRtcRecord;
    Clipboards: TRtcRecord;

    LWinDown, RWinDown, LWinUsed, RWinUsed: boolean;

    FChg_DeskCnt: integer;
    FChg_Desktop: TRtcFunctionInfo;

    FOnDesktopOpen: TRtcPDesktopEvent;
    FOnDesktopClose: TRtcPDesktopEvent;
    FOnDesktopData: TRtcPDesktopDataEvent;

    FOnNewUI: TRtcPDesktopEvent;

    FSendShortcuts: Boolean;

    //FileTrans+
    loop_tosendfile: boolean;
    loop_update: TRtcArray;

    WantToSendFiles, PrepareFiles, UpdateFiles: TRtcRecord;
    SendingFiles: TRtcArray;
    File_Sending: boolean;
    File_Senders: integer;

    FMaxSendBlock: longint;
    FMinSendBlock: longint;

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

    //FileTrans-
    FHostMode: boolean;

    procedure InitData;

    procedure Event_Error(Sender: TObject);
    procedure Event_Logout(Sender: TObject);

    procedure Event_DesktopOpen(Sender: TObject; const user: String);
    procedure Event_DesktopClose(Sender: TObject; const user: String);

    procedure Event_DesktopData(Sender: TObject; const user: String;
      const ScreenData, CursorData: RtcString);

    procedure CallDesktopEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String; const ScreenData, CursorData: RtcString); overload;
    procedure CallDesktopEvent(Sender: TObject; Event: TRtcCustomDataEvent;
      const user: String); overload;

    function LockUI(const UserName: String): TRtcAbsPDesktopControlUI;
    procedure UnlockUI(UI: TRtcAbsPDesktopControlUI);

    procedure setClipboard(const UserName: String; const data: RtcString);

    //FileTrans+
    function StartSendingFile(const UserName: String; const path: String;
      idx: integer): boolean;
    function CancelFileSending(Sender: TObject; const uname, FileName, folder: String): int64;
    procedure StopFileSending(Sender: TObject; const uname: String);

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
    //FileTrans-

  protected

    procedure xOnDesktopOpen(Sendeer, Obj: TObject; data: TRtcValue);
    procedure xOnDesktopClose(Sendeer, Obj: TObject; data: TRtcValue);
    procedure xOnDesktopData(Sendeer, Obj: TObject; data: TRtcValue);

    procedure xOnNewUI(Sendeer, Obj: TObject; data: TRtcValue);

    //FileTrans+
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
    //FileTrans-

  protected

     function SenderLoop_Check(Sender:TObject):boolean; override;
     procedure SenderLoop_Prepare(Sender:TObject); override;
     procedure SenderLoop_Execute(Sender:TObject); override;

    // procedure Call_LogIn(Sender:TObject); override;
    procedure Call_LogOut(Sender: TObject); override;
    procedure Call_Error(Sender: TObject; data: TRtcValue); override;
    procedure Call_FatalError(Sender: TObject; data: TRtcValue); override;

    procedure Call_Start(Sender:TObject; Data:TRtcValue); override;
    // procedure Call_Params(Sender:TObject; Data:TRtcValue); override;

    // procedure Call_BeforeData(Sender:TObject); override;

    // procedure Call_UserLoggedIn(Sender:TObject; const uname:String); override;
    // procedure Call_UserLoggedOut(Sender:TObject; const uname:String); override;

    // procedure Call_UserJoinedMyGroup(Sender:TObject; const group:String; const uname:String); override;
    // procedure Call_UserLeftMyGroup(Sender:TObject; const group:String; const uname:String); override;

    procedure Call_JoinedUsersGroup(Sender: TObject; const group: String;
      const uname: String; uinfo:TRtcRecord); override;
    procedure Call_LeftUsersGroup(Sender: TObject; const group: String;
      const uname: String); override;

    procedure Call_DataFromUser(Sender: TObject; const uname: String;
      data: TRtcFunctionInfo); override;

    // procedure Call_AfterData(Sender:TObject); override;

    procedure AddUI(UI: TRtcAbsPDesktopControlUI);
    procedure RemUI(UI: TRtcAbsPDesktopControlUI);

    procedure Init; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Open Desktop from user "Username" }
    procedure Open(const UserName: String; Sender: TObject = nil);
    { Close Desktop from user "Username" }
    procedure Close(const UserName: String; Sender: TObject = nil);

    { Send a notification message to all connected UIs }
    procedure NotifyUI(const msg: integer; Sender: TObject = nil);

    { Send "Mouse Down" event to user "Username" }
    procedure SendMouseDown(const UserName: String; X, Y: integer;
      Shift: TShiftState; Button: TMouseButton; Sender: TObject = nil);
    { Send "Mouse Up" event to user "Username" }
    procedure SendMouseUp(const UserName: String; X, Y: integer;
      Shift: TShiftState; Button: TMouseButton; Sender: TObject = nil);
    { Send "Mouse Move" event to user "Username" }
    procedure SendMouseMove(const UserName: String; X, Y: integer;
      Shift: TShiftState; Sender: TObject = nil);
    { Send "Mouse Wheel" event to user "Username" }
    procedure SendMouseWheel(const UserName: String; Wheel: integer;
      Shift: TShiftState; Sender: TObject = nil);

    { Send "Key Down" event to user "Username".
      If "MapKeys=True", ASCII local characters will be mapped to remote Host. }
    procedure SendKeyDown(const UserName: String; MapKeys: boolean;
      const Key: Word; Shift: TShiftState; Sender: TObject = nil);
    { Send "Key Up" event to user "Username".
      If "MapKeys=True", ASCII local characters will be mapped to remote Host. }
    procedure SendKeyUp(const UserName: String; MapKeys: boolean;
      const Key: Word; Shift: TShiftState; Sender: TObject = nil);

    { We want to start controlling the Desktop from user "Username" (desktop has to be open).
      This method is used to check if local clipboard should be sent to the user "Username".
      You should call this method every time a Desktop Viewer becomes active,
      because it will make sure that remote keyboard is synchronized with your local clipboard,
      eliminating the need to use any manual operations for sending clipboard to the Host. }
    procedure ControlStart(const UserName: String; Sender: TObject = nil);
    { We want to stop contrlling the Desktop from user "Username" (desktop has to be open).
      This method is used to check if user "Username" has data on clipboard which should be sent to us.
      You should call this method every time a Desktop Viewer becomes inactive,
      because it will make sure that your local clipboard is synchronized with remote clipboard,
      eliminating the need to use any manual operations for receiving clipboard from the Host. }
    procedure ControlStop(const UserName: String; Sender: TObject = nil);

    (* Methods you can use when Desktop Control is open to user "UserName" *)

    procedure Send_SpecialKey(const UserName: String; const Key: RtcString;
      Sender: TObject = nil);

    procedure Send_CtrlAltDel(const UserName: String; Sender: TObject = nil);

    procedure Send_FileCopy(const UserName: String; Sender: TObject = nil);

    procedure Send_HideDesktop(const UserName: String; Sender: TObject = nil);
    procedure Send_ShowDesktop(const UserName: String; Sender: TObject = nil);

    procedure Send_BlockKeyboardAndMouse(const UserName: String; Sender: TObject = nil);
    procedure Send_UnBlockKeyboardAndMouse(const UserName: String; Sender: TObject = nil);

    procedure Send_PowerOffMonitor(const UserName: String; Sender: TObject = nil);
    procedure Send_PowerOnMonitor(const UserName: String; Sender: TObject = nil);
    procedure Send_LockSystem(const UserName: String; Sender: TObject = nil);
    procedure Send_PowerOffSystem(const UserName: String; Sender: TObject = nil);
    procedure Send_LogoffSystem(const UserName: String; Sender: TObject = nil);
    procedure Send_RestartSystem(const UserName: String; Sender: TObject = nil);

    procedure Send_AltTAB(const UserName: String; Sender: TObject = nil);
    procedure Send_ShiftAltTAB(const UserName: String; Sender: TObject = nil);
    procedure Send_CtrlAltTAB(const UserName: String; Sender: TObject = nil);
    procedure Send_ShiftCtrlAltTAB(const UserName: String;
      Sender: TObject = nil);

    { To change multiple parameters in a single call and
      avoid refreshing the screen for each parameter separately,
      call "ChgDesktop_Begin" before using other ChgDesk_ methods,
      then call "ChgDesktop_End" to send all changes.

      NOTE: When using ChgDesk_Begin and ChgDesk_End, you only
      have to specify the "UserName" parameter in ChgDesk_End. }

    procedure ChgDesktop_Begin;
    procedure ChgDesktop_ColorLimit(const Value: TrdColorLimit;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_FrameRate(const Value: TrdFrameRate;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_UseMirrorDriver(Value: boolean;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_UseMouseDriver(Value: boolean;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_SendScreenInBlocks(Value: TrdScreenBlocks;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_SendScreenRefineBlocks(Value: TrdScreenBlocks;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_SendScreenRefineDelay(Value: integer;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_SendScreenSizeLimit(Value: TrdScreenLimit;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_CaptureAllMonitors(Value: boolean;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_CaptureLayeredWindows(Value: boolean;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_ColorLowLimit(const Value: TrdLowColorLimit;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_ColorReducePercent(const Value: integer;
      const UserName: String = ''; Sender: TObject = nil);
    procedure ChgDesktop_End(const UserName: String; Sender: TObject = nil);

    //FileTrans+
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

    procedure Call(const UserName: String; const Data: TRtcFunctionInfo;
      Sender: TObject = nil);
    //FileTrans-

    //+sstuman
    procedure SendFilesToCopyList(const UserName: String; sFilesDirs, sFilesDirsSizes: String; Sender: TObject = nil);
    //-sstuman

  published
    { This event will be triggered when a RtcPChatUI component is required, but still not assigned for this user.
      You should create a new ChatUI component in this event and assign this component to it's Module property.
      The ChatUI component will then take care of processing all events received from that user. }
    property OnNewUI: TRtcPDesktopEvent read FOnNewUI write FOnNewUI;

    { User with username = "user" is offering us to see his Desktop.
      You could leave this event empty (not implemented) if you want to simply display the Desktop View
      window when your request to view Desktop has been granted by the Host, or ... you could use this
      event to notify the Viewer/Control that Host has allowed the Control/Viewer access and has started
      sending his desktop screen. You could also implement this event to set the "Allow" parmeter
      (passed into the event as TRUE) saying if you still want to see the Screen or not, or ...
      simply use this event to notify the Control/Viewer that a Host is asking for support if you
      have implemented the Host to select a Control/Viewer from a list and simply start pushing its
      Desktop to that user, without the user asking to see the Screen. If you set "Allow" to FALSE,
      Desktop Window will NOT be opened, you will remove yourself from Hosts Desktop receiver group
      and the Host will be notified about this, so it can stop sending its screen your way. There will
      be no special notification on the Host side. If you set "Allow" to FALSE in this event, to the
      Host it will look as if you have opened the Desktop Viewer and then closed it immediatelly.

      If you implement this event, make sure it will not take longer than 20 seconds to complete, because
      this code is executed from the context of a connection component responsible for receiving data from
      the Gateway and if this component does not return to the Gateway before time runs out, the client will
      be disconnected from the Gateway. If you implement this event by using a dialog for the user, that dialog
      will have to auto-close whithin no more than 20 seconds automatically, selecting what ever you find apropriate. }
    property OnQueryAccess;
    { We have a new Chat user, username = "user";
      You can use this event to maintain a list of active Chat users. }
    property OnUserJoined;
    { User "Data.asText" no longer has Chat open with us.
      You can use this event to maintain a list of active Chat users. }
    property OnUserLeft;

    { *Optional* These events can be used for general monitoring. }
    property On_DesktopOpen: TRtcPDesktopEvent read FOnDesktopOpen
      write FOnDesktopOpen;
    property On_DesktopClose: TRtcPDesktopEvent read FOnDesktopClose
      write FOnDesktopClose;
    property On_DesktopData: TRtcPDesktopDataEvent read FOnDesktopData
      write FOnDesktopData;

    property SendShortcuts: Boolean read FSendShortcuts write FSendShortcuts default True;

    //FileTrans+
    { FileTransfer has 2 sides. For two clients to be able to exchange files,
      at least one side has to have BeTheHost property set to True.
      You can NOT send files between two clients if they both have BeTheHost=False.
      On the other hand, if two clients have BeTheHost=True, the one to initiate
      file transfer will become the host for the duration of file transfer. }
    property BeTheHost: boolean read FHostMode write FHostMode default False;

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
    //FileTrans-
  end;

implementation

{ TRtcPDesktopControl }

constructor TRtcPDesktopControl.Create(AOwner: TComponent);
begin
  inherited;
  CSUI := TCriticalSection.Create;
  UIs := TRtcInfo.Create;

  Clipboards := TRtcRecord.Create;
  InControl := TRtcRecord.Create;

  FChg_DeskCnt := 0;
  FChg_Desktop := nil;

  LWinDown := False;
  RWinDown := False;
  LWinUsed := False;
  RWinUsed := False;

  SendShortcuts := True;

  //FileTrans+
  FHostMode := False;

  FMinSendBlock := RTCP_DEFAULT_MINCHUNKSIZE;
  FMaxSendBlock := RTCP_DEFAULT_MAXCHUNKSIZE;

  SendingFiles := TRtcArray.Create;
  UpdateFiles := TRtcRecord.Create;
  PrepareFiles := TRtcRecord.Create;
  WantToSendFiles := TRtcRecord.Create;
  File_Senders := 0;
  File_Sending := False;
  //FileTrans-
end;

destructor TRtcPDesktopControl.Destroy;
var
  i: integer;
  X: String;
begin
  CSUI.Acquire;
  try
    for i := 0 to UIs.Count - 1 do
    begin
      X := UIs.FieldName[i];
      if UIs.asBoolean[X] and assigned(UIs.asPtr[X]) then
        TRtcAbsPDesktopControlUI(UIs.asPtr[X]).Module := nil;
    end;
    UIs.Clear;
  finally
    CSUI.Release;
  end;

  if assigned(FChg_Desktop) then
  begin
    FChg_Desktop.Free;
    FChg_Desktop := nil;
    FChg_DeskCnt := 0;
  end;

  Clipboards.Free;
  InControl.Free;

  UIs.Free;
  CSUI.Free;

  //FileTrans+
  WantToSendFiles.Free;
  PrepareFiles.Free;
  SendingFiles.Free;
  UpdateFiles.Free;
  //FileTrans-

  inherited;
end;

procedure TRtcPDesktopControl.Init;
begin
  inherited;
  CS.Acquire;
  try
    Clipboards.Clear;
    InControl.Clear;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopControl.setClipboard(const UserName: String;
  const data: RtcString);
begin
  CS.Acquire;
  try
    Clipboards.asString[UserName] := data;
    Put_Clipboard(data);
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopControl.Call_LogOut(Sender: TObject);
begin
  Event_Logout(Sender);
end;

procedure TRtcPDesktopControl.Call_Error(Sender: TObject; data: TRtcValue);
begin
  Event_Error(Sender);
end;

procedure TRtcPDesktopControl.Call_FatalError(Sender: TObject; data: TRtcValue);
begin
  Event_Error(Sender);
end;

procedure TRtcPDesktopControl.Open(const UserName: String;
  Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  // Clear current clipboard, so we don't try sending it to remote
  setClipboard(UserName, '');

  // data to send to the user ...
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'desk';

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.Close(const UserName: String;
  Sender: TObject = nil);
begin
  Client.LockSender;
  try
    Client.LeaveUserGroup(Sender, UserName, 'desk');
    Client.LeaveUserGroup(Sender, UserName, 'idesk');
  finally
    Client.UnLockSender(Sender);
  end;
end;

procedure TRtcPDesktopControl.Call_JoinedUsersGroup(Sender: TObject;
  const group, uname: String; uinfo:TRtcRecord);
begin
  inherited;

  if group = 'idesk' then
  begin
    // store to change temporary to full subscription
    if not isSubscriber(uname) then
    begin
      if Event_QueryAccess(Sender, uname) then
      begin
        InControl.asBoolean[uname] := True;
        Event_NewUser(Sender, uname, uinfo);
        Event_DesktopOpen(Sender, uname);
      end
      else
        Close(uname, Sender);
    end;
  end
  else if group = 'desk' then
  begin
    if setSubscriber(uname, True) then
    begin
      // Event_NewUser(Sender, uname);
    end;
  end;
end;

procedure TRtcPDesktopControl.Call_LeftUsersGroup(Sender: TObject;
  const group, uname: String);
begin
  if group = 'idesk' then
  begin
    if not isSubscriber(uname) then
    begin
      InControl.asBoolean[uname] := False;
      Event_DesktopClose(Sender, uname);
      Event_OldUser(Sender, uname);
    end;
  end
  else if group = 'desk' then
  begin
    if setSubscriber(uname, False) then
    begin
      InControl.asBoolean[uname] := False;
      Event_DesktopClose(Sender, uname);
      Event_OldUser(Sender, uname);
    end;
  end;

  inherited;
end;

procedure TRtcPDesktopControl.Call_DataFromUser(Sender: TObject;
  const uname: String; data: TRtcFunctionInfo);
var
  uscr, ucur: RtcString;

  //FileTrans+
  r: TRtcFunctionInfo;
  s, tofolder, tofile: String;
  loop: integer;
  WriteOK,ReadOK:boolean;

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
  //FileTrans-
begin
  //FileTrans+
  if Data.FunctionName = 'file' then // user is sending us a file
  begin
    if isSubscriber(uname) then
    begin
      s := Data.asString['data'];

      tofolder := Data.asText['to'];
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
    if isSubscriber(uname) then
    begin
      // tell user we are ready to accept his file
      r := TRtcFunctionInfo.Create;
      r.FunctionName := 'pfile';
      r.asInteger['id'] := Data.asInteger['id'];
      r.asText['path'] := Data.asText['path'];
      Client.SendToUser(Sender, uname, r);
      tofolder := Data.asText['to'];
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
  else
  //FileTrans-
  if (data.FunctionName = 'desk') and (data.FieldCount > 0) then
  begin
    if InControl.asBoolean[uname] then
    begin
      if data.asString['init'] <> '' then
      begin
        // got initial data
        uscr := data.asString['init'];
        if data.asString['cur'] <> '' then
          ucur := data.asString['cur']
        else
          ucur := '';
        Event_DesktopData(Sender, uname, uscr, ucur);
      end
      else if data.asString['next'] <> '' then
      begin
        // got delta image
        uscr := data.asString['next'];
        if data.asString['cur'] <> '' then
          ucur := data.asString['cur']
        else
          ucur := '';
        Event_DesktopData(Sender, uname, uscr, ucur);
      end
      else if data.asString['cur'] <> '' then
      begin
        // got new cursor
        ucur := data.asString['cur'];
        Event_DesktopData(Sender, uname, '', ucur);
      end;
    end;
  end
  else if data.FunctionName = 'cbrd' then
  begin
    if InControl.asBoolean[uname] then
    begin
      // got new clipboard data
      ucur := data.asString['s'];
      setClipboard(uname, ucur);
    end;
  end;
end;

procedure TRtcPDesktopControl.CallDesktopEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String;
  const ScreenData, CursorData: RtcString);
var
  r: TRtcValue;
begin
  r := TRtcValue.Create;
  try
    with r.NewRecord do
    begin
      asText['user'] := user;
      asString['scr'] := ScreenData;
      asString['crs'] := CursorData;
    end;
    CallEvent(Sender, Event, r);
  finally
    r.Free;
  end;
end;

procedure TRtcPDesktopControl.CallDesktopEvent(Sender: TObject;
  Event: TRtcCustomDataEvent; const user: String);
var
  r: TRtcValue;
begin
  r := TRtcValue.Create;
  try
    r.asText := user;
    CallEvent(Sender, Event, r);
  finally
    r.Free;
  end;
end;

procedure TRtcPDesktopControl.AddUI(UI: TRtcAbsPDesktopControlUI);
begin
  CSUI.Acquire;
  try
    if UIs.asBoolean[UI.UserName] then
      if assigned(UIs.asPtr[UI.UserName]) and (UIs.asPtr[UI.UserName] <> UI) then
        TRtcAbsPDesktopControlUI(UIs.asPtr[UI.UserName]).Module := nil;

    UIs.asBoolean[UI.UserName] := True;
    UIs.asPtr[UI.UserName] := UI;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPDesktopControl.RemUI(UI: TRtcAbsPDesktopControlUI);
begin
  CSUI.Acquire;
  try
    UIs.asBoolean[UI.UserName] := False;
    UIs.asPtr[UI.UserName] := nil;
  finally
    CSUI.Release;
  end;
end;

function TRtcPDesktopControl.LockUI(const UserName: String)
  : TRtcAbsPDesktopControlUI;
begin
  CSUI.Acquire;
  try
    Result := TRtcAbsPDesktopControlUI(UIs.asPtr[UserName]);
    if assigned(Result) then
      Result.Locked := Result.Locked + 1;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPDesktopControl.UnlockUI(UI: TRtcAbsPDesktopControlUI);
var
  toFree: boolean;
begin
  CSUI.Acquire;
  try
    UI.Locked := UI.Locked - 1;
    toFree := (UI.Locked = 0) and UI.Cleared;
  finally
    CSUI.Release;
  end;
  if toFree then
    UI.Call_LogOut(nil);
end;

procedure TRtcPDesktopControl.Event_DesktopOpen(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPDesktopControlUI;
  msg: TRtcValue;
begin
  if assigned(FOnDesktopOpen) then
    CallDesktopEvent(Sender, xOnDesktopOpen, user);

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
    msg := TRtcValue.Create;
    try
      msg.asText := user;
      CallEvent(Sender, xOnNewUI, msg);
    finally
      msg.Free;
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

procedure TRtcPDesktopControl.Event_DesktopClose(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPDesktopControlUI;
begin
  if assigned(FOnDesktopClose) then
    CallDesktopEvent(Sender, xOnDesktopClose, user);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_Close(Sender);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPDesktopControl.Event_DesktopData(Sender: TObject;
  const user: String; const ScreenData, CursorData: RtcString);
var
  UI: TRtcAbsPDesktopControlUI;
begin
  if assigned(FOnDesktopData) then
    CallDesktopEvent(Sender, xOnDesktopData, user, ScreenData, CursorData);

  UI := LockUI(user);
  if assigned(UI) then
    try
      UI.Call_Data(Sender, ScreenData, CursorData);
    finally
      UnlockUI(UI);
    end;
end;

procedure TRtcPDesktopControl.Event_Error(Sender: TObject);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_Logout(Sender: TObject);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.NotifyUI(const msg: integer;
  Sender: TObject = nil);
var
  UI: TRtcAbsPDesktopControlUI;
  i: integer;
  user: String;
begin
  for i := 0 to UIs.Count - 1 do
  begin
    user := UIs.FieldName[i];
    UI := LockUI(user);
    if assigned(UI) then
      try
        UI.NotifyUI(msg, Sender);
      finally
        UnlockUI(UI);
      end;
  end;
end;

procedure TRtcPDesktopControl.xOnDesktopClose(Sendeer, Obj: TObject;
  data: TRtcValue);
begin
  FOnDesktopClose(self, data.asText);
end;

procedure TRtcPDesktopControl.xOnDesktopData(Sendeer, Obj: TObject;
  data: TRtcValue);
begin
  FOnDesktopData(self, data.asRecord.asText['user'],
    data.asRecord.asString['scr'], data.asRecord.asString['crs']);
end;

procedure TRtcPDesktopControl.xOnDesktopOpen(Sendeer, Obj: TObject;
  data: TRtcValue);
begin
  FOnDesktopOpen(self, data.asText);
end;

procedure TRtcPDesktopControl.xOnNewUI(Sendeer, Obj: TObject; data: TRtcValue);
begin
  FOnNewUI(self, data.asText);
end;

procedure TRtcPDesktopControl.ControlStart(const UserName: String;
  Sender: TObject);
var
  fn: TRtcFunctionInfo;
  clip: RtcString;
begin
  fn := nil;
  CS.Acquire;
  try
    // send Clipboard to Host
    clip := Get_Clipboard;
    if (Clipboards.isType[UserName] = rtc_Null) or
      (clip <> Clipboards.asString[UserName]) then
    begin
      Put_Clipboard(clip);
      clip := Get_Clipboard;
      if (Clipboards.isType[UserName] = rtc_Null) or
        (clip <> Clipboards.asString[UserName]) then
      begin
        if clip = '' then
        begin
          Clipboards.asString[UserName] := '';
          fn := TRtcFunctionInfo.Create;
          fn.FunctionName := 'cbrd';
          // fn.asString['s']:='';
        end
        else
        begin
          Clipboards.asString[UserName] := clip;
          fn := TRtcFunctionInfo.Create;
          fn.FunctionName := 'cbrd';
          fn.asString['s'] := clip;
        end;
      end;
    end;
  finally
    CS.Release;
  end;
  if assigned(fn) then
    Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.ControlStop(const UserName: String;
  Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  // Get Clipboard from Host
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'getcbrd';

  Client.SendToUser(Sender, UserName, fn);
end;

{$IFDEF RTC_UNICODE}

function checkKeyPressW(Key: longint): WideChar;
var
  pc: array [1 .. 10] of WideChar;
  ks: TKeyboardState;
begin
  FillChar(ks, SizeOf(ks), 0);
  GetKeyboardState(ks);
  if ToUnicode(Key, MapVirtualKey(Key, 0), ks, pc[1], 10, 0) = 1 then
  begin
    Result := pc[1];
    if vkKeyScanW(Result) and $FF <> Key and $FF then
      Result := #0;
  end
  else
    Result := #0;
end;
{$ELSE}

function checkKeyPress(Key: longint): AnsiChar;
var
  pc: array [1 .. 10] of AnsiChar;
  ks: TKeyboardState;
begin
  FillChar(ks, SizeOf(ks), 0);
  GetKeyboardState(ks);
  if ToAscii(Key, MapVirtualKey(Key, 0), ks, @pc[1], 0) = 1 then
  begin
    Result := pc[1];
    if vkKeyScanA(Result) and $FF <> Key and $FF then
      Result := #0;
  end
  else
    Result := #0;
end;
{$ENDIF}

procedure TRtcPDesktopControl.SendKeyDown(const UserName: String;
  MapKeys: boolean; const Key: Word; Shift: TShiftState; Sender: TObject);
var
  fn: TRtcFunctionInfo;
{$IFDEF RTC_UNICODE}
  c: WideChar;
{$ELSE}
  c: AnsiChar;
{$ENDIF}
begin
  if not(Key in [VK_NUMLOCK, VK_CAPITAL]) or not MapKeys then
  begin
    if (ssAlt in Shift) and (Key = VK_TAB) then
    begin
      // ignore on remote
    end
    else if (ssCtrl in Shift) and (ssAlt in Shift) and
      (Key in [VK_INSERT, VK_DELETE]) then
      Send_CtrlAltDel(UserName, Sender)
    else if (ssCtrl in Shift) and (ssAlt in Shift) and (Key = Ord('C')) then
      Send_FileCopy(UserName, Sender)
      // Alt+Win = Alt+TAB
    else if (ssAlt in Shift) and (Key in [VK_LWIN, VK_RWIN]) then
    begin
      if ssShift in Shift then
      begin
        if ssCtrl in Shift then
          Send_ShiftCtrlAltTAB(UserName, Sender)
        else
          Send_ShiftAltTAB(UserName, Sender);
      end
      else
      begin
        if ssCtrl in Shift then
          Send_CtrlAltTAB(UserName, Sender)
        else
          Send_AltTAB(UserName, Sender);
      end;
    end
    // Ctrl+Win = Hide Background
    // Ctrl+Shift+Win = Show Background
    else if (ssCtrl in Shift) and (Key in [VK_LWIN, VK_RWIN]) then
    begin
      if ssShift in Shift then
        Send_ShowDesktop(UserName, Sender)
      else
        Send_HideDesktop(UserName, Sender);
    end
    // Shift+Win = Win
    else if (Key in [VK_LWIN, VK_RWIN]) then
    begin
//      if ssShift in Shift then
      if SendShortcuts then
      begin
        if Key = VK_LWIN then
        begin
          LWinDown := True;
          LWinUsed := False;
        end
        else
        begin
          RWinDown := True;
          RWinUsed := False;
        end;
      end;
    end
    else if LWinDown and (Key in [65 .. 90]) then
    begin
      LWinUsed := True;
      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'key';
      fn.asInteger['lw'] := Key;
      Client.SendToUser(Sender, UserName, fn);
    end
    else if RWinDown and (Key in [65 .. 90]) then
    begin
      RWinUsed := True;
      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'key';
      fn.asInteger['rw'] := Key;
      Client.SendToUser(Sender, UserName, fn);
    end
    else
    begin
      if MapKeys then
{$IFDEF RTC_UNICODE}
        c := checkKeyPressW(Key)
{$ELSE}
        c := checkKeyPress(Key)
{$ENDIF}
      else
        c := #0;
      if c = #0 then
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'key';
        fn.asInteger['d'] := Key;
        Client.SendToUser(Sender, UserName, fn);
      end
      else
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'key';
{$IFDEF RTC_UNICODE}
        fn.asWideString['p'] := c;
{$ELSE}
        fn.asString['p'] := c;
{$ENDIF}
        fn.asInteger['k'] := Key;
        Client.SendToUser(Sender, UserName, fn);
      end;
    end;
  end;
end;

procedure TRtcPDesktopControl.SendKeyUp(const UserName: String;
  MapKeys: boolean; const Key: Word; Shift: TShiftState; Sender: TObject);
var
  fn: TRtcFunctionInfo;
{$IFDEF RTC_UNICODE}
  c: WideChar;
{$ELSE}
  c: AnsiChar;
{$ENDIF}
begin
  if not(Key in [VK_NUMLOCK, VK_CAPITAL]) or not MapKeys then
  begin
    if (LWinDown or RWinDown) and (Key in [VK_LWIN, VK_RWIN, 65 .. 90]) then
    begin
      if LWinDown and (Key = VK_LWIN) then
      begin
        // LWin released
        LWinDown := False;
        if not LWinUsed then
        begin
          LWinUsed := False;
          fn := TRtcFunctionInfo.Create;
          fn.FunctionName := 'key';
          fn.asString['s'] := 'WIN';
          Client.SendToUser(Sender, UserName, fn);
        end;
      end
      else if RWinDown and (Key = VK_RWIN) then
      begin
        // RWin released
        RWinDown := False;
        if not RWinUsed then
        begin
          RWinUsed := False;
          fn := TRtcFunctionInfo.Create;
          fn.FunctionName := 'key';
          fn.asString['s'] := 'RWIN';
          Client.SendToUser(Sender, UserName, fn);
        end;
      end;
    end
    else if (Key in [VK_LWIN, VK_RWIN]) then
    begin
      // ignore simple LWIN and RWIN
    end
    else if ((ssCtrl in Shift) and (ssAlt in Shift) and
      (Key in [VK_INSERT, VK_DELETE])) or ((ssAlt in Shift) and (Key = VK_TAB))
    then
    begin
      // ignore KeyUp for Ctrl+Alt-Insert,Left,Right,Up,Down
    end
    else
    begin
      if MapKeys then
{$IFDEF RTC_UNICODE}
        c := checkKeyPressW(Key)
{$ELSE}
        c := checkKeyPress(Key)
{$ENDIF}
      else
        c := #0;
      if c = #0 then
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'key';
        fn.asInteger['u'] := Key;
        Client.SendToUser(Sender, UserName, fn);
      end;
    end;
  end;
end;

procedure TRtcPDesktopControl.SendMouseDown(const UserName: String;
  X, Y: integer; Shift: TShiftState; Button: TMouseButton; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'mouse';
  case Button of // Mouse Down
    mbLeft:
      fn.asInteger['d'] := 1;
    mbRight:
      fn.asInteger['d'] := 2;
    mbMiddle:
      fn.asInteger['d'] := 3;
  end;
  fn.asInteger['x'] := X;
  fn.asInteger['y'] := Y;

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.SendMouseMove(const UserName: String;
  X, Y: integer; Shift: TShiftState; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'mouse';
  fn.asInteger['x'] := X;
  fn.asInteger['y'] := Y;

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.SendMouseUp(const UserName: String; X, Y: integer;
  Shift: TShiftState; Button: TMouseButton; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'mouse';
  case Button of // Mouse Up
    mbLeft:
      fn.asInteger['u'] := 1;
    mbRight:
      fn.asInteger['u'] := 2;
    mbMiddle:
      fn.asInteger['u'] := 3;
  end;
  fn.asInteger['x'] := X;
  fn.asInteger['y'] := Y;

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.SendMouseWheel(const UserName: String;
  Wheel: integer; Shift: TShiftState; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'mouse';
  fn.asInteger['w'] := Wheel;

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.Send_SpecialKey(const UserName: String;
  const Key: RtcString; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'key';
  fn.asString['s'] := Key; // Special Key to send

  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.Send_CtrlAltDel(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'CAD', Sender);
end;

procedure TRtcPDesktopControl.Send_FileCopy(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'COPY', Sender);
end;

procedure TRtcPDesktopControl.Send_AltTAB(const UserName: String;
  Sender: TObject);
begin
  if not FSendShortcuts then //sstuman
    Exit;

  Send_SpecialKey(UserName, 'AT', Sender);
end;

procedure TRtcPDesktopControl.Send_ShiftAltTAB(const UserName: String;
  Sender: TObject);
begin
  if not FSendShortcuts then //sstuman
    Exit;

  Send_SpecialKey(UserName, 'SAT', Sender);
end;

procedure TRtcPDesktopControl.Send_CtrlAltTAB(const UserName: String;
  Sender: TObject);
begin
  if not FSendShortcuts then //sstuman
    Exit;

  Send_SpecialKey(UserName, 'CAT', Sender);
end;

procedure TRtcPDesktopControl.Send_ShiftCtrlAltTAB(const UserName: String;
  Sender: TObject);
begin
  if not FSendShortcuts then //sstuman
    Exit;

  Send_SpecialKey(UserName, 'SCAT', Sender);
end;

procedure TRtcPDesktopControl.Send_HideDesktop(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'HDESK', Sender);
end;

procedure TRtcPDesktopControl.Send_ShowDesktop(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'SDESK', Sender);
end;

procedure TRtcPDesktopControl.Send_BlockKeyboardAndMouse(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'BKM', Sender);
end;

procedure TRtcPDesktopControl.Send_UnBlockKeyboardAndMouse(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'UBKM', Sender);
end;

procedure TRtcPDesktopControl.Send_PowerOffMonitor(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'OFFMON', Sender);
end;

procedure TRtcPDesktopControl.Send_PowerOnMonitor(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'ONMON', Sender);
end;

procedure TRtcPDesktopControl.Send_PowerOffSystem(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'OFFSYS', Sender);
end;

procedure TRtcPDesktopControl.Send_LockSystem(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'LCKSYS', Sender);
end;

procedure TRtcPDesktopControl.Send_LogoffSystem(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'LOGOFF', Sender);
end;

procedure TRtcPDesktopControl.Send_RestartSystem(const UserName: String;
  Sender: TObject);
begin
  Send_SpecialKey(UserName, 'RSTRT', Sender);
end;

procedure TRtcPDesktopControl.ChgDesktop_Begin;
begin
  Inc(FChg_DeskCnt);
  if FChg_DeskCnt = 1 then
  begin
    FChg_Desktop := TRtcFunctionInfo.Create;
    FChg_Desktop.FunctionName := 'chgdesk';
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_End(const UserName: String;
  Sender: TObject = nil);
begin
  Dec(FChg_DeskCnt);
  if FChg_DeskCnt = 0 then
  begin
    if assigned(Client) then
    begin
      if UserName = '' then
        raise Exception.Create
          ('UserName required in the ChgDesktop_End method.');
      Client.SendToUser(Sender, UserName, FChg_Desktop);
      FChg_Desktop := nil;
    end
    else
    begin
      FChg_Desktop.Free;
      FChg_Desktop := nil;
    end;
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_CaptureAllMonitors(Value: boolean;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['monitors'] := Value;
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_CaptureLayeredWindows(Value: boolean;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['layered'] := Value;
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_ColorLimit(const Value: TrdColorLimit;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['color'] := Ord(Value);
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_ColorLowLimit
  (const Value: TrdLowColorLimit; const UserName: String = '';
  Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['colorlow'] := Ord(Value);
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_ColorReducePercent
  (const Value: integer; const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['colorpercent'] := Value;
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_FrameRate(const Value: TrdFrameRate;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['frame'] := Ord(Value);
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_SendScreenInBlocks
  (Value: TrdScreenBlocks; const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scrblocks'] := Ord(Value);
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_SendScreenRefineBlocks
  (Value: TrdScreenBlocks; const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scrblocks2'] := Ord(Value);
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_SendScreenRefineDelay(Value: integer;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scr2delay'] := Value;
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_SendScreenSizeLimit
  (Value: TrdScreenLimit; const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asInteger['scrlimit'] := Ord(Value);
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_UseMirrorDriver(Value: boolean;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['mirror'] := Value;
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

procedure TRtcPDesktopControl.ChgDesktop_UseMouseDriver(Value: boolean;
  const UserName: String = ''; Sender: TObject = nil);
begin
  ChgDesktop_Begin;
  try
    FChg_Desktop.asBoolean['mouse'] := Value;
  finally
    ChgDesktop_End(UserName, Sender);
  end;
end;

{ TRtcAbsPDesktopControlUI }

constructor TRtcAbsPDesktopControlUI.Create(AOwner: TComponent);
begin
  inherited;
  FMapKeys := False;
end;

destructor TRtcAbsPDesktopControlUI.Destroy;
begin
  Module := nil;
  inherited;
end;

procedure TRtcAbsPDesktopControlUI.SetModule(const Value: TRtcPDesktopControl);
begin
  if assigned(Value) and (UserName = '') then
    raise Exception.Create
      ('Set "UserName" before linking to RtcPDesktopControl');
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

function TRtcAbsPDesktopControlUI.GetModule: TRtcPDesktopControl;
begin
  Result := FModule;
end;

procedure TRtcAbsPDesktopControlUI.SetUserName(const Value: String);
begin
  if assigned(Module) and (Value = '') then
    raise Exception.Create
      ('Can not clear "UserName" while linked to RtcPDesktopControl');
  if Value <> FUserName then
  begin
    if assigned(Module) then
      Module.RemUI(self);
    FUserName := Value;
    if assigned(Module) then
      Module.AddUI(self);
  end;
end;

function TRtcAbsPDesktopControlUI.GetUserName: String;
begin
  Result := FUserName;
end;

procedure TRtcAbsPDesktopControlUI.Open(Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Open(UserName, Sender);
end;

procedure TRtcAbsPDesktopControlUI.Close(Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Close(UserName, Sender);
end;

function TRtcAbsPDesktopControlUI.CloseAndClear(Sender: TObject = nil): boolean;
begin
  if (UserName <> '') and assigned(FModule) and not FCleared then
  begin
    Module.RemUI(self);
    Result := Locked = 0;
    FModule.Close(UserName, nil);
    if not Result then
      FCleared := True
    else
      FModule := nil;
  end
  else
    Result := True;
end;

procedure TRtcAbsPDesktopControlUI.ControlStart(Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.ControlStart(UserName, Sender);
end;

procedure TRtcAbsPDesktopControlUI.ControlStop(Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.ControlStop(UserName, Sender);
end;

procedure TRtcAbsPDesktopControlUI.SendKeyDown(const Key: Word;
  Shift: TShiftState; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendKeyDown(UserName, MapKeys, Key, Shift, Sender);
end;

procedure TRtcAbsPDesktopControlUI.SendKeyUp(const Key: Word;
  Shift: TShiftState; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendKeyUp(UserName, MapKeys, Key, Shift, Sender);
end;

procedure TRtcAbsPDesktopControlUI.SendMouseDown(X, Y: integer;
  Shift: TShiftState; Button: TMouseButton; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendMouseDown(UserName, X, Y, Shift, Button, Sender);
end;

procedure TRtcAbsPDesktopControlUI.SendMouseMove(X, Y: integer;
  Shift: TShiftState; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendMouseMove(UserName, X, Y, Shift, Sender);
end;

procedure TRtcAbsPDesktopControlUI.SendMouseUp(X, Y: integer;
  Shift: TShiftState; Button: TMouseButton; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendMouseUp(UserName, X, Y, Shift, Button, Sender);
end;

procedure TRtcAbsPDesktopControlUI.SendMouseWheel(Wheel: integer;
  Shift: TShiftState; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendMouseWheel(UserName, Wheel, Shift, Sender);
end;

//FileTrans+
procedure TRtcPDesktopControl.xOnFileReadStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileRead(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileRead(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileReadUpdate(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadUpdate(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileReadStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileReadCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileWriteStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileWrite(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileWrite(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileWriteStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnFileWriteCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopControl.xOnCallReceived(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnCallReceived(self, Data.asRecord.asText['user'],
    Data.asRecord.asFunction['data']);
end;

function TRtcPDesktopControl.StartSendingFile(const UserName: String;
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

function TRtcPDesktopControl.CancelFileSending(Sender:TObject; const uname, FileName,
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

procedure TRtcPDesktopControl.StopFileSending(Sender: TObject;
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

procedure TRtcPDesktopControl.Event_FileReadStart(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileRead(Sender: TObject; const user: String;
  const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileReadUpdate(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileReadStop(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileReadCancel(Sender: TObject;
  const user, fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileWriteStart(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileWrite(Sender: TObject; const user: String;
  const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileWriteStop(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_FileWriteCancel(Sender: TObject;
  const user, fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.Event_CallReceived(Sender: TObject;
  const user: String; const Data: TRtcFunctionInfo);
var
  UI: TRtcAbsPDesktopControlUI;
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

procedure TRtcPDesktopControl.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopControl.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopControl.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopControl.CallFileEvent(Sender: TObject;
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

procedure TRtcAbsPDesktopControlUI.Send(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Send(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPDesktopControlUI.Fetch(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Fetch(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPDesktopControlUI.Cancel_Fetch(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cancel_Fetch(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPDesktopControlUI.Cancel_Send(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cancel_Send(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPDesktopControlUI.Call(const Data: TRtcFunctionInfo;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Call(UserName, Data, Sender);
end;

procedure TRtcPDesktopControl.Call(const UserName: String;
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

procedure TRtcPDesktopControl.Send(const UserName: String; const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
  idx: integer;
  dts: TRtcRecord;
begin
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

    Open(UserName, Sender);
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

procedure TRtcPDesktopControl.Fetch(const UserName: String;
  const FileName: String; const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'getfile';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopControl.Cancel_Send(const UserName, FileName: String;
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

procedure TRtcPDesktopControl.Cancel_Fetch(const UserName, FileName: String;
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

function TRtcPDesktopControl.SenderLoop_Check(Sender: TObject): boolean;
begin
  loop_update := nil;
  loop_tosendfile := False;

  CS.Acquire;
  try
    Result := File_Sending;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopControl.SenderLoop_Prepare(Sender: TObject);
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

procedure TRtcPDesktopControl.SenderLoop_Execute(Sender: TObject);
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
end;

procedure TRtcPDesktopControl.InitData;
begin
  CS.Acquire;
  try
    SendingFiles.Clear;
    UpdateFiles.Clear;
    PrepareFiles.Clear;
    WantToSendFiles.Clear;

    File_Senders := 0;
    File_Sending := False;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopControl.Call_Start(Sender: TObject; data: TRtcValue);
begin
  InitData;
end;
//FileTrans-

//////////////////////////////////DETOURS//////////////////////////////////

procedure TRtcAbsPDesktopControlUI.SendFilesToCopyList(sFilesDirs, sFilesDirsSizes: String; Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.SendFilesToCopyList(UserName, sFilesDirs, sFilesDirsSizes, Sender);
end;

procedure TRtcPDesktopControl.SendFilesToCopyList(const UserName: String;
  sFilesDirs, sFilesDirsSizes: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'files_to_copy_list';
  fn.asString['f'] := sFilesDirs;
  fn.asString['s'] := sFilesDirsSizes;

  Client.SendToUser(Sender, UserName, fn);
end;

end.
