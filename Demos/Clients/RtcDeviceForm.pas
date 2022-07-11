unit RtcDeviceForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, rtcInfo, rtcConn, rtcCliModule,
  rtcFunction, Vcl.Buttons, Vcl.ExtCtrls, VirtualTrees, uVircessTypes;

type
  TDeviceForm = class(TForm)
    Label6: TLabel;
    eID: TEdit;
    pBtnClose: TPanel;
    bClose: TSpeedButton;
    pBtnOK: TPanel;
    bOK: TSpeedButton;
    Panel2: TPanel;
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
    procedure bCloseClick(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure rAddDeviceReturn(Sender: TRtcConnection; Data, Result: TRtcValue);
    procedure rChangeDeviceReturn(Sender: TRtcConnection; Data,
      Result: TRtcValue);
    procedure cbGroupChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    CModule: TRtcClientModule;
    twDevices: TVirtualStringTree;
    ActionResult: TModalResult;
    Mode: String;
    UID: String;
    AccountUID: String;
    GroupUID: String;
  end;

var
  DeviceForm: TDeviceForm;

implementation

{$R *.dfm}

procedure TDeviceForm.bCloseClick(Sender: TObject);
begin
  ActionResult := mrCancel;
  Close;
end;

procedure TDeviceForm.bOKClick(Sender: TObject);
var
  i: Integer;
begin
  eID.Text := StringReplace(eID.Text, ' ', '', [rfReplaceAll]);
  if eID.Text = '' then
  begin
    MessageBox(Handle, 'Не указано ID компьютера', 'VIRCESS', MB_ICONWARNING or MB_OK);
    eID.SetFocus;
    Exit;
  end;
  for i := 1 to Length(eID.Text) do
  begin
    if Pos(Copy(eID.Text, i, 1), '0123456789') = 0 then
    begin
      MessageBox(Handle, 'ID компьютера может содержать только цифры', 'VIRCESS', MB_ICONWARNING or MB_OK);
      eID.SetFocus;
      Exit;            
    end;
  end;
    
  if Trim(eName.Text) = '' then
  begin
    MessageBox(Handle, 'Не указано имя компьютера', 'VIRCESS', MB_ICONWARNING or MB_OK);
    eName.SetFocus;
    Exit;
  end;
  if cbGroup.ItemIndex = -1 then
  begin
    MessageBox(Handle, 'Не указана группа', 'VIRCESS', MB_ICONWARNING or MB_OK);
    cbGroup.SetFocus;
    Exit;
  end;

  if Mode = 'Add' then
  begin
    with CModule.Data.NewFunction('Account.AddDevice') do
    begin
      asWideString['Name'] := eName.Text;
      asString['UID'] := UID;
      asString['AccountUID'] := AccountUID;
      asString['GroupUID'] := GroupUID;
      asInteger['DeviceID'] := StrToInt(eID.Text);
      asWideString['Password'] := ePassword.Text;
      asWideString['Description'] := mDescription.Lines.GetText;
    end;
    CModule.Call(rAddDevice);
  end
  else
  begin
    with CModule.Data.NewFunction('Account.ChangeDevice') do
    begin
      asWideString['Name'] := eName.Text;
      asString['UID'] := UID;
      asString['AccountUID'] := AccountUID;
      asString['GroupUID'] := GroupUID;
      asInteger['DeviceID'] := StrToInt(eID.Text);
      asWideString['Password'] := ePassword.Text;
      asWideString['Description'] := mDescription.Lines.GetText;
    end;
    CModule.Call(rChangeDevice);
  end
end;

procedure TDeviceForm.cbGroupChange(Sender: TObject);
begin
  GroupUID := TDeviceGroup(cbGroup.Items.Objects[cbGroup.ItemIndex]).UID;
end;

procedure TDeviceForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    bOK.Click
  else if Key = VK_ESCAPE then
    bClose.Click;
end;

procedure TDeviceForm.FormShow(Sender: TObject);
var
  Node: PVirtualNode;
  GData: TDeviceGroup;
  DData: PDeviceData;
begin
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

procedure TDeviceForm.rAddDeviceReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  UID := Result.asString;
  ActionResult := mrOk;
  Close;
end;

procedure TDeviceForm.rChangeDeviceReturn(Sender: TRtcConnection; Data,
  Result: TRtcValue);
begin
  ActionResult := mrOk;
  Close;
end;


end.
