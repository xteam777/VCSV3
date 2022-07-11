program VircessGateway;

{ Copyright (c) Danijel Tkalcec,
  RealThinClient components - http://www.realthinclient.com }

{$INCLUDE rtcDefs.inc}

uses
  {$ifdef rtcDeploy}
  {$IFNDEF IDE_2006up}
  FastMM4,
  {$ENDIF }
  {$endif }
  rtcLog,
  SysUtils,
  rtcService,
  Windows,
  SvcMgr,
  WinSvc,
  Forms,
  ServiceMgr,
  CommonData,
  rtcSystem,
  uProcess,
  RtcGatewayForm in 'RtcGatewayForm.pas' {MainForm},
  RtcGatewaySvc in 'RtcGatewaySvc.pas' {Rtc_GatewayService: TService},
  rtcDataProvider in '..\Modules\DataProviders\rtcDataProvider.pas' {Data_Provider: TDataModule},
  rtcAccounts in '..\Modules\DataProviders\rtcAccounts.pas';

{$R *.res}

begin
StartLog;

  LOG_EXCEPTIONS := True;

  if not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Logs\' + GetSystemUserName) then
    CreateDir(ExtractFilePath(ParamStr(0)) + 'Logs\' + GetSystemUserName);
  RTC_LOG_FOLDER := ExtractFilePath(ParamStr(0)) + 'Logs\' + GetSystemUserName + '\';

  AppFileName := ParamStr(0);
  ActiveConsoleSessionID := GetActiveConsoleSessionId;
  CurrentProcessId := GetCurrentProcessId;
  ProcessIdToSessionId(GetCurrentProcessId, CurrentSessionID);
  IsWinServer := IsWindowsServerPlatform;

  try
    if IsDesktopMode(RTC_GATEWAYSERVICE_NAME) then
      begin
      Forms.Application.Initialize;
      Forms.Application.Title := 'Vircess Gateway';
      Forms.Application.CreateForm(TMainForm, MainForm);
    Forms.Application.Run;
      end
    else
      begin
      xLog('Starting Vircess Gateway ...');
      SvcMgr.Application.Initialize;
      SvcMgr.Application.CreateForm(TRtc_GatewayService, Rtc_GatewayService);
      SvcMgr.Application.Run;
      end;
  except
    on E:Exception do
      xLog('FATAL ERROR '+E.ClassName+': '+E.Message);
    end;
end.
