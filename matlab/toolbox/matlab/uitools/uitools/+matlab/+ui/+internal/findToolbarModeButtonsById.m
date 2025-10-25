function out = findToolbarModeButtonsById(toolbarChildren,id)
% This function is undocumented and will change in a future release

% Returns objects where the tag or toolid appdata matches the specified id. 
% This is used by uigettool and implementations of uimodes to find mode toolbar
% buttons in standard figure or in GUIDE

%   Copyright 2019 The MathWorks, Inc.

out = [];
for i=1:length(toolbarChildren)
    % getappdata expects a handle object. Some object in the cameratoolbar
    % are not handle objects so when it is visible, and rotate is activated,
    % this will error g2054396
    if ishandle(toolbarChildren(i))
        toolid = getappdata(toolbarChildren(i),'toolid');
        if isequal(get(toolbarChildren(i),'Tag'), id) || isequal(toolid, id)
            out = [out; toolbarChildren(i)]; %#ok<AGROW>
        end
    end
end