classdef MoveguiStrategyUifigure
    % MoveguiStrategyUifigure
    %
    % "movegui" strategy for scenario where figure is a "uifigure" in Java
    
    % Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function [oldOuterPos, widthAdjustment, heightAdjustment, borderEstimate] = getInitialOuterPositionInfo(fig)
            import matlab.ui.internal.FigureToolsDimsConstants.*;

            % save figure position before making adjustments
            oldpos = get(fig, 'Position');

            % estimated value for MenuBar
            menuBarEstimate = matlab.ui.internal.FigureToolsDimsConstants.MenuBarHeight;

            % estimated value for toolbar
            toolBarEstimate = matlab.ui.internal.FigureToolsDimsConstants.ToolBarHeight;
            
            % we can't rely on outerposition to place the uifigure
            % correctly.  use reasonable defaults and place using regular
            % position.
           
            if isunix
                % reasonable defaults to calculate outer position in unix
            
                % border estimate for figure window
                borderEstimate = 0;
                % padding value to account backward compatibility
                paddingEstimate = 6;
                % width adjustment is border value plus padding value of window
                widthAdjustment = borderEstimate + paddingEstimate;
                % estimated value of titlebar
                titleBarEstimate = 24;

            else
                % reasonable defaults to calculate outer position in windows
            
                % border estimate for figure window
                borderEstimate = 8;
                % border value of both left and right side of window
                widthAdjustment = borderEstimate * 2;
                % estimated value of titlebar
                titleBarEstimate = 31;
            end
            
            % estimate the outer position
            heightAdjustment = titleBarEstimate + borderEstimate;
            
            % check if the figure has uimenus parented directly to it and is visible
            haveMenubar = ~isempty(findall(fig,'type','uimenu','Visible','on','-depth',1));
            
            % get the number of uitoolbars that are visible in figure
            numToolbars = length(findall(fig,'type','uitoolbar','Visible','on'));
            
            if haveMenubar
                heightAdjustment = heightAdjustment + menuBarEstimate;
            end
            
            if numToolbars > 0
                heightAdjustment = heightAdjustment + toolBarEstimate * numToolbars;
            end
            
            oldOuterPos(1) = oldpos(1) - borderEstimate;
            oldOuterPos(2) = oldpos(2) - borderEstimate;
            oldOuterPos(3) = oldpos(3) + widthAdjustment;
            oldOuterPos(4) = oldpos(4) + heightAdjustment;
        end

        function setNewAdjustedOuterPosition(fig, newpos, widthAdjustment, heightAdjustment, borderEstimate)
            % remove width and height adjustments added above
            newpos(1) = newpos(1) + borderEstimate;
            newpos(2) = newpos(2) + borderEstimate;
            newpos(3) = newpos(3) - widthAdjustment;
            newpos(4) = newpos(4) - heightAdjustment;
            set(fig, 'Position', newpos);
        end
    end
end