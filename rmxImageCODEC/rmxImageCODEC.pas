unit rmxImageCODEC;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics;


type

  TRMXEncoder = class
  private
    class procedure EncodeQOI(Src: PByte; dx, dy: Integer; dstBPP: Integer;
      out ms: TMemoryStream);
    class procedure EncodeBMP(Src: PByte; dx, dy: Integer; dstBPP: Integer;
      out ms: TMemoryStream);
  public
    // Src - source buffer, 32 BitsPerPixels
    // dx, dy - width and heigth
    // dstBPP - destination bitsPerPixel. 32, 24, 16, 8, 4, 1 else not implemented
    class function Encode(Src: PByte; dx, dy: Integer; dstBPP: Integer;
      out ms: TMemoryStream): string;
  end;


  TRMXDecoder = class
  private
    class procedure DecodeQOI(Data: TMemoryStream; Image: TBitmap;
      PixelsOffset, RowSize: Integer);
    class procedure DecodeBMP(Data: TMemoryStream; Image: TBitmap;
      PixelsOffset, RowSize: Integer);
  public
    // Data   - source buffer, qoi image
    // dx, dy - width and heigth
    // dstBPP - destination bitsPerPixel. 32, 24 else not implemented
    class procedure Decode(Data: TMemoryStream; Image: TBitmap; PixelsOffset,
      RowSize: Integer; const mime: string);
  end;


implementation



uses dQOI, System.RTLConsts;

const
  mime_qoi = 'image/qoi';
  mime_bmp = 'image/bmp';

type
  TEncodeMemoryStream = class(TMemoryStream)
  protected
    function Realloc(var NewCapacity:
      {$IF CompilerVersion >= 35.0} NativeInt {$ELSE} LongInt {$ENDIF}): Pointer; override;
  public
    destructor Destroy; override;
  end;

{ **************************************************************************** }
{                               TEncodeMemoryStream                            }
{ **************************************************************************** }


destructor TEncodeMemoryStream.Destroy;
begin
  qoi_free(Memory);
  inherited;
end;

function TEncodeMemoryStream.Realloc(var NewCapacity:
  {$IF CompilerVersion >= 35.0} NativeInt {$ELSE} LongInt {$ENDIF}): Pointer;
const
  MemoryDelta = $2000; { Must be a power of 2 }
begin

  if NewCapacity <> Capacity then
    raise Exception.Create('Not allowing expand a memory');
  exit;

  if (NewCapacity > 0) and (NewCapacity <> Size) then
    NewCapacity := (NewCapacity + (MemoryDelta - 1)) and not (MemoryDelta - 1);
  Result := Memory;
  if NewCapacity <> Capacity then
  begin
    if NewCapacity = 0 then
    begin
      qoi_free(Memory);
      Result := nil;
    end else
    begin
      Result := qoi_alloc(NewCapacity);
      if (Result <> nil) and (Capacity > 0) then
        begin
          if Capacity < NewCapacity  then
            Move(Memory^, Result^, Capacity) else
            Move(Memory^, Result^, NewCapacity);
          qoi_free(Memory);
        end;
      if Result = nil then raise EStreamError.CreateRes(@SMemoryStreamError);
    end;
  end;
end;

{ **************************************************************************** }
{                               TRMXEncoder                                    }
{ **************************************************************************** }


class function TRMXEncoder.Encode(Src: PByte; dx, dy, dstBPP: Integer;
  out ms: TMemoryStream): string;
begin
  case dstBPP of
    32, 24:
      begin
        EncodeQOI(Src, dx, dy, dstBPP, ms);
        Result := 'image/qoi';
      end
    else
      begin
        EncodeBMP(Src, dx, dy, dstBPP, ms);
        Result := 'image/bmp';
      end;
  end;
end;

class procedure TRMXEncoder.EncodeBMP(Src: PByte; dx, dy, dstBPP: Integer;
  out ms: TMemoryStream);
var
  bmp32, bmp: TBitmap;
  bottom_up: Boolean;
  i, row: Integer;
  DS: TDIBSection;
  bmBits, scanline, p: PByte;
  line_width: Integer;
begin
  bmp32 := TBitmap.Create(dx, dy);
  try
    // init info
    //BitsPerPixel    := 32; // BitsPerPixel := DS.dsBm.bmBitsPixel * DS.dsbm.bmPlanes;
    line_width      := dx * 4;// BytesPerScanline(dx, bitsPerPixel, 32)
    bmp32.PixelFormat := pf32bit;

    if GetObject(bmp32.Handle, SizeOf(DS), @DS) = 0 then
      raise Exception.Create('InvalidBitmap');
    bottom_up := DS.dsBm.bmHeight > 0;
    p := Src;
    bmBits := bmp32.ScanLine[0];
    // save data to bitmap
    if bottom_up then
      begin
        bmBits := bmBits - (DS.dsBm.bmHeight - 1) * line_width;
        for i := 0 to dy - 1 do
        begin
          if bottom_up then
            row := dy - i - 1 else
            row := i;
          scanline := bmBits + row * line_width;
          Move(p^, scanline^, line_width);
          inc(p, line_width);
        end;
      end
    else
      begin
        Move(Src^, bmBits^, dx * dy * 4);
      end;

    // convert
    bmp := TBitmap.Create(dx, dy);
    try

      case dstBPP of
       1: bmp.PixelFormat := pf1bit;
       4: bmp.PixelFormat := pf4bit;
       8: bmp.PixelFormat := pf8bit;
       16:bmp.PixelFormat := pf16bit;
      end;

      bmp.Canvas.Draw(0, 0, bmp32);
      // result
      ms := TMemoryStream.Create;
      try
        bmp.SaveToStream(ms);
      except
        ms.Free;
        raise
      end;

    finally
      bmp.Free;
    end;

  finally
    bmp32.Free;
  end;
