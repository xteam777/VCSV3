unit ConsoleAppliaction;

interface
uses
  Winapi.Windows, System.SysUtils, System.Classes;


type
  TOnConsoleTerminate = procedure (Sender: TObject; Context: Pointer) of object;

  TConsoleApplication = class
  private
    FOnTerminate: TOnConsoleTerminate;
    FTerminated: Boolean;
    FOutputHandle: THandle;
    FContext: Pointer;
    procedure SetQuickMode(const Value: Boolean);
    function GetQuickMode: Boolean;
    function GetHideCursor: Boolean;
    procedure SetHideCursor(const Value: Boolean);
  public
    constructor Create(const ATitle: string; Context: Pointer);
    destructor Destroy; override;
    procedure Terminate;
    property OnTerminate: TOnConsoleTerminate read FOnTerminate write FOnTerminate;
    property Terminated: Boolean read FTerminated;
    property QuickMode: Boolean read GetQuickMode write SetQuickMode;
    property HideCursor: Boolean read GetHideCursor write SetHideCursor;
    property Context: Pointer read FContext write FContext;
  end;

implementation

var
  app: TConsoleApplication;

//==============================================================================
function ConsoleEventProc(CtrlType: DWORD): BOOL; stdcall;
begin
  if (CtrlType = CTRL_CLOSE_EVENT) or (CtrlType = CTRL_C_EVENT) then
  begin
    app.Terminate;
//    if Assigned(OnConsolteTerminate) then
//      OnConsolteTerminate();
    //  доп. код
  end;
  Result := True;
end;

{ **************************************************************************** }
{                               TConsoleApplication                            }
{ **************************************************************************** }


constructor TConsoleApplication.Create(const ATitle: string; Context: Pointer);
begin
  inherited Create;
  FOutputHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  app := Self;
  SetConsoleCP(GetACP);
  SetConsoleOutputCP(GetACP);
  SetConsoleTitle(PChar(ATitle));
  SetConsoleCtrlHandler(@ConsoleEventProc, True);
  FContext := Context;
end;

destructor TConsoleApplication.Destroy;
begin

  inherited;
end;

function TConsoleApplication.GetHideCursor: Boolean;
var
  CCI: TConsoleCursorInfo;
begin
  GetConsoleCursorInfo(FOutputHandle, CCI);
  Result := CCI.bVisible;
end;

function TConsoleApplication.GetQuickMode: Boolean;
var
  mode: Cardinal;
begin
  Win32Check(GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), mode));
  Result := mode and ENABLE_QUICK_EDIT_MODE = ENABLE_QUICK_EDIT_MODE ;
end;

procedure TConsoleApplication.SetHideCursor(const Value: Boolean);
var
  CCI: TConsoleCursorInfo;
begin
  Win32Check(GetConsoleCursorInfo(FOutputHandle, CCI));
  if Value <>  CCI.bVisible then
    begin
      CCI.bVisible := false;
      Win32Check(SetConsoleCursorInfo(FOutputHandle, CCI));
    end;
end;

procedure TConsoleApplication.SetQuickMode(const Value: Boolean);
var
  mode: Cardinal;
begin

  Win32Check(GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), mode));
  if Value =  (mode and ENABLE_QUICK_EDIT_MODE = ENABLE_QUICK_EDIT_MODE) then exit;

  if Value then
    mode := mode or ENABLE_QUICK_EDIT_MODE or ENABLE_EXTENDED_FLAGS else
    mode := (mode or ENABLE_EXTENDED_FLAGS) and not ENABLE_QUICK_EDIT_MODE;
  Win32Check(SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), mode));

end;

procedure TConsoleApplication.Terminate;
begin
  if FTerminated then exit;
  FTerminated := true;
  if Assigned(FOnTerminate) then
    FOnTerminate(Self, FContext);
end;

end.
