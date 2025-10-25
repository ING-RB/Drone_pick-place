function rootDir = getEmbeddedUtilitesRootDir()
% GETSPPKGROOTDIR Return the root directory of this component

% Copyright 2021 The MathWorks, Inc.

rootDir = fileparts(strtok(mfilename('fullpath'), '+'));
end