classdef AppInstantiator < appdesigner.internal.apprun.RunInstantiator
    %APPINSTANTIATOR Responsible for instantiating a standard or responsive
    %app from app designer
    
    % Copyright 2021-2024, MathWorks Inc.
    
    methods
        function obj = AppInstantiator(appmodel)
            obj@appdesigner.internal.apprun.RunInstantiator(appmodel);
        end
        
        function runningApp = run(obj, arguments)
            desktopAppRunner = appdesigner.internal.apprun.DesktopAppRunner.instance();

            % use onCleanup to set runningApp in case of app code Exception
            cleanupObj = onCleanup(@()obj.setRunningAppAndCleanup(desktopAppRunner));

            runningApp = desktopAppRunner.run(obj.AppModel.FullFileName, arguments, obj);
        end

        function setRunningAppAndCleanup(obj, desktopAppRunner)
            % Exception in startup function from app's constructor, but app already created,
            % get running app from AppManagementService and set AppModel RunningApp
            app = desktopAppRunner.getRunningApp(obj.AppModel.FullFileName);
            obj.AppModel.RunningApp = app;

            obj.setupCleanup(app, obj.AppModel.FullFileName)
        end

        function runningApp = launchApp(~, filepath, arguments)
            % Override - DesktopAppRunner will call into this abstraction
            runningApp = appdesigner.internal.service.AppManagementService.runApp(filepath, arguments);
        end
    end
end

