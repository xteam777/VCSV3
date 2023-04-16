 unit CommonData;

interface

uses
  Windows, Classes, Messages, RecvDataObject;

type
  TMessageTypeEvent = (mteUnknown,
                       mteNewClipText,
                       mteGetSingleFile,
                       mteApplySingleFile,
                       mteNewClipFiles,
                       mteClearClipFiles,
                       mteNoFile,
                       mteRegistration,
                       mteRegistrationOK);

  THelperIOData = record
    //Out from helper
    BitmapSize: Cardinal;
    HaveScreen: Boolean;
    ScreenWidth : Integer;
    ScreenHeight : Integer;
    BitsPerPixel : Integer;
    MouseFlags : DWORD;
    MouseCursor : HCURSOR;
    MouseX, MouseY: Integer;
    DirtyRCnt: Integer;
    MovedRCnt: Integer;

    //In to helper
    PID: DWORD;
    ipBase_ScreenBuff: PByte;
    ipBase_DirtyR: PByte;
    ipBase_MovedR: PByte;
    ipBase_MovedRP: PByte;
  end;

const
  RMX_VERSION = '3.0';

  WM_SETCURRENTFRAME = WM_USER + 1001;
  WM_TASKBAREVENT = WM_USER + 1002;
  WM_CHANGE_LOCKED_STATUS = WM_USER + 1003;
  WM_BLOCK_INPUT_MESSAGE = WM_USER + 1004;
  WM_DRAG_FULL_WINDOWS_MESSAGE = WM_USER + 1005;
  WM_SET_FILES_TO_CLIPBOARD = WM_USER + 1006;
  WM_GET_FILES_FROM_CLIPBOARD = WM_USER + 1007;
//  WM_BROADCAST_LOGOFF = WM_USER + 1008;

  EVENT_KEY_DOWN = 0;
  EVENT_KEY_UP = 1;
  EVENT_KEY_PRESS = 2;
  EVENT_KEY_SPECIAL = 3;
  EVENT_KEY_LWIN = 4;
  EVENT_KEY_RWIN = 5;

  QT_SENDINPUT = 1;
  QT_SENDCAD = 2;
  QT_SENDCOPY = 3;
  QT_SENDAT = 4;
  QT_SENDSAT = 5;
  QT_SENDCAT = 6;
  QT_SENDSCAT = 7;
  QT_SENDWIN = 8;
  QT_SENDRWIN = 9;
  QT_SENDHDESK = 10;
  QT_SENDSDESK = 11;
  QT_SENDBKM = 12;
  QT_SENDUBKM = 13;
  QT_SENDOFFMON = 14;
  QT_SENDONMON = 15;
  QT_SENDLCKSYS = 16;
  QT_SENDLOGOFF = 17;
  QT_GETDATA = 18;

var
  MainFormHandle: THandle;
  CurrentSessionID: DWORD;
//  IsConsoleClient: Boolean;
  IsService: Boolean; //Текущий процесс - это сервис. Нужен для обращения к текущему консольному хелперу. Если False, то обращаемся к хелперу текущей сессии
  ActiveConsoleSessionID: DWORD;
  CurrentProcessID: DWORD;
  IsWinServer: Boolean;
  CB_DataObject: TDataObject;
//  TorServiceID: String;
//  TorProcessID: DWORD;

implementation

end.
