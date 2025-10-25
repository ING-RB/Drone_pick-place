function setParentForWidgets(widgets,parent)
% setParentForWidgets: Helper for performing tasks in a Live Script
%   This function takes an array of WIDGETS and unparents them if their
%   Visible property is 'off' or parents them to PARENT if their Visible
%   property is 'on'
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2021 The MathWorks, Inc.

% get the visible property
visible = get(widgets,'Visible');
if iscell(visible)
    % get returns a cell array of values for an array of inputs
    visible = [visible{:}];
end
% use the visible property to decide if the widgets should be parented
[widgets(visible).Parent] = deal(parent);
[widgets(~visible).Parent] = deal([]);