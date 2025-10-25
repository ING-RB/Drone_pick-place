function updateResources(folderPaths)
    % updateResources updates specified resources with Registration Framework
    %
    %   matlab.internal.regfwk.updateResources(folderPaths) 
    %   updates the resources with the specified folderPaths.
    %
    %
    %   folderPaths is the list of resources to be updated,
    %   specified as an array of strings
    %
    %   See also: matlab.internal.regfwk.enableResources,
    %   matlab.internal.regfwk.disableResources
    %   matlab.internal.regfwk.registerResources,
    %   matlab.internal.regfwk.unregisterResources

    
    % Copyright 2022 The MathWorks, Inc.
    % Calls a Built-in function.
    if (iscellstr(folderPaths) || ischar(folderPaths) || isstring(folderPaths)) 
        folderPathStrings = convertCharsToStrings(folderPaths);
        matlab.internal.regfwk.updateResourcesImpl(folderPathStrings);
    else 
        ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'folderPaths'));
        throw(ME)
    end