function setBlockPositions(varargin)
%This function is for internal use only. It may be removed in the future.

%SETBLOCKPOSITIONS Organize blocks in a library.
%
% Example: setBlockPositions(libName, params)
% If params are not passed in, this function uses the following
% defaults:
%
% params.locationX      = 100;
% params.locationY      = 100;
% params.leftMargin     = 35;
% params.topMargin      = 60;
% params.rightMargin    = 35;
% params.bottomMargin   = 25;
% params.blkMarginX     = 35;
% params.blkMarginY     = 25;
% params.blkWidth       = 110;
% params.blkHeight      = 60;
% params.numBlksInaRow  = 3;

% Copyright 2007-2024 The MathWorks, Inc.

% This file is copied from toolbox\target\supportpackages\arm_cortex_a\+codertarget\+arm_cortex_a\+blocks\setBlockPositions.m
% It is called from the preSave callback of the block library, and is used
% by all the Embedded Coder targets and Simulink Targets to set the block
% locations in the library.

% For Robotics System Toolbox, the values are hardcoded for block and
% library positions. The block positions are specified as cell array of
% positions with the same dimensions as the block arrangement in the
% library. Use the following syntax to arrange blocks and library
% robotics.sl.internal.setBlockPositions(gcs, 'Mobile Robot Algorithms', 2016);
% robotics.sl.internal.setBlockPositions(gcs, 'Robot Operating System (ROS)', 2015, 3)
% robotics.sl.internal.setBlockPositions(gcs, 'Robotics System Toolbox', 2015);

narginchk(1,4);
libName        = varargin{1};
libraryTitle   = varargin{2};
copyrightStart = varargin{3};
params = getDefaultParams(libName);
if (nargin > 3)
    params.numBlksInaRow = varargin{4};
end

% Find all blocks in the given library
blks = find_system(libName, 'SearchDepth', 1, 'type', 'block');
title = find_system(libName, 'SearchDepth', 1, 'masktype', 'Library Name');
blks = setdiff(blks, title);
if isempty(blks)
    return;
end

% Get positions of each of the blocks in the library
numBlks = length(blks);
if (numBlks == 0)
    libLocation = get_param(libName, 'Location');
    newLocation = [...
        params.locationX, ...
        params.locationY, ...
        params.locationX + libLocation(3) - liblibLocation(1), ...
        params.locationY + libLocation(4) - liblibLocation(2)];
    set_param(libName, 'Location', newLocation);
    return
end

% Sort blocks according to Y coordinates
blkPos = zeros(numBlks, 4);
for i = 1:numBlks
    blkPos(i, :) = get_param(blks{i}, 'Position');
end
[~, I] = sort(blkPos(:,2), 'ascend');
blkPos = blkPos(I);
blks   = blks(I);

% Arrange blocks. Don't change original block order. Just re-arrange
% blocks uniformly according to given parameters
numRows = ceil(numBlks / params.numBlksInaRow);
for i = 1:numRows
    numCols = getNumCols(numBlks, params.numBlksInaRow);
    numBlks = numBlks - numCols;
    
    iCol = (i-1) * params.numBlksInaRow+1:(i-1)* params.numBlksInaRow+numCols;
    colBlkPos = blkPos(iCol, 1);
    blksInRow = blks(iCol);
    [~, I] = sort(colBlkPos, 'ascend');
    
    % Feed in position sorted blocks
    blksInRow = blksInRow(I);
    for j = 1:numCols
        % Override block positions with hard-coded values
        set_param(blksInRow{j}, 'Position', params.blockPos{i,j});
    end
end

% Compute library location
numCols = getNumCols(length(blks), params.numBlksInaRow);
libLocation = [params.locationX, params.locationY, ...
    params.locationX + params.leftFudge + params.leftMargin + numCols*params.blkWidth + ...
    (numCols - 1)*params.blkMarginX + params.rightMargin, ...
    params.locationY + params.topFudge + params.topMargin  + numRows * params.blkHeight + ...
    (numRows - 1) * params.blkMarginY + params.bottomMargin];

% Override library position with hard-coded values
set_param(libName, 'Location', params.libPos);
if ~isempty(title)
    set_param(title{1}, 'position', getTitlePosition(title, libLocation));
end
set_param(libName, 'ZoomFactor', '100');

