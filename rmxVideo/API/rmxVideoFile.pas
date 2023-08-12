unit rmxVideoFile;

interface
uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  rmxVideoPacketTypes,
  rtcZLib, System.ZLib, Compressions, System.DateUtils;


const
  CAPACITY_GRANUALITY = 1024 * 1024 * 500; // 500 MB


type
  TRMXVideoFile = class;
  TRMXSectionList = class;
  TRMXSectionData = class;

  TRegionInfo = record
    region: Pointer;
    offset: Int64;
    availabel_size: Cardinal;
  end;


  TRMXHeader = class
  private
    FHeader: PRMXHeaderFile;
    FRMXFile: TRMXVideoFile;
    FSectionList: TRMXSectionList;
    FCompressionClass: TCompressionClass;
    FCompression: TCompressionCustom;
    function GetMagic: Cardinal;
    function GetNumberOfFrames: Cardinal;
    function GetNumberOfSections: Cardinal;
    function GetSizeOfImage: Int64;
    function GetVersion: TRMXFileVersion;
    function GetVersionStr: string;
    procedure SetVersion(const Value: TRMXFileVersion);
    function GetDuration: Int64;
    function GetTimeStamp: Int64;
    procedure SetTimeStamp(const Value: Int64);
    function GetTimeStampAsDateTime: TDateTime;
    procedure SetTimeStampAsDateTime(const Value: TDateTime);
  public
    Origin: PRMXHeaderFile;

    constructor Create(RMXFile: TRMXVideoFile);
    destructor Destroy; override;
    procedure InitializeNew;
    function GetSectionList: TRMXSectionList;
    procedure SetCompressionClass(cls: TCompressionClass);
    function GetCompression: TCompressionCustom;

    property Version: TRMXFileVersion read GetVersion write SetVersion;
    property VersionStr: string read GetVersionStr;
    property Magic: Cardinal read GetMagic;
    property SizeOfImage: Int64 read GetSizeOfImage;
    property TimeStamp: Int64 read GetTimeStamp write SetTimeStamp;
    property TimeStampAsDateTime: TDateTime read GetTimeStampAsDateTime write SetTimeStampAsDateTime;
    property Duration: Int64 read GetDuration;
    property NumberOfSections: Cardinal read GetNumberOfSections;
    property NumberOfFrames: Cardinal read GetNumberOfFrames;


  end;

  TRMXSection = class

  end;




  TRMXPacketData = class
  private
    FPacket: TRMXDataPacket;
    FSection: TRMXSectionData;
    FPosition: Cardinal;
    FData: TBytes;
    FCompression: TCompressionCustom;
  protected

    procedure LoadCompressed(pkt: PRMXDataPacket);
    function SaveCompressed(out pkt: PRMXDataPacket): Cardinal;
  public
    constructor Create(Section: TRMXSectionData);
    destructor Destroy; override;
    procedure InitializeNew;
    procedure WriteData(const Buffer; Size: Cardinal);
    function ReadData(var Buffer; Size: Cardinal): Integer;
    function Seek(Offset: Cardinal; Origin: Integer): Integer;
    property CompressedSize: Cardinal read FPacket.CompressedSize;
    property DataSize: Cardinal read FPacket.DataSize;
    property TimeStampEllapsed: Int64 read FPacket.TimeStampEllapsed write FPacket.TimeStampEllapsed;
    property Index: Cardinal read FPacket.Index;
    property CheckSum: Cardinal read FPacket.CheckSum;
    property TypeOfData: TTypeDataPacket read FPacket.TypeOfData write FPacket.TypeOfData;
    property Data: TBytes read FData;
  end;

  TSectionState = (ssFree, ssWriting, ssClosed);
  TRMXSectionData = class (TRMXSection)
  private
    FSection: PRMXDataSection;
    FRMXFile: TRMXVideoFile;
    FHeader: TRMXHeader;

    FState: TSectionState;
    FMaxAvailaiblePackets: Cardinal;

    //=========
    FBase: Pointer;
    FOffset: Cardinal;
    FFrameSize: Cardinal; // current frame size
    FPosition: Cardinal;      // current index
    function ReallocFrame(Ptr: Pointer; var FrameOffset: Cardinal; FrameSize: Cardinal): Pointer;
  public
    Origin: PRMXImageSection;

    constructor Create(RMXFile: TRMXVideoFile; Ptr: PRMXDataSection);
    destructor Destroy; override;
    procedure InitializeNew;
    procedure StartOf;
    procedure EndOf;
    function CanExpandSize(size: Cardinal): Boolean;

    function AddPacket(Packet: TRMXPacketData): Boolean;
    procedure LoadPacket(Index: Cardinal; Packet: TRMXPacketData);
    function GetPacket(Index: Integer): TRMXPacketData;
    function GetPacketDirect: PRMXDataPacket;
    procedure First;
    function Next: Boolean;
    function EOF: Boolean;
    function PacketCount: Cardinal;

