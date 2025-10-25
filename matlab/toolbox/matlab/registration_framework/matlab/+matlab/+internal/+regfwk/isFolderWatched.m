function isWatched = isFolderWatched(folderPath)
% isFolderWatched Checks whether the provided folder is being watched for any metadata changes
%
%   matlab.internal.regfwk.isFolderWatched(folderPath) 
%   Checks whether the provided resources folder is being watched for any changes to metadata files inside by the Registration Framework.
%
%
%   folderPath is the list of resources to be checked,
%   specified as an array of strings
%
%   See also: matlab.internal.regfwk.enableFilesystemWatching,
%   matlab.internal.regfwk.disableFilesystemWatching

% Copyright 2023 The MathWorks, Inc.
% Calls a Built-in function.
if (ischar(folderPath) || isstring(folderPath)) 
    folderPathString = convertCharsToStrings(folderPath);
    isWatched = matlab.internal.regfwk.isFolderWatchedImpl(folderPathString);
else 
    ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'folderPath'));
    throw(ME)
end