object PlayerForm: TPlayerForm
  Left = 0
  Top = 0
  Caption = #1055#1088#1086#1080#1075#1088#1099#1074#1072#1090#1077#1083#1100
  ClientHeight = 350
  ClientWidth = 582
  Color = clBtnFace
  CustomTitleBar.CaptionAlignment = taCenter
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'Tahoma'
  Font.Style = []
  StyleElements = [seFont, seClient]
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 12
  object btnSlide: TSpeedButton
    Left = 470
    Top = 21
    Width = 18
    Height = 18
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = '5'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -10
    Font.Name = 'Webdings'
    Font.Style = []
    ParentFont = False
    OnClick = btnSlideClick
  end
  object pnlCommon: TPanel
    Left = 121
    Top = 0
    Width = 368
    Height = 20
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'pnlCommon'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -10
    Font.Name = 'Webdings'
    Font.Style = []
    ParentBackground = False
    ParentColor = True
    ParentFont = False
    ParentShowHint = False
    ShowCaption = False
    ShowHint = True
    TabOrder = 0
    DesignSize = (
      368
      20)
    object btnPlay: TSpeedButton
      Left = 38
      Top = 1
      Width = 18
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actPlay
      Align = alLeft
    end
    object btnPause: TSpeedButton
      Left = 1
      Top = 1
      Width = 18
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actPause
      Align = alLeft
    end
    object btnStop: TSpeedButton
      Left = 56
      Top = 1
      Width = 18
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actStop
      Align = alLeft
    end
    object btnForward: TSpeedButton
      Left = 74
      Top = 1
      Width = 19
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actForward
      Align = alLeft
    end
    object btnBackward: TSpeedButton
      Left = 19
      Top = 1
      Width = 19
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actBackward
      Align = alLeft
    end
    object btnOpenFile: TSpeedButton
      Left = 93
      Top = 1
      Width = 18
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actOpenFile
      Align = alLeft
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Wingdings'
      Font.Style = []
      ParentFont = False
    end
    object btnConvert: TSpeedButton
      Left = 111
      Top = 1
      Width = 19
      Height = 18
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Action = actConvert
      Align = alLeft
    end
    object lblTime: TLabel
      Left = 311
      Top = 3
      Width = 52
      Height = 12
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Alignment = taRightJustify
      Anchors = [akLeft, akTop, akRight]
      Caption = '00:00/00:00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
  object ActionList: TActionList
    Left = 296
    Top = 128
    object actPlay: TAction
      Caption = '4'
      Hint = 'Play'
      OnExecute = btnPlayClick
    end
    object actStop: TAction
      Caption = '<'
      Hint = 'Stop'
      OnExecute = actStopExecute
    end
    object actPause: TAction
      Caption = ';'
      Hint = 'Pause'
      OnExecute = actPauseExecute
    end
    object actForward: TAction
      Caption = ':'
      Hint = 'Forward 2 sec'
      OnExecute = actForwardExecute
    end
    object actBackward: TAction
      Caption = '9'
      Hint = 'Backward 2 sec'
      OnExecute = actBackwardExecute
    end
    object actOpenFile: TAction
      Caption = '0'
      Hint = 'Open a file'
      OnExecute = actOpenFileExecute
    end
    object actConvert: TAction
      Caption = #183
      Hint = 'Show a converter'
      OnExecute = actConvertExecute
    end
  end
  object FileOpenDialog: TFileOpenDialog
    DefaultExtension = '*.rmxv'
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'RMX Video File'
        FileMask = '*.rmxv'
      end>
    Options = [fdoFileMustExist]
    Left = 380
    Top = 128
  end
end
