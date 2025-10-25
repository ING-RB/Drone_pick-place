classdef MoveguiStrategyJava
    % MoveguiStrategyJava
    %
    % "movegui" strategy for scenario where figure is a Java figure
    
    % Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function [oldpos, widthAdjustment, heightAdjustment, borderEstimate] = getInitialOuterPositionInfo(fig)
            widthAdjustment = 0;
            heightAdjustment = 0;
            borderEstimate = 0;

            oldpos = get(fig, 'OuterPosition');
            if isunix
                oldpos = get(fig, 'Position');
            end
            
            if matlab.ui.internal.hasDisplay
                % check if the figure has a menubar
                haveMenubar = ~isempty(findall(fig,'type','uimenu'));
                
                % check if the figure has any toolbars 
                numToolbars = length(findall(fig,'type','uitoolbar'));
            
                
                if isunix
                    % on unix, we can't rely on outerposition to place the figure
                    % correctly.  use reasonable defaults and place using regular
                    % position. 
                    
                    % reasonable defaults to calculate outer position 
                    widthAddEstimate = 6;
                    topEstimate1 = 24;
                    topEstimate2 = 32;
            
                    % estimate the outer position
                    widthAdjustment =  widthAddEstimate;
                    heightAdjustment = topEstimate1;
            
                    if haveMenubar
                        heightAdjustment = heightAdjustment + topEstimate2;
                    end
            
                    if numToolbars > 0
                        heightAdjustment = heightAdjustment + topEstimate1 * numToolbars;
                    end
            
                    oldpos(3) = oldpos(3) + widthAdjustment;
                    oldpos(4) = oldpos(4) + heightAdjustment;
                else
                    % detect unreasonable outer position value
                    % and try to correct it
                    if (haveMenubar || numToolbars > 0)
                        
                        innerPos = get(fig,'Position');
                        heightDiff = oldpos(4) - innerPos(4);
                        
                        minHeightDiff = 50;
                        % if the difference between inner and outer height
                        % is too small, let's query outer position again
                        if (heightDiff < minHeightDiff)
                            drawnow; 
                            % check figure handle validity after the call to drawnow
                            if (~ishghandle(fig,'figure'))
                                return;
                            end
                            oldpos = get(fig, 'OuterPosition');
                        end
                    end
                end
            end
        end

        function setNewAdjustedOuterPosition(fig, newpos, widthAdjustment, heightAdjustment, ~)
            if isunix
                % remove width and height adjustments added above
                newpos(3) = newpos(3) - widthAdjustment;
                newpos(4) = newpos(4) - heightAdjustment;
                set(fig, 'Position', newpos);
            else
                set(fig, 'OuterPosition', newpos);
            end
        end
    end
end