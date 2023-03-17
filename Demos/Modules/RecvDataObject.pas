unit RecvDataObject;

interface
uses
  Winapi.Windows, System.SysUtils, Winapi.Messages, System.Classes,
  Winapi.SHLObj, Winapi.ActiveX, ComObj, ClipbrdMonitor;
type
  TDataObject = class;
  TFormatEtcDynArray = array of FORMATETC;
  TDataOwnership = (soCopied, soReference, soOwned);
  TOnGetData = procedure (Sender: TDataObject; AUserName: String) of Object;
  TFileInfo = record
    desc: TFileDescriptor;
    filePath: String;
    ownership: TDataOwnership;
  end;

  TDataObject = class (TInterfacedObject, IDataObject, IEnumFORMATETC)
  private
	  FFormats: TFormatEtcDynArray;
    FOnGetData: TOnGetData;

    FEnumIndex: Integer;
    procedure ReleaseFiles;
    function InternalGetName(Index: Integer; out name: string): Boolean;

  public
    FFiles: TArray<TFileInfo>;
    FCount: Integer;
    FDirectory: String;
    FUserName: String;
    // IDataObject
    function GetData(const formatetcIn: TFormatEtc; out medium: TStgMedium):
      HResult; stdcall;
    function GetDataHere(const formatetc: TFormatEtc; out medium: TStgMedium):
      HResult; stdcall;
    function QueryGetData(const formatetc: TFormatEtc): HResult;
      stdcall;
    function GetCanonicalFormatEtc(const formatetc: TFormatEtc;
      out formatetcOut: TFormatEtc): HResult; stdcall;
    function SetData(const formatetc: TFormatEtc; var medium: TStgMedium;
      fRelease: BOOL): HResult; stdcall;
    function EnumFormatEtc(dwDirection: Longint; out enumFormatEtc:
      IEnumFormatEtc): HResult; stdcall;
    function DAdvise(const formatetc: TFormatEtc; advf: Longint;
      const advSink: IAdviseSink; out dwConnection: Longint): HResult; stdcall;
    function DUnadvise(dwConnection: Longint): HResult; stdcall;
    function EnumDAdvise(out enumAdvise: IEnumStatData): HResult;
      stdcall;

    // IEnumFORMATETC
    function Next(celt: Longint; out elt;
      pceltFetched: PLongint): HResult; stdcall;
    function Skip(celt: Longint): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enum: IEnumFormatEtc): HResult; stdcall;

    constructor Create(AUserName: String; const AFiles: TArray<TFileDescriptor>; AFilePaths: TArray<String>; AOnGetData: TOnGetData); overload;
    destructor Destroy; override;


  end;


implementation

{ TDataObject }

function TDataObject.Clone(out Enum: IEnumFormatEtc): HResult;
var
  data: TDataObject;
begin

  data := TDataObject.Create('', nil, nil, nil);
  data.FFormats := FFormats;
  data.FEnumIndex := FEnumIndex;
  Enum := data;
  Result := S_OK;

end;

constructor TDataObject.Create(AUserName: String; const AFiles: TArray<TFileDescriptor>; AFilePaths: TArray<String>; AOnGetData: TOnGetData);
begin
  inherited Create;
  FUserName := AUserName;
  FOnGetData := AOnGetData;
  FCount := Length(AFiles);
  SetLength(FFiles, Length(AFiles));
  for var i: Integer := 0 to Length(AFiles)-1 do
  begin
    FFiles[i].desc := AFiles[i];
    FFiles[i].filePath := AFilePaths[i];
  end;

	SetLength(FFormats, 2);

	FFormats[0].cfFormat  := TClipbrdMonitor.CF_FILECONTENTS;
	FFormats[0].dwAspect  := DVASPECT_CONTENT;
	FFormats[0].lindex    := -1;
	FFormats[0].tymed     := TYMED_ISTREAM; //TYMED_HGLOBAL; //TYMED_NULL;
	FFormats[0].ptd       := nil;

	FFormats[1].cfFormat  := TClipbrdMonitor.CF_FILEDESCRIPTOR;
	FFormats[1].dwAspect  := DVASPECT_CONTENT;
	FFormats[1].tymed     := TYMED_HGLOBAL;
	FFormats[1].lindex    := -1;
	FFormats[1].ptd       := nil;

//	FFormats[2].cfFormat  := CF_HDROP;
//	FFormats[2].dwAspect  := DVASPECT_CONTENT;
//	FFormats[2].tymed     := TYMED_HGLOBAL;
//	FFormats[2].lindex    := -1;
//	FFormats[2].ptd       := nil;
end;


function TDataObject.DAdvise(const formatetc: TFormatEtc; advf: Longint;
  const advSink: IAdviseSink; out dwConnection: Longint): HResult;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;


destructor TDataObject.Destroy;
begin
  ReleaseFiles;
  inherited;
end;

function TDataObject.DUnadvise(dwConnection: Longint): HResult;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;

