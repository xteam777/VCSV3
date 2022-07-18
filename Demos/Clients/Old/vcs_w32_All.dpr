program vcs_x64;

uses
//  FastMM4,
  Winapi.Windows,
//  Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  CommonData,
  rtcLog,
  NTPriveleges,
  SASLibEx,
//  SyncObjs,
//  FWIOCompletionPipes;
  // cromis units
  Cromis.Comm.Custom, Cromis.Comm.IPC, Cromis.Threading;
//  rtcWinlogon,
  //FastDIB in 'Lib\FastDIB.pas';

type
  // Controls.TCMMouseWheel relies on TShiftState not exceeding 2 bytes in size
  TShiftState = set of (ssShift, ssAlt, ssCtrl,
    ssLeft, ssRight, ssMiddle, ssDouble, ssTouch, ssPen, ssCommand, ssHorizontal);

  RtcString = String;

{  TInputEmulator = class
  private
    FShiftDown, FCtrlDown, FAltDown: Boolean;

    procedure keybdevent(key: word; Down: boolean = True);

    procedure SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);
    procedure ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt: boolean);

    procedure KeyPressW(const AText: WideString; AKey: word);
//    procedure KeyPress(const AText: RtcString; AKey: word);
    procedure KeyDown(key: word; Shift: TShiftState);
    procedure KeyUp(key: word; Shift: TShiftState);

    procedure SpecialKey(const AKey: RtcString);

    procedure LWinKey(key: word);
    procedure RWinKey(key: word);

    procedure ReleaseAllKeys;
  end;}

{  TPipeObject = class
  private
    FServer: TFWPipeServer;
    FInput: TInputEmulator;
    NeedStop: Boolean;
  protected
    procedure Connect(Sender: TObject; PipeHandle: PFWPipeData);
    procedure Disconnect(Sender: TObject; PipeHandle: PFWPipeData);
    procedure Read(Sender: TObject; PipeInstance: PFWPipeData);
    procedure Idle(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    property Server: TFWPipeServer read FServer;
  end;}

  RPC_STATUS = Longint;
  I_RPC_HANDLE = Pointer;
  RPC_BINDING_HANDLE = I_RPC_HANDLE;

  ACL_SIZE_INFORMATION = record
    AceCount: DWORD;
    AclBytesInUse: DWORD;
    AclBytesFree: DWORD;
  end;

  ACE_HEADER = record
    AceType: BYTE;
    AceFlags: BYTE;
    AceSize: WORD;
  end;
  PACE_HEADER = ^ACE_HEADER;

  ACCESS_ALLOWED_ACE = record
    Header: ACE_HEADER;
    Mask: ACCESS_MASK;
    SidStart: DWORD;
  end;

  THelper = class(TObject)
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteToListBox(const AMessage: string);
    procedure OnClientConnect(const Context: ICommContext);
    procedure OnClientDisconnect(const Context: ICommContext);
    procedure OnServerError(const Context: ICommContext; const Error: TServerError);
    procedure OnExecuteRequest(const Context: ICommContext; const Request, Response: IMessageData);
  end;

const
  VCS_MAGIC_NUMBER = 777;

  DESKTOP_ALL = DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
    DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or DESKTOP_WRITEOBJECTS or
    DESKTOP_READOBJECTS or DESKTOP_SWITCHDESKTOP or GENERIC_WRITE;
  WINSTA_ALL = WINSTA_ENUMDESKTOPS or WINSTA_READATTRIBUTES or WINSTA_ACCESSCLIPBOARD or WINSTA_CREATEDESKTOP or
    WINSTA_WRITEATTRIBUTES or WINSTA_ACCESSGLOBALATOMS or WINSTA_EXITWINDOWS or WINSTA_ENUMERATE or
    WINSTA_READSCREEN or STANDARD_RIGHTS_REQUIRED;
  GENERIC_ACCESS = GENERIC_READ or GENERIC_WRITE or GENERIC_EXECUTE or GENERIC_ALL;

  HEAP_ZERO_MEMORY         = 8;
  ACL_REVISION             = 2;
  ACCESS_ALLOWED_ACE_TYPE  = 0;
  CONTAINER_INHERIT_ACE    = 2;
  INHERIT_ONLY_ACE         = 8;
  OBJECT_INHERIT_ACE       = 1;
  NO_PROPAGATE_INHERIT_ACE = 4;
  SE_GROUP_LOGON_ID        = $C0000000;
  WM_TIMER                 = $0113;
  WM_PAINT                 = $0F;
  WM_QUIT                  = $0012;

var
//  sWidth, sHeight: Integer;
  home_window_station: HWINSTA;
  hThrd: THandle;
  ThreadId: DWORD;
  CurrentDesktopName, LogonDesktopName: String;
  tidIPC, tidSS, tidIN: Cardinal;
  hThread, hThreadIPC, hThreadSS, hThreadIN: THandle;
  CurrentSessionID: DWORD;
//  PipeObj: TPipeObject;
  c: Integer;
  //EventReadBegin,
  EventWriteBegin, EventWriteEnd, EventReadEnd, EventReadBeginIN, EventWriteEndIN: THandle;
  ScreenBitmap: TBitmap;
  BmpStream: TMemoryStream;
  FHelper: THelper;
  FIPCServer: TIPCServer;
  msg: TMsg;
  NameSuffix: String;
//  CS: TCriticalSection;

  sWidth, sHeight: Integer;
  hScrDC, hMemDC: HDC;
  hDeskWin, hMap: THandle;
  pMap: Pointer;
  hBmp: HBitmap;
  bitmap_info: BITMAPINFO;
  pBits: Pointer;
  hOld: HGDIOBJ;
  CurrentPID: DWORD;
  HeaderSize: Integer;
  err: LongInt;

  dwFlags, wVk, wScan: DWORD;
  IOtype, dx, dy, mouseData: Integer;

  function RpcRevertToSelf: RPC_STATUS; stdcall; external 'rpcrt4.dll';
  function RpcImpersonateClient(BindingHandle: RPC_BINDING_HANDLE): RPC_STATUS; stdcall; external 'rpcrt4.dll';
  function ProcessIdToSessionId(dwProcessId: DWORD; out pSessionId: DWORD): BOOL; stdcall; external 'kernel32.dll';
  function WTSGetActiveConsoleSessionId: THandle; external 'Kernel32.dll' name 'WTSGetActiveConsoleSessionId';


//---------------------------------------------------------TInputEmulator-----------------------------------------//

{function BitmapsAreEqual(Bitmap1, Bitmap2: TBitmap): Boolean;
var
 Stream1, Stream2: TMemoryStream;
begin
  Assert((Bitmap1 <> nil) and (Bitmap2 <> nil), 'Params can''t be nil');
  Result:= False;
  if (Bitmap1.Height <> Bitmap2.Height) or (Bitmap1.Width <> Bitmap2.Width) then
     Exit;
  Stream1:= TMemoryStream.Create;
  try
    Bitmap1.SaveToStream(Stream1);
    Stream2:= TMemoryStream.Create;
    try
      Bitmap2.SaveToStream(Stream2);
      if Stream1.Size = Stream2.Size Then
        Result:= CompareMem(Stream1.Memory, Stream2.Memory, Stream1.Size);
    finally
      Stream2.Free;
    end;
  finally
    Stream1.Free;
  end;
end;}

{procedure TInputEmulator.keybdevent(key: word; Down: boolean = True);
var
  vk: integer;
  inputs: array[0..0] of TInput;
  dwFlags: DWORD;
begin
  vk := MapVirtualKey(key, 0);
  if Down then
    dwFlags := 0
//    keybd_event(key, vk, 0, 0)
  else
    dwFlags := KEYEVENTF_KEYUP;
//    keybd_event(key, vk, KEYEVENTF_KEYUP, 0);

  ZeroMemory(@inputs, SizeOf(TInput));
  inputs[0].Itype := INPUT_KEYBOARD;
  inputs[0].ki.dwFlags := dwFlags;
  inputs[0].ki.wVk := key;
  inputs[0].ki.wScan := vk;
  inputs[0].ki.dwExtraInfo := VCS_MAGIC_NUMBER;

  SendInput(1, inputs[0], SizeOf(inputs));
  xLog('keybdevent err = ' + IntToStr(GetLastError));
end;

procedure TInputEmulator.KeyDown(key: word; Shift: TShiftState);
var
  inputs: array[0..0] of TInput;
  numlock: boolean;
begin
  case key of
    VK_SHIFT:
      if FShiftDown then
        Exit
      else
        FShiftDown := True;
    VK_CONTROL:
      if FCtrlDown then
        Exit
      else
        FCtrlDown := True;
    VK_MENU:
      if FAltDown then
        Exit
      else
        FAltDown := True;
  end;

  if (Key >= $21) and (Key <= $2E) then
  begin
    numlock := (GetKeyState(VK_NUMLOCK) and 1 = 1);
    if numlock then
    begin
      keybdevent(VK_NUMLOCK);
      keybdevent(VK_NUMLOCK, False);
    end;
//    keybd_event(key,MapVirtualKey(key, 0), KEYEVENTF_EXTENDEDKEY, 0) // have to be Exctended ScanCodes

    ZeroMemory(@inputs, SizeOf(TInput));
    inputs[0].Itype := INPUT_KEYBOARD;
    inputs[0].ki.dwFlags := KEYEVENTF_EXTENDEDKEY;
    inputs[0].ki.wVk := key;
    inputs[0].ki.wScan := MapVirtualKey(key, 0);
    inputs[0].ki.dwExtraInfo := VCS_MAGIC_NUMBER;

    SendInput(1, inputs[0], SizeOf(inputs));
    xLog('KeyDown err = ' + IntToStr(GetLastError));
  end
  else
  begin
    numlock := False;
    keybdevent(Key);
  end;

  if numlock then
  begin
    keybdevent(VK_NUMLOCK, False);
    keybdevent(VK_NUMLOCK);
  end;
end;

procedure TInputEmulator.KeyUp(key: word; Shift: TShiftState);
var
  numlock: boolean;
begin
  case key of
    VK_SHIFT:
      if not FShiftDown then
        Exit
      else
        FShiftDown := False;
    VK_CONTROL:
      if not FCtrlDown then
        Exit
      else
        FCtrlDown := False;
    VK_MENU:
      if not FAltDown then
        Exit
      else
        FAltDown := False;
  end;

  if (key >= $21) and (key <= $2E) then
  begin
    numlock := (GetKeyState(VK_NUMLOCK) and 1 = 1);
    if numlock then
    begin
      // turn NUM LOCK off
      keybdevent(VK_NUMLOCK);
      keybdevent(VK_NUMLOCK, False);
    end;
  end
  else
    numlock := False;

  keybdevent(key, False);

  if numlock then
  begin
    // turn NUM LOCK on
    keybdevent(VK_NUMLOCK);
    keybdevent(VK_NUMLOCK, False);
  end;
end;

procedure TInputEmulator.SetKeys(capslock, lWithShift, lWithCtrl,
  lWithAlt: boolean);
begin
  if capslock then
  begin
    // turn CAPS LOCK off
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, lWithShift);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, lWithCtrl);

  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, lWithAlt);
end;

procedure TInputEmulator.ResetKeys(capslock, lWithShift, lWithCtrl,
  lWithAlt: boolean);
begin
  if lWithAlt <> FAltDown then
    keybdevent(VK_MENU, FAltDown);

  if lWithCtrl <> FCtrlDown then
    keybdevent(VK_CONTROL, FCtrlDown);

  if lWithShift <> FShiftDown then
    keybdevent(VK_SHIFT, FShiftDown);

  if capslock then
  begin
    // turn CAPS LOCK on
    keybdevent(VK_CAPITAL);
    keybdevent(VK_CAPITAL, False);
  end;
end;}

