function extensionsMetadata = getExtensionsMetadataFromFile(extensionsJsonFilePath)
    % getExtensionsMetadataFromFile Given an "extensions.json" file path, returns
    %   an unflattened struct containing all the metadata from the "extensions.json" file
    %
    %   See also: matlab.internal.regfwk.ResourceSpecification
    %   matlab.internal.regfwk.getResourceList,
    %   matlab.internal.regfwk.setExtensionsMetadataToFile,
    %   matlab.internal.regfwk.getExtensionsPropertyFromFile,
    %   matlab.internal.regfwk.setExtensionsPropertyToFile
    
    % Copyright 2023 The MathWorks, Inc.
    
    extensionsMetadataJson = matlab.internal.regfwk.getExtensionsMetadataFromFileImpl(extensionsJsonFilePath);
    extensionsMetadata = jsondecode(extensionsMetadataJson);
end