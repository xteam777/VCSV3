unit VideoRecorder;
{$DEFINE AVI_WORK_THREAD}
interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, vfw, Vcl.Graphics,
  Vcl.Forms, Winapi.Messages;

type
  TVideoRecorderState = (vrsStoped, vrsRecording, vrsPaused);
  TVideoPacketManager = class;

  EVideoRecorder = class (Exception)
  private
    FErrorCode: HRESULT;
  public
    constructor Create(const AMsg: string; ACode: HRESULT);
    property ErrorCode: HRESULT read FErrorCode write FErrorCode;
  end;



  TVideoRecorder = class
  private
    FWindow: THandle;
    FFileName: string;
    FState: TVideoRecorderState;
    FTerminated: Boolean;
    FDuration: Integer;
    FFPS: Integer;
    FOnFPSVideoFrame: TNotifyEvent;
  protected
    procedure Error(Msg: PResStringRec; ErrorCode: HRESULT); overload;
    procedure Error(Msg: PResStringRec; ErrorCode: HRESULT; ErrorAddr: Pointer); overload;
    procedure CreateVideoFile(const AFileName: string); virtual;
    procedure CloseVideoFile(); virtual;
    procedure InitRecorder(); virtual; abstract;
    procedure FinalizeRecorder(); virtual; abstract;
  public
    constructor Create(Window: HWND;
      const AFileName: string;
      AFPS: Integer;
      const AOnFPSVideoFrame: TNotifyEvent); virtual;
    destructor Destroy; override;
    class procedure ExtractCodecInfo(List: TStrings); virtual; abstract;
    procedure AddVideoFrame(const Bitmap: TBitmap; Changed: Boolean = true); overload; virtual;
    procedure AddVideoFrame(const Canvas: TCanvas; Changed: Boolean = true); overload; virtual;
    procedure Terminate; virtual;
    property FileName: string read FFileName;
    property State: TVideoRecorderState read FState write FState;
    property Terminated: Boolean read FTerminated;
    property Duration: Integer read FDuration write FDuration;
    property OnFPSVideoFrame: TNotifyEvent read FOnFPSVideoFrame;
    property FPS: Integer read FFPS write FFPS;
  end;

  TAVIVideoHandler = (avhDialog, avhXvid, avhMSVC);

  TVideoRecorderAVIVFW = class (TVideoRecorder)
  private
    FFile: IAVIFile;
    FStream, FStreamCompressed: IAVIStream;
    FStreamInfo: TAVIStreamInfo;
    FBitmap: TBitmap;
    FBitmapInfoSize: Cardinal;
    FBitmapBitsSize: Cardinal;
    FBitmapInfoHeader: PBitmapInfoHeader;
    FBitmapBits: Pointer;
    FHandler: TAVIVideoHandler;
    FFrameIndex: Integer;
    {$IFDEF AVI_WORK_THREAD}
    FPacketManager: TVideoPacketManager;
    {$ENDIF}

    start_time, end_time: Cardinal;
    procedure InitializeBitmap(bmp: TBitmap);

  protected
    procedure CheckError(Code: HRESULT);
    procedure CreateVideoFile(const AFileName: string); override;
    procedure CreateVideoFileSimple(const AFileName: string);
    procedure CloseVideoFile(); override;
    procedure InitRecorder(); override;
    procedure FinalizeRecorder(); override;
    procedure RawAddVideoFrame(buffer: Pointer; size: Integer);
  public
    constructor Create(Window: HWND;
      const AFileName: string;
      AFPS: Integer;
      const AOnFPSVideoFrame: TNotifyEvent); overload; override;
    constructor Create(Window: HWND;
      const AFileName: string;
      AFPS: Integer;
      const AOnFPSVideoFrame: TNotifyEvent;
      Prototype: TBitmap); reintroduce; overload;
    destructor Destroy; override;
    class procedure ExtractCodecInfo(List: TStrings); override;
    procedure AddVideoFrame(const Bitmap: TBitmap; Changed: Boolean = true); overload; override;
    procedure AddVideoFrame(const Canvas: TCanvas; Changed: Boolean = true); overload; override;
    procedure Terminate; override;
  end;

  PVideoPacket = ^TVideoPacket;
  TVideoPacket = record
    BitmapHeader: PBitmapInfoHeader;
    BitmapBits: Pointer;
    next: PVideoPacket;

  end;

  TVideoPacketManager = class
  private
    FEvent: THandle;
    FCache: PVideoPacket;
    FHead, FLast: PVideoPacket;
    FRecorder: TVideoRecorderAVIVFW;
    FLockRecord, FlockImage: Integer;
    FTerminate, FProcessing, FDestroing: Boolean;
    FTimerThread, FBackThread: THandle;

    procedure FinalizePackets;
    procedure BackgroundExecute();
    procedure WaitableTimerExecute();
    procedure HandleException();

    procedure LockRecord;
    procedure UnLockRecord;
    procedure LockImage;
    procedure UnLockImage;

    function GetCachedPacket(var packet: PVideoPacket): Boolean;
    procedure PutCachedPacket(packet: PVideoPacket);
    function NewPacket(): PVideoPacket;
    procedure FreePacket(packet: PVideoPacket);
    function GetFramePacket(var packet: PVideoPacket): Boolean;
    procedure AddLastPacketDouble;

  protected
  public
    constructor Create(ARecorder: TVideoRecorderAVIVFW);
    destructor Destroy(); override;
    procedure Terminate;
    procedure AddFrame(const Bitmap: TBitmap; Changed: Boolean = true);

  end;