% Turn off tool bar and status bar
% g809891: These do not work in UE1
set_param(libName, 'ToolBar', 'off');
set_param(libName, 'StatusBar', 'off');

% Re-position annotations. One at the top representing the block library
% title and one at the bottom for Copyright notice
ann = find_system(gcs, 'FindAll', 'on', 'type', 'annotation');
if isempty(ann)
    ann(1) = add_block('built-in/Note', [gcs, '/TBF'], 'Position', [10 10]);
    ann(2) = add_block('built-in/Note', [gcs, '/TBF1'], 'Position', [10 10]);
elseif (numel(ann) == 1)
    ann(2) = add_block('built-in/Note', [gcs, '/TBF'], 'Position', [10 10]);
elseif (numel(ann) > 2)
    delete(ann(3:end));
end

% Compute library dimensions
libHeight = params.topMargin + ...
    numRows * params.blkHeight + ...
    (numRows-1) * params.blkMarginY;

% Set annotation for the title
set_param(ann(1), ...
    'Name', libraryTitle, ...
    'Position', [params.titlePos, round(params.topMargin / 2)], ...
    'FontName', 'Arial', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

% Set title & position for Copyright notice
tmp = clock;
if (copyrightStart >= tmp(1))
    cpText = ['Copyright ', num2str(copyrightStart), ...
        ' The MathWorks, Inc.'];
else
    cpText = ['Copyright ', num2str(copyrightStart), '-', num2str(tmp(1)), ...
        ' The MathWorks, Inc.'];
end
set_param(ann(2), ...
    'Name', cpText, ...
    'Position', [params.copyrightPos, libHeight + round(params.bottomMargin/3)], ...
    'FontName', 'Arial', ...
    'FontSize', 10, ...
    'FontWeight', 'auto');


%--------------------------------------------------------------------------
function numCols = getNumCols(numBlks, numBlksInaRow)

if (numBlks >= numBlksInaRow)
    numCols = numBlksInaRow;
else
    numCols = numBlks;
end

% -------------------------------------------------------------------------
function pos = getTitlePosition(title, libLocation)
titlepos = get_param(title{1}, 'position');
libwidth = libLocation(3) - libLocation(1);
titlewidth = titlepos(3) - titlepos(1);
titleheight = titlepos(4) - titlepos(2);
x1 = (libwidth - titlewidth)/2;
y1 = (60 - titleheight)/2;
x2 = x1 + titlewidth;
y2 = y1 + titleheight;
pos = [x1 y1 x2 y2];

% -------------------------------------------------------------------------
function params = getDefaultParams(libName)

params.locationX      = 100;
params.locationY      = 100;
params.leftMargin     = 35;
params.leftFudge      = 60;
params.topMargin      = 60;
params.topFudge       = 80;
params.rightMargin    = 35;
params.bottomMargin   = 195;
params.blkMarginX     = 35;
params.blkMarginY     = 25;

switch libName
    case 'robotalgslib'
        params.blkWidth       = 140;
        params.blkHeight      = 75;
        params.numBlksInaRow  = 1;
        params.titlePos       = -184;
        params.copyrightPos   = -184;
        params.blockPos       = {[-260 60 -120 135], [-85 60 55 135]};
        params.libPos         = [100 100 560 540];
    case 'robotlib'
        params.blkWidth       = 130;
        params.blkHeight      = 65;
        params.numBlksInaRow  = 3;
        params.titlePos       = -10;
        params.copyrightPos   = -5;
        params.blockPos       = {[-130 65 0 130], [35 65 165 130], [200 65 330 130]; ...
            [-130 155 0 220], [35 155 165 220], []};
        params.libPos         = [100 100 690 590];
    case 'robotsyslib'
        params.blkWidth       = 130;
        params.blkHeight      = 65;
        params.numBlksInaRow  = 2;
        params.titlePos       = -122;
        params.copyrightPos   = -126;
        params.blockPos       = {[-180 60 -50 135], [-15 60 115 135]};
        params.libPos         = [100 100 560 540];
    case 'robotInternalSystemLib'
        params.blkWidth       = 130;
        params.blkHeight      = 65;
        params.numBlksInaRow  = 2;
        params.titlePos       = -122;
        params.copyrightPos   = -126;
        params.blockPos       = {[-180 60 -50 135], [-15 60 115 135]};
        params.libPos         = [100 100 560 540];
end

%[EOF]
