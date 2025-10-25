classdef InteractionStrategy < matlab.graphics.interaction.uiaxes.InteractionStrategy
    %

    %   Copyright 2018 The MathWorks, Inc.
    
    properties
        HeatmapChart
    end
    
    events
        LimitsStart
        LimitsStop
    end
    
    properties (Transient, NonCopyable, Hidden, Access = ?ChartUnitTestFriend)
        DragSingleton matlab.graphics.interaction.uiaxes.DragSingleton
        DragListener event.listener = event.listener.empty()
        MidPan = false
        StartingXLimits
        StartingYLimits
        DataRangeNorm
        LayoutCache = struct();
    end
    
    methods
        function hStrategy = InteractionStrategy(hChart)
            % Store a handle to the HeatmapChart
            hStrategy.HeatmapChart = hChart;
            
            % Get a handle to the DragSingleton to listen for
            % DragComplete events.
            hStrategy.DragSingleton = matlab.graphics.interaction.uiaxes.DragSingleton.getInstance();
        end
        
        function tf = isValidMouseEvent(hStrategy, ~, ~, eventData)
            % Get the object that was hit.
            hitObject = eventData.HitObject;
            hChart = hStrategy.HeatmapChart;
            
            % Check if we are in plot edit mode.
            hFigure = eventData.Source;
            plotEditMode = isscalar(hFigure) && isactiveuimode(hFigure,'Standard.EditPlot');
            
            % The event is valid if the heatmap primitive was hit.
            tf = isscalar(hitObject) && hitObject == hChart.Heatmap && ...
                hChart.EnableInteractions && ~plotEditMode;
        end
        
        function setUntransformedPanLimits(hStrategy, hAx, hDataSpace, xLimits, yLimits, ~)
            % Transform the limits from normalized to data units then set
            % the limits.
            
            % If this is the first time the limits have been set since
            % starting a click-and-drag pan, call startPan.
            if ~hStrategy.MidPan
                hStrategy.MidPan = true;
                hStrategy.startPan(hDataSpace);
            end
            
            % Constrain the limits to prevent panning too far outside the
            % range of the data.
            xRange = hStrategy.DataRangeNorm(1,:);
            yRange = hStrategy.DataRangeNorm(2,:);
            [xLimits, yLimits] = hStrategy.constrainLimits(xLimits, yLimits, xRange, yRange);
            
            % Convert the limits to data units.
            [xLimits, yLimits] = matlab.graphics.interaction.internal.UntransformLimits(hDataSpace, xLimits, yLimits, [0 1]);
            
            % Make sure the limits span an integer number of categories.
            % This is done to make sure that the lower and upper limits are
            % shifted by equal amounts, otherwise they could exceed the
            % tolerance used by the categorical ruler to determine whether
            % the span is a whole number of categories.
            xLimits(2) = xLimits(1) + round(diff(xLimits));
            yLimits(2) = yLimits(1) + round(diff(yLimits));
            
            % Set the limits on the axes.
            hStrategy.setPanLimits(hAx, xLimits, yLimits);
        end
        
        function setPanLimits(hStrategy, hAx, xLimits, yLimits)
            % Update the limits due to a pan event. The incoming limits are
            % numeric, even though the underlying ruler is a categorical
            % ruler.
            
            % Set the limits directly on the data space to bypass the
            % categorical ruler, which would normally round the limits to
            % the nearest category. This allows for a continous pan.
            hDataSpace = hAx.DataSpace;
            hDataSpace.XLim = xLimits;
            hDataSpace.YLim = yLimits;
            
            % Update the chart limits so that the chart limits always
            % reflect the nearest categories. makeNonNumericLimits will
            % automatically snap the limits to the nearest categories, and
            % constrain the limits to the bounds of the chart.
            hChart = hStrategy.HeatmapChart;
            hChart.XLimits = hAx.XAxis.makeNonNumericLimits(xLimits);
            hChart.YLimits = hAx.YAxis.makeNonNumericLimits(yLimits);
        end
        
        function startPan(hStrategy, hDataSpace)
            import matlab.graphics.chart.internal.heatmap.LimitsEventData
            import matlab.graphics.chart.internal.heatmap.Controller
            
            % Calculate the data range from the chart.
            hChart = hStrategy.HeatmapChart;
            xRange = 0.5 + [0 numel(hChart.XDisplayData)];
            yRange = 0.5 + [0 numel(hChart.YDisplayData)];
            
            % Convert the data range to normalized units.
            hStrategy.DataRangeNorm = hStrategy.calculateNormalizedDataRange(hDataSpace, xRange, yRange);
            
            % Freeze the layout so that the layout doesn't jump around when
            % long labels enter/exit the limits.
            hChart.freezeLayout(false);
            
            % Attach a listener to the DragComplete event.
            hStrategy.DragListener = event.listener(hStrategy.DragSingleton,'DragComplete',@(~,~) hStrategy.stopPan);
            
            % Update the chart to allow continuous panning by stopping the
            % chart from pushing the numeric limits directly to the data
            % space.
            hChart.UpdateDataSpaceLimits = false;
            
            % Trigger the LimitsStart event with the starting limits.
            [xLimits, yLimits] = Controller.getLimitsForUndo(hStrategy.HeatmapChart);
            hStrategy.StartingXLimits = xLimits;
            hStrategy.StartingYLimits = yLimits;
            notify(hStrategy, 'LimitsStart', LimitsEventData(xLimits, yLimits));
        end
        
        function stopPan(hStrategy)
            import matlab.graphics.chart.internal.heatmap.LimitsEventData
            
            % Register that the drag has finished and clear the listener.
            hStrategy.MidPan = false;
            hStrategy.DragListener = event.listener.empty();
            
            % Restore the layout of the heatmap.
            hChart = hStrategy.HeatmapChart;
            hChart.thawLayout();
            
            % Disable continuous panning.
            hChart.UpdateDataSpaceLimits = true;
            
            % Trigger the LimitsStop event with the starting limits.
            xLimits = hStrategy.StartingXLimits;
            yLimits = hStrategy.StartingYLimits;
            notify(hStrategy, 'LimitsStop', LimitsEventData(xLimits, yLimits));
        end
    end
    
    methods (Static)
        function dataRangeNorm = calculateNormalizedDataRange(hDataSpace, xRange, yRange)
            % Convert the x and y range to normalized units.
            
            % Build a matrix of data points that extend the full range.
            pointsData = [xRange; yRange];
            
            % Transform the points from data to normalized units.
            I = eye(4);
            pointsWorld = matlab.graphics.internal.transformDataToWorld(hDataSpace, I, pointsData);
            dataRangeNorm = matlab.graphics.internal.transformWorldToNormalized(hDataSpace, I, pointsWorld);
        end
        
        function [xLimits, yLimits] = constrainLimits(xLimits, yLimits, xRange, yRange)
            % Constrain the limits so they do not exceed the full data
            % range by more than an allowed tolerance.
            scaleFactor = 10;
            tolerance = 0.05; % normalized units
            
            % Flip any dimension with reverse direction.
            pointsNorm = [xLimits xRange; yLimits yRange];
            flip = pointsNorm(:,4)<pointsNorm(:,3);
            pointsNorm(flip,:) = pointsNorm(flip,[1 2 4 3]);
            
            % Constrain the limits in normalized units.
            outsideRange = pointsNorm(:,[1 2]) - pointsNorm(:,[3 4]);
            scaledOutsideRange = sign(outsideRange).*min(abs(outsideRange)./scaleFactor,tolerance);
            shift = (pointsNorm(:,[3 4]) + scaledOutsideRange) - pointsNorm(:,[1 2]);
            shift = min(0,shift(:,2)) + max(0,shift(:,1));
            
            % Restore any dimension with reverse direction.
            pointsNorm = pointsNorm(:,[1 2]) + shift;
            pointsNorm(flip,:) = pointsNorm(flip,[2 1]);
            
            % Extract the constrained limits.
            xLimits = pointsNorm(1,:);
            yLimits = pointsNorm(2,:);
        end
    end
end
