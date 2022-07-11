unit RunElevatedSupport;

{$WARN SYMBOL_PLATFORM OFF}
{$R+}

interface

uses
  Windows;

type
  TElevatedProc       = reference to function(const AHost, AParameters: String; AWait: Boolean): Cardinal;
  TProcessMessagesMeth = procedure of object;

  TEleavateSupport = class
  private
    FProc : TElevatedProc;
    procedure CheckForElevatedTask;
  public
    constructor Create(Proc: TElevatedProc); overload;

    function  IsAdministrator: Boolean;
    function  IsAdministratorAccount: Boolean;
    function  IsUACEnabled: Boolean;
    function  IsElevated: Boolean;

    // Add 'Shield' icon to regular button
    procedure SetButtonElevated(const AButtonHandle: THandle);

    // Runs FProc function under full administrator rights
    // Warning: this function will be executed in external process.
    // Do not use any global variables inside this routine!
    // Use only supplied AParameters.
    function RunElevated(const AHost: String;
                         const AParameters: String;
                         const AWnd: HWND = 0;
                         const AWait: Boolean = True;
                         const AProcessMessages: TProcessMessagesMeth = nil): cardinal;
    function DoElevatedTask(const AHost, AParameters: String; AWait: Boolean): Cardinal;
    function ExecAndWait(const FileName,
                   Params: ShortString;
                   const WinState: Word): boolean;
  end;


//  ---------------------- Usage -------------------------
//
//  On App start:
//
//  EleavateSupport:=TEleavateSupport.Create(function (Params: string): cardinal
//                                           begin
//                                             Result := ERROR_GENERIC_NOT_MAPPED;
//                                             if Params=MyMode then begin
//                                               try
//                                                 [DoWork]
//                                                 Result := ERROR_SUCCESS;
//                                               except
//                                                 Result := ERROR_GEN_FAILURE;
//                                               end;
//                                             end;
//                                           end);
//
//  if [NeedElevation] then begin
//    EleavateSupport.RunElevated(MyMode);
//  end;


//  function RunedAsAdmin: Boolean;

var
//  EleavateSupport: TEleavateSupport;
  Host: String;
  Wait: Boolean;

implementation

uses
  SysUtils, Registry, ShellAPI, ComObj;

const
  RunElevatedTaskSwitch = '0CC5C50CB7D643B68CB900BF000FFFD5'; // some unique value

function CheckTokenMembership(TokenHandle: THANDLE; SidToCheck: Pointer; var IsMember: BOOL): BOOL; stdcall; external advapi32 name 'CheckTokenMembership';

function TEleavateSupport.RunElevated(const AHost: String;
                                      const AParameters: String;
                                      const AWnd: HWND = 0;
                                      const AWait: Boolean = True;
                                      const AProcessMessages: TProcessMessagesMeth = nil): cardinal;
var
  SEI: TShellExecuteInfo;
  Args: String;
begin
  CheckForElevatedTask;

  Host := AHost; //ParamStr(0);
  Wait := AWait;

  if IsElevated then
  begin
    if Assigned(FProc) then
    begin
      Result := FProc(Host, AParameters, AWait)
    end
    else
    begin
      DoElevatedTask(AHost, AParameters, AWait);
      Result := 0; //ERROR_PROC_NOT_FOUND;
    end;
    Exit;
  end;

  Args := Format('/%s %s', [RunElevatedTaskSwitch, AParameters]);

  FillChar(SEI, SizeOf(SEI), 0);
  SEI.cbSize := SizeOf(SEI);
  SEI.fMask := SEE_MASK_NOCLOSEPROCESS;
  {$IFDEF UNICODE}
  SEI.fMask := SEI.fMask or SEE_MASK_UNICODE;
  {$ENDIF}
  SEI.Wnd := AWnd;
  SEI.lpVerb := 'runas';
  SEI.lpFile := PChar(Host);
  SEI.lpParameters := PChar(Args);
  SEI.lpDirectory := PChar(ExtractFilePath(Host));
  SEI.nShow := SW_HIDE;

  if not ShellExecuteEx(@SEI) then
    Exit(GetLastError);

  if not Wait then
  begin
    Result := 0;
    Exit;
  end;

  try
    Result := ERROR_GEN_FAILURE;
    if Assigned(AProcessMessages) then begin
      repeat
        if not GetExitCodeProcess(SEI.hProcess, Result) then Result := ERROR_GEN_FAILURE;
        AProcessMessages;
      until Result <> STILL_ACTIVE;
    end else begin
      if WaitForSingleObject(SEI.hProcess, INFINITE) <> WAIT_OBJECT_0 then begin
        Result := ERROR_GEN_FAILURE;
      end else begin
        if not GetExitCodeProcess(SEI.hProcess, Result) then
          Result := ERROR_GEN_FAILURE;
      end;
    end;

  finally
    CloseHandle(SEI.hProcess);
  end;
end;

function TEleavateSupport.DoElevatedTask(const AHost, AParameters: String; AWait: Boolean): Cardinal;

