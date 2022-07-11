{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

unit rdFileTrans;

interface

{$INCLUDE rtcDefs.inc}

uses
  Windows, Messages, SysUtils, CommonData, uVircessTypes,
  Classes, Graphics, Controls, Forms, rtcpFileUtils, rtcSystem,
  Dialogs, ShellAPI, Gauges, ExtCtrls, Math, CommonUtils,

  rtcInfo, Buttons, ComCtrls,

  rtcPortalMod, rtcpFileTrans, rtcpFileTransUI,
  rtcpFileExplore, Vcl.Menus, Vcl.StdCtrls;

type
  TrdFileTransfer = class(TForm)

    myUI: TRtcPFileTransferUI;
    pMiddle: TPanel;
    eRemoteFilesList: TRtcPFileExplorer;
    eLocalFilesList: TRtcPFileExplorer;
    pSubTop: TPanel;
    bLocalNewFolder: TSpeedButton;
    bLocalDelete: TSpeedButton;
    bUpload: TSpeedButton;
    bDownload: TSpeedButton;
    bRemoteDelete: TSpeedButton;
    bRemoteNewFolder: TSpeedButton;
    lLocal: TLabel;
    lRemote: TLabel;
    pTop: TPanel;
    bLocalBack: TSpeedButton;
    bLocalTop: TSpeedButton;
    LSplitter: TLabel;
    bRemoteBack: TSpeedButton;
    bRemoteTop: TSpeedButton;
    bLocalReload: TSpeedButton;
    bRemoteReload: TSpeedButton;
    eLocalDirectory: TEdit;
    eRemoteDirectory: TEdit;
    pBottom: TPanel;
    lSendSpeed: TLabel;
    lSendTime: TLabel;
    lSendCompleted: TLabel;
    lSendTotal: TLabel;
    lSendCurrent: TLabel;
    LabelSendFrom: TLabel;
    lSendFileName: TLabel;
    lSendFromFolder: TLabel;
    btnCancelSend: TSpeedButton;
    lUploading: TLabel;
    lRecvFrom: TLabel;
    lRecvSpeed: TLabel;
    lRecvTime: TLabel;
    lRecvTotal: TLabel;
    btnCancelFetch: TSpeedButton;
    lRecvCurrent: TLabel;
    lRecvToFolder: TLabel;
    lRecvFileName: TLabel;
    lDownloading: TLabel;
    gSendCurrent: TGauge;
    gSendCompleted: TGauge;
    gSendTotal: TGauge;
    gRecvTotal: TGauge;
    gRecvCurrent: TGauge;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure pTitlebarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pTitlebarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pTitlebarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnOpenInboxClick(Sender: TObject);

    procedure myUIInit(Sender: TRtcPFileTransferUI);
    procedure myUIOpen(Sender: TRtcPFileTransferUI);
    procedure myUIClose(Sender: TRtcPFileTransferUI);
    procedure myUIError(Sender: TRtcPFileTransferUI);
    procedure myUILogOut(Sender: TRtcPFileTransferUI);
    procedure myUIRecv(Sender: TRtcPFileTransferUI);
    procedure myUISend(Sender: TRtcPFileTransferUI);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lSendFromFolderClick(Sender: TObject);

    procedure myUIRecvCancel(Sender: TRtcPFileTransferUI);
    procedure myUISendCancel(Sender: TRtcPFileTransferUI);
    procedure btnCancelSendClick(Sender: TObject);
    procedure btnCancelFetchClick(Sender: TObject);
    procedure eRemoteFilesListDirectoryChange(Sender: TObject;
      const FileName: string);
    procedure eRemoteFilesListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure eRemoteFilesListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure eRemoteFilesListEdited(Sender: TObject; Item: TListItem; var S: string);
    procedure eRemoteFilesListEditing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure eRemoteFilesListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnExecuteClick(Sender: TObject);
    procedure mnDeleteClick(Sender: TObject);
    procedure mnDownloadClick(Sender: TObject);
    procedure bRemoteNewFolderClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure eRemoteFilesListFileOpen(Sender: TObject; const FileName: string);
    procedure eRemoteDirectory0KeyPress(Sender: TObject; var Key: Char);
    procedure btnRemoteViewStyleClick(Sender: TObject);
    procedure btnRemoteReloadClick(Sender: TObject);
    procedure bLocalBackClick(Sender: TObject);
    procedure bLocalNewFolderClick(Sender: TObject);
    procedure bLocalDeleteClick(Sender: TObject);
    procedure bLocalReloadClick(Sender: TObject);
    procedure eLocalDirectoryKeyPress(Sender: TObject; var Key: Char);
    procedure bRemoteReloadClick(Sender: TObject);
    procedure bRemoteTopClick(Sender: TObject);
    procedure bUploadClick(Sender: TObject);
    procedure eLocalFilesListDirectoryChange(Sender: TObject;
      const FileName: string);
    procedure eLocalFilesListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure eLocalFilesListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure eLocalFilesListEdited(Sender: TObject; Item: TListItem;
      var S: string);
    procedure eLocalFilesListEditing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure eLocalFilesListFileOpen(Sender: TObject; const FileName: string);
    procedure eLocalFilesListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure bLocalTopClick(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
    FAutoBrowse: boolean;

    FOnUIOpen: TUIOpenEvent;
    FOnUIClose: TUICloseEvent;
    
    procedure MyOnFileList(Sender:TRtcPFileTransferUI);
    
  protected
    FReady: boolean;

    procedure SetCaption;

    // declare our DROPFILES message handler
    procedure AcceptFiles( var msg : TMessage ); message WM_DROPFILES;
    procedure CreateParams(Var params: TCreateParams); override;

    procedure Form_Open(const mode:string);
    procedure Form_Close(const mode:string);

  public
    property UI:TRtcPFileTransferUI read myUI;

    // Automatically open a Remote File Explorer / Browser window when File Transfer window opens?
    property AutoExplore:boolean read FAutoBrowse write FAutoBrowse default False;

    property OnUIOpen: TUIOpenEvent read FOnUIOpen write FOnUIOpen;
    property OnUIClose: TUICloseEvent read FOnUIClose write FOnUIClose;
  end;

implementation

{$R *.dfm}

{ TrdFileTransfer }

var
  LMouseX,LMouseY:integer;
  LMouseD:boolean=False;

procedure TrdFileTransfer.pTitlebarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
  LMouseD:=True;
  LMouseX:=X;LMouseY:=Y;
  end;

procedure TrdFileTransfer.pTitlebarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  begin
  if LMouseD then
    SetBounds(Left+X-LMouseX,Top+Y-LMouseY,Width,Height);
  end;

procedure TrdFileTransfer.pTitlebarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
  LMouseD:=False;
  end;

procedure TrdFileTransfer.CreateParams(Var params: TCreateParams);
  begin
  inherited CreateParams( params );
  params.ExStyle := params.ExStyle or WS_EX_APPWINDOW;
  params.WndParent := GetDeskTopWindow;
  end;

procedure TrdFileTransfer.eLocalDirectoryKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=#13 then
    begin
    Key:=#0;
    bLocalReloadClick(Sender);
    end;
end;

procedure TrdFileTransfer.eLocalFilesListDirectoryChange(Sender: TObject;
  const FileName: string);
begin
//  if assigned(myUI) then
  eLocalDirectory.Text := eLocalFilesList.Directory;
end;

procedure TrdFileTransfer.eLocalFilesListDragDrop(Sender, Source: TObject; X,
  Y: Integer);
  var
    myFiles:TStringList;
    newDir:String;
    a:integer;
  begin
  if assigned(myUI) then
    begin
    newDir:=eLocalFilesList.GetFileName(eRemoteFilesList.GetItemAt(X,Y));
    if newDir<>'' then
      begin
      if newDir='..' then
        newDir:=IncludeTrailingBackslash(eLocalFilesList.Directory)+'..\'
      else
        newDir:=IncludeTrailingBackslash(newDir);
      myFiles:=eLocalFilesList.SelectedFiles;
      if myFiles.Count>0 then
        begin
        for a:=0 to myFiles.Count-1 do
          myUI.Cmd_FileMove(myFiles.Strings[a],newDir+ExtractFileName(myFiles.Strings[a]));
        myUI.GetFileList(eLocalFilesList.Directory,'');
        end;
      end;
    end;
end;

procedure TrdFileTransfer.eLocalFilesListDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept:=(Source=eLocalFilesList) and (eLocalFilesList.Directory<>'');
end;

procedure TrdFileTransfer.eLocalFilesListEdited(Sender: TObject;
  Item: TListItem; var S: string);
  var
    dir, newS:String;
  begin
  if assigned(myUI) then
    begin
    dir:=eLocalFilesList.GetFileName(Item);
    if (dir<>'') and (dir<>'..') then
      begin
      eLocalFilesList.SetFileName(Item,S);
      newS:=ExtractFilePath(dir)+S;
      myUI.Cmd_FileRename(dir, newS);
//      eCommand.Text:=S; //Доделать
      end;
    end;
end;

procedure TrdFileTransfer.eLocalFilesListEditing(Sender: TObject;
  Item: TListItem; var AllowEdit: Boolean);
begin
  AllowEdit:=assigned(myUI) and (eLocalFilesList.Directory<>'') and (Item.Caption<>'..');
end;

procedure TrdFileTransfer.eLocalFilesListFileOpen(Sender: TObject;
  const FileName: string);
begin
  if assigned(myUI) then
    if MessageDlg('Download file'#13#10+'"'+FileName+'"?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
      myUI.Fetch(FileName);
end;

procedure TrdFileTransfer.eLocalFilesListSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
//  if Selected and (eFilesList.GetFileName(Item)<>'..') then //Доделать
//    eCommand.Text:=ExtractFileName(eFilesList.GetFileName(Item))
//  else
//    eCommand.Text:='';
end;

procedure TrdFileTransfer.eRemoteDirectory0KeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then
    begin
    Key:=#0;
    btnRemoteReloadClick(Sender);
    end;
end;

procedure TrdFileTransfer.eRemoteFilesListDirectoryChange(Sender: TObject;
  const FileName: string);
begin
  if assigned(myUI) then
    myUI.GetFileList(FileName,'');
end;

procedure TrdFileTransfer.eRemoteFilesListDragDrop(Sender, Source: TObject; X,
  Y: Integer);
  var
    myFiles:TStringList;
    newDir:String;
    a:integer;
  begin
  if assigned(myUI) then
    begin
    newDir:=eRemoteFilesList.GetFileName(eRemoteFilesList.GetItemAt(X,Y));
    if newDir<>'' then
      begin
      if newDir='..' then
        newDir:=IncludeTrailingBackslash(eRemoteFilesList.Directory)+'..\'
      else
        newDir:=IncludeTrailingBackslash(newDir);
      myFiles:=eRemoteFilesList.SelectedFiles;
      if myFiles.Count>0 then
        begin
        for a:=0 to myFiles.Count-1 do
          myUI.Cmd_FileMove(myFiles.Strings[a],newDir+ExtractFileName(myFiles.Strings[a]));
        myUI.GetFileList(eRemoteFilesList.Directory,'');
        end;
      end;
    end;
end;

procedure TrdFileTransfer.eRemoteFilesListDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept:=(Source=eRemoteFilesList) and (eRemoteFilesList.Directory<>'');
end;

procedure TrdFileTransfer.eRemoteFilesListEdited(Sender: TObject; Item: TListItem;
  var S: string);
  var
    dir, newS:String;
  begin
  if assigned(myUI) then
    begin
    dir:=eRemoteFilesList.GetFileName(Item);
    if (dir<>'') and (dir<>'..') then
      begin
      eRemoteFilesList.SetFileName(Item,S);
      newS:=ExtractFilePath(dir)+S;
      myUI.Cmd_FileRename(dir, newS);
//      eCommand.Text:=S;
      end;
    end;
end;

procedure TrdFileTransfer.eRemoteFilesListEditing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
  AllowEdit:=assigned(myUI) and (eRemoteFilesList.Directory<>'') and (Item.Caption<>'..');
end;

procedure TrdFileTransfer.eRemoteFilesListFileOpen(Sender: TObject;
  const FileName: string);
begin
  if assigned(myUI) then
    if MessageDlg('Download file'#13#10+'"'+FileName+'"?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
      myUI.Fetch(FileName);
end;

procedure TrdFileTransfer.eRemoteFilesListSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
//  if Selected and (eRemoteFilesList.GetFileName(Item)<>'..') then
//    eCommand.Text:=ExtractFileName(eRemoteFilesList.GetFileName(Item))
//  else
//    eCommand.Text:='';
end;

procedure TrdFileTransfer.AcceptFiles( var msg : TMessage );
  const
    cnMaxFileNameLen = 1024;
  var
    i,
    nCount     : integer;
    acFileName : array [0..cnMaxFileNameLen] of char;
    myFileName : string;
  begin
//  if not assigned(myUI.Module) then MessageBeep(0);

  // find out how many files we're accepting
  nCount := DragQueryFile( msg.WParam,
                           $FFFFFFFF,
                           acFileName,
                           cnMaxFileNameLen );

  try
    // query Windows one at a time for the file name
    for i := 0 to nCount-1 do
      begin
      DragQueryFile( msg.WParam, i, acFileName, cnMaxFileNameLen );

      if assigned(myUI.Module) then
        begin
        myFileName:=acFileName;
        myUI.Send(myFileName);
        end;
      end;
  finally
    // let Windows know that you're done
    DragFinish( msg.WParam );
    end;
  end;

procedure TrdFileTransfer.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
  Action:=caFree;

  if Assigned(FOnUIClose) then
    FOnUIClose(myUI.Tag); //ThreadID
  end;

procedure TrdFileTransfer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  begin
  Hide;

  CanClose:=myUI.CloseAndClear;
  end;

procedure TrdFileTransfer.myUILogOut(Sender: TRtcPFileTransferUI);
  begin
  Close;
  end;

procedure TrdFileTransfer.FormCreate(Sender: TObject);
  begin
  // tell Windows that you're
  // accepting drag and drop files
  DragAcceptFiles( Handle, True );
  FReady:=False;

//  Left:=Screen.Width-Width;
//  Top:=0;

  eLocalFilesList.Local := True;
  eLocalDirectory.Text := '';
  end;

procedure TrdFileTransfer.FormDestroy(Sender: TObject);
  begin
  DragAcceptFiles(Handle, False);
  end;

procedure TrdFileTransfer.FormResize(Sender: TObject);
var
  iCenter: Integer;
begin
  iCenter := Ceil(ClientWidth / 2);

  //pTop
  eLocalFilesList.Left := 5;
  eLocalFilesList.Top := 67;
  eLocalFilesList.Width := iCenter - 5 - 5;
  eLocalFilesList.Height := ClientHeight - pTop.Height - pSubTop.Height - pBottom.Height;

  eRemoteFilesList.Left := iCenter + 5;
  eRemoteFilesList.Top := 67;
  eRemoteFilesList.Width := iCenter - 5 - 5;
  eRemoteFilesList.Height := ClientHeight - pTop.Height - pSubTop.Height - pBottom.Height;

  bLocalBack.Left := 5;
  bLocalBack.Top := 4;
  bLocalTop.Left := 35;
  bLocalTop.Top := 4;
  eLocalDirectory.Left := 65;
  eLocalDirectory.Width := iCenter - 5 - bLocalTop.Width - 5 - bLocalReload.Width - 5 - bLocalBack.Width - 5 - 5;
  eLocalDirectory.Top := 4;
  bLocalReload.Left := eLocalDirectory.Left + eLocalDirectory.Width + 5;
  bLocalReload.Top := 4;
  lSplitter.Left := iCenter - Ceil(lSplitter.Width / 2);
  lSplitter.Top := 4;

  bRemoteBack.Left := iCenter + 5;
  bRemoteBack.Top := 4;
  bRemoteTop.Left := iCenter + 5 + bRemoteBack.Width + 5;
  bRemoteTop.Top := 4;
  eRemoteDirectory.Left := iCenter + 5 + bRemoteBack.Width + 5 + bRemoteTop.Width + 5;
  eRemoteDirectory.Width := iCenter - 5 - bRemoteTop.Width - 5 - bRemoteBack.Width - 5 - bRemoteReload.Width - 5 - 5;
  eRemoteDirectory.Top := 4;
  bRemoteReload.Left := eRemoteDirectory.Left + eRemoteDirectory.Width + 5;
  bRemoteReload.Top := 4;

  //pSubTop
  bLocalNewFolder.Left := 5;
  bLocalNewFolder.Top := 4;
  bLocalDelete.Left := 5 + bLocalNewFolder.Width + 5;
  bLocalDelete.Top := 4;
  lLocal.Left := Ceil(iCenter / 2) - lLocal.Width;
  lLocal.Top := 4;
  bUpload.Left := iCenter - 5 - bUpload.Width;
  bUpload.Top := 4;

  bRemoteDelete.Left := ClientWidth - 5 - bRemoteDelete.Width;
  bRemoteDelete.Top := 4;
  bRemoteNewFolder.Left := bRemoteDelete.Left - 5 - bRemoteNewFolder.Width;
  bRemoteNewFolder.Top := 4;
  lRemote.Left := iCenter + Ceil(iCenter / 2) - lLocal.Width;
  lRemote.Top := 4;
  bDownload.Left := iCenter + 5;
  bDownload.Top := 4;

  //pBottom
  lUploading.Left := 5;
  btnCancelSend.Left := iCenter - 5 - btnCancelSend.Width;
  lSendFileName.Left := 5;
  lSendFromFolder.Left := 32;
  lSendCurrent.Left := 5;
  lSendTotal.Left := iCenter - 5 - lSendTotal.Width;
  gSendCurrent.Left := 5;
  gSendCurrent.Width := iCenter - 5;
  gSendTotal.Left := 5;
  gSendTotal.Width := iCenter - 5;
  gSendCompleted.Left := 5;
  gSendCompleted.Width := iCenter - 5;
  lSendSpeed.Left := 5;
  lSendTime.Left := 5;
  lSendCompleted.Left := iCenter - 5 - lSendCompleted.Width;

  lDownloading.Left := iCenter + 5;
  btnCancelFetch.Left := ClientWidth - 5 - btnCancelFetch.Width;
  lRecvFileName.Left := iCenter + 5;
  lRecvFrom.Left := iCenter + 5;
  lRecvToFolder.Left := 32;
  lRecvCurrent.Left := iCenter + 5;
  gRecvCurrent.Left := iCenter + 5;
  gRecvCurrent.Width := iCenter - 5 - 5;
  gRecvTotal.Left := iCenter + 5;
  gRecvTotal.Width := iCenter - 5 - 5;
  lRecvTotal.Left := ClientWidth - 5 - lRecvTotal.Width;
  lRecvSpeed.Left := iCenter + 5;
  lRecvTime.Left := iCenter + 5;
end;

procedure TrdFileTransfer.btnExecuteClick(Sender: TObject);
begin
//  if assigned(myUI) then
//    myUI.Cmd_Execute(IncludeTrailingBackslash(eRemoteFilesList.Directory)+eCommand.Text,eParams.Text);
end;

procedure TrdFileTransfer.btnOpenInboxClick(Sender: TObject);
//  var
//    DestFolder:String;
  begin
//  if assigned(myUI.Module) then
//    begin
//    if lRecvToFolder.Caption='INBOX' then
//      DestFolder:=myUI.Module.FileInboxPath
//    else
//      DestFolder:=lRecvToFolder.Caption;
//      ShellExecute(handle, 'open', PChar(DestFolder), nil,nil,SW_SHOW);
//    end;
  end;

procedure TrdFileTransfer.btnRemoteReloadClick(Sender: TObject);
begin
  if assigned(myUI) then
    myUI.GetFileList(eRemoteDirectory.Text,'');
end;

procedure TrdFileTransfer.btnRemoteViewStyleClick(Sender: TObject);
begin
//  eRemoteFilesList.RefreshColumns; // a work-around for D2009 AV bug
//  case eRemoteFilesList.ViewStyle of
//    vsIcon: eRemoteFilesList.ViewStyle:=vsSmallIcon;
//    vsSmallIcon: eRemoteFilesList.ViewStyle:=vsList;
//    vsList: eRemoteFilesList.ViewStyle:=vsReport;
//    else eRemoteFilesList.ViewStyle:=vsIcon;
//    end;
//  eRemoteFilesList.RefreshColumns; // a work-around for D2009 non-updating view
end;

procedure TrdFileTransfer.bUploadClick(Sender: TObject);
var
  myFiles:TStringList;
  a:integer;
begin
  if assigned(myUI) then
    begin
    myFiles:=eLocalFilesList.SelectedFiles;
    if myFiles.Count>0 then
      for a:=0 to myFiles.Count-1 do
        myUI.Send(myFiles.Strings[a], eRemoteFilesList.Directory);
    end;
end;

procedure TrdFileTransfer.SetCaption;
begin
  if myUI.UserDesc <> '' then
    Caption := myUI.UserDesc + ' - Files transferring'
  else
    Caption := RemoveUserPrefix(myUI.UserName) + ' - Files transferring';
end;

procedure TrdFileTransfer.Form_Open(const mode: string);
  begin
//  Caption:={mode +} myUI.UserName+' - Files transferring';
  SetCaption;

//  cUserName.Caption:=myUI.UserName;
//  cTitleBar.Caption:=mode+'Files';

  lSendFileName.Caption:='----';
  lSendFromFolder.Caption:='----';
  lSendCurrent.Caption:='-- / --';
  lSendTotal.Caption:='-- / --';
  lSendCompleted.Caption:='-- / --';

  gSendCurrent.Progress:=0;
  gSendTotal.Progress:=0;
  gSendCompleted.Progress:=0;
  gSendCurrent.MaxValue:=10000;
  gSendTotal.MaxValue:=10000;
  gSendCompleted.MaxValue:=10000;

  gSendCurrent.ForeColor:=clNavy;
  gSendTotal.ForeColor:=clTeal;
  gSendCompleted.ForeColor:=clGreen;

  lSendSpeed.Caption:='-';
  lSendTime.Caption:='---';

  lRecvFileName.Caption:='----';
  lRecvToFolder.Caption:='----';
  lRecvCurrent.Caption:='-- / --';
  lRecvTotal.Caption:='-- / --';
  gRecvCurrent.Progress:=0;
  gRecvTotal.Progress:=0;
  gRecvCurrent.MaxValue:=10000;
  gRecvTotal.MaxValue:=10000;

  gRecvCurrent.ForeColor:=clNavy;
  gRecvTotal.ForeColor:=clGreen;

  lRecvSpeed.Caption:='-';
  lRecvTime.Caption:='---';

//  if WindowState=wsNormal then
//    begin
//    BringToFront;
//    BringWindowToTop(Handle);
//    end;

//  Left:=Screen.Width-Width;
//  Top:=0;

  FReady:=True;
  end;

procedure TrdFileTransfer.Form_Close(const mode: string);
  begin
//  cUserName.Caption:=myUI.UserName;
//  cTitleBar.Caption:='('+mode+')';

  gSendCurrent.ForeColor:=clMaroon;
  gSendTotal.ForeColor:=clMaroon;
  gSendCompleted.ForeColor:=clMaroon;

  lSendSpeed.Caption:=mode;
  lSendTime.Caption:='---';

  gRecvCurrent.ForeColor:=clMaroon;
  gRecvTotal.ForeColor:=clMaroon;

  lRecvSpeed.Caption:=mode;
  lRecvTime.Caption:='---';
  
  FReady:=False;
  end;

procedure TrdFileTransfer.myUIInit(Sender: TRtcPFileTransferUI);
  begin
  if not FReady then Form_Open('(Init) ');
  end;

procedure TrdFileTransfer.myUIOpen(Sender: TRtcPFileTransferUI);
  var
    fIsPending: Boolean;
  begin
  if Assigned(FOnUIOpen) then
    FOnUIOpen(myUI.UserName, 'file', fIsPending);

  if not fIsPending then
  begin
    Close;
    Exit;
  end
  else
  begin
    Show;
//    BringToFront;
    //BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
  end;

  Form_Open('');

//  Caption:=myUI.UserName+' - Files transferring';
  SetCaption;
  MyUI.OnFileList:=MyOnFileList;
  myUI.GetFileList('',''); // load remote drives list to initialize
  end;

procedure TrdFileTransfer.MyOnFileList(Sender: TRtcPFileTransferUI);
  begin
//  eLocalDirectory.Text := '';

  eRemoteDirectory.Text:=Sender.FolderName;
  eRemoteFilesList.UpdateFileList(Sender.FolderName,Sender.FolderData);
  end;

procedure TrdFileTransfer.mnDeleteClick(Sender: TObject);
  var
    myFiles:TStringList;
    s:String;
    a:integer;
  begin
  if assigned(myUI) then
    begin
    myFiles:=eRemoteFilesList.SelectedFiles;
    if myFiles.Count>0 then
      begin
      s:='Delete the following File(s) and/or Folder(s)?';
      for a:=0 to myFiles.Count-1 do
        s:=s+#13#10+ExtractFileName(myFiles.Strings[a]);

      if MessageDlg(s,mtWarning,[mbYes,mbNo],0)=mrYes then
        begin
        for a:=0 to myFiles.Count-1 do
          myUI.Cmd_FileDelete(myFiles.Strings[a]);
        myUI.GetFileList(eRemoteFilesList.Directory,'');
        end;
      end;
    end;
end;

procedure TrdFileTransfer.mnDownloadClick(Sender: TObject);
  var
    myFiles:TStringList;
    a:integer;
  begin
  if assigned(myUI) then
    begin
    myFiles:=eRemoteFilesList.SelectedFiles;
    if myFiles.Count>0 then
      for a:=0 to myFiles.Count-1 do
        myUI.Fetch(myFiles.Strings[a], eLocalFilesList.Directory);
    end;
end;

procedure TrdFileTransfer.bRemoteNewFolderClick(Sender: TObject);
begin
  if assigned(myUI) and (eRemoteFilesList.Directory<>'') then
    begin
    myUI.Cmd_NewFolder(IncludeTrailingBackslash(eRemoteFilesList.Directory)+'New Folder');
    myUI.GetFileList(eRemoteFilesList.Directory,'');
    end;
end;

procedure TrdFileTransfer.myUIClose(Sender: TRtcPFileTransferUI);
  begin
  Form_Close('Closed');
  Close;
  end;

procedure TrdFileTransfer.myUIError(Sender: TRtcPFileTransferUI);
  begin
  Form_Close('DISCONNECTED');
  // we disconnected. Can not use this FileTransfer window anymore.
  myUI.Module:=nil;
  Close;
  end;

procedure TrdFileTransfer.myUIRecv(Sender: TRtcPFileTransferUI);
  begin
  if myUI.Recv_FirstTime then
    begin
    gRecvCurrent.ForeColor:=clNavy;
    gRecvTotal.ForeColor:=clGreen;
    end;

  if myUI.Recv_FileCount>1 then
    lRecvFileName.Caption:='['+IntToStr(myUI.Recv_FileCount)+'] '+myUI.Recv_FileName
  else
    lRecvFileName.Caption:=myUI.Recv_FileName;

  if myUI.Recv_ToFolder='' then
    lRecvToFolder.Caption:='INBOX'
  else
    lRecvToFolder.Caption:=myUI.Recv_ToFolder;

  lRecvCurrent.Caption:=Format('%.0n / %.0n KB', [myUI.Recv_FileIn/1024, myUI.Recv_FileSize/1024]);
  lRecvTotal.Caption:=Format('%.0n / %.0n KB', [myUI.Recv_BytesComplete/1024, myUI.Recv_BytesTotal/1024]);

  if myUI.Recv_FileSize>0 then
    gRecvCurrent.Progress:=round(myUI.Recv_FileIn/myUI.Recv_FileSize*10000)
  else
    gRecvCurrent.Progress:=0;

  if myUI.Recv_BytesTotal>0 then
    gRecvTotal.Progress:=round(myUI.Recv_BytesComplete/myUI.Recv_BytesTotal*10000)
  else
    gRecvTotal.Progress:=0;

  if (myUI.Recv_FileCount=0) and (myUI.Recv_BytesComplete=myUI.Recv_BytesTotal) then
    begin
    gRecvCurrent.ForeColor:=clSilver;
    gRecvTotal.ForeColor:=clSilver;

    lRecvTime.Caption:='DONE. Completed in '+myUI.Recv_TotalTime;
    lRecvSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Recv_KBit/1]);

//    if myUI.Recv_ToFolder='' then
//      btnOpenInboxClick(nil);
    end
  else if myUI.Recv_BytesComplete>0 then
    begin
    lRecvSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Recv_KBit/1]);
    lRecvTime.Caption:='Estimated completion in '+myUI.Recv_ETA;
    end
  else
    begin
    lRecvSpeed.Caption:='';
    lRecvTime.Caption:='';
    end;
  end;

