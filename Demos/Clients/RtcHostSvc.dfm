object RemoxService: TRemoxService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  OnDestroy = ServiceDestroy
  DisplayName = 'Remox'
  Interactive = True
  OnExecute = ServiceExecute
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 215
  Width = 303
  object PClient: TRtcHttpPortalClient
    UserVisible = True
    OnLogIn = PClientLogIn
    OnLogOut = PClientLogOut
    OnError = PClientError
    OnFatalError = PClientFatalError
    AutoSyncEvents = True
    DataCompress = rtcpCompMax
    DataEncrypt = 16
    DataSecureKey = '2240897'
    DataForceEncrypt = True
    RetryFirstLogin = -1
    RetryOtherCalls = -1
    MultiThreaded = True
    GatePort = '443'
    Gate_Timeout = 300
    Gate_WinHttp = True
    OnStatusGet = PClientStatusGet
    Left = 44
    Top = 8
  end
  object PFileTrans: TRtcPFileTransfer
    Client = PClient
    BeTheHost = True
    GUploadAnywhere = True
    GUploadAnywhere_Super = True
    GAllowFileMove = True
    GAllowFileMove_Super = True
    GAllowFileRename = True
    GAllowFileRename_Super = True
    GAllowFileDelete = True
    GAllowFileDelete_Super = True
    GAllowFolderCreate = True
    GAllowFolderCreate_Super = True
    GAllowFolderMove = True
    GAllowFolderMove_Super = True
    GAllowFolderRename = True
    GAllowFolderRename_Super = True
    GAllowFolderDelete = True
    GAllowFolderDelete_Super = True
    GAllowShellExecute = True
    GAllowShellExecute_Super = True
    Left = 72
    Top = 6
  end
  object PChat: TRtcPChat
    Client = PClient
    BeTheHost = True
    Left = 98
    Top = 6
  end
  object PDesktopHost: TRtcPDesktopHost
    Client = PClient
    FileTransfer = PFileTrans
    Left = 126
    Top = 6
  end
  object tPClientReconnect: TTimer
    Enabled = False
    OnTimer = tPClientReconnectTimer
    Left = 160
    Top = 7
  end
  object HostTimerModule: TRtcClientModule
    AutoSyncEvents = True
    Client = HostTimerClient
    Compression = cMax
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    AutoRepost = 2
    ModuleFileName = '/gatefunc'
    Left = 68
    Top = 142
  end
  object HostTimerClient: TRtcHttpClient
    MultiThreaded = True
    Timeout.AfterConnecting = 40
    ServerPort = '443'
    OnConnect = HostTimerClientConnect
    OnDisconnect = HostTimerClientDisconnect
    ReconnectOn.ConnectLost = True
    ReconnectOn.ConnectFail = True
    OnConnectLost = HostTimerClientConnectLost
    OnConnectError = HostTimerClientConnectError
    AutoConnect = True
    UseWinHTTP = True
    MaxResponseSize = 128000
    MaxHeaderSize = 16000
    Left = 16
    Top = 143
  end
  object resHostPing: TRtcResult
    OnReturn = resHostPingReturn
    Left = 39
    Top = 57
  end
  object rActivate: TRtcResult
    OnReturn = rActivateReturn
    Left = 3
    Top = 54
  end
  object tHostTimerClientReconnect: TTimer
    Enabled = False
    OnTimer = tHostTimerClientReconnectTimer
    Left = 145
    Top = 55
  end
  object HostPingTimer: TTimer
    Enabled = False
    Interval = 6000
    OnTimer = HostPingTimerTimer
    Left = 171
    Top = 54
  end
  object resHostLogin: TRtcResult
    OnReturn = resHostLoginReturn
    Left = 207
    Top = 56
  end
  object resHostLogout: TRtcResult
    Left = 241
    Top = 55
  end
  object resHostPassUpdate: TRtcResult
    Left = 195
    Top = 7
  end
  object resHostTimerLogin: TRtcResult
    Left = 73
    Top = 55
  end
  object resHostTimer: TRtcResult
    OnReturn = resHostTimerReturn
    Left = 107
    Top = 54
  end
  object tActivate: TTimer
    Enabled = False
    OnTimer = tActivateTimer
    Left = 232
    Top = 8
  end
  object resPing: TRtcResult
    OnReturn = resPingReturn
    Left = 239
    Top = 101
  end
end