//  procedure InstallUpdate;
//  var
//    Msg: String;
//  begin
//    Msg := 'Hello from InstallUpdate!' + sLineBreak +
//           sLineBreak +
//           'This function is running elevated under full administrator rights.' + sLineBreak +
//           'This means that you have write-access to Program Files folder and you''re able to overwrite files (e.g. install updates).' + sLineBreak +
//           'However, note that your executable is still running.' + sLineBreak +
//           sLineBreak +
//           'IsAdministrator: '        + BoolToStr(EleavateSupport.IsAdministrator, True) + sLineBreak +
//           'IsAdministratorAccount: ' + BoolToStr(EleavateSupport.IsAdministratorAccount, True) + sLineBreak +
//           'IsUACEnabled: '           + BoolToStr(EleavateSupport.IsUACEnabled, True) + sLineBreak +
//           'IsElevated: '             + BoolToStr(EleavateSupport.IsElevated, True);
//    MessageBox(0, PChar(Msg), 'Hello from InstallUpdate!', MB_OK or MB_ICONINFORMATION);
//  end;

var
  sHost, sParams: String;
begin
  if AWait then
    ExecAndWait(AHost, AParameters, SW_HIDE)
  else
  begin
    sHost := Host;
    sParams := AParameters;
    UniqueString(sHost);
    UniqueString(sParams);
    ShellExecute(0, 'open', PChar(sHost), PChar(sParams), nil, SW_HIDE);
  end;

  Result := ERROR_SUCCESS;
//  if AParameters = '/INSTALL' then
//    InstallUpdate
//  else
//    Result := ERROR_GEN_FAILURE;
end;

function TEleavateSupport.ExecAndWait(const FileName,
                     Params: ShortString;
                     const WinState: Word): boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CmdLine: ShortString;
begin
  // Помещаем имя файла между кавычками, с соблюдением всех пробелов в именах Win9x
  CmdLine := '"' + Filename + '" ' + Params;
  FillChar(StartInfo, SizeOf(StartInfo), #0);
  with StartInfo do
  begin
    cb := SizeOf(StartInfo);
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := WinState;
  end;
  Result := CreateProcess(nil, PChar( String( CmdLine ) ), nil, nil, false,
                          CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil,
                          PChar(ExtractFilePath(Filename)),StartInfo,ProcInfo);
  // Ожидаем завершения приложения
  if Result then
  begin
    WaitForSingleObject(ProcInfo.hProcess, INFINITE);
    // Free the Handles
    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  end;
end;

constructor TEleavateSupport.Create(Proc: TElevatedProc);
begin
  FProc:=Proc;
  CheckForElevatedTask;
end;

function TEleavateSupport.IsAdministrator: Boolean;
var
  psidAdmin: Pointer;
  B: BOOL;
const
  SECURITY_NT_AUTHORITY: TSidIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID  = $00000020;
  DOMAIN_ALIAS_RID_ADMINS      = $00000220;
  SE_GROUP_USE_FOR_DENY_ONLY  = $00000010;
begin
  psidAdmin := nil;
  try
    // Создаём SID группы админов для проверки
    Win32Check(AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
      SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
      psidAdmin));

    // Проверяем, входим ли мы в группу админов (с учётов всех проверок на disabled SID)
    if CheckTokenMembership(0, psidAdmin, B) then
      Result := B
    else
      Result := False;
  finally
    if psidAdmin <> nil then
      FreeSid(psidAdmin);
  end;
end;

{$R-}

function TEleavateSupport.IsAdministratorAccount: Boolean;
var
  psidAdmin: Pointer;
  Token: THandle;
  Count: DWORD;
  TokenInfo: PTokenGroups;
  HaveToken: Boolean;
  I: Integer;
const
  SECURITY_NT_AUTHORITY: TSidIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID  = $00000020;
  DOMAIN_ALIAS_RID_ADMINS      = $00000220;
  SE_GROUP_USE_FOR_DENY_ONLY  = $00000010;
begin
  Result := Win32Platform <> VER_PLATFORM_WIN32_NT;
  if Result then
    Exit;

  psidAdmin := nil;
  TokenInfo := nil;
  HaveToken := False;
  try
    Token := 0;
    HaveToken := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, Token);
    if (not HaveToken) and (GetLastError = ERROR_NO_TOKEN) then
      HaveToken := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token);
    if HaveToken then
    begin
      Win32Check(AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
        SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
        psidAdmin));
      if GetTokenInformation(Token, TokenGroups, nil, 0, Count) or
         (GetLastError <> ERROR_INSUFFICIENT_BUFFER) then
        RaiseLastOSError;
      TokenInfo := PTokenGroups(AllocMem(Count));
      Win32Check(GetTokenInformation(Token, TokenGroups, TokenInfo, Count, Count));
      for I := 0 to TokenInfo^.GroupCount - 1 do
      begin
        Result := EqualSid(psidAdmin, TokenInfo^.Groups[I].Sid);
        if Result then
          Break;
      end;
    end;
  finally
    if TokenInfo <> nil then
      FreeMem(TokenInfo);
    if HaveToken then
      CloseHandle(Token);
    if psidAdmin <> nil then
      FreeSid(psidAdmin);
  end;