procedure TrdFileTransfer.myUISend(Sender: TRtcPFileTransferUI);
  begin
  if myUI.Send_FirstTime then
    begin
    gSendCurrent.ForeColor:=clNavy;
    gSendTotal.ForeColor:=clTeal;
    gSendCompleted.ForeColor:=clGreen;
    end;

  if myUI.Send_FileCount>1 then
    lSendFileName.Caption:='['+IntToStr(myUI.Send_FileCount)+'] '+myUI.Send_FileName
  else
    lSendFileName.Caption:=myUI.Send_FileName;

  lSendFromFolder.Caption:=myUI.Send_FromFolder;

  lSendCurrent.Caption:=Format('%.0n / %.0n KB', [myUI.Send_FileOut/1024,myUI.Send_FileSize/1024]);
  lSendTotal.Caption:=Format('%.0n / %.0n KB', [myUI.Send_BytesPrepared/1024, myUI.Send_BytesTotal/1024]);
  lSendCompleted.Caption:=Format('%.0n / %.0n KB', [myUI.Send_BytesComplete/1024, myUI.Send_BytesTotal/1024]);

  if myUI.Send_FileSize>0 then
    gSendCurrent.Progress:=round(myUI.Send_FileOut/myUI.Send_FileSize*10000)
  else
    gSendCurrent.Progress:=0;

  if myUI.Send_BytesTotal>0 then
    begin
    gSendTotal.Progress:=round(myUI.Send_BytesPrepared/myUI.Send_BytesTotal*10000);
    gSendCompleted.Progress:=round(myUI.Send_BytesComplete/myUI.Send_BytesTotal*10000);
    end
  else
    begin
    gSendTotal.Progress:=0;
    gSendCompleted.Progress:=0;
    end;

  if (myUI.Send_FileCount=0) and (myUI.Send_BytesComplete=myUI.Send_BytesTotal) then
    begin
    gSendCurrent.ForeColor:=clSilver;
    gSendTotal.ForeColor:=clSilver;
    gSendCompleted.ForeColor:=clSilver;

    lSendTime.Caption:='DONE. Completed in '+myUI.Send_TotalTime;
    lSendSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Send_KBit/1]);
    end
  else if myUI.Send_BytesComplete>0 then
    begin
    lSendSpeed.Caption:=Format('Speed: %.0n Kbps',[myUI.Send_KBit/1]);
    lSendTime.Caption:='Estimated completion in '+myUI.Send_ETA;
    end
  else
    begin
    lSendSpeed.Caption:='';
    lSendTime.Caption:='';
    end;
  end;

