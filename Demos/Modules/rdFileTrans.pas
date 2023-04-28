unit rdFileTrans;

interface

{$include rtcDefs.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls,
  Buttons, ComCtrls, ExtCtrls, Clipbrd, IOUtils, rtcPortalMod, rtcpFileTrans,
  rtcpFileTransUI, System.ImageList, Vcl.ImgList, Vcl.Menus, Vcl.Samples.Gauges,
  rtcpFileExplore, rtcSystem, Character,

{$IFDEF IDE_XE3up}
  UITypes,
{$ENDIF}

  ShellAPI, AppEvnts,
  uVircessTypes, CommonUtils, rtcScrUtils, CommonData;

const
  WM_SAFE_DELETE_OBJECT  = WM_USER + 1;
  DELAY_CLICK_SEND_FETCH = 500;

type

  TListViewInfo = record
    cnt: Integer;
    index: Integer;
    vert_scroll_pos: Integer;
  end;

  TTaskRemoveLogic = (trlImmediately, trlDemandError, trlManual);

  TTaskPanelList = class;
  TTaskPanelInfo = class
  private
  public
    Finished  : boolean;
    panel     : TPanel;
    gauge     : TGauge;
    lblFile   : TLabel;
    lblSize   : TLabel;
    sbtnClose : TSpeedButton;
    list      : TTaskPanelList;
    files     : TStrings;
    to_path   : string;


    taskID    : TTaskID;

    destructor Destroy; override;
    procedure ForgetWinControl;
  end;



  TTaskPanelList = class (TStringList)
  private
    FTaskRemoveLogic: TTaskRemoveLogic;
  public
    constructor Create(); reintroduce; overload;
    function FindTaskInfo(const TaskID: TTaskID; out Info: TTaskPanelInfo): Boolean;
    function GetTaskInfo(const TaskID: TTaskID): TTaskPanelInfo;
    function AddTask(const TaskID: TTaskID): TTaskPanelInfo;
    procedure RemoveTask(const TaskID: TTaskID);
    procedure ForgetTask(const TaskID: TTaskID);
    function ActiveTaskCount: Integer;
    property TaskRemoveLogic: TTaskRemoveLogic read FTaskRemoveLogic write FTaskRemoveLogic;
  end;


  TRecentPathList = class (TStringList)
  private
    FDoubleRet: Boolean;
    FStep: Integer;
  public
    constructor Create(); reintroduce; overload;
    procedure Push(const s: String);
    function Pop(): string; overload; inline;
    function Pop(out s: string): Boolean; overload;
    function Available: Boolean;
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
    pnlInfoRemote: TPanel;
    eParams: TEdit;
    P1: TMenuItem;
    ImageList1: TImageList;
    Panel_: TPanel;
    FilesLocal: TRtcPFileExplorer;
    Panel7: TPanel;
    pnlInfoLocal: TPanel;
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
    sbxProgressPanel: TScrollBox;
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
    lblCloseAllTask: TLabel;
    al_b: TLabel;
    myUI: TRtcPFileTransferUI;
    btnRemoteBack: TSpeedButton;
    btnLocalBack: TSpeedButton;
    tAutoFitColumns: TTimer;
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
    procedure FilesRemoteKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tiClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SpeedButton10Click(Sender: TObject);
    procedure btnLocalReloadClick(Sender: TObject);
    procedure FilesLocalDirectoryChange(Sender: TObject;
      const FileName: string);
    procedure Label6MouseEnter(Sender: TObject);
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
    procedure lblCloseAllTaskClick(Sender: TObject);
    procedure myUIClose(Sender: TRtcPFileTransferUI);
    procedure myUIError(Sender: TRtcPFileTransferUI);
    procedure myUIInit(Sender: TRtcPFileTransferUI);
    procedure myUILogOut(Sender: TRtcPFileTransferUI);
    procedure myUIOpen(Sender: TRtcPFileTransferUI);
    procedure myUIFileList(Sender: TRtcPFileTransferUI);
    procedure sbtnRemoteLevelUpClick(Sender: TObject);
    procedure FilesLocalFileOpen(Sender: TObject; const FileName: string);
    procedure FilesEdited(Sender: TObject; Item: TListItem;
      var S: string);
    procedure btnRemoteBackClick(Sender: TObject);
    procedure tAutoFitColumnsTimer(Sender: TObject);
  private
    FReady: Boolean;
    FOnUIOpen: TUIOpenEvent;
    FOnUIClose: TUICloseEvent;
    FBmpL, FBmpR: TBitmap;
    FTotalBytesTransfer, FCurrentBytesTransfer: Int64;
    FDelayClickSendFetch: Integer;

