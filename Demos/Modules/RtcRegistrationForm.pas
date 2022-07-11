unit RtcRegistrationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.jpeg,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.AppEvnts, rtcCliModule, rtcInfo,
  rtcConn, rtcFunction, uVircessTypes, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdComponent, IdTCPConnection,
  IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase,
  IdSMTP, IdBaseComponent, IdAntiFreezeBase, IdMessage,
  rtcDataCli, rtcHttpCli, rtcSystem, IdAntiFreeze;

type
  TRegistrationForm = class(TForm)
    PageControl1: TPageControl;
    tsAccount: TTabSheet;
    Label1: TLabel;
    Image1: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    eAccountName: TEdit;
    eEmail: TEdit;
    ePassword: TEdit;
    ePasswordConfirm: TEdit;
    Panel1: TPanel;
    tsDevice: TTabSheet;
    Label5: TLabel;
    Label10: TLabel;
    eDevicePasswordConfirm: TEdit;
    eDevicePassword: TEdit;
    eDeviceName: TEdit;
    Label11: TLabel;
    Panel2: TPanel;
    Image2: TImage;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Panel3: TPanel;
    bNext1: TSpeedButton;
    Panel4: TPanel;
    bClose1: TSpeedButton;
    Panel5: TPanel;
    bNext2: TSpeedButton;
    Panel6: TPanel;
    bClose2: TSpeedButton;
    Panel7: TPanel;
    bBack2: TSpeedButton;
    bhMain: TBalloonHint;
    ApplicationEvents1: TApplicationEvents;
    rAddAccount: TRtcResult;
    tsConfirm: TTabSheet;
    eConfirmationCode: TEdit;
    Label15: TLabel;
    Image3: TImage;
    Panel8: TPanel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Panel9: TPanel;
    bBack3: TSpeedButton;
    Panel10: TPanel;
    bOk: TSpeedButton;
    Panel11: TPanel;
    SpeedButton3: TSpeedButton;
    pResendConfirm: TPanel;
    bResendConfirm: TSpeedButton;
    IdAntiFreeze: TIdAntiFreeze;
    IdSMTP: TIdSMTP;
    IdSSL: TIdSSLIOHandlerSocketOpenSSL;
    pRegistration: TPanel;
    bBack1: TSpeedButton;
    HTTPRequest: TRtcDataRequest;
    HTTPClient: TRtcHttpClient;
    procedure bClose1Click(Sender: TObject);
    procedure bNext1Click(Sender: TObject);
    procedure bBack2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure eAccountNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure rAddAccountReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure bOkClick(Sender: TObject);
    procedure bNext2Click(Sender: TObject);
    procedure bResendConfirmClick(Sender: TObject);
    procedure bBack3Click(Sender: TObject);
    procedure HTTPRequestBeginRequest(Sender: TRtcConnection);
    procedure HTTPRequestDataReceived(Sender: TRtcConnection);
    procedure eDeviceNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure eConfirmationCodeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    {  declarations }
    function CheckAccountFields: Boolean;
    function CheckDeviceFields: Boolean;
    procedure SendConfirmationMessage;
  public
    CModule: TRtcClientModule;
    ThisDeviceID: String;
    ConfirmationCode: String;
    MF_AccountName, MF_AccountPass: TEdit;

    AccountLoginProcedure: TExecuteProcedure;
    { Public declarations }
  end;

var
  RegistrationForm: TRegistrationForm;

implementation

{$R *.dfm}

procedure TRegistrationForm.bNext1Click(Sender: TObject);
begin
  if CheckAccountFields then
  begin
    tsAccount.PageControl.ActivePage := tsAccount.PageControl.Pages[1];
    eDeviceName.SetFocus;
  end;
end;

procedure TRegistrationForm.bNext2Click(Sender: TObject);
begin
  if CheckDeviceFields then
  begin
    tsAccount.PageControl.ActivePage := tsAccount.PageControl.Pages[2];
    eConfirmationCode.SetFocus;
    SendConfirmationMessage;
  end;
end;

procedure TRegistrationForm.bOkClick(Sender: TObject);
begin
  if Trim(eConfirmationCode.Text) <> ConfirmationCode then
  begin
    bhMain.Description := 'Введен неверный код подтверждения';
    bhMain.ShowHint(eConfirmationCode);

    eConfirmationCode.SetFocus;
    Exit;
  end;

  with CModule, Data.NewFunction('AddAccount') do
  begin
    asWideString['Email'] := Trim(eEmail.Text);
    asWideString['Name'] := Trim(eAccountName.Text);
    asWideString['Pass'] := Trim(ePassword.Text);
    asString['DeviceID'] := ThisDeviceID;
    asWideString['DeviceName'] := Trim(eDeviceName.Text);
    asWideString['DevicePass'] := Trim(eDevicePassword.Text);
    Call(rAddAccount);
  end;
end;

procedure TRegistrationForm.bResendConfirmClick(Sender: TObject);
begin
  SendConfirmationMessage;
