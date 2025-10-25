%Using .NET from within MATLAB
%
%   You can construct .NET objects from within MATLAB by using the
%   name of their class to instantiate them. For example:
%
%    >> obj = System.String("Hello, .NET!")
%
%    obj =
%
%    Hello, .NET!
%
%   For more details, you can use 'help' with these commands or refer to
%   the documentation for details.
%
%   .NET Interface is supported on all platforms.
%
%   NET.addAssembly            - Makes a .NET assembly visible to MATLAB.
%   NET.createArray            - Creates a single or multi-dimensional.NET
%                                array in MATLAB.
%   NET.createGeneric          - Creates an instance of a .NET generic type.
%   NET.invokeGenericMethod    - Invokes generic methods in a .NET class.
%   NET.GenericClass           - Represents parameterized generic type definitions.
%   NET.NetException           - Represents an exception thrown from .NET.
%   NET.setStaticProperty      - Sets a static property or field of a .NET type.
%   NET.disableAutoRelease     - Locks a .NET object representing a Runtime
%                                Callable Wrapper (COM Wrapper).
%   NET.enableAutoRelease      - Unlocks a .NET object representing a Runtime
%                                Callable Wrapper (COM Wrapper) if it was
%                                locked using NET.disableAutoRelease.
%   NET.isNETSupported         - Checks if a supported version of .NET is installed
%                                based on the current settings.
%   NET.interfaceView          - Creates an explicit view of a .NET object 
%                                as one of its explicitly implemented interfaces.
%   dotnetenv                  - Allows changing the .NET version to .NET Framework
%                                or .NET (formerly known as .NET Core).
%   NETEnvironment             - Contains information about the current .NET environment.

%   Copyright 2009-2024 The MathWorks, Inc. 

