unit DisplaySettings;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

// if returned false, call GetLastError() or RaiseLastError
function GetMonitorResolutions(list: TStrings; full_info: Boolean; out current: Integer): Boolean; overload;
function GetMonitorResolutions(var s: string; full_info: Boolean; out current: Integer): Boolean; overload;
// if returned false, call GetLastError() or RaiseLastError
function SetMonitorResolution(Width, Height: Integer; Persist: Boolean): Boolean;


implementation

const
  EDS_RAWMODE            = $00000002;
  EDS_ROTATEDMODE        = $00000004;
  ENUM_CURRENT_SETTINGS  = DWORD(-1);
  ENUM_REGISTRY_SETTINGS = DWORD(-2);

//* field selection bits */
  DM_ORIENTATION          = $00000001;
  DM_PAPERSIZE            = $00000002;
  DM_PAPERLENGTH          = $00000004;
  DM_PAPERWIDTH           = $00000008;
  DM_SCALE                = $00000010;
  DM_POSITION             = $00000020;
  DM_NUP                  = $00000040;
  DM_DISPLAYORIENTATION   = $00000080;
  DM_COPIES               = $00000100;
  DM_DEFAULTSOURCE        = $00000200;
  DM_PRINTQUALITY         = $00000400;
  DM_COLOR                = $00000800;
  DM_DUPLEX               = $00001000;
  DM_YRESOLUTION          = $00002000;
  DM_TTOPTION             = $00004000;
  DM_COLLATE              = $00008000;
  DM_FORMNAME             = $00010000;
  DM_LOGPIXELS            = $00020000;
  DM_BITSPERPEL           = $00040000;
  DM_PELSWIDTH            = $00080000;
  DM_PELSHEIGHT           = $00100000;
  DM_DISPLAYFLAGS         = $00200000;
  DM_DISPLAYFREQUENCY     = $00400000;
  DM_ICMMETHOD            = $00800000;
  DM_ICMINTENT            = $01000000;
  DM_MEDIATYPE            = $02000000;
  DM_DITHERTYPE           = $04000000;
  DM_PANNINGWIDTH         = $08000000;
  DM_PANNINGHEIGHT        = $10000000;
  DM_DISPLAYFIXEDOUTPUT   = $20000000;

type

  TDevModeHelper = record helper for TDevMode
  const
    mode_bit = 1;
    mode_enum = 2;
    mode_full = 3;
  private
    function FieldsToStringBit(): string;
    function FieldsToStringEnum(): string;
    function FieldsToStringFull(): string;
  public
    function ToString(): string;
    function FieldsToString(mode: Integer): string;
  end;

  TDupValues = record
    Count: Integer;
    Buf: array of Int64;
    procedure Init;
    function AddIfNotExists(w, h: Integer): Boolean;
  end;


//==============================================================================
function SetMonitorResolution(Width, Height: Integer; Persist: Boolean): Boolean;
const
  CDS_MODE: array [Boolean] of Cardinal = (CDS_FULLSCREEN, CDS_UPDATEREGISTRY);
var
  mode: TDevMode;
begin
  Result := false;
  FillChar(mode, SizeOf(mode), 0);
  mode.dmSize := SizeOf(mode);
  mode.dmPelsWidth := Width;
  mode.dmPelsHeight := Height;
  mode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
  if ChangeDisplaySettings(mode, CDS_TEST) = DISP_CHANGE_SUCCESSFUL then
    Result := ChangeDisplaySettings(mode, CDS_MODE[Persist]) = DISP_CHANGE_SUCCESSFUL;
end;


//==============================================================================
function GetMonitorResolutions(list: TStrings; full_info: Boolean; out current: Integer): Boolean;
var
  dc: TDisplayDevice;
  dNum, mNum: Cardinal;
  dev_mode, cur_mode: TDevMode;
  dup: TDupValues;
