unit RecordThrd;

interface

uses
  SysUtils, Dialogs, Classes, uVircessTypes, {AviFromBitmaps, vfw, }Windows, Graphics, CommonData;

type
  TRecordThrd = class(TThread)
  private
  protected
    FCurrent: Integer;
    FRecordState: TRecordState;
    HasFrame: Boolean;
    FBitmap: TBitmap;

    procedure GetNextFrameFromQueue;
    procedure CheckState;
    procedure Execute; override;
  public
    ParentHandle: THandle;
    FramesCount: ^Integer;
    CurrentFrame: ^Integer;
    CheckRecordStateProc: TExecuteProcedure;
    RecordState: ^TRecordState;
//    Avi: TAviFromBitmaps;
    FileName: String;
    ImageWidth, ImageHeight: Integer;
  end;

implementation

procedure TRecordThrd.GetNextFrameFromQueue;
var
  hFileMapping: THandle;
  lpFileMap: Pointer;bitimage: Pointer;
  bitDC, DC: HDC;
  hbitm: HBITMAP;
  hold: HGDIOBJ;
  BitsMem: Pointer;
  msize: Integer;
  BitmapInfo: TBitmapInfo;
  hbitmap: THandle;
begin
  if FramesCount^ > FCurrent then
    HasFrame := True
  else
  begin
    HasFrame := False;
    Exit;
  end;

  with BitmapInfo do
    with bmiHeader do
    begin
      biSize := SizeOf(bmiHeader);
      biWidth := ImageWidth;
      biHeight := ImageHeight;
      biPlanes:= 1;
      biBitCount:= 24;
      biCompression := BI_RGB;
      msize := BytesPerScanLine(biwidth, bibitcount, sizeof(DWORD)) * biheight;
      biSizeImage := msize;
      biXPelsPerMeter := 0;
      biYPelsPerMeter := 0;
      biClrUsed := 0;
      biClrImportant := 0;
    end;

  hbitmap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, msize, PWideChar('ScreenFrame' + IntToStr(FCurrent)));
  bitimage := MapViewOfFile(hbitmap, FILE_MAP_ALL_ACCESS, 0, 0, msize);

  DC := GetDC(INVALID_HANDLE_VALUE);
  bitDC := CreateCompatibleDC(DC);
  hbitm := CreateDIBSection(DC, BitmapInfo, DIB_RGB_COLORS, BitsMem, hbitmap, 0);
  ReleaseDC(INVALID_HANDLE_VALUE, DC);
  hold := SelectObject(bitDC, hbitm);

  BitBlt(FBitmap.Canvas.Handle, 0, 0, ImageWidth, ImageHeight, bitDC, 0, 0, SRCCOPY);

  SelectObject(bitDC, hold);
  DeleteObject(bitDC);

  UnMapViewOfFile(bitimage);
  CloseHandle(hbitmap);

  FCurrent := FCurrent + 1;
end;

procedure TRecordThrd.CheckState;
begin
  CurrentFrame^ := FCurrent;
  //CheckRecordStateProc;
  PostMessage(ParentHandle, WM_SETCURRENTFRAME, FCurrent, 0);

  FRecordState := RecordState^;
end;

procedure TRecordThrd.Execute;
begin
//  if (Avi = nil)
//    and (not Terminated) then
//  begin
//    Avi := TAviFromBitmaps.CreateAviFile(
//      nil, FileName,
//      //MKFOURCC('x', 'v', 'i', 'd'),// XVID (MPEG-4) compression
//      MKFOURCC('D', 'I', 'B', ' '),  // No compression
//      25, 1);                         // 25 frames per second
//
//    FBitmap := TBitmap.Create;
//    FBitmap.Width := ImageWidth;
//    FBitmap.Height := ImageHeight;
//    FBitmap.PixelFormat := pf24bit;
//  end;

  while not Terminated do
  begin
    Sleep(100);

    Synchronize(GetNextFrameFromQueue);

//    if HasFrame then
//    begin
//      //Write frame
//      Avi.AppendNewFrame(FBitmap.Handle);
//    end;

    Synchronize(CheckState);
  end;

  if Terminated then
  begin
    FBitmap.Free;
//    FreeAndNil(Avi);
  end;
end;


end.
