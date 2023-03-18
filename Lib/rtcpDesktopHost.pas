{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcpDesktopHost;

interface

{$INCLUDE rtcDefs.inc}
{$INCLUDE rtcPortalDefs.inc}

uses
  Windows, Messages, Classes, SysUtils, Graphics, Controls, Forms, CommonData, BlackLayered, rtcBlankOutForm,
  ShlObj, Clipbrd, IOUtils, DateUtils, SHDocVw, ExtCtrls, ActiveX, ShellApi, ComObj, ClipbrdMonitor,
{$IFNDEF IDE_1}
  Variants,
{$ENDIF}
  rtcLog, SyncObjs, rtcpFileUtils,
  rtcInfo, rtcPortalMod, uProcess,

  rtcScrCapture, rtcScrUtils,
  rtcWinLogon, rtcSystem,

  uVircessTypes, NTPriveleges,

  rtcpFileTrans, //ImageCatcher,
  rtcpDesktopConst, ServiceMgr,
  Execute.DesktopDuplicationAPI;

var
  RTC_CAPTUREBLT: DWORD = $40000000;

type
  { captureEverything = captures the Desktop and all Windows.
    captureDesktopOnly =  only captures the Desktop background.
    captureWindowOnly = only captures the Window specified in "RtcCaptureWindowHdl" }
  TRtcCaptureMode=(captureEverything, captureDesktopOnly, captureWindowOnly);
  TRtcMouseControlMode=(eventMouseControl, messageMouseControl);

var
  RtcCaptureMode: TRtcCaptureMode = captureEverything;
  RtcCaptureWindowHdl:HWND=0;

  RtcMouseControlMode: TRtcMouseControlMode = eventMouseControl;

type
  TRtcPDesktopHost = class;

  TRtcPFileTransUserEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String) of object;
  TRtcPFileTransFolderEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const FileName, path: String; const size: int64)
    of object;
  TRtcPFileTransCallEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const Data: TRtcFunctionInfo) of object;
  TRtcPFileTransListEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const FolderName: String; const Data: TRtcDataSet)
    of object;

  TRtcPDesktopHostUIEvent = procedure(Sender: TRtcPDesktopHost)
    of object;

  TRtcAbsPHostFileTransferUI = class(TRtcPortalComponent)
  private
    FModule: TRtcPDesktopHost;
    FUserName, FUserDesc: String;
    FCleared: boolean;
    FLocked: integer;

    function GetModule: TRtcPDesktopHost;
    procedure SetModule(const Value: TRtcPDesktopHost);

    function GetUserName: String;
    procedure SetUserName(const Value: String);

  public
    procedure Call_LogOut(Sender: TObject); virtual; abstract;
    procedure Call_Error(Sender: TObject); virtual; abstract;

    procedure Call_Init(Sender: TObject); virtual; abstract;
    procedure Call_Open(Sender: TObject); virtual; abstract;
    procedure Call_Close(Sender: TObject); virtual; abstract;

    property Cleared: boolean read FCleared;
    property Locked: integer read FLocked write FLocked;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

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
    property Module: TRtcPDesktopHost read GetModule write SetModule;
    { Name of the user we are communicating with }
    property UserName: String read GetUserName write SetUserName;
    property UserDesc: String read FUserDesc write FUserDesc;
  end;

  TRtcPHostFileTransUserEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String) of object;
  TRtcPHostFileTransFolderEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const FileName, path: String; const size: int64)
    of object;
  TRtcPHostFileTransCallEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const Data: TRtcFunctionInfo) of object;
  TRtcPHostFileTransListEvent = procedure(Sender: TRtcPDesktopHost;
    const user: String; const FolderName: String; const Data: TRtcDataSet)
    of object;

  TRtcPDesktopHost = class(TRtcPModule)
  private
    CS2: TCriticalSection;
    Clipboards: TRtcRecord;
    FLastMouseUser: String;
    FDesktopActive: boolean;

    Scr: TRtcScreenCapture;
    LastGrab: longword;

    FramePause, FrameSleep: longword;

    RestartRequested: boolean;

    FShowFullScreen: boolean;
    FScreenRect: TRect;

    FUseMouseDriver: boolean;
    FUseMirrorDriver: boolean;
    FCaptureAllMonitors: boolean;
//    FCaptureLayeredWindows: boolean;
    FScreenInBlocks: TrdScreenBlocks;
    FScreenRefineBlocks: TrdScreenBlocks;
    FScreenRefineDelay: integer;
    FScreenSizeLimit: TrdScreenLimit;

    FColorLimit: TrdColorLimit;
    FLowColorLimit: TrdLowColorLimit;
    FColorReducePercent: integer;
    FFrameRate: TrdFrameRate;

    FAllowControl: boolean;
    FAllowView: boolean;

    FAllowSuperControl: boolean;
    FAllowSuperView: boolean;

    loop_needtosend, loop_need_restart: boolean;
    loop_s1, loop_s2: RtcString;

    _desksub: TRtcArray;
    _sub_desk: TRtcRecord;

    FAccessControl: boolean;
    FGatewayParams: boolean;

    FFileTrans: TRtcPFileTransfer;

    //FileTrans+
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

    FOnNewUI: TRtcPHostFileTransUserEvent;

    FMaxSendBlock: longint;
    FMinSendBlock: longint;

    FHostMode: boolean;

    CSUI: TCriticalSection;
    UIs: TRtcInfo;
    //FileTrans-

    //FileTrans+
    procedure InitData;

    function LockUI(const UserName: String): TRtcAbsPHostFileTransferUI;
    procedure UnlockUI(UI: TRtcAbsPHostFileTransferUI);

    procedure Event_LogOut(Sender: TObject);
    procedure Event_Error(Sender: TObject);

    procedure Event_FileTransInit(Sender: TObject; const user: String);
    procedure Event_FileTransOpen(Sender: TObject; const user: String);
    procedure Event_FileTransClose(Sender: TObject; const user: String);

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

    { Start sending all Files and Folder which have been waiting in our "WantToSend" buffer }
    procedure SendWaiting(const UserName: String; Sender: TObject = nil);
    //FileTrans-

    procedure setClipboard(const username: String; const data: RtcString);

    procedure ScrStart;
    procedure ScrStop;

    function GetLastMouseUser: String;
    function GetColorLimit: TrdColorLimit;
    function GetLowColorLimit: TrdLowColorLimit;
    function GetFrameRate: TrdFrameRate;
    function GetShowFullScreen: boolean;
    function GetUseMirrorDriver: boolean;
    function GetUseMouseDriver: boolean;
//    function GetCaptureLayeredWindows: boolean;

    procedure SetColorLimit(const Value: TrdColorLimit);
    procedure SetLowColorLimit(const Value: TrdLowColorLimit);
    procedure SetFrameRate(const Value: TrdFrameRate);
    procedure SetShowFullScreen(const Value: boolean);
    procedure SetUseMirrorDriver(const Value: boolean);
    procedure SetUseMouseDriver(const Value: boolean);
