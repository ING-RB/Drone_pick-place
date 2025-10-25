classdef WebAppRunner < handle
    % WEBAPPRUNNER Provide API to run an app in web
    %  
    %    The WEBAPPRUNNER interface exposes one static method to run a web
    %    app - runWebApp(appName, appRunCallback), which
    %    returns the running app object.
    %
    %    Example:
    %       % Define callback functions
    %       funciton appRunCallback(e)
    %           disp(e.FigureURL);
    %       end
    %       % call runWebApp() method
    %       appObject = appdesigner.internal.service.WebAppRunner.runWebApp('AppToRun', ...
    %                  @appRunCallback);
    
    % Copyright 2016 - 2021 The MathWorks, Inc.
    
    methods(Static)
        function appObject = runWebApp(appName, appRunCallback)
            % RUNWEBAPP Run an app as a webapp. 
            %
            % appObject = RUNWEBAPP(appName, appRunCallback)
            %
            % Returns:
            % appObject - handle of the running app
            %
            % Inputs:
            % appName - Name of the app to run
            % appRunCallback - Function handle to be called when the app
            % createComponents() execution is completed. The event data has
            % the properties: 
            %      Figure - figure object
            %      FigureURL - figure URL
            %      App - app object
            %
            % This function can throw exception.

            appObject = [];
            appManagementService = appdesigner.internal.service.AppManagementService.instance();

            % Listen to AppCreateComponentsExecutionCompleted to call
            % appRunCallback to notify app layout creation completed
            listenerToAppCreateComponentsDone = listener(... 
                appManagementService, 'AppCreateComponentsExecutionCompleted',...
                    @(~,e)appRunCallback(e));

            appObject = appdesigner.internal.service.AppManagementService.runApp(appName);
        end
    end

end