implementation

resourcestring
  rsErrorBitmapEmpty = 'The Bitmap object cannot be nil.';
  rsErrorInitBitmap = 'Initialize Bitmap failed';
  rsErrorVideoPacketManagerGetDIB = 'VideoPacketManager: GetDIB failed';
  rsErrorVideoRecordGlobal = 'VideoRecorder error.';
  rsErrorFmtCode = 'Error Code: 0x';
  rsErrorAbortOptions = 'User pressed CANCEL';
  RS_ERROR_AVIERR_BADFORMAT = 'The file couldn''t be read, indicating a corr' +
  'upt file or an unrecognized format.';
  RS_ERROR_AVIERR_MEMORY = 'There is not enough memory to complete the operation.';
  RS_ERROR_AVIERR_FILEOPEN = 'A disk error occurred while opening the file.';
  RS_ERROR_REGDB_E_CLASSNOTREG = 'According to the registry, the type of fil' +
  'e specified in AVIFileOpen does not have a handler to process it.';
  RS_ERROR_AVIERR_READONLY = 'The file has been opened without write permiss' +
  'ion.';
  RS_ERROR_AVIERR_FILEREAD = 'A disk error occurred while reading the file.';
  RS_ERROR_AVIERR_NOCOMPRESSOR = 'A suitable compressor cannot be found.';
  RS_ERROR_AVIERR_UNSUPPORTED = 'Compression is not supported for this type ' +
  'of data. This error might be returned if you try to compress data that is' +
  ' not audio or video.';
  RS_VIDCF_COMPRESSFRAMES = 'VIDCF_COMPRESSFRAMES';
  RS_VIDCF_CRUNCH = 'VIDCF_CRUNCH';
  RS_VIDCF_DRAW = 'VIDCF_DRAW';
  RS_VIDCF_FASTTEMPORALC = 'VIDCF_FASTTEMPORALC';
  RS_VIDCF_FASTTEMPORALD = 'VIDCF_FASTTEMPORALD';
  RS_VIDCF_QUALITY = 'VIDCF_QUALITY';
  RS_VIDCF_TEMPORAL = 'VIDCF_TEMPORAL';


{ **************************************************************************** }
{                               TVideoRecorder                                 }
{ **************************************************************************** }


procedure TVideoRecorder.AddVideoFrame(const Bitmap: TBitmap; Changed: Boolean);
begin

end;

procedure TVideoRecorder.AddVideoFrame(const Canvas: TCanvas; Changed: Boolean);
begin

end;



procedure TVideoRecorder.CloseVideoFile;
begin
  FState := vrsStoped;
end;

