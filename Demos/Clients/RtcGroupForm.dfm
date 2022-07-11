object GroupForm: TGroupForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1043#1088#1091#1087#1087#1072' '#1082#1086#1084#1087#1100#1102#1090#1077#1088#1086#1074
  ClientHeight = 96
  ClientWidth = 335
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label6: TLabel
    Left = 12
    Top = 8
    Width = 109
    Height = 23
    AutoSize = False
    Caption = #1053#1072#1079#1074#1072#1085#1080#1077' '#1075#1088#1091#1087#1087#1099':'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Layout = tlCenter
  end
  object eName: TEdit
    Left = 127
    Top = 8
    Width = 196
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    MaxLength = 50
    ParentFont = False
    TabOrder = 0
    OnKeyDown = FormKeyDown
  end
  object pBtnClose: TPanel
    Left = 216
    Top = 59
    Width = 107
    Height = 29
    BevelKind = bkFlat
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object bClose: TSpeedButton
      Tag = 1
      Left = 0
      Top = 0
      Width = 103
      Height = 25
      Align = alClient
      Caption = #1054#1058#1052#1045#1053#1040
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = cl3DDkShadow
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = bCloseClick
      ExplicitLeft = 64
    end
  end
  object pBtnOK: TPanel
    Left = 96
    Top = 59
    Width = 107
    Height = 29
    BevelKind = bkFlat
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object bOK: TSpeedButton
      Tag = 1
      Left = 0
      Top = 0
      Width = 103
      Height = 25
      Align = alClient
      Caption = #1054#1050
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = cl3DDkShadow
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = bOKClick
      ExplicitLeft = -2
    end
  end
  object Panel2: TPanel
    Left = 12
    Top = 45
    Width = 311
    Height = 4
    TabOrder = 3
  end
  object rAddGroup: TRtcResult
    OnReturn = rAddGroupReturn
    Left = 8
    Top = 56
  end
  object rChangeGroup: TRtcResult
    OnReturn = rChangeGroupReturn
    Left = 35
    Top = 56
  end
end
