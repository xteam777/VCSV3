object MainForm: TMainForm
  Left = 566
  Top = 123
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Remox Gateway'
  ClientHeight = 462
  ClientWidth = 575
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  Position = poScreenCenter
  PrintScale = poNone
  Scaled = False
  ShowHint = True
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 14
  object pMaster: TPanel
    Left = 0
    Top = 0
    Width = 575
    Height = 429
    Align = alClient
    TabOrder = 0
    ExplicitTop = 28
    ExplicitWidth = 595
    ExplicitHeight = 441
    object Pages: TPageControl
      Left = 1
      Top = 1
      Width = 581
      Height = 428
      ActivePage = Page_Setup
      Align = alClient
      TabOrder = 0
      TabStop = False
      ExplicitWidth = 593
      ExplicitHeight = 439
      object Page_Setup: TTabSheet
        Caption = 'Setup'
        object Label3: TLabel
          Left = 8
          Top = 103
          Width = 60
          Height = 14
          Caption = 'SQL Server:'
        end
        object Label9: TLabel
          Left = 9
          Top = 131
          Width = 54
          Height = 14
          Caption = 'Max users:'
        end
        object btnLogin: TButton
          Left = 171
          Top = 279
          Width = 77
          Height = 33
          Caption = 'START'
          Default = True
          TabOrder = 2
          OnClick = btnLoginClick
        end
        object eAddress: TEdit
          Left = 87
          Top = 72
          Width = 165
          Height = 22
          Hint = 'Enter the IP Address of the Network Addapter you want to use'
          Color = clGray
          Enabled = False
          TabOrder = 1
        end
        object xBindIP: TCheckBox
          Left = 7
          Top = 72
          Width = 69
          Height = 21
          Hint = 'You do not want to Listen on all Network Addapters?'
          TabStop = False
          Caption = 'Bind to IP:'
          TabOrder = 0
          OnClick = xBindIPClick
        end
        object Panel2: TPanel
          Left = 3
          Top = 318
          Width = 257
          Height = 86
          BevelInner = bvLowered
          TabOrder = 3
          object Label25: TLabel
            Left = 5
            Top = 10
            Width = 221
            Height = 14
            Caption = 'Gateway can also run as a Windows Service'
          end
          object Label24: TLabel
            Left = 12
            Top = 36
            Width = 40
            Height = 14
            Caption = 'Service:'
          end
          object btnInstall: TSpeedButton
            Left = 56
            Top = 30
            Width = 53
            Height = 25
            Caption = 'Install'
            OnClick = btnInstallClick
          end
          object btnRun: TSpeedButton
            Left = 108
            Top = 30
            Width = 41
            Height = 25
            Caption = 'Run'
            OnClick = btnRunClick
          end
          object btnStop: TSpeedButton
            Left = 148
            Top = 30
            Width = 41
            Height = 25
            Caption = 'Stop'
            OnClick = btnStopClick
          end
          object btnUninstall: TSpeedButton
            Left = 188
            Top = 30
            Width = 61
            Height = 25
            Caption = 'Uninstall'
            OnClick = btnUninstallClick
          end
          object btnRestartService: TSpeedButton
            Left = 108
            Top = 56
            Width = 141
            Height = 25
            Caption = 'Restart Service && Exit'
            OnClick = btnRestartServiceClick
          end
          object btnSaveSetup: TSpeedButton
            Left = 16
            Top = 56
            Width = 93
            Height = 25
            Caption = 'Save Setup'
            OnClick = btnSaveSetupClick
          end
        end
        object eSQLServer: TEdit
          Left = 87
          Top = 100
          Width = 164
          Height = 22
          TabOrder = 4
          Text = 'localhost'
        end
        object cbMainGate: TCheckBox
          Left = 7
          Top = 45
          Width = 69
          Height = 21
          TabStop = False
          Caption = 'Main Gate:'
          TabOrder = 5
          OnClick = cbMainGateClick
        end
        object cb80: TCheckBox
          Left = 87
          Top = 182
          Width = 80
          Height = 17
          Caption = '80'
          TabOrder = 6
          OnClick = cb80Click
        end
        object cb8080: TCheckBox
          Left = 87
          Top = 205
          Width = 80
          Height = 17
          Caption = '8080'
          TabOrder = 7
          OnClick = cb8080Click
        end
        object cb443: TCheckBox
          Left = 171
          Top = 182
          Width = 80
          Height = 17
          Caption = '443'
          TabOrder = 8
          OnClick = cb443Click
        end
        object cb5938: TCheckBox
          Left = 171
          Top = 205
          Width = 80
          Height = 17
          Caption = '5938'
          TabOrder = 9
          OnClick = cb5938Click
        end
        object eMainGate: TEdit
          Left = 87
          Top = 44
          Width = 165
          Height = 22
          Hint = 'Enter the IP Address of the Network Addapter you want to use'
          Color = clGray
          Enabled = False
          TabOrder = 10
        end
        object eMaxUsers: TEdit
          Left = 88
          Top = 128
          Width = 164
          Height = 22
          TabOrder = 11
          Text = '0'
        end
      end
      object Page_Active: TTabSheet
        Caption = 'Active'
        ImageIndex = 1
        object Label5: TLabel
          Left = 8
          Top = 200
          Width = 126
          Height = 14
          Caption = 'This gate logged-in Users:'
        end
        object btnLogout: TSpeedButton
          Left = 180
          Top = 369
          Width = 77
          Height = 37
          Caption = 'STOP'
          OnClick = btnLogoutClick
        end
        object Label1: TLabel
          Left = 8
          Top = 10
          Width = 94
          Height = 14
          Caption = 'All logged-in Users:'
        end
        object Label7: TLabel
          Left = 75
          Top = 302
          Width = 59
          Height = 14
          AutoSize = False
          Caption = '5938:'
        end
        object Label6: TLabel
          Left = 75
          Top = 279
          Width = 59
          Height = 14
          AutoSize = False
          Caption = '443:'
        end
        object Label4: TLabel
          Left = 75
          Top = 253
          Width = 59
          Height = 14
          AutoSize = False
          Caption = '8080:'
        end
        object Label2: TLabel
          Left = 75
          Top = 230
          Width = 59
          Height = 14
          AutoSize = False
          Caption = '80:'
        end
        object l80: TLabel
          Left = 145
          Top = 230
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object l8080: TLabel
          Left = 145
          Top = 253
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object l443: TLabel
          Left = 145
          Top = 279
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object l5938: TLabel
          Left = 145
          Top = 302
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object Label10: TLabel
          Left = 75
          Top = 83
          Width = 59
          Height = 14
          AutoSize = False
          Caption = 'Hosts:'
        end
        object Label11: TLabel
          Left = 75
          Top = 60
          Width = 59
          Height = 14
          AutoSize = False
          Caption = 'Accounts:'
        end
        object lAccounts: TLabel
          Left = 145
          Top = 60
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object lHosts: TLabel
          Left = 145
          Top = 83
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object Label8: TLabel
          Left = 75
          Top = 107
          Width = 59
          Height = 14
          AutoSize = False
          Caption = 'Gateways:'
        end
        object lGateways: TLabel
          Left = 145
          Top = 107
          Width = 59
          Height = 14
          Alignment = taRightJustify
          AutoSize = False
          Caption = '0'
        end
        object eLogoff: TEdit
          Left = 8
          Top = 341
          Width = 249
          Height = 22
          TabOrder = 0
          Text = '100000010'
        end
        object bLogoffUser: TButton
          Left = 8
          Top = 367
          Width = 57
          Height = 25
          Caption = 'Logoff'
          TabOrder = 1
          OnClick = bLogoffUserClick
        end
        object Button1: TButton
          Left = 426
          Top = 274
          Width = 75
          Height = 25
          Caption = 'ClrGet'
          TabOrder = 2
          OnClick = Button1Click
        end
        object Button2: TButton
          Left = 426
          Top = 306
          Width = 75
          Height = 25
          Caption = 'ClrPut'
          TabOrder = 3
          OnClick = Button2Click
        end
        object Button3: TButton
          Left = 426
          Top = 243
          Width = 75
          Height = 25
          Caption = 'ClrMsg'
          TabOrder = 4
          OnClick = Button3Click
        end
      end
    end
  end
  object lblStatusPanel: TPanel
    Left = 0
    Top = 429
    Width = 575
    Height = 33
    Align = alBottom
    BevelInner = bvLowered
    Color = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    ExplicitTop = 469
    ExplicitWidth = 595
    object lblStatus: TLabel
      Left = 2
      Top = 2
      Width = 579
      Height = 29
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Caption = 'Click "START" to start the Gateway.'
      Transparent = True
      Layout = tlCenter
      WordWrap = True
      ExplicitLeft = 1
      ExplicitTop = 1
      ExplicitWidth = 895
    end
  end
  object HttpServer1: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerPort = '80'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenLost = HttpServer1ListenLost
    OnListenError = HttpServer1ListenError
    FixupRequest.RemovePrefix = True
    MaxRequestSize = 16000
    MaxHeaderSize = 64000
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 290
    Top = 71
  end
  object DataProvider1: TRtcDataProvider
    Server = HttpServer1
    OnCheckRequest = DataProvider1CheckRequest
    OnDataReceived = DataProvider1DataReceived
    Left = 372
    Top = 70
  end
  object Gateway1: TRtcPortalGateway
    Server = HttpServer1
    WriteLog = True
    AutoRegisterUsers = True
    OnUserLogin = Gateway1UserLogin
    OnUserLogout = Gateway1UserLogout
    AutoSyncUserEvents = True
    Compression = cMax
    EncryptionKey = 16
    SecureKey = '2240897'
    AutoSessions = True
    ModuleFileName = '/$rdgate'
    OnSessionClosing = Gateway1SessionClosing
    Left = 330
    Top = 70
  end
  object hsMain1: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerAddr = 'localhost'
    ServerPort = '80'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 284
    Top = 399
  end
  object hsMain2: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerAddr = 'localhost'
    ServerPort = '8080'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 322
    Top = 399
  end
  object hsMain3: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerAddr = 'localhost'
    ServerPort = '443'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 358
    Top = 399
  end
  object hsMain4: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerAddr = 'localhost'
    ServerPort = '5938'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 394
    Top = 399
  end
  object HttpServer2: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerPort = '8080'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenLost = HttpServer1ListenLost
    OnListenError = HttpServer1ListenError
    FixupRequest.RemovePrefix = True
    MaxRequestSize = 16000
    MaxHeaderSize = 64000
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 440
    Top = 71
  end
  object Gateway2: TRtcPortalGateway
    Server = HttpServer2
    WriteLog = True
    AutoRegisterUsers = True
    OnUserLogin = Gateway1UserLogin
    OnUserLogout = Gateway1UserLogout
    AutoSyncUserEvents = True
    Compression = cMax
    EncryptionKey = 16
    SecureKey = '2240897'
    AutoSessions = True
    ModuleFileName = '/$rdgate'
    OnSessionClosing = Gateway1SessionClosing
    Left = 480
    Top = 70
  end
  object DataProvider2: TRtcDataProvider
    Server = HttpServer2
    OnCheckRequest = DataProvider1CheckRequest
    OnDataReceived = DataProvider1DataReceived
    Left = 522
    Top = 70
  end
  object HttpServer3: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerPort = '443'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenLost = HttpServer1ListenLost
    OnListenError = HttpServer1ListenError
    FixupRequest.RemovePrefix = True
    MaxRequestSize = 16000
    MaxHeaderSize = 64000
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 288
    Top = 131
  end
  object Gateway3: TRtcPortalGateway
    Server = HttpServer3
    WriteLog = True
    AutoRegisterUsers = True
    OnUserLogin = Gateway1UserLogin
    OnUserLogout = Gateway1UserLogout
    AutoSyncUserEvents = True
    Compression = cMax
    EncryptionKey = 16
    SecureKey = '2240897'
    AutoSessions = True
    ModuleFileName = '/$rdgate'
    OnSessionClosing = Gateway1SessionClosing
    Left = 332
    Top = 132
  end
  object DataProvider3: TRtcDataProvider
    Server = HttpServer3
    OnCheckRequest = DataProvider1CheckRequest
    OnDataReceived = DataProvider1DataReceived
    Left = 372
    Top = 130
  end
  object DataProvider4: TRtcDataProvider
    Server = HttpServer4
    OnCheckRequest = DataProvider1CheckRequest
    OnDataReceived = DataProvider1DataReceived
    Left = 522
    Top = 130
  end
  object Gateway4: TRtcPortalGateway
    Server = HttpServer4
    WriteLog = True
    AutoRegisterUsers = True
    OnUserLogin = Gateway1UserLogin
    OnUserLogout = Gateway1UserLogout
    AutoSyncUserEvents = True
    Compression = cMax
    EncryptionKey = 16
    SecureKey = '2240897'
    AutoSessions = True
    ModuleFileName = '/$rdgate'
    OnSessionClosing = Gateway1SessionClosing
    Left = 478
    Top = 132
  end
  object HttpServer4: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerPort = '5938'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenLost = HttpServer1ListenLost
    OnListenError = HttpServer1ListenError
    FixupRequest.RemovePrefix = True
    MaxRequestSize = 16000
    MaxHeaderSize = 64000
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 438
    Top = 131
  end
  object tGetStatsCount: TTimer
    OnTimer = tGetStatsCountTimer
    Left = 521
    Top = 192
  end
  object MainGateClient: TRtcHttpClient
    MultiThreaded = True
    ServerPort = '9000'
    ReconnectOn.ConnectError = True
    ReconnectOn.ConnectLost = True
    ReconnectOn.ConnectFail = True
    AutoConnect = True
    Left = 273
    Top = 290
  end
  object MainGateServer: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerPort = '9000'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenLost = HttpServer1ListenLost
    OnListenError = HttpServer1ListenError
    FixupRequest.RemovePrefix = True
    MaxRequestSize = 16000
    MaxHeaderSize = 64000
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 274
    Top = 243
  end
  object PortalGateServer: TRtcHttpServer
    MultiThreaded = True
    Timeout.AfterConnecting = 300
    ServerPort = '9000'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    OnListenLost = HttpServer1ListenLost
    OnListenError = HttpServer1ListenError
    FixupRequest.RemovePrefix = True
    MaxRequestSize = 16000
    MaxHeaderSize = 64000
    TimeoutsOfAPI.ResolveTimeout = 10
    TimeoutsOfAPI.ConnectTimeout = 10
    TimeoutsOfAPI.SendTimeout = 10
    TimeoutsOfAPI.ReceiveTimeout = 10
    TimeoutsOfAPI.ResponseTimeout = 10
    Left = 364
    Top = 245
  end
end