begin
  current := -1;
  list.BeginUpdate;
  try
    list.Clear;
    dNum := 0;
    dc.cb := SizeOf(dc);
    while EnumDisplayDevices(nil,  dNum, dc, EDD_GET_DEVICE_INTERFACE_NAME) do
      begin
        if not full_info then
          begin
            // check only primary
            if dc.StateFlags and DISPLAY_DEVICE_PRIMARY_DEVICE <> DISPLAY_DEVICE_PRIMARY_DEVICE then
              begin
                inc(dNum);
                Continue;
              end;

            mNum := 0;
            dup.Init();
            FillChar(cur_mode, SizeOf(cur_mode), 0);
            cur_mode.dmSize := SizeOf(cur_mode);
            if not EnumDisplaySettings(dc.DeviceName, ENUM_CURRENT_SETTINGS, cur_mode) then
              exit;
          end
        else
          begin
            mNum := ENUM_REGISTRY_SETTINGS;
            list.Add(
              Format('DEVICENAME = %s, DeviceString = %s, IsPrimary = %s, StateFlags = %d',
                [dc.DeviceName, dc.DeviceString,
                 BoolToStr(dc.StateFlags and DISPLAY_DEVICE_PRIMARY_DEVICE <> 0, true),
                 dc.StateFlags
                ]
              ));
            list.Add('');
          end;

        FillChar(dev_mode, SizeOf(dev_mode), 0);
        dev_mode.dmSize := SizeOf(dev_mode);


        while EnumDisplaySettings(dc.DeviceName, mNum, dev_mode) do
          begin
            if full_info or (
//              (dev_mode.dmDisplayFlags = 0) and
              (dev_mode.dmDisplayFrequency = cur_mode.dmDisplayFrequency) and
              (dup.AddIfNotExists(dev_mode.dmPelsWidth, dev_mode.dmPelsHeight)) and
              (//dev_mode.dmFields = {DM_DISPLAYORIENTATION or DM_BITSPERPEL or}
                dev_mode.dmFields and (DM_PELSWIDTH or DM_PELSHEIGHT) <> 0
                                   {DM_DISPLAYFLAGS or DM_DISPLAYFREQUENCY})) then
              begin
                if full_info then
                  begin
                    if mNum = ENUM_REGISTRY_SETTINGS then
                      list.Add('ENUM_REGISTRY_SETTINGS'+ sLineBreak)
                    else if mNum = ENUM_CURRENT_SETTINGS then
                      list.Add('ENUM_CURRENT_SETTINGS'+ sLineBreak)
                    else
                      list.Add('ENUM '+ mNum.ToString + sLineBreak);
                    list.Add(dev_mode.ToString);
                    list.Add(dev_mode.FieldsToString(dev_mode.mode_enum));
                    list.Add('------');
                    list.Add('');
                  end
                else
                begin
                  list.Add(Format('%dx%d', [dev_mode.dmPelsWidth, dev_mode.dmPelsHeight]));
                end;
                if not full_info and
                   (dev_mode.dmPelsWidth  = cur_mode.dmPelsWidth) and
                   (dev_mode.dmPelsHeight = cur_mode.dmPelsHeight) then
                    current := list.Count - 1;
              end;
            Inc(mNum);
          end;


        if full_info then
          inc(dNum)
        else
          break;

      end;

  finally
    list.EndUpdate;
  end;
  Result := list.Count > 0;

end;

function GetMonitorResolutions(var s: string; full_info: Boolean; out current: Integer): Boolean; overload;
var
  list: TStringList;
begin
  list := TStringList.Create;
  try
    Result := GetMonitorResolutions(list, full_info, current);
    s := trim(list.Text);
  finally
    list.Free;
  end;
end;


{ **************************************************************************** }
{                               TDevModeHelper                                 }
{ **************************************************************************** }

function TDevModeHelper.FieldsToString(mode: Integer): string;
begin
  case mode of
    mode_bit:   Result := FieldsToStringBit();
    mode_enum:  Result := FieldsToStringEnum();
    mode_full:  Result := FieldsToStringFull();
  else
    Result := '';
  end;
end;

