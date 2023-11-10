{ Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)
  Copyright © 1999,2003 Michal Mutl (http://www.mitec.cz) }

unit rtcpFileUtils;

interface

{$INCLUDE rtcPortalDefs.inc}
{$INCLUDE rtcDefs.inc}

uses
  Winapi.Windows, System.SysUtils, System.Classes, Math, ShellAPI, rtcInfo, rtcSystem, Winapi.ShlObj, Winapi.ActiveX, Vcl.Forms, System.UITypes;

type
  TRtcPMediaType = (dtUnknown, dtNotExists, dtRemovable, dtFixed, dtRemote,
    dtCDROM, dtRAMDisk);

function FileSetDate(const FileName: String; Age: Integer): Integer;

function Folder_Size(const FolderName: String): int64;

function Folder_Content(const FolderName, SubFolderName: String;
  Folder: TRtcDataSet): int64;

function File_Content(const FileName: String; Folder: TRtcDataSet): int64;

procedure GetFilesList_Inner(const FolderName, FileMask: String; Folder: TRtcDataSet);

function FormatFileSize(const Number: int64): String;

Function DelFolderTree(DirName: String): Boolean;

function FileTimeToDateTime(FT: FILETIME): TDateTime;

procedure GetFilesList(const FolderName, FileMask: String; Folder: TRtcDataSet);
function HandleNetworkFile(const FileName: string): string;

implementation

const
  FILE_SUPPORTS_ENCRYPTION = 32;
  FILE_SUPPORTS_OBJECT_IDS = 64;
  FILE_SUPPORTS_REPARSE_POINTS = 128;
  FILE_SUPPORTS_SPARSE_FILES = 256;
  FILE_VOLUME_QUOTAS = 512;

  ID_MYCOMPUTER = '::{20D04FE0-3AEA-1069-A2D8-08002B30309D}';
  ID_NETWORK    = '::{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}';

type
  TDiskSign = String;

  TDiskInfo = record
    MediaType: TRtcPMediaType;
    SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters,
      Serial: DWORD;
    Capacity, FreeSpace: int64;
    VolumeLabel, SerialNumber, FileSystem: String;
  end;

//==============================================================================
//  Background request
//
type
  PProcParam = ^TProcParam;
  TProcParam = record
    event: THandle;
    Folder: TRtcDataSet;
    FolderName, FileMask: String
  end;

function GetFilesListBackThreadProc(p: PProcParam): Integer;
begin
  try
    GetFilesList(p.FolderName, p.FileMask, p.Folder);
    Result := 0;
  except
    Result := -1
  end;
  SetEvent(p.event);
end;

procedure GetFilesListBackGround(const FolderName, FileMask: String; Folder: TRtcDataSet);
var
  t: THandle;
  p: TProcParam;
  Wait: Cardinal;
begin
  p.event := CreateEvent(nil, false, false, '');
  Win32Check(p.event <> 0);
  Screen.Cursor := crHourGlass;
  try
    p.FolderName := FolderName;
    p.FileMask   := FileMask;
    p.Folder     := Folder;
    t := BeginThread(nil, 0, @GetFilesListBackThreadProc, @p, 0, PCardinal(nil)^);
    Win32Check(t <> 0);
    CloseHandle(t);
      repeat
        Wait := MsgWaitForMultipleObjects(1, p.event, false, INFINITE, QS_ALLEVENTS);
        case Wait of
          WAIT_OBJECT_0    : break;
          WAIT_OBJECT_0 + 1: Application.ProcessMessages;
        end;
      until Wait <> WAIT_OBJECT_0 + 1;
  finally
    CloseHandle(p.event);
    Screen.Cursor := crDefault;
  end;

end;

function FormatFileSize(const Number: int64): String;
begin
  if Number < int64(1024) * 100 then // below 100 KB - in Bytes
    Result := Format('%.0n B', [Number / 1])
  else if Number < int64(1024) * 1024 * 100 then // below 100 MB - in KB
    Result := Format('%.0n KB', [Number / 1024])
  else if Number < int64(1024) * 1024 * 1024 * 100 then // below 100 GB - in MB
    Result := Format('%.0n MB', [Number / (1024 * 1024)])
  else // above 100 GB - in GB
    Result := Format('%.0n GB', [Number / (1024 * 1024 * 1024)])
end;

Function DelFolderTree(DirName: String): Boolean;
var
  SHFileOpStruct: TSHFileOpStruct;
  DirBuf: array [0 .. 255] of char;
begin
  try
    Fillchar(SHFileOpStruct, Sizeof(SHFileOpStruct), 0);
    Fillchar(DirBuf, Sizeof(DirBuf), 0);
    StrPCopy(DirBuf, DirName);
    with SHFileOpStruct do
    begin
      Wnd := 0;
      pFrom := @DirBuf;
      wFunc := FO_DELETE;
      fFlags := FOF_ALLOWUNDO;
      fFlags := fFlags or FOF_NOCONFIRMATION;
      fFlags := fFlags or FOF_SILENT;
    end;
    Result := (SHFileOperation(SHFileOpStruct) = 0);
  except
    Result := False;
  end;
end;

function FileTimeToDateTime(FT: FILETIME): TDateTime;
var
  st: SYSTEMTIME;
  dt1, dt2: TDateTime;
begin
  FileTimeToSystemTime(FT, st);
  try
    dt1 := EncodeTime(st.whour, st.wminute, st.wsecond, st.wMilliseconds);
  except
    dt1 := 0;
  end;
  try
    dt2 := EncodeDate(st.wyear, st.wmonth, st.wday);
  except
    dt2 := 0;
  end;
  Result := dt1 + dt2;
end;

function FileSetDate(const FileName: String; Age: Integer): Integer;
var
  f: THandle;
begin
  f := FileOpen(FileName, fmOpenWrite);
  if f = THandle(-1) then
    Result := GetLastError
  else
  begin
    Result := System.SysUtils.FileSetDate(f, Age);
    FileClose(f);
  end;
end;

function Folder_Size(const FolderName: String): int64;
var
  sr: TSearchRec;
begin
  try
    Result := 0;
    if FindFirst(FolderName + '\*.*', faAnyFile, sr) = 0 then
      repeat
        if (sr.Name <> '.') and (sr.Name <> '..') then
        begin
          if (sr.Attr and faDirectory) = faDirectory then
            Result := Result + Folder_Size(FolderName + '\' + sr.Name)
          else
          begin
            //Result := Result + File_Size(FolderName+'\'+sr.Name);
            Result := Result + (int64(sr.FindData.nFileSizeHigh) shl 32) or
              (sr.FindData.nFileSizeLow);
          end;
        end;
      until (FindNext(sr) <> 0);
  finally
    FindClose(sr);
  end;
end;

function Folder_Content(const FolderName, SubFolderName: String;
  Folder: TRtcDataSet): int64;
var
  sr: TSearchRec;
  TempResult: int64;
begin
  try
    Result := 0;
    if FindFirst(FolderName + '\*.*', faAnyFile, sr) = 0 then
      repeat
        if (sr.Name <> '.') and (sr.Name <> '..') then
        begin
          if (sr.Attr and faDirectory) = faDirectory then
            begin
            TempResult := Folder_Content(FolderName + '\' + sr.Name, SubFolderName + sr.Name + '\', Folder);
            if TempResult = 0 then
              begin
              Folder.Append;
              Folder.asText['name'] := SubFolderName + sr.Name + '\';
              try
                Folder.asDateTime['age'] := FileDateToDateTime(sr.Time);
              except
                Folder.isNull['age'] := True;
                end;
              Folder.asInteger['attr'] := sr.Attr;
              end
            else
              Result := Result + TempResult;
            end
          else
          begin
            Folder.Append;
            Folder.asText['name'] := SubFolderName + sr.Name;
            try
              Folder.asDateTime['age'] := FileDateToDateTime(sr.Time);
            except
              Folder.isNull['age'] := True;
            end;
            Folder.asInteger['attr'] := sr.Attr;
            //Folder.asLargeInt['size']:= File_Size(FolderName+'\'+sr.Name);
            Folder.asLargeInt['size'] :=
              (int64(sr.FindData.nFileSizeHigh) shl 32) or
              (sr.FindData.nFileSizeLow);
            Result := Result + Folder.asLargeInt['size'];
          end;
        end;
      until (FindNext(sr) <> 0);
  finally
    FindClose(sr);
  end;
end;

function File_Content(const FileName: String; Folder: TRtcDataSet): int64;
var
  sr: TSearchRec;
  FolderName: String;
  TempResult: int64;
begin
  if Copy(FileName, length(FileName), 1) = '\' then
    Result := File_Content(FileName + '*.*', Folder)
  else
  begin
    FolderName := ExtractFilePath(FileName);
    if Copy(FolderName, length(FolderName), 1) = '\' then
      Delete(FolderName, length(FolderName), 1);
    try
      Result := 0;
      if FindFirst(FileName, faAnyFile, sr) = 0 then
        repeat
          if (sr.Name <> '.') and (sr.Name <> '..') then
          begin
            if (sr.Attr and faDirectory) = faDirectory then
              begin
              TempResult := Folder_Content(FolderName + '\' + sr.Name, sr.Name + '\', Folder);
              if TempResult = 0 then
                begin
                Folder.Append;
                Folder.asText['name'] := sr.Name + '\';
                try
                  Folder.asDateTime['age'] := FileDateToDateTime(sr.Time);
                except
                  Folder.isNull['age'] := True;
                  end;
                Folder.asInteger['attr'] := sr.Attr;
                end
              else
                Result := Result + TempResult;
              end
            else
            begin
              Folder.Append;
              Folder.asText['name'] := sr.Name;
              try
                Folder.asDateTime['age'] := FileDateToDateTime(sr.Time);
              except
                Folder.isNull['age'] := True;
              end;
              Folder.asInteger['attr'] := sr.Attr;
              //Folder.asLargeInt['size']:= File_Size(FolderName+'\'+sr.Name);
              Folder.asLargeInt['size'] :=
                (int64(sr.FindData.nFileSizeHigh) shl 32) or
                (sr.FindData.nFileSizeLow);
              Result := Result + Folder.asLargeInt['size'];
            end;
          end;
        until (FindNext(sr) <> 0);
    finally
      FindClose(sr);
    end;
  end;
end;

function GetDiskInfo_Inner(Value: TDiskSign): TDiskInfo;
var
  ErrorMode: Word;
  BPS, TC, FC, SPC: Integer;
  T, f: TLargeInteger;
  TF: PLargeInteger;
  bufRoot, bufVolumeLabel, bufFileSystem: pchar;
  MCL, Size, Flags: DWORD;
  s: String;
begin
  with Result do
  begin
    // Initialize structure ...
    SectorsPerCluster := 0;
    BytesPerSector := 0;
    FreeClusters := 0;
    TotalClusters := 0;
    Capacity := 0;
    FreeSpace := 0;
    VolumeLabel := '';
    SerialNumber := '';
    FileSystem := '';
    Serial := 0;

    // Try to get Drive information ...
    Size := 255;
    bufRoot := AllocMem(Size);
    try
      StrPCopy(bufRoot, Value + '\');
      case GetDriveType(bufRoot) of
        DRIVE_UNKNOWN:
          MediaType := dtUnknown;
        DRIVE_NO_ROOT_DIR:
          MediaType := dtNotExists;
        DRIVE_REMOVABLE:
          MediaType := dtRemovable;
        DRIVE_FIXED:
          MediaType := dtFixed;
        DRIVE_REMOTE:
          MediaType := dtRemote;
        DRIVE_CDROM:
          MediaType := dtCDROM;
        DRIVE_RAMDISK:
          MediaType := dtRAMDisk;
      end;
      // if (MediaType in [dtFixed,dtRemote,dtRAMDisk] ) then
      begin
        ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
        try
          if GetDiskFreeSpace(bufRoot, SectorsPerCluster, BytesPerSector,
            FreeClusters, TotalClusters) then
          begin
            New(TF);
            try
              try
                System.SysUtils.GetDiskFreeSpaceEx(bufRoot, f, T, TF);
                Capacity := T;
                FreeSpace := f;
              except
                BPS := BytesPerSector;
                TC := TotalClusters;
                FC := FreeClusters;
                SPC := SectorsPerCluster;
                Capacity := TC * SPC * BPS;
                FreeSpace := FC * SPC * BPS;
              end;
            finally
              Dispose(TF);
            end;
            bufVolumeLabel := AllocMem(Size);
            bufFileSystem := AllocMem(Size);
            try
              if GetVolumeInformation(bufRoot, bufVolumeLabel, Size, @Serial,
                MCL, Flags, bufFileSystem, Size) then
              begin;
                VolumeLabel := bufVolumeLabel;
                FileSystem := bufFileSystem;
                s := IntToHex(Serial, 8);
                SerialNumber := Copy(s, 1, 4) + '-' + Copy(s, 5, 4);
              end;
            finally
              FreeMem(bufVolumeLabel);
              FreeMem(bufFileSystem);
            end;
          end;
        finally
          SetErrorMode(ErrorMode);
        end;
      end;
    finally
      FreeMem(bufRoot);
    end;
  end;
end;

procedure GetDiskInfo(Value: string; Folder: TRtcDataSet);
var
  TotalFree, FreeAvailable, TotalSpace: Int64;
begin
  Value := IncludeTrailingBackslash(Value);
  Folder.asText['drive'] := Value;
  Folder.asInteger['type'] := GetDriveType(PChar(Value));
  if GetDiskFreeSpaceEx(PChar(Value), FreeAvailable, TotalSpace, @TotalFree) then
    begin
      Folder.asLargeInt['size'] := TotalSpace;
      Folder.asLargeInt['free'] := FreeAvailable;
    end;
end;

procedure GetFilesList_Inner(const FolderName, FileMask: String; Folder: TRtcDataSet);
var
  sr: TSearchRec;
  ErrorMode: Word;
  fm: String;

  procedure AddDrives;
  var
    shInfo: TSHFileInfo;
    i: Integer;
    Drv: String;
    DI: TDiskInfo;
    Drives: set of 0 .. 25;
  begin
    Integer(Drives) := GetLogicalDrives;
    for i := 0 to 25 do
      if (i in Drives) then
      begin
        Drv := char(i + Ord('A')) + ':';

        DI := GetDiskInfo_Inner(TDiskSign(Drv));
        Folder.Append;
        Folder.asText['drive'] := Drv;
        Folder.asLargeInt['size'] := DI.Capacity;
        Folder.asLargeInt['free'] := DI.FreeSpace;
        Folder.asInteger['type'] := Ord(DI.MediaType);
        SHGetFileInfo(pchar(Drv + '\'), 0, shInfo, Sizeof(shInfo),
          SHGFI_SYSICONINDEX or SHGFI_DISPLAYNAME or SHGFI_TYPENAME);
        Folder.asText['label'] := StrPas(shInfo.szDisplayName);
        // Folder.asText['label']:=DI.VolumeLabel;
      end;
  end;
  procedure AddFolders;
  begin
    if FileMask <> '' then
      fm := IncludeTrailingBackslash(FolderName) + FileMask
    else
      fm := IncludeTrailingBackslash(FolderName) + '*.*';
    ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
    try
      if FindFirst(fm, faAnyFile, sr) = 0 then
        try
          repeat
            if (sr.Name <> '.') and (sr.Name <> '..') then
            begin
              Folder.Append;
              Folder.asText['file'] := sr.Name;
              try
                Folder.asDateTime['age'] := FileDateToDateTime(sr.Time);
              except
                Folder.isNull['age'] := True;
              end;
              Folder.asInteger['attr'] := sr.Attr;
              if (sr.Attr and faDirectory) <> faDirectory then
              begin
                //Folder.asLargeInt['size']:= File_Size(FolderName+'\'+sr.Name);
                Folder.asLargeInt['size'] :=
                  (int64(sr.FindData.nFileSizeHigh) shl 32) or
                  (sr.FindData.nFileSizeLow);
              end;
            end;
          until (FindNext(sr) <> 0);
        finally
          FindClose(sr);
        end;
    finally
      SetErrorMode(ErrorMode);
    end;
  end;

begin
  if FolderName = '' then
    AddDrives
  else
    AddFolders;
end;

function StrRetToStr(var STRT: TStrRet; pidl: PItemIDList; Malloc: IMalloc): string;
var
   P    : PChar;
begin
   Result := '';
   case STRT.uType of
     STRRET_CSTR   : SetString(Result, STRT.cStr,   Length(STRT.cStr));
     STRRET_OFFSET : begin
                        P  := @PiDL.mkid.abID[STRT.uOffset - SizeOf(PiDL.mkid.cb)];
                        SetString(Result, P, PIDL.mkid.cb - STRT.uOffset);
                     end;
     STRRET_WSTR   : begin
                        Result     :=  STRT.pOleStr;
                        Malloc.Free(STRT.pOleStr);
                     end;
   end;
end;
function GetShellIcon(const ShellFolder: IShellFolder;
              PIDL: PItemIDList; out Index: Integer; out IconPath: string): Boolean;
var
  ExtractIcon: IExtractIcon;
  Flags  : Cardinal;
  Buffer :array [0..MAX_PATH] of Widechar;
  szS, szL: Integer;
begin
  Result  := false;
  if ShellFolder <> nil then
   if Succeeded(ShellFolder.GetUIObjectOf(0, 1, PiDL,
                              IExtractIcon, nil, Pointer(ExtractIcon))) then
      begin
          Result := SUCCEEDED(ExtractIcon.GetIconLocation(GIL_OPENICON, Buffer, MAX_PATH, Index, Flags));
      end;
   if Result then
    IconPath := Buffer;
end;

procedure GetNestedFolders(const FolderPath: string; Folder: TRtcDataSet);
var
  root, desk: IShellFolder;
  pidl: PItemIDList;
  sz: Cardinal;
  enum: IEnumIDList;
  malloc: IMalloc;
  strt: TStrRet;
  s: string;
  ImgIndex: Integer;
begin
  SHGetMalloc(MAlloc);
  if FAILED(SHGetDesktopFolder(desk)) then exit;
  sz := 0;
  if FAILED(desk.ParseDisplayName(0, nil, PChar(FolderPath), sz, pidl, sz)) then exit;
  try
    if FAILED(desk.BindToObject(pidl, nil, IShellFolder, root)) then exit;
  finally
    Malloc.Free(pidl);
  end;
  // nested folder
  if Succeeded(root.EnumObjects(0, SHCONTF_FOLDERS, Enum)) then
    begin
      pidl := nil;
      while Enum.Next(1, pidl, sz) = S_OK do
        try
          Folder.Append;
          if SUCCEEDED(root.GetDisplayNameOf(PiDL, SHGDN_NORMAL, strt)) then
            Folder.asText['label'] := StrRetToStr(STRT, pidl, malloc);
          if SUCCEEDED(root.GetDisplayNameOf(PiDL, SHGDN_FORPARSING, STRT)) then
            begin
              s := StrRetToStr(STRT, pidl, malloc);
              if Length(s) > 3 then
                begin
                  Folder.asText['drive'] := s;
                  Folder.asText['file'] := s;
                  Folder.asInteger['attr'] := faDirectory or faReadOnly;
                  Folder.asBoolean['tsclient'] := Pos('tsclient', s) > 0;
                end
              else
                GetDiskInfo(s, Folder);
            end;
          s := '';
          if GetShellIcon(root, pidl, ImgIndex, s) then
            begin
              Folder.asInteger['icon_index'] := ImgIndex;
              Folder.asText['icon_path'] := s;
            end;
        finally
          Malloc.Free(pidl);
        end;
    end;
end;

procedure GetFilesListStart(Folder: TRtcDataSet);
var
  desk: IShellFolder;
  pidl: PItemIDList;
  sz: Cardinal;
  malloc: IMalloc;
  hr: HRESULT;
  strt: TStrRet;
  s: string;
  ImgIndex: Integer;
begin

  SHGetMalloc(MAlloc);
  hr := SHGetDesktopFolder(desk);
  if not Succeeded(hr) then exit;
  GetNestedFolders(ID_MYCOMPUTER, Folder);
  // network

  hr := desk.ParseDisplayName(0, nil, PChar(ID_NETWORK), sz, pidl, sz);
  if not Succeeded(hr) then exit;
  Folder.Append;
  if SUCCEEDED(desk.GetDisplayNameOf(PiDL, SHGDN_NORMAL, strt)) then
    Folder.asText['label'] := StrRetToStr(STRT, pidl, malloc);

  if SUCCEEDED(desk.GetDisplayNameOf(PiDL, SHGDN_FORPARSING, STRT)) then
    begin
      s := StrRetToStr(STRT, pidl, malloc);
      Folder.asText['drive'] := s;
      Folder.asText['file'] := s;
      Folder.asInteger['attr'] := faDirectory or faReadOnly;
      Folder.asBoolean['network'] := true;
    end;
  s := '';
  if GetShellIcon(desk, pidl, ImgIndex, s) then
    begin
      Folder.asInteger['icon_index'] := ImgIndex;
      Folder.asText['icon_path'] := s;
    end;

  Malloc.Free(pidl);
end;

procedure GetFilesList(const FolderName, FileMask: String; Folder: TRtcDataSet);
var
  s: string;
begin
  s := Foldername;
  if (s = '') or (s[1] = ':') then
    begin
      if (Length(s) > 1) and (Length(s) < 3) and (s[1] = ':') then
        s := '' else
        s := ExcludeTrailingBackslash(s);
      if MainThreadID <> GetCurrentThreadId then
        begin
           if FAILED(CoInitializeEx(nil, COINIT_APARTMENTTHREADED)) then
            raise Exception.Create('CoInitializeEx FAILED');
        end
      else if s.StartsWith(ID_NETWORK) then
        begin
          GetFilesListBackGround(FolderName, FileMask, Folder);
          exit;
        end;

      try
        if (s = '') then
          GetFilesListStart(Folder) else
          GetNestedFolders(s, Folder);
      finally
        if MainThreadID <> GetCurrentThreadId then
          CoUninitialize;
      end;
    end
  else
    GetFilesList_Inner(FolderName, FileMask, Folder);
end;

//==============================================================================
// process network paths
//
function HandleNetworkFile(const FileName: string): string;
var
  s, s1: string;
  p: PChar;
  i: Integer;
begin
  // fix GUID path
  s := FileName;
  i := s.IndexOf('}');
  if (i <> -1) and s.StartsWith(ID_NETWORK, false) then
    begin
      s1 := s.Substring(i+1, Length(s));
      p := PChar(s1);
      i := 0;
      while (p^ <> #0) and (P^ = PathDelim) do
        begin
          Inc(p);
          Inc(i);
        end;
      if i < Length(s1) then
        begin
          while (P^ <> #0) and (P^ <> PathDelim) do
            begin
              Inc(p);
              Inc(i);
            end;
          if i + 1 < Length(s1) then
            s := s1.Substring(i+1, Length(s1));
        end;
    end;

  Result := s;
end;

end.
