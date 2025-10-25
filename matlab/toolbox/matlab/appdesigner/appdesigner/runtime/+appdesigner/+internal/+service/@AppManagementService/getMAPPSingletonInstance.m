function [runningApp, runningFig] = getMAPPSingletonInstance(obj, app)
    %GETMAPPSINGLETONINSTANCE

%   Copyright 2024 The MathWorks, Inc.

    runningAppFigures = obj.getRunningAppFigures();

    runningApp = [];
    runningFig = [];

    for i = 1:length(runningAppFigures)
        fig = runningAppFigures(i);
        if (strcmp(class(fig.RunningAppInstance), class(app)))
            runningApp = fig.RunningAppInstance;
            runningFig = fig;
            break;
        end
    end
end
