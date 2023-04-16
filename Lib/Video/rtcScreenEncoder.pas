{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rtcScreenEncoder;

interface
{$INLINE AUTO}


//{$INCLUDE rtcDefs.inc}
//{$INCLUDE rtcPortalDefs.inc}
{$POINTERMATH ON}


uses
  Windows, Classes, //Messages, rtcSystem,
  System.Types, SysUtils, Graphics, Forms, //Controls, Forms, rtcpDesktopHost,
  Math, Vcl.Dialogs, System.SyncObjs, Execute.DesktopDuplicationAPI,
  rtcInfo, rtcLog,// rtcZLib, SyncObjs, rtcScrUtils,
  ServiceMgr, CommonData, uVircessTypes,
  rtcCompress, Vcl.Imaging.JPEG, Vcl.Imaging.PNGImage, //RtcWebPCodec,//rtcXJPEGEncode,
   {$IFDEF WithSynLZTest} SynLZ, {$ENDIF} lz4d, lz4d.lz4, lz4d.lz4s,
 {ServiceMgr,} rtcWinLogon;

type
  TRtcScreenEncoder = class
  private
    DataCS : TCriticalSection;
    HelperCS: TCriticalSection;

    FDesktopDuplicator: TDesktopDuplicationWrapper;

    CodecId, Codec2Param1, Codec3Param1, Codec4Param1, Codec4Param2 : Integer;


    FFullScreen : Boolean;
    FDirtyRCnt, FMovedRCnt : Integer;
    FDirtyR: array [0..10000] of TRect;
    FMovedR: array [0..10000] of TRect;
    FMovedRP: array [0..10000] of TPoint;
    FScreenWidth, FScreenHeight, FBitsPerPixel, FMouseFlags, FMouseCursor, FMouseX, FMouseY: Integer;
    FClipRect: TRect;
    FScreenBuff: PByte;
    FScreenInfoChanged : Boolean;

    FHaveScreen: Boolean;
    FOnHaveScreenChanged: TNotifyEvent;
    HelperIOData: THelperIOData;

    function GetScreenWidth: Integer;
    function GetScreenHeight: Integer;
    function GetBitsPerPixel: Integer;
    function GetMouseFlags: Integer;
    function GetMouseCursor: Integer;
    function GetDirtyRCnt: Integer;
    function GetMovedRCnt: Integer;
    procedure SetDirtyRCnt(Value: Integer);
    procedure SetMovedRCnt(Value: Integer);
    function GetDirtyR(Index: Integer): TRect;
    function GetMovedR(Index: Integer): TRect;
    function GetMovedRP(Index: Integer): TPoint;
    procedure SetDirtyR(Index: Integer; const Value: TRect);
    procedure SetMovedR(Index: Integer; const Value: TRect);
    procedure SetMovedRP(Index: Integer; const Value: TPoint);
    function GetClipRect: TRect;
    procedure SetClipRect(Value: TRect);
    function GetScreenInfoChanged: Boolean;

    procedure EncodeImage(Rec : TRtcRecord; Rect : TRect);

    function GetDataFromHelper(OnlyGetScreenParams: Boolean = False; fFirstScreen: Boolean = False): Boolean;

    function GetHaveScreen: Boolean;
    procedure SetHaveScreen(const Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
  //  function GetFrame(NeedFullCapture : Boolean): Boolean;

    procedure GrabScreen(ScrDelta : PString; ScrFull : PString = NIL);

    property ScreenWidth: Integer read GetScreenWidth;
    property ScreenHeight: Integer read GetScreenHeight;
    property BitsPerPixel: Integer read GetBitsPerPixel;
    property MouseFlags: Integer read GetMouseFlags;
    property MouseCursor: Integer read GetMouseCursor;
    property DirtyRCnt: Integer read GetDirtyRCnt write SetDirtyRCnt;
    property MovedRCnt: Integer read GetMovedRCnt write SetMovedRCnt;
    property DirtyR[Index: Integer]: TRect read GetDirtyR write SetDirtyR;
    property MovedR[Index: Integer]: TRect read GetMovedR write SetMovedR;
    property MovedRP[Index: Integer]: TPoint read GetMovedRP write SetMovedRP;
    property ClipRect: TRect read GetClipRect write SetClipRect;
    property ScreenInfoChanged: Boolean read GetScreenInfoChanged;

    property HaveScreen: Boolean read GetHaveScreen write SetHaveScreen;
    property OnHaveScreeenChanged: TNotifyEvent read FOnHaveScreenChanged write FOnHaveScreenChanged;
  end;

implementation
uses RtcDebug, IniFiles;

type
  TRtcCaptureMode=(captureEverything, captureDesktopOnly);

var
  RtcCaptureMode:TRtcCaptureMode=captureEverything;
  RTC_CAPTUREBLT: DWORD = $40000000;

//function WebPEncodeLosslessRGB(const rgb: PByte; width, height, stride: Integer;
 // quality_factor: single; var output: PByte): Cardinal; cdecl; external 'libwebp.dll';

//function WebPDecodeRGBInto(const data: PByte; data_size: Cardinal;
//  output_buffer: PByte; output_buffer_size, output_stride: Integer): PByte;
//  cdecl; external 'libwebp.dll';


{uses Types;

function GetBitsPerPixel(aBitsPerPixel: TPixelFormat): Word;
begin
  case aBitsPerPixel of
    pf1bit: Result := 1;
    pf4bit: Result := 4;
    pf8bit: Result := 8;
    pf15bit: Result := 15;
    pf16bit: Result := 16;
    pf24bit: Result := 24;
    pf32bit: Result := 32;
    else Result := 32;
  end;
end;
 }

function TRtcScreenEncoder.GetHaveScreen: Boolean;
begin
  Result := FHaveScreen;
end;

procedure TRtcScreenEncoder.SetHaveScreen(const Value: Boolean);
begin
  if FHaveScreen <> Value then
  begin
    FHaveScreen := Value;
    if Assigned(FOnHaveScreenChanged) then
      FOnHaveScreenChanged(Self);
  end;
end;

function TRtcScreenEncoder.GetScreenInfoChanged: Boolean;
begin
  if IsService then
    Result := FScreenInfoChanged
  else
    Result := FDesktopDuplicator.ScreenInfoChanged;
end;

function TRtcScreenEncoder.GetScreenWidth: Integer;
begin
  if IsService then
    Result := FScreenWidth
  else
    Result := FDesktopDuplicator.ScreenWidth;
end;

function TRtcScreenEncoder.GetScreenHeight: Integer;
begin
  if IsService then
    Result := FScreenHeight
  else
    Result := FDesktopDuplicator.ScreenHeight;
end;

function TRtcScreenEncoder.GetBitsPerPixel: Integer;
begin
  if IsService then
    Result := FBitsPerPixel
  else
    Result := FDesktopDuplicator.BitsPerPixel;
end;

function TRtcScreenEncoder.GetMouseFlags: Integer;
begin
  if IsService then
    Result := FMouseFlags
  else
    Result := FDesktopDuplicator.MouseFlags;
end;

function TRtcScreenEncoder.GetMouseCursor: Integer;
begin
  if IsService then
    Result := FMouseCursor
  else
    Result := FDesktopDuplicator.MouseCursor;
end;

function TRtcScreenEncoder.GetClipRect: TRect;
begin
  if IsService then
    Result := FClipRect
  else
    Result := FDesktopDuplicator.ClipRect;
end;

procedure TRtcScreenEncoder.SetClipRect(Value: TRect);
begin
  if IsService then
    FClipRect := Value
  else
    FDesktopDuplicator.ClipRect := Value;
end;

function TRtcScreenEncoder.GetMovedRCnt: Integer;
begin
  if IsService then
    Result := FMovedRCnt
  else
    Result := FDesktopDuplicator.MovedRCnt;
end;

procedure TRtcScreenEncoder.SetMovedRCnt(Value: Integer);
begin
  if IsService then
    FMovedRCnt := Value
  else
    FDesktopDuplicator.MovedRCnt := Value;
end;

function TRtcScreenEncoder.GetDirtyRCnt: Integer;
begin
  if IsService then
    Result := FDirtyRCnt
  else
    Result := FDesktopDuplicator.DirtyRCnt;
end;

procedure TRtcScreenEncoder.SetDirtyRCnt(Value: Integer);
begin
  if IsService then
    FDirtyRCnt := Value
  else
    FDesktopDuplicator.DirtyRCnt := Value;
end;

function TRtcScreenEncoder.GetDirtyR(Index: Integer): TRect;
begin
  if IsService then
    Result := FDirtyR[Index]
  else
    Result := FDesktopDuplicator.DirtyR[Index];
end;

procedure TRtcScreenEncoder.SetDirtyR(Index: Integer; const Value: TRect);
begin
  if IsService then
    FDirtyR[Index] := Value
  else
    FDesktopDuplicator.DirtyR[Index] := Value;
end;

function TRtcScreenEncoder.GetMovedR(Index: Integer): TRect;
begin
  if IsService then
    Result := FMovedR[Index]
  else
    Result := FDesktopDuplicator.MovedR[Index];
end;

procedure TRtcScreenEncoder.SetMovedR(Index: Integer; const Value: TRect);
begin
  if IsService then
    FMovedR[Index] := Value
  else
    FDesktopDuplicator.MovedR[Index] := Value;
end;

function TRtcScreenEncoder.GetMovedRP(Index: Integer): TPoint;
begin
  if IsService then
    Result := FMovedRP[Index]
  else
    Result := FDesktopDuplicator.MovedRP[Index];
end;

procedure TRtcScreenEncoder.SetMovedRP(Index: Integer; const Value: TPoint);
begin
  if IsService then
    FMovedRP[Index] := Value
  else
    FDesktopDuplicator.MovedRP[Index] := Value;
end;

function IsWindows8orLater: Boolean;
begin
  Result := False;

  if Win32MajorVersion > 6 then
    Result := True;
  if Win32MajorVersion = 6 then
    if Win32MinorVersion >= 2 then
      Result := True;
end;

constructor TRtcScreenEncoder.Create;
var
 i : integer;
begin
  FDesktopDuplicator := TDesktopDuplicationWrapper.Create();

  FDesktopDuplicator.ClipRect := TRect.Create(0, 0, 0, 0);

  DataCS := TCriticalSection.Create;
  HelperCS := TCriticalSection.Create;

  {
  GetMem(ScreenBuff, 1 shl 25);

  for i := 0 to 1280 * 1024 do
  begin
    ScreenBuff[i * 4 + 0] := i and 255;
    ScreenBuff[i * 4 + 1] := i and 255;
    ScreenBuff[i * 4 + 2] := i and 255;
    ScreenBuff[i * 4 + 3] := 255;
  end; }
  //FillChar(ScreenBuff^, 1 shl 25, 0);

//  GrabScreen(NIL, NIL);
 // ShowMessage('EncCreate');
  Debug.Log('-------------------------------------------------------------');
  Debug.Log('TRtcEncoder Created');
end;

destructor TRtcScreenEncoder.Destroy;
begin
  FreeAndNil(FDesktopDuplicator);

  HelperCS.Free;
  DataCS.Free;
end;

procedure TRtcScreenEncoder.EncodeImage(Rec : TRtcRecord; Rect : TRect);
var
  Image, PackedImage : RtcByteArray;
  DataPos : PByte;
  ImagePos : PByte;
  RectId, RowId, Len, DataSize : Integer;
  RowSize, ScreenRowSize : Integer;

  MS : TMemoryStream;
  FS : TFileStream;
  Bmp : TBitmap;
  JPG : TJPEGImage;
  PNG : TPNGImage;
begin
 // if (ImageCompressionType < 1) or (ImageCompressionType > 2) then
  //  ImageCompressionType := 1;
  //!!!!!!!!!!!!with Debug.ScreenCapture do
  begin
    Debug.Log('Encoding image CodecId ' + IntToStr(CodecId) + ' (' + IntToStr(Rect.Left) + ',' +
      IntToStr(Rect.Top) + ',' + IntToStr(Rect.Right) + ',' + IntToStr(Rect.Bottom) + ')' );

    if CodecId in [0, 1, 5, 6, 7] then
    begin // No compression, passing bitmap
      SetLength(Image, (Rect.Width * Rect.Height * BitsPerPixel) shr 3);
      ImagePos := FScreenBuff +
                ((Rect.Top * ScreenWidth + Rect.Left) * BitsPerPixel) shr 3;
                 DataPos := @Image[0];
              //  if (Rect.Height < 2) or (Cardinal(Bmp.ScanLine[0]) <
               //   Cardinal(Bmp.ScanLine[1])) then RowSize := 1 else
               // RowSize := -1;

              RowSize := (Rect.Width * BitsPerPixel) shr 3;
              ScreenRowSize := (ScreenWidth * BitsPerPixel) shr 3;
              for RowId := 0 to Rect.Height - 1 do
              begin
                Move(ImagePos^, DataPos^, Abs(RowSize));
                Inc(ImagePos, ScreenRowSize);
                Inc(DataPos, RowSize);
              end;

           // Move();
            //SetLength(PackedImage, RowSize * Rect.Height);
    end;

    {if ImageCompressionType = 1 then
    begin
    if (Rect.Height < 2) or (Cardinal(Bmp.ScanLine[0]) then
      PackedImage := Bmp.ScanLine[0]; else
      PackedImage := Bmp.ScanLine[Bmp.Height - 1];
    end;}

    MS := TMemoryStream.Create;

    if CodecId = 0 then
    begin
      MS.SetSize(Length(Image));
      MS.WriteData(Image, Length(Image));
     // PackedImage := Image;
    end;

    if CodecId = 1 then
    begin
      PackedImage := NIL;
      SetLength(PackedImage, ((Rect.Width * Rect.Height * BitsPerPixel) shr 3) * 3);
   {  if (Rect.Height < 2) or (Cardinal(Bmp.ScanLine[0]) < Cardinal(Bmp.ScanLine[1]))
        then Len := DWordCompress_Normal(Bmp.ScanLine[0], Addr(PackedImage[0]),
      (Rect.Height * Rect.Width * BitsPerPixel) shr 3)
         else Len := DWordCompress_Normal(Bmp.ScanLine[Bmp.Height - 1], Addr(PackedImage[0]),
      (Rect.Height * Rect.Width * BitsPerPixel) shr 3);
    }
      Len := DWordCompress_Normal(Addr(Image[0]), Addr(PackedImage[0]),
        (Rect.Height * Rect.Width * BitsPerPixel) shr 3);

    //SetLength(PackedImage, Len);
      MS.SetSize(Len);
      MS.WriteData(PackedImage, Len);
     // SetLength(Image, 0);
    end;

    if CodecId in [2, 3] then
    begin
      Bmp := TBitmap.Create;
      Bmp.PixelFormat := pf32bit;
      Bmp.SetSize(Rect.Width, Rect.Height);
      ImagePos := FScreenBuff + ((Rect.Top * ScreenWidth +
        Rect.Left) * BitsPerPixel) shr 3;
      DataPos := Bmp.ScanLine[0];
      if (Rect.Height < 2) or (Cardinal(Bmp.ScanLine[0]) <
                  Cardinal(Bmp.ScanLine[1])) then
                   RowSize := 1 else RowSize := -1;

      RowSize := RowSize * ((Rect.Width * BitsPerPixel) shr 3);
      ScreenRowSize := (ScreenWidth * BitsPerPixel) shr 3;
      for RowId := 0 to Rect.Height - 1 do
      begin
        Move(ImagePos^, DataPos^, Abs(RowSize));
        Inc(ImagePos, ScreenRowSize);
        Inc(DataPos, RowSize);
      end;
    end;

    if CodecId = 2 then
    begin
      //bmp.SaveToFile('d:\bbb.bmp');
      JPG := TJPEGImage.Create;
     // Bmp.Dormant;
      JPG.Assign(Bmp);
     // JPG.JPEGNeeded;
      // JPG.Compress;
      JPG.ProgressiveEncoding := false;
      JPG.CompressionQuality := Codec2Param1;
      //MS.Position := 0;
      JPG.SaveToStream(MS);
      // JPG.SaveToFile('d:\bbb.jpg');
      JPG.Free;
      Bmp.Free;
    end;

    if CodecId = 3 then
    begin
      //bmp.SaveToFile('d:\bbb.bmp');
      PNG := TPNGImage.Create;
      // Bmp.Dormant;
      PNG.Assign(Bmp);
      PNG.CompressionLevel := Codec3Param1;
      //MS.Position := 0;
      PNG.SaveToStream(MS);
      // JPG.SaveToFile('d:\bbb.jpg');
      PNG.Free;
      Bmp.Free;
    end;

{    if (CodecId = 4) and (ScreenHeight >= 4) then
    begin

    //  DataPos := @(TempBuff[0]);

    //  Len := WebPEncodeLosslessRGBFunc(ScreenBuff + ((Rect.Top * ScreenWidth +
    //    Rect.Left) * BitsPerPixel) shr 3, Rect.Width, Rect.Height,
     //  (ScreenWidth * BitsPerPixel) shr 3, Codec4Param1, DataPos);
       // @(TempBuff[0]));

     //if Rect.Height < 16 then Rect.Top := Min(Integer(Rect.Top) - 16, 0);
     //if Rect.Height < 16 then Rect.Height := 16;


      if Rect.Height < 16 then
      begin
        Rect.Top := Max(0, Rect.Top - (16 - Rect.Height));
        Rect.Height := 16;
      end;

//       if Rect.Top > 16 then
//       begin
//         Rect.Height := 16;
//         Rect.Top := Rect.Top - (16 - Rect.Height);
//         Rect.Height := 16;
//       end else
//       begin
//         Rect.Height := 16;
//       end;

     // выравнивание по 32 байтам чтобы внутренние алгоритмы кодека могли с ним работать

      DataSize := 1 shl 25;
      GetMem(DataPos, DataSize);

      TRtcWebPCodec.SetComprParams(Codec4Param1, Codec4Param2);
      Len := TRtcWebPCodec.CompressImage(ScreenBuff, (ScreenWidth * BitsPerPixel) shr 3,
        Rect, DataPos, DataSize);

      //  if Len = 0 then ShowMessage('Len=0');

//     if (Rect.Width > 100) and (Rect.Height > 100) then
//       begin
//       FS := TFileStream.Create('c:\out\img' + IntToStr(FInd) + '.webp', fmCreate);
//       FS.Write(DataPos^, Len);
//       FS.Free;
//       Inc(FInd);
//       end;
      // TWebPCodec.
       MS.WriteData(DataPos, Len);

       FreeMem(DataPos);
    end;}

    if CodecId in [5, 6, 7] then
    begin
       PackedImage := NIL;
      SetLength(PackedImage, ((Rect.Width * Rect.Height * BitsPerPixel) shr 3) * 3);
      case CodecId of
        5:   Len :=  TLZ4.Encode(Addr(Image[0]), Addr(PackedImage[0]),
          (Rect.Height * Rect.Width * BitsPerPixel) shr 3, ((Rect.Width * Rect.Height * BitsPerPixel) shr 3) * 3);
        6: Len := TLZ4.Stream_Encode( Addr(Image[0]), Addr(PackedImage[0]),
          (Rect.Height * Rect.Width * BitsPerPixel) shr 3, ((Rect.Width * Rect.Height * BitsPerPixel) shr 3) * 3
           ,sbs4MB, False );
        7: ;//SynLZcompress1asm(;
      end;

      MS.SetSize(Len);
      MS.WriteData(PackedImage, Len);
    end;

    with Rec, Rect do
    begin
      asInteger['Left'] := Left;
      asInteger['Top'] := Top;
      asInteger['Width'] := Width;
      asInteger['Height'] := Height;
      asInteger['Codec'] := CodecId;
      MS.Seek(0, SOBeginning);
      asByteStream['Data'] := MS;

      PackedImage := NIL;
    end;

    MS.Free;
  end;
  //SetLength(Image);
end;

procedure TRtcScreenEncoder.GrabScreen(ScrDelta : PString; ScrFull : PString = NIL);
var
  Rec : TRtcRecord;
  Str : RtcString;
  InfoChanged : Boolean;
  RectId : Integer;
  F : TextFile;
  CurTick, CapLat, EncLat : UInt64;
  IniF: TIniFile;
  time: DWORD;
begin
//  DataCS.Enter;

  if Assigned(ScrFull) then
  begin
    FScreenWidth := 0; FScreenHeight := 0;
    // Сбрасываем информацию о экране
  end;

time := GetTickCount;

  //ShowMessage('GrabScreen');
  {$IFDEF DEBUG}
    CurTick := Debug.GetMCSTick;
  {$ENDIF}

//  IsService := True;
  if IsService then
  begin
//    time := GetTickCount;
    GetDataFromHelper;
//    time := GetTickCount - time;

//    DataCS.Leave;
  end
  else
  begin
    if not FDesktopDuplicator.DDCaptureScreen then
    begin
//      DataCS.Leave;

      ScrDelta^ := '';
      if Assigned(ScrFull) then ScrFull^ := '';

      Exit;
    end;
//    else
//      DataCS.Leave;

    FScreenBuff := FDesktopDuplicator.ScreenBuff;
  end;

  InfoChanged := ScreenInfoChanged;
  {$IFDEF DEBUG}
  if InfoChanged then
    Debug.Log('ScreenInfo Changed to ' + IntToStr(FScreenWidth) + 'x' +
      IntToStr(FScreenHeight) + 'x' + IntToStr(FBitsPerPixel));
  {$ENDIF}

  {$IFDEF DEBUG}
  CapLat := Debug.GetMCSTick - CurTick;
  {$ENDIF}
// Assert((ScreenBuff and 31) = 0, 'Unable to load libwebp_debug.dll or libsharpyuv_debug.dll from path ' + ExtractFilePath(Application.ExeName));


 //ShowMessage('DDRecieved');
//  InfoChanged := FDesktopDuplicator.ScreenInfoChanged;
//  DDRecieveRects;

 {
   BitsPerPixel := 32;
  ClipRect := TRect.Create(0, 0, 1280, 1024);
  InfoChanged := true;
  DirtyRCnt := 1;
  DirtyR[0] := ClipRect;
  }

  CodecId := 5;
  Codec2Param1 := 0;
  Codec3Param1 := 1;
  Codec4Param1 := 0;
  Codec4Param2 := 0;

 // AssignFile(F, ExtractFilePath(Application.ExeName) + 'webp.txt');
 // Reset(F);
 // Read(F, Codec4Param1, Codec4Param2);
 // CloseFile(F);

 // CodecId := 4;
 // Codec4Param1 := 20;//IniF.ReadInteger('ScreenCapture', 'Codec4Param1', 50);
 // Codec4Param2 := 0;//IniF.ReadInteger('ScreenCapture', 'Codec4Param2', 3);


// // InfoChanged := true;

{  IniF := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'debug.ini');
//
 with IniF do
  begin
    CodecId := ReadInteger('ScreenCapture', 'CodecId', 1);
//  if ScreenCapture.CodecId < 0 then
//  begin
//   // ShowMessage('Unable to open "' + IniF.FileName + '"');
//    Application.Terminate;
//    CodecId := 0;
//  end;

    Codec2Param1 := ReadInteger('ScreenCapture', 'Codec2Param1', 0);
    Codec3Param1 := ReadInteger('ScreenCapture', 'Codec3Param1', 0);
    Codec4Param1 := ReadInteger('ScreenCapture', 'Codec4Param1', 0);
    Codec4Param2 := ReadInteger('ScreenCapture', 'Codec4Param2', 0);
  end;
//
  IniF.Free;}

  if InfoChanged or Assigned(ScrFull) then
  begin
    Rec := TRtcRecord.Create;
    with Rec.newRecord('res') do//Res.newRecord('res') do
    begin
      asInteger['Width'] := ClipRect.Width;//ScreenDD.ScreenWidth;
      asInteger['Height'] := ClipRect.Height;//ScreenDD.ScreenHeight;
      asInteger['Bits'] := BitsPerPixel;
      //if FullScreen then FScreenRect := ClipRect;
         // asInteger['BytesPerPixel'] := BytesPerPixel;
    end;

    //Debug.Log('Encoding full screen1');

   // DirtyRCnt := 1;
   // DirtyR[0] := ClipRect;
   {$IFDEF DEBUG}
    CurTick := Debug.GetMCSTick;
   {$ENDIF}
    //Debug.Log('Encoding full screen2');

    EncodeImage(Rec.newArray('scrdr').NewRecord(0){AsRecord[0]}, ClipRect);

    {$IFDEF DEBUG}
      EncLat := Debug.GetMCSTick - CurTick;

      with Rec.newRecord('scrfs') do
      begin
        asInteger['CapLat'] := CapLat;
        asInteger['EncLat'] := EncLat;
      end;
      {$ENDIF}

    Debug.Log('Encoded full screen');

    Str := Rec.toCode;
    //Arr := Rec.asArray['scr'].AsRecord[0].asByteArray['Data'];
    //SetLength(Arr, 0);
    Rec.Free;

   // ShowMessage('FullScreen');

    if Assigned(ScrFull) then ScrFull^ := Str;
  end;


  if Assigned(ScrDelta) then
    if InfoChanged then
    begin
      ScrDelta^ := Str;
     // FDuplicate.ReleaseFrame;
      //Exit;
    end else
    if {$IFDEF DEBUG} true or {$ENDIF} (DirtyRCnt + MovedRCnt > 0) then
    begin
      Rec := TRtcRecord.Create;

      Debug.Log('Encoding MoveRects ' + IntToStr(MovedRCnt) +
        ' DirtyRects ' + IntToStr(DirtyRCnt));

      if MovedRCnt > 0 then
        with Rec.newArray('scrmr') do
          for RectId := 0 to MovedRCnt - 1 do
            with NewRecord(RectId), MovedR[RectId], MovedRP[RectId] do
            begin
              asInteger['Left'] :=  Left;
              asInteger['Top'] :=  Top;
              asInteger['Right'] :=  Right;
              asInteger['Bottom'] := Bottom;
              asInteger['PointX'] :=  X;
              asInteger['PointY'] :=  Y;
            end;


      {$IFDEF DEBUG}
      CurTick := Debug.GetMCSTick;
      {$ENDIF}

      if DirtyRCnt > 0 then
        with Rec.newArray('scrdr') do
          for RectId := 0 to DirtyRCnt - 1 do
            EncodeImage(NewRecord(RectId), DirtyR[RectId]);

        {with Rec.asArray['scr'] do
          for RectId := 0 to FChangedRectsCnt - 1 do
          begin
            ByteS := AsRecord[RectId].asByteStream['Data'] as TMemoryStream;
            ByteS.Free;
          end;      }


      {$IFDEF DEBUG}
      EncLat := Debug.GetMCSTick - CurTick;

      with Rec.newRecord('scrfs') do
      begin
        asInteger['CapLat'] :=  CapLat;
        asInteger['EncLat'] :=  EncLat;
      end;
      {$ENDIF}

      ScrDelta^ := Rec.toCode;
      Rec.Free;
    end else
      ScrDelta^ := '';

  Debug.Log('Host data sent');

  if IsService then
  begin
    FreeMem(FScreenBuff);
//    Dispose(FScreenBuff);
  end;

  DataCS.Leave;

  time := GetTickCount - time;
  Debug.Log('grab: ' + IntToStr(time));

 //FDuplicate.ReleaseFrame;
end;


function TRtcScreenEncoder.GetDataFromHelper(OnlyGetScreenParams: Boolean = False; fFirstScreen: Boolean = False): Boolean;
var
  h, hMap: THandle;
  pMap: Pointer;
  hScrDC, hDestDC, hMemDC: HDC;
  hBmp: HBitmap;
  BitmapSize: Cardinal;
  bitmap_info: BITMAPINFO;
  EventWriteBegin, EventWriteEnd, EventReadBegin, EventReadEnd: THandle;
  SessionID: DWORD;
  HeaderSize, CurOffset: Integer;
  NameSuffix: String;
  hOld: HGDIOBJ;
  hProc: THandle;
  numberRead : SIZE_T;
  WaitTimeout: DWORD;
  SaveBitMap: TBitmap;
  i, j, TempInt: LongInt;
begin
  if not IsWindows8orLater then
    Exit;

  WaitTimeout := 1000; //INFINITE;

  HelperCS.Acquire;
  try
    Result := False;

    if IsService then
    begin
      SessionID := ActiveConsoleSessionID;
      NameSuffix := '_C';
    end
    else
    begin
      SessionID := CurrentSessionID;
      NameSuffix := '';
    end;

//    NameSuffix := '_C';
//    SessionID := 1;

    EventWriteBegin := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_WRITE_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventWriteBegin = 0 then
      Exit;
    EventWriteEnd := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_WRITE_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventWriteEnd = 0 then
      Exit;
    EventReadBegin := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_BEGIN_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventReadBegin = 0 then
      Exit;
    EventReadEnd := OpenEvent(EVENT_ALL_ACCESS, False, PWideChar(WideString('Global\RMX_SCREEN_READ_END_SESSION_' + IntToStr(SessionID) + NameSuffix)));
    if EventReadEnd = 0 then
      Exit;

    try
      //Сбрасываем события предыдущей итерации
      ResetEvent(EventWriteEnd);
      ResetEvent(EventReadBegin);
      ResetEvent(EventReadEnd);

      SetEvent(EventWriteBegin); //Если чтение не идет, то начинаем запись скрина

      WaitForSingleObject(EventWriteEnd, WaitTimeout); //Добавить таймаут, ждем окончания записи скрина
      ResetEvent(EventWriteEnd);

      try
        hMap := OpenFileMapping(FILE_MAP_READ or FILE_MAP_WRITE, False, PWideChar(WideString('Session\' + IntToStr(SessionID) + '\RMX_SCREEN' + NameSuffix)));
        if hMap = 0 then
          Exit;
        HeaderSize := SizeOf(THelperIOData);
//        HeaderSize := SizeOf(BitmapSize) + SizeOf(fScreenGrabbed) + SizeOf(FScreenWidth) + SizeOf(FScreenHeight) + SizeOf(FBitsPerPixel) +
//          SizeOf(CurrentProcessId) + SizeOf(FScreenBuff) + SizeOf(DirtyArray) + SizeOf(MovedArray) + SizeOf(FMouseFlags) + SizeOf(FMouseCursor) +
//          SizeOf(FMouseX) + SizeOf(FMouseY);
        pMap := MapViewOfFile(hMap, //дескриптор "проецируемого" объекта
                                FILE_MAP_READ or FILE_MAP_WRITE,  // разрешение чтения/записи
                                0,0,
                                HeaderSize);  //размер буфера
        if pMap = nil then
          Exit;

        CopyMemory(@HelperIOData, pMap, SizeOf(THelperIOData));

        //Записываем входные параметры
        BitmapSize := HelperIOData.BitmapSize;
        HaveScreen := HelperIOData.HaveScreen;
        if HelperIOData.ScreenWidth <> FScreenWidth then
          FScreenInfoChanged := True;
        FScreenWidth := HelperIOData.ScreenWidth;
        if HelperIOData.ScreenHeight <> FScreenHeight then
          FScreenInfoChanged := True;
        FScreenHeight := HelperIOData.ScreenHeight;
        if HelperIOData.BitsPerPixel <> FBitsPerPixel then
          FScreenInfoChanged := True;
        FBitsPerPixel := HelperIOData.BitsPerPixel;
        FMouseFlags := HelperIOData.MouseFlags;
        FMouseCursor := HelperIOData.MouseCursor;
        FMouseX := HelperIOData.MouseX;
        FMouseY := HelperIOData.MouseY;
        FDirtyRCnt := HelperIOData.DirtyRCnt;
        FMovedRCnt := HelperIOData.MovedRCnt;

//        BitmapSize := 0;
////        FScreenWidth := 0;
////        FScreenHeight := 0;
////        FBitsPerPixel := 0;
//        FScreenInfoChanged := False;
//        CurOffset := 0;
//        CopyMemory(@BitmapSize, pMap, SizeOf(BitmapSize));
//        CurOffset := CurOffset + SizeOf(BitmapSize);
//        CopyMemory(@FHaveScreen, PByte(pMap) + CurOffset, SizeOf(FHaveScreen));
//        CurOffset := CurOffset + SizeOf(FHaveScreen);
//
//        CopyMemory(@TempInt, PByte(pMap) + CurOffset, SizeOf(TempInt));
//        CurOffset := CurOffset + SizeOf(TempInt);
//        if TempInt <> FScreenWidth then
//          FScreenInfoChanged := True;
//        FScreenWidth := TempInt;
//        CopyMemory(@TempInt, PByte(pMap) + CurOffset, SizeOf(TempInt));
//        CurOffset := CurOffset + SizeOf(TempInt);
//        if TempInt <> FScreenHeight then
//          FScreenInfoChanged := True;
//        FScreenHeight := TempInt;
//        CopyMemory(@TempInt, PByte(pMap) + CurOffset, SizeOf(TempInt));
//        CurOffset := CurOffset + SizeOf(TempInt);
//        if TempInt <> FBitsPerPixel then
//          FScreenInfoChanged := True;
//        FBitsPerPixel := TempInt;

        FClipRect.Top := 0;
        FClipRect.Left := 0;
        FClipRect.Bottom := FScreenHeight;
        FClipRect.Right := FScreenWidth;

////        CopyMemory(@PID, PByte(pMap) + CurOffset, SizeOf(PID));
//        CurOffset := CurOffset + SizeOf(CurrentProcessId);
////        CopyMemory(@FScreenBuff, PByte(pMap) + CurOffset, SizeOf(FScreenBuff));
//        CurOffset := CurOffset + SizeOf(FScreenBuff);

//        CopyMemory(@FMouseFlags, PByte(pMap) + CurOffset, SizeOf(FMouseFlags));
//        CurOffset := CurOffset + SizeOf(FMouseFlags);
//        CopyMemory(@FMouseCursor, PByte(pMap) + CurOffset, SizeOf(FMouseCursor));
//        CurOffset := CurOffset + SizeOf(FMouseCursor);
//        CopyMemory(@FMouseX, PByte(pMap) + CurOffset, SizeOf(FMouseX));
//        CurOffset := CurOffset + SizeOf(FMouseX);
//        CopyMemory(@FMouseY, PByte(pMap) + CurOffset, SizeOf(FMouseY));
//        CurOffset := CurOffset + SizeOf(FMouseY);

        if OnlyGetScreenParams then
          Exit;

//        CurOffset := 0;
//  //      CopyMemory(@BitmapSize, pMap, SizeOf(BitmapSize));
//        CurOffset := CurOffset + SizeOf(BitmapSize);
//  //      CopyMemory(@fScreenGrabbed, PByte(pMap) + CurOffset, SizeOf(fScreenGrabbed));
//        CurOffset := CurOffset + SizeOf(fScreenGrabbed);
//  //      CopyMemory(@FHelper_Width, PByte(pMap) + CurOffset, SizeOf(FHelper_Width));
//        CurOffset := CurOffset + SizeOf(FScreenWidth);
//  //      CopyMemory(@FHelper_Height, PByte(pMap) + CurOffset, SizeOf(FHelper_Height));
//        CurOffset := CurOffset + SizeOf(FScreenHeight);
//  //      CopyMemory(@FHelper_BitsPerPixel, PByte(pMap) + CurOffset, SizeOf(FHelper_BitsPerPixel));
//        CurOffset := CurOffset + SizeOf(FBitsPerPixel);
//        CopyMemory(PByte(pMap) + CurOffset, @CurrentProcessId, SizeOf(CurrentProcessId));
//        CurOffset := CurOffset + SizeOf(CurrentProcessId);
//        CopyMemory(PByte(pMap) + CurOffset, @FScreenBuff, SizeOf(FScreenBuff));
//        CurOffset := CurOffset + SizeOf(FScreenBuff);
//        CopyMemory(PByte(pMap) + CurOffset, @DirtyArray, SizeOf(DirtyArray));
//        CurOffset := CurOffset + SizeOf(DirtyArray);
//        CopyMemory(PByte(pMap) + CurOffset, @MovedArray, SizeOf(MovedArray));
//        CurOffset := CurOffset + SizeOf(MovedArray);
//
//        CopyMemory(PByte(pMap) + CurOffset, @FDirtyRCnt, SizeOf(FDirtyRCnt));
//        CurOffset := CurOffset + SizeOf(FDirtyRCnt);
//        CopyMemory(PByte(pMap) + CurOffset, @FMovedRCnt, SizeOf(FMovedRCnt));
//        CurOffset := CurOffset + SizeOf(FMovedRCnt);

        GetMem(FScreenBuff, BitmapSize);

        //Записываем выходные параметры
        HelperIOData.PID := CurrentProcessId;
        HelperIOData.ipBase_ScreenBuff := FScreenBuff;
        HelperIOData.ipBase_DirtyR := @FDirtyR;
        HelperIOData.ipBase_MovedR := @FMovedR;
        HelperIOData.ipBase_MovedRP := @FMovedRP;

        CopyMemory(PByte(pMap), @HelperIOData, SizeOf(HelperIOData));
      finally
        if pMap <> nil then
          UnmapViewOfFile(pMap);
        if hMap <> 0 then
          CloseHandle(hMap);
      end;

      SetEvent(EventReadBegin);
      if WaitForSingleObject(EventReadEnd, WaitTimeout) = WAIT_TIMEOUT then
        Exit;

      //Запись экрана и изменений в хелпере в текущий процесс...
    finally
      ResetEvent(EventReadEnd);

      if EventWriteEnd <> 0 then
      begin
        CloseHandle(EventWriteEnd);
        EventWriteEnd := 0;
      end;
      if EventWriteBegin <> 0 then
      begin
        CloseHandle(EventWriteBegin);
        EventWriteBegin := 0;
      end;
      if EventReadBegin <> 0 then
      begin
        CloseHandle(EventReadBegin);
        EventReadBegin := 0;
      end;
      if EventReadEnd <> 0 then
      begin
        CloseHandle(EventReadEnd);
        EventReadEnd := 0;
      end;
    end;
  finally
    HelperCS.Release;
  end;
end;

end.
