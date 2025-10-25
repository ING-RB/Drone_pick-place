classdef OnlineStartupStateProviderFactory < appdesigner.internal.application.startup.StartupStateProviderFactory 
    % State Factory for all things MATLAB Online
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
       StartupStateProviderPackages = {...
           'appdesigner.internal.application.startup.common', ...
           'appdesigner.internal.application.startup.online', ...
           };
    end
    
    
end


