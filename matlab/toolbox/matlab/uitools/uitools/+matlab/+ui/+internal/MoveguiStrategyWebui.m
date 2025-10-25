classdef MoveguiStrategyWebui
    % MoveguiStrategyWebui
    %
    % "movegui" strategy for scenario where feature is "webui"
    
    % Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function [oldOuterPos, widthAdjustment, heightAdjustment, borderEstimate] = getInitialOuterPositionInfo(fig)
            import matlab.ui.internal.FigureToolsDimsConstants.*;
            import matlab.internal.capability.Capability;
            
            if ~Capability.isSupported(Capability.LocalClient)
                % If the environment is MATLAB Online, just get Position
                oldOuterPos = get(fig, 'Position');
                widthAdjustment = 0;
                heightAdjustment = 0;
                borderEstimate = 0;
                return
            end

            % save figure position before making adjustments
            oldOuterPos = get(fig, 'OuterPosition');
            
            % The outerposition isn't the actual value returned by the view
            % it is the estimated value from the model (same as position),
            % As a result we must estimate the outerposition for a figure
            % that is not rendered yet. 
            if matlab.ui.internal.MoveguiStrategyWebui.isOuterPositionEstimatedUsingPosition(fig)
    
                % check if figure has Menubar
                hasMenubar = get(fig, 'ShowMenuBarForView');
    
                % Number of toolbars figure has
                numToolbars = get(fig, 'NumToolBarsForView');
    
                % check if figure has toolstrip
                if isequal(get(fig, 'DefaultTools'), 'toolstrip')
                    hasFigureToolstrip = 1;
                else 
                    hasFigureToolstrip = 0;
                end

                % border and titlebar estimate based on platform
                if ismac

                    % border estimate for figure window
                    borderEstimate = matlab.ui.internal.FigureToolsDimsConstants.BorderEstimateInMac;

                    % width adjustment is border estimate
                    widthAdjustment = borderEstimate;
    
                    % estimated value of titlebar
                    titleBarEstimate = matlab.ui.internal.FigureToolsDimsConstants.TitleBarHeightMac;
                   
                elseif isunix
                    
                    % border estimate for figure window
                    borderEstimate = matlab.ui.internal.FigureToolsDimsConstants.BorderEstimateInLinux;

                    % width adjustment is border left and right side of
                    % window
                    widthAdjustment = borderEstimate * 2;
    
                    % estimated value of titlebar
                    titleBarEstimate = matlab.ui.internal.FigureToolsDimsConstants.TitleBarHeightLinux;

                else 
                    
                    % border estimate for figure window
                    borderEstimate = matlab.ui.internal.FigureToolsDimsConstants.BorderEstimateInWindows;

                    % border value of both left and right side of window
                    widthAdjustment =  borderEstimate * 2;
    
                    % estimated value of titlebar
                    titleBarEstimate = matlab.ui.internal.FigureToolsDimsConstants.TitleBarHeightWindows;
                end
                
                % estimate the outer position height
                heightAdjustment = titleBarEstimate + borderEstimate;

                if hasMenubar
                    heightAdjustment = heightAdjustment + matlab.ui.internal.FigureToolsDimsConstants.MenuBarHeight;
                end
                
                if numToolbars > 0
                    heightAdjustment = heightAdjustment + matlab.ui.internal.FigureToolsDimsConstants.ToolBarHeight * numToolbars;
                end
    
                if hasFigureToolstrip
                     heightAdjustment = heightAdjustment + matlab.ui.internal.FigureToolsDimsConstants.FiguretoolstripHeight;
                end

            else
                % if the figure position and outerposition is not equal
                % which means figure is already rendered which means the
                % outerposition refelcts the actual value

                widthAdjustment = 0;
                heightAdjustment = 0;
                borderEstimate = 0;
            end
            % Setting the xPosition and yPosition such that 
            % we account for outerPosition for unrendered figure since 
            % the current values will be for Position generally. 
            % Meanwhile, if the last set position-related property 
            % is 'OuterPosition',
            % borderEstimate will be zero, thus this should work for that
            % scenario as well. 
            % Similarly, for rendered figures also, the borderEstimate is zero.
            oldOuterPos(1) = oldOuterPos(1) - borderEstimate;
            oldOuterPos(2) = oldOuterPos(2) - borderEstimate;

            oldOuterPos(3) = oldOuterPos(3) + widthAdjustment;
            oldOuterPos(4) = oldOuterPos(4) + heightAdjustment;

        end

        function setNewAdjustedOuterPosition(fig, newpos, widthAdjustment, heightAdjustment, borderEstimate)
            import matlab.internal.capability.Capability;
            if ~Capability.isSupported(Capability.LocalClient)
                % If the environment is MATLAB Online, set the Position
                set(fig, 'Position', newpos);
                return
            end

            if matlab.ui.internal.MoveguiStrategyWebui.isOuterPositionEstimatedUsingPosition(fig)
                % xPosition and yPosition for figure Position
                % are each 'borderEstimate' higher
                % than the counterpart for OuterPosition for all platform
                set(fig, 'Position', [newpos(1) + borderEstimate, newpos(2) + borderEstimate, newpos(3) - widthAdjustment, newpos(4) - heightAdjustment]);
            else
                set(fig, 'OuterPosition', newpos);
            end
        end

        function isEstimated = isOuterPositionEstimatedUsingPosition(fig)
            isEstimated = all(abs(get(fig, 'OuterPosition') - get(fig, 'Position')) <= 1) && ~(matlab.ui.internal.FigureServices.isLastPropOuterPosition(fig));
        end

    end
end