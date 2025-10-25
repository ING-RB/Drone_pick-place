function classNames = functionhintsfunc(methodName)
% This undocumented function may be removed in a future release.

% UTGETCLASSESFORMETHOD  Utility function used by Function Hints for
% obtaining the class names for a function/method on the MATLAB path

%   Copyright 1984-2022 The MathWorks, Inc.

[pathNames, comments] = which("-all", methodName);

% filter case insensitive matches
[~, methodNames] = fileparts(string(pathNames));
% first find the names that aren't exactly equal
mismatches = methodNames ~= methodName;
% then find the ones on that list by the ones that are case mismatches
mismatches(mismatches) = strcmpi(methodNames(mismatches), methodName);
comments(mismatches) = [];

% the comments say ".... <classname> method"
classesWithMethod = regexp(comments, "\w+(?= method$)", "match", "once");
[functionsInMem, ~, classesInMem] = inmem("-completenames");
atDirsInMem = functionsInMem(~contains(functionsInMem, "+") & count(functionsInMem, "@")==1);
atClassesInMem = unique(extractBetween(atDirsInMem, '@', filesep));
classesInMem = union(atClassesInMem, classesInMem);
classNames = intersect(classesWithMethod, classesInMem);

% discard excluded classes
classNames = setdiff(classNames, {'mtree', 'opaque'});

% discard hidden classes
hiddenClasses = false(size(classNames));
for i = 1:numel(classNames)
    hiddenClasses(i) = matlab.lang.internal.introspective.isHiddenClass(classNames{i});
end
classNames(hiddenClasses) = [];