//    property Cursor: TRMXPacketData read FPacket;
//    property CursorRaw: PRMXDataPacket read GetCursorRaw;
    property Position: Cardinal read FPosition;
    property State: TSectionState read FState;
    property MaxAvailaiblePackets: Cardinal read FMaxAvailaiblePackets;
  end;

  TRMXSectionClass = class of TRMXSection;

  TRMXSectionList = class
  private
    FSections: array of TRMXSectionData;
    FCurrentSection: TRMXSectionData;
    FRMXFile: TRMXVideoFile;
    FHeader: TRMXHeader;
    FDir: PRMXSectionDirectory;
    procedure LoadSection(Index: Integer);
    function GetSection(Index: Integer): TRMXSectionData; overload;
    procedure GrowSectionList;
  public

    constructor Create(RMXFile: TRMXVideoFile; Header: TRMXHeader);
    destructor Destroy; override;
    procedure Clear;
    function CreateSection(TypeOfSection: TTypeImageSection): TRMXSectionData;
    procedure EndSection(Section: TRMXSectionData);
    procedure StartSection(Section: TRMXSectionData);
    function GetSection<T: TRMXSection>(Index: Integer): T; overload;
    function Count: Integer;
    property Sections[Index: Integer]: TRMXSectionData read GetSection; default;

    //procedure AddSection(Section: TRMXSection);
  end;

  TRMXVideoFile = class
  private
    FHeader: TRMXHeader;
    FDataAlignment: Cardinal;

    FFileName: string;
    FCapacity, FSize: Int64;
    FSysInfo: TSystemInfo;
    FReadOnly: Boolean;
    procedure UnmapPtrs;
    procedure CheckSize; inline;
    procedure CheckGrow(NewSize: Int64);
    function CalcAlignment(dwAlignment: Cardinal; qwSize: Int64): Int64; overload;
    function CalcAlignment(dwAlignment: Cardinal; dwSize: Cardinal): Cardinal; overload;
    function GetSize: Int64;
    function GetSectionList: TRMXSectionList;
    function GetHeader: TRMXHeader;
  protected
    procedure Grow(OldCapacity: Int64; var NewCapacity: Int64); virtual;
    function Remap(Ptr: Pointer; Offset, Size: Int64): Pointer; virtual;
    function Map(Ptr: Pointer; Offset, Size: Int64): Pointer; virtual;
    procedure Unmap(Ptr: Pointer); virtual;
    procedure InitializeFile; virtual;
    procedure FinalizeFile; virtual;
    procedure UpdateSysInfo(var ASysInfo: TSystemInfo); virtual;

    function WriteFile(const Data; Offset: Int64; Size: Cardinal): Cardinal; virtual;
    function ReadFile(var Data; Offset: Int64; Size: Cardinal): Cardinal; virtual;
  public
    constructor Create(const AFileName: string; ReadOnly: Boolean); virtual;
    destructor Destroy; override;
    function CreateHeader(): TRMXHeader;
    procedure UpdateCheckSumOfData;
    procedure UpdateCheckSumOfImage;
    procedure VerifyCheckSumOfData;
    procedure VerifyCheckSumOfImage;




    property Header: TRMXHeader read GetHeader;
    property SectionList: TRMXSectionList read GetSectionList;
    property FileName: string read FFileName ;
    property Capacity: Int64 read FCapacity;
    property Size: Int64 read GetSize;
    property SysInfo: TSystemInfo read FSysInfo;


  end;

  PFileAllocatedRangeBuffer = ^TFileAllocatedRangeBuffer;
  _FILE_ALLOCATED_RANGE_BUFFER  = record
    FileOffset: TLargeInteger;
    Length: TLargeInteger;
  end;
  TFileAllocatedRangeBuffer = _FILE_ALLOCATED_RANGE_BUFFER;
  FILE_ALLOCATED_RANGE_BUFFER = _FILE_ALLOCATED_RANGE_BUFFER;
  {$EXTERNALSYM _FILE_ALLOCATED_RANGE_BUFFER}
  {$EXTERNALSYM FILE_ALLOCATED_RANGE_BUFFER}



  _FILE_ZERO_DATA_INFORMATION = record
    FileOffset: TLargeInteger;
    BeyondFinalZero: TLargeInteger;
  end;
  TFileZeroDataInformation = _FILE_ZERO_DATA_INFORMATION;
  FILE_ZERO_DATA_INFORMATION = _FILE_ZERO_DATA_INFORMATION;
  {$EXTERNALSYM _FILE_ZERO_DATA_INFORMATION}
  {$EXTERNALSYM FILE_ZERO_DATA_INFORMATION}


  _FILE_BASIC_INFO  = record
    CreationTime: TLargeInteger;
    LastAccessTime: TLargeInteger;
    LastWriteTime: TLargeInteger;
    ChangeTime: TLargeInteger;
    FileAttributes: DWORD;
  end;
  TFileBasicInfo = _FILE_BASIC_INFO;
  FILE_BASIC_INFO = _FILE_BASIC_INFO;
  {$EXTERNALSYM _FILE_BASIC_INFO}
  {$EXTERNALSYM FILE_BASIC_INFO}


  TRMXVideoFileWin = class(TRMXVideoFile)
  private
    FFileHandle: THandle;
    FFileMap: THandle;
    FIsSparse: Boolean;
    FSparseCapacity: Int64;
    FHandle: THandle;
    function DoesFileSystemSupportSparseStreams(const Volume: string): Boolean;
    function IsStreamSparse(Stream: THandle): Boolean;
    function MakeSparse(Stream: THandle): Boolean;
    function DecommitPortionOfStream(qwOffsetStart, qwOffsetEnd: Int64): Boolean;
    function DoesFileContainAnySparseStreams(const FilePath: string): Boolean;
    function QueryAllocatedRanges(var pdwNumEntries: Cardinal): PFileAllocatedRangeBuffer;
    function FreeAllocatedRanges(buffer: PFileAllocatedRangeBuffer): Boolean;
    function CheckAttrSet(dwFlagBits, FlagsToCheck: Cardinal): Boolean; inline;
    function SetFileAttr(exclude_attr, include_attr: Cardinal): Boolean;
    function WinCheckError(RetVal: BOOL): BOOL;

  //protected
  public
    procedure Grow(OldCapacity: Int64; var NewCapacity: Int64); override;
    function Remap(Ptr: Pointer; Offset, Size: Int64): Pointer; override;
    function Map(Ptr: Pointer; Offset, Size: Int64): Pointer; override;
    procedure Unmap(Ptr: Pointer); override;
    procedure InitializeFile; override;
    procedure FinalizeFile; override;
    procedure UpdateSysInfo(var ASysInfo: TSystemInfo); override;

    function WriteFile(const Data; Offset: Int64; Size: Cardinal): Cardinal; override;
    function ReadFile(var Data; Offset: Int64; Size: Cardinal): Cardinal; override;
  public
    constructor Create(const AFileName: string; ReadOnly: Boolean); overload; override;
    constructor Create(const AFileName: string; ReadOnly, Sparse: Boolean); overload;
    property Handle: THandle read FFileHandle;
  end;

  TRMXVideoFileClass = class of TRMXVideoFile;

  TCompressDecompressFunc =  procedure (const inBuffer: Pointer; inSize: Integer;
    out outBuffer: Pointer; out outSize: Integer);


