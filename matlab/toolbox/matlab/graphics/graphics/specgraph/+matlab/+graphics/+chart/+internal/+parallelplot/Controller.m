classdef Controller < handle
    % Controller for matlab.graphics.chart.ParallelCoordinates interactions.
    
    %   Copyright 2023 The MathWorks, Inc.
    
    properties
        LingerTime (1,1) double = 1
    end
    
    properties (SetAccess = ?ChartUnitTestFriend)
        ParallelCoordinatesChart
    end
    
    properties (Transient, NonCopyable, Access={?ChartUnitTestFriend,...
            ?matlab.graphics.chart.ParallelCoordinatesPlot})
        Figure
        AxesRulerHitArea
        
        Linger
        EnterDatapointListener
        ExitDatapointListener
        
        Drag
        DragStartedListener
        DragCompleteListener
        MidDrag = false
        PreDrag = struct()
        
        Highlight
        Datatip
        
        DataChangedListener
        
        DeleteListener
        
        ClickListener
        
        CachedPoint = NaN(1,2)
        CachedIntersectionPoint = NaN(2,2)
                
        ModeChangeListener
        
        OriginalView = struct();
    end
    
    methods
        function hController = Controller(hChart)
            % Create a hit area around the axes rulers.
            hController.AxesRulerHitArea = ...
                matlab.graphics.chart.internal.heatmap.AxesRulerHitArea;
            
            % Set the ParallelCoordinatesChart property.
            if nargin == 1
                hController.ParallelCoordinatesChart = hChart;
            end
        end
        
        function set.ParallelCoordinatesChart(hController, hChart)
            % Update the ParallelCoordinatesChart property.
            hController.ParallelCoordinatesChart = hChart;
            
            % Set up the interactions on the ParallelCoordinatesChart.
            hController.setupInteractions(hChart);
            
            % Get a handle to the ancestor figure.
            hFigure = ancestor(hChart, 'figure');
            
            % Setup the figure listeners.
            if ~isempty(hFigure)
                hController.Figure = hFigure; %#ok<MCSUP>
                hController.setupListeners(hFigure);
            end
        end
        
        function updateListeners(hController)
            % Update the listeners due to a figure change.
            
            % Get a handle to the parallelplot chart.
            hChart = hController.ParallelCoordinatesChart;
            
            % Get a handle to the current figure ancestor.
            currentFigure = ancestor(hChart, 'figure');
            
            % Get the stored figure handle.
            hFigure = hController.Figure;
            
            % If the figure has changed, recreate the listeners.
            if ~isempty(currentFigure) && (isempty(hFigure) || hFigure ~= currentFigure)
                hController.Figure = currentFigure;
                hController.setupListeners(currentFigure);
            end
        end
    end
    
    methods (Access=?ChartUnitTestFriend)
        function setupInteractions(hController, hChart)
            % Set up interactions that do not depend on the parent/figure.
            
            import matlab.graphics.chart.internal.parallelplot.Controller
            
            % Move the axes ruler hit area to the new parallelplot.
            ch = getInternalChildren(hChart);
            hAx = ch.Axes;
            hController.AxesRulerHitArea.Parent = hAx;
            
            % Delete the ruler highlight so it is recreated the next time
            % it is used.
            hHighlight = hController.Highlight;
            if isscalar(hHighlight) && isvalid(hHighlight)
                delete(hHighlight);
            end
            
            % Create a Linger object to track mouse motion.
            hLinger = matlab.graphics.interaction.actions.Linger(hAx);
            hLinger.LingerTime = hController.LingerTime;
            hLinger.GetNearestPointFcn = @Controller.getNearestPointFcn;
            hController.Linger = hLinger;
            hController.EnterDatapointListener = event.listener(hLinger, ...
                'EnterObject', @(~,e) hController.enterEvent(e));
            hController.ExitDatapointListener = event.listener(hLinger, ...
                'ExitObject', @(~,e) hController.exitEvent(e));
            hLinger.enable();
            
            % Create a callback to disable interactions before printing.
            behaviorProp = findprop(hChart, 'Behavior');
            if isempty(behaviorProp)
                behaviorProp = addprop(hChart, 'Behavior');
                behaviorProp.Hidden = true;
                behaviorProp.Transient = true;
            end
            hBehavior = hggetbehavior(hChart,'print');
            hBehavior.PrePrintCallback = @(hChart, ~) Controller.printEvent(hChart);            
            
            % Add a listener to delete the controller when the
            % corresponding parallelplot is deleted.
            hController.DeleteListener = event.listener(hChart, ...
                'ObjectBeingDestroyed', @(~,~) hController.delete());
        end
        
        function setupListeners(hController, hFigure)
            % Set up interactions that do depend on the parent/figure.
            
            % Create a DragToRearrange object to enable dragging tick labels.
            hChart = hController.ParallelCoordinatesChart;
            hDrag = matlab.graphics.chart.internal.parallelplot.DragToRearrange(hChart);
            hController.Drag = hDrag;
            
            % Add the highlight to the drag object.
            hHighlight = hController.Highlight;
            if isscalar(hHighlight) && isvalid(hHighlight)
                hDrag.Highlight = hHighlight;
            end
            
            % Set up listeners on the drag object.
            hController.DragStartedListener = event.listener(hDrag, ...
                'DragStarted', @(~,e) hController.dragStarted(e));
            hController.DragCompleteListener = event.listener(hDrag, ...
                'DragComplete', @(~,e) hController.dragComplete(e));
            
            % Create a listener for changes to the figure mode.
            uigetmodemanager(hFigure);
            hModeManager = hFigure.ModeManager;
            hController.ModeChangeListener = hModeManager.listener( ...
                'CurrentMode', 'PostSet', @(~,e) hController.modeChangedEvent());
        end
        
        function enterEvent(hController, eventData)
            hChart = hController.ParallelCoordinatesChart;
            if hChart.EnableInteractions
                hitObject = eventData.HitObject;
                ch = getInternalChildren(hChart);
                if hitObject == ch.Axes
                    enterRuler(hController, eventData);
                end
            end
        end
        
        function enterRuler(hController, eventData)
            % Get the limits of the axes
            hChart = hController.ParallelCoordinatesChart;
            ch = getInternalChildren(hChart);
            hAx = ch.Axes;
            xl = hAx.XAxis.NumericLimits;
            ncols = hChart.NumColumns;
            
            % Determine the number of the X-Tick labels.
            nx = length(hAx.XAxis.TickLabels);
            
            % Determine whether x ruler is being hovered over. The HitArea
            % should be below the ruler and including the TickLabel
            x = eventData.IntersectionPoint(1,1);
            y = eventData.IntersectionPoint(1,2);
            showHighlight = false;
            if nx > 0 && x >= 0.5 && x<(ncols+0.5) &&...
                    y < hAx.YAxis(1).NumericLimits(1) % Hit only below the axes ruler
                x = round(x);
                y = realmax;
                showHighlight = true;
            end
            
            % Update the ruler highlight.
            hHighlight = hController.getHighlight(showHighlight);
            if isscalar(hHighlight) && isvalid(hHighlight)
                hHighlight.Position = [x y 0];
                hHighlight.OutlineLabels = 'on';
            end
            
            % Update the corresponding highlight label.
            if showHighlight
                updateTickHighlight(hController, hHighlight, x)
            end
            
            % Update the cursor to show the open hand.
            if (eventData.HitObject == hAx) && showHighlight
                hFigure = ancestor(hChart, 'figure');
                hController.setPointer(hFigure,'hand');
                disableDefaultInteractivity(hAx)
            end
        end
        
        function exitEvent(hController, eventData)
            if nargin > 1 && isscalar(hController.Highlight) &&...
                    isvalid(hController.Highlight) &&...
                    (isempty(eventData.HitObject) || ...
                    isscalar(eventData.HitObject) &&...
                    eventData.HitObject ~= hController.Highlight)
                % Hide the ruler highlight.
                hController.getHighlight(false);

                % Restore the original pointer.
                hController.restorePointer();
            end
        end
        
        function clearInteractions(hController, ~, ~, ~)
            % Clear all interactions.
            
            % Abort any active drag event.
            if isscalar(hController.Drag)
                hController.Drag.abort();
            end
            
            % Get a handle to the highlight.
            hHighlight = hController.Highlight;
            
            % Clear the highlight if necessary.
            if isscalar(hHighlight) && isvalid(hHighlight)
                % Hide any highlight or datatip.
                exitEvent(hController);
                
                % Reset the linger timer.
                hController.Linger.resetLinger();
            end
        end
        
        function dragStarted(hController, eventData)
            % When a drag starts, disable the Linger object.
            hController.Linger.disable();
            
            % Record that a drag event is occurring.
            hController.MidDrag = true;
            
            % Record the current data and limits for undo/redo.
            hChart = hController.ParallelCoordinatesChart;
            [data, dataMode, limits, limitsMode] = ...
                hController.getDisplayDataAndLimits(hChart, upper(eventData.Axis));
            hController.PreDrag.Data = data;
            hController.PreDrag.DataMode = dataMode;
            hController.PreDrag.Limits = limits;
            hController.PreDrag.LimitsMode = limitsMode;
        end
        
        function dragComplete(hController, eventData)
            % When a drag completes, re-enable the Linger object.
            hController.Linger.enable();
            
            % Fix the pointer if necessary.
            hHighlight = hController.Highlight;
            if ~isequal(hHighlight, eventData.HitObject)
                hController.restorePointer();
            end
            
            % Clear the stored data and limits.
            hController.PreDrag = struct();
            hController.MidDrag = false;
        end
        
        function modeChangedEvent(hController)
            % Enable or disable interactions in response to a change in
            % figure mode.
            
            currentMode = hController.Figure.ModeManager.CurrentMode;
            if isscalar(currentMode) && strcmp(currentMode.Name, 'Standard.EditPlot')
                % Disable the highlight effects.
                hController.Linger.disable();
                
                % Clear the current interactions.
                hController.clearInteractions();
            else
                % Re-enable highlight effects.
                hController.Linger.enable();
            end
        end
    end
    
    methods (Access=?ChartUnitTestFriend)
        function [y,x] = ind2sub(hController, index)
            [ny,nx] = size(hController.ParallelCoordinatesChart.ColorDisplayData);
            [y,x] = ind2sub([ny nx], index);
        end
        
        function hHighlight = getHighlight(hController, visible)
            % Deferred instantiation of the highlight.
            hHighlight = hController.Highlight;
            
            if visible
                if ~isscalar(hHighlight) || ~isvalid(hHighlight)
                    % Create highlight object for use when hovering over
                    % tick labels.
                    hHighlight = matlab.graphics.chart.internal.heatmap.Highlight(...
                        'Visible','off','HitTest','on','DisplaySortIcons',false);
                    ch = getInternalChildren(hController.ParallelCoordinatesChart);
                    hHighlight.Parent = ch.Axes;
                    hController.Highlight = hHighlight;
                    
                    % Add the highlight to the Drag object.
                    hController.Drag.Highlight = hHighlight;
                    
                    % Add the highlight to the Linger object.
                    hLinger = hController.Linger;
                    hLinger.Target = [hLinger.Target; hHighlight];
                end
                
                hHighlight.Visible = 'on';
            elseif isscalar(hHighlight) && isvalid(hHighlight)
                hHighlight.Visible = 'off';
            end
        end
        
        function updateTickHighlight(hController, hHighlight, val)
            % Get a handle to the parallelplot chart.
            hChart = hController.ParallelCoordinatesChart;
            
            % Update the highlight label text.
            hHighlight.XLabel = hChart.CoordinateTickLabels(val);
        end
        
        function setPointer(hController, hFigure, pointer)
            % Update the cursor.
            try
                setptr(hFigure, pointer);
            catch
                % Web figures do not support setting the Pointer.
            end
        end

        function restorePointer(hController)
            try
                hFigure = ancestor(hController.ParallelCoordinatesChart,'figure');
                hFigure.PointerMode = 'auto';
           catch
                % Web figures do not support setting the Pointer.
            end
            ch = getInternalChildren(hController.ParallelCoordinatesChart);
            enableDefaultInteractivity(ch.Axes)
        end
    end
    
    methods (Static)
        function index = getNearestPointFcn(hitObject, eventData)
            import matlab.graphics.chart.internal.parallelplot.Controller
            
            % Make sure the event data has a valid intersection point
            eventData.fixIntersectionPoint();
            
            % Ensure that the intersection point is on the axes XTickLabels
            % Otherwise return NaN
            if isa(hitObject,'matlab.graphics.axis.Axes') &&...
                    eventData.IntersectionPoint(2) < hitObject.YAxis(1).NumericLimits(1)
                
                % If we are not over the parallelplot itself, calculate an index
                % by rounding the nearest intersection point.
                point = round(eventData.IntersectionPoint(1,1:2));
                
                % Encode the coordinates using imaginary numbers so that
                % the single number encodes both coordinates.
                index = point(1);
                
            else
                index = NaN;
            end
        end
        
        function [data, dataMode, limits, limitsMode] = getDisplayDataAndLimits(hChart, ~)
            % Get the current data order and limits.
            data = hChart.CoordinateTickLabels;
            dataMode = 'auto';
            ch = getInternalChildren(hChart);
            limits = ch.Axes.XLim;
            limitsMode = 'auto';
        end
        
        function proxyChart = getProxyValueFromChart(hChart)
            try
                proxyChart = plotedit({'getProxyValueFromHandle',hChart});
            catch
                proxyChart = NaN;
            end
        end
        
        function printEvent(hChart)
            % Clear any interactions before printing.
            hChart.Controller.clearInteractions();
        end
    end
    
    methods (Hidden)
        function delete(hController)
            % Restore the original pointer.
            hController.restorePointer();
            
            % Explicitly delete the Linger object first to prevent the
            % linger event from firing during the delete process.
            hLinger = hController.Linger;
            if isscalar(hLinger) && isvalid(hLinger)
                delete(hLinger);
            end
            
            % Cleanup is only needed if the Controller is being deleted
            % without also deleting the ParallelCoordinatesChart.
            hChart = hController.ParallelCoordinatesChart;
            if isscalar(hChart) && isvalid(hChart) && strcmp(hChart.BeingDeleted, 'off')
                % Delete the axes ruler hit area.
                hAxesRulerHitArea = hController.AxesRulerHitArea;
                if isscalar(hAxesRulerHitArea) && isvalid(hAxesRulerHitArea)
                    delete(hAxesRulerHitArea);
                end
                
                % Delete the ruler highlight.
                hHighlight = hController.Highlight;
                if isscalar(hHighlight) && isvalid(hHighlight)
                    delete(hHighlight);
                end
                
                % Delete the Behavior property.
                behaviorProp = findprop(hChart,'Behavior');
                if isscalar(behaviorProp)
                    delete(behaviorProp);
                end
            end
        end
        
        function hObj = saveobj(hObj) %#ok<MANU>
            % Do not allow users to save this object.
            error(message('MATLAB:Chart:SavingDisabled', ...
                'matlab.graphics.chart.internal.parallelplot.Controller'));
        end
    end
end
