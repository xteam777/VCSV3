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
    FPosition: Integer;
    FReplayFrame: Boolean;

    procedure OnTimer(Sender: TObject);
    procedure PlayFrame();
    procedure SetFPS(const Value: Integer);
    procedure SetPause(const Value: Boolean);
    procedure SetPosition(Value: Integer);
  public
    constructor Create();
    destructor Destroy; override;
    procedure Play(const AFileName: string);
    procedure Stop;
    function CurrentFrame: TBitmap;
    function PositionToTime(APosition: Integer): Int64;
    property Running: Boolean read FRunning;// write FRunning;
    property Pause: Boolean read FPause write SetPause;
    property OnFrame: TOnFrameImage read FOnFrame write FOnFrame;
    property FPS: Integer read FFPS write SetFPS;
    property Position: Integer read FPosition write SetPosition;
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



  if Assigned(FOnFrame) and (FReplayFrame or FBitmaper.DecodeNext) then
    begin
      FPosition := FBitmaper.Position;
      FProgress.frames_pos := FBitmaper.Position;
      FProgress.time_pos := FPosition * FBitmaper.Interval;
      FOnFrame(Self, FBitmaper.Bitmap, FProgress);


    end else
    begin
      //FTimer.Enabled := false;
      Stop;
    end;
end;

function TPlayerHandler.PositionToTime(APosition: Integer): Int64;
begin
  if Assigned(FBitmaper) then
    Result := APosition * FBitmaper.Interval else
    Result := APosition;
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

procedure TPlayerHandler.SetPosition(Value: Integer);
begin
  if Value < 0 then Value := 0;

  if FPosition <> Value then
    begin
      FBitmaper.Position := Value;
      FPosition := Value;
      FReplayFrame := true;
      if FRunning then
        PlayFrame;
      FReplayFrame := false;
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
