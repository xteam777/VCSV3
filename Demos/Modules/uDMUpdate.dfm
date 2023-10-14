object DMUpdate: TDMUpdate
  OnCreate = DataModuleCreate
  Height = 300
  Width = 391
  object hcUpdate: TRtcHttpClient
    MultiThreaded = True
    Timeout.AfterConnecting = 40
    Timeout.AfterConnect = 40
    ServerPort = '80'
    ReconnectOn.ConnectError = True
    ReconnectOn.ConnectLost = True
    ReconnectOn.ConnectFail = True
    AutoConnect = True
    UseWinHTTP = True
    MaxResponseSize = 128000
    MaxHeaderSize = 16000
    TimeoutsOfAPI.ConnectTimeout = 5
    Left = 23
    Top = 18
  end
  object drDownload: TRtcDataRequest
    AutoSyncEvents = True
    Client = hcUpdate
    AutoRepost = 2
    OnResponseAbort = drDownloadResponseAbort
    OnDataReceived = drDownloadDataReceived
    Left = 59
    Top = 18
  end
end
