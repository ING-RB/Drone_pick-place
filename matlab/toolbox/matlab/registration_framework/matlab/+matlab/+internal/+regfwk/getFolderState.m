function folderState = getFolderState(folderPath)
% getFolderState Gets the state of the specified folder as known to RegistrationFramework
%
%   matlab.internal.regfwk.getFolderState(folderPath) 
%   Gets the state of the specified folder as known to RegistrationFramework
%
%   folderPath is the folder whose state is being queried
%   folderState is the returned state of the queried folder
%
%   See also: matlab.internal.regfwk.enableResources,
%   matlab.internal.regfwk.disableResources,
%   matlab.internal.regfwk.registerResources,
%   matlab.internal.regfwk.unregisterResources

% Copyright 2020 The MathWorks, Inc.
% Calls a Built-in function.
if (ischar(folderPath) || isstring(folderPath)) 
    folderPathString = convertCharsToStrings(folderPath);
    folderState = matlab.internal.regfwk.getFolderStateImpl(folderPathString);
else 
    ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'folderPath'));
    throw(ME)
end
