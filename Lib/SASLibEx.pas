{SASLibEx Library for Delphi.

This unit provides access to the SASLibEx library for Delphi.

Copyright 2009 Weijnen ICT Diensten, All Rights Reserved.

This source code, hereafter referred to as the code, may not be distributed,
modified or used in any way, without explicit written permission.

This software is provided ‘as-is’, without any express or implied warranty.
In no event will the author be held liable for any damages arising from the
use of this software.

File Version 2.0

Changelog:
  20.05.2010 - 2.1 - Delphi and C++ Builder extension added, bugfixes
  15.05.2010 - 2.0   - Second major release
  07.10.2009 - 1.904 - Fixed handle leaks.
  01.07.2009 - 1.903 - Delphi support changed. Bugfixes.
  20.05.2009 - 1.823 - Fixed minor bugs. Updated docs.
  11.04.2009 - 1.800 - Added more functions. Made Delphi obj compatible.
  04.04.2009 - 1.176 - Fixed minor bugs and features in versioning. Fixed wrong docs.
  10.03.2009 - 1.170 - Fixed some minor bugs. Added docs.
  08.02.2009 - 1.0   - First release
}
unit SASLibEx;

interface

{$A4}

{Using DCU:
This directive only works for SasLibEx.dcu if the user has the same
JwaWindows.dcu as at compile time.
So it should be turned off.

The reason is for developing. If a function - not available in Windows.pas -
must be imported, we still can use the JEDI.
}
{$UNDEF JWAWINDOWS}
{.$DEFINE JWAWINDOWS}

{$IFDEF JWAWINDOWS}
{$DEFINE JWA}
uses JwaWindows
{$ELSE}
 {$IFDEF JWASINGLE}
 {$DEFINE JWA}
 //...
 {$ELSE}
uses Windows
 {$ENDIF JWASINGLE}
{$ENDIF JWASINGLE}
 ,sysutils, classes, SyncObjs
;

const
  //only console session?
  BIT_MULTIPLE_SESSIONS = $1;
  //Secure Attention Sequence feature
  BIT_FEATURE_SAS = $2;
  //Lock workstation feature
  BIT_FEATURE_LOCK = $4;
  //Unlock workstation feature
  BIT_FEATURE_UNLOCK = $8;
  //Logoff user feature
  BIT_FEATURE_LOGOFF = $10;
  //Wait until unlocked desktop feature
  BIT_FEATURE_WAIT_UNLOCK = $20;
  //Switch to and from secure desktop feature
  BIT_FEATURE_SWITCH_LOGON = $40;
  BIT_FEATURE_CANCEL_UAC_REQUEST = $80;
  BIT_FEATURE_CANCEL_SAS = $100;
  BIT_FEATURE_DISENABLE_CAD = $200;
  BIT_FEATURE_SESSION_CONNECT = $400;
  BIT_FEATURE_SESSION_USERNAME = $800;
  BIT_FEATURE_IS_DESKTOP_LOCKED = $1000;
  BIT_FEATURE_SASASUSER = $2000;

  {
  SAS_CONSOLE_SESSION is used for the dynamic replacement of the
  console session ID in all SASLibEx functions.
  If this value is used the call is executed in the console session
  regardless of the process session id.
  If the library license does not permit multiple session, this
  value is mandatory for all SASLibEx functions which receives a session id;
  otherwise they will fail.
  }
  SAS_CONSOLE_SESSION = DWORD(-1);

  {The function tries to start the TerminalService if necessary.
  It also stops it afterwards if it was not running in the beginning.
  }
  SAS_AUTO = $0;

  {
  The function prepares the TerminalService if necessary
  but does not revert to the state in the beginning.
  }
  SAS_NO_REVERT = $4000;

  {
  The function does not initiate a CAD. This is useful with
  SAS_NO_REVERT to adapt the TerminalService for further calls.
  }
  SAS_NO_CAD = $8001;

  {
  The function does not try to fix anything. It just initiates CAD.
  }
  SAS_NO_FIX = $0002;


