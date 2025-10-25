function [mapName, relativePathToMapFile, found] = getBlockHelpMapNameAndPath(block_type)
%   This function is for internal use only. It may be removed in the future. 

%GETBLOCKHELPMAPNAMEANDPATH Doc hook for shared_positioning 

%  Copyright 2020-2021 The MathWorks, Inc.

% First column is System object name. Second column is anchor ID
blks = {...
    'fusion.internal.simulink.insSensor', 'slpositioninginssensor'; ...
   };

ii = strcmpi(block_type, blks(:,1));

if ~any(ii)
    mapName = 'User Defined';
    found = false;
else
    mapName = blks(ii,2);
    found = true;
end

mapfile = "";

% Add new product to the END of the following array.
prodlist = ["nav", "fusion", "uav", "driving"];

for ii=1:numel(prodlist)
    v = ver(prodlist(ii));
    if ~isempty(v)
        mapfile = "/" + prodlist(ii) + "/helptargets.map";
        break;
    end
end
relativePathToMapFile = char(mapfile);

