function uiFigure = getFigure(appOrUserComponent)
    % Get figure handle in the running app
    % Used by Compiler team now. When they can use new API, try to remove it

%   Copyright 2024 The MathWorks, Inc.

    uiFigure = [];

    if isa(appOrUserComponent, 'matlab.ui.componentcontainer.ComponentContainer')
        uiFigure = appOrUserComponent.Parent;
    else
        runningAppFigures = appdesigner.internal.service.AppManagementService.getRunningAppFigures();

        if ~isempty(runningAppFigures)
            uiFigure = runningAppFigures(1);
        end
    end
end
