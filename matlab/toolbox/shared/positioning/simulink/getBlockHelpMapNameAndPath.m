function [mapName, relativePathToMapFile, found] = getBlockHelpMapNameAndPath(block_type)
%   This function is for internal use only. It may be removed in the future. 

%GETBLOCKHELPMAPNAMEANDPATH Doc hook for shared_positioning 

%  Copyright 2019-2023 The MathWorks, Inc.


% First column is System object name. Second column is anchor ID
blks = {...
    'fusion.simulink.imuSensor', 'slpositioningimusensor'; ...
    'fusion.simulink.ahrsfilter', 'slpositioningahrsfilter'; ...
    'fusion.internal.simulink.insSensor', 'slpositioninginssensor'; ...
    'fusion.internal.simulink.complementaryFilter', ...
    'slpositioningcomplementaryfilter'; ...
    'fusion.internal.simulink.imufilter', ...
    'slpositioningimufilter'; ...
    'fusion.internal.simulink.ecompass', ...
    'slpositioningecompass', ...
   };

ii = strcmpi(block_type, blks(:,1));

if ~any(ii)
    mapName = 'User Defined';
    found = false;
    relativePathToMapFile = '/fusion/helptargets.map'; % doesn't matter what this is because found=false.
else
    mapName = blks(ii,2);
    found = true;

    foundNav = fusion.internal.PositioningHandleBase.testLicense();

    if foundNav
        relativePathToMapFile = '/nav/helptargets.map';
    else % SFTT
        relativePathToMapFile = '/fusion/helptargets.map';
    end    

end