function DateTimeToUnixMSec(const AValue: TDateTime; AInputIsUTC: Boolean): Int64;
function UnixMSecToDateTime(const AValue: Int64; AReturnUTC: Boolean): TDateTime;

var
  Compress: TCompressDecompressFunc;
  Decompress: TCompressDecompressFunc;
implementation
const
  DEF_FRAME_SIZE = 1024 * 1024 * 10;    // 10 MB

type
  {$Z+}
  // min enum size = double word
  TFileInfoByHandleClass = (FileBasicInfo = 0);
  {$Z-}

function SetFileInformationByHandle(
  hFile: THandle;
  FileInformationClass: TFileInfoByHandleClass;
  lpFileInformation: Pointer;
  dwBufferSize: DWORD
): Bool; stdcall; external 'kernel32.dll';


// unix time in msec

function DateTimeToUnixMSec(const AValue: TDateTime; AInputIsUTC: Boolean): Int64;
var
  LDate: TDateTime;
 begin
  if AInputIsUTC then
    LDate := AValue
  else
    LDate := TTimeZone.Local.ToUniversalTime(AValue);
  Result := MilliSecondsBetween(UnixDateDelta, LDate);
  if LDate < UnixDateDelta then
     Result := -Result;
 end;

function UnixMSecToDateTime(const AValue: Int64; AReturnUTC: Boolean): TDateTime;
begin
  if AReturnUTC then
    Result := IncMilliSecond(UnixDateDelta, AValue)
  else
    Result := TTimeZone.Local.ToLocalTime(IncMilliSecond(UnixDateDelta, AValue));
end;

{ TRMXVideoFile }

function TRMXVideoFile.CalcAlignment(dwAlignment: Cardinal;
  qwSize: Int64): Int64;
begin
  if qwSize mod dwAlignment <> 0 then
    Result := (qwSize + dwAlignment) and not (dwAlignment-1) else
    Result := qwSize;
end;

function TRMXVideoFile.CalcAlignment(dwAlignment, dwSize: Cardinal): Cardinal;
begin
  if dwSize mod dwAlignment <> 0 then
    Result := (dwSize + dwAlignment) and not (dwAlignment-1) else
    Result := dwSize;
end;


procedure TRMXVideoFile.CheckGrow(NewSize: Int64);
begin
  if FCapacity < NewSize then
    begin
      Grow(FCapacity, NewSize);
      FCapacity := NewSize;
    end;
end;

procedure TRMXVideoFile.CheckSize;
begin


end;

constructor TRMXVideoFile.Create(const AFileName: string; ReadOnly: Boolean);
begin
  inherited Create;
  FReadOnly := ReadOnly;
  UpdateSysInfo(FSysInfo);
  FCapacity := 0;//CAPACITY_GRANUALITY;
  FFileName := AFileName;
  InitializeFile;
end;

function TRMXVideoFile.CreateHeader(): TRMXHeader;
begin
  if FHeader = nil then
    FHeader := TRMXHeader.Create(Self);
  FHeader.InitializeNew;
  Result := FHeader;

end;


destructor TRMXVideoFile.Destroy;
begin
  if Assigned(FHeader) and not FReadOnly then
    FSize := FHeader.Origin.SizeOfImage;
  FHeader.Free;
  FinalizeFile;
  inherited;
end;

procedure TRMXVideoFile.FinalizeFile;
begin

end;

function TRMXVideoFile.GetHeader: TRMXHeader;
begin
  if FHeader = nil then
    begin
      FHeader := TRMXHeader.Create(Self);
    end;
  Result := FHeader;
end;

function TRMXVideoFile.GetSectionList: TRMXSectionList;
begin
  Result := Header.GetSectionList;
end;

function TRMXVideoFile.GetSize: Int64;
begin
  Result := FSize;//FHeader.Origin.SizeOfImage;
end;

procedure TRMXVideoFile.Grow(OldCapacity: Int64; var NewCapacity: Int64);
begin
  if OldCapacity < NewCapacity then
    begin
      NewCapacity := CalcAlignment(FSysInfo.dwAllocationGranularity, NewCapacity);
      FCapacity := NewCapacity;
    end;
end;

procedure TRMXVideoFile.InitializeFile;
begin

end;

function TRMXVideoFile.Map(Ptr: Pointer; Offset, Size: Int64): Pointer;
begin
  Result := nil;
  if FSize < Offset + Size then
    FSize := Offset + Size;

  CheckGrow(Offset + Size);

end;


function TRMXVideoFile.ReadFile(var Data; Offset: Int64;
  Size: Cardinal): Cardinal;
begin
  Result := 0;
  if FSize < Offset + Size then
    FSize := Offset + Size;

  CheckGrow(Offset + Size);
end;

function TRMXVideoFile.Remap(Ptr: Pointer; Offset, Size: Int64): Pointer;
begin
  Unmap(Ptr);
  Result := Map(Ptr, Offset, Size);
end;

procedure TRMXVideoFile.Unmap(Ptr: Pointer);
begin

end;

procedure TRMXVideoFile.UnmapPtrs;
begin
end;

procedure TRMXVideoFile.UpdateCheckSumOfData;
begin

end;

procedure TRMXVideoFile.UpdateCheckSumOfImage;
begin

