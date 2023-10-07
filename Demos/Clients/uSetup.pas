unit uSetup;

interface

uses
  Windows,
  Classes,
  Forms,
  SysUtils,
  ShlObj,
  ComObj,
  ActiveX,
  Registry,
  rtcWinLogon,
  uVircessTypes,
  RunElevatedSupport,
  ShellApi,
  CommonData;

procedure CreateAutorunRegistryKey;
//procedure CopyRegistrySettingsFromCurrentUserToLocalMachine;
procedure CreateShortcuts;
procedure DeleteShortcuts;
procedure CreateUninstallRegistryKey;
procedure DeleteUninstallRegistryKey;
procedure DeleteSettingsRegistryKeys;
procedure DeleteAutorunRegistryKey;
procedure CreateProgramFolder;
procedure DeleteProgramFolder;
function GetSpecialFolderLocation(nFolder: Integer): String;
function CreateDesktopShellLink(const TargetName: String; nFolder: Integer): Boolean;
procedure DeleteShortcut(sFileName: String; nFolder: Integer);
//procedure ReadGroups(Strings: TStrings);

implementation

{procedure CopyRegistrySettingsFromCurrentUserToLocalMachine;
var
  reg: TRegistry;
  ProxyOption: Integer;
  PermanentPassword, ProxyAddr, ProxyUsername, ProxyPassword: String;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.Access := KEY_READ;
    if not reg.OpenKey('Software\Remox', False) then
      Exit;

    if reg.ValueExists('PermanentPassword') then
      PermanentPassword := reg.ReadString('PermanentPassword')
    else
      PermanentPassword := '';

    if reg.ValueExists('ProxyOption') then
      ProxyOption := reg.ReadInteger('ProxyOption')
    else
      ProxyOption := PO_AUTOMATIC;

    if reg.ValueExists('ProxyAddr') then
      ProxyAddr := reg.ReadString('ProxyAddr')
    else
      ProxyAddr := '';
    if reg.ValueExists('ProxyUsername') then
      ProxyUserName := reg.ReadString('ProxyUsername')
    else
      ProxyUserName := '';
    if reg.ValueExists('ProxyPassword') then
      ProxyPassword := reg.ReadString('ProxyPassword')
    else
      ProxyPassword := '';

    reg.CloseKey;
  finally
    reg.Free;
  end;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.Access := KEY_WRITE or KEY_WOW64_64KEY;
    if not reg.OpenKey('SOFTWARE\Remox', True) then
      Exit;

    reg.WriteString('PermanentPassword', PermanentPassword);
    reg.WriteInteger('ProxyOption', ProxyOption);
    reg.WriteString('ProxyAddr', ProxyAddr);
    reg.WriteString('ProxyUsername', ProxyUsername);
    reg.WriteString('ProxyPassword', ProxyPassword);

    reg.CloseKey;
  finally
    reg.Free;
  end;
end;}

function GetTempFile: String;
var
  lsTmpFile : array[0..MAX_PATH] of Char;
begin
  GetTempFileName('.', 'RMX', 1, @lsTmpFile);
  Result := lsTmpFile;
end;

procedure CreateProgramFolder;
var
  pfFolder, fn: String;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);

  if not DirectoryExists(pfFolder + '\Remox') then
    CreateDir(pfFolder + '\Remox');
  if ParamStr(0) <> pfFolder + '\Remox\Remox.exe' then
    CopyFile(PChar(ParamStr(0)), PChar(pfFolder + '\Remox\Remox.exe'), False);
end;

procedure DeleteProgramFolder;
var
  pfFolder, fn: String;
  EleavateSupport: TEleavateSupport;
//  err: LongInt;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);

  with TStringList.Create do
  try
    Add('PING 127.0.0.1 -n 2 > NUL');
    Add('RMDIR "' + pfFolder + '\Remox" /s /q');
