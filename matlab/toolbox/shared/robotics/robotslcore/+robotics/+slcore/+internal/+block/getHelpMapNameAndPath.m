function [mapName, relativePathToMapFile, found] = getHelpMapNameAndPath(block_type, blks, tbxList)
%This function is for internal use only. It may be removed in the future.

%getHelpMapNameAndPath  Returns the mapName and the relative path to the
%   maps file for this block_type, with the mapping defined by BLKS
%
%   BLKS input:
%    First column is the "System object name", corresponding to the block,
%    Second column is the anchor ID, the doc uses for the block.
%    For core blocks, the first column is the 'BlockType'.
%
%   TBXLIST input
%    List of toolboxes to check for installation status. This input becomes
%    important if blocks are shared between different toolbox (can ship in
%    either one), so that the right MAP file is picked for the user's
%    installation.

% Copyright 2017-2020 The MathWorks, Inc.

    if nargin < 3
        % If not provided by the user, simply pick Robotics System Toolbox
        % (legacy behavior).
        tbxList = {'robotics'};
    else
        % Make sure that tbxList is always a cell array
        tbxList = cellstr(tbxList);
        for i = 1:length(tbxList)
            % The given string needs to correspond to an autonomous systems toolbox
            validatestring(tbxList{i}, {'robotics', 'ros', 'nav', 'uav'}, 'getHelpMapNameAndPath', 'tbxList');
        end
    end

    found = false;
    relativePathToMapFile = '';

    % See whether or not the block is a Robotics System Toolbox or not
    i = strcmp(block_type, blks(:,1));

    if ~any(i)
        mapName = 'User Defined';
    else
        found = true;
        mapName = blks(i,2);
    end

    if ~found
        return;
    end


    % Create function handles for license and installation checks
    licenseChecks = containers.Map;
    licenseChecks('robotics') = @robotics.internal.license.isRoboticsToolboxLicensed;
    licenseChecks('nav') = @robotics.internal.license.isNavigationToolboxLicensed;
    licenseChecks('ros') = @robotics.internal.license.isROSToolboxLicensed;
    licenseChecks('uav') = @robotics.internal.license.isUAVToolboxLicensed;

    % The block might be exposed in different toolboxes, so pick the map file
    % that corresponds to installed product.
    for i = 1:length(tbxList)
        tbx = tbxList{i};

        % If product is installed and licensed, use its map file
        if feval(licenseChecks(tbx))
            relativePathToMapFile = ['/' tbx '/helptargets.map'];
            break;
        end
    end
