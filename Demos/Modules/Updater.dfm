object fUpdater: TfUpdater
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1054#1073#1085#1086#1074#1083#1077#1085#1080#1077
  ClientHeight = 62
  ClientWidth = 499
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object LabelGlobalSpeed: TLabel
    Left = 8
    Top = 43
    Width = 481
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'LabelGlobalSpeed'
  end
  object ProgressBarDownload: TProgressBar
    Left = 8
    Top = 6
    Width = 481
    Height = 31
    TabOrder = 0
  end
end
