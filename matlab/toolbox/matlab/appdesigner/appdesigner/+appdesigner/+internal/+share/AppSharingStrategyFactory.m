classdef AppSharingStrategyFactory
    %APPSHARINGSTRATEGYFACTORY Hands out instances of AppSharingStrategy
    %   Used to retrieve an AppSharingStrategy to allow an app to be compiled
    %   or packaged to the appropriate type of project.
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods (Static)
        function strategy = getStrategy(appType)
            %GETSTRATEGY Returns the appropriate type of sharing strategy
            % based on the type of sharing requested.
            switch (appType)
                case 'DESKTOP_APP'
                    strategy = compiler.internal.DesktopAppSharingStrategy();
                case 'WEB_APP'
                    strategy = compiler.internal.WebAppSharingStrategy();
                case 'MATLAB_APP'
                    strategy = matlab.internal.deployment.MatlabAppSharingStrategy();
                otherwise
                    error('Unknown or missing app type.  Could not create an appropriate sharing strategy.');
            end
        end
    end
end