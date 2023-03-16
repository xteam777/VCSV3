// LAST UPDATE 22:15:00 on 5/12/02

// �2002 Bayden Systems.  All rights reserved.
// May not be published or distributed in source form without permission, which liberally given.
// You may not distribute any product which uses this component in binary form unless you first
//    spend register (free, takes only 1 minute) at www.bayden.com/register.asp

unit ProgressDialog;

interface

uses Windows, SysUtils, ActiveX, Classes, Graphics, Controls, Shlobj, ComCtrls, rtcScrUtils;

//type
//  TCommonAVI = (aviNone, aviFindFolder, aviFindFile, aviFindComputer, aviCopyFiles, aviCopyFile, aviRecycleFile, aviEmptyRecycle, aviDeleteFile);

// Constants for enum PROGDLG_FLAGS
type
  PROGDLG_FLAGS = TOleEnum;
const
  PROGDLG_NORMAL = $00000000;
  PROGDLG_MODAL = $00000001;
  PROGDLG_AUTOTIME = $00000002;
  PROGDLG_NOTIME = $00000004;
  PROGDLG_NOMINIMIZE = $00000008;
  PROGDLG_NOPROGRESSBAR = $00000010;

// Constants for enum PDTIMER_FLAGS
type
  PDTIMER_FLAGS = TOleEnum;

Const
  PDTIMER_RESET = $00000001;

type
  IProgressDialog = interface;
//  IOleWindow = interface;

// Interface: IProgressDialog
  IProgressDialog = interface(IUnknown)
    ['{EBBC7C04-315E-11D2-B62F-006097DF5BD4}']
    function StartProgressDialog(hwndParent: Integer; const punkEnableModless: IUnknown; dwFlags: PROGDLG_FLAGS; var pvResevered: Pointer): HResult; stdcall;
    function StopProgressDialog: HResult; stdcall;
    function SetTitle(pwzTitle: PWideChar): HResult; stdcall;
    function SetAnimation(hInstAnimation: Integer; idAnimation: Integer): HResult; stdcall;
    function HasUserCancelled: Integer; stdcall;
    function SetProgress(dwCompleted: Integer; dwTotal: Integer): HResult; stdcall;
    function SetProgress64(ullCompleted: Currency; ullTotal: Currency): HResult; stdcall;
    function SetLine(dwLineNum: Integer; pwzString: PWideChar; fCompactPath: Integer; var pvResevered: Pointer): HResult; stdcall;
    function SetCancelMsg(pwzCancelMsg: PWideChar; var pvResevered: Pointer): HResult; stdcall;
    function Timer(dwTimerAction: PDTIMER_FLAGS; var pvResevered: Pointer): HResult; stdcall;
    function GetHWND: HWND; stdcall;
  end;

// Interface: IOleWindow
{  IOleWindow = interface(IUnknown)
    [00000114-0000-0000-C000-000000000046]
    function GetWindow(out phwnd: Integer): HResult; stdcall;
    function ContextSensitiveHelp(fEnterMode: Integer): HResult; stdcall;
  end;           }

type
  TProgressDialog = class(TComponent)
  private
    ShellModule: HModule;
		fTitle: WideString;
    fCommonAVI: TCommonAVI;
		fOnCancel: TNotifyEvent;
		fLine1: WideString;
		fLine2: WideString;
		fFooter: WideString;
    fCancel: WideString;
		fMax: Integer;
		fPosition: Integer;
    fModal: Boolean;
    fAutoCalc: Boolean;

    iiProgressDialog: IProgressDialog;
    function GetShellModule: THandle;

  protected
		procedure SetTitle(Value: WideString);
		procedure SetMax(Value: Integer);
		procedure SetPosition(Value: Integer);
		procedure SetLine1(Value: WideString);
		procedure SetLine2(Value: WideString);
		procedure SetFooter(Value: WideString);
		procedure SetCancel(Value: WideString);
  public
    fHwndParent: HWnd;
    constructor Create(AOwner: TComponent); override;
		procedure Execute;
		procedure Stop;
    destructor Destroy; override;
  published
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    property Title: WideString read fTitle write SetTitle;
    property CommonAVI: TCommonAVI read FCommonAVI write FCommonAVI default aviNone;
    property Max: Integer read fMax write SetMax default 100;
    property Position: Integer read fPosition write SetPosition;
    property Modal: Boolean read fModal write fModal default False;
    property AutoCalcFooter: Boolean read fAutoCalc write fAutoCalc default True;
    property TextLine1: WideString read fLine1 write SetLine1;
    property TextLine2: WideString read fLine2 write SetLine2;
    property TextFooter: WideString read fFooter write SetFooter;
    property TextCancel: WideString read fCancel write SetCancel;
  end;

procedure Register;

implementation
uses ComObj;

