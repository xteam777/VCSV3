unit ConvertUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  rmxConverterBase, rmxConverterUtils, rmxBitmaper, rmxVideoFile,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, System.TimeSpan;

type
  TRMXVisualProgress = class(TRMXConverterProgress)
  private
    FProgressBar: TProgressBar;
    FProgressLabel: TLabel;
  protected
    procedure UpdateProgress; override;
  public
    constructor Create(Context: Pointer); override;
  end;

  TConvertForm = class(TForm)
    ProgressBar: TProgressBar;
    edSrc: TButtonedEdit;
    edDest: TButtonedEdit;
    lblProgress: TLabel;
    rgpFormat: TRadioGroup;
    edFPS: TEdit;
    btnConvert: TButton;
    lblSource: TLabel;
    lblDest: TLabel;
    lblFPS: TLabel;
    ImageList: TImageList;
    lblInfo: TLabel;
    FileSaveDialog: TFileSaveDialog;
    FileOpenDialog: TFileOpenDialog;
    procedure btnConvertClick(Sender: TObject);
    procedure edDestRightButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FConverter: TRMXConverter;
    procedure Convert;
    procedure AbortConvert;
  public
    { Public declarations }
  end;

//var
//  ConvertForm: TConvertForm;

implementation

{$R *.dfm}

{ TRMXVisualProgress }

constructor TRMXVisualProgress.Create(Context: Pointer);
begin
  inherited;
  if not (TObject(Context) is TConvertForm) then
    raise Exception.Create('Invalid Context');
  FProgressBar   := TConvertForm(Context).ProgressBar;
  FProgressLabel := TConvertForm(Context).lblProgress;
end;

procedure TRMXVisualProgress.UpdateProgress;
begin
  FProgress := Position / Max * 100;

  FProgressBar.Min := Min;
  FProgressBar.Max := Max;
  FProgressBar.Position := Position;
  FProgressLabel.Caption := FormatFloat('0.00%', FProgress );
end;

procedure TConvertForm.AbortConvert;
begin
  if Assigned(FConverter) then
    FConverter.Abort := true;

end;

procedure TConvertForm.btnConvertClick(Sender: TObject);
begin
  if btnConvert.Tag <> 0 then
    begin
      AbortConvert;
      exit;
    end;

  btnConvert.Tag := 1;
  try
    btnConvert.Caption := 'Abort';
    Convert;
  finally
    btnConvert.Tag := 0;
    btnConvert.Caption := 'Covert';
  end;
end;

procedure TConvertForm.Convert;
var
  Bitmaper: TRmxBitmaper;
  header: TRMXHeader;
  converter: TRMXConverter;
  cvt_class: TRMXConverterClass;
  cvt_prms: TParamConverter;
  s: string;
begin
  cvt_class := Converters[rgpFormat.ItemIndex].cvt_class;


  Bitmaper := TRmxBitmaper.Create(edSrc.Text);
  try


      Bitmaper.FPS := StrToIntDef(edFPS.Text, 30);

      header := Bitmaper.Reader.RMXFile.Header;
      s := '';
      s := s + 'Video version      = ' + Header.VersionStr + sLineBreak;
      s := s + 'FrameCount         = ' + Header.NumberOfFrames.ToString + sLineBreak;
      s := s + 'TimeStamp          = ' + FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', Header.TimeStampAsDateTime) + sLineBreak;
      s := s + 'Duration           = ' + TTimeSpan.FromMilliseconds(Header.Duration).ToString + sLineBreak;
      s := s + 'FPS                = ' + Bitmaper.FPS.ToString + sLineBreak;
      s := s + 'MeasuredFrameCount = ' + Bitmaper.MeasuredFrameCount.ToString + sLineBreak;

      lblInfo.Caption := s;
      cvt_prms.output := edDest.Text;

      converter := cvt_class.Create(TRMXVisualProgress, Self);
      try
          FConverter := converter;
          converter.Proccess(Bitmaper, @cvt_prms);
      finally
        FConverter := nil;
        converter.Free;
      end;

      MessageBox(Handle, PChar('Done'), PChar('RMX Convert'), MB_ICONINFORMATION or MB_OK);

  finally
    Bitmaper.Free;
  end;

end;

procedure TConvertForm.edDestRightButtonClick(Sender: TObject);
begin
  if rgpFormat.ItemIndex = 0 then
    begin
      if FileOpenDialog.Execute then
        edDest.Text := FileOpenDialog.FileName
    end
  else
    begin
      if FileSaveDialog.Execute then
        edDest.Text := FileSaveDialog.FileName
    end

end;

procedure TConvertForm.FormCreate(Sender: TObject);
begin
  lblInfo.Caption := '';
end;

end.
