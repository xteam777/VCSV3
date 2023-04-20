object rdClientSettings: TrdClientSettings
  Left = 554
  Top = 226
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 258
  ClientWidth = 439
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poScreenCenter
  PrintScale = poNone
  Scaled = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 14
  object tcSettings: TPageControl
    Left = 0
    Top = 2
    Width = 431
    Height = 217
    ActivePage = tsSequrity
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    MultiLine = True
    ParentFont = False
    TabOrder = 0
    object tsNetwork: TTabSheet
      Caption = #1057#1077#1090#1100
      object gProxy: TGroupBox
        Left = 3
        Top = 0
        Width = 418
        Height = 177
        Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1087#1088#1086#1082#1089#1080
        TabOrder = 0
        object Label1: TLabel
          Left = 10
          Top = 92
          Width = 38
          Height = 16
          Caption = #1040#1076#1088#1077#1089
        end
        object Label4: TLabel
          Left = 10
          Top = 118
          Width = 110
          Height = 16
          Caption = #1048#1084#1103' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103
        end
        object Label5: TLabel
          Left = 9
          Top = 145
          Width = 44
          Height = 16
          Caption = #1055#1072#1088#1086#1083#1100
        end
        object Label2: TLabel
          Left = 292
          Top = 93
          Width = 28
          Height = 16
          Alignment = taRightJustify
          Caption = #1055#1086#1088#1090
        end
        object eProxyAddr: TEdit
          Left = 126
          Top = 88
          Width = 157
          Height = 24
          Hint = #1042#1074#1077#1076#1080#1090#1077' '#1072#1076#1088#1077#1089' '#1087#1088#1086#1082#1089#1080', '#1074#1082#1083#1102#1095#1072#1103' http:// or https://'
          Color = clMenu
          TabOrder = 3
          OnChange = eProxyAddrChange
          OnKeyDown = cbAutoRunKeyDown
        end
        object eProxyUsername: TEdit
          Left = 126
          Top = 115
          Width = 283
          Height = 24
          Hint = 'Enter Username needed to log in to the Proxy'
          Color = clMenu
          TabOrder = 5
          OnChange = eProxyUsernameChange
          OnKeyDown = cbAutoRunKeyDown
        end
        object eProxyPassword: TEdit
          Left = 126
          Top = 142
          Width = 283
          Height = 24
          Hint = 'Enter Password needed to log in to the Proxy'
          Color = clMenu
          PasswordChar = '*'
          TabOrder = 6
          OnChange = eProxyPasswordChange
          OnKeyDown = cbAutoRunKeyDown
        end
        object rbNoProxy: TRadioButton
          Left = 10
          Top = 42
          Width = 399
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
          Width = 399
          Height = 17
          Caption = #1040#1074#1090#1086#1084#1072#1090#1080#1095#1077#1089#1082#1086#1077' '#1086#1087#1088#1077#1076#1077#1083#1077#1085#1080#1077
          TabOrder = 2
          OnClick = rbAutomaticClick
          OnKeyDown = cbAutoRunKeyDown
        end
        object rbManual: TRadioButton
          Left = 10
          Top = 61
          Width = 399
          Height = 17
          Caption = #1048#1089#1087#1086#1083#1100#1079#1086#1074#1072#1090#1100' '#1089#1083#1077#1076#1091#1102#1097#1080#1077' '#1085#1072#1089#1090#1088#1086#1081#1082#1080
          TabOrder = 1
          OnClick = rbManualClick
          OnKeyDown = cbAutoRunKeyDown
        end
        object eProxyPort: TEdit
          Left = 326
          Top = 88
          Width = 83
          Height = 24
          Color = clMenu
          TabOrder = 4
          OnChange = eProxyAddrChange
          OnKeyDown = cbAutoRunKeyDown
        end
      end
    end
    object tsSequrity: TTabSheet
      Caption = #1041#1077#1079#1086#1087#1072#1089#1085#1086#1089#1090#1100
      ImageIndex = 1
      object cbOnlyAdminChanges: TCheckBox
        Left = 3
        Top = 167
        Width = 410
        Height = 17
        Caption = #1056#1072#1079#1088#1077#1096#1080#1090#1100' '#1080#1079#1084#1077#1085#1077#1085#1080#1077' '#1085#1072#1089#1090#1088#1086#1077#1082' '#1090#1086#1083#1100#1082#1086' '#1072#1076#1084#1080#1085#1080#1089#1090#1088#1072#1090#1086#1088#1072#1084
        TabOrder = 3
        Visible = False
        OnKeyDown = cbAutoRunKeyDown
      end
      object cbStoreHistory: TCheckBox
        Left = 3
        Top = 121
        Width = 410
        Height = 17
        Caption = #1057#1086#1093#1088#1072#1085#1103#1090#1100' '#1080#1089#1090#1086#1088#1080#1102' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1081
        TabOrder = 0
        OnClick = cbStoreHistoryClick
        OnKeyDown = cbAutoRunKeyDown
      end
      object cbStorePasswords: TCheckBox
        Left = 3
        Top = 144
        Width = 410
        Height = 17
        Caption = #1057#1086#1093#1088#1072#1085#1103#1090#1100' '#1074#1074#1077#1076#1077#1085#1085#1099#1077' '#1087#1072#1088#1086#1083#1080
        TabOrder = 2
        OnKeyDown = cbAutoRunKeyDown
      end
      object GroupBox1: TGroupBox
        Left = 3
        Top = 0
        Width = 410
        Height = 115
        Caption = #1053#1077#1082#1086#1085#1090#1088#1086#1083#1080#1088#1091#1077#1084#1099#1081' '#1076#1086#1089#1090#1091#1087
        TabOrder = 1
        object Label7: TLabel
          Left = 11
          Top = 82
          Width = 151
          Height = 16
          AutoSize = False
          Caption = #1055#1086#1076#1090#1074#1077#1088#1078#1076#1077#1085#1080#1077' '#1087#1072#1088#1086#1083#1103':'
          Transparent = True
        end
        object Label6: TLabel
          Left = 11
          Top = 52
          Width = 151
          Height = 16
          AutoSize = False
          Caption = #1055#1072#1088#1086#1083#1100':'
          Transparent = True
        end
        object Label8: TLabel
          Left = 11
          Top = 22
          Width = 390
          Height = 17
          Alignment = taCenter
          AutoSize = False
          Caption = #1045#1089#1083#1080' '#1085#1077' '#1093#1086#1090#1080#1090#1077' '#1088#1072#1079#1088#1077#1096#1072#1090#1100' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077', '#1086#1089#1090#1072#1074#1100#1090#1077' '#1087#1086#1083#1103' '#1087#1091#1089#1090#1099#1084#1080
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          Transparent = True
          WordWrap = True
        end
        object ePassword: TEdit
          Left = 173
          Top = 49
          Width = 228
          Height = 24
          PasswordChar = '*'
          TabOrder = 0
          OnKeyDown = cbAutoRunKeyDown
        end
        object ePasswordConfirm: TEdit
          Left = 173
          Top = 79
          Width = 228
          Height = 24
          PasswordChar = '*'
          TabOrder = 1
          OnKeyDown = cbAutoRunKeyDown
        end
      end
    end
  end
  object bOK: TButton
    Left = 211
    Top = 225
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
    OnClick = btnOKClick
  end
  object bClose: TButton
    Left = 324
    Top = 225
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
    OnClick = btnCancelClick
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 44
    Top = 200
  end
end
