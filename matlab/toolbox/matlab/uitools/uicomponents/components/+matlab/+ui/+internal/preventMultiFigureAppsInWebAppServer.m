function preventMultiFigureAppsInWebAppServer(option)
%preventMultiFigureAppsInWebAppServer handle listener on figure object 
% and throw erros in case of multiple figures in created in apps.
% This is used by the deployed webapps 

    
    % Disallow additional Figures
    persistent figureInstanceListener;
    
    % clear the block value 
    if nargin > 0 && ischar(option) && strcmp(option,'clear')
       figureInstanceListener = [];
       return
    end


    if isempty(figureInstanceListener)
        clazz = ?matlab.ui.Figure;
        figureInstanceListener = event.listener(clazz, 'InstanceCreated', @handleMultiWindowAttempt);
    end

    function handleMultiWindowAttempt(~,e)
        % Delete the new Figure
        delete(e.Instance);
        
        % Report an error
        matlab.ui.internal.NotSupportedInWebAppServer('multiwindow apps');
    end
end

