unit AcceleratedPaintBox;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls,

  Vcl.Direct2D, D2D1;

type

  TDirect2DCanvasHelper = class helper for Vcl.Direct2D.TDirect2DCanvas
    function GetRender: ID2D1RenderTarget;
    procedure SetRender(const v: ID2D1RenderTarget);
    function GetWnd: HWND;
  end;

  TDirect2DCanvas = class(Vcl.Direct2D.TDirect2DCanvas)
  private
    FInit: Boolean;
  protected
      procedure RequiredState(ReqState: TCanvasState); override;
      procedure CreateRenderTarget;
  public
      procedure Clear(Color: TColor);
  end;

  TCustomAcceleratedPaintBox = class(TCustomControl)
  private
    FOnPaint: TNotifyEvent;
    FUseD2D: Boolean;
    FD2DCanvas: TDirect2DCanvas;

    function CreateD2DCanvas: Boolean;

    { Catching paint events }
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;

    { Set/Get stuff }
    procedure SetAccelerated(const Value: Boolean);
    function GetGDICanvas: TCanvas;
    function GetOSCanvas: TCustomCanvas;
  protected
    procedure CreateWnd; override;
    procedure Paint; override;


  public
    { Life-time management }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    { Public properties }
    property Accelerated: Boolean read FUseD2D write SetAccelerated;
    property Canvas: TCustomCanvas read GetOSCanvas;
    property GDICanvas: TCanvas read GetGDICanvas;
    property D2DCanvas: TDirect2DCanvas read FD2DCanvas;

    { The Paint event }
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  published
    property ParentColor;
    property OnMouseMove;
  end;
implementation
uses
  Winapi.DxgiFormat, Winapi.UxTheme, System.Win.ComObj, System.Types,
  System.UITypes, System.Math, Vcl.Forms, Vcl.Consts, WinApi.Wincodec;
{ TCustomAcceleratedPaintBox }

constructor TCustomAcceleratedPaintBox.Create(AOwner: TComponent);
begin
  inherited;

end;

function TCustomAcceleratedPaintBox.CreateD2DCanvas: Boolean;
begin
   try
     FD2DCanvas := TDirect2DCanvas.Create(Handle);
   except
     { Failed creating the D2D canvas, halt! }
     Exit(false);
   end;

   Result := true;
end;

procedure TCustomAcceleratedPaintBox.CreateWnd;
begin
   inherited;

   { Try to create the custom canvas }
   if (Win32MajorVersion >= 6) and (Win32Platform = VER_PLATFORM_WIN32_NT) then
     FUseD2D := CreateD2DCanvas
   else
     FUseD2D := false;

end;

destructor TCustomAcceleratedPaintBox.Destroy;
begin
  FD2DCanvas.Free;
  inherited;
end;

function TCustomAcceleratedPaintBox.GetGDICanvas: TCanvas;
begin
   if FUseD2D then
     Result := nil
   else
     Result := inherited Canvas;
end;

function TCustomAcceleratedPaintBox.GetOSCanvas: TCustomCanvas;
begin
   if FUseD2D then
     Result := FD2DCanvas
   else
     Result := inherited Canvas;
end;

procedure TCustomAcceleratedPaintBox.Paint;
begin
   if FUseD2D then
   begin
     D2DCanvas.Font.Assign(Font);
     D2DCanvas.Brush.Color := Color;

     if csDesigning in ComponentState then
     begin
       D2DCanvas.Pen.Style := psDash;
       D2DCanvas.Brush.Style := bsSolid;

       D2DCanvas.Rectangle(0, 0, Width, Height);
     end;
   end else
   begin
     GDICanvas.Font.Assign(Font);
     GDICanvas.Brush.Color := Color;

     if csDesigning in ComponentState then
     begin
       GDICanvas.Pen.Style := psDash;
       GDICanvas.Brush.Style := bsSolid;

       GDICanvas.Rectangle(0, 0, Width, Height);
     end;
   end;
   if Assigned(FOnPaint) then FOnPaint(Self);
end;