{SASLibEx_Init must be called before any other call of the following functions.

WARNING: Do not call this or any other SasLibEx function within DLL main. Doing so
 will lead to unexpected behavior.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.

Remarks
  This function fails with return value FALSE if it is called more than once. However
  the GetLastError value is set to ERROR_SUCCESS (0). This is just a warning.

All SASLibEx_xxx functions need this call before they can be used. Exceptions are
SASLibEx_GetFeatures and SASLibEx_GetVersion;

}
function SASLibEx_InitLib : BOOL;



{
SASLib_GetFeatures returns the supported features by this library
A feature is availabe if the assigned bit is set:

Use the BIT_FEATURE_XXXX constants.
}
function SASLibEx_GetFeatures() : Cardinal; stdcall; external;



{
SASLibEx_GetVersion returns the version of the library.

You can use SASLibEx_GetVersionEx for easier access.

}
function SASLibEx_GetVersion() : DWORD; stdcall; external;




{
SASLibEx_SendSAS sends a CAD to the given session.


Parameter
  SessionID Target session where CAD should be initiated. This parameter
  must be SAS_CONSOLE_SESSION for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.

Remarks
  This function needs at least Windows Vista.
  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

  ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_SendSAS(SessionID : DWORD) : BOOL; stdcall; external;

{
SASLibEx_SendSASAsUser calls CAD from a simple user process (see Remarks section
for detailed information). There is no way to specific
a session ID, it uses always the current session ID of the process.


Parameters
	Options
		Use any combination of the SAS_XXX flags to control the function.
		The function does not check for combinations that does not make sense (like SAS_NO_FIX | SAS_NO_CAD).

Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.

Remarks
	This function is only available in Windows Vista and later.

	It cannot be called from SYSTEM.

	Administrator necessary:
	  Sometimes the function needs to do preparations to make the CAD succeed.
	  These preparations can only work if the call is made by an Administrator.

	If the preparations are not necessary the function can be called by a standard user!

	The preparations of the function can be one of the following processes:

	A. If Terminal Service is running and connections are allowed:
	   The function initiates CAD and exits.

	B. If Terminal Service is not running the function tries to start the service.
	   Then it initiates CAD and stops the Terminal Services afterwards.

	C. If Terminal Service is running but connections are not allowed the function
	   tries to restart the Terminal Service.
	   Then it initiates CAD but it does not restart the Terminal Services afterwards.

    Behavior C will disconnect logged on remote users.

	Behavior B and C can take some time (several seconds).
	If you use SAS_NO_REVERT subsequent calls will be processed faster because preparations
	are no more necessary. It is reset on a restart of the system (depending on configuration).

	You can use SAS_NO_FIX if you don't want any preparations to take place.


	The following return values of GetLastError are possible. However there
	can be additional ones.

	ERROR_ACCESS_DENIED (5)
		The access was denied. This can have several reasons:
		1. If the SASLibEx license is console only and the current process
			is not running in a console session.
		2. A policy denies access.

	ERROR_REQUEST_OUT_OF_SEQUENCE (776)
		SASLibEx_Init must be called first.

	ERROR_CALL_NOT_IMPLEMENTED
		If the function is not supported by the library.

	ERROR_OLD_WIN_VERSION
		The Windows version is not supported or a library did not export a necessary
		function.

	ERROR_ACCOUNT_RESTRICTION
		A process in session 0 cannot call CAD on Windows >= VISTA.

	ERROR_ACCESS_DISABLED_BY_POLICY
		One or more policies to enable CAD could not be enabled. This usually
		occurs if the caller has not enough rights to do this. Call the function
		with administrative rights again.

	ERROR_SERVICE_REQUEST_TIMEOUT
		The Terminal Service could not be restarted. Usually this means that a timeout
		occurred because the service did not respond.

	ERROR_SERVICE_NOT_ACTIVE
		The Terminal Service was not running but also could not be started.
		Maybe the service was disabled by an Administrator or the caller has not enough
		rights to start it.

}
function SASLibEx_SendSASAsUser(Options : DWORD) : BOOL; stdcall; external;



{
SASLibEx_UnlockWorkstation unlocks the workstation of a specific session.
The user doesn't have to enter a password or hit CAD.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  A workstation can be locked using the function SASLibEx_LockWorkstation.

  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
	 If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_UnlockWorkstation(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_LockWorkstation locks the workstation of a specific session
so the user has to enter her password.
On some systems the user also have to hit the CAD sequence to get access again.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  A locked workstation can be unlocked using the function SASLibEx_LockWorkstation.
   The user doesn't have to enter a password or hit CAD.

  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.


  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
	 SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_LockWorkstation(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_EnterSecureDesktop switches to the secure desktop in a specific session.
The secured desktop can be used to show a security relevant user interface - like password input.

Warning: By default the secured desktop is empty and the user cannot get back by hand.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  A secured desktop can be left by calling SASLibEx_LeaveSecureDesktop.

  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_EnterSecureDesktop(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_LeaveSecureDesktop switches to the default desktop in a specific session.
The secured desktop can be used to show a security relevant user interface - like password input.
Warning: By default the secured desktop is empty and the user cannot get back by hand.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  A secured desktop can be switchted to by calling SASLibEx_EnterSecureDesktop.

  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_LeaveSecureDesktop(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_CancelUACRequest cancels an UAC prompt. The UAC request will not be processed.
This function simulates a user who clicks the Cancel button of the UAC prompt.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
	 The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_CancelUACRequest(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_CancelSAS

TBD

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_CancelSAS(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_EnableCAD enables the CAD sequence that was previously disabled by SASLibEx_DisableCAD.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
     The privilege TCB is not available.

}
function SASLibEx_EnableCAD(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_DisableCAD disables the CAD sequence so the system does no more
respond to Ctrl+Alt+Del.

Parameters:
  SessionID Terminal session that should be used by this function. This parameter
  must be SAS_CONSOLE_SESSION (-1) for a SAS library that does support only
  console session.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  This function needs at least Windows Vista.

  This function needs to run as SYSTEM.

  The following return values of GetLastError are possible. However there
  can be additional ones.

  ERROR_ACCESS_DENIED (5)
	 Usually this means that the process does not run as SYSTEM.

  ERROR_REQUEST_OUT_OF_SEQUENCE (776)
     SASLibEx_Init must be called first.

  ERROR_CALL_NOT_IMPLEMENTED
     If the function is not supported by the library.

   ERROR_OLD_WIN_VERSION
     The Windows version is not supported or a library did not export a necessary
     function.

  ERROR_INVALID_PARAMETER
     The library supports only console session and any other value than SAS_CONSOLE_SESSION
     is set in parameter SessionID.

  ERROR_FILE_NOT_FOUND
      The given SessionID is not available.

  ERROR_TOKEN_ALREADY_IN_USE
	  The current thread is impersonated (thread token). The thread must not have an attached token.
	  You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

  ERROR_PRIVILEGE_NOT_HELD
	 The privilege TCB is not available.

}
function SASLibEx_DisableCAD(SessionID : DWORD) : BOOL; stdcall; external;



{
SASLibEx_ConsoleConnect connects the given session to the console.

Parameters
  ForceRdpDisconnect
	Set to true to disconnect the user on the session set by SourceSession.
  SourceSession
	Defines the session that should be connected to console.
  Password [OPTIONAL]
	Defines an password that must be supplied if the caller is not SYSTEM.
	For caller as SYSTEM this parameter should be an empty string or nil.
	The password is the login password of the user of SourceSession.


Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  This function works on Windows XP Sp1 and later.

  Disconnecting a user does not log off a user.

  The caller has to make sure the password is correct. If the password is incorrect
  and a user is active in the given session, the user is still disconnected but
  the session is not connected to console.

  The switched session is not secured. A user who switches to the given session has full
  access to the desktop. It is on the behalf of the caller to lock the workstation to reauthenticate
  the user.


  The following return values of GetLastError are possible. However there
  can be additional ones.

	ERROR_ACCESS_DENIED (5)
		The process is running not as SYSTEM and the password parameter is not nil or empty. Only
		SYSTEM can run without a password. Empty user passwords are not supported.

	ERROR_REQUEST_OUT_OF_SEQUENCE (776)
		SASLibEx_Init must be called first.

	ERROR_CALL_NOT_IMPLEMENTED
		If the function is not supported by the library.

	ERROR_OLD_WIN_VERSION
		The Windows version is not supported or a library did not export a necessary
		function. Only Windows 2000,XP and Server 2000,2003 are supported.

	ERROR_TOKEN_ALREADY_IN_USE
		The current thread is impersonated (thread token). The thread must not have an attached token.
		You need to call RevertToSelf() first, then call this function and afterwards re-impersonate the thread.

	ERROR_CTX_WINSTATION_ALREADY_EXISTS
		ForceRdpDisconnect is FALSE and a user is still connected to the session in
		SourceSession.

	ERROR_CTX_WINSTATION_NOT_FOUND
		The session SourceSession is not in a valid state
		(WTSActive or WTSConnected or WTSDisconnected or WTSShadow or WTSListen)

	ERROR_CTX_WINSTATION_BUSY
		The console session is currently not established. Try again later.

	ERROR_TS_INCOMPATIBLE_SESSIONS
		The session SourceSession is already connected to console.

	ERROR_CTX_WINSTATION_ACCESS_DENIED
		In Vista and newer a connection to session 0 (service session) is not possible.

	ERROR_CTX_SESSION_IN_USE
		The session SourceSession could not be disconnected. A timeout exceeded.

}
function SASLibEx_ConsoleConnect(ForceRdpDisconnect : BOOL; SourceSession : DWORD; Password : PWideChar) : BOOL; stdcall; external;


{
SASLibEx_LogoffSession logs a session off.

Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
  This function works on Windows XP Sp1 and later.

  Only administrators can log off foreign users.

  The following return values of GetLastError are possible. However there
  can be additional ones.


	ERROR_REQUEST_OUT_OF_SEQUENCE (776)
		SASLibEx_Init must be called first.

	ERROR_CALL_NOT_IMPLEMENTED
		If the function is not supported by the library.

	ERROR_OLD_WIN_VERSION
		The Windows version is not supported or a library did not export a necessary
		function. Only Windows XP and later are supported.

	ERROR_FILE_NOT_FOUND
		The given SessionID is not available.


}
function SASLibEx_LogoffSession(SessionID : DWORD) : BOOL; stdcall; external;


{
SASLibEx_IsDesktopLocked returns whether the desktop on a given session is locked or not.

Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
	This function doesn't need any special privilege.

	A desktop is considered locked when a user is logged on but the winlgoon desktop
	is shown with a password input field. The UAC desktop is not a locked desktop
	because they can be left by canceling.

	The following return values of GetLastError are possible. However there
	can be additional ones.

	ERROR_REQUEST_OUT_OF_SEQUENCE (776)
		SASLibEx_Init must be called first.

	ERROR_CALL_NOT_IMPLEMENTED
		If the function is not supported by the library.

	ERROR_OLD_WIN_VERSION
		The Windows version is not supported or a library did not export a necessary
		function. Only Windows Vista and later are supported.

	ERROR_INVALID_PARAMETER
		1. Parameter bLocked is nil.
		2. Parameter SessionID is not SAS_CONSOLE_SESSION (only console session license)

	ERROR_FILE_NOT_FOUND
		The given SessionID is not available.


}
function SASLibEx_IsDesktopLocked(SessionID : DWORD; out bLocked : BOOL) : BOOL; stdcall; external;



{
SASLibEx_GetSessionUserName retrieves domain and username of the user logged onto a session.

Parameters:
	SessionID
		A sessionID to be used to retrieve the username and domain. The session must be active;
		otherwise an error will be returned.

	sUserName, sDomain
		A pointer to a unicode string. The unicode string itself must be initialized to nil; otherwise the function
		fails with the error ERROR_INVALID_PARAMETER.
		The returned pointer must be freed with LocalFree on success.

		Example
		<code>
      var
			  pszUserName, pszDomain : PWideChar;
      begin
			  pszUserName := nil;
        pszDomain := nil;

			  if SASLibEx_GetSessionUserName(1, &pszUserName, &pszDomain) then
        begin
          LocalFree(Cardinal(pszUserName));
          LocalFree(Cardinal(pszDomain));
        end;
		</code>

Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
	The following return values of GetLastError are possible. However there
	can be additional ones.

	ERROR_REQUEST_OUT_OF_SEQUENCE (776)
		SASLibEx_Init must be called first.

	ERROR_CALL_NOT_IMPLEMENTED
		If the function is not supported by the library.

	ERROR_OLD_WIN_VERSION
		The Windows version is not supported or a library did not export a necessary
		function. Only Windows Vista and later are supported.

	ERROR_INVALID_PARAMETER
		1. Parameter sUserName or sDomain is not nil.
		2. Parameter SessionID is not SAS_CONSOLE_SESSION (only console session license)

	ERROR_FILE_NOT_FOUND
		The given SessionID is not available.

}
function SASLibEx_GetSessionUserName(SessionID : DWORD;  out UserName : PWideChar; out Domain : PWideChar) : BOOL; stdcall; external;

{SASLibEx_GetSessionUserNameHelper is a wrapper fo SASLibEx_GetSessionUserName that
can be used in Delphi.
}
function SASLibEx_GetSessionUserNameHelper(SessionID : DWORD;  out UserName : WideString; out Domain : WideString) : BOOL;


procedure GetVersion(var hi, lo, flag : DWORD);
function GetSupportedFeatures() : TStringList;



implementation
uses ComObj;

{$OPTIMIZATION OFF}
{$STACKFRAMES OFF}

const
  //ntdll = 'ntdll.dll';
  ntdll = 'kernel32.dll';
  advapi32 = 'Advapi32.dll';

type
  Size_T = Cardinal;

var
  __vsnwprintf_: Pointer;
  __vsnprintf_: Pointer;


{Includes the obj file}
{$I SasLibEx.inc}

function SASLibEx_Init() : BOOL; stdcall; external;
function SASLIBExIn_ExceptionTrap() : Integer; stdcall; external;


{$IFNDEF JWAWINDOWS}
function ConvertStringSidToSidW(StringSid: LPCWSTR; var Sid: PSID): BOOL; stdcall; external advapi32 name 'ConvertStringSidToSidW';


procedure GetProcedureAddress(var P: Pointer; const ModuleName, ProcName: AnsiString); forward;


{$ENDIF}


function SASLibEx_InitLib : BOOL;
begin
  GetProcedureAddress(__vsnwprintf_, 'msvcrt.dll', '_vsnwprintf');
  GetProcedureAddress(__vsnprintf_, 'msvcrt.dll', '_vsnprintf');

  result := SASLibEx_Init();
end;


procedure CheckSAS(const Result : BOOL);
begin
  if not Result then
    RaiseLastOSError;
 end;

procedure GetVersion(var hi, lo, flag : DWORD);
var v : DWORD;
begin
  v := SASLibEx_GetVersion;

  flag := 0;
  if v and $80000000 = $80000000 then
    flag := 1;
  v := v and not $80000000;
  hi := v shr 16;
  //lo := v shl 16 shr 16;
  lo := v and not (hi shl 16);
end;

function GetSupportedFeatures() : TStringList;
var Features : INT64;
begin
  Features := SASLibEx_GetFeatures;
  result := TStringList.Create;
  if Features and $1 = $1 then
    result.Add('Multiple session support')
  else
    result.Add('Console session support');

  if Features and $2 = $2 then
    result.Add('Send SAS support');

  if Features and $4 = $4 then
    result.Add('Lock workstation support');

  if Features and $8 = $8 then
    result.Add('Unlock workstation support');

  if Features and $10 = $10 then
    result.Add('Logoff user support');

  if Features and $20 = $20 then
    result.Add('Wait unlock support');

  if Features and $40 = $40 then
    result.Add('Switch logon support');

  if Features and $80 = $80 then
    result.Add('Cancel UAC request');

  if Features and $100 = $100 then
    result.Add('Cancel SAS');

  if Features and $200 = $200 then
    result.Add('Enable/Disable CAD');

  if Features and $400 = $400 then
    result.Add('Session connect');
end;

{$IFNDEF JWAWINDOWS}
procedure GetProcedureAddress(var P: Pointer; const ModuleName, ProcName: AnsiString);
var
  ModuleHandle: HMODULE;
begin
  if not Assigned(P) then
  begin
    ModuleHandle := GetModuleHandleA(PAnsiChar(AnsiString(ModuleName)));
    if ModuleHandle = 0 then
    begin
      ModuleHandle := LoadLibraryA(PAnsiChar(ModuleName));
      if ModuleHandle = 0 then
        raise Exception.CreateFmt('Library %s not found.', [ModuleName]);
    end;
    P := Pointer(GetProcAddress(ModuleHandle, PAnsiChar(ProcName)));
    if not Assigned(P) then
      raise Exception.CreateFmt('Procedure not found %s in %s (%s)', [ModuleName, ProcName, SysErrorMessage(GetLastError)]);
  end;
end;
{$ENDIF}


function SASLibEx_GetSessionUserNameHelper(SessionID : DWORD; out UserName : WideString; out Domain : WideString) : BOOL;
var sUserName, sDomain : PWideChar;
begin
  sUserName := nil;
  sDomain := nil;

  result := SASLibEx_GetSessionUserName(SessionID, sUserName, sDomain);
  if result then
  begin
    UserName := WideString(sUserName);
    Domain := WideString(sDomain);

    LocalFree(HLOCAL(sUserName));
    LocalFree(HLOCAL(sDomain));
  end
  else
  begin
    UserName := '';
    Domain := '';
  end;
end;

var
  Crit : TCriticalSection;

procedure _SASLIBExIn_EnterExceptionHandler;
begin
  Crit.Enter;
end;

function _SASLIBExIn_ExceptionHandler : Integer;
begin
 try
   try
      Result := SASLIBExIn_ExceptionTrap;
   except
      on e : EOleException do
        result := E.ErrorCode;
      on e : EExternalException do
        result := ERROR_INVALID_DATA;  //tested by CW: midl_MIDL_PROC_FORMAT_STRING was changed
      on e : EAccessViolation do
        result := ERROR_INVALID_BLOCK;
      on e : Exception do
        result := ERROR_INVALID_ACCESS;
    end;
 finally
   Crit.Leave;
 end;
end;


function StrCpyW(psz1, psz2: PWideChar): PWideChar; stdcall; external 'shlwapi.dll' name 'StrCpyW';

function _wcscpy(
   strDestination : PWideChar;
   strSource : PWideChar) : PWideChar; cdecl;
begin
  result := StrCpyW(strDestination, strSource);
end;

function _malloc(Size: Cardinal): Pointer; cdecl;
begin
  GetMem(Result, Size);
end;

function _strlen ( str : PChar) : DWORD;
begin
  result := StrLen(str);
end;

function _free(P : Pointer): BOOL; cdecl;
begin
  FreeMem(P);
  Result := TRUE;
end;

function _memset ( Ptr : Pointer; Value : Integer; Num : Size_T) : Pointer; cdecl;
begin
  ZeroMemory(Ptr, Num);
  result := ptr;
end;


procedure __vsnwprintf;
asm
   jmp dword ptr __vsnwprintf_;
end;


procedure __vsnprintf;
asm
   jmp dword ptr __vsnprintf_;
end;



function _getwc(s : Pointer) : Integer; cdecl;
begin
  result := 0;
end;


function __fgetc(s : Pointer) : Integer; cdecl;
begin
  result := 0;
end;

function __streams(s : Pointer) : Integer; cdecl;
begin
  result := 0;
end;

function _memcmp(P1,P2 : Pointer; D3 : DWORD): DWORD; cdecl;
begin
  Result := DWORD(CompareMem(P1,P2, D3));
end;


{$IFNDEF JWA}

function VerifyVersionInfoA( lpVersionInformation: Pointer;
  dwTypeMask: DWORD; dwlConditionMask: int64): BOOL; stdcall; external ntdll;
function VerifyVersionInfoW( lpVersionInformation: Pointer;
  dwTypeMask: DWORD; dwlConditionMask: int64): BOOL; stdcall; external ntdll;
function VerifyVersionInfo( lpVersionInformation: Pointer;
  dwTypeMask: DWORD; dwlConditionMask: int64): BOOL; stdcall; external ntdll;

function  VerSetConditionMask(
    ConditionMask : int64;
    dwTypeMask : DWORD;
    Condition : BYTE
  ): int64; stdcall; external ntdll;

{$ENDIF JWA}

initialization
  Crit := TCriticalSection.Create;


finalization
  FreeAndNil(Crit);

end.





