constructor TVideoRecorder.Create(
      Window: HWND;
      const AFileName: string;
      AFPS: Integer;
      const AOnFPSVideoFrame: TNotifyEvent);
begin
  inherited Create;
  FWindow          := Window;
  FFileName        := AFileName;
  FFPS             := AFPS;
  FOnFPSVideoFrame := AOnFPSVideoFrame;
  InitRecorder;
  CreateVideoFile(AFileName);
end;

procedure TVideoRecorder.CreateVideoFile(const AFileName: string);
begin
  FState := vrsRecording
end;

destructor TVideoRecorder.Destroy;
begin
  Terminate;
  CloseVideoFile;
  FinalizeRecorder;
  FTerminated := true;
  inherited;
end;


procedure TVideoRecorder.Error(Msg: PResStringRec; ErrorCode: HRESULT;
  ErrorAddr: Pointer);
begin
  raise EVideoRecorder.Create(LoadResString(Msg), ErrorCode) at ErrorAddr;
end;

procedure TVideoRecorder.Error(Msg: PResStringRec; ErrorCode: HRESULT);
begin
  raise EVideoRecorder.Create(LoadResString(Msg), ErrorCode) at
    PPointer(PByte(@Msg) + SizeOf(Msg) + SizeOf(Self) + SizeOf(Pointer))^;
//  Error(Msg, ErrorCode, PPointer(PByte(@Msg) + SizeOf(Msg) + SizeOf(Self) + SizeOf(Pointer))^);
end;

procedure TVideoRecorder.Terminate;
begin
  FTerminated := true;
end;


{ **************************************************************************** }
{                               TVideoRecorderAVIVFW                           }
{ **************************************************************************** }


procedure TVideoRecorderAVIVFW.AddVideoFrame(const Bitmap: TBitmap; Changed: Boolean);
begin
  if Terminated then
    exit;

  if Assigned(FBitmap) and (Bitmap <> FBitmap) then
    begin
      AddVideoFrame(Bitmap.Canvas);
      exit;
    end
  else if not Assigned(Bitmap) then
    Error(@rsErrorBitmapEmpty, 0);


  {$IFDEF AVI_WORK_THREAD}
    FPacketManager.AddFrame(Bitmap, Changed);
  {$ELSE}
    RawAddVideoFrame(FBitmapBits, FBitmapBitsSize);
  {$ENDIF}

end;

procedure TVideoRecorderAVIVFW.AddVideoFrame(const Canvas: TCanvas; Changed: Boolean);
begin
  if Terminated then
    exit;

  FBitmap.Canvas.CopyRect(FBitmap.Canvas.ClipRect, Canvas, Canvas.ClipRect);
  AddVideoFrame(FBitmap, Changed);
end;

procedure TVideoRecorderAVIVFW.CheckError(Code: HRESULT);
var
  ErrorAddr: Pointer;
begin
  if Succeeded(Code) then exit;
  ErrorAddr := PPointer(PByte(@Code) + SizeOf(Code) + SizeOf(Self) + SizeOf(Pointer))^;
  case Code of
    AVIERR_BADFORMAT    : Error(@RS_ERROR_AVIERR_BADFORMAT, Code, ErrorAddr);
    AVIERR_MEMORY       : Error(@RS_ERROR_AVIERR_MEMORY, Code, ErrorAddr);
    AVIERR_FILEREAD     : Error(@RS_ERROR_AVIERR_FILEREAD, Code, ErrorAddr);
    AVIERR_FILEOPEN     : Error(@RS_ERROR_AVIERR_FILEOPEN, Code, ErrorAddr);
    REGDB_E_CLASSNOTREG : Error(@RS_ERROR_REGDB_E_CLASSNOTREG, Code, ErrorAddr);
    AVIERR_READONLY     : Error(@RS_ERROR_AVIERR_READONLY, Code, ErrorAddr);
    AVIERR_NOCOMPRESSOR : Error(@RS_ERROR_AVIERR_NOCOMPRESSOR, Code, ErrorAddr);
    AVIERR_UNSUPPORTED  : Error(@RS_ERROR_AVIERR_UNSUPPORTED, Code, ErrorAddr);
  else
    Error(nil, Code, ErrorAddr);
  end;
