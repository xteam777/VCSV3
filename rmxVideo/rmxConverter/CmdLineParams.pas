unit CmdLineParams;

interface
uses
  Classes, SysUtils, Windows;
type
  TParamStrings = class (TStringList)
  public
    function ParamValue(const Name: string): string;
    function ParamExists(const Name: string): Boolean;
  end;

  function GetCmdLineParams: TParamStrings; overload;
  function GetCmdLineParams(var Params: TParamStrings): Boolean; overload;
  procedure PrintHelp;
  procedure PrintTitle;
implementation


function GetCmdLineParams: TParamStrings; overload;
begin
  Result := TParamStrings.Create;
  if ExtractStrings(['/','-', ' '], [], GetCommandLine, Result) < 1 then
    FreeAndNil(Result);

end;

function GetCmdLineParams(var Params: TParamStrings): Boolean; overload;
begin
  Params.Clear;
  Result :=  ExtractStrings(['/','-',' '], [], GetCommandLine, Params) > 0;
end;

procedure PrintHelp;
begin
  WriteLn('SYNTAX: rmxConverter [options]  -i input [-o, -d] output');
  WriteLn(#9, '-i: input file');
  WriteLn(#9, '-o: output file');
  WriteLn(#9, '-d: ouptut folder');
  WriteLn(#9, '-fps: integer value, default 10, set "0" to disable measure frames');
  WriteLn(#9, '-f: format ouptut [avi, mp4]');

  WriteLn(#9, '.');

end;

procedure PrintTitle;
begin
  WriteLn('rmxConverter Version 1.0 - RMX Video converter software. © 2023');
  WriteLn('');
end;

{ TParamStrings }

function TParamStrings.ParamExists(const Name: string): Boolean;
begin
  Result := IndexOfName(Name) <> -1;
  if not Result then
    Result := IndexOf(Name) <> -1;
end;

function TParamStrings.ParamValue(const Name: string): string;
begin
  Result := Values[Name];
end;

end.
