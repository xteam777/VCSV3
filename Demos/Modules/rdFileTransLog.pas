﻿unit rdFileTransLog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, CommonUtils,
  rtcPortalMod, rtcpFileTrans, rtcpFileTransUI, CommonData, uVircessTypes;

type
  TrdFileTransferLog = class(TForm)
    mLog: TMemo;
    pBottom: TPanel;
    myUI: TRtcPFileTransferUI;
    bOK: TButton;
    procedure bOKClick(Sender: TObject);
    procedure myUIClose(Sender: TRtcPFileTransferUI);
    procedure myUIError(Sender: TRtcPFileTransferUI);
    procedure myUIInit(Sender: TRtcPFileTransferUI);
    procedure myUILogOut(Sender: TRtcPFileTransferUI);
    procedure myUIOpen(Sender: TRtcPFileTransferUI);
    procedure myUIRecv(Sender: TRtcPFileTransferUI);
    procedure myUIRecvCancel(Sender: TRtcPFileTransferUI);
    procedure myUIRecvStart(Sender: TRtcPFileTransferUI);
    procedure myUISend(Sender: TRtcPFileTransferUI);
    procedure myUISendCancel(Sender: TRtcPFileTransferUI);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure myUISendStart(Sender: TRtcPFileTransferUI);
  private
    { Private declarations }
    FOnUIOpen: TUIOpenEvent;
    FOnUIClose: TUICloseEvent;

    FReady: boolean;

    procedure SetCaption;

    procedure CreateParams(Var params: TCreateParams); override;

    procedure Form_Open(const mode:string);
    procedure Form_Close(const mode:string);

    procedure MyOnFileList(Sender:TRtcPFileTransferUI);
  public
    { Public declarations }
    UIVisible: Boolean;
    property UI:TRtcPFileTransferUI read myUI;

    property OnUIOpen: TUIOpenEvent read FOnUIOpen write FOnUIOpen;
    property OnUIClose: TUICloseEvent read FOnUIClose write FOnUIClose;
  end;

var
  rdFileTransferLog: TrdFileTransferLog;

implementation

{$R *.dfm}

procedure TrdFileTransferLog.CreateParams(Var params: TCreateParams);
begin
  inherited CreateParams( params );
  params.ExStyle := params.ExStyle   or WS_EX_APPWINDOW;
  params.WndParent := GetDeskTopWindow;
end;

procedure TrdFileTransferLog.SetCaption;
begin
  Caption := GetUserFromFromUserName(myUI.UserName) + ' - Лог передачи файлов';
end;

procedure TrdFileTransferLog.Form_Open(const mode: string);
begin
  SetCaption;

//  Caption := {mode +} myUI.UserDesc + ' - Files transferring log';

//  cUserName.Caption:=myUI.UserName;
//  cTitleBar.Caption:=mode+'Files';

  FReady := True;
end;

procedure TrdFileTransferLog.Form_Close(const mode: string);
begin
//  cUserName.Caption:=myUI.UserName;
//  cTitleBar.Caption:='('+mode+')';

  FReady:=False;
end;

procedure TrdFileTransferLog.bOKClick(Sender: TObject);
begin
  Close;
end;

procedure TrdFileTransferLog.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;
begin
  Action:=caFree;

  if Assigned(FOnUIClose) then
    FOnUIClose('file', myUI.UserName); //ThreadID
end;

procedure TrdFileTransferLog.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Hide;

  CanClose:=myUI.CloseAndClear;
end;

procedure TrdFileTransferLog.myUIClose(Sender: TRtcPFileTransferUI);
var
  sDate: String;
begin
  DateTimeToString(sDate, 'dd.mm.yyyy hh:nn:ss', Now);
  mLog.Lines.Add(sDate + ': Ïåðåäà÷à ôàéëîâ çàâåðøåíà');

  Form_Close('Closed');
  Close;
end;

procedure TrdFileTransferLog.myUIError(Sender: TRtcPFileTransferUI);
begin
  Form_Close('DISCONNECTED');
  // we disconnected. Can not use this FileTransfer window anymore.
  myUI.Module:=nil;
  Close;