end;

procedure TVideoRecorderAVIVFW.CloseVideoFile;
begin
  if State <> vrsRecording then exit;

  { TODO : Расчитать кадры вначале и по событию из таймера забирать. }
  if (FFrameIndex <> 0) and ((FPS < 1) or not Assigned(OnFPSVideoFrame)) then
    begin
      if FDuration = 0 then
        FDuration := (end_time - start_time);
      FStreamInfo.dwRate := Round(FFrameIndex / (FDuration / 1000));
      FStream.SetInfo(FStreamInfo, SizeOf(FStreamInfo));
    end;

  FFile             := nil;
  FStream           := nil;
  FStreamCompressed := nil;
  inherited;
end;

constructor TVideoRecorderAVIVFW.Create(Window: HWND;
      const AFileName: string;
      AFPS: Integer;
      const AOnFPSVideoFrame: TNotifyEvent);
begin
  Create(Window, AFileName, AFPS, AOnFPSVideoFrame, nil);
end;

constructor TVideoRecorderAVIVFW.Create(Window: HWND;
      const AFileName: string;
      AFPS: Integer;
      const AOnFPSVideoFrame: TNotifyEvent;
      Prototype: TBitmap);
begin
  if not Assigned(Prototype) or not (Prototype.PixelFormat in [pf24bit, pf32bit]) then
    begin
      FBitmap := TBitmap.Create;
      if Assigned(Prototype) then
        FBitmap.SetSize(Prototype.Width, Prototype.Height) else
        FBitmap.SetSize(Screen.Width, Screen.Height);
      FBitmap.PixelFormat := pf32bit;
      Prototype := FBitmap;
    end;
  FHandler := avhDialog;
  InitializeBitmap(Prototype);

  inherited Create(Window, AFileName, AFPS, AOnFPSVideoFrame);


  {$IFDEF AVI_WORK_THREAD}
    FPacketManager := TVideoPacketManager.Create(Self);
  {$ENDIF}

end;

procedure TVideoRecorderAVIVFW.CreateVideoFile(const AFileName: string);
begin
  CreateVideoFileSimple(AFileName);
  inherited;

end;

procedure TVideoRecorderAVIVFW.CreateVideoFileSimple(const AFileName: string);
var
   galpAVIOptions: PAVICOMPRESSOPTIONS;
   gaAVIOptions  : TAVICOMPRESSOPTIONS;
begin
  start_time := 0;
  CheckError(AVIFileOpen(FFile, PChar(AFileName), OF_WRITE or OF_CREATE, nil));


  FStreamInfo.fccType               := streamtypeVIDEO;
  FStreamInfo.fccHandler            := 0;
  FStreamInfo.dwScale               := 1;         // dwRate / dwScale = frames/second
  FStreamInfo.dwRate                := FPS;        // FPS;
  FStreamInfo.dwSuggestedBufferSize := FBitmapBitsSize;
  FStreamInfo.rcFrame.Right         := FBitmapInfoHeader.biWidth;
  FStreamInfo.rcFrame.Bottom        := FBitmapInfoHeader.biHeight;


  CheckError(FFile.CreateStream(FStream, FStreamInfo));

  fillchar(gaAVIOptions, SizeOf(gaAVIOptions), 0);
  gaAVIOptions.fccType := streamtypeVIDEO;
  galpAVIOptions       := @gaAVIOptions;

  case FHandler of
    avhDialog:
      if not AVISaveOptions(FWindow, ICMF_CHOOSE_KEYFRAME or ICMF_CHOOSE_DATARATE, 1, FStream, galpAVIOptions) then
        raise EAbort.Create(rsErrorAbortOptions);
    avhXvid:
      gaAVIOptions.fccHandler := mmioFOURCC('X','V','I','D');
    avhMSVC:
      begin
        gaAVIOptions.fccHandler:=mmioFOURCC('M','S','V','C');
        gaAVIOptions.dwQuality := 7500;
      end;
  end;


  CheckError(AVIMakeCompressedStream(FStreamCompressed, FStream, @gaAVIOptions, nil));
  CheckError(FStreamCompressed.SetFormat(0, FBitmapInfoHeader, FBitmapInfoSize));

