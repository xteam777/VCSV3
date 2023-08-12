unit PlayImage;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  rmxBitmaper, Vcl.ExtCtrls, System.Diagnostics, System.TimeSpan, rmxVideoFile, rmxVideoPacketTypes;

type
  TRMXPlayerProgress = record
    frames_min,
    frames_max,
    frames_pos: Integer;
    time_pos: Int64;
    time_duration: Int64;
  end;

  TOnFrameImage = procedure (Sender: TObject; Image: TBitmap; const Progress: TRMXPlayerProgress) of object;


  TPlayerHandler = class
  private
    FBitmaper: TRmxBitmaper;
    FRunning: Boolean;
    FOnFrame: TOnFrameImage;
    FPause: Boolean;
    FTimer: TTimer;
    FFPS: Integer;
    FProgress: TRMXPlayerProgress;
    FTimeEllapsed: Int64;

    procedure OnTimer(Sender: TObject);
    procedure PlayFrame();
    procedure SetFPS(const Value: Integer);
    procedure SetPause(const Value: Boolean);
  public
    constructor Create();
    destructor Destroy; override;
    procedure Play(const AFileName: string);
    procedure Stop;
    function CurrentFrame: TBitmap;
    property Running: Boolean read FRunning;// write FRunning;
    property Pause: Boolean read FPause write SetPause;
    property OnFrame: TOnFrameImage read FOnFrame write FOnFrame;
    property FPS: Integer read FFPS write SetFPS;
  end;

implementation

{ TPlayerHandler }

constructor TPlayerHandler.Create;
begin
  inherited Create;
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := false;
  FTimer.OnTimer := OnTimer;
  SetFPS(30);
end;

function TPlayerHandler.CurrentFrame: TBitmap;
begin
  Result := nil;
  if Assigned(FBitmaper) and (FPause or not FRunning) then
    Result := FBitmaper.Bitmap;

end;

destructor TPlayerHandler.Destroy;
begin
  Stop;
  FTimer.Free;
  inherited;
end;



procedure TPlayerHandler.OnTimer(Sender: TObject);
begin
  PlayFrame;
end;

procedure TPlayerHandler.Play(const AFileName: string);
begin
  if FRunning then
    raise Exception.Create('Another file is plaing');

  FBitmaper :=  TRmxBitmaper.Create(AFileName);
  FBitmaper.FPS := FPS;
  FRunning := true;
  FPause := false;
  FProgress.frames_min := 0;
  FProgress.frames_max := FBitmaper.MeasuredFrameCount-1;
  FProgress.frames_pos := 0;
  FProgress.time_pos := 0;
  FProgress.time_duration := FBitmaper.Duration;
  FTimer.Enabled := true;
end;

procedure TPlayerHandler.PlayFrame;
begin
  if not FRunning then exit;



  if Assigned(FOnFrame) and  FBitmaper.DecodeNext then
    begin
      FProgress.frames_pos := FBitmaper.Position;
      FOnFrame(Self, FBitmaper.Bitmap, FProgress);
      FProgress.time_pos := FProgress.time_pos + FBitmaper.Interval;

    end else
    begin
      //FTimer.Enabled := false;
      Stop;
    end;
end;

procedure TPlayerHandler.SetFPS(const Value: Integer);
begin
  if (FFPS <> Value) and not Running then
    begin
      FFPS := Value;
      FTimer.Interval := 1000 div Value;
    end;

end;

procedure TPlayerHandler.SetPause(const Value: Boolean);
begin
  if FRunning and (FPause <> Value) then
    begin
      FPause := Value;
      FTimer.Enabled := not Value;
    end;
end;

procedure TPlayerHandler.Stop;
begin
  FTimer.Enabled := false;
  FRunning := false;
  FPause := false;
  FreeAndNil(FBitmaper);
end;

end.
