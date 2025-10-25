function tagMap = determineTagsFor(testClass, testMethods)
% This function is undocumented and may change in a future release.

% Only pick up tags for a method's defining class and its superclasses.

% Copyright 2016-2021 The MathWorks, Inc.

import matlab.unittest.internal.getAllTestCaseClassesInHierarchy;

if isempty(testMethods)
    tagMap = containers.Map;
    return;
end

tags = {testMethods.TestTags}.';
tags = cellfun(@toRow, tags, UniformOutput=false);

superclasses = getAllTestCaseClassesInHierarchy(testClass);
superclassTags = {superclasses.TestTags};
nonEmptyTagMask = ~cellfun(@isempty, superclassTags);
superclasses = superclasses(nonEmptyTagMask);
superclassTags = superclassTags(nonEmptyTagMask);
superclassTags = cellfun(@toRow, superclassTags, UniformOutput=false);

if ~isempty(superclassTags)
    definingClasses = vertcat(testMethods.DefiningClass);
    mask = repmat(definingClasses, 1, numel(superclasses)) <= repmat(superclasses, numel(definingClasses), 1);
    superclassTags = repmat(superclassTags, numel(definingClasses), 1);
    [superclassTags{~mask}] = deal({});
    combinedTags = [superclassTags, tags];
    tags = arrayfun(@(row)horzcat(combinedTags{row,:}), 1:height(combinedTags), UniformOutput=false);
end

tags = cellfun(@unique, tags, UniformOutput=false);

methodNames = {testMethods.Name};
tagMap = containers.Map(methodNames, tags);
end

function arr = toRow(arr)
arr = reshape(arr, 1, []);
end
