object Data_Provider: TData_Provider
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 447
  Width = 617
  object Module1: TRtcServerModule
    Link = ServerLink1
    Compression = cMax
    DataFormats = [fmt_RTC, fmt_XMLRPC]
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    AutoSessionsLive = 600
    ModuleFileName = '/gatefunc'
    FunctionGroup = GatewayFunctions
    OnSessionClose = Module1SessionClose
    Left = 98
    Top = 15
  end
  object GatewayFunctions: TRtcFunctionGroup
    Left = 266
    Top = 17
  end
  object AccountLogin: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.Login'
    OnExecute = AccountLoginExecute
    Left = 22
    Top = 153
  end
  object AccountSendText: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'SendText'
    OnExecute = AccountSendTextExecute
    Left = 206
    Top = 153
  end
  object HostGetData: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'GetData'
    OnExecute = HostGetDataExecute
    Left = 490
    Top = 212
  end
  object ServerLink1: TRtcDataServerLink
    Left = 42
    Top = 15
  end
  object AccountGetDeviceState: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.GetDeviceState'
    OnExecute = AccountGetDeviceStateExecute
    Left = 114
    Top = 153
  end
  object AccountDelFriend: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.DelFriend'
    OnExecute = AccountDelFriendExecute
    Left = 116
    Top = 208
  end
  object AccountLogOut: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.Logout'
    OnExecute = AccountLogOutExecute
    Left = 22
    Top = 263
  end
  object AccountLogin2: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.Login2'
    OnExecute = AccountLogin2Execute
    Left = 114
    Top = 264
  end
  object AccountPing: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.Ping'
    OnExecute = AccountPingExecute
    Left = 206
    Top = 263
  end
  object SQLConnection: TADOConnection
    ConnectionString = 
      'provider=SQLNCLI11;server=localhost\SQL2K14;User ID=sa;database=' +
      'Vircess;uid=sa;Persist security info=True;pwd=2230897'
    IsolationLevel = ilReadCommitted
    LoginPrompt = False
    Provider = 'SQLNCLI11'
    Left = 264
    Top = 81
  end
  object AccountAddGroup: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.AddGroup'
    OnExecute = AccountAddGroupExecute
    Left = 114
    Top = 327
  end
  object AccountDeleteGroup: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.DeleteDeviceGroup'
    OnExecute = AccountDeleteGroupExecute
    Left = 18
    Top = 327
  end
  object AccountAddDevice: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.AddDevice'
    OnExecute = AccountAddDeviceExecute
    Left = 206
    Top = 209
  end
  object AccountChangeDevice: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.ChangeDevice'
    OnExecute = AccountChangeDeviceExecute
    Left = 18
    Top = 379
  end
  object AccountChangeGroup: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.ChangeGroup'
    OnExecute = AccountChangeGroupExecute
    Left = 110
    Top = 379
  end
  object AccountAddAccount: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'AddAccount'
    OnExecute = AccountAddAccountExecute
    Left = 22
    Top = 207
  end
  object HostLogin: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.Login'
    OnExecute = HostLoginExecute
    Left = 328
    Top = 153
  end
  object HostLogOut: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.Logout'
    OnExecute = HostLogOutExecute
    Left = 326
    Top = 263
  end
  object HostActivate: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.Activate'
    OnExecute = HostActivateExecute
    Left = 412
    Top = 264
  end
  object HostLogin2: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.Login2'
    OnExecute = HostLogin2Execute
    Left = 412
    Top = 210
  end
  object HostGetUserInfo: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.GetUserInfo'
    OnExecute = HostGetUserInfoExecute
    Left = 414
    Top = 153
  end
  object HostPing: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.Ping'
    OnExecute = HostPingExecute
    Left = 490
    Top = 153
  end
  object HostPassUpdate: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.PasswordsUpdate'
    OnExecute = HostPassUpdateExecute
    Left = 326
    Top = 212
  end
  object AccountEmailIsExists: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Account.EmailIsExists'
    OnExecute = AccountEmailIsExistsExecute
    Left = 204
    Top = 327
  end
  object HostLockedStateUpdate: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.LockedStateUpdate'
    OnExecute = HostLockedStateUpdateExecute
    Left = 490
    Top = 264
  end
  object GetLockedState: TRtcFunction
    Group = GatewayFunctions
    FunctionName = 'Host.GetLockedState'
    OnExecute = GetLockedStateExecute
    Left = 558
    Top = 154
  end
  object Module2: TRtcServerModule
    Link = ServerLink2
    Compression = cMax
    DataFormats = [fmt_RTC, fmt_XMLRPC]
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    AutoSessionsLive = 600
    ModuleFileName = '/gatefunc'
    FunctionGroup = GatewayFunctions
    OnSessionClose = Module1SessionClose
    Left = 96
    Top = 77
  end
  object ServerLink2: TRtcDataServerLink
    Left = 40
    Top = 77
  end
  object ServerLink3: TRtcDataServerLink
    Left = 150
    Top = 17
  end
  object Module3: TRtcServerModule
    Link = ServerLink3
    Compression = cMax
    DataFormats = [fmt_RTC, fmt_XMLRPC]
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    AutoSessionsLive = 600
    ModuleFileName = '/gatefunc'
    FunctionGroup = GatewayFunctions
    OnSessionClose = Module1SessionClose
    Left = 206
    Top = 17
  end
  object Module4: TRtcServerModule
    Link = ServerLink4
    Compression = cMax
    DataFormats = [fmt_RTC, fmt_XMLRPC]
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    AutoSessionsLive = 600
    ModuleFileName = '/gatefunc'
    FunctionGroup = GatewayFunctions
    OnSessionClose = Module1SessionClose
    Left = 206
    Top = 79
  end
  object ServerLink4: TRtcDataServerLink
    Left = 150
    Top = 79
  end
  object GateServer: TRtcFunctionGroup
    Left = 509
    Top = 26
  end
  object GateServerModule: TRtcServerModule
    Link = GateServerLink
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    ModuleFileName = '/gategroup'
    FunctionGroup = GateServer
    Left = 445
    Top = 20
  end
  object GateClientModule: TRtcClientModule
    Link = GateClientLink
    Compression = cMax
    HyperThreading = True
    EncryptionKey = 16
    SecureKey = '2240897'
    ForceEncryption = True
    AutoSessions = True
    ModuleFileName = '/gategroup'
    Left = 441
    Top = 84
  end
  object GateServerLink: TRtcDataServerLink
    Left = 398
    Top = 19
  end
  object GateClientLink: TRtcDataClientLink
    AutoSyncEvents = True
    Left = 396
    Top = 84
  end
  object GateRelogin: TRtcFunction
    Group = GateServer
    FunctionName = 'Gateway.Relogin'
    OnExecute = GateReloginExecute
    Left = 328
    Top = 331
  end
  object GateLogout: TRtcFunction
    Group = GateServer
    FunctionName = 'Gateway.Logout'
    OnExecute = GateLogoutExecute
    Left = 412
    Top = 333
  end
  object rGateRelogin: TRtcResult
    OnReturn = rGateReloginReturn
    RequestAborted = rGateReloginRequestAborted
    Left = 326
    Top = 388
  end
  object rGateLogOut: TRtcResult
    Left = 412
    Top = 390
  end
end