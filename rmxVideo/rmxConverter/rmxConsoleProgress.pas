unit rmxConsoleProgress;

interface
uses
  Winapi.Windows,
  System.SysUtils,
  RMXConverterBase;


type
  TRMXConsoleProgress = class(TRMXConverterProgress)
  private
    FCoord: _COORD;
    FHandle: THandle;
    FBarWidth: Integer;
    FBuffer: PChar;

    procedure SetBarWidth(const Value: Integer);

  protected
    procedure UpdateProgress; override;
  public
    constructor Create(Context: Pointer); override;
    destructor Destroy; override;
    property BarWidth: Integer read FBarWidth write SetBarWidth;
  end;

implementation


{ **************************************************************************** }
{                               TTConsoleProgress                              }
{ **************************************************************************** }

constructor TRMXConsoleProgress.Create(Context: Pointer);
var
  bi: TConsoleScreenBufferInfo;
begin
  inherited;
  FHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(FHandle, bi);
  FCoord := bi.dwCursorPosition;
  FCoord.X := 0;
  FBarWidth := 70;
  GetMem(FBuffer, (FBarWidth + 20) * SizeOf(Char));
  Writeln('');
end;

destructor TRMXConsoleProgress.Destroy;
begin
  FreeMem(FBuffer);
  inherited;
end;

procedure TRMXConsoleProgress.SetBarWidth(const Value: Integer);
begin
  if FBarWidth <> Value then
    begin
      FBarWidth := Value;
      ReallocMem(FBuffer, (FBarWidth + 20) * SizeOf(Char));
      UpdateProgress;
    end;
end;



procedure TRMXConsoleProgress.UpdateProgress;
var
  s: string;
  i, pos: Integer;
  P: PChar;
begin
  FillChar(FBuffer^, (FBarWidth + 20) * SizeOf(Char), 0);
  P := FBuffer;
  FProgress := Position / Max;


      P[0] := '[';
      Inc(P);
      pos := Round(BarWidth * FProgress);
      for i := 0 to BarWidth-1 do
        begin
          if i < pos then P^ := '=' else
          if i = pos then P^ := '>' else
          P^ := ' ';
          Inc(P);
        end;
      if pos = BarWidth then
        P^ := '>';

      P^ := ']';
      Inc(P);
      s := ' ' +Round(FProgress * 100).ToString + ' %';
      Move(Pointer(s)^, P^, Length(s) * SizeOf(Char));
      WriteConsoleOutputCharacter(FHandle, FBuffer, (P-FBuffer)+Length(s), FCoord, PCardinal(@i)^);


end;


end.
