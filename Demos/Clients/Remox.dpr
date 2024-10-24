﻿ program Remox;

{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

{$INCLUDE rtcDefs.inc}

{$define FullDebugMode}
{$define LogMemoryLeakDetailToFile}


{$R *.dres}

uses
  rtcLog,
  Classes,
  SysUtils,
  rtcInfo,
  rtcService,
  Windows,
  SvcMgr,
  WinSvc,
  Forms,
  ShellApi,
  rtcSystem,
  rtcWinLogon,
  Registry,
  uProcess,
  ShlObj,
  RtcHostForm in 'RtcHostForm.pas' {MainForm},
  RtcHostSvc in 'RtcHostSvc.pas' {RemoxService: TService},
  dmSetRegion in '..\Modules\dmSetRegion.pas' {dmSelectRegion},
  rdChat in '..\Modules\rdChat.pas' {rdChatForm},
  rdFileTrans in '..\Modules\rdFileTrans.pas' {rdFileTransfer},
  rdSetClient in '..\Modules\rdSetClient.pas' {rdClientSettings},
  rdSetHost in '..\Modules\rdSetHost.pas' {rdHostSettings},
  rdDesktopView in '..\Modules\rdDesktopView.pas' {rdDesktopViewer},
  rdDesktopSave in '..\Modules\rdDesktopSave.pas' {rdDesktopSaver: TDataModule},
  Messages,
  RtcGroupForm in '..\Modules\RtcGroupForm.pas' {GroupForm},
  RtcDeviceForm in '..\Modules\RtcDeviceForm.pas' {DeviceForm},
  uVircessTypes in '..\Modules\uVircessTypes.pas',
  RunElevatedSupport in '..\Modules\RunElevatedSupport.pas',
  RtcIdentification in '..\Modules\RtcIdentification.pas' {fIdentification},
  RtcRegistrationForm in '..\Modules\RtcRegistrationForm.pas' {RegistrationForm},
  AboutForm in '..\Modules\AboutForm.pas' {fAboutForm},
  CommonUtils in '..\Modules\CommonUtils.pas',
  FireWall in '..\Modules\FireWall.pas',
  CommonData in '..\Modules\CommonData.pas',
  System.Types,
  System.IOUtils,
  ServiceMgr in '..\Modules\ServiceMgr.pas',
  Vcl.Themes,
  Vcl.Styles,
  uMessageBox in '..\Modules\uMessageBox.pas' {fMessageBox},
  uPowerWatcher in '..\Modules\uPowerWatcher.pas',
  rdFileTransLog in '..\Modules\rdFileTransLog.pas' {rdFileTransferLog},
  uSetup in 'uSetup.pas',
  uAcceptEula in '..\Modules\uAcceptEula.pas' {fAcceptEULA},
  NTImport in 'NTImport.pas',
  rtcpFileTrans in 'rtcpFileTrans.pas',
  rmxVideoFile in '..\..\rmxVideo\API\rmxVideoFile.pas',
  rmxVideoPacketTypes in '..\..\rmxVideo\API\rmxVideoPacketTypes.pas',
  rmxVideoStorage in '..\..\rmxVideo\API\rmxVideoStorage.pas',
  Compressions in '..\..\rmxVideo\Compressor\Compressions.pas',
  SendDestroyToGateway in '..\Modules\SendDestroyToGateway.pas',
  uUIDataModule in '..\Modules\uUIDataModule.pas' {UIDataModule},
  uChannelsUsage in '..\Modules\uChannelsUsage.pas' {fChannelsUsage},
  uDMUpdate in '..\Modules\uDMUpdate.pas' {DMUpdate: TDataModule},
  ConvertUnit in '..\..\rmxVideo\rmxPlayaer\Convert\ConvertUnit.pas' {ConvertForm},
  FLoatPanelVCL in '..\..\rmxVideo\rmxPlayaer\FloatPanel\FLoatPanelVCL.pas',
  AcceleratedPaintBox in '..\..\rmxVideo\rmxPlayaer\AcceleratedPaintBox.pas',
  PlayerUnit in '..\..\rmxVideo\rmxPlayaer\PlayerUnit.pas' {PlayerForm},
  PlayImage in '..\..\rmxVideo\rmxPlayaer\PlayImage.pas',
  SimleTrackBar in '..\..\rmxVideo\rmxPlayaer\SimleTrackBar.pas',
  rmxAVIConverter in '..\..\rmxVideo\rmxConverter\converters\rmxAVIConverter.pas',
  rmxBitmapConverter in '..\..\rmxVideo\rmxConverter\converters\rmxBitmapConverter.pas',
  rmxBitmaper in '..\..\rmxVideo\rmxConverter\converters\rmxBitmaper.pas',
  RMXConverterBase in '..\..\rmxVideo\rmxConverter\converters\RMXConverterBase.pas',
  rmxConverterUtils in '..\..\rmxVideo\rmxConverter\converters\rmxConverterUtils.pas',
  CmdLineParams in '..\..\rmxVideo\rmxConverter\CmdLineParams.pas',
  VideoRecorder in '..\..\rmxVideo\rmxConverter\VideoRecorder.pas',
  rmxImageCODEC in '..\..\rmxImageCODEC\rmxImageCODEC.pas';

{$R *.res}


var
//  cnt: Integer;
//  s: RtcString;
  hPrev: THandle;
  err: LongInt;
  strParams, pfFolder, fn: String;
//  EleavateSupport: TEleavateSupport;
//  TorControlSocket: TIdTCPClient;

function UniqueApp(const Title: AnsiString): Boolean;
var
  hMutex: THandle;
begin
   hMutex := 0;
   hMutex := CreateMutex(nil, False, PWideChar(WideString(Title)));
   Result := (GetLastError <> ERROR_ALREADY_EXISTS);
end;

procedure StartProcessInDesktopMode;
begin
//MessageBox(Application.Handle, PWideChar(WideString(IntToStr(GetCurrentProcessId))), '', MB_OK);
//Sleep(10000);

  xLog('Start Remox in desktop mode');

  if not File_Exists(GetTempDirectory + 'rmxCompression.dll') then
    CommonUtils.SaveResourceToFile('FAST_LZMA2', GetTempDirectory + 'rmxCompression.dll');

  IsService := False;

  AutoDesktopSwitch := False; //True; //Íóæíî äëÿ ïîëó÷åíèÿ èíôû îá ýêðàíå è êóðñîðå

//      TStyleManager.LoadFromResource(hInstance, 'LIGHT', 'RCDATA');
//  TStyleManager.TrySetStyle('Windows10');
//äîäåëàòü      TCustomStyleExt(TStyleManager.ActiveStyle).SetStyleColor(scPanel, clWhite);
  Forms.Application.Initialize;
//      if Win32MajorVersion = 10 then
//        TStyleManager.TrySetStyle('Windows10');
//  TStyleManager.TrySetStyle('Windows10');
  Application.Title := 'Remox';
  Forms.Application.ShowMainForm := (Pos('/SILENT', UpperCase(CmdLine)) = 0);
  Forms.Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TPlayerForm, PlayerForm);
  Forms.Application.Run;
