function unregisterResources(folderPaths)
% unregisterResources Unregisters specified resources with Registration Framemwork
%
%   matlab.internal.regfwk.unregisterResources(folderPaths) 
%   unregisters the resources with the specified folderPaths.
%
%
%   folderPaths is the list of resources to be unregistered,
%   specified as an array of strings
%
%   See also: matlab.internal.regfwk.enableResources,
%   matlab.internal.regfwk.disableResources,
%   matlab.internal.regfwk.registerResources

% Copyright 2020 The MathWorks, Inc.
% Calls a Built-in function.

% perform validation here
if (iscellstr(folderPaths) || ischar(folderPaths) || isstring(folderPaths)) 
    folderPathStrings = convertCharsToStrings(folderPaths);
    matlab.internal.regfwk.unregisterResourcesImpl(folderPathStrings);
else 
    ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'folderPaths'));
    throw(ME)
end