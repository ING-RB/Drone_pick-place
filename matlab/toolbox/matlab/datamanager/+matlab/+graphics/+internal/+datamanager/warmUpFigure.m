function warmUpFigure(hFig)

%This is an undocumented class and may be removed in future

% Copyright 2019 MathWorks, Inc.

hFig = handle(hFig);
if isempty(hFig) || ~isvalid(hFig)
    return;
end
if ~isprop(hFig,'PlotToolsAppFigure')
    propName = addprop(hFig,'PlotToolsAppFigure');
    propName.Hidden = true;
    propName.Transient = true;
end
if isempty(hFig.PlotToolsAppFigure) || ...
        ~isvalid(hFig.PlotToolsAppFigure) || ...
        (~isempty(hFig.PlotToolsAppFigure) && ...
        strcmpi(get(hFig.PlotToolsAppFigure,'Visible'),'on'))
    hFig.PlotToolsAppFigure = uifigure('Visible','off',...
        'Internal', true, ...
        'Position', getDialogPosition(hFig),...
        'PositionMode','auto',...
        'AutoResizeChildren', 'off');
    addlistener(hFig,'ObjectBeingDestroyed',@(e,d) deleteUiFigure(hFig));
end

    function dialogPos = getDialogPosition(hFig)
        figPos = getpixelposition(hFig);
        dialogPos = [figPos(1)+figPos(3)+5 figPos(2) 444 473];
        
        if strcmpi(hFig.WindowState, 'maximized')
            % If dialog cannot fit in the current screen, then position it
            % at the bottom-right corner of the current figure
            dialogPos(1) = figPos(1)+figPos(3) - dialogPos(3);
            dialogPos(2) = figPos(2);
        end
    end

    function deleteUiFigure(hFig)
        if isprop(hFig,'PlotToolsAppFigure')
            delete(hFig.PlotToolsAppFigure);
        end
    end
end