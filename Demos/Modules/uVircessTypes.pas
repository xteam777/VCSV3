unit uVircessTypes;

interface

uses
  Windows, Classes, rtcInfo, Controls, Forms, Messages, rtcHttpCli,
  rtcPortalHttpCli, rtcpDesktopControl, rtcpFileTrans, rtcpChat, ShellApi;

type
  TWorkThread = class(TThread)
  private
   { Private declarations }
  protected
    procedure Execute; override;
  public
    FDoWork: procedure of object;
  end;

  TUIOpenEvent = procedure(UserName, Action: String; var IsPending: Boolean) of Object;
  TUICloseEvent = procedure(AThreadId: Cardinal) of Object;
  TOnCustomFormEvent = procedure(AHandle: THandle);
  TDoStartFileTransferring = procedure(AUser, AUserName, APassword: String; ANeedGetPass: Boolean = False) of Object;

  TDoDeleteDeviceGroup = procedure(AUID: String) of object;
  TDoExit = procedure of object;

  PList = ^TList;

  PDeviceData = ^TDeviceData;
  TDeviceData = record
    UID: String;
    GroupUID: String;
    ID: Integer;
    Name: WideString;
    Password: WideString;
    Description: WideString;
    HighLight: Boolean;
    StateIndex: Integer;
  end;

  PDeviceGroup = ^TDeviceGroup;
  TDeviceGroup = class(TObject)
    UID: String;
    Name: WideString;
  end;

  {Stores a fill range which is equal to a scanline but there can be many fill ranges for one X coordinate}
  TRange = packed record
    X: Integer;
    Count: Word;
  end;
  TRangeList = array of TRange;
  TRangeListArray = array of TRangeList;

  TRGBArray = ARRAY[0..32767] OF TRGBTriple;
  pRGBArray = ^TRGBArray;

  pRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = ARRAY[word] OF TRGBTriple;

  PRtcHttpPortalClient = ^TRtcHttpPortalClient;
  PRtcPDesktopControl = ^TRtcPDesktopControl;
  PRtcPFileTransfer = ^TRtcPFileTransfer;
  PRtcPChat = ^TRtcPChat;

  PRtcHttpClient = ^TRtcHttpClient;

//  PGatewayRec = ^TGatewayRec;
//  TGatewayRec = record
//    GatewayClient: PRtcHttpPortalClient;
//    DesktopControl: PRtcPDesktopControl;
//    FileTransfer: PRtcPFileTransfer;
//    Chat: PRtcPChat;
//    ID: String;
//    Action: String;
//    UIHandle: THandle;
//    LockedState: Integer;
//    UIClosed: Boolean;
//    Stopped: Boolean;
//  end;

  PPortalConnection = ^TPortalConnection;
  TPortalConnection = record
    ThreadID: Cardinal;
    ID: String;
    Action: String;
    UIHandle: THandle;
  end;

  PGatewayServerRec = ^TGatewayServerRec;
  TGatewayServerRec = record
    Address: String;
    Port: String;
    MaxUsers: Integer;
    Users: TRtcRecord;
  end;

  TPendingRequestItem = record
    UserName: String;
    Gateway: String;
    Action: String;
    Handle: THandle;
    ThreadID: Cardinal;
  end;
  PPendingRequestItem = ^TPendingRequestItem;

  TGatewayServerList = array of PGatewayServerRec;

  TExecuteProcedure = procedure of object;
  TStateProcedure = procedure(fConnected: Boolean) of object;
  TGetDeviceInfoFunc = function(uname: String): PDeviceData of object;
  TUserEvent = procedure(const UserName: String) of object;

  TFooClass = class(TControl); { ���������� �������� ������������ }

  PRangeItem = ^TRangeItem;
  TRangeItem = record
    X: Integer;
    Up: Boolean;
    Next: pRangeItem;
  end;

  TdecBitmapInfo = packed record
    bmiHeader: TBitmapInfoHeader;
    bmiColors: array[0..255] of TRGBQuad;
  end;

  TRecordState = (RSTATE_STARTED, RSTATE_PAUSED, RSTATE_STOPPED);

  TMappedFileRec = record
    hFile: THandle;
    pImage: Pointer;
  end;

  PHistoryRec = ^THistoryRec;
  THistoryRec = class(TObject)
  public
    user: String;
    username: WideString;
    password: WideString;
  end;

  tagCREATEWNDSTRUCT =  packed record
    lpcs: PCREATESTRUCT;
    hwndInsertAfter: HWND;
  end;
  CREATEWNDSTRUCT      =  tagCREATEWNDSTRUCT;
  PCREATEWNDSTRUCT     =  ^CREATEWNDSTRUCT;

  tagKBDLLHOOKSTRUCT =  packed record
    vkCode :            DWORD;
    scanCode :          DWORD;
    flags :             DWORD;
    time :              DWORD;
    dwExtraInfo :       Integer;
  end;
  KBDLLHOOKSTRUCT      =  tagKBDLLHOOKSTRUCT;
  PKBDLLHOOKSTRUCT     =  ^KBDLLHOOKSTRUCT;

  tagMSLLHOOKSTRUCT = packed record
    pt: TPoint;
    mouseData: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;
  MSLLHOOKSTRUCT = tagMSLLHOOKSTRUCT;
  PMSLLHOOKSTRUCT = ^MSLLHOOKSTRUCT;

  TInputsArray = array[0..0] of TInput;
  PInputsArray = ^TInputsArray;

const
  MSG_STATUS_UNKNOWN = -1;
  MSG_STATUS_ONLINE = 0;
  MSG_STATUS_OFFLINE = 1;

  LCK_STATE_UNLOCKED = 0;
  LCK_STATE_SAS = 1;
  LCK_STATE_LOCKED = 2;
  LCK_STATE_SCREENSAVER = 3;

  RTC_HOSTSERVICE_NAME = 'VircessService'; //������ ����������, ����� ������ �� ����������
  RTC_HOSTSERVICE_DISPLAY_NAME = 'Vircess';


implementation


procedure TWorkThread.Execute;
begin
  if Assigned(FDoWork) then
    Synchronize(FDoWork);
end;


end.