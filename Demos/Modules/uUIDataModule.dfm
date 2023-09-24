object UIDataModule: TUIDataModule
  Left = 0
  Top = 0
  ClientHeight = 103
  ClientWidth = 267
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object UI: TRtcPDesktopControlUI
    MapKeys = True
    SmoothScale = True
    ExactCursor = True
    ControlMode = rtcpFullControl
    HaveScreen = False
    Left = 46
    Top = 8
  end
  object FT_UI: TRtcPFileTransferUI
    Left = 76
    Top = 8
  end
  object PFileTrans: TRtcPFileTransfer
    Left = 120
    Top = 8
  end
  object TimerReconnect: TTimer
    Enabled = False
    Interval = 60000
    Left = 158
    Top = 10
  end
  object TimerRec: TTimer
    Enabled = False
    Left = 198
    Top = 12
  end
end