function TDevModeHelper.FieldsToStringBit: string;
begin
with Self do
  Result := Format(
    '%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d',

  [
    (dmFields and DM_ORIENTATION <> 0).ToInteger,
    (dmFields and DM_PAPERSIZE <> 0).ToInteger,
    (dmFields and DM_PAPERLENGTH <> 0).ToInteger,
    (dmFields and DM_PAPERWIDTH <> 0).ToInteger,
    (dmFields and DM_SCALE <> 0).ToInteger,
    (dmFields and DM_COPIES <> 0).ToInteger,
    (dmFields and DM_DEFAULTSOURCE <> 0).ToInteger,
    (dmFields and DM_PRINTQUALITY <> 0).ToInteger,
    (dmFields and DM_POSITION <> 0).ToInteger,
    (dmFields and DM_DISPLAYORIENTATION <> 0).ToInteger,
    (dmFields and DM_DISPLAYFIXEDOUTPUT <> 0).ToInteger,
    (dmFields and DM_COLOR <> 0).ToInteger,
    (dmFields and DM_DUPLEX <> 0).ToInteger,
    (dmFields and DM_YRESOLUTION <> 0).ToInteger,
    (dmFields and DM_TTOPTION <> 0).ToInteger,
    (dmFields and DM_COLLATE <> 0).ToInteger,
    (dmFields and DM_FORMNAME <> 0).ToInteger,
    (dmFields and DM_LOGPIXELS <> 0).ToInteger,
    (dmFields and DM_BITSPERPEL <> 0).ToInteger,
    (dmFields and DM_PELSWIDTH <> 0).ToInteger,
    (dmFields and DM_PELSHEIGHT <> 0).ToInteger,
    (dmFields and DM_DISPLAYFLAGS <> 0).ToInteger,
    (dmFields and DM_NUP <> 0).ToInteger,
    (dmFields and DM_DISPLAYFREQUENCY <> 0).ToInteger,
    (dmFields and DM_ICMMETHOD <> 0).ToInteger,
    (dmFields and DM_ICMINTENT <> 0).ToInteger,
    (dmFields and DM_MEDIATYPE <> 0).ToInteger,
    (dmFields and DM_DITHERTYPE <> 0).ToInteger,
    (dmFields and DM_PANNINGWIDTH <> 0).ToInteger,
    (dmFields and DM_PANNINGHEIGHT <> 0).ToInteger
  ]
  )
end;

function TDevModeHelper.FieldsToStringEnum: string;
begin
  Result := '';
    if (dmFields and DM_ORIENTATION <> 0) then
      Result := Result + ' DM_ORIENTATION';
    if (dmFields and DM_PAPERSIZE <> 0) then
      Result := Result + ' DM_PAPERSIZE';
    if (dmFields and DM_PAPERLENGTH <> 0) then
      Result := Result + ' DM_PAPERLENGTH';
    if (dmFields and DM_PAPERWIDTH <> 0) then
      Result := Result + ' DM_PAPERWIDTH';
    if (dmFields and DM_SCALE <> 0) then
      Result := Result + ' DM_SCALE';
    if (dmFields and DM_COPIES <> 0) then
      Result := Result + ' DM_COPIES';
    if (dmFields and DM_DEFAULTSOURCE <> 0) then
      Result := Result + ' DM_DEFAULTSOURCE';
    if (dmFields and DM_PRINTQUALITY <> 0) then
      Result := Result + ' DM_PRINTQUALITY';
    if (dmFields and DM_POSITION <> 0) then
      Result := Result + ' DM_POSITION';
    if (dmFields and DM_DISPLAYORIENTATION <> 0) then
      Result := Result + ' DM_DISPLAYORIENTATION';
    if (dmFields and DM_DISPLAYFIXEDOUTPUT <> 0) then
      Result := Result + ' DM_DISPLAYFIXEDOUTPUT';
    if (dmFields and DM_COLOR <> 0) then
      Result := Result + ' DM_COLOR';
    if (dmFields and DM_DUPLEX <> 0) then
      Result := Result + ' DM_DUPLEX';
    if (dmFields and DM_YRESOLUTION <> 0) then
      Result := Result + ' DM_YRESOLUTION';
    if (dmFields and DM_TTOPTION <> 0) then
      Result := Result + ' DM_TTOPTION';
    if (dmFields and DM_COLLATE <> 0) then
      Result := Result + ' DM_COLLATE';
    if (dmFields and DM_FORMNAME <> 0) then
      Result := Result + ' DM_FORMNAME';
    if (dmFields and DM_LOGPIXELS <> 0) then
      Result := Result + ' DM_LOGPIXELS';
    if (dmFields and DM_BITSPERPEL <> 0) then
      Result := Result + ' DM_BITSPERPEL';
    if (dmFields and DM_PELSWIDTH <> 0) then
      Result := Result + ' DM_PELSWIDTH';
    if (dmFields and DM_PELSHEIGHT <> 0) then
      Result := Result + ' DM_PELSHEIGHT';
    if (dmFields and DM_DISPLAYFLAGS <> 0) then
      Result := Result + ' DM_DISPLAYFLAGS';
    if (dmFields and DM_NUP <> 0) then
      Result := Result + ' DM_NUP';
    if (dmFields and DM_DISPLAYFREQUENCY <> 0) then
      Result := Result + ' DM_DISPLAYFREQUENCY';
    if (dmFields and DM_ICMMETHOD <> 0) then
      Result := Result + ' DM_ICMMETHOD';
    if (dmFields and DM_ICMINTENT <> 0) then
      Result := Result + ' DM_ICMINTENT';
    if (dmFields and DM_MEDIATYPE <> 0) then
      Result := Result + ' DM_MEDIATYPE';
    if (dmFields and DM_DITHERTYPE <> 0) then
      Result := Result + ' DM_DITHERTYPE';
    if (dmFields and DM_PANNINGWIDTH <> 0) then
      Result := Result + ' DM_PANNINGWIDTH';
    if (dmFields and DM_PANNINGHEIGHT <> 0) then
      Result := Result + ' DM_PANNINGHEIGHT';
