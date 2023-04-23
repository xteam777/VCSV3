(* ******************************************************
  File Explorer component,  
  Copyright 2004-2017 (c) RealThinClient.com (http://www.realthinclient.com)

  Based on MiTeC File Explorer Component by Michal Mutl,
  Copyright © 1999,2003 Michal Mutl (http://www.mitec.cz)

  @exclude
  ****************************************************** *)

unit rtcpFileExplore;

interface

{$INCLUDE rtcPortalDefs.inc}
{$INCLUDE rtcDefs.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, CommCtrl,
{$IFNDEF IDE_1} Variants, {$ELSE} FileCtrl, {$ENDIF}
  ShellAPI, Registry, Menus, ImgList, rtcInfo, rtcpFileUtils, Math;

type
  PHICON = ^HICON;

  TRtcPSortDirection = (sdAscending, sdDescending);

  TRtcPObjectType = (otFile, otDirectory, otDisk);
  TRtcPObjectTypes = set of TRtcPObjectType;

  TRtcPFileEvent = procedure(Sender: TObject; const FileName: String) of object;

  TRtcPFileExplorer = class(TCustomListView)
  private
    FDirectory: String;
    FDirectorySize: int64;
    FMyFiles,FMyFiles_: TRtcDataSet;

    iconMap: TStrings;

    FSortColumn: integer;
    LImageList, SImageList: TImageList;
    FSelectedFiles: TStringList;
    FSortDir: TRtcPSortDirection;

    FOnDirectoryChange: TRtcPFileEvent;
    FOnFileOpen: TRtcPFileEvent;
    FOnFileSelect: TRtcPFileEvent;
    FLocal: boolean;

    function GetSelectedNum: integer;
    function GetSelectedSize: int64;
    function GetSelectedFiles: TStringList; overload;

    procedure CompareFiles(Sender: TObject; Item1, Item2: TListItem;
      Data: integer; var Compare: integer);

    { procedure WMRButtonDown(var Message: TWMRButtonDown); message WM_RBUTTONDOWN;
      procedure DoMouseDown(var Message: TWMMouse; Button: TMouseButton; Shift: TShiftState); }

    procedure ColumnClick(Sender: TObject; Column: TListColumn);

    procedure SetSortColumn(const Value: integer);
    procedure SetSortDir(const Value: TRtcPSortDirection);
    procedure SetLocal(const Value: boolean);

    procedure LoadDefaultIcons;
    function IndexOfIcon(const Value: String): integer;

    function GetDirIconIndex(updir: boolean = False): integer;
    function GetFileIconIndex(const FileExt: String): integer;
    function GetDriveIconIndex(const MediaType: TRtcPMediaType): integer;

  protected
    procedure AddDrives(const FData: TRtcDataSet);
    procedure AddFiles(const FData: TRtcDataSet);

    procedure Click; override;
    procedure DblClick; override;

    // procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function GetMediaTypeStr(MT: TRtcPMediaType): String;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure onPath(NewDir: String; mask: String='');

    function SelectedFiles_(d_cap,f_cap: string): TStringList;
    procedure GetSelectedFiles(const PrefixFolder, PrefixFile: string; List: TStrings); overload;
    procedure PerformDoubleClick;

    procedure RefreshColumns;

    procedure OneLevelUp(clear_sel:boolean=False);
    procedure UpdateFileList(const Folder: String; const FData: TRtcDataSet);
    procedure UpdateFileList_(const Folder: String; const FData: TRtcDataSet);

    function GetFileName(const Item: TListItem): String;
    procedure SetFileName(const Item: TListItem; const FileName: String);

    property SelectedCount: integer read GetSelectedNum;
    property SelectedSize: int64 read GetSelectedSize;
    property SelectedFiles: TStringList read GetSelectedFiles;

    property Directory: String read FDirectory;
    property DirectorySize: int64 read FDirectorySize;

  published
    property SortColumn: integer read FSortColumn write SetSortColumn;
    property SortDirection: TRtcPSortDirection read FSortDir write SetSortDir;

    property Local: boolean read FLocal write SetLocal default False;

    property Align;
    property PopupMenu;
    property BorderStyle;
    property Color;
    property Ctl3D;
    property Dragmode;
    property DragCursor;
    property FlatScrollBars;
    property Font;
    property HideSelection;
    property HotTrack;
    property HotTrackStyles;
    property IconOptions;
    property MultiSelect;
    property ParentShowHint;
    property ReadOnly;
    property RowSelect;
    property ShowColumnHeaders;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property ViewStyle;
    property Visible;
    property OnChange;
    property OnChanging;
    property OnClick;
    property OnColumnClick;
    property OnCompare;
    property OnDblClick;
    property OnDeletion;
    property OnDragDrop;
    property OnDragOver;
    property OnEdited;
    property OnEditing;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnInsert;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property OnSelectItem;
    property OnContextPopup;

    property OnDirectoryChange: TRtcPFileEvent read FOnDirectoryChange
      write FOnDirectoryChange;
    property OnFileOpen: TRtcPFileEvent read FOnFileOpen write FOnFileOpen;
  end;

procedure FixIcon(ListView: TRtcPFileExplorer);
procedure AutoFitColumns(ListView: TRtcPFileExplorer);

procedure InitFileIconLibrary;

implementation

const
    LVSCW_AUTOSIZE_BESTFIT = -3;

var
  SysIconLib: String = '';

resourcestring
  SErrorExtractIcon = 'Failed to get an icon';

function GetWindowsSystemFolder: string;
var
  Required: Cardinal;
begin
  Result := '';
  Required := GetSystemDirectory(nil, 0);
  if Required <> 0 then
  begin
    SetLength(Result, Required);
    GetSystemDirectory(PChar(Result), Required);
    SetLength(Result, Required-1);
  end;
end;
function GetShell32Path: string;
const
  shell32dll = 'shell32.dll';
begin
  Result := IncludeTrailingPathDelimiter(GetWindowsSystemFolder) + shell32dll;
end;

procedure FixIcon(ListView: TRtcPFileExplorer);
const
  IC_ONE = 0;
  IC_TWO = 3;
  IC_THREE = 146;
var
  shell32: string;
  LargeIcon, SmallIcon: HICON;
  LImgs, SImgs: HIMAGELIST;
  Largeimages, SmallImages: TCustomImageList;
begin
  SImgs := 0;
  LImgs := 0;
  try
    shell32 := GetShell32Path;
    SmallImages := ListView.SmallImages;
    Largeimages := ListView.LargeImages;
    SImgs := ImageList_Create(SmallImages.Width, SmallImages.Height, ILC_COLOR32,
                SmallImages.AllocBy, SmallImages.AllocBy);
    LImgs := ImageList_Create(Largeimages.Width, Largeimages.Height, ILC_COLOR32,
                Largeimages.AllocBy, Largeimages.AllocBy);
    if ExtractIconEx(PChar(shell32), IC_ONE, LargeIcon, SmallIcon, 1) = INVALID_HANDLE_VALUE then
      RaiseLastOSError(GetLastError, SErrorExtractIcon);
    ImageList_AddIcon(SImgs, SmallIcon);
    ImageList_AddIcon(LImgs, LargeIcon);
    DestroyIcon(SmallIcon);
    DestroyIcon(LargeIcon);

    if ExtractIconEx(PChar(shell32), IC_TWO, LargeIcon, SmallIcon, 1) = INVALID_HANDLE_VALUE then
      RaiseLastOSError(GetLastError, SErrorExtractIcon);
    ImageList_AddIcon(SImgs, SmallIcon);
    ImageList_AddIcon(LImgs, LargeIcon);
    DestroyIcon(SmallIcon);
    DestroyIcon(LargeIcon);
    if ExtractIconEx(PChar(shell32), IC_THREE, LargeIcon, SmallIcon, 1) = INVALID_HANDLE_VALUE then
      RaiseLastOSError(GetLastError, SErrorExtractIcon);
    ImageList_AddIcon(SImgs, SmallIcon);
    ImageList_AddIcon(LImgs, LargeIcon);
    DestroyIcon(SmallIcon);
    DestroyIcon(LargeIcon);
  except
    if SImgs <> 0 then
      ImageList_Destroy(SImgs);
    if LImgs <> 0 then
      ImageList_Destroy(LImgs);
    raise;
  end;
  SmallImages.DrawingStyle := dsTransparent;
  Largeimages.DrawingStyle := dsTransparent;
  SmallImages.Handle := SImgs;
  Largeimages.Handle := LImgs;
end;

procedure AutoResizeColumn(const Column: TListColumn; const Mode: Integer = LVSCW_AUTOSIZE_BESTFIT);
var
  Width : Integer;
begin
  Case Mode of
    LVSCW_AUTOSIZE_BESTFIT  : begin
                                 Column.Width := LVSCW_AUTOSIZE;
                                 Width        := Column.Width;
                                 Column.Width := LVSCW_AUTOSIZE_USEHEADER;
                                 if Width>Column.Width then
                                 Column.Width := LVSCW_AUTOSIZE;
                              end;
    LVSCW_AUTOSIZE           : Column.Width := LVSCW_AUTOSIZE;
    LVSCW_AUTOSIZE_USEHEADER : Column.Width := LVSCW_AUTOSIZE_USEHEADER;
  end;
end;
//------------------------------------------------------------------------------
function GetMaxWidthColumn(ListView: TRtcPFileExplorer; Column: Integer): Integer;
var
  i, W: Integer;
  s: string;
  lvHandle: HWND;
begin
  lvHandle := ListView.Handle;
  s := ListView.Columns[Column].Caption;
  Result := ListView_GetStringWidth(lvHandle, PChar(s));
  for I := 0 to ListView.Items.Count-1 do
    if ListView.Items[i].SubItems.Count = Column then
      begin
        s := ListView.Items[i].SubItems[Column-1];
        W := ListView_GetStringWidth(lvHandle, PChar(s));
        if W > Result then
          Result := W;
      end;
end;
//------------------------------------------------------------------------------
procedure FitSpace(ListView: TRtcPFileExplorer);
var
  maxW, W, partW, I: Integer;
begin
  W := ListView.Columns[ListView.Columns.Count-1].Width;
  maxW := GetMaxWidthColumn(ListView, ListView.Columns.Count-1);
  if W <= maxW then exit;
  partW := (W - maxW) div ListView.Columns.Count;
  for I := 0 to ListView.Columns.Count-2 do
    begin
      ListView.Columns[i].Width := ListView.Columns[i].Width + partW;
    end;
  ListView.Columns[ListView.Columns.Count-1].Width := maxW + partW
end;
//------------------------------------------------------------------------------
procedure AutoFitColumns(ListView: TRtcPFileExplorer);
var
  i: integer;
begin
  if ListView.Columns.Count = 0 then exit;
  for i:=0 to ListView.Columns.Count-1 do
    AutoResizeColumn(ListView.Columns[i]);
  FitSpace(ListView);
end;

function GetSysIconLibrary: String;
var
  buffer: array [0 .. 255] of Char;
  path: String;
begin
  GetWindowsDirectory(buffer, SizeOf(buffer));
  path := IncludeTrailingPathDelimiter(StrPas(buffer));
  path := Format('%s;%sSystem\;%sSystem32\', [path, path, path]);
  Result := FileSearch('shell32.dll', path);
end;

function FileIconInit(FullInit: boolean = true): boolean;
type
  TFileIconInit = function(FullInit: BOOL): BOOL; stdcall;
var
  ShellDLL: HMODULE;
  PFileIconInit: TFileIconInit;
begin
  Result := False;
  if (Win32Platform = VER_PLATFORM_WIN32_NT) then
  begin
    ShellDLL := LoadLibrary(PChar(Shell32));
    PFileIconInit := GetProcAddress(ShellDLL, PChar(660));
    if (Assigned(PFileIconInit)) then
      Result := PFileIconInit(FullInit);
  end;
end;

procedure InitFileIconLibrary;
begin
  if SysIconLib = '' then
  begin
    SysIconLib := GetSysIconLibrary;
    if SysIconLib <> '' then
      if not FileExists(SysIconLib) then
        SysIconLib := ''
      else
        FileIconInit(true);
  end;
end;

procedure ConvertTo32BitImageList(const ImageList: TCustomImageList);
const
  Mask: array [boolean] of Longint = (0, ILC_MASK);
var
  TempList: TImageList;
begin
  if Assigned(ImageList) then
  begin
    TempList := TImageList.Create(nil);
    try
      TempList.Assign(ImageList);
      with ImageList do
      begin
        Handle := ImageList_Create(Width, Height, ILC_COLOR32 or Mask[Masked],
          0, AllocBy);
        if not HandleAllocated then
          raise EInvalidOperation.Create('Invalid image list');
      end;
      ImageList.AddImages(TempList);
    finally
      FreeAndNil(TempList);
    end;
  end;
end;

function ReadKey(Reg: TRegistry; key: String): String;
begin
  Result := '';
  try
    if (Reg.OpenKeyReadOnly(key)) then
      Result := Reg.ReadString('');
  finally
    Reg.CloseKey;
  end;
end;

function GetSystemAssociatedIconFile(Ext: String): String;
var
  Reg: TRegistry;
  FileType: String;
begin
  Result := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    if Ext = '.EXE' then
      Ext := '.COM';
    FileType := ReadKey(Reg, Ext);
    if (FileType <> '') then
    begin
      Result := ReadKey(Reg, FileType + '\DefaultIcon');
      if (Result = '') then
      begin
        Result := ReadKey(Reg, FileType + '\CurVer');
        if (Result <> '') then
          Result := ReadKey(Reg, Result + '\DefaultIcon');
      end;
    end;
  finally
    Reg.Free;
  end;
end;

function GetDefaultIcon(FileExt: String;
  PLargeIcon, PSmallIcon: PHICON): boolean;
var
  FileName: String;
  IconIndex: integer;
begin
  Result := False;
  FileName := SysIconLib;
  if FileName = '' then
    Exit;

  if (FileExt = '.DOC') or (FileExt = '.RTF') then
    IconIndex := 1
  else if (FileExt = '.EXE') or (FileExt = '.COM') then
    IconIndex := 2
  else if (FileExt = '.HLP') then
    IconIndex := 23
  else if (FileExt = '.INI') or (FileExt = '.INF') then
    IconIndex := 63
  else if (FileExt = '.TXT') then
    IconIndex := 64
  else if (FileExt = '.BAT') then
    IconIndex := 65
  else if (FileExt = '.DLL') or (FileExt = '.SYS') or (FileExt = '.VBX') or
    (FileExt = '.OCX') or (FileExt = '.VXD') then
    IconIndex := 66
  else if (FileExt = '.FON') then
    IconIndex := 67
  else if (FileExt = '.TTF') then
    IconIndex := 68
  else if (FileExt = '.FOT') then
    IconIndex := 69
  else
    IconIndex := 0;

  if ExtractIconEx(PChar(FileName), IconIndex, PLargeIcon^, PSmallIcon^, 1) < 1
  then
  begin
    if PLargeIcon <> nil then
      PLargeIcon^ := 0;
    if PSmallIcon <> nil then
      PSmallIcon^ := 0;
  end
  else
    Result := true;
end;

function GetSystemAssociatedIcon(FileExt: String;
  PLargeIcon, PSmallIcon: PHICON): boolean;
var
  assocFile: String;
  idx, IconIndex: integer;
begin
  IconIndex := 0;
  assocFile := GetSystemAssociatedIconFile(FileExt);
  if (assocFile = '') then
    Result := GetDefaultIcon(FileExt, PLargeIcon, PSmallIcon)
  else
  begin
    idx := Pos(',', assocFile);
    if (idx > 0) then
    begin
      IconIndex := StrToIntDef(copy(assocFile, idx + 1,
        length(assocFile) - idx), 0);
      assocFile := copy(assocFile, 0, idx - 1);
    end;
    if ExtractIconEx(PChar(assocFile), IconIndex, PLargeIcon^, PSmallIcon^, 1) < 1
    then
      Result := GetDefaultIcon(FileExt, PLargeIcon, PSmallIcon)
    else
      Result := true;
  end;
end;

function GetDriveIcon(DriveType: TRtcPMediaType;
  PLargeIcon, PSmallIcon: PHICON): boolean;
var
  FileName: String;
  iconIdx: integer;
begin
  Result := False;
  FileName := SysIconLib;
  if FileName = '' then
    Exit;

  case DriveType of
    dtRemovable:
      iconIdx := 6;
    dtFixed:
      iconIdx := 8;
    dtRemote:
      iconIdx := 9;
    dtNotExists:
      iconIdx := 10;
    dtCDROM:
      iconIdx := 11;
    dtUnknown:
      iconIdx := 53;
    dtRAMDisk:
      iconIdx := 140;
  else
    iconIdx := 8;
  end;

  if ExtractIconEx(PChar(FileName), iconIdx, PLargeIcon^, PSmallIcon^, 1) < 1
  then
  begin
    if PLargeIcon <> nil then
      PLargeIcon^ := 0;
    if PSmallIcon <> nil then
      PSmallIcon^ := 0;
  end
  else
    Result := true;
end;

procedure AddIcon(ImageList: TCustomImageList; sicon: HICON);
var
  icon: TICon;
begin
  if (sicon > 0) then
  begin
    icon := TICon.Create;
    icon.Width := ImageList.Width;
    icon.Height := ImageList.Height;
    icon.Handle := sicon;
    ImageList.AddIcon(icon);
    DestroyIcon(sicon);
    icon.Free;
  end;
end;

constructor TRtcPFileExplorer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSelectedFiles := TStringList.Create;
  LoadDefaultIcons; // CreateImages;
  FDirectory := '';
  FLocal := False;
  FSortDir := sdAscending;
  FSortColumn := -1;
  FMyFiles := nil;
  OnCompare := CompareFiles;
  OnColumnClick := ColumnClick;

  FixIcon(Self);
end;

destructor TRtcPFileExplorer.Destroy;
begin
  if Assigned(iconMap) then
  begin
    LImageList.Free;
    SImageList.Free;
    iconMap.Free;
  end;
  FSelectedFiles.Free;
  FMyFiles.Free;
  FMyFiles := nil;
  inherited Destroy;
end;

procedure TRtcPFileExplorer.LoadDefaultIcons;
var
  FileName: String;
  LargeIcon, SmallIcon: HICON;
begin
  InitFileIconLibrary;

  Smallimages := TImageList.Create(Self);

  Largeimages := TImageList.Create(Self);
  Largeimages.Width := 32;
  Largeimages.Height := 32;

  ConvertTo32BitImageList(LargeImages);
  ConvertTo32BitImageList(SmallImages);

  iconMap := TStringList.Create;

  FileName := SysIconLib;
  if FileName = '' then
    Exit;

  if ExtractIconEx(PChar(FileName), 0, LargeIcon, SmallIcon, 1) < 1 then
    raise Exception.Create('Unable to retrieve icon from list.');
  AddIcon(Largeimages, LargeIcon);
  AddIcon(Smallimages, SmallIcon);
  iconMap.Add('*');

  if ExtractIconEx(PChar(FileName), 3, LargeIcon, SmallIcon, 1) < 1 then
    raise Exception.Create('Unable to retrieve icon from list.');
  AddIcon(Largeimages, LargeIcon);
  AddIcon(Smallimages, SmallIcon);
  iconMap.Add('<Directory>');

  if ExtractIconEx(PChar(FileName), 146, LargeIcon, SmallIcon, 1) < 1 then
    raise Exception.Create('Unable to retrieve icon from list.');
  AddIcon(Largeimages, LargeIcon);
  AddIcon(Smallimages, SmallIcon);
  iconMap.Add('<Up>');
end;

function TRtcPFileExplorer.IndexOfIcon(const Value: String): integer;
begin
  Result := iconMap.IndexOf(Value);
end;

function TRtcPFileExplorer.GetDriveIconIndex(const MediaType
  : TRtcPMediaType): integer;
  function AddDriveIcon: integer;
  var
    LargeIcon, SmallIcon: HICON;
  begin
    Result := -1;
    if GetDriveIcon(MediaType, @LargeIcon, @SmallIcon) then
    begin
      AddIcon(Largeimages, LargeIcon);
      AddIcon(Smallimages, SmallIcon);
      Result := iconMap.Add('*' + IntToStr(Ord(MediaType)));
    end;
  end;

begin
  Result := IndexOfIcon('*' + IntToStr(Ord(MediaType)));
  if Result < 0 then
    Result := AddDriveIcon;
end;

function TRtcPFileExplorer.GetDirIconIndex(updir: boolean = False): integer;
begin
  if updir then
    Result := 2
  else
    Result := 1;
end;

function TRtcPFileExplorer.GetFileIconIndex(const FileExt: String): integer;
  function AddFileIcon: integer;
  var
    LargeIcon, SmallIcon: HICON;
  begin
    Result := 0;
    if GetSystemAssociatedIcon(FileExt, @LargeIcon, @SmallIcon) then
    begin
      AddIcon(Largeimages, LargeIcon);
      AddIcon(Smallimages, SmallIcon);
      Result := iconMap.Add(FileExt);
    end;
  end;
  function AddFileIconNew: integer;
  var
    FileInfo: TShFileInfo;
  begin
    FileInfo.dwAttributes := FILE_ATTRIBUTE_NORMAL;

    SHGetFileInfo(PChar('x' + FileExt), 0, FileInfo, SizeOf(FileInfo),
      SHGFI_ICON or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
    AddIcon(Smallimages, FileInfo.HICON);

    SHGetFileInfo(PChar('x' + FileExt), 0, FileInfo, SizeOf(FileInfo),
      SHGFI_ICON or SHGFI_LARGEICON or SHGFI_USEFILEATTRIBUTES);
    AddIcon(Largeimages, FileInfo.HICON);

    Result := iconMap.Add(FileExt);
  end;

begin
  if FileExt = '' then
    Result := 0
  else
  begin
    Result := IndexOfIcon(FileExt);
    if Result < 0 then
      Result := AddFileIconNew;
  end;
end;

procedure TRtcPFileExplorer.GetSelectedFiles(const PrefixFolder,
  PrefixFile: string; List: TStrings);
var
  i: integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    if SelCount > 0 then
      for i := 0 to Items.Count - 1 do
        if Items[i].selected then
          if (Items[i].SubItems[5] = 'dir') or (Items[i].SubItems[5] = 'file')
          then
            if (Items[i].SubItems[4] <> '..') then
            if (Items[i].SubItems[5] = 'dir') then
              List.Add(PrefixFolder + ExtractFileName(Items[i].SubItems[4])) else
              List.Add(PrefixFile + ExtractFileName(Items[i].SubItems[4]))
  finally
    List.EndUpdate
  end;

end;

function TRtcPFileExplorer.GetSelectedNum: integer;
begin
  Result := SelCount;
  if Result = 0 then
    Result := Items.Count;
end;

function TRtcPFileExplorer.GetSelectedSize: int64;
var
  i: integer;
  FSize: int64;
  FSizeStr: String;
begin
  FSize := 0;
  if SelCount > 0 then
    for i := 0 to Items.Count - 1 do
      if Items[i].selected then
      begin
        FSizeStr := Items[i].SubItems[6];
        if FSizeStr <> '' then
          FSize := FSize + StrToInt64(FSizeStr);
      end;
  Result := FSize;
end;

{ procedure TRtcPFileExplorer.Createimages;
  var
  SysImageList: uint;
  SFI: TSHFileInfo;
  begin
  Largeimages:=TImageList.Create(self);
  SysImageList:=SHGetFileInfo('',0,SFI,SizeOf(TSHFileInfo),SHGFI_SYSICONINDEX or SHGFI_LARGEICON);
  if SysImageList<>0 then
  begin
  Largeimages.Handle:=SysImageList;
  Largeimages.ShareImages:=TRUE;
  end;
  Smallimages:=TImageList.Create(Self);
  SysImageList:=SHGetFileInfo('',0,SFI,SizeOf(TSHFileInfo),SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  if SysImageList<>0 then
  begin
  Smallimages.Handle:=SysImageList;
  Smallimages.ShareImages:=TRUE;
  end;
  end; }

procedure TRtcPFileExplorer.ColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index = FSortColumn then
  begin
    if FSortDir = sdAscending then
      SortDirection := sdDescending
    else
      SortDirection := sdAscending;
  end
  else
  begin
    FSortDir := sdAscending;
    SortColumn := Column.Index;
  end;
end;

const
  maxint64: int64 = $7FFFFFFFFFFFFFFF;

procedure TRtcPFileExplorer.CompareFiles(Sender: TObject;
  Item1, Item2: TListItem; Data: integer; var Compare: integer);
var
  s1, s2, Caption1, Caption2: String;
  date1, date2: Double;
  d1, d2, size1, size2: int64;
  Result: integer;
begin
  if FSortColumn <= 0 then // name
  begin
    if FDirectory = '' then
    begin
      Caption1 := Item1.SubItems[4]; // drive letter
      Caption2 := Item2.SubItems[4]; // drive letter
    end
    else
    begin
      Caption1 := Item1.Caption;
      Caption2 := Item2.Caption;
    end;
  end
  else if (FSortColumn = 2) then // size
  begin
    Caption1 := Item1.SubItems[6];
    Caption2 := Item2.SubItems[6];
  end
  else if ((FSortColumn = 3) and (FDirectory = '')) then // free
  begin
    Caption1 := Item1.SubItems[7];
    Caption2 := Item2.SubItems[7];
  end
  else // name, date, type, etc
  begin
    Caption1 := Item1.SubItems[FSortColumn - 1];
    Caption2 := Item2.SubItems[FSortColumn - 1];
  end;

  if (FSortColumn = 2) or ((FSortColumn = 3) and (FDirectory = '')) then
  // size and free (numbers)
  begin
    try
      if Caption1 = '' then
      begin
        if FSortDir = sdDescending then
          size1 := maxint64
        else
          size1 := 0;
      end
      else
        size1 := StrToInt64(Caption1);
    except
      if FSortDir = sdDescending then
        size1 := maxint64
      else
        size1 := 0;
    end;

    try
      if Caption2 = '' then
      begin
        if FSortDir = sdDescending then
          size2 := maxint64
        else
          size2 := 0;
      end
      else
        size2 := StrToInt64(Caption2);
    except
      if FSortDir = sdDescending then
        size2 := maxint64
      else
        size2 := 0;
    end;

    if FSortDir = sdDescending then
    begin
      d1 := maxint64 - 1;
      d2 := maxint64;
    end
    else
    begin
      d1 := -maxint64 + 1;
      d2 := -maxint64;
    end;
    if SameText(Item1.SubItems[5], 'dir') then
    begin
      if SameText(Item1.Caption, '..') then
        size1 := d2 + size1
      else
        size1 := d1 + size1;
    end;
    if SameText(Item2.SubItems[5], 'dir') then
    begin
      if SameText(Item2.Caption, '..') then
        size2 := d2 + size2
      else
        size2 := d1 + size2;
    end;
    if size1 < size2 then
      Result := -1
    else if size2 < size1 then
      Result := 1
    else
      Result := 0;
  end
  else if (FSortColumn = 3) and (FDirectory <> '') then // modified
  begin
    s1 := Caption1;
    try
      if s1 = '' then
      begin
        if FSortDir = sdDescending then
          date1 := maxint
        else
          date1 := 0;
      end
      else
        date1 := StrToDatetime(s1);
    except
      if FSortDir = sdDescending then
        date1 := maxint
      else
        date1 := 0;
    end;

    s2 := Caption2;
    try
      if s2 = '' then
      begin
        if FSortDir = sdDescending then
          date2 := maxint
        else
          date2 := 0;
      end
      else
        date2 := StrToDatetime(s2);
    except
      if FSortDir = sdDescending then
        date2 := maxint
      else
        date2 := 0;
    end;

    if FSortDir = sdDescending then
    begin
      d1 := MaxWord;
      d2 := 2 * MaxWord;
    end
    else
    begin
      d1 := -MaxWord;
      d2 := -2 * MaxWord;
    end;
    if SameText(Item1.SubItems[5], 'dir') then
    begin
      if SameText(Item1.Caption, '..') then
        date1 := d2 + date1
      else
        date1 := d1 + date1;
    end;
    if SameText(Item2.SubItems[5], 'dir') then
    begin
      if SameText(Item2.Caption, '..') then
        date2 := d2 + date2
      else
        date2 := d1 + date2;
    end;
    Result := Sign(date1 - date2);
  end
  else // name, type, attr
  begin
    if FSortDir = sdDescending then
    begin
      s1 := #254;
      s2 := #255
    end
    else
    begin
      s1 := #1;
      s2 := #0;
    end;
    if SameText(Item1.SubItems[5], 'dir') then
    begin
      if SameText(Item1.Caption, '..') then
        Caption1 := s2 + Caption1
      else
        Caption1 := s1 + Caption1;
    end;
    if SameText(Item2.SubItems[5], 'dir') then
    begin
      if SameText(Item2.Caption, '..') then
        Caption2 := s2 + Caption2
      else
        Caption2 := s1 + Caption2;
    end;
    Result := CompareText(Caption1, Caption2);
  end;

  if FSortDir = sdDescending then
    Compare := -Result
  else
    Compare := Result;
end;

procedure TRtcPFileExplorer.UpdateFileList(const Folder: String;
  const FData: TRtcDataSet);
begin
  if Assigned(FData) then
  begin
    if Assigned(FMyFiles) then
      FMyFiles.Free;
    FMyFiles := TRtcDataSet(FData.copyOf);
  end
  else
  begin
    FMyFiles.Free;
    FMyFiles := nil;
  end;
  FDirectory := Folder;
  RefreshColumns;
end;

procedure TRtcPFileExplorer.UpdateFileList_(const Folder: String;
  const FData: TRtcDataSet);
begin
  if Assigned(FData) then
  begin
    if Assigned(FMyFiles_) then
      FMyFiles_.Free;
    FMyFiles := TRtcDataSet(FData.copyOf);
  end
  else
  begin
    FMyFiles_.Free;
    FMyFiles_ := nil;
  end;
end;

procedure TRtcPFileExplorer.AddDrives(const FData: TRtcDataSet);
var
  i: integer;
  Drv: String;
begin
  if FData = nil then
    Exit;

  FData.First;
  for i := 1 to FData.RowCount do
  begin
    Drv := FData.asText['drive'];
    with Items.Add do
    begin
      Caption := FData.asText['label']; // name 0
      ImageIndex := GetDriveIconIndex(TRtcPMediaType(FData.asInteger['type']));
      SubItems.Add(GetMediaTypeStr(TRtcPMediaType(FData.asInteger['type'])));
      // type 1
      SubItems.Add(FormatFileSize(FData.asLargeInt['size'])); // size 2
      SubItems.Add(FormatFileSize(FData.asLargeInt['free'])); // free 3
      SubItems.Add(''); // attr 4
      SubItems.Add(Drv + '\'); // full path 5
      SubItems.Add('drv'); // item kind 6
      SubItems.Add(IntToStr(FData.asLargeInt['size']));
      // unformatted size (used for sorting) 7
      SubItems.Add(IntToStr(FData.asLargeInt['free']));
      // unformatted size (used for sorting) 8
    end;
    FData.Next;
  end;
end;

procedure TRtcPFileExplorer.AddFiles(const FData: TRtcDataSet);
var
  CurPath, Attributes: String;
  FDate, FName, FileName: String;
  FSize: int64;
  i: integer;

  function AttrStr(Attr: integer): String;
  begin
    Result := '';
    if (FILE_ATTRIBUTE_DIRECTORY and Attr) > 0 then
      Result := Result + '';
    if (FILE_ATTRIBUTE_ARCHIVE and Attr) > 0 then
      Result := Result + 'A';
    if (FILE_ATTRIBUTE_READONLY and Attr) > 0 then
      Result := Result + 'R';
    if (FILE_ATTRIBUTE_HIDDEN and Attr) > 0 then
      Result := Result + 'H';
    if (FILE_ATTRIBUTE_SYSTEM and Attr) > 0 then
      Result := Result + 'S';
  end;

  function AttrHidden(Attr: integer): boolean;
  begin
    Result := ((FILE_ATTRIBUTE_HIDDEN and Attr) > 0) or
      ((FILE_ATTRIBUTE_SYSTEM and Attr) > 0);
  end;

begin
  if FData = nil then
    Exit;

  FData.First;
  CurPath := IncludeTrailingBackslash(FDirectory);
  FileName := CurPath + FName;
  // ".." (go up)
//  with Items.Add do
//  begin
//    Caption := '..'; // Name 0
//    ImageIndex := GetDirIconIndex(true);
//    SubItems.Add('[Назад]'); // Type 1
//    SubItems.Add(''); // Size 2
//    SubItems.Add(''); // Modified 3
//    SubItems.Add(''); // Attributes 4
//    SubItems.Add('..'); // Full path 5
//    SubItems.Add('dir'); // 6
//    SubItems.Add('0'); // 7
//  end;
  for i := 1 to FData.RowCount do
  begin
    FName := FData.asText['file'];
    FileName := CurPath + FName;
    FSize := FData.asLargeInt['size'];
    if FData.isType['age'] = rtc_DateTime then
       DateTimeToString(FDate, 'dd.mm.yyyy hh:nn:ss', FData.asDateTime['age'])
    else
      FDate := '';
    Attributes := AttrStr(FData.asInteger['attr']);
    with Items.Add do
    begin
      Caption := FName; // Name 0
      if (FData.asInteger['attr'] and faDirectory) = faDirectory then
      begin
        ImageIndex := GetDirIconIndex;
        (*SubItems.Add('<Directory>'); // Type 1*)
        SubItems.Add('Папка'); // Type 1
        SubItems.Add(''); // Size 2
        SubItems.Add(FDate); // Modified 3
        SubItems.Add(Attributes); // Attributes 4
        SubItems.Add(FileName); // Full path 5
        SubItems.Add('dir'); // 6
        SubItems.Add('0'); // 7
      end
      else
      begin
        FName := UpperCase(ExtractFileExt(FName));
        ImageIndex := GetFileIconIndex(FName);
        (*SubItems.Add(FName + ' File'); // Type 1*)
        if FName <> '' then
          SubItems.Add(FName + ' Файл') // Type 1
        else
          SubItems.Add('Файл'); // Type 1
        SubItems.Add(FormatFileSize(FSize)); // Size 2
        SubItems.Add(FDate); // Modified 3
        SubItems.Add(Attributes); // Attributes 4
        SubItems.Add(FileName); // Full path 5
        SubItems.Add('file'); // 6
        SubItems.Add(IntToStr(FSize)); // 7
      end;
    end;
    FDirectorySize := FDirectorySize + FSize;
    FData.Next;
  end;
end;

procedure TRtcPFileExplorer.OneLevelUp(clear_sel:boolean=False);
var
  NewDir: String;
  fld: TRtcDataSet;
begin
  if FDirectory = '' then
    NewDir := ''
  else
  begin
    NewDir := IncludeTrailingBackslash(FDirectory);
    if (length(NewDir) < 2) or (NewDir[length(NewDir) - 1] = ':') then
      NewDir := ''
    else
    begin
      NewDir := copy(NewDir, 1, length(NewDir) - 1);
      NewDir := ExtractFilePath(NewDir);
    end;
  end;
  if FLocal then
  begin
    fld := TRtcDataSet.Create;
    try
      GetFilesList(NewDir, '*.*', fld);
      UpdateFileList(NewDir, fld);

      if not clear_sel then
      begin
           selected:=    items[0];
           ItemFocused:= selected;
      end;

    finally
      fld.Free;
    end;
  end;
  if Assigned(FOnDirectoryChange) then
    FOnDirectoryChange(Self, NewDir);
end;

procedure TRtcPFileExplorer.Click;
begin
  if selected <> nil then
    if Assigned(FOnFileSelect) then
      FOnFileSelect(Self, selected.SubItems[4]);
  inherited;
end;

procedure TRtcPFileExplorer.DblClick;
var
  NewDir: String;
  fld: TRtcDataSet;
begin
  inherited;
  if selected = nil then
    Exit;
  if (selected.SubItems[5] = 'dir') or (selected.SubItems[5] = 'drv') then
  begin
    NewDir := selected.SubItems[4];
    if NewDir = '..' then
      OneLevelUp
    else
    begin
      NewDir := IncludeTrailingBackslash(NewDir);
      if FLocal then
      begin
        fld := TRtcDataSet.Create;
        try
          GetFilesList(NewDir, '*.*', fld);
          UpdateFileList(NewDir, fld);
          Selected:=     items[0];
          ItemFocused:=  items[0];
        finally
          fld.Free;
        end;
      end;
      if Assigned(FOnDirectoryChange) then
        FOnDirectoryChange(Self, NewDir);
    end;
  end
  else if selected.SubItems[5] = 'file' then
  begin
    NewDir := selected.SubItems[4];
    if Assigned(FOnFileOpen) then
      FOnFileOpen(Self, NewDir);
  end;
end;


{ procedure TRtcPFileExplorer.WMRButtonDown(var Message: TWMRButtonDown);
  begin
  DoMouseDown(Message, mbRight, []);
  end;

  procedure TRtcPFileExplorer.DoMouseDown(var Message: TWMMouse;
  Button: TMouseButton; Shift: TShiftState);
  begin
  if not (csNoStdEvents in ControlStyle) then
  with Message do
  MouseDown(Button, KeysToShiftState(Keys) + Shift, XPos, YPos);
  end;

  procedure TRtcPFileExplorer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  var
  p :tpoint;
  n :tlistitem;
  begin
  inherited;
  if (button=mbright) then
  begin
  n:=getItemAt(x,y);
  if assigned(n) then
  begin
  if pos(n.subitems[4],selectedfilenames)=0 then
  selected:=nil;
  selected:=n;
  click;
  getcursorpos(p);
  if selectedcount>1 then
  getselectedfilenames;
  end;
  end;
  end; }

function TRtcPFileExplorer.GetSelectedFiles: TStringList;
var
  i: integer;
begin
  Result := FSelectedFiles;
  FSelectedFiles.Clear;
  if SelCount > 0 then
    for i := 0 to Items.Count - 1 do
      if Items[i].selected then
        if (Items[i].SubItems[5] = 'dir') or (Items[i].SubItems[5] = 'file')
        then
          if (Items[i].SubItems[4] <> '..') then
            FSelectedFiles.Add(Items[i].SubItems[4]);
end;

function TRtcPFileExplorer.GetMediaTypeStr(MT: TRtcPMediaType): String;
begin
  case MT of
    dtUnknown:
      Result := '<unknown>';
    dtNotExists:
      Result := '<not exists>';
    dtRemovable:
      Result := 'Removable';
    dtFixed:
      Result := 'Drive';
    dtRemote:
      Result := 'Remote';
    dtCDROM:
      Result := 'CD/DVD-ROM';
    dtRAMDisk:
      Result := 'RAM Disk';
  end;
end;

procedure TRtcPFileExplorer.SetSortColumn(const Value: integer);
begin
  FSortColumn := Value;
  if FSortColumn < 0 then
    SortType := stNone
  else
    SortType := stText;
  AlphaSort;
end;

procedure TRtcPFileExplorer.SetSortDir(const Value: TRtcPSortDirection);
begin
  FSortDir := Value;
  AlphaSort;
end;

procedure TRtcPFileExplorer.SetLocal(const Value: boolean);
begin
  if Value <> FLocal then
  begin
    FLocal := Value;
    FDirectory := '';
    OneLevelUp;
  end;
end;

function TRtcPFileExplorer.GetFileName(const Item: TListItem): String;
begin
  Result := '';
  if Assigned(Item) then
    if (Item.SubItems[5] = 'dir') or (Item.SubItems[5] = 'file') then
      if (Item.SubItems[4] <> '..') or (length(Directory) > 3) then
        Result := Item.SubItems[4];
end;

procedure TRtcPFileExplorer.SetFileName(const Item: TListItem;
  const FileName: String);
begin
  if Assigned(Item) then
    if (Item.SubItems[5] = 'dir') or (Item.SubItems[5] = 'file') then
      if (Item.SubItems[4] <> '..') or (length(Directory) > 3) then
        Item.SubItems[4] := ExtractFilePath(Item.SubItems[4]) + FileName;
end;

procedure TRtcPFileExplorer.RefreshColumns;
var
  oldCur: TCursor;
begin
  if Columns.Count <> 5 then
  begin
    Columns.Clear;
    with Columns.Add do // 0
    begin
      Caption := 'Имя';//'Name';
      Width := 200;
    end;
    with Columns.Add do // 1
    begin
      Caption := 'Тип';//'Type';
      Width := 90;
    end;
    with Columns.Add do // 2
    begin
      Caption := 'Размер';//'Size';
      Width := 80;
      Alignment := taRightJustify;
    end;
    with Columns.Add do // 3
    begin
      Caption := 'Изменено';//'Modified';
      Width := 150;
      Alignment := taRightJustify;
    end;
    with Columns.Add do // 4
    begin
      Caption := 'Атрибуты';//'Attr';
      Width := 45;
    end;
  end;
  oldCur := Screen.Cursor;
  Items.BeginUpdate;
  try
    FDirectorySize := 0;
    Items.Clear;
    Screen.Cursor := crHourGlass;
    try
      if FDirectory = '' then
      begin
        Column[1].Caption := 'Тип';//'Type';
        Column[2].Caption := 'Емкость';//'Capacity';
        Column[3].Caption := 'Свободно';//'Free Space';
        AddDrives(FMyFiles);
      end
      else
      begin
        Column[1].Caption := 'Тип'; //'Type';
        Column[2].Caption := 'Размер';//'Size';
        Column[3].Caption := 'Изменено';//'Modified';
        AddFiles(FMyFiles);
      end;
    finally
      FSortDir := sdDescending;
      ColumnClick(Self, Columns[0]);
    end;
  finally
    Items.EndUpdate;
    Screen.Cursor := oldCur;
  end;
end;

procedure TRtcPFileExplorer.onPath(NewDir, mask: string);
var
  data: TRtcDataSet;
begin
  if not Local then exit;

  data := TRtcDataSet.Create;
  try
    GetFilesList(NewDir, mask, data);
    UpdateFileList(NewDir, data);
  finally
    data.Free;
  end;

//  if Assigned(OnDirectoryChange) then
//    OnDirectoryChange(Self, NewDir);

end;

{procedure TRtcPFileExplorer.onPath(NewDir: String; mask: String='');
var
  fld: TRtcDataSet;
begin
  inherited;
      if mask='' then mask:= '*.*';
      NewDir := IncludeTrailingBackslash(NewDir);
      if FLocal then
      begin
        fld := TRtcDataSet.Create;
        try
          GetFilesList(NewDir, mask, fld);
          UpdateFileList(NewDir, fld);
        finally
          fld.Free;
        end;
      end;
      if Assigned(FOnDirectoryChange) then
        FOnDirectoryChange(Self, NewDir);
end;}

procedure TRtcPFileExplorer.PerformDoubleClick;
begin
  DblClick;
end;

function TRtcPFileExplorer.SelectedFiles_(d_cap,f_cap: string): TStringList;
var
  i: integer;
begin
  Result := FSelectedFiles;
  FSelectedFiles.Clear;
  if SelCount > 0 then
    for i := 0 to Items.Count - 1 do
      if Items[i].selected then
        if (Items[i].SubItems[5] = 'dir') or (Items[i].SubItems[5] = 'file')
        then
          if (Items[i].SubItems[4] <> '..') then
          if (Items[i].SubItems[5] = 'dir') then
            FSelectedFiles.Add(d_cap+ExtractFileName(Items[i].SubItems[4])) else
            FSelectedFiles.Add(f_cap+ExtractFileName(Items[i].SubItems[4]))
end;

end.
