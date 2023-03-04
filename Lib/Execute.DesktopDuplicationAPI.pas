unit Execute.DesktopDuplicationAPI;
{$INLINE AUTO}
interface

uses
  Winapi.Windows,
  DX12.D3D11,
  DX12.D3DCommon,
  DX12.DXGI,
  DX12.DXGI1_2,
  Vcl.Graphics,
  Math,
  SysUtils,
  rtcDebug;

const TempBuffLen = 100000;

type
{$POINTERMATH ON} // Pointer[x]
  TDesktopDuplicationWrapper = class
  private
    FError: HRESULT;
  // D3D11
    FDevice: ID3D11Device;
    FContext: ID3D11DeviceContext;
    FFeatureLevel: TD3D_FEATURE_LEVEL;
  // DXGI
    FOutput: TDXGI_OUTPUT_DESC;
    FDuplicate: IDXGIOutputDuplication;
    FTexture: ID3D11Texture2D;

    FrameInfo: TDXGI_OUTDUPL_FRAME_INFO;
    Desc: TD3D11_TEXTURE2D_DESC;

    DesktopResource: IDXGIResource;
    FTempTexture: ID3D11Texture2D;

    FScreenWidth, FScreenHeight, FBitsPerPixel : Integer;

    FFullScreen: Boolean;
    FClipRect : TRect;

    FScreenBuff : PByte;

    FDirtyRCnt, FMovedRCnt : Integer;

    TempBuff : array [0..TempBuffLen] of Byte;

    DDExists : Boolean;

    function CreateDD : Boolean;
    procedure DestroyDD;
    function GetScreenInfoChanged: Boolean;
    procedure SetClipRect(const Rect : TRect);
  public
    DirtyR, MovedR : array [0..10000] of TRect;
    MovedRP : array [0..10000] of TPoint;

    constructor Create;
    destructor Destroy; override;
    function DDCaptureScreen : Boolean;
    function DDRecieveRects : Boolean;

    property Error: HRESULT read FError;
    property ScreenWidth : Integer read FScreenWidth;
    property ScreenHeight : Integer read FScreenHeight;
    property BitsPerPixel : Integer read FBitsPerPixel;
    property ScreenInfoChanged : Boolean read GetScreenInfoChanged;
    property FullScreen: Boolean read FFullScreen write FFullScreen;
    property ClipRect : TRect read FClipRect write SetClipRect;
    property ScreenBuff : PByte read FScreenBuff;
    property DirtyRCnt: Integer read FDirtyRCnt write FDirtyRCnt;
    property MovedRCnt: Integer read FMovedRCnt write FMovedRCnt;
  end;

implementation

{ TDesktopDuplicationWrapper }

constructor TDesktopDuplicationWrapper.Create;
begin
  inherited;

  CreateDD;
end;

destructor TDesktopDuplicationWrapper.Destroy;
begin
  inherited;

  DestroyDD;
end;

function TDesktopDuplicationWrapper.CreateDD : Boolean;
var
  GI: IDXGIDevice;
  GA: IDXGIAdapter;
  GO: IDXGIOutput;
  O1: IDXGIOutput1;
begin
  Result := false;
  DDExists := False;

  //!!!!!!!!!!!!!!fTexture := NIL;

  Debug.Log('Creating DesktopDuplication');

  FTexture := NIL;
  FDuplicate := NIL;

  FContext := NIL;

  FDevice := NIL;
  // DGI

  //DXGI_ERROR_SESSION_DISCONNECTED
