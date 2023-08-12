unit rmxVideoPacketTypes;
{$A8}

interface

const
  RMX_MAGIC_TEXT = 'RMX!';
  RMX_MAGIC = Ord('R') or  Ord('M') shl 8  or Ord('X') shl 16 or Ord('!') shl 24;  //$524D5821;
  RMX_FILE_VERSION =  $01000001; //(Word: minor, Word: major)
  RMX_SECTION_PADDING = 128;
  RMX_DATA_ALIGNMENT = 16;
  RMX_REGION_SIZE = 1024 * 64; // 64kb
  RMX_FIELDS_ALIGNMENT = 8;
  RMX_MAX_SIZE_DATA = Cardinal($FFFFFFFF);

type
  PRMXFileVersion = ^TRMXFileVersion;
  TRMXFileVersion = record
    MajorVersion: Word;
    MinorVersion: Word;
  end;





  PRMXHeaderFile = ^TRMXHeaderFile;
  TRMXHeaderFile = record
    Magic            : Cardinal;
    dummy            : array [0..16-SizeOf(Cardinal) -1] of byte;  // padding zero
    Version          : TRMXFileVersion;           // cast to DWORD
    SizeOfImage      : Int64;                     // Size of File
    TimeStamp        : Int64;                     // TimeStamp (msec), created file
    Duration         : Int64;                     // duration video
    CheckSumOfImage  : Cardinal;                  // CheckSum of File, exclde this field
    DataAlignment    : Cardinal;                  // Alignment of all structures
    NumberOfSections : Cardinal;                  // Number of sections
    NumberOfFrames   : Cardinal;                  // Number of frames
    BaseOfSection    : Int64;                     // Offset of First Section  , TRMXImageSection
    Reserve          : Cardinal;                  // Reserve not use
    SectionDirectory : array [0..0] of Int64;     // array of offset of Sections

  end;


  {$Z+}
  // min enum size = double word
  TTypeImageSection = (tisUnknown, tisData, tisMetaData);
  {$Z-}

  TRMXDataDirectoryInfo = record
    offset: Cardinal;
    size: Cardinal;
  end;
  PRMXDataDirectory = ^TRMXDataDirectory;
  TRMXDataDirectory = array [0..0] of TRMXDataDirectoryInfo;


  PRMXImageSection = ^TRMXImageSection;
  TRMXImageSection = record
    SizeOfSection : Cardinal;           // Size of Current section
    Index         : Cardinal;
    TypeOfSection : TTypeImageSection;
    RVPrior       : Int64;
    RVNext        : Int64;
  end;

  PRMXDataSection = ^TRMXDataSection;
  TRMXDataSection = record
    SizeOfSection         : Cardinal;  // Size of Current section
    Index                 : Cardinal;
    TypeOfSection         : TTypeImageSection;
    RVPrior               : Int64;
    RVNext                : Int64;

    SizeOfData            : Cardinal;  // Size of Data
    PacketCount           : Cardinal;  // Packet Count
    CheckSum              : Cardinal;  // CheckSum all packets
    BaseOfData            : Int64;     // Entry point of packets. Offset from begining file
    Reserve               : Cardinal;  // Reserve not use
    DataDirectory         : array [0..0] of TRMXDataDirectoryInfo;   // Entry point of Array with Address of Packets , TAddressOfPacket

  end;


  {$Z+}
  // min enum size = double word
  TTypeDataPacket = (tdpUnknown, tdpBridge, tdpRaw, tdpScreenInfo);
  {$Z-}

  PRMXDataPacket = ^TRMXDataPacket;
  TRMXDataPacket = record
    SizeOfPacket      : Cardinal;            // Packet size in bytes  SizeOf(TRMXDataPacket) + SizeOfCompressed
    CompressedSize    : Cardinal;            // Compressed Data size in bytes, ,
    DataSize          : Cardinal;            // Raw Data size in bytes, ,
    TimeStampEllapsed : Int64;               // Relative Time label of Packet in ms
    Index             : Cardinal;            // Index of Packet
    CheckSum          : Cardinal;            // CheckSum of Data
    TypeOfData        : TTypeDataPacket;     // Type of Data
    RVPrior           : Int64;               // Relative offset from current, negative value
    RVNext            : Int64;               // Relative offfset from current, positve value
    Reserve           : Cardinal;            // Reserve not use
    Data              : array [0..0] of Byte;
  end;





  PRMXSectionDirectory = ^TRMXSectionDirectory;
  TRMXSectionDirectory = array [0..0] of Int64;

implementation

end.
