object UIDataModule: TUIDataModule
  Height = 210
  Width = 290
  object UI: TRtcPDesktopControlUI
    MapKeys = True
    SmoothScale = True
    ExactCursor = True
    ControlMode = rtcpFullControl
    Left = 30
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
end
