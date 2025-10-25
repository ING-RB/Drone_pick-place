function baseFolder = getBaseFolderFromParentName(parentName)
% 

% Copyright 2016-2023 The MathWorks, Inc.

import matlab.unittest.internal.whichFile;
import matlab.unittest.internal.getBaseFolderFromFilename;

baseFolder = whichFile(parentName);

% Remove namespace and class folders
baseFolder = getBaseFolderFromFilename(baseFolder);

end

