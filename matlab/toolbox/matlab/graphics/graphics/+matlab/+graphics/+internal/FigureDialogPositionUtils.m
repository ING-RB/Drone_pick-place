classdef FigureDialogPositionUtils

% Copyright 2023 The MathWorks, Inc.

    methods (Static)
        % Position the dialog next to the parent figure. If parent figure
        % is maximized, then position app in the bottom right corner of the
        % figure
        function dialogPos =  getDialogPosition(fig, width, height)
            figPos = getpixelposition(fig);
            screenSize = get(0,'ScreenSize');
            monitorPositions = get(groot,'MonitorPosition');

            dialogPos = matlab.graphics.internal.FigureDialogPositionUtils.getDialogPositionWithScreenInfo(width, height, figPos, fig.WindowState, fig.WindowStyle, screenSize, monitorPositions);
        end

        function dialogPos =  getDialogPositionWithScreenInfo(width, height, figPos, figWindowState, figWindowStyle, screenSize, monitorPositions)
            dialogPos = [figPos(1)+figPos(3)+5 figPos(2) width height];
            [~,rightMonitorPosition] = max(monitorPositions(:,2));
            if strcmpi(figWindowState, 'maximized')
                % If dialog cannot fit in the current screen, then position it
                % at the bottom-right corner of the current figure
                dialogPos(1) = figPos(1)+figPos(3) - dialogPos(3);
                dialogPos(2) = figPos(2);
            elseif strcmpi(figWindowStyle,'docked')
                % When the figure is docked, we will position the
                % linkedplot dialog to the center of the screen
                dialogPos(1) = screenSize(3)/3;
                dialogPos(2) = screenSize(4)/3;
            elseif (dialogPos(1)+dialogPos(3)) > monitorPositions(rightMonitorPosition,3)+monitorPositions(rightMonitorPosition,1)
                % If dialog cannot fit in the current screen, then position it
                % at the center of the figure
                dialogPos(1) = max(figPos(1) - dialogPos(3) - 5,1);
                dialogPos(2) = figPos(2);
            end
        end
    end
end