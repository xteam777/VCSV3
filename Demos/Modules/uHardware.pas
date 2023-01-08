unit uHardware;

interface

uses
  Windows,
  Classes,
  SysUtils,
  ActiveX,
  ComObj,
  Variants,
  uProcess;

type
   PTokenUser = ^TTokenUser;
   TTokenUser = packed record
     User: TSidAndAttributes;
   end;
   TMotherBoardInfo   = (Mb_SerialNumber,Mb_Manufacturer,Mb_Product,Mb_Model);
   TMotherBoardInfoSet= set of TMotherBoardInfo;
   TProcessorInfo     = (Pr_Description,Pr_Manufacturer,Pr_Name,Pr_ProcessorId,Pr_UniqueId);
   TProcessorInfoSet  = set of TProcessorInfo;
   TBIOSInfo          = (Bs_BIOSVersion,Bs_BuildNumber,Bs_Description,Bs_Manufacturer,Bs_Name,Bs_SerialNumber,Bs_Version);
   TBIOSInfoSet       = set of TBIOSInfo;
   TOSInfo            = (Os_BuildNumber,Os_BuildType,Os_Manufacturer,Os_Name,Os_SerialNumber,Os_Version);
   TOSInfoSet         = set of TOSInfo;

const //properties names to get the data
   MotherBoardInfoArr: array[TMotherBoardInfo] of AnsiString =
                        ('SerialNumber','Manufacturer','Product','Model');

   OsInfoArr         : array[TOSInfo] of AnsiString =
                        ('BuildNumber','BuildType','Manufacturer','Name','SerialNumber','Version');

   BiosInfoArr       : array[TBIOSInfo] of AnsiString =
                        ('BIOSVersion','BuildNumber','Description','Manufacturer','Name','SerialNumber','Version');

   ProcessorInfoArr  : array[TProcessorInfo] of AnsiString =
                        ('Description','Manufacturer','Name','ProcessorId','UniqueId');

   HEAP_ZERO_MEMORY = $00000008;
   SID_REVISION     = 1; // Current revision level

   THREAD_QUERY_INFORMATION = $0040;

type
   THardwareId  = class
   private
    FOSInfo         : TOSInfoSet;
    FBIOSInfo       : TBIOSInfoSet;
    FProcessorInfo  : TProcessorInfoSet;
    FMotherBoardInfo: TMotherBoardInfoSet;
    FBuffer         : AnsiString;
    function GetHardwareIdHex: AnsiString;
   public
    AddUserProfileName: Boolean;
    UserProfileName: String;
     //Set the properties to  be used in the generation of the hardware id
    property  MotherBoardInfo : TMotherBoardInfoSet read FMotherBoardInfo write FMotherBoardInfo;
    property  ProcessorInfo : TProcessorInfoSet read FProcessorInfo write FProcessorInfo;
    property  BIOSInfo: TBIOSInfoSet read FBIOSInfo write FBIOSInfo;
    property  OSInfo  : TOSInfoSet read FOSInfo write FOSInfo;
    property  Buffer : AnsiString read FBuffer; //return the content of the data collected in the system
    property  HardwareIdHex : AnsiString read GetHardwareIdHex; //get a hexadecimal represntation of the data collected
    procedure GenerateHardwareId; //calculate the hardware id
    constructor  Create(Generate:Boolean=True); overload;
    destructor Destroy; override;
    function SIDToString(ASID: PSID): String;
    function ObtainTextSid(hToken: THandle): String; //; pszSid: PChar; var dwBufferLen: DWORD
    function GetLocalComputerName: String;
    function GetComputerSID: String;
    function GetCurrentUserSid: String;
//    function GetSystemUserName: String;
   end;

   function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwThreadId: DWORD): DWORD; stdcall; external 'kernel32.dll';

implementation

//function THardwareId.GetSystemUserName: String;
//var // Получить имя пользователя машины
//  UserName: array[0..255] of Char;
//  UserNameSize: DWORD;
//begin
//  UserNameSize := 255;
//  if GetUserName(@UserName, UserNameSize) then
//    Result := string(UserName)
//  else
//    Result := '';
//end;