end;

destructor TVideoRecorderAVIVFW.Destroy;
begin
  if end_time = 0 then
    end_time := GetTickCount;

  {$IFDEF AVI_WORK_THREAD}
  FPacketManager.Free;
  FPacketManager := nil;
  {$ENDIF}
  Terminate;
  FBitmap.Free;
  FreeMem(FBitmapInfoHeader);
  FBitmapInfoHeader := nil;
  inherited;
end;

class procedure TVideoRecorderAVIVFW.ExtractCodecInfo(List: TStrings);
  function FOURCC_to_str(f: DWORD): string;
  begin
    Result :=
      chr(f and $000000FF) +
      chr((f and $0000FF00) shr 8) +
      chr((f and $00FF0000) shr 16) +
      chr((f and $FF000000) shr 24);
  end;

  function FlagsToStr(f: DWORD): string;
  var
    a: array [0..7-1] of string;
    i: Integer;
  begin
    Result := '';
    if f and VIDCF_COMPRESSFRAMES <> 0 then
      a[0] := RS_VIDCF_COMPRESSFRAMES;
    if f and VIDCF_CRUNCH <> 0 then
      a[1] := RS_VIDCF_CRUNCH;
    if f and VIDCF_DRAW <> 0 then
      a[2] := RS_VIDCF_DRAW;
    if f and VIDCF_FASTTEMPORALC <> 0 then
      a[3] := RS_VIDCF_FASTTEMPORALC;
    if f and VIDCF_FASTTEMPORALD <> 0 then
      a[4] := RS_VIDCF_FASTTEMPORALD;
    if f and VIDCF_QUALITY <> 0 then
      a[5] := RS_VIDCF_QUALITY;
    if f and VIDCF_TEMPORAL <> 0 then
      a[6] := RS_VIDCF_TEMPORAL;

    for I := 0 to Length(a)-1 do
      if a[i] <> '' then
        begin
          if Result <> '' then
            Result := Result + ', ' +a[i] else
            Result := a[i];
        end;
    if Result = '' then
      Result := '0';
  end;

var
  i: Integer;
  cinfo: TICINFO;
  ICTYPE_VIDEO: Cardinal;
  //ICTYPE_AUDIO: Cardinal;
  hic: VFW.HIC;
  s: string;
begin
  ICTYPE_VIDEO := mmioFOURCC('v', 'i', 'd', 'c');
  //ICTYPE_AUDIO := mmioFOURCC('a', 'u', 'd', 's');



  i := 0;
  while ICInfo(ICTYPE_VIDEO, i, @cinfo) do
    begin
      Inc(i);
      hic := ICOpen(cinfo.fccType, cinfo.fccHandler, ICMODE_QUERY);
      if hic = 0 then Continue;
      try
        ICGetInfo(hic, @cinfo, SizeOf(cinfo));
        s := Format('--- %d ---'+sLineBreak+
          'Size        = %d' + sLineBreak+
          'Type        = %s (0x%.8x)' + sLineBreak+
          'Handler     = %s (0x%.8x)' + sLineBreak+
          'Flags       = %s' + sLineBreak+
          'Version     = 0x%.8x' + sLineBreak+
          'VersionICM  = 0x%.8x' + sLineBreak+
          'Name        = %s' + sLineBreak+
          'Description = %s' + sLineBreak+
          'Driver      = %s' + sLineBreak,
          [
            i,
            cinfo.dwSize,
            FOURCC_to_str(cinfo.fccType), cinfo.fccType,
            FOURCC_to_str(cinfo.fccHandler), cinfo.fccHandler,
            FlagsToStr(cinfo.dwFlags),
            cinfo.dwVersion,
            cinfo.dwVersionICM,
            cinfo.szName,
            cinfo.szDescription,
            cinfo.szDriver
          ]);
          List.Add(s);
        finally
          ICClose(hic);
        end;
    end;

    List.Insert(0, 'Video Compressors Count: '+ i.ToString +sLineBreak);