{procedure TInputEmulator.KeyPress(const AText: RtcString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
{$IFDEF RTC_BYTESTRING
    lScanCode := VkKeyScanA(AText[a]);
{$ELSE
    lScanCode := VkKeyScanW(AText[a]);
{$ENDIF
    if lScanCode = -1 then
    begin
      if not (AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;}

{procedure TInputEmulator.KeyPressW(const AText: WideString; AKey: word);
var
  a: integer;
  lScanCode: Smallint;
  lWithAlt, lWithCtrl, lWithShift: boolean;
  capslock: boolean;
begin
  for a := 1 to length(AText) do
  begin
    lScanCode := VkKeyScanW(AText[a]);

    if lScanCode = -1 then
    begin
      if not (AKey in [VK_MENU, VK_SHIFT, VK_CONTROL, VK_CAPITAL, VK_NUMLOCK])
      then
      begin
        keybdevent(AKey);
        keybdevent(AKey, False);
      end;
    end
    else
    begin
      lWithShift := lScanCode and $100 <> 0;
      lWithCtrl := lScanCode and $200 <> 0;
      lWithAlt := lScanCode and $400 <> 0;

      lScanCode := lScanCode and $F8FF;
      // remove Shift, Ctrl and Alt from the scan code

      capslock := GetKeyState(VK_CAPITAL) > 0;

      SetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);

      keybdevent(lScanCode);
      keybdevent(lScanCode, False);

      ResetKeys(capslock, lWithShift, lWithCtrl, lWithAlt);
    end;
  end;
end;

procedure TInputEmulator.LWinKey(key: word);
begin
  SetKeys(False, False, False, False);
  keybdevent(VK_LWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_LWIN, False);
  ResetKeys(False, False, False, False);
end;

procedure TInputEmulator.RWinKey(key: word);
begin
  SetKeys(False, False, False, False);
  keybdevent(VK_RWIN);
  keybdevent(key);
  keybdevent(key, False);
  keybdevent(VK_RWIN, False);
  ResetKeys(False, False, False, False);
end;

procedure TInputEmulator.SpecialKey(const AKey: RtcString);
var
  capslock: Boolean;
  err: Integer;
  res: Boolean;
  file_name1, file_name2, s: String;
begin
  capslock := GetKeyState(VK_CAPITAL) > 0;

  if AKey = 'CAD' then
  begin
    XLog('Simulate CAD');
    // Ctrl+Alt+Del}
{    if (Win32MajorVersion >= 6) then //vista\server 2k8
    begin
      if IsServiceStarted(RTC_HOSTSERVICE_NAME) then
        ExecuteCtrlAltDel
      else
      begin
        file_name1 := GetTempFile + '.exe'; //Доделать через SAS
        SaveResourceToFile('RUNASSYS', file_name1);

        file_name2 := GetTempFile + '.bat';
        s := file_name1 + ' "' + AppFileName + '" /CAD' + #13#10;
        s := s + 'DEL ' + file_name1 + #13#10;
        s := s + 'DEL ' + file_name2 + #13#10;
        s := s + 'PAUSE';
        Write_File(file_name2, s);
        ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);
      end;

//      EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//      SetLastError(EleavateSupport.RunElevated(file_name2, '', Application.Handle, Application.ProcessMessages));
//      err := GetLastError;
//      if err <> ERROR_SUCCESS then
//        XLog(SysErrorMessage(err));
    end
    else
      WinExec('taskmgr.exe', SW_SHOW);}

//    if UpperCase(Get_UserName) = 'SYSTEM' then
//    begin
//      XLog('Executing CtrlAltDel as SYSTEM user ...');
//      SetKeys(capslock, False, False, False);
//      if not Post_CtrlAltDel then
//        begin
//        XLog('CtrlAltDel execution failed as SYSTEM user');
//        if rtcGetProcessID(AppFileName) > 0 then
//          begin
//          XLog('Sending CtrlAltDel request to Host Service ...');
//          Write_File(ChangeFileExt(AppFileName, '.cad'), '');
//          end;
//        end
//      else
//        XLog('CtrlAltDel execution successful');
//      ResetKeys(capslock, False, False, False);
//    end
//    else
//    begin
//      if rtcGetProcessID(AppFileName) > 0 then
//        begin
//        XLog('Sending CtrlAltDel request to Host Service ...');
//        Write_File(ChangeFileExt(AppFileName, '.cad'), '');
//        end
//      else
//        begin
//        XLog('Emulating CtrlAltDel as "'+Get_UserName+'" user ...');
//        SetKeys(capslock, False, True, True);
//        keybdevent(VK_ESCAPE);
//        keybdevent(VK_ESCAPE, False);
//        ResetKeys(capslock, False, True, True);
//        end;
//    end;
{  end
  else if AKey = 'COPY' then
  begin
    // Ctrl+C
    SetKeys(capslock, False, True, False);
    keybdevent(Ord('C'));
    keybdevent(Ord('C'), False);
    ResetKeys(capslock, False, True, False);
  end
  else if AKey = 'AT' then
  begin
    // Alt+Tab
    SetKeys(capslock, False, False, True);
    keybdevent(VK_TAB);
    keybdevent(VK_TAB, False);
    ResetKeys(capslock, False, False, True);
  end
  else if AKey = 'SAT' then
  begin
    // Shift+Alt+Tab
    SetKeys(capslock, True, False, True);
    keybdevent(VK_TAB);
    keybdevent(VK_TAB, False);
    ResetKeys(capslock, True, False, True);
  end
  else if AKey = 'CAT' then
  begin
    // Ctrl+Alt+Tab
    SetKeys(capslock, False, True, True);
    keybdevent(VK_TAB);
    keybdevent(VK_TAB, False);
    ResetKeys(capslock, False, True, True);
  end
  else if AKey = 'SCAT' then
  begin
    // Shift+Ctrl+Alt+Tab
    SetKeys(capslock, True, True, True);
    keybdevent(VK_TAB);
    keybdevent(VK_TAB, False);
    ResetKeys(capslock, True, True, True);
  end
  else if AKey = 'WIN' then
  begin
    // Windows
    SetKeys(capslock, False, False, False);
    keybdevent(VK_LWIN);
    keybdevent(VK_LWIN, False);
    ResetKeys(capslock, False, False, False);
  end
  else if AKey = 'RWIN' then
  begin
    // Windows
    SetKeys(capslock, False, False, False);
    keybdevent(VK_RWIN);
    keybdevent(VK_RWIN, False);
    ResetKeys(capslock, False, False, False);
  end
{  else if AKey = 'HDESK' then
  begin
    // Hide Wallpaper
    Hide_Wallpaper;
  end
  else if AKey = 'SDESK' then
  begin
    // Show Wallpaper
    Show_Wallpaper;
  end
  else if AKey = 'BKM' then
  begin
    // Block Keyboard and Mouse
    XLog('Block input');

//    file_name1 := GetTempFile + '.exe';
//    SaveResourceToFile('RUNASSYS', file_name1);
//
//    file_name2 := GetTempFile + '.bat';
//    s := file_name1 + ' "' + AppFileName + '" -DCAD' + #13#10;
//    s := s + 'DEL ' + file_name1 + #13#10;
//    s := s + 'DEL ' + file_name2 + #13#10;
//    s := s + 'PAUSE';
//    Write_File(file_name2, s);
//    ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);

    //Block_UserInput_Hook(True);
    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
////    Block_UserInput(True);
//    EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '-BKM', Application.Handle, Application.ProcessMessages));
//    err := GetLastError;
//    if err <> ERROR_SUCCESS then
//      XLog(SysErrorMessage(err));
  end
  else if AKey = 'UBKM' then
  begin
    // UnBlock Keyboard and Mouse
    XLog('Unblock input');

//    file_name1 := GetTempFile + '.exe';
//    SaveResourceToFile('RUNASSYS', file_name1);
//
//    file_name2 := GetTempFile + '.bat';
//    s := file_name1 + ' "' + AppFileName + '" -ECAD' + #13#10;
//    s := s + 'DEL ' + file_name1 + #13#10;
//    s := s + 'DEL ' + file_name2 + #13#10;
//    s := s + 'PAUSE';
//    Write_File(file_name2, s);
//    ShellExecute(Application.Handle, 'open', PChar(file_name2), '', '', SW_HIDE);

    //Block_UserInput_Hook(False);
    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
////    Block_UserInput(False);
//    EleavateSupport := TEleavateSupport.Create(DoElevatedTask);
//    SetLastError(EleavateSupport.RunElevated(AppFileName, '-UBKM', Application.Handle, Application.ProcessMessages));
//    err := GetLastError;
//    if err <> ERROR_SUCCESS then
//      XLog(SysErrorMessage(err));
  end
  else if AKey = 'OFFMON' then
  begin
    // Power Off Monitor
    XLog('Receive Monitor off');

    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 0, 0);
    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 0, 0);
//    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(2));
    SetBlankMonitor(True);
//    SendMessage(MainFormHandle, WM_ZORDER_MESSAGE, 0, 0);
//    Hide_Cursor;

//    ThreadHandle2 := CreateThread(nil, 0, @BlackWindow, nil, 0, &dwTId);
//    if ThreadHandle2 <> 0 then
//      CloseHandle(ThreadHandle2);
//    m_Black_window_active := True;

//    SetProcessShutdownParameters($100, 0);
//    res := SystemParametersInfo(SPI_GETPOWEROFFTIMEOUT, 0, @m_OldPowerOffTimeout, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, 3600, nil, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFACTIVE, 1, nil, 0);
//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(2));

//    Block_UserInput_Hook(True);
    //PowerOffMonitor;
  end
  else if AKey = 'ONMON' then
  begin
    // Power On Monitor
    XLog('Receive Monitor on');


    SetBlankMonitor(False);
//    Show_Cursor;
//    SendMessage(MainFormHandle, WM_ZORDER_MESSAGE, 1, 0);
    SendMessage(MainFormHandle, WM_BLOCK_INPUT_MESSAGE, 1, 0);
    SendMessage(MainFormHandle, WM_DRAG_FULL_WINDOWS_MESSAGE, 1, 0);
//    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));

//    if m_OldPowerOffTimeout <> 0 then
//      res := SystemParametersInfo(SPI_SETPOWEROFFTIMEOUT, m_OldPowerOffTimeout, nil, 0);
//    res := SystemParametersInfo(SPI_SETPOWEROFFACTIVE, 0, nil, 0);
//    m_OldPowerOffTimeout := 0;
//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));

//    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, LPARAM(-1));
//		//win8 require mouse move
//		mouse_event(MOUSEEVENTF_MOVE, 0, 1, 0, 0);
//		Sleep(40);
//		mouse_event(MOUSEEVENTF_MOVE, 0, DWORD(-1), 0, 0);
//
//    PostMessage(FindWindow(('blackscreen'), 0), WM_CLOSE, 0, 0);
//    m_Black_window_active := False;

//    Block_UserInput_Hook(False);
    //PowerOnMonitor;
  end
  else if AKey = 'OFFSYS' then
  begin
    // Power Off System
    PowerOffSystem;
  end
  else if AKey = 'LCKSYS' then
  begin
    // Lock System
    LockSystem;
  end
  else if AKey = 'LOGOFF' then
  begin
    // Logoff
    LogoffSystem;
  end
  else if AKey = 'RSTRT' then
  begin
    // Restart
    RestartSystem;
  end;}
{end;

procedure TInputEmulator.ReleaseAllKeys;
begin
  if FShiftDown then
    KeyUp(VK_SHIFT, []);
  if FAltDown then
    KeyUp(VK_MENU, []);
  if FCtrlDown then
    KeyUp(VK_CONTROL, []);
end;}

//---------------------------------------------------------TInputEmulator-----------------------------------------//

function AddAceToWindowStation(hwinsta: HWINSTA; psid: PSID): Boolean;
var
  si: SECURITY_INFORMATION;
  psd, psdNew: PSECURITY_DESCRIPTOR;
  dwSidSize, dwSdSizeNeeded, dwNewAclSize: DWORD;
  bDaclPresent, bDaclExist: LongBool;
  pdacl, pNewAcl: PACL;
  aclSizeInfo: ACL_SIZE_INFORMATION;
  i: integer;
  pTempAce: PACE_HEADER;
  pace: ^ACCESS_ALLOWED_ACE;
begin
  Result := False;
  si := DACL_SECURITY_INFORMATION;
  pace := nil;
  psd := nil;
  dwSidSize := 0;
  pNewAcl := nil;
  psdNew := nil;
  // Obtain the DACL for the window station.

  try
    if not GetUserObjectSecurity(hwinsta, si, psd, dwSidSize, dwSdSizeNeeded) then begin
      if GetLastError = ERROR_INSUFFICIENT_BUFFER then begin
        psd := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwSdSizeNeeded);
        if psd = nil then
          Exit;

        psdNew := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwSdSizeNeeded);
        if psdNew = nil then
          Exit;

        dwSidSize := dwSdSizeNeeded;

        if not GetUserObjectSecurity(hwinsta, si, psd, dwSidSize, dwSdSizeNeeded) then
          Exit;
      end
      else begin
        Exit;
      end;
    end;

    // Create a new DACL.

    if not InitializeSecurityDescriptor(psdNew, SECURITY_DESCRIPTOR_REVISION) then
      Exit;

    // Get the DACL from the security descriptor.

    if not GetSecurityDescriptorDacl(psd, bDaclPresent, pdacl, bDaclExist) then
      Exit;

    // Initialize the ACL.

    ZeroMemory(@aclSizeInfo, SizeOf(ACL_SIZE_INFORMATION));
    aclSizeInfo.AclBytesInUse := SizeOf(ACL);

    // Call only if the DACL is not NULL.

    if pdacl <> nil then begin
      // get the file ACL size info
      if not GetAclInformation(pdacl^, @aclSizeInfo, SizeOf(ACL_SIZE_INFORMATION), AclSizeInformation) then
        Exit;
    end;

    // Compute the size of the new ACL.

    dwNewAclSize := aclSizeInfo.AclBytesInUse + (2 * SizeOf(ACCESS_ALLOWED_ACE)) + (2 * GetLengthSid(psid)) - (2 * SizeOf(DWORD));

    // Allocate memory for the new ACL.

    pNewAcl := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwNewAclSize);

    if pNewAcl = nil then
      Exit;

    // Initialize the new DACL.

    if not InitializeAcl(pNewAcl^, dwNewAclSize, ACL_REVISION) then
      Exit;

    // If DACL is present, copy it to a new DACL.

    if bDaclPresent then begin
       // Copy the ACEs to the new ACL.
      if aclSizeInfo.AceCount > 0 then begin
        for i := 0 to aclSizeInfo.AceCount - 1 do begin
          // Get an ACE.
          if not GetAce(pdacl^, i, Pointer(pTempAce)) then
            Exit;

          // Add the ACE to the new ACL.
          if not AddAce(pNewAcl^, ACL_REVISION, MAXDWORD, pTempAce, pTempAce.AceSize) then
            Exit;
        end;
      end;
    end;

    // Add the first ACE to the window station.

    pace := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, SizeOf(ACCESS_ALLOWED_ACE) + GetLengthSid(psid) - SizeOf(DWORD));

    if pace = nil then
      Exit;

    pace.Header.AceType := ACCESS_ALLOWED_ACE_TYPE;
    pace.Header.AceFlags := CONTAINER_INHERIT_ACE or INHERIT_ONLY_ACE or OBJECT_INHERIT_ACE;
    pace.Header.AceSize := SizeOf(ACCESS_ALLOWED_ACE) + GetLengthSid(psid) - SizeOf(DWORD);
    pace.Mask := GENERIC_ACCESS;

    if not CopySid(GetLengthSid(psid), @pace.SidStart, psid) then
      Exit;

    if not AddAce(pNewAcl^, ACL_REVISION, MAXDWORD, pace, pace.Header.AceSize) then
      Exit;

    // Add the second ACE to the window station.

    pace.Header.AceFlags := NO_PROPAGATE_INHERIT_ACE;
    pace.Mask := WINSTA_ALL;

    if not AddAce(pNewAcl^, ACL_REVISION, MAXDWORD, pace, pace.Header.AceSize) then
      Exit;

    // Set a new DACL for the security descriptor.

    if not SetSecurityDescriptorDacl(psdNew, True, pNewAcl, False) then
      Exit;

    // Set the new security descriptor for the window station.

    if not SetUserObjectSecurity(hwinsta, si, psdNew) then
      Exit;

    // Indicate success.

    Result := True;
  finally
    // Free the allocated buffers.

    if pace <> nil then
      HeapFree(GetProcessHeap, 0, pace);

    if pNewAcl <> nil then
      HeapFree(GetProcessHeap, 0, pNewAcl);

    if psd <> nil then
      HeapFree(GetProcessHeap, 0, psd);

    if psdNew <> nil then
      HeapFree(GetProcessHeap, 0, psdNew);
  end;