    FBeforeClose: TNotifyEvent;
    FRemoteRecent, FLocalRecent: TRecentPathList;
    FTaskPanelList: TTaskPanelList;
    FDirFilesInited: Boolean;
    FRepositionFolder: string;

    function wrong_caption(s: string): Integer;
    function info2pn(lv: TRtcPFileExplorer): Int64;
    procedure add_lg(s: string);
    function str_size(sz: int64;   gb:boolean=true; mb:boolean=true;
                                   kb:boolean=true; round_:boolean=false; dig:byte=1): string;
    function file_exists(sd,ya,na: boolean; src,dst: string): integer;
    procedure comp_border(cp: twincontrol; pix: byte);
    function get_TF(ss: TStrings): string;

    procedure Form_Open(const mode:string);
    procedure Form_Close(const mode:string);
    procedure SetCaption;


  protected

    procedure AcceptFiles(var msg : TMessage); message WM_DROPFILES;
    procedure CreateParams(var params: TCreateParams); override;
    procedure ChangeLockedState(var Message: TMessage); message WM_CHANGE_LOCKED_STATUS;

    // new methods
  private
    procedure WmSafeDeleteObject(var Message: TMessage); message WM_SAFE_DELETE_OBJECT;
    procedure SafeDeleteObject(const [ref] Obj: TObject);
    procedure RenameFileExplorer(Files: TRtcPFileExplorer; Item: TListItem; const NewName: string);
    procedure DefTaskPanel(var taskPanel: TTaskPanelInfo; const title: string;
      Direction: TDirectionBatchTask);
    function SaveScroolListView(lv: TRtcPFileExplorer): TListViewInfo;
    procedure RestoreScroolListView(lv: TRtcPFileExplorer; const info: TListViewInfo);
    procedure BuildListDrivs();
    procedure OnTaskPanelChange(Sender: TObject);
    procedure OnRecentChange(Sender: TObject);

    // new methods
  published
    procedure sbtnSendBatchClick(Sender: TObject);
    procedure sbtnFetchBatchClick(Sender: TObject);
    procedure CancelBatchClick(Sender: TObject);
    procedure OnSendBatch(Sender: TObject; const task: TBatchTask; mode: TModeBatchSend) ;
    procedure FilesReload(Sender: TObject;  Files: TRtcPFileExplorer);



  public
    UIVisible: Boolean;
    PartnerLockedState: Integer;
    PartnerServiceStarted: Boolean;

    procedure SetFormState;

    property UI:TRtcPFileTransferUI read myUI;
    property OnUIOpen: TUIOpenEvent read FOnUIOpen write FOnUIOpen;
    property OnUIClose: TUICloseEvent read FOnUIClose write FOnUIClose;
    property BeforeClose:TNotifyEvent read FBeforeClose write FBeforeClose;
  end;


implementation
uses
  Winapi.ShlObj, ComObj, rtcInfo, rtcpFileUtils, System.Math;


{$R *.dfm}

procedure TrdFileTransfer.CancelBatchClick(Sender: TObject);
var
  taskPanel: TTaskPanelInfo;
  task: TBatchTask;
  reload: TSpeedButton;
begin
  if not (Sender is TSpeedButton) then
    raise Exception.Create('Incorrect class type');
  taskPanel :=  TTaskPanelInfo(TSpeedButton(Sender).Tag);
  if taskPanel.Finished then
    begin
      SafeDeleteObject(taskPanel.panel);
      FTaskPanelList.RemoveTask(taskPanel.taskID);
      exit;
    end;

  taskPanel.Finished := true;
  task := TRtcPFileTransfer(myUI.Module).TaskList.GetTaskByName(taskPanel.taskID.ToString);
  task._AddRef;
  try
    if task.Direction = dbtFetch then
      reload := btnLocalReload
    else
      reload := btnRemoteReload;