procedure TrdFileTransfer.lSendFromFolderClick(Sender: TObject);
  var
    SrcFolder:String;
  begin
  if assigned(myUI.Module) then
    begin
    SrcFolder:=lSendFromFolder.Caption;
    ShellExecute(handle, 'open', PChar(SrcFolder), nil,nil,SW_SHOW);
    end;
  end;

procedure TrdFileTransfer.myUIRecvCancel(Sender: TRtcPFileTransferUI);
  begin
  lRecvFileName.Caption:='Cancelled';
  end;

procedure TrdFileTransfer.myUISendCancel(Sender: TRtcPFileTransferUI);
  begin
  lSendFileName.Caption:='Cancelled';
  end;

procedure TrdFileTransfer.btnCancelSendClick(Sender: TObject);
  begin
  if myUI.Send_FileName <> '' then
    myUI.Cancel_Send(IncludeTrailingPathDelimiter(myUI.Send_FromFolder) + myUI.Send_FileName);
  end;

procedure TrdFileTransfer.bLocalBackClick(Sender: TObject);
begin
  eLocalFilesList.OneLevelUp;
end;

procedure TrdFileTransfer.bLocalDeleteClick(Sender: TObject);
var
  myFiles:TStringList;
  a:integer;
begin
  if assigned(myUI) then
    begin
    myFiles:=eLocalFilesList.SelectedFiles;
    if myFiles.Count>0 then
      for a:=0 to myFiles.Count-1 do
      begin
        myUI.Send(myFiles.Strings[a], eRemoteFilesList.Directory);
        try
          if DirectoryExists(myFiles.Strings[a]) then
            DelFolderTree(myFiles.Strings[a]);
        except
          // ignore all exceptions
        end;
        try
          if File_Exists(myFiles.Strings[a]) then
            Delete_File(myFiles.Strings[a]);
        except
          // ignore all exceptions
        end;
      end;
    end;
