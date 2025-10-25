function updateBuildInfo(varargin)
%CODER.UPDATEBUILDINFO Update the RTW.BuildInfo object.
%
%  coder.updateBuildInfo('METHOD',ARGUMENTS) applies the specified METHOD
%  to the current RTW.BuildInfo object, using the specified ARGUMENTS. Each
%  of the ARGUMENTS must be a compile-time constant.
%
%  For example, to add a stack-size option to the linker command-line:
%
%    coder.updateBuildInfo('addLinkFlags','/STACK:1000000');
%
%  See also RTW.BuildInfo.addCompileFlags, RTW.BuildInfo.addLinkFlags,
%  RTW.BuildInfo.addLinkObjects, RTW.BuildInfo.addNonBuildFiles,
%  RTW.BuildInfo.addSourceFiles, RTW.BuildInfo.addSourcePaths,
%  coder.target.
%
%  This is a code generation function. In MATLAB, it is ignored.

%   Copyright 2006-2019 The MathWorks, Inc.