//  Sleep(10000);
  FError := D3D11CreateDevice(
    nil, // Default adapter
    D3D_DRIVER_TYPE_HARDWARE, // A hardware driver, which implements Direct3D features in hardware.
    0,
    Ord(D3D11_CREATE_DEVICE_SINGLETHREADED),
    nil, 0, // default feature
    D3D11_SDK_VERSION,
    FDevice,
    FFeatureLevel,
    FContext
  );

  if Failed(FError) then
  begin
    Debug.Log('D3D11CreateDevice Error: ' + IntToStr(FError));//SysErrorMessage(FError));
    Exit;
  end;

  Debug.Log('FDevice.QueryInterface(IID_IDXGIDevice, GI)');
  FError := FDevice.QueryInterface(IID_IDXGIDevice, GI);
  if Failed(FError) then
  begin
    Debug.Log('QueryInterface IID_IDXGIDevice Error: ' + IntToStr(FError));
    Exit;
  end;

  Debug.Log('GI.GetParent(IID_IDXGIAdapter, Pointer(GA)');
  FError := GI.GetParent(IID_IDXGIAdapter, Pointer(GA));
  if Failed(FError) then
  begin
    Debug.Log('GI.GetParent Error: ' + IntToStr(FError));
    Exit;
  end;

  Debug.Log('GA.EnumOutputs(0, GO)');
  FError := GA.EnumOutputs(0, GO);
  if Failed(FError) then
  begin
    Debug.Log('EnumOutputs Error: ' + IntToStr(FError));
    Exit;
  end;

  Debug.Log('GO.GetDesc(FOutput)');
  FError := GO.GetDesc(FOutput);
  if Failed(FError) then
  begin
    Debug.Log('GetDesc Error: ' + IntToStr(FError));
    Exit;
  end;

  Debug.Log('GO.QueryInterface(IID_IDXGIOutput1, O1)');
  FError := GO.QueryInterface(IID_IDXGIOutput1, O1);
  if Failed(FError) then
  begin
    Debug.Log('QueryInterface IID_IDXGIOutput1 Error: '
      + IntToStr(FError));
    Exit;
  end;

  Debug.Log('O1.DuplicateOutput(FDevice, FDuplicate) '
    + IntToStr(Integer(O1)) + ' ' + IntToStr(Integer(FDevice)));
  FError := O1.DuplicateOutput(FDevice, FDuplicate);
  if Failed(FError) then
  begin
    Debug.Log('DuplicateOutput Error: ' +
      IntToStr(FError));
    Exit;
  end;
  // DXGI_ERROR_NOT_CURRENTLY_AVAILABLE
   // E_ACCESSDENIED
  Debug.Log('DesktopDupilcation object created');
  DDExists := true;
  Result := True;
end;

procedure TDesktopDuplicationWrapper.DestroyDD;
begin
  DDExists := false;

  if (FContext <> NIL) and (FTexture <> NIL) then
    FContext.Unmap(FTexture, 0);

  FTexture := nil;

  FTempTexture := NIL;
  DesktopResource := NIL;

//  if Assigned(FTexture) then
//  begin
//    FContext.Unmap(FTexture, 0); //Это нужно?
//    FTexture := NIL;
//  end;
  if Assigned(FDuplicate) then
  begin
    FDuplicate.ReleaseFrame;
    FDuplicate := NIL;
  end;
end;

function TDesktopDuplicationWrapper.DDCaptureScreen : Boolean;
var
 // DesktopResource: IDXGIResource;
 // Desc: TD3D11_TEXTURE2D_DESC;
 // Temp: ID3D11Texture2D;
  Resource: TD3D11_MAPPED_SUBRESOURCE;
  BadAttempt: Boolean;
  AttemptId: Integer;
  ResourceDesc: TDXGI_OUTDUPL_DESC;
  time: DWORD;
 // BufLen : Integer;
  label CaptureStart, ErrorInCapture, FailedCapture, AttemptFinish;
begin
  Debug.Log('Capturing screen');
  time := GetTickCount;

  BadAttempt := false;
  AttemptId := 1;

//  if (not DDExists) or (not DDCaptureScreen) or (not DDRecieveRects) then
//  if (not CreateDD) or (not DDCaptureScreen) or (not DDRecieveRects) then
 // begin
  //  Result := false;
  //end;
 //fNeedRecreate := False;
  if not DDExists then goto ErrorInCapture;

  CaptureStart:

  if FDuplicate = nil then goto ErrorInCapture;
  //else
   // FDuplicate.ReleaseFrame;

  //Sleep(1);


  FDuplicate.ReleaseFrame;
  Sleep(1);
  FError := FDuplicate.AcquireNextFrame(50, FrameInfo, DesktopResource);
  if Failed(FError) then
  begin
    Debug.Log('AcquireNextFrame Error: ' + IntToStr(FError));
