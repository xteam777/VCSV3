object LockForm: TLockForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'LockForm'
  ClientHeight = 453
  ClientWidth = 599
  Color = 6450
  CustomTitleBar.CaptionAlignment = taCenter
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -10
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  Position = poDefault
  WindowState = wsMaximized
  StyleElements = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  DesignSize = (
    599
    453)
  TextHeight = 12
  object lblTime: TLabel
    Left = 26
    Top = 275
    Width = 245
    Height = 93
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Anchors = [akLeft, akBottom]
    Caption = '20:12:53'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -70
    Font.Name = 'Segoe UI Light'
    Font.Style = [fsBold]
    ParentFont = False
    StyleElements = []
    ExplicitTop = 140
  end
  object lblUserMessage: TLabel
    Left = 272
    Top = 66
    Width = 155
    Height = 32
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Alignment = taCenter
    Caption = 'lblUserMessage'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clAqua
    Font.Height = -24
    Font.Name = 'Segoe UI Light'
    Font.Style = []
    ParentFont = False
    StyleElements = []
  end
  object lblDate: TLabel
    Left = 26
    Top = 373
    Width = 103
    Height = 45
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Anchors = [akLeft, akBottom]
    Caption = 'lblDate'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'Segoe UI Light'
    Font.Style = [fsBold]
    ParentFont = False
    StyleElements = []
    ExplicitTop = 238
  end
  object TimerDate: TTimer
    OnTimer = TimerDateTimer
    Left = 72
    Top = 36
  end
end
