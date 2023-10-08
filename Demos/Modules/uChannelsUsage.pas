unit uChannelsUsage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.ExtCtrls, Vcl.Grids,
  AdvObj, BaseGrid, AdvGrid, ColorSpeedButton, uVircessTypes, Vcl.StdCtrls,
  rtcSystem, rtcInfo, rtcConn, rtcFunction, rtcCliModule, SendDestroyToGateway;

type
  TfChannelsUsage = class(TForm)
    sgChannels: TAdvStringGrid;
    pTop: TPanel;
    pBtnClose: TPanel;
    bClose: TColorSpeedButton;
    pBtnCloseAll: TPanel;
    bCloseAll: TColorSpeedButton;
    pBottom: TPanel;
    bOK: TButton;
    rResult: TRtcResult;
    tRefresh: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure rResultReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure bOKClick(Sender: TObject);
    procedure tRefreshTimer(Sender: TObject);
    procedure bCloseMouseEnter(Sender: TObject);
    procedure bCloseMouseLeave(Sender: TObject);
    procedure bCloseClick(Sender: TObject);
    procedure bCloseAllClick(Sender: TObject);
  private
    { Private declarations }
    FOnCustomFormClose: TOnCustomFormEvent;
    function GetActionStr(AAction: String): String;
  public
    { Public declarations }
    FLoggedIn: Boolean;
    FAccountUID, FDeviceUID: String;
    FTimerModule: TRtcClientModule;
    FSendManualLogoutToControl: TSendManualLogoutToControl;
    procedure GetConnections;
    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
  end;

var
  fChannelsUsage: TfChannelsUsage;

implementation

{$R *.dfm}

procedure TfChannelsUsage.GetConnections;
begin
  with FTimerModule do
  try
    with Data.NewFunction('Connection.GetList') do
    begin
      asBoolean['IsAccount'] := FLoggedIn;
      asString['AccountUID'] := FAccountUID;
      asString['DeviceUID'] := FDeviceUID;
      Call(rResult);
    end;
  except
    on E: Exception do
      Data.Clear;
  end;

  tRefresh.Enabled := True;
end;

procedure TfChannelsUsage.bCloseAllClick(Sender: TObject);
var
  i: Integer;
begin
  i := sgChannels.RowCount - 1;
  while i > 0 do
  begin
    FSendManualLogoutToControl(sgChannels.Cells[4, i], sgChannels.Cells[0, i], sgChannels.Cells[1, i]);

    i := i - 1;
  end;
end;

procedure TfChannelsUsage.bCloseClick(Sender: TObject);
begin
  if sgChannels.Row > 0 then
    FSendManualLogoutToControl(sgChannels.Cells[4, sgChannels.Row], sgChannels.Cells[0, sgChannels.Row], sgChannels.Cells[1, sgChannels.Row]);
end;

procedure TfChannelsUsage.bCloseMouseEnter(Sender: TObject);
begin
  TColorSpeedButton(Sender).Color := RGB(231, 84, 87);
end;

procedure TfChannelsUsage.bCloseMouseLeave(Sender: TObject);
begin
  TColorSpeedButton(Sender).Color := RGB(241, 94, 97);
end;

procedure TfChannelsUsage.bOKClick(Sender: TObject);
begin
  Close;
end;

procedure TfChannelsUsage.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose;

  tRefresh.Enabled := False;

  Action := caFree;
end;

procedure TfChannelsUsage.FormCreate(Sender: TObject);
begin
  sgChannels.RowCount := 1;
  sgChannels.Cells[0, 0] := 'Оператор';
  sgChannels.Cells[1, 0] := 'Партнер';
  sgChannels.Cells[2, 0] := 'Тип подключения';
  sgChannels.Cells[3, 0] := 'Начало';
  sgChannels.Cells[4, 0] := 'Action';
  sgChannels.HideColumns(4, 4);
end;

procedure TfChannelsUsage.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    bOKClick(Sender);
end;

procedure TfChannelsUsage.rResultReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  i: Integer;
begin
  if Result.isType = rtc_Exception then
    Exit
  else
  if Result.isType <> rtc_DataSet then
    Exit
  else
  with Result.asDataSet do
  begin
    sgChannels.RowCount := RowCount + 1;

    i := 0;
    First;
    while not Eof do
    begin
      sgChannels.Cells[0, i + 1] := asString['UserFrom'];
      sgChannels.Cells[1, i + 1] := asString['UserTo'];
      sgChannels.Cells[2, i + 1] := GetActionStr(asString['Action']);
      sgChannels.Cells[3, i + 1] := DateTimeToStr(asDateTime['CreateDate']);
      sgChannels.Cells[4, i + 1] := asString['Action'];

      i := i + 1;
      Next;
    end;
  end;
end;

procedure TfChannelsUsage.tRefreshTimer(Sender: TObject);
begin
  GetConnections;
end;

function TfChannelsUsage.GetActionStr(AAction: String): String;
begin
  if AAction = 'file' then
    Result := 'Передача файлов'
  else
  if AAction = 'chat' then
    Result := 'Чат'
  else
  if AAction = 'desk' then
    Result := 'Управление'
  else
    Result := '';
end;

end.
