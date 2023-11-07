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
  rtcDebug,
  SyncObjs;

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

    FMouseFlags, FMouseCursor: Integer;

    FFullScreen: Boolean;

    FScreenBuff : PByte;

    FDirtyRCnt, FMovedRCnt : Integer;

    TempBuff : array [0..TempBuffLen] of Byte;

    FAdapterName: String;

    light_black: Boolean;
    desk_pixel_color: Cardinal;
    DDExists : Boolean;

    function CreateDD : Boolean;
    function GetScreenInfoChanged: Boolean;
  public
    pScreenWidth, pScreenHeight, pBitsPerPixel, pClipRect: Pointer;
    DirtyR, MovedR : array [0..10000] of TRect;
    MovedRP : array [0..10000] of TPoint;

    constructor Create;
    destructor Destroy; override;
    function DDCaptureScreen: Boolean;
    function DDReceiveRects: Boolean;
    procedure DestroyDD;

    function InvertColor(clr: TColor): TColor;
    procedure SetAdapter(AdapterName: String);

    property Error: HRESULT read FError;
    property MouseFlags : Integer read FMouseFlags;
    property MouseCursor : Integer read FMouseCursor;
    property ScreenInfoChanged : Boolean read GetScreenInfoChanged;
    property FullScreen: Boolean read FFullScreen write FFullScreen;
    property ScreenBuff : PByte read FScreenBuff;
    property DirtyRCnt: Integer read FDirtyRCnt write FDirtyRCnt;
    property MovedRCnt: Integer read FMovedRCnt write FMovedRCnt;
  end;

const
  ERROR_WAIT_TIMEOUT = -2005270489;

var
  DDExists_CS: TCriticalSection;

implementation

{ TDesktopDuplicationWrapper }

procedure TDesktopDuplicationWrapper.SetAdapter(AdapterName: String);
begin
  if FAdapterName <> AdapterName then
  begin
    FAdapterName := AdapterName;
    DDExists_CS.Acquire;
    try
      DDExists := False;
    finally
      DDExists_CS.Release;
    end;
  end;
end;

constructor TDesktopDuplicationWrapper.Create;
begin
  inherited;

  FFullScreen := True;

  CreateDD;
end;

destructor TDesktopDuplicationWrapper.Destroy;
begin
  inherited;

  DestroyDD;
end;

function TDesktopDuplicationWrapper.CreateDD : Boolean;
var
  Factory: IDXGIFactory;
  Adapter: IDXGIAdapter;
  AdapterIndex: UINT;
  AdapterDesc: TDXGI_ADAPTER_DESC;
  DriverType: TD3D_DRIVER_TYPE;
  GI: IDXGIDevice;
  GA: IDXGIAdapter;
  GO: IDXGIOutput;
  O1: IDXGIOutput1;
begin
  Result := False;

  DDExists_CS.Acquire;
  try
    DDExists := False;
  finally
    DDExists_CS.Release;
  end;

  //!!!!!!!!!!!!!!fTexture := NIL;

  Debug.Log('Creating DesktopDuplication');

  FTexture := nil;
  FDuplicate := nil;
  FContext := nil;
  FDevice := nil;
  Adapter := nil;

  if FAdapterName <> '' then
  begin
    DriverType := D3D_DRIVER_TYPE_HARDWARE;

    // Создаем экземпляр IDXGIFactory1 для доступа к адаптерам
    if Succeeded(CreateDXGIFactory(IID_IDXGIFactory, Factory)) then
    begin
      // Перечисляем доступные адаптеры
      AdapterIndex := 0;
      while Factory.EnumAdapters(AdapterIndex, Adapter) = S_OK do
      begin
        // В этой части можно получать информацию о каждом адаптере, если необходимо
        Adapter.GetDesc(AdapterDesc);
        if WideCompareText(AdapterDesc.Description, FAdapterName) = 0 then
        begin
          {$R-}
          Debug.Log('Set adapter: ' + FAdapterName);
          {$R+}
          Break;
        end;

        Inc(AdapterIndex);
      end;
    end
    else
    begin
      {$R-}
      Debug.Log('Error creating IDXGIFactory');
      {$R+}

      Exit;
    end;
  end
  else
  begin
    Adapter := nil;
    DriverType := D3D_DRIVER_TYPE_HARDWARE;

    {$R-}
    Debug.Log('Set adapter: Default');
    {$R+}
  end;

  //DXGI_ERROR_SESSION_DISCONNECTED
