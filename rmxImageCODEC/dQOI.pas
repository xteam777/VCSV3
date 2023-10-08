{==============================================================================*
* Copyright © 2023, Pukhkii Ihor                                               *
* All rights reserved.                                                         *
*==============================================================================*
* This Source Code Form is subject to the terms of the Mozilla                 *
* Public License, v. 2.0. If a copy of the MPL was not distributed             *
* with this file, You can obtain one at http://mozilla.org/MPL/2.0/.           *
*==============================================================================*
* The Initial Developer of this Unit is Pukhkii Ihor (Ukraine).                *
* Contacts: nspytnik-programming@yahoo.com                                     *
*==============================================================================*
* DESCRIPTION:                                                                 *
* This module is an implementation\translation of the "QOI" image              *
* compression algorithm in Pascal.                                             *
* link: https://qoiformat.org/                                                 *
*                                                                              *
* QOI -  The Quite OK Image Format for Fast, Lossless Compression              *
*                                                                              *
* QOI is fast. It losslessly compresses images to a similar size of PNG,       *
* while offering 20x-50x faster encoding and 3x-4x faster decoding.            *
*                                                                              *
*                                                                              *
* dQOI.pas - this module                                                       *
*                                                                              *
* Last modified: 05.10.2023 16:51:10                                           *
* Author       : Pukhkii Ihor                                                  *
* Skype        : spytnick                                                      *
* Email        : nspytnik-programming@yahoo.com                                *
* www          :                                                               *
*                                                                              *
* File version: 0.0.0.1                                                        *
*==============================================================================}

unit dQOI;

interface

const
 QOI_OP_INDEX  = $00; // 00xxxxxx
 QOI_OP_DIFF   = $40; // 01xxxxxx
 QOI_OP_LUMA   = $80; // 10xxxxxx
 QOI_OP_RUN    = $C0; // 11xxxxxx
 QOI_OP_RGB    = $FE; // 11111110
 QOI_OP_RGBA   = $FF; // 11111111

 QOI_MASK_2    = $C0; // 11000000


 //QOI_MAGIC = Ord('q') or  Ord('o') shl 8  or Ord('i') shl 16 or Ord('f') shl 24;
 QOI_MAGIC = Ord('f') or  Ord('i') shl 8  or Ord('o') shl 16 or Ord('q') shl 24;
 QOI_HEADER_SIZE = 14;

{ 2GB is the max file size that this implementation can safely handle. We guard
against anything larger than that, assuming the worst case with 5 bytes per
pixel, rounded down to a nice clean value. 400 million pixels ought to be
enough for anybody. }
 QOI_PIXELS_MAX: Cardinal = 400000000; //unsigned int


qoi_padding: array [0..8-1] of Byte = (0,0,0,0,0,0,0,1); //unsigned char

type

  qoi_desc = packed record
    width      : Cardinal;    //unsigned int
    height     : Cardinal;    //unsigned int
    channels   : Byte;        //unsigned char
    colorspace : Byte;        //unsigned char
    has_alpha  : Boolean;     // custom flag
  end;

  TQOIDesc = qoi_desc;
  PQOIDesc = ^TQOIDesc;

  PBGRA = ^TBGRA;
  TBGRA = record
    case Boolean of
      false: (b, g, r, a: Byte);
      true:  (v: Cardinal);
  end;

  PRGBA = ^TRGBA;
  TRGBA = record
    case Boolean of
      false: (r, g, b, a: Byte);
      true:  (v: Cardinal);
  end;


  TARGB = record
    case Boolean of
      false: (a, r, g, b: Byte);
      true:  (v: Cardinal);
  end;




{ Encode raw RGB or RGBA pixels into a QOI image in memory.

The function either returns nil on failure (invalid parameters or malloc
failed) or a pointer to the encoded data on success. On success the out_len
is set to the size in bytes of the encoded data.

The returned qoi data should be qoi_free() after use.
}

function qoi_encode(const data: Pointer; const desc: TQOIDesc; out out_len: Integer): Pointer;

{ Decode a QOI image from memory.

The function either returns nil on failure (invalid parameters or malloc
failed) or a pointer to the decoded pixels. On success, the qoi_desc struct
is filled with the description from the file header.

The returned pixel data should be qoi_free after use.
}

function qoi_decode(const data: Pointer; size: Integer; var desc: TQOIDesc; channels: Integer): Pointer;



function qoi_alloc(Size: Integer): Pointer; inline;
procedure qoi_free(P: Pointer); inline;

implementation


function qoi_alloc(size: Integer): Pointer;
begin
  GetMem(Result, Size);
end;

procedure qoi_free(P: Pointer);
begin
  FreeMem(P);
end;

function IncX(var X: Integer): Integer; overload; inline;
begin
  Result := X;
  System.Inc(X);
end;

function IncX(var X: Integer; N: Integer): Integer; overload; inline;
begin
  Result := X;
  System.Inc(X, N);
end;

function QOI_COLOR_HASH(const C: TRGBA) : Integer; overload;
begin
  Result := (C.r * 3 + C.g * 5 + C.b * 7 + C.a * 11);
