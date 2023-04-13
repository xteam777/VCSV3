unit FixFileExplorer;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.ComCtrls, Winapi.ShellAPI,
  rtcpFileExplore, Vcl.Controls, Vcl.ImgList, Winapi.CommCtrl, System.IOUtils;

type
  TRtcPFileExplorer = class (rtcpFileExplore.TRtcPFileExplorer)
  protected
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure FixIcon(ListView: TRtcPFileExplorer);
procedure AutoFitColumns(ListView: TRtcPFileExplorer);

implementation

uses
  Vcl.Graphics, System.Math;

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
  Result := IncludeTrailingBackslash(GetWindowsSystemFolder) + shell32dll;
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


//==============================================================================
//
//==============================================================================
const
  LVSCW_AUTOSIZE_BESTFIT = -3;

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


{ **************************************************************************** }
{                               TRtcPFileExplorer                              }
{ **************************************************************************** }


constructor TRtcPFileExplorer.Create(AOwner: TComponent);
begin
  inherited;
  FixIcon(Self);
end;


end.