end;

procedure TRMXVideoFile.UpdateSysInfo(var ASysInfo: TSystemInfo);
begin

end;

procedure TRMXVideoFile.VerifyCheckSumOfData;
begin

end;

procedure TRMXVideoFile.VerifyCheckSumOfImage;
begin

end;


function TRMXVideoFile.WriteFile(const Data; Offset: Int64;
  Size: Cardinal): Cardinal;
begin
  Result := 0;
  if FSize < Offset + Size then
    FSize := Offset + Size;

  CheckGrow(Offset + Size);
end;

{ TRMXVideoFileWin }

function TRMXVideoFileWin.CheckAttrSet(dwFlagBits,
  FlagsToCheck: Cardinal): Boolean;
begin
  Result := (dwFlagBits and FlagsToCheck) = FlagsToCheck;
end;

constructor TRMXVideoFileWin.Create(const AFileName: string; ReadOnly, Sparse: Boolean);
begin
  FIsSparse := Sparse;
  Create(AFileName, ReadOnly);
end;

constructor TRMXVideoFileWin.Create(const AFileName: string; ReadOnly: Boolean);
begin
  FFileHandle := INVALID_HANDLE_VALUE;
  inherited;
end;

function TRMXVideoFileWin.DecommitPortionOfStream(qwOffsetStart,
  qwOffsetEnd: Int64): Boolean;
var
  dw: Cardinal;
  fzdi: TFileZeroDataInformation;
begin
   // NOTE: This function does not work if this file is memory-mapped.
   fzdi.FileOffset := qwOffsetStart;
   fzdi.BeyondFinalZero := qwOffsetEnd + 1;
   Result := DeviceIoControl(FFileHandle, FSCTL_SET_ZERO_DATA, @fzdi,  SizeOf(fzdi), nil, 0, dw, nil);
end;

function TRMXVideoFileWin.DoesFileContainAnySparseStreams(
  const FilePath: string): Boolean;
var
  dwAttributes: Cardinal;
begin
   dwAttributes := GetFileAttributes(PChar(FilePath));
   Result := (dwAttributes <> INVALID_FILE_ATTRIBUTES) and
             CheckAttrSet(dwAttributes, FILE_ATTRIBUTE_SPARSE_FILE)
end;

function TRMXVideoFileWin.DoesFileSystemSupportSparseStreams(
  const Volume: string): Boolean;
var
  dwFileSystemFlags: Cardinal;
  dw: Cardinal;
begin
   dwFileSystemFlags := 0;
   dw := 0;
   Result := GetVolumeInformation(PChar(Volume), nil, 0, nil, dw,  dwFileSystemFlags, nil, 0) and
             CheckAttrSet(dwFileSystemFlags, FILE_SUPPORTS_SPARSE_FILES);
end;

procedure TRMXVideoFileWin.FinalizeFile;
var
  sz: Int64;
begin
  inherited;
  if FFileMap <> 0 then
    CloseHandle(FFileMap);
  FFileMap := 0;

  if FFileHandle <> INVALID_HANDLE_VALUE then
    begin
//      if FIsSparse then
        begin
          sz := Size;
          SetFilePointer(FFileHandle, Int64Rec(sz).Lo,   @Int64Rec(sz).Hi, soFromBeginning);
          SetEndOfFile(FFileHandle);
        end;

      SetFileAttr(0, FILE_ATTRIBUTE_READONLY);
      CloseHandle(FFileHandle);

    end;
  FFileHandle := INVALID_HANDLE_VALUE;
end;

function TRMXVideoFileWin.FreeAllocatedRanges(
  buffer: PFileAllocatedRangeBuffer): Boolean;
begin
  FreeMem(buffer);
  Result := true;
end;

procedure TRMXVideoFileWin.Grow(OldCapacity: Int64; var NewCapacity: Int64);
begin
  inherited;

  if FReadOnly and (FFileMap <> 0 ) then exit;

  if FIsSparse then
    begin
      if FSparseCapacity > NewCapacity then exit;
      while FSparseCapacity < NewCapacity do
        FSparseCapacity := FSparseCapacity +  MAXDWORD;   // 4 GB
      NewCapacity := FSparseCapacity;
    end;
  if FFileMap <> 0 then
    CloseHandle(FFileMap);

  if FReadOnly then
    begin
      WinCheckError(GetFileSizeEx(FFileHandle, NewCapacity));
      FFileMap := CreateFileMapping(FFileHandle, nil, PAGE_READONLY, 0, 0, nil);
    end
  else
    FFileMap := CreateFileMapping(FFileHandle, nil, PAGE_READWRITE, Int64Rec(NewCapacity).Hi, Int64Rec(NewCapacity).Lo, nil);
  WinCheckError(FFileMap <> 0);

end;

procedure TRMXVideoFileWin.InitializeFile;
begin
  inherited;
  FinalizeFile;
  if FFileHandle = INVALID_HANDLE_VALUE then
    begin
      if FReadOnly then
          FFileHandle := CreateFile(PChar(FileName), GENERIC_READ,  0, nil,
                              OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0) else
          FFileHandle := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,  0, nil,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0) ;

    end;
  Win32Check(FFileHandle <> INVALID_HANDLE_VALUE);

  try
//    if DoesFileSystemSupportSparseStreams(ExtractFileDrive(ExpandFileName(FileName))+'\') then
//      begin
//        FIsSparse := MakeSparse(FFileHandle);
//        WinCheckError(FIsSparse);
//      end;

  except
    FinalizeFile;
    raise;

  end;

end;

function TRMXVideoFileWin.IsStreamSparse(Stream: THandle): Boolean;
var
  bhfi: TByHandleFileInformation;
begin
   GetFileInformationByHandle(FFileHandle, bhfi);
   Result := CheckAttrSet(bhfi.dwFileAttributes, FILE_ATTRIBUTE_SPARSE_FILE);
