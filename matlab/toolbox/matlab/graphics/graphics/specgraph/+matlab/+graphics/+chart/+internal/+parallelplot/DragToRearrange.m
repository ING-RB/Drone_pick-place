classdef DragToRearrange < matlab.graphics.interaction.uiaxes.Drag
    %

    %   Copyright 2019 The MathWorks, Inc.
    
    events (NotifyAccess = private)
        DragStarted
        DragComplete
    end
    
    properties
        ParallelCoordinatesChart
        Highlight
    end
    
    properties (Transient, NonCopyable, Hidden, Access = ?ChartUnitTestFriend)
        DragGap
        DragChart
        ChartXAxis
    end
    
    methods
        function hDrag = DragToRearrange(hChart, hHighlight)
            hFigure = ancestor(hChart, 'figure');
            hDrag = hDrag@matlab.graphics.interaction.uiaxes.Drag(hFigure, ...
                'WindowMousePress', 'WindowMouseMotion', 'WindowMouseRelease');
            hDrag.DragChart = hChart;
            ch = getInternalChildren(hChart);
            hDrag.ChartXAxis = ch.Axes.XAxis;
            
            hDrag.ParallelCoordinatesChart = hChart;
            if nargin >= 2
                hDrag.Highlight = hHighlight;
            end
            hDrag.enable();
        end
    end
    
    methods (Access = protected)
        function tf = validate(hDrag, ~, eventData)
            % Get the object that was hit.
            hitObject = eventData.HitObject;
            
            if any(hitObject == hDrag.Highlight) && hDrag.ParallelCoordinatesChart.EnableInteractions
                % Make sure the click occurred outside the axes, over one of
                % the two rulers.
                point = eventData.IntersectionPoint(1,1:2);
                [xr, yr] = matlab.graphics.internal.getRulersForChild(hitObject);
                xl = xr.NumericLimits;
                yl = yr.NumericLimits;
                
                outsideX = point(1) <= xl(1) || point(1) >= xl(2);
                outsideY = point(2) <= yl(1) || point(2) >= yl(2);
                tf = xor(outsideX, outsideY);
            else
                % You can only drag the highlight tick labels.
                tf = false;
            end
        end
        
        function customEventData = start(hDrag, ~, eventData)
            % Get a handle to the parallelplot chart.
            hChart = hDrag.ParallelCoordinatesChart;
            hFigure = ancestor(hChart,'figure');
            
            % Get X-Ruler limits
            hitObject = eventData.HitObject;
            xl = hDrag.ChartXAxis.NumericLimits;
            
            % Collect data needed for the rearrange operation.
            index = round(hitObject.Position(1));
            itemBeingMoved = index;
            limitsPadding = hitObject.Size/2;
            xl = xl + [limitsPadding -limitsPadding];
            
            % Prepare custom event data.
            customEventData.Object = hitObject;
            customEventData.Dimension = 1;
            customEventData.StartIndex = index;
            customEventData.NumericLimits = xl;
            customEventData.ItemBeingMoved = itemBeingMoved;
            customEventData.OldPointer.Name = hFigure.Pointer;
            customEventData.OldPointer.CData = hFigure.PointerShapeCData;
            customEventData.OldPointer.HotSpot = hFigure.PointerShapeHotSpot;
            
            % Update the cursor to show the closed hand.
            try
                setptr(hFigure, 'closedhand');
            catch
                % Web figures do not support setting the Pointer.
            end
            
            % Collect the event data.
            dragEventData = matlab.graphics.chart.internal.heatmap.DragToRearrangeEventData;
            dragEventData.Axis = 'X';
            dragEventData.Item = itemBeingMoved;
            dragEventData.StartIndex = index;
            dragEventData.EndIndex = index;
            dragEventData.DragOccurred = false;
            dragEventData.HitObject = hitObject;
            
            % Notify listeners that the drag is starting.
            notify(hDrag, 'DragStarted', dragEventData)
        end
        
        function move(hDrag, ~, eventData, customEventData)
            import matlab.graphics.interaction.internal.calculateIntersectionPoint
            
            % Determine which axes was hit.
            hChart = hDrag.ParallelCoordinatesChart;
            hitAxes = ancestor(eventData.HitPrimitive, 'matlab.graphics.axis.AbstractAxes', 'node');
            
            % Get the current intersection point. Once the drag has
            % started, allow the cursor to move outside the bounds of the
            % axes. To do this, the intersection point will need to be
            % calculated relative to the axes.
            point = eventData.IntersectionPoint;
            ch = getInternalChildren(hChart);
            if isempty(hitAxes) || hitAxes ~= ch.Axes || all(isnan(point))
                point = calculateIntersectionPoint(eventData.PointInPixels, ch.Axes);
            end
            
            % Determine the new location.
            dim = customEventData.Dimension;
            position = point(dim);
            
            if isfinite(position)                
                % Update the location of the tick label.
                hitObject = customEventData.Object;
                if isvalid(hitObject)
                    hitObject.Position(dim) = position;
                end
                
                % Update the order of the items.
                endIndex = round(position);
                itemBeingMoved = customEventData.ItemBeingMoved;
                hChart.moveRulerAndData(itemBeingMoved, endIndex, position);
            end
        end
        
        function stop(hDrag, ~, eventData, customEventData)
            % Lock the highlight to the nearest category.
            hitObject = customEventData.Object;
            dim = customEventData.Dimension;
            
            if isvalid(hitObject)
                index = round(hitObject.Position(dim));
                hitObject.Position(dim) = index;
            end
            
            % Finish drag and clean up drag related artifacts.
            hDrag.stopOrCancel(eventData, customEventData, index);
        end
        
        function cancel(hDrag, ~, eventData, customEventData)
            % Move highlight back to the starting category.
            hitObject = customEventData.Object;
            dim = customEventData.Dimension;
            index = customEventData.StartIndex;
            hitObject.Position(dim) = index;
            
            % Restore the original ordering of the categories.
            hChart = hDrag.ParallelCoordinatesChart;
            hChart.resetCoordinateDataWithCache();
            
            % Finish drag and clean up drag related artifacts.
            hDrag.stopOrCancel(eventData, customEventData, index);
        end
    end
    
    methods (Access = protected)
        function stopOrCancel(hDrag, eventData, customEventData, index)
            % Restore the label of the parallelplot.
            hChart = hDrag.ParallelCoordinatesChart;
            hChart.OriginalIndex = [];
            hChart.snapRulersAndData();
            
            % Collect the event data.
            dim = customEventData.Dimension;
            dragEventData = matlab.graphics.chart.internal.heatmap.DragToRearrangeEventData;
            dragEventData.Axis = char('W'+dim);
            dragEventData.Item = customEventData.ItemBeingMoved;
            dragEventData.StartIndex = customEventData.StartIndex;
            dragEventData.EndIndex = index;
            dragEventData.DragOccurred = customEventData.StartIndex ~= index;
            dragEventData.HitObject = eventData.HitObject;
            
            % Restore the original pointer.
            hFigure = ancestor(hChart,'figure');
            hFigure.Pointer = customEventData.OldPointer.Name;
            hFigure.PointerShapeCData = customEventData.OldPointer.CData;
            hFigure.PointerShapeHotSpot = customEventData.OldPointer.HotSpot;
            
            % Notify listeners that the drag is finished.
            notify(hDrag, 'DragComplete', dragEventData)
        end
    end
    
    methods (Hidden)
        function hObj = saveobj(hObj) %#ok<MANU>
            % Do not allow users to save this object.
            error(message('MATLAB:Chart:SavingDisabled', ...
                'matlab.graphics.chart.internal.parallelplot.DragToRearrange'));
        end
    end
end