//    else
//    begin
//      if (Win32MajorVersion >= 6)
//        and (Pos('-VISTA', UpperCase(CmdLine)) <> 0) Then
//      begin
//        s := '';
//        if Pos('-AUTORUN', UpperCase(CmdLine))<>0 then
//          s := s+' -AUTORUN';
//        if Pos('-SILENT',UpperCase(CmdLine)) <> 0 then
//          s := s+' -SILENT';
//        Write_File(ChangeFileExt(AppFileName,'.run'), s);
//
//        ShellExecute(0, 'open', PChar(AppFileName), '/INSTALL /SILENT', nil, SW_SHOW);
//        Sleep(500);
//        ShellExecute(0, 'open', 'net', PChar('start ' + RTC_HOSTSERVICE_NAME), nil, SW_HIDE);
//        cnt := 0;
//        repeat
//          Sleep(500);
//          Inc(cnt);
//        until not File_Exists(ChangeFileExt(AppFileName, '.run')) or (cnt >= 20);
//        Sleep(500);
//        // Service will return FALSE from its "Start" event,
//        // so it does not have to be stopped manually, we can simply uninstall it.
//        ShellExecute(0, 'open', PChar(AppFileName), '/UNINSTALL /SILENT', nil, SW_HIDE);
//
//        if File_Exists(ChangeFileExt(AppFileName,'.run')) then
//        begin
//          Delete_File(ChangeFileExt(AppFileName,'.run'));
//          Forms.Application.Initialize;
//          Forms.Application.Title := 'Remox';
//          Forms.Application.CreateForm(TMainForm, MainForm);
//          Forms.Application.Run;
//        end;
//      end
//      else
//      begin
//        Forms.Application.Initialize;
//        Forms.Application.Title := 'Remox';
//        Forms.Application.CreateForm(TMainForm, MainForm);
//        Forms.Application.Run;
//      end;
//    end;
end;