const
  LIBID_ProgressDialog: TGUID = '{2F2719A2-83CC-11D3-A08C-0040F6A4BFEC}';
  IID_IProgressDialog: TGUID = '{EBBC7C04-315E-11D2-B62F-006097DF5BD4}';
  IID_IOleWindow: TGUID = '{00000114-0000-0000-C000-000000000046}';
  CLASS_ProgressDialog: TGUID = '{F8383852-FCD3-11D1-A6B9-006097DF5BD4}';

  CommonAVIId: array[TCommonAVI] of Integer = (0, 150, 151, 152, 160, 161, 162, 163, 164);

type
  TWaitThread = class(TThread)
  private
    fOwner: TProgressDialog;
  protected
    procedure AnnounceDone;
    procedure Execute; override;
  public
    constructor Create(Owner: TProgressDialog);
end;

constructor TProgressDialog.Create(AOwner: TComponent);
begin
  if not(AOwner.InheritsFrom(TWinControl)) then
    Raise Exception.CreateFmt('Error: Component must be owned by TForm or descendent of TForm %s', [AOwner.Classname]);
  inherited Create(AOwner);
  if csDesigning in ComponentState then
    Exit;
  fHwndParent := (AOwner as TWinControl).Handle;
end;

destructor TProgressDialog.Destroy;
begin
  Stop;
  inherited Destroy;
end;

// --------------------------------------------------------------------------------------------
// ----------------------------------- Watcher thread -----------------------------------------

constructor TWaitThread.Create(Owner: TProgressDialog);
Begin
  FreeOnTerminate:=FALSE;
  FOwner:= Owner;
  inherited Create(FALSE);
End;

procedure TWaitThread.AnnounceDone;
Begin
  if Assigned(FOwner.fOnCancel) then
    fOwner.fOnCancel(fOwner);
End;

procedure TWaitThread.Execute;
Begin
  while True do
  begin
    if not Assigned(fOwner.iiProgressDialog) then
      Break
    else if fOwner.iiProgressDialog.HasUserCancelled <> 0 then
    begin
      Synchronize(AnnounceDone);
      Terminate;
      Break;
    end
    else
      Sleep(250);
  end;
End;

// ----------------------------------- End Watcher thread -------------------------------------
// --------------------------------------------------------------------------------------------


function TProgressDialog.GetShellModule: THandle;
begin
  if ShellModule = 0 then
  begin
    ShellModule := SafeLoadLibrary( 'shell32.dll');
    if ShellModule <= HINSTANCE_ERROR then
      ShellModule := 0;
  end;
  Result := ShellModule;
end;

Procedure TProgressDialog.Stop;
begin
  if Assigned(iiProgressDialog) then
  begin
    iiProgressDialog.StopProgressDialog;
    iiProgressDialog := nil;
  end;
end;

procedure TProgressDialog.SetTitle(Value: WideString);
begin
  fTitle:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetTitle(PWideChar(fTitle));
end;

procedure TProgressDialog.SetLine1(Value: WideString);
var pNil: Pointer;
Begin
  pNil:=nil;
  fLine1:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetLine(1, PWideChar(fLine1), 1, pNil);
End;

procedure TProgressDialog.SetLine2(Value: WideString);
var pNil: Pointer;
Begin
  pNil:=nil;
  fLine2:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetLine(2, PWideChar(fLine2), 1, pNil);
End;

procedure TProgressDialog.SetFooter(Value: WideString);
var pNil: Pointer;
Begin
  pNil:=nil;
  fFooter:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetLine(3, PWideChar(fFooter), 1, pNil);
End;

procedure TProgressDialog.SetCancel(Value: WideString);
var pNil: Pointer;
Begin
  pNil:=nil;
  fCancel:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetCancelMsg(PWideChar(FCancel), pNil);
End;

procedure TProgressDialog.Execute;
var pNil: Pointer;
    dwFlags: Integer;
Begin
  pNil := nil;
  dwFlags := PROGDLG_NOMINIMIZE;
  if fAutoCalc then dwFlags := dwFlags OR PROGDLG_AUTOTIME; 
  if fModal then dwFlags := dwFlags OR PROGDLG_MODAL;

  iiProgressDialog := CreateComObject(CLASS_ProgressDialog) as IProgressDialog;
  with iiProgressDialog do
    Begin
      SetTitle(PWideChar(fTitle));
      SetAnimation(GetShellModule, CommonAVIId[fCommonAVI]);
      SetLine(1, PWideChar(fLine1), 1, pNil);
      SetLine(2, PWideChar(fLine2), 1, pNil);
      SetLine(3, PWideChar(fFooter), 1, pNil);
      SetCancelMsg( PWideChar(fCancel), pNil);
      StartProgressDialog(fHwndParent, nil, dwFlags, pNil);
//      SetForegroundWindow(iiProgressDialog.GetHWND);
    End;
  TWaitThread.Create(Self);
End;

procedure TProgressDialog.SetPosition(Value: Integer);
begin
  fPosition:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetProgress(fPosition, fMax);
end;

procedure TProgressDialog.SetMax(Value: Integer);
Begin
  fMax:=Value;
  if Assigned(iiProgressDialog) then
    iiProgressDialog.SetProgress(fPosition, fMax);
End;

procedure Register;
begin
  RegisterComponents('System', [TProgressDialog]);
end;

end.
