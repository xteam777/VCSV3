{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcScrUtils;

interface

{$INCLUDE rtcPortalDefs.inc}
{$INCLUDE rtcDefs.inc}

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Clipbrd,
  Registry,
  DWMApi,

  rtcLog,
  rtcSystem,

  rtcInfo,
  ShellApi;

type
  _MARGINS = packed record
    cxLeftWidth: Integer;
    cxRightWidth: Integer;
    cyTopHeight: Integer;
    cyBottomHeight: Integer;
  end;
  PMargins = ^_MARGINS;
  TMargins = _MARGINS;

const
  SC_MONITOR_ON = -1;
  SC_MONITOR_OFF = 2;

  DESKTOP_ALL = DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
    DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or DESKTOP_WRITEOBJECTS or
    DESKTOP_READOBJECTS or DESKTOP_SWITCHDESKTOP or GENERIC_WRITE;

function Get_ComputerName: RtcString;
function Get_UserName: RtcString;

function Get_Clipboard: RtcString;
procedure Put_Clipboard(const s: RtcString);
procedure Empty_Clipboard;

function Get_ClipboardFiles: TRtcArray;

function Post_CtrlAltDel(fromLauncher: boolean = False): boolean; //Need aw_sas32.dll

procedure Show_Wallpaper;
procedure Hide_Wallpaper;

//procedure BlockKeyboardMouse;
//procedure UnBlockKeyboardMouse;
procedure PowerOffMonitor;
procedure PowerOnMonitor;
procedure PowerOffSystem;
procedure LockSystem;
procedure LogoffSystem;
procedure RestartSystem;

//procedure ToggleAero;
procedure DisableAero;
procedure RestoreAero;

//function Block_UserInput(fBlockInput: boolean): DWord;
function Get_CursorInfo(var pci: TCursorInfo): BOOL;

procedure Hide_Cursor;
procedure Show_Cursor;

implementation

//Выключение курсора
procedure Hide_Cursor;
var
  CState: Integer;
begin
  CState := ShowCursor(True);
  while Cstate >= 0 do
    Cstate := ShowCursor(False);
end;

//Включение курсора
procedure Show_Cursor;
var
  Cstate: Integer;
begin
  Cstate := ShowCursor(True);
  while CState < 0 do
    CState := ShowCursor(True);
end;


function Get_ComputerName: RtcString;
var
  buf: array [0 .. 256] of AnsiChar;
  len: DWord;
begin
  len := sizeof(buf);
  GetComputerName(@buf, len);
  Result := RtcString(PAnsiChar(@buf));
end;

function Get_UserName: RtcString;
var
  buf: array [0 .. 256] of AnsiChar;
  len: DWord;
begin
  len := sizeof(buf);
  GetUserName(@buf, len);
  Result := RtcString(PAnsiChar(@buf));
end;

function Get_Clipboard: RtcString;
var
  len, fmt: integer;
  tmp: RtcByteArray;

  Data: THandle;
  DataPtr: Pointer;
  DataLen: integer;

  pFormatName: String;

  MyClip: TRtcDataSet;
begin Exit;
  try
    MyClip := TRtcDataSet.Create;
    try
      Clipboard.Open;
    except
      xLog('Failed to open clipboard');
      Exit;
    end;
    try
      fmt := EnumClipboardFormats(0);
      while (fmt > 0) do
      begin
        Data := GetClipboardData(fmt);
        if Data <> 0 then
        begin
          DataPtr := GlobalLock(Data);
          if DataPtr <> nil then
            try
              DataLen := GlobalSize(Data);
              if DataLen > 0 then
              begin
                SetLength(pFormatName, 255);
                len := GetClipboardFormatName(fmt, @pFormatName[1], 255);
                SetLength(pFormatName, len);

                MyClip.Append;
                if pFormatName <> '' then
                  MyClip.asText['form'] := pFormatName
                else
                  MyClip.asInteger['fmt'] := fmt;

                SetLength(tmp, DataLen);
                Move(DataPtr^, tmp[0], DataLen);
                MyClip.asString['data'] := RtcBytesToString(tmp);
                SetLength(tmp, 0);
              end;
            finally
              GlobalUnlock(Data);
            end;
        end;
        fmt := EnumClipboardFormats(fmt);
      end;
    finally
      Clipboard.Close;
    end;
  finally
    Result := MyClip.toCode;
    MyClip.Free;
  end;
end;

function Get_ClipboardFiles: TRtcArray;
var
  len, fmt: integer;
  tmp: RtcByteArray;
  tmpw: WideString;

  Data: THandle;
  DataPtr: Pointer;
  DataLen: integer;

  pFormatName: String;

  MyClip: TRtcArray;
begin Exit;
  try
    MyClip := TRtcArray.Create;
    try
      Clipboard.Open;
    except
      xLog('Failed to open clipboard');
      Exit;
    end;
    try
      fmt := EnumClipboardFormats(0);
      while (fmt > 0) do
      begin
        SetLength(pFormatName, 255);
        len := GetClipboardFormatName(fmt, @pFormatName[1], 255);
        SetLength(pFormatName, len);
        if UpperCase(pFormatName) = 'FILENAMEW' then
        begin
          Data := GetClipboardData(fmt);
          if Data <> 0 then
          begin
            DataPtr := GlobalLock(Data);
            if DataPtr <> nil then
              try
                DataLen := GlobalSize(Data);
                if DataLen > 0 then
                begin
                  SetLength(tmpw, DataLen div 2);
                  Move(DataPtr^, tmpw[1], DataLen);
                  if copy(tmpw, length(tmpw), 1) = #0 then
                    SetLength(tmpw, length(tmpw) - 1);
                  MyClip.asText[MyClip.Count] := tmpw;
                  SetLength(tmpw, 0);
                end;
              finally
                GlobalUnlock(Data);
              end;
          end;
        end;
        fmt := EnumClipboardFormats(fmt);
      end;
    finally
      Clipboard.Close;
    end;

    if MyClip.Count = 0 then
    begin
      try
        Clipboard.Open;
      except
        xLog('Failed to open clipboard');
        Exit;
      end;
      try
        fmt := EnumClipboardFormats(0);
        while (fmt > 0) do
        begin
          SetLength(pFormatName, 255);
          len := GetClipboardFormatName(fmt, @pFormatName[1], 255);
          SetLength(pFormatName, len);
          if UpperCase(pFormatName) = 'FILENAME' then
          begin
            Data := GetClipboardData(fmt);
            if Data <> 0 then
            begin
              DataPtr := GlobalLock(Data);
              if DataPtr <> nil then
                try
                  DataLen := GlobalSize(Data);
                  if DataLen > 0 then
                  begin
                    SetLength(tmp, DataLen);
                    Move(DataPtr^, tmp[0], DataLen);
                    MyClip.asString[MyClip.Count] := RtcBytesZeroToString(tmp);
                    SetLength(tmp, 0);
                  end;
                finally
                  GlobalUnlock(Data);
                end;
            end;
          end;
          fmt := EnumClipboardFormats(fmt);
        end;
      finally
        Clipboard.Close;
      end;
    end;
  finally
    if MyClip.Count > 0 then
      Result := MyClip
    else
    begin
      Result := nil;
      MyClip.Free;
    end;
  end;
end;

procedure Put_Clipboard(const s: RtcString);
var
  fmt: integer;
  fname: String;
  tmp: RtcByteArray;

  Data: THandle;
  DataPtr: Pointer;
  DataLen: integer;

  MyClip: TRtcDataSet;

begin  Exit;
  tmp := nil;
  try
    Clipboard.Open;
  except
    xLog('Failed to open clipboard');
    Exit;
  end;
  try
    EmptyClipboard;

    if s <> '' then
    begin
      MyClip := TRtcDataSet.FromCode(s);
      try
        MyClip.First;
        while not MyClip.EOF do
        begin
          fname := MyClip.asText['form'];
          tmp := RtcStringToBytes(MyClip.asString['data']);

          if fname <> '' then
            fmt := RegisterClipboardFormat(PChar(fname))
          else
            fmt := MyClip.asInteger['fmt'];

          DataLen := length(tmp);
          Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, DataLen);
          try
            DataPtr := GlobalLock(Data);
            try
              Move(tmp[0], DataPtr^, DataLen);
              SetClipboardData(fmt, Data);
            finally
              GlobalUnlock(Data);
            end;
          except
            GlobalFree(Data);
            raise;
          end;
          MyClip.Next;
        end;
      finally
        MyClip.Free;
      end;
    end;
  finally
    Clipboard.Close;
  end;