//    Add('DEL "' + pfFolder + '"');
    fn := GetTempFile + '.bat';
    //fn := 'C:\TEMP\0.bat';
    Add('DEL "' + fn + '"');
    SaveToFile(fn, TEncoding.GetEncoding(866));
  finally
    Free;
  end;

  ShellExecute(Application.Handle, 'open', PWideChar(fn), '', '', SW_HIDE);

//  EleavateSupport := TEleavateSupport.Create(nil);
//  try
//    SetLastError(EleavateSupport.RunElevated(fn, '', Application.Handle, True, Application.ProcessMessages));
////    err := GetLastError;
////    if err <> ERROR_SUCCESS then
////      xLog('ServiceInstall error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
////      SetServiceMenuAttributes;
//  finally
//    EleavateSupport.Free;
//  end;

  Application.Terminate;

//  rtcStartProcess('cmd /c "' + fn + '"');
end;

procedure CreateShortcuts;
var
  pfFolder: String;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);
  CreateDesktopShellLink(pfFolder + '\Remox\Remox.exe', CSIDL_DESKTOP);
  CreateDesktopShellLink(pfFolder + '\Remox\Remox.exe', CSIDL_PROGRAMS);
end;

procedure DeleteShortcuts;
var
  sFileName: String;
begin
  sFileName := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86) + '\Remox\Remox.exe';

  DeleteShortcut(sFileName, CSIDL_DESKTOP);
  DeleteShortcut(sFileName, CSIDL_PROGRAMS);
end;

procedure CreateUninstallRegistryKey;
var
  pfFolder, UninstallProgramName: String;
  Registry: TRegistry;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);

  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.Access := KEY_WRITE or KEY_WOW64_64KEY;
    if not Registry.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remox', True) then
      Exit;
    Registry.WriteString('DisplayName', 'Remox');
    Registry.WriteString('DisplayIcon', pfFolder + '\Remox\Remox.exe');
    Registry.WriteString('Publisher', 'Remox');
    Registry.WriteString('Version', RMX_VERSION);
    Registry.WriteString('UninstallString', '"' + pfFolder + '\Remox\Remox.exe" /UNINSTALL');
  finally
    Registry.Free;
  end;
end;

procedure DeleteUninstallRegistryKey;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.Access := KEY_WRITE or KEY_WOW64_64KEY;
    if Registry.KeyExists('\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remox') then
      Registry.DeleteKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Remox');
  finally
    Registry.Free;
  end;
end;

procedure CreateAutorunRegistryKey;
var
  pfFolder, UninstallProgramName: String;
  Registry: TRegistry;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);

  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.Access := KEY_WRITE or KEY_WOW64_64KEY;
    if Registry.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', False) then
      Registry.WriteString('Remox', pfFolder + '\Remox\Remox.exe');
  finally
    Registry.Free;
  end;
end;

procedure DeleteAutorunRegistryKey;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.Access := KEY_WRITE or KEY_WOW64_64KEY;
    if Registry.OpenKey('\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', False) then
//      if Registry.ValueExists('Remox') then
        Registry.DeleteValue('Remox');
  finally
    Registry.Free;
  end;
end;

