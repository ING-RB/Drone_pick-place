function rootDir = getSensorRootDir()
% GETSENSORROOTDIR return the root directory of sensor component

% Copyright 2020 The MathWorks, Inc.

rootDir = fileparts(strtok(mfilename('fullpath'), '+'));
end

