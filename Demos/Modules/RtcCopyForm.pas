unit RtcCopyForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, acPNG,
  Vcl.ExtCtrls, shellapi, ShlObj, SHDocVw, Character, IOUtils, Types;

type
  TRctCopy = class(TForm)
    pb: TProgressBar;
    pb_: TProgressBar;
    Image1: TImage;
    lRecvToFolder: TLabel;
    Button1: TButton;
    lRecvFileName: TLabel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
    function get_destExp(dir: string): hwnd;
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    function RctCopy_Close(repl_d:boolean=True; repl_path:string=''; only_clear: boolean=False):THandle;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  function RctCopy_showing:boolean;


var
  RctCopy: TRctCopy; stop_copy: boolean = False;

implementation

{$R *.dfm}

function doshfileop(handle: thandle; opmode: uint; src, dest: string;
  delriclebin: boolean): boolean;
var
  ret: integer;
  ipfileop: tshfileopstruct;
begin
  screen.cursor := crappstart;
  fillchar(ipfileop, sizeof(ipfileop), 0);
  with ipfileop do
  begin
    wnd := handle;
    wfunc := opmode;
    pfrom := pchar(src);
    pto := pchar(dest);
    if delriclebin then
      fflags := fof_allowundo
    else
      fflags := fof_noconfirmmkdir;
    fanyoperationsaborted := false;
    hnamemappings := nil;
    lpszprogresstitle := '';
  end;
  try
    ret := shfileoperation(ipfileop);
  except
    ret := 1;
  end;
  result := (ret = 0);
  screen.cursor := crdefault;
end;

function src(s: string): string;
var
  f: TStringDynArray; i: integer;
begin
  result:= '';
  f:= TDirectory.GetFileSystemEntries(s, '*');

  for i:= 0 to high(f) do
  begin
    result:= result + f[i]+#0;
  end;
end;

function TRctCopy.RctCopy_Close(repl_d:boolean=True; repl_path:string=''; only_clear: boolean=False):THandle;
label 0;
var old_path: string; hd: THandle;
begin
  result:= 0;
  showwindow(findwindow('TRctCopy',nil), SW_HIDE);
  try
  if only_clear then
                   goto 0;

  if repl_d then
  if repl_path<>'' then
  begin

     old_path:= ExcludeTrailingPathDelimiter(repl_path);
     delete(old_path,length(old_path)-1,2);
     result:= RctCopy.get_destExp(old_path);

     if doshfileop(application.Handle, fo_move, src(repl_path), old_path, True) then
     begin
       0:
       if (repl_path<>'') and DirectoryExists(repl_path) then
       begin
         SetFileAttributes(pchar(repl_path),0);
         TDirectory.Delete(repl_path, True);
       end;
     end else goto 0;
  end;

  finally
    try
      DestroyWindow(findwindow('TRctCopy',nil));
    except end;
  end;

end;

function RctCopy_showing:boolean;
var
  h: hwnd;
begin
  try
  result:=  RctCopy.showing;
  except
  result:=  False;
  end;
end;

function TRctCopy.get_destExp(dir:string): hwnd;
var Explorer: IShellWindows;
    i: integer;
    s: string;
begin
  result:= 0;
  dir:= ToLower(IncludeTrailingPathDelimiter(dir));
  Explorer := CoShellWindows.Create;
  for I := 0 to Explorer.Count - 1 do
  begin
    s:= (Explorer.Item(I) as IWebbrowser2).LocationUrl;
    s:= stringreplace(s,'/','\',[rfReplaceAll]);
    delete(s,1,8);
    s:= ToLower(IncludeTrailingPathDelimiter(stringreplace(s,'%20',' ',[rfReplaceAll])));
    if s = dir then
    begin
      result:= (Explorer.Item(I) as IWebbrowser2).HWND;
      EXIT
    end;
  end;

end;

procedure TRctCopy.Button1Click(Sender: TObject);
begin
 stop_copy:= true;
end;

procedure TRctCopy.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action:= caFree;
end;

procedure TRctCopy.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 stop_copy:= True;
 canclose:=  False;
end;

procedure TRctCopy.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=27 then close;
end;

procedure TRctCopy.FormShow(Sender: TObject);
begin
  stop_copy:= False;
  setforegroundwindow(Handle);
end;

end.