end;

procedure TrdFileTransferLog.myUIInit(Sender: TRtcPFileTransferUI);
var
  sDate: String;
begin
  if not FReady then Form_Open('(Init) ');

  DateTimeToString(sDate, 'dd.mm.yyyy hh:nn:ss', Now);
  mLog.Lines.Add(sDate + ': Инициализация передачи файлов...');
end;

procedure TrdFileTransferLog.myUILogOut(Sender: TRtcPFileTransferUI);
begin
  Close;
end;

procedure TrdFileTransferLog.myUIOpen(Sender: TRtcPFileTransferUI);
  var
    fIsPending: Boolean;
  begin
//  if Assigned(FOnUIOpen) then
//    FOnUIOpen(myUI.UserName, 'file', fIsPending);
//
//  if not fIsPending then
//  begin
//    Close;
//    Exit;
//  end
//  else
  if UIVisible then
  begin
    Show;
    BringToFront;
    //BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
  end;

  Form_Open('');

//  mLog.Lines.Add('Начата передача файлов');

//  Caption:=myUI.UserName+' - Files transferring';
  SetCaption;
//  MyUI.OnFileList:=MyOnFileList;
//  myUI.GetFileList('',''); // load remote drives list to initialize
  end;

procedure TrdFileTransferLog.myUIRecv(Sender: TRtcPFileTransferUI);
begin
//  if myUI.Recv_FirstTime then
//    begin
//    if pMain.ActivePage<>pReceiving then
//      pMain.ActivePage:=pReceiving;
//    gRecvCurrent.ForeColor:=clNavy;
//    gRecvTotal.ForeColor:=clGreen;
//    end;
//
//  if myUI.Recv_FileCount>1 then
//    lRecvFileName.Caption:='['+IntToStr(myUI.Recv_FileCount)+'] '+myUI.Recv_FileName
//  else
//    lRecvFileName.Caption:=myUI.Recv_FileName;
//
//  if myUI.Recv_ToFolder='' then
//    lRecvToFolder.Caption:='INBOX'
//  else
//    lRecvToFolder.Caption:=myUI.Recv_ToFolder;
//
//  lRecvCurrent.Caption:=Format('%.0n / %.0n KB', [myUI.Recv_FileIn/1024, myUI.Recv_FileSize/1024]);
//  lRecvTotal.Caption:=Format('%.0n / %.0n KB', [myUI.Recv_BytesComplete/1024, myUI.Recv_BytesTotal/1024]);
//
//  if myUI.Recv_FileSize>0 then
//    gRecvCurrent.Progress:=round(myUI.Recv_FileIn/myUI.Recv_FileSize*10000)
//  else
//    gRecvCurrent.Progress:=0;
//
//  if myUI.Recv_BytesTotal>0 then
//    gRecvTotal.Progress:=round(myUI.Recv_BytesComplete/myUI.Recv_BytesTotal*10000)
//  else
//    gRecvTotal.Progress:=0;
//
//  if (myUI.Recv_FileCount=0) and (myUI.Recv_BytesComplete=myUI.Recv_BytesTotal) then
//    begin
//    gRecvCurrent.ForeColor:=clSilver;
//    gRecvTotal.ForeColor:=clSilver;
//
//    lRecvTime.Caption:='DONE. Completed in '+myUI.Recv_TotalTime;
//    lRecvSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Recv_KBit/1]);
//
//    if myUI.Recv_ToFolder='' then
//      btnOpenInboxClick(nil);
//    end
//  else if myUI.Recv_BytesComplete>0 then
//    begin
//    lRecvSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Recv_KBit/1]);
//    lRecvTime.Caption:='Estimated completion in '+myUI.Recv_ETA;
//    end
//  else
//    begin
//    lRecvSpeed.Caption:='';
//    lRecvTime.Caption:='';
//    end;
end;

procedure TrdFileTransferLog.myUIRecvCancel(Sender: TRtcPFileTransferUI);
var
  sDate: String;
