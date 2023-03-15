unit ClipbrdMonitor;

interface
uses
  Winapi.Windows, System.SysUtils, Winapi.Messages, System.Classes,
  Winapi.SHLObj, Winapi.ActiveX, ComObj;


type
  TClipBrdRec = record
    id: Cardinal;
    Format: TCLIPFORMAT;
    Process: string;
    Data: string;
    files_count: Integer;
    files: array  of  TFileDescriptor;

//    procedure SaveToBuf(out buffer: TArray<Byte>);
//    procedure LoadBromBuf(const buffer: TArray<byte>);
  end;

  TClipGetFileRec = record
    id: Cardinal;
    index: Integer;
  end;

  TClipBrdFileData = class
  private
    function GetPath(const Index: Integer): string;
    procedure SetPath(const Index: Integer; const Value: string);
  public
    id: Cardinal;
    Format: TCLIPFORMAT;
    Process: string;
    Data: string;
    FUserName: String;
    files_count: Integer;
    files: TArray<TFileDescriptor>;
    FFilePaths: TArray<String>;
    FFilesCount: Integer;

    procedure SaveToStream(stream: TStream);
    procedure LoadBromStream(stream: TStream);
    procedure Clear;
    function PathsToString(): string;
    function NamesToString(): string;
    function FilesToString(): string;
    property FilesCount: Integer read FFilesCount write FFilesCount;
    property Paths[const Index: Integer]: string read GetPath write SetPath;


  end;



  TClipbrdMonitor = class
  class var
    CF_FILECONTENTS          : TCLIPFORMAT;
    CF_FILEDESCRIPTOR        : TCLIPFORMAT;
    CF_FILENAME              : TCLIPFORMAT;
    CF_PREFERREDDROPEFFECT   : TCLIPFORMAT;
    CF_INETURL               : TCLIPFORMAT;
    CF_SHELLURL              : TCLIPFORMAT;
    CF_FILE_ATTRIBUTES_ARRAY : TCLIPFORMAT;
    CF_SHELLIDLIST           : TCLIPFORMAT;
  private class var ClipFmtRegistered: Boolean;
  private
    FWnd: HWND;
    FNextClipViewer: HWND;
    FOnClip: TNotifyEvent;
    FSequence: Cardinal;
    procedure WndProc(var Message: TMessage);
    function GetFileDescriptor(const FileName: string): TFileDescriptor;

    class procedure RegisterFormats;
    class constructor Create;
  public

    constructor Create();
    destructor Destroy; override;
    property OnClip: TNotifyEvent read FOnClip write FOnClip;
    function GetClipbrdData(clipdata: TClipBrdFileData): Boolean;

  end;


const
  CLIPBRDFILEDATA_CLASS_ID: Cardinal =  $AF11FA;

implementation
uses
  ShellApi;

{ TClipbrdMonitor }

constructor TClipbrdMonitor.Create;
begin
  inherited;
  FWnd := AllocateHWnd(WndProc);
  AddClipboardFormatListener(FWnd);
  //FNextClipViewer := SetClipboardViewer(FWnd);
end;

class constructor TClipbrdMonitor.Create;
begin
  RegisterFormats
end;

destructor TClipbrdMonitor.Destroy;
begin
  //ChangeClipboardChain(FWnd, FNextClipViewer);
  RemoveClipboardFormatListener(FWnd);
  DeallocateHWnd(FWnd);
  inherited;
end;

function TClipbrdMonitor.GetClipbrdData(clipdata: TClipBrdFileData): Boolean;
var
  Data: THandle;
  I: Integer;
  fmts: array [0..1] of integer;
  s:  string;

begin
  Result := false;
  clipdata.Clear;


  (*
  { Информация о процессе/окне }
  Wnd := GetForegroundWindow;
  GetWindowThreadProcessId(Wnd, pid);
  Data := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, pid);
  try
    SetLength(Rec.Process, 1024);
    SetLength(Rec.Process, (GetModuleBaseName(Data, 0, PChar(Rec.Process), 1024)));
    Rec.DataTime := Now;
  finally
    CLoseHandle(Data);
  end;
  *)

  // система автоматически преобразует CF_TEXT в CF_UNICODE получив кодовую страницу из CF_LOCALE
  // Вот пусть система этим и занимается
  fmts[0] := CF_UNICODETEXT;
  fmts[1] := CF_HDROP;
  I := GetPriorityClipboardFormat(fmts, 2);
  if I <= 0  then exit;// нет формата подходящего

  clipdata.Format  := I;
  clipdata.id := FSequence;



  while not OpenClipboard(FWnd) do sleep(100);
  try
    Data := GetClipboardData(clipdata.Format);
    if Data <> 0 then
      case clipdata.Format of
        CF_TEXT:         //<  Текст  Ansi , не работаем с ним
          begin
            clipdata.Data := PAnsiChar(GlobalLock(Data));
            GlobalUnlock(Data);
          end;
        CF_UNICODETEXT:  //<  Текст
          begin
            clipdata.Data := PChar(GlobalLock(Data));
            GlobalUnlock(Data);
          end;
        CF_HDROP:        //<  Файлы
          begin
            clipdata.files_count := DragQueryFile(Data, DWORD(-1), nil, 0);
            SetLength(clipdata.files, clipdata.files_count);
            SetLength(clipdata.FFilePaths, clipdata.files_count);
            for I := 0 to clipdata.files_count-1 do
              begin
                SetLength(s, 1024);
                SetLength(s, DragQueryFile(Data, I, PChar(s), 1024));
                clipdata.FFilePaths[i] := s;
                clipdata.files[I] := GetFileDescriptor(s);
              end;
          end;
      end;
  finally
    CloseClipboard;
  end;


  Result := Data <> 0;

