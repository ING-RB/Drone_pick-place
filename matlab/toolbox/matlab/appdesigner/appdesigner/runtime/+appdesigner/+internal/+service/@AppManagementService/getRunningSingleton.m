function runningApp = getRunningSingleton(obj, app)
%

%   Copyright 2024 The MathWorks, Inc.

    runningAppFigures = obj.getRunningAppFigures();

    runningApp = [];

    for i = 1:length(runningAppFigures)
        fig = runningAppFigures(i);
        if (strcmp(class(fig.RunningAppInstance), class(app)))
            runningApp = fig.RunningAppInstance;
            break;
        end
    end
end
