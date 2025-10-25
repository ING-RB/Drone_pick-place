function runStartupFcn(obj, app, startupFcn, fig)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        obj appdesigner.internal.service.AppManagementService
        app
        startupFcn function_handle
        fig = []
    end

    if isempty(fig)
        fig = obj.getFigure(app);
    end

    % If handle visibility is set to 'callback', turn it on until
    % finished with StartupFcn. This enables gcf and gca to work in
    % the StartupFcn and also allows exceptions from the StartupFcn
    % to be catchable.
    if ~isempty(fig) && strcmp(fig.HandleVisibility, 'callback')
        fig.HandleVisibility = 'on';
        c = onCleanup(@()setHandleVisibility(fig, 'callback'));
    end

    % call startupFcn directly
    startupFcn(app);

    function setHandleVisibility(fig, value)
        % Only set figure's handle visibility if figure is valid
        % (see g2654259)
        if isvalid(fig)
            set(fig, 'HandleVisibility', value);
        end
    end
end
