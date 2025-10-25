function addAddOn(Identifier, Version, Enabled, InstalledFolder)
% addAddOn Register an add-on
%
%   matlab.internal.addons.registry.addAddOn(IDENTIFIER, VERSION,STATE,INSTALLEDFOLDER) registers
%   an add-on with the specified IDENTIFIER, VERSION, STATE, INSTALLEDFOLDER.
%
%
%   IDENTIFIER is the unique identifier of the add-on to be registered,
%   specified as a string
%
%   VERSION: Version of the add-on provided as a string
%
%   ENABLED: Must be set to true if the add-on needs to be enabled post registration.
%
%   INSTALLEDFOLDER: Path to the root folder of the add-on containing the
%   resources folder provided as a string
%
%   Example: Enables an add-on with resources folder
%   matlab.internal.addons.registry.addAddOn("b443a7d0-3a0b-4f52-ad0c-8facef8a00f7","1.0", true, "/Users/ddeepak/Library/Application Support/MathWorks/MATLAB Add-Ons/Apps/SimIam")
%
%   See also: matlab.internal.addons.registry.enableAddOn,
%   matlab.internal.addons.registry.disableAddOn,
%   matlab.internal.addons.registry.removeAddOn

% Copyright 2020 The MathWorks, Inc.
% Built-in function.
