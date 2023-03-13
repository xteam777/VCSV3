unit BlackLayered;

interface

uses Windows, Messages, SysUtils, rtcLog, rtcScrUtils, CommCtrl;

const
  LWA_COLORKEY = 1;
  LWA_ALPHA = 2;
  WS_EX_LAYERED = $80000;
  IDB_LOGO64 = 139;
  WM_ACTIVATETOPLEVEL = $036E;

var
  black_hwnd: THandle;
//  hInst: THandle;
  wd: Integer = 0;
  ht: Integer = 0;
  BlankMonitorEnabled: Boolean = False;

  procedure SetBlankMonitor(enabled: Boolean);

implementation

//function DoGetBkGndBitmap2(const uBmpResId: UINT): HBITMAP;
//var
//  hbmBkGnd: HBITMAP;
//  WORKDIR: PWideChar;
//  mycommand: PWideChar;
//  h2: TBitmapInfo;
//  hxdc: HDC;
//  rc: TRect;
//begin
////  if GetModuleFileName(0, WORKDIR, MAX_PATH) <> ERROR then
////    if Pos(WORKDIR, '\') = 0 then
////      Exit;
////
////  StrCopy(mycommand, WORKDIR);
////  StrCat(mycommand, '\background.bmp');
//
////  hbmBkGnd := LoadImage(0, 'background.bmp', IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
////  if hbmBkGnd = ERROR then
////     hbmBkGnd := LoadImage(GetModuleHandle(nil), MAKEINTRESOURCE(IDB_LOGO64), IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
////
////  h2.bmiHeader.biSize := sizeof(h2);
////  h2.bmiHeader.biBitCount := 0;
//  //// h2.biWidth=11; h2.biHeight=22; h2.biPlanes=1;
//  hxdc := CreateDC('DISPLAY', nil, nil, nil);
//  GetDIBits(hxdc, hbmBkGnd, 0, 0, nil, h2, DIB_RGB_COLORS);
//  rc.Left := 0;
//  rc.Top := 0;
//  rc.Right := h2.bmiHeader.biWidth;
//  rc.Bottom := h2.bmiHeader.biHeight;
//  FillRect(hxdc, rc, HBRUSH(GetStockObject(BLACK_BRUSH)));
//  wd := h2.bmiHeader.biWidth;
//  ht := h2.bmiHeader.biHeight;
//  DeleteDC(hxdc);
//
//  if hbmBkGnd <> ERROR then
//    Result := hbmBkGnd
//  else
//    Result := HBITMAP(-1);
//end;
//
//function DoSDKEraseBkGnd2(const pHDC: HDC; const crBkGndFill: COLORREF): Boolean;
//var
//  hbmBkGnd, hbrBkGnd: HBITMAP;
//  rc: TRect;
//  hdcMem: HDC;
//  hbrOld, hbmOld: HGDIOBJ;
//  size: TSIZE;
//begin
//  hbmBkGnd := DoGetBkGndBitmap2(0);
//  if (pHDC <> INVALID_HANDLE_VALUE)
//    and (hbmBkGnd <> INVALID_HANDLE_VALUE) then
//  begin
//    if (GetClipBox(pHDC, rc) <> ERROR)
//      and (not IsRectEmpty(rc)) then
//    begin
//      hdcMem := CreateCompatibleDC(pHDC);
////      if hdcMem <> 0 then
////      begin
//        hbrBkGnd := CreateSolidBrush(crBkGndFill);
//        if hbrBkGnd <> ERROR then
//        begin
//          hbrOld := SelectObject(pHDC, hbrBkGnd);
//          if hbrOld <> ERROR then
//          begin
//            size.cx := rc.right - rc.left;
//            size.cy := rc.bottom - rc.top;
//
//            if PatBlt(pHDC, rc.left, rc.top, size.cx, size.cy, PATCOPY) then
//              hbmOld := SelectObject(hdcMem, hbmBkGnd);
//            if hbmOld <> ERROR then
//            begin
//              StretchBlt(pHDC, 0, 0, size.cx, size.cy, hdcMem, 0, 0, wd, ht, SRCCOPY);
//
////              BitBlt(hDC, rc.left, rc.top, size.cx, size.cy, hdcMem, rc.left, rc.top, SRCCOPY);
//              SelectObject(hdcMem, hbmOld);
//            end;
//          end;
//          SelectObject(pHDC, hbrOld);
//        end;
//        DeleteObject(hbrBkGnd);
////      end;
//      DeleteDC(hdcMem);
//    end;
//  end;
//
//  Result := True;
//end;