//    if FError = DXGI_ERROR_ACCESS_LOST then
   //   fNeedRecreate := True;
    goto ErrorInCapture;
  end;

  //if FrameInfo.TotalMetadataBufferSize <= 0 then Exit;

  //if FTexture <> nil then
    FTexture := nil;

  FError := DesktopResource.QueryInterface(IID_ID3D11Texture2D, FTexture);
  DesktopResource := nil;
  if Failed(FError) then
  begin
    Debug.Log('QueryInterface.IID_ID3D11Texture2D Error: ' + IntToStr(FError));
    goto ErrorInCapture;
  end;

  FTexture.GetDesc(Desc);

  FDuplicate.GetDesc(ResourceDesc);

  ZeroMemory(@Desc, SizeOf(Desc));
  Desc.Width := ResourceDesc.ModeDesc.Width;
  Desc.Height := ResourceDesc.ModeDesc.Height;
  Desc.MipLevels := 1;
  Desc.ArraySize := 1;
  Desc.Format := DXGI_FORMAT_B8G8R8A8_TYPELESS;
  Desc.SampleDesc.Count := 1;
  Desc.Usage := D3D11_USAGE_STAGING;
  Desc.BindFlags := 0;
  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_READ) or Ord(D3D11_CPU_ACCESS_WRITE);
  Desc.MiscFlags := 0;

//  Desc.BindFlags := 0;
////  Desc.Format := DXGI_FORMAT_B8G8R8X8_TYPELESS; //DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
//  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_READ) or Ord(D3D11_CPU_ACCESS_WRITE);
//  Desc.Usage := D3D11_USAGE_STAGING;
//  Desc.MiscFlags := 0;

  //  READ/WRITE texture
  FError := FDevice.CreateTexture2D(@Desc, nil, FTempTexture);
  if Failed(FError) then
  begin
    Debug.Log('CreateTexture2D Error: ' + IntToStr(FError));
   // FTexture := nil;
   // FDuplicate.ReleaseFrame;

    goto ErrorInCapture;
  end;

  // copy original to the RW texture
  FContext.CopyResource(FTempTexture, FTexture);
  if Failed(FError) then
  begin
    Debug.Log('FContext.CopyResource Error: ' + IntToStr(FError));

    goto ErrorInCapture;
  end;

  // get texture bits
  FError := FContext.Map(FTempTexture, 0, D3D11_MAP_READ_WRITE, 0, Resource);
  if Failed(FError) then
  begin
    Debug.Log('FContext.Map Error: ' + IntToStr(FError));
  //  FTexture := nil;
    //FDuplicate.ReleaseFrame;

    goto ErrorInCapture;
  end;

 // CheckScreenInfo(@Desc);

  //Result := false;

  FScreenBuff := Resource.pData;
 // getmem(ScreenBuff, 1920 * 1090 * 4);
  //Move(Resource.pData^, ScreenBuff^, 1280 * 1024 * 4);
 // ScreenBuff^:= 0;

  if not DDRecieveRects then ;//goto ErrorInCapture;

AttemptFinish:
  if BadAttempt then
  begin
    if (FContext <> NIL) and (FTexture <> NIL) then FContext.Unmap(FTexture, 0); //
    FTexture := nil;

    FTempTexture := NIL;
    DesktopResource := NIL;

  if AttemptId > 1 then goto FailedCapture;

    Inc(AttemptId);
    BadAttempt := false;

    if not CreateDD then goto FailedCapture;

    goto CaptureStart;
  end;

  Result := true;
  time := GetTickCount - time;
  Debug.Log('cap time: ' + IntToStr(time));
  Debug.Log('Screen successfully captured');

  Exit;

ErrorInCapture:
  BadAttempt := true;
  goto AttemptFinish;

FailedCapture:
  Debug.Log('Failed to capture screen');
  Result := false;
end;

function TDesktopDuplicationWrapper.DDRecieveRects : Boolean;
var
  i, j, S1, S2, SU, SI : Integer;
  BytesRecieved : UInt;
  RctU, RctI : TRect;

  PMoveRect : PDXGI_OUTDUPL_MOVE_RECT;
  PDirtyRect : PRECT;

  CLeft, CTop, CRight, CBottom : Boolean;
  time: DWORD;
