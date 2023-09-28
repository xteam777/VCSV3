unit Compressions;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;


//==============================================================================
// LZMA2
type
  TCompressCtx = type Pointer;
  TDecompressCtx = type Pointer;
  {$Z+}
  TLZMA2_ERROR = (
    E_LZMA2_NO_ERROR                = 0,
    E_LZMA2_GENERIC                 = 1,
    E_LZMA2_INTERNAL                = 2,
    E_LZMA2_CORRUPTION_DETECTED     = 3,
    E_LZMA2_CHECKSUM_WRONG          = 4,
    E_LZMA2_PARAMETER_UNSUPPORTED   = 5,
    E_LZMA2_PARAMETER_OUTOFBOUND    = 6,
    E_LZMA2_LCLPMAX_EXCEEDED        = 7,
    E_LZMA2_STAGE_WRONG             = 8,
    E_LZMA2_INIT_MISSING            = 9,
    E_LZMA2_MEMORY_ALLOCATION       = 10,
    E_LZMA2_DSTSIZE_TOOSMALL        = 11,
    E_LZMA2_SRCSIZE_WRONG           = 12,
    E_LZMA2_CANCELED                = 13,
    E_LZMA2_BUFFER                  = 14,
    E_LZMA2_TIMEDOUT                = 15,
    E_LZMA2_MAXCODE                 = 20
  );
 {$Z-}

function lzma2_CreateCompressorEx(nbThreads: Integer): TCompressCtx; cdecl;
procedure lzma2_FreeCompressor(Ctx: Pointer); cdecl;
function lzma2_CreateDecompressorEx(nbThreads: Integer): TDecompressCtx; cdecl;
procedure lzma2_FreeDecompressor(Ctx: TDecompressCtx); cdecl;

function lzma2_compress(CCtx: TCompressCtx; Dst: Pointer; DstSize: size_t;
  Src: Pointer; SrcSize: size_t; compressionlevel: Integer): size_t; cdecl;
function lzma2_decompress(DCtx: TDecompressCtx; Dst: Pointer; DstSize: size_t;
  Src: Pointer; SrcSize: size_t): size_t; cdecl;

function lzma2_GetDecompressedSize(Src: Pointer; SrcSize: size_t): Int64; cdecl;
function lzma2_GetErrorCode(Code: size_t): TLZMA2_ERROR; cdecl;
function lzma2_GetErrorName(Code: size_t): PAnsiChar; cdecl;
function lzma2_GetErrorString(Code: TLZMA2_ERROR): PAnsiChar; cdecl;

//==============================================================================
// LZMA
const

 E_LZMA_SZ_OK                = 0;
 E_LZMA_SZ_ERROR_DATA        = 1;
 E_LZMA_SZ_ERROR_MEM         = 2;
 E_LZMA_SZ_ERROR_CRC         = 3;
 E_LZMA_SZ_ERROR_UNSUPPORTED = 4;
 E_LZMA_SZ_ERROR_PARAM       = 5;
 E_LZMA_SZ_ERROR_INPUT_EOF   = 6;
 E_LZMA_SZ_ERROR_OUTPUT_EOF  = 7;
 E_LZMA_SZ_ERROR_READ        = 8;
 E_LZMA_SZ_ERROR_WRITE       = 9;
 E_LZMA_SZ_ERROR_PROGRESS    = 10;
 E_LZMA_SZ_ERROR_FAIL        = 11;
 E_LZMA_SZ_ERROR_THREAD      = 12;
 E_LZMA_SZ_ERROR_ARCHIVE     = 16;
 E_LZMA_SZ_ERROR_NO_ARCHIVE  = 17;

{type
 TLZMAMemoryAlloc = function (Size: size_t): Pointer; stdcall;
 TLZMAMemoryFree = procedure (P: Pointer); stdcall;

function lzma_Compress(Dst: Pointer; DstSize: PSIZE_T;
  Src: Pointer; SrcSize: size_t; compressionlevel: Integer): Integer; stdcall;
function lzma_Decompress(Dst: Pointer; DstSize: PSIZE_T;
  Src: Pointer; SrcSize: size_t): Integer; stdcall;
function lzma_GetDecompressedSize(Src: Pointer;
  SrcSize: size_t; DecompressedSize: PSIZE_T): Integer; stdcall;
function lzma_SetMemoryManager(_Alloc: TLZMAMemoryAlloc;
  _Free: TLZMAMemoryFree): Integer; stdcall;
function lzma_GetErrorString(code: Integer): PAnsiChar; stdcall;}