end;

procedure TrdFileTransfer.bLocalNewFolderClick(Sender: TObject);
begin
  try
    ForceDirectories(IncludeTrailingBackslash(eLocalFilesList.Directory) + 'New folder');
  except
    // ignore all exceptions
  end;
end;

procedure TrdFileTransfer.bLocalReloadClick(Sender: TObject);
begin
  eLocalFilesList.RefreshFilesList;
end;

procedure TrdFileTransfer.bLocalTopClick(Sender: TObject);
begin
  eLocalDirectory.Text := '';
  eLocalFilesList.TopLevel;
end;

procedure TrdFileTransfer.bRemoteReloadClick(Sender: TObject);
begin
  if assigned(myUI) then
    myUI.GetFileList(eRemoteDirectory.Text,'');
end;

procedure TrdFileTransfer.bRemoteTopClick(Sender: TObject);
begin
  eRemoteDirectory.Text := '';
  myUI.GetFileList(eRemoteDirectory.Text,'');
end;

procedure TrdFileTransfer.btnBackClick(Sender: TObject);
begin
  eRemoteFilesList.OneLevelUp;
end;

procedure TrdFileTransfer.btnCancelFetchClick(Sender: TObject);
  begin
  if myUI.Recv_FileName <> '' then
    myUI.Cancel_Fetch(myUI.Recv_FileName);
  end;

end.