end;

procedure TVideoRecorderAVIVFW.FinalizeRecorder;
begin
  AVIFileExit;
end;

procedure TVideoRecorderAVIVFW.InitializeBitmap(bmp: TBitmap);
var
  BitmapInfoSize, BitmapBitsSize: Cardinal;
  header: PBitmapInfoHeader;
  bits: Pointer;
begin
  FreeMem(FBitmapInfoHeader);
  FBitmapInfoHeader := nil;

  GetDIBSizes(bmp.Handle, BitmapInfoSize, BitmapBitsSize);
  header := AllocMem(BitmapInfoSize + BitmapBitsSize);
  try
    bits := Pointer(PByte(header) + BitmapInfoSize);
    if not GetDIB(bmp.Handle, 0, header^, bits^) then
      Error(@rsErrorInitBitmap, 0);
    FBitmapInfoHeader := header;
    FBitmapBits       := bits;
    FBitmapBitsSize   := BitmapBitsSize;
    FBitmapInfoSize   := BitmapInfoSize;
  except
    FreeMem(header);
    raise;
  end;
end;

procedure TVideoRecorderAVIVFW.InitRecorder;
begin
  AVIFileInit
end;


procedure TVideoRecorderAVIVFW.RawAddVideoFrame(buffer: Pointer; size: Integer);
begin
  if start_time = 0 then
    start_time := GetTickCount;

  CheckError(AVIStreamWrite(FStreamCompressed, FFrameIndex, 1, buffer, size,
                        AVIIF_KEYFRAME, nil, nil));
  Inc(FFrameIndex);
end;

procedure TVideoRecorderAVIVFW.Terminate;
begin
  inherited;

  {$IFDEF AVI_WORK_THREAD}
  if Assigned(FPacketManager) then
    FPacketManager.Terminate;
  {$ENDIF}
end;

{ **************************************************************************** }
{                               EVideoRecorder                                 }
{ **************************************************************************** }


constructor EVideoRecorder.Create(const AMsg: string; ACode: HRESULT);
var
  s: string;
begin
  FErrorCode := ACode;
  s := AMsg;
  if s = '' then
  begin
    s := SysErrorMessage(Cardinal(ErrorCode));
    if s = '' then
     s := rsErrorVideoRecordGlobal;
  end;
  if ACode <> 0 then
    s := rsErrorFmtCode + IntToHex(ACode, 8) + sLineBreak + AMsg;
  inherited Create(s);

end;


{ **************************************************************************** }
{                               TVideoPacketManager                            }
{ **************************************************************************** }

procedure TVideoPacketManager.AddFrame(const Bitmap: TBitmap; Changed: Boolean);
var
  packet: PVideoPacket;
begin
  if not Changed then
    begin
      AddLastPacketDouble;
      exit;
    end;

  if FDestroing or FTerminate then exit;

  if not GetCachedPacket(packet) then
    packet := NewPacket;
  LockImage;
  try
    if not GetDIB(Bitmap.Handle, 0, packet.BitmapHeader^, packet.BitmapBits^) then
      begin
        FreePacket(packet);
        FRecorder.Error(@rsErrorVideoPacketManagerGetDIB, 0);
      end;
  finally
    UnLockImage;
  end;
  LockRecord;
  if Assigned(FHead) then
    begin
      FLast.next := packet;
      FLast := packet;
    end
  else
    begin
      FHead := packet;
      FLast := packet;
      SetEvent(FEvent);
    end;
  UnLockRecord;
end;

procedure TVideoPacketManager.AddLastPacketDouble;
var
  packet: PVideoPacket;
begin
  if not Assigned(FLast) then exit;
  if not GetCachedPacket(packet) then
    packet := NewPacket;

  LockImage;
  try
    Move(FLast.BitmapHeader^, packet.BitmapHeader^, FRecorder.FBitmapInfoSize + FRecorder.FBitmapBitsSize);
  finally
    UnLockImage;
  end;

  LockRecord;
    if Assigned(FHead) then
      begin
        FLast.next := packet;
        FLast := packet;
      end
    else
      begin
        FHead := packet;
        FLast := packet;
        SetEvent(FEvent);
      end;
  UnLockRecord;