end;

{$R+}

function TEleavateSupport.IsUACEnabled: Boolean;
var
  Reg: TRegistry;
begin
  Result := CheckWin32Version(6, 0);
  if Result then
  begin
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Policies\System', False) then
        if Reg.ValueExists('EnableLUA') then
          Result := (Reg.ReadInteger('EnableLUA') <> 0)
        else
          Result := False
      else
        Result := False;
    finally
      FreeAndNil(Reg);
    end;
  end;
end;

function TEleavateSupport.IsElevated: Boolean;
const
  TokenElevation = TTokenInformationClass(20);
type
  TOKEN_ELEVATION = record
    TokenIsElevated: DWORD;
  end;
var
  TokenHandle: THandle;
  ResultLength: Cardinal;
  ATokenElevation: TOKEN_ELEVATION;
  HaveToken: Boolean;
begin
  if CheckWin32Version(6, 0) then
  begin
    TokenHandle := 0;
    HaveToken := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, TokenHandle);
    if (not HaveToken) and (GetLastError = ERROR_NO_TOKEN) then
      HaveToken := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, TokenHandle);
    if HaveToken then
    begin
      try
        ResultLength := 0;
        if GetTokenInformation(TokenHandle, TokenElevation, @ATokenElevation, SizeOf(ATokenElevation), ResultLength) then
          Result := ATokenElevation.TokenIsElevated <> 0
        else
          Result := False;
      finally
        CloseHandle(TokenHandle);
      end;
    end
    else
      Result := False;
  end
  else
    Result := IsAdministrator;
end;

procedure TEleavateSupport.SetButtonElevated(const AButtonHandle: THandle);
const
  BCM_SETSHIELD = $160C;
var
  Required: BOOL;
begin
  if not CheckWin32Version(6, 0) then
    Exit;
  if IsElevated then
    Exit;

  Required := True;
  SendMessage(AButtonHandle, BCM_SETSHIELD, 0, LPARAM(Required));
end;

procedure TEleavateSupport.CheckForElevatedTask;

  function GetArgsForElevatedTask: String;

    function PrepareParam(const ParamNo: Integer): String;
    begin
      Result := ParamStr(ParamNo);
      if Pos(' ', Result) > 0 then
        Result := AnsiQuotedStr(Result, '"');
    end;

  var
    X: Integer;
  begin
    Result := '';
    for X := 1 to ParamCount do begin
      if (AnsiUpperCase(ParamStr(X)) = ('/' + RunElevatedTaskSwitch)) or
         (AnsiUpperCase(ParamStr(X)) = ('-' + RunElevatedTaskSwitch)) then
        Continue;

      Result := Result + PrepareParam(X) + ' ';
    end;

    Result := Trim(Result);
  end;

var
  ExitCode: Cardinal;
begin
  if not FindCmdLineSwitch(RunElevatedTaskSwitch) then
    Exit;

  ExitCode := ERROR_GEN_FAILURE;
  try
    if not IsElevated then
      ExitCode := ERROR_ACCESS_DENIED
    else

    if Assigned(FProc) then begin
      ExitCode := FProc(Host, GetArgsForElevatedTask, Wait)
    end else begin
      ExitCode := ERROR_PROC_NOT_FOUND;
    end;
  except
    on E: Exception do
    begin
      if E is EAbort then
        ExitCode := ERROR_CANCELLED
      else
      if E is EOleSysError then
        ExitCode := Cardinal(EOleSysError(E).ErrorCode)
      else
      if E is EOSError then
      else
        ExitCode := ERROR_GEN_FAILURE;
    end;
  end;

  if ExitCode = STILL_ACTIVE then
    ExitCode := ERROR_GEN_FAILURE;

  TerminateProcess(GetCurrentProcess, ExitCode);
end;

{function RunedAsAdmin: Boolean;
const
  TokenElevationType        = 18;
  TokenElevation            = 20;
  TokenElevationTypeDefault = 01;
  TokenElevationTypeFull    = 02;
  TokenElevationTypeLimited = 03;
Var
  Token         : THandle;
  ElevationType : Integer;
  Elevation     : DWord;
  dwSize        : Cardinal;
begin
  Result := False;
  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token) then
  begin
    try
      if GetTokenInformation(Token, TTokenInformationClass(TokenElevationType), @ElevationType, SizeOf(ElevationType), dwSize) then
        case ElevationType of
          TokenElevationTypeDefault : Result := False;
          TokenElevationTypeFull    : Result := True;
          TokenElevationTypeLimited : Result := False;
        else
          Result := False;
        end;

      if GetTokenInformation(Token, TTokenInformationClass(TokenElevation), @Elevation, SizeOf(Elevation), dwSize) then
      begin
        if Elevation = 0 then Result := False
                         else Result := True;
      end;
    finally
      CloseHandle(Token);
    end;
  end;
end;}

{ TEleavateSupport }


end.
