function unregisterMApp(obj, app)
    %UNREGISTERMAPP

%   Copyright 2024 The MathWorks, Inc.

    figures = obj.getRunningAppFigures();

    for i = 1:length(figures)
        if figures(i).RunningAppInstance == app
            figures(i).delete();
            break;
        end
    end
end
