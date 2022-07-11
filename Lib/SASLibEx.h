/*SASLibEx Library for C

Copyright 2009 Weijnen ICT Diensten, All Rights Reserved.

This source code, hereafter referred to as the code, may not be distributed,
modified or used in any way, without explicit written permission.

This software is provided ‘as-is’, without any express or implied warranty.
In no event will the author be held liable for any damages arising from the
use of this software.

File Version 2.3

Changelog:
  21.01.2012 - 2.3 - Bugfix release
  20.05.2010 - 2.1 - Delphi and C++ Builder extension added, bugfixes
  15.05.2010 - 2.0 - Second major release
  07.10.2009 - 1.904 - Fixed handle leaks.
  01.07.2009 - 1.903 - Delphi support changed. Bugfixes.
  20.05.2009 - 1.823 - Fixed minor bugs. Updated docs.
  11.04.2009 - 1.800 - Added more functions. Made Delphi obj compatible.
  04.04.2009 - 1.176 - Fixed minor bugs and features in versioning. Fixed wrong docs.
  10.03.2009 - 1.170 - Fixed some minor bugs. Added docs.
  08.02.2009 - 1.0 - First release
*/
#ifndef SASLIBEX_H
#define SASLIBEX_H

#pragma once

#include "windows.h"


#ifndef SAS_FEATURE_BITS
//only console session?
#define BIT_MULTIPLE_SESSIONS 0x1
//Secure Attention Sequence feature
#define BIT_FEATURE_SAS 0x2
//Lock workstation feature
#define BIT_FEATURE_LOCK 0x4
//Unlock workstation feature
#define BIT_FEATURE_UNLOCK 0x8
//Logoff user feature
#define BIT_FEATURE_LOGOFF 0x10
//Wait until unlocked desktop feature
#define BIT_FEATURE_WAIT_UNLOCK 0x20
//Switch to and from secure desktop feature
#define BIT_FEATURE_SWITCH_LOGON 0x40

#define BIT_FEATURE_CANCEL_UAC_REQUEST 0x80
#define BIT_FEATURE_CANCEL_SAS 0x100
#define BIT_FEATURE_DISENABLE_CAD 0x200
#define BIT_FEATURE_SESSION_CONNECT 0x400
#define BIT_FEATURE_SESSION_USERNAME 0x800 
#define BIT_FEATURE_IS_DESKTOP_LOCKED 0x1000 
#define BIT_FEATURE_SASASUSER 0x2000

#endif //SAS_FEATURE_BITS


/**
SAS_CONSOLE_SESSION is used for the dynamic replacement of the
console session ID in all SASLibEx functions.
If this value is used the call is executed in the console session
regardless of the process session id.
If the library license does not permit multiple session, this
value is mandatory for all SASLibEx functions which receives a session id;
otherwise they will fail.
*/
#define SAS_CONSOLE_SESSION (DWORD)-1


