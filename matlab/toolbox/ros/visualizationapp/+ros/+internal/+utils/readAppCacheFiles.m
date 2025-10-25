function out = readAppCacheFiles
%readAppCacheFiles reads the content in the cache file and returns the tag,
%bookmark, visualizer type and bag path information .

%   Copyright 2023-2024 The MathWorks, Inc.

% Define the file path to the .mat file
CacheFolder = fullfile(ros.internal.utils.getCacheFolderLocation(), 'rosbagViewer');
matFilePath = fullfile(CacheFolder, 'rosbagViewerSessionMetadata.mat');

% Check if the file exists
if exist(matFilePath, 'file') ~= 2
    out = '';
    return;
end

% Load the .mat file
data = load(matFilePath);

% Initialize variables to store the results
numEntries = numel(data.BagInfo);

% Initialize cell arrays to store data
bagPaths = cell(numEntries, 1);
tags = cell(numEntries, 1);
bookmarks = cell(numEntries, 1);
visualizerTypes = cell(numEntries, 1);

% Iterate over the entries
for i = 1:numEntries
    % Construct the cache file path
    cacheFilePath = fullfile(CacheFolder, data.CacheName{i});

    % Check if the cache file exists
    if exist(cacheFilePath, 'file') ~= 2
        continue;
    end

    % Load the cache file
    cacheContent = load(cacheFilePath);

    % Store data in cell arrays
    bagPaths{i} = data.BagInfo{i};
    if isfield(cacheContent, 'Tags') && ~isempty(cacheContent.Tags)
        tags{i} = cacheContent.Tags;
    end
    if isfield(cacheContent, 'BookmarkData') && ~isempty(cacheContent.BookmarkData)
        bookmarks{i} = cacheContent.BookmarkData.Label';
    end
    if isfield(cacheContent, 'VisualizerInfo') && ~isempty(cacheContent.VisualizerInfo) && isfield(cacheContent.VisualizerInfo, 'DataType')
        visualizerTypes{i} = [cacheContent.VisualizerInfo(:).DataType];
    end
end

% Create a table from the cell arrays
out = table(bagPaths, tags, bookmarks, visualizerTypes);
end
