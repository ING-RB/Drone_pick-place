function createNewApp
    % CREATENEWAPP - creates a new App Designer app
    % launch app designer, called from new app action from JSD and MO
    
    % Copyright 2021-2023 The MathWorks, Inc.

    import matlab.internal.capability.Capability;
    % App Designer requires webwindow - throws error on unsupported clients
    % such as MATLAB Mobile.
    Capability.require(Capability.WebWindow);


    appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment();
    appDesignEnvironment.createNewApp();
