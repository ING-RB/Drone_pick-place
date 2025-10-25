function [isFound, extensionProperty] = getExtensionsPropertyFromFile(extensionsJsonFilePath, resourceName)
    % getExtensionsMetadataFromFile Given an "extensions.json" file path, returns
    %   an "isFound", to indicate if the property was found, as well as an unflattened struct containing all
    %   the metadata from the "extensions.json" file
    %
    %   See also: matlab.internal.regfwk.ResourceSpecification
    %   matlab.internal.regfwk.getResourceList,
    %   matlab.internal.regfwk.setExtensionsPropertyToFile,
    %   matlab.internal.regfwk.getExtensionsMetadataFromFile,
    %   matlab.internal.regfwk.setExtensionsMetadataToFile
    
    % Copyright 2023 The MathWorks, Inc.
    
    [isFound, extensionPropertyJson] = matlab.internal.regfwk.getExtensionsPropertyFromFileImpl(extensionsJsonFilePath, resourceName);
    extensionProperty = jsondecode(extensionPropertyJson);
end