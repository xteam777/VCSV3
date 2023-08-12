unit rmxConverterUtils;

interface
uses
  RMXConverterBase, rmxBitmapConverter, rmxAVIConverter;

type
  TConverterInfo = record
    name: string;
    cvt_class: TRMXConverterClass;
  end;

const
  Converters: array [0..1] of TConverterInfo = (
    (name: 'bmp'; cvt_class: TRMXBitmapConverter),
    (name: 'avi'; cvt_class: TRMXAVIConverter)

  );
function GetConverterByName(const name: string; out cvt_class: TRMXConverterClass): Boolean;

implementation



function GetConverterByName(const name: string; out cvt_class: TRMXConverterClass): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to Length(Converters)-1 do
    if Converters[i].name = name then
      begin
        Result := true;
        cvt_class := Converters[i].cvt_class;
        break;
      end;
end;


end.
