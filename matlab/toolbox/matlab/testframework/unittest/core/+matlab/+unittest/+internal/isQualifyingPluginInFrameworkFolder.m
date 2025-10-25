function mask = isQualifyingPluginInFrameworkFolder(files)
% This function is undocumented.

% Copyright 2015-2020 The MathWorks, Inc.

mask = string(files).startsWith(matlab.unittest.internal.getFrameworkFolder + filesep);
mask(mask) = isQualifyingPluginSubclass(files(mask));
end

function bools = isQualifyingPluginSubclass(filenames)
import matlab.unittest.internal.getParentNameFromFilename;

[uniqueFiles, ~, uniqueIdx] = unique(filenames);

parentNames = getParentNameFromFilename(uniqueFiles);
classes = arrayfun(@meta.class.fromName, parentNames, "UniformOutput",false);
results = cellfun(@(cls)~isempty(cls) && cls < ?matlab.unittest.plugins.QualifyingPlugin, classes);

bools = results(uniqueIdx);
end

% LocalWords:  bools cls
