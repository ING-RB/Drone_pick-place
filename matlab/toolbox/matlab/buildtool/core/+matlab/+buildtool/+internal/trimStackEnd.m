function stack = trimStackEnd(stack)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2021-2023 The MathWorks, Inc.

arguments
    stack (:,1) struct
end

import matlab.buildtool.internal.getFrameworkFolder;

runnerLocation = fullfile(getFrameworkFolder(),"core","+matlab","+buildtool","BuildRunner.m");

names = {stack.name};
runIndices = find(strcmp(names, 'BuildRunner.run'));

for idx = fliplr(runIndices)
    if startsWith(stack(idx).file, runnerLocation)
        stack(idx:end) = [];
        break;
    end
end

files = {stack.file};
buildContentFrames = ~startsWith(files, getFrameworkFolder) | isTaskSubclass(files);
lastBuildContentFrame = find(buildContentFrames, 1, "last");
if isempty(lastBuildContentFrame)
    stack(:,:) = [];
else
    stack(lastBuildContentFrame+1:end) = [];
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
