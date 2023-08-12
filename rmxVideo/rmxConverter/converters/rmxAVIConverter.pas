unit rmxAVIConverter;

interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, CmdLineParams,
  rmxVideoFile, rmxVideoStorage, rmxBitmaper, RMXConverterBase,
  VideoRecorder;

type


  TRMXAVIConverter = class(TRMXConverter)
  private
     procedure LoopMessage;
  public
    procedure Proccess(const Bitmaper: TRmxBitmaper; const Params: PParamConverter); override;
  end;

implementation

{ TRMXAVIConverter }

procedure TRMXAVIConverter.LoopMessage;
var
  msg: TMsg;
begin
  while PeekMessage(msg,0, 0, 0, 0) do
    begin
      if GetMessage(msg, 0, 0, 0) then
        begin
          TranslateMessage(msg);
          DispatchMessage(msg)
        end;
    end;

end;

procedure TRMXAVIConverter.Proccess(const Bitmaper: TRmxBitmaper;
  const Params: PParamConverter);
const
  AVIIF_KEYFRAME              = $00000010 ;
var
  avi: TVideoRecorderAVIVFW;
  header: TRMXHeader;
  i: Integer;
  fps: Integer;
  static_key: Boolean;
begin
  Abort := false;
  header := Bitmaper.Reader.RMXFile.Header;
  fps :=  Bitmaper.FPS;
  Progress.Max :=  Bitmaper.MeasuredFrameCount;
  static_key := false;
  if fps = 0 then
    begin
      fps :=  Round((header.NumberOfFrames * 1000) / header.Duration);
      Progress.Max :=  header.NumberOfFrames;
      static_key := true;
    end;


  Bitmaper.DecodeNext;
  avi := TVideoRecorderAVIVFW.Create(0, ExpandFileName(Params^.output), fps, nil, Bitmaper.Bitmap);
  try
    i := 0;
    avi.KEY := AVIIF_KEYFRAME;
    repeat
      if not static_key and Bitmaper.IsKey then
        avi.KEY := AVIIF_KEYFRAME else
        avi.KEY := 0;

      avi.AddVideoFrame(Bitmaper.Bitmap);
      Inc(i);
      Progress.Position := i;
      LoopMessage;
      if Abort then break;



    until not Bitmaper.DecodeNext;

  finally
    avi.Free;
  end;

end;

end.
