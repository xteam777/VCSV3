{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcScrPlayback;

interface

{$INCLUDE rtcPortalDefs.inc}
{$INCLUDE rtcDefs.inc}

uses
  Windows,
  Classes,
  SysUtils,
  Graphics,
  Forms,

  rtcSystem,
  rtcInfo,
  rtcZLib,
  System.UITypes,
  rmxImageCODEC,

  IniFiles, System.SyncObjs,
  rtcCompress, Vcl.Imaging.JPEG, Vcl.Imaging.PNGImage, //RtcWebPCodec,
  {$IFDEF WithSynLZTest} SynLZ, {$ENDIF} lz4d, lz4d.lz4, lz4d.lz4s,
  Math, Compressions;

type
  TRtcScreenPlayback = class;

  TRtcScreenDecoder = class
  type
    TWebPDecodeRGBIntoFunc = function (const data: PByte; data_size: Cardinal;
      output_buffer: PByte; output_buffer_size, output_stride: Integer): PByte;
      cdecl;
    TOnSetScreenData = procedure (Sender: TObject; UserName: String; const Data: RtcString) of object;

  private
   // FBytesPerPixel: byte;
    TempBuff: RtcByteArray;
    CS : TCriticalSection;
    Playback: TRtcScreenPlayback;

    FScreenWidth, FScreenHeight, FScreenBPP,

    FBPPWidth, FBlockSize: integer;

    FScreenInfoChanged: Boolean;

    FImage: TBitmap;
    FOnSetScreenData: TOnSetScreenData;
    FCompressor: TCompressionLZMA2;

    function CreateBitmap: TBitmap;
    function SetScreenData(const Data: TRtcRecord): boolean; overload;
  protected
    procedure PrepareStorage;
    procedure ReleaseStorage;

    procedure SetScreenInfo(const Info: TRtcRecord);
    procedure SetPalette(const s: RtcByteArray);

    procedure DrawMovedRects(Rects : TRtcArray);
    procedure DrawDirtyRects(Rects : TRtcArray);

    procedure DecompressBlock(const Offset: longint; const s: RtcByteArray);
    procedure DecompressBlock2(const Offset: longint; const s: RtcByteArray);
    procedure DecompressBlock3(const Offset: longint; const s: RtcByteArray);

    function FixDrawDirtyRects(const Rects : TRtcArray): Boolean;
  public
    constructor Create;
    destructor Destroy; override;


    function SetScreenData(const Data: RtcString): boolean;  overload;

    property Image: TBitmap read FImage;
    property ScreenWidth: Integer read FScreenWidth;
    property ScreenHeight: Integer read FScreenHeight;
    property ScreenBPP: Integer read FScreenBPP;
    property ScreenInfoChanged: Boolean read FScreenInfoChanged write FScreenInfoChanged;
    property OnSetScreenData: TOnSetScreenData read FOnSetScreenData write FOnSetScreenData;

  end;

  TRtcScreenPlayback = class
  private
    ScrOut: TRtcScreenDecoder;
    FCursorVisible: boolean;
    FCursorHotX: integer;
    FCursorHotY: integer;
    FCursorX: integer;
    FCursorY: integer;
    FCursorShape: integer;
    FCursorStd: boolean;
    FCursorImage: TBitmap;
    FCursorMask: TBitmap;
    FCursorOldY: integer;
    FCursorOldX: integer;
    FCursorUser: String;

    {$IFDEF DEBUG}
    FCapLat, FEncLat, FDecLat : Int64;
    {$ENDIF}

    FCursorSever: TCursor;
    function GetScreen: TBitmap;

  public
    FLoginUserName: String;

    constructor Create; virtual;
    destructor Destroy; override;

    function PaintScreen(const s: RtcString): boolean;
    function PaintCursor(const s: RtcString): boolean;

    property Image: TBitmap read GetScreen;
    property ScreenDecoder: TRtcScreenDecoder read ScrOut;

    property LoginUserName: String read FLoginUserName write FLoginUserName;
    property CursorVisible: boolean read FCursorVisible;
    property CursorOldX: integer read FCursorOldX;
    property CursorOldY: integer read FCursorOldY;
    property CursorX: integer read FCursorX;
    property CursorY: integer read FCursorY;
    property CursorHotX: integer read FCursorHotX;
    property CursorHotY: integer read FCursorHotY;
    property CursorImage: TBitmap read FCursorImage;
    property CursorMask: TBitmap read FCursorMask;
    property CursorShape: integer read FCursorShape;
    property CursorStd: boolean read FCursorStd;
    property CursorUser: String read FCursorUser;
    property CursorSever: TCursor read FCursorSever write FCursorSever;

   {$IFDEF DEBUG}
    property CapLat : Int64 read FCapLat; // Desktop Duplication Latency
    property EncLat : Int64 read FEncLat; // WebP Encode Latency
    property DecLat : Int64 read FDecLat; // WebP Decode Latency
   {$ENDIF}
 end;

implementation

{$IFDEF DEBUG}
uses rtcDebug{, rmxImageCODEC};
{$ENDIF}



{ Helper Functions }

function BitmapDataPtr(const Image: TBitmap): pointer;
begin
  With Image do
  begin
    if Height < 2 then
      Result := ScanLine[0]
    else if Cardinal(ScanLine[0]) < Cardinal(ScanLine[1]) then
      Result := ScanLine[0]
    Else
      Result := ScanLine[Height - 1];
  End;
end;

function BitmapDataPtr2(const Image: TBitmap; Offset: longint): pointer;
begin
  With Image do
    Result := pointer(longint(ScanLine[0]) + Offset);
end;

{ - TRtcScreenDecoder - }

constructor TRtcScreenDecoder.Create;
begin
  inherited;
  FImage := nil;
  SetLength(TempBuff, 0);

  CS := TCriticalSection.Create;
end;

destructor TRtcScreenDecoder.Destroy;
begin
  ReleaseStorage;
  FreeAndNil(FCompressor);
  inherited;

  CS.Free;
end;

function TRtcScreenDecoder.FixDrawDirtyRects(const Rects: TRtcArray): Boolean;
var
  i: Integer;
  ms: TMemoryStream;
  Left, Top, Width, Height, CodecId, ScreenRowSize : Integer;
  mime: string;
  ms_decompressed: TMemoryStream;
  ImageSize, CompressedSize: Integer;
begin
  Result := false;
  FImage.Canvas.Lock;
  try
    for i := 0 to Integer(Rects.Count) - 1 do
      with Rects.asRecord[i] do
      begin
        mime    := asString['MIME'];
        if mime = '' then break;
        Result := true;
        Left    := asInteger['Left'];
        Top     := asInteger['Top'];
        Width   := asInteger['Width'];
        Height  := asInteger['Height'];
        CodecId := asInteger['Codec'];
        ImageSize       := asInteger['ImageSize'];
        CompressedSize  := asInteger['CompressedSize'];
        ms              := RTCByteStream(asByteStream['Data']);
        ms_decompressed := nil;
        try
          if CompressedSize > 0 then
            begin
              ms_decompressed := TMemoryStream.Create;
              ms_decompressed.Size := ImageSize;
              if not Assigned(FCompressor) then
                FCompressor := TCompressionLZMA2.Create(5);
              FCompressor.Decompress(ms.Memory, ms.Size, ms_decompressed.Memory, ms_decompressed.Size);
              ms := ms_decompressed;
            end;
          if (FImage.Height < 2) or (Cardinal(FImage.ScanLine[0]) <
             Cardinal(FImage.ScanLine[1])) then ScreenRowSize := 1 else
             ScreenRowSize := -1;
          ScreenRowSize := ScreenRowSize * ((FImage.Width * FSCreenBPP) shr 3);
          TRMXDecoder.Decode(ms, Image,
            Top * ScreenRowSize + ((Left * FScreenBPP) shr 3),
            ScreenRowSize,
            mime);
        finally
          if Assigned(ms_decompressed) then
            ms_decompressed.Free;
        end;
      end;
  finally
    FImage.Canvas.UnLock;
  end;
end;

function TRtcScreenDecoder.SetScreenData(const Data: RtcString): boolean;
var
  rec: TRtcRecord;
begin
  rec := TRtcRecord.FromCode(Data);
  try
    Result := SetScreenData(rec);
  finally
    rec.Free;
  end;
  if Assigned(FOnSetScreenData) then
    FOnSetScreenData(Self, Playback.LoginUserName, Data);
end;

procedure TRtcScreenDecoder.SetScreenInfo(const Info: TRtcRecord);
begin
  FScreenWidth := Info.asInteger['Width'];
  FScreenHeight := Info.asInteger['Height'];
  FScreenBPP := Info.asInteger['Bits'];
  //FBytesPerPixel := Info.asInteger['Bytes'];

 // if FBytesPerPixel = 0 then
  FBPPWidth := (FScreenWidth * FScreenBPP) shr 3;
  if (FScreenWidth * FScreenBPP) mod 8 <> 0 then Inc(FBPPWidth);

 // else
 //   FBPPWidth := FBytesPerPixel * FScreenWidth;

  FBlockSize := FBPPWidth * FScreenHeight;

  PrepareStorage;
end;

procedure TRtcScreenDecoder.PrepareStorage;
begin
  ReleaseStorage;

  FImage := CreateBitmap;
  SetLength(TempBuff, 8192 * 4 * 2);
end;

procedure TRtcScreenDecoder.ReleaseStorage;
begin
  if assigned(FImage) then
  begin
    SetLength(TempBuff, 0);
    FImage.Free;
    FImage := nil;
  end;
end;

function TRtcScreenDecoder.CreateBitmap: TBitmap;
begin
  Result := TBitmap.Create;
  With Result do
  Begin
    case FScreenBPP of
      1:
        PixelFormat := pf1bit;
      4:
        PixelFormat := pf4bit;
      8:
        PixelFormat := pf8bit;
      16:
        PixelFormat := pf16bit;
      24:
        PixelFormat := pf24bit;
      32:
        PixelFormat := pf32bit;
    End;
    Width := FScreenWidth;
    Height := FScreenHeight;
  End;
end;

procedure TRtcScreenDecoder.SetPalette(const s: RtcByteArray);
var
  lpPal: PLogPalette;
  myPal: HPALETTE;
begin
  if not assigned(FImage) then
    Exit;
  if length(s) = 0 then
    Exit;

  lpPal := @s[0];
  myPal := CreatePalette(lpPal^);

  with FImage do
  begin
    Canvas.Lock;
    try
      Palette := myPal;
    finally
      Canvas.Unlock;
    end;
  end;
end;

function TRtcScreenDecoder.SetScreenData(const Data: TRtcRecord): boolean;
var
  a: integer;
  Scr, Atr: TRtcArray;
begin
  FScreenInfoChanged := False;
  Result := False;
  if assigned(Data) then
  begin
    if Data.isType['res'] = rtc_Record then
    begin
      SetScreenInfo(Data.asRecord['res']);
      FScreenInfoChanged := True;
      Result := True;
    end;

    if Data.isType['pal'] = rtc_String then
    begin
      SetPalette(RtcStringToBytes(Data.asString['pal']));
      FScreenInfoChanged := True;
      Result := True;
    end;

    if not assigned(FImage) then
      Exit;

    if Data.isType['di'] = rtc_Array then
    begin
      Scr := Data.asArray['di'];
      Atr := Data.asArray['at'];
      if Scr.Count > 0 then
      begin
        Result := True;
        for a := 0 to Scr.Count - 1 do
          DecompressBlock3(Atr.asInteger[a], RtcStringToBytes(Scr.asString[a]));
      end;
    end
    else if Data.isType['pu'] = rtc_Array then
    begin
      Scr := Data.asArray['pu'];
      Atr := Data.asArray['at'];
      if Scr.Count > 0 then
      begin
        Result := True;
        for a := 0 to Scr.Count - 1 do
          DecompressBlock3(Atr.asInteger[a], RtcStringToBytes(Scr.asString[a]));
      end;
    end
    else if Data.isType['diff'] = rtc_Array then
    begin
      Scr := Data.asArray['diff'];
      Atr := Data.asArray['at'];
      if Scr.Count > 0 then
      begin
        Result := True;
        for a := 0 to Scr.Count - 1 do
          DecompressBlock2(Atr.asInteger[a], RtcStringToBytes(Scr.asString[a]));
      end;
    end
    else if Data.isType['put'] = rtc_Array then
    begin
      Scr := Data.asArray['put'];
      Atr := Data.asArray['at'];
      if Scr.Count > 0 then
      begin
        Result := True;
        for a := 0 to Scr.Count - 1 do
          DecompressBlock2(Atr.asInteger[a], RtcStringToBytes(Scr.asString[a]));
      end;
    end;

    if Data.isType['scrmr'] = rtc_Array then  // Screen Move Rects
    begin
      DrawMovedRects(Data.asArray['scrmr']);
      Result := true;
    end;

    if Data.isType['scrdr'] = rtc_Array then  // Screen Dirty Rects
    begin
      DrawDirtyRects(Data.asArray['scrdr']);
      Result := true;
    end;
  end;
end;

procedure TRtcScreenDecoder.DrawMovedRects(Rects : TRtcArray);
var
  i, Left, Top, Right, Bottom, PointX, PointY : integer;
begin
  FImage.Canvas.Lock;
  try
    for i := 0 to Integer(Rects.Count) - 1 do
      with Rects.asRecord[i] do
      begin
        Left := asInteger['Left']; Top := asInteger['Top'];
        Right := asInteger['Right']; Bottom := asInteger['Bottom'];
        PointX := asInteger['PointX']; PointY := asInteger['PointY'];

        FImage.Canvas.CopyRect(TRect.Create(Left, Top, Right, Bottom), FImage.Canvas,
          TRect.Create(PointX, PointY, PointX + Right - Left, PointY + Bottom - Top));
      end;
  finally
    FImage.Canvas.Unlock;
  end;
end;

procedure TRtcScreenDecoder.DrawDirtyRects(Rects : TRtcArray);
//const Left, Top, Width, Height, CodecId : Integer;
 //     MS : RtcByteStream);

var
  DataPos, ImagePos : PByte;
  RowSize, ScreenRowSize : Integer;

  Left, Top, Width, Height, CodecId : Integer;
  MS : RtcByteStream;
  i, RectId, RowId : Integer;
 // s : RTCByteArray;
  JPG : TJPEGImage;
  PNG : TPNGImage;
  MS2 : TMemoryStream;
  TmpBuff : array of byte;
begin
  if FixDrawDirtyRects(Rects) then
    Exit;

  FImage.Canvas.Lock;
 try
 //  CS.Enter;
  for i := 0 to Integer(Rects.Count) - 1 do
    with Rects.asRecord[i] do
    begin
       // IniF := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Settings.ini');
      //  CompressionType := IniF.ReadInteger('ScreenCapture', 'CompressionType', 0);
      //  IniF.Free;
      Left := asInteger['Left']; Top := asInteger['Top'];
      Width := asInteger['Width']; Height := asInteger['Height'];
      CodecId := asInteger['Codec'];
      MS := RTCByteStream(asByteStream['Data']);
      //Debug.Log('Writing area (' + IntToStr(Left) + ', ' +
       // IntToStr(Top) + ', ' + IntToStr(Left + Width) + ', ' +
        //  IntToStr(Top + Height) + ')   BMW '
        // + IntToStr(FImage.WIdth) + ' BMH ' + IntToStr(FImage.Height) + ', ');

    //  MS.Position := 0;
      MS2 := NIL;

     if CodecId in [5, 6, 7] then
     begin
       //s := NIL;
       //SetLength(s, (Width * Height * FSCreenBPP) shr 3);
       MS2 := TMemoryStream.Create;
       MS2.SetSize((Width * Height * FSCreenBPP) shr 3);
     //  var
      //   OrSize : integer := (PInteger(MS.Memory))^;
       case CodecId of
         5: TLZ4.Decode(MS.Memory, MS2.Memory, MS.Size, MS2.Size);
         6: TLZ4.Stream_Decode(MS.Memory, MS2.Memory, MS.Size, MS2.Size);
         7:;
       end;

       //DWordDecompress(MS.Memory, MS2.Memory, 0, MS.Size, MS2.Size);
       MS := MS2;
       //SetLength(s, 0);
       //  s := s2;
     end;

 {     if CodecId = 4 then
      begin
        if (Height < 2) or (Cardinal(FImage.ScanLine[0]) <
           Cardinal(FImage.ScanLine[1])) then ScreenRowSize := 1 else
           ScreenRowSize := -1;
        ImagePos := PByte(FImage.ScanLine[0]);
        ScreenRowSize := ScreenRowSize * ((FImage.Width * FSCreenBPP) shr 3);
        Inc(ImagePos, Top * ScreenRowSize + ((Left * FScreenBPP) shr 3));

        //MS.Position := 0;
        //MS.SaveToFile('D:\1.webp');
        TRtcWebPCodec.DeCompressImage(MS.Memory, MS.Size, ImagePos,// PByte(FImage.ScanLine[0]),//ImagePos,
          Height * ((FImage.Width * FSCreenBPP) shr 3), ScreenRowSize);

       (*SetLength(TmpBuff, Width * Height * 5);

       TWebPCodec.DeCompressImage(MS.Memory, MS.Size, @TmpBuff[0],//ImagePos,// PByte(FImage.ScanLine[0]),//ImagePos,
          Height * ((FImage.Width * FSCreenBPP) shr 3),
          //ScreenRowSize
          (Width * FSCreenBPP) shr 3);

        if (Height < 2) or (Cardinal(FImage.ScanLine[0]) <
           Cardinal(FImage.ScanLine[1])) then ScreenRowSize := 1 else
           ScreenRowSize := -1;
         ImagePos := PByte(FImage.ScanLine[0]);
         ScreenRowSize := ScreenRowSize * ((FImage.Width * FSCreenBPP) shr 3);
         Inc(ImagePos, Top * ScreenRowSize + ((Left * FScreenBPP) shr 3));
         DataPos := @TmpBuff[0];
         RowSize := ((Width * FScreenBPP) shr 3);
         for RowId := 0 to Height - 1 do
         begin
           Move(DataPos^, ImagePos^, RowSize);
           Inc(ImagePos, ScreenRowSize);
           Inc(DataPos, RowSize);
         end;

         SetLength(TmpBuff, 0); *)



          //(FImage.Width * FSCreenBPP) shr 3);
     //   WebPDecodeRGBIntoFunc(MS.Memory, MS.Size, ImagePos,
       //   Height * ((FImage.Width * FSCreenBPP) shr 3),
         // (FImage.Width * FSCreenBPP) shr 3);

      // FImage.Canvas.Unlock;
      end;}

      if CodecId = 3 then
      begin
        PNG := TPNGImage.Create;
        PNG.LoadFromStream(MS);
        PNG.Transparent := false;
        //JPG.SaveToFile('d:\aaa.jpg');
       // JPG.DIBNeeded;
        //PNG.DrawUsingPixelInformation(FImage.Canvas, TPoint.Create(Left, Top));
      //  FImage.Canvas.Lock;
        PNG.Draw(FImage.Canvas, TRect.Create(Left, Top,
          Left + Width, Top + Height));

//      if MinuteOf(Now) >= 13 then
//        PNG.SaveToFile('C:\Screenshots\Codec_3_' + FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.png');
//        FImage.SaveToFile('C:\Screenshots\Codec_3_' + FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now) + '.bmp');

       // FImage.Canvas.UnLock;
        PNG.Free;
      end;

      if CodecId = 2 then
      begin
        JPG := TJPEGImage.Create;
        JPG.Scale := jsFullSize;
        JPG.LoadFromStream(MS);
        //JPG.SaveToFile('d:\aaa.jpg');
       // JPG.DIBNeeded;
        FImage.Canvas.Draw(Left, Top, JPG);
        JPG.Free;
      end;

     if CodecId = 1 then
     begin
      //s := NIL;
      //SetLength(s, (Width * Height * FSCreenBPP) shr 3);
      MS2 := TMemoryStream.Create;
      MS2.SetSize((Width * Height * FSCreenBPP) shr 3);
      DWordDecompress(MS.Memory, MS2.Memory, 0, MS.Size, MS2.Size);
      MS := MS2;
      //SetLength(s, 0);
     //  s := s2;
     end;

     if CodecId in [0, 1, 5, 6, 7] then
     begin
      //Width, 100; Height := 100;
         if (FImage.Height < 2) or (Cardinal(FImage.ScanLine[0]) <
           Cardinal(FImage.ScanLine[1])) then ScreenRowSize := 1 else
           ScreenRowSize := -1;
         ImagePos := PByte(FImage.ScanLine[0]);
         ScreenRowSize := ScreenRowSize * ((FImage.Width * FSCreenBPP) shr 3);
         Inc(ImagePos, Top * ScreenRowSize + ((Left * FScreenBPP) shr 3));
         DataPos := MS.Memory;
         RowSize := ((Width * FScreenBPP) shr 3);
         for RowId := 0 to Height - 1 do
         begin
          Move(DataPos^, ImagePos^, RowSize); //������ ��
          Inc(ImagePos, ScreenRowSize);
          Inc(DataPos, RowSize);
         end;
     end;
    if Assigned(MS2) then MS2.Free;
  end;

 // CS.Leave;
  finally
    FImage.Canvas.UnLock;
  end;

 // if CompressionType = 1 then setlength(S, 0);


  //Image.SaveToFile('d:\aaa.bmp')
end;


procedure TRtcScreenDecoder.DecompressBlock(const Offset: longint;
  const s: RtcByteArray);
begin
  if length(s) > 0 then
    if not DWordDecompress(Addr(s[0]), BitmapDataPtr(FImage), Offset, length(s),
      FBlockSize - Offset) then
      raise Exception.Create('Error decompressing image');
end;

procedure TRtcScreenDecoder.DecompressBlock2(const Offset: longint;
  const s: RtcByteArray);
begin
  if length(s) > 0 then
    if not DWordDecompress(Addr(s[0]), BitmapDataPtr2(FImage, Offset), 0,
      length(s), FBlockSize - Offset) then
      raise Exception.Create('Error decompressing image');
end;

procedure TRtcScreenDecoder.DecompressBlock3(const Offset: longint;
  const s: RtcByteArray);
begin
  if length(s) > 0 then
    if not DWordDecompress_New(Addr(s[0]), BitmapDataPtr2(FImage, Offset),
      Addr(TempBuff[0]), 0, length(s), FBlockSize - Offset) then
      raise Exception.Create('Error decompressing image');
end;

{ - TRtcScreenPlayback - }

constructor TRtcScreenPlayback.Create;
begin
  inherited;
  ScrOut := TRtcScreenDecoder.Create;
  ScrOut.Playback := Self;

  FCursorVisible := False;
  FLoginUserName := '';
end;

destructor TRtcScreenPlayback.Destroy;
begin
  if assigned(FCursorImage) then
  begin
    FCursorImage.Free;
    FCursorImage := nil;
  end;
  if assigned(FCursorMask) then
  begin
    FCursorMask.Free;
    FCursorMask := nil;
  end;
  ScrOut.Free;
  inherited;
end;

function TRtcScreenPlayback.PaintScreen(const s: RtcString): boolean;
var
  rec: TRtcRecord;
  Tick : UInt64;
begin
  if s = '' then
  begin
    Result := False;
    Exit;
  end;


  {$IFDEF DEBUG}
  rec := TRtcRecord.FromCode(s);
  try
    with rec do
      if isType['scrfs'] = rtc_Record then  // Screen Frame Stat
      begin
        FCapLat := asRecord['scrfs'].asInteger['CapLat'];
        FEncLat := asRecord['scrfs'].asInteger['EncLat'];
      end else
      begin
        FCapLat := -1;
        FEncLat := -1;
      end;
  finally
    rec.Free;
  end;

  Tick := Debug.GetMCSTick;
  {$ENDIF}

  Result := ScrOut.SetScreenData(s);

  {$IFDEF DEBUG}
  FDecLat := Debug.GetMCSTick - Tick;
  {$ENDIF}
end;

function TRtcScreenPlayback.GetScreen: TBitmap;
begin
  Result := ScrOut.Image;
end;

function TRtcScreenPlayback.PaintCursor(const s: RtcString): boolean;
var
  rec: TRtcRecord;
  icinfo: TIconInfo;
  hc: HICON;
begin
  Result := False;
  if s = '' then
    Exit;

  rec := TRtcRecord.FromCode(s);
  try
    if (rec.isType['X'] <> rtc_Null) or (rec.isType['Y'] <> rtc_Null) then
    begin
      if FCursorVisible then
      begin
        FCursorOldX := FCursorX;
        FCursorOldY := FCursorY;
      end
      else
      begin
        FCursorOldX := rec.asInteger['X'];
        FCursorOldY := rec.asInteger['Y'];
      end;
      FCursorX := rec.asInteger['X'];
      FCursorY := rec.asInteger['Y'];
      if FCursorUser <> rec.asText['U'] then
        Result := True // changing user
      else
        Result := (FCursorX <> FCursorOldX) or (FCursorY <> FCursorOldY);
      FCursorUser := rec.asText['U'];
    end;
    if (rec.isType['V'] <> rtc_Null) and (rec.asBoolean['V'] <> FCursorVisible)
    then
    begin
      Result := True;
      FCursorVisible := rec.asBoolean['V'];
    end;
    if rec.isType['C'] <> rtc_Null then
    begin
      if not FCursorStd or (FCursorShape <> -rec.asInteger['C']) then
      begin
        Result := True;
        FCursorShape := -rec.asInteger['C'];
        FCursorStd := True;

        hc := Screen.Cursors[FCursorShape];
        if GetIconInfo(hc, icinfo) then
        begin
          FCursorHotX := icinfo.xHotspot;
          FCursorHotY := icinfo.yHotspot;

          if assigned(FCursorImage) then
          begin
            FCursorImage.Free;
            FCursorImage := nil;
          end;
          if assigned(FCursorMask) then
          begin
            FCursorMask.Free;
            FCursorMask := nil;
          end;

          if icinfo.hbmColor <> INVALID_HANDLE_VALUE then
          begin
            FCursorImage := TBitmap.Create;
            FCursorImage.Handle := icinfo.hbmColor;
          end;

          if icinfo.hbmMask <> INVALID_HANDLE_VALUE then
          begin
            FCursorMask := TBitmap.Create;
            FCursorMask.Handle := icinfo.hbmMask;
            FCursorMask.PixelFormat := pf4bit;
          end;
        end;
      end;
    end
    else if rec.isType['HX'] <> rtc_Null then
    begin
      Result := True;
      FCursorShape := 0;
      FCursorStd := False;

      FCursorHotX := rec.asInteger['HX'];
      FCursorHotY := rec.asInteger['HY'];

      if assigned(FCursorImage) then
      begin
        FCursorImage.Free;
        FCursorImage := nil;
      end;
      if assigned(FCursorMask) then
      begin
        FCursorMask.Free;
        FCursorMask := nil;
      end;

      if (rec.isType['I'] = rtc_ByteStream) then
      begin
        FCursorImage := TBitmap.Create;
        FCursorImage.LoadFromStream(rec.asByteStream['I']);
      end;

      if (rec.isType['M'] = rtc_ByteStream) then
      begin
        FCursorMask := TBitmap.Create;
        FCursorMask.LoadFromStream(rec.asByteStream['M']);
      end;
    end;
    if rec.isType['cr'] = rtc_Integer then
      FCursorSever := rec.asInteger['cr']
    else
      FCursorSever := crDefault;
  finally
    rec.Free;
  end;
end;

end.
