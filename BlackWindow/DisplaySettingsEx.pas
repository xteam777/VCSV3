unit DisplaySettingsEx;

interface
uses
  Winapi.Windows, System.SysUtils, System.Classes;


type
(*
" Generic PnP Monitor "

This happens because the screen's have no driver installed and therefore the
actual device itself is running with the Generic PnP Monitor Driver.
Look in Device Manager and you will see.

Im pretty sure there is no way to achieve what you are trying to achieve
without install the monitor's drivers from the manufacturer.
*)

  TMonitorResolution = record
    width, height: Integer;
  end;

  TMonitorResolutionList = array of TMonitorResolution;

  TMonitorInfo = record
    DeviceName: string;
    MonitorName: string;
    AdapterName: string;
    IsPrimary: Boolean;
    CurrentResolution: Integer;
    Resolutions: TMonitorResolutionList;
  end;
  TMonitorInfoList = array of TMonitorInfo;

    function GetMonitorListEx: TMonitorInfoList;
    function GetMonitorResolutions(const DeviceName: string; out Current: Integer): TMonitorResolutionList;
    function SetMonitorResolution(const DeviceName: string;
      Width, Height: Integer; Persist: Boolean): Integer;
    procedure CheckDisplaySettingsResult(code: Integer);
implementation

const
  EDS_RAWMODE            = $00000002;
  EDS_ROTATEDMODE        = $00000004;
  ENUM_CURRENT_SETTINGS  = DWORD(-1);
  ENUM_REGISTRY_SETTINGS = DWORD(-2);

type
  TDupValues = record
    Count: Integer;
    Buf: TMonitorResolutionList;
    procedure Init;
    function AddIfNotExists(w, h: Integer): Integer;
  end;

procedure CheckDisplaySettingsResult(code: Integer);
const
  // #if(_WIN32_WINNT >= 0x0501)
  DISP_CHANGE_BADDUALVIEW = -6;
var
  s: string;
begin
  s := '';
  case code of
    DISP_CHANGE_SUCCESSFUL  : ; //The settings change was successful.
    DISP_CHANGE_BADDUALVIEW : s := 'The settings change was unsuccessful because the system is DualView capable.';
    DISP_CHANGE_BADFLAGS    : s := 'An invalid set of flags was passed in.';
    DISP_CHANGE_BADMODE     : s := 'The graphics mode is not supported.';
    DISP_CHANGE_BADPARAM    : s := 'An invalid parameter was passed in. This can include an invalid flag or combination of flags.';
    DISP_CHANGE_FAILED      : s := 'The display driver failed the specified graphics mode.';
    DISP_CHANGE_NOTUPDATED  : s := 'Unable to write settings to the registry.';
    DISP_CHANGE_RESTART     : s := 'NO ERROR -> The computer must be restarted for the graphics mode to work.';
  end;
  if s <> '' then
    raise Exception.Create(s);

end;




function GetMonitorResolutions(
  const DeviceName: string; out Current: Integer): TMonitorResolutionList;
var
  mNum: Cardinal;
  dev_mode, cur_mode: TDevMode;
  dup: TDupValues;
  i: Integer;
begin
  current := -1;
  dup.Init;
  if not EnumDisplaySettings(PChar(DeviceName), ENUM_CURRENT_SETTINGS, cur_mode) then
    Exit;

  FillChar(dev_mode, SizeOf(dev_mode), 0);
  dev_mode.dmSize := SizeOf(dev_mode);
  mNum := 0;

  while EnumDisplaySettings(PChar(DeviceName), mNum, dev_mode) do
  begin
    if (dev_mode.dmDisplayFrequency = cur_mode.dmDisplayFrequency) and
      (dev_mode.dmFields and (DM_PELSWIDTH or DM_PELSHEIGHT) <> 0) then
    begin
      i := dup.AddIfNotExists(dev_mode.dmPelsWidth, dev_mode.dmPelsHeight);
      if (dev_mode.dmPelsWidth  = cur_mode.dmPelsWidth) and
         (dev_mode.dmPelsHeight = cur_mode.dmPelsHeight) then
          current := i;
    end;

    Inc(mNum);
  end;

  Result := dup.buf;
  SetLength(Result, dup.Count);
end;


