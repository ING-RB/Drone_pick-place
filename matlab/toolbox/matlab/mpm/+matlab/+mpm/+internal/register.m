%   REGISTER Register location as package
%   matlab.mpm.internal.register(packageLocation1, packageLocation2 ...)
%   matlab.mpm.internal.register(option1, option2 ..., ...)
%
%   Registers one or more locations "in-place" without copying to the MATLAB
%   managed installation root. packageLocation must be a path to the folder
%   containing the package. Register will not install/register any declared dependencies,
%   however, if there exists a dependency pre-installed in the system that
%   satisfies the dependency specifier, that will be used.
%
%   The specified packages are added to the path. MATLAB will obeserve changes
%   to the package's structure and definition file.
%
%   matlab.mpm.internal.register takes following options:
%       -frozen                 Changes to the package's structure and
%                               definition file are not observed
%       -temporary              Registration will not persist between sessions

%   Copyright 2023 The MathWorks, Inc. Built-in function.