procedure StartProcessInServiceMode;
begin
//Sleep(10000);

  xLog('Start Remox in service mode');

  IsService := True;

//  xLog('Kill Remox desktop process');
//  rtcKillProcess(AppFileName); //<--Èççà ýòîãî ñåðâèñ çàâåðøàåòñÿ
//    PostMessage(HWND_BROADCAST, WM_CLOSEVIRCESS, Application.Handle, 0);

//      if not File_Exists(ChangeFileExt(AppFileName,'.run')) then
//        xLog('Remox Service ...');

  AutoDesktopSwitch := False; //True; //Нужно для получения инфы об экране и курсоре

//      TStyleManager.LoadFromResource(hInstance, 'LIGHTVSF');
//  TStyleManager.TrySetStyle('Windows10');
//äîäåëàòü      TCustomStyleExt(TStyleManager.ActiveStyle).SetStyleColor(scPanel, clWhite);
  SvcMgr.Application.Initialize;
  SvcMgr.Application.CreateForm(TRemoxService, RemoxService);
//      if Win32MajorVersion = 10 then
//        TStyleManager.TrySetStyle('Windows10');
  SvcMgr.Application.Run;
end;


begin
//  if File_Exists(ChangeFileExt(AppFileName, '.ext')) then
//  begin
//    Delete_File(ChangeFileExt(AppFileName, '.ext'));
//  end;

