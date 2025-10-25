function str = getVersionString()
%GETVERSIONSTRING Get the version string associated with the current
%process.

%   Copyright 2019-2021 The MathWorks, Inc.

str = string(version('-release'));