    TRtcPFileTransfer(myUI.Module).CancelBatch(Sender, task.Id);
    FTotalBytesTransfer := FTotalBytesTransfer - task.Size;
    FCurrentBytesTransfer := FCurrentBytesTransfer - task.SentSize;
  finally
    task._Relase
  end;
  SafeDeleteObject(taskPanel.panel);
  FTaskPanelList.RemoveTask(taskPanel.taskID);
  reload.Click;
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

  FilesRemote.StyleElements := [];
  FilesLocal.StyleElements  := [];
  Splitter1.StyleElements   := [];
  FilesRemote.GridLines     := True;
  FilesLocal.GridLines      := True;

  Application.HintHidePause := 10000;

  FBmpL := TBitmap.Create;
  FBmpR := TBitmap.Create;
  FBmpL.Assign(sbtnSend.Glyph);
  FBmpR.Assign(sbtnReceive.Glyph);
  FRemoteRecent                  := TRecentPathList.Create;
  FLocalRecent                   := TRecentPathList.Create;
  FLocalRecent.OnChange          := OnRecentChange;
  FRemoteRecent.OnChange         := OnRecentChange;
  FTaskPanelList                 := TTaskPanelList.Create;
  FTaskPanelList.OnChange        := OnTaskPanelChange;
  FTaskPanelList.TaskRemoveLogic := trlManual;

  b_ppClick(nil);

  DragAcceptFiles(Handle, True);
end;

procedure TrdFileTransfer.Image1Click(Sender: TObject);
begin
//  with mouse.CursorPos do
//    pop.Popup(x, y);
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
  info: TListViewInfo;
begin


   info := SaveScroolListView(FilesRemote);

   b_dl.Enabled:= False;
   sbtnReceive.Enabled:= False;

   edRemoteDir.Text:=Sender.FolderName;
   FilesRemote.UpdateFileList(Sender.FolderName,Sender.FolderData);

   FilesRemote.ClearSelection;

   tempItem := nil;
   if FRepositionFolder <> '' then
    tempItem := FilesRemote.FindCaption(0, FRepositionFolder, False, False, False);
   if tempItem <> nil then
     FilesRemote.ItemIndex := tempItem.Index   else
     RestoreScroolListView(FilesRemote, Info);


   if FilesRemote.ItemFocused <> nil then
    FilesRemote.ItemFocused.MakeVisible(False);

   FRepositionFolder := '';
   FilesRemoteClick(nil);

  if not FDirFilesInited then
    begin
      BuildListDrivs;
      FDirFilesInited := true;
    end;
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
  FilesLocalClick(nil);
end;

procedure TrdFileTransfer.FilesRemoteDirectoryChange(Sender: TObject; const FileName: String);
begin
  FRemoteRecent.Push(FileName);
  if assigned(myUI) then
    myUI.GetFileList(FileName,'');

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

procedure TrdFileTransfer.BuildListDrivs;
var
  i: Integer;
  data: TRtcDataSet;
begin
  //edRemoteDir.ItemsEx.BeginUpdate;

  edRemoteDir.Images := TListView(FilesRemote).SmallImages;
  for i := 0 to FilesRemote.Items.Count-1 do
    begin
      edRemoteDir.ItemsEx.AddItem(
        FilesRemote.Items[i].Caption,
        FilesRemote.Items[i].ImageIndex, -1, -1, 0, nil);
    end;

  if FilesLocal.Items.Count = 0 then
    begin
      //FilesLocal.onPath('', '');
      data := TRtcDataSet.Create;
      try
        GetFilesList('', '*.*', data);
        FilesLocal.UpdateFileList('', data);
      finally
        data.Free;
      end;
    end;

