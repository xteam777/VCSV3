object Hosts_Provider: THosts_Provider
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 270
  Width = 294
  object Module: TRtcServerModule
    Link = ServerLink
    Compression = cMax
    DataFormats = [fmt_RTC, fmt_XMLRPC]
    EncryptionKey = 16
    SecureKey = '2230897'
    ForceEncryption = True
    AutoSessionsLive = 40
    AutoSessions = True
    ModuleFileName = '/hostsfunc'
    FunctionGroup = HostsFunctions
    OnSessionClose = ModuleSessionClose
    Left = 96
    Top = 15
  end
  object HostsFunctions: TRtcFunctionGroup
    Left = 168
    Top = 15
  end
  object HostLogin: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'Login'
    OnExecute = HostLoginExecute
    Left = 28
    Top = 85
  end
  object HostRegister: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'Register'
    OnExecute = HostRegisterExecute
    Left = 28
    Top = 140
  end
  object HostGetData: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'GetData'
    OnExecute = HostGetDataExecute
    Left = 214
    Top = 86
  end
  object ServerLink: TRtcDataServerLink
    Left = 24
    Top = 15
  end
  object HostLogOut: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'Logout'
    OnExecute = HostLogOutExecute
    Left = 28
    Top = 195
  end
  object HostLogin2: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'Login2'
    OnExecute = HostLogin2Execute
    Left = 116
    Top = 144
  end
  object HostPing: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'Ping'
    OnExecute = HostPingExecute
    Left = 216
    Top = 143
  end
  object SQLConnection: TADOConnection
    ConnectionString = 
      'provider=SQLNCLI11;server=localhost;User ID=sa;database=Vircess;' +
      'uid=sa;Persist security info=True;pwd=2230897'
    IsolationLevel = ilReadCommitted
    LoginPrompt = False
    Provider = 'SQLNCLI11'
    Left = 236
    Top = 15
  end
  object HostGetUserConnectionInfo: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'GetUserConnectionInfo'
    OnExecute = HostGetUserConnectionInfoExecute
    Left = 118
    Top = 87
  end
  object HostActivate: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'Activate'
    OnExecute = HostActivateExecute
    Left = 116
    Top = 198
  end
  object HostPassUpdate: TRtcFunction
    Group = HostsFunctions
    FunctionName = 'PasswordsUpdate'
    OnExecute = HostPassUpdateExecute
    Left = 216
    Top = 200
  end
end
