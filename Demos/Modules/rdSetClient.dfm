object rdClientSettings: TrdClientSettings
  Left = 554
  Top = 226
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 279
  ClientWidth = 384
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  PrintScale = poNone
  Scaled = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object tcSettings: TPageControl
    Left = 0
    Top = 2
    Width = 385
    Height = 237
    ActivePage = tsNetwork
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    MultiLine = True
    ParentFont = False
    TabOrder = 0
    object tsNetwork: TTabSheet
      Caption = #1054#1089#1085#1086#1074#1085#1086#1077
      object gProxy: TGroupBox
        Left = 3
        Top = 26
        Width = 371
        Height = 177
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1087#1088#1086#1082#1089#1080
        TabOrder = 0
        object Label1: TLabel
          Left = 10
          Top = 94
          Width = 38
          Height = 16
          Alignment = taRightJustify
          Caption = #1040#1076#1088#1077#1089
        end
        object Label4: TLabel
          Left = 10
          Top = 120
          Width = 110
          Height = 16
          Alignment = taRightJustify
          Caption = #1048#1084#1103' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103
        end
        object Label5: TLabel
          Left = 9
          Top = 147
          Width = 44
          Height = 16
          Alignment = taRightJustify
          Caption = #1055#1072#1088#1086#1083#1100
        end
        object Label2: TLabel
          Left = 253
          Top = 94
          Width = 28
          Height = 16
          Alignment = taRightJustify
          Caption = #1055#1086#1088#1090
        end
        object eProxyAddr: TEdit
          Left = 126
          Top = 90
          Width = 119
          Height = 24
          Hint = #1042#1074#1077#1076#1080#1090#1077' '#1072#1076#1088#1077#1089' '#1087#1088#1086#1082#1089#1080', '#1074#1082#1083#1102#1095#1072#1103' http:// or https://'
          Color = clMenu
          TabOrder = 3
          OnKeyDown = cbAutoRunKeyDown
        end
        object eProxyUsername: TEdit
          Left = 126
          Top = 117
          Width = 233
          Height = 24
          Hint = 'Enter Username needed to log in to the Proxy'
          Color = clMenu
          TabOrder = 5
          OnKeyDown = cbAutoRunKeyDown
        end
        object eProxyPassword: TEdit
          Left = 126
          Top = 144
          Width = 233
          Height = 24
          Hint = 'Enter Password needed to log in to the Proxy'
          Color = clMenu
          PasswordChar = '*'
          TabOrder = 6
          OnKeyDown = cbAutoRunKeyDown
        end
        object rbNoProxy: TRadioButton
          Left = 10
          Top = 42
          Width = 241
          Height = 17
          Caption = #1055#1088#1103#1084#1086#1077' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnClick = rbNoProxyClick
          OnKeyDown = cbAutoRunKeyDown
        end
        object rbAutomatic: TRadioButton
          Left = 10
          Top = 23
          Width = 243
          Height = 17
          Caption = #1040#1074#1090#1086#1084#1072#1090#1080#1095#1077#1089#1082#1086#1077' '#1086#1087#1088#1077#1076#1077#1083#1077#1085#1080#1077
          TabOrder = 2
          OnClick = rbAutomaticClick
          OnKeyDown = cbAutoRunKeyDown
        end
        object rbManual: TRadioButton
          Left = 10
          Top = 61
          Width = 241
          Height = 17
          Caption = #1048#1089#1087#1086#1083#1100#1079#1086#1074#1072#1090#1100' '#1089#1083#1077#1076#1091#1102#1097#1080#1077' '#1085#1072#1089#1090#1088#1086#1081#1082#1080
          TabOrder = 1
          OnClick = rbManualClick
          OnKeyDown = cbAutoRunKeyDown
        end
        object eProxyPort: TEdit
          Left = 292
          Top = 90
          Width = 67
          Height = 24
          Color = clMenu
          TabOrder = 4
          OnKeyDown = cbAutoRunKeyDown
        end
      end
      object cbAutoRun: TCheckBox
        Left = 10
        Top = 3
        Width = 357
        Height = 17
        Caption = #1047#1072#1087#1091#1089#1082#1072#1090#1100' '#1087#1088#1080' '#1089#1090#1072#1088#1090#1077' Windows'
        TabOrder = 1
        OnKeyDown = cbAutoRunKeyDown
      end
    end
    object tsSequrity: TTabSheet
      Caption = #1041#1077#1079#1086#1087#1072#1089#1085#1086#1089#1090#1100
      ImageIndex = 1
      object cbOnlyAdminChanges: TCheckBox
        Left = 7
        Top = 147
        Width = 365
        Height = 17
        Caption = #1056#1072#1079#1088#1077#1096#1080#1090#1100' '#1080#1079#1084#1077#1085#1077#1085#1080#1077' '#1085#1072#1089#1090#1088#1086#1077#1082' '#1090#1086#1083#1100#1082#1086' '#1072#1076#1084#1080#1085#1080#1089#1090#1088#1072#1090#1086#1088#1072#1084
        TabOrder = 3
        Visible = False
        OnKeyDown = cbAutoRunKeyDown
      end
      object cbStoreHistory: TCheckBox
        Left = 7
        Top = 101
        Width = 365
        Height = 17
        Caption = #1057#1086#1093#1088#1072#1085#1103#1090#1100' '#1080#1089#1090#1086#1088#1080#1102' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1081
        TabOrder = 0
        OnClick = cbStoreHistoryClick
        OnKeyDown = cbAutoRunKeyDown
      end
      object cbStorePasswords: TCheckBox
        Left = 7
        Top = 124
        Width = 365
        Height = 17
        Caption = #1057#1086#1093#1088#1072#1085#1103#1090#1100' '#1074#1074#1077#1076#1077#1085#1085#1099#1077' '#1087#1072#1088#1086#1083#1080
        TabOrder = 2
        OnKeyDown = cbAutoRunKeyDown
      end
      object GroupBox1: TGroupBox
        Left = 3
        Top = 2
        Width = 371
        Height = 93
        Caption = #1055#1086#1089#1090#1086#1103#1085#1085#1099#1081' '#1087#1072#1088#1086#1083#1100
        TabOrder = 1
        object Label7: TLabel
          Left = 7
          Top = 56
          Width = 151
          Height = 16
          AutoSize = False
          Caption = #1055#1086#1076#1090#1074#1077#1088#1078#1076#1077#1085#1080#1077' '#1087#1072#1088#1086#1083#1103':'
          Transparent = True
        end
        object Label6: TLabel
          Left = 7
          Top = 26
          Width = 151
          Height = 16
          AutoSize = False
          Caption = #1055#1072#1088#1086#1083#1100':'
          Transparent = True
        end
        object ePassword: TEdit
          Left = 169
          Top = 23
          Width = 192
          Height = 24
          PasswordChar = '*'
          TabOrder = 0
          OnKeyDown = cbAutoRunKeyDown
        end
        object ePasswordConfirm: TEdit
          Left = 169
          Top = 53
          Width = 192
          Height = 24
          PasswordChar = '*'
          TabOrder = 1
          OnKeyDown = cbAutoRunKeyDown
        end
      end
    end
  end
  object pBtnOK: TPanel
    Left = 152
    Top = 245
    Width = 107
    Height = 29
    BevelKind = bkFlat
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object bOK: TSpeedButton
      Tag = 1
      Left = 0
      Top = 0
      Width = 103
      Height = 25
      Caption = #1054#1050
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = cl3DDkShadow
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnOKClick
    end
  end
  object pBtnClose: TPanel
    Left = 269
    Top = 245
    Width = 107
    Height = 29
    BevelKind = bkFlat
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object bClose: TSpeedButton
      Tag = 1
      Left = 0
      Top = 0
      Width = 103
      Height = 25
      Caption = #1054#1058#1052#1045#1053#1040
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = cl3DDkShadow
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnCancelClick
    end
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 42
    Top = 230
  end
end