end;

procedure TVideoPacketManager.BackgroundExecute;
var
  packet: PVideoPacket;
begin
  FProcessing := true;
  while not FTerminate and  (WaitForSingleObject(FEvent, INFINITE) = WAIT_OBJECT_0) do
    begin

      while not FTerminate and GetFramePacket(packet) do
        begin

          try
            FRecorder.RawAddVideoFrame(packet.BitmapBits, FRecorder.FBitmapBitsSize);
          except
            HandleException();
          end;
          PutCachedPacket(packet);

        end;

    end;
  FProcessing := false;
end;

constructor TVideoPacketManager.Create(ARecorder: TVideoRecorderAVIVFW);
var
 t1, t2: TThread;
begin
  inherited Create;
  FRecorder := ARecorder;
  FEvent    := CreateEvent(nil, false, false, PChar('TVideoPacketManager.Event:'+TGUID.NewGuid.ToString));
  if FEvent = 0 then
    RaiseLastOSError;
  t1 := nil;
  t2 := nil;
  try
    t1 := TThread.CreateAnonymousThread(procedure
      begin
        BackgroundExecute;
      end);
    t2 := TThread.CreateAnonymousThread(procedure
      begin
        WaitableTimerExecute;
      end);
    FBackThreaD := t1.Handle;
    FTimerThread := t2.Handle;

  {$IFDEF DEBUG}
    t1.NameThreadForDebugging('BackgroundExecute: '+t1.ThreadID.ToString, t1.ThreadID);
    t2.NameThreadForDebugging('WaitableTimerExecute: '+t2.ThreadID.ToString, t2.ThreadID);
  {$ENDIF}

  except
    t1.Free;
    t2.Free;
    raise;
  end;

  t1.Start;
  t2.Start;

//  t := BeginThread(nil, 0, @ThreadProc, Self, 0, ti);
//  Win32Check(t <> 0);
//  CloseHandle(t);
//  if Assigned(FRecorder.OnFPSVideoFrame) and (FRecorder.FPS > 1) then
//    begin
//      t := BeginThread(nil, 0, @TimerProc, Self, 0, ti);
//      Win32Check(t <> 0);
//      CloseHandle(t);
//    end;
end;

destructor TVideoPacketManager.Destroy;
begin
  FDestroing := true;

  while FProcessing and (FHead <> nil) do
    begin
      Application.ProcessMessages;
      SwitchToThread;
    end;
  FTerminate := true;

  SetEvent(FEvent);

  while FProcessing do
    begin
      Application.ProcessMessages;
      SwitchToThread;
    end;

  CloseHandle(FEvent);

  WaitForSingleObject(FBackThread, INFINITE);
  WaitForSingleObject(FTimerThread, INFINITE);

  FinalizePackets;
  inherited;
end;

procedure TVideoPacketManager.FinalizePackets;
var
  d: PVideoPacket;
begin
  while FHead <> nil do
    begin
      d := FHead;
      FHead := FHead.next;
      FreePacket(d);
    end;

  while FCache <> nil do
    begin
      d := FCache;
      FCache := FCache.next;
      FreePacket(d);
    end;

end;

procedure TVideoPacketManager.FreePacket(packet: PVideoPacket);
begin
  if Assigned(packet) then
    begin
      FreeMem(packet.BitmapHeader);
      Dispose(packet);
    end;
end;

function TVideoPacketManager.GetFramePacket(var packet: PVideoPacket): Boolean;
begin
  LockRecord;
    packet := FHead;
    Result := Assigned(packet);
    if Assigned(FHead) then
      begin
        FHead := FHead.next;
        packet.next := nil;
      end;
  UnLockRecord;

  // put to cahce free packet
  (*
  repeat
    packet.next := FCache;
    n := InterlockedCompareExchangePointer(FCache, packet, packet.next);
  until n = packet.next;
  *)
end;

procedure TVideoPacketManager.HandleException;
var
  EObject: Exception;
  EAddr: Pointer;
