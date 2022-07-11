unit uPowerWatcher;

interface

uses
  Winapi.Windows, System.Classes, System.SyncObjs, Winapi.Messages;

{$M+}

type
  TPowerSource = (PoAc = 0, PoDc = 1, PoHot = 2);
  TPowerEvent = procedure of object;

  TPowerWatcher = class(TComponent)
  private
    FMyHWND: HWND;
    FHPOWERNOTIFY: HPOWERNOTIFY;
    FOnPowerPause, FOnPowerResume: TPowerEvent;
    procedure DoPowerSourceChanged(const Value: TPowerSource);
    procedure WndHandler(var Msg: TMessage);
    procedure SetOnPowerPause(const Value: TPowerEvent);
    procedure SetOnPowerResume(const Value: TPowerEvent);
  published
    property OnPowerPause: TPowerEvent read FOnPowerPause write SetOnPowerPause;
    property OnPowerResume: TPowerEvent read FOnPowerResume write SetOnPowerResume;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

const
  GUID_ACDC_POWER_SOURCE: TGUID = '{5D3E9A59-E9D5-4B00-A6BD-FF34FF516548}';

implementation

uses
  System.SysUtils;

{ TPowerWatcher }

constructor TPowerWatcher.Create;
begin
  inherited;
  FMyHWND := AllocateHWND(WndHandler);
  FHPOWERNOTIFY := RegisterPowerSettingNotification(FMyHWND, GUID_ACDC_POWER_SOURCE, DEVICE_NOTIFY_WINDOW_HANDLE);
end;

destructor TPowerWatcher.Destroy;
begin
  DeallocateHWND(FMyHWND);
  UnregisterPowerSettingNotification(FHPOWERNOTIFY);
  inherited;
end;

procedure TPowerWatcher.DoPowerSourceChanged(const Value: TPowerSource);
begin
  if Assigned(FOnPowerResume) then
    FOnPowerResume;
end;

procedure TPowerWatcher.SetOnPowerPause(const Value: TPowerEvent);
begin
  FOnPowerPause := Value;
end;

procedure TPowerWatcher.SetOnPowerResume(const Value: TPowerEvent);
begin
  FOnPowerResume := Value;
end;

procedure TPowerWatcher.WndHandler(var Msg: TMessage);
begin
  if (Msg.Msg = WM_POWERBROADCAST) then
  begin
    if (Msg.WParam = PBT_APMRESUMEAUTOMATIC) then
    begin
  //    if PPowerBroadcastSetting(Msg.LParam)^.PowerSetting = GUID_ACDC_POWER_SOURCE then
  //      DoPowerResume(TPowerSource(PPowerBroadcastSetting(Msg.LParam)^.Data[0]));
      if Assigned(FOnPowerResume) then
        FOnPowerResume;
    end
    else
    if (Msg.WParam = PBT_APMSUSPEND) then
    begin
  //    if PPowerBroadcastSetting(Msg.LParam)^.PowerSetting = GUID_ACDC_POWER_SOURCE then
  //      DoPowerResume(TPowerSource(PPowerBroadcastSetting(Msg.LParam)^.Data[0]));
      if Assigned(FOnPowerPause) then
        FOnPowerPause;
    end;
  end
  else
    Msg.Result := DefWindowProc(FMyHWND, Msg.Msg, Msg.WParam, Msg.LParam);
end;

end.