//    procedure SetCaptureLayeredWindows(const Value: boolean);

    function setDeskSubscriber(const username: String; active: boolean)
      : boolean;

    function GetAllowControl: boolean;
    function GetAllowSuperControl: boolean;
    function GetAllowSuperView: boolean;
    function GetAllowView: boolean;
    procedure SetAllowControl(const Value: boolean);
    procedure SetAllowSuperControl(const Value: boolean);
    procedure SetAllowSuperView(const Value: boolean);
    procedure SetAllowView(const Value: boolean);

    function GetCaptureAllMonitors: boolean;
    procedure SetCaptureAllMonitors(const Value: boolean);

    function GetColorReducePercent: integer;
    procedure SetColorReducePercent(const Value: integer);

    function MayViewDesktop(const user: String): boolean;
    function MayControlDesktop(const user: String): boolean;

    procedure SetFileTrans(const Value: TRtcPFileTransfer);
    procedure MakeDesktopActive;

    function GetSendScreenInBlocks: TrdScreenBlocks;
    function GetSendScreenRefineBlocks: TrdScreenBlocks;
    function GetSendScreenRefineDelay: integer;
    function GetSendScreenSizeLimit: TrdScreenLimit;

    procedure SetSendScreenInBlocks(const Value: TrdScreenBlocks);
    procedure SetSendScreenRefineBlocks(const Value: TrdScreenBlocks);
    procedure SetSendScreenRefineDelay(const Value: integer);
    procedure SetSendScreenSizeLimit(const Value: TrdScreenLimit);

  protected
    // Implement if you are linking to any other TRtcPModule. Usage:
    // Check if you are refferencing the "Module" component and remove the refference
    procedure UnlinkModule(const Module: TRtcPModule); override;

    function SenderLoop_Check(Sender: TObject): boolean; override;
    procedure SenderLoop_Prepare(Sender: TObject); override;
    procedure SenderLoop_Execute(Sender: TObject); override;

    procedure Call_LogIn(Sender: TObject); override;
    procedure Call_LogOut(Sender: TObject); override;
    procedure Call_Error(Sender: TObject; Data: TRtcValue); override;
    procedure Call_FatalError(Sender: TObject; data: TRtcValue); override;

    procedure Call_Start(Sender: TObject; data: TRtcValue); override;
    procedure Call_Params(Sender: TObject; data: TRtcValue); override;

    procedure Call_BeforeData(Sender: TObject); override;

    // procedure Call_UserLoggedIn(Sender: TObject; const uname: String; uinfo:TRtcRecord); override;
    // procedure Call_UserLoggedOut(Sender: TObject; const uname: String); override;

    procedure Call_UserJoinedMyGroup(Sender: TObject; const group: String;
      const uname: String; uinfo:TRtcRecord); override;
    procedure Call_UserLeftMyGroup(Sender: TObject; const group: String;
      const uname: String); override;

    procedure Call_JoinedUsersGroup(Sender: TObject; const group: String; const uname: String; uinfo:TRtcRecord); override;
    procedure Call_LeftUsersGroup(Sender: TObject; const group: String; const uname: String); override;

    procedure Call_DataFromUser(Sender: TObject; const uname: String;
      data: TRtcFunctionInfo); override;

    procedure AddUI(UI: TRtcAbsPHostFileTransferUI);
    procedure RemUI(UI: TRtcAbsPHostFileTransferUI);

    procedure Call_AfterData(Sender: TObject); override;

    procedure Init; override;

    //FileTrans+
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
    //FileTrans-
  public
    FHaveScreen: Boolean;
    FOnHaveScreeenChanged: TNotifyEvent;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Restart;

    // Open Desktop session for user "uname"
    procedure Open(const uname: String; Sender: TObject = nil);

    // Close all Desktop sessions: all users viewing or controlling our Desktop will be disconnected.
    procedure CloseAll(Sender: TObject = nil);
    // Close Desktop sessions for user "uname"
    procedure Close(const uname: String; Sender: TObject = nil);

    property LastMouseUser: String read GetLastMouseUser;

    function MirrorDriverInstalled(Init: boolean = False): boolean;

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
      const FolderName, FileMask: String; Sender: TObject);
    //FileTrans-

  published
    { Set to TRUE if you wish to store access right and screen parameters on the Gateway
      and load parameters from the Gateway after Activating the component.
      When gwStoreParams is FALSE, parameter changes will NOT be sent to the Gateway,
      nor will current parameters stored on the Gateway be loaded on start. }
    property GwStoreParams: boolean read FGatewayParams write FGatewayParams
      default False;

    { Set to FALSE if you want to ignore Access right settings and allow all actions,
      regardless of user lists and AllowView/Control parameters set by this user. }
    property AccessControl: boolean read FAccessControl write FAccessControl
      default True;

    { Allow users to View our Desktop?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowView: boolean read GetAllowView write SetAllowView
      default True;
    { Allow Super users to View our Desktop?
      If geStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowView_Super: boolean read GetAllowSuperView
      write SetAllowSuperView default True;

    { Allow users to Control our Desktop?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowControl: boolean read GetAllowControl write SetAllowControl
      default True;
    { Allow Super users to Control our Desktop?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GAllowControl_Super: boolean read GetAllowSuperControl
      write SetAllowSuperControl default True;

    { This property defines in how many frames the Screen image will be split when processing the first image pass.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenInBlocks: TrdScreenBlocks read GetSendScreenInBlocks
      write SetSendScreenInBlocks default rdBlocks1;
    { This property defines in how many steps the Screen image will be refined.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenRefineBlocks: TrdScreenBlocks
      read GetSendScreenRefineBlocks write SetSendScreenRefineBlocks
      default rdBlocks1;
    { This property defines minimum delay (in seconds) before the Screen image can be refined.
      If the value is zero, a default delay of 500 ms (0.5 seconds) will be used.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenRefineDelay: integer read GetSendScreenRefineDelay
      write SetSendScreenRefineDelay default 0;
    { This property defines how much data can be sent in a single screen frame.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GSendScreenSizeLimit: TrdScreenLimit read GetSendScreenSizeLimit
      write SetSendScreenSizeLimit default rdBlockAnySize;
    { Use Video Mirror Driver (if installed)?
      Using video mirror driver can greatly improve remote desktop performance.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GUseMirrorDriver: boolean read GetUseMirrorDriver
      write SetUseMirrorDriver default False;
    { Use Virtual Mouse Driver (if DLL and SYS files are available)?
      Using virtual mouse driver makes it possible to control the UAC screen on Vista,
      but requires the EXE to be compiled with the "rtcportaluac" manifest file,
      signed with a trusted certificate and placed in a trusted folder like "C:/Program Files". }
    property GUseMouseDriver: boolean read GetUseMouseDriver
      write SetUseMouseDriver default False;
    { Capture Layered Windows even if not using mirror driver (slows down screen capture)?
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
//    property GCaptureLayeredWindows: boolean read GetCaptureLayeredWindows
//      write SetCaptureLayeredWindows default False;
    { Capture Screen from All Monotirs when TRUE, or only from the Primary Display when FALSE.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GCaptureAllMonitors: boolean read GetCaptureAllMonitors
      write SetCaptureAllMonitors default False;

    { Limiting the number of colors can reduce bandwidth needs and improve performance.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GColorLimit: TrdColorLimit read GetColorLimit write SetColorLimit
      default rdColor8bit;
    { Setting LowColorLimit value lower than ColorLimit value will use dynamic color reduction to
      improve performance by sending the image in LowColorLimit first and then refining up to ColorLimit.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GColorLowLimit: TrdLowColorLimit read GetLowColorLimit
      write SetLowColorLimit default rd_ColorHigh;
    { ColorReducePercent defines the minimum percentage (0-100) by which the normal color
      image has to be reduced in size using low color limit in order to use the low color image.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GColorReducePercent: integer read GetColorReducePercent
      write SetColorReducePercent default 0;
    { Reducing Frame rate can reduce CPU usage and bandwidth needs.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GFrameRate: TrdFrameRate read GetFrameRate write SetFrameRate
      default rdFramesMax;

    { If FullScreen is TRUE, the whole Screen (Desktop region) is sent.
      If FullScreen is FALSE, only the part defined with "ScreenRect" is sent.
      If gwStoreParams=True, this parameter will be stored on the Gateway. }
    property GFullScreen: boolean read GetShowFullScreen write SetShowFullScreen
      default True;

    { Rectangular Screen Region to be sent when FullScreen is FALSE.
      This parameter is NOT stored on the Gateway. }
    property ScreenRect: TRect read FScreenRect write FScreenRect;

    { FileTransfer component to be used when we need to send a file to a user. }
    property FileTransfer: TRtcPFileTransfer read FFileTrans write SetFileTrans;

    { User with username = "user" is asking for access to our Desktop.
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
    { We have a new Desktop Host user, username = "user".
      You can use this event to maintain a list of active Desktop Host users. }
    property OnUserJoined;
    { "User" no longer has our Desktop Host open.
      You can use this event to maintain a list of active Desktop Host users. }
    property OnUserLeft;

    property HaveScreen: Boolean read FHaveScreen;
    property OnHaveScreeenChanged: TNotifyEvent read FOnHaveScreeenChanged write FOnHaveScreeenChanged;

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

    //FileTrans+
    { This event will be triggered when a FileTransferUI component is required, but still not assigned for this user.
      You should create a new FileTransferUI component in this event and assign *this* component to it's Module property.
      The FileTransferUI component will then take care of processing all events received from that user. }
    property OnNewUI: TRtcPHostFileTransUserEvent read FOnNewUI write FOnNewUI;

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
    //FileTrans-
  end;

//function CaptureFullScreen(MultiMon: boolean; PixelFormat: TPixelFormat = pf8bit): TBitmap;

//function GetCursorInfo2(var pci: PCursorInfo): BOOL; stdcall; external 'user32.dll' name 'GetCursorInfo';

const
  TG_F ='';

var
  FHelper_Width, FHelper_Height: Integer;
  FHelper_BitsPerPixel: Word;
  FHelper_mouseFlags: DWORD;
  FHelper_mouseCursor: HCURSOR;
  FHelper_mouseX, FHelper_mouseY: LongInt;

implementation

uses Math, Types;

function IsWinNT: boolean;
var
  OS: TOSVersionInfo;
begin
  ZeroMemory(@OS, SizeOf(OS));
  OS.dwOSVersionInfoSize := SizeOf(OS);
  GetVersionEx(OS);
  Result := OS.dwPlatformId = VER_PLATFORM_WIN32_NT;
end;

{ TRtcPDesktopHost }
constructor TRtcPDesktopHost.Create(AOwner: TComponent);
begin
  inherited;

  CS2 := TCriticalSection.Create;
  Clipboards := TRtcRecord.Create;
  FLastMouseUser := '';
  FDesktopActive := False;
  _desksub := nil;
  _sub_desk := nil;

  FAccessControl := True;

  FAllowView := True;
  FAllowControl := True;

  FAllowSuperView := True;
  FAllowSuperControl := True;

  FShowFullScreen := True;
  FScreenInBlocks := rdBlocks1;
  FScreenRefineBlocks := rdBlocks1;
  FScreenRefineDelay := 0;
  FScreenSizeLimit := rdBlockAnySize;
  FUseMirrorDriver := False;
  FUseMouseDriver := False;
  FCaptureAllMonitors := False;
//  FCaptureLayeredWindows := False;

  FColorLimit := rdColor8bit;
  FLowColorLimit := rd_ColorHigh;
  FColorReducePercent := 0;
  FFrameRate := rdFramesMax;

  //FileTrans+
  CSUI := TCriticalSection.Create;
  UIs := TRtcInfo.Create;

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

destructor TRtcPDesktopHost.Destroy;
begin
   FileTransfer := nil;

  ScrStop;
  if assigned(_desksub) then
  begin
    _desksub.Free;
    _desksub := nil;
  end;
  if assigned(_sub_desk) then
  begin
    _sub_desk.Free;
    _sub_desk := nil;
  end;
  Clipboards.Free;
  CS2.Free;

  //FileTrans+
  WantToSendFiles.Free;
  PrepareFiles.Free;
  SendingFiles.Free;
  UpdateFiles.Free;

  UIs.Free;
  CSUI.Free;
  //FileTrans-

  inherited;
end;

function TRtcPDesktopHost.MayControlDesktop(const user: String): boolean;
begin
  if FAccessControl and assigned(Client) then
    Result := (FAllowControl and Client.inUserList[user]) or
      (FAllowSuperControl and Client.isSuperUser[user])
  else
    Result := True;
end;

function TRtcPDesktopHost.MayViewDesktop(const user: String): boolean;
begin
  if FAccessControl and assigned(Client) then
    Result := (FAllowView and Client.inUserList[user]) or
      (FAllowSuperView and Client.isSuperUser[user])
  else
    Result := True;
end;

procedure TRtcPDesktopHost.Init;
begin
  ScrStop;
  inherited;
end;

procedure TRtcPDesktopHost.MakeDesktopActive;
begin
  if not FDesktopActive then
  begin
    FDesktopActive := True;
    SwitchToActiveDesktop;
  end;
end;

procedure TRtcPDesktopHost.Call_LogIn(Sender: TObject);
begin
end;

procedure TRtcPDesktopHost.Call_LogOut(Sender: TObject);
begin
end;

procedure TRtcPDesktopHost.Call_Params(Sender: TObject; data: TRtcValue);
begin
  CS2.Acquire;
  try
    RestartRequested := False;
    FLastMouseUser := '';
    Clipboards.Clear;
  finally
    CS2.Release;
  end;

  if FGatewayParams then
    if data.isType = rtc_Record then
      with data.asRecord do
      begin
        FAllowView := not asBoolean['NoViewDesktop'];
        FAllowControl := not asBoolean['NoControlDesktop'];

        FAllowSuperView := not asBoolean['NoSuperViewDesktop'];
        FAllowSuperControl := not asBoolean['NoSuperControlDesktop'];

        FShowFullScreen := not asBoolean['ScreenRegion'];
        FUseMirrorDriver := asBoolean['MirrorDriver'];
        FUseMouseDriver := asBoolean['MouseDriver'];
        FCaptureAllMonitors := asBoolean['AllMonitors'];
//        FCaptureLayeredWindows := asBoolean['LayeredWindows'];

        FScreenInBlocks := TrdScreenBlocks(asInteger['ScreenBlocks']);
        FScreenRefineBlocks := TrdScreenBlocks(asInteger['ScreenBlocks2']);
        FScreenRefineDelay := asInteger['Screen2Delay'];
        FScreenSizeLimit := TrdScreenLimit(asInteger['ScreenLimit']);
        FColorLimit := TrdColorLimit(asInteger['ColorLimit']);
        FLowColorLimit := TrdLowColorLimit(asInteger['LowColorLimit']);
        FColorReducePercent := asInteger['ColorReducePercent'];
        FFrameRate := TrdFrameRate(asInteger['FrameRate']);
      end;
end;

procedure TRtcPDesktopHost.SendWaiting(const UserName: String;
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

procedure TRtcPDesktopHost.Call_Start(Sender: TObject; data: TRtcValue);
begin
  ScrStart;
  InitData;
end;

procedure TRtcPDesktopHost.Call_Error(Sender: TObject; data: TRtcValue);
begin
end;

procedure TRtcPDesktopHost.Call_FatalError(Sender: TObject; data: TRtcValue);
begin
end;

procedure TRtcPDesktopHost.Call_BeforeData(Sender: TObject);
begin
  if assigned(_desksub) then
  begin
    _desksub.Free;
    _desksub := nil;
  end;
  if assigned(_sub_desk) then
  begin
    _sub_desk.Free;
    _sub_desk := nil;
  end;
  FDesktopActive := False;
end;

procedure TRtcPDesktopHost.Call_UserJoinedMyGroup(Sender: TObject;
  const group, uname: String; uinfo:TRtcRecord);
begin
  inherited;

  if group = 'idesk' then
  begin
    if MayViewDesktop(uname) then
    begin
      // store to change temporary to full subscription
      if not assigned(_desksub) then
        _desksub := TRtcArray.Create;
      _desksub.asText[_desksub.Count] := uname;

      if not isSubscriber(uname) then
        Event_NewUser(Sender, uname, uinfo);
    end;
  end
  else if group = 'desk' then
  begin
    if MayViewDesktop(uname) then
    begin
      if setDeskSubscriber(uname, True) then
      begin
        // Event_NewUser(Sender, uname);
      end;

      //FileTrans+
      // New "File Transfer" subscriber ...
      if BeTheHost then
        // Allow subscriptions only if "CanUpload/DownloadFiles" is enabled.
//        if MayUploadFiles(uname) or MayDownloadFiles(uname) then
          if Event_QueryAccess(Sender, uname) then
          begin
            Client.AddUserToMyGroup(Sender, uname, 'desk');
            Event_FileTransInit(Sender, uname);
          end;

//          if (group = 'file') then
            if setSubscriber(uname, True) then
            begin
        //      AmHost.asBoolean[uname] := True;
              Event_NewUser(Sender, uname, uinfo);
              Event_FileTransOpen(Sender, uname);

              SendWaiting(uname, Sender);
            end;
      //FileTrans-
    end;
  end;
end;

procedure TRtcPDesktopHost.Call_UserLeftMyGroup(Sender: TObject;
  const group, uname: String);
begin
  if group = 'idesk' then
  begin
    if not isSubscriber(uname) then
      Event_OldUser(Sender, uname);
  end
  else if group = 'desk' then
  begin
    if setDeskSubscriber(uname, False) then
      Event_OldUser(Sender, uname);

    if setSubscriber(uname, False) then
    begin
//      AmHost.asBoolean[uname] := False;
      StopFileSending(Sender, uname);
      Event_FileTransClose(Sender, uname);
      Event_OldUser(Sender, uname);
    end;
  end;

  inherited;
end;

procedure TRtcPDesktopHost.Call_DataFromUser(Sender: TObject;
  const uname: String; data: TRtcFunctionInfo);
var
  s: RtcString;
  r: TRtcFunctionInfo;
  MyFiles: TRtcArray;
  k: integer;
  ScrChanged: boolean;

  //FileTrans+
  tofolder, tofile: String;
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
  if Data.FunctionName = 'hfile' then // user is sending us a file
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
  else if Data.FunctionName = 'hputfile' then // user wants to send us a file
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
  else if Data.FunctionName = 'hpfile' then
  begin
    if isSubscriber(uname) then
    // user is letting us know that we may start sending the file
      StartSendingFile(uname, Data.asText['path'], Data.asInteger['id']);
  end
  else if Data.FunctionName = 'hgetfile' then
  begin
    if isSubscriber(uname) then
      Send(uname, Data.asText['file'], Data.asText['to'], Sender);
  end
  else
  //FileTrans-
  if data.FunctionName = 'mouse' then
  begin
    if MayControlDesktop(uname) and isSubscriber(uname) then
    begin
      MakeDesktopActive;
      if data.isType['d'] = rtc_Integer then
      begin
        CS2.Acquire;
        try
          FLastMouseUser := uname;
        finally
          CS2.Release;
        end;
        CS.Acquire;
        try
          if assigned(Scr) then
            case data.asInteger['d'] of
              1:
                Scr.MouseDown(uname, data.asInteger['x'],
                  data.asInteger['y'], mbLeft);
              2:
                Scr.MouseDown(uname, data.asInteger['x'],
                  data.asInteger['y'], mbRight);
              3:
                Scr.MouseDown(uname, data.asInteger['x'], data.asInteger['y'],
                  mbMiddle);
            end;
        finally
          CS.Release;
        end;
      end
      else if data.isType['u'] = rtc_Integer then
      begin
        CS2.Acquire;
        try
          FLastMouseUser := uname;
        finally
          CS2.Release;
        end;
        CS.Acquire;
        try
          if assigned(Scr) then
            case data.asInteger['u'] of
              1:
                Scr.MouseUp(uname, data.asInteger['x'],
                  data.asInteger['y'], mbLeft);
              2:
                Scr.MouseUp(uname, data.asInteger['x'],
                  data.asInteger['y'], mbRight);
              3:
                Scr.MouseUp(uname, data.asInteger['x'], data.asInteger['y'],
                  mbMiddle);
            end;
        finally
          CS.Release;
        end;
      end
      else if data.isType['w'] = rtc_Integer then
      begin
        CS.Acquire;
        try
          if assigned(Scr) then
            Scr.MouseWheel(data.asInteger['w']);
        finally
          CS.Release;
        end;
      end
      else
      begin
        CS.Acquire;
        try
          if assigned(Scr) then
            Scr.MouseMove(uname, data.asInteger['x'], data.asInteger['y']);
        finally
          CS.Release;
        end;
      end;
    end;
  end
  else if data.FunctionName = 'key' then
  begin
    if MayControlDesktop(uname) then
    begin
      if isSubscriber(uname) then
      begin
        MakeDesktopActive;
        CS.Acquire;
        try
          if assigned(Scr) then
          begin
            if data.isType['d'] = rtc_Integer then
              Scr.KeyDown(data.asInteger['d'], [])
            else if data.isType['u'] = rtc_Integer then
              Scr.KeyUp(data.asInteger['u'], [])
//Доделать. Убрано nonunicode тк в хелпере не реализовано
//            else if data.isType['p'] = rtc_String then
//              Scr.KeyPress(data.asString['p'], data.asInteger['k'])
            else if data.isType['p'] = rtc_WideString then
              Scr.KeyPressW(data.asWideString['p'], data.asInteger['k'])
            else if data.isType['lw'] = rtc_Integer then
              Scr.LWinKey(data.asInteger['lw'])
            else if data.isType['rw'] = rtc_Integer then
              Scr.RWinKey(data.asInteger['rw'])
            else if data.isType['s'] = rtc_String then
            begin
              Scr.SpecialKey(data.asString['s']);
//              if data.asString['s'] = 'COPY' then
//              begin
//                if assigned(FileTransfer) then
//                begin
//                  // wait for Ctrl+C to be processed by the receiving app
//                  Sleep(250);
//                  // Clipboard has changed. Check if we have files in it and start sending them
//                  MyFiles := Get_ClipboardFiles;
//                  if assigned(MyFiles) then
//                    try
//                      for k := 0 to MyFiles.Count - 1 do
//                        FileTransfer.Send(uname, MyFiles.asText[k]);
//                    finally
//                      MyFiles.Free;
//                    end;
//                end;
//              end;
            end;
          end;
        finally
          CS.Release;
        end;
      end
      else
      begin
        MakeDesktopActive;
        CS.Acquire;
        try
          if data.isType['s'] = rtc_String then
            if data.asString['s'] = 'HDESK' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDHDESK, 0, 0, 0, 0, 0, 0, 0, '')
              else
                Hide_Wallpaper;
            end
            else
            if data.asString['s'] = 'SDESK' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDSDESK, 0, 0, 0, 0, 0, 0, 0, '')
              else
                Show_Wallpaper;
            end
            else
            if data.asString['s'] = 'BKM' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDBKM, 0, 0, 0, 0, 0, 0, 0, '')
              else
                SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
            end
            else
            if data.asString['s'] = 'UBKM' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDUBKM, 0, 0, 0, 0, 0, 0, 0, '')
              else
                SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
            end
            else
            if data.asString['s'] = 'OFFMON' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDOFFMON, 0, 0, 0, 0, 0, 0, 0, '')
              else
              begin
          //    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
          //    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 0, 0);
          //    SetBlankMonitor(True);
              end;
            end
            else
            if data.asString['s'] = 'ONMON' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDONMON, 0, 0, 0, 0, 0, 0, 0, '')
              else
              begin
          //    SetBlankMonitor(False);
          //    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
          //    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 1, 0);
              end;
            end
            else
            if data.asString['s'] = 'OFFSYS' then
              PowerOffSystem
            else
            if data.asString['s'] = 'LCKSYS' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDLCKSYS, 0, 0, 0, 0, 0, 0, 0, '')
              else
                LockSystem;
            end
            else
            if data.asString['s'] = 'LOGOFF' then
            begin
              if IsService then
                SendIOToHelperByIPC(QT_SENDLOGOFF, 0, 0, 0, 0, 0, 0, 0, '')
              else
                LogoffSystem;
            end
            else
            if data.asString['s'] = 'RSTRT' then
              RestartSystem;
        finally
          CS.Release;
        end;
      end;
    end;
  end
  else if data.FunctionName = 'cbrd' then
  begin
    if MayControlDesktop(uname) and isSubscriber(uname) then
    begin
      MakeDesktopActive;
      // Clipboard data
      s := data.asString['s'];
      setClipboard(uname, s);
    end;
  end
  else if data.FunctionName = 'getcbrd' then
  begin
    if MayControlDesktop(uname) and isSubscriber(uname) then
    begin
      MakeDesktopActive;
      r := nil;
      // Clipboard request
      CS2.Acquire;
      try
        s := Get_Clipboard;
//        if (Clipboards.isType[uname] = rtc_Null) or
//          (s <> Clipboards.asString[uname]) then
//        begin
//          Put_Clipboard(uname, s);
//          s := Get_Clipboard;
          if (Clipboards.isType[uname] = rtc_Null) or
            (s <> Clipboards.asString[uname]) then
          begin
            if s = '' then
            begin
              Clipboards.asString[uname] := '';
              r := TRtcFunctionInfo.Create;
              r.FunctionName := 'cbrd';
              // r.asString['s']:='';
            end
            else
            begin
              Clipboards.asString[uname] := s;
              r := TRtcFunctionInfo.Create;
              r.FunctionName := 'cbrd';
              r.asString['s'] := s;
            end;
          end;
//        end;
      finally
        CS2.Release;
      end;
      if assigned(r) then
        Client.SendToUser(Sender, uname, r);
    end;
  end
  else if (data.FunctionName = 'chgdesk') then
  begin
    if MayControlDesktop(uname) then
    begin
      ScrChanged := False;
      if (data.isType['color'] = rtc_Integer) and
        (GColorLimit <> TrdColorLimit(data.asInteger['color'])) then
      begin
        GColorLimit := TrdColorLimit(data.asInteger['color']);
        ScrChanged := True;
      end;
      if (data.isType['colorlow'] = rtc_Integer) and
        (GColorLowLimit <> TrdLowColorLimit(data.asInteger['colorlow'])) then
      begin
        GColorLowLimit := TrdLowColorLimit(data.asInteger['colorlow']);
        ScrChanged := True;
      end;
      if (data.isType['colorpercent'] = rtc_Integer) and
        (GColorReducePercent <> data.asInteger['colorpercent']) then
      begin
        GColorReducePercent := data.asInteger['colorpercent'];
        ScrChanged := True;
      end;
      if (data.isType['frame'] = rtc_Integer) and
        (GFrameRate <> TrdFrameRate(data.asInteger['frame'])) then
      begin
        GFrameRate := TrdFrameRate(data.asInteger['frame']);
        ScrChanged := True;
      end;
      if (data.isType['mirror'] = rtc_Boolean) and
        (GUseMirrorDriver <> data.asBoolean['mirror']) then
      begin
        GUseMirrorDriver := data.asBoolean['mirror'];
        ScrChanged := True;
      end;
      if (data.isType['mouse'] = rtc_Boolean) and
        (GUseMouseDriver <> data.asBoolean['mouse']) then
      begin
        GUseMouseDriver := data.asBoolean['mouse'];
        ScrChanged := True;
      end;
      if (data.isType['scrblocks'] = rtc_Integer) and
        (GSendScreenInBlocks <> TrdScreenBlocks(data.asInteger['scrblocks']))
      then
      begin
        GSendScreenInBlocks := TrdScreenBlocks(data.asInteger['scrblocks']);
        ScrChanged := True;
      end;
      if (data.isType['scrblocks2'] = rtc_Integer) and
        (GSendScreenRefineBlocks <> TrdScreenBlocks(data.asInteger
        ['scrblocks2'])) then
      begin
        GSendScreenRefineBlocks :=
          TrdScreenBlocks(data.asInteger['scrblocks2']);
        ScrChanged := True;
      end;
      if (data.isType['scr2delay'] = rtc_Integer) and
        (GSendScreenRefineDelay <> data.asInteger['scr2delay']) then
      begin
        GSendScreenRefineDelay := data.asInteger['scr2delay'];
        ScrChanged := True;
      end;
      if (data.isType['scrlimit'] = rtc_Integer) and
        (GSendScreenSizeLimit <> TrdScreenLimit(data.asInteger['scrlimit']))
      then
      begin
        GSendScreenSizeLimit := TrdScreenLimit(data.asInteger['scrlimit']);
        ScrChanged := True;
      end;
      if (data.isType['monitors'] = rtc_Boolean) and
        (GCaptureAllMonitors <> data.asBoolean['monitors']) then
      begin
        GCaptureAllMonitors := data.asBoolean['monitors'];
        ScrChanged := True;
      end;
//      if (data.isType['layered'] = rtc_Boolean) and
//        (GCaptureLayeredWindows <> data.asBoolean['layered']) then
//      begin
//        GCaptureLayeredWindows := data.asBoolean['layered'];
//        ScrChanged := True;
//      end;
      if ScrChanged then
        Restart;
    end;
  end
  // New "Desktop View" subscriber ...
  else if (data.FunctionName = 'desk') and (data.FieldCount = 0) then
  begin
    // allow subscriptions only if "CanViewDesktop" is enabled
    if MayViewDesktop(uname) then
      if Event_QueryAccess(Sender, uname) then
      begin
        if not assigned(_sub_desk) then
          _sub_desk := TRtcRecord.Create;
        _sub_desk.asBoolean[uname] := True;
      end;
  end
  //+sstuman
//  else if Data.FunctionName = 'files_to_copy_list' then
//  begin
//    if isSubscriber(uname) then
//    begin
//      AcceptFilesDirsList(uname, Data.asText['f']);
//      AcceptFilesDirsList(uname, Data.asText['s']);
//    end;
//  end;
//  //-sstuman
end;

procedure TRtcPDesktopHost.Call_AfterData(Sender: TObject);
var
  a: integer;
  have_desktop: boolean;
  uname: String;

  procedure SendDesktop(full: boolean);
  var
    fn1, fn2: String;
    s1, s1full, s1delta, s2: RtcString;
    fn: TRtcFunctionInfo;
  begin
    // New user for Desktop View
    fn := nil;

    CS.Acquire;
    try
      if assigned(Scr) and
        (full or ((getSubscriberCnt > 0) and Client.canSendNext)) then
      begin
        if not have_desktop then
        begin
          LastGrab := GetTickCount;
          Scr.GrabScreen(@s1delta, @s1full);
          Scr.GrabMouse;
          have_desktop := True;
        end;

        if full then
        begin
          // Send Initial Full Screen to New subscribers
          s1 := s1full;//Scr.GetScreen;  // non delta
          s2 := Scr.GetMouse;
          fn1 := 'idesk';
          fn2 := 'init';
        end
        else
        begin
          // Send Screen Delta to already active subscribers
          s1 := s1delta;//Scr.GetScreen; //delta
          s2 := Scr.GetMouseDelta;
          fn1 := 'desk';
          fn2 := 'next';
        end;
      end;
    finally
      CS.Release;
    end;

    if s1 <> '' then
    begin
      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'desk';
      fn.asString[fn2] := s1;
    end;
    if s2 <> '' then
    begin
      if not assigned(fn) then
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'desk';
      end;
      fn.asString['cur'] := s2;
    end;

    if assigned(fn) then
      Client.SendToMyGroup(Sender, fn1, fn);
  end;

begin
  have_desktop := False;
  try
    if assigned(_desksub) then
    begin
      MakeDesktopActive;

      // Send Delta screen
      SendDesktop(False);
      // Send initial screen
      SendDesktop(True);

      // Change temporary subscriptions to full subscriptions ...
      for a := 0 to _desksub.Count - 1 do
      begin
        uname := _desksub.asText[a];
        Client.AddUserToMyGroup(Sender, uname, 'desk');
        Client.RemoveUserFromMyGroup(Sender, uname, 'idesk');
      end;
    end;

    if assigned(_sub_desk) then
    begin
      for a := 0 to _sub_desk.Count - 1 do
      begin
        uname := _sub_desk.FieldName[a];
        Client.AddUserToMyGroup(Sender, uname, 'idesk');
      end;
    end;
  finally
    if assigned(_desksub) then
    begin
      _desksub.Free;
      _desksub := nil;
    end;
    if assigned(_sub_desk) then
    begin
      _sub_desk.Free;
      _sub_desk := nil;
    end;
  end;
end;

function TRtcPDesktopHost.SenderLoop_Check(Sender: TObject): boolean;
var
  a: integer;
  uname: String;
begin
  loop_needtosend := False;
  loop_need_restart := False;

  CS.Acquire;
  try
    Result := (getSubscriberCnt > 0) and assigned(Scr);
  finally
    CS.Release;
  end;

//FileTrans+
  loop_update := nil;
  loop_tosendfile := False;

  CS.Acquire;
  try
    Result := Result or File_Sending;
  finally
    CS.Release;
  end;
//FileTrans-
end;

procedure TRtcPDesktopHost.SenderLoop_Prepare(Sender: TObject);
var
  nowtime: longword;
  a: integer;
  uname: String;
begin
  CS.Acquire;
  try
    if (getSubscriberCnt > 0) and assigned(Scr) then
    begin
      SwitchToActiveDesktop;

      loop_needtosend := True;

      loop_s1 := '';
      loop_s2 := '';

      loop_need_restart := RestartRequested;
      RestartRequested := False;

      nowtime := GetTickCount;
      if LastGrab > 0 then
        if FrameSleep > 0 then
          Sleep(FrameSleep)
        else if (FramePause > 0) and (FramePause > nowtime - LastGrab) then
          Sleep(FramePause - (nowtime - LastGrab));

      LastGrab := GetTickCount;
      Scr.GrabScreen(@loop_s1);
      //loop_s1 := Scr.GetScreen; // delta

      Scr.GrabMouse;
      loop_s2 := Scr.GetMouseDelta;
    end;
  finally
    CS.Release;
  end;

//FileTrans+
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
//FileTrans-
end;

procedure TRtcPDesktopHost.SenderLoop_Execute(Sender: TObject);
var
  fn: TRtcFunctionInfo;
//FileTrans+
var
  sr: TRtcRecord;

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
//FileTrans-
begin
  fn := nil;

  if loop_needtosend then
  begin
    if loop_s1 <> '' then
    begin
      fn := TRtcFunctionInfo.Create;
      fn.FunctionName := 'desk';
      fn.asString['next'] := loop_s1;
    end;
    if loop_s2 <> '' then
    begin
      if not assigned(fn) then
      begin
        fn := TRtcFunctionInfo.Create;
        fn.FunctionName := 'desk';
      end;
      fn.asString['cur'] := loop_s2;
    end;

    if assigned(fn) then
      Client.SendToMyGroup(Sender, 'desk', fn)
    else
      Client.SendPing(Sender);

    if loop_need_restart then
    begin
      ScrStop;
      ScrStart;
    end;
  end;

//FileTrans+
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
//FileTrans-
end;

function TRtcPDesktopHost.GetLastMouseUser: String;
begin
  CS2.Acquire;
  try
    Result := FLastMouseUser;
  finally
    CS2.Release;
  end;
end;

function TRtcPDesktopHost.setDeskSubscriber(const username: String;
  active: boolean): boolean;
begin
  Result := setSubscriber(username, active);
  CS.Acquire;
  try
    if Result and assigned(Scr) and not active and (getSubscriberCnt = 0) then
      Scr.Clear;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.setClipboard(const username: String;
  const data: RtcString);
begin
  CS2.Acquire;
  try
    Clipboards.asString[username] := data;
    Put_Clipboard(username, data);
  finally
    CS2.Release;
  end;
end;

procedure TRtcPDesktopHost.SetAllowView(const Value: boolean);
begin
  if Value <> FAllowView then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoViewDesktop', TRtcBooleanValue.Create(not Value));
    FAllowView := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowView: boolean;
begin
  Result := FAllowView;
end;

procedure TRtcPDesktopHost.SetAllowControl(const Value: boolean);
begin
  if Value <> FAllowControl then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoControlDesktop',
        TRtcBooleanValue.Create(not Value));
    FAllowControl := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowControl: boolean;
begin
  Result := FAllowControl;
end;

procedure TRtcPDesktopHost.SetAllowSuperView(const Value: boolean);
begin
  if Value <> FAllowSuperView then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperViewDesktop',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperView := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowSuperView: boolean;
begin
  Result := FAllowSuperView;
end;

procedure TRtcPDesktopHost.SetAllowSuperControl(const Value: boolean);
begin
  if Value <> FAllowSuperControl then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'NoSuperControlDesktop',
        TRtcBooleanValue.Create(not Value));
    FAllowSuperControl := Value;
  end;
end;

function TRtcPDesktopHost.GetAllowSuperControl: boolean;
begin
  Result := FAllowSuperControl;
end;

procedure TRtcPDesktopHost.SetUseMirrorDriver(const Value: boolean);
begin
  if Value <> FUseMirrorDriver then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'MirrorDriver', TRtcBooleanValue.Create(Value));
    FUseMirrorDriver := Value;
  end;
end;

procedure TRtcPDesktopHost.SetUseMouseDriver(const Value: boolean);
begin
  if Value <> FUseMouseDriver then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'MouseDriver', TRtcBooleanValue.Create(Value));
    FUseMouseDriver := Value;
  end;
end;

procedure TRtcPDesktopHost.SetCaptureAllMonitors(const Value: boolean);
begin
  if Value <> FCaptureAllMonitors then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'AllMonitors', TRtcBooleanValue.Create(Value));
    FCaptureAllMonitors := Value;
  end;
end;

//procedure TRtcPDesktopHost.SetCaptureLayeredWindows(const Value: boolean);
//begin
//  if Value <> FCaptureLayeredWindows then
//  begin
//    if FGatewayParams and assigned(Client) then
//      Client.ParamSet(nil, 'LayeredWindows', TRtcBooleanValue.Create(Value));
//    FCaptureLayeredWindows := Value;
//  end;
//end;

function TRtcPDesktopHost.GetUseMirrorDriver: boolean;
begin
  Result := FUseMirrorDriver;
end;

function TRtcPDesktopHost.GetUseMouseDriver: boolean;
begin
  Result := FUseMouseDriver;
end;

function TRtcPDesktopHost.GetCaptureAllMonitors: boolean;
begin
  Result := FCaptureAllMonitors;
end;

//function TRtcPDesktopHost.GetCaptureLayeredWindows: boolean;
//begin
//  Result := FCaptureLayeredWindows;
//end;

procedure TRtcPDesktopHost.SetSendScreenInBlocks(const Value: TrdScreenBlocks);
begin
  if Value <> FScreenInBlocks then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenBlocks', TRtcIntegerValue.Create(Ord(Value)));
    FScreenInBlocks := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenInBlocks: TrdScreenBlocks;
begin
  Result := FScreenInBlocks;
end;

procedure TRtcPDesktopHost.SetSendScreenRefineBlocks
  (const Value: TrdScreenBlocks);
begin
  if Value <> FScreenRefineBlocks then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenBlocks2',
        TRtcIntegerValue.Create(Ord(Value)));
    FScreenRefineBlocks := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenRefineBlocks: TrdScreenBlocks;
begin
  Result := FScreenRefineBlocks;
end;

procedure TRtcPDesktopHost.SetSendScreenRefineDelay(const Value: integer);
begin
  if Value <> FScreenRefineDelay then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'Screen2Delay', TRtcIntegerValue.Create(Value));
    FScreenRefineDelay := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenRefineDelay: integer;
begin
  Result := FScreenRefineDelay;
end;

procedure TRtcPDesktopHost.SetSendScreenSizeLimit(const Value: TrdScreenLimit);
begin
  if Value <> FScreenSizeLimit then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenLimit', TRtcIntegerValue.Create(Ord(Value)));
    FScreenSizeLimit := Value;
  end;
end;

function TRtcPDesktopHost.GetSendScreenSizeLimit: TrdScreenLimit;
begin
  Result := FScreenSizeLimit;
end;

procedure TRtcPDesktopHost.SetShowFullScreen(const Value: boolean);
begin
  if Value <> FShowFullScreen then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ScreenRegion', TRtcBooleanValue.Create(not Value));
    FShowFullScreen := Value;
  end;
end;

function TRtcPDesktopHost.GetShowFullScreen: boolean;
begin
  Result := FShowFullScreen;
end;

procedure TRtcPDesktopHost.SetColorLimit(const Value: TrdColorLimit);
begin
  if Value <> FColorLimit then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ColorLimit', TRtcIntegerValue.Create(Ord(Value)));
    FColorLimit := Value;
  end;
end;

function TRtcPDesktopHost.GetColorLimit: TrdColorLimit;
begin
  Result := FColorLimit;
end;

procedure TRtcPDesktopHost.SetColorReducePercent(const Value: integer);
begin
  if Value <> FColorReducePercent then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'ColorReducePercent',
        TRtcIntegerValue.Create(Ord(Value)));
    FColorReducePercent := Value;
  end;
end;

function TRtcPDesktopHost.GetColorReducePercent: integer;
begin
  Result := FColorReducePercent;
end;

procedure TRtcPDesktopHost.SetLowColorLimit(const Value: TrdLowColorLimit);
begin
  if Value <> FLowColorLimit then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'LowColorLimit',
        TRtcIntegerValue.Create(Ord(Value)));
    FLowColorLimit := Value;
  end;
end;

function TRtcPDesktopHost.GetLowColorLimit: TrdLowColorLimit;
begin
  Result := FLowColorLimit;
end;

procedure TRtcPDesktopHost.SetFrameRate(const Value: TrdFrameRate);
begin
  if Value <> FFrameRate then
  begin
    if FGatewayParams and assigned(Client) then
      Client.ParamSet(nil, 'FrameRate', TRtcIntegerValue.Create(Ord(Value)));
    FFrameRate := Value;
  end;
end;

function TRtcPDesktopHost.GetFrameRate: TrdFrameRate;
begin
  Result := FFrameRate;
end;

procedure TRtcPDesktopHost.ScrStart;
begin
  CS.Acquire;
  try
    if not assigned(Scr) and (FAllowView or FAllowControl or FAllowSuperView or
      FAllowSuperControl) then
    begin
      LastGrab := 0;
      FrameSleep := 0;
      FramePause := 0;
      case FFrameRate of
        rdFrames50:
          FramePause := 1000 div 50;
        rdFrames40:
          FramePause := 1000 div 40;
        rdFrames25:
          FramePause := 1000 div 25;
        rdFrames20:
          FramePause := 1000 div 20;
        rdFrames10:
          FramePause := 1000 div 10;
        rdFrames8:
          FramePause := 1000 div 8;
        rdFrames5:
          FramePause := 1000 div 5;
        rdFrames4:
          FramePause := 1000 div 4;
        rdFrames2:
          FramePause := 1000 div 2;
        rdFrames1:
          FramePause := 1000 div 1;

        rdFrameSleep500:
          FrameSleep := 500;
        rdFrameSleep400:
          FrameSleep := 400;
        rdFrameSleep250:
          FrameSleep := 250;
        rdFrameSleep200:
          FrameSleep := 200;
        rdFrameSleep100:
          FrameSleep := 100;
        rdFrameSleep80:
          FrameSleep := 80;
        rdFrameSleep50:
          FrameSleep := 50;
        rdFrameSleep40:
          FrameSleep := 40;
        rdFrameSleep20:
          FrameSleep := 20;
        rdFrameSleep10:
          FrameSleep := 10;

      else
        FramePause := 16; // Max = 59 FPS
      end;

      Scr := TRtcScreenCapture.Create;
      case FColorLimit of
        rdColor4bit:
          begin
            Scr.BPPLimit := 0;
            Scr.Reduce16bit := $8E308E30; // 6bit
            Scr.Reduce32bit := $00C0C0C0; // 6bit
          end;
        rdColor6bit:
          begin
            Scr.Reduce16bit := $8E308E30; // 6bit
            Scr.Reduce32bit := $00C0C0C0; // 6bit
          end;
        rdColor8bit:
          begin
            Scr.BPPLimit := 1;
            Scr.Reduce16bit := $CF38CF38; // 9bit
            Scr.Reduce32bit := $00E0E0E0; // 9bit
          end;
        rdColor9bit:
          begin
            Scr.Reduce16bit := $CF38CF38; // 9bit
            Scr.Reduce32bit := $00E0E0E0; // 9bit
          end;
        rdColor12bit:
          begin
            Scr.Reduce16bit := $EFBCEFBC; // 12bit
            Scr.Reduce32bit := $00F0F0F0; // 12bit
          end;
        rdColor15bit:
          begin
            Scr.Reduce16bit := $FFF0FFF0; // 15bit
            Scr.Reduce32bit := $00F8F8F8; // 15bit
          end;
        rdColor16bit:
          begin
            Scr.BPPLimit := 2;
            Scr.Reduce32bit := $80F8F8F8; // 16bit
          end;
        rdColor18bit:
          begin
            Scr.Reduce32bit := $00FCFCFC; // 18bit
          end;
        rdColor21bit:
          begin
            Scr.Reduce32bit := $00FEFEFE; // 21bit
          end;
      end;

      case FLowColorLimit of
        rd_Color6bit, rd_ColorHigh6bit:
          begin
            Scr.LowReduce16bit := $8E308E30; // 6bit
            Scr.LowReduce32bit := $00C0C0C0; // 6bit
          end;
        rd_Color9bit, rd_ColorHigh9bit:
          begin
            Scr.LowReduce16bit := $CF38CF38; // 9bit
            Scr.LowReduce32bit := $00E0E0E0; // 9bit
          end;
        rd_Color12bit, rd_ColorHigh12bit:
          begin
            Scr.LowReduce16bit := $EFBCEFBC; // 12bit
            Scr.LowReduce32bit := $00F0F0F0; // 12bit
          end;
        rd_Color15bit, rd_ColorHigh15bit:
          begin
            Scr.LowReduce16bit := $FFF0FFF0; // 15bit
            Scr.LowReduce32bit := $00F8F8F8; // 15bit
          end;
        rd_Color18bit, rd_ColorHigh18bit:
          begin
            Scr.LowReduce32bit := $00FCFCFC; // 18bit
          end;
        rd_Color21bit, rd_ColorHigh21bit:
          begin
            Scr.LowReduce32bit := $00FEFEFE; // 21bit
          end;
      end;

      if FLowColorLimit < rd_ColorHigh6bit then
        Scr.LowReduceType := 0
      else
        Scr.LowReduceType := 1;

      if (Scr.Reduce32bit > 0) and (Scr.LowReduce32bit > 0) then
        Scr.LowReducedColors := Scr.LowReduce32bit < Scr.Reduce32bit
      else
        Scr.LowReducedColors := Scr.LowReduce32bit > 0;
      Scr.LowReduceColorPercent := GColorReducePercent;

//      Scr.LayeredWindows := FCaptureLayeredWindows;

//      case FScreenInBlocks of
//        rdBlocks1:
//          Scr.ScreenBlockCount := 1;
//        rdBlocks2:
//          Scr.ScreenBlockCount := 2;
//        rdBlocks3:
//          Scr.ScreenBlockCount := 3;
//        rdBlocks4:
//          Scr.ScreenBlockCount := 4;
//        rdBlocks5:
//          Scr.ScreenBlockCount := 5;
//        rdBlocks6:
//          Scr.ScreenBlockCount := 6;
//        rdBlocks7:
//          Scr.ScreenBlockCount := 7;
//        rdBlocks8:
//          Scr.ScreenBlockCount := 8;
//        rdBlocks9:
//          Scr.ScreenBlockCount := 9;
//        rdBlocks10:
//          Scr.ScreenBlockCount := 10;
//        rdBlocks11:
//          Scr.ScreenBlockCount := 11;
//        rdBlocks12:
//          Scr.ScreenBlockCount := 12;
//      end;
//
//      case FScreenRefineBlocks of
//        rdBlocks1:
//          begin
//            Scr.Screen2BlockCount := Scr.ScreenBlockCount * 2;
//            if Scr.Screen2BlockCount < 4 then
//              Scr.Screen2BlockCount := 4
//            else if Scr.Screen2BlockCount > 12 then
//              Scr.Screen2BlockCount := 12;
//          end;
//        rdBlocks2:
//          Scr.Screen2BlockCount := 2;
//        rdBlocks3:
//          Scr.Screen2BlockCount := 3;
//        rdBlocks4:
//          Scr.Screen2BlockCount := 4;
//        rdBlocks5:
//          Scr.Screen2BlockCount := 5;
//        rdBlocks6:
//          Scr.Screen2BlockCount := 6;
//        rdBlocks7:
//          Scr.Screen2BlockCount := 7;
//        rdBlocks8:
//          Scr.Screen2BlockCount := 8;
//        rdBlocks9:
//          Scr.Screen2BlockCount := 9;
//        rdBlocks10:
//          Scr.Screen2BlockCount := 10;
//        rdBlocks11:
//          Scr.Screen2BlockCount := 11;
//        rdBlocks12:
//          Scr.Screen2BlockCount := 12;
//      end;

      case FScreenSizeLimit of
        rdBlock1KB:
          Scr.MaxTotalSize := 1024;
        rdBlock2KB:
          Scr.MaxTotalSize := 1024 * 2;
        rdBlock4KB:
          Scr.MaxTotalSize := 1024 * 4;
        rdBlock8KB:
          Scr.MaxTotalSize := 1024 * 8;
        rdBlock12KB:
          Scr.MaxTotalSize := 1024 * 12;
        rdBlock16KB:
          Scr.MaxTotalSize := 1024 * 16;
        rdBlock24KB:
          Scr.MaxTotalSize := 1024 * 24;
        rdBlock32KB:
          Scr.MaxTotalSize := 1024 * 32;
        rdBlock48KB:
          Scr.MaxTotalSize := 1024 * 48;
        rdBlock64KB:
          Scr.MaxTotalSize := 1024 * 64;
        rdBlock96KB:
          Scr.MaxTotalSize := 1024 * 96;
        rdBlock128KB:
          Scr.MaxTotalSize := 1024 * 128;
        rdBlock192KB:
          Scr.MaxTotalSize := 1024 * 192;
        rdBlock256KB:
          Scr.MaxTotalSize := 1024 * 256;
        rdBlock384KB:
          Scr.MaxTotalSize := 1024 * 384;
        rdBlock512KB:
          Scr.MaxTotalSize := 1024 * 512;
      end;

      if FScreenRefineDelay < 0 then
        Scr.Screen2Delay := 0
      else if FScreenRefineDelay = 0 then
        Scr.Screen2Delay := 500
      else
        Scr.Screen2Delay := FScreenRefineDelay * 1000;

      if FShowFullScreen then
        Scr.ClipRect := TRect.Create(0, 0, 0, 0)
      else
        Scr.ClipRect := FScreenRect;

//      Scr.MouseDriver := FUseMouseDriver;
      Scr.MultiMonitor := FCaptureAllMonitors;

      // Always set the "MirageDriver" property at the end ...
//      Scr.MirageDriver := FUseMirrorDriver;

//      Scr.FPDesktopHost := Self;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.ScrStop;
begin
  CS.Acquire;
  try
    if assigned(Scr) then
    begin
      Scr.Free;
      Scr := nil;
    end;
  finally
    CS.Release;
  end;
end;

procedure TRtcPDesktopHost.Restart;
begin
  CS.Acquire;
  try
    if getSubscriberCnt = 0 then
    begin
      ScrStop;
      ScrStart;
    end
    else
      RestartRequested := True;
  finally
    CS.Release;
  end;
  // if assigned(FOnStartHost) then FOnStartHost;
end;

procedure TRtcPDesktopHost.SetFileTrans(const Value: TRtcPFileTransfer);
begin
  if Value <> FFileTrans then
  begin
    if assigned(FFileTrans) then
      FFileTrans.RemModule(self);
    FFileTrans := Value;
    if assigned(FFileTrans) then
      FFileTrans.AddModule(self);
  end;
end;

procedure TRtcPDesktopHost.UnlinkModule(const Module: TRtcPModule);
begin
  if Module = FFileTrans then
    FileTransfer := nil;
  inherited;
end;

procedure TRtcPDesktopHost.CloseAll(Sender: TObject);
begin
  Client.DisbandMyGroup(Sender, 'desk');
end;

procedure TRtcPDesktopHost.Close(const uname: String; Sender: TObject);
begin
  Client.RemoveUserFromMyGroup(Sender, uname, 'desk');
end;

procedure TRtcPDesktopHost.Open(const uname: String; Sender: TObject);
begin
  Client.AddUserToMyGroup(Sender, uname, 'idesk');
end;

function TRtcPDesktopHost.MirrorDriverInstalled(Init: boolean = False): boolean;
begin
  Result := false;
end;

//FileTrans+
procedure TRtcPDesktopHost.xOnFileTransInit(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileTransInit(self, Data.asText);
end;

procedure TRtcPDesktopHost.xOnFileTransOpen(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileTransOpen(self, Data.asText);
end;

procedure TRtcPDesktopHost.xOnFileTransClose(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileTransClose(self, Data.asText);
end;

procedure TRtcPDesktopHost.xOnFileReadStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileRead(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileRead(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileReadUpdate(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadUpdate(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileReadStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileReadCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileReadCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWriteStart(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStart(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWrite(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileWrite(self, Data.asRecord.asText['user'], Data.asRecord.asText['path'],
    Data.asRecord.asText['folder'], Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWriteStop(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteStop(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnFileWriteCancel(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnFileWriteCancel(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['path'], Data.asRecord.asText['folder'],
    Data.asRecord.asLargeInt['size']);
end;

procedure TRtcPDesktopHost.xOnCallReceived(Sender, Obj: TObject;
  Data: TRtcValue);
begin
  FOnCallReceived(self, Data.asRecord.asText['user'],
    Data.asRecord.asFunction['data']);
end;

procedure TRtcPDesktopHost.xOnFileList(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnFileList(self, Data.asRecord.asText['user'],
    Data.asRecord.asText['folder'], Data.asRecord.asDataSet['data']);
end;

procedure TRtcPDesktopHost.xOnNewUI(Sender, Obj: TObject; Data: TRtcValue);
begin
  FOnNewUI(self, Data.asText);
end;

function TRtcPDesktopHost.StartSendingFile(const UserName: String;
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

function TRtcPDesktopHost.CancelFileSending(Sender:TObject; const uname, FileName,
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

procedure TRtcPDesktopHost.StopFileSending(Sender: TObject;
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

procedure TRtcPDesktopHost.Event_FileReadStart(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileRead(Sender: TObject; const user: String;
  const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileReadUpdate(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileReadStop(Sender: TObject;
  const user: String; const fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileReadCancel(Sender: TObject;
  const user, fname, fromfolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileWriteStart(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileWrite(Sender: TObject; const user: String;
  const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileWriteStop(Sender: TObject;
  const user: String; const fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileWriteCancel(Sender: TObject;
  const user, fname, tofolder: String; size: int64);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_CallReceived(Sender: TObject;
  const user: String; const Data: TRtcFunctionInfo);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileList(Sender: TObject;
  const user, FolderName: String; const Data: TRtcDataSet);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopHost.CallFileEvent(Sender: TObject;
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

procedure TRtcPDesktopHost.Call(const UserName: String;
  const Data: TRtcFunctionInfo; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'call';
  fn.asObject['i'] := Data;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.GetFileList(const UserName: String;
  const FolderName, FileMask: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'list';
  fn.asText['file'] := FolderName;
  if FileMask <> '' then
    fn.asText['mask'] := FileMask;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Send(const UserName: String; const FileName: String;
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
      fn.FunctionName := 'hputfile';
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

procedure TRtcPDesktopHost.Fetch(const UserName: String;
  const FileName: String; const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hgetfile';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cancel_Send(const UserName, FileName: String;
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
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'abort';
  fn.asText['file'] := fname;
  fn.asText['to'] := tofolder;
  fn.asLargeInt['size'] := fsize;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cancel_Fetch(const UserName, FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'cancel';
  fn.asText['file'] := FileName;
  fn.asText['to'] := tofolder;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cmd_Execute(const UserName, FileName,
  Params: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'run';
  fn.asText['file'] := FileName;
  fn.asText['par'] := Params;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cmd_FileDelete(const UserName, FileName: String;
  Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'del';
  fn.asText['file'] := FileName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cmd_FileMove(const UserName, FileName,
  NewName: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'mov';
  fn.asText['file'] := FileName;
  fn.asText['new'] := NewName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cmd_FileRename(const UserName, FileName,
  NewName: String; Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'ren';
  fn.asText['file'] := FileName;
  fn.asText['new'] := NewName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.Cmd_NewFolder(const UserName, FolderName: String;
  Sender: TObject);
var
  fn: TRtcFunctionInfo;
begin
  fn := TRtcFunctionInfo.Create;
  fn.FunctionName := 'hfilecmd';
  fn.asString['c'] := 'md';
  fn.asText['dir'] := FolderName;
  Client.SendToUser(Sender, UserName, fn);
end;

procedure TRtcPDesktopHost.InitData;
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

function TRtcPDesktopHost.LockUI(const UserName: String)
  : TRtcAbsPHostFileTransferUI;
begin
  CSUI.Acquire;
  try
    Result := TRtcAbsPHostFileTransferUI(UIs.asPtr[UserName]);
    if assigned(Result) then
      Result.Locked := Result.Locked + 1;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPDesktopHost.UnlockUI(UI: TRtcAbsPHostFileTransferUI);
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

procedure TRtcPDesktopHost.Event_Error(Sender: TObject);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_LogOut(Sender: TObject);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileTransInit(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileTransOpen(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.Event_FileTransClose(Sender: TObject;
  const user: String);
var
  UI: TRtcAbsPHostFileTransferUI;
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

procedure TRtcPDesktopHost.AddUI(UI: TRtcAbsPHostFileTransferUI);
begin
  CSUI.Acquire;
  try
    if UIs.asBoolean[UI.UserName] then
      if assigned(UIs.asPtr[UI.UserName]) and (UIs.asPtr[UI.UserName] <> UI) then
        TRtcAbsPHostFileTransferUI(UIs.asPtr[UI.UserName]).Module := nil;

    UIs.asBoolean[UI.UserName] := True;
    UIs.asPtr[UI.UserName] := UI;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPDesktopHost.RemUI(UI: TRtcAbsPHostFileTransferUI);
begin
  CSUI.Acquire;
  try
    UIs.asBoolean[UI.UserName] := False;
    UIs.asPtr[UI.UserName] := nil;
  finally
    CSUI.Release;
  end;
end;

procedure TRtcPDesktopHost.Call_JoinedUsersGroup(Sender: TObject;
  const group, uname: String; uinfo:TRtcRecord);
begin
  inherited;

  if (group = 'desk') then
    if not isSubscriber(uname) then
//      if (MayUploadFiles(uname) or MayDownloadFiles(uname)) and
      if  Event_QueryAccess(Sender, uname) then
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

procedure TRtcPDesktopHost.Call_LeftUsersGroup(Sender: TObject;
  const group, uname: String);
begin
  if (group = 'desk') then
    if setSubscriber(uname, False) then
    begin
      StopFileSending(Sender, uname);
      Event_FileTransClose(Sender, uname);
      Event_OldUser(Sender, uname);
    end;

  inherited;
end;

{ TRtcAbsPHostFileTransferUI }

constructor TRtcAbsPHostFileTransferUI.Create(AOwner: TComponent);
begin
  inherited;
  FModule := nil;
  FUserName := '';
end;

destructor TRtcAbsPHostFileTransferUI.Destroy;
begin
  Module := nil;
  inherited;
end;

procedure TRtcAbsPHostFileTransferUI.Open(Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Open(UserName, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Close(Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Close(UserName, Sender);
end;

function TRtcAbsPHostFileTransferUI.CloseAndClear(Sender: TObject = nil): boolean;
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

procedure TRtcAbsPHostFileTransferUI.Send(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Send(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Fetch(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Fetch(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cancel_Fetch(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cancel_Fetch(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cancel_Send(const FileName: String;
  const tofolder: String = ''; Sender: TObject = nil);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cancel_Send(UserName, FileName, tofolder, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Call(const Data: TRtcFunctionInfo;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Call(UserName, Data, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.GetFileList(const FolderName, FileMask: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.GetFileList(UserName, FolderName, FileMask, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cmd_Execute(const FileName, Params: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_Execute(UserName, FileName, Params, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cmd_FileDelete(const FileName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_FileDelete(UserName, FileName, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cmd_FileMove(const FileName, NewName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_FileMove(UserName, FileName, NewName, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cmd_FileRename(const FileName, NewName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_FileRename(UserName, FileName, NewName, Sender);
end;

procedure TRtcAbsPHostFileTransferUI.Cmd_NewFolder(const FolderName: String;
  Sender: TObject);
begin
  if (UserName <> '') and assigned(FModule) then
    FModule.Cmd_NewFolder(UserName, FolderName, Sender);
end;

function TRtcAbsPHostFileTransferUI.GetModule: TRtcPDesktopHost;
begin
  Result := FModule;
end;

procedure TRtcAbsPHostFileTransferUI.SetModule(const Value: TRtcPDesktopHost);
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

function TRtcAbsPHostFileTransferUI.GetUserName: String;
begin
  Result := FUserName;
end;

procedure TRtcAbsPHostFileTransferUI.SetUserName(const Value: String);
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
//FileTrans-

initialization

if not IsWinNT then
  RTC_CAPTUREBLT := 0;

end.
