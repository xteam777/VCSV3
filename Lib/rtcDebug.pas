unit rtcDebug;

interface

type
TRtcDebug = class
private
type
  TScreenCapture = record
    CodecId, Codec2Param1, Codec3Param1, Codec4Param1, Codec4Param2 : Integer;
  end;
//class var
//  IniF : TMemIniFIle;

  //class procedure Create1;
 // class procedure Destroy1;
var
  LogF : TextFile;
  TicksInMCS : Extended;

public
var
  FScreenCapture : TScreenCapture;
  FrameStatLog : string;
  FrameStatFontSize : Integer;


  constructor Create;
  destructor Destroy;

  procedure Log(s : String); inline;

  function GetMCSTick : UInt64; inline;

  property ScreenCapture : TScreenCapture read FScreenCapture;
  class procedure SetComprParams(Quality : Single; ComprMethod : Integer);
end;

var
  Debug : TRtcDebug;

implementation
uses WinAPI.Windows, Forms, System.SysUtils, IniFiles;

constructor TRtcDebug.Create;
var
  IniF : TIniFile;
  F : TextFile;
  TicksInSec : Int64;
begin
  {$IFDEF DEBUG}
  AssignFile(LogF, ExtractFilePath(Application.ExeName) + 'debug.log');
  ReWrite(LogF);
  CloseFile(LogF);

  IniF := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'debug.ini');
  //if IniF. then
  with FScreenCapture, IniF do
  begin
    CodecId := ReadInteger('ScreenCapture', 'CodecId', 4);
  {if ScreenCapture.CodecId < 0 then
  begin
   // ShowMessage('Unable to open "' + IniF.FileName + '"');
    Application.Terminate;
    CodecId := 0;
  end;  }

    Codec2Param1 := ReadInteger('ScreenCapture', 'Codec2Param1', 100);
    Codec3Param1 := ReadInteger('ScreenCapture', 'Codec3Param1', 100);
    Codec4Param1 := ReadInteger('ScreenCapture', 'Codec4Param1', 50);
    Codec4Param2 := ReadInteger('ScreenCapture', 'Codec4Param2', 3);
  end;

  FrameStatLog := IniF.ReadString('FrameStat', 'Log', '');
  if FrameStatLog <> '' then
  begin
    AssignFile(F, ExtractFilePath(Application.ExeName) + FrameStatLog);
    ReWrite(F);
    WriteLn(F, '   Date      Time      DD      WPE     WPD    Misc    Total   Traff  ');
    CloseFile(F);
  end;
  FrameStatFontSize := IniF.ReadInteger('FrameStat', 'FontSize', 30);

  IniF.Free;

  if QueryPerformanceFrequency(TicksInSec) then
    TicksInMCS := TicksInSec / 1e6 else TicksInMCS := -1;
 {$ENDIF}

end;

destructor TRtcDebug.Destroy;
begin
end;

procedure TRtcDebug.Log(s : String);
begin
  {$IFDEF DEBUG}
  Append(LogF);
  WriteLn(LogF, DateTimeToStr(Now) + ' ' + s);
  CloseFile(LogF);
  {$ENDIF}
end;

function TRtcDebug.GetMCSTick : UInt64;
var
  Tick : Int64;
begin
  if QueryPerformanceCounter(Tick) then Result := Round(Tick / TicksInMCS) else
    Result := GetTickCount64 * 1000;
end;

class procedure TRtcDebug.SetComprParams(Quality : Single; ComprMethod : Integer);
begin
end;

initialization

Debug := TRtcDebug.Create;

finalization

Debug.Destroy;

end.
