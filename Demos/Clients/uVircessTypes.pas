unit uVircessTypes;

interface

type
    PDeviceData = ^TDeviceData;
    TDeviceData = record
      UID: String;
      GroupUID: String;
      ID: Integer;
      Name: WideString;
      Password: WideString;
      Description: WideString;
      HighLight: Boolean;
      StateIndex: Integer;
    end;

  PDeviceGroup = ^TDeviceGroup;
  TDeviceGroup = class(TObject)
    UID: String;
    Name: WideString;
  end;

implementation

end.
