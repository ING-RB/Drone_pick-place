%CLIBCONFIGURATION Change execution mode of C++ library interface
%
%  [CLIBRARYCONFIGURATION] = clibConfiguration(LIBNAME) returns configuration for
%  interface to C++ library LIBNAME
%
%  [CLIBRARYCONFIGURATION] = clibConfiguration(LIBNAME,ExecutionMode=EXECUTIONMODE)
%  changes the execution mode of the library. The value can either be
%  "inprocess" or "outofprocess". The setting is persistent across MATLAB
%  sessions.
%
%  The default execution mode is inprocess and suggested for performance
%  critical use cases. Set this mode after you develop and test the
%  interface.
%
%  Use the outofprocess execution mode while testing the interface library,
%  which requires rebuilding the interface, and for debugging workflows. If
%  your C++ library requires a 3rd party library which is also shipped with
%  MATLAB, but you need a different version of the library, then set
%  execution mode to outofprocess.
%
%  CLIBRARYCONFIGURATION properties:
%  InterfaceLibraryPath - Path to the interface library
%  Libraries            - Libraries used in the build stage to build the interface library.
%  Loaded               - 1 if library is loaded, otherwise 0.
%  ExecutionMode        - inprocess for in-process execution mode
%                         or outofprocess for out-of-process execution
%                         mode.
%  ProcessID            - MATLAB process ID. If the library is not loaded, then ProcessID is not displayed.
%  ProcessName          - Process name in the registry. If the library is
%                         not loaded, then ProcessName is not displayed.
%  Examples:
%
%  Example1:
%  Suppose you have a library libnameInterface.dll in C:\work which is on
%  MATLAB path for a library libname.lib. If the library is not loaded, type:
%  configObj = clibConfiguration("libname")
%
%  configObj =
%     CLibraryConfiguration for libname with properties:
%       InterfaceLibraryPath: "C:\work"
%                  Libraries: "libname.lib"
%                     Loaded: 0
%              ExecutionMode: inprocess
%
%  Example2:
%  After you load the library, type:
%
%  configObj = clibConfiguration("libname")
%
%  configObj =
%     CLibraryConfiguration for libname with properties:
%       InterfaceLibraryPath: "C:\work"
%                  Libraries: "libname.lib"
%                     Loaded: 1
%              ExecutionMode: inprocess
%                  ProcessID: "12345"
%
%  Example3:
%  Suppose you have a library mylibInterface.dll in C:\work which is on
%  MATLAB path for a library mylib.lib and the library is not loaded.
%  To change the execution mode, type:
%
%  configObj = clibConfiguration("mylib","ExecutionMode","outofprocess")
%
%  configObj =
%     CLibraryConfiguration for mylib with properties:
%       InterfaceLibraryPath: "C:\work"
%                  Libraries: "mylib.lib"
%                     Loaded: 0
%              ExecutionMode: outofprocess
%
% Copyright 2022 The MathWorks, Inc.