end;

function TDevModeHelper.FieldsToStringFull: string;
begin
  with Self do
  Result := Format(
    'DM_ORIENTATION = %d'+slinebreak+
    'DM_PAPERSIZE = %d'+slinebreak+
    'DM_PAPERLENGTH = %d'+slinebreak+
    'DM_PAPERWIDTH = %d'+slinebreak+
    'DM_SCALE = %d'+slinebreak+
    'DM_COPIES = %d'+slinebreak+
    'DM_DEFAULTSOURCE = %d'+slinebreak+
    'DM_PRINTQUALITY = %d'+slinebreak+
    'DM_POSITION = %d'+slinebreak+
    'DM_DISPLAYORIENTATION = %d'+slinebreak+
    'DM_DISPLAYFIXEDOUTPUT = %d'+slinebreak+
    'DM_COLOR = %d'+slinebreak+
    'DM_DUPLEX = %d'+slinebreak+
    'DM_YRESOLUTION = %d'+slinebreak+
    'DM_TTOPTION = %d'+slinebreak+
    'DM_COLLATE = %d'+slinebreak+
    'DM_FORMNAME = %d'+slinebreak+
    'DM_LOGPIXELS = %d'+slinebreak+
    'DM_BITSPERPEL = %d'+slinebreak+
    'DM_PELSWIDTH = %d'+slinebreak+
    'DM_PELSHEIGHT = %d'+slinebreak+
    'DM_DISPLAYFLAGS = %d'+slinebreak+
    'DM_NUP = %d'+slinebreak+
    'DM_DISPLAYFREQUENCY = %d'+slinebreak+
    'DM_ICMMETHOD = %d'+slinebreak+
    'DM_ICMINTENT = %d'+slinebreak+
    'DM_MEDIATYPE = %d'+slinebreak+
    'DM_DITHERTYPE = %d'+slinebreak+
    'DM_PANNINGWIDTH = %d'+slinebreak+
    'DM_PANNINGHEIGHT = %d'+slinebreak,

  [
    (dmFields and DM_ORIENTATION <> 0).ToInteger,
    (dmFields and DM_PAPERSIZE <> 0).ToInteger,
    (dmFields and DM_PAPERLENGTH <> 0).ToInteger,
    (dmFields and DM_PAPERWIDTH <> 0).ToInteger,
    (dmFields and DM_SCALE <> 0).ToInteger,
    (dmFields and DM_COPIES <> 0).ToInteger,
    (dmFields and DM_DEFAULTSOURCE <> 0).ToInteger,
    (dmFields and DM_PRINTQUALITY <> 0).ToInteger,
    (dmFields and DM_POSITION <> 0).ToInteger,
    (dmFields and DM_DISPLAYORIENTATION <> 0).ToInteger,
    (dmFields and DM_DISPLAYFIXEDOUTPUT <> 0).ToInteger,
    (dmFields and DM_COLOR <> 0).ToInteger,
    (dmFields and DM_DUPLEX <> 0).ToInteger,
    (dmFields and DM_YRESOLUTION <> 0).ToInteger,
    (dmFields and DM_TTOPTION <> 0).ToInteger,
    (dmFields and DM_COLLATE <> 0).ToInteger,
    (dmFields and DM_FORMNAME <> 0).ToInteger,
    (dmFields and DM_LOGPIXELS <> 0).ToInteger,
    (dmFields and DM_BITSPERPEL <> 0).ToInteger,
    (dmFields and DM_PELSWIDTH <> 0).ToInteger,
    (dmFields and DM_PELSHEIGHT <> 0).ToInteger,
    (dmFields and DM_DISPLAYFLAGS <> 0).ToInteger,
    (dmFields and DM_NUP <> 0).ToInteger,
    (dmFields and DM_DISPLAYFREQUENCY <> 0).ToInteger,
    (dmFields and DM_ICMMETHOD <> 0).ToInteger,
    (dmFields and DM_ICMINTENT <> 0).ToInteger,
    (dmFields and DM_MEDIATYPE <> 0).ToInteger,
    (dmFields and DM_DITHERTYPE <> 0).ToInteger,
    (dmFields and DM_PANNINGWIDTH <> 0).ToInteger,
    (dmFields and DM_PANNINGHEIGHT <> 0).ToInteger
  ]
  )
