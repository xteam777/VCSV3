object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 397
  ClientWidth = 747
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  WindowState = wsMaximized
  PixelsPerInch = 120
  TextHeight = 16
  object btnMake: TButton
    Left = 44
    Top = 40
    Width = 98
    Height = 25
    Caption = 'Make Layered'
    TabOrder = 0
    OnClick = btnMakeClick
  end
  object btnReset: TButton
    Left = 163
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Reset'
    TabOrder = 1
    OnClick = btnResetClick
  end
  object chkDisableInput: TCheckBox
    Left = 360
    Top = 44
    Width = 193
    Height = 17
    Caption = 'Disable Input'
    TabOrder = 2
  end
  object btnClose: TButton
    Left = 252
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 3
    OnClick = btnCloseClick
  end
  object edPercent: TEdit
    Left = 44
    Top = 10
    Width = 121
    Height = 24
    Color = clWhite
    NumbersOnly = True
    TabOrder = 4
    Text = '80'
  end
  object btnDisableRecord: TButton
    Left = 44
    Top = 76
    Width = 125
    Height = 25
    Caption = 'Disable Record'
    TabOrder = 5
    OnClick = btnDisableRecordClick
  end
  object btnSHowForm: TButton
    Left = 44
    Top = 116
    Width = 145
    Height = 25
    Caption = 'btnSHowForm'
    TabOrder = 6
    OnClick = btnSHowFormClick
  end
  object btnShowModal: TButton
    Left = 236
    Top = 116
    Width = 129
    Height = 25
    Caption = 'btnShowModal'
    TabOrder = 7
    OnClick = btnShowModalClick
  end
end
