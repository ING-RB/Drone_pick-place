function isAvailable = openJavaVE()
% OPENJAVAVE returns true if the capability to open JAVA Variable Editor
% is available and false otherwise

% Copyright 2023 The MathWorks, Inc.

    % NOTE: We are currently using the following flags to determine whether
    % to route the openvar request to JAVA or JS VariableEditor. In the future, we will
    % switch to using a better flag to determine the ennvironment.
    % JAVA Variable Editor
    import matlab.internal.capability.Capability;
    Capability.require(Capability.InteractiveCommandLine); 
    isAvailable = matlab.internal.feature('webui') == 0 && Capability.isSupported(Capability.LocalClient);
end

