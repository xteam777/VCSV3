object rdFileTransferLog: TrdFileTransferLog
  Left = 0
  Top = 0
  Caption = 'File transferring log'
  ClientHeight = 288
  ClientWidth = 403
  Color = clBtnFace
  CustomTitleBar.CaptionAlignment = taCenter
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  TextHeight = 13
  object mLog: TMemo
    Left = 0
    Top = 0
    Width = 403
    Height = 247
    Align = alClient
    ReadOnly = True
    TabOrder = 0
    ExplicitWidth = 399
    ExplicitHeight = 246
  end
  object pBottom: TPanel
    Left = 0
    Top = 247
    Width = 403
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 246
    ExplicitWidth = 399
    object bOK: TButton
      Left = 156
      Top = 6
      Width = 107
      Height = 29
      Caption = 'Close'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = bOKClick
    end
  end
  object myUI: TRtcPFileTransferUI
    OnInit = myUIInit
    OnOpen = myUIOpen
    OnClose = myUIClose
    OnError = myUIError
    OnLogOut = myUILogOut
    OnSendStart = myUISendStart
    OnSend = myUISend
    OnSendUpdate = myUISend
    OnSendStop = myUISend
    OnSendCancel = myUISendCancel
    OnRecvStart = myUIRecvStart
    OnRecv = myUIRecv
    OnRecvStop = myUIRecv
    OnRecvCancel = myUIRecvCancel
    Left = 14
    Top = 22
  end
end
