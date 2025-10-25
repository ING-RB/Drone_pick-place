function setupPropertyInspector()
    % This function is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2019 The MathWorks, Inc.
    
    % This is called when being used in a connector environment (ex: MO)
    % Make sure the server-side property inspector is started
    internal.matlab.inspector.peer.DefaultPropertyInspector.startup;
end