  edLocalDir.Images := TListView(FilesLocal).SmallImages;
  for i := 0 to FilesLocal.Items.Count-1 do
    begin
      edLocalDir.ItemsEx.AddItem(
        FilesLocal.Items[i].Caption,
        FilesLocal.Items[i].ImageIndex, -1, -1, 0, nil);
    end;


end;

procedure TrdFileTransfer.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if assigned(FBeforeClose) then
    FBeforeClose(Self);
  if FTaskPanelList.ActiveTaskCount > 0 then
    raise Exception.Create('You have active tasks');
  CanClose := true;
end;

procedure TrdFileTransfer.FormDestroy(Sender: TObject);
begin
  DragAcceptFiles(Handle, False);
  FBmpR.Free;
  FBmpL.Free;
  FRemoteRecent.Free;
  FLocalRecent.Free;
  FTaskPanelList.Free;
end;

procedure TrdFileTransfer.DownLabelDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
  begin
  Accept:=(Source=FilesRemote) and (FilesRemote.Directory<>'');
  end;

procedure TrdFileTransfer.DefTaskPanel(var taskPanel: TTaskPanelInfo;
  const title: string; Direction: TDirectionBatchTask);
const
  FORE_COLOR: array [TDirectionBatchTask] of TColor = ($00BFFFBF, $00FFE2C6);
var
  img: TImage;
begin
  taskPanel.panel := TPanel.create(sbxProgressPanel);
  taskPanel.panel.Parent           := sbxProgressPanel;
  taskPanel.panel.StyleElements    := [];
  taskPanel.panel.Color            := clWhite;
  taskPanel.panel.ShowCaption      := False;
  taskPanel.panel.Width            := 185;
  taskPanel.panel.Align            := alRight;
  taskPanel.panel.Align            := alLeft;
  taskPanel.panel.Margins.SetBounds(4, 4, 4, 4);
  taskPanel.panel.AlignWithMargins := True;
  taskPanel.panel.BevelKind        := bkFlat;
  taskPanel.panel.BevelOuter       := bvNone;
  taskPanel.panel.ParentBackground := False;

  taskPanel.gauge := TGauge.Create(taskPanel.panel);
  taskPanel.gauge.Parent           := taskPanel.panel;
  taskPanel.gauge.Align            := alClient;
  taskPanel.gauge.Margins.SetBounds(1, 1, 1, 1);
  taskPanel.gauge.AlignWithMargins := False;
  taskPanel.gauge.BorderStyle      := bsNone;
  taskPanel.gauge.MaxValue         := 10000;
  taskPanel.gauge.ForeColor        := FORE_COLOR[Direction];

  taskPanel.lblFile              := TLabel.Create(taskPanel.panel);
  taskPanel.lblFile.Parent       := taskPanel.panel;
  taskPanel.lblFile.AutoSize     := False;
  taskPanel.lblFile.ShowHint     := True;
  taskPanel.lblFile.OnMouseEnter := Label6MouseEnter;
  taskPanel.lblFile.SetBounds(7, 7, 147, 13);
  taskPanel.lblFile.Caption      := title;
  taskPanel.lblFile.Tag          := NativeInt(taskPanel);

  taskPanel.lblSize := TLabel.Create(taskPanel.panel);
  taskPanel.lblSize.Parent       := taskPanel.panel;
  taskPanel.lblSize.Caption      := '..';
  taskPanel.lblSize.AutoSize     := False;
  taskPanel.lblSize.Align        := alCustom;
  taskPanel.lblSize.Alignment    := taLeftJustify;
  taskPanel.lblSize.SetBounds(7, taskPanel.panel.ClientHeight - 20, 147, 13);
  taskPanel.lblSize.ShowHint     := True;
  taskPanel.lblSize.OnMouseEnter := Label6MouseEnter;
  taskPanel.lblSize.Tag          := NativeInt(taskPanel);

  taskPanel.sbtnClose := TSpeedButton.Create(taskPanel.panel);
  taskPanel.sbtnClose.Parent     := taskPanel.panel;
  taskPanel.sbtnClose.Caption    := 'r';
  taskPanel.sbtnClose.Flat       := True;
  taskPanel.sbtnClose.Font.Color := clGray;
  taskPanel.sbtnClose.Font.Name  := 'Marlett';
  taskPanel.sbtnClose.Font.Size  := 12;
  taskPanel.sbtnClose.SetBounds(157, 3, 22, 19);
  taskPanel.sbtnClose.OnClick    := SpeedButton10Click;
  // set the Pointer to taskPanel, will search in this method "OnClick" (cancel task)
  taskPanel.sbtnClose.Tag        := NativeInt(taskPanel);


  img := TImage.Create(taskPanel.panel);
  img.Parent      := taskPanel.panel;
  img.AutoSize    := True;
  img.Transparent := True;
  img.SetBounds(7, 24, 24, 24);
  img.Picture     := logo.Picture;

  sendmessage(sbxProgressPanel.Handle, WM_HSCROLL, SB_RIGHT, 0);

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

