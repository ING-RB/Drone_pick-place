function updateWorkspaceDropDownValue(workspaceDropDown, inputValue)

% This function updates the Value property of a WorkspaceDropDown to the specified value
%
% INPUTS:
%   workspaceDropDown (1, 1) matlab.ui.control.internal.model.WorkspaceDropDown - WorkspaceDropDown to update
%   inputValue (1, :) char - Value to set
%
% OUTPUTS:
%   None - workSpaceDropDown is a handle object

% Copyright 2020 The MathWorks, Inc.

% Populate dropdown with the current filtered workspace variables
workspaceDropDown.populateVariables();

% If inputValue is not in the workspace, append inputValue to Items and ItemsData properties
if ~any(strcmp(workspaceDropDown.ItemsData, inputValue))
    workspaceDropDown.Items = [workspaceDropDown.Items, inputValue];
    workspaceDropDown.ItemsData = [workspaceDropDown.ItemsData, inputValue];
end

% Set Value property to inputValue
workspaceDropDown.Value = inputValue;
end