procedure DeleteSettingsRegistryKeys;
var
  Registry: TRegistry;
  i: Integer;
  SubKeyNames: TStringList;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_USERS;
    Registry.Access := KEY_ALL_ACCESS or KEY_WOW64_64KEY;
    if not Registry.OpenKey('\', False) then
      Exit;
    SubKeyNames := TStringList.Create;
    try
      Registry.GetKeyNames(SubKeyNames);
      for i := 0 to SubKeyNames.Count - 1 do
        if Registry.KeyExists('\' + SubKeyNames[i] + '\SOFTWARE\Remox') then
          Registry.DeleteKey('\' + SubKeyNames[i] + '\SOFTWARE\Remox');
    finally
      SubKeyNames.Free;
    end;
  finally
    Registry.Free;
  end;
end;

procedure DeleteShortcut(sFileName: String; nFolder: Integer);
//var
//  SearchRec: TSearchRec;
//  FindResult: Integer;
begin
  if FileExists(GetSpecialFolderLocation(nFolder) + '\Remox.lnk') then
    DeleteFile(GetSpecialFolderLocation(nFolder) + '\Remox.lnk');

//  FindResult := FindFirst(GetSpecialFolderLocation(nFolder) + '*.*', faAnyFile, SearchRec);
//  while FindResult = 0 do
//  begin
//    with SearchRec do
//      if (Name <> '.') and (Name <> '..') and (Attr and faAnyFile <> 0) then
//        DeleteFile(Name);
//
//      FindResult := FindNext(SearchRec);
//  end;
//  FindClose(SearchRec);
end;

//function GetDesktopFolder: String;
//var
//  PIDList: PItemIDList;
//  Buffer: array [0..MAX_PATH-1] of Char;
//begin
//  Result := '';
//  SHGetSpecialFolderLocation(Application.Handle, CSIDL_DESKTOP, PIDList);
//  if Assigned(PIDList) then
//    if SHGetPathFromIDList(PIDList, Buffer) then
//      Result := Buffer;
//end;

function GetSpecialFolderLocation(nFolder: Integer): String;
var
  PIDList: PItemIDList;
  Malloc: IMalloc;
  szPath: array[0..MAX_PATH - 1] of Char;
begin
  SHGetSpecialFolderLocation(Application.Handle, nFolder, PIDList);
  SHGetMalloc(Malloc);
  SHGetPathFromIDList(PIDList, szPath);
  Malloc.Free(PIDList);
  Malloc := nil;
  Result := String(szPath);
end;

function CreateDesktopShellLink(const TargetName: String; nFolder: Integer): Boolean;
var
  IObject: IUnknown;
  ISLink: IShellLink;
  IPFile: IPersistFile;
  PIDL: PItemIDList;
  LinkName: string;
  InFolder: array [0..MAX_PATH - 1] of Char;
begin
  Result := False;

  IObject := CreateComObject(CLSID_ShellLink);
  ISLink := IObject as IShellLink;
  IPFile := IObject as IPersistFile;

  with ISLink do
  begin
    SetDescription('Remox');
    SetPath(PChar(TargetName));
    SetWorkingDirectory(PChar(ExtractFilePath(TargetName)));
  end;

  SHGetSpecialFolderLocation(0, CSIDL_DESKTOPDIRECTORY, PIDL);
  SHGetPathFromIDList(PIDL, InFolder) ;

  LinkName := IncludeTrailingBackslash({GetDesktopFolder} GetSpecialFolderLocation(nFolder));
  LinkName := LinkName + ChangeFileExt(ExtractFileName(TargetName), '') + '.lnk';

  if not FileExists(LinkName) then
    if IPFile.Save(PWideChar(LinkName), False) = S_OK then
      Result := True;
end;

//procedure ReadGroups(Strings: TStrings);
//var
//  ARegistry: TRegistry;
//  Programs: String;
//  SearchRec: TSearchRec;
//  FindResult: Integer;
//begin
//  Strings.Clear;
//  // Находим каталог
//  ARegistry := TRegistry.Create;
//  with ARegistry do
//  begin
//    RootKey := HKEY_CURRENT_USER;
//    if OpenKey('Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', False) then
//    begin
//      Programs := ReadString('Programs');
//      CloseKey;
//    end
//    else
//      Programs := '';
//
//    Free;
//  end;
//
//  if (Length(Programs) > 0) and (Programs[Length(Programs)] <> '') then
//    Programs := Programs + '';
//  // Читаем содержимое каталога
//  FindResult := FindFirst(Programs + '*.*', faDirectory, SearchRec);
//  while FindResult = 0 do
//  begin
//    with SearchRec do
//      if (Name <> '.') and (Name <> '..') and (Attr and faDirectory <> 0) then
//        Strings.Add(Name);
//
//      FindResult := FindNext(SearchRec);
//  end;
//  FindClose(SearchRec);
//end;

end.
