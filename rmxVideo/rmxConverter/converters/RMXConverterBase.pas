unit rmxConverterBase;

interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, CmdLineParams,
  rmxVideoStorage, rmxBitmaper;

type
  TRMXConverterProgress = class
  private
    FMax: Integer;
    FMin: Integer;
    FPosition: Integer;
    FContext: Pointer;

    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(const Value: Integer);

  protected
    FProgress: Double;
    procedure UpdateProgress; virtual; abstract;
  public
    constructor Create(Context: Pointer); virtual;
    property Max: Integer read FMax write SetMax;
    property Min: Integer read FMin write SetMin;
    property Position: Integer read FPosition write SetPosition;
    property Progress: Double read FProgress;
    property Context: Pointer read FContext;


  end;

  TRMXConverterProgressClass = class of TRMXConverterProgress;

  PParamConverter = ^TParamConverter;
  TParamConverter = record
    output: string
  end;

  TRMXConverter = class
  private
    FProgress: TRMXConverterProgress;
    FContext: Pointer;
    FAbort: Boolean;
  protected
    procedure UpdateProgress(Min, Max, Position: Integer);
  public
    constructor Create(const ProgressClass: TRMXConverterProgressClass; UserContext: Pointer); virtual;
    destructor Destroy; override;
    procedure Proccess(const Bitmaper: TRmxBitmaper; const Params: PParamConverter); virtual; abstract;
    property Progress: TRMXConverterProgress read FProgress;
    property Abort: Boolean read FAbort write FAbort;
    property Context: Pointer read FContext;
  end;

 TRMXConverterClass = class of TRMXConverter;


implementation

{ **************************************************************************** }
{                               TRMXConverter                                  }
{ **************************************************************************** }


constructor TRMXConverter.Create(const ProgressClass: TRMXConverterProgressClass;
  UserContext: Pointer);
begin
  inherited Create;
  if Assigned(ProgressClass) then
    FProgress := ProgressClass.Create(UserContext);
  FContext := UserContext;
end;

destructor TRMXConverter.Destroy;
begin
  FProgress.Free;
  inherited;
end;

procedure TRMXConverter.UpdateProgress(Min, Max, Position: Integer);
begin
  if Assigned(FProgress) then
    begin
      FProgress.Min := Min;
      FProgress.Max := Max;
      FProgress.Position := Position;
    end;
end;

{ **************************************************************************** }
{                               TRMXConverterProgress                          }
{ **************************************************************************** }


constructor TRMXConverterProgress.Create(Context: Pointer);
begin
  inherited Create;
  FMin      := 1;
  FMax      := 100;
  FPosition := 0;
  FContext  := Context;
end;

procedure TRMXConverterProgress.SetMax(const Value: Integer);
begin
  if FMax <> Value then
    begin
      FMax := Value;
      UpdateProgress;
    end;
end;

procedure TRMXConverterProgress.SetMin(const Value: Integer);
begin
  if FMin <> Value then
    begin
      FMin := Value;
      UpdateProgress;
    end;
end;

procedure TRMXConverterProgress.SetPosition(const Value: Integer);
begin
  if FPosition <> Value then
    begin
      FPosition := Value;
      UpdateProgress;
    end;
end;

end.
