unit Updater;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Net.HTTPClient, System.Net.URLClient, System.IOUtils,
  Vcl.StdCtrls, Vcl.ComCtrls, rtcLog, System.Types;

type
  TDownloadThreadDataEvent = procedure(const Sender: TObject; ThreadNo, ASpeed: Integer; AContentLength: Int64; AReadCount: Int64; var Abort: Boolean) of object;
  TDownloadThread = class(TThread)
  private
    FOnThreadData: TDownloadThreadDataEvent;
  protected
    FURL, FFileName: string;
    FStartPoint, FEndPoint: Int64;
    FThreadNo: Integer;
    FTimeStart: Cardinal;

    procedure ReceiveDataEvent(const Sender: TObject; AContentLength: Int64; AReadCount: Int64; var Abort: Boolean);
  public
    procedure Execute; override;

    property OnThreadData: TDownloadThreadDataEvent write FOnThreadData;
  end;

  TfUpdater = class(TForm)
    LabelGlobalSpeed: TLabel;
    ProgressBarDownload: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FURL, FFileName: string;
    FClient: THTTPClient;
    FGlobalStart: DWORD;
    FDownloadStream: TFileStream;
    FAsyncResult: IAsyncResult;
    { Private declarations }
  public
    { Public declarations }
    procedure StartDownload;
    procedure DoEndDownload(const AsyncResult: IAsyncResult);
  end;

var
  fUpdater: TfUpdater;

implementation

{$R *.dfm}

procedure TDownloadThread.Execute;
var
  LResponse: IHTTPResponse;
  LStream: TFileStream;
  LHttpClient: THTTPClient;
begin
  inherited;
  //создаем объект клиента HTTP
  LHttpClient := THTTPClient.Create;
  try
    //настраиваем обработчик события OnReceiveData
    //событие срабатывает при получении очередного ответа от сервера
    LHttpClient.OnReceiveData := ReceiveDataEvent;
    //настраиваем поток для хранения данных
    LStream := TFileStream.Create(FFileName, fmOpenWrite or fmShareDenyNone);
    try
      FTimeStart := GetTickCount;
      LStream.Seek(FStartPoint, TSeekOrigin.soBeginning);
      //отправляем запрос на получение части файла
      LResponse := LHttpClient.GetRange(FURL, FStartPoint, FEndPoint, LStream);
    finally
      LStream.Free;
    end;
  finally
    LHttpClient.Free;
  end;
end;

procedure TDownloadThread.ReceiveDataEvent(const Sender: TObject; AContentLength, AReadCount: Int64;
  var Abort: Boolean);
var
  LTime: Cardinal;
  LSpeed: Integer;
begin
  if Assigned(FOnThreadData) then
  begin
    LTime := GetTickCount - FTimeStart;
    if AReadCount = 0 then
      LSpeed := 0
    else
      LSpeed := (AReadCount * 1000) div LTime;
    //отправляем событие потока OnThreadData
    //передаем номер потока, скорость загрузки, размер скачанных данных
    FOnThreadData(Sender, FThreadNo, LSpeed, AContentLength, AReadCount, Abort);
  end;
end;

procedure TfUpdater.StartDownload;
var
  URL: string;
  LResponse: IHTTPResponse;
  LFileName: string;
  LSize: Int64;
begin
  LFileName := TPath.Combine(TPath.GetDocumentsPath, FFileName);
  try
    URL := FURL;

    LResponse := FClient.Head(URL);
    LSize := LResponse.ContentLength;
    xLog(Format('Head response: %d - %s', [LResponse.StatusCode, LResponse.StatusText]));
    LResponse := nil;

    ProgressBarDownload.Max := LSize;
    ProgressBarDownload.Min := 0;
    ProgressBarDownload.Position := 0;
    LabelGlobalSpeed.Caption := 'Global speed: 0 KB/s';

    xLog(Format('Downloading: "%s" (%d Bytes) into "%s"' , [FFileName, LSize, LFileName]));

    // создаем поток, в который будем сохранять файл
    FDownloadStream := TFileStream.Create(LFileName, fmCreate);
    FDownloadStream.Position := 0;

    FGlobalStart := TThread.GetTickCount;

    // запускаем процесс загрузки в асинхронном режиме
    FAsyncResult := FClient.BeginGet(DoEndDownload, URL, FDownloadStream);

  finally
//    BStopDownload.Enabled := FAsyncResult &lt;&gt; nil;
//    BStartDownload.Enabled := FAsyncResult = nil;
  end;
end;

procedure TfUpdater.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//  FClient.
end;

procedure TfUpdater.FormCreate(Sender: TObject);
begin
  FURL := 'https://remox.support/';
  FFileName := 'remox.exe';
  FClient := THTTPClient.Create;

  StartDownload;
end;

procedure TfUpdater.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FClient);
end;

procedure TfUpdater.DoEndDownload(const AsyncResult: IAsyncResult);
var
  LAsyncResponse: IHTTPResponse;
begin
  try
    LAsyncResponse := THTTPClient.EndAsyncHTTP(AsyncResult);
    TThread.Synchronize(nil,
      procedure
      begin
        xLog('Download Finished!');
        xLog(Format('Status: %d - %s', [LAsyncResponse.StatusCode, LAsyncResponse.StatusText]));
      end);
  finally
    LAsyncResponse := nil;
    FreeandNil(FDownloadStream);
//    BStopDownload.Enabled := False;
//    BStartDownload.Enabled := True;
  end;
end;

end.
