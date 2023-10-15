unit uDMUpdate;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes, rtcSystem, rtcInfo, rtcConn, rtcDataCli,
  rtcHttpCli, rtcCliModule, ShellApi, uSetup, ShlObj, CommonData, SyncObjs, Math;

const
  US_READY = 0;
  US_DOWNLOADING = 1;
  US_INSTALLING = 1;

type
  TOnProgressChange = procedure (AUpdateStatus, AProgress: Integer) of Object;

  TDMUpdate = class(TDataModule)
    hcUpdate: TRtcHttpClient;
    drDownload: TRtcDataRequest;
    procedure DataModuleCreate(Sender: TObject);
    procedure drDownloadDataReceived(Sender: TRtcConnection);
    procedure drDownloadResponseAbort(Sender: TRtcConnection);
    procedure drDownloadBeginRequest(Sender: TRtcConnection);
  private
    fOut: TRtcFileHdl;
    { Private declarations }
    procedure InstallServiceUpdate;
    procedure InstallClientUpdate;
  public
    { Public declarations }
    CurFilePos: Integer;
    LastVersion, TempExeName: String;
    UpdateStatus: Integer;
    Progress: Integer;
    OnSuccessCheck: TNotifyEvent;
    procedure StartUpdate(AProxyEnabled: Boolean; AProxyAddr, AProxyUserName, AProxyPassword: String);
    procedure GetProgress(var AUpdateStatus, AProgress: Integer);
  end;

  PDMUpdateThread = ^TDMUpdateThread;
  TDMUpdateThread = class(TThread)
  private
  public
    DMUpdate: TDMUpdate;
    constructor Create(CreateSuspended: Boolean; AOnSuccessCheck: TNotifyEvent); overload;
    destructor Destroy; override;
  protected
    procedure Execute; override;
  end;

var
//  DMUpdate: TDMUpdate;
  CS: TCriticalSection;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

constructor TDMUpdateThread.Create(CreateSuspended: Boolean; AOnSuccessCheck: TNotifyEvent);
begin
  inherited Create(CreateSuspended);

  DMUpdate := TDMUpdate.Create(nil);
  DMUpdate.OnSuccessCheck := AOnSuccessCheck;
end;

destructor TDMUpdateThread.Destroy;
begin
  FreeAndNil(DMUpdate);
end;

procedure TDMUpdateThread.Execute;
begin
  while not Terminated do
    Sleep(100);
end;

procedure TDMUpdate.GetProgress(var AUpdateStatus, AProgress: Integer);
begin
  CS.Acquire;
  try
    AUpdateStatus := UpdateStatus;
    AProgress := Progress;
  finally
    CS.Release;
  end;
end;

procedure TDMUpdate.DataModuleCreate(Sender: TObject);
begin
  UpdateStatus := US_READY;
  Progress := 0;
  hcUpdate.ServerAddr := 'remox.com';
end;

procedure TDMUpdate.drDownloadBeginRequest(Sender: TRtcConnection);
begin
  with Sender as TRtcDataClient do
  begin
    // Make sure that our request starts with "/"
    if Copy(Request.FileName, 1, 1) <> '/' then
      Request.FileName := '/' + Trim(Request.FileName);

//    edFileName.Text := Request.FileName;
    // Define the "HOST" header
    if Request.Host = '' then
    begin
      ServerAddr := 'remox.com';
      Request.Host := ServerAddr;
    end;

    // Send Request Header out
    WriteHeader;
  end;
end;

procedure TDMUpdate.drDownloadDataReceived(Sender: TRtcConnection);
var
  Progress: Double;
  data: RtcByteArray;
begin
  CS.Acquire;
  try
    with Sender as TRtcDataClient do
    begin
      if Response.Started then
      begin
        Delete_File(TempExeName);
        CurFilePos := 0;
//        fOut := FileOpen(TempExeName, fmOpenReadWrite + fmShareDenyNone);
        fOut := FileCreate(TempExeName);
      end;

      data := ReadEx;
      if Length(data)>0 then
      begin
        if CurFilePos < 0 then
        begin
        FileSeek(fOut, 0, 2);
        if FileWrite(fOut, data[0], Length(data)) = Length(data) then
//            Result:=True;
        end
        else
        begin
        if FileSeek(fOut, CurFilePos, 0) = CurFilePos then
          if FileWrite(fOut, data[0], Length(data)) = Length(data) then
//              Result:=True;
        end;
      end;

//      Write_FileEx(TempExeName, ReadEx, CurFilePos);
      CurFilePos := CurFilePos + DataIn;

      if Response.DataSize <> 0 then
        Progress := CurFilePos / Response.DataSize * 100
      else
        Progress := 0;

      if Response.Done then
      begin
        FileClose(fOut);

        Request.Host := '';
        hcUpdate.Disconnect;

        Progress := 100;

        UpdateStatus := US_INSTALLING;

        if IsService then
          InstallServiceUpdate
        else
          InstallClientUpdate;

        UpdateStatus := US_READY;

        Halt;
      end;
    end;
  finally
    CS.Release;
  end;
end;

procedure TDMUpdate.drDownloadResponseAbort(Sender: TRtcConnection);
begin
  Tag := Tag;
end;

procedure TDMUpdate.InstallServiceUpdate;
var
  pfFolder, fn: String;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);
  with TStringList.Create do
  try
    Add('PING 127.0.0.1 -n 2 > NUL');
    Add('"' + TempExeName + '" /STOP');
    Add('"' + TempExeName + '" /KILL');
    Add('COPY "' + TempExeName + '" "' + pfFolder + '\Remox\Remox.exe" /Y');
    Add('"' + TempExeName + '" /START');
    fn := GetTempFile + '.bat';
    Add('DEL "' + fn + '"');
    SaveToFile(fn, TEncoding.GetEncoding(866));
  finally
    Free;
  end;

  ShellExecute(0, 'open', PWideChar(fn), '', '', SW_HIDE);
end;

procedure TDMUpdate.InstallClientUpdate;
var
  pfFolder, fn: String;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);
  with TStringList.Create do
  try
    Add('PING 127.0.0.1 -n 2 > NUL');
    Add('"' + TempExeName + '" /KILL');
    Add('COPY "' + TempExeName + '" "' + ParamStr(0) + '" /Y');
    Add('"' + ParamStr(0) + '"');
    fn := GetTempFile + '.bat';
    Add('DEL "' + fn + '"');
    SaveToFile(fn, TEncoding.GetEncoding(866));
  finally
    Free;
  end;

  ShellExecute(0, 'open', PWideChar(fn), '', '', SW_HIDE);
end;

procedure TDMUpdate.StartUpdate(AProxyEnabled: Boolean; AProxyAddr, AProxyUserName, AProxyPassword: String);
begin
  CS.Acquire;
  try
    UpdateStatus := US_DOWNLOADING;
  finally
    CS.Release;
  end;

  hcUpdate.UseProxy := AProxyEnabled;
  hcUpdate.UserLogin.ProxyAddr := AProxyAddr;
  hcUpdate.UserLogin.ProxyUserName := AProxyUserName;
  hcUpdate.UserLogin.ProxyPassword := AProxyPassword;

  TempExeName := GetTempFile + '.exe';

  with drDownload do
  begin
    Request.Method := 'GET';
    Request.FileName := '/download/Remox.exe';
    Post;
  end;

  hcUpdate.Connect();
end;

initialization
  CS := TCriticalSection.Create;

finalization
  CS.Free;

end.