end;

function QOI_COLOR_HASH(const C: TBGRA) : Integer; overload;
begin
  Result := (C.r * 3 + C.g * 5 + C.b * 7 + C.a * 11);
end;

function Swap32(v: Cardinal): Cardinal; //inline;
{$IFDEF PUREPASCAL}
begin
  PByte(@Result)[0] := PByte(@v)[3];
  PByte(@Result)[1] := PByte(@v)[2];
  PByte(@Result)[2] := PByte(@v)[1];
  PByte(@Result)[3] := PByte(@v)[0];
end;
{$ELSE !PUREPASCAL}
{$IFDEF CPUX86}
asm
  BSWAP EAX
end;
{$ENDIF}
{$IFDEF CPUX64}
asm
  MOV   EAX, ECX
  BSWAP EAX
end;
{$ENDIF}
{$ENDIF PUREPASCAL}

procedure qoi_write_32(bytes: PByte; var p: Integer; v: Cardinal);
begin
  PCardinal(@bytes[p])^ := Swap32(v);
  Inc(p, SizeOf(Cardinal));
  {
    bytes[IncX(p)] := ($ff000000 and v) shr 24;
    bytes[IncX(p)] := ($00ff0000 and v) shr 16;
    bytes[IncX(p)] := ($0000ff00 and v) shr 8;
    bytes[IncX(p)] := ($000000ff and v);
  }
end;



function qoi_read_32(bytes: PByte; var p: Integer): Cardinal;
{
var
  a, b, c, d: Cardinal;
}
begin
  Result := Swap32(PCardinal(@bytes[p])^);
  Inc(p, SizeOf(Cardinal));
  {
    a := bytes[IncX(p)];
    b := bytes[IncX(p)];
    c := bytes[IncX(p)];
    d := bytes[IncX(p)];
    Result := a shl 24 or b shl 16 or c shl 8 or d;
  }
end;

function qoi_encode(const data: Pointer; const desc: TQOIDesc; out out_len: Integer): Pointer;
var
 i, max_size, p, run: Integer;
 px_len, px_end, px_pos, channels: Integer;
 bytes: PByte;
 pixels: PByte;
 index: array [0..64-1] of TBGRA;
 px, px_prev: TBGRA;

  index_pos: Integer;
  vr, vg, vb, vg_r, vg_b: Integer;
begin
  Result := nil;
  if (data = nil) or
     (desc.width = 0) or (desc.height = 0) or
     (not (desc.channels in [3, 4])) or
     (desc.colorspace > 1) or
     (desc.height >= QOI_PIXELS_MAX div desc.width) then  exit;

  max_size :=
      desc.width * desc.height * (desc.channels + 1) +
      QOI_HEADER_SIZE + sizeof(qoi_padding);

  p := 0;
  bytes := qoi_alloc(max_size);
  if (bytes = nil) then exit;

  qoi_write_32(bytes, p, QOI_MAGIC);
  qoi_write_32(bytes, p, desc.width);
  qoi_write_32(bytes, p, desc.height);
  bytes[IncX(p)] := desc.channels;
  bytes[IncX(p)] := desc.colorspace;

  pixels := data;

  FillChar(index, SizeOf(index), 0);

  run := 0;
  px_prev.r := 0;
  px_prev.g := 0;
  px_prev.b := 0;
  px_prev.a := 255;
  px := px_prev;

  px_len := desc.width * desc.height * desc.channels;
  px_end := px_len - desc.channels;
  channels := desc.channels;

  px_pos := 0;
  while px_pos < px_len do
    begin
      // speed up
      if (channels = 4) then
        begin
          px := PBGRA(@pixels[px_pos])^;
        end
      else
        begin
          px.b := pixels[px_pos + 0];
          px.g := pixels[px_pos + 1];
          px.r := pixels[px_pos + 2];
        end;

      if (px.v = px_prev.v) then
        begin
          Inc(run);
          if (run = 62) or (px_pos = px_end) then
            begin
              bytes[IncX(p)] := QOI_OP_RUN or (run - 1);
              run := 0;
            end
        end
      else
        begin

          if (run > 0) then
            begin
              bytes[IncX(p)] := QOI_OP_RUN or (run - 1);
              run := 0;
            end;

          index_pos := QOI_COLOR_HASH(px) mod 64;
          if (index[index_pos].v = px.v) then
            begin
              bytes[IncX(p)] := QOI_OP_INDEX or index_pos;
            end
          else
            begin
              index[index_pos] := px;

              if (px.a = px_prev.a) then
                begin
                  vr := px.r - px_prev.r;
                  vg := px.g - px_prev.g;
                  vb := px.b - px_prev.b;

                  vg_r := vr - vg;
                  vg_b := vb - vg;

                  if (vr > -3) and (vr < 2) and
                     (vg > -3) and (vg < 2) and
                     (vb > -3) and (vb < 2) then
                    begin
                      bytes[IncX(p)] := QOI_OP_DIFF or (vr + 2) shl 4 or (vg + 2) shl 2 or (vb + 2);
                    end
                  else if (vg_r >  -9)  and (vg_r <  8) and
                          (vg   > -33)  and (vg   < 32) and
                          (vg_b >  -9)  and (vg_b <  8) then
                          begin
                            bytes[IncX(p)] := QOI_OP_LUMA or (vg + 32);
                            bytes[IncX(p)] := (vg_r + 8) shl 4 or (vg_b + 8);
                          end
                  else
                    begin
                      bytes[IncX(p)] := QOI_OP_RGB;
                      bytes[IncX(p)] := px.r;
                      bytes[IncX(p)] := px.g;
                      bytes[IncX(p)] := px.b;
                    end;

                end
              else
                begin
                  bytes[IncX(p)] := QOI_OP_RGBA;
                  bytes[IncX(p)] := px.r;
                  bytes[IncX(p)] := px.g;
                  bytes[IncX(p)] := px.b;
                  bytes[IncX(p)] := px.a;
                end;
            end;
        end;

      px_prev := px;
      Inc(px_pos, channels);
    end;

  for i := 0 to SizeOf(qoi_padding)-1 do
    bytes[IncX(p)] := qoi_padding[i];
  out_len := p;
  Result := bytes;