end;

function GetLogonSID(hToken: THandle; var ppsid: PSID): Boolean;
var
  dwLength: DWORD;
  ptg: ^TOKEN_GROUPS;
  i: integer;
begin
  Result := False;
  dwLength := 0;
  ptg := nil;

  try
    // Verify the parameter passed in is not NULL.
//    if ppsid = nil then
//      Exit;

    // Get required buffer size and allocate the TOKEN_GROUPS buffer.

    if not GetTokenInformation(hToken, TokenGroups, ptg, 0, dwLength) then begin

      if GetLastError <> ERROR_INSUFFICIENT_BUFFER then
        Exit;

      ptg := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwLength);

      if ptg = nil then
        Exit;

      // Get the token group information from the access token.

      if not GetTokenInformation(hToken, TokenGroups, ptg, dwLength, dwLength) then
        Exit;

      // Loop through the groups to find the logon SID.

      for i := 0 to ptg.GroupCount - 1 do begin
        if ptg.Groups[i].Attributes and SE_GROUP_LOGON_ID = SE_GROUP_LOGON_ID then begin
          // Found the logon SID; make a copy of it.

          dwLength := GetLengthSid(ptg.Groups[i].Sid);
          ppsid := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwLength);
          if ppsid = nil then
            Exit;
          if not CopySid(dwLength, ppsid, ptg.Groups[i].Sid) then begin
            HeapFree(GetProcessHeap, 0, ppsid);
            Exit;
          end;
          Break;
        end;
      end;
      Result := True;
    end;
  finally
    // Free the buffer for the token groups.
    if ptg <> nil then
      HeapFree(GetProcessHeap, 0, ptg);
  end;
end;

function AddAceToDesktop(hdesktop: HDESK; ps: PSID): Boolean;
var
  aclSizeInfo: ACL_SIZE_INFORMATION;
  bDaclExist, bDaclPresent: LongBool;
  dwNewAclSize, dwSidSize, dwSdSizeNeeded: DWORD;
  pdacl, pNewAcl: PACL;
  psd, psdNew: PSECURITY_DESCRIPTOR;
  pTempAce: PACE_HEADER;
  si: SECURITY_INFORMATION;
  i: integer;
begin
  Result := False;
  psd := nil;
  psdNew := nil;
  pNewAcl := nil;
  si := DACL_SECURITY_INFORMATION;
  dwSidSize := 0;
  try
    // Obtain the security descriptor for the desktop object.

    if not GetUserObjectSecurity(hdesktop, si, psd, dwSidSize, dwSdSizeNeeded) then begin
      if GetLastError = ERROR_INSUFFICIENT_BUFFER then begin
        psd := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwSdSizeNeeded);
        if psd = nil then
          Exit;

        psdNew := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwSdSizeNeeded);
        if psdNew = nil then
          Exit;

        dwSidSize := dwSdSizeNeeded;

        if not GetUserObjectSecurity(hdesktop, si, psd, dwSidSize, dwSdSizeNeeded) then
          Exit;
      end
      else begin
        Exit;
      end;
    end;

    // Create a new security descriptor.

    if not InitializeSecurityDescriptor(psdNew, SECURITY_DESCRIPTOR_REVISION) then
      Exit;

    // Obtain the DACL from the security descriptor.

    if not GetSecurityDescriptorDacl(psd, bDaclPresent, pdacl, bDaclExist) then
      Exit;

    // Initialize.

    ZeroMemory(@aclSizeInfo, SizeOf(ACL_SIZE_INFORMATION));
    aclSizeInfo.AclBytesInUse := SizeOf(ACL);

    // Call only if NULL DACL.

    if pdacl <> nil then begin
      // Determine the size of the ACL information.

      if not GetAclInformation(pdacl^, @aclSizeInfo, SizeOf(ACL_SIZE_INFORMATION), AclSizeInformation) then
        Exit;
    end;

    // Compute the size of the new ACL.

    dwNewAclSize := aclSizeInfo.AclBytesInUse + SizeOf(ACCESS_ALLOWED_ACE) + GetLengthSid(ps) - SizeOf(DWORD);

    // Allocate buffer for the new ACL.

    pNewAcl := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwNewAclSize);

    if pNewAcl = nil then
      Exit;

    // Initialize the new ACL.

    if not InitializeAcl(pNewAcl^, dwNewAclSize, ACL_REVISION) then
      Exit;

    // If DACL is present, copy it to a new DACL.

    if bDaclPresent then begin
      // Copy the ACEs to the new ACL.
      if aclSizeInfo.AceCount > 0 then begin
        for i := 0 to aclSizeInfo.AceCount - 1 do begin
          // Get an ACE.
          if not GetAce(pdacl^, i, Pointer(pTempAce)) then
            Exit;

          // Add the ACE to the new ACL.
          if not AddAce(pNewAcl^, ACL_REVISION, MAXDWORD, pTempAce, pTempAce.AceSize) then
            Exit;
        end;
      end;
    end;

    // Add ACE to the DACL.

    if not AddAccessAllowedAce(pNewAcl^, ACL_REVISION, DESKTOP_ALL, ps) then
      Exit;

    // Set new DACL to the new security descriptor.

    if not SetSecurityDescriptorDacl(psdNew, True, pNewAcl, False) then
      Exit;

    // Set the new security descriptor for the desktop object.

    if not SetUserObjectSecurity(hdesktop, si, psdNew) then
      Exit;

    // Indicate success.

    Result := True;
  finally
    // Free buffers.

    if pNewAcl <> nil then
      HeapFree(GetProcessHeap, 0, pNewAcl);

    if psd <> nil then
      HeapFree(GetProcessHeap(), 0, psd);

    if psdNew <> nil then
      HeapFree(GetProcessHeap(), 0, psdNew);
  end;
end;

{function StartInteractiveClientProcess(lpszUsername, lpszDomain, lpszPassword, lpCommandLine: PChar): Boolean;
var
  hToken: THandle;
  hdesktop: HDESK;
  hwinst, hwinstSave: HWINSTA;
  pi: PROCESS_INFORMATION;
  pS: PSID;
  si: STARTUPINFO;
begin
  Result := False;
  hdesktop := 0;
  hwinst := 0;
  hwinstSave := 0;
  pS := nil;

  try
    // Log the client on to the local computer.

    if not LogonUser(lpszUsername, lpszDomain, lpszPassword, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, hToken) then
      Exit;

    // Save a handle to the caller's current window station.

    hwinstSave := GetProcessWindowStation;
    if hwinstSave = 0 then
      Exit;

    // Get a handle to the interactive window station.

    hwinst := OpenWindowStation('winsta0', False, READ_CONTROL or WRITE_DAC);

    if hwinst = 0 then
      Exit;

    // To get the correct default desktop, set the caller's
    // window station to the interactive window station.

    if not SetProcessWindowStation(hwinst) then
      Exit;

    // Get a handle to the interactive desktop.

    hdesktop := OpenDesktop('default', 0, False, READ_CONTROL or WRITE_DAC or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS);

    // Restore the caller's window station.

    if not SetProcessWindowStation(hwinstSave) then
      Exit;

    if hdesktop = 0 then
      Exit;

    // Get the SID for the client's logon session.

    if not GetLogonSID(hToken, pS) then
      Exit;

    // Allow logon SID full access to interactive window station.

    if not AddAceToWindowStation(hwinst, pS) then
      Exit;

    // Allow logon SID full access to interactive desktop.

    if not AddAceToDesktop(hdesktop, pS) then
      Exit;

    // Impersonate client to ensure access to executable file.

    if not ImpersonateLoggedOnUser(hToken) then
      Exit;

    // Initialize the STARTUPINFO structure.
    // Specify that the process runs in the interactive desktop.

    ZeroMemory(@si, SizeOf(STARTUPINFO));
    si.cb := SizeOf(STARTUPINFO);
    si.lpDesktop := PChar('winsta0\default');

    // Launch the process in the client's logon session.

    Result := CreateProcessAsUser(hToken, nil, lpCommandLine, nil, nil, False, // handles are not inheritable
      NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, nil, nil, si, pi);

    // End impersonation of client.

    RevertToSelf();

    if Result and (pi.hProcess <> INVALID_HANDLE_VALUE) then begin
      WaitForSingleObject(pi.hProcess, INFINITE);
      CloseHandle(pi.hProcess);
    end;

    if pi.hThread <> INVALID_HANDLE_VALUE then
      CloseHandle(pi.hThread);

    Result := True;
  finally

    if hwinstSave <> 0 then
      SetProcessWindowStation(hwinstSave);

    // Free the buffer for the logon SID.

    if pS <> nil then
      HeapFree(GetProcessHeap, 0, pS);

    // Close the handles to the interactive window station and desktop.

    if hwinst <> 0 then
      CloseWindowStation(hwinst);

    if hdesktop <> 0 then
      CloseDesktop(hdesktop);

    // Close the handle to the client's access token.

    if hToken <> INVALID_HANDLE_VALUE then
      CloseHandle(hToken);
  end;
end;}