function WndProc(
    hWindow: THandle;        // handle to window
    uMsg: UINT;        // message identifier
    wParam: WPARAM;    // first message parameter
    lParam: LPARAM): LRESULT; stdcall; export;    // second message parameter
var
  rc: TRect;
begin
  case uMsg of
    WM_CREATE:
//		  SetTimer(hWindow,10,30000,NULL);
      SetTimer(hWindow, 100, 20, nil);
    WM_TIMER:
      if wParam = 100 then
        SetWindowPos(hWindow, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
    WM_ERASEBKGND:
    begin
      //DoSDKEraseBkGnd2(HDC(wParam), RGB(0, 0, 0));
      rc.Left := 0;
      rc.Top := 0;
      rc.Width := GetSystemMetrics(SM_CXVIRTUALSCREEN);
      rc.Height := GetSystemMetrics(SM_CYVIRTUALSCREEN);
      FillRect(HDC(wParam), rc, HBRUSH(GetStockObject(BLACK_BRUSH)));
      Result := 1;
      Exit;
    end;
    WM_CTLCOLORSTATIC:
    begin
      SetBkMode(HDC(wParam), TRANSPARENT);
			Result := LONG_PTR(GetStockObject(NULL_BRUSH));
      Exit;
    end;
    WM_DESTROY:
    begin
      KillTimer(hWindow, 100);
      PostQuitMessage(0);
    end;
    else
    begin
      Result := DefWindowProc(hWindow, uMsg, wParam, lParam);
      Exit;
    end;
  end;
    Result := 0;
end;

function create_window: Boolean;
var
	wndClass, TempClass: TWndClassEx;
  clientRect: TRect;
  x, y, cx, cy: UINT;
  {$IFDEF WIN64}
  style: LONG;
  {$ELSE}
  style: LONG_PTR;
  {$ENDIF}
//  margins: TMargins;
begin
//	ZeroMemory(@wndClass, sizeof(wndClass));
  FillChar(wndClass, SizeOf(wndClass), 0);
  wndClass.cbSize := sizeof(wndClass);
  wndClass.style := CS_HREDRAW or CS_VREDRAW;
  wndClass.lpfnWndProc := @WndProc;
  wndClass.cbClsExtra := 0;
  wndClass.cbWndExtra := 0;
  wndClass.hInstance := HInstance;
  wndClass.hIcon := LoadIcon(0, IDI_APPLICATION);
  wndClass.hIconSm := 0;
  wndClass.hCursor := LoadCursor(0, IDC_ARROW);
  wndClass.hbrBackground := {CreateSolidBrush(RGB(182, 219, 255)); //}HBRUSH(GetStockObject(BLACK_BRUSH));
  wndClass.lpszMenuName := nil;
  wndClass.lpszClassName := 'blackscreen';

  if not GetClassInfoEx(HInstance, wndClass.lpszClassName, TempClass) then
  begin
    wndClass.hInstance := HInstance;
    if Windows.RegisterClassEx(wndClass) = 0 then
      RaiseLastOSError;
  end;

//  RegisterClassEx(wndClass);
//  if RegisterClassEx(wndClass) = ERROR then
//  begin
//    Result := False;
//    Exit;
//  end;

//  clientRect.left := 0;
//  clientRect.top := 0;
//  clientRect.right := GetSystemMetrics(SM_CXSCREEN);
//  clientRect.bottom := GetSystemMetrics(SM_CYSCREEN);

  x := GetSystemMetrics(SM_XVIRTUALSCREEN);
  y := GetSystemMetrics(SM_YVIRTUALSCREEN);
  cx := GetSystemMetrics(SM_CXVIRTUALSCREEN);
  cy := GetSystemMetrics(SM_CYVIRTUALSCREEN);

  clientRect.left := x;
  clientRect.top := y;
  clientRect.right := x + cx;
  clientRect.bottom := y + cy;

  AdjustWindowRect(clientRect, WS_CAPTION, False);
  black_hwnd := CreateWindowEx(WS_EX_TOPMOST,
                         'blackscreen',
                         'blackscreen',
                         WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or WS_BORDER,
                         x, //Integer(CW_USEDEFAULT),
                         y, //Integer(CW_USEDEFAULT),
                         cx,
                         cy,
                         0,
                         0,
                         HInstance,
                         nil);

//		typedef DWORD (WINAPI *PSLWA)(HWND, DWORD, BYTE, DWORD);
//
//	PSLWA pSetLayeredWindowAttributes=NULL;
//	/*
//	* Code that follows allows the program to run in
//	* environment other than windows 2000
//	* without crashing only difference being that
//	* there will be no transparency as
//	* the SetLayeredAttributes function is available only in
//	* windows 2000
//	*/
//	HMODULE hDLL = LoadLibrary ("user32");
//	if (hDLL) pSetLayeredWindowAttributes = (PSLWA) GetProcAddress(hDLL,"SetLayeredWindowAttributes");
//	/*
//	* Make the windows a layered window
//	*/

//  SetParent(black_hwnd, GetDesktopwindow);

{$IFNDEF WIN64}
	style := GetWindowLong(black_hwnd, GWL_STYLE);
//	style := GetWindowLong(hwnd, GWL_STYLE);
	style := style and not (WS_DLGFRAME or WS_THICKFRAME);
	SetWindowLong(black_hwnd, GWL_STYLE, style);
{$ELSE}
	style := GetWindowLongPtr(black_hwnd, GWL_STYLE);
//	style = GetWindowLongPtr(hwnd, GWL_STYLE);
	style := style and not (WS_DLGFRAME or WS_THICKFRAME);
	SetWindowLongPtr(black_hwnd, GWL_STYLE, style);
{$ENDIF}

//	if (pSetLayeredWindowAttributes != NULL) {
{$IFNDEF WIN64}
		SetWindowLong(black_hwnd, GWL_EXSTYLE, GetWindowLong(black_hwnd, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOPMOST or WS_EX_NOACTIVATE);
{$ELSE}
		SetWindowLongPtr(black_hwnd, GWL_EXSTYLE, GetWindowLongPtr(black_hwnd, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOPMOST or WS_EX_NOACTIVATE);
{$ENDIF}
  ShowWindow(black_hwnd, SW_SHOWNORMAL);

//	if (pSetLayeredWindowAttributes != NULL) {
//	/**
//	* Second parameter RGB(255,255,255) sets the colorkey to white
//	* LWA_COLORKEY flag indicates that color key is valid
//	* LWA_ALPHA indicates that ALphablend parameter (factor)
//	* is valid
//	*/
	SetLayeredWindowAttributes(black_hwnd, RGB(255, 255, 255), 255, LWA_ALPHA);
//	}
	SetWindowPos(black_hwnd, HWND_TOPMOST, x, y, cx, cy, SWP_FRAMECHANGED or SWP_NOACTIVATE);

//  margins.cxLeftWidth := 0;
//  margins.cyTopHeight := 0;
//  margins.cxRightWidth := cx;
//  margins.cyBottomHeight := cy;
//  DoDwmExtendFrameIntoClientArea(black_hwnd, @margins);

//  ShowWindow(black_hwnd, SW_HIDE);

//SM_CXVIRTUALSCREEN
	Result := True;
end;

function BlackWindow: DWORD;
var
//	desktop, old_desktop: HDESK;
//  dummy: DWORD;
//	new_name: PChar;
	umsg: TMsg;
begin
	xLog('Show Blank screen');

//	desktop := OpenInputDesktop(0, False,
//								DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
//								DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or
//								DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or
//								DESKTOP_SWITCHDESKTOP or GENERIC_WRITE
//								);
//
//	if desktop = ERROR then
//		xLog('OpenInputdesktop Error')
//	else
//		xLog('OpenInputdesktop OK');
//
//	old_desktop := GetThreadDesktop(GetCurrentThreadId());
//
//
//	if desktop <> ERROR then
//	begin
//		if not GetUserObjectInformation(desktop, UOI_NAME, new_name, 256, &dummy) then
//		{
//			vnclog.Print(LL_INTERR, VNCLOG("!GetUserObjectInformation \n"));
//		}
//
//		xLog('SelectHDESK to ' + new_name + ' (' + IntToStr(desktop) + ') from ' + IntToStr(old_desktop));
//
//		if not SetThreadDesktop(desktop) then
//			xLog('SelectHDESK: not SetThreadDesktop');
//	end;

	create_window;

	while GetMessage(umsg, 0, 0, 0) do
	begin
		TranslateMessage(umsg);
		DispatchMessage(umsg);
	end;
	xLog('Hide Black Screen');
//	SetThreadDesktop(old_desktop);
//	if desktop <> ERROR then
//    CloseDesktop(desktop);

	Result := 0;
end;

procedure SetBlankMonitor(enabled: Boolean);
var
  ThreadHandle2: THandle;
  dwTId: DWORD;
  Blackhnd: THandle;
begin
	// Also Turn Off the Monitor if allowed ("Blank Screen", "Blank Monitor")
  if enabled
    and (not BlankMonitorEnabled) then
  begin
	//if (VNCOS.OS_AERO_ON) VNCOS.DisableAero();
///////////////////////////////////////////////////////////////////////////    DisableAero;
//	  Sleep(1000);
//		    if (!VNCOS.CaptureAlphaBlending() || VideoBuffer())
//		    {
//			    SendMessage(m_hwnd,WM_SYSCOMMAND,SC_MONITORPOWER,(LPARAM)2);
//				m_screen_in_powersave=true;
//		    }
//		    else
//		    {
    ThreadHandle2 := CreateThread(nil, 0, @BlackWindow, nil, 0, dwTId);
    if ThreadHandle2 <> ERROR then
      CloseHandle(ThreadHandle2);
    BlankMonitorEnabled := True;
//		    }
  end
  else // Monitor On
  if (not enabled)
    and BlankMonitorEnabled then
	begin
//		    if (!VNCOS.CaptureAlphaBlending() || VideoBuffer())
//		    {
//			    SendMessage(m_hwnd,WM_SYSCOMMAND,SC_MONITORPOWER,(LPARAM)-1);
//				//win8 require mouse move
//				mouse_event(MOUSEEVENTF_MOVE, 0, 1, 0, NULL);
//				Sleep(40);
//				mouse_event(MOUSEEVENTF_MOVE, 0, -1, 0, NULL);
//				//JUst in case video driver state was changed
//				HWND Blackhnd = FindWindow(("blackscreen"), 0);
//			    if (Blackhnd) PostMessage(Blackhnd, WM_CLOSE, 0, 0);
//				 m_screen_in_powersave=false;
//		    }
//		    else
//		    {
    Blackhnd := FindWindow('blackscreen', nil);
	  if Blackhnd <> ERROR then
      PostMessage(Blackhnd, WM_CLOSE, 0, 0);
    BlankMonitorEnabled := False;
    //VNCOS.ResetAero();
///////////////////////////////////////////////////////////////////////    RestoreAero;
  end;
end;

end.
