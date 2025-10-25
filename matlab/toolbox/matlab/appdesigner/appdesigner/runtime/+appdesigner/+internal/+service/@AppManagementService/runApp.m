function runningApp = runApp(appFullFileName, appArguments)
    % run app for web app (WebAppRunner) or run app in app designer (DesktopAppRunner)
    % running app in MATLAB does not call this function

%   Copyright 2024 The MathWorks, Inc.

    command = appdesigner.internal.service.AppManagementService.prepareCommand(appFullFileName);

    if nargin == 1
        appArguments = '';
    end

    runningApp = evalin('base', sprintf('%s(%s);', command, appArguments));
end