function resourceInformations = getResourceList(resourceSpecifications, resourceStateFilter)
% getResourceList Given an array of 'ResourceSpecification' objects, returns
%   an array of structs representing the matching metadata known to the
%   Registration Framework at the time of invocation
%
%   matlab.internal.regfwk.getResourceList(resourceSpecification) 
%
%   resourceSpecifications is an array of 'ResourceSpecification' objects
%   resourceInformations is the returned cell-array of structs, each
%   representing metadata that matches the given resourceSpecifications
%
%   See also: matlab.internal.regfwk.ResourceSpecification
%   matlab.internal.regfwk.enableResources,
%   matlab.internal.regfwk.disableResources,
%   matlab.internal.regfwk.registerResources,
%   matlab.internal.regfwk.unregisterResources

% Copyright 2022 The MathWorks, Inc.
if (nargin > 1) 
    resourceStateFilterFinal = resourceStateFilter;
else
    resourceStateFilterFinal = "enabled";
end
if isa(resourceSpecifications, "matlab.internal.regfwk.ResourceSpecification")
    if isscalar(resourceSpecifications)
        resourceSpecificationsJson = "["+jsonencode(resourceSpecifications)+"]";
    else
        resourceSpecificationsJson = string(jsonencode(resourceSpecifications));
    end
    resourceInformationsJson = matlab.internal.regfwk.getResourceListImpl(resourceSpecificationsJson, resourceStateFilterFinal);
    resourceInformations = jsondecode(resourceInformationsJson);
else 
    ME = MException(message('registration_framework:reg_fw_resources:invalidResourceSpecificationsArray'));
    throw(ME)
end