//  Sleep(10000);
  FError := D3D11CreateDevice(
    Adapter, //Adapter, // Адаптер, nil для использования "первого" адаптера
    DriverType, //D3D_DRIVER_TYPE_UNKNOWN, //D3D_DRIVER_TYPE_HARDWARE, // Тип драйвера (или D3D_DRIVER_TYPE_WARP для WARP-устройства)
    0, // Software Rasterizer, 0 или D3D11_CREATE_DEVICE_SOFTWARE_ADAPTER
    Ord(D3D11_CREATE_DEVICE_SINGLETHREADED), //D3D11_CREATE_DEVICE_DEBUG // Флаги создания
    nil, // Массив поддерживаемых версий
    0, // Количество элементов в массиве поддерживаемых версий
    D3D11_SDK_VERSION, // Версия SDK
    FDevice, // Указатель на созданное устройство
    FFeatureLevel, // Поддерживаемый уровень функций
    FContext // Указатель на контекст устройства
  );

  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('D3D11CreateDevice Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;

  Debug.Log('FDevice.QueryInterface(IID_IDXGIDevice, GI)');
  FError := FDevice.QueryInterface(IID_IDXGIDevice, GI);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('QueryInterface IID_IDXGIDevice Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;

  Debug.Log('GI.GetParent(IID_IDXGIAdapter, Pointer(GA)');
  FError := GI.GetParent(IID_IDXGIAdapter, Pointer(GA));
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('GI.GetParent Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;

  Debug.Log('GA.EnumOutputs(0, GO)');
  FError := GA.EnumOutputs(0, GO);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('EnumOutputs Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;

  Debug.Log('GO.GetDesc(FOutput)');
  FError := GO.GetDesc(FOutput);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('GetDesc Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;

  Debug.Log('GO.QueryInterface(IID_IDXGIOutput1, O1)');
  FError := GO.QueryInterface(IID_IDXGIOutput1, O1);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('QueryInterface IID_IDXGIOutput1 Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;

  Debug.Log('O1.DuplicateOutput(FDevice, FDuplicate) ' + IntToStr(Integer(O1)) + ' ' + IntToStr(Integer(FDevice)));
  FError := O1.DuplicateOutput(FDevice, FDuplicate);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('DuplicateOutput Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
    Exit;
  end;
  // DXGI_ERROR_NOT_CURRENTLY_AVAILABLE
   // E_ACCESSDENIED
  Debug.Log('DesktopDupilcation object created');

  DDExists_CS.Acquire;
  try
    DDExists := True;
  finally
    DDExists_CS.Release;
  end;

  Result := True;
end;

procedure TDesktopDuplicationWrapper.DestroyDD;
begin
  DDExists_CS.Acquire;
  try
    DDExists := False;
  finally
    DDExists_CS.Release;
  end;

  if (FContext <> nil) and (FTexture <> nil) then
    FContext.Unmap(FTexture, 0);

  FTexture := nil;
  FTempTexture := nil;
  DesktopResource := nil;

//  if Assigned(FTexture) then
//  begin
//    FContext.Unmap(FTexture, 0); //Это нужно?
//    FTexture := NIL;
//  end;
  if Assigned(FDuplicate) then
  begin
    FDuplicate.ReleaseFrame;
    FDuplicate := nil;
  end;
end;

function TDesktopDuplicationWrapper.InvertColor(clr: TColor): TColor;
begin
  Result := RGB(
    255 - GetRValue(clr),
    255 - GetGValue(clr),
    255 - GetBValue(clr));
end;

function TDesktopDuplicationWrapper.DDCaptureScreen: Boolean;
var
 // DesktopResource: IDXGIResource;
 // Desc: TD3D11_TEXTURE2D_DESC;
 // Temp: ID3D11Texture2D;
  Resource: TD3D11_MAPPED_SUBRESOURCE;
  BadAttempt: Boolean;
  AttemptId: Integer;
  ResourceDesc: TDXGI_OUTDUPL_DESC;
  time: DWORD;
  desk_dc: HDC;
  mDDExists: Boolean;
 // BufLen : Integer;
  label CaptureStart, ErrorInCapture, FailedCapture, AttemptFinish;
begin
  Debug.Log('Capturing screen');
  time := GetTickCount;

  BadAttempt := False;
  AttemptId := 1;

//  if (not DDExists) or (not DDCaptureScreen) or (not DDReceiveRects) then
//  if (not CreateDD) or (not DDCaptureScreen) or (not DDReceiveRects) then
 // begin
  //  Result := False;
  //end;
 //fNeedRecreate := False;
  DDExists_CS.Acquire;
  try
    mDDExists := DDExists;
  finally
    DDExists_CS.Release;
  end;
  if not mDDExists then
  begin
    Debug.Log('DD is not exists');

    goto ErrorInCapture;
  end;

  CaptureStart:

  if FDuplicate = nil then
    goto ErrorInCapture;
  //else
   // FDuplicate.ReleaseFrame;

  //Sleep(1);


  FDuplicate.ReleaseFrame;
//  Sleep(1);
  FError := FDuplicate.AcquireNextFrame(10, FrameInfo, DesktopResource);
  if FError = ERROR_WAIT_TIMEOUT then //Изменений нет
  begin
//    if not CreateDD then
//    begin
//      goto FailedCapture;
    FDirtyRCnt := 0;
    FMovedRCnt := 0;

    Result := True;
    time := GetTickCount - time;
    Debug.Log('cap time: ' + IntToStr(time));
    Debug.Log('AcquireNextFrame ERROR_WAIT_TIMEOUT');

    Exit;
//    end;
  end
  else
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('AcquireNextFrame Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
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
    {$R-}
    Debug.Log('QueryInterface.IID_ID3D11Texture2D Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}

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

//  desk_dc := GetDC(0); //рисую пиксель в левом нижнем углу экрана
//  desk_pixel_color := InvertColor(desk_pixel_color);
//  SetPixel(desk_dc, 0, Desc.Height, desk_pixel_color);
//  ReleaseDC(0, desk_dc);

//  Desc.BindFlags := 0;
////  Desc.Format := DXGI_FORMAT_B8G8R8X8_TYPELESS; //DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
//  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_READ) or Ord(D3D11_CPU_ACCESS_WRITE);
//  Desc.Usage := D3D11_USAGE_STAGING;
//  Desc.MiscFlags := 0;

  //  READ/WRITE texture
  FError := FDevice.CreateTexture2D(@Desc, nil, FTempTexture);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('CreateTexture2D Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
   // FTexture := nil;
   // FDuplicate.ReleaseFrame;

    goto ErrorInCapture;
  end;

  // copy original to the RW texture
  FContext.CopyResource(FTempTexture, FTexture);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('FContext.CopyResource Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}

    goto ErrorInCapture;
  end;

  // get texture bits
  FError := FContext.Map(FTempTexture, 0, D3D11_MAP_READ_WRITE, 0, Resource);
  if Failed(FError) then
  begin
    {$R-}
    Debug.Log('FContext.Map Error: ' + IntToStr(FError) + ': ' + SysErrorMessage(FError));
    {$R+}
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

//  if not DDReceiveRects then ;//goto ErrorInCapture;

  if {(not DDExists) or (not DDCaptureScreen) or} (not DDReceiveRects) then
//  if (not CreateDD) or (not DDCaptureScreen) or (not DDReceiveRects) then
  begin
    Debug.Log('Rects is not received');
    Result := False;
  end;

AttemptFinish:
  if BadAttempt then
  begin
    if (FContext <> nil) and (FTexture <> nil) then
      FContext.Unmap(FTexture, 0);
    FTexture := nil;

    FTempTexture := nil;
    DesktopResource := nil;

  if AttemptId > 1 then
    goto FailedCapture;

    Inc(AttemptId);
    BadAttempt := False;

    if not CreateDD then
      goto FailedCapture;

    goto CaptureStart;
  end;

  Result := True;
  time := GetTickCount - time;
  Debug.Log('cap time: ' + IntToStr(time));
  Debug.Log('Screen successfully captured');

  Exit;

ErrorInCapture:
  BadAttempt := True;
  goto AttemptFinish;

FailedCapture:
  Debug.Log('Failed to capture screen');
  Result := False;
end;

function TDesktopDuplicationWrapper.DDReceiveRects: Boolean;
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
  end
  else
    FMovedRCnt := (BytesRecieved div SizeOf(TDXGI_OUTDUPL_MOVE_RECT));

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
  if (PRect(pClipRect)^.Width <> 0) and (PRect(pClipRect)^.Height <> 0) then
    for i := 0 to FDirtyRCnt - 1 do
      DirtyR[i] := TRect.Intersect(DirtyR[i], PRect(pClipRect)^);

  time := GetTickCount - time;
  Debug.Log('enc time: ' + IntToStr(time));

  Exit;//!!!!!!!!!!!!!!!!!!!!!!!!
  // Если при перемещении областей MoveR часть окна попала из невидимой
  // зоны в видимую то эту часть нужно добавить в DirtyR
  // Если движение было по диагонали добавляем 3 прямоуголника, иначе 1

  for i := 0 to FMovedRCnt - 1 do
    with MovedR[i], MovedRP[i] do
    begin
      CLeft := (X < Left) and (X < PRect(pClipRect)^.Left); // нужно перерисовать область слева от окна
      CTop := (Y < Top) and (Y < PRect(pClipRect)^.Top); // сверху
      CRight := (X >= Left) and (X + Width >= PRect(pClipRect)^.Right); // справа
      CBottom := (Y >= Bottom) and (Y + Height >= PRect(pClipRect)^.Bottom); // снизу

      // Горизонтальные или вертикальные области по боковым граням окна
      if CLeft then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(PRect(pClipRect)^.Left, Top,
          PRect(pClipRect)^.Left + Left - X + 1, Bottom);
        Inc(FDirtyRCnt);
      end;
      if CTop then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(Left, PRect(pClipRect)^.Top,
          Right, PRect(pClipRect)^.Top + Top - Y + 1);
        Inc(FDirtyRCnt);
      end;
      if CRight then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(PRect(pClipRect)^.Right - (X - Left) - 1,
          Top, PRect(pClipRect)^.Right, Bottom);
        Inc(FDirtyRCnt);
      end;
      if CBottom then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(Left, PRect(pClipRect)^.Bottom - (Y - Bottom) - 1,
          Right, PRect(pClipRect)^.Bottom);
        Inc(FDirtyRCnt);
      end;

      // Пересечение горизонтальных и вертикальных областей
      // нужно если перемещение было по обоим осям сразу
      if CLeft and CTop then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(PRect(pClipRect)^.Left, PRect(pClipRect)^.Top,
          PRect(pClipRect)^.Left + Left - X, PRect(pClipRect)^.Top + Top - Y);
        Inc(FDirtyRCnt);
      end;
      if CLeft and CBottom then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(PRect(pClipRect)^.Left,
          PRect(pClipRect)^.Bottom - (Y - Top) - 1,
          PRect(pClipRect)^.Left + Left - X, PRect(pClipRect)^.Bottom);
        Inc(FDirtyRCnt);
      end;
      if CRight and CTop then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(PRect(pClipRect)^.Right - (X - Left) - 1,
          PRect(pClipRect)^.Top, PRect(pClipRect)^.Right, PRect(pClipRect)^.Top + Top - Y);
        Inc(FDirtyRCnt);
      end;
      if CRight and CBottom then
      begin
        DirtyR[FDirtyRCnt] := TRect.Create(PRect(pClipRect)^.Right - (X - Left) - 1,
          PRect(pClipRect)^.Bottom - (Y - Top) - 1, PRect(pClipRect)^.Right, PRect(pClipRect)^.Bottom);
        Inc(FDirtyRCnt);
      end;

      // Корректируем MoveR и MoveRP чтобы они не выходили за ClipRect
      if CLeft then begin Left := PRect(pClipRect)^.Left + Left - X; X := PRect(pClipRect)^.Left; end;
      if CTop then begin Top := PRect(pClipRect)^.Top + Top - Y; Y := PRect(pClipRect)^.Top; end;
      if CRight then begin Right := PRect(pClipRect)^.Right - (X - Left); X := PRect(pClipRect)^.Left + (X - Left); end;
      if CBottom then begin Bottom := PRect(pClipRect)^.Bottom - (Y - Bottom); Y := PRect(pClipRect)^.Top + (Y - Top); end;
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
  Result := False;

  if PInteger(pScreenWidth)^ <> Desc.Width then
  begin
    PInteger(pScreenWidth)^ := Desc.Width;
    Result := True;
  end;

  if PInteger(pScreenHeight)^ <> Desc.Height then
  begin
    PInteger(pScreenHeight)^ := Desc.Height;
    Result := True;
  end;

  if Result and FFullScreen then
    PRect(pClipRect)^ := TRect.Create(0, 0, PInteger(pScreenWidth)^, PInteger(pScreenHeight)^);

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
  if PInteger(pBitsPerPixel)^ <> NewBitsPerPixel then
  begin
    PInteger(pBitsPerPixel)^ := NewBitsPerPixel;
    Result := True;
  end;
end;

//procedure TDesktopDuplicationWrapper.SetClipRect(const Rect : TRect);
//begin
//  if (Rect.Width = 0) or (Rect.Height = 0) then
//  begin
//    FullScreen := True;
//    PRect(pClipRect)^ := TRect.Create(0, 0, PInteger(pScreenWidth)^, PInteger(pScreenHeight)^);
//  end
//  else
//  begin
//    FullScreen := False;
//    PRect(pClipRect)^ := Rect;
//  end;
//end;

initialization
  DDExists_CS := TCriticalSection.Create;

finalization
  DDExists_CS.Free;

end.
