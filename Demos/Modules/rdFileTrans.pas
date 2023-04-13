unit rdFileTrans;
interface
{$include rtcDefs.inc}
uses
  Windows, Messages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls,
  Buttons, ComCtrls, ExtCtrls, Clipbrd, IOUtils,
  Character, WinSock,
{$IFDEF IDE_XE3up}
  UITypes,
{$ENDIF}
  rtcSystem, rtcpFileExplore, rtcpFileTransUI, ShellAPI, Menus, AppEvnts, ImgList, Vcl.Samples.Gauges, System.ImageList,
  rtcPortalMod, rtcpFileTrans, uVircessTypes, CommonUtils, rtcScrUtils, CommonData,

  FixFileExplorer;
const
  WM_SAFE_DELETE_OBJECT  = WM_USER + 1;
  DELAY_CLICK_SEND_FETCH = 500;
type
  TListViewInfo = record
    cnt: Integer;
    index: Integer;
    vert_scroll_pos: Integer;
  end;
  TRecentPathList = class (TStringList)
  private
    FDoubleRet: Boolean;
  public
    procedure Push(const s: string);
    function Pop(): string; overload; inline;
    function Pop(out s: string): Boolean; overload;
  end;
  TrdFileTransfer = class(TForm)
    Panel: TPanel;
    Panel3: TPanel;
    FilesRemote: TRtcPFileExplorer;
    btnRemoteReload: TSpeedButton;
    Panel5: TPanel;
    btnViewStyle: TSpeedButton;
    pmFiles: TPopupMenu;
    mnNewFolder: TMenuItem;
    mnRefresh: TMenuItem;
    N2: TMenuItem;
    mnDelete: TMenuItem;
    mnDownload: TMenuItem;
    N1: TMenuItem;
    pn: TPanel;
    eParams: TEdit;
    P1: TMenuItem;
    tr: TTimer;
    ImageList1: TImageList;
    Panel_: TPanel;
    FilesLocal: TRtcPFileExplorer;
    Panel7: TPanel;
    pn_: TPanel;
    sb: TStatusBar;
    Splitter1: TSplitter;
    Panel_0: TPanel;
    Panel_1: TPanel;
    sbtnReceive: TSpeedButton;
    sbtnSend: TSpeedButton;
    Panel11: TPanel;
    Image1: TImage;
    lRemoteName: TLabel;
    Label2: TLabel;
    Panel12: TPanel;
    Image2: TImage;
    lLocalName: TLabel;
    Label4: TLabel;
    b_hm: TSpeedButton;
    sbtnRemoteLevelUp: TSpeedButton;
    Panel6: TPanel;
    btnLocalReload: TSpeedButton;
    SpeedButton2: TSpeedButton;
    b_hm_: TSpeedButton;
    sbtnLocalLevelUp: TSpeedButton;
    Shape2: TShape;
    Shape3: TShape;
    Timer1: TTimer;
    ImageList2: TImageList;
    edRemoteDir: TComboBoxEx;
    edLocalDir: TComboBoxEx;
    Shape4: TShape;
    Shape5: TShape;
    N3: TMenuItem;
    P2: TMenuItem;
    b_dr: TSpeedButton;
    b_dl: TSpeedButton;
    b_pp: TSpeedButton;
    b_dr_: TSpeedButton;
    b_dl2: TSpeedButton;
    pop: TPopupMenu;
    J1: TMenuItem;
    N4: TMenuItem;
    pmFiles_: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    MenuItem10: TMenuItem;
    Image_0: TImage;
    Image_1: TImage;
    PageControlTasks: TPageControl;
    tbFileTask: TTabSheet;
    tbFileLog: TTabSheet;
    pp: TScrollBox;
    Shape1: TShape;
    lblNoTask: TLabel;
    p_0: TPanel;
    gTotal: TGauge;
    Label5: TLabel;
    logo: TImage;
    Label6: TLabel;
    SpeedButton10: TSpeedButton;
    lg: TMemo;
    Panel1: TPanel;
    Label7: TLabel;
    tr_dy: TTimer;
    al_b: TLabel;
    myUI: TRtcPFileTransferUI;
    btnRemoteBack: TSpeedButton;
    btnLocalBack: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FilesRemoteDirectoryChange(Sender: TObject; const FileName: String);
    procedure btnRemoteReloadClick(Sender: TObject);
    procedure btnViewStyleClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure DownLabelDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure DownLabelDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FilesRemoteDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure mnRefreshClick(Sender: TObject);
    procedure mnNewFolderClick(Sender: TObject);
    procedure FilesEditing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure mnDeleteClick(Sender: TObject);
    procedure FilesRemoteSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FilesRemoteDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure P1Click(Sender: TObject);
    procedure FilesRemoteKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tiClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure sbtnReceiveClick(Sender: TObject);
    procedure sbtnSendClick(Sender: TObject);
    procedure SpeedButton10Click(Sender: TObject);
    procedure btnLocalReloadClick(Sender: TObject);
    procedure FilesLocalDirectoryChange(Sender: TObject;
      const FileName: string);
    procedure Label6MouseEnter(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure edRemoteDirSelect(Sender: TObject);
    procedure edRemoteDirKeyPress(Sender: TObject; var Key: Char);
    procedure edLocalDirKeyPress(Sender: TObject; var Key: Char);
    procedure edLocalDirSelect(Sender: TObject);
    procedure FilesLocalSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure sbtnLocalLevelUpClick(Sender: TObject);
    procedure b_hmClick(Sender: TObject);
    procedure b_hm_Click(Sender: TObject);
    procedure FilesLocalKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure b_dlClick(Sender: TObject);
    procedure FilesRemoteEnter(Sender: TObject);
    procedure FilesLocalEnter(Sender: TObject);
    procedure b_dl2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure P2Click(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure b_ppClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure FilesRemoteClick(Sender: TObject);
    procedure FilesRemoteKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FilesLocalKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FilesLocalClick(Sender: TObject);
    procedure b_dr_Click(Sender: TObject);
    procedure FilesLocalDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure FilesLocalDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Splitter1Moved(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Label7Click(Sender: TObject);
    procedure tr_dyTimer(Sender: TObject);
    procedure myUIClose(Sender: TRtcPFileTransferUI);
    procedure myUIError(Sender: TRtcPFileTransferUI);
    procedure myUIInit(Sender: TRtcPFileTransferUI);
    procedure myUILogOut(Sender: TRtcPFileTransferUI);
    procedure myUIOpen(Sender: TRtcPFileTransferUI);
    procedure myUISendStart(Sender: TRtcPFileTransferUI);
    procedure myUISend(Sender: TRtcPFileTransferUI);
    procedure myUIRecvStop(Sender: TRtcPFileTransferUI);
    procedure myUIRecvStart(Sender: TRtcPFileTransferUI);
    procedure myUIRecv(Sender: TRtcPFileTransferUI);
    procedure myUISendStop(Sender: TRtcPFileTransferUI);
    procedure myUIFileList(Sender: TRtcPFileTransferUI);
    procedure myUISendCancel(Sender: TRtcPFileTransferUI);
    procedure myUIRecvCancel(Sender: TRtcPFileTransferUI);
    procedure sbtnRemoteLevelUpClick(Sender: TObject);
    procedure FilesLocalFileOpen(Sender: TObject; const FileName: string);
    procedure FilesEdited(Sender: TObject; Item: TListItem;
      var S: string);
    procedure btnRemoteBackClick(Sender: TObject);
    procedure myUINotifyFileBatchSend(Sender: TObject; const task: TBatchTask;
      mode: TModeBatchSend);
  private
    FReady: Boolean;
    FOnUIOpen: TUIOpenEvent;
    FOnUIClose: TUICloseEvent;
    FBmpL, FBmpR: TBitmap;
    FTotalBytesTransfer, FCurrentBytesTransfer: Int64;
    FDelayClickSendFetch: Integer;
    FBeforeClose: TNotifyEvent;
    FRemoteRecent, FLocalRecent: TRecentPathList;
//    function GetUI: TRtcPFileTransferUI;
//    procedure SetUI(const Value: TRtcPFileTransferUI);
    function send_f(myFile,d: string): Integer;
    function add_pn(path: string; send: boolean): TGauge;
    function add_rc(send: boolean; to_dir: string; ff: TStringList;
      g: TGauge): Integer;
    function fnd_rec(pn_: TPanel; all:boolean=False): integer;
    function next_rec(p: integer): integer;
    function wrong_caption(s: string): Integer;
    function info2pn(lv: TRtcPFileExplorer): Int64;
    procedure check_task;
    function rec_finished(pn: TPanel; isDelete: boolean=False): integer;
    procedure add_lg(s: string);
    function str_size(sz: int64;   gb:boolean=true; mb:boolean=true;
                                   kb:boolean=true; round_:boolean=false; dig:byte=1): string;
    function file_exists(sd,ya,na: boolean; src,dst: string): integer;
    function end_copy(f: string): integer;
    function next_task(pan:TPanel; del: boolean=False; all:boolean=False): integer;
    procedure clear_deleted;
    procedure myUICallReceived(Sender: TRtcPFileTransferUI);
    function renameF_(pn: TPanel; back:Boolean): boolean;
    procedure comp_border(cp: twincontrol; pix: byte);
    function get_TF(ss: TStrings): string;
    procedure set_info(snd:boolean; b:int64);
    procedure Form_Open(const mode:string);
    procedure Form_Close(const mode:string);
    procedure SetCaption;

  protected
    procedure AcceptFiles(var msg : TMessage); message WM_DROPFILES;
    procedure CreateParams(var params: TCreateParams); override;
    procedure ChangeLockedState(var Message: TMessage); message WM_CHANGE_LOCKED_STATUS;
    // new methods
    // private
    procedure WmSafeDeleteObject(var Message: TMessage); message WM_SAFE_DELETE_OBJECT;
    procedure SafeDeleteObject(const [ref] Obj: TObject);
    procedure RenameFileExplorer(Files: TRtcPFileExplorer; Item: TListItem; const NewName: string);
    // published
    procedure sbtnSendBatchClick(Sender: TObject);
    procedure sbtnFetchBatchClick(Sender: TObject);
    procedure CancelBatchClick(Sender: TObject);
    procedure OnSendBatch(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend) ;
    procedure FilesReload(Sender: TObject;  Files: TRtcPFileExplorer);
    function SaveScroolListView(lv: TRtcPFileExplorer): TListViewInfo;
    procedure RestoreScroolListView(lv: TRtcPFileExplorer; const info: TListViewInfo);
  public
    UIVisible: Boolean;
    PartnerLockedState: Integer;
    PartnerServiceStarted: Boolean;
    property UI:TRtcPFileTransferUI read myUI;
    procedure SetFormState;
    property OnUIOpen: TUIOpenEvent read FOnUIOpen write FOnUIOpen;
    property OnUIClose: TUICloseEvent read FOnUIClose write FOnUIClose;
    property BeforeClose:TNotifyEvent read FBeforeClose write FBeforeClose;
  end;
  TRec = record
    is_send,finished,deleted: boolean;
    from_path,
    to_path: string;
    sel_files: TStringList;
    pn:TPanel;
    g_:TGauge;
    lb:TLabel;
    taskID: TTaskID;
    direction: TStatusBatchTask;
  end;
  TArrayOfTRec = array of TRec;
var
  curr_g: TGauge = nil;  cur_files:TStringList; rr: TArrayOfTRec;
  stopped: boolean = True; KEY_BACK: boolean = False;
  Timer1_cn: integer = 0;
  foc_: string;
  VK_UPDOWN:  boolean=False;
  load_first: boolean=True;
  send_stop: boolean=False; resv_stop: boolean=False; coping_stop: boolean=False;
  recv_bytes:int64=0;
  send_bytes:int64=0;
implementation
uses
  Winapi.ShlObj, ComObj, MultiFileTrans;

{$R *.dfm}
procedure TrdFileTransfer.CancelBatchClick(Sender: TObject);
var
  i: Integer;
  p:TPanel;
  task: TBatchTask;
  reload: TSpeedButton;
begin
  p := TPanel(TSpeedButton(Sender).Parent);
  i := rec_finished(p, true);
  if i = -1 then exit;
  task := TRtcPFileTransfer(myUI.Module).TaskList.GetTaskByName(rr[i].taskID.ToString);
  task._AddRef;
  try
    if rr[i].direction = sbtReceiving then
      reload := btnLocalReload else
      reload := btnRemoteReload;
    rr[i].taskID := TGUID.Empty;
    TRtcPFileTransfer(myUI.Module).CancelBatch(Sender, task.Id);
    FTotalBytesTransfer := FTotalBytesTransfer - task.Size;
    FCurrentBytesTransfer := FCurrentBytesTransfer - task.SentSize;
  finally
    task._Relase
  end;
  reload.Click;
  clear_deleted;
  lblNoTask.Visible := Length(rr) = 0;
end;
procedure TrdFileTransfer.ChangeLockedState(var Message: TMessage);
begin
  PartnerLockedState := Message.WParam;
  PartnerServiceStarted := Boolean(Message.LParam);
  SetFormState;
end;
procedure TrdFileTransfer.SetFormState;
begin
  if (PartnerLockedState = LCK_STATE_LOCKED) then
    Close;
end;
procedure TrdFileTransfer.SetCaption;
begin
  lLocalName.Caption := Get_ComputerName;
  if myUI.UserDesc <> '' then
  begin
    Caption := myUI.UserDesc + ' - Передача файлов';
    lRemoteName.Caption := myUI.UserDesc;
  end
  else
  begin
    Caption := RemoveUserPrefix(myUI.UserName) + ' - Передача файлов';
    lRemoteName.Caption := RemoveUserPrefix(myUI.UserName);
  end;
end;
procedure TrdFileTransfer.Form_Open(const mode: string);
begin
//  Caption:={mode +} myUI.UserName+' - Files transferring log';
  SetCaption;
//  cUserName.Caption:=myUI.UserName;
//  cTitleBar.Caption:=mode+'Files';
  FReady:=True;
end;

procedure TrdFileTransfer.Form_Close(const mode: string);
begin
//  cUserName.Caption:=myUI.UserName;
//  cTitleBar.Caption:='('+mode+')';
  FReady:=False;
end;
procedure TrdFileTransfer.CreateParams(Var params: TCreateParams);
begin
  inherited CreateParams(params);
//  params.Style := params.Style or WS_CLIPCHILDREN;
//  params.Style := WS_CHILDWINDOW or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN;
//  params.ExStyle := WS_EX_LEFT or WS_EX_LTRREADING or WS_EX_RIGHTSCROLLBAR or WS_EX_CONTROLPARENT or WS_EX_APPWINDOW;
  params.ExStyle := params.ExStyle {or WS_EX_CONTROLPARENT} or WS_EX_APPWINDOW;
  params.WndParent := 0; //GetDeskTopWindow;
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
  if not assigned(myUI.Module) then MessageBeep(0);
  nCount := DragQueryFile( msg.WParam,
                           $FFFFFFFF,
                           acFileName,
                           cnMaxFileNameLen );
  try
    for i := 0 to nCount-1 do
      begin
      DragQueryFile( msg.WParam, i, acFileName, cnMaxFileNameLen );
      if assigned(myUI.Module) then
        begin
        myFileName:=acFileName;
        myUI.Send(myFileName, edRemoteDir.Text);
        end;
      end;
  finally
    DragFinish( msg.WParam );
    end;
  end;

procedure TrdFileTransfer.FormCreate(Sender: TObject);
begin
  Application.HintHidePause := 10000;
  cur_files := TStringList.Create;
  FBmpL := TBitmap.Create;
  FBmpR := TBitmap.Create;
  FBmpL.Assign(sbtnSend.Glyph);
  FBmpR.Assign(sbtnReceive.Glyph);
  FRemoteRecent := TRecentPathList.Create;
  FLocalRecent  := TRecentPathList.Create;
  b_ppClick(nil);
  DragAcceptFiles(Handle, True);

end;
{function TrdFileTransfer.GetUI: TRtcPFileTransferUI;
  begin
  Result:=MyUI;
  end;}
procedure TrdFileTransfer.Image1Click(Sender: TObject);
begin
  with mouse.CursorPos do
    pop.Popup(x, y);
end;
{procedure TrdFileTransfer.SetUI(const Value: TRtcPFileTransferUI);
  begin
  if Value<>MyUI then
    begin
    if assigned(myUI) then
      MyUI.OnFileList:=nil;
    myUI:=Value;
    if assigned(myUI) then
      begin
      Caption:=myUI.UserName+' - File Explorer';
      MyUI.OnFileList:=  myOnFileList;
      MyUI.OnSend:=      myOnSend;
      MyUI.OnSendStop:=  myOnSendStop;
      MyUI.OnSendStart:= myOnSendStart;
      MyUI.OnRecv:=      myOnResv;
      MyUI.OnRecvStop:=  myOnResvStop;
      MyUI.OnRecvStart:= myOnResvStart;
      MyUI.OnCallReceived:=
                         myUICallReceived;
      MyUI.OnRecvCancel:=
                         myUIRecvCancel;
      MyUI.OnSendCancel:=
                         myUISendCancel;
      myUI.GetFileList('','');
      end;
    end;
  end;}
procedure TrdFileTransfer.myUICallReceived(Sender: TRtcPFileTransferUI);
begin
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
procedure TrdFileTransfer.myUIFileList(Sender: TRtcPFileTransferUI);
var
  tempItem: TListItem;
  s: string;
  i: integer;
  r: TRTChugestring;
  Index, Count: Integer;
  info: TListViewInfo;
begin
  info := SaveScroolListView(FilesRemote);
//  if FilesRemote.SelectedCount = 1 then
//    begin
//      Index := FilesRemote.ItemIndex;
//      Count := FilesRemote.Items.Count;
//    end
//  else
//    Count := -1;
   b_dl.Enabled:= False;
   sbtnReceive.Enabled:= False;
   edRemoteDir.Text:=Sender.FolderName;
   FilesRemote.UpdateFileList(Sender.FolderName,Sender.FolderData);
   FilesRemote.ClearSelection;
   tempItem := nil;
   if KEY_BACK and (foc_<>'') then
    tempItem := FilesRemote.FindCaption(0, foc_, False, False, False);
   if tempItem <> nil then
     FilesRemote.ItemIndex := tempItem.Index
     else
     RestoreScroolListView(FilesRemote, Info);
//   else if FilesRemote.Items.Count = Count  then
//     FilesRemote.ItemIndex := Index
//   else if FilesRemote.Items.Count > 0 then
//     FilesRemote.ItemIndex := 0;

   if FilesRemote.ItemFocused <> nil then
    FilesRemote.ItemFocused.MakeVisible(False);
   KEY_BACK:= False; foc_:='';
   FilesRemoteClick(nil);
end;
procedure TrdFileTransfer.myUIInit(Sender: TRtcPFileTransferUI);
begin
  if not FReady then Form_Open('(Init) ');
end;
procedure TrdFileTransfer.myUILogOut(Sender: TRtcPFileTransferUI);
begin
  Close;
end;

procedure TrdFileTransfer.myUIOpen(Sender: TRtcPFileTransferUI);
  var
    fIsPending: Boolean;
begin
  fIsPending := true;
  if Assigned(FOnUIOpen) then
    FOnUIOpen(myUI.UserName, 'file', fIsPending);
  if not fIsPending then
  begin
    Close;
    Exit;
  end
  else
  if UIVisible then
  begin
    Show;
    BringToFront;
    //BringWindowToTop(Handle);
    SetForegroundWindow(Handle);
  end;
  Form_Open('');
//  Caption:=myUI.UserName+' - Files transferring';
//  SetCaption;
//  MyUI.OnFileList:=MyOnFileList;
  myUI.GetFileList('',''); // load remote drives list to initialize
end;
procedure TrdFileTransfer.FilesLocalDirectoryChange(Sender: TObject;
  const FileName: string);
begin
  FLocalRecent.Push(FileName);
  edLocalDir.Text:= FileName;
  if not load_first then
     FilesLocalClick(nil);
end;
procedure TrdFileTransfer.FilesRemoteDirectoryChange(Sender: TObject; const FileName: String);
begin
  FRemoteRecent.Push(FileName);
  if assigned(myUI) then
    myUI.GetFileList(FileName,'');
  if not load_first then
    FilesRemoteClick(nil);
end;
procedure TrdFileTransfer.btnRemoteBackClick(Sender: TObject);
begin
  if Sender = btnRemoteBack then
    begin
      edRemoteDir.Text := FRemoteRecent.Pop;
      btnRemoteReloadClick(nil);
    end
  else
    begin
      edLocalDir.Text := FLocalRecent.Pop;
      btnLocalReloadClick(nil);
    end;
end;
procedure TrdFileTransfer.btnRemoteReloadClick(Sender: TObject);
begin
  FilesReload(Sender, FilesRemote);
  exit;
  try
  if assigned(myUI) then
    myUI.GetFileList(edRemoteDir.Text, extractfilename(edRemoteDir.Text));
    FilesRemote.ItemFocused:=  FilesRemote.Items[0];
    FilesRemote.Selected:=     FilesRemote.Items[0];
    FilesRemote.SetFocus;
    SetCaption;
    except
    end;
end;
procedure TrdFileTransfer.btnViewStyleClick(Sender: TObject);
  begin
  FilesRemote.RefreshColumns;
  case FilesRemote.ViewStyle of
    vsIcon: FilesRemote.ViewStyle:=vsSmallIcon;
    vsSmallIcon: FilesRemote.ViewStyle:=vsList;
    vsList: FilesRemote.ViewStyle:=vsReport;
    else FilesRemote.ViewStyle:=vsIcon;
    end;
  FilesRemote.RefreshColumns;
  end;
procedure TrdFileTransfer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  begin
  if assigned(FBeforeClose) then
    FBeforeClose(Self);
  CanClose:=True;
  end;
procedure TrdFileTransfer.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  DragAcceptFiles(Handle, False);
  cur_files.Free;
  cur_files := nil;
  FBmpR.Free;
  FBmpL.Free;
  for I := 0 to Length(rr)-1 do
    rr[i].sel_files.Free;
  FRemoteRecent.Free;
  FLocalRecent.Free;
end;
procedure TrdFileTransfer.DownLabelDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
  begin
  Accept:=(Source=FilesRemote) and (FilesRemote.Directory<>'');
  end;
procedure TrdFileTransfer.DownLabelDragDrop(Sender, Source: TObject; X, Y: Integer);
  var
    myFiles:TStringList;
    a:integer;
  begin
  if assigned(myUI) then
    begin
    myFiles:=FilesRemote.SelectedFiles;
    if myFiles.Count>0 then
      for a:=0 to myFiles.Count-1 do
        myUI.Fetch(myFiles.Strings[a]);
    end;
  end;
procedure TrdFileTransfer.mnRefreshClick(Sender: TObject);
  begin
  btnRemoteReloadClick(Sender);
  end;
procedure TrdFileTransfer.SafeDeleteObject(const [ref] Obj: TObject);
begin
  PostMessage(Handle, WM_SAFE_DELETE_OBJECT, 0, LPARAM(Obj));
  TObject(Pointer(@Obj)^) := nil;
end;
function TrdFileTransfer.SaveScroolListView(
  lv: TRtcPFileExplorer): TListViewInfo;
var
  scroll_info: TScrollInfo;
begin
  scroll_info.cbSize := SizeOf(scroll_info);
  scroll_info.fMask := SIF_ALL;
  GetScrollInfo(lv.Handle, SB_VERT, scroll_info);

  Result.index := lv.ItemIndex;
  Result.cnt   := lv.Items.Count;
  Result.vert_scroll_pos := scroll_info.nPos;
end;
procedure TrdFileTransfer.WmSafeDeleteObject(var Message: TMessage);
begin
  TObject(Message.LParam).Free;
end;
procedure TrdFileTransfer.FilesEdited(Sender: TObject; Item: TListItem;
  var S: string);
begin
  RenameFileExplorer(TRtcPFileExplorer(Sender), Item, S);
end;
procedure TrdFileTransfer.FilesEditing(Sender: TObject; Item: TListItem; var AllowEdit: Boolean);
begin
  AllowEdit := Assigned(myUI) and
               (TRtcPFileExplorer(Sender).Directory<>'') and
               (Item.Caption<>'..');
end;
procedure TrdFileTransfer.mnDeleteClick(Sender: TObject);
label 1;
var
    myFiles:TStringList;
    s:String;
    a:integer;
  begin
  if assigned(myUI) then
    begin
    myFiles:=FilesRemote.SelectedFiles;
    if myFiles.Count>0 then
      begin
      s:='Подтвердите удаление выделенный файлов / каталогов.';
      for a:=0 to myFiles.Count-1 do
        s:=s+#13#10+ExtractFileName(myFiles.Strings[a]);
      if sender = nil then goto 1;
      if MessageDlg(s, mtWarning, [mbYes, mbNo], 0, mbYes) = mrYes then
        begin
        1:
        for a:=0 to myFiles.Count-1 do
        begin
          myUI.Cmd_FileDelete(myFiles.Strings[a]);
        end;
        myUI.GetFileList(FilesRemote.Directory,'');
        end;
      end;
    end;
  end;
function TrdFileTransfer.send_f(myFile,d:string): Integer;
  var
    a:integer;
  begin
        myUI.Send(myFile,d);
  end;
procedure Delay(dwMilliseconds: Longint);
 var
   iStart, iStop: DWORD;
begin
   iStart := GetTickCount;
   repeat
     iStop := GetTickCount;
     Application.ProcessMessages;
   until (iStop - iStart) >= dwMilliseconds;
end;
procedure TrdFileTransfer.P1Click(Sender: TObject);
var
   f: THandle;
   buffer: Array [0..MAX_PATH] of Char;
   i, numFiles: Integer;
begin
   try
     Clipboard.Open;
     f:= Clipboard.GetAsHandle( CF_HDROP ) ;
     If f <> 0 Then
     Begin
       numFiles := DragQueryFile( f, $FFFFFFFF, nil, 0 ) ;
       for i:= 0 to numfiles - 1 do
       begin
         buffer[0] := #0;
         DragQueryFile( f, i, buffer, sizeof(buffer)) ;
         send_f(strpas(buffer), edRemoteDir.Text);
       end;
     end;
   finally
     Clipboard.close;
   end;
   if numfiles>0 then begin delay(1000); btnRemoteReloadClick(Sender) end;
end;
procedure TrdFileTransfer.tiClick(Sender: TObject);
begin
  if showing then hide
  else
  begin
    windowState:= wsNormal;
    show;
    setforegroundwindow(Handle);
  end;
end;
procedure TrdFileTransfer.FormClose(Sender: TObject; var Action: TCloseAction);
//var
//  h: hwnd;
begin
  if Assigned(FOnUIClose) then
    FOnUIClose(myUI.Tag); //ThreadID
  load_first:= True;
  Action:=caFree;
//  h:= findwindow('TrdFileTransfer',nil);
//  if IsWindowVisible(h) then
//  begin
//    postmessage(h, WM_CLOSE, 0, 0);
//  end;
end;
procedure TrdFileTransfer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if key = 27 then
 if shift=[ssshift] then
   begin
     if (activecontrol=FilesRemote )and(b_hm. Enabled)   then b_hm. click else
     if (activecontrol=FilesLocal)and(b_hm_.Enabled)   then b_hm_.click
   end else
   begin
     if (activecontrol=FilesRemote) and(btnRemoteReload.Enabled)  then btnRemoteReload.click else
     if (activecontrol=FilesLocal)and(btnLocalReload.Enabled) then btnLocalReload.click
   end;
 if key = VK_F1 then
   begin
     if (activecontrol=FilesRemote )and(sbtnReceive.Enabled)   then sbtnReceive.click else
     if (activecontrol=FilesLocal)and(sbtnSend.Enabled)  then sbtnSend.click
   end;
// if (key=ord('Q')) and (shift=[ssCtrl]) then
// begin
//    if messageBox(handle, pchar('Закрыть программу ?'), pchar('Выход'),MB_ICONINFORMATION + MB_OKCANCEL)=IDOK then MainForm.close;
// end;
//
// if (key=ord('X')) and (shift=[ssCtrl]) then
// begin
//    if messageBox(handle, pchar('Закрыть файловый менеджер ?'), pchar('Закрыть ФМ'),MB_ICONQUESTION + MB_OKCANCEL)=IDOK then close;
// end;
end;
procedure TrdFileTransfer.Label6MouseEnter(Sender: TObject);
var cn,i: integer; s,s_:string;
begin
 with TLabel(sender) do
 begin
  i:= fnd_rec(TPanel(TLabel(sender).Parent), True);
  with rr[i] do
  try
  s:= 'Получатель: '+to_path+#13'Итого: '+sel_files.count.tostring+#13#13;
  if sel_files.count>10 then cn:= 10 else cn:= sel_files.count-1;
  for i:=0 to cn do
      s_:= s_+extractfilename(sel_files[i])+#13;
      if sel_files.count-1>cn then
      s_:= s_+'...';
  Hint:= Trim(s+s_);
 except
  Hint:= '';
 end;
end;
end;
function TrdFileTransfer.add_pn(path:string; send: boolean):TGauge;
var pn: TPanel; ge:TGauge;
    lb: TLabel;
begin
 result:= nil;
 pn:= TPanel.create(pp);
 with pn do
 begin
   parent:= pp;
   styleelements:= [];
   color:= clWhite;
   showcaption:= False;
   if send then
   caption:= 'Send' else
   caption:= 'Recv';
   width:= 185;
   align:= alRight;
   align:= alLeft;
   Margins.Left  := 4;
   Margins.Top   := 4;
   Margins.Right := 4;
   Margins.Bottom:= 4;
   AlignWithMargins:= True;
   BevelKind:= bkFlat;
   BevelOuter:= bvNone;
   ParentBackground:= False;
   ParentFont:= True;
   ge:= TGauge.create(pn);
   with ge do
   begin
     parent:= pn;
     align:= alClient;
     Margins.Left  := 1;
     Margins.Top   := 1;
     Margins.Right := 1;
     Margins.Bottom:= 1;
     AlignWithMargins:= False;
     BorderStyle:= bsNone;
     if send then
     foreColor:= $00BFFFBF else
     foreColor:= $00FFE2C6;
     MaxValue:=  10000;
     Progress:=  0;
     pn.HelpContext:= longint(ge);
     result:= ge;
   end;
   lb:= TLabel.create(pn);
   with lb do
   begin
     parent:= pn;
     caption:= extractfilename(path);
     parentFont:= True;
     autosize:= False;
     align:= alCustom;
     alignment:= taLeftJustify;
     setBounds(7,7,147,13);
     pn.Tag:= longint(lb);
     showHint:= True;
     OnMouseEnter:= Label6MouseEnter;
   end;
   lb:= TLabel.create(pn);
   with lb do
   begin
     parent:= pn;
     caption:= '..';
     parentFont:= True;
     autosize:= False;
     align:= alCustom;
     alignment:= taLeftJustify;
     setBounds(7,pn.ClientHeight-20,147,13);
     ge.Tag:= longint(lb);
     showHint:= True;
     OnMouseEnter:= Label6MouseEnter;
   end;
   with TSpeedButton.create(pn) do
   begin
     parent:= pn;
     caption:= 'r';
     flat:= True;
     font.Color:= clGray;
     font.name:= 'Marlett';
     font.size:= 12;
     setBounds(157,3,22,19);
     onClick:= SpeedButton10Click;
   end;
   with TImage.create(pn) do
   begin
     parent:= pn;
     autosize:= True;
     Transparent:= True;
     setBounds(7,24,24,24);
     picture:= logo.picture;
   end;
 end;
 sendmessage(pp.Handle, WM_HSCROLL, SB_RIGHT, 0);
end;
procedure TrdFileTransfer.Timer1Timer(Sender: TObject);
var pn:TPanel;
begin
try
  pn:= TPanel(longint(Timer1.Tag));
  inc(Timer1_cn);
  if Timer1_cn > 10 then
  begin
     pn.AlignWithMargins:= True;
     Timer1.Enabled:=      False
  end else
          pn.AlignWithMargins:= not pn.AlignWithMargins;
except
end;
end;
function TrdFileTransfer.next_rec(p:integer):integer;
var i: integer;
begin
  result:= -1;
  for i:=p+1 to high(rr) do
  with rr[i] do
  if (not deleted) then
  begin
    result:= i;
    EXIT
  end;
end;
function TrdFileTransfer.fnd_rec(pn_:TPanel; all:boolean=False): integer;
var i: integer;
begin
  result:= -1;
  for i:=0 to high(rr) do
  with rr[i] do
  if (all and (not deleted))
  or ((not deleted) and (not finished)) then
  if pn = pn_ then
  begin
   result:= i;
   EXIT
  end;
end;
procedure TrdFileTransfer.set_info(snd:boolean; b:int64);
begin
  if snd then
      al_b.caption:= al_b.hint +
      str_size(recv_bytes,False,False)+' ['+str_size(recv_bytes)+'] / '+
      str_size(send_bytes+b,False,False)+' ['+str_size(send_bytes+b)+']';
  if snd=False then
      al_b.caption:= al_b.hint +
      str_size(recv_bytes+b,False,False)+' ['+str_size(recv_bytes+b)+'] / '+
      str_size(send_bytes,False,False)+' ['+str_size(send_bytes)+']';
end;
procedure TrdFileTransfer.sbtnRemoteLevelUpClick(Sender: TObject);
begin
  FilesRemote.OneLevelUp;
end;
procedure TrdFileTransfer.sbtnLocalLevelUpClick(Sender: TObject);
begin
  FilesLocal.OneLevelUp;
end;
function TrdFileTransfer.add_rc(send:boolean; to_dir:string; ff:TStringList; g:TGauge): Integer;
var s: string;
begin
  setlength(rr, length(rr)+1);
  with rr[high(rr)] do
  begin
    sel_files:= TStringList.create;
    sel_files.Assign(ff);
    finished:= False; is_send:= send;
    deleted:=  False;
    to_path:=  to_dir;
    if sel_files.count>0 then
    begin
     s:= extractfilename(sel_files[0]);
     from_path:= extractfilepath(sel_files[0]);
    end;
    g_:= g;
    pn:= TPanel(g_.parent);
    lb:= TLabel(pn.Tag);
    lb.caption:= 'PAUSED. '+s;
    result:= high(rr);
  end;
end;

function not_finished(): integer;
var i: integer;
begin
  result:= -1;
  for i:=0 to high(rr) do
  with rr[i] do
  if (not deleted) then if g_.ForeColor<>$00FFD9FF then
  begin
    result:= i;
    EXIT
  end;
end;
function TrdFileTransfer.end_copy(f: string):integer;
begin
end;
function TrdFileTransfer.file_exists(sd,ya,na: boolean; src,dst: string): integer;
var
  sz_1,sz_2,s,n_s: string;
  l_1,l_2: TListItem;
begin
  result:= mrNone;
    if YA then begin result:= mrYes; EXIT end;
    n_s:= extractfilename(src);
    if not sd then
    begin
      l_1:= FilesRemote. FindCaption(0,n_s,False,False,False);
      l_2:= FilesLocal.FindCaption(0,n_s,False,False,False);
    end else
    begin
      l_1:= FilesLocal.FindCaption(0,n_s,False,False,False);
      l_2:= FilesRemote. FindCaption(0,n_s,False,False,False);
    end;
    if (l_1<>nil)and(l_2<>nil)and(l_1.caption + l_1.subitems[0] = l_2.caption + l_2.subitems[0]) then
    begin
      if (l_1.subitems[1]<>l_2.subitems[1]) or (l_1.subitems[2]<>l_2.subitems[2]) then
      begin
        if NA then begin result:= mrNo;  EXIT end;
        if l_1.subitems[0]='Каталог' then     s:= 'Заменить каталог?'#13#13 else
                                              s:= 'Заменить файл?'#13#13;
        if l_1.subitems[1]<>'' then sz_1:= #13'Размер: '+l_1.subitems[1];
        if l_2.subitems[1]<>'' then sz_2:= #13'Размер: '+l_2.subitems[1];
        s:= s+'Источник:'#13#13+src+#13+'Изменено: '  +l_1.subitems[2]+sz_1+
        #13#13'Получатель:'#13#13+dst+#13+'Изменено: '  +l_2.subitems[2]+sz_2;
        result:= MessageDlg(s, mtInformation, [mbYes,mbYesToAll,mbNo,mbNoToAll,mbClose],0)
      end else
      begin
        add_lg(timetostr(now) + ': ' + src +' - файл не изменен');
        result:= mrIgnore;
        EXIT;
      end;
    end;
end;
procedure TrdFileTransfer.check_task();
var i: integer;
begin
   for i:=0 to pp.ControlCount-1 do
   if pp.Controls[i] is TPanel then
   with pp.Controls[i] as TPanel do if visible then EXIT;
   lblNoTask.show;
   setlength(rr,0);
end;
function TrdFileTransfer.rec_finished(pn:TPanel; isDelete:boolean=False): integer;
var i: integer;
begin
     result:= -1;
     i:= fnd_rec(pn, true);
     if i >-1 then
     begin
          rr[i].finished:= True;
      if isDelete then
          rr[i].deleted:=  True;
      result:= i;
     end;
end;
procedure TrdFileTransfer.RenameFileExplorer(Files: TRtcPFileExplorer;
  Item: TListItem; const NewName: string);
var
  OldPath: string;
begin
  OldPath := Files.GetFileName(Item);
  if (OldPath = '') or (OldPath = '..') then
    raise EAbort.Create('Can not rename sys_name');
  if Files.Local then
      Win32Check(RenameFile(OldPath, ExtractFilePath(OldPath) + NewName)) else
      myUI.Cmd_FileRename(OldPath, ExtractFilePath(OldPath) + NewName);
  Files.SetFileName(Item, NewName);
end;
procedure TrdFileTransfer.clear_deleted;
var
  rr_: TArrayOfTRec;
  i, c: integer;
begin
  SetLength(rr_, Length(rr));
  c := 0;
  for I := 0 to Length(rr)-1 do
    if not rr[i].deleted then
      begin
        rr_[c] := rr[i];
        Inc(c);
      end
    else
      begin
        rr[i].sel_files.Free;
        SafeDeleteObject(rr[i].pn);
        rr[i].g_ := nil;
      end;
  SetLength(rr_, c);
  rr := rr_;
end;
function TrdFileTransfer.renameF_(pn:TPanel; back:Boolean): boolean;
var i: integer; dr:string;
begin
          result:= False;
          i:= fnd_rec(pn); if i=-1 then EXIT;
          result:= True;
          with rr[i] do
          if not is_send then
          begin
            if assigned(myUI) then
            begin
            dr:= ExcludeTrailingPathDelimiter(from_path);
            if back then
               myUI.Cmd_FileRename(dr+'_', dr) else
               myUI.Cmd_FileRename(dr,     dr+'_');
            end;
          end else
          begin
          end;
end;
procedure TrdFileTransfer.RestoreScroolListView(lv: TRtcPFileExplorer;
  const info: TListViewInfo);
var
  scroll_info: TScrollInfo;
  R: TRect;
  i: Integer;
begin
  SendMessage(lv.Handle, WM_SETREDRAW, 0, 0);
  try
    if (lv.Items.Count = info.cnt) and (info.index >= 0) then
      begin
        R := lv.Items[0].DisplayRect(drBounds);
        lv.Scroll(0, info.vert_scroll_pos * (R.Bottom - R.Top));
//        for i := 0 to info.vert_scroll_pos-1 do
//          SendMessage(lv.Handle, WM_VSCROLL, SB_LINEDOWN, 0);
        lv.ItemIndex := info.index
      end
    else if lv.Items.Count > 0 then
      lv.ItemIndex := 0;
  finally
    SendMessage(lv.Handle, WM_SETREDRAW, 1, 0);
  end;
end;
procedure TrdFileTransfer.SpeedButton10Click(Sender: TObject);
label
  0, 1;
var
  i, a: Integer;
  f0, send, copying: Boolean;
  g_: TGauge;
  p:TPanel;
  ff: TStringList;
begin
  CancelBatchClick(Sender);
  exit;
  p := TPanel(TSpeedButton(Sender).Parent);
  copying := False;
  g_ := TGauge(LongInt(p.HelpContext));
  Send := TPanel(g_.Parent).Caption = 'Send';
  if (cur_files.Count = 0) or (g_.ForeColor = $00FFD9FF) or (Copy(TLabel(TPanel(g_.Parent).Tag).Caption, 1, 7) = 'PAUSED.')
  then
    goto 0;
  copying := True;
  curr_g := g_;
  stopped := True;
  0:
    if copying then
    begin
      if Send then
      begin
        if myUI.Send_FileName <> '' then
        begin
          f0 := (myUI.Send_FileCount = 1);
          myUI.Cancel_Send(IncludeTrailingPathDelimiter(myUI.Send_FromFolder) + myUI.Send_FileName);
          if myUI.Send_FileCount = 0 then
            goto 1
          else
          if f0 then
          begin
            sb.HelpContext := 0;
            tr_dy.Tag := longint(p);
            sb.Tag := 0;
            tr_dy.Enabled := True;
          end;
        end;
      end
      else
      begin
        if myUI.Recv_FileName <> '' then
        begin
          f0 := (myUI.Recv_FileCount = 1);
          myUI.Cancel_Fetch(myUI.Recv_FileName);
          if myUI.Recv_FileCount = 0 then
            goto 1
          else
          if f0 then
          begin
            sb.HelpContext := 0;
            tr_dy.Tag := LongInt(p);
            sb.Tag := 1;
            tr_dy.Enabled := True;
          end;
        end;
      end;
    end
    else
    begin
      1:
        if copying then
         next_task(p, True)
        else
        begin
         i := rec_finished(p, True);
         SafeDeleteObject(p);
        end;
    end;
  check_task;
end;
procedure TrdFileTransfer.tr_dyTimer(Sender: TObject);
begin
  tr_dy.Enabled := False;
  if not Assigned(myUI) then
    Exit;
  sb.HelpContext := sb.HelpContext + 1;
  try
    if ((sb.Tag = 1) and (myUI.Recv_FileCount = 0))
    or ((sb.Tag = 0) and (myUI.Send_FileCount = 0)) then
    begin
      next_task(TPanel(tr_dy.Tag), True);
      Exit;
    end
    else
    if sb.HelpContext < 50 then
      tr_dy.Enabled := True;
  except
  end;
end;
procedure TrdFileTransfer.FilesRemoteEnter(Sender: TObject);
begin
  Panel11.Color := $00FFF9F2;
  Panel12.Color := clwhite;
  pn.Color := Panel11.Color;
  Panel5.Color := Panel11.Color;
  pn_.Color := Panel12.Color;
  Panel7.Color := Panel12.Color;
  with FilesRemote do
    if selCount = 0 then
      selected := ItemFocused;
  FilesRemoteSelectItem(nil, FilesRemote.ItemFocused, True);
end;
procedure TrdFileTransfer.FilesLocalEnter(Sender: TObject);
begin
  Panel12.Color := $00FFF9F2;
  Panel11.Color := clWhite;
  pn_.Color := Panel12.Color;
  Panel7.Color := Panel12.Color;
  pn.Color := Panel11.Color;
  Panel5.Color := Panel11.Color;
  with FilesLocal do
    if selCount = 0 then
      selected := ItemFocused;
  FilesLocalSelectItem(nil, FilesLocal.ItemFocused, True);
end;

procedure TrdFileTransfer.FilesLocalFileOpen(Sender: TObject;
  const FileName: string);
var
  oai: TOpenAsInfo;
  status: HRESULT;
begin
  oai.pcszFile    := PChar(FileName);
  oai.pcszClass   := nil;
  oai.oaifInFlags := OAIF_EXEC;
  status := SHOpenWithDialog(Handle, oai);
  if  Succeeded(status) or
      (status and HRESULT($80070000) = $80070000) and  // The sytem code
      (status and HRESULT($0000FFFF) = $4C7) then   // 1223 операция отменена пользователем
        begin
          exit;
        end;
  raise EOleSysError.Create('', status, 0);
end;
procedure TrdFileTransfer.myUIRecv(Sender: TRtcPFileTransferUI);
var
  cn,i: int64; from_,s: String;
begin
  set_info(False, myUI.Recv_BytesComplete);
  if curr_g = nil then
    Exit;
  if resv_stop then
    Exit;
  try
    i := fnd_rec(TPanel(curr_g.Parent));
    if i >- 1 then
    begin
      from_ := rr[i].from_path;
      cn := rr[i].sel_files.count;
    end;
    if myUI.Recv_BytesTotal <> 0 then
      curr_g.Progress := Round(myUI.Recv_BytesComplete / myUI.Recv_BytesTotal * 10000)
    else
      curr_g.Progress := 0;
    TLabel(curr_g.Tag).Caption := IntToStr(cn - myUI.Recv_FileCount) + '/' + cn.ToString;
    TLabel(TPanel(curr_g.Parent).Tag).Caption:= ExtractFileName(myUI.Recv_FileName);
    Caption := 'Передано: ' + str_size(myUI.Recv_BytesComplete, False, False) + ' Итого: ' + str_size(myUI.Recv_BytesTotal, False, False);
    s := from_+ myUI.Recv_FileName;
    if myUI.Recv_FileIn = myUI.Recv_FileSize then
      add_lg(TimeToStr(Now) + ':  Загрузка из "' + s +'" в "' + myUI.Recv_ToFolder + ExtractFileName(s) + '" (' + str_size(myUI.Recv_FileSize) + ')');
  except
    Caption:= 'E: ' + Caption;
  end;
end;
procedure TrdFileTransfer.myUIRecvCancel(Sender: TRtcPFileTransferUI);
begin
  Exit;
end;
procedure TrdFileTransfer.myUIRecvStart(Sender: TRtcPFileTransferUI);
begin
  stopped := False;
  myUIRecv(Sender);
end;
procedure TrdFileTransfer.myUIRecvStop(Sender: TRtcPFileTransferUI);
var
  a,n,i: integer;
begin
  if resv_stop then
    Exit;
  myUIRecv(Sender);
  if (myUI.Recv_FileCount = 0) then
  try
    recv_bytes := recv_bytes + myUI.Recv_BytesTotal;
    stopped := True;
    TLabel(TPanel(curr_g.Parent).Tag).Caption:= Format('%.0n / %.0n KB', [myUI.Recv_BytesComplete / 1024, myUI.Recv_BytesTotal / 1024]);
   curr_g.Progress := curr_g.MaxValue;
   curr_g.ForeColor := $00FFD9FF;
   btnLocalReload.Click;
   Timer1_cn := 0;
   Timer1.Tag := LongInt(TPanel(curr_g.Parent));
   Timer1.Enabled := True;

    if assigned(curr_g) then
      next_task(TPanel(curr_g.Parent));
  except
  end;
end;
procedure TrdFileTransfer.myUISend(Sender: TRtcPFileTransferUI);
var
  s, to_: String;
  cn, i: Integer;
begin
  set_info(True, myUI.Send_BytesComplete);
  if send_stop then
    Exit;
  if curr_g = nil then
    Exit;
  try
    i := fnd_rec(TPanel(curr_g.Parent));
    if i >- 1 then
    begin
      to_:= rr[i].to_path;
      cn := rr[i].sel_files.Count;
    end;
    if myUI.Send_BytesTotal <> 0 then
      curr_g.Progress := Round(myUI.Send_BytesPrepared / myUI.Send_BytesTotal * 10000)
    else
      curr_g.Progress := 0;
    TLabel(curr_g.Tag).Caption := IntToStr(cn - myUI.Send_FileCount) + '/' + cn.ToString;
    TLabel(TPanel(curr_g.Parent).Tag).Caption:= ExtractFileName(myUI.Send_FileName);
    Caption:= 'Передано: ' + str_size(myUI.Send_BytesComplete, False, False) + ' Итого: ' + str_size(myUI.Send_BytesTotal, False, False);
    s := myUI.Send_FromFolder + myUI.Send_FileName;
    if myUI.Send_FileOut = myUI.Send_FileSize then
      add_lg(TimeToStr(now) + ':  Выгрузка из "' + s + '" в "' + to_ + ExtractFileName(s) + '" (' + str_size(myUI.Send_FileSize) + ')');
  except
    Caption := 'E: ' + Caption;
  end;
end;

procedure TrdFileTransfer.myUISendCancel(Sender: TRtcPFileTransferUI);
begin
  Exit;
end;
procedure TrdFileTransfer.myUISendStart(Sender: TRtcPFileTransferUI);
begin
  stopped := False;
  MyUISend(Sender);
end;
procedure TrdFileTransfer.myUISendStop(Sender: TRtcPFileTransferUI);
var
  a, n, i, index: integer;
begin
  MyUISend(sender);
  if (myUI.Send_FileCount = 0) then
  try
    send_bytes := send_bytes + myUI.Send_BytesTotal;
    stopped := True;
    TLabel(TPanel(curr_g.Parent).Tag).Caption:= Format('%.0n / %.0n KB', [myUI.Send_BytesPrepared / 1024, myUI.Send_BytesTotal / 1024]);
    curr_g.Progress := curr_g.MaxValue;
    curr_g.ForeColor := $00FFD9FF;
    btnRemoteReload.Click;
    Timer1_cn := 0;
    Timer1.Tag := LongInt(TPanel(curr_g.Parent));
    Timer1.Enabled := True;
    if assigned(curr_g) then
      next_task(TPanel(curr_g.Parent));
  except
  end;
end;
function TrdFileTransfer.wrong_caption(s: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 1 to Length(s) do
    if not TPath.IsValidFileNameChar(s[i]) then
    begin
      Result := i;
      Exit;
    end;
end;
procedure TrdFileTransfer.N3Click(Sender: TObject);
label
  1;
var
  s: String;
begin
  if FilesRemote.ItemFocused = nil then
    Exit;
  s := FilesRemote.ItemFocused.Caption;
  1:
    if InputQuery('Переименование', 'Введите новое имя файла', s) then
    begin
      if s= '' then
        Exit;
      if s = FilesRemote.ItemFocused.Caption then
        Exit;
      if wrong_caption(s) > -1 then
        goto 1;
      RenameFileExplorer(FilesRemote, FilesRemote.ItemFocused, s);
    end;
end;
function TrdFileTransfer.next_task(pan:TPanel; del:boolean=False; all:boolean=False): integer;
var
  a, n, i: integer;
begin
  Result := -1;
  clear_deleted;
  i := fnd_rec(pan, all);
  if i = -1 then
    Exit;
  with rr[i] do
  begin
    finished := True;
    if del then
    begin
      deleted := True;
      pn.Free;
    end;
  end;
  n := next_rec(i);
  if n = -1 then
    Exit;
  if not assigned(myUI) then
    Exit;
  with rr[n] do
  begin
    stopped := False;
    if is_send then
      send_stop:= False
    else
      resv_stop := False;
    g_.Progress := 0;
    curr_g := g_;
    cur_files.Assign(sel_files);
    with cur_files do
    if count > 0 then
      for a := 0 to Count - 1 do
      if is_send then
        myUI.Send(Strings[a], to_path)
      else
        myUI.Fetch(Strings[a], to_path);
  end;
end;

procedure TrdFileTransfer.myUINotifyFileBatchSend(Sender: TObject;
  const task: TBatchTask; mode: TModeBatchSend);
begin
  OnSendBatch(Sender, task, mode);
end;

procedure TrdFileTransfer.OnSendBatch(Sender: TObject; const task: TBatchTask;
  mode: TModeBatchSend);
  function GetTaskPanelIndex(): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for I := 0 to Length(rr)-1 do
      if rr[i].taskID = task.Id then
        exit(i);
  end;
var
  s, to_: String;
  cn, i, index: Integer;
  g: TGauge;
  reload: TSpeedButton;
begin
  Index := GetTaskPanelIndex();
  if Index = -1 then exit;
//  set_info(True, task.SentSize);
    to_:= rr[index].to_path;
    cn := rr[index].sel_files.Count;
    g := rr[index].g_;
    if rr[i].direction = sbtReceiving then
      reload := btnLocalReload else
      reload := btnRemoteReload;

  case mode of
    mbsFileStart:
      begin
        TLabel(TPanel(g.Parent).Tag).Caption:= ExtractFileName(task.Files[task.Current].file_path);
        TLabel(g.Tag).Caption := IntToStr(task.Current+1) + '/' + task.FileCount.ToString;
      end;
    mbsFileData:
      begin
        g.Progress := Round(task.Progress * 10000);
        FCurrentBytesTransfer := FCurrentBytesTransfer + task.LastChunkSize;
        Caption:= 'Передано: ' + str_size(FCurrentBytesTransfer, False, False) + ' Итого: ' + str_size(FTotalBytesTransfer, False, False);
      end;
    mbsFileStop:
      begin
        TLabel(TPanel(g.Parent).Tag).Caption:= Format('%.0n / %.0n KB', [task.SentSize / 1024, task.Size / 1024]);
        add_lg(TimeToStr(now) + ':  Выгрузка из "' + task.Files[task.Current].file_path + '" в "' + ExtractFileName(task.Files[task.Current].file_path) + '" (' + str_size(task.Files[task.Current].file_size) + ')');
        reload.Click;
      end;
    mbsTaskStart:
      begin
        FTotalBytesTransfer := FTotalBytesTransfer + task.Size;
      end;
    mbsTaskFinished:
      begin
        rr[index].taskID := TGUID.Empty;
        rr[index].finished := true;
        rr[index].deleted := true;
        g.Progress := g.MaxValue;
        g.ForeColor := $00FFD9FF;
        reload.Click;
      end;
    mbsTaskError:
      begin
        rr[index].taskID := TGUID.Empty;
        rr[index].finished := true;
        rr[index].deleted := true;
        reload.Click;
        add_lg(TimeToStr(now) + ':  [ERROR] Выгрузка из "' + task.Files[task.Current].file_path + '" в "' + ExtractFileName(task.Files[task.Current].file_path) + '" (' + str_size(myUI.Send_FileSize) + ') - '+task.ErrorString );
        TaskMessageDlg('Error', task.ErrorString, mtError, [mbOK], 0, mbOK);
      end;
  end;

  clear_deleted;
  lblNoTask.Visible := Length(rr) = 0;
end;
procedure TrdFileTransfer.comp_border(cp:twincontrol; pix:byte);
var formrgn : hrgn;
begin
  formrgn := CreateRectRgn(pix,pix, cp.width - pix, cp.height - pix);
  SetWindowRgn(cp.Handle, formrgn, True);
end;
procedure TrdFileTransfer.FormShow(Sender: TObject);
var
  i: Integer;
begin
  FilesLocal.Local := False;
  FilesLocal.Local := True;
  FilesRemote.StyleElements := [];
  FilesLocal.StyleElements := [];
  Splitter1.StyleElements := [];
  FilesRemote.GridLines := True;
  FilesLocal.GridLines := True;

//  Label1.caption:= host_nn;
//  Label3.caption:= serv_nn;
end;
procedure TrdFileTransfer.FormActivate(Sender: TObject);
var
  i: Integer;
begin
  if load_first then
  begin
    application.ProcessMessages;
    load_first:= False;
    FilesRemote.setfocus;
    with FilesRemote do
    for i:=0 to Items.count-1 do
    with edRemoteDir.ItemsEx.Add do
    begin
      caption:= FilesRemote.Items[i].caption;
      ImageIndex:=0;
    end;
    FilesLocal.setfocus;
    with FilesLocal do
    for i:=0 to Items.count-1 do
    with edLocalDir.ItemsEx.Add do
    begin
      caption:= FilesLocal.Items[i].caption;
      ImageIndex:=1;
    end;
    if FilesRemote.items.count>0 then add_lg(timetostr(now)+':  Соединение успешно установлено.');
  edRemoteDir. Text:= 'C:\';  btnRemoteReloadClick(nil);
  edLocalDir.Text:= 'C:\';  btnLocalReloadClick(nil);
  end;
end;
procedure TrdFileTransfer.edRemoteDirKeyPress(Sender: TObject; var Key: Char);
var s: string;
begin
  if Key=#13 then
    begin
    Key:=#0;
     s:= edRemoteDir.Text;
     if ExtractFileExt(s)='' then
        edRemoteDir.Text:= IncludeTrailingPathDelimiter(s);
     btnRemoteReloadClick(nil);
    end;
end;
procedure TrdFileTransfer.edRemoteDirSelect(Sender: TObject);
var s: string;
begin
 s:= edRemoteDir.Items[edRemoteDir.Itemindex];
 delete(s,1,pos('(',s));
 edRemoteDir.Text:= copy(s,1,2)+'\';
 btnRemoteReloadClick(nil);
end;
procedure TrdFileTransfer.edLocalDirKeyPress(Sender: TObject; var Key: Char);
var s: string;
begin
  if Key=#13 then
    begin
    Key:=#0;
     s:= edLocalDir.Text;
     if ExtractFileExt(s)='' then
        edLocalDir.Text:= IncludeTrailingPathDelimiter(s);
     btnLocalReloadClick(nil);
    end;
end;
procedure TrdFileTransfer.edLocalDirSelect(Sender: TObject);
var s: string;
begin
   s:= edLocalDir.Items[edLocalDir.Itemindex];
   delete(s,1,pos('(',s));
   edLocalDir.Text:= copy(s,1,2)+'\';
   FilesLocal.onPath(edLocalDir.Text);
    try
     FilesLocal.Selected:=    FilesLocal.Items[0];
     FilesLocal.ItemFocused:= FilesLocal.Selected;
    except
    end;
    FilesLocal.SetFocus;
end;
type
  TListViewX = class(TListView);
procedure TrdFileTransfer.FilesRemoteKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
label 1;
var
  s: string;
begin
 if FilesRemote.IsEditing then exit;
 if key in [VK_UP,VK_DOWN,VK_END,VK_HOME,VK_PRIOR,VK_NEXT] then VK_UPDOWN:= True;
 if key = VK_F2 then
  begin
    if FilesRemote.ItemFocused <> nil then
      FilesRemote.ItemFocused.EditCaption;
    exit;
  end;
 if key = VK_F5 then
  begin
    if sbtnReceive.Enabled then
      sbtnReceiveClick(sbtnSend);
    exit;
  end;
 if key=VK_UP then
 if shift = [ssAlt] then
 begin
    edRemoteDir.setfocus;
    EXIT;
 end;
 if key=ord('A') then
 if shift = [ssctrl] then
 begin
    FilesRemote.SelectAll;
    EXIT;
 end;
 if key = VK_RETURN then
 if shift = [ssctrl] then
 if sbtnReceive.Enabled then
 begin
    sbtnReceive.click;
    EXIT;
 end;
 if key = VK_DELETE then
 if b_dl.Enabled then
 begin
    b_dl.click;
    EXIT;
 end;
 if key = VK_F7 then
 if b_dr.Enabled then
 begin
    b_dr.click;
    EXIT;
 end;
 if key = VK_BACK then
  btnRemoteBackClick(btnRemoteBack);

// клавиша backspace переназначена на функцию "назад"
// if key in [VK_BACK] then
// try
//   s:= ExcludeTrailingPathDelimiter(edRemoteDir.Text);
//   KEY_BACK:= True;
//   foc_:= extractfilename(s);
//   FilesRemote.OneLevelUp(True);
//
//   FilesRemote.SetFocus;
// except
// end;
 if key in [VK_RETURN] then
 try
  FilesRemote.DblClick;
  FilesRemote.ItemFocused:= FilesRemote.Items[0];
  FilesRemote.Selected:=    FilesRemote.ItemFocused;
  except
  end;
end;
procedure TrdFileTransfer.FilesLocalKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
label 1;
var
  l: TListItem; s: string;
begin
 if FilesLocal.IsEditing then exit;
 if key in [VK_UP,VK_DOWN,VK_END,VK_HOME,VK_PRIOR,VK_NEXT] then VK_UPDOWN:= True;
 if key = VK_F2 then
  begin
    if FilesLocal.ItemFocused <> nil then
      FilesLocal.ItemFocused.EditCaption;
    exit;
  end;
 if key = VK_F5 then
  begin
    if sbtnSend.Enabled then
      sbtnSendClick(sbtnSend);
    exit;
  end;

 if key=VK_UP then
 if shift = [ssAlt] then
 begin
    edLocalDir.setfocus;
    EXIT;
 end;
 if key=ord('A') then
 if shift = [ssctrl] then
 begin
    FilesLocal.SelectAll;
    EXIT;
 end;
 if key = VK_RETURN then
 if shift = [ssctrl] then
 if sbtnSend.Enabled then
 begin
    sbtnSend.click;
    EXIT;
 end;
 if key = VK_DELETE then
 if b_dl2.Enabled then
 begin
    b_dl2.click;
    EXIT;
 end;
 if key = VK_F7 then
 if b_dr_.Enabled then
 begin
    b_dr_.click;
    EXIT;
 end;
  if key = VK_BACK then
    btnRemoteBackClick(btnLocalBack);

// if key in [VK_BACK] then
// try
//   s:= ExcludeTrailingPathDelimiter(edLocalDir.Text);
//   FilesLocal.OneLevelUp(True);
//
//   l:= FilesLocal.FindCaption(0,extractfilename(s),False,False,False);
//   if l<>nil then
//   begin
//       1:
//       FilesRemote.ClearSelection;
//       FilesLocal.ItemFocused:= l;
//       FilesLocal.Selected:=    l;
//   end else
//   begin
//     l:= FilesLocal.items[0];
//     goto 1;
//   end;
//
//   FilesLocal.SetFocus;
// except
// end;
 if key in [VK_RETURN] then
 try
  FilesLocal.DblClick;
  FilesLocal.ItemFocused:= FilesLocal.Items[0];
  FilesLocal.Selected:=    FilesLocal.ItemFocused;
  except
  end;
end;
procedure TrdFileTransfer.b_hmClick(Sender: TObject);
begin
  edRemoteDir.Text:= '';
  btnRemoteReloadClick(nil);
end;
function get_size(s: string): int64;
var i: integer;
    _,q,v: string;
begin
  for i:= length(s) downto 1 do if s[i]=#32 then
  begin
    application.ProcessMessages;
    v:= ToLower(copy(s,i+1,length(s)));
    _:= copy(s,1,i-1);
    break
  end;
  for i:= 1 to length(_) do
  begin
   application.ProcessMessages;
   if _[i].IsDigit then q:= q+_[i];
  end;
  result:= StrToInt64Def(q,0);
  if v='kb' then
     result:= result*1024 else
  if v='mb' then
     result:= result*1024*1024 else
  if v='gb' then
     result:= result*1024*1024*1024;
end;
function format_str(s:string; delim:char=','):string;
var l,i,v,p:integer; des:string;
begin
  p:= pos(delim,s);
  if p>0 then
  begin
   des:= copy(s,p,length(s));
   delete(s,p,length(s));
  end;
  l:= length(s); v:=0;
  while l>1 do
  begin
   inc(v);
   if v=3 then
   begin
    insert(' ',s, l);
    v:=0;
   end;
   dec(l);
  end;
  result:= s+des;
end;
function TrdFileTransfer.str_size(sz:int64; gb:boolean=true; mb:boolean=true; kb:boolean=true; round_:boolean=false; dig:byte=1): string;
var s:string;
function dig_(n:string; c:integer): string;
label 1;
var p:integer;
begin
  p:= pos(',',n); if p>0 then begin delete(n,succ(p)+c,length(n)); goto 1 end;
  p:= pos('.',n); if p>0 then delete(n,succ(p)+c,length(n));
  1:
  result:= n;
end;
begin
 if gb then
 if sz div (1024*1024*1024) >0 then
 begin
   if round_ then
   begin
   s:= floattostrf(round(sz/(1024*1024*1024)),ffgeneral,10,0);
   end else
   s:= floattostrf(sz/(1024*1024*1024),ffgeneral,10,10);
   s:= format_str(s);
   result:= dig_(s,dig)+' Gb';
   EXIT
 end else
 if not MB and not KB then EXIT;
 if mb then
 if sz div (1024*1024) >0 then
 begin
   if round_ then
   begin
   s:= floattostrf(round(sz/(1024*1024)),ffgeneral,10,0);
   end else
   s:= floattostrf(sz/(1024*1024),ffgeneral,10,10);
   s:= format_str(s);
   result:= dig_(s,dig)+' Mb';
   EXIT
 end else
 if not KB then EXIT;
 if kb then
 if sz div 1024 >0 then
 begin
   if round_ then
   begin
   s:= floattostrf(round(sz/1024),ffgeneral,10,0);
   end else
   s:= floattostrf(sz/1024,ffgeneral,10,10);
   s:= format_str(s);
   result:= dig_(s,dig)+' Kb';
   EXIT
 end;
   result:= inttostr(sz);
   result:= result+' b'
end;
function TrdFileTransfer.info2pn(lv: TRtcPFileExplorer): Int64;
var p,i: integer; sz: int64; s,s2: string;
begin
 result:= 0;
try
 sz:= 0; p:= 0;
  for i:=0 to lv.Items.Count-1 do
    with lv.Items[i] do
      if Selected then
      begin
       Application.ProcessMessages;
       inc(p);
       if SubItems.Count > 0 then
        sz := sz + get_size(SubItems[1]);
      end;
 result:= sz;
 s:= str_size(sz); s2:= str_size(sz,False,False);
 if s<>s2 then s:= s2+' ['+s+']';
 if lv = FilesRemote then
    pn. caption:= 'Выбрано '+p.tostring+' объектов '+s else
    pn_.caption:= 'Выбрано '+p.tostring+' объектов '+s
except
end;
end;
procedure TrdFileTransfer.FilesRemoteSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
label 0,1,2;
var lev0,root: Boolean; ind: integer;
begin
  root:= FilesRemote.Directory='';
  if root then goto 2;
  lev0:= (FilesRemote.selcount=1)and(item.Caption='..');
  ind:= FilesRemote.ItemIndex;
  2:
  b_dl.Enabled:= (not root)and(Ind<>-1)and(not lev0);
  sbtnReceive.Enabled:= (not root)and(Ind<>-1)and(not lev0)and(FilesLocal.Directory<>'');
  1:
  b_hm.Enabled:= not root;
  sbtnRemoteLevelUp.Enabled:= not root;
  b_dr.Enabled:= not root;
  0:
  if sender<>nil then
        FilesLocalSelectItem(nil, FilesLocal.ItemFocused, True);
  if activecontrol=FilesLocal then
  begin
     if (FilesLocal.Selected<>nil)and(FilesLocal.GetFileName(Item)<>'..') then
         sb.SimpleText:= FilesLocal.GetFileName(Item)
  end else
     if (FilesRemote.Selected<>nil)and(FilesRemote.GetFileName(Item)<>'..') then
         sb.SimpleText:= FilesRemote.GetFileName(Item);
end;
procedure TrdFileTransfer.FilesLocalSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
label 0,1,2;
var lev0,root: Boolean; ind: integer;
begin
  root:= FilesLocal.Directory='';
  if root then goto 2;
  lev0:= (FilesLocal.selcount=1)and(item.Caption='..');
  ind:= FilesLocal.ItemIndex;
  2:
  b_dl2.Enabled:= (not root)and(Ind<>-1)and(not lev0);
  sbtnSend.Enabled:= (not root)and(Ind<>-1)and(not lev0)and(FilesRemote.Directory<>'');
  1:
  b_hm_.Enabled:= not root;
  sbtnLocalLevelUp.Enabled:= not root;
  b_dr_.Enabled:= not root;
  0:
  if sender<>nil then
       FilesRemoteSelectItem(nil, FilesRemote.ItemFocused, True);
  if activecontrol=FilesLocal then
  begin
     if (FilesLocal.Selected<>nil)and(FilesLocal.GetFileName(Item)<>'..') then
         sb.SimpleText:= FilesLocal.GetFileName(Item)
  end else
     if (FilesRemote.Selected<>nil)and(FilesRemote.GetFileName(Item)<>'..') then
         sb.SimpleText:= FilesRemote.GetFileName(Item);
end;
procedure TrdFileTransfer.P2Click(Sender: TObject);
label 1;
var s: string;
begin
  if not assigned(myUI) then EXIT;
  if FilesRemote.ItemFocused=nil then EXIT;
  s:=FilesRemote.ItemFocused.caption;
  1:
  if inputquery('Переименование', 'Введите новое имя файла', s) then
  begin
     if s='' then EXIT;
     RenameFileExplorer(FilesRemote, FilesRemote.ItemFocused, s);
  end;
end;
procedure TrdFileTransfer.b_ppClick(Sender: TObject);
begin
 lockwindowupdate(Handle);
 try
 if panel.Align=alLeft then
 begin
    panel.Hide;
    panel_.Align:= alLeft;
    splitter1.align:= alRight; splitter1.align:= alLeft;
    panel. Align:= alClient;
    panel.show;
    b_pp.Parent:= panel;
    b_pp.show;

      sbtnSend.Align:= alRight;
      sbtnSend.Layout:= blGlyphRight;
      sbtnSend.Glyph:= FBmpR;
      b_dr_.Align:= alLeft;
      b_dl2.Align:= alLeft;
      Panel_1.Padding.Right:= 0; Panel_1.Padding.Left:= 13;
      sbtnReceive.Align:= alLeft;
      sbtnReceive.Layout:= blGlyphLeft;
      sbtnReceive.Glyph:= FBmpL;
      b_dl.Align:= alRight;
      b_dr.Align:= alRight;
      Panel_0.Padding.Right:= 13; Panel_0.Padding.Left:= 0;

 end else
 begin
    panel_.Hide;
    panel. Align:= alLeft;
    splitter1.align:= alRight; splitter1.align:= alLeft;
    panel_.Align:= alClient;
    panel_.show;
    b_pp.Parent:= panel_;
    b_pp.show;
    b_pp.Left:= panel.width-b_pp.width-10;
    sbtnSend.Align:= alLeft;
    sbtnSend.Layout:= blGlyphLeft;
    sbtnSend.Glyph:= FBmpL;
    b_dl2.Align:= alRight;
    b_dr_.Align:= alRight;
    Panel_1.Padding.Right:= 13; Panel_1.Padding.Left:= 0;
    sbtnReceive.Align:= alRight;
    sbtnReceive.Layout:= blGlyphRight;
    sbtnReceive.Glyph:= FBmpR;
    b_dr.Align:= alLeft;
    b_dl.Align:= alLeft;
    Panel_0.Padding.Right:= 0; Panel_0.Padding.Left:= 13;
 end;
 FormResize(nil);
 finally
   lockwindowupdate(0);
 end;
end;
procedure TrdFileTransfer.FormResize(Sender: TObject);
begin
  if panel. Align=alLeft then
    panel. width:= clientwidth div 2 else
    panel_.width:= clientwidth div 2;
    comp_border(edRemoteDir,1);
    comp_border(edLocalDir,1);
   SendMessage(FilesRemote.Handle, WM_SETREDRAW, 0, 0);
   SendMessage(FilesLocal.Handle, WM_SETREDRAW, 0, 0);
   try
     AutoFitColumns(FilesRemote);
     AutoFitColumns(FilesLocal);
   finally
     SendMessage(FilesLocal.Handle, WM_SETREDRAW, 1, 0);
     SendMessage(FilesRemote.Handle, WM_SETREDRAW, 1, 0);
   end;
end;
procedure TrdFileTransfer.FilesReload(Sender: TObject; Files: TRtcPFileExplorer);
var
  Index, Cnt: Integer;
  info: TListViewInfo;
begin
  info := SaveScroolListView(Files);
//  if Files.ItemFocused <> nil then
//    begin
//      Index := Files.ItemFocused.Index;
//      Cnt   := Files.Items.Count;
//    end else
//  Cnt := -1;
  if Files.Local = false then
    myUI.GetFileList(edRemoteDir.Text, ExtractFileName(edRemoteDir.Text))
  else
    begin
      if not Assigned(Sender)  then
        Files.onPath(edLocalDir.Text, ExtractFileName(edLocalDir.Text)) else
      if (Files.Directory <> '') then
        Files.onPath(Files.Directory) else
        b_hm_Click(nil);
    end;
//  if Files.Items.Count <> Cnt then
//    Index := 0;
//
//
//    if Files.Items.Count > 0 then
//      Files.ItemIndex := Index;
  RestoreScroolListView(Files, info);
    Files.SetFocus;
    SetCaption;
end;
procedure TrdFileTransfer.FilesRemoteClick(Sender: TObject);
begin
 info2pn(FilesRemote);
end;
procedure TrdFileTransfer.FilesLocalClick(Sender: TObject);
begin
  info2pn(FilesLocal);
end;
procedure TrdFileTransfer.FilesRemoteKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  VK_UPDOWN:= False;
  if key in [VK_UP,VK_DOWN,VK_END,VK_HOME,VK_PRIOR,VK_NEXT] then
    FilesRemoteClick(Sender)
end;
procedure TrdFileTransfer.FilesLocalKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  VK_UPDOWN:= False;
  if key in [VK_UP,VK_DOWN,VK_END,VK_HOME,VK_PRIOR,VK_NEXT] then
    FilesLocalClick(Sender)
end;
procedure TrdFileTransfer.Label4Click(Sender: TObject);
begin
  Label4.Tag:=1;
  if assigned(myUI) then
    myUI.GetFileList(edLocalDir.Text, '');
end;
procedure TrdFileTransfer.mnNewFolderClick(Sender: TObject);
label 1;
var s: string; p: integer;
begin
  if assigned(myUI) and (FilesRemote.Directory<>'') then
  begin
        s:= 'Новая папка'; p:=1;
        if FilesRemote.FindCaption(0,s,False,False,False)<>nil then
        begin
           while FilesRemote.FindCaption(0,s+' '+inttostr(p),False,False,False)<>nil do inc(p);
           s:= 'Новая папка '+p.tostring;
        end;
  1:
  if inputquery('Новый каталог', 'Введите имя папки', s) then
  begin
     if s='' then EXIT;
     if wrong_caption(s)>-1 then goto 1;
     myUI.Cmd_NewFolder(IncludeTrailingBackslash(FilesRemote.Directory)+s);
     KEY_BACK:= True;
     foc_:= s;
     myUI.GetFileList(FilesRemote.Directory,'');
  end;
end;
end;
procedure TrdFileTransfer.b_dr_Click(Sender: TObject);
label 1;
var s: string; p: integer;
  l: TListItem;
begin
  if FilesLocal.Directory<>'' then
  begin
        s:= 'Новая папка'; p:=1;
        if FilesLocal.FindCaption(0,s,False,False,False)<>nil then
        begin
           while FilesLocal.FindCaption(0,s+' '+inttostr(p),False,False,False)<>nil do inc(p);
           s:= 'Новая папка '+p.tostring;
        end;
  1:
  if inputquery('Новый каталог', 'Введите имя папки', s) then
  begin
     if s='' then EXIT;
     if wrong_caption(s)>-1 then goto 1;
     if CreateDir(IncludeTrailingBackslash(FilesLocal.Directory)+s) then
     begin
       FilesLocal.onPath(FilesLocal.Directory);
       l:= FilesLocal.FindCaption(0,s,False,False,False);
       if l<>nil then
       begin
           FilesLocal.Selected:=    l;
           FilesLocal.ItemFocused:= l;
           l.MakeVisible(False);
       end;
     end;
  end;
end;
end;
procedure TrdFileTransfer.b_hm_Click(Sender: TObject);
begin
  edLocalDir.Text:= '';
  FilesLocal.Local:= False;
  FilesLocal.Local:= True;
end;
procedure TrdFileTransfer.btnLocalReloadClick(Sender: TObject);
begin
  FilesReload(Sender, FilesLocal);
end;
procedure TrdFileTransfer.FilesRemoteDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
    Accept:= (sbtnSend.Enabled) and (FilesRemote.Directory<>'') and (source = FilesLocal);
end;
procedure TrdFileTransfer.FilesLocalDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
    Accept:= (sbtnReceive.Enabled) and (FilesLocal.Directory<>'') and (source = FilesRemote);
end;
procedure TrdFileTransfer.FilesLocalDragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
  if sbtnReceive.Enabled then sbtnReceive.click;
end;
procedure TrdFileTransfer.FilesRemoteDragDrop(Sender, Source: TObject; X, Y: Integer);
  var
    myFiles:TStringList;
    newDir:String;
    a:integer;
  begin
  if sbtnSend.Enabled then sbtnSend.click; EXIT;
  if assigned(myUI) then
    begin
    newDir:=FilesRemote.GetFileName(FilesRemote.GetItemAt(X,Y));
    if newDir<>'' then
      begin
      if newDir='..' then
        newDir:=IncludeTrailingBackslash(FilesRemote.Directory)+'..\'
      else
        newDir:=IncludeTrailingBackslash(newDir);
      myFiles:=FilesRemote.SelectedFiles;
      if myFiles.Count>0 then
        begin
        for a:=0 to myFiles.Count-1 do
          myUI.Cmd_FileMove(myFiles.Strings[a],newDir+ExtractFileName(myFiles.Strings[a]));
        myUI.GetFileList(FilesRemote.Directory,'');
        end;
      end;
    end;
  end;
procedure TrdFileTransfer.add_lg(s: string);
begin
  if lg.lines[lg.lines.count-1]<>s then
     lg.lines.add(s);
end;
procedure TrdFileTransfer.Splitter1Moved(Sender: TObject);
begin
 comp_border(edRemoteDir,1); comp_border(edLocalDir,1);
end;
function TrdFileTransfer.get_TF(ss: TStrings): string;
var s: string; mx,i: integer;
begin
  if ss.Count>30 then mx:= 30 else mx:= ss.Count;
  s:= #13#10;
  for i:=0 to mx-1 do
  begin
        s:=s+#13#10+ss[i];
  end;
        if ss.Count>mx then
        s:=s+#13#10'[..]';
  result:= s;
end;
procedure TrdFileTransfer.b_dlClick(Sender: TObject);
var s: string;
begin
  s:= get_TF(FilesRemote.SelectedFiles_('Каталог:  ','Файл:     '));
  if TaskMessageDlg(
    'Удаление',
    'Подтвердите удаление для выбранного ('+FilesRemote.SelectedFiles.Count.ToString+'):'+s,
    mtInformation, [mbCancel, mbOK], 0, mbOK) <> mrOK then exit;
     mnDeleteClick(nil);
end;
procedure TrdFileTransfer.b_dl2Click(Sender: TObject);
var myFiles:TStringList;
    a: Integer;
    s: string;
begin
  s:= get_TF(FilesLocal.SelectedFiles_('Каталог:  ','Файл:     '));
  if TaskMessageDlg(
    'Удаление',
    'Подтвердите удаление для выбранного ('+FilesLocal.SelectedFiles.Count.ToString+'):'+s,
    mtInformation, [mbCancel, mbOK], 0, mbOK) <> mrOK then exit;

    myFiles:= FilesLocal.SelectedFiles;
    if myFiles.Count>0 then
      for a:=myFiles.Count-1 downto 0 do
      begin
        if DirectoryExists(myFiles[a]) then TDirectory.Delete(myFiles[a], True) else
        if FileExists(myFiles[a]) then TFile.Delete(myFiles[a]);
      end;
      FilesLocal.onPath(FilesLocal.Directory);
end;
procedure TrdFileTransfer.sbtnSendBatchClick(Sender: TObject);
var
  SelectedFiles, FileList: TStringList;
  i: Integer;
  y_all, n_all:boolean;
  g: TGauge;
  temp_id: TTaskID;
begin
  i := GetTickCount;
  if i - FDelayClickSendFetch < DELAY_CLICK_SEND_FETCH  then exit;
  FDelayClickSendFetch := i;
  SelectedFiles := FilesLocal.SelectedFiles;
  if SelectedFiles.Count = 0 then exit;
  FileList := TStringList.Create;
  try
    Y_all:= False; N_all:= False;
    I := 0;
    for I := 0 to SelectedFiles.Count-1 do
      begin
        case file_exists(True, Y_all, N_all, SelectedFiles[i],
          FilesRemote.Directory + ExtractFileName(SelectedFiles[i])) of
          mrNone, mrYes:
            FileList.Add(SelectedFiles[i]);
          mrYesToAll:
            begin
              FileList.Add(SelectedFiles[i]);
              Y_all := true;
            end;
          mrNoToAll:
            N_all := true;
          mrNo,
          mrIgnore: ;
          mrCancel, mrClose:
            exit;
        end;
      end;

    if FileList.Count > 0 then
      begin
        TRtcPFileTransfer(myUI.Module).NotifyFileBatchSend := OnSendBatch;
        try
          temp_id := TRtcPFileTransfer(myUI.Module).SendBatch(myUI.UserName,
                              FileList, FilesLocal.Directory, FilesRemote.Directory, nil);
        except
          on E: Exception do
            begin
              add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
              PageControlTasks.ActivePage := tbFileLog;
              raise;
            end;
        end;
        g := add_pn(ExtractFileName(FilesRemote.Directory), True);
        i := add_rc(True, FilesRemote.Directory, SelectedFiles, g);
        rr[i].taskID      := temp_id;
        rr[i].direction   := sbtSending;
        lblNoTask.Visible := false;
      end
    else
      PageControlTasks.ActivePage := tbFileLog;
  finally
    FileList.Free;
  end;
end;
procedure TrdFileTransfer.sbtnSendClick(Sender: TObject);
label 0;
  var
    send_f,myFiles:TStringList;
    f,i,p,a:integer; s: string; y_all,n_all:boolean;
    g:TGauge;
  begin
    sbtnSendBatchClick(Sender);
    exit;
    if assigned(myUI) then
    begin
      g:= add_pn(extractfilename(FilesRemote.Directory), True);
      myFiles:= FilesLocal.SelectedFiles;
      i:= add_rc(True, FilesRemote.Directory, myFiles, g);
      if not stopped then begin sb.SimpleText:= sb.SimpleText+'*'; EXIT; end;
      lblNoTask.Hide;
      curr_g:= g;
      cur_files.Assign(myFiles); send_stop:= False; Y_all:= False; N_all:= False;
      send_f:= TStringList.create;
      if myFiles.Count>0 then
        for a:=0 to myFiles.Count-1 do
        begin
        0:
          s:= myFiles.Strings[a];
          case file_exists(True,Y_all,N_all, s, FilesRemote.Directory+extractfilename(s)) of
          mrNone,mrYes:
          begin
            send_f.add(s);
          end;
          mrYesToAll:
          begin
            Y_all:= True;
            goto 0;
          end;
          mrNoToAll:
          begin
            N_all:= True;
            goto 0;
          end;
          mrNo: continue;
          mrIgnore:
          begin
            continue;
          end;
          mrCancel,mrClose:
          begin
            break;
          end;
          end;
        end;

        for i:=0 to send_f.count-1 do
        begin
         myUI.Send (send_f[i], FilesRemote.Directory);
        end;
        if send_f.count=0 then
        begin
          rec_finished(TPanel(g.Parent), True);
          TPanel(g.Parent).Free;
        end;
        send_f.Free;
      end;
end;
procedure TrdFileTransfer.sbtnFetchBatchClick(Sender: TObject);
var
  SelectedFiles, FileList: TStringList;
  i: Integer;
  y_all, n_all:boolean;
  g: TGauge;
  temp_id: TTaskID;
begin
  i := GetTickCount;
  if i - FDelayClickSendFetch < DELAY_CLICK_SEND_FETCH  then exit;
  FDelayClickSendFetch := i;
  SelectedFiles := FilesRemote.SelectedFiles;
  if SelectedFiles.Count = 0 then exit;
  FileList := TStringList.Create;
  try
    Y_all:= False; N_all:= False;
    I := 0;
    for I := 0 to SelectedFiles.Count-1 do
      begin
        case file_exists(True, Y_all, N_all, SelectedFiles[i],
          FilesLocal.Directory + ExtractFileName(SelectedFiles[i])) of
          mrNone, mrYes:
            FileList.Add(SelectedFiles[i]);
          mrYesToAll:
            begin
              FileList.Add(SelectedFiles[i]);
              Y_all := true;
            end;
          mrNoToAll:
            N_all := true;
          mrNo,
          mrIgnore: ;
          mrCancel, mrClose:
            exit;
        end;
      end;


    if FileList.Count > 0 then
      begin
//        TRtcPFileTransfer(myUI.Module).NotifyFileBatchSend := OnSendBatch;
        try
          temp_id := TRtcPFileTransfer(myUI.Module).FetchBatch(myUI.UserName,
                              FileList, FilesRemote.Directory, FilesLocal.Directory, nil);
        except
          on E: Exception do
            begin
              add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
              PageControlTasks.ActivePage := tbFileLog;
              raise;
            end;
        end;
        g := add_pn(ExtractFileName(FilesLocal.Directory), True);
        i := add_rc(True, FilesLocal.Directory, SelectedFiles, g);
        rr[i].direction   := sbtReceiving;
        rr[i].taskID      := temp_id;
        lblNoTask.Visible := false;
      end
    else
      PageControlTasks.ActivePage := tbFileLog;
  finally
    FileList.Free;
  end;
end;
procedure TrdFileTransfer.sbtnReceiveClick(Sender: TObject);
label 0;
  var
    send_f,myFiles:TStringList;
    f,i,p,a:integer; s: string; y_all,n_all:boolean;
    g:TGauge;
  begin
    sbtnFetchBatchClick(Sender);
    exit;
    if assigned(myUI) then
    begin
      g:= add_pn(extractfilename(FilesLocal.Directory), False);
      myFiles:= FilesRemote.SelectedFiles;
      i:= add_rc(False, FilesLocal.Directory, myFiles, g);
      if not stopped then begin sb.SimpleText:= sb.SimpleText+'*'; EXIT; end;
      lblNoTask.Hide;
      curr_g:= g;
      cur_files.Assign(myFiles); resv_stop:= False; Y_all:= False; N_all:= False;
      send_f:= TStringList.create;
      if myFiles.Count>0 then
        for a:=0 to myFiles.Count-1 do
        begin
          0:
          s:= myFiles.Strings[a];
          case file_exists(False,Y_all,N_all, s, FilesLocal.Directory+extractfilename(s)) of
          mrNone,mrYes:
          begin
             send_f.add(s);
          end;
          mrYesToAll:
          begin
            Y_all:= True;
            goto 0;
          end;
          mrNoToAll:
          begin
            N_all:= True;
            goto 0;
          end;
          mrNo: continue;
          mrIgnore:
          begin
            continue;
          end;
          mrCancel,mrClose:
          begin
            break;
          end;
          end;
        end;
        for i:=0 to send_f.count-1 do
        begin
         myUI.Fetch(send_f[i], FilesLocal.Directory);
        end;
        if send_f.count=0 then
        begin
          rec_finished(TPanel(g.Parent), True);
          TPanel(g.Parent).Free;
        end;
        send_f.Free;
      end;
  end;
procedure TrdFileTransfer.Label7Click(Sender: TObject);
var i: integer; g:TGauge;
begin
 lockwindowupdate(Handle);
 try
 for i:=0 to high(rr) do
 with rr[i] do
 if not deleted then
 try
   g:= TGauge(longint(pn.HelpContext));
   if g.ForeColor = $00FFD9FF then
   begin
     sel_files.clear;
     deleted:= True; finished:= True;
     pn.Free;
   end;
 except
 end;
 check_task;
 finally
   lockwindowupdate(0);
 end;
end;

{ **************************************************************************** }
{                               TRecentPathList                                }
{ **************************************************************************** }
function TRecentPathList.Pop: string;
begin
  Pop(Result);
end;
function TRecentPathList.Pop(out s: string): Boolean;
begin
  if FDoubleRet then
    Delete(Count-1);
  FDoubleRet := false;
  Result := Count > 0;
  s := '';
  if Result then
    begin
      s := Strings[Count-1];
      Delete(Count-1);
    end
end;
procedure TRecentPathList.Push(const s: string);
begin
  Add(s);
  FDoubleRet := true;
end;

end.
