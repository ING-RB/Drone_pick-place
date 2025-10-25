function stack = trimStackStart(stack)
% This function is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2021-2023 The MathWorks, Inc.

arguments
    stack (:,1) struct
end

import matlab.buildtool.internal.getFrameworkFolder;

files = {stack.file};
buildContentFrames = ~startsWith(files, getFrameworkFolder) | isTaskSubclass(files);
firstBuildContentFrame = find(buildContentFrames, 1);
if isempty(firstBuildContentFrame)
    stack(:,:) = [];
else
    stack(1:firstBuildContentFrame-1) = [];
end
end

function tf = isTaskSubclass(files)
import matlab.automation.internal.getParentNameFromFilename;

[uniqueFiles, ~, uniqueIdx] = unique(files);

parentNames = getParentNameFromFilename(uniqueFiles);
classes = arrayfun(@meta.class.fromName, parentNames, UniformOutput=false);
results = cellfun(@(cls)~isempty(cls) && cls < ?matlab.buildtool.Task, classes);

tf = results(uniqueIdx);
end