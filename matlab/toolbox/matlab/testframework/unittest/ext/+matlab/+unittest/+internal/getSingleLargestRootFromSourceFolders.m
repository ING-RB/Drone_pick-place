function commonRootFolder = getSingleLargestRootFromSourceFolders(sourceFolders)
% This function is undocumented and may change in a future release.

% Copyright 2018 MathWorks Inc.

if isempty(sourceFolders)
    commonRootFolder = "";
    return;
end

% first get unique folders. This returns the paths in sorted order
sourceFolders = unique(sourceFolders);

% Take the first and the last one, strip fileseps on the right and split by filesep
% Add a trailing filesep to handle UNC paths.
first = (split(strip(sourceFolders(1),'right',filesep), filesep) + filesep);
last = (split(strip(sourceFolders(end),'right',filesep), filesep) + filesep);

% Compare them up to the size of the smallest-path (N) to find the first N matching values
sizeMin = min(numel(first), numel(last));
N = find(~[arrayfun(@strcmp, first(1:sizeMin), last(1:sizeMin)); 0], 1) - 1;

% Get the smallest common path
commonRootFolder = strjoin(first(1:N), '');
end