function TDataObject.EnumDAdvise(out enumAdvise: IEnumStatData): HResult;
begin
  Result := OLE_E_ADVISENOTSUPPORTED;
end;

function TDataObject.EnumFormatEtc(dwDirection: Longint;
  out enumFormatEtc: IEnumFormatEtc): HResult;
begin
	enumFormatEtc := nil;
  Result :=  S_OK;
	case (dwDirection) of
	  DATADIR_GET: enumFormatEtc := Self;
    else
	  	Result :=  E_NOTIMPL;
  end;

end;

function TDataObject.GetCanonicalFormatEtc(const formatetc: TFormatEtc;
  out formatetcOut: TFormatEtc): HResult;
begin
	Result := DATA_S_SAMEFORMATETC;
end;

function TDataObject.GetData(const formatetcIn: TFormatEtc;
  out medium: TStgMedium): HResult;
var
  pFormatName: String;
  len: Integer;
begin
   SetLength(pFormatName, 255);
   len := GetClipboardFormatName(formatetcIn.cfFormat, @pFormatName[1], 255);
   SetLength(pFormatName, len);

	if (formatetcIn.dwAspect and DVASPECT_CONTENT) = 0 then
		exit(DV_E_DVASPECT);

	medium.hGlobal := 0;
	medium.unkForRelease := nil;

	if (formatetcIn.tymed and TYMED_ISTREAM <> 0) and
     (formatetcIn.cfFormat = TClipbrdMonitor.CF_FILECONTENTS) then
	  begin
//      var data: TStream;
      //var fname: String;
//      if not InternalGetData(formatetcIn.lindex, data) then exit (E_INVALIDARG);
      //if not InternalGetName(formatetcIn.lindex, fname) then exit (E_INVALIDARG);

      if (formatetcIn.lindex >= 0) and (formatetcIn.lindex < FCount) then
        if Assigned(FOnGetData)
          and (formatetcIn.lindex = 0) then
          FOnGetData(Self, FUserName);

		  // supports the IStream format.
//      var local_stream: TMemoryStream;
//		  local_stream := TMemoryStream.Create;
//		  local_stream.CopyFrom(data);
//		  local_stream.Position := 0;
//		  var pIStream: IStream := TStreamAdapter.Create(local_stream, TStreamOwnership.soOwned);
//      pIStream._AddRef;
//		  medium.stm := pIStream;

//		  medium.tymed := TYMED_NULL;
//		  exit(S_OK);

