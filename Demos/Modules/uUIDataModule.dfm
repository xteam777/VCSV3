object UIDataModule: TUIDataModule
  Height = 210
  Width = 290
  object UI: TRtcPDesktopControlUI
    MapKeys = True
    SmoothScale = True
    ExactCursor = True
    ControlMode = rtcpFullControl
    HaveScreen = False
    Left = 30
    Top = 8
  end
  object FT_UI: TRtcPFileTransferUI
    OnClose = FT_UIClose
    OnLogOut = FT_UILogOut
    NotifyFileBatchSend = FT_UINotifyFileBatchSend
    Left = 76
    Top = 8
  end
  object PFileTrans: TRtcPFileTransfer
    Left = 122
    Top = 8
  end
  object TimerReconnect: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = TimerReconnectTimer
    Left = 164
    Top = 8
  end
  object TimerRec: TTimer
    Enabled = False
    Left = 206
    Top = 8
  end
end