end;

procedure TRegistrationForm.SendConfirmationMessage;
begin
  with HTTPRequest do
  begin
    Request.Method := 'POST';

    // request the file defined in the Edit field
    Request.FileName := '/emailconfirm.php?lang=ru&accountname=' + Trim(eAccountName.Text) + '&email=' + Trim(eEmail.Text) + '&confirmationcode=' + ConfirmationCode;
    Post; // Post the request
  end;
end;

function TRegistrationForm.CheckAccountFields: Boolean;
var
  sSymbols: String;
  i: Integer;
  s: String;
  HasDots: Boolean;
begin
  Result := True;

  sSymbols := '0123456789abcdefghiklmnopqrstuvwxyz';
  if Length(LowerCase(eEmail.Text)) < 6 then
  begin
//    bhMain.Description := 'Адрес электронной почты должен состоять из 6 и более символов';
//    bhMain.ShowHint(eEmail);

    eEmail.SetFocus;
    eEmail.SelectAll;
    MessageBox(Handle, 'Адрес электронной почты должен состоять из 6 и более символов', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;
  for i := 1 to Length(eEmail.Text) do
    if (AnsiPos(LowerCase(eEmail.Text[i]), sSymbols) = 0)
      and (eEmail.Text[i] <> '@')
      and (eEmail.Text[i] <> '.') then
    begin
//      bhMain.Description := 'Адрес электронной почты должен содержать только буквы и цифры';
//      bhMain.ShowHint(eEmail);

      eEmail.SetFocus;
      eEmail.SelectAll;
      MessageBox(Handle, 'Адрес электронной почты должен содержать только буквы и цифры', 'VIRCESS', MB_ICONWARNING or MB_OK);
      Result := False;
      Exit;
    end;
  HasDots := False;
  i := AnsiPos('.', eEmail.Text);
  if i <> 0 then
  begin
    s := Copy(eEmail.Text, 1, i);
    if AnsiPos('.', s) <> 0 then
      HasDots := True;
  end;
  if (AnsiPos('@', LowerCase(eEmail.Text)) = 0)
    or (not HasDots) then
  begin
//    bhMain.Description := 'Неверно указан адрес электронной почты';
//    bhMain.ShowHint(eEmail);

    eEmail.SetFocus;
    eEmail.SelectAll;
    MessageBox(Handle, 'Неверно указан адрес электронной почты', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;

  if Length(LowerCase(eAccountName.Text)) = 0 then
  begin
//    bhMain.Description := 'Не указано имя';
//    bhMain.ShowHint(eAccountName);

    eAccountName.SetFocus;
    eAccountName.SelectAll;
    MessageBox(Handle, 'Не указано имя', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;
  if Length(LowerCase(eAccountName.Text)) < 3 then
  begin
//    bhMain.Description := 'Имя должно состоять из 3 и более символов';
//    bhMain.ShowHint(eAccountName);

    eAccountName.SetFocus;
    eAccountName.SelectAll;
    MessageBox(Handle, 'Имя должно состоять из 3 и более символов', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;
  for i := 1 to Length(eAccountName.Text) do
    if AnsiPos(LowerCase(eAccountName.Text[i]), sSymbols) = 0 then
    begin
//      bhMain.Description := 'Имя должно содержать только буквы и цифры';
//      bhMain.ShowHint(eAccountName);

      eAccountName.SetFocus;
      eAccountName.SelectAll;
      MessageBox(Handle, 'Имя должно содержать только буквы и цифры', 'VIRCESS', MB_ICONWARNING or MB_OK);
      Result := False;
      Exit;
    end;

  if ePassword.Text <> ePasswordConfirm.Text then
  begin
//    bhMain.Description := 'Пароль и его подтверждение не совпадают';
//    bhMain.ShowHint(ePassword);

    ePassword.SetFocus;
    ePassword.SelectAll;
    MessageBox(Handle, 'Пароль и его подтверждение не совпадают', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;

  with CModule do
  begin
    Prepare('Account.EmailIsExists');
    Param.asWideString['Email'] := Trim(eEmail.Text);
    Execute;
    if LastResult.asBoolean then
    begin
//      bhMain.Description := 'Пользователь с таким адресом электронной почты уже зарегистрирован';
//      bhMain.ShowHint(eEmail);

      eEmail.SetFocus;
      eEmail.SelectAll;
      MessageBox(Handle, 'Пользователь с таким адресом электронной почты уже зарегистрирован', 'VIRCESS', MB_ICONWARNING or MB_OK);
      Result := False;
      Exit;
    end;
  end;
end;

function TRegistrationForm.CheckDeviceFields: Boolean;
begin
  Result := True;
  if Trim(eDeviceName.Text) = '' then
  begin
    //bhMain.Description := 'Не указано название компьютера';
    //bhMain.ShowHint(eDeviceName);

    eDeviceName.SetFocus;
    eDeviceName.SelectAll;
    MessageBox(Handle, 'Не указано название компьютера', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;
  if eDevicePassword.Text <> eDevicePasswordConfirm.Text then
  begin
//    bhMain.Description := 'Пароль компьютера и его подтверждение не совпадают';
//    bhMain.ShowHint(eDevicePassword);

    eDevicePassword.SetFocus;
    eDevicePassword.SelectAll;
    MessageBox(Handle, 'Пароль компьютера и его подтверждение не совпадают', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Result := False;
    Exit;
  end;
end;

procedure TRegistrationForm.eAccountNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Mgs: TMsg;
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);

  if Key = VK_RETURN then
    bNext1Click(Sender)
  else if Key = VK_ESCAPE then
    bClose1Click(Sender);
end;

procedure TRegistrationForm.eConfirmationCodeKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  Mgs: TMsg;
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);

  if Key = VK_RETURN then
    bOkClick(Sender)
  else if Key = VK_ESCAPE then
    bClose1Click(Sender);
end;

procedure TRegistrationForm.eDeviceNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Mgs: TMsg;
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);

  if Key = VK_RETURN then
    bNext2Click(Sender)
  else if Key = VK_ESCAPE then
    bClose1Click(Sender);
end;

procedure TRegistrationForm.FormCreate(Sender: TObject);
var
  MyGUID : TGUID;
begin
  CreateGUID(MyGUID);
  ConfirmationCode := GUIDToString(MyGUID);
  ConfirmationCode := StringReplace(ConfirmationCode, '{', '', [rfReplaceAll]);
  ConfirmationCode := StringReplace(ConfirmationCode, '}', '', [rfReplaceAll]);
  ConfirmationCode := StringReplace(ConfirmationCode, '-', '', [rfReplaceAll]);

  tsAccount.PageControl.ActivePage := tsAccount.PageControl.Pages[0];
end;

procedure TRegistrationForm.FormShow(Sender: TObject);
begin
  eEmail.SetFocus;
end;

procedure TRegistrationForm.HTTPRequestBeginRequest(Sender: TRtcConnection);
begin
 with TRtcDataClient(Sender) do
    begin
    // make sure our request starts with "/"
    if Copy(Request.FileName,1,1) <> '/' then
      Request.FileName:='/' + Request.FileName;

    // define the "HOST" header
    if Request.Host = '' then
      Request.Host := ServerAddr;
//    lblStatus.Caption := 'Requesting "' + Request.FileName+
//                '" from "' + ServerAddr + '".';

    // send request header out
    WriteHeader;
    end;
end;

procedure TRegistrationForm.HTTPRequestDataReceived(Sender: TRtcConnection);
begin
//  with TRtcDataClient(Sender) do
//    if Response.Done then
//      ShowMessage(Read);
end;

procedure TRegistrationForm.rAddAccountReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
var
  GroupUID, pResult: String;
begin
  if Result.isType = rtc_Exception then
  begin
    MessageBox(Handle, PWideChar(Result.asException), 'VIRCESS', MB_ICONWARNING or MB_OK);
    Exit;
  end
  else
  if Result.isType <> rtc_String then
  begin
    MessageBox(Handle, 'Invalid Server Response.', 'VIRCESS', MB_ICONWARNING or MB_OK);
    Exit;
  end
  else
  if Result.asString = 'BUSY' then
  begin
    eEmail.SetFocus;
    eEmail.SelectAll;
    MessageBox(Handle, 'Пользователь с таким адресом электронной почты уже зарегистрирован.', 'VIRCESS', MB_ICONWARNING or MB_OK);
  end
  else
  begin
    MF_AccountName.Text := eEmail.Text;
    MF_AccountPass.Text := ePassword.Text;
    AccountLoginProcedure;
    Close;
  end;
end;

procedure TRegistrationForm.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  if Msg.message = WM_KEYUP then
    case Msg.wParam of
      VK_RETURN:
        begin
          if tsAccount.PageControl.ActivePage = tsAccount.PageControl.Pages[0] then
            bNext1Click(nil)
          else
          if tsAccount.PageControl.ActivePage = tsAccount.PageControl.Pages[1] then
            bNext2Click(nil)
          else
          if tsAccount.PageControl.ActivePage = tsAccount.PageControl.Pages[2] then
            bOKClick(nil);
          Handled := True;
        end;
      VK_ESCAPE:
        begin
          bClose1Click(nil);
          Handled := True;
        end;
      15:
        Handled := True
    end;
end;

procedure TRegistrationForm.bBack2Click(Sender: TObject);
begin
  tsAccount.PageControl.ActivePage := tsAccount.PageControl.Pages[0];
  eEmail.SetFocus;
end;

procedure TRegistrationForm.bBack3Click(Sender: TObject);
begin
  tsAccount.PageControl.ActivePage := tsAccount.PageControl.Pages[1];
  eDeviceName.SetFocus;
end;

procedure TRegistrationForm.bClose1Click(Sender: TObject);
begin
  Close;
end;

end.
