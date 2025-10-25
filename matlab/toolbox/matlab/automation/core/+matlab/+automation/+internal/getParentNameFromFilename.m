function parentNames = getParentNameFromFilename(filenames)
%

% This function assumes that the file corresponding to the filename is not
% in private folder

% Copyright 2014-2023 The MathWorks, Inc.

import matlab.unittest.internal.getBaseFolderFromFilename;

filenames = string(filenames);

folderParts = getBaseFolderFromFilename(filenames);
[parentRoots, shortNames] = fileparts(filenames);
packagePortionParts = parentRoots.extractAfter(strlength(folderParts));

parentNames = shortNames;

hasPackageFolder = contains(packagePortionParts, "+");
hasClassFolder = contains(packagePortionParts, "@");
hasEither = hasPackageFolder | hasClassFolder;
packageOnly = hasPackageFolder & ~hasClassFolder;

parentNames(hasEither) = packagePortionParts(hasEither).replace(filesep + ["@","+"], ".").extractAfter(1);
parentNames(packageOnly) = parentNames(packageOnly) + "." + shortNames(packageOnly);
end


% LocalWords:  strlength
