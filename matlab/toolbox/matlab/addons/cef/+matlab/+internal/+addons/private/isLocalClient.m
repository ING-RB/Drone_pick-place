function isLocal = isLocalClient()
    % ISLOCALCLIENT Find if client is Local or Remote

%   Copyright 2021-2023 The MathWorks, Inc.
    
    % Copyright: 2021 The MathWorks, Inc.
    import matlab.internal.capability.Capability;
    if Capability.isSupported(Capability.LocalClient)
        isLocal = true;
    else
        isLocal = false;
    end
end