end;

procedure Empty_Clipboard;
begin
  try
    Clipboard.Open;
  except
    xLog('Failed to open clipboard');
    Exit;
  end;
  try
    EmptyClipboard;
  finally
    Clipboard.Close;
  end;
end;

type
  TSendCtrlAltDel = function(asUser: Bool; iSession: integer) : Cardinal; stdcall;

function Call_CAD:boolean;
var
  nr     : integer;
  sendcad: TSendCtrlAltDel;
  lib    : Cardinal;
begin
  Result:=False;
  lib := LoadLibrary('aw_sas32.dll');
  if lib <> 0 then
  begin
    try
      @sendcad := GetProcAddress(lib, 'sendCtrlAltDel');
      if assigned(sendcad) then
      begin
        nr := sendcad(False, -1);
        if nr<>0 then
          XLog('SendCtrlAltDel execution failed, Error Code = ' + inttostr(nr))
        else
          begin
          XLog('SendCtrlAltDel executed OK using aw_sas32.dll');
          Result:=True;
          end;
      end
      else
        XLog('Loading sendCtrlAltDel from aw_sas32.dll failed');
    finally
      FreeLibrary(lib);
    end;
  end
  else
    XLog('Loading aw_sas32.dll failed, can not execute sendCtrlAltDel');
  end;

