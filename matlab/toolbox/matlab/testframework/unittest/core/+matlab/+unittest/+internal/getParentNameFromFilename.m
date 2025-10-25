function parentNames = getParentNameFromFilename(filenames)
%

% This function assumes that the file corresponding to the filename is not
% in private folder

% Copyright 2014-2023 The MathWorks, Inc.

parentNames = matlab.automation.internal.getParentNameFromFilename(filenames);
end