end;


function TDevModeHelper.ToString: string;
begin
  With Self do
  Result := Format(
    'dmDeviceName: %s'+sLineBreak+
    'dmSpecVersion: %d'+sLineBreak+
    'dmDriverVersion: %d'+sLineBreak+
    'dmSize: %d'+sLineBreak+
    'dmDriverExtra: %d'+sLineBreak+
    'dmFields: %d'+sLineBreak+
    'dmOrientation: %d'+sLineBreak+
    'dmPaperSize: %d'+sLineBreak+
    'dmPaperLength: %d'+sLineBreak+
    'dmPaperWidth: %d'+sLineBreak+
    'dmScale: %d'+sLineBreak+
    'dmCopies: %d'+sLineBreak+
    'dmDefaultSource: %d'+sLineBreak+
    'dmPrintQuality: %d'+sLineBreak+
    'dmColor: %d'+sLineBreak+
    'dmDuplex: %d'+sLineBreak+
    'dmYResolution: %d'+sLineBreak+
    'dmTTOption: %d'+sLineBreak+
    'dmCollate: %d'+sLineBreak+
    'dmFormName: %s'+sLineBreak+
    'dmLogPixels: %d'+sLineBreak+
    'dmBitsPerPel: %d'+sLineBreak+
    'dmPelsWidth: %d'+sLineBreak+
    'dmPelsHeight: %d'+sLineBreak+
    'dmDisplayFlags: %d'+sLineBreak+
    'dmDisplayFrequency: %d'+sLineBreak+
    'dmICMMethod: %d'+sLineBreak+
    'dmICMIntent: %d'+sLineBreak+
    'dmMediaType: %d'+sLineBreak+
    'dmDitherType: %d'+sLineBreak+
    'dmICCManufacturer: %d'+sLineBreak+
    'dmICCModel: %d'+sLineBreak+
    'dmPanningWidth: %d'+sLineBreak+
    'dmPanningHeight: %d',
    [
    dmDeviceName,
    dmSpecVersion,
    dmDriverVersion,
    dmSize,
    dmDriverExtra,
    dmFields,
    dmOrientation,
    dmPaperSize,
    dmPaperLength,
    dmPaperWidth,
    dmScale,
    dmCopies,
    dmDefaultSource,
    dmPrintQuality,
    dmColor,
    dmDuplex,
    dmYResolution,
    dmTTOption,
    dmCollate,
    dmFormName,
    dmLogPixels,
    dmBitsPerPel,
    dmPelsWidth,
    dmPelsHeight,
    dmDisplayFlags,
    dmDisplayFrequency,
    dmICMMethod,
    dmICMIntent,
    dmMediaType,
    dmDitherType,
    dmICCManufacturer,
    dmICCModel,
    dmPanningWidth,
    dmPanningHeight]
  )
end;

{ TDupValues }

function TDupValues.AddIfNotExists(w, h: Integer): Boolean;
var
  i: Integer;
  value: Int64;
begin
  Result := false;
  Int64Rec(value).Hi := w;
  Int64Rec(value).Lo := h;

  for I := 0 to Count-1 do
    if Buf[i] = value then exit;
  if Count = Length(Buf) then
    SetLength(Buf, GrowCollection(Count, Count + 1));
  buf[Count] := value;
  Inc(Count);
  Result := true;

end;

procedure TDupValues.Init;
begin
  Count := 0;
end;

end.