begin
  Result := true;
  time := GetTickCount;

  {if FrameInfo.TotalMetadataBufferSize <= 0 then
  begin
    FMovedRCnt := 0;
    FDirtyRCnt := 0;
    Exit;
  end;}

  // Получаем MoveRects и зансоим их в FChangeRects
  FError := FDuplicate.GetFrameMoveRects(TempBuffLen,
        PDXGI_OUTDUPL_MOVE_RECT(@TempBuff[0]), BytesRecieved);
  if Failed(FError) then
  begin
    //Result := false;
   // Exit;
    FMovedRCnt := 0;
  end else FMovedRCnt := (BytesRecieved div SizeOf(TDXGI_OUTDUPL_MOVE_RECT));

  for i := 0 to FMovedRCnt - 1 do
  begin
    PMoveRect := PDXGI_OUTDUPL_MOVE_RECT(@TempBuff[0]) + i;
  {  ChangedRects[ChangedRectsCnt] := TRect.Create(TPoint.Create(PMoveRect.SourcePoint.X, PMoveRect.SourcePoint.Y),
    PMoveRect.DestinationRect.Right - PMoveRect.DestinationRect.Left,
    PMoveRect.DestinationRect.Bottom - PMoveRect.DestinationRect.Top);
    ChangedRects[ChangedRectsCnt + 1] := TRect.Create(PMoveRect.DestinationRect.Left, PMoveRect.DestinationRect.Top,
    PMoveRect.DestinationRect.Right, PMoveRect.DestinationRect.Bottom);
    Inc(ChangedRectsCnt, 2);}
    with PMoveRect^ do
    begin
      MovedR[i] := DestinationRect;//TRect.Create(DestinationRect.Left,
       // DestinationRect.Top, DestinationRect.Right, DestinationRect.Bottom);
      MovedRP[i] := SourcePoint;//TPoint.Create(PMoveRect.SourcePoint.X,
     //   PMoveRect.SourcePoint.Y
    end;

  end;


  // Получаем DirtyRects и зансоим их в FChangeRects
  FDuplicate.GetFrameDirtyRects(TempBuffLen, PRECT(@TempBuff[0]), BytesRecieved);
  if Failed(FError) then
  begin
    //Result := false;
    FDirtyRCnt := 0;
//    Exit;
  end else FDirtyRCnt := (BytesRecieved div SizeOf(TRECT));

 // Result := true;

  FDirtyRCnt := (Integer(BytesRecieved) div SizeOf(TRECT));
  for i := 0 to FDirtyRCnt - 1 do
  begin
    PDirtyRect := PRECT(@TempBuff[0]) + i;
    with PDirtyRect^ do
    begin
      DirtyR[i] := TRect.Create(Left, Top, Right, Bottom);
      Debug.Log('DirtyRect recieved (' + IntToStr(Left)
         + ', ' + IntToStr(Top) + ', ' + IntToStr(Right)
         + ', ' + IntToStr(Bottom) + ')');
    end;
  end;

  // Отсекаем части прямоугольников из DirtyRecs, выходящие за ClipRect
  if (ClipRect.Width <> 0) and (ClipRect.Height <> 0) then
    for i := 0 to FDirtyRCnt - 1 do
      DirtyR[i] := TRect.Intersect(DirtyR[i], ClipRect);

  time := GetTickCount - time;
  Debug.Log('enc time: ' + IntToStr(time));

  Exit;//!!!!!!!!!!!!!!!!!!!!!!!!
  // Если при перемещении областей MoveR часть окна попала из невидимой
  // зоны в видимую то эту часть нужно добавить в DirtyR
  // Если движение было по диагонали добавляем 3 прямоуголника, иначе 1

  for i := 0 to FMovedRCnt - 1 do
    with MovedR[i], MovedRP[i] do
    begin
      CLeft := (X < Left) and (X < ClipRect.Left); // нужно перерисовать область слева от окна
      CTop := (Y < Top) and (Y < ClipRect.Top); // сверху
      CRight := (X >= Left) and (X + Width >= ClipRect.Right); // справа
      CBottom := (Y >= Bottom) and (Y + Height >= ClipRect.Bottom); // снизу

      // Горизонтальные или вертикальные области по боковым граням окна
      if CLeft then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(ClipRect.Left, Top,
          ClipRect.Left + Left - X + 1, Bottom);
        Inc(FDirtyRCnt);
      end;
      if CTop then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(Left, ClipRect.Top,
          Right, ClipRect.Top + Top - Y + 1);
        Inc(FDirtyRCnt);
      end;
      if CRight then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(ClipRect.Right - (X - Left) - 1,
          Top, ClipRect.Right, Bottom);
        Inc(FDirtyRCnt);
      end;
      if CBottom then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(Left, ClipRect.Bottom - (Y - Bottom) - 1,
          Right, ClipRect.Bottom);
        Inc(FDirtyRCnt);
      end;

      // Пересечение горизонтальных и вертикальных областей
      // нужно если перемещение было по обоим осям сразу
      if CLeft and CTop then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(ClipRect.Left, ClipRect.Top,
          ClipRect.Left + Left - X, ClipRect.Top + Top - Y);
        Inc(FDirtyRCnt);
      end;
      if CLeft and CBottom then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(ClipRect.Left,
          ClipRect.Bottom - (Y - Top) - 1,
          ClipRect.Left + Left - X, ClipRect.Bottom);
        Inc(FDirtyRCnt);
      end;
      if CRight and CTop then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(ClipRect.Right - (X - Left) - 1,
          ClipRect.Top, ClipRect.Right, ClipRect.Top + Top - Y);
        Inc(FDirtyRCnt);
      end;
      if CRight and CBottom then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(ClipRect.Right - (X - Left) - 1,
          ClipRect.Bottom - (Y - Top) - 1, ClipRect.Right, ClipRect.Bottom);
        Inc(FDirtyRCnt);
      end;

      // Корректируем MoveR и MoveRP чтобы они не выходили за ClipRect
      if CLeft then begin Left := ClipRect.Left + Left - X; X := ClipRect.Left; end;
      if CTop then begin Top := ClipRect.Top + Top - Y; Y := ClipRect.Top; end;
      if CRight then begin Right := ClipRect.Right - (X - Left); X := ClipRect.Left + (X - Left); end;
      if CBottom then begin Bottom := ClipRect.Bottom - (Y - Bottom); Y := ClipRect.Top + (Y - Top); end;
    end;


  // Обьеденяем прямоугольники из ChangedRects если их площадь пересечения велика
 { for i := 0 to ChangedRectsCnt - 1 do
  begin
    j := i + 1;
    while j < ChangedRectsCnt do
    begin
      RctU := TRect.Union(ChangedRects[i], ChangedRects[j]);
      RctI := TRect.Intersect(ChangedRects[i], ChangedRects[j]);

      S1 := ChangedRects[i].Width * ChangedRects[i].Height;
      S2 := ChangedRects[j].Width * ChangedRects[j].Height;
      SU := RctU.Width * RctU.Height; SI := RctI.Width * RctI.Height;

      if SU - (S1 + S2) > SI then
      begin
        Inc(j);
        continue; // Площадь пересечения двух прямоугольников мала
      end;
          // Площадь пересечения двух прямоугольников велика
          // Заносим в i-ый прямоугольник прямоугольник обьединения i и j
          // j-ый прямоугольник удаляем
      ChangedRects[i] := RctU;

      Move(ChangedRects[j + 1], ChangedRects[j],
        (ChangedRectsCnt - j - 1) * SizeOf(TRect));

      Dec(ChangedRectsCnt);
    end;
  end; }
  Result := true;
  time := GetTickCount - time;
  Debug.Log('enc time: ' + IntToStr(time));
