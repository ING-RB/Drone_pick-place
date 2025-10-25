function root = cacheRoot(planRoot)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2021-2022 The MathWorks, Inc.

arguments
    planRoot (1,1) string {mustBeNonmissing}
end

verRoot = extractBefore(version(), " ");
root = fullfile(planRoot, ".buildtool", verRoot);
end