begin
  DateTimeToString(sDate, 'dd.mm.yyyy hh:nn:ss', Now);
  if myUI.Recv_FileCount>1 then
    mLog.Lines.Add(sDate + ': Получение отменено ' + myUI.Recv_ToFolder + '\' + '[' + IntToStr(myUI.Recv_FileCount) + '] ' + myUI.Recv_FileName)
  else
    mLog.Lines.Add(sDate + ': Получение отменено ' + myUI.Recv_ToFolder + '\' + myUI.Recv_FileName);
//  lRecvFileName.Caption:='Cancelled';
end;

procedure TrdFileTransferLog.myUIRecvStart(Sender: TRtcPFileTransferUI);
var
  sDate: String;
begin
  DateTimeToString(sDate, 'dd.mm.yyyy hh:nn:ss', Now);
 if myUI.Recv_FirstTime then
  begin
    if myUI.Recv_FileCount > 1 then
      mLog.Lines.Add(sDate + ': Получение ' + myUI.Recv_ToFolder + '\' + '[' + IntToStr(myUI.Recv_FileCount) + '] ' + myUI.Recv_FileName)
    else
      mLog.Lines.Add(sDate + ': Получение ' + myUI.Recv_ToFolder + '\' + myUI.Recv_FileName);
  end;

//  if myUI.Recv_FirstTime then
//    begin
//    if pMain.ActivePage<>pReceiving then
//      pMain.ActivePage:=pReceiving;
//    gRecvCurrent.ForeColor:=clNavy;
//    gRecvTotal.ForeColor:=clGreen;
//    end;
//
//  if myUI.Recv_FileCount>1 then
//    lRecvFileName.Caption:='['+IntToStr(myUI.Recv_FileCount)+'] '+myUI.Recv_FileName
//  else
//    lRecvFileName.Caption:=myUI.Recv_FileName;
//
//  if myUI.Recv_ToFolder='' then
//    lRecvToFolder.Caption:='INBOX'
//  else
//    lRecvToFolder.Caption:=myUI.Recv_ToFolder;
//
//  lRecvCurrent.Caption:=Format('%.0n / %.0n KB', [myUI.Recv_FileIn/1024, myUI.Recv_FileSize/1024]);
//  lRecvTotal.Caption:=Format('%.0n / %.0n KB', [myUI.Recv_BytesComplete/1024, myUI.Recv_BytesTotal/1024]);
//
//  if myUI.Recv_FileSize>0 then
//    gRecvCurrent.Progress:=round(myUI.Recv_FileIn/myUI.Recv_FileSize*10000)
//  else
//    gRecvCurrent.Progress:=0;
//
//  if myUI.Recv_BytesTotal>0 then
//    gRecvTotal.Progress:=round(myUI.Recv_BytesComplete/myUI.Recv_BytesTotal*10000)
//  else
//    gRecvTotal.Progress:=0;
//
//  if (myUI.Recv_FileCount=0) and (myUI.Recv_BytesComplete=myUI.Recv_BytesTotal) then
//    begin
//    gRecvCurrent.ForeColor:=clSilver;
//    gRecvTotal.ForeColor:=clSilver;
//
//    lRecvTime.Caption:='DONE. Completed in '+myUI.Recv_TotalTime;
//    lRecvSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Recv_KBit/1]);
//
//    if myUI.Recv_ToFolder='' then
//      btnOpenInboxClick(nil);
//    end
//  else if myUI.Recv_BytesComplete>0 then
//    begin
//    lRecvSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Recv_KBit/1]);
//    lRecvTime.Caption:='Estimated completion in '+myUI.Recv_ETA;
//    end
//  else
//    begin
//    lRecvSpeed.Caption:='';
//    lRecvTime.Caption:='';
//    end;
end;

procedure TrdFileTransferLog.myUISend(Sender: TRtcPFileTransferUI);
begin
//  lSendFromFolder.Caption := myUI.Send_FromFolder;

//  if myUI.Send_FirstTime then
//    begin
//    if pMain.ActivePage<>pSending then
//      pMain.ActivePage:=pSending;
//
//    gSendCurrent.ForeColor:=clNavy;
//    gSendTotal.ForeColor:=clTeal;
//    gSendCompleted.ForeColor:=clGreen;
//    end;
//
//  if myUI.Send_FileCount>1 then
//    lSendFileName.Caption:='['+IntToStr(myUI.Send_FileCount)+'] '+myUI.Send_FileName
//  else
//    lSendFileName.Caption:=myUI.Send_FileName;
//
//  lSendFromFolder.Caption:=myUI.Send_FromFolder;
//
//  lSendCurrent.Caption:=Format('%.0n / %.0n KB', [myUI.Send_FileOut/1024,myUI.Send_FileSize/1024]);
//  lSendTotal.Caption:=Format('%.0n / %.0n KB', [myUI.Send_BytesPrepared/1024, myUI.Send_BytesTotal/1024]);
//  lSendCompleted.Caption:=Format('%.0n / %.0n KB', [myUI.Send_BytesComplete/1024, myUI.Send_BytesTotal/1024]);
//
//  if myUI.Send_FileSize>0 then
//    gSendCurrent.Progress:=round(myUI.Send_FileOut/myUI.Send_FileSize*10000)
//  else
//    gSendCurrent.Progress:=0;
//
//  if myUI.Send_BytesTotal>0 then
//    begin
//    gSendTotal.Progress:=round(myUI.Send_BytesPrepared/myUI.Send_BytesTotal*10000);
//    gSendCompleted.Progress:=round(myUI.Send_BytesComplete/myUI.Send_BytesTotal*10000);
//    end
//  else
//    begin
//    gSendTotal.Progress:=0;
//    gSendCompleted.Progress:=0;
//    end;
//
//  if (myUI.Send_FileCount=0) and (myUI.Send_BytesComplete=myUI.Send_BytesTotal) then
//    begin
//    gSendCurrent.ForeColor:=clSilver;
//    gSendTotal.ForeColor:=clSilver;
//    gSendCompleted.ForeColor:=clSilver;
//
//    lSendTime.Caption:='DONE. Completed in '+myUI.Send_TotalTime;
//    lSendSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Send_KBit/1]);
//    end
//  else if myUI.Send_BytesComplete>0 then
//    begin
//    lSendSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Send_KBit/1]);
//    lSendTime.Caption:='Estimated completion in '+myUI.Send_ETA;
//    end
//  else
//    begin
//    lSendSpeed.Caption:='';
//    lSendTime.Caption:='';
//    end;
end;

procedure TrdFileTransferLog.myUISendCancel(Sender: TRtcPFileTransferUI);
var
  sDate: String;
begin
  DateTimeToString(sDate, 'dd.mm.yyyy hh:nn:ss', Now);
  if myUI.Send_FileCount > 1 then
    mLog.Lines.Add(sDate + ': Отправка отменена ' + myUI.Send_FromFolder + ' [' + IntToStr(myUI.Send_FileCount) + '] '+ myUI.Send_FileName)
  else
    mLog.Lines.Add(sDate + ': Отправка отменена ' + myUI.Send_FromFolder + myUI.Send_FileName);

//  lSendFileName.Caption:='Cancelled';
end;

procedure TrdFileTransferLog.myUISendStart(Sender: TRtcPFileTransferUI);
var
  sDate: String;
begin
  DateTimeToString(sDate, 'dd.mm.yyyy hh:nn:ss', Now);
  if myUI.Send_FirstTime then
  begin
    if myUI.Send_FileCount > 1 then
      mLog.Lines.Add(sDate + ': Отправка ' + myUI.Send_FromFolder + ' [' + IntToStr(myUI.Send_FileCount) + '] '+ myUI.Send_FileName)
    else
      mLog.Lines.Add(sDate + ': Отправка ' + myUI.Send_FromFolder + myUI.Send_FileName);
  end;
end;

procedure TrdFileTransferLog.MyOnFileList(Sender: TRtcPFileTransferUI);
begin
//  eLocalDirectory.Text := '';
end;

end.