type
  TCompressinID = array [0..8-1] of AnsiChar;

  ECompressionError = class (Exception);

  TCompressionCustom = class
  private
    FLevel: Integer;
  public
    constructor Create(Alevel: Integer); virtual;
    destructor Destroy; override;
    function Compress(InBuffer: Pointer; InSize: NativeUInt;
      OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt; virtual; abstract;
    function Decompress(InBuffer: Pointer; InSize: NativeUInt;
      OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt; virtual; abstract;
    function GetCompressionSize(Buffer: Pointer; Size: NativeUInt): NativeUInt; virtual; abstract;
    class function GetCompressionId: TCompressinID; virtual; abstract;
    property Level: Integer read FLevel write FLevel;
  end;

  TCompressionClass = class of TCompressionCustom;



  TCompressionLZMA2 = class(TCompressionCustom)
  private
    FCCtx, FDCtx: Pointer;

    procedure InitCompressor;
    procedure InitDecompressor;
    procedure FinalizeCompressor;
    procedure FinalizeDecompressor;
    procedure CheckError(Code: size_t);
  protected
  public
    constructor Create(Alevel: Integer); override;
    destructor Destroy; override;
    function Compress(InBuffer: Pointer; InSize: NativeUInt;
      OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt; override;
    function Decompress(InBuffer: Pointer; InSize: NativeUInt;
      OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt; override;
    function GetCompressionSize(Buffer: Pointer; Size: NativeUInt): NativeUInt; override;
    class function GetCompressionId: TCompressinID; override;

  end;

{  TCompressionLZMA = class(TCompressionCustom)
  private
    FLevel: Integer;
    procedure CheckError(Code: Integer);
    class constructor Create;
  protected
  public
    constructor Create(Alevel: Integer); override;
    destructor Destroy; override;
    function Compress(InBuffer: Pointer; InSize: NativeUInt;
      OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt; override;
    function Decompress(InBuffer: Pointer; InSize: NativeUInt;
      OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt; override;
    function GetCompressionSize(Buffer: Pointer; Size: NativeUInt): NativeUInt; override;
    class function GetCompressionId: TCompressinID; override;

  end;}

implementation
const
  lzma2_lib = 'rmxCompression.dll';
//  lzma_lib = 'LZMA.dll';

function lzma2_CreateCompressorEx; external lzma2_lib delayed;
procedure lzma2_FreeCompressor; external lzma2_lib delayed;
function lzma2_CreateDecompressorEx;  external lzma2_lib delayed;
procedure lzma2_FreeDecompressor; external lzma2_lib delayed;

function lzma2_compress; external lzma2_lib delayed;
function lzma2_decompress; external lzma2_lib delayed;

function lzma2_GetDecompressedSize; external lzma2_lib delayed;
function lzma2_GetErrorCode; external lzma2_lib delayed;
function lzma2_GetErrorName; external lzma2_lib delayed;
function lzma2_GetErrorString; external lzma2_lib delayed;

{function lzma_Compress; external lzma_lib delayed;
function lzma_Decompress; external lzma_lib delayed;
function lzma_GetDecompressedSize; external lzma_lib delayed;
function lzma_SetMemoryManager; external lzma_lib delayed;
function lzma_GetErrorString; external lzma_lib delayed;}

{ **************************************************************************** }
{                               TCompressionCustom                             }
{ **************************************************************************** }


constructor TCompressionCustom.Create(Alevel: Integer);
begin
  inherited Create;
  FLevel := Alevel
end;

destructor TCompressionCustom.Destroy;
begin

  inherited;
end;



{ **************************************************************************** }
{                               TCompressionLZMA2                              }
{ **************************************************************************** }


procedure TCompressionLZMA2.CheckError(Code: size_t);
var
  ecode: TLZMA2_ERROR;
begin
  ecode := lzma2_GetErrorCode(Code);
  if ecode <> E_LZMA2_NO_ERROR then
    raise ECompressionError.Create(AnsiString(lzma2_GetErrorString(ecode))) at ReturnAddress;
end;

function TCompressionLZMA2.Compress(InBuffer: Pointer; InSize: NativeUInt;
  OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt;
begin
  InitCompressor;
  Result := lzma2_compress(FCCtx, OutBuffer, OutSize, InBuffer, InSize, FLevel);
  CheckError(Result);
end;

constructor TCompressionLZMA2.Create(Alevel: Integer);
begin
  inherited;
end;

function TCompressionLZMA2.Decompress(InBuffer: Pointer; InSize: NativeUInt;
  OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt;
begin
  InitDecompressor;
  Result := lzma2_decompress(FDCtx, OutBuffer, OutSize, InBuffer, InSize);
  CheckError(Result);
end;

destructor TCompressionLZMA2.Destroy;
begin
  FinalizeCompressor;
  FinalizeDecompressor;
  inherited;
end;

procedure TCompressionLZMA2.FinalizeCompressor;
begin
  if Assigned(FCCtx) then
    lzma2_FreeCompressor(FCCtx);
  FCCtx := nil;
end;

procedure TCompressionLZMA2.FinalizeDecompressor;
begin
  if Assigned(FDCtx) then
    lzma2_FreeDecompressor(FDCtx);
  FDCtx := nil;
end;

class function TCompressionLZMA2.GetCompressionId: TCompressinID;
begin
  Result := 'lzma2';
end;

function TCompressionLZMA2.GetCompressionSize(Buffer: Pointer; Size: NativeUInt): NativeUInt;
begin
  Result := lzma2_GetDecompressedSize(Buffer, Size)
end;

procedure TCompressionLZMA2.InitCompressor;
begin
  if not Assigned(FCCtx) then
    FCCtx := lzma2_CreateCompressorEx(1);
end;

procedure TCompressionLZMA2.InitDecompressor;
begin
    if not Assigned(FDCtx) then
      FDCtx := lzma2_CreateDecompressorEx(1);
end;


{ **************************************************************************** }
{                               TCompressionLZMA                               }
{ **************************************************************************** }


{function LZMAMemoryAlloc(Size: size_t): Pointer; stdcall;
begin
  GetMem(Result, Size);
end;

procedure LZMAMemoryFree(P: Pointer); stdcall;
begin
  FreeMem(P);
end;

procedure TCompressionLZMA.CheckError(Code: Integer);
begin
  if Code <> E_LZMA_SZ_OK then
    raise ECompressionError.CreateFmt('Error occured (code %d): %s',
                                     [Code, AnsiString(lzma_GetErrorString(Code))]);
end;

function TCompressionLZMA.Compress(InBuffer: Pointer; InSize: NativeUInt;
  OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt;
var
  ecode: Integer;
begin
  Result := OutSize;
  ecode := lzma_compress(OutBuffer, @Result, InBuffer, InSize, FLevel);
  CheckError(ecode);
end;

class constructor TCompressionLZMA.Create;
begin
  if lzma_SetMemoryManager(@LZMAMemoryAlloc, LZMAMemoryFree) <> E_LZMA_SZ_OK then
    raise ECompressionError.Create('Can not set memory manager');
end;

constructor TCompressionLZMA.Create(Alevel: Integer);
begin
  inherited;

  FLevel := Alevel;
end;

function TCompressionLZMA.Decompress(InBuffer: Pointer; InSize: NativeUInt;
  OutBuffer: Pointer; OutSize: NativeUInt): NativeUInt;
var
  ecode: Integer;
begin
  Result := OutSize;
  ecode := lzma_decompress(OutBuffer, @Result, InBuffer, InSize);
  CheckError(ecode);
end;

destructor TCompressionLZMA.Destroy;
begin

  inherited;
end;

class function TCompressionLZMA.GetCompressionId: TCompressinID;
begin
  Result := 'lzma';
end;

function TCompressionLZMA.GetCompressionSize(Buffer: Pointer;
  Size: NativeUInt): NativeUInt;
var
  ecode: Integer;
begin
  Result := 0;
  ecode := lzma_GetDecompressedSize(Buffer, Size, @Result);
  CheckError(ecode);

end;}

end.
