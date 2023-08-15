object fAcceptEULA: TfAcceptEULA
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = #1059#1089#1090#1072#1085#1086#1074#1082#1072
  ClientHeight = 279
  ClientWidth = 436
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 16
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 436
    Height = 279
    Align = alClient
    BevelOuter = bvNone
    Color = 16645629
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    ShowCaption = False
    TabOrder = 0
    StyleElements = [seFont, seBorder]
    ExplicitWidth = 440
    ExplicitHeight = 249
    object Label6: TLabel
      Left = 6
      Top = 8
      Width = 401
      Height = 16
      Alignment = taCenter
      AutoSize = False
      Caption = 'Remox '#1073#1091#1076#1077#1090' '#1091#1089#1090#1072#1085#1086#1074#1083#1077#1085' '#1074' '#1089#1080#1089#1090#1077#1084#1091
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object lEULA: TLabel
      Left = 8
      Top = 184
      Width = 425
      Height = 16
      Alignment = taCenter
      AutoSize = False
      Caption = #1051#1080#1094#1077#1085#1079#1080#1086#1085#1085#1086#1077' '#1089#1086#1075#1083#1072#1096#1077#1085#1080#1077' '#1082#1086#1085#1077#1095#1085#1086#1075#1086' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10720035
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsUnderline]
      ParentColor = False
      ParentFont = False
      Transparent = True
      StyleElements = [seClient, seBorder]
      OnClick = lEULAClick
      OnMouseEnter = lEULAMouseEnter
      OnMouseLeave = lEULAMouseLeave
    end
    object Label5: TLabel
      Left = 8
      Top = 206
      Width = 425
      Height = 33
      Alignment = taCenter
      AutoSize = False
      Caption = 
        #1055#1088#1080#1089#1090#1091#1087#1072#1103' '#1082' '#1087#1088#1086#1094#1077#1089#1089#1091' '#1091#1089#1090#1072#1085#1086#1074#1082#1080', '#1042#1099' '#1089#1086#1075#1083#1072#1096#1072#1077#1090#1077#1089#1100' '#1089' '#1083#1080#1094#1077#1085#1079#1080#1086#1085#1085#1099#1084' '#1089 +
        #1086#1075#1083#1072#1096#1077#1085#1080#1077#1084
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
      WordWrap = True
    end
    object bOK: TButton
      Left = 213
      Top = 245
      Width = 107
      Height = 29
      Caption = #1054#1050
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = bOKClick
    end
    object bClose: TButton
      Left = 326
      Top = 245
      Width = 107
      Height = 29
      Caption = #1054#1058#1052#1045#1053#1040
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ModalResult = 2
      ParentFont = False
      TabOrder = 3
      OnClick = bCloseClick
    end
    object GroupBox1: TGroupBox
      Left = 8
      Top = 34
      Width = 425
      Height = 111
      Caption = #1042#1074#1077#1076#1080#1090#1077' '#1087#1072#1088#1086#1083#1100' '#1076#1083#1103' '#1091#1076#1072#1083#1077#1085#1085#1086#1075#1086' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1103' '#1082' '#1101#1090#1086#1084#1091' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1091
      TabOrder = 0
      object Label8: TLabel
        Left = 0
        Top = 22
        Width = 413
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
      object Label3: TLabel
        Left = 9
        Top = 48
        Width = 151
        Height = 16
        AutoSize = False
        Caption = #1055#1072#1088#1086#1083#1100':'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object Label7: TLabel
        Left = 9
        Top = 83
        Width = 151
        Height = 16
        AutoSize = False
        Caption = #1055#1086#1076#1090#1074#1077#1088#1078#1076#1077#1085#1080#1077' '#1087#1072#1088#1086#1083#1103':'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object ePasswordConfirm: TEdit
        Left = 171
        Top = 78
        Width = 246
        Height = 24
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        PasswordChar = '*'
        TabOrder = 1
      end
      object ePassword: TEdit
        Left = 171
        Top = 45
        Width = 246
        Height = 24
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        PasswordChar = '*'
        TabOrder = 0
      end
    end
    object cbAutoUpdate: TCheckBox
      Left = 8
      Top = 156
      Width = 425
      Height = 17
      Caption = #1040#1074#1090#1086#1084#1072#1090#1080#1095#1077#1089#1082#1086#1077' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1077' '#1087#1088#1080' '#1085#1072#1083#1080#1095#1080#1080' '#1085#1086#1074#1086#1081' '#1074#1077#1088#1089#1080#1080
      TabOrder = 1
    end
  end
end
