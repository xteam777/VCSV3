program rmxConverter;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows,
  System.SysUtils,
  System.TimeSpan,
  System.DateUtils,
  rmxVideoFile,
  CmdLineParams in 'CmdLineParams.pas',
  rmxBitmaper in 'converters\rmxBitmaper.pas',
  rtcScrPlayback in '..\..\lib\rtcScrPlayback.pas',
  rmxConsoleProgress in 'rmxConsoleProgress.pas',
  ConsoleAppliaction in 'ConsoleAppliaction.pas',
  rmxBitmapConverter in 'converters\rmxBitmapConverter.pas',
  rmxAVIConverter in 'converters\rmxAVIConverter.pas',
  rmxConverterBase in 'converters\rmxConverterBase.pas',
  Compressions in '..\Compressor\Compressions.pas',
  rmxConverterUtils in 'converters\rmxConverterUtils.pas';

{$ifdef RELEASE}

{$SETPEFlAGS IMAGE_FILE_DEBUG_STRIPPED or IMAGE_FILE_LINE_NUMS_STRIPPED or
             IMAGE_FILE_LOCAL_SYMS_STRIPPED OR IMAGE_FILE_RELOCS_STRIPPED}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$endif}


type
  TConsoleTerminate = class
    class procedure OnTerminate(Sender: TObject; Context: Pointer);
  end;

class procedure TConsoleTerminate.OnTerminate(Sender: TObject; Context: Pointer);
begin
  if TObject(Context) is TRMXConverter then
    TRMXConverter(Context).Abort := true;

end;

var
  app: TConsoleApplication;

procedure Convert(const InputFile: string; const Params: TParamStrings);
var
  Bitmaper: TRmxBitmaper;
  header: TRMXHeader;
  converter: TRMXConverter;
  cvt_class: TRMXConverterClass;
  cvt_prms: TParamConverter;
begin
  if not GetConverterByName(Params.ParamValue('f'), cvt_class) then
    begin
      raise Exception.CreateFmt('Converter "%s" not found', [Params.ParamValue('f')]);
    end;

  cvt_prms.output := Params.ParamValue('o');

  Bitmaper := TRmxBitmaper.Create(InputFile);
  try

      //if Params.ParamExists('fps') then
      Bitmaper.FPS := StrToIntDef(Params.ParamValue('fps'), 30);

      header := Bitmaper.Reader.RMXFile.Header;
      Writeln('Video version      = ', Header.VersionStr);
      Writeln('FrameCount         = ', Header.NumberOfFrames);
      Writeln('TimeStamp          = ', FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', Header.TimeStampAsDateTime));
      Writeln('Duration           = ', TTimeSpan.FromMilliseconds(Header.Duration).ToString);
      Writeln('FPS                = ', Bitmaper.FPS);
      Writeln('MeasuredFrameCount = ', Bitmaper.MeasuredFrameCount);
      Writeln(' ');

      converter := cvt_class.Create(TRMXConsoleProgress, nil);
      try
          app.Context := converter;
          converter.Proccess(Bitmaper, @cvt_prms);
      finally
        app.Context := nil;
        converter.Free;
      end;

      Writeln('Done');

  finally
    Bitmaper.Free;
  end;
end;

procedure MainProc;
var
  params: TParamStrings;
  i: Integer;
begin
  params := GetCmdLineParams;
  if not Assigned(params)  then
    begin
      PrintHelp;
      exit;
    end;

  try
    if (params.Count < 2) or params.ParamExists('h') then
      begin
        PrintHelp;
        exit;
      end;

    if not FileExists(params.ParamValue('i')) then
      raise Exception.Create('File not found '+params.ParamValue('i'));

    Convert(params.ParamValue('i'), params);

  finally
    params.Free;
  end;
end;


begin
  try
    app := TConsoleApplication.Create('rmxConverter Version 1.0', nil);
    try
      app.QuickMode := false;
      app.HideCursor := true;
      app.OnTerminate := TConsoleTerminate.OnTerminate;
      PrintTitle;
      MainProc;
//      app.QuickMode := true;
//      app.HideCursor := false;

    finally
      app.Free;
    end;
    if IsDebuggerPresent then
      Readln;
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      begin
        Writeln(E.ClassName, ': ', E.Message);
        Writeln('');
        PrintHelp;
      end;
  end;
end.