function Post_CtrlAltDel(fromLauncher: boolean = False): boolean;
var
  LogonDesktop, CurDesktop: HDESK;
  dummy: Cardinal;
  new_name: array [0 .. 256] of AnsiChar;
begin
  if (Win32MajorVersion >= 6) then //vista\server 2k8
    Result := Call_CAD
  else
    Result := false;

  if not Result then
  begin
    // dwSessionId := WTSGetActiveConsoleSessionId;
    //  myPID:= GetCurrentProcessId;
    //  winlogonSessId := 0;
    //  if (ProcessIdToSessionId(myPID, winlogonSessId) and (winlogonSessId = dwSessionId)) then

    XLog('Executing CtrlAltDel through WinLogon ...');
    Result := False;
    LogonDesktop := OpenDesktop('Winlogon', 0, False, DESKTOP_ALL);
    if (LogonDesktop <> 0) and
      (GetUserObjectInformation(LogonDesktop, UOI_NAME, @new_name, 256, dummy))
    then
      try
        CurDesktop := GetThreadDesktop(GetCurrentThreadID);
        if (CurDesktop = LogonDesktop) or SetThreadDesktop(LogonDesktop) then
          try
            PostMessage(HWND_BROADCAST, WM_HOTKEY, 0,
              MAKELONG(MOD_ALT or MOD_CONTROL, VK_DELETE));
            Result := True;
          finally
            if CurDesktop <> LogonDesktop then
              SetThreadDesktop(CurDesktop);
          end
        else
        begin
          PostMessage(HWND_BROADCAST, WM_HOTKEY, 0,
            MAKELONG(MOD_ALT or MOD_CONTROL, VK_DELETE));
        end;
      finally
        CloseDesktop(LogonDesktop);
      end
    else
    begin
      PostMessage(HWND_BROADCAST, WM_HOTKEY, 0,
        MAKELONG(MOD_ALT or MOD_CONTROL, VK_DELETE));
    end;
  end;
end;

function GetDesktopRect: TRect;
var
  DW: HWND;
begin
  DW := GetDesktopWindow;
  GetWindowRect(DW, Result);
end;

var
  WallpaperVisible: boolean = True;

//procedure BlockKeyboardMouse;
//begin
//  ShellExecute(nil, 'open', 'rundll32 keyboard,disable', '', '', SW_HIDE);
//  ShellExecute(nil, 'open', 'rundll32 mouse,disable', '', '', SW_HIDE);
//end;
//
//procedure UnBlockKeyboardMouse;
//begin
//  ShellExecute(nil, 'open', 'rundll32 keyboard,enable', '', '', SW_HIDE);
//  ShellExecute(nil, 'open', 'rundll32 mouse,enable', '', '', SW_HIDE);
//end;

procedure PowerOffMonitor;
begin
//  SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, SC_MONITOR_OFF);
end;

procedure PowerOnMonitor;
begin
//  SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, SC_MONITOR_ON);
end;

procedure PowerOffSystem;
begin
  try
    WinExec('cmd /c shutdown -s -t 0', SW_HIDE);
  except
  on E: Exception do
    XLog('Error PowerOnMonitor GetLastError = ' + IntToStr(GetLastError) + '. ' + E.ClassName + ' ошибка с сообщением : ' + E.Message);
  end;
end;

procedure LockSystem;
begin
  try
    WinExec('cmd /c rundll32 user32.dll, LockWorkStation', SW_HIDE);
  except
  on E: Exception do
    XLog('Error LockSystem GetLastError = ' + IntToStr(GetLastError) + '. ' + E.ClassName + ' ошибка с сообщением : ' + E.Message);
  end;
end;

procedure LogoffSystem;
begin
  try
    WinExec('cmd /c shutdown -l', SW_HIDE);
  except
  on E: Exception do
    XLog('Error LogoffSystem GetLastError = ' + IntToStr(GetLastError) + '. ' + E.ClassName + ' ошибка с сообщением : ' + E.Message);
  end;
