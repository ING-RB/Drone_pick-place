function enableResources(folderPaths)
% enableResources Enables specified resources with Registration Framework
%
%   matlab.internal.regfwk.enableResources(folderPaths) 
%   enables the resources with the specified folderPaths.
%
%
%   folderPaths is the list of resources to be enabled,
%   specified as an array of strings
%
%   See also: matlab.internal.regfwk.disableResources,
%   matlab.internal.regfwk.registerResources,
%   matlab.internal.regfwk.unregisterResources

% Copyright 2020 The MathWorks, Inc.
% Calls a Built-in function.
if (iscellstr(folderPaths) || ischar(folderPaths) || isstring(folderPaths)) 
    folderPathStrings = convertCharsToStrings(folderPaths);
    matlab.internal.regfwk.enableResourcesImpl(folderPathStrings);
else 
    ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'folderPaths'));
    throw(ME)
end