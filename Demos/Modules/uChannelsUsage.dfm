object fChannelsUsage: TfChannelsUsage
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1048#1089#1087#1086#1083#1100#1079#1086#1074#1072#1085#1080#1077' '#1082#1072#1085#1072#1083#1086#1074
  ClientHeight = 330
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object sgChannels: TAdvStringGrid
    Left = 0
    Top = 41
    Width = 500
    Height = 248
    Align = alClient
    ColCount = 6
    DefaultColWidth = 118
    DrawingStyle = gdsClassic
    FixedColor = clWhite
    FixedCols = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect, goFixedRowDefAlign]
    TabOrder = 0
    GridLineColor = 13948116
    GridFixedLineColor = 11250603
    ActiveCellFont.Charset = DEFAULT_CHARSET
    ActiveCellFont.Color = 4474440
    ActiveCellFont.Height = -12
    ActiveCellFont.Name = 'Segoe UI'
    ActiveCellFont.Style = [fsBold]
    ActiveCellColor = 11565130
    ActiveCellColorTo = 11565130
    BorderColor = 11250603
    ControlLook.FixedGradientFrom = clWhite
    ControlLook.FixedGradientTo = clWhite
    ControlLook.FixedGradientHoverTo = clWhite
    ControlLook.FixedGradientHoverMirrorFrom = clWhite
    ControlLook.FixedGradientHoverMirrorTo = clWhite
    ControlLook.FixedGradientHoverBorder = 11645361
    ControlLook.FixedGradientDownFrom = clWhite
    ControlLook.FixedGradientDownTo = clWhite
    ControlLook.FixedGradientDownMirrorFrom = clWhite
    ControlLook.FixedGradientDownMirrorTo = clWhite
    ControlLook.FixedGradientDownBorder = 11250603
    ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownHeader.Font.Color = clWindowText
    ControlLook.DropDownHeader.Font.Height = -11
    ControlLook.DropDownHeader.Font.Name = 'Segoe UI'
    ControlLook.DropDownHeader.Font.Style = []
    ControlLook.DropDownHeader.Visible = True
    ControlLook.DropDownHeader.Buttons = <>
    ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownFooter.Font.Color = clWindowText
    ControlLook.DropDownFooter.Font.Height = -11
    ControlLook.DropDownFooter.Font.Name = 'Segoe UI'
    ControlLook.DropDownFooter.Font.Style = []
    ControlLook.DropDownFooter.Visible = True
    ControlLook.DropDownFooter.Buttons = <>
    Filter = <>
    FilterDropDown.Font.Charset = DEFAULT_CHARSET
    FilterDropDown.Font.Color = clWindowText
    FilterDropDown.Font.Height = -12
    FilterDropDown.Font.Name = 'Segoe UI'
    FilterDropDown.Font.Style = []
    FilterDropDown.TextChecked = 'Checked'
    FilterDropDown.TextUnChecked = 'Unchecked'
    FilterDropDownClear = '(All)'
    FilterEdit.TypeNames.Strings = (
      'Starts with'
      'Ends with'
      'Contains'
      'Not contains'
      'Equal'
      'Not equal'
      'Larger than'
      'Smaller than'
      'Clear')
    FixedColWidth = 118
    FixedRowHeight = 22
    FixedFont.Charset = DEFAULT_CHARSET
    FixedFont.Color = 3881787
    FixedFont.Height = -11
    FixedFont.Name = 'Segoe UI'
    FixedFont.Style = [fsBold]
    FloatFormat = '%.2f'
    HoverButtons.Buttons = <>
    HTMLSettings.ImageFolder = 'images'
    HTMLSettings.ImageBaseName = 'img'
    Look = glCustom
    PrintSettings.DateFormat = 'dd/mm/yyyy'
    PrintSettings.Font.Charset = DEFAULT_CHARSET
    PrintSettings.Font.Color = clWindowText
    PrintSettings.Font.Height = -12
    PrintSettings.Font.Name = 'Segoe UI'
    PrintSettings.Font.Style = []
    PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
    PrintSettings.FixedFont.Color = clWindowText
    PrintSettings.FixedFont.Height = -12
    PrintSettings.FixedFont.Name = 'Segoe UI'
    PrintSettings.FixedFont.Style = []
    PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
    PrintSettings.HeaderFont.Color = clWindowText
    PrintSettings.HeaderFont.Height = -12
    PrintSettings.HeaderFont.Name = 'Segoe UI'
    PrintSettings.HeaderFont.Style = []
    PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
    PrintSettings.FooterFont.Color = clWindowText
    PrintSettings.FooterFont.Height = -12
    PrintSettings.FooterFont.Name = 'Segoe UI'
    PrintSettings.FooterFont.Style = []
    PrintSettings.PageNumSep = '/'
    SearchFooter.ColorTo = clNone
    SearchFooter.FindNextCaption = 'Find &next'
    SearchFooter.FindPrevCaption = 'Find &previous'
    SearchFooter.Font.Charset = DEFAULT_CHARSET
    SearchFooter.Font.Color = clWindowText
    SearchFooter.Font.Height = -12
    SearchFooter.Font.Name = 'Segoe UI'
    SearchFooter.Font.Style = []
    SearchFooter.HighLightCaption = 'Highlight'
    SearchFooter.HintClose = 'Close'
    SearchFooter.HintFindNext = 'Find next occurrence'
    SearchFooter.HintFindPrev = 'Find previous occurrence'
    SearchFooter.HintHighlight = 'Highlight occurrences'
    SearchFooter.MatchCaseCaption = 'Match case'
    SearchFooter.ResultFormat = '(%d of %d)'
    SelectionColor = 13744549
    ShowDesignHelper = False
    SortSettings.HeaderColor = clWhite
    SortSettings.HeaderColorTo = clWhite
    SortSettings.HeaderMirrorColor = clWhite
    SortSettings.HeaderMirrorColorTo = clWhite
    Version = '8.7.2.1'
    ExplicitWidth = 493
    ExplicitHeight = 152
  end
  object pTop: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitLeft = 32
    ExplicitTop = 14
    ExplicitWidth = 185
    object pBtnClose: TPanel
      Left = 10
      Top = 7
      Width = 200
      Height = 28
      BevelOuter = bvNone
      Color = 6381297
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      StyleElements = [seFont, seBorder]
      object bClose: TColorSpeedButton
        Left = 0
        Top = 0
        Width = 200
        Height = 28
        Caption = #1047#1072#1082#1088#1099#1090#1100' '#1089#1086#1077#1076#1080#1085#1077#1085#1080#1077
        Color = 6381297
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = bCloseClick
        OnMouseEnter = bCloseMouseEnter
        OnMouseLeave = bCloseMouseLeave
      end
    end
    object pBtnCloseAll: TPanel
      Left = 290
      Top = 7
      Width = 200
      Height = 28
      BevelOuter = bvNone
      Color = 6381297
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 1
      StyleElements = [seFont, seBorder]
      object bCloseAll: TColorSpeedButton
        Left = 0
        Top = 0
        Width = 200
        Height = 28
        Caption = #1047#1072#1082#1088#1099#1090#1100' '#1074#1089#1077
        Color = 6381297
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = bCloseAllClick
        OnMouseEnter = bCloseMouseEnter
        OnMouseLeave = bCloseMouseLeave
      end
    end
  end
  object pBottom: TPanel
    Left = 0
    Top = 289
    Width = 500
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitLeft = 116
    ExplicitTop = 158
    ExplicitWidth = 185
    object bOK: TButton
      Left = 383
      Top = 6
      Width = 107
      Height = 29
      Caption = 'OK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = bOKClick
    end
  end
  object rResult: TRtcResult
    OnReturn = rResultReturn
    Left = 18
    Top = 47
  end
  object tRefresh: TTimer
    Enabled = False
    OnTimer = tRefreshTimer
    Left = 62
    Top = 47
  end
end
