function value = isAppRunInAppDesigner(app)
    % Returns true if app is run using App Designer

%   Copyright 2024 The MathWorks, Inc.

    uiFigure = appdesigner.internal.service.AppManagementService.getFigure(app);

    if isempty(uiFigure)
        value = false;
    else
        % todo, set IsRunningInAppDesigner in app
        % as dynamic property instead on uiFigure
        % so no need to loop all figures and find specific app
        value = isprop(uiFigure, 'IsRunningInAppDesigner');
    end
end