end;

function qoi_decode(const data: Pointer; size: Integer; var desc: TQOIDesc; channels: Integer): Pointer;
var
  bytes: PByte;
  header_magic: Cardinal;
  pixels: PByte;
  index: array [0..64-1] of TBGRA;
  px: TBGRA;
  px_len, chunks_len, px_pos: Integer;
  p, run: Integer;
  b1, b2, vg: Integer;

begin
  Result := nil;
  p := 0;
  run := 0;

  if (data = nil) or
     (not (channels in [0, 3, 4])) or
     (size < QOI_HEADER_SIZE + SizeOf(qoi_padding)) then
      exit;

  bytes := data;

  header_magic    := qoi_read_32(bytes, p);
  desc.width      := qoi_read_32(bytes, p);
  desc.height     := qoi_read_32(bytes, p);
  desc.channels   := bytes[IncX(p)];
  desc.colorspace := bytes[IncX(p)];
  desc.has_alpha  := false;

  if (desc.width = 0) or (desc.height = 0) or
     (not (desc.channels in [3, 4])) or
     (desc.colorspace > 1) or
     (header_magic <> QOI_MAGIC) or
     (desc.height >= QOI_PIXELS_MAX div desc.width) then
      exit;

  if (channels = 0) then
    channels := desc.channels;

  px_len := Integer(desc.width * desc.height) * channels;
  pixels := qoi_alloc(px_len);
  if (pixels = nil) then exit;

  FillChar(index, SizeOf(index), 0);
  px.r := 0;
  px.g := 0;
  px.b := 0;
  px.a := 255;

  chunks_len := size - SizeOf(qoi_padding);
  px_pos := 0;
  while px_pos < px_len do
    begin
      if (run > 0) then
        begin
          run := run - 1;
        end
      else if (p < chunks_len) then
        begin
          b1 := bytes[IncX(p)];

          if (b1 = QOI_OP_RGB) then
            begin
              px.r := bytes[IncX(p)];
              px.g := bytes[IncX(p)];
              px.b := bytes[IncX(p)];
            end
          else if (b1 = QOI_OP_RGBA) then
            begin
              px.r := bytes[IncX(p)];
              px.g := bytes[IncX(p)];
              px.b := bytes[IncX(p)];
              px.a := bytes[IncX(p)];
            end
          else if ((b1 and QOI_MASK_2) = QOI_OP_INDEX) then
            begin
              px := index[b1];
            end
          else if ((b1 and QOI_MASK_2) = QOI_OP_DIFF) then
            begin
              px.r := px.r + ((b1 shr 4) and $03) - 2;
              px.g := px.g + ((b1 shr 2) and $03) - 2;
              px.b := px.b + ( b1        and $03) - 2;
            end
          else if ((b1 and QOI_MASK_2) = QOI_OP_LUMA) then
            begin
              b2 := bytes[IncX(p)];
              vg := (b1 and $3f) - 32;
              px.r := px.r + vg - 8 + ((b2 shr 4) and $0F);
              px.g := px.g + vg;
              px.b := px.b + vg - 8 +  (b2        and $0F);
            end
          else if ((b1 and QOI_MASK_2) = QOI_OP_RUN) then
            begin
              run := (b1 and $3F);
            end;

          index[QOI_COLOR_HASH(px) mod 64] := px;
      end;

      // speed up
      if (channels = 4) then
        begin
          PBGRA(@pixels[px_pos])^ := px;
          if not desc.has_alpha and (px.a <> 255) then
            desc.has_alpha := true;
        end
      else
        begin
          pixels[px_pos + 0] := px.b;
          pixels[px_pos + 1] := px.g;
          pixels[px_pos + 2] := px.r;
        end;

      Inc(px_pos, channels);
    end;
  Result := pixels;
end;

end.