//function ObtainSid(
//        hToken: THandle;           // Handle to an process access token.
//        psid: PSID                 // ptr to the buffer of the logon sid
//        ): BOOL;
//var
//  bSuccess: BOOL;
//  dwIndex, dwLength: DWORD;
//  tic: TTokenInformationClass;
//  ptg: PTokenGroups;
//begin
//  bSuccess := False; // assume function will fail
//  dwLength := 0;
//  tic := TokenGroups;
//  ptg := nil;
//
//  try
//    // determine the size of the buffer
//    if not GetTokenInformation(hToken, tic, ptg, 0, dwLength) then
//    begin
//      if GetLastError() = ERROR_INSUFFICIENT_BUFFER then
//      begin
//        ptg := PTokenGroups(HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, dwLength));
//        if ptg = nil then
//          Exit;
//      end
//      else
//        Exit;
//    end;
//
//    // obtain the groups the access token belongs to
//    //
//    if not GetTokenInformation(hToken, tic, ptg, dwLength, dwLength) then
//      Exit;
//
//    // determine which group is the logon sid
//    //
//    for dwIndex := 0 to ptg^.GroupCount - 1 do
//    begin
//      if (ptg^.Groups[dwIndex].Attributes and SE_GROUP_LOGON_ID) =  SE_GROUP_LOGON_ID then
//      begin
//          // determine the length of the sid
//          dwLength := GetLengthSid(ptg^.Groups[dwIndex].Sid);
//
//          // allocate a buffer for the logon sid
//          psid := HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, dwLength);
//          if psid = nil then
//          Exit;
//
//          // obtain a copy of the logon sid
//          if not CopySid(dwLength, psid, ptg^.Groups[dwIndex].Sid) then
//               Exit;
//
//          // break out of the loop because the logon sid has been found
//          Break;
//      end;
//    end;
//
//    // indicate success
//     bSuccess := TRUE;
//  finally
//    // free the buffer for the token group
//    if ptg <> nil then
//      HeapFree(GetProcessHeap(), 0, ptg);
//  end;
//
//  Result := bSuccess;
//end;
//
//procedure RemoveSid(psid: PSID);
//begin
//  HeapFree(GetProcessHeap(), 0, psid);
//end;

//function AddTheAceWindowStation(hwinsta: HWINSTA; psid: PSID): BOOL;
//var
//  pace: ACCESS_ALLOWED_ACE;
//  aclSizeInfo: ACL_SIZE_INFORMATION;
//  bDaclExist, bDaclPresent, bSuccess: BOOL;
//  dwNewAclSize, dwSidSize, dwSdSizeNeeded: DWORD;
//  pacl, pNewAcl: PACL;
//  psd, psdNew: PSECURITY_DESCRIPTOR;
//  pTempAce: PVOID;
//  si: SECURITY_INFORMATION;
//  i: UInt;
//begin
//  bSuccess := False; // assume function will fail
//  dwSidSize := 0;
//  psd := nil;
//  psdNew := nil;
//  si := DACL_SECURITY_INFORMATION;
//
//  try
//     // obtain the dacl for the windowstation
//     if not GetUserObjectSecurity(hwinsta, si, psd, dwSidSize, dwSdSizeNeeded) then
//     if (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
//          {
//          psd = (PSECURITY_DESCRIPTOR)HeapAlloc(
//               GetProcessHeap(),
//               HEAP_ZERO_MEMORY,
//               dwSdSizeNeeded
//     );
//          if (psd == NULL)
//               __leave;
//
//          psdNew = (PSECURITY_DESCRIPTOR)HeapAlloc(
//               GetProcessHeap(),
//               HEAP_ZERO_MEMORY,
//               dwSdSizeNeeded
//               );
//          if (psdNew == NULL)
//               __leave;
//
//          dwSidSize = dwSdSizeNeeded;
//
//          if (!GetUserObjectSecurity(
//               hwinsta,
//               &si,
//               psd,
//               dwSidSize,
//               &dwSdSizeNeeded
//               ))
//               __leave;
// }
//     else
//           __leave;
//
//     //
//     // create a new dacl
////
//     if (!InitializeSecurityDescriptor(
//          psdNew,
//          SECURITY_DESCRIPTOR_REVISION
//          ))
//          __leave;
//
//     //
//// get dacl from the security descriptor
//     //
//     if (!GetSecurityDescriptorDacl(
//          psd,
//          &bDaclPresent,
//          &pacl,
//          &bDaclExist
//          ))
//          __leave;
//
//     //
//     // initialize
//     //
//     ZeroMemory(&aclSizeInfo, sizeof(ACL_SIZE_INFORMATION));
//     aclSizeInfo.AclBytesInUse = sizeof(ACL);
//
//     //
//     // call only if the dacl is not NULL
//     //
//     if (pacl != NULL)
//          {
//          // get the file ACL size info
//          if (!GetAclInformation(
//               pacl,
//               (LPVOID)&aclSizeInfo,
//               sizeof(ACL_SIZE_INFORMATION),
//               AclSizeInformation
//               ))
//               __leave;
//           }
//
//     //
//     // compute the size of the new acl
//     //
//     dwNewAclSize = aclSizeInfo.AclBytesInUse + (2 *
//     sizeof(ACCESS_ALLOWED_ACE)) + (2 * GetLengthSid(psid)) - (2 *
//     sizeof(DWORD));
//
//     //
//     // allocate memory for the new acl
//     //
//     pNewAcl = (PACL)HeapAlloc(
//          GetProcessHeap(),
//          HEAP_ZERO_MEMORY,
//          dwNewAclSize
//          );
//     if (pNewAcl == NULL)
//          __leave;
//
//     //
//     // initialize the new dacl
//     //
//     if (!InitializeAcl(pNewAcl, dwNewAclSize, ACL_REVISION))
//          __leave;
//
//     //
//     // if DACL is present, copy it to a new DACL
//     //
//     if (bDaclPresent) // only copy if DACL was present
//          {
//          // copy the ACEs to our new ACL
//          if (aclSizeInfo.AceCount)
//               {
//               for (i=0; i < aclSizeInfo.AceCount; i++)
//                    {
//                    // get an ACE
//                    if (!GetAce(pacl, i, &pTempAce))
//                         __leave;
//
//                    // add the ACE to the new ACL
//                    if (!AddAce(
//          pNewAcl,
//                         ACL_REVISION,
//                         MAXDWORD,
//                         pTempAce,
//          ((PACE_HEADER)pTempAce)->AceSize
//                         ))
//                         __leave;
//                     }
//                }
//          }
//
//     //
//     // add the first ACE to the windowstation
//     //
//     pace = (ACCESS_ALLOWED_ACE *)HeapAlloc(
//          GetProcessHeap(),
//          HEAP_ZERO_MEMORY,
//     sizeof(ACCESS_ALLOWED_ACE) + GetLengthSid(psid) -
//          sizeof(DWORD
//          ));
//     if (pace == NULL)
//          __leave;
//
//     pace->Header.AceType  = ACCESS_ALLOWED_ACE_TYPE;
//     pace->Header.AceFlags = CONTAINER_INHERIT_ACE |
//                             INHERIT_ONLY_ACE      |
//
//                             OBJECT_INHERIT_ACE;
//     pace->Header.AceSize  = sizeof(ACCESS_ALLOWED_ACE) +
//
//                             GetLengthSid(psid) - sizeof(DWORD);
//     pace->Mask            = GENERIC_ACCESS;
//
//     if (!CopySid(GetLengthSid(psid), &pace->SidStart, psid))
//          __leave;
//
//     if (!AddAce(
//          pNewAcl,
//          ACL_REVISION,
//     MAXDWORD,
//          (LPVOID)pace,
//          pace->Header.AceSize
//          ))
//          __leave;
//
//     //
//     // add the second ACE to the windowstation
//     //
//     pace->Header.AceFlags = NO_PROPAGATE_INHERIT_ACE;
//     pace->Mask            = WINSTA_ALL;
//
//     if (!AddAce(
//          pNewAcl,
//          ACL_REVISION,
//          MAXDWORD,
//          (LPVOID)pace,
//          pace->Header.AceSize
//          ))
//          __leave;
//
//          //
//          // set new dacl for the security descriptor
//          //
//          if (!SetSecurityDescriptorDacl(
//               psdNew,
//               TRUE,
//               pNewAcl,
//               FALSE
//               ))
//               __leave;
//
//           //
// // set the new security descriptor for the windowstation
// //
// if (!SetUserObjectSecurity(hwinsta, &si, psdNew))
//    __leave;
//
// //
// // indicate success
// //
// bSuccess = TRUE;
//     }
//__finally
//     {
//     //
//     // free the allocated buffers
//     //
//     if (pace != NULL)
//          HeapFree(GetProcessHeap(), 0, (LPVOID)pace);
//
//     if (pNewAcl != NULL)
//          HeapFree(GetProcessHeap(), 0, (LPVOID)pNewAcl);
//
//     if (psd != NULL)
//          HeapFree(GetProcessHeap(), 0, (LPVOID)psd);
//
//     if (psdNew != NULL)
//          HeapFree(GetProcessHeap(), 0, (LPVOID)psdNew);
//     }
//
//  Result := bSuccess;
//end;

function GetUserObjectName(hUserObject: THandle): String;
var
//  buf: PChar;
  buf: array[0..255] of Char;
  needed: Cardinal;
begin
//  buf := AllocMem(1024);
  if not GetUserObjectInformation(hUserObject, UOI_NAME, @buf, 255, needed) then
  begin
//    FreeMem(buf);
//    buf := AllocMem(needed);
    GetUserObjectInformation(hUserObject, UOI_NAME, @buf, needed, needed);
  end;
  Result := buf;
//  FreeMem(buf);
end;

{function GetUserObjectName(hUserObject: THandle): String;
var
  buf: array[0..255] of Char;
  dwLength: DWORD;
begin
  dwLength := 0;
  GetUserObjectInformation(hUserObject, UOI_NAME, @buf, 0, dwLength);
  GetUserObjectInformation(hUserObject, UOI_NAME, @buf, dwLength, dwLength);
  Result := buf;
end;}

procedure LogIfError(desc: String; err: Long);
begin
  if err <> 0 then
    xLog(desc + ' err = ' + IntToStr(err) + ' = ' + SysErrorMessage(err));
end;

// memory initialization
procedure ResetMemory(out P; Size: Longint);
begin
  if Size > 0 then
  begin
    Byte(P) := 0;
    FillChar(P, Size, 0);
  end;
end;

{procedure ScreenShot(bm: TBitmap; Left, Top, Width, Height: Integer; Window: THandle);
var
  WinDC: HDC;
  Pal: TMaxLogPalette;
begin
  bm.Width := Width;
  bm.Height := Height;

  // Get the HDC of the window...
  WinDC := GetDC(Window);
  if WinDC = 0 then
    Exit;
  try
    // Palette-device?
    if (GetDeviceCaps(WinDC, RASTERCAPS) and RC_PALETTE) = RC_PALETTE then
    begin
      ResetMemory(Pal, SizeOf(TMaxLogPalette));  // fill the structure with zeros
      Pal.palVersion := $300;                     // fill in the palette version

      // grab the system palette entries...
      Pal.palNumEntries := GetSystemPaletteEntries(WinDC, 0, 256, Pal.palPalEntry);
      if Pal.PalNumEntries <> 0 then
        bm.Palette := CreatePalette(PLogPalette(@Pal)^);
    end;

    // copy from the screen to our bitmap...
    BitBlt(bm.Canvas.Handle, 0, 0, Width, Height, WinDC, Left, Top, SRCCOPY);
  finally
    ReleaseDC(Window, WinDC);        // finally, relase the DC of the window
  end;
end;}

{procedure CreateBitMaps;
var
  DesktopHandle: HDC;
  BitMapHandle, BufHandle: HDC;
  BitMap, Buf: HBitMap;
begin
  DesktopHandle := GetDC(GetDesktopWindow);//Handle экрана
  //копия экрана
  BitMapHandle := CreateCompatibleDC(GetDC(0));//создание совместимого handl-а
  BitMap := CreateCompatibleBitmap(GetDC(0),GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));//создание совместимой битовой карты
  SelectObject(BitMapHandle, BitMap);//применение
  BitBlt(BitMapHandle,//копирование экрана
  0,0,GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
  DesktopHandle,0,0,
  SRCCOPY);

  //буфер (чтобы избавиться от мерцания)
  BufHandle := CreateCompatibleDC(GetDC(0));//создание совместимого handl-а
  buf := CreateCompatibleBitmap(GetDC(0),GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));//создание совместимой битовой карты
  SelectObject(BufHandle, Buf);//применение

  DeleteDC(DesktopHandle);//удаление Handl-а экрана

  BitBlt(BufHandle, //копирование снимка экрана в буфер
  0,0,GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
  BitMapHandle,0,0,
  SRCCOPY);

  DeleteDC(BitMapHandle);

  BitBlt(SaveBitMap.Canvas.Handle, //куда
  0,0,sWidth,sHeight,//координаты и размер
  BufHandle, //откуда
  0,0, //координаты
  SRCCOPY); //режим копирования

  DeleteDC(BufHandle);
  DeleteObject(buf);

//  SaveBitMap.SaveToFile('C:\Screenshots\VH_' + StringReplace(DateTimeToStr(Now), ':', '_', [rfReplaceAll]) + '.bmp');
//  MemStream.Clear;
//  SaveBitMap.SaveToStream(MemStream);
end;}

