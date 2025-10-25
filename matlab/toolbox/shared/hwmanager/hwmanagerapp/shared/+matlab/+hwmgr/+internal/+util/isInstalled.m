function out = isInstalled(basecode, varargin)
% Utility function to check if an AddOn is installed

% Copyright 2021-2024 Mathworks Inc.

% Check if a table of installed AddOns is provided
if nargin > 1 && istable(varargin{1})
    allInstalled = varargin{1};
else
    % Get the list of installed AddOns
    allInstalled = matlab.hwmgr.internal.util.getInstalled();
end

% Check if the AddOn is installed
out = ~isempty(allInstalled) && any(strcmp(allInstalled.Identifier, basecode));

end