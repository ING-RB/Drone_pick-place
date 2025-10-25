function runningApp = runMApp(appFullFileName, appArguments)
    %RUNMAPP

%   Copyright 2024-2025 The MathWorks, Inc.

    command = appdesigner.internal.service.AppManagementService.prepareCommand(appFullFileName);

    evalAppArguments = [cellfun(@(arg) evalin('base', arg), appArguments(1:end-1), 'UniformOutput', false), appArguments(end)];
    runningApp = feval(command, evalAppArguments{:});
end
