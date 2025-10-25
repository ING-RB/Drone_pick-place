classdef ResourceType
    % ResourceType Class enumeration definition defining the optional
    %   property in "matlab.internal.regfwk.ResourceSpecification" class to
    %   denote a metadata file extension. Currently, JSON and XML are the two
    %   supported metadata file extensions. 
    %
    %   See also: matlab.internal.regfwk.ResourceType
    %   matlab.internal.regfwk.getResourceList,
    %   matlab.internal.regfwk.enableResources,
    %   matlab.internal.regfwk.disableResources,
    %   matlab.internal.regfwk.registerResources,
    %   matlab.internal.regfwk.unregisterResources
    %
    % Copyright 2022 The MathWorks, Inc.
    enumeration
        JSON, XML
    end
end