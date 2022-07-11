unit InputThread;

interface

uses Windows, Messages, SysUtils, uVircessTypes;

//var
//  InputThread_hwnd: THandle;

procedure StartInputThread(Parameter: PInputsArray; Handle: HWND);
//  procedure SetInputThread(Enabled: Boolean);

implementation

//function WndProc(
//    hWindow: THandle;        // handle to window
//    uMsg: UINT;        // message identifier
//    wParam: WPARAM;    // first message parameter
//    lParam: LPARAM): LRESULT; stdcall; export;    // second message parameter
//var
//  Data: array[0..0] of TInput;
//begin
//  case uMsg of
//    WM_COPYDATA:
//    begin
//      CopyMemory(@Data, PCopyDataStruct(LParam).lpData, SizeOf(Data));
//      SendInput(1, Data[0], SizeOf(Data))
//    end;
//    WM_DESTROY:
//    begin
//      PostQuitMessage(0);
//    end;
//    else
//    begin
//      Result := DefWindowProc(hWindow, uMsg, wParam, lParam);
//      Exit;
//    end;
//  end;
//    Result := 0;
//end;
//
//function create_window: Boolean;
//var
//	wndClass, TempClass: TWndClassEx;
//  clientRect: TRect;
//  x, y, cx, cy: UINT;
//  {$IFDEF WIN64}
//  style: LONG;
//  {$ELSE}
//  style: LONG_PTR;
//  {$ENDIF}
//  margins: TMargins;
//begin
////	ZeroMemory(@wndClass, sizeof(wndClass));
//  FillChar(wndClass, SizeOf(wndClass), 0);
//  wndClass.cbSize := sizeof(wndClass);
//  wndClass.style := CS_HREDRAW or CS_VREDRAW;
//  wndClass.lpfnWndProc := @WndProc;
//  wndClass.cbClsExtra := 0;
//  wndClass.cbWndExtra := 0;
//  wndClass.hInstance := HInstance;
//  wndClass.hIcon := LoadIcon(0, IDI_APPLICATION);
//  wndClass.hIconSm := 0;
//  wndClass.hCursor := LoadCursor(0, IDC_ARROW);
//  wndClass.hbrBackground := {CreateSolidBrush(RGB(182, 219, 255)); //}HBRUSH(GetStockObject(BLACK_BRUSH));
//  wndClass.lpszMenuName := nil;
//  wndClass.lpszClassName := 'inputthread';
//
//  if not GetClassInfoEx(HInstance, wndClass.lpszClassName, TempClass) then
//  begin
//    wndClass.hInstance := HInstance;
//    if Windows.RegisterClassEx(wndClass) = 0 then
//      RaiseLastOSError;
//  end;
//
////  RegisterClassEx(wndClass);
////  if RegisterClassEx(wndClass) = ERROR then
////  begin
////    Result := False;
////    Exit;
////  end;
//
////  clientRect.left := 0;
////  clientRect.top := 0;
////  clientRect.right := GetSystemMetrics(SM_CXSCREEN);
////  clientRect.bottom := GetSystemMetrics(SM_CYSCREEN);
//
//  x := 0;
//  y := 0;
//  cx := 1;
//  cy := 1;
//
//  clientRect.left := x;
//  clientRect.top := y;
//  clientRect.right := x + cx;
//  clientRect.bottom := y + cy;
//
//  AdjustWindowRect(clientRect, WS_CAPTION, False);
//  InputThread_hwnd := CreateWindowEx(WS_EX_TOPMOST,
//                         'inputthread',
//                         'inputthread',
//                         WS_POPUP or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or WS_BORDER,
//                         x, //Integer(CW_USEDEFAULT),
//                         y, //Integer(CW_USEDEFAULT),
//                         cx,
//                         cy,
//                         0,
//                         0,
//                         HInstance,
//                         nil);
//
////		typedef DWORD (WINAPI *PSLWA)(HWND, DWORD, BYTE, DWORD);
////
////	PSLWA pSetLayeredWindowAttributes=NULL;
////	/*
////	* Code that follows allows the program to run in
////	* environment other than windows 2000
////	* without crashing only difference being that
////	* there will be no transparency as
////	* the SetLayeredAttributes function is available only in
////	* windows 2000
////	*/
////	HMODULE hDLL = LoadLibrary ("user32");
////	if (hDLL) pSetLayeredWindowAttributes = (PSLWA) GetProcAddress(hDLL,"SetLayeredWindowAttributes");
////	/*
////	* Make the windows a layered window
////	*/
//
////  SetParent(black_hwnd, GetDesktopwindow);
//
//{$IFNDEF WIN64}
//	style := GetWindowLong(InputThread_hwnd, GWL_STYLE);
////	style := GetWindowLong(hwnd, GWL_STYLE);
//	style := style and not (WS_DLGFRAME or WS_THICKFRAME);
//	SetWindowLong(InputThread_hwnd, GWL_STYLE, style);
//{$ELSE}
//	style := GetWindowLongPtr(InputThread_hwnd, GWL_STYLE);
////	style = GetWindowLongPtr(hwnd, GWL_STYLE);
//	style := style and not (WS_DLGFRAME or WS_THICKFRAME);
//	SetWindowLongPtr(InputThread_hwnd, GWL_STYLE, style);
//{$ENDIF}
//
////	if (pSetLayeredWindowAttributes != NULL) {
//{$IFNDEF WIN64}
//		SetWindowLong(InputThread_hwnd, GWL_EXSTYLE, GetWindowLong(InputThread_hwnd, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOPMOST or WS_EX_NOACTIVATE);
//{$ELSE}
//		SetWindowLongPtr(InputThread_hwnd, GWL_EXSTYLE, GetWindowLongPtr(InputThread_hwnd, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOPMOST or WS_EX_NOACTIVATE);
//{$ENDIF}
//  ShowWindow(InputThread_hwnd, SW_SHOWNORMAL);
//
////	if (pSetLayeredWindowAttributes != NULL) {
////	/**
////	* Second parameter RGB(255,255,255) sets the colorkey to white
////	* LWA_COLORKEY flag indicates that color key is valid
////	* LWA_ALPHA indicates that ALphablend parameter (factor)
////	* is valid
////	*/
//	SetLayeredWindowAttributes(InputThread_hwnd, RGB(0, 0, 0), 0, LWA_ALPHA);
////	}
//	SetWindowPos(InputThread_hwnd, HWND_TOPMOST, x, y, cx, cy, SWP_FRAMECHANGED or SWP_NOACTIVATE);
//  ShowWindow(InputThread_hwnd, SW_HIDE);
//
////  margins.cxLeftWidth := 0;
////  margins.cyTopHeight := 0;
////  margins.cxRightWidth := cx;
////  margins.cyBottomHeight := cy;
////  DoDwmExtendFrameIntoClientArea(black_hwnd, @margins);
//
////  ShowWindow(black_hwnd, SW_HIDE);
//
////SM_CXVIRTUALSCREEN
//	Result := True;
//end;
//
//function InputThreadMainProc: DWORD;
//var
////	desktop, old_desktop: HDESK;
////  dummy: DWORD;
////	new_name: PChar;
//	umsg: TMsg;
//begin
////	xLog('Show Blank screen');
//
////	desktop := OpenInputDesktop(0, False,
////								DESKTOP_CREATEMENU or DESKTOP_CREATEWINDOW or
////								DESKTOP_ENUMERATE or DESKTOP_HOOKCONTROL or
////								DESKTOP_WRITEOBJECTS or DESKTOP_READOBJECTS or
////								DESKTOP_SWITCHDESKTOP or GENERIC_WRITE
////								);
////
////	if desktop = ERROR then
////		xLog('OpenInputdesktop Error')
////	else
////		xLog('OpenInputdesktop OK');
////
////	old_desktop := GetThreadDesktop(GetCurrentThreadId());
////
////
////	if desktop <> ERROR then
////	begin
////		if not GetUserObjectInformation(desktop, UOI_NAME, new_name, 256, &dummy) then
////		{
////			vnclog.Print(LL_INTERR, VNCLOG("!GetUserObjectInformation \n"));
////		}
////
////		xLog('SelectHDESK to ' + new_name + ' (' + IntToStr(desktop) + ') from ' + IntToStr(old_desktop));
////
////		if not SetThreadDesktop(desktop) then
////			xLog('SelectHDESK: not SetThreadDesktop');
////	end;
//
//	create_window;
//
//	while GetMessage(umsg, 0, 0, 0) do
//	begin
//		TranslateMessage(umsg);
//		DispatchMessage(umsg);
//	end;
////	xLog('Hide Black Screen');
////	SetThreadDesktop(old_desktop);
////	if desktop <> ERROR then
////    CloseDesktop(desktop);
//
//	Result := 0;
//end;
//
//procedure SetInputThread(enabled: Boolean);
//var
//  ThreadHandle2: THandle;
//  dwTId: DWORD;
//  Blackhnd: THandle;
//begin
//  if enabled then
//  begin
//    ThreadHandle2 := CreateThread(nil, 0, @InputThreadMainProc, nil, 0, dwTId);
//    if ThreadHandle2 <> ERROR then
//      CloseHandle(ThreadHandle2);
//  end
//  else
//  if not enabled then
//	begin
//    Blackhnd := FindWindow('inputthread', nil);
//	  if Blackhnd <> ERROR then
//      PostMessage(Blackhnd, WM_CLOSE, 0, 0);
//  end;
//end;

function ThreadFunc(Parameter : PInputsArray): DWORD; stdcall;
var
  i: Integer;
  Data: array[0..0] of TInput;
begin
  try
    CopyMemory(@Data, Parameter, SizeOf(TInput));
    SendInput(1, Data[0], SizeOf(Data));
    Dispose(Parameter);
  finally
    EndThread(0);
  end;
end;

procedure StartInputThread(Parameter: PInputsArray; Handle: HWND);
var
  ThrHandle: HWND;
  dwID: DWORD;
  pinputs: PInputsArray;
begin
  New(pinputs);
  CopyMemory(pinputs, Parameter, SizeOf(TInput));
  ThrHandle := CreateThread(nil, 0, @ThreadFunc, pinputs, 0, dwID);
  if ThrHandle <> 0 then //поток успешно создался
  begin
//    AttachThreadInput(GetWindowThreadProcessID(Handle, nil), dwID, True);
//    ResumeThread(ThrHandle);
    CloseHandle(ThrHandle);
  end;
end;

end.
