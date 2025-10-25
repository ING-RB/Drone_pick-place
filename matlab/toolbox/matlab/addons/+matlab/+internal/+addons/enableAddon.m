function enableAddon(identifier, addOnVersion, name)
% Enables an add-on with given identifier and version

% Copyright 2018-2024 The MathWorks, Inc.
    try
        matlab.addons.enableAddon(identifier, addOnVersion);
        disp(getString(message('matlab_addons:enableDisableManagement:addOnSuccessfullyEnabled', name, addOnVersion)));
    catch ME
        throw(ME)
    end
end