end;

function TClipbrdMonitor.GetFileDescriptor(
  const FileName: string): TFileDescriptor;
var
  hFile: THandle;
  s: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  s := ExtractFileName(FileName);
  if Length(s) < MAX_PATH then
    Move(Pointer(s)^, Result.cFileName[0], Length(s) * SizeOf(Char)) else
    exit;
  Result.dwFileAttributes := GetFileAttributes(PChar(FileName));
  if Result.dwFileAttributes <> INVALID_FILE_ATTRIBUTES then
    Result.dwFlags := Result.dwFlags or FD_ATTRIBUTES;

  hFile := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
        OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
  if hFile = INVALID_HANDLE_VALUE then exit; // raise

  if GetFileTime(hFile, @Result.ftCreationTime, @Result.ftLastAccessTime, @Result.ftLastWriteTime) then
    Result.dwFlags := Result.dwFlags or FD_CREATETIME or FD_ACCESSTIME or FD_WRITESTIME;

  Result.nFileSizeLow := GetFileSize(hFile, @Result.nFileSizeHigh);
  if Result.nFileSizeLow <> INVALID_FILE_SIZE then
    Result.dwFlags := Result.dwFlags or FD_FILESIZE;


end;

class procedure TClipbrdMonitor.RegisterFormats;
begin
  if ClipFmtRegistered then exit;
  ClipFmtRegistered := true;

  CF_FILECONTENTS := RegisterClipboardFormat(CFSTR_FILECONTENTS);
  CF_FILEDESCRIPTOR := RegisterClipboardFormat(CFSTR_FILEDESCRIPTOR);
  CF_FILENAME := RegisterClipboardFormat(CFSTR_FILENAME);
  CF_PREFERREDDROPEFFECT := RegisterClipboardFormat(CFSTR_PREFERREDDROPEFFECT);
  CF_INETURL := RegisterClipboardFormat(CFSTR_INETURL);
  CF_SHELLURL := RegisterClipboardFormat(CFSTR_SHELLURL);
  CF_FILE_ATTRIBUTES_ARRAY := RegisterClipboardFormat(CFSTR_FILE_ATTRIBUTES_ARRAY);
  CF_SHELLIDLIST := RegisterClipboardFormat(CFSTR_SHELLIDLIST);

end;

procedure TClipbrdMonitor.WndProc(var Message: TMessage);
var
  pid: Cardinal;
begin
  case Message.Msg of
    WM_CHANGECBCHAIN:
      begin
        // If the next window is closing, repair the chain.

        if (Message.wParam = FNextClipViewer) then
            FNextClipViewer := Message.lParam

        // Otherwise, pass the message to the next link.

        else if (FNextClipViewer <> 0) then
            SendMessage(FNextClipViewer, Message.Msg, Message.wParam, Message.lParam);

      end;
    WM_CLIPBOARDUPDATE:
      begin
        { Проверка на новые данные }
        pid := GetClipboardSequenceNumber;
        if pid <> FSequence then
          begin
            FSequence  := pid;
            if Assigned(FOnClip) then
              FOnClip(Self);
          end;
      end;
  end;
end;

{ TClipBrdFileData }


procedure TClipBrdFileData.SaveToStream(stream: TStream);
var
  tmp: Integer;
begin
  stream.WriteBuffer(CLIPBRDFILEDATA_CLASS_ID, SizeOf(CLIPBRDFILEDATA_CLASS_ID));
  stream.WriteBuffer(id, SizeOf(id));
  stream.WriteBuffer(Format, SizeOf(Format));
  tmp := Length(Process);
  stream.Write(tmp, SizeOf(Integer));
  if tmp > 0 then
    stream.WriteBuffer(Pointer(Process)^, tmp * SizeOf(Char));
  tmp := Length(Data);
  stream.WriteBuffer(tmp, SizeOf(Integer));
  if tmp > 0 then
    stream.WriteBuffer(Pointer(Data)^, tmp * SizeOf(Char));
  stream.WriteBuffer(files_count, SizeOf(files_count));
  if files_count > 0 then
    stream.WriteBuffer(files[0], Length(files) * SizeOf(TFileDescriptor));