      if MessageDlg(s,mtWarning,[mbYes,mbNo],0)=mrYes then
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

procedure Delay(dwMilliseconds: Longint);
 var
   iStart, iStop: DWORD;
begin
   iStart := GetTickCount;
   repeat
     iStop := GetTickCount;
     Application.ProcessMessages;
   until Integer(iStop - iStart) >= dwMilliseconds;
end;

procedure TrdFileTransfer.tAutoFitColumnsTimer(Sender: TObject);
begin
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
var
  list: TStringList;
  taskPanel: TTaskPanelInfo;
  I: Integer;
begin
  taskPanel := TTaskPanelInfo(TLabel(sender).Tag);
  if not Assigned(taskPanel) then exit;

  list := TStringList.Create;
  try
    list.Add('Получатель: ' + taskPanel.to_path);
    list.Add('Итого: '+ taskPanel.files.Count.ToString);
    list.Add('');

    for i := 0 to Min(10, taskPanel.files.Count)-1 do
      list.Add(ExtractFileName(taskPanel.files[i]));

    if 10 < taskPanel.files.Count then
      list.Add('...');

    Hint:= list.Text;
  finally
    list.Free;
  end;

end;

procedure TrdFileTransfer.sbtnRemoteLevelUpClick(Sender: TObject);
begin
  FilesRemote.OneLevelUp;
end;

procedure TrdFileTransfer.sbtnLocalLevelUpClick(Sender: TObject);
begin
  FilesLocal.OneLevelUp;
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


procedure TrdFileTransfer.RestoreScroolListView(lv: TRtcPFileExplorer;
  const info: TListViewInfo);
var
  R: TRect;
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
begin
  CancelBatchClick(Sender);
end;

procedure TrdFileTransfer.FilesRemoteEnter(Sender: TObject);
begin
  Panel11.Color := $00FFF9F2;
  Panel12.Color := clwhite;

  pnlInfoRemote.Color := Panel11.Color;
  Panel5.Color := Panel11.Color;

  pnlInfoLocal.Color := Panel12.Color;
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

  pnlInfoLocal.Color := Panel12.Color;
  Panel7.Color := Panel12.Color;

  pnlInfoRemote.Color := Panel11.Color;
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
      (status and HRESULT($80070000) = HRESULT($80070000)) and  // The sytem code
      (status and HRESULT($0000FFFF) = $4C7) then   // 1223 операция отменена пользователем
        begin
          exit;
        end;
  raise EOleSysError.Create('', status, 0);

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

procedure TrdFileTransfer.OnRecentChange(Sender: TObject);
begin
  if Sender = FRemoteRecent then
    btnRemoteBack.Enabled := TRecentPathList(Sender).Available
  else
    btnLocalBack.Enabled := TRecentPathList(Sender).Available;
end;

procedure TrdFileTransfer.OnSendBatch(Sender: TObject; const task: TBatchTask;
  mode: TModeBatchSend);
var
  reload: TSpeedButton;
  taskPanel: TTaskPanelInfo;
begin
  if not FTaskPanelList.FindTaskInfo(task.Id, taskPanel) then exit;


    if task.direction = dbtFetch then
      reload := btnLocalReload else
      reload := btnRemoteReload;


  case mode of

    mbsFileStart:
      begin
        taskPanel.lblFile.Caption := ExtractFileName(task.Files[task.Current].file_path);
        taskPanel.lblSize.Caption := IntToStr(task.Current+1) + '/' + task.FileCount.ToString;
      end;

    mbsFileData:
      begin
        taskPanel.gauge.Progress := Round(task.Progress * 10000);
        FCurrentBytesTransfer := FCurrentBytesTransfer + task.LastChunkSize;
        Caption:= 'Передано: ' + str_size(FCurrentBytesTransfer, False, False) + ' Итого: ' + str_size(FTotalBytesTransfer, False, False);
      end;

    mbsFileStop:
      begin
        taskPanel.lblSize.Caption:= Format('%.0n / %.0n KB', [task.SentSize / 1024, task.Size / 1024]);
        add_lg(TimeToStr(now) + ':  Выгрузка из "' + task.Files[task.Current].file_path + '" в "' + ExtractFileName(task.Files[task.Current].file_path) + '" (' + str_size(task.Files[task.Current].file_size) + ')');
        reload.Click;
      end;

    mbsTaskStart:
      begin
        FTotalBytesTransfer := FTotalBytesTransfer + task.Size;
      end;

