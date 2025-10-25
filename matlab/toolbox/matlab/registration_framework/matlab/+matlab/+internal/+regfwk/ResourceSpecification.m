classdef ResourceSpecification
    % ResourceSpecification Class definition defining the method by which
    %   an Extension Point describes the metadata it is interested in.
    %   Contains a mandatory property, "ResourceName", which must be a
    %   string, and an optional property used only to denote JSON / XML
    %   files, called "ResourceType", which refers to the enumeration class:
    %   "matlab.internal.regfwk.ResourceType".
    %
    %   See also: matlab.internal.regfwk.ResourceType
    %   matlab.internal.regfwk.getResourceList,
    %   matlab.internal.regfwk.enableResources,
    %   matlab.internal.regfwk.disableResources,
    %   matlab.internal.regfwk.registerResources,
    %   matlab.internal.regfwk.unregisterResources
    %
    % Copyright 2022 The MathWorks, Inc.
    properties (Access = public)
        ResourceName = "";
        ResourceType = "";
    end
    methods
        function resourceSpecification = ResourceSpecification(resourceStruct)
            if nargin > 0
                if isstruct(resourceStruct)
                    if isfield(resourceStruct, 'ResourceName')
                        if ischar(resourceStruct.ResourceName) || isstring(resourceStruct.ResourceName)
                            resourceSpecification.ResourceName = convertCharsToStrings(resourceStruct.ResourceName);
                        else
                            ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'resourceSpecification.ResourceName'));
                            throw(ME)
                        end
                    else 
                        ME = MException(message('registration_framework:reg_fw_resources:invalidResourceSpecificationStruct'));
                        throw(ME)
                    end
            
                    if isfield(resourceStruct, 'ResourceType')
                        if isa(matlab.internal.regfwk.ResourceType(resourceStruct.ResourceType), "matlab.internal.regfwk.ResourceType")
                            resourceSpecification.ResourceType = lower(string(resourceStruct.ResourceType));
                        else
                            ME = MException(message('registration_framework:reg_fw_resources:invalidResourceTypeEnum'));
                            throw(ME)
                        end
                    else 
                        resourceSpecification.ResourceType = "";
                    end
            
                else 
                    ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedStruct', 'resourceSpecification'));
                    throw(ME)
                end
            end
        end

        function resourceSpecification = set.ResourceName(resourceSpecification, resourceName)
            if ischar(resourceName) || isstring(resourceName)
                resourceSpecification.ResourceName = convertCharsToStrings(resourceName);
            else
                ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedCharOrString', 'resourceSpecification.ResourceName'));
                throw(ME)
            end
        end

        function resourceSpecification = set.ResourceType(resourceSpecification, resourceType)
            if resourceType == ""
                resourceSpecification.ResourceType = "";
            elseif isa(matlab.internal.regfwk.ResourceType(resourceType), "matlab.internal.regfwk.ResourceType")
                resourceSpecification.ResourceType = lower(string(resourceType));
            else
                ME = MException(message('registration_framework:reg_fw_resources:invalidResourceTypeEnum'));
                throw(ME)
            end
        end
    end
end
