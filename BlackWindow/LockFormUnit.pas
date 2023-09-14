unit LockFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

const

  WM_SHOW_FORM = WM_USER + 1;

type

  TLockForm = class(TForm)
    lblTime: TLabel;
    lblUserMessage: TLabel;
    lblDate: TLabel;
    TimerDate: TTimer;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimerDateTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FAutoLock: Boolean;
    procedure WmShowForm(var Message: TMessage); message WM_SHOW_FORM;
  protected
    procedure CreateHandle; override;
    procedure WndProc(var Message : TMessage); override;
  public
    { Public declarations }
    procedure DisableWindowForRecord(Disable: Boolean);
    procedure ApplyLayeredWindow(DisableInput: Boolean; Percent: Byte);
    procedure ResetLayeredWindow();
    procedure DisableInput(Disable: Boolean);
    property AutoLock: Boolean read FAutoLock write FAutoLock;
  end;


  procedure ShowLockForm();
  procedure CloseLockForm();


implementation

var
  lock: Integer;
  LockForm: TLockForm;
{$R *.dfm}





resourcestring
  rsUserMessageEN = 'The computer is locked. '+sLineBreak+
                    'Do not turn off or restart your computer.'+sLineBreak+
                    'Wait for the operator to finish.';
  rsUserMessageDE = 'Der Computer ist gesperrt.'+sLineBreak+
                    'Schalten Sie Ihren Computer nicht aus und starten Sie ihn nicht neu.'+sLineBreak+
                    'Warten Sie, bis der Operator fertig ist.';
  rsUserMessageRU = 'Компьютор заблокирован.'+sLineBreak+
                    'Не выключайте и не перзагружайте компьютер.'+sLineBreak+
                    'Дождидесь окончания работ оператора.';
  rsUserMessageUA = 'Комп''ютер заблоковано.'+sLineBreak+
                    'Не вимикайте та не перезавантажуйте комп''ютер.'+sLineBreak+
                    'Дочекайтесь закінчення робіт оператора.';



procedure ShowLockForm();
begin
  if Assigned(LockForm) then exit;
  while InterlockedExchange(lock, 1) <> 0 do
    begin
      SwitchToThread;
      Application.ProcessMessages;
    end;
  try

    TThread.Queue(TThread.CurrentThread, procedure
    begin
      if not Assigned(LockForm) then
        begin
          LockForm := TLockForm.Create(Application);
          LockForm.AutoLock := true;
          // show modal
          PostMessage(LockForm.Handle, WM_SHOW_FORM, 0, 0);
        end;
    end
    );

  finally
    InterlockedExchange(lock, 0);
  end;
end;

procedure CloseLockForm();
begin
  if not Assigned(LockForm) then exit;
  
  while InterlockedExchange(lock, 1) <> 0 do
    begin
      SwitchToThread;
      Application.ProcessMessages;
    end;
  try
    if Assigned(LockForm) then
      SendMessage(LockForm.Handle, WM_CLOSE, 0, 0);
    LockForm := nil;

  finally
    InterlockedExchange(lock, 0);
  end;
end;


procedure TLockForm.ApplyLayeredWindow(DisableInput: Boolean;
  Percent: Byte);
const
  WND_EXSTYLE_TRANSPARENT: array [Boolean] of DWORD = (WS_EX_LAYERED, WS_EX_LAYERED or WS_EX_TRANSPARENT);
begin
  Win32Check(SetWindowLong(Handle, GWL_EXSTYLE,
                GetWindowLong(Handle, GWL_EXSTYLE) or WND_EXSTYLE_TRANSPARENT[DisableInput]) <> 0);
  Win32Check(SetLayeredWindowAttributes(Handle, 0, (255 * Percent) div 100, LWA_ALPHA));
end;

procedure TLockForm.CreateHandle;
begin
  inherited;
  if FAutoLock then
    begin
      ApplyLayeredWindow(true, 100);
      DisableWindowForRecord(true);
    end;

end;

procedure TLockForm.DisableInput(Disable: Boolean);
begin
  //Win32Check(BlockInput(LongBool(Disable)));
  // not implemented
end;

procedure TLockForm.DisableWindowForRecord(Disable: Boolean);
const
  WDA_EXCLUDEFROMCAPTURE = $00000011;
  WDA_NONE = 0;
  DWA_AFFINITY: array [Boolean] of DWORD = (WDA_NONE, WDA_EXCLUDEFROMCAPTURE);
begin
  Win32Check(SetWindowDisplayAffinity(Handle, DWA_AFFINITY[Disable]));
end;

procedure TLockForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  LockForm := nil;
  Action := TCloseAction.caFree;
end;

procedure TLockForm.FormCreate(Sender: TObject);
begin
  case Lo(GetUserDefaultUILanguage) of
    LANG_RUSSIAN:   lblUserMessage.Caption := rsUserMessageRU;
    LANG_ENGLISH:   lblUserMessage.Caption := rsUserMessageEN;
    LANG_DUTCH:     lblUserMessage.Caption := rsUserMessageDE;
    LANG_UKRAINIAN: lblUserMessage.Caption := rsUserMessageUA;
  else
    lblUserMessage.Caption := rsUserMessageEN;
  end;
  TimerDateTimer(TimerDate);
end;

procedure TLockForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Key := 0;   // Disable all user inputs. ALT+F4
end;

procedure TLockForm.FormResize(Sender: TObject);
var
  r: TRect;
  i: Integer;
begin
  r := ClientRect;
  i := r.CenterPoint.X -  lblUserMessage.Width div 2;
  if i < r.Left then i := r.Left;
  lblUserMessage.Left := i;
  i  := r.CenterPoint.Y - Round(lblUserMessage.Height * 1.8);
  if i < r.Top then i := r.Top;
  lblUserMessage.Top  := i;

end;

procedure TLockForm.ResetLayeredWindow;
begin
  Win32Check(SetWindowLong(Handle, GWL_EXSTYLE,  GetWindowLong(Handle, GWL_EXSTYLE) and not (WS_EX_LAYERED or WS_EX_TRANSPARENT)) <> 0);
end;



procedure TLockForm.TimerDateTimer(Sender: TObject);
var
  s: string;
begin
  SetLength(s, 256);
  Win32Check(GetTimeFormatEx(PChar(LOCALE_NAME_USER_DEFAULT), 0, 0, 'HH:mm:ss', Pointer(s), Length(s)) > 0);
  lblTime.Caption := s;
  Win32Check(GetDateFormatEx(PChar(LOCALE_NAME_USER_DEFAULT),  0, 0, 'dddd, d MMMM', Pointer(s), Length(s), 0) > 0);
  lblDate.Caption := s;
end;

procedure TLockForm.WmShowForm(var Message: TMessage);
begin
  if Visible then
    Exit;

  Application.NormalizeAllTopMosts;
  try
    FormStyle := fsStayOnTop;
    if FAutoLock then
      begin
        LockForm.ApplyLayeredWindow(true, 100);
        LockForm.DisableWindowForRecord(true);
        LockForm.DisableInput(true);
      end;
    BoundsRect := Rect(0, 0, Screen.Width, Screen.Height);
    Left := 0;
    Top := 0;

    ShowModal;
  finally
    if FAutoLock then
      begin
        LockForm.DisableInput(false);
      end;

    Application.RestoreTopMosts;
  end;
end;

procedure TLockForm.WndProc(var Message: TMessage);
begin
  if (Message.Msg = WM_SYSCOMMAND) and
     (Message.WParam = SC_KEYMENU)
     then Exit;

  inherited WndProc(Message);
end;

end.