#ifdef __cplusplus
extern "C"
{
#endif


/**
SASLib_GetFeatures returns the supported features by this library
A feature is availabe if the assigned bit is set:

Use the BIT_FEATURE_XXXX constants.

*/
ULONGLONG  WINAPI SASLibEx_GetFeatures();



/**
SASLibEx_GetVersion returns the version of the library.

You can use SASLibEx_GetVersionEx for easier access.

*/
DWORD  WINAPI SASLibEx_GetVersion();



/**
SASLibEx_Init must be called before any other call of the following functions.

WARNING: Do not call this or any other SasLibEx function within DLL main. Doing so
 will lead to unexpected behavior.

Returns
  Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.

Remarks
  This function fails with return value FALSE if it is called more than once. However
  the GetLastError value is set to ERROR_SUCCESS (0). This is just a warning.

All SASLibEx_xxx functions need this call before they can be used. Exceptions are
SASLibEx_GetFeatures and SASLibEx_GetVersion;

*/
BOOL  WINAPI SASLibEx_Init();



/**
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

*/
BOOL  WINAPI SASLibEx_SendSAS(DWORD SessionID);

/**
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
	
	It cannot be called from SYSTEM and returns the error Access Denied.

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

	You can use SAS_NO_FIX if you don't want any preparation to take place.


	The following return values of GetLastError are possible. However there
	can be additional ones.

	ERROR_ACCESS_DENIED (5)
		The access was denied. This can have several reasons:
		1. If the SASLibEx license is console only and the current process 
			is not running in a console session.
		2. A policy denies access.
		3. A SYSTEM process tried to run the function.

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

*/
BOOL WINAPI SASLibEx_SendSASAsUser(DWORD Options);

/*The function tries to start the TerminalService if necessary.
It also stops it afterwards if it was not running in the beginning.
*/
#define SAS_AUTO	  0x0

/*
The function prepares the TerminalService if necessary 
but does not revert to the state in the beginning. 
*/
#define SAS_NO_REVERT 0x4000

/*
The function does not initiate a CAD. This is useful with
SAS_NO_REVERT to adapt the TerminalService for further calls.
*/
#define SAS_NO_CAD	  0x8001

/*
The function does not try to fix anything. It just initiates CAD.
*/
#define SAS_NO_FIX    0x0002 
 


/**
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

*/
BOOL  WINAPI SASLibEx_UnlockWorkstation(IN DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_LockWorkstation(DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_EnterSecureDesktop(IN DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_LeaveSecureDesktop(IN DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_CancelUACRequest(IN DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_CancelSAS(IN DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_EnableCAD(IN DWORD SessionID);



/**
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

*/
BOOL  WINAPI SASLibEx_DisableCAD(IN DWORD SessionID);



/**
SASLibEx_ConsoleConnect connects the given session to the console.

Parameters
  ForceRdpDisconnect
	Set to true to disconnect the user on the session set by SourceSession.
  SourceSession
	Defines the session that should be connected to console.
  Password [OPTIONAL]
	Defines an password that must be supplied if the caller is not SYSTEM.
	For caller as SYSTEM this parameter should be an empty string or NULL.
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
		The process is running not as SYSTEM and the password parameter is not NULL or empty. Only
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
		(WTSActive | WTSConnected | WTSDisconnected | WTSShadow | WTSListen)

	ERROR_CTX_WINSTATION_BUSY
		The console session is currently not established. Try again later.

	ERROR_TS_INCOMPATIBLE_SESSIONS
		The session SourceSession is already connected to console.

	ERROR_CTX_WINSTATION_ACCESS_DENIED 
		In Vista and newer a connection to session 0 (service session) is not possible.

	ERROR_CTX_SESSION_IN_USE
		The session SourceSession could not be disconnected. A timeout exceeded.

*/
BOOL WINAPI SASLibEx_ConsoleConnect(IN BOOL ForceRdpDisconnect, IN DWORD SourceSession, IN LPWSTR Password OPTIONAL);


/**
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
	
		
*/
BOOL  WINAPI SASLibEx_LogoffSession(IN DWORD SessionID);


/**
SASLibEx_IsDesktopLocked returns whether the desktop on a given session is locked or not.

Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.


Remarks
	This function doesn't need any special privilege.

	A desktop is considered locked when a user is logged on but the winlgoon desktop
	is shown with a password input field. The UAC (or password change) desktop is not a locked desktop
	because they can be left by canceling.

	The function will return TRUE for bLocked if the session screen shows a user and/or password prompt for credential
	validation to log on a user (but not UAC prompt).

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
		1. Parameter bLocked is NULL.
		2. Parameter SessionID is not SAS_CONSOLE_SESSION (only console session license)

	ERROR_FILE_NOT_FOUND
		The given SessionID is not available or disconnected. A disconnected session cannot be queried for its locking state.
		
*/
BOOL WINAPI SASLibEx_IsDesktopLocked(IN DWORD SessionID, OUT BOOL *bLocked);



/**
SASLibEx_GetSessionUserName retrieves domain and username of the user logged onto a session.

Parameters:
	SessionID
		A sessionID to be used to retrieve the username and domain. The session must be active;
		otherwise an error will be returned.
		
	sUserName, sDomain
		A pointer to a unicode string. The unicode string itself must be initialized to NULL; otherwise the function
		fails with the error ERROR_INVALID_PARAMETER.
		The returned pointer must be freed with LocalFree on success.

		Example
		<code>
			LPWSTR pszUserName, pszDomain;
			pszUserName = pszDomain = NULL;

			if (SASLibEx_GetSessionUserName(1, &pszUserName, &pszDomain))
			{
			    ...
				LocalFree(pszUserName);
				LocalFree(pszDomain);
			}
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
		1. Parameter sUserName or sDomain is not NULL.
		2. Parameter SessionID is not SAS_CONSOLE_SESSION (only console session license)

	ERROR_FILE_NOT_FOUND
		The given SessionID is not available.

*/
BOOL WINAPI SASLibEx_GetSessionUserName(IN DWORD SessionID, OUT LPWSTR* UserName, OUT LPWSTR* Domain);

#define SAS_OPFLAG_AUTOLOGON_DEFAULT 0x00000000
/*
SASLibEx_AutoLogonConsole tries to log on a user on the console session. It takes a username and a password to do an automatic log-on
disconnecting (but not logging off) an already logged on user.

Parameters:
	Operation
		Defines flags to be used with this function. Set this parameter to SAS_OPFLAG_AUTOLOGON_DEFAULT.
	UserName
		Defines a unicode string of the name of the user who shall be logged on. This value must not be NULL.
	Domain
		Defines a unicode string of the domain of the user. This value can be NULL if the user has an account on the local machine.
	Password
		Defines a unicode string of the user's plain password. For security reasons this value should be zeroed afterwards.
Returns
	Returns TRUE on success; otherwise FALSE. Check GetLastError for more information.

Remarks
    The function only works on the console session.

	You have to make sure that the provided login data is correct otherwise the function will return success but the user is not logged on
	and instead will see an error on the screen. Then the logon screen on console will show the user name and prompt for a password. It won't show
	the usual logon screen until the session is reset (or logged off).

	The function will not log off the user on the console but instead he will remain disconnected in the background. You can reconnect this user to the console
	by calling SASLibEx_ConsoleConnect or log off the user beforehand with SASLibEx_LogOff.
	In addition, if the user is already logged on (in another session, disconnected or connected) the user will be reconnected to the console session.

	Use WTSGetActiveConsoleSession afterwards to retrieve the new console session ID.

	If the policy "CAD required to log on" is active, the function will overcome the CAD and log on the user.

	This function will stall the current thread until the user is logged on, a time out or error occurred.

	The following return values of GetLastError are possible. However there
	can be additional ones.

	ERROR_REQUEST_OUT_OF_SEQUENCE (776)
	SASLibEx_Init must be called first.

	ERROR_CALL_NOT_IMPLEMENTED
	If the function is not supported by the library.

	ERROR_OLD_WIN_VERSION
	The Windows version is not supported or a library did not export a necessary
	function. Only Windows Vista and later are supported.

	ERROR_INVALID_LEVEL
	Parameter Operation is invalid.

	ERROR_INVALID_PARAMETER
	1. Parameter UserName is NULL.
	2. Parameter Password is NULL.

	ERROR_INVALID_USER_BUFFER
	Buffer of parameter UserName is invalid or exceeds 1024 bytes.

	ERROR_TIMEOUT
	The function tried to wait for the user to be logged on. However, the process took too long and the function returned. The state of the logon 
	process is unknown.

	On Windows XP there can also be errors from SASLibEx_LogoffSession.
*/
BOOL WINAPI SASLibEx_AutoLogonConsole(__in_opt DWORD Operation, __in LPWSTR UserName, __in_opt LPWSTR Domain, __in LPWSTR Password);


//The following structures and functions are invalid and cannot be used

#define SAS_OPFLAG_CP_DEFAULT			 0x00000000
#define SAS_OPFLAG_CP_AS_ADMIN			 0x00000002 //get admin token on >= Vista
#define SAS_OPFLAG_CP_AS_ADMIN_FAILSAFE  0x00000003 //if admin token not available -> start as user
#define SAS_OPFLAG_CP_DONT_CLOSE_HANDLES 0x00000004 //don't automatically close handles returned by CreateProcess 

#define SAS_OPFLAG_CP_VERSION_1 0x00000001
#define SAS_OPFLAG_CP_VERSION_2 0x00000002

typedef struct _SASLIBEX_STRUCT_CREATEPROCESSINSESSION {
		//Version of struct
		DWORD Version;	

		DWORD OperationFlags; //SAS_OPFLAG_CP_xxx
		DWORD SessionID; //Target session id to spawn process into

		struct {  //stuff for LsaLogonUser
			LPWSTR UserName;
			LPWSTR Domain;
			LPWSTR Password;
		} Credentials;

		struct {
			LPWSTR lpCommandLine;
			LPCWSTR lpApplicationName;

			LPSECURITY_ATTRIBUTES lpProcessAttributes;
			LPSECURITY_ATTRIBUTES lpThreadAttributes;

			DWORD dwCreationFlags;
			LPVOID lpEnvironment;
			LPCTSTR lpCurrentDirectory;

			STARTUPINFOW StartupInfo;
			PROCESS_INFORMATION ProcessInformation;
		} CreateProcess;

		/*struct {
			//stuff for LsaLogonUser
			PSID* AdditionalGroupList; 
....

		
		} Extended;
		*/
		struct {
			PHANDLE ProcessHandle;
			DWORD ProcessID;

			/*HANDLE LinkedToken;
			HANDLE Token;

			PVOID EnvironmentBlock;
			TOKEN_SOURCE TokenSource;

			//PMSV1_0_INTERACTIVE_PROFILE ProfileBuffer; 

			HANDLE Lsa;
			LUID TokenLuid;*/

		} Output;

} SASLIBEX_STRUCT_CREATEPROCESSINSESSION, *PSASLIBEX_STRUCT_CREATEPROCESSINSESSION;

//BOOL WINAPI SASLibEx_CreateProcessInSession(IN PSASLIBEX_STRUCT_CREATEPROCESSINSESSION Options);
//
////ruft SASLibEx_CreateProcessInSession mit SAS_OPFLAG_CP_AS_ADMIN auf
//BOOL WINAPI SASLibEx_CreateProcessInSessionAsAdmin(IN PSASLIBEX_STRUCT_CREATEPROCESSINSESSION Options);

/*
TODO:
Vllt noch das JWSCL ungetüm hier erstma intern einbauen, welches dann von den SASLibEx_CreateProcessInSession verwendet wird.
Später noch dann LsaLogonUser verwenden
*/


#ifdef __cplusplus
}
#endif


/**
SASLibEx_GetVersionEx returns a decoded version of the SasLibEx

Parameters:
	hi Defines a pointer to a DWORD that receives the major version. 
	lo Defines a pointer to a DWORD that receives the minor version. 
	flag Defines a pointer to a DWORD that receives the developer flag of the library. Can be NULL.

Remarks:
	If one of the parameters hi or lo is NULL none of them will be set.
	
*/
__inline void SASLibEx_GetVersionEx(DWORD *hi, DWORD *lo, DWORD *flag)
{
	DWORD dwVersion = SASLibEx_GetVersion();

	if (flag) 
	{
		if (dwVersion & (0x80000000)) 
		{
			*flag = 1;
		} 
		else 
		{
			*flag = 0;
		}
	}

	dwVersion = dwVersion & ~(0x80000000);

	if (hi && lo) 
	{
		*hi = dwVersion >> 16;
		*lo = dwVersion & ~(*hi << 16);
	}
}

#endif //SASLIBEX_H
