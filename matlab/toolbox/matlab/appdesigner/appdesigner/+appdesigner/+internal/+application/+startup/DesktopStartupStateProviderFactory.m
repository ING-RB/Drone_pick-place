classdef DesktopStartupStateProviderFactory < appdesigner.internal.application.startup.StartupStateProviderFactory
    % State Factory for all things Desktop (regular MATLAB use case)
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
       StartupStateProviderPackages = {...
           'appdesigner.internal.application.startup.common', ...
           'appdesigner.internal.application.startup.desktop', ...
           };
    end
    
    
end


