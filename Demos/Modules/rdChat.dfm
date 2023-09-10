object rdChatForm: TrdChatForm
  Left = 433
  Top = 139
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'rdChatForm'
  ClientHeight = 408
  ClientWidth = 421
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  Position = poDefault
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  OnShow = FormResize
  TextHeight = 13
  object Panel3: TPanel
    Left = 3
    Top = 3
    Width = 415
    Height = 402
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alClient
    ParentBackground = False
    TabOrder = 0
    OnMouseDown = Panel3MouseDown
    OnMouseMove = Panel3MouseMove
    OnMouseUp = Panel3MouseUp
    object pSplit: TSplitter
      Left = 1
      Top = 174
      Width = 413
      Height = 4
      Cursor = crVSplit
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alTop
      Color = clGray
      ParentColor = False
    end
    object pMain: TPanel
      Left = 1
      Top = 30
      Width = 413
      Height = 144
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alTop
      BorderWidth = 2
      ParentBackground = False
      TabOrder = 1
      object mChatLog: TRichEdit
        Left = 2
        Top = 2
        Width = 408
        Height = 140
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        TabStop = False
        Align = alClient
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        PopupMenu = HistoryPopupMenu
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object pBox: TScrollBox
      Left = 1
      Top = 261
      Width = 413
      Height = 140
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      VertScrollBar.Smooth = True
      VertScrollBar.Style = ssHotTrack
      VertScrollBar.Tracking = True
      Align = alClient
      BorderStyle = bsNone
      Color = 14737632
      ParentColor = False
      TabOrder = 0
      TabStop = True
    end
    object pTitle: TPanel
      Left = 1
      Top = 1
      Width = 413
      Height = 29
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alTop
      BevelOuter = bvNone
      Color = 12704960
      ParentBackground = False
      TabOrder = 2
      OnMouseDown = pTitleMouseDown
      OnMouseMove = pTitleMouseMove
      OnMouseUp = pTitleMouseUp
      object cTitle: TLabel
        Left = 8
        Top = 8
        Width = 27
        Height = 13
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Caption = 'Chat'
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = True
        OnMouseDown = pTitleMouseDown
        OnMouseMove = pTitleMouseMove
        OnMouseUp = pTitleMouseUp
      end
      object Panel2: TPanel
        Left = 306
        Top = 0
        Width = 107
        Height = 29
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Align = alRight
        BevelOuter = bvNone
        Color = clMoneyGreen
        TabOrder = 0
        object btnClose: TSpeedButton
          Left = 82
          Top = 4
          Width = 21
          Height = 21
          Margins.Left = 2
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 2
          Caption = 'X'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnCloseClick
        end
        object btnMinimize: TSpeedButton
          Left = 63
          Top = 4
          Width = 19
          Height = 21
          Margins.Left = 2
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 2
          Caption = '_'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          OnClick = btnMinimizeClick
        end
        object btnOnTop: TSpeedButton
          Left = 4
          Top = 3
          Width = 52
          Height = 23
          Margins.Left = 2
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 2
          Caption = 'To Top'
          Flat = True
          Layout = blGlyphRight
          OnClick = btnOnTopClick
        end
      end
    end
    object myBox: TPanel
      Left = 1
      Top = 205
      Width = 413
      Height = 56
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alTop
      AutoSize = True
      BevelOuter = bvNone
      Color = 14737632
      ParentBackground = False
      TabOrder = 3
    end
    object Panel12: TPanel
      Left = 1
      Top = 178
      Width = 413
      Height = 27
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alTop
      ParentBackground = False
      TabOrder = 4
      object btnLockChatBoxes: TSpeedButton
        Left = 319
        Top = 3
        Width = 91
        Height = 23
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Caption = 'Lock Chat Boxes'
        Flat = True
        Layout = blGlyphRight
        OnClick = btnLockChatBoxesClick
      end
      object btnClearHistory: TSpeedButton
        Left = 67
        Top = 2
        Width = 75
        Height = 24
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Caption = 'Clear History'
        Flat = True
        OnClick = btnClearHistoryClick
      end
      object btnHideHistory: TSpeedButton
        Left = 146
        Top = 2
        Width = 76
        Height = 24
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Caption = 'Hide History'
        Flat = True
        OnClick = btnHideHistoryClick
      end
      object btnDesktop: TSpeedButton
        Left = 4
        Top = 2
        Width = 60
        Height = 24
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Caption = 'Desktop'
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Visible = False
        OnClick = btnDesktopClick
      end
      object btnHideTyping: TSpeedButton
        Left = 225
        Top = 2
        Width = 91
        Height = 24
        Margins.Left = 2
        Margins.Top = 2
        Margins.Right = 2
        Margins.Bottom = 2
        Caption = 'Hide my Typing'
        Flat = True
        OnClick = btnHideTypingClick
      end
    end
  end
  object pRight: TPanel
    Left = 418
    Top = 3
    Width = 3
    Height = 402
    Cursor = crSizeWE
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alRight
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 1
    OnMouseDown = Panel3MouseDown
    OnMouseMove = Panel3MouseMove
    OnMouseUp = Panel3MouseUp
    object pSize1: TPanel
      Left = 0
      Top = 390
      Width = 3
      Height = 12
      Cursor = crSizeNWSE
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alBottom
      BevelOuter = bvNone
      Color = clBlack
      TabOrder = 0
      OnMouseDown = Panel3MouseDown
      OnMouseMove = Panel3MouseMove
      OnMouseUp = Panel3MouseUp
    end
  end
  object pBottom: TPanel
    Left = 0
    Top = 405
    Width = 421
    Height = 3
    Cursor = crSizeNS
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alBottom
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 2
    OnMouseDown = Panel3MouseDown
    OnMouseMove = Panel3MouseMove
    OnMouseUp = Panel3MouseUp
    object pSize2: TPanel
      Left = 406
      Top = 0
      Width = 15
      Height = 3
      Cursor = crSizeNWSE
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alRight
      BevelOuter = bvNone
      Color = clBlack
      TabOrder = 0
      OnMouseDown = Panel3MouseDown
      OnMouseMove = Panel3MouseMove
      OnMouseUp = Panel3MouseUp
    end
  end
  object pLeft: TPanel
    Left = 0
    Top = 3
    Width = 3
    Height = 402
    Cursor = crSizeWE
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alLeft
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 3
    OnMouseDown = Panel3MouseDown
    OnMouseMove = Panel3MouseMove
    OnMouseUp = Panel3MouseUp
    object pSize4: TPanel
      Left = 0
      Top = 0
      Width = 3
      Height = 12
      Cursor = crSizeNWSE
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alTop
      BevelOuter = bvNone
      Color = clBlack
      TabOrder = 0
      OnMouseDown = Panel3MouseDown
      OnMouseMove = Panel3MouseMove
      OnMouseUp = Panel3MouseUp
    end
  end
  object pTop: TPanel
    Left = 0
    Top = 0
    Width = 421
    Height = 3
    Cursor = crSizeNS
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alTop
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 4
    OnMouseDown = Panel3MouseDown
    OnMouseMove = Panel3MouseMove
    OnMouseUp = Panel3MouseUp
    object pSize3: TPanel
      Left = 0
      Top = 0
      Width = 14
      Height = 3
      Cursor = crSizeNWSE
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alLeft
      BevelOuter = bvNone
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnMouseDown = Panel3MouseDown
      OnMouseMove = Panel3MouseMove
      OnMouseUp = Panel3MouseUp
    end
  end
  object pTimer: TTimer
    Enabled = False
    Interval = 500
    OnTimer = pTimerTimer
    Left = 248
    Top = 45
  end
  object CopyPastePopupMenu: TPopupMenu
    Left = 280
    Top = 45
    object Copy1: TMenuItem
      Caption = 'Copy'
      OnClick = Copy1Click
    end
    object Paste1: TMenuItem
      Caption = 'Paste'
      OnClick = Paste1Click
    end
  end
  object HistoryPopupMenu: TPopupMenu
    Left = 60
    Top = 89
    object miSaveHistory: TMenuItem
      Caption = 'Save History'
      OnClick = miSaveHistoryClick
    end
    object miLoadHistory: TMenuItem
      Caption = 'Load History'
      OnClick = miLoadHistoryClick
    end
    object miCopyHistory: TMenuItem
      Caption = 'Copy to Clipboard'
      OnClick = miCopyHistoryClick
    end
  end
  object dlgSaveHistory: TSaveDialog
    DefaultExt = '.hst'
    Filter = 'History(*.hst)|*.hst'
    InitialDir = '.'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 92
    Top = 89
  end
  object dlgLoadHistory: TOpenDialog
    DefaultExt = '.hst'
    Filter = 'History(*.hst)|*.hst'
    InitialDir = '.'
    Options = [ofReadOnly, ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 28
    Top = 89
  end
  object myUI: TRtcPChatUI
    OnInit = myUIInit
    OnOpen = myUIOpen
    OnClose = myUIClose
    OnError = myUIError
    OnLogOut = myUILogOut
    OnUserJoined = myUIUserJoined
    OnUserLeft = myUIUserLeft
    OnMessage = myUIMessage
    Left = 140
    Top = 8
  end
end
