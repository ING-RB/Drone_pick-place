function toolboxPath = getToolboxPath()
%GETTOOLBOXPATH Gets the path to the App Designer "toolbox" directory.
%   TOOLBOXPATH = GETTOOLBOXPATH returns string TOOLBOXPATH representing
%   the path to the App Designer "toolbox" directory.

%   Copyright 2014-2015 The MathWorks, Inc


% Determine the location of this file
%
% Ex: 
% 
%   C:\Program Files\MATLAB\toolbox\matlab\.......\getToolboxPath
absolutePathToThisFile = mfilename('fullpath');

% Determine the relative path of this file starting from the "toolbox" directory
relativePathFromToolbox = fullfile('toolbox', 'shared','appdes','services','+appdesservices','+internal','+application','getToolboxPath');

% Return the path up to the "toolbox" directory
%
% (the absolute path) - (the relative path) - 1
% 
% If App Designer is installed in MATLABROOT, then this will
% return the same path as the command MATLABROOT.
toolboxPath = absolutePathToThisFile(1:length(absolutePathToThisFile) - length(relativePathFromToolbox) - 1);