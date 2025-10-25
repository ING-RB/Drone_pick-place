function baseCode = getAddOnsSpkgBaseCode(resourcesFolder)
% getAddOnsSpkgBaseCode function retrieves metadata for a specified add-on resource file.
%
% Inputs:
%   resourcesFolder - A Full path to the target Root folder 
%                     where resources folder is available 
%
% Outputs:
%   addOnMetaData - A structure containing the setup and identifier of the
%                   specified add-on resource file. If the resource file is
%                   not found, it returns an empty array.

% Copyright 2024 The MathWorks, Inc.

baseCode = '';
% Create a ResourceSpecification object for 'mw.addons'
addOnsSpecification = matlab.internal.regfwk.ResourceSpecification;
addOnsSpecification.ResourceName = 'mw.addons';

% Get the list of all resources for the specified add-on
resourceList = matlab.internal.regfwk.getResourceList(addOnsSpecification, 'all');

% Extract the contents and root folders of the resources
addOnsResourceList = {resourceList.resourcesFileContents};

resourceIndex = strcmp({resourceList.rootFolder}, resourcesFolder);

if any(resourceIndex)
    % extract the setup and identifier metadata
    baseCode = addOnsResourceList{resourceIndex}.identifier;
end