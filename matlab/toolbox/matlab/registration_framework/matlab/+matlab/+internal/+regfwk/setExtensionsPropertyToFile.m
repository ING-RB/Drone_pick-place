function setExtensionsPropertyToFile(extensionsJsonFilePath, resourceName, resourceValue)
    % getExtensionsMetadataFromFile Given an "extensions.json" file path, resourceName and 
    %   resourceValue (which should be a JSON string), sets the resourceValue to the resourceName within 
    %   the supplied "extensions.json" file.
    %
    %   This overrides any existing value already present in the file. The resourceName can be a 
    %   hierarchical "." separated string, which is resolved within the supplied "extensions.json" file.
    %
    %   See also: matlab.internal.regfwk.ResourceSpecification
    %   matlab.internal.regfwk.getResourceList,
    %   matlab.internal.regfwk.getExtensionsPropertyFromFile,
    %   matlab.internal.regfwk.getExtensionsMetadataFromFile,
    %   matlab.internal.regfwk.setExtensionsMetadataToFile
    
    % Copyright 2023 The MathWorks, Inc.
    
    matlab.internal.regfwk.setExtensionsPropertyToFileImpl(extensionsJsonFilePath, resourceName, resourceValue);
end