begin
  EObject := Exception(ExceptObject);
  EAddr   := ExceptAddr;

  if not (EObject is EAbort) then
    TThread.Synchronize(TThread.Current,
      procedure ()
      begin
        // Cancel the mouse capture
        if GetCapture <> 0 then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);
        // Now actually show the exception
        EObject.Message := EObject.Message;
        if EObject is Exception then
          if Assigned(Application.OnException) then
            Application.OnException(Self, EObject) else
            Application.ShowException(EObject)
        else
          System.SysUtils.ShowException(EObject, EAddr);

      end
      );


end;

procedure TVideoPacketManager.LockRecord;
begin
  while InterlockedExchange(FLockRecord, 1) <> 0 do SwitchToThread;
end;

procedure TVideoPacketManager.LockImage;
begin
  while InterlockedExchange(FlockImage, 1) <> 0 do SwitchToThread;
end;

function TVideoPacketManager.GetCachedPacket(var packet: PVideoPacket): Boolean;
begin
  Result := false;
  if not Assigned(FCache) then exit;
  LockRecord;
  if Assigned(FCache) then
    begin
      packet := FCache;
      FCache := FCache.next;
      packet.next := nil;
      Result := true;
    end;
  UnLockRecord;


  // Get from cache packet
  (*
  packet := InterlockedExchangePointer(FCache, FCache.next);
  packet.next := nil;
  Result := true;
  *)
end;

function TVideoPacketManager.NewPacket: PVideoPacket;
begin
  New(Result);
  Result.BitmapHeader := AllocMem(FRecorder.FBitmapInfoSize + FRecorder.FBitmapBitsSize);
  Result.BitmapBits   := Pointer(PByte(Result.BitmapHeader) + FRecorder.FBitmapInfoSize);
  Result.next         := nil;
end;

procedure TVideoPacketManager.PutCachedPacket(packet: PVideoPacket);
begin
  if not Assigned(packet)  then exit;
  LockRecord;
    packet.next := FCache;
    FCache      := packet;
  UnLockRecord;
end;

procedure TVideoPacketManager.Terminate;
begin
  FTerminate := true;
end;

procedure TVideoPacketManager.UnLockRecord;
begin
  InterlockedExchange(FLockRecord, 0);
end;

procedure TVideoPacketManager.UnLockImage;
begin
  InterlockedExchange(FlockImage, 0);
end;

procedure TVideoPacketManager.WaitableTimerExecute;
const
  TIMER_UNITS_PERSECOND = 10000000;
  TIMER_UNITS_FACTOR_MILISECOND = TIMER_UNITS_PERSECOND div 1000;
var
  interval, last_time, t: Cardinal;
  period: Integer;
  timer: THandle;
  DueTime: Int64;
begin
  interval := 1000 div FRecorder.FPS;
  timer := 0;
  try
    timer := CreateWaitableTimer(nil, false, PChar('TVideoPacketManager.WaitableTimer:' + TGuid.NewGuid.ToString));
    if timer = 0 then
      RaiseLastOSError;
  except
    HandleException;
    FTerminate := true;
  end;

  last_time := GetTickCount;
  LARGE_INTEGER(DueTime).QuadPart := 0;

  while not FTerminate and not FDestroing do
    try
      repeat

          t := (GetTickCount - last_time);
          if t <> 0 then;

          period := interval - Integer(GetTickCount - last_time);
          LARGE_INTEGER(DueTime).QuadPart := -Integer(period * TIMER_UNITS_FACTOR_MILISECOND);
          if period > 0 then
            begin
              SetWaitableTimer(timer, DueTime, 0, nil, nil, false);
              WaitForSingleObject(timer, INFINITE);
            end;
          if FDestroing or FTerminate then break;
          last_time := GetTickCount;
          FRecorder.OnFPSVideoFrame(FRecorder);
//          if  Changed then
//            AddFrame(Bitmap)
//          else
//            AddLastPacketDouble;

      until FDestroing or FTerminate;

    except
      HandleException;
    end;
  CloseHandle(timer);

end;

end.