end;

procedure RestartSystem;
begin
  try
    WinExec('cmd /c shutdown -r -t 0', SW_HIDE);
  except
  on E: Exception do
    XLog('Error RestartSystem GetLastError = ' + IntToStr(GetLastError) + '. ' + E.ClassName + ' ошибка с сообщением : ' + E.Message);
  end;
end;

function Show_Wallpaper_ThreadProc(pParam: Pointer): DWORD; stdcall;
var
  reg: TRegIniFile;
  pResult: String;
begin
  pResult := '';

  reg := TRegIniFile.Create('Control Panel\Desktop');
  pResult := Trim(reg.ReadString('', 'Wallpaper', ''));
  reg.Free;

  if pResult <> '' then
  begin
    WallpaperVisible := True;
    // Return the old value back to Registry.
    if pResult <> '' then
    begin
      reg := TRegIniFile.Create('Control Panel\Desktop');
      try
        reg.WriteString('', 'Wallpaper', pResult);
      finally
        reg.Free;
      end;
    end;

    //
    // let everyone know that we changed
    // a system parameter
    //
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(pResult),
      SPIF_SENDCHANGE); // SPIF_UPDATEINIFILE + SPIF_SENDWININICHANGE);
    PostMessage(GetDesktopWindow, WM_SETTINGCHANGE, 0,0);
  end;

  ExitThread(0);
end;

procedure Show_Wallpaper;
var
  hThread: THandle;
  tid: Cardinal;
begin
  hThread := CreateThread(nil, 0, @Show_Wallpaper_ThreadProc, nil, 0, tid);
end;

function Hide_Wallpaper_ThreadProc(pParam: Pointer): DWORD; stdcall;
var
  reg: TRegIniFile;
  aWall: array [0..MAX_PATH] of Char;
  pResult: String;
begin
  if WallpaperVisible then
  begin
    WallpaperVisible := False;
    //
    // change registry
    //
    // HKEY_CURRENT_USER
    // Control Panel\Desktop
    // TileWallpaper (REG_SZ)
    // Wallpaper (REG_SZ)
    //
    pResult := '';

    try
      SystemParametersInfo(SPI_GETDESKWALLPAPER, MAX_PATH, @aWall, 0);
      pResult := strPas(aWall);
    finally
//      FreeMem(aWall);
    end;

    //
    // let everyone know that we changed
    // a system parameter
    //
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PChar(''),
      SPIF_UPDATEINIFILE + SPIF_SENDWININICHANGE);

    // Return the old value back to Registry.
    if pResult <> '' then
    begin
      reg := TRegIniFile.Create('Control Panel\Desktop');
      try
        reg.WriteString('', 'Wallpaper', pResult);
      finally
        reg.Free;
      end;
    end;
  end;

  ExitThread(0);
end;

procedure Hide_Wallpaper;
var
  hThread: THandle;
  tid: Cardinal;
begin
  hThread := CreateThread(nil, 0, @Hide_Wallpaper_ThreadProc, nil, 0, tid);
end;

type
//  TBlockInputProc = function(fBlockInput: boolean): DWord; stdcall;
  TGetCursorInfo = function(var pci: TCursorInfo): BOOL; stdcall;

var
  User32Loaded: boolean = False; // User32 DLL loaded ?
  User32Handle: HInst; // User32 DLL handle

//  BlockInputProc: TBlockInputProc = nil;
  GetCursorInfoProc: TGetCursorInfo = nil;

function GetOSVersionInfo(var Info: TOSVersionInfo): boolean;
begin
  FillChar(Info, sizeof(TOSVersionInfo), 0);
  Info.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
  Result := GetVersionEx(Info);
  if (not Result) then
  begin
    FillChar(Info, sizeof(TOSVersionInfo), 0);
    Info.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
    Result := GetVersionEx(Info);
    if (not Result) then
      Info.dwOSVersionInfoSize := 0;
  end;
end;

procedure LoadUser32;
var
  osi: TOSVersionInfo;
begin
  if not User32Loaded then
  begin
    User32Handle := LoadLibrary(user32);
    if User32Handle = 0 then
      Exit; // if loading fails, exit.

    User32Loaded := True;

    if GetOSVersionInfo(osi) then
    begin
      if osi.dwMajorVersion >= 5 then
      begin
//        @BlockInputProc := GetProcAddress(User32Handle, 'BlockInput');
        @GetCursorInfoProc := GetProcAddress(User32Handle, 'GetCursorInfo');
      end;
    end;
  end;
end;

