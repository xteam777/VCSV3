unit NTImport;

interface
uses
  Winapi.Windows;

const
  ntdll = 'NTDLL.DLL';

type

  _IO_STATUS_BLOCK = record
    //union {
    Status: NTSTATUS;
    //    PVOID Pointer;
    //}
    Information: ULONG_PTR;
  end;
  IO_STATUS_BLOCK = _IO_STATUS_BLOCK;
  PIO_STATUS_BLOCK = ^IO_STATUS_BLOCK;
  TIoStatusBlock = IO_STATUS_BLOCK;
  PIoStatusBlock = ^TIoStatusBlock;

  _FILE_INFORMATION_CLASS = (
    FileFiller0,
    FileDirectoryInformation, // 1
    FileFullDirectoryInformation, // 2
    FileBothDirectoryInformation, // 3
    FileBasicInformation, // 4  wdm
    FileStandardInformation, // 5  wdm
    FileInternalInformation, // 6
    FileEaInformation, // 7
    FileAccessInformation, // 8
    FileNameInformation, // 9
    FileRenameInformation, // 10
    FileLinkInformation, // 11
    FileNamesInformation, // 12
    FileDispositionInformation, // 13
    FilePositionInformation, // 14 wdm
    FileFullEaInformation, // 15
    FileModeInformation, // 16
    FileAlignmentInformation, // 17
    FileAllInformation, // 18
    FileAllocationInformation, // 19
    FileEndOfFileInformation, // 20 wdm
    FileAlternateNameInformation, // 21
    FileStreamInformation, // 22
    FilePipeInformation, // 23
    FilePipeLocalInformation, // 24
    FilePipeRemoteInformation, // 25
    FileMailslotQueryInformation, // 26
    FileMailslotSetInformation, // 27
    FileCompressionInformation, // 28
    FileObjectIdInformation, // 29
    FileCompletionInformation, // 30
    FileMoveClusterInformation, // 31
    FileQuotaInformation, // 32
    FileReparsePointInformation, // 33
    FileNetworkOpenInformation, // 34
    FileAttributeTagInformation, // 35
    FileTrackingInformation, // 36
    FileMaximumInformation);
  FILE_INFORMATION_CLASS = _FILE_INFORMATION_CLASS;
  PFILE_INFORMATION_CLASS = ^FILE_INFORMATION_CLASS;
  TFileInformationClass = FILE_INFORMATION_CLASS;
  PFileInformationClass = ^TFileInformationClass;


  _FILE_NETWORK_OPEN_INFORMATION = record
    CreationTime: LARGE_INTEGER;
    LastAccessTime: LARGE_INTEGER;
    LastWriteTime: LARGE_INTEGER;
    ChangeTime: LARGE_INTEGER;
    AllocationSize: LARGE_INTEGER;
    EndOfFile: LARGE_INTEGER;
    FileAttributes: ULONG;
  end;
  FILE_NETWORK_OPEN_INFORMATION = _FILE_NETWORK_OPEN_INFORMATION;
  PFILE_NETWORK_OPEN_INFORMATION = ^FILE_NETWORK_OPEN_INFORMATION;
  TFileNetworkOpenInformation = FILE_NETWORK_OPEN_INFORMATION;
  PFileNetworkOpenInformation = ^TFileNetworkOpenInformation;

  _FILE_STANDARD_INFORMATION = record
    AllocationSize: LARGE_INTEGER;
    EndOfFile: LARGE_INTEGER;
    NumberOfLinks: ULONG;
    DeletePending: ByteBool;
    Directory: ByteBool;
  end;
  FILE_STANDARD_INFORMATION = _FILE_STANDARD_INFORMATION;
  PFILE_STANDARD_INFORMATION = ^FILE_STANDARD_INFORMATION;
  TFileStandardInformation = FILE_STANDARD_INFORMATION;
  PFileStandardInformation = ^TFileStandardInformation;

function  NtQueryInformationFile(
    FileHandle : THANDLE;
    IoStatusBlock : PIO_STATUS_BLOCK;
    FileInformation : PVOID;
    FileInformationLength : ULONG;
    FileInformationClass : FILE_INFORMATION_CLASS
  ): NTSTATUS; stdcall;

function ConvertNtStatusToWin32Error(status: NTSTATUS): Cardinal;
implementation

(*
 * This is an alternative to the RtlNtStatusToDosError()
 * function in ntdll.dll.  It uses the GetOverlappedResult()
 * function in kernel32.dll to do the conversion.
 *)
function ConvertNtStatusToWin32Error(status: NTSTATUS): Cardinal;
var
  e, b: Cardinal;
  ov: TOverlapped;
begin
        e := GetLastError();
        GetOverlappedResult(0, ov, b, false);
        result := GetLastError();
        SetLastError(e);
end;

function  NtQueryInformationFile; external ntdll delayed;
end.
