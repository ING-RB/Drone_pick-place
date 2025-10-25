function removeAddOn(Identifier,Version)
% removeAddOn Unregister an add-on
%
%   matlab.internal.addons.registry.removeAddOn(IDENTIFIER,
%   VERSION) Unregisters an add-on with the specified IDENTIFIER, VERSION.
%
%
%   IDENTIFIER is the unique identifier of the add-on to be un-registered,
%   specified as a string
%
%   VERSION: Version of the add-on provided as a string
%   Example: Disable an add-on 
%   matlab.internal.addons.registry.removeAddOn("b443a7d0-3a0b-4f52-ad0c-8facef8a00f7","1.0")
%
%   See also: matlab.internal.addons.registry.addAddOn,
%   matlab.internal.addons.registry.enableAddOn,
%   matlab.internal.addons.registry.disableAddOn
%   matlab.internal.addons.registry.isAddOnEnabled

% Copyright 2020 The MathWorks, Inc.
% Built-in function.