unit rmxVideoStorage;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, rtcInfo, rmxVideoPacketTypes,
  rmxVideoFile, System.Diagnostics, System.TimeSpan, Compressions;

type
  TRMXVideoWriter = class
  private
    FRMXFile: TRMXVideoFile;
    FSection: TRMXSectionData;
    FTimer: TStopwatch;
    FFrameCount: Cardinal;
    procedure InitalizeFile;
    procedure FilalizeFile;
  public
    constructor Create(const FileName: string; FileClass: TRMXVideoFileClass);
    destructor Destroy; override;

    // add new packet to file
    procedure WriteRTCCode(const code: RtcString);
    procedure WriteRTCRec(const rec: TRtcRecord);
    property RMXFile: TRMXVideoFile read FRMXFile;
    property FrameCount: Cardinal read FFrameCount;
  end;

  TRMXVideoReader = class
  private
    FRMXFile: TRMXVideoFile;
    FSection: TRMXSectionData;
    FSectionList: TRMXSectionList;
    FIndex: Cardinal;
    procedure InitalizeFile;
    procedure FilalizeFile;

  public
    constructor Create(const FileName: string; FileClass: TRMXVideoFileClass);
    destructor Destroy; override;

    // add new packet to file
    function ReadRTCCode(out code: RtcString; out TimeStamp: Int64): Boolean;
    function ReadRTCRec(out rec: TRtcRecord; out TimeStamp: Int64): Boolean;
    property RMXFile: TRMXVideoFile read FRMXFile;
  end;

implementation

{ TRMXVideoWriter }

constructor TRMXVideoWriter.Create(const FileName: string; FileClass: TRMXVideoFileClass);
begin
  inherited Create;
  FRMXFile := FileClass.Create(FileName, false);
  InitalizeFile;
end;

destructor TRMXVideoWriter.Destroy;
begin
  FilalizeFile;
  FRMXFile.Free;
  inherited;
end;

procedure TRMXVideoWriter.FilalizeFile;
var
  header: PRMXHeaderFile;
begin
  FTimer.Stop;
  FRMXFile.SectionList.EndSection(FSection);
  header := FRMXFile.Header.Origin;
  header.Duration := FTimer.ElapsedMilliseconds;
end;

procedure TRMXVideoWriter.InitalizeFile;
begin
  FTimer := TStopwatch.Create;
  FRMXFile.Header.SetCompressionClass(TCompressionLZMA2);
  FTimer.Start;
end;

procedure TRMXVideoWriter.WriteRTCCode(const code: RtcString);
var
  sz: Cardinal;
  pkt: TRMXPacketData;
begin
  sz := Length(code) * SizeOf(code[1]);
  if not Assigned(FSection) or not FSection.CanExpandSize(SizeOf(TRMXDataPacket) + sz) then
    begin
      FRMXFile.SectionList.EndSection(FSection);
      FSection := FRMXFile.SectionList.CreateSection(tisData);
    end;
  pkt := TRMXPacketData.Create(nil);
  try
    pkt.WriteData(Pointer(code)^, sz);
    pkt.TimeStampEllapsed := FTimer.ElapsedMilliseconds;
    FSection.AddPacket(pkt);
  finally
    pkt.Free;
  end;
end;

procedure TRMXVideoWriter.WriteRTCRec(const rec: TRtcRecord);
begin
  WriteRTCCode(rec.toCode)
end;

{ TRMXVideoReader }

constructor TRMXVideoReader.Create(const FileName: string;
  FileClass: TRMXVideoFileClass);
begin
  inherited Create;
  FRMXFile := FileClass.Create(FileName, true);
  InitalizeFile;
end;

destructor TRMXVideoReader.Destroy;
begin
  FilalizeFile;
  FRMXFile.Free;
  inherited;
end;

procedure TRMXVideoReader.FilalizeFile;
begin

end;

procedure TRMXVideoReader.InitalizeFile;
begin
  FRMXFile.Header.SetCompressionClass(TCompressionLZMA2);
end;

function TRMXVideoReader.ReadRTCCode(out code: RtcString; out TimeStamp: Int64): Boolean;
var
  pkt: TRMXPacketData;
begin
  Result := false;
  if not Assigned(FSectionList)  then
    begin
      FIndex := 0;
      FSectionList := FRMXFile.SectionList;
      FSection := FSectionList.Sections[FIndex];
      if FSection.PacketCount = 0 then exit;

      FSection.First;
    end

  else

  if not FSection.Next then
    begin
      Inc(FIndex);
      if FIndex >= Integer(FSectionList.Count) then exit;
      FSection := FSectionList.Sections[FIndex];
      if FSection.PacketCount = 0 then exit;
      FSection.First;
    end;

  pkt := FSection.GetPacket(FSection.Position);
  try
    SetLength(code, pkt.DataSize div SizeOf(Code[1]));
    pkt.ReadData(Pointer(code)^, pkt.DataSize);
    TimeStamp := pkt.TimeStampEllapsed;
  finally
    pkt.Free;
  end;
  Result := true;

end;

function TRMXVideoReader.ReadRTCRec(out rec: TRtcRecord; out TimeStamp: Int64): Boolean;
var
  code: RtcString;
begin
  Result := ReadRTCCode(code, TimeStamp);
  if Result then
      rec := TRtcRecord.FromCode(code);
end;

end.
