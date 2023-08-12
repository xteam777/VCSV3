unit rmxBitmapConverter;

interface
uses
  Winapi.Windows, System.SysUtils, System.Classes, CmdLineParams,
  rmxVideoStorage, rmxBitmaper, RMXConverterBase;

type


  TRMXBitmapConverter = class(TRMXConverter)
  public
    procedure Proccess(const Bitmaper: TRmxBitmaper; const Params: PParamConverter); override;
  end;

implementation

{ **************************************************************************** }
{                               TBitmapConverter                               }
{ **************************************************************************** }


procedure TRMXBitmapConverter.Proccess(const Bitmaper: TRmxBitmaper;
  const Params: PParamConverter);
var
  s: string;
  i: Integer;
begin
  Abort := false;
  s := ExpandFileName(Params^.output);
  if s = '' then
    raise Exception.Create('Incorrect directory');
  Win32Check(ForceDirectories(s));
  s := IncludeTrailingBackslash(s);
  Progress.Max := Bitmaper.Reader.RMXFile.Header.NumberOfFrames;
  i := 0;
    while bitmaper.DecodeNext do
      begin
        Inc(i);
        bitmaper.Bitmap.SaveToFile(s+'image'+i.ToString+'.bmp');
        Progress.Position := i;
        if Abort then break;

      end;

end;

end.
