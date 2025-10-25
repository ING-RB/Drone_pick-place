function registrationRoot = getRegistrationRootForEnabledOrMostRecentlyInstalledVersion(identifier)
%  getRegistrationRootForEnabledOrMostRecentlyInstalledVersion Get registration root for an add-on
%
%   matlab.internal.addons.registry.getRegistrationRootForEnabledOrMostRecentlyInstalledVersion(IDENTIFIER) 
%   Returns the registration root folder of an add-on with the specified IDENTIFIER.
%
%
%   IDENTIFIER is the unique identifier of the add-on,
%   specified as a string
%
%   VERSION: Version of the add-on provided as a string
%   Example: Getregistration root for an add-on
%   matlab.internal.addons.registry.getRegistrationRootForEnabledOrMostRecentlyInstalledVersion("b443a7d0-3a0b-4f52-ad0c-8facef8a00f7")
%
%   In a scenario where only IDENTIFIER of the add-on is provided, the API
%   returns the registration folder of the enabled version or the most
%   recently installed version if none of the versions are enabled. 
%
%   See also: matlab.internal.addons.registry.addAddOn,
%   matlab.internal.addons.registry.enableAddOn,
%   matlab.internal.addons.registry.disableAddOn
%   matlab.internal.addons.registry.isAddOnEnabled

% Copyright 2021 The MathWorks, Inc.
% Built-in function.

