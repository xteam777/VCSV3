unit rmxBitmaper;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, rtcScrPlayback, rtcInfo,
  rmxVideoStorage, rmxVideoFile, rmxVideoPacketTypes;

type
  TRmxBitmaper = class
  private
    FDecoder: TRtcScreenDecoder;
    FReader: TRMXVideoReader;
    FFrameCount: Integer;
    FTimeStamp: Int64;
    FDuration: Int64;

    FFrames: array of Boolean; // true Load // falst repeat prior
    FPosFrame: Integer;
    FFPS: Integer;
    FInterval: Integer;

    procedure MeasureTiming();
    procedure SetFPS(const Value: Integer);
    function GetMeasuredFrameCount: Integer;
    function GetIsKey: Boolean;
  public
    constructor Create(const FileName: string); overload;
    constructor Create(const AReader: TRMXVideoReader); overload;
    destructor Destroy; override;
    function DecodeNext: Boolean;
    function Bitmap: TBitmap;
    property TimeStamp: Int64 read FTimeStamp;
    property Duration: Int64 read FDuration;
    property FrameCount: Integer read FFrameCount;
    property Reader: TRMXVideoReader read FReader;
    property Decoder: TRtcScreenDecoder read FDecoder;
    property FPS: Integer read FFPS write SetFPS;
    property Interval: Integer read FInterval;
    property MeasuredFrameCount: Integer read GetMeasuredFrameCount;
    property Position: Integer read FPosFrame;
    property IsKey: Boolean read GetIsKey;

  end;

implementation

{ TRmxBitmaper }

function TRmxBitmaper.Bitmap: TBitmap;
begin
  Result := FDecoder.Image
end;

constructor TRmxBitmaper.Create(const FileName: string);
begin
  Create(TRMXVideoReader.Create(FileName, TRMXVideoFileWin));
end;

constructor TRmxBitmaper.Create(const AReader: TRMXVideoReader);
begin
  inherited Create;
  FReader := AReader;
  FDecoder := TRtcScreenDecoder.Create;
  FFrameCount := FReader.RMXFile.Header.Origin.NumberOfFrames;
  FDuration := FReader.RMXFile.Header.Origin.Duration;
  FPosFrame := -2;
end;

function TRmxBitmaper.DecodeNext: Boolean;
var
  code: RtcString;
begin
  if FPS > 0 then
    begin

      Inc(FPosFrame);

      if Length(FFrames) <= FPosFrame then
        begin
          Result := false;
          exit;
        end;


      if not FFrames[FPosFrame] then
        begin
          Result := true;
          exit;
        end;

    end;

  Result := FReader.ReadRTCCode(code, FTimeStamp);
  if Result then
    begin
      FDecoder.SetScreenData(code);
    end;
end;

destructor TRmxBitmaper.Destroy;
begin
  FDecoder.Free;
  FReader.Free;
  inherited;
end;

function TRmxBitmaper.GetIsKey: Boolean;
begin
  Result := false;
  if (FPosFrame >=0)  and (FPosFrame < Length(FFrames)) then
   Result := FFrames[FPosFrame];
end;

function TRmxBitmaper.GetMeasuredFrameCount: Integer;
begin
  Result := Length(FFrames);
  if Result = 0 then
    Result := FFrameCount;

end;

procedure TRmxBitmaper.MeasureTiming;
var
  r: TRMXVideoFile;
  s: TRMXSectionData;
  sl: TRMXSectionList;
  h: TRMXHeader;
  i, k: Integer;
  cur, ellapse: Int64;
  pkt: PRMXDataPacket;
  interval_pow: Double;
begin
  FPosFrame := -1;
  if FPS <= 0 then
    begin
      SetLength(FFrames, 0);
      exit;
    end;

  r := FReader.RMXFile;
  h := r.Header;
  sl := h.GetSectionList;
  k := 0;
  cur := 0;
  FInterval := 1000 div FPS;
  if FPS = 30 then
    interval_pow := FInterval * 1.18 else
    interval_pow := FInterval;
  SetLength(FFrames, Integer(h.NumberOfFrames) * FPS);
  for I := 0 to sl.Count-1 do
    begin
      s := sl[i];
      s.First;
      repeat
        pkt := s.GetPacketDirect;
        if k = 0 then
          begin
            FFrames[k] := true;
            cur := pkt.TimeStampEllapsed;
            Inc(k);
          end
        else
          begin
            ellapse := pkt.TimeStampEllapsed;
            while ellapse - cur > interval_pow do
              begin
                FFrames[k] := false;
                Inc(k);
                cur := cur + FInterval;
              end;
            cur := ellapse;
            FFrames[k] := true;
            Inc(k);
          end;

      until (not s.Next);
    end;
  SetLength(FFrames, k);
end;

procedure TRmxBitmaper.SetFPS(const Value: Integer);
begin
  if FFPS <> Value then
    begin
      FFPS := Value;
      MeasureTiming;
    end;
end;

end.
