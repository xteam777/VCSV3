unit RtcDeviceForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, rtcInfo, rtcConn, rtcCliModule,
  rtcFunction, Vcl.Buttons, Vcl.ExtCtrls, VirtualTrees, uVircessTypes,
  Vcl.AppEvnts, rtcSystem;

type
  PRtcClientModule = ^TRtcClientModule;

  TDeviceForm = class(TForm)
    Label6: TLabel;
    eID: TEdit;
    rAddDevice: TRtcResult;
    rChangeDevice: TRtcResult;
    Label1: TLabel;
    ePassword: TEdit;
    Label2: TLabel;
    eName: TEdit;
    Label3: TLabel;
    cbGroup: TComboBox;
    Label4: TLabel;
    mDescription: TMemo;
    ApplicationEvents1: TApplicationEvents;
    bOK: TButton;
    bClose: TButton;
    procedure bCloseClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rAddDeviceReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure rChangeDeviceReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure eIDKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rAddDeviceRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure rChangeDeviceRequestAborted(Sender: TRtcConnection; Data,
      Result: TRtcValue);
  private
    { Private declarations }
    FOnCustomFormClose: TOnCustomFormEvent;

    procedure EraseDeviceGroups;
  public
    { Public declarations }
    CModule: PRtcClientModule;
    twDevices: TVirtualStringTree;
    Mode: String;
    UID: String;
    AccountUID: String;
    user: String;
    GroupUID: String;
    GetDeviceInfoFunc: TGetDeviceInfoFunc;

    property OnCustomFormClose: TOnCustomFormEvent read FOnCustomFormClose write FOnCustomFormClose;
  end;

var
  DeviceForm: TDeviceForm;

implementation

{$R *.dfm}

procedure TDeviceForm.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  case Msg.message of
  WM_KEYDOWN:
    case Msg.wParam of
      VK_RETURN:
        begin
          Handled := True;
        end;
      VK_ESCAPE:
        begin
          Handled := True;
        end;
      15:
        Handled := True
    end;
  WM_KEYUP:
    case Msg.wParam of
      VK_RETURN:
        begin
          bOKClick(nil);
          Handled := True;
        end;
      VK_ESCAPE:
        begin
          bCloseClick(nil);
          Handled := True;
        end;
      15:
        Handled := True
    end;
  end;
end;

procedure TDeviceForm.bCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
  Close;
end;

procedure TDeviceForm.bOKClick(Sender: TObject);
var
  i: Integer;
  DData: PDeviceData;
begin
  eID.Text := StringReplace(eID.Text, ' ', '', [rfReplaceAll]);
  if eID.Text = '' then
  begin
    MessageBox(Handle, 'Не указано ID компьютера', 'Remox', MB_ICONWARNING or MB_OK);
    eID.SetFocus;
    Exit;
  end;