    mbsTaskFinished:
      begin
        taskPanel.Finished        := true;
        taskPanel.gauge.Progress  := taskPanel.gauge.MaxValue;
        taskPanel.gauge.ForeColor := $00FFD9FF;
        reload.Click;
        if FTaskPanelList.TaskRemoveLogic <> trlManual then
          FTaskPanelList.RemoveTask(taskPanel.taskID);
      end;

    mbsTaskError:
      begin
        taskPanel.Finished := true;
        reload.Click;
        if FTaskPanelList.TaskRemoveLogic = trlImmediately then
          FTaskPanelList.RemoveTask(taskPanel.taskID);

        add_lg(TimeToStr(now) + ':  [ERROR] Выгрузка из "' + task.Files[task.Current].file_path + '" в "' + ExtractFileName(task.Files[task.Current].file_path) + '" (' + str_size(myUI.Send_FileSize) + ') - '+task.ErrorString );
        TaskMessageDlg('Error', task.ErrorString, mtError, [mbOK], 0, mbOK);

      end;
  end;

end;

procedure TrdFileTransfer.OnTaskPanelChange(Sender: TObject);
begin
  lblNoTask.Visible := TTaskPanelList(Sender).Count = 0;
end;

procedure TrdFileTransfer.comp_border(cp:twincontrol; pix:byte);
var
  formrgn : hrgn;
begin
  formrgn := CreateRectRgn(pix,pix, cp.width - pix, cp.height - pix);
  SetWindowRgn(cp.Handle, formrgn, True);
end;

procedure TrdFileTransfer.edRemoteDirKeyPress(Sender: TObject; var Key: Char);
var
  s: string;
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
var
  s: string;
begin
  s:= edRemoteDir.Items[edRemoteDir.Itemindex];
  delete(s,1,pos('(',s));

  edRemoteDir.Text:= copy(s,1,2)+'\';
  btnRemoteReloadClick(nil);
end;

procedure TrdFileTransfer.edLocalDirKeyPress(Sender: TObject; var Key: Char);
var
  s: string;
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
var
  s: string;
begin
  s := edLocalDir.Items[edLocalDir.Itemindex];
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
begin
 if FilesRemote.IsEditing then exit;

 if key = VK_F2 then
  begin
    if FilesRemote.ItemFocused <> nil then
      FilesRemote.ItemFocused.EditCaption;
    exit;
  end;

 if key = VK_F5 then
  begin
    if sbtnReceive.Enabled then
      sbtnFetchBatchClick(sbtnReceive);
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


 if key in [VK_RETURN] then
 try
  FilesRemote.PerformDoubleClick;
  FilesRemote.ItemFocused:= FilesRemote.Items[0];
  FilesRemote.Selected:=    FilesRemote.ItemFocused;
  except
  end;
end;

procedure TrdFileTransfer.FilesLocalKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if FilesLocal.IsEditing then exit;

 if key = VK_F2 then
  begin
    if FilesLocal.ItemFocused <> nil then
      FilesLocal.ItemFocused.EditCaption;
    exit;
  end;

 if key = VK_F5 then
  begin
    if sbtnSend.Enabled then
      sbtnSendBatchClick(sbtnSend);
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


 if key in [VK_RETURN] then
 try
  FilesLocal.PerformDoubleClick;
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
var l,v,p:integer; des:string;
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
    pnlInfoRemote.caption:= 'Выбрано '+p.tostring+' объектов '+s else
    pnlInfoLocal.caption:= 'Выбрано '+p.tostring+' объектов '+s
except

end;
end;

procedure TrdFileTransfer.FilesRemoteSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
label 0,1,2;
var lev0,root: Boolean; ind: integer;
begin
  root:= FilesRemote.Directory='';
  lev0 := false;
  ind  := 0;
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
  lev0 := false;
  ind := 0;

  if root then goto 2;

  lev0 := (FilesLocal.selcount=1) and (item.Caption='..');
  ind := FilesLocal.ItemIndex;

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
    panel. width:= clientwidth div 2
  else
    panel_.width:= clientwidth div 2;

  comp_border(edRemoteDir,1);
  comp_border(edLocalDir,1);