procedure TCustomAcceleratedPaintBox.SetAccelerated(const Value: Boolean);
begin
   { Same value? }
   if Value = FUseD2D then
     Exit;

   if not Value then
   begin
     FUseD2D := false;
     Repaint;
   end else
   begin
     FUseD2D := FD2DCanvas <> nil;

     if FUseD2D then
       Repaint;
   end;
end;

procedure TCustomAcceleratedPaintBox.WMPaint(var Message: TWMPaint);
 var
   PaintStruct: TPaintStruct;
 begin
   if FUseD2D then
   begin
     BeginPaint(Handle, PaintStruct);
     try
       FD2DCanvas.BeginDraw;

       try
         Paint;
       finally
         FD2DCanvas.EndDraw;
       end;

     finally
       EndPaint(Handle, PaintStruct);
     end;
   end else
     inherited;

end;

procedure TCustomAcceleratedPaintBox.WMSize(var Message: TWMSize);
var
  sz: TD2D1SizeU;
begin
   if FD2DCanvas <> nil then
    begin
      sz := D2D1SizeU(Width, Height);
      ID2D1HwndRenderTarget(FD2DCanvas.RenderTarget).Resize(sz);
    end;

   inherited;
end;

{ TDirect2DCanvas }

// Баг . Если дпи по умолчанию установить 0, то вернется системынй дпи.
//  Это может быть 120. Но Форма рисуетя в 96
function D2D1RenderTargetPropertiesEx(&Type: TD2D1RenderTargetType = D2D1_RENDER_TARGET_TYPE_DEFAULT): TD2D1RenderTargetProperties; overload;
begin
  Result := D2D1RenderTargetProperties(&Type, D2D1PixelFormat(), 96, 96);
end;

procedure TDirect2DCanvas.Clear(Color: TColor);
begin
  if Assigned(GetRender()) then
    begin
      BeginDraw;
      GetRenderTarget.Clear(D2D1ColorF(Color));
      EndDraw;
    end;
end;

procedure TDirect2DCanvas.CreateRenderTarget;
var
  Rect: TRect;
  HR: HRESULT;
  wnd: HWND;
  target: ID2D1RenderTarget;
begin
  wnd := GetWnd;
  target := GetRender;
  if wnd <> 0 then
  begin
    // Render Target
    GetClientRect(wnd, Rect);
    HR := D2DFactory.CreateHwndRenderTarget(D2D1RenderTargetPropertiesEx(),
      D2D1HwndRenderTargetProperties(wnd, D2D1SizeU(Rect.Width, Rect.Height)),
      ID2D1HwndRenderTarget(target));
    System.Win.ComObj.OleCheck(HR);
    SetRender(target);
  end
  else inherited;
//  else if FDC <> 0 then
//  begin
//    D2DFactory.CreateDCRenderTarget(
//      D2D1RenderTargetProperties(
//        D2D1_RENDER_TARGET_TYPE_DEFAULT,
//        D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED),
//        0, 0, D2D1_RENDER_TARGET_USAGE_GDI_COMPATIBLE),
//      ID2D1DCRenderTarget(FRenderTarget));
//    ID2D1DCRenderTarget(FRenderTarget).BindDC(FDC, FSubRect);
//  end;
end;

procedure TDirect2DCanvas.RequiredState(ReqState: TCanvasState);
var
  x, y: single;
begin
  if not FInit then
    begin
      //SetRender(nil);
      //FInit := true;
      if Assigned(GetRender()) then
        begin
          GetRenderTarget.GetDpi(x, y);
          if (x <> 96) or (y <> 96) then
            begin
              GetRenderTarget.SetDpi(96, 96);
//              GetRenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_FORCE_DWORD);
              FInit := true;
            end;

        end;


    end;

  if (csHandleValid in ReqState) and (GetRender = nil) then CreateRenderTarget;
  inherited;

end;

{ TDirect2DCanvasHelper }

function TDirect2DCanvasHelper.GetRender: ID2D1RenderTarget;
begin
  with Self do
    Result := FRenderTarget;
end;

function TDirect2DCanvasHelper.GetWnd: HWND;
begin
  with Self do
    Result := FHWnd;
end;

procedure TDirect2DCanvasHelper.SetRender(const v: ID2D1RenderTarget);
begin
  with Self do
    FRenderTarget := v;
end;

end.