end;

function TRMXVideoFileWin.MakeSparse(Stream: THandle): Boolean;
var
  dw: Cardinal;
begin
   Result := DeviceIoControl(FFileHandle, FSCTL_SET_SPARSE, nil, 0, nil, 0, dw, nil);
end;

function TRMXVideoFileWin.Map(Ptr: Pointer; Offset, Size: Int64): Pointer;
begin

  Result := inherited Map(Ptr, Offset, Size);
  if Result <> nil then exit;

  if not FReadOnly then
    begin

      Result := MapViewOfFileEx(FFileMap, FILE_MAP_WRITE, Int64Rec(Offset).Hi,
                  Int64Rec(Offset).Lo, Size, Ptr);
      if (Result = nil) and (GetLastError = ERROR_INVALID_ADDRESS) then
        Result := MapViewOfFileEx(FFileMap, FILE_MAP_WRITE, Int64Rec(Offset).Hi,
                  Int64Rec(Offset).Lo, Size, nil);
    end else
    begin
      Result := MapViewOfFileEx(FFileMap, FILE_MAP_READ, Int64Rec(Offset).Hi,
                  Int64Rec(Offset).Lo, Size, Ptr);
      if (Result = nil) and (GetLastError = ERROR_INVALID_ADDRESS) then
        Result := MapViewOfFileEx(FFileMap, FILE_MAP_READ, Int64Rec(Offset).Hi,
                  Int64Rec(Offset).Lo, Size, nil);
    end;
  WinCheckError(Result <> nil);

end;

function TRMXVideoFileWin.QueryAllocatedRanges(
  var pdwNumEntries: Cardinal): PFileAllocatedRangeBuffer;
var
  farb: TFileAllocatedRangeBuffer;
  cbSize: Cardinal;
begin
   farb.FileOffset := 0;
   Int64Rec(farb.Length).Lo := GetFileSize(FFileHandle, PCardinal(@Int64Rec(farb.Length).Hi));

   // There is no way to determine the correct memory block size prior to
   // attempting to collect this data, so I just picked 100 * sizeof(*pfarb)
   cbSize := 100 * SizeOf(farb);
   Result := AllocMem(cbSize);
   DeviceIoControl(FFileHandle, FSCTL_QUERY_ALLOCATED_RANGES, @farb, sizeof(farb), Result, cbSize, cbSize, nil);
   pdwNumEntries := cbSize div SizeOf(farb);

end;

function TRMXVideoFileWin.ReadFile(var Data; Offset: Int64; Size: Cardinal): Cardinal;
begin
  Result := inherited ReadFile(Data, Offset, Size);
  if Result <> 0 then exit;

  SetFilePointer(FFileHandle, Int64Rec(Offset).Lo, @Int64Rec(Offset).Hi, soFromBeginning);
  WinCheckError(Winapi.Windows.ReadFile(FFileHandle, Data, Size, Result, nil));
end;

function TRMXVideoFileWin.Remap(Ptr: Pointer; Offset, Size: Int64): Pointer;
begin
  Result := Inherited;
end;


function TRMXVideoFileWin.SetFileAttr(exclude_attr,
  include_attr: Cardinal): Boolean;
var
  bhfi: TByHandleFileInformation;
  info: TFileBasicInfo;
begin
   GetFileInformationByHandle(FFileHandle, bhfi);
   FillChar(info, SizeOf(TFileBasicInfo), 0);
   info.FileAttributes := bhfi.dwFileAttributes;
   info.FileAttributes := info.FileAttributes and not exclude_attr;
   info.FileAttributes := info.FileAttributes or include_attr;
   Result := SetFileInformationByHandle(FFileHandle, FileBasicInfo, @info, SizeOf(info));


end;

procedure TRMXVideoFileWin.Unmap(Ptr: Pointer);
begin
  inherited;
  if Ptr <> nil then
    WinCheckError(UnmapViewOfFile(Ptr));
end;

procedure TRMXVideoFileWin.UpdateSysInfo(var ASysInfo: TSystemInfo);
begin
  inherited;
  GetSystemInfo(ASysInfo);
end;

function TRMXVideoFileWin.WinCheckError(RetVal: BOOL): BOOL;
begin
  if not RetVal then RaiseLastOSError;
  Result := RetVal;
end;

function TRMXVideoFileWin.WriteFile(const Data; Offset: Int64; Size: Cardinal): Cardinal;
begin
  Result := inherited WriteFile(Data, Offset, Size);
  if Result <> 0 then exit;

  SetFilePointer(FFileHandle, Int64Rec(Offset).Lo, @Int64Rec(Offset).Hi, soFromBeginning);
  WinCheckError(Winapi.Windows.WriteFile(FFileHandle, Data, Size, Result, nil));

end;

{ THeaderFile }

constructor TRMXHeader.Create(RMXFile: TRMXVideoFile);
begin
  inherited Create;
  FRMXFile := RMXFile;
  FHeader  := FRMXFile.Map(nil, 0, RMXFile.FSysInfo.dwAllocationGranularity);
  Origin   := FHeader;
end;

destructor TRMXHeader.Destroy;
begin
  FreeAndNil(FSectionList);
  FRMXFile.Unmap(FHeader);
  SetCompressionClass(nil);
  inherited;
end;

function TRMXHeader.GetCompression: TCompressionCustom;
begin
  if not Assigned(FCompression) and Assigned(FCompressionClass) then
    FCompression := FCompressionClass.Create(5);
  Result := FCompression;
end;

function TRMXHeader.GetDuration: Int64;
begin
  Result := FHeader.Duration
end;

function TRMXHeader.GetMagic: Cardinal;
begin
  Result := FHeader.Magic
end;

function TRMXHeader.GetNumberOfFrames: Cardinal;
begin
  Result := FHeader.NumberOfFrames