{function SetUserObjectFullAccess(hUserObject: THandle): Boolean;
var
  Sd: PSecurity_Descriptor;
  Si: Security_Information;
begin
  Result := not (Win32Platform = VER_PLATFORM_WIN32_NT); //IsWinNT;
  if Result then  // Win9x/ME
    Exit;
  // TODO : Check the success of called functions
  Sd := PSecurity_Descriptor(LocalAlloc(LPTR, SECURITY_DESCRIPTOR_MIN_LENGTH));
  InitializeSecurityDescriptor(Sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(Sd, True, nil, False);

  Si := DACL_SECURITY_INFORMATION;
  Result := SetUserObjectSecurity(hUserObject, Si, Sd);

  LocalFree(HLOCAL(Sd));
end;}

function WinStationEnumProc(name: LPTSTR; param: LPARAM): BOOL; stdcall;
var
  station: HWINSTA;
  oldstation: HWINSTA;
  flags: USEROBJECTFLAGS;
  tmp: Cardinal;
  mname: array[0..255] of Char;
  DesktopName: String;
  Count: Cardinal;
  err: LongInt;
  b: Bool;
  hToken, hProcess: THandle;
  pS: PSID;
begin
  try
    Result := False;
//    xLog('Check WinStation NAME = ' + name);
    station := OpenWindowStation(PChar(name), False, MAXIMUM_ALLOWED);
    tmp := 0;
    if GetUserObjectInformation(station, UOI_FLAGS, @flags, Sizeof(flags), tmp) then
      if (flags.dwFlags and WSF_VISIBLE) <> 0 then
      begin
        SetProcessWindowStation(station);
//        err := GetLastError;
//        xLog('New WinStation UOI_NAME = ' + GetUserObjectName(station) + ' Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));
        Result := True;

//        hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, GetCurrentProcessId);
//
//        if not OpenProcessToken(hProcess, TOKEN_QUERY, hToken) then
//          xLog('OpenProcessToken error: ' + SysErrorMessage(GetLastError));

        // Get the SID for the client's logon session.

//        SetUserObjectFullAccess(station);

//        if not GetLogonSID(hToken, pS) then
//          Exit;

        // Allow logon SID full access to interactive window station.

//        if pS <> nil then
//          try
//            if not AddAceToWindowStation(station, pS) then
//              Exit;
//          finally
//          end;
      end;
  finally
    if station <> 0 then
      CloseWindowStation(station);
//    if hProcess <> 0 then
//      CloseHandle(hProcess);
  end;
//  Result := True;
//  try
//    station := OpenWindowStation(name, False, MAXIMUM_ALLOWED);
//    xLog('OpenWindowStation name = ' + name);
//    LogIfError('OpenWindowStation', GetLastError);
//    oldstation := GetProcessWindowStation;
//    LogIfError('GetProcessWindowStation', GetLastError);
//    tmp := 0;
//    if not GetUserObjectInformation(station, UOI_FLAGS, @flags,
//      Sizeof(flags), tmp) then
//      Result := True
//    else
//    begin
//      if (flags.dwFlags and WSF_VISIBLE) <> 0 then
//      begin
//        b := SetProcessWindowStation(station);
//        LogIfError('GetProcessWindowStation', GetLastError);
//        if (b) then
//        begin
//          err := GetLastError;
//          xLog('New WinStation HANDLE = ' + GetUserObjectName(station) + ' UOI_NAME = ' + DesktopName + ' Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));
//
//          if (oldstation <> home_window_station) then
//            CloseWindowStation(oldstation);
//          Result := False; // success !!!
//        end
//        else
//        begin
//          CloseWindowStation(station);
//          Result := True;
//        end;
//      end
//      else
//        Result := True;
//    end;
//  except
//    on E:Exception do
//    begin
//      LogIfError(E.Message, GetLastError);
//      if station <> 0 then
//        CloseWindowStation(station);
//      if (oldstation <> home_window_station) then
//        CloseWindowStation(oldstation);
//    end;
//  end;
end;

procedure SelectInputWinStation;
//var
//  flags: USEROBJECTFLAGS;
//  tmp: Cardinal;
//  err: LongInt;
//  name: array[0..255] of Char;
//  DesktopName: String;
//  Count: Cardinal;
//  b: BOOL;
begin
//  home_window_station := 0;
//  try
//    tmp := 0;
//    home_window_station := GetProcessWindowStation;
//
//    GetUserObjectInformation(home_window_station, UOI_NAME, @name, 256, Count);
//    err := GetLastError;
//    SetString(DesktopName, name, Pred(Count));
//    xLog('Current WinStation UOI_NAME = ' + DesktopName + ' Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

//    GetUserObjectInformation(home_window_station, UOI_FLAGS, @flags,
//      Sizeof(flags), tmp);
//    err := GetLastError;
//    xLog('GetUserObjectInformation UOI_FLAGS = ' + IntToStr(flags.dwFlags) + ' Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

//  home_window_station := 0;
//  try
//    tmp := 0;
//    home_window_station := GetProcessWindowStation;
//    b := GetUserObjectInformation(home_window_station, UOI_FLAGS, @flags, Sizeof(flags), tmp);
//    if not b or ((flags.dwFlags and WSF_VISIBLE) = 0) then
////    begin
      //if
      EnumWindowStations(@WinStationEnumProc, 0);
      // then
//        home_window_station := 0;
////    end;
//  except
//    home_window_station := 0;
//  end;
end;

{procedure CreateBitmapData;
begin
  sWidth := GetSystemMetrics(SM_CXSCREEN);
  sHeight := GetSystemMetrics(SM_CYSCREEN);

  hDesktop := GetDesktopWindow;
  hScrDC := GetDC(hDesktop);
  hMemDC := CreateCompatibleDC(hScrDC);
  hBmp := CreateCompatibleBitmap(hScrDC, sWidth, sHeight);
  SelectObject(hMemDC, hBmp);

  with bitmap_info.bmiHeader do
  begin
    biSize := 40;
    biWidth := sWidth;
    //Use negative height to scan top-down.
    biHeight := -sHeight;
    biPlanes := 1;
    biBitCount := GetDeviceCaps(hScrDC, BITSPIXEL);
    biCompression := BI_RGB;
  end;
end;}

procedure CreateBitmapData;
begin
  sWidth := GetSystemMetrics(SM_CXSCREEN);
  sHeight := GetSystemMetrics(SM_CYSCREEN);

  hDeskWin := GetDesktopWindow;
  hScrDC := GetDC(hDeskWin);
  with bitmap_info.bmiHeader do
  begin
    biSize := sizeof(BITMAPINFOHEADER);
    biWidth := sWidth;
    //Use negative height to scan top-down.
    biHeight := -sHeight;
    biPlanes := 1;
    biBitCount := GetDeviceCaps(hScrDC, BITSPIXEL);
    biCompression := BI_RGB;
  end;
  pBits := nil;
  hBmp := CreateDIBSection(hScrDC, bitmap_info, DIB_RGB_COLORS, pBits, 0, 0);
end;

procedure DestroyBitmapData;
begin
  if hMemDC <> 0 then
    DeleteObject(hMemDC);
  if hBmp <> 0 then
    DeleteObject(hBmp);
  ReleaseDC(hDeskWin, hScrDC);
end;

function SwitchToActiveDesktop: String;
var
  LogonDesktop, CurDesktop: HDESK;
  name: array[0..255] of Char;
  DesktopName: String;
  Count: DWORD;
  err: LongInt;
  hToken, hProcess: THandle;
  pS: PSID;
  res: Boolean;
begin
  Result := 'Default';
//  CS.Acquire;
  try
    LogonDesktop := OpenInputDesktop(DF_ALLOWOTHERACCOUNTHOOK, False, READ_CONTROL or WRITE_DAC or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or DESKTOP_JOURNALPLAYBACK);
    if LogonDesktop = 0 then
    begin
      err := GetLastError;
      LogIfError('OpenInputDesktop HANDLE = ' + IntToStr(LogonDesktop) + ' NAME = ' + GetUserObjectName(CurDesktop), err);
    end;

//    err := GetLastError;
    //xLog('OpenInputDesktop LogonDesktop Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

    CurDesktop := GetThreadDesktop(GetCurrentThreadID);
    if CurDesktop = 0 then
    begin
      LogIfError('GetThreadDesktop: ' + GetUserObjectName(CurDesktop), GetLastError);
    end;

    if (LogonDesktop <> 0) and (GetUserObjectName(LogonDesktop) <> GetUserObjectName(CurDesktop)) then
    begin
      res := SetThreadDesktop(LogonDesktop);
      LogIfError('SetThreadDesktop', GetLastError);
//      err := GetLastError;
//      if res then
//        Result := GetUserObjectName(LogonDesktop)
//      else
//      xLog('New Desktop: ' + GetUserObjectName(LogonDesktop) + ' Err code = ' + IntToStr(err) + ' Desc = ' + SysErrorMessage(err));

//      hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, GetCurrentProcessId);
//
//      if not OpenProcessToken(hProcess, TOKEN_QUERY, hToken) then
//        xLog('OpenProcessToken error: ' + SysErrorMessage(GetLastError));

//      SetUserObjectFullAccess(LogonDesktop);

      // Get the SID for the client's logon session.

//      if not GetLogonSID(hToken, pS) then
//        Exit;

      // Allow logon SID full access to interactive desktop.

//      if pS <> nil then
//        try
//          if not AddAceToDesktop(LogonDesktop, pS) then
//            Exit;
//        finally
//        end;
    end;
  finally
    if (LogonDesktop <> 0) then
      CloseDesktop(LogonDesktop);
//    if hProcess <> 0 then
//      CloseHandle(hProcess);
//    CS.Release;
  end;
end;

{procedure SendScreenToVircess;
var
  pResult: IIPCData;
  Request: IIPCData;
  IPCClient: TIPCClient;
  TimeStamp: TDateTime;
  I: Integer;
begin
  IPCClient := TIPCClient.Create;
  try
    IPCClient.ComputerName := 'localhost';
    IPCClient.ServerName := 'Vircess_IPC';
    IPCClient.ConnectClient(cDefaultTimeout);
    try
      if IPCClient.IsConnected then
      begin
        Request := AcquireIPCData;
        Request.ID := DateTimeToStr(Now);
        //Request.Data.WriteUTF8String('Command', 'Synchronous');
        Request.Data.WriteStream('Bitmap', MemStream);
        pResult := IPCClient.ExecuteConnectedRequest(Request);

        if IPCClient.AnswerValid then
        begin

        end;

//          if IPCClient.LastError <> 0 then
//            ListBox1.Items.Add(Format('Error: Code %d', [IPCClient.LastError]));
      end;
    finally
      IPCClient.DisconnectClient;
    end;
  finally
    IPCClient.Free;
  end;
end;}

//function ThreadProc(const lpParam: LPVOID): DWORD;
//var
//  i: DWORD;
//begin
//  SelectInputWinStation;
//  SwitchToActiveDesktop;
//
//  CreateBitMaps;
//
//  ExitThread(0);
//end;

//function WndProc(hWnd: HWND; msg: UINT; wParam: WPARAM; lParam: LPARAM): LongInt; stdcall;
//var
//  LogonDesktopName: String;
//begin
//  Result := 0;
//
//  LogonDesktopName := GetUserObjectName(OpenInputDesktop(DF_ALLOWOTHERACCOUNTHOOK, False, READ_CONTROL or WRITE_DAC or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS));
//  if CurrentDesktopName <> LogonDesktopName then
//  begin
//    xLog('Desktop changed CurrentDesktopName = ' + CurrentDesktopName + ' LogonDesktopName = ' + LogonDesktopName);
//    CurrentDesktopName := LogonDesktopName;
//    PostQuitMessage(0);
//    Exit;
//  end;
//  Result := DefWindowProc(hWnd,msg,wParam,lParam);
//
////  case msg of
////    WM_DESTROY: PostQuitMessage(0);
////    else Result := DefWindowProc(hWnd,msg,wParam,lParam);
////  end;
//end;

{function CheckChangeDesktopThreadProc(pParam: Pointer): DWORD; stdcall;
begin
//  while CurrentDesktopName = LogonDesktopName do
  begin
    Sleep(25);
//    LogonDesktopName := GetUserObjectName(OpenInputDesktop(DF_ALLOWOTHERACCOUNTHOOK, False, READ_CONTROL or WRITE_DAC or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS));
  end;

//  xLog('Desktop changed CurrentDesktopName = ' + CurrentDesktopName + ' LogonDesktopName = ' + LogonDesktopName);
  ExitThread(0);
end;}

procedure mSleep(uSleep: UINT);
var
  msg: TMSG;
  id: Integer;
begin
  id := SetTimer(0, 42, uSleep, nil);

  while GetMessage(msg, 0, 0, 0) do
  begin
    if (msg.message = WM_TIMER)
      and (msg.wParam = WORD(id)) then
        Break;

    TranslateMessage(msg);
    DispatchMessage(msg);
  end;

  KillTimer(0, id);
end;

{function DoCreateMutex(AName: String): THandle;
var
  SD: TSecurityDescriptor;
  SA: TSecurityAttributes;
  pSA: PSecurityAttributes;
begin
  if not InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION) then
    xLog(Format('Error InitializeSecurityDescriptor: %s', [SysErrorMessage(GetLastError)]));

  SA.nLength := SizeOf(TSecurityAttributes);
  SA.lpSecurityDescriptor := @SD;
  SA.bInheritHandle := False;

  if not SetSecurityDescriptorDacl(SA.lpSecurityDescriptor, True, nil, False) then
    xLog(Format('Error SetSecurityDescriptorDacl: %s', [SysErrorMessage(GetLastError)]));

  pSA := @SA;

  Result := CreateMutex(pSA, False, PChar(AName));

  if Result = 0 then
    xLog(Format('Error CreateMutex: %s', [SysErrorMessage(GetLastError)]));
end;}