end;

procedure TClipBrdFileData.SetPath(const Index: Integer; const Value: string);
begin
  if (Index >= 0) and (Index < files_count) then
    FFilePaths[Index] := Value;
end;

procedure TClipBrdFileData.Clear;
begin
  id := 0;
  Format := 0;
  Process := '';
  Data := '';
  files_count := 0;
  SetLength(files, 0);
  SetLength(FFilePaths, 0);
end;

function TClipBrdFileData.FilesToString: string;
var
  I: Integer;
  s: string;
  tc, ta, tw: TSystemTime;
  fmt: TFormatSettings;
begin
  Result := '';
  fmt := FormatSettings;
  for I := 0 to files_count-1 do
    begin
      FileTimeToSystemTime(files[i].ftCreationTime, tc);
      FileTimeToSystemTime(files[i].ftLastAccessTime, ta);
      FileTimeToSystemTime(files[i].ftLastWriteTime, tw);
      SystemTimeToTzSpecificLocalTime(nil, tc, tc);
      SystemTimeToTzSpecificLocalTime(nil, ta, ta);
      SystemTimeToTzSpecificLocalTime(nil, tw, tw);
      s := System.SysUtils.Format(
        'dwFileAttributes = %x' + sLineBreak +
        'ftCreationTime = %s' + sLineBreak +
        'ftLastAccessTime = %s' + sLineBreak  +
        'ftLastWriteTime = %s' + sLineBreak  +
        'nFileSizeHigh = %x' + sLineBreak +
        'nFileSizeLow = %x' + sLineBreak +
        'name = %s' + sLineBreak +
        'path = %s',

        [
          files[i].dwFileAttributes,
          FormatDateTime(fmt.ShortDateFormat + ' ' + fmt.LongTimeFormat, SystemTimeToDateTime(tc)),
          FormatDateTime(fmt.ShortDateFormat + ' ' + fmt.LongTimeFormat, SystemTimeToDateTime(ta)),
          FormatDateTime(fmt.ShortDateFormat + ' ' + fmt.LongTimeFormat, SystemTimeToDateTime(tw)),
          files[i].nFileSizeHigh,
          files[i].nFileSizeLow,
          files[i].cFileName,
          Paths[i]
        ]
        );
      if i = 0 then
        Result := s else
        Result := Result + sLineBreak + sLineBreak + s
    end;

end;

function TClipBrdFileData.GetPath(const Index: Integer): string;
begin
  if (Index >= 0) and (Index < files_count) then
    Result := FFilePaths[Index];
end;

procedure TClipBrdFileData.LoadBromStream(stream: TStream);
var
  tmp: Cardinal;

begin
  stream.ReadBuffer(tmp, SizeOf(CLIPBRDFILEDATA_CLASS_ID));
  if tmp <> CLIPBRDFILEDATA_CLASS_ID then
    raise Exception.Create('Stream has inncorrect data for TClipBrdFileData');


  stream.ReadBuffer(id, SizeOf(id));
  stream.ReadBuffer(Format, SizeOf(Format));
  stream.ReadBuffer(tmp, SizeOf(Integer));
  if tmp > 0 then
    begin
      SetLength(Process, tmp);
      stream.ReadBuffer(Pointer(Process)^, tmp * SizeOf(Char));
    end;
  stream.ReadBuffer(tmp, SizeOf(Integer));
  if tmp > 0 then
    begin
      SetLength(Data, tmp);
      stream.ReadBuffer(Pointer(Data)^, tmp * SizeOf(Char));
    end;
  stream.ReadBuffer(files_count, SizeOf(files_count));
  if files_count > 0 then
    begin
      SetLength(files, files_count);
      SetLength(FFilePaths, files_count);
      stream.ReadBuffer(files[0], Length(files) * SizeOf(TFileDescriptor));
    end;

end;

function TClipBrdFileData.NamesToString: string;
var
  I: Integer;
begin
  for I := 0 to files_count-1 do
    if i = 0 then
      Result := files[i].cFileName else
      Result := Result + sLineBreak + files[i].cFileName
end;

function TClipBrdFileData.PathsToString: string;
var
  I: Integer;
begin
  for I := 0 to files_count-1 do
    if i = 0 then
      Result := FFilePaths[i] else
      Result := Result + sLineBreak + FFilePaths[i]

end;

end.