end;

function TRMXHeader.GetNumberOfSections: Cardinal;
begin
  Result := FHeader.NumberOfSections
end;

function TRMXHeader.GetSectionList: TRMXSectionList;
begin
  if not Assigned(FSectionList) then
    FSectionList := TRMXSectionList.Create(FRMXFile, Self);
  Result := FSectionList;

end;

function TRMXHeader.GetSizeOfImage: Int64;
begin
  Result := FHeader.SizeOfImage
end;

function TRMXHeader.GetTimeStamp: Int64;
begin
  Result := FHeader.TimeStamp
end;

function TRMXHeader.GetTimeStampAsDateTime: TDateTime;
begin
  Result := UnixMSecToDateTime(FHeader^.TimeStamp, false)
end;

function TRMXHeader.GetVersion: TRMXFileVersion;
begin
  Result := FHeader.Version
end;

function TRMXHeader.GetVersionStr: string;
begin
  Result :=
              IntToHex(FHeader.Version.MajorVersion and $00FF, 1) + '.' +
              IntToHex(FHeader.Version.MajorVersion and $FF00 shr 8, 1) + '.' +
              IntToHex(FHeader.Version.MinorVersion and $00FF, 1) + '.' +
              IntToHex(FHeader.Version.MinorVersion and $FF00 shr 8, 1);
end;

procedure TRMXHeader.InitializeNew;
begin
  FillChar(FHeader^, SizeOf(FHeader), 0);
  FHeader.SizeOfImage       := FRMXFile.FSysInfo.dwAllocationGranularity;
  Cardinal(FHeader.Version) := RMX_FILE_VERSION;
  FHeader.Magic             := RMX_MAGIC;
  FHeader.DataAlignment     := RMX_DATA_ALIGNMENT;
  FHeader.TimeStamp     := DateTimeToUnixMSec(Now, false)

end;

procedure TRMXHeader.SetCompressionClass(cls: TCompressionClass);
begin
  if Assigned(FCompression) then
    FreeAndNil(FCompression);
  FCompressionClass := cls;
end;

procedure TRMXHeader.SetTimeStamp(const Value: Int64);
begin
  FHeader.TimeStamp := Value
end;

procedure TRMXHeader.SetTimeStampAsDateTime(const Value: TDateTime);
begin
  FHeader^.TimeStamp := DateTimeToUnixMSec(Value, false)
end;

procedure TRMXHeader.SetVersion(const Value: TRMXFileVersion);
begin
  FHeader.Version := Value
end;

{ TRMXSectionList }

procedure TRMXSectionList.Clear;
var
  I: Integer;
begin
  for I := 0 to Length(FSections)-1 do
    begin
      FSections[i].Free;
    end;
  FillChar(FHeader.Origin.SectionDirectory, FHeader.Origin.NumberOfSections * SizeOf(FHeader.Origin.SectionDirectory[0]), 0);
  SetLength(FSections, 0);

  FHeader.Origin.NumberOfSections := 0;
  { TODO -cRAISE : ¬озможно это следует перенести в RMXFile или в Header}
  FHeader.Origin.SizeOfImage := FRMXFile.SysInfo.dwAllocationGranularity;

end;

function TRMXSectionList.Count: Integer;
begin
  Result := Integer(FHeader.Origin.NumberOfSections);
end;

constructor TRMXSectionList.Create(RMXFile: TRMXVideoFile; Header: TRMXHeader);
begin
  inherited Create;
  FRMXFile := RMXFile;
  FHeader := Header;
  FDir := @Header.Origin.SectionDirectory;
end;

function TRMXSectionList.CreateSection(
  TypeOfSection: TTypeImageSection): TRMXSectionData;
var
  I: Integer;
  offset: Int64;
  SizeOfSection: Cardinal;
  ptr: Pointer;
begin
  if Assigned(FCurrentSection) and (FCurrentSection.State <> ssFree) then
    raise Exception.Create('Need to close active section');

  GrowSectionList;

  offset := FRMXFile.CalcAlignment(RMX_REGION_SIZE, FHeader.Origin.SizeOfImage);
  ptr := FRMXFile.Map(nil, offset, RMX_REGION_SIZE);
  case TypeOfSection of
    tisUnknown: ;
    tisData:
      begin
        SizeOfSection := SizeOf(TRMXDataSection);
        Result := TRMXSectionData.Create(FRMXFile, ptr);
      end;
    tisMetaData: ;
    else exit(nil);
  end;
  Result.InitializeNew;
  FHeader.Origin.SizeOfImage := FHeader.Origin.SizeOfImage + Result.Origin.SizeOfSection;

  I := Count;
  FSections[i] := Result;
  FHeader.Origin.NumberOfSections    := FHeader.Origin.NumberOfSections + 1;
  FHeader.Origin.SectionDirectory[I] := offset;
  FSections[I].Origin.Index          := I;
  if I > 0 then
    begin
      FSections[I-1].Origin.RVNext := offset - FHeader.Origin.SectionDirectory[I-1];
      FSections[I].Origin.RVPrior  := -offset;
    end;

  StartSection(Result);


end;

destructor TRMXSectionList.Destroy;
var
  I: Integer;
begin
  for I := 0 to Count-1 do
    begin
      FRMXFile.Unmap(FSections[i].Origin);
      FSections[i].Free;
    end;
  inherited;
end;

procedure TRMXSectionList.EndSection(Section: TRMXSectionData);
begin
  if FCurrentSection = Section then
    begin
      FCurrentSection := nil;
      if Assigned(Section) then
        Section.EndOf;
    end;
end;

function TRMXSectionList.GetSection(Index: Integer): TRMXSectionData;
begin
  if Index >= Count then
    raise Exception.Create('Index of bound');
  LoadSection(Index);
  Result := FSections[Index];
end;

