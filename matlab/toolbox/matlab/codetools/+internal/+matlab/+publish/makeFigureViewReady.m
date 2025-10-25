function makeFigureViewReady(f)
% Poll until FigureViewReady is set to 'on' before proceeding to
% publish/export the figure
if ~strcmp(get(f, "FigureViewReady"), "on")
    for i=1:50
        pause(0.1);
        if strcmp(get(f, "FigureViewReady"), "on")
            break;
        end
    end
end

if ~strcmp(get(f, "FigureViewReady"), "on") && isenv('IS_PUBLISHING')  && strcmp(getenv('IS_PUBLISHING'),'1')
    warning(message("MATLAB:publish:FigureViewNotReady"));
end