end;

function TDesktopDuplicationWrapper.GetScreenInfoChanged: Boolean;
var
  NewBitsPerPixel : Integer;
begin
  Result := false;

  if FScreenWidth <> Desc.Width then
  begin
    FScreenWidth := Desc.Width;
    Result := true;
  end;

  if FScreenHeight <> Desc.Height then
  begin
    FScreenHeight := Desc.Height;
    Result := true;
  end;

  if Result and FFullScreen then
    FClipRect := TRect.Create(0, 0, FScreenWidth, FScreenHeight);

  case Desc.Format of
    DXGI_FORMAT_R8G8B8A8_TYPELESS,
    DXGI_FORMAT_R8G8B8A8_UNORM,
    DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
    DXGI_FORMAT_R8G8B8A8_UINT,
    DXGI_FORMAT_R8G8B8A8_SNORM,
    DXGI_FORMAT_R8G8B8A8_SINT,
    DXGI_FORMAT_B8G8R8A8_UNORM,
    DXGI_FORMAT_B8G8R8X8_UNORM,
    DXGI_FORMAT_B8G8R8A8_TYPELESS,
    DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
    DXGI_FORMAT_B8G8R8X8_TYPELESS,
    DXGI_FORMAT_B8G8R8X8_UNORM_SRGB : NewBitsPerPixel := 32;
  end;
  if FBitsPerPixel <> NewBitsPerPixel then
  begin
    FBitsPerPixel := NewBitsPerPixel;
    Result := true;
  end;
end;

procedure TDesktopDuplicationWrapper.SetClipRect(const Rect : TRect);
begin
  if (Rect.Width = 0) or (Rect.Height = 0) then
  begin
    FullScreen := true;
    FClipRect := TRect.Create(0, 0, FScreenWidth, FScreenHeight);
  end else
  begin
    FullScreen := false;
    FClipRect := Rect;
  end;
end;

end.