{ function ConvertSid(Sid: PSID; pszSidText: PChar; var dwBufferLen: DWORD): BOOL;
 var
   psia: PSIDIdentifierAuthority;
   dwSubAuthorities: DWORD;
   dwSidRev: DWORD;
   dwCounter: DWORD;
   dwSidSize: DWORD;
 begin
   Result := False;

   dwSidRev := SID_REVISION;

   if not IsValidSid(Sid) then Exit;

   psia := GetSidIdentifierAuthority(Sid);

   dwSubAuthorities := GetSidSubAuthorityCount(Sid)^;

   dwSidSize := (15 + 12 + (12 * dwSubAuthorities) + 1) * SizeOf(Char);

   if (dwBufferLen < dwSidSize) then
   begin
     dwBufferLen := dwSidSize;
     SetLastError(ERROR_INSUFFICIENT_BUFFER);
     Exit;
   end;

   StrFmt(pszSidText, 'S-%u-', [dwSidRev]);

   if (psia.Value[0] <> 0) or (psia.Value[1] <> 0) then
     StrFmt(pszSidText + StrLen(pszSidText),
       '0x%.2x%.2x%.2x%.2x%.2x%.2x',
       [psia.Value[0], psia.Value[1], psia.Value[2],
       psia.Value[3], psia.Value[4], psia.Value[5]])
   else
     StrFmt(pszSidText + StrLen(pszSidText),
       '%u',
       [DWORD(psia.Value[5]) +
       DWORD(psia.Value[4] shl 8) +
       DWORD(psia.Value[3] shl 16) +
       DWORD(psia.Value[2] shl 24)]);

   dwSidSize := StrLen(pszSidText);

   for dwCounter := 0 to dwSubAuthorities - 1 do
   begin
     StrFmt(pszSidText + dwSidSize, '-%u',
       [GetSidSubAuthority(Sid, dwCounter)^]);
     dwSidSize := StrLen(pszSidText);
   end;

   Result := True;
 end;}

function THardwareId.ObtainTextSid(hToken: THandle): String; //; pszSid: PChar; var dwBufferLen: DWORD
var
   dwReturnLength: DWORD;
   dwTokenUserLength: DWORD;
   tic: TTokenInformationClass;
   ptu: Pointer;
begin
   Result := '';
   dwReturnLength := 0;
   dwTokenUserLength := 0;
   tic := TokenUser;
   ptu := nil;

   if not GetTokenInformation(hToken, tic, ptu, dwTokenUserLength,
     dwReturnLength) then
   begin
     if GetLastError = ERROR_INSUFFICIENT_BUFFER then
     begin
       ptu := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwReturnLength);
       if ptu = nil then Exit;
       dwTokenUserLength := dwReturnLength;
       dwReturnLength    := 0;

       if not GetTokenInformation(hToken, tic, ptu, dwTokenUserLength,
         dwReturnLength) then Exit;
     end
      else
        Exit;
   end;

   //if not ConvertSid((PTokenUser(ptu).User).Sid, pszSid, dwBufferLen) then Exit;
   Result := SIDToString((PTokenUser(ptu).User).Sid);

   if not HeapFree(GetProcessHeap, 0, ptu) then Exit;

//   Result := True;
end;

function THardwareId.GetCurrentUserSid: String;
 var
   hAccessToken: THandle;
   bSuccess: BOOL;
   dwBufferLen: DWORD;
   szSid: array[0..260] of Char;
 begin
   Result := '';

   bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True,
     hAccessToken);
   if not bSuccess then
   begin
     if GetLastError = ERROR_NO_TOKEN then
       bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY,
         hAccessToken);
   end;
   if bSuccess then
   begin
     ZeroMemory(@szSid, SizeOf(szSid));
     dwBufferLen := SizeOf(szSid);

     Result := ObtainTextSid(hAccessToken);
     CloseHandle(hAccessToken);
   end;
 end;

