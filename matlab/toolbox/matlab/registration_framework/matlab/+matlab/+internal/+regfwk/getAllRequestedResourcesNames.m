function getAllRequestedResourcesNames = getAllRequestedResourcesNames()
% getFolderState Gets all the requested resources names known to RegistrationFramework at the moment of invocation
%
%   matlab.internal.regfwk.getAllRequestedResourcesNames() 
%   Gets all the requested resources names known to RegistrationFramework at the moment of invocation
%
%
%   See also: matlab.internal.regfwk.enableResources,
%   matlab.internal.regfwk.disableResources,
%   matlab.internal.regfwk.registerResources,
%   matlab.internal.regfwk.unregisterResources

% Copyright 2021 The MathWorks, Inc.
% Calls a Built-in function.
getAllRequestedResourcesNames = matlab.internal.regfwk.getAllRequestedResourcesNamesImpl();