function TRMXSectionList.GetSection<T>(Index: Integer): T;
begin
  Result := GetSection(Index) as T;
end;

procedure TRMXSectionList.GrowSectionList;
begin
  if Length(FSections) <= Count then
    begin
      SetLength(FSections, GrowCollection(Count, Count + 1));
    end;
end;

procedure TRMXSectionList.LoadSection(Index: Integer);
var
  ptr: PRMXImageSection;
begin

  if Index >= Count then
    begin
      // raise
      exit;
    end;
  GrowSectionList;
  if FSections[Index] <> nil then exit;

  ptr := FRMXFile.Map(nil, FHeader.Origin.SectionDirectory[Index], RMX_REGION_SIZE);

  case ptr.TypeOfSection of
    tisUnknown: ;
    tisData:
      begin
        FSections[Index] := TRMXSectionData.Create(FRMXFile, PRMXDataSection(ptr));
      end;
    tisMetaData: ;
  end;

end;

procedure TRMXSectionList.StartSection(Section: TRMXSectionData);
begin
  if FCurrentSection <> Section then
    begin
      if Assigned(FCurrentSection) and (FCurrentSection.State <> ssFree) then
        raise Exception.Create('Need to close active section');
    end
  else
    exit;

  FCurrentSection := Section;
  Section.StartOf;

end;

{ TRMXSectionData }


function TRMXSectionData.AddPacket(Packet: TRMXPacketData): Boolean;
var
  sz: Cardinal;
  pkt: PRMXDataPacket;
  ptr: Pointer;
begin

  if FState <> ssWriting then
    raise Exception.Create('Section is not in wtite mode');
  Packet.FCompression := FHeader.GetCompression;
  Packet.SaveCompressed(pkt);
  try
    sz := FRMXFile.CalcAlignment(FHeader.Origin.DataAlignment, pkt.SizeOfPacket);
    if not CanExpandSize(sz) then
      raise Exception.Create('This section is full. Create a new section');

    if FFrameSize - FOffset < sz then
      begin
        FFrameSize := DEF_FRAME_SIZE;
        FBase := ReallocFrame(FBase, FOffset, FFrameSize);
      end;
    ptr := Pointer(INT_PTR(FBase) + FOffset);
    pkt.Index := PacketCount;
    Move(pkt^, ptr^, sz);
    FSection.DataDirectory[pkt.Index].offset := FOffset;
    FSection.DataDirectory[pkt.Index].size := sz;
  finally
    FreeMem(pkt);
  end;

  FSection.PacketCount := FSection.PacketCount + 1;
  FSection.SizeOfData  := FSection.SizeOfData + sz;
  FOffset := FOffset + sz;


end;

function TRMXSectionData.CanExpandSize(size: Cardinal): Boolean;
begin
  Result := (Cardinal($FFFFFFFF) - FSection.SizeOfData >= size) and (PacketCount < FMaxAvailaiblePackets);
end;

constructor TRMXSectionData.Create(RMXFile: TRMXVideoFile;
  Ptr: PRMXDataSection);
begin
  inherited Create;
  FSection := Ptr;
  Origin := PRMXImageSection(Ptr);
  FRMXFile := RMXFile;
  FHeader := FRMXFile.FHeader;
  if FSection.SizeOfData > 0 then
    FState := ssClosed;

end;

destructor TRMXSectionData.Destroy;
begin
  FRMXFile.Unmap(FBase);
  inherited;
end;

procedure TRMXSectionData.EndOf;
begin
  if FState = ssWriting then
    begin
      FHeader.Origin.SizeOfImage := FHeader.Origin.SizeOfImage +
        FRMXFile.CalcAlignment(FRMXFile.SysInfo.dwAllocationGranularity, FSection.SizeOfData);
      FHeader.Origin.NumberOfFrames := FHeader.Origin.NumberOfFrames + FSection.PacketCount;
      FState := ssClosed;
    end;


end;

function TRMXSectionData.EOF: Boolean;
begin
  if FState <> ssClosed  then
    raise Exception.Create('Sestion is empty or in the writing state');
  Result := (FPosition + 1 >= PacketCount);
end;

procedure TRMXSectionData.First;
begin
  if (FState <> ssClosed) or (PacketCount = 0)  then
    raise Exception.Create('Sestion is empty or in the writing state');
  FRMXFile.Unmap(FBase);
  FPosition := 0;
  FOffset := 0;
  FBase := nil;
  if FSection.SizeOfData < DEF_FRAME_SIZE then
    FFrameSize := FSection.SizeOfData else
    FFrameSize := DEF_FRAME_SIZE;

  FBase := ReallocFrame(FBase, FOffset, FFrameSize);

end;

function TRMXSectionData.GetPacket(Index: Integer): TRMXPacketData;
begin
  Result := nil;
  if (FState <> ssClosed) or (PacketCount = 0)  then
    raise Exception.Create('Sestion is empty or in the writing state');
  Result := TRMXPacketData.Create(Self);
  try
    LoadPacket(Index, Result);
  except
    Result.Free;
    raise;
  end;
end;

function TRMXSectionData.GetPacketDirect: PRMXDataPacket;
begin
    if Assigned(FBase) then
      begin
        Result := Pointer(INT_PTR(FBase) + FOffset);
      end
end;

procedure TRMXSectionData.InitializeNew;
begin
  FillChar(FSection^, RMX_REGION_SIZE, 0);
  FSection.SizeOfSection := RMX_REGION_SIZE;
  FSection.TypeOfSection := tisData;
  FState := ssFree;
  FMaxAvailaiblePackets := (RMX_REGION_SIZE - SizeOf(TRMXDataSection)) div SizeOf(FSection.DataDirectory[0]);
end;

procedure TRMXSectionData.LoadPacket(Index: Cardinal; Packet: TRMXPacketData);
var
  sz: Cardinal;
  pkt: PRMXDataPacket;
