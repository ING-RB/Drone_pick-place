function setExtensionsMetadataToFile(extensionsJsonFilePath, jsonString)
    % setExtensionsMetadataFromFile Given an "extensions.json" file path and a JSON string, writes
    %   the JSON string out to the supplied "extensions.json" file exactly as it is.
    %
    %   See also: matlab.internal.regfwk.ResourceSpecification
    %   matlab.internal.regfwk.getResourceList,
    %   matlab.internal.regfwk.getExtensionsMetadataToFile,
    %   matlab.internal.regfwk.getExtensionsPropertyFromFile,
    %   matlab.internal.regfwk.setExtensionsPropertyToFile
    
    % Copyright 2023 The MathWorks, Inc.
    
    matlab.internal.regfwk.setExtensionsMetadataToFileImpl(extensionsJsonFilePath, jsonString);
end