end;

class procedure TRMXEncoder.EncodeQOI(Src: PByte; dx, dy, dstBPP: Integer;
  out ms: TMemoryStream);
var
  data: Pointer;
  SrcEx: PByte;
  desc: TQOIDesc;
  len, i: Integer;
begin
  desc.width      := dx;
  desc.height     := dy;
  desc.channels   := dstBPP div 8; // 8 bit   channels 3 or 4
  desc.colorspace := 1;
  SrcEx := nil;
  if desc.channels = 3 then
    begin
      SrcEx := qoi_alloc(dx * dy * 3);
      data  := SrcEx;
      for I := 1 to dx * dy * 4 do
        begin
          if i mod 4 <> 0 then
            begin
              SrcEx^ := Src[i-1];
              Inc(SrcEx);
            end;
        end;
//      for I := 0 to dx * dy-1 do
//        begin
//          SrcEx[i*3+0] := Src[i*4+0];
//          SrcEx[i*3+1] := Src[i*4+1];
//          SrcEx[i*3+2] := Src[i*4+2];
//        end;
      SrcEx := data;
      Src   := data;
    end;
  try

    data := qoi_encode(Src, desc, len);
    if data = nil then
      raise Exception.Create('Cannot encode image');
    ms := TEncodeMemoryStream.Create;
    TEncodeMemoryStream(ms).SetPointer(data, len);
    ms.Seek(0, soEnd);
  finally
    if SrcEx <> nil then
      qoi_free(SrcEx);
  end;
end;


{ **************************************************************************** }
{                               TRMXDecoder                                    }
{ **************************************************************************** }


class procedure TRMXDecoder.Decode(Data: TMemoryStream; Image: TBitmap;
  PixelsOffset, RowSize: Integer;const mime: string);
begin
  if not Assigned(Image) then
    raise Exception.Create('Image must be not nil');
  if not Assigned(Data) then
    raise Exception.Create('Data must be not nil');

  if mime = 'image/qoi' then
    DecodeQOI(Data, Image, PixelsOffset, RowSize)
  else if mime = 'image/bmp' then
    DecodeBMP(Data, Image, PixelsOffset, RowSize)
  else
    raise Exception.Create('MIME type unsuported');
end;

class procedure TRMXDecoder.DecodeBMP(Data: TMemoryStream; Image: TBitmap;
  PixelsOffset, RowSize: Integer);
var
  bmp: TBitmap;
  pixels: PByte;
  i, line_width, bpp: Integer;
  bmBits: PByte;
begin
  bmp := TBitmap.Create();
  try
    bmp.LoadFromStream(Data);
    case bmp.PixelFormat of
      pf1bit: bpp := 1;
      pf4bit: bpp := 4;
      pf8bit: bpp := 8;
      pf15bit: bpp := 15;
      pf16bit: bpp := 16;
      pf24bit: bpp := 24;
      pf32bit: bpp := 32;
    else
      raise Exception.Create('Invalid Bitmap.PixelFormat');
    end;

    line_width := BytesPerScanline(bmp.Width, bpp, 32);

    bmBits := Image.ScanLine[0];
    Inc(bmBits, PixelsOffset);

    for i := 0 to bmp.height -1 do
    begin
      pixels := bmp.ScanLine[i];
      Move(pixels^, bmBits^, line_width);
      Inc(bmBits, RowSize);
      //inc(p, line_width);
    end;

  finally
    bmp.Free;
  end;

end;

class procedure TRMXDecoder.DecodeQOI(Data: TMemoryStream; Image: TBitmap;
  PixelsOffset, RowSize: Integer);
var
  desc: TQOIDesc;
  pixels: Pointer;
  i, line_width: Integer;
  bmBits, p: PByte;

begin
  pixels := qoi_decode(Data.Memory, Data.Size, desc, 0);
  if pixels = nil then
    raise Exception.Create('Invalid Data');

  try
      if desc.channels = 4 then
        Image.PixelFormat := pf32bit
      else if desc.channels = 3 then
        Image.PixelFormat := pf24bit
      else
        raise Exception.Create('Format unsuported');

      p := pixels;
      line_width := desc.Width * desc.channels;

      bmBits := Image.ScanLine[0];
      Inc(bmBits, PixelsOffset);

      for i := 0 to desc.height -1 do
      begin
        Move(p^, bmBits^, line_width);
        Inc(bmBits, RowSize);
        inc(p, line_width);
      end;
      if desc.has_alpha then
        Image.AlphaFormat := afDefined;

  finally
    qoi_free(pixels);
  end;

end;

end.
