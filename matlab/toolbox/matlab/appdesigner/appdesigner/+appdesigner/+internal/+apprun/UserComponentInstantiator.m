classdef UserComponentInstantiator < appdesigner.internal.apprun.RunInstantiator
    %USERCOMPONENTINSTANTIATOR Responsible for instantiating components
    %executed from appdesigner

    % Copyright 2021-2024, MathWorks Inc.

    methods
        function obj = UserComponentInstantiator(appModel)
            obj@appdesigner.internal.apprun.RunInstantiator(appModel);
        end

        function runningComponent = run(obj, ~)
            userComponentRunner = appdesigner.internal.apprun.UserComponentRunner.instance();
            runningComponent = userComponentRunner.run(obj.AppModel.FullFileName);

            % update the auto-created parent to the size of the component
            fig = runningComponent.Parent;
            runningComponent.Parent.Position = [...
                fig.Position(1)...
                fig.Position(2)...
                runningComponent.Position(1) + runningComponent.Position(3)...
                runningComponent.Position(2) + runningComponent.Position(4)];

            obj.setupCleanup(runningComponent, obj.AppModel.FullFileName);

            obj.AppModel.addUpdateExceptionAlertListener(runningComponent);
        end

        function launchApp(~, ~, ~)
            % Override - no-op, UAC does not launch through the DesktopAppRunner
        end
    end
end