//  LOG_THREAD_EXCEPTIONS := True;
  LOG_EXCEPTIONS := True;

  if Pos('\Program files', ParamStr(0)) > 0 then
  begin
    if not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Logs') then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Logs');
    if not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Logs\' + GetSystemUserName) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Logs\' + GetSystemUserName);
    RTC_LOG_FOLDER := ExtractFilePath(ParamStr(0)) + 'Logs\' + GetSystemUserName + '\';
  end
  else
  begin
    if not DirectoryExists(System.SysUtils.GetEnvironmentVariable('APPDATA') + '\Logs') then
      CreateDir(System.SysUtils.GetEnvironmentVariable('APPDATA') + '\Logs');
    if not DirectoryExists(System.SysUtils.GetEnvironmentVariable('APPDATA') + '\Logs\' + GetSystemUserName) then
      CreateDir(System.SysUtils.GetEnvironmentVariable('APPDATA') + '\Logs\' + GetSystemUserName);
    RTC_LOG_FOLDER := System.SysUtils.GetEnvironmentVariable('APPDATA') + '\Logs\' + GetSystemUserName + '\';
  end;

  AppFileName := ParamStr(0);
  ActiveConsoleSessionID := GetActiveConsoleSessionId;
  CurrentProcessId := GetCurrentProcessId;
  ProcessIdToSessionId(GetCurrentProcessId, CurrentSessionID);
  IsWinServer := IsWindowsServerPlatform;

//Sleep(10000);

//  CreateAttachedProcess('\Tor\tor.exe', 'SocksPort 9250 ControlPort 9251', SW_HIDE, TorProcessID);

//  TorControlSocket := TIdTCPClient.Create(nil);
////  TorControlSocket.OnStatus := OnSocketStatus;
//  TorControlSocket.Host := '127.0.0.1';
//  TorControlSocket.Port := 9251; //ControlPort
//  TorControlSocket.Connect;
////  sck.SendCmd('AUTHENTICATE "tuman777"');
//  TorControlSocket.SendCmd('AUTHENTICATE');
//  TorControlSocket.SendCmd('ADD_ONION NEW:BEST PORT=80,127.0.0.1 FLAGS=DiscardPK');
//  if Length(TorControlSocket.LastCmdResult.Text.Text) > 56 + 11 then
//  begin
//    if Copy(TorControlSocket.LastCmdResult.Text.Text, 1, 10) = 'ServiceID=' then
//      TorServiceID := Copy(TorControlSocket.LastCmdResult.Text.Text, 11, 56)
//    else
//    begin
//      XLog('');
//      Exit;
//    end;
//  end
//  else
//    Exit;

//  AdjustPriviliges(SE_DEBUG_NAME); //Нужно для OpenProcess -> ReadProcessMemory

//  ProcessIdToSessionId(GetCurrentProcessId, CurrentSessionID);
//  IsConsoleClient := (CurrentSessionID = WTSGetActiveConsoleSessionId);

  //Сохраняться в HKLM
//  RTC_LOG_FOLDER := GetDOSEnvVar('APPDATA') + '\Remox\';

  StartLog;
  try
    if Pos('.RMXV', UpperCase(ParamStr(1))) <> 0 then
    begin
      TPlayerForm.Create(nil).OpenFile(ParamStr(1));
    end
    else
    if Pos('/UPDATE', UpperCase(CmdLine)) <> 0 then
    begin
      //Обновлятор уже запускается с правами администратора
      //Stop service

      with TStringList.Create do
      try
        Add('PING 127.0.0.1 -n 2 > NUL');
        if FileExists(pfFolder + '\Remox\Remox.exe') then
          Add('"' + pfFolder + '\Remox\Remox.exe"')
        else
          Add('"' + ParamStr(0) + '"');
        fn := GetTempFile + '.bat';
        Add('DEL "' + fn + '"');
        SaveToFile(fn, TEncoding.GetEncoding(866));
      finally
        Free;
      end;

      ShellExecute(Application.Handle, 'open', PChar(fn), '', '', SW_HIDE);
    end;
    if Pos('/ADDRULES', UpperCase(CmdLine)) <> 0 then
    begin
      AddFireWallRules(ParamStr(0));
      Exit;
    end;

//    if Pos('-BKM', UpperCase(CmdLine)) <> 0 then
//    begin
//      BlockInput(True);
//      Exit;
//    end;
//    if Pos('-UBKM', UpperCase(CmdLine)) <> 0 then
//    begin
//      BlockInput(False);
//      Exit;
//    end;

  //Sleep(10000);
//  if not EleavateSupport.IsElevated then
//    MessageBox(0, 'Not Elevated', '', MB_OK)
//  else
//  MessageBox(0, 'Elevated', '', MB_OK);

//    if IsDesktopMode(RTC_HOSTSERVICE_NAME)
//      and (not EleavateSupport.IsElevated) then
//    begin
//        if (Pos('/ELEVATE', UpperCase(CmdLine)) = 0) then
//        begin
//          strParams := Copy(GetCommandLine, Length(ParamStr(0)) + 2, Length(GetCommandLine) - Length(ParamStr(0)) - 1);
//          SetLastError(EleavateSupport.RunElevated(ParamStr(0), strParams, Application.Handle, False, Application.ProcessMessages));
//          err := GetLastError;
//          if err <> ERROR_SUCCESS then
//            xLog('Run elevated error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
//
//    //      MessageBox(Application.Handle, PWideChar(WideString(strParams)), '', MB_OK);
//
//          Exit;
//        end;

////      if (Pos('/ELEVATE', UpperCase(CmdLine)) > 0) then
////      begin
//        strParams := Copy(GetCommandLine, Length(ParamStr(0)) + 3, Length(GetCommandLine) - Length(ParamStr(0)) - 2);
//        strParams := Trim(StringReplace(strParams, '/ELEVATE', '', [rfReplaceAll]));
//        strParams := Trim(StringReplace(strParams, '  ', ' ', [rfReplaceAll]));
//        EleavateSupport := TEleavateSupport.Create(nil);
//        try
//          SetLastError(EleavateSupport.RunElevated(ParamStr(0), strParams, Application.Handle, False, Application.ProcessMessages));
//          err := GetLastError;
//        finally
//          EleavateSupport.Free;
//        end;
//        if err <> ERROR_SUCCESS then
//          xLog('Run elevated error = ' + IntToStr(err) + ' ' + SysErrorMessage(err));
//
//        Exit;
////      end;
//    end;

    if Pos('/INSTALL', UpperCase(CmdLine)) > 0 then
    begin
      pfFolder := GetSpecialFolderLocation(CSIDL_PROGRAM_FILESX86);

      CreateUninstallRegistryKey;
      CreateAutorunRegistryKey;
      CreateShortcuts;
      CreateProgramFolder;
      AddFireWallRules(ParamStr(0));
      AddExceptionToFireWall;
      RegisterFileType('rmxv', 'Файл видеозаписи Remox', Application.ExeName, Application.ExeName, False);

      if not IsServiceExisted(RTC_HOSTSERVICE_NAME) then
        CreateServices(RTC_HOSTSERVICE_NAME, RTC_HOSTSERVICE_DISPLAY_NAME, pfFolder + '\Remox\Remox.exe');
      StartServices(RTC_HOSTSERVICE_NAME);

      AddFireWallRules(pfFolder + '\Remox\Remox.exe');

      with TStringList.Create do
      try
        Add('PING 127.0.0.1 -n 2 > NUL');
        Add('"' + pfFolder + '\Remox\Remox.exe"');
        fn := GetTempFile + '.bat';
        Add('DEL "' + fn + '"');
        SaveToFile(fn, TEncoding.GetEncoding(866));
      finally
        Free;
      end;

      ShellExecute(Application.Handle, 'open', PChar(fn), '', '', SW_HIDE);
    end
    else
    if Pos('/START', UpperCase(CmdLine)) > 0 then
    begin
      StartServices(RTC_HOSTSERVICE_NAME);
    end
    else
    if Pos('/STOP', UpperCase(CmdLine)) > 0 then
    begin
      StopServices(RTC_HOSTSERVICE_NAME);
    end
    else
    if Pos('/KILL', UpperCase(CmdLine)) > 0 then
    begin
      rtcKillProcess('rmx_x32');
      rtcKillProcess('rmx_x64');
      rtcKillProcess('remox.exe');
    end
    else
    if Pos('/UNINSTALL', UpperCase(CmdLine)) > 0 then
    begin
      if MessageBox(Application.Handle, 'Remox ,будет удален из системы. Продолжить?', 'Remox', MB_OKCANCEL) = ID_CANCEL then
        Exit;

      UninstallService(RTC_HOSTSERVICE_NAME, 0);

      UnregisterFileType('rmxv', False);
      RemoveFireWallRules(ParamStr(0));
      RemoveExceptionToFireWall;
      DeleteShortcuts;
      DeleteUninstallRegistryKey;
      DeleteAutorunRegistryKey;
      DeleteSettingsRegistryKeys;
      DeleteProgramFolder;
    end
    else
    begin
      if IsDesktopMode(RTC_HOSTSERVICE_NAME) then
      begin
        if not UniqueApp('Remox_Session_' + IntToStr(CurrentSessionID)) then
        begin
          hPrev := FindWindow('TMainForm', 'Remox');
          if hPrev <> 0 then
          begin
//            xLog('Bring existing Remox window to top. Handle:' + IntToStr(hPrev));
            PostMessage(hPrev, WM_TASKBAREVENT, 100, WM_LBUTTONDBLCLK);

  //          Visible := True;
  //          ShowWindow(Application.Handle, SW_SHOW);
  //          Application.Restore;
//            SetForegroundWindow(hPrev);
            PostMessage(hPrev, WM_ACTIVATE, WA_ACTIVE, 0);
            Exit;
          end;
        end
        else
        begin
  //      if FindWindow('Shell_TrayWnd', nil) = 0 then //Отключено для запуска в неактивной консольной сессии
  //        Exit;

  //      try
  //        AdjustPriviliges(SE_CREATE_GLOBAL_NAME); //В вин10 АВ. Для вин10 не нужно?. Для открытия события не нужно. Только для создания
  //      finally
  //      end;
          StartProcessInDesktopMode;
        end;
      end
      else
      begin
  //      try
  //        AdjustPriviliges(SE_CREATE_GLOBAL_NAME);
  //      finally
  //      end;
        StartProcessInServiceMode;
      end;
    end;

  except
    on E: Exception do
      xLog('ERROR ' + E.ClassName + ': ' + E.Message);
    end;
end.