function DoCreateEvent(AName: String): THandle;
var
  SD: TSecurityDescriptor;
  SA: TSecurityAttributes;
  pSA: PSecurityAttributes;
begin
  if not InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION) then
    xLog(Format('Error InitializeSecurityDescriptor: %s', [SysErrorMessage(GetLastError)]));

  SA.nLength := SizeOf(TSecurityAttributes);
  SA.lpSecurityDescriptor := @SD;
  SA.bInheritHandle := False;

  if not SetSecurityDescriptorDacl(SA.lpSecurityDescriptor, True, nil, False) then
    xLog(Format('Error SetSecurityDescriptorDacl: %s', [SysErrorMessage(GetLastError)]));

  pSA := @SA;

  Result := CreateEvent(pSA, True, False, PWideChar(WideString(AName)));

  if Result = 0 then
    xLog(Format('Error CreateEvent: %s', [SysErrorMessage(GetLastError)]));
end;

{procedure SaveBitmapToMMF;
var
  CurBitmapInfoSize: Integer;
  EventReadBegin, EventReadEnd, EventWrite: THandle;
  SaveBitMap: TBitMap;
  MemStream: TMemoryStream;
begin
  EventReadBegin := 0;
  EventReadEnd := 0;
  EventWrite := 0;

  try
//    MutexRead := DoCreateMutex('VCS_SCREEN_READ_SESSION_' + IntToStr(CurrentSessionID));
    EventReadBegin := DoCreateEvent('VCS_SCREEN_READ_BEGIN_SESSION_' + IntToStr(CurrentSessionID));
    WaitForSingleObject(EventReadBegin, INFINITE);
    if EventReadBegin > 0 then
    begin
      CloseHandle(EventReadBegin);
      EventReadBegin := 0;
    end;

//    MutexWrite := DoCreateMutex('VCS_SCREEN_WRITE_SESSION_' + IntToStr(CurrentSessionID));

    MemStream := TMemoryStream.Create;
    SaveBitMap := TBitMap.Create;

    ScreenShot(SaveBitMap, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), GetDesktopWindow); //47ms

//    MemStream.Clear;
    SaveBitmap.SaveToStream(MemStream);
//    CurBitmapInfoSize := MemStream.size;
    BitmapInfoSize := MemStream.size;
  //  CurBitmapInfoSize := PBitmapFileHeader(MemStream.Memory)^.bfOffBits - SizeOf(TBitmapFileHeader) + sizeof(pSize);

    hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
      BitmapInfoSize + sizeof(BitmapInfoSize) + 4, PWideChar(WideString('Global\VCS_SCREEN_SESSION_' + IntToStr(CurrentSessionID))));
    pMap := MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, BitmapInfoSize + sizeof(BitmapInfoSize) + 4);

//    if BitmapInfoSize <> CurBitmapInfoSize then
//    begin
//      BitmapInfoSize := CurBitmapInfoSize;
//
//      UnmapViewOfFile(pMap); //Disposes the mem map
//      if hMap > 0 then
//        CloseHandle(hMap);
//
//      hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
//        BitmapInfoSize + sizeof(BitmapInfoSize) + 4, PWideChar(WideString('Global\VCS_SCREEN_SESSION_' + IntToStr(CurrentSessionID))));
//      pMap := MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, BitmapInfoSize + sizeof(BitmapInfoSize) + 4);
//    end;

    CopyMemory(pMap, @BitmapInfoSize, sizeof(BitmapInfoSize));
    MemStream.Position := 0;
    MemStream.Read((PByte(pMap) + sizeof(BitmapInfoSize) + 4)^, BitmapInfoSize);

    EventWrite := DoCreateEvent('VCS_SCREEN_WRITE_SESSION_' + IntToStr(CurrentSessionID));
    PulseEvent(EventWrite);

    EventReadEnd := DoCreateEvent('VCS_SCREEN_READ_END_SESSION_' + IntToStr(CurrentSessionID));
    WaitForSingleObject(EventReadEnd, INFINITE);
    if EventReadEnd > 0 then
    begin
      CloseHandle(EventReadEnd);
      EventReadEnd := 0;
    end;
//    MemStream.Clear;
  finally
    if hMap > 0 then
      UnmapViewOfFile(pMap); //Disposes the mem map
    if hMap > 0 then
      CloseHandle(hMap);
    SaveBitMap.Free;
    MemStream.Free;
//    CloseHandle(hMap);
//    ReleaseMutex(MutexWrite);
//    CloseHandle(MutexWrite);
    if EventReadBegin > 0 then
    begin
      CloseHandle(EventReadBegin);
      EventReadBegin := 0;
    end;
    if EventReadEnd > 0 then
    begin
      CloseHandle(EventReadEnd);
      EventReadEnd := 0;
    end;
    if EventWrite <> 0 then
    begin
      ResetEvent(EventWrite);
      CloseHandle(EventWrite);
      EventWrite := 0;
    end;
  end;
end;}

{ TSimpleObject }

//  Инициализация сервера
// =============================================================================
{constructor TPipeObject.Create;
begin
  FInput := TInputEmulator.Create;
  // Флаг NeedStop используется для остановки сервера
  NeedStop := False;
  // Создаем сервер
  FServer := TFWPipeServer.Create('Vircess_IPC_Session_' + IntToStr(CurrentSessionID));
  // Назначаем обработчики
  FServer.OnConnect := Connect;
  FServer.OnDisconnect := Disconnect;
  FServer.OnNeedProcessReadAndWrite := Read;
  FServer.OnIdle := Idle;
end;

destructor TPipeObject.Destroy;
begin
  FServer.Free;
  FInput.Free;
  inherited;
end;

//  Метод вызывается при подсоединении нового клиента
// =============================================================================
procedure TPipeObject.Connect(Sender: TObject; PipeHandle: PFWPipeData);
begin
//  xLog('New client connected. Handle ', PipeHandle^.PipeHandle);
end;

//  Метод вызывается при отсоединении клиента
// =============================================================================
procedure TPipeObject.Disconnect(Sender: TObject; PipeHandle: PFWPipeData);
begin
//  xLog('Client with handle ', PipeHandle^.PipeHandle, ' disconnected');
end;

//  Метод вызывается в тот момент когда сервер ничем не занят
// =============================================================================
procedure TPipeObject.Idle(Sender: TObject);
begin
  if NeedStop then
    FServer.Active := False;
end;

function GetInputDesktopName: String;
var
  desk: HDESK;
begin
  try
    desk := OpenInputDesktop(0, False, GENERIC_ALL);
    if desk <> 0 then
    begin
      Result := GetUserObjectName(desk);
      CloseDesktop(desk);
    end
    else
      Result := 'Winlogon';
  except
    Result := 'Winlogon';
  end;
end;

procedure keybdevent(key: word; Down: boolean = True);
var
  vk: integer;
begin
  vk := MapVirtualKey(key, 0);
  if Down then
    keybd_event(key, vk, 0, 0)
  else
    keybd_event(key, vk, KEYEVENTF_KEYUP, 0);
end;

function IntToShiftState(const Value: Integer): TShiftState;
begin
  case Value of
    0: Result := [ssShift];
    1: Result := [ssAlt];
    2: Result := [ssCtrl];
    3: Result := [ssLeft];
    4: Result := [ssRight];
    5: Result := [ssMiddle];
    6: Result := [ssDouble];
    7: Result := [ssTouch];
    8: Result := [ssPen];
    9: Result := [ssCommand];
    10: Result := [ssHorizontal];
  else
    Result := [];
  end;
end;

//  Метод вызывается при получении данных от клиента
// =============================================================================
procedure TPipeObject.Read(Sender: TObject; PipeInstance: PFWPipeData);
var
  Len: Integer;
//  Buff: AnsiString;
  IOType, dwFlags, mouseData, kbdEvent, strLen: DWORD;
  dx, dy: Longint;
  wVk, wScan: WORD;
  inputs: array[0..0] of TInput;
  sWidth, sHeight: Integer;
  sShift: TShiftState;
  sText: WideString;
  Shift: Integer;
begin
  // Проверяем размер приемного буффера.
  // В данном демо режиме клиент всегда должен
  // отправлять данные размером не менее 4 байт
  if PipeInstance^.ReadBuffSize <> 24 then
    xLog('Wrong readbuff size.');

  Move(PipeInstance^.ReadBuff[0], IOType, 4);

  SelectInputWinStation;
  SwitchToActiveDesktop;

  ZeroMemory(@inputs, SizeOf(TInput));
  if IOType = INPUT_MOUSE then
  begin
    Move(PipeInstance^.ReadBuff[4], dwFlags, 4);
    Move(PipeInstance^.ReadBuff[8], dx, 4);
    Move(PipeInstance^.ReadBuff[12], dy, 4);
    Move(PipeInstance^.ReadBuff[16], mouseData, 4);
    Move(PipeInstance^.ReadBuff[20], wVk, 2);
    Move(PipeInstance^.ReadBuff[22], wScan, 2);

    inputs[0].Itype := IOType;
    inputs[0].mi.dwFlags := dwFlags;
    sWidth := GetSystemMetrics(SM_CXSCREEN);
    sHeight := GetSystemMetrics(SM_CYSCREEN);
    if (MOUSEEVENTF_MOVE and dwFlags) = MOUSEEVENTF_MOVE then
    begin
      inputs[0].mi.dx := Round(dx / (sWidth - 1) * 65535);
      inputs[0].mi.dy := Round(dy / (sHeight - 1) * 65535);
    end
    else
    begin
      inputs[0].mi.dx := dx;
      inputs[0].mi.dy := dy;
    end;
    inputs[0].mi.mouseData := mouseData;
    inputs[0].mi.dwExtraInfo := VCS_MAGIC_NUMBER;
    try
      SendInput(1, inputs[0], SizeOf(inputs));
    except
      on e: Exception do
        xLog('SendInput exception = ' + e.Message + ' with err = ' + IntToStr(GetLastError));
    end;
  end
  else
  begin
    Move(PipeInstance^.ReadBuff[4], kbdEvent, 4);
    if kbdEvent = EVENT_KEY_DOWN then
    begin
      Move(PipeInstance^.ReadBuff[8], wVk, 2);
      Move(PipeInstance^.ReadBuff[10], Shift, 4);
      FInput.KeyDown(wVk, IntToShiftState(Shift));
    end
    else
    if kbdEvent = EVENT_KEY_UP then
    begin
      Move(PipeInstance^.ReadBuff[8], wVk, 2);
      Move(PipeInstance^.ReadBuff[10], Shift, 4);
      FInput.KeyUp(wVk, IntToShiftState(Shift));
    end
    else
    if kbdEvent = EVENT_KEY_PRESS then
    begin
      Move(PipeInstance^.ReadBuff[8], wVk, 2);
      Move(PipeInstance^.ReadBuff[10], strLen, 4);
      Move(PipeInstance^.ReadBuff[14], sText, strLen * SizeOf(WideString));
      FInput.KeyPressW(sText, wVk);
    end
  end;}

