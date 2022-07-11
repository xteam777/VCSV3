/*
This file is intended for including the library directly into your project.
It depends on the folder layout delivered to you and can be included in one of your project files.

You may also include the lib file directly into your project settings.

The following code demonstrates how to support different C++ Builder and Visual C++ versions.

Copyright 2009,2010 Weijnen ICT Diensten
Author: Christian Wimmer
Last revision date: 12.7.2010
*/
#if defined(__BORLANDC__)   //C++ Builder
	#if (__BORLANDC__ > 0x0620)
	  #pragma comment(lib, "..\\..\\Release2010\\SasLibEx 2010.lib")
	#else
	#if (__BORLANDC__ > 0x0600)
	  #pragma comment(lib, "..\\..\\Release2009\\SasLibEx 2009.lib")
	#else
	  #error Unsupported C++Builder
	#endif
	#endif
#elif defined(_MSC_VER) //MS Visual C++
	#ifdef WIN64
		//include lib file (can also be done using project settings)
		#if defined(_MSC_VER) && (_MSC_VER == 1400) //MSVC2005
			#pragma comment(lib,"..\\..\\release2005\\x64\\SASLibEx2005.lib")
		#elif defined(_MSC_VER) && (_MSC_VER == 1500) //MSVC2008
			#pragma comment(lib,"..\\..\\release2008\\x64\\SASLibEx.lib")
		#else //MSVC > 2008
			#pragma comment(lib,"..\\..\\release2010\\x64\\SASLibEx.lib")
		#endif
	#else
		//include lib file (can also be done using project settings)
		#if defined(_MSC_VER) && (_MSC_VER == 1400) //MSVC2005
			#pragma comment(lib,"..\\..\\release2005\\SASLibEx2005.lib")
		#elif defined(_MSC_VER) && (_MSC_VER == 1500) //MSVC2008
			#pragma comment(lib,"..\\..\\release2008\\SASLibEx.lib")
		#else //MSVC > 2008
			#pragma comment(lib,"..\\..\\release2010\\SASLibEx.lib")
		#endif
	#endif
#else
  #error The compiler is not supported
#endif
