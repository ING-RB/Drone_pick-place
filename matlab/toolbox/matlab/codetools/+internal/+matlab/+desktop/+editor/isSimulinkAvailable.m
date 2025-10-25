function isAvailable = isSimulinkAvailable()
%ISSIMULINKAVAILABLE A quick check to detect availability of Simulink
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.
%
%   This function is used in conjunction with getSystemObjectInfo to
%   determine if Simulink specific code insertion tools must be shown on
%   the System Object editor.

%   Copyright 2020 The MathWorks, Inc.

filepath = matlabroot + "/toolbox/simulink/simulink/Contents.m";
isAvailable = exist(filepath,'file') == 2;
end

