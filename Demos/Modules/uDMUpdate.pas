unit uDMUpdate;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes, rtcSystem, rtcInfo, rtcConn, rtcDataCli,
  rtcHttpCli, rtcCliModule, ShellApi, uSetup, ShlObj, CommonData, SyncObjs;

const
  US_READY = 0;
  US_DOWNLOADING = 1;
  US_INSTALLING = 1;

type
  TDMUpdate = class(TDataModule)
    hcUpdate: TRtcHttpClient;
    drDownload: TRtcDataRequest;
    procedure DataModuleCreate(Sender: TObject);
    procedure drDownloadDataReceived(Sender: TRtcConnection);
  private
    { Private declarations }
    procedure InstallServiceUpdate;
    procedure InstallClientUpdate;
  public
    { Public declarations }
    CurFilePos: Integer;
    LastVersion, TempExeName: String;
    UpdateStatus: Integer;
    Progress: Double;
    OnSuccessCheck: TNotifyEvent;
    procedure StartUpdate(AProxyEnabled: Boolean; AProxyAddr, AProxyUserName, AProxyPassword: String);
    procedure GetProgress(var AUpdateStatus: Integer; AProgress: Double);
  end;

var
  DMUpdate: TDMUpdate;
  CS: TCriticalSection;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDMUpdate.GetProgress(var AUpdateStatus: Integer; AProgress: Double);
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

procedure TDMUpdate.drDownloadDataReceived(Sender: TRtcConnection);
begin
  with Sender as TRtcDataClient do
  begin
    if Response.Started then
    begin
      Delete_File(TempExeName);
      CurFilePos := 0;
      Write_FileEx(TempExeName, ReadEx, CurFilePos);
      CurFilePos := CurFilePos + DataIn;

      CS.Acquire;
      try
        if Request.ContentLength <> 0 then
          Progress := CurFilePos / Request.ContentLength * 100
        else
          Progress := 0;
      finally
        CS.Release;
      end;

      Exit;
    end;

    Write_FileEx(TempExeName, ReadEx, CurFilePos);
    CurFilePos := CurFilePos + DataIn;

    CS.Acquire;
    try
      if Request.ContentLength <> 0 then
        Progress := CurFilePos / Request.ContentLength * 100
      else
        Progress := 0;
    finally
      CS.Release;
    end;

    if Response.Done then
    begin
      Request.Host := '';
      hcUpdate.Disconnect;

      CS.Acquire;
      try
        Progress := 100;
      finally
        CS.Release;
      end;

      CS.Acquire;
      try
        UpdateStatus := US_INSTALLING;
      finally
        CS.Release;
      end;

      if IsService then
        InstallServiceUpdate
      else
        InstallClientUpdate;

      CS.Acquire;
      try
        UpdateStatus := US_READY;
      finally
        CS.Release;
      end;
    end;
  end;
end;

procedure TDMUpdate.InstallServiceUpdate;
var
  pfFolder, fn: String;
begin
  pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);
  with TStringList.Create do
  try
    Add('PING 127.0.0.1 -n 2 > NUL');
    Add(TempExeName + ' /STOP');
    Add(TempExeName + ' /KILL');
    Add('COPY "' + TempExeName + '" "' + ' "' + pfFolder + '\Remox\Remox.exe"');
    Add(TempExeName + ' /START');
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
    Add(TempExeName + ' /KILL');
    Add('COPY "' + TempExeName + '" "' + ' "' + ParamStr(0) + '"');
    Add('START ' + ParamStr(0));
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
