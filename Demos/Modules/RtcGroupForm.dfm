object GroupForm: TGroupForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1043#1088#1091#1087#1087#1072' '#1091#1089#1090#1088#1086#1081#1089#1090#1074
  ClientHeight = 77
  ClientWidth = 328
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnKeyDown = FormKeyDown
  OnShow = FormShow
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
    MaxLength = 150
    ParentFont = False
    TabOrder = 0
    OnKeyDown = FormKeyDown
  end
  object bOK: TButton
    Left = 104
    Top = 45
    Width = 107
    Height = 29
    Caption = #1054#1050
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = bOKClick
  end
  object bClose: TButton
    Left = 217
    Top = 45
    Width = 107
    Height = 29
    Caption = #1054#1058#1052#1045#1053#1040
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = bCloseClick
  end
  object rAddGroup: TRtcResult
    OnReturn = rAddGroupReturn
    RequestAborted = rAddGroupRequestAborted
    Left = 142
    Top = 18
  end
  object rChangeGroup: TRtcResult
    OnReturn = rChangeGroupReturn
    RequestAborted = rChangeGroupRequestAborted
    Left = 205
    Top = 8
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 34
    Top = 14
  end
end