//	  	var dataSize: size_t := 1;
//	  	var data: HGLOBAL := GlobalAlloc(GMEM_MOVEABLE or GMEM_SHARE or GMEM_ZEROINIT, dataSize);
//
//	  	GlobalUnlock(data);
//
//	  	medium.hGlobal := data;
//	  	medium.tymed := TYMED_HGLOBAL;
//	  	exit(S_OK);

	  	medium.stm := nil;
	  	medium.tymed := TYMED_NULL;
	  	exit(S_FALSE);
    end
	else if (formatetcIn.tymed and TYMED_HGLOBAL <> 0) and
			    (formatetcIn.cfFormat = TClipbrdMonitor.CF_FILEDESCRIPTOR) then
	  begin
	  	var dataSize: size_t := sizeof(FILEGROUPDESCRIPTOR) + (FCount-1) * SizeOf(TFileDescriptor);
	  	var data: HGLOBAL := GlobalAlloc(GMEM_MOVEABLE or GMEM_SHARE or GMEM_ZEROINIT, dataSize);

	  	var files: PFileGroupDescriptor := GlobalLock(data);
      files.cItems := 1;
      files.fgd[0] := FFiles[0].desc;

      for var i := 0 to FCount - 1 do
        if (FFiles[i].desc.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then //Это папка
          if Assigned(FOnGetData) then
            FOnGetData(Self, FUserName);

//      var pFNDest: String;
//      var pSep: Char;
//      pSep := #0; // separator between file names

//      if FCount > 0 then
//      begin
//        for var index: Integer := 0 to FCount - 1 do
//          begin
//            if index < FCount - 1 then
//            begin
//              pFNDest := pFNDest + String(FFiles[Index].desc.cFileName);
//              pFNDest := pFNDest + pSep;
//            end
//            else
//            begin
//              pFNDest := pFNDest + String(FFiles[Index].desc.cFileName);
//              pFNDest := pFNDest + pSep;
////              pFNDest := pFNDest + pSep;
//            end;
//
//  //          Move(Pointer(FFileName)^, files.fgd[index].cFileName[0], Length(FFileName) * SizeOf(Char));
//  //    	  	files.fgd[index].dwFlags := FD_ATTRIBUTES or FD_FILESIZE;
//  //    	  	files.fgd[index].dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
//  //          files.fgd[index].nFileSizeHigh := 0;
//  //    	  	files.fgd[index].nFileSizeLow  := FData.Size;
//          end;

//          files.fgd[0] := FFiles[0].desc;

//          Move(PChar(pFNDest)^, files.fgd[0].cFileName, (Length(pFNDest) + 1) * SizeOf(WideChar));
//      end;

	  	GlobalUnlock(data);

	  	medium.hGlobal := data;
	  	medium.tymed := TYMED_HGLOBAL;
	  	exit(S_OK);
	  end;


  (*
  система сама конвертнет, времени нет реализовывать
	else if (formatetcIn.tymed and TYMED_HGLOBAL <> 1) and
          (formatetcIn.cfFormat = CF_HDROP) then
    begin

		var nBufferSize: Integer := sizeof(TDropFiles) + (FFileName.Length() + 1) * sizeof(Char);
		var pBuffer: TArray<Byte>;
		SetLength(pBuffer, nBufferSize);

		var df: PDropFiles := @pBuffer[0];
		df.pFiles := sizeof(TDropFiles);
		df.fWide := 1;

		var pFilename: PChar := (PChar(@pBuffer[0] + sizeof(TDropFiles)));
    Move(Pointer(FFileName)^, pFilename[0], Length(FFileName) * SizeOf(Char));
		pFilename^ := #0; // separator between file names


		medium.tymed := TYMED_HGLOBAL;
		medium.hGlobal := GlobalAlloc(GMEM_ZEROINIT or GMEM_MOVEABLE or GMEM_DDESHARE, nBufferSize);
		if (medium.hGlobal <> 0) then
		  begin
  			var pMem: Pointer := GlobalLock(medium.hGlobal);
	  		if (pMem <> nil) then
		  		CopyMemory(pMem, @pBuffer[0], nBufferSize);
			  GlobalUnlock(medium.hGlobal);
		  end;
		exit(S_OK);
	end;
  *)
//			CopyMedium(pmedium, m_vecStgMedium[i], m_vecFormatEtc[i]);

	Result := DV_E_FORMATETC;
end;

function TDataObject.GetDataHere(const formatetc: TFormatEtc;
  out medium: TStgMedium): HResult;
begin
  Result := E_NOTIMPL;
end;

function TDataObject.InternalGetName(Index: Integer; out name: string): Boolean;
begin
  name := '';
  if (Index >= 0) and (Index < FCount) then
    name := FFiles[Index].desc.cFileName;
  Result := name <> '';
end;

function TDataObject.Next(celt: Longint; out elt;
  pceltFetched: PLongint): HResult;
var
  FormatEtc: PFormatEtc;
begin
  FormatEtc := PFormatEtc(@Elt);
//---------
 	if (celt <= 0) then
		exit(E_INVALIDARG);
//	if (pceltFetched = nil and celt <> 1) then // pceltFetched can be NULL only for 1 item request
//		exit(E_POINTER);
	if (FormatEtc = nil) then
		exit(E_POINTER);

	if (pceltFetched <> nil) then
		pceltFetched^ := 0;

	if FEnumIndex >= Length(FFormats) then
		exit(S_FALSE);

	var cReturn: ULONG := celt;

	while (FEnumIndex < Length(FFormats)) and (cReturn > 0) do
    begin
      FormatEtc^ := FFormats[FEnumIndex];
      Inc(FormatEtc);
      Inc(FEnumIndex);
      Dec(cReturn);
	  end;

	if (pceltFetched <> nil) then
		pceltFetched^ := celt - cReturn;

  if cReturn = 0 then
    Result := S_OK else
    Result := S_FALSE;
end;

function TDataObject.QueryGetData(const formatetc: TFormatEtc): HResult;
var
  i: Integer;
begin

	if (formatetc.dwAspect and DVASPECT_CONTENT) = 0  then
    begin
  		Result :=  DV_E_DVASPECT;
      exit;
    end;

	for i := 0 to Length(FFormats)-1 do
    begin
  		if (
          (formatetc.tymed = FFormats[i].tymed) and
          (formatetc.cfFormat = FFormats[i].cfFormat)
         ) then
        begin
    			Result :=  S_OK;
          exit;
        end;
    end;

	Result :=  DV_E_TYMED;
end;

procedure TDataObject.ReleaseFiles;
//var
//  i: Integer;
begin
//  for i := 0 to FCount-1 do
//  begin
//    if FFiles[i].data <> nil then
//      case FFiles[i].ownership of
//        soCopied, soOwned: FreeAndNil(FFiles[i].data);
//        soReference: FFiles[i].data := nil;
//      end;
//  end;
  FCount := 0;
  SetLength(FFiles, 0);
end;

function TDataObject.Reset: HResult;
begin
  FEnumIndex := 0;
  Result := S_OK;
end;

function TDataObject.SetData(const formatetc: TFormatEtc;
  var medium: TStgMedium; fRelease: BOOL): HResult;
begin
  Result := E_NOTIMPL;
end;



function TDataObject.Skip(celt: Longint): HResult;
begin
  Result := S_OK;
	if FEnumIndex + celt >= Length(FFormats) then
		Result :=  S_FALSE else
    FEnumIndex := FEnumIndex + celt;
end;

end.