procedure InvertResolutionArray(var Info: TMonitorResolutionList);
var
  i, j: Integer;
  temp: TMonitorResolution;
begin
  i := Low(Info);
  j := High(Info);

  while i < j do
  begin
    // Swap the elements
    temp := Info[i];
    Info[i] := Info[j];
    Info[j] := temp;

    // Move towards the array's center
    Inc(i);
    Dec(j);
  end;
end;

function GetMonitorListEx: TMonitorInfoList;
var
  dc: TDisplayDevice;
  num, monitor_idx: Cardinal;
  device, adapter: string;
  is_primary: Boolean;
begin
  Num := 0;
  monitor_idx := 0;
  dc.cb := SizeOf(dc);
  while EnumDisplayDevices(nil,  Num, dc, EDD_GET_DEVICE_INTERFACE_NAME) do
    begin
      device  := dc.DeviceName;
      adapter := dc.DeviceString;
      is_primary := dc.StateFlags and DISPLAY_DEVICE_PRIMARY_DEVICE <> 0;
      if EnumDisplayDevices(PChar(device),  0, dc, 0) then
        begin
          if Length(Result) = monitor_idx then
            SetLength(Result, GrowCollection(monitor_idx, monitor_idx+1));
          Result[monitor_idx].DeviceName  := device;
          Result[monitor_idx].MonitorName := dc.DeviceString;
          Result[monitor_idx].AdapterName := adapter;
          Result[monitor_idx].Resolutions := GetMonitorResolutions(device, Result[monitor_idx].CurrentResolution);
          InvertResolutionArray(Result[monitor_idx].Resolutions);
          Result[monitor_idx].CurrentResolution := Length(Result[monitor_idx].Resolutions) - 1 - Result[monitor_idx].CurrentResolution;
          Result[monitor_idx].IsPrimary   := is_primary;
          Inc(monitor_idx);
        end
      else
        begin
          if Length(Result) = monitor_idx then
            SetLength(Result, GrowCollection(monitor_idx, monitor_idx+1));
          Result[monitor_idx].DeviceName  := device;
          Result[monitor_idx].MonitorName := 'device: '+ device+'adapter: '+adapter;
          Result[monitor_idx].AdapterName := adapter;
          Result[monitor_idx].Resolutions := GetMonitorResolutions(device, Result[monitor_idx].CurrentResolution);
          InvertResolutionArray(Result[monitor_idx].Resolutions);
          Result[monitor_idx].CurrentResolution := Length(Result[monitor_idx].Resolutions) - 1 - Result[monitor_idx].CurrentResolution ;
          Result[monitor_idx].IsPrimary   := is_primary;
          Inc(monitor_idx);
        end;
      Inc(Num);
    end;
  SetLength(Result, monitor_idx);

end;



function SetMonitorResolution(const DeviceName: string; Width,
  Height: Integer; Persist: Boolean): Integer;
const
  CDS_MODE: array [Boolean] of Cardinal = (CDS_FULLSCREEN, CDS_UPDATEREGISTRY);
var
  mode: TDevMode;
begin
  Result := 0;
  FillChar(mode, SizeOf(mode), 0);
  mode.dmSize := SizeOf(mode);
  mode.dmPelsWidth := Width;
  mode.dmPelsHeight := Height;
  mode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
  Result := ChangeDisplaySettingsEx(PChar(DeviceName), mode, 0, CDS_TEST, nil);
  if Result = DISP_CHANGE_SUCCESSFUL then
    begin
      Result := ChangeDisplaySettingsEx(PChar(DeviceName), mode, 0, CDS_MODE[Persist], nil);
    end;

end;

{ **************************************************************************** }
{                               TDupValues                                     }
{ **************************************************************************** }

function TDupValues.AddIfNotExists(w, h: Integer): Integer;
var
  i: Integer;
  value: TMonitorResolution;
begin
  Result := -1;
  value.width := w;
  value.height := h;

  for I := 0 to Count-1 do
    if Int64(Buf[i]) = Int64(value) then exit;
  if Count = Length(Buf) then
    SetLength(Buf, GrowCollection(Count, Count + 1));
  buf[Count] := value;
  Result := Count;
  Inc(Count);
end;

procedure TDupValues.Init;
begin
  Count := 0;
end;

end.
