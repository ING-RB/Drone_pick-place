function tf = preferMATLABHostCompiledLibraries()
% Return true if the generated code or this function is running on MATLAB
% host and user prefers to take advantage of MATLAB-provided precompiled libraries.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

tf = coder.internal.preferPrecompiledLibraries() && ...
    coder.internal.isTargetMATLABHost();