  tAutoFitColumns.Enabled := True;
end;

procedure TrdFileTransfer.FilesReload(Sender: TObject; Files: TRtcPFileExplorer);
var
  info: TListViewInfo;
begin
  info := SaveScroolListView(Files);

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
  if key in [VK_UP,VK_DOWN,VK_END,VK_HOME,VK_PRIOR,VK_NEXT] then
    FilesRemoteClick(Sender)

end;

procedure TrdFileTransfer.FilesLocalKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
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
     FRepositionFolder := s;
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
var
  s: string;
  list: TStringList;
begin
  list := TStringList.Create;
  try
    FilesRemote.GetSelectedFiles('Каталог:  ', 'Файл:     ', list);
    s := get_TF(list);
    if TaskMessageDlg(
    'Удаление',
    'Подтвердите удаление для выбранного (' + list.Count.ToString + '):' + s,
      mtInformation, [mbCancel, mbOK], 0, mbCancel) <> mrOK then exit;
       mnDeleteClick(nil);
  finally
    list.Free;
  end;
end;

procedure TrdFileTransfer.b_dl2Click(Sender: TObject);
var
  i: Integer;
  s: string;
  list: TStringList;
begin
  list := TStringList.Create;
  try
    FilesLocal.GetSelectedFiles('Каталог:  ','Файл:     ', list);
    s := get_TF(list);
    if TaskMessageDlg(
    'Удаление',
    'Подтвердите удаление для выбранного (' + list.Count.ToString + '):' + s,
      mtInformation, [mbCancel, mbOK], 0, mbCancel) <> mrOK then exit;

      if list.Count > 0 then
        begin
          FilesLocal.GetSelectedFiles('', '', list);
          for i := list.Count-1 downto 0 do
            begin
              if DirectoryExists(list[i]) then
                TDirectory.Delete(list[i], True)
              else if FileExists(list[i]) then
                TFile.Delete(list[i]);
            end;
          FilesLocal.onPath(FilesLocal.Directory);
        end;
  finally
    list.Free;
  end;
end;

procedure TrdFileTransfer.sbtnSendBatchClick(Sender: TObject);
var
  SelectedFiles, FileList: TStringList;
  i: Integer;
  y_all, n_all:boolean;
  temp_id: TTaskID;
  taskPanel: TTaskPanelInfo;
begin
  i := GetTickCount;
  if i - FDelayClickSendFetch < DELAY_CLICK_SEND_FETCH  then exit;
  FDelayClickSendFetch := i;

  SelectedFiles := FilesLocal.SelectedFiles;
  if SelectedFiles.Count = 0 then exit;
  taskPanel := nil;

  FileList := TStringList.Create;
  try
    Y_all:= False; N_all:= False;

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
          taskPanel := FTaskPanelList.AddTask(temp_id);
          taskPanel.to_path   := FilesRemote.Directory;
          taskPanel.Files     := FileList;
          DefTaskPanel(taskPanel, ExtractFileName(FilesRemote.Directory), dbtSend);
        except
          on E: Exception do
            begin
              add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
              PageControlTasks.ActivePage := tbFileLog;
              raise;
            end;
        end;
      end
    else
      PageControlTasks.ActivePage := tbFileLog;

  finally
    if not Assigned(taskPanel) and not Assigned(taskPanel.files) then
      FileList.Free;
  end;

end;

procedure TrdFileTransfer.sbtnFetchBatchClick(Sender: TObject);
var
  SelectedFiles, FileList: TStringList;
  i: Integer;
  y_all, n_all:boolean;
  temp_id: TTaskID;
  taskPanel: TTaskPanelInfo;
begin
  i := GetTickCount;
  if i - FDelayClickSendFetch < DELAY_CLICK_SEND_FETCH  then exit;
  FDelayClickSendFetch := i;

  SelectedFiles := FilesRemote.SelectedFiles;
  if SelectedFiles.Count = 0 then exit;
  taskPanel := nil;

  FileList := TStringList.Create;
  try
    Y_all:= False; N_all:= False;
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
        TRtcPFileTransfer(myUI.Module).NotifyFileBatchSend := OnSendBatch;
        try
          temp_id := TRtcPFileTransfer(myUI.Module).FetchBatch(myUI.UserName,
                              FileList, FilesRemote.Directory, FilesLocal.Directory, nil);
          taskPanel := FTaskPanelList.AddTask(temp_id);
          taskPanel.to_path   := FilesLocal.Directory;
          taskPanel.files     := FileList;
          DefTaskPanel(taskPanel, ExtractFileName(FilesLocal.Directory), dbtFetch);
        except
          on E: Exception do
            begin
              add_lg(TimeToStr(now) + ':  [ERROR] '+E.Message );
              PageControlTasks.ActivePage := tbFileLog;
              raise;
            end;
        end;
      end
    else
      PageControlTasks.ActivePage := tbFileLog;

