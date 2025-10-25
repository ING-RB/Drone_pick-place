classdef PlainTextAppInstantiator < appdesigner.internal.apprun.RunInstantiator
    % PLAINTEXTAPPINSTANTIATOR

    % Copyright 2023-2024 The MathWorks, Inc.

    methods
        function obj = PlainTextAppInstantiator(appmodel)
            obj@appdesigner.internal.apprun.RunInstantiator(appmodel);
        end

        function runningApp = run(obj, inputArguments)
            desktopAppRunner = appdesigner.internal.apprun.DesktopAppRunner.instance();

            % use onCleanup to set runningApp in case of app code Exception
            cleanupObj = onCleanup(@()obj.setRunningAppAndCleanup(desktopAppRunner));

            options = appdesigner.internal.apprun.AppOptions;

            options.Filepath = obj.AppModel.FullFileName;

            options.ClearCache = true;

            if isempty(inputArguments)
                args = {options};
            else
                args = cellfun(@(x)strtrim(x), strsplit(inputArguments, ','), 'UniformOutput', false);

                args{end+1} = options;
            end

            runningApp = desktopAppRunner.run(obj.AppModel.FullFileName, args, obj);
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
            runningApp = appdesigner.internal.service.AppManagementService.runMApp(filepath, arguments);
        end
    end
end