procedure UnLoadUser32;
begin
  if User32Loaded then
  begin
//    @BlockInputProc := nil;
    @GetCursorInfoProc := nil;
    FreeLibrary(User32Handle);
    User32Loaded := False;
  end;
end;

{unction Block_UserInput(fBlockInput: boolean): DWord;
begin
  if not User32Loaded then
    LoadUser32;
  if @BlockInputProc <> nil then
    Result := BlockInputProc(fBlockInput)
  else
    Result := 0;
end;}

function Get_CursorInfo(var pci: TCursorInfo): BOOL;
begin
  if not User32Loaded then
    LoadUser32;
  if @GetCursorInfoProc <> nil then
    Result := GetCursorInfoProc(pci)
  else
    Result := False;
end;

//type
//  TDwmEnableComposition = function(uCompositionAction: UINT): HRESULT; stdcall;
//  TDwmIsCompositionEnabled = function(var pfEnabled: BOOL): HRESULT; stdcall;
//
//const
//  DWM_EC_DISABLECOMPOSITION = 0;
//  DWM_EC_ENABLECOMPOSITION = 1;

var
//  DwmEnableComposition: TDwmEnableComposition = nil;
//  DwmIsCompositionEnabled: TDwmIsCompositionEnabled = nil;
  ChangedAero: Boolean = False;
  OriginalAero: LongBool = True;

//  DWMLibLoaded : boolean = False;
//  DWMlibrary: THandle;

{procedure LoadDwmLibs;
begin
  if not DWMLibLoaded then
  begin
    DWMlibrary := LoadLibrary('DWMAPI.dll');
    if DWMlibrary <> 0 then
    begin
      DWMLibLoaded := True;
      DwmEnableComposition := GetProcAddress(DWMlibrary, 'DwmEnableComposition');
      DwmIsCompositionEnabled := GetProcAddress(DWMlibrary, 'DwmIsCompositionEnabled');
    end;
  end;
end;

procedure UnloadDwmLibs;
begin
  if DWMLibLoaded then
  begin
    DWMLibLoaded := False;
    @DwmEnableComposition := nil;
    @DwmIsCompositionEnabled := nil;
    FreeLibrary(DWMLibrary);
  end;
end;

procedure ToggleAero;
var
  CurrentAero: LongBool;
  res: HRESULT;
begin
  LoadDWMLibs;
  if @DwmEnableComposition <> nil then
  begin
    if @DwmIsCompositionEnabled <> nil then
      DwmIsCompositionEnabled(CurrentAero);
    if not ChangedAero then
      OriginalAero := CurrentAero;
    ChangedAero := True;

    if not CurrentAero then
      res := DwmEnableComposition(DWM_EC_ENABLECOMPOSITION)
    else
      res := DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);
    if res <> 0 then
      xlog(Format('DwmEnableComposition failed with "%s"',
        [SysErrorMessage(res)]));
  end;
end;

procedure DisableAero;
var
  CurrentAero: LongBool;
  res: HRESULT;
begin
  LoadDWMLibs;
  if @DwmEnableComposition <> nil then
  begin
    if @DwmIsCompositionEnabled <> nil then
      DwmIsCompositionEnabled(CurrentAero);
    if not ChangedAero then
      OriginalAero := CurrentAero;
    ChangedAero := True;

    if CurrentAero then
      res := DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);
    if res <> 0 then
      xlog(Format('DwmEnableComposition failed with "%s"',
        [SysErrorMessage(res)]));
  end;
end;

procedure RestoreAero;
begin
  if not ChangedAero then
    Exit;
  LoadDWMLibs;
  if @DwmEnableComposition <> nil then
  begin
    if OriginalAero then
      DwmEnableComposition(DWM_EC_ENABLECOMPOSITION)
    else
      DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);
  end;
  ChangedAero := False;
end;}

procedure DisableAero;
var
  CurrentAero: LongBool;
  res: HRESULT;
begin
  DwmIsCompositionEnabled(CurrentAero);
  if not ChangedAero then
    OriginalAero := CurrentAero;
  ChangedAero := True;

  if CurrentAero then
    res := DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);
  if res <> 0 then
    xlog(Format('DwmEnableComposition failed with "%s"',
      [SysErrorMessage(res)]));
end;

procedure RestoreAero;
begin
  if not ChangedAero then
    Exit;

  if OriginalAero then
    DwmEnableComposition(DWM_EC_ENABLECOMPOSITION)
  else
    DwmEnableComposition(DWM_EC_DISABLECOMPOSITION);

  ChangedAero := False;
end;

initialization

finalization
  UnLoadUser32;
//  LoadDWMLibs;

end.