  finally
    if not Assigned(taskPanel) and not Assigned(taskPanel.files) then
      FileList.Free;
  end;

end;

procedure TrdFileTransfer.lblCloseAllTaskClick(Sender: TObject);
var
  i: integer;
  taskPanel: TTaskPanelInfo;
begin
  FTaskPanelList.BeginUpdate;
  try
    for I := FTaskPanelList.Count-1 downto 0 do
      begin
        taskPanel := TTaskPanelInfo(FTaskPanelList.Objects[i]);
        if not taskPanel.Finished then
          CancelBatchClick(taskPanel.sbtnClose);

      end;
    FTaskPanelList.Clear;
  finally
    FTaskPanelList.EndUpdate;
  end;

end;


{ **************************************************************************** }
{                               TRecentPathList                                }
{ **************************************************************************** }

function TRecentPathList.Pop: string;
begin
  Pop(Result);
end;

function TRecentPathList.Available: Boolean;
begin
  Result := FStep > 0;
end;

constructor TRecentPathList.Create;
begin
  inherited Create;
  //Add('');
end;

function TRecentPathList.Pop(out s: string): Boolean;
begin
  if FDoubleRet then
    Delete(Count-1);
  FDoubleRet := false;
  Result := FStep > 0;
  s := '';
  if Result then
    Dec(FStep);
  if Count > 0 then
    begin
      s := Strings[Count-1];
      Delete(Count-1);
    end
  else if Result then
    Changed;
end;

procedure TRecentPathList.Push(const s: String);
begin
  Inc(FStep);
  FDoubleRet := True;
  Add(s);
end;


{ **************************************************************************** }
{                               TListTaskPanel                                 }
{ **************************************************************************** }


constructor TTaskPanelList.Create;
begin
  inherited Create(true);
  Sorted := true;
  FTaskRemoveLogic := trlImmediately;
end;

function TTaskPanelList.FindTaskInfo(const TaskID: TTaskID;
  out Info: TTaskPanelInfo): Boolean;
var
  index: Integer;
begin
  Result := Find(TaskID.ToString, index);
  if Result then
    Info := TTaskPanelInfo(Objects[index]);
end;

procedure TTaskPanelList.ForgetTask(const TaskID: TTaskID);
var
  index: Integer;
begin
  if not Find(TaskID.ToString, index) then exit;
  // Owned = true, avoid destroy
  Objects[index] := nil;
  Delete(index);
end;

function TTaskPanelList.GetTaskInfo(const TaskID: TTaskID): TTaskPanelInfo;
begin
  if not FindTaskInfo(TaskID, Result) then
    raise Exception.CreateFmt('Task %s not found', [TaskID.ToString]);
end;

procedure TTaskPanelList.RemoveTask(const TaskID: TTaskID);
var
  index: Integer;
begin
  if Find(TaskID.ToString, index) then
    Delete(index);
end;

function TTaskPanelList.ActiveTaskCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count-1 do
    Inc(Result, Integer(not TTaskPanelInfo(Objects[i]).Finished));
end;

function TTaskPanelList.AddTask(const TaskID: TTaskID): TTaskPanelInfo;
begin
  Result := TTaskPanelInfo.Create;
  try
    Result.taskID := TaskID;
    Result.list   := Self;
    AddObject(TaskID.ToString, Result)
  except
    Result.Free;
    raise;
  end;
end;


{ **************************************************************************** }
{                               TTaskPanelInfo                                 }
{ **************************************************************************** }


destructor TTaskPanelInfo.Destroy;
var
  p: TPanel;
begin
  files.Free;
  p := panel;
  ForgetWinControl;
  p.Free;

  inherited;
end;

procedure TTaskPanelInfo.ForgetWinControl;
begin
  if Assigned(panel) then
    begin
      panel         := nil;
      sbtnClose.Tag := 0;
      lblFile.Tag   := 0;
      lblSize.Tag   := 0;
    end;
end;

end.
