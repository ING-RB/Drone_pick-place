classdef Controller < handle
    % Controller for matlab.graphics.chart.HeatmapChart interactions.
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    properties
        LingerTime (1,1) double = 1
        ScrollZoomFactor = 1.1
        MaximumZoom = 1
        MinimumZoomStep = 2
    end
    
    properties (SetAccess = ?ChartUnitTestFriend)
        HeatmapChart
    end
    
    properties (Transient, NonCopyable, Access=?ChartUnitTestFriend)
        Figure
        AxesRulerHitArea
        
        Linger
        EnterDatapointListener
        ExitDatapointListener
        LingerDatapointListener
        
        Drag
        DragStartedListener
        DragCompleteListener
        MidDrag = false
        PreDrag = struct()
        
        Pan
        PanStrategy
        LimitsStartListener
        LimitsStopListener
        
        Highlight
        Datatip
        
        DataChangedListener
        
        DeleteListener
        
        ClickListener
        LastSortXBy = ''
        LastSortXDir = 'unsorted'
        LastSortYBy = ''
        LastSortYDir = 'unsorted'
        OriginalOrderX = {}
        OriginalOrderY = {}
        
        ScrollEvent
        ScrollListener
        CachedPoint = NaN(1,2)
        CachedIntersectionPoint = NaN(2,2)
        
        KeyPressListener
        KeyPressManager
        
        OldPointer = struct()
        
        ModeChangeListener
        
        OriginalView = struct();
        
        HitChartListener
    end
    
    methods
        function hController = Controller(hChart)
            % Create a hit area around the axes rulers.
            hController.AxesRulerHitArea = ...
                matlab.graphics.chart.internal.heatmap.AxesRulerHitArea;
            
            % Set the HeatmapChart property.
            if nargin == 1
                hController.HeatmapChart = hChart;
            end
        end
        
        function set.HeatmapChart(hController, hChart)
            % Update the HeatmapChart property.
            hController.HeatmapChart = hChart;
            
            % Set up the interactions on the HeatmapChart.
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
            
            % Get a handle to the heatmap chart.
            hChart = hController.HeatmapChart;
            
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
            
            import matlab.graphics.chart.internal.heatmap.Controller
            
            % Set HitTest on the Heatmap on.
            hHeatmap = hChart.Heatmap;
            hHeatmap.HitTest = 'on';
            
            % Move the axes ruler hit area to the new heatmap.
            hAx = hChart.Axes;
            hController.AxesRulerHitArea.Parent = hAx;
            
            % Delete the datatip so it is recreated the next time it is
            % used.
            hDatatip = hController.Datatip;
            if isscalar(hDatatip) && isvalid(hDatatip)
                delete(hDatatip);
            end
            
            % Delete the ruler highlight so it is recreated the next time
            % it is used.
            hHighlight = hController.Highlight;
            if isscalar(hHighlight) && isvalid(hHighlight)
                delete(hHighlight);
            end
            
            % Create a Linger object to track mouse motion.
            hLinger = hController.createLinger([hAx, hHeatmap]);
            hLinger.LingerTime = hController.LingerTime;
            hLinger.GetNearestPointFcn = @Controller.getNearestPointFcn;
            hController.Linger = hLinger;
            hController.EnterDatapointListener = event.listener(hLinger, ...
                'EnterObject', @(~,e) hController.enterEvent(e));
            hController.ExitDatapointListener = event.listener(hLinger, ...
                'ExitObject', @(~,e) hController.exitEvent(e));
            hController.LingerDatapointListener = event.listener(hLinger, ...
                'LingerOverObject', @(~,e) hController.lingerEvent(e));
            hLinger.enable();
            
            % Create a strategy for use by click-and-drag pan.
            hStrategy = matlab.graphics.chart.internal.heatmap.InteractionStrategy(hChart);
            hController.PanStrategy = hStrategy;
            hController.LimitsStartListener = event.listener(hStrategy, ...
                'LimitsStart', @(~,e) hController.limitsStart(e));
            hController.LimitsStopListener = event.listener(hStrategy, ...
                'LimitsStop', @(~,e) hController.limitsStop(e));
            
            % Create a callback to disable interactions before printing.
            behaviorProp = findprop(hChart, 'Behavior');
            if isempty(behaviorProp)
                behaviorProp = addprop(hChart, 'Behavior');
                behaviorProp.Hidden = true;
                behaviorProp.Transient = true;
            end
            hBehavior = hggetbehavior(hChart,'print');
            hBehavior.PrePrintCallback = @(hChart, ~) Controller.printEvent(hChart);
            
            % Add a listener to DataChanged events in the heatmap.
            hController.DataChangedListener = event.listener(hChart, ...
                'DataChanged', @hController.dataChangedEvent);
            
            % For matrix-based heatmap chart, datatipconfiguration property
            % remains empty and we don't initialize context-menu
            hController.HitChartListener = event.listener(hHeatmap, ...
                'Hit', @(e,d) hController.hitEventHandler(d));
            
            % Add a listener to delete the controller when the
            % corresponding Heatmap is deleted.
            hController.DeleteListener = event.listener(hChart, ...
                'ObjectBeingDestroyed', @(~,~) hController.delete());
            
            % Create an axes toolbar.
            [tb, hResetButton] = axtoolbar(hChart.Axes,'restoreview','Visible','on');
            
            if ~isempty(tb)
                tb.Serializable = 'off';
            end
            
            if ~isempty(hResetButton)
                hResetButton.ButtonPushedFcn = @(~,~) hController.restoreOriginalView();
            end
        end
        
        function setupListeners(hController, hFigure)
            % Set up interactions that do depend on the parent/figure.
            
            % Create a DragToReorder object to enable dragging tick labels.
            hChart = hController.HeatmapChart;
            hDrag = matlab.graphics.chart.internal.heatmap.DragToRearrange(hChart);
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
            
            % Create a Pan object to enable click-and-drag pan.
            hPan = matlab.graphics.interaction.uiaxes.Pan3D(hChart.Axes, ...
                hFigure, 'WindowMousePress', 'WindowMouseMotion', 'WindowMouseRelease');
            hController.Pan = hPan;
            hPan.strategy = hController.PanStrategy;
            hPan.enable();
            
            % Create ScrollEvent object to listen for scroll events.
            hScroll = hController.createScrollEvent(hFigure);
            hController.ScrollEvent = hScroll;
            hController.ScrollListener = event.listener(hScroll, ...
                'scroll', @(~,e) hController.scrollEvent(e));
            hScroll.enable();            
            
            % Create key press listener.
            hController.KeyPressListener = event.listener(hFigure, ...
                'KeyPress', @(~,e) hController.keypressEvent(e));
            
            % If moving from one figure to another, unregister with the old
            % figure before registering with the new figure.
            hManager = hController.KeyPressManager;
            if isscalar(hManager) && isvalid(hManager)
                matlab.graphics.interaction.internal.FigureKeyPressManager.unregisterObject(hChart, hManager);
            end
            
            % Register with the figure key press manager.
            keys = {'equal', 'add', 'hyphen', 'subtract', ...
                'leftarrow', 'rightarrow', 'uparrow', 'downarrow'};
            hController.KeyPressManager = ...
                matlab.graphics.interaction.internal.FigureKeyPressManager.registerObject(...
                hChart, keys);
            
            % Create a listener for changes to the figure mode.
            uigetmodemanager(hFigure);
            hModeManager = hFigure.ModeManager;
            hController.ModeChangeListener = hModeManager.listener( ...
                'CurrentMode', 'PostSet', @(~,e) hController.modeChangedEvent());
        end
        
        function enterEvent(hController, eventData)
            hChart = hController.HeatmapChart;
            if hChart.EnableInteractions
                hitObject = eventData.HitObject;
                if hitObject == hChart.Heatmap
                    enterCell(hController, eventData);
                else
                    enterRuler(hController, eventData);
                end
            end
        end
        
        function enterCell(hController, eventData)
            % Convert from data point index into x and y values.
            index = eventData.NearestPoint;
            [y,x] = hController.ind2sub(index);
            
            % Update the ruler highlight.
            hHighlight = hController.getHighlight(true);
            hHighlight.Position = [x y 0];
            hHighlight.OutlineLabels = 'fade';
            
            % Update the corresponding highlight labels.
            updateTickHighlight(hController, hHighlight, 'X', x)
            updateTickHighlight(hController, hHighlight, 'Y', y)
        end
        
        function enterRuler(hController, eventData)
            % Get the limits of the axes
            hChart = hController.HeatmapChart;
            hAx = hChart.Axes;
            xl = hAx.XAxis.NumericLimits;
            yl = hAx.YAxis.NumericLimits;
            
            % Determine the size of the color data.
            [ny, nx] = size(hChart.ColorDisplayData);
            
            % Determine which ruler is being hovered over.
            x = eventData.IntersectionPoint(1,1);
            y = eventData.IntersectionPoint(1,2);
            showHighlight = [false false];
            if nx > 0 && x >= xl(1) && x < xl(2) && (y <= yl(1) || y >= yl(2))
                x = round(x);
                y = -1;
                showHighlight(1) = true;
            elseif ny > 0 && y >= yl(1) && y < yl(2) && (x <= xl(1) || x >= xl(2))
                x = -1;
                y = round(y);
                showHighlight(2) = true;
            end
            
            % Update the ruler highlight.
            hHighlight = hController.getHighlight(any(showHighlight));
            hHighlight.Position = [x y 0];
            hHighlight.OutlineLabels = 'on';
            
            % Update the corresponding highlight label.
            if showHighlight(1)
                updateTickHighlight(hController, hHighlight, 'X', x)
            elseif showHighlight(2)
                updateTickHighlight(hController, hHighlight, 'Y', y)
            end
            
            % Update the cursor to show the open hand.
            if eventData.HitObject == hHighlight
                hFigure = ancestor(hChart, 'figure');
                hController.setPointer(hFigure,'hand');
            end
        end
        
        function exitEvent(hController, ~)
            % Hide the datatip.
            hController.getDatatip(false);
            
            % Hide the ruler highlight.
            hController.getHighlight(false);
            
            % Restore the original pointer.
            hController.restorePointer();
        end
        
        function clearInteractions(hController, abortPan, clearX, clearY)
            % Clear all interactions.
            
            % Abort any active drag event.
            if isscalar(hController.Drag)
                hController.Drag.abort();
            end
            
            % Abort any active drag pan event.
            if isscalar(hController.Pan) && (nargin < 2 || abortPan)
                hController.Pan.abort();
            end
            
            % Determine whether to clear x and/or y.
            clearX = nargin < 4 || clearX;
            clearY = nargin < 4 || clearY;
            
            % Get a handle to the highlight.
            hHighlight = hController.Highlight;
            
            % Clear the highlight if necessary.
            if isscalar(hHighlight) && isvalid(hHighlight)
                % Get the highlight position.
                pos = hHighlight.Position;
                
                % Clear x if the highlight is over the x-ruler.
                clearX = clearX && pos(1) > 0;
                
                % Clear y if hte highlight is over the y-ruler.
                clearY = clearY && pos(2) > 0;
                
                if clearX || clearY
                    % Hide any highlight or datatip.
                    exitEvent(hController);
                    
                    % Reset the linger timer.
                    hController.Linger.resetLinger();
                end
            end
        end
        
        function lingerEvent(hController, eventData)
            hitObject = eventData.HitObject;
            hChart = hController.HeatmapChart;
            hHeatmap = hChart.Heatmap;
            if hitObject == hHeatmap && hChart.EnableInteractions
                % Convert from data point index into x and y values.
                index = eventData.NearestPoint;
                [y,x] = hController.ind2sub(index);
                
                % Update the datatip position.
                hDatatip = hController.getDatatip(true);
                hDatatip.Position = [x y 0];
                hDatatip.LocatorSize = max(hHeatmap.ActualFontSize, eps);
                
                % Update the datatip string.
                hDatatip.String = hChart.getDataTipString([x y],...
                             hDatatip.LabelFontColor,hDatatip.PinnedValueFontColor);
                % User may remove all variables from datatip configuration.
                % In that case, instead of showing empty data tip, hide it.
                if isempty(hDatatip.String)
                    set(hDatatip,'Visible','off');
                end
            end
        end
        
        function limitsStart(hController, ~)
            % When a drag starts, disable the Linger object.
            hController.Linger.disable();
            
            % Clear all interactions except drag pan.
            clearInteractions(hController, false);
            
            % Record the original view.
            hController.saveOriginalView();
        end
        
        function limitsStop(hController, eventData)
            % When a drag completes, re-enable the Linger object.
            hController.Linger.enable();
            
            oldXLimits = eventData.StartingXLimits;
            oldYLimits = eventData.StartingYLimits;
            hChart = hController.HeatmapChart;
            [xLimits, yLimits] = hController.getLimitsForUndo(hChart);
            hController.registerZoomOrPanUndoRedo('Pan', hChart, oldXLimits, oldYLimits, xLimits, yLimits)
        end
        
        function dragStarted(hController, eventData)
            % When a drag starts, disable the Linger object.
            hController.Linger.disable();
            
            % Record that a drag event is occurring.
            hController.MidDrag = true;
            
            % Record the current data and limits for undo/redo.
            hChart = hController.HeatmapChart;
            [data, dataMode, limits, limitsMode] = ...
                hController.getDisplayDataAndLimits(hChart, upper(eventData.Axis));
            hController.PreDrag.Data = data;
            hController.PreDrag.DataMode = dataMode;
            hController.PreDrag.Limits = limits;
            hController.PreDrag.LimitsMode = limitsMode;
            
            % Record the original view.
            hController.saveOriginalView();
        end
        
        function dragComplete(hController, eventData)
            % When a drag completes, re-enable the Linger object.
            hController.Linger.enable();
            
            % Fix the pointer if necessary.
            hHighlight = hController.Highlight;
            if ~isequal(hHighlight, eventData.HitObject)
                hController.restorePointer();
            end
            
            if eventData.DragOccurred
                % Clear any stored ordering
                axis = upper(eventData.Axis);
                originalProp = ['OriginalOrder' axis];
                lastSort = ['LastSort' axis 'By'];
                hController.(lastSort) = '';
                hController.(originalProp) = {};
                
                % Register with undo menu.
                preDrag = hController.PreDrag;
                hController.registerReorderUndoRedo('Rearrange', ...
                    hController.HeatmapChart, axis, preDrag.Data, ...
                    preDrag.DataMode, preDrag.Limits, preDrag.LimitsMode);
            end
            
            % Clear the stored data and limits.
            hController.PreDrag = struct();
            hController.MidDrag = false;
        end
        
        function scrollEvent(hController, eventData)
            % Scroll event
            
            % Determine whether we hit the correct axes.
            hitAxes = ancestor(eventData.HitObject, 'matlab.graphics.axis.AbstractAxes', 'node');
            hChart = hController.HeatmapChart;
            hitCorrectAxes = isscalar(hitAxes) && hitAxes == hChart.Axes;
            
            % Check if we are in plot edit mode.
            hFigure = hController.Figure;
            plotEditMode = isactiveuimode(hFigure,'Standard.EditPlot');
            
            % Get the reported point and scroll count.
            pointFig = eventData.Point;
            scrollCount = eventData.VerticalScrollCount;
            
            % Scroll only works if you are hovering over the heatmap, no
            % keys are pressed, and we are not in plot edit mode.
            hasModifier = eventData.ControlPressed || eventData.ShiftPressed || eventData.AltPressed;
            if hitCorrectAxes && hChart.EnableInteractions && ~hasModifier && ~plotEditMode
                % Make sure the intersection point is valid.
                eventData.fixIntersectionPoint();
                
                % Zoom around the intersection point.
                pointData = eventData.IntersectionPoint(1:2);
                if ~any(isnan(pointData))
                    scrollZoom(hController, pointFig, pointData, scrollCount)
                end
            end
        end
        
        function scrollZoom(hController, pointFig, pointData, scrollCount)
            % Zoom the heatmap in response to a scroll event.
            
            % If you use scroll wheel zoom, the intersecion point under the
            % cursor will shift slightly because the limits round to the
            % nearest integer. However, because the IntersectionPoint is
            % coming from WindowMouseMotion instead of the scroll event,
            % the IntersectionPoint may be stale. If the point in figure
            % units and the IntersectionPoint have not changed, use the
            % updated IntersectionPoint from the cache.
            pointDataEvent = pointData;
            if isequal(pointData, hController.CachedIntersectionPoint(1,:)) && ...
                    isequal(pointFig, hController.CachedPoint)
                pointData = hController.CachedIntersectionPoint(2,:);
            end
            
            % Zoom around the specified point.
            pointData = hController.zoomOrPan(pointData, scrollCount, [0 0]);
            
            % Cache the point and updated intersecion point.
            hController.CachedPoint = pointFig;
            hController.CachedIntersectionPoint = [pointDataEvent; pointData];
        end
        
        function keypressEvent(hController, eventData)
            % Keypress within the figure.
            
            % Clear all interactions.
            clearInteractions(hController);
            
            % Get the figure and heatmap.
            hFigure = eventData.Source;
            hChart = hController.HeatmapChart;
            
            % Check if we are in plot edit mode.
            plotEditMode = isactiveuimode(hFigure,'Standard.EditPlot');
            
            % Make sure the heatmap is the current axes.
            currentAxes = hFigure.CurrentAxes;
            if isscalar(currentAxes) && currentAxes == hChart && ...
                    hChart.EnableInteractions && ~plotEditMode
                % Calculate how much to zoom or translate.
                translate = [0 0];
                zoom = 0;
                modifiers = eventData.Modifier;
                switch eventData.Key
                    case {'equal', 'add'}
                        if isequal(modifiers, {'shift'})
                            % Both '=' and '+' work for zooming in, so if
                            % only shift is pressed, ignore it.
                            modifiers = {};
                        end
                        zoom = -1;
                    case {'hyphen', 'subtract'}
                        zoom = 1;
                    case 'leftarrow'
                        translate = [-1 0];
                    case 'rightarrow'
                        translate = [1 0];
                    case 'uparrow'
                        translate = [0 -1];
                    case 'downarrow'
                        translate = [0 1];
                end
                
                % Keys only work if no modifiers are pressed.
                if ~isempty(modifiers)
                    zoom = 0;
                    translate = [0 0];
                end
                
                % Zoom or Pan
                if zoom ~= 0 || any(translate ~= 0)
                    hController.zoomOrPan([NaN NaN], zoom, translate);
                end
            end
        end
        
        function pointData = zoomOrPan(hController, pointData, scrollCount, translate)
            % Zoom the heatmap around the specified point.
            
            % Clear all interactions.
            clearInteractions(hController);
            
            % Get the size of the color data.
            hChart = hController.HeatmapChart;
            [ny,nx] = size(hChart.ColorDisplayData);
            
            % Get the numeric limits of the heatmap.
            [~,loc] = ismember(hChart.XLimits, hChart.XDisplayData);
            xLimits = loc + [-0.5 0.5];
            [~,loc] = ismember(hChart.YLimits, hChart.YDisplayData);
            yLimits = loc + [-0.5 0.5];
            
            % If the pointData is not specified, set it to the center.
            if isnan(pointData(1))
                pointData(1) = sum(xLimits)/2;
            end
            if isnan(pointData(2))
                pointData(2) = sum(yLimits)/2;
            end
            
            % Scroll or pan the limits.
            maxZoom = hController.MaximumZoom;
            minStep = hController.MinimumZoomStep;
            factor = hController.ScrollZoomFactor^(sign(scrollCount));
            [xLimits, pointData(1)] = hController.zoomOrPanOneDimension(xLimits, pointData(1), factor, translate(1), maxZoom, minStep, nx);
            [yLimits, pointData(2)] = hController.zoomOrPanOneDimension(yLimits, pointData(2), factor, translate(2), maxZoom, minStep, ny);
            
            % Convert limits from numbers to labels.
            if nx > 0
                xLimits = hChart.XDisplayData(xLimits)';
            else
                xLimits = hChart.XLimits;
            end
            if ny > 0
                yLimits = hChart.YDisplayData(yLimits)';
            else
                yLimits = hChart.YLimits;
            end
            
            % Register a zoom or pan operation with the undo menu.
            if factor < 1
                cmdName = 'Zoom In';
            elseif factor > 1
                cmdName = 'Zoom Out';
            else
                cmdName = 'Pan';
            end
            [oldXLimits, oldYLimits] = hController.getLimitsForUndo(hChart);
            hController.registerZoomOrPanUndoRedo(cmdName, hChart, oldXLimits, oldYLimits, xLimits, yLimits)
            
            % Record the original view.
            hController.saveOriginalView();
            
            % Update the limits of the Heatmap.
            hChart.XLimits = xLimits;
            hChart.YLimits = yLimits;
        end
        
        function clickEvent(hController, eventData)
            % Click on one of the sort icons.
            
            newState = eventData.NewState;
            sortByDim = upper(eventData.Axis);
            
            hHighlight = hController.Highlight;
            hChart = hController.HeatmapChart;
            
            % Abort early if interactions are disabled.
            if ~hChart.EnableInteractions
                hController.clearInteractions();
                return
            end
            
            switch sortByDim
                case 'X'
                    val = hHighlight.Position(1);
                    sortBy = hChart.XDisplayData{val};
                    hController.LastSortYBy = sortBy;
                    hController.LastSortYDir = newState;
                    sortFcn = @hChart.sorty;
                    limitsModeProp = 'YLimitsMode';
                    sortedDataProp = 'YDisplayData';
                    originalProp = 'OriginalOrderY';
                    sortedDim = 'Y';
                case 'Y'
                    val = hHighlight.Position(2);
                    sortBy = hChart.YDisplayData{val};
                    hController.LastSortXBy = sortBy;
                    hController.LastSortXDir = newState;
                    sortFcn = @hChart.sortx;
                    limitsModeProp = 'XLimitsMode';
                    sortedDataProp = 'XDisplayData';
                    originalProp = 'OriginalOrderX';
                    sortedDim = 'X';
            end
            
            % Read the data and limits before sorting.
            [data, dataMode, limits, limitsMode] = ...
                hController.getDisplayDataAndLimits(hChart, sortedDim);
            
            % Record the pre-sorted state.
            if isempty(hController.(originalProp))
                hController.(originalProp) = data;
            end
            
            % Record the original view.
            hController.saveOriginalView();
            
            % Sort the data.
            switch newState
                case 'ascending'
                    sortFcn(sortBy,'ascend');
                case 'descending'
                    sortFcn(sortBy,'descend');
                case 'unsorted'
                    % Reset the limits to auto in case the current limits
                    % are invalid with the original display data.
                    hChart.(limitsModeProp) = 'auto';
                    
                    % Resore the display data.
                    hChart.(sortedDataProp) = hController.(originalProp);
            end
            
            % Update the sorting icon.
            eventData.Source.State = newState;
            
            % Register the sort operation with the undo menu.
            hController.registerReorderUndoRedo('Sort', hChart, sortedDim, ...
                data, dataMode, limits, limitsMode);
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
        
        function hitEventHandler(hController, eventData)
            % Show context menu on the chart on right-clicking on the chart
            if eventData.Button == 3
                hController.HeatmapChart.openContextMenu(eventData);
            end
        end
        
        function dataChangedEvent(hController, ~, eventData)
            % React to changes in the heatmap chart data.
            
            if eventData.Matrix
                % ColorData changed, clear any visible interactions.
                hController.clearInteractions();
            elseif  (eventData.XDisplay || eventData.YDisplay) && ~hController.MidDrag
                % XDisplayData or YDisplayData changed, clear highlight if
                % it was impacted by the data that changed.
                hController.clearInteractions(true, eventData.XDisplay, eventData.YDisplay);
            end
            
            % Clear the original view if the XData or YData changes.
            clearx = eventData.XData;
            cleary = eventData.YData;
            if clearx || cleary
                hController.clearOriginalView(clearx, cleary)
            end
        end
    end

    methods (Access=protected)
        function hLinger = createLinger(~, varargin)
            hLinger = matlab.graphics.interaction.actions.Linger(varargin{:});
        end

        function hScroll = createScrollEvent(~, hFigure)
            hScroll = matlab.graphics.interaction.uiaxes.ScrollEvent(hFigure, ...
                'WindowScrollWheel', 'WindowMouseMotion');
        end
    end

    methods (Access=?ChartUnitTestFriend)
        function [y,x] = ind2sub(hController, index)
            [ny,nx] = size(hController.HeatmapChart.ColorDisplayData);
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
                        'Visible','off','HitTest','on');
                    hHighlight.Parent = hController.HeatmapChart.Axes;
                    hController.Highlight = hHighlight;
                    
                    % Add the highlight to the Drag object.
                    hController.Drag.Highlight = hHighlight;
                    
                    % Add the highlight to the Linger object.
                    hXIcon = hHighlight.XSortIcon;
                    hYIcon = hHighlight.YSortIcon;
                    hLinger = hController.Linger;
                    hLinger.Target = [hLinger.Target; hHighlight; hXIcon; hYIcon];
                    
                    % Add click listeners to the sort icons.
                    hController.ClickListener = event.listener(...
                        [hXIcon hYIcon], 'Click', @(~,e) hController.clickEvent(e));
                end
                
                hHighlight.Visible = 'on';
                hHighlight.Interpreter = hController.HeatmapChart.Interpreter;
            elseif isscalar(hHighlight) && isvalid(hHighlight)
                hHighlight.Visible = 'off';
            end
        end
        
        function hDatatip = getDatatip(hController, visible)
            % Deferred instantiation of the graphics tip.
            hDatatip = hController.Datatip;
            
            if visible
                if ~isscalar(hDatatip) || ~isvalid(hDatatip)
                    % Create a graphics tip object for use as a datatip.
                    hDatatip = matlab.graphics.shape.internal.GraphicsTip( ...
                        'Parent', hController.HeatmapChart.Axes, ...
                        'HitTest', 'off', 'PickableParts', 'none');
                    hDatatip.ScribeHost.HitTest = 'off';
                    hDatatip.ScribeHost.PickableParts = 'none';
                    hController.Datatip = hDatatip;
                    
                    % Make sure the ScripePeer does not capture clicks.
                    addlistener(hDatatip.ScribeHost.DisplayHandle, ...
                        'Reparent', @disableHitTestAfterReparent);
                end
                
                hDatatip.Visible = 'on';
                hDatatip.TextFormatHelper.Interpreter = hController.HeatmapChart.Interpreter;
            elseif isscalar(hDatatip) && isvalid(hDatatip)
                hDatatip.Visible = 'off';
            end
            
            function disableHitTestAfterReparent(o,~)
                % During the first update of GraphicsTip the DisplayHandle
                % (the text object that shows the datatip) is reparented
                % from the GraphicsTip into the ScribePeer. After that
                % happens, set the HitTest and PickableParts on the
                % ScribePeer off so it will not capture mouse events.
                scribePeer = ancestor(o,'matlab.graphics.shape.internal.ScribePeer','node');
                if ~isempty(scribePeer)
                    scribePeer.HitTest = 'off';
                    scribePeer.PickableParts = 'none';
                end
            end
        end
        
        function updateTickHighlight(hController, hHighlight, dim, val)
            % Get a handle to the heatmap chart.
            hChart = hController.HeatmapChart;
            
            % Get the property names.
            dim = upper(dim);
            dataProp = [dim 'DisplayData'];
            labelProp = [dim 'DisplayLabels'];
            tickLabelProp = [dim 'Label'];
            otherDim = char(mod(dim-'W',2)+'X');
            lastSort = ['LastSort' otherDim 'By'];
            lastSortDir = ['LastSort' otherDim 'Dir'];
            sortIcon = [dim 'SortIcon'];
            
            % Update the highlight label text.
            hHighlight.(tickLabelProp) = hChart.(labelProp)(val);
            
            % Get the data from the current row or column.
            switch dim
                case 'X'
                    colorData = hChart.ColorDisplayData(:,val);
                case 'Y'
                    colorData = hChart.ColorDisplayData(val,:);
            end
            
            % Update the sort icon.
            lastSortBy = hController.(lastSort);
            lastSortDir = hController.(lastSortDir);
            if strcmp(lastSortBy, hChart.(dataProp){val})
                if strcmp(lastSortDir, 'ascending') && issorted(colorData)
                    state = 'ascending';
                elseif strcmp(lastSortDir, 'descending') && issorted(colorData, 'descend')
                    state = 'descending';
                else
                    state = 'unsorted';
                end
            else
                state = 'unsorted';
            end
            hHighlight.(sortIcon).State = state;
        end
        
        function setPointer(hController, hFigure, pointer)
            % Save the current cursor.
            oldPointer.Name = hFigure.Pointer;
            oldPointer.CData = hFigure.PointerShapeCData;
            oldPointer.HotSpot = hFigure.PointerShapeHotSpot;
            
            % Update the cursor.
            try
                setptr(hFigure, pointer);
                hController.OldPointer = oldPointer;
            catch
                % Web figures do not support setting the Pointer.
            end
        end
        
        function restorePointer(hController)
            oldPointer = hController.OldPointer;
            if isfield(oldPointer, 'Name')
                hFigure = ancestor(hController.HeatmapChart,'figure');
                try
                    hFigure.Pointer = oldPointer.Name;
                    hFigure.PointerShapeCData = oldPointer.CData;
                    hFigure.PointerShapeHotSpot = oldPointer.HotSpot;
                    
                    % Clear out the saved pointer data.
                    hController.OldPointer = struct();
                catch
                    % Web figures do not support setting the Pointer.
                end
            end
        end
        
        function saveOriginalView(hController)
            % Save the original view.
            
            % Define the list of properties to store in the default view.
            xprops = {'XDisplayData', 'XDisplayDataMode', 'XLimits', 'XLimitsMode'};
            yprops = {'YDisplayData', 'YDisplayDataMode', 'YLimits', 'YLimitsMode'};
            
            % Get the saved original view.
            view = hController.OriginalView;
            
            % Get a handle to the heatmap.
            hChart = hController.HeatmapChart;
            
            % Save the current x view, but only if there is not a saved
            % view already.
            if ~isfield(view, 'x')
                view.x = get(hChart, xprops);
            end
            
            % Save the current y view, but only if there is not a saved
            % view already.
            if ~isfield(view, 'y')
                view.y = get(hChart, yprops);
            end
            
            % Update the saved original view.
            hController.OriginalView = view;
        end
        
        function restoreOriginalView(hController)
            % Save/restore the original view.
            
            % Define the list of properties to store in the default view.
            xprops = {'XDisplayData', 'XDisplayDataMode', 'XLimits', 'XLimitsMode'};
            yprops = {'YDisplayData', 'YDisplayDataMode', 'YLimits', 'YLimitsMode'};
            
            % Get the saved original view.
            view = hController.OriginalView;
            
            % Get a handle to the heatmap.
            hChart = hController.HeatmapChart;
            
            % Restore the original x view.
            if isfield(view, 'x')
                % Set the limits mode to auto first to prevent the
                % data from conflicting with the current limits.
                hChart.XLimitsMode = 'auto';
                
                % Restore the view properties.
                set(hChart, xprops, view.x);
            end
            
            % Restore the original y view.
            if isfield(view, 'y')
                % Set the limits mode to auto first to prevent the
                % data from conflicting with the current limits.
                hChart.YLimitsMode = 'auto';
                
                % Restore the view properties.
                set(hChart, yprops, view.y);
            end
        end
        
        function clearOriginalView(hController, clearx, cleary)
            % Clear the saved original view.
            
            % Get the saved original view.
            view = hController.OriginalView;
            
            % Clear the saved x view.
            if clearx
                view = rmfield(view, 'x');
            end
            
            % Clear the saved y view.
            if cleary
                view = rmfield(view, 'y');
            end
            
            % Update the saved original view.
            hController.OriginalView = view;
        end
    end
    
    methods (Static)
        function index = getNearestPointFcn(hitObject, eventData)
            import matlab.graphics.chart.internal.heatmap.Controller
            
            if isa(hitObject, 'matlab.graphics.chart.interaction.DataAnnotatable')
                index = hitObject.getNearestPoint(eventData.PointInPixels);
            else
                % Make sure the event data has a valid intersection point
                eventData.fixIntersectionPoint();
                
                % If we are not over the heatmap itself, calculate an index
                % by rounding the nearest intersection point.
                point = round(eventData.IntersectionPoint(1,1:2));
                
                % Encode the coordinates using imaginary numbers so that
                % the single number encodes both coordinates.
                index = sum(point.*[1 1i]);
            end
        end
        
        function [newLimits, newPoint] = zoomOrPanOneDimension(oldLimits, point, factor, translate, maxZoom, minStep, n)
            % Zoom or pan along one dimension.
            
            % Establish a minimum and maximum scroll factor to guarantee
            % that each zoom changes the limits by at least one category.
            oldRange = diff(oldLimits);
            if point < oldLimits(1) || point > oldLimits(2)
                % Ruler based constrained zoom. If the point is outside the
                % limits, do not zoom in this dimension, only zoom in the
                % other dimension.
                factor = 1;
            elseif factor < 1
                factor = min((oldRange-minStep)/oldRange, factor);
            elseif factor > 1
                factor = max((oldRange+minStep)/oldRange, factor);
            end
            
            % Apply zoom factor to calculate the new range.
            newRange = round(oldRange*factor);
            
            % Make sure the new range is at a minimum equal to the maxZoom,
            % and at a maximum equal to the full range.
            newRange = max(maxZoom, min(n, newRange));
            
            % Calculate the shift necessary to keep the same cell under the
            % cursor in the new range.
            newPoint = (point - oldLimits(1))*newRange/oldRange + 0.5;
            shift = round(point)-round(newPoint);
            
            % Pan the limits.
            shift = shift + translate;
            
            % Make sure the pan doesn't exceed the limits.
            shift = max(0, min(n-newRange, shift));
            
            % Calculate the new limits based on the left and range.
            newLimits = [0 newRange] + shift + 0.5;
            
            % Calculate the new point based on the new limits.
            newPoint = newPoint + shift;
            
            % Shift the limits so they refer to integer categories.
            newLimits = newLimits + [0.5 -0.5];
        end
        
        function [data, dataMode, limits, limitsMode] = getDisplayDataAndLimits(hChart, axis)
            % Get the property names.
            dataProp = [axis 'DisplayData'];
            dataModeProp = [axis 'DisplayDataMode'];
            limitsProp = [axis 'Limits'];
            limitsModeProp = [axis 'LimitsMode'];
            
            % Get the current data order and limits.
            data = hChart.(dataProp);
            dataMode = hChart.(dataModeProp);
            limits = hChart.(limitsProp);
            limitsMode = hChart.(limitsModeProp);
        end
        
        function registerReorderUndoRedo(cmdName, hChart, axis, oldData, oldDataMode, oldLimits, oldLimitsMode)
            % Register a reorder interaction with the undo menu.
            
            import matlab.graphics.chart.internal.heatmap.Controller
            
            % Get the current data order and limits.
            [newData, newDataMode, newLimits, newLimitsMode] = ...
                Controller.getDisplayDataAndLimits(hChart, axis);
            
            % Only register the undo operation if the order or limits changed.
            if ~isequal(oldData, newData) || ~isequal(oldLimits, newLimits) ...
                    || ~isequal(oldDataMode, newDataMode) ...
                    || ~isequal(oldLimitsMode, newLimitsMode)
                % Get the figure handle.
                hFigure = ancestor(hChart,'figure');
                
                % Use the object's proxy value in case the user deletes the
                % heatmap and then undoes the deletion.
                proxyChart = Controller.getProxyValueFromChart(hChart);
                
                % Generate the command for undo/redo.
                cmd.Name = cmdName;
                cmd.Function = @Controller.undoRedoReorder;
                cmd.Varargin = {hFigure, proxyChart, axis, newData, newDataMode, newLimits, newLimitsMode};
                cmd.InverseFunction = @Controller.undoRedoReorder;
                cmd.InverseVarargin = {hFigure, proxyChart, axis, oldData, oldDataMode, oldLimits, oldLimitsMode};
                
                % Register the undo command.
                uiundo(hFigure,'function',cmd);
            end
        end
        
        function undoRedoReorder(hFigure, proxyChart, axis, data, dataMode, limits, limitsMode)
            % Undo/Redo a reorder interaction.
            
            import matlab.graphics.chart.internal.heatmap.Controller
            
            % Get the object handle back from the proxy value.
            hChart = plotedit({'getHandleFromProxyValue', hFigure, proxyChart});
            
            % Make sure that the chart has not been deleted, and that there
            % is an original view stored. If there is no original view,
            % then most likely a DataChanged event has happened, and the
            % undo stack contains stale data.
            if isgraphics(hChart) && isscalar(hChart.Controller) && ...
                    isvalid(hChart.Controller) && ...
                    isfield(hChart.Controller.OriginalView,lower(axis))
                % Get the property names.
                dataProp = [axis 'DisplayData'];
                dataModeProp = [axis 'DisplayDataMode'];
                limitsProp = [axis 'Limits'];
                limitsModeProp = [axis 'LimitsMode'];
                
                % Set the limits mode to 'auto' to avoid an error when
                % setting the display data.
                hChart.(limitsModeProp) = 'auto';
                
                % Set the display data and display data mode.
                hChart.(dataProp) = data;
                hChart.(dataModeProp) = dataMode;
                
                % Set the limits and limits mode.
                hChart.(limitsProp) = limits;
                hChart.(limitsModeProp) = limitsMode;
            end
        end
        
        function [xLimits, yLimits] = getLimitsForUndo(hChart)
            % Collect the current limits, before the pan or zoom operation.
            if strcmp(hChart.XLimitsMode, 'manual')
                xLimits = hChart.XLimits;
            else
                xLimits = 'auto';
            end
            if strcmp(hChart.YLimitsMode, 'manual')
                yLimits = hChart.YLimits;
            else
                yLimits = 'auto';
            end
        end
        
        function registerZoomOrPanUndoRedo(cmdName, hChart, oldXLimits, oldYLimits, newXLimits, newYLimits)
            % Register a zoom or pan operation with the undo menu.
            
            import matlab.graphics.chart.internal.heatmap.Controller
            
            % Only register the undo operation if the limits have changed.
            if ~isequal(oldXLimits, newXLimits) || ~isequal(oldYLimits, newYLimits)
                % Get the figure handle.
                hFigure = ancestor(hChart,'figure');
                
                % Use the object's proxy value in case the user deletes the
                % heatmap and then undoes the deletion.
                proxyChart = Controller.getProxyValueFromChart(hChart);
                
                % Generate the command for undo/redo.
                cmd.Name = cmdName;
                cmd.Function = @Controller.undoRedoZoomOrPan;
                cmd.Varargin = {hFigure, proxyChart, newXLimits, newYLimits};
                cmd.InverseFunction = @Controller.undoRedoZoomOrPan;
                cmd.InverseVarargin = {hFigure, proxyChart, oldXLimits, oldYLimits};
                
                % Register the undo command.
                uiundo(hFigure,'function',cmd);
            end
        end
        
        function undoRedoZoomOrPan(hFigure, proxyChart, xLimits, yLimits)
            % Undo/Redo a pan or zoom operation.
            
            import matlab.graphics.chart.internal.heatmap.Controller
            
            % Get the object handle back from the proxy value.
            hChart = plotedit({'getHandleFromProxyValue', hFigure, proxyChart});
            
            if isgraphics(hChart)
                % Capture the current limits.
                [currentXLimits, currentYLimits] = Controller.getLimitsForUndo(hChart);
                try
                    % Attempt to restore the old limits.
                    hChart.xlim(xLimits);
                    hChart.ylim(yLimits);
                catch
                    % If restoring the old limits failed, make sure the
                    % limits are left in a consistent state.
                    hChart.xlim(currentXLimits);
                    hChart.ylim(currentYLimits);
                end
            end
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
    
    methods
        function set.LingerTime(hController, time)
            hController.LingerTime = time;
            hController.Linger.LingerTime = time; %#ok<MCSUP>
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
            % without also deleting the HeatmapChart.
            hChart = hController.HeatmapChart;
            if isscalar(hChart) && isvalid(hChart) && strcmp(hChart.BeingDeleted, 'off')
                % Set HitTest back to off on the Heatmap.
                hHeatmap = hChart.Heatmap;
                if isscalar(hHeatmap) && isvalid(hHeatmap)
                    hHeatmap.HitTest = 'off';
                end
                
                % Delete the axes ruler hit area.
                hAxesRulerHitArea = hController.AxesRulerHitArea;
                if isscalar(hAxesRulerHitArea) && isvalid(hAxesRulerHitArea)
                    delete(hAxesRulerHitArea);
                end
                
                % Delete the datatip.
                hDatatip = hController.Datatip;
                if isscalar(hDatatip) && isvalid(hDatatip)
                    delete(hDatatip);
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
                
                % Restore the default toolbar.
                hAxes = hChart.Axes;
                if isscalar(hAxes) && isvalid(hAxes)
                    hAxes.Toolbar = gobjects(0);
                end
                
                % Unregister with the figure key press manager.
                hManager = hController.KeyPressManager;
                if isscalar(hManager) && isvalid(hManager)
                    matlab.graphics.interaction.internal.FigureKeyPressManager.unregisterObject(hChart, hManager);
                end
            end
        end
        
        function hObj = saveobj(hObj) %#ok<MANU>
            % Do not allow users to save this object.
            error(message('MATLAB:Chart:SavingDisabled', ...
                'matlab.graphics.chart.internal.heatmap.Controller'));
        end
    end
end