{  // Читаем размер данных
  Move(PipeInstance^.ReadBuff[0], Len, 4);


  // Проверка, получено ли число -1?
  if Len = -1  then
    // Если получено - то выставляем флаг о необходимости остановки сервера
    // Данный флаг будет зачитан в режиме IDLE и сервер будет корректно остановлен
    // Если останавливать сервер прямо сейчас командой FServer.Active := False,
    // то клиент получит ошибку о том что на другой стороне пайпа никого нет.
    NeedStop := True
  else
  begin
    // Если получено число отличное от -1, зачитываем буфер с текстом
    // добавляем к нему слово "DONE" и отправляем обратно
    if Len > 0 then
    begin
      SetLength(Buff, Len);
      Move(PipeInstance^.ReadBuff[4], Buff[1], Len);
      Buff := Buff + 'DONE';
      Len := Length(Buff);
      Move(Len, PipeInstance^.WriteBuff[0], 4);
      Move(Buff[1], PipeInstance^.WriteBuff[4], Len);
      // При этом не забываем указать размер отправляемого буффера
      PipeInstance^.WriteBuffSize := Len + 4;
    end;
  end;}
{end;

function IPCServerThreadProc(pParam: Pointer): DWORD; stdcall;
begin
  try
    PipeObj := TPipeObject.Create;
    try
      // тонкий момент, после команды Server.Active := True управление на
      // следующую строку кода не произойдет до тех пор, пока сервер
      // не будет остановлен, т.е. не будет выполнена команда
      // Server.Active := False
      PipeObj.Server.Active := True;
      xLog('Server stopped');
    finally
      PipeObj.Free;
    end;
  except
    on E:Exception do
      xLog(E.Classname + ': ' + E.Message);
  end;
end;}