begin
  sz := FSection.DataDirectory[Index].size;
  GetMem(pkt, sz);
  try
    if (Index = FPosition) and Assigned(FBase) then
      begin
        Move(Pointer(INT_PTR(FBase) + FOffset)^, pkt^, sz);
      end
    else
      begin
        FRMXFile.ReadFile(pkt^, FSection.BaseOfData + FSection.DataDirectory[Index].offset, sz);
      end;
    Packet.FCompression := FHeader.GetCompression;
    Packet.LoadCompressed(pkt);
  finally
    FreeMem(pkt);
  end;

end;

function TRMXSectionData.Next: Boolean;
var
  sz: Cardinal;
begin
  Result := false;
  if (FState <> ssClosed) or (PacketCount = 0)  then
    raise Exception.Create('Sestion is empty or in the writing state');
  if (FPosition + 1) >= FSection.PacketCount then exit;
  Inc(FPosition);
  FOffset := FSection.DataDirectory[FPosition].offset;

  if FFrameSize - FOffset < FSection.DataDirectory[FPosition].size then
    begin
      sz := FSection.SizeOfData - (FOffset + FSection.DataDirectory[FPosition].size);
      if sz < DEF_FRAME_SIZE then
        FFrameSize := sz else
        FFrameSize := DEF_FRAME_SIZE;
      FBase := ReallocFrame(FBase, FOffset, FFrameSize);
    end;

  Result := true;
end;

function TRMXSectionData.PacketCount: Cardinal;
begin
  Result := FSection.PacketCount;
end;

function TRMXSectionData.ReallocFrame(Ptr: Pointer;
  var FrameOffset: Cardinal; FrameSize: Cardinal): Pointer;
var
  offset_g, offset: Int64;
begin
  offset := FSection.BaseOfData;
  if (offset = 0) then
    begin
      offset := FHeader.Origin.SectionDirectory[FSection.Index] + FSection.SizeOfSection;
    end;
  offset := offset + FrameOffset;
  offset_g := FRMXFile.CalcAlignment(FRMXFile.SysInfo.dwAllocationGranularity, offset);
  Assert(offset_g >= offset, 'CalcAlignment error');
  if (offset_g <> offset) and (FrameOffset > 0) then
    begin
      offset_g := offset_g - FRMXFile.SysInfo.dwAllocationGranularity;
      FrameOffset := Offset - offset_g;
      FrameSize := FrameSize + FRMXFile.SysInfo.dwAllocationGranularity;
    end;


  Result := FRMXFile.Remap(Ptr, offset_g, FrameSize);
  if FSection.BaseOfData = 0 then
    begin
      FSection.BaseOfData := offset_g;
    end;

end;


procedure TRMXSectionData.StartOf;
begin
  if FState = ssClosed  then
    raise Exception.Create('Sestion is closed. Can''t expand. Use new section');
  FState := ssWriting;
end;



{ TRMXPacketData }

constructor TRMXPacketData.Create(Section: TRMXSectionData);
begin
  inherited Create;
  FSection := Section;
  InitializeNew;
end;

destructor TRMXPacketData.Destroy;
begin

  inherited;
end;

procedure TRMXPacketData.InitializeNew;
begin
  FillChar(FPacket, SizeOf(TRMXDataPacket), 0);
  FPacket.SizeOfPacket := SizeOf(TRMXDataPacket);
  FPosition := 0;
  SetLength(FData, 0);
  FCompression := nil;
end;

procedure TRMXPacketData.LoadCompressed(pkt: PRMXDataPacket);
begin
  SetLength(FData, pkt.DataSize);
  FPacket := pkt^;
  if pkt.CompressedSize = pkt.DataSize then
    begin
      Move(pkt.Data[0], FData[0], pkt.DataSize);
    end
  else
    begin
      FCompression.Decompress(@pkt.Data[0], pkt.CompressedSize, @FData[0], pkt.DataSize);
    end;
end;

function TRMXPacketData.ReadData(var Buffer; Size: Cardinal): Integer;
begin
  if FPosition + Size > FPacket.DataSize  then
    Result :=  FPacket.DataSize - FPosition else
    Result := Size;
  if Result <= 0 then exit;
  Move(FData[FPosition], Buffer , Result);
  FPosition := FPosition + Result;
end;

function TRMXPacketData.SaveCompressed(out pkt: PRMXDataPacket): Cardinal;
var
  sz: NativeUInt;
begin
  //GetMem(pkt, FPacket.SizeOfPacket);
  pkt := AllocMem(FPacket.SizeOfPacket);
  pkt^ := FPacket;
  if Assigned(FCompression) then
    begin
      sz := FCompression.Compress(@FData[0], Length(FData), @pkt^.Data[0] , Length(FData));
    end
  else
    begin
      sz := Length(FData);
      Move(FData[0], pkt^.Data[0], sz);
    end;
  pkt.CompressedSize := sz;
  pkt.SizeOfPacket := SizeOf(TRMXDataPacket) + sz;
  Result := pkt.SizeOfPacket;
  FPacket.CompressedSize := pkt.CompressedSize;
end;

function TRMXPacketData.Seek(Offset: Cardinal; Origin: Integer): Integer;
begin
  case TSeekOrigin(Origin) of
    soBeginning: FPosition := Offset;
    soCurrent: Inc(FPosition, Offset);
    soEnd: FPosition := FPacket.DataSize + Offset;
  end;
  Result := FPosition;
end;

procedure TRMXPacketData.WriteData(const Buffer; Size: Cardinal);
begin

  if Length(FData) <= FPosition then
    SetLength(FData, FPosition + Size);

  Move(Buffer, FData[FPosition], Size);
  FPosition := FPosition + Size;
  FPacket.DataSize := FPosition;
  FPacket.SizeOfPacket := SizeOf(TRMXDataPacket) + FPosition

end;

end.
