object rdFileTransferLog: TrdFileTransferLog
  Left = 0
  Top = 0
  Caption = 'File transferring log'
  ClientHeight = 292
  ClientWidth = 419
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object mLog: TMemo
    Left = 0
    Top = 0
    Width = 419
    Height = 251
    Align = alClient
    ReadOnly = True
    TabOrder = 0
  end
  object pBottom: TPanel
    Left = 0
    Top = 251
    Width = 419
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object bOK: TButton
      Left = 156
      Top = 6
      Width = 107
      Height = 29
      Caption = 'OK'
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
    OnSendStart = myUISend
    OnSend = myUISend
    OnSendUpdate = myUISend
    OnSendStop = myUISend
    OnSendCancel = myUISendCancel
    OnRecvStart = myUIRecv
    OnRecv = myUIRecv
    OnRecvStop = myUIRecv
    OnRecvCancel = myUIRecvCancel
    Left = 12
    Top = 22
  end
end