{procedure SaveBitmapToMMF;
var
  h, hMap: THandle;
  pMap: Pointer;
  hScrDC, hMemDC: HDC;
  hBmp: HBitmap;
  bitmap_info: BITMAPINFO;
  BitmapSize: Int64;
  sWidth, sHeight: Integer;
begin
  try
//    WaitForSingleObject(EventReadEnd, INFINITE);
//    ResetEvent(EventReadEnd);

    WaitForSingleObject(EventReadBegin, INFINITE);
    ResetEvent(EventReadBegin);

    h := GetDesktopWindow;
    sWidth := GetSystemMetrics(SM_CXSCREEN);
    sHeight := GetSystemMetrics(SM_CYSCREEN);

    hScrDC := GetDC(h);
    hMemDC := CreateCompatibleDC(hScrDC);
    hBmp := CreateCompatibleBitmap(hScrDC, sWidth, sHeight);
    SelectObject(hMemDC, hBmp);
    BitBlt(hMemDC, 0, 0, sWidth, sHeight, hScrDC, 0, 0, SRCCOPY);

    with bitmap_info.bmiHeader do
    begin
      biSize := 40;
      biWidth := sWidth;
      //Use negative height to scan top-down.
      biHeight := -sHeight;
      biPlanes := 1;
      biBitCount := GetDeviceCaps(hScrDC, BITSPIXEL);
      biCompression := BI_RGB;
    end;

    BitmapSize := sHeight * sWidth * 4;
    hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
//      BitmapSize + sizeof(BitmapSize), PWideChar(WideString('Global\VCS_SCREEN_SESSION_' + IntToStr(CurrentSessionID))));
      BitmapSize + sizeof(BitmapSize), PWideChar(WideString('Session\' + IntToStr(CurrentSessionID) + '\VCS_SCREEN')));
    pMap := MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, BitmapSize + SizeOf(BitmapSize));

    CopyMemory(pMap, @BitmapSize, SizeOf(BitmapSize));
    GetDIBits(hMemDC, hBmp, 0, sHeight, (PByte(pMap) + SizeOf(BitmapSize)), bitmap_info, DIB_RGB_COLORS);

    DeleteObject(hBmp);
    DeleteObject(hMemDC);
    ReleaseDC(h, hScrDC);

//    ResetEvent(EventReadEnd);
    SetEvent(EventWriteEnd);

//    WaitForSingleObject(EventReadEnd, INFINITE);
//    SetEvent(EventReadEnd);
  finally
    if hMap > 0 then
      UnmapViewOfFile(pMap); //Disposes the mem map
    if hMap > 0 then
      CloseHandle(hMap);
  end;
end;}

constructor THelper.Create;
begin
  inherited;
end;

destructor THelper.Destroy;
begin
  inherited;
end;

procedure THelper.WriteToListBox(const AMessage: string);
begin

end;

procedure THelper.OnClientConnect(const Context: ICommContext);
begin

end;

procedure THelper.OnClientDisconnect(const Context: ICommContext);
begin

end;

procedure THelper.OnServerError(const Context: ICommContext; const Error: TServerError);
begin

end;

{function ScreenShotThreadProc(pParam: Pointer): DWORD; stdcall;
begin
//  SelectInputWinStation;
//  CurrentDesktopName := SwitchToActiveDesktop;

//  ScreenShot(SaveBitMap, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), GetDesktopWindow);
  ExitThread(0);
end;}

procedure CheckSAS(value : Boolean; name : String);
var
  s, sErrValue : String;
begin
	if (not value) then
  begin
    case GetLastError() of
			{ERROR_REQUEST_OUT_OF_SEQUENCE}776:
            	sErrValue := 'You need to call SASLibEx_Init first!';

			ERROR_PRIVILEGE_NOT_HELD:
				sErrValue := 'The function needs a system privilege that is not available in the process.';

			ERROR_FILE_NOT_FOUND:
				sErrValue := 'The supplied session is not available.';


			ERROR_CALL_NOT_IMPLEMENTED:
				sErrValue := 'The called function is not available in this demo (license).';


			ERROR_OLD_WIN_VERSION:
				sErrValue := 'The called function does not support the Windows system.';

    else
			sErrValue := SysErrorMessage(GetLastError());
		end;

		s := Format('The function call %s failed. '#13#10'%s',
			[name, sErrValue]);


		xLog(s);
  end;
end;

function ScreenShotThreadProc(pParam: Pointer): DWORD; stdcall;
var
  BitmapSize: Cardinal;
  mResult: Boolean;
  CurOffset: Integer;
begin
  try
    while True do
    begin
      try
        try
    //      WaitForSingleObject(EventReadEnd, INFINITE);
    //      ResetEvent(EventReadEnd);

          WaitForSingleObject(EventWriteBegin, INFINITE);
          ResetEvent(EventWriteBegin);
          ResetEvent(EventReadEnd);

          SelectInputWinStation;
          SwitchToActiveDesktop;

          CreateBitmapData;

          hMemDC := CreateCompatibleDC(hScrDC);
          hOld := SelectObject(hMemDC, hBmp);
          mResult := BitBlt(hMemDC, 0, 0, sWidth, sHeight, hScrDC, 0, 0, SRCCOPY);
          if not mResult then
          begin
            err := GetLastError;
            xLog('BitBlt Error: ' + IntToStr(err) + ' ' + SysErrorMessage(err));
            Continue;
          end;

          BitmapSize := sHeight * sWidth * 4;

          CurOffset := 0;
          CopyMemory(pMap, @BitmapSize, sizeof(BitmapSize));
          CurOffset := sizeof(BitmapSize);
          CopyMemory(PByte(pMap) + CurOffset, @mResult, sizeof(mResult));
          CurOffset := CurOffset + sizeof(mResult);
          CopyMemory(PByte(pMap) + CurOffset, @sWidth, sizeof(sWidth));
          CurOffset := CurOffset + sizeof(sWidth);
          CopyMemory(PByte(pMap) + CurOffset, @sHeight, sizeof(sHeight));
          CurOffset := CurOffset + sizeof(sHeight);
          CopyMemory(PByte(pMap) + CurOffset, @bitmap_info.bmiHeader.biBitCount, sizeof(Word));
          CurOffset := CurOffset + sizeof(Word);
          CopyMemory(PByte(pMap) + CurOffset, @CurrentPID, sizeof(CurrentPID));
          CurOffset := CurOffset + sizeof(CurrentPID);
          CopyMemory(PByte(pMap) + CurOffset, @pBits, sizeof(pBits));
          CurOffset := CurOffset + sizeof(pBits);
//          CopyMemory(PByte(pMap) + CurOffset, pBits, BitmapSize);
          //GetDIBits(hMemDC, hBmp, 0, sHeight, PByte(pMap) + HeaderSize, bitmap_info, DIB_RGB_COLORS);
        except
          on E: Exception do
            xLog('ScreenShotThreadProc Error: ' + E.Message);
        end;
      finally
//        if pMap <> nil then
//          UnmapViewOfFile(pMap);
//        if hMap <> 0 then
//          CloseHandle(hMap);

    //     ResetEvent(EventReadEnd);
        SetEvent(EventWriteEnd);

        WaitForSingleObject(EventReadEnd, 10000);
    //     ResetEvent(EventReadEnd);

        SelectObject(hMemDC, hOld);
        DestroyBitmapData;
      end;
    end;
  finally
    ExitThread(0);
  end;
end;

{function ScreenShotThreadProc(pParam: Pointer): DWORD; stdcall;
var
  h: THandle;
  hScrDC, hMemDC: HDC;
  hBmp: HBitmap;
  bitmap_info: BITMAPINFO;
  sWidth, sHeight: Integer;
begin
  try
    while True do
    begin
  //    WaitForSingleObject(EventReadEnd, INFINITE);
  //    ResetEvent(EventReadEnd);

      WaitForSingleObject(EventReadBegin, INFINITE);
      ResetEvent(EventReadBegin);

      SelectInputWinStation;
      SwitchToActiveDesktop;

//      mSleep(1);

      h := GetDesktopWindow;
      sWidth := GetSystemMetrics(SM_CXSCREEN);
      sHeight := GetSystemMetrics(SM_CYSCREEN);

      hScrDC := GetDC(h);
      hMemDC := CreateCompatibleDC(hScrDC);
      hBmp := CreateCompatibleBitmap(hScrDC, sWidth, sHeight);
      SelectObject(hMemDC, hBmp);
      BitBlt(hMemDC, 0, 0, sWidth, sHeight, hScrDC, 0, 0, SRCCOPY);

{      with bitmap_info.bmiHeader do
      begin
        biSize := 40;
        biWidth := sWidth;
        //Use negative height to scan top-down.
        biHeight := -sHeight;
        biPlanes := 1;
        biBitCount := GetDeviceCaps(hScrDC, BITSPIXEL);
        biCompression := BI_RGB;
      end;

      BmpStream.Size := sHeight * sWidth * 4;
      GetDIBits(hMemDC, hBmp, 0, sHeight, @BmpStream, bitmap_info, DIB_RGB_COLORS);}

{      ScreenBitmap.Width := GetSystemMetrics(SM_CXSCREEN);
      ScreenBitmap.Height := GetSystemMetrics(SM_CYSCREEN);
      BitBlt(ScreenBitmap.Canvas.Handle, 0, 0, sWidth, sHeight, hMemDC, 0, 0, SRCCOPY);

      DeleteObject(hBmp);
      DeleteObject(hMemDC);
      ReleaseDC(h, hScrDC);

  //    ResetEvent(EventReadEnd);
      SetEvent(EventWriteEnd);

  //    WaitForSingleObject(EventReadEnd, INFINITE);
  //    ResetEvent(EventReadEnd);
    end;
  finally
    ExitThread(0);
  end;
end;}

function InputThreadProc(pParam: Pointer): DWORD; stdcall;
var
  inputs: array[0..0] of TInput;
begin
  try
    while True do
    begin
  //    WaitForSingleObject(EventReadEnd, INFINITE);
  //    ResetEvent(EventReadEnd);

      WaitForSingleObject(EventReadBeginIN, INFINITE);
      ResetEvent(EventReadBeginIN);

      SelectInputWinStation;
      SwitchToActiveDesktop;

      if IOtype = INPUT_MOUSE then
      begin
        if GetSystemMetrics(SM_CXSCREEN) > 0 then
        begin
          dx := Round(dx / (GetSystemMetrics(SM_CXSCREEN) - 1) * 65535);
          dy := Round(dy / (GetSystemMetrics(SM_CYSCREEN) - 1) * 65535);

          ZeroMemory(@inputs, SizeOf(TInput));
          inputs[0].Itype := IOtype;
          inputs[0].mi.dwFlags := dwFlags;
          inputs[0].mi.dx := dx;
          inputs[0].mi.dy := dy;
          inputs[0].mi.mouseData := mouseData;
          inputs[0].mi.dwExtraInfo := VCS_MAGIC_NUMBER;
          SendInput(1, inputs[0], SizeOf(inputs));
        end
        else
          SetCursorPos(dx, dy);
      end
      else
      begin
        ZeroMemory(@inputs, SizeOf(TInput));
        inputs[0].Itype := IOtype;
        inputs[0].ki.dwFlags := dwFlags;
        inputs[0].ki.wVk := wVk;
        inputs[0].ki.wScan := wScan;
        inputs[0].ki.dwExtraInfo := VCS_MAGIC_NUMBER;
        SendInput(1, inputs[0], SizeOf(inputs));
      end;

  //    ResetEvent(EventReadEnd);
      SetEvent(EventWriteEndIN);

  //    WaitForSingleObject(EventReadEnd, INFINITE);
  //    ResetEvent(EventReadEnd);
    end;
  finally
    ExitThread(0);
  end;
end;

function CADThreadProc(pParam: Pointer): DWORD; stdcall;
var
  res: Boolean;
  err: Integer;
begin
  try
    res := SASLibEx.SASLibEx_InitLib;
    err := GetLastError();
    if (not res)
      and (err <> 0) then
      xLog(Format('The SAS Library could not be initialized: %s', [SysErrorMessage(err)]))
    else
      CheckSAS(SASLibEx_SendSAS(DWORD(CurrentSessionID)), 'SASLibEx_SendSAS');
  finally
    ExitThread(0);
  end;
end;

procedure THelper.OnExecuteRequest(const Context: ICommContext; const Request, Response: IMessageData);
var
  tid: Cardinal;
begin
{  if Request.Data.ReadInteger('QueryType') = QT_GETSCREEN then
  begin
    ScreenBitmap := TBitmap.Create;
    BmpStream := TMemoryStream.Create;

    SetEvent(EventReadBegin);
    WaitForSingleObject(EventWriteEnd, INFINITE);
    ResetEvent(EventWriteEnd);

    ScreenBitmap.SaveToStream(BmpStream);
    BmpStream.Position := 0;
    Response.Data.WriteStream('Screen', BmpStream);

    BmpStream.Free;
    ScreenBitmap.Free;
  end
  else}
  if Request.Data.ReadInteger('QueryType') = QT_SENDINPUT then
  begin
    IOtype := Request.Data.ReadInteger('IOType');
    dwFlags := Request.Data.ReadInteger('dwFlags');
    dx := Request.Data.ReadInteger('dx');
    dy := Request.Data.ReadInteger('dy');
    mouseData := Request.Data.ReadInteger('mouseData');
    wVk := Request.Data.ReadInteger('wVk');
    wScan := Request.Data.ReadInteger('wScan');

    SetEvent(EventReadBeginIN);
    WaitForSingleObject(EventWriteEndIN, INFINITE);
    ResetEvent(EventWriteEndIN);
  end
  else
  if Request.Data.ReadInteger('QueryType') = QT_SENDCAD then
  begin
    CreateThread(nil, 0, @CADThreadProc, nil, 0, tid);
  end;

//  t := GetTickCount;
//  hThread2 := CreateThread(nil, 0, @ScreenShotThreadProc, nil, 0, tid2);
//  WaitForSingleObject(hThread2, INFINITE);
//  CloseHandle(hThread2);
//  t := GetTickCount - t;

//  t2 := GetTickCount;
//  MemStream.Clear;
//  SaveBitMap.SaveToStream(MemStream);
//  Response.Data.WriteStream('Bitmap', MemStream);
//  MemStream.Clear;
//  t2 := GetTickCount - t2;
//  t2 := t2;

//  SaveBitMap.SaveToFile(Format('C:\Screenshots\%s_OnExecute.bmp', ['Screenshot_' + FormatDateTime('mm-dd-yyyy-hhnnss', Now())]));
//xLog('SaveBitMap.SaveToFile');
end;

{function IPCServerThreadProc(pParam: Pointer): DWORD; stdcall;
var
  FHelper: THelper;
  FIPCServer: TIPCServer;
  msg: TMsg;
begin
  FHelper := THelper.Create;
  FIPCServer := TIPCServer.Create;
  FIPCServer.OnExecuteRequest := FHelper.OnExecuteRequest;
  FIPCServer.ServerName := 'Vircess_IPC_Session_' + IntToStr(CurrentSessionID);
  FIPCServer.Start;

  while GetMessage(msg, 0, 0, 0) do
    DispatchMessage(msg);

  FIPCServer.Stop;
  FIPCServer.Free;
  FHelper.Free;

  ExitThread(0);
end;}

function UniqueApp(const Title: AnsiString): Boolean;
var
  hMutex: THandle;
begin
   hMutex := 0 ;
   hMutex := CreateMutex(nil, False, PWideChar(WideString(Title)));
   Result := (GetLastError <> ERROR_ALREADY_EXISTS);
end;


begin
  hBmp := 0;
  hMemDC := 0;

  CurrentPID := GetCurrentProcessId;

//  CS := TCriticalSection.Create;
  if LowerCase(ExtractFileName(ParamStr(0))) = 'vcs_w32.exe' then
    NameSuffix := ''
  else
    NameSuffix := '_C';

  ProcessIdToSessionId(GetCurrentProcessId, CurrentSessionID);

  if not UniqueApp('Vircess_Helper_Session_' + IntToStr(CurrentSessionID) + NameSuffix) then
    Exit;

  AdjustPriviliges(SE_CREATE_GLOBAL_NAME);

  RTC_LOG_FOLDER := ExtractFilePath(ParamStr(0)) + '\Log\';
  StartLog;

  xLog('Started in session ' + IntToStr(CurrentSessionID));

  HeaderSize := sizeof(Cardinal) + sizeof(Boolean) + sizeof(sWidth) + sizeof(sHeight) + sizeof(Word) + sizeof(CurrentPID);
  hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, HeaderSize,
    PWideChar(WideString('Session\' + IntToStr(CurrentSessionID) + '\VCS_SCREEN' + NameSuffix)));

  if hMap = 0 then
  begin
    xLog('CreateFileMapping Error: ' + IntToStr(err) + ' ' + SysErrorMessage(err));
    Exit;
  end;

  pMap := MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, HeaderSize);
  err := GetLastError;
  if pMap = nil then
  begin
    xLog('MapViewOfFile Error: ' + IntToStr(err) + ' ' + SysErrorMessage(err));
    Exit;
  end;

//  LastBitMap := TBitMap.Create;

//  hMap := OpenFileMapping(FILE_MAP_WRITE, False, PWideChar(WideString('Global\VCS_SCREEN_SESSION_' + IntToStr(CurrentSessionID))));
//  if hMap > 0 then
//    UnmapViewOfFile(pMap); //Disposes the mem map
//  if hMap > 0 then
//    CloseHandle(hMap);

// hMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, BitmapInfoSize, PWideChar(WideString('VCS_SCREEN_SESSION_' + IntToStr(CurrentSessionID))));
//  pMap := MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);

//  RpcImpersonateClient(nil);

//  EventReadBegin := DoCreateEvent('Global\VCS_SCREEN_READ_BEGIN_SESSION_' + IntToStr(CurrentSessionID) + NameSuffix);
  EventWriteBegin := DoCreateEvent('Global\VCS_SCREEN_WRITE_BEGIN_SESSION_' + IntToStr(CurrentSessionID) + NameSuffix);
  EventWriteEnd := DoCreateEvent('Global\VCS_SCREEN_WRITE_END_SESSION_' + IntToStr(CurrentSessionID) + NameSuffix);
  EventReadEnd := DoCreateEvent('Global\VCS_SCREEN_READ_END_SESSION_' + IntToStr(CurrentSessionID) + NameSuffix);

  EventReadBeginIN := DoCreateEvent('Global\VCS_SCREEN_READ_BEGIN_IN_SESSION_' + IntToStr(CurrentSessionID) + NameSuffix);
  EventWriteEndIN := DoCreateEvent('Global\VCS_SCREEN_WRITE_END_IN_SESSION_' + IntToStr(CurrentSessionID) + NameSuffix);

//  hThreadIPC := CreateThread(nil, 0, @IPCServerThreadProc, nil, 0, tidIPC);
  hThreadSS := CreateThread(nil, 0, @ScreenShotThreadProc, nil, 0, tidSS);
  hThreadIN := CreateThread(nil, 0, @InputThreadProc, nil, 0, tidIN);
//  WaitForSingleObject(hThreadIPC, INFINITE);
//  CloseHandle(hThread);

  try
//    while True do
    begin
//      hThread := CreateThread(nil, 0, @CheckChangeDesktopThreadProc, nil, 0, tid);
//      WaitForSingleObject(hThread, INFINITE);
//      CloseHandle(hThread);

//  SelectInputWinStation;
//  xLog('Current desktop: ' + SwitchToActiveDesktop);

      FHelper := THelper.Create;
      FIPCServer := TIPCServer.Create;
      FIPCServer.OnExecuteRequest := FHelper.OnExecuteRequest;
      FIPCServer.ServerName := 'Vircess_IPC_Session_' + IntToStr(CurrentSessionID);
      FIPCServer.Start;

      while GetMessage(msg, 0, 0, 0) do
        if msg.message <> WM_QUIT then
        DispatchMessage(msg);

      FIPCServer.Stop;
      FIPCServer.Free;
      FHelper.Free;

//      if LowerCase(CurrentDesktopName) <> 'default' then
//      begin
//        ScreenShot(SaveBitMap, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), GetDesktopWindow); //47ms

//        if not BitmapsAreEqual(LastBitMap, SaveBitMap) then //16ms
//        begin
//          SaveBitmapToMMF; //16ms
//          LastBitMap := SaveBitMap;
//        end;
//      end;
//      mSleep(1);
//      Sleep(1);

      {LogonDesktopName := GetUserObjectName(OpenInputDesktop(DF_ALLOWOTHERACCOUNTHOOK, False, READ_CONTROL or WRITE_DAC or DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS));
      if CurrentDesktopName <> LogonDesktopName then
      begin
        SelectInputWinStation;
        CurrentDesktopName := SwitchToActiveDesktop;
        xLog('Desktop swithed to ' + CurrentDesktopName);
      end;}

//  SelectInputWinStation;
//  if (SwitchToActiveDesktop <> 'Default') then
//  ScreenShot(SaveBitMap, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), GetDesktopWindow);

//  if CurrentSessionID = WTSGetActiveConsoleSessionId then
//    c := 'Console';
//  SaveBitMap.SaveToFile(Format('C:\Screenshots\%s_Main_' + c + '_' + IntToStr(CurrentSessionID) + '.bmp', ['Screenshot_' + FormatDateTime('mm-dd-yyyy-hhnnss', Now())]));
//
//  Sleep(100);
//
//  ScreenShot(SaveBitMap, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), GetDesktopWindow);
//  SaveBitMap.SaveToFile(Format('C:\Screenshots\%s_Main_' + c + '_' + IntToStr(CurrentSessionID) + '.bmp', ['Screenshot_' + FormatDateTime('mm-dd-yyyy-hhnnss', Now())]));

//      ScreenShot(SaveBitMap, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), GetDesktopWindow);
  //
  //    SaveBitMap.SaveToFile('C:\Screenshots\VH_' + StringReplace(DateTimeToStr(Now), ':', '_', [rfReplaceAll]) + '.bmp');
  //    SendScreenToVircess;

  //    RpcRevertToSelf;

//      ZeroMemory(@wndclass, SizeOf(TWndClassEx));
//      wndclass.cbSize := SizeOf(TWndClassEx);
//      wndclass.hInstance := hInstance;
//      wndclass.lpszClassName := WND_CLASS_NAME;
//      wndclass.lpfnWndProc := @WndProc;
//      if RegisterClassEx(wndclass) = 0 then
//        Continue;
//      wnd := CreateWindowEx(0, WND_CLASS_NAME, nil, 0, 0, 0, 0, 0, HWND(HWND_MESSAGE), 0, hInstance, nil);
//      if wnd = 0 then
//        Continue;
//      while GetMessage(msg, 0, 0, 0) do
//        DispatchMessage(msg);
//      CloseHandle(wnd);
//      DestroyWindow(wnd);
    end;
  finally
//    UnmapViewOfFile(pMap); //Disposes the mem map
//    CloseHandle(hMap);

{    if EventReadBegin > 0 then
    begin
      CloseHandle(EventReadBegin);
      EventReadBegin := 0;
    end;}
    if EventWriteBegin <> 0 then
    begin
      CloseHandle(EventWriteBegin);
      EventWriteBegin := 0;
    end;
    if EventWriteEnd <> 0 then
    begin
      CloseHandle(EventWriteEnd);
      EventWriteEnd := 0;
    end;
    if EventReadEnd <> 0 then
    begin
      CloseHandle(EventReadEnd);
      EventReadEnd := 0;
    end;
    if EventReadBeginIN > 0 then
    begin
      CloseHandle(EventReadBeginIN);
      EventReadBeginIN := 0;
    end;
    if EventWriteEndIN <> 0 then
    begin
      CloseHandle(EventWriteEndIN);
      EventWriteEndIN := 0;
    end;

    if pMap <> nil then
      UnmapViewOfFile(pMap);
    if hMap <> 0 then
      CloseHandle(hMap);

    StopLog;

//    Cs.Free;
  end;

//  StartLog;

//  while True do
//  begin
//    hThrd := CreateThread(nil, 0, @ThreadProc, nil, 0, ThreadId);
//    if hThrd = 0 then
//      xLog('Failed to create thread')
//    else
//    begin
//      WaitForSingleObject(hThrd, INFINITE);
//      CloseHandle(hThrd);
//    end;
//
//    Sleep(1000);
//  end;

//  StopLog;

end.


