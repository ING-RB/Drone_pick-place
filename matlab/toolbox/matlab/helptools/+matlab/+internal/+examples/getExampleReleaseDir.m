function erd = getExampleReleaseDir
%

%   Copyright 2018-2020 The MathWorks, Inc.

erd = fullfile('Examples',['R' version('-release')]);