function VarArrayToStr(const vArray: variant): AnsiString;
  function _VarToStr(const V: variant): AnsiString;
  var
  Vt: integer;
  begin
   Vt := VarType(V);
      case Vt of
        varSmallint,
        varInteger  : Result := AnsiString(IntToStr(integer(V)));
        varSingle,
        varDouble,
        varCurrency : Result := AnsiString(FloatToStr(Double(V)));
        varDate     : Result := AnsiString(VarToStr(V));
        varOleStr   : Result := AnsiString(WideString(V));
        varBoolean  : Result := AnsiString(VarToStr(V));
        varVariant  : Result := AnsiString(VarToStr(Variant(V)));
        varByte     : Result := AnsiChar(byte(V));
        varString   : Result := AnsiString(V);
        varArray    : Result := VarArrayToStr(Variant(V));
      end;
  end;

var
i : integer;
begin
    Result := '[';
    if (VarType(vArray) and VarArray)=0 then
       Result := _VarToStr(vArray)
    else
    for i := VarArrayLowBound(vArray, 1) to VarArrayHighBound(vArray, 1) do
     if i=VarArrayLowBound(vArray, 1)  then
      Result := Result+_VarToStr(vArray[i])
     else
      Result := Result+'|'+_VarToStr(vArray[i]);

    Result:=Result+']';
end;

function VarStrNull(const V:OleVariant):AnsiString; //avoid problems with null strings
begin
  Result:='';
  if not VarIsNull(V) then
  begin
    if VarIsArray(V) then
       Result:=VarArrayToStr(V)
    else
    Result:=AnsiString(VarToStr(V));
  end;
end;

{ THardwareId }

constructor THardwareId.Create(Generate:Boolean=True);
begin
   inherited Create;
   CoInitialize(nil);
   FBuffer          :='';
   //Set the propeties to be used in the hardware id generation
   FMotherBoardInfo :=[Mb_SerialNumber,Mb_Manufacturer,Mb_Product,Mb_Model];
   FOSInfo          :=[]; //Os_SerialNumber, Os_BuildNumber,Os_BuildType,Os_Manufacturer,Os_Name,Os_Version,
   FBIOSInfo        :=[Bs_SerialNumber]; //Bs_BIOSVersion,Bs_BuildNumber,Bs_Description,Bs_Manufacturer,Bs_Name,Bs_Version,
   FProcessorInfo   :=[];//including the processor info is expensive [Pr_Description,Pr_Manufacturer,Pr_Name,Pr_ProcessorId,Pr_UniqueId];
   if Generate then
    GenerateHardwareId;
end;

destructor THardwareId.Destroy;
begin
  CoUninitialize;
  inherited;
end;

//Main function which collect the system data.
procedure THardwareId.GenerateHardwareId;
var
  objSWbemLocator : OLEVariant;
  objWMIService   : OLEVariant;
  objWbemObjectSet: OLEVariant;
  oWmiObject      : OLEVariant;
  oEnum           : IEnumvariant;
  iValue          : LongWord;
  SDummy          : AnsiString;
  Mb              : TMotherBoardInfo;
  Os              : TOSInfo;
  Bs              : TBIOSInfo;
  Pr              : TProcessorInfo;
begin
  FBuffer := '';

  objSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  objWMIService   := objSWbemLocator.ConnectServer('localhost','root\cimv2', '','');

  if FMotherBoardInfo<>[] then //MotherBoard info
  begin
    objWbemObjectSet:= objWMIService.ExecQuery('SELECT * FROM Win32_BaseBoard','WQL',0);
    oEnum           := IUnknown(objWbemObjectSet._NewEnum) as IEnumVariant;
    while oEnum.Next(1, oWmiObject, iValue) = 0 do
    begin
      for Mb := Low(TMotherBoardInfo) to High(TMotherBoardInfo) do
       if Mb in FMotherBoardInfo then
       begin
          SDummy:=VarStrNull(oWmiObject.Properties_.Item(MotherBoardInfoArr[Mb]).Value);
          FBuffer:=FBuffer+SDummy;
       end;
       oWmiObject:=Unassigned;
    end;
  end;

  if FOSInfo<>[] then//Windows info
  begin
    objWbemObjectSet:= objWMIService.ExecQuery('SELECT * FROM Win32_OperatingSystem','WQL',0);
    oEnum           := IUnknown(objWbemObjectSet._NewEnum) as IEnumVariant;
    while oEnum.Next(1, oWmiObject, iValue) = 0 do
    begin
      for Os := Low(TOSInfo) to High(TOSInfo) do
       if Os in FOSInfo then
       begin
          SDummy:=VarStrNull(oWmiObject.Properties_.Item(OsInfoArr[Os]).Value);
          FBuffer:=FBuffer+SDummy;
       end;
       oWmiObject:=Unassigned;
    end;
  end;

  FBuffer := FBuffer + GetComputerSID;

  if FBIOSInfo<>[] then//BIOS info
  begin
    objWbemObjectSet:= objWMIService.ExecQuery('SELECT * FROM Win32_BIOS','WQL',0);
    oEnum           := IUnknown(objWbemObjectSet._NewEnum) as IEnumVariant;
    while oEnum.Next(1, oWmiObject, iValue) = 0 do
    begin
      for Bs := Low(TBIOSInfo) to High(TBIOSInfo) do
       if Bs in FBIOSInfo then
       begin
          SDummy:=VarStrNull(oWmiObject.Properties_.Item(BiosInfoArr[Bs]).Value);
          FBuffer:=FBuffer+SDummy;
       end;
       oWmiObject:=Unassigned;
    end;
  end;

  if FProcessorInfo<>[] then//CPU info
  begin
    objWbemObjectSet:= objWMIService.ExecQuery('SELECT * FROM Win32_Processor','WQL',0);
    oEnum           := IUnknown(objWbemObjectSet._NewEnum) as IEnumVariant;
    while oEnum.Next(1, oWmiObject, iValue) = 0 do
    begin
      for Pr := Low(TProcessorInfo) to High(TProcessorInfo) do
       if Pr in FProcessorInfo then
       begin
          SDummy:=VarStrNull(oWmiObject.Properties_.Item(ProcessorInfoArr[Pr]).Value);
          FBuffer:=FBuffer+SDummy;
       end;
       oWmiObject:=Unassigned;
    end;
  end;

  if AddUserProfileName then
    if UserProfileName <> '' then
      FBuffer := FBuffer + UserProfileName
    else
      FBuffer := FBuffer + GetCurrentUserSid; //GetSystemUserName;
end;

function THardwareId.SIDToString(ASID: PSID): String;
var
  StringSid : PChar;
begin
  ConvertSidToStringSid(ASID, StringSid);
  Result := string(StringSid);
end;

function THardwareId.GetLocalComputerName: String;
var
  nSize: DWORD;
begin
  nSize := MAX_COMPUTERNAME_LENGTH + 1;
  SetLength(Result, nSize);
  if not GetComputerName(PChar(Result), nSize) then
    Result := '';
end;

function THardwareId.GetComputerSID: String;
var
  Sid: PSID;
  cbSid: DWORD;
  cbReferencedDomainName : DWORD;
  ReferencedDomainName: string;
  peUse: SID_NAME_USE;
  Success: BOOL;
  lpSystemName : string;
  lpAccountName: string;
begin
  Sid:=nil;
  try
    lpSystemName:='';
    lpAccountName:=GetLocalComputerName;

    cbSid := 0;
    cbReferencedDomainName := 0;
    // First call to LookupAccountName to get the buffer sizes.
    Success := LookupAccountName(PChar(lpSystemName), PChar(lpAccountName), nil, cbSid, nil, cbReferencedDomainName, peUse);
    if (not Success) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
    begin
      SetLength(ReferencedDomainName, cbReferencedDomainName);
      Sid := AllocMem(cbSid);
      // Second call to LookupAccountName to get the SID.
      Success := LookupAccountName(PChar(lpSystemName), PChar(lpAccountName), Sid, cbSid, PChar(ReferencedDomainName), cbReferencedDomainName, peUse);
      if not Success then
      begin
        FreeMem(Sid);
        Sid := nil;
        RaiseLastOSError;
      end
      else
        Result := SIDToString(Sid);
    end
    else
      RaiseLastOSError;
  finally
    if Assigned(Sid) then
     FreeMem(Sid);
  end;
end;

function THardwareId.GetHardwareIdHex: AnsiString;
begin
  SetLength(Result,Length(FBuffer)*2);
  BinToHex(PAnsiChar(FBuffer),PAnsiChar(Result),Length(FBuffer));
end;

end.