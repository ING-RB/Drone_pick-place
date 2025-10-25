function [mapName, relativePathToMapFile, found] = getBlockHelpMapNameAndPath(block_type)
%getBlockHelpMapNameAndPath Returns the mapName and the relative path to the maps file for this block_type

% Internal note:
%   First column is the "System object name", corresponding to the block,
%   Second column is the anchor ID, the doc uses for the block.
%   For core blocks, the first column is the 'BlockType'.

% Copyright 2024-2025 The MathWorks, Inc.
blks = {...
    'nav.slalgs.internal.TimedElasticBand' 'navtimedelasticband';
    };

    relativePathToMapFile = '/nav/helptargets.map';
    found = false;

    % See whether or not the block is an nav or built-in
    i = find(contains(blks(:,1),block_type));

    if isempty(i)
        mapName = 'User Defined';
    else
        found = true;
        mapName = blks(i,2);
    end