//  for i := 1 to Length(eID.Text) do
//  begin
//    if Pos(Copy(eID.Text, i, 1), '0123456789') = 0 then
  try
    i := StrToInt(eID.Text);
  except
    MessageBox(Handle, 'ID компьютера может содержать только цифры', 'Remox', MB_ICONWARNING or MB_OK);
    eID.SetFocus;
    Exit;
  end;
  DData := GetDeviceInfoFunc(eID.Text);
  if DData <> nil then
    if DData.UID <> UID then
    begin
      MessageBox(Handle, 'Компьютер с указанныс ID уже присутствует в списке', 'Remox', MB_ICONWARNING or MB_OK);
      eID.SetFocus;
      Exit;
    end;

  if Trim(eName.Text) = '' then
  begin
    MessageBox(Handle, 'Не указано имя компьютера', 'Remox', MB_ICONWARNING or MB_OK);
    eName.SetFocus;
    Exit;
  end;
  if cbGroup.ItemIndex = -1 then
  begin
    MessageBox(Handle, 'Не указана группа', 'Remox', MB_ICONWARNING or MB_OK);
    cbGroup.SetFocus;
    Exit;
  end;

  bOK.Enabled := False;

  GroupUID := TDeviceGroup(cbGroup.Items.Objects[cbGroup.ItemIndex]).UID;

  if Mode = 'Add' then
  begin
    with CModule^ do
    try
      with CModule^.Data.NewFunction('Account.AddDevice') do
      begin
        asString['User'] := user;
        asWideString['Name'] := eName.Text;
  //      asString['UID'] := UID;
        asString['AccountUID'] := AccountUID;
        asString['GroupUID'] := GroupUID;
        asInteger['DeviceID'] := StrToInt(eID.Text);
        asWideString['Password'] := ePassword.Text;
        asWideString['Description'] := mDescription.Lines.GetText;
      end;
      Call(rAddDevice);
    except
      on E: Exception do
        Data.Clear;
    end;
  end
  else
  begin
    with CModule^ do
    try
      with CModule^.Data.NewFunction('Account.ChangeDevice') do
      begin
        asWideString['Name'] := eName.Text;
        asString['UID'] := UID;
        asString['AccountUID'] := AccountUID;
        asString['GroupUID'] := GroupUID;
        asInteger['DeviceID'] := StrToInt(eID.Text);
        asWideString['Password'] := ePassword.Text;
        asWideString['Description'] := mDescription.Lines.GetText;
      end;
      Call(rChangeDevice);
    except
      on E: Exception do
        Data.Clear;
    end;
  end;
//  CModule^.WaitForCompletion(True, 1000, True);

//  if (CModule^.LastResult.isType = rtc_String)
//    and (CModule^.LastResult.asString = 'OK') then
//  begin
//    ModalResult := mrOk;
//    Close;
//  end;
end;

procedure TDeviceForm.eIDKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Mgs: TMsg;
begin
  if (Key = VK_RETURN)
    or (Key = VK_ESCAPE) then
    PeekMessage(Mgs, 0, WM_CHAR, WM_CHAR, PM_REMOVE);   //Убираем Beep

  if Key = VK_RETURN then
    bOKClick(Sender)
  else if Key = VK_ESCAPE then
    bCloseClick(Sender);
end;

procedure TDeviceForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnCustomFormClose) then
    FOnCustomFormClose(Handle);
end;

procedure TDeviceForm.FormDestroy(Sender: TObject);
begin
  EraseDeviceGroups;
end;

procedure TDeviceForm.EraseDeviceGroups;
var
  i: Integer;
begin
  for i := 0 to cbGroup.Items.Count - 1 do
    cbGroup.Items.Objects[i].Free;
//  cbGroup.Items.Clear;
end;

procedure TDeviceForm.FormShow(Sender: TObject);
var
  Node: PVirtualNode;
  GData: TDeviceGroup;
  DData: PDeviceData;
begin
  EraseDeviceGroups;

  Node := twDevices.GetFirst();
  while Node <> nil do
  begin
    DData := twDevices.GetNodeData(Node);

    GData := TDeviceGroup.Create;
    GData.Name := DData.Name;
    GData.UID := DData.UID;
    cbGroup.Items.AddObject(GData.Name, GData);

    if GData.UID = GroupUID then
      cbGroup.ItemIndex := cbGroup.Items.Count - 1;

    Node := Node.NextSibling;
  end;

  eID.SetFocus;
end;

procedure TDeviceForm.rAddDeviceRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  bOK.Enabled := True;
end;

procedure TDeviceForm.rAddDeviceReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  bOK.Enabled := True;

  if (Result.isType = rtc_String) then
  begin
    UID := Result.asString;
    ModalResult := mrOk;
    Close;
  end;
end;

procedure TDeviceForm.rChangeDeviceRequestAborted(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  bOK.Enabled := True;
end;

procedure TDeviceForm.rChangeDeviceReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  bOK.Enabled := True;

  if (Result.isType = rtc_String)
    and (Result.asString = 'OK') then
  begin
    ModalResult := mrOk;
    Close;
  end;
end;


end.
