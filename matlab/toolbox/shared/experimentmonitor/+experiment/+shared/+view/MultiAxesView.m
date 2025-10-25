classdef MultiAxesView < handle
    % MultiAxesView  The widget for viewing multiple subplots

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        % MainComponent   (uipanel)  Main panel holding everything.
        MainComponent
    end

    properties (Access = private)
        % AnimatedLinesMap  dictionary mapping line names (metric names)
        % to line handles.
        AnimatedLinesMap

        % MarkerMap dictionary mapping line names (metric names) to an 
        % end of line marker object.
        MarkerMap

        % AxesMap  dictionary mapping axes names to axes handles
        % containing only one line (not grouped).
        AxesMap

        % GroupedAxesMap  dictionary mapping axes names to axes handles
        % containing multiple lines (grouped lines)
        GroupedAxesMap

        % AxesYScaleButtonMap  dictionary mapping axes names to their
        % y-scale button handles.
        AxesYScaleButtonMap

        % GroupedAxesYScaleButtonMap  dictionary mapping grouped axes names
        % to their y-scale button handles.
        GroupedAxesYScaleButtonMap

        % XLabel (string) x-label used for all the axes.
        XLabel

        % TiledLayout  (tiledlayout) Main tiledlayout holding the subplots
        TiledLayout

        % NextTileCounter Keeps track of the tile order to prevent filling
        % the positions of axes that have been deleted.
        NextTileCounter = 1;

        % Model (experiment.shared.model.Model)  View-model used by this
        % view to listen for updates.
        Model

        % Listeners  cell array of listeners on the model.
        Listeners
    end

    methods
        function this = MultiAxesView(parent, model)
            this.Model = model;

            % Get a weak reference of the `this` object and create some
            % listeners.
            weakThis = matlab.lang.WeakReference(this);
            this.Listeners{end+1} = listener(this.Model, 'XLabel', 'PostSet', @(~, evtData)weakThis.Handle.onXLabelPostSet(evtData));
            this.Listeners{end+1} = listener(this.Model, 'GroupPlot', @(~, evtData)weakThis.Handle.onGroupPlot(evtData));
            this.Listeners{end+1} = listener(this.Model, 'MetricsUpdated', @(~, evtData)weakThis.Handle.onMetricsUpdated(evtData));
            this.Listeners{end+1} = listener(this.Model, 'MetricsAdded', @(~, evtData)weakThis.Handle.onMetricsAdded(evtData));
            this.Listeners{end+1} = listener(this.Model, 'MetricDisplayNameWasSet', @(~, ~)weakThis.Handle.onMetricDisplayNameSet());
            this.Listeners{end+1} = listener(this.Model, 'YLimitsSet', @(~, ~)weakThis.Handle.onYLimitsSet());
            this.Listeners{end+1} = listener(this.Model, 'YScaleSet', @(~, evtData)weakThis.Handle.onYScaleSet(evtData));
            this.Listeners{end+1} = listener(this.Model, 'LegendLocationSet', @(~, ~)weakThis.Handle.onLegendLocationSet());

            % Create a uipanel before adding a tiledLayout to it. That's
            % because it's not currently possible to add a tiledlayout 
            % directly to a uigridlayout.
            this.MainComponent = uipanel(parent, ...
                "BorderType", "none", ...
                "Tag", "EXPERIMENT_MULTIAXES_MAINCOMPONENT");
            this.Listeners{end+1} = listener(this.MainComponent, 'ObjectBeingDestroyed', @(~,~)weakThis.Handle.onMainComponentDestroyed());
            
            this.TiledLayout = tiledlayout(this.MainComponent,...
                "vertical",...
                "Padding","tight",...
                "TileSpacing", "compact",...
                "Tag", "EXPERIMENT_MULTIAXES_TILEDLAYOUT");

            this.AnimatedLinesMap = dictionary(string.empty(), matlab.graphics.Graphics.empty());
            this.MarkerMap = dictionary(string.empty(), matlab.graphics.Graphics.empty());
            this.AxesMap = dictionary(string.empty(), matlab.graphics.Graphics.empty());
            this.GroupedAxesMap = dictionary(string.empty(), matlab.graphics.Graphics.empty());
            this.AxesYScaleButtonMap = dictionary(string.empty(), matlab.graphics.Graphics.empty());
            this.GroupedAxesYScaleButtonMap = dictionary(string.empty(), matlab.graphics.Graphics.empty());

            this.XLabel = this.Model.XLabel;
            this.updateAxes(this.Model.SubPlotMap);
            this.updateLines();
        end 
        
        % Note: this method is called from the
        % experiments.internal.CustomTrialRunner.detachTrainingAxes, 
        % after the training function execution is completed.
        % This method removes the references of the MATLAB Graphics objects
        % TiledLayout and MainComponent.
        % This makes sure that even if the trial runner object is deleted,
        % the MATLAB Graphics are still in memory and the training progress
        % plot is visible in the EM visualization panel 
        function detachUI(this)
            this.TiledLayout = [];
            this.MainComponent = [];
        end
        
        function delete(this)  
            for i = 1:length(this.Listeners)
                delete(this.Listeners{i});
            end
            this.Listeners = {};

            delete(values(this.AnimatedLinesMap));
            delete(values(this.MarkerMap));
            delete(values(this.AxesMap));
            delete(values(this.GroupedAxesMap));
            delete(values(this.AxesYScaleButtonMap));
            delete(values(this.GroupedAxesYScaleButtonMap));
            delete(this.TiledLayout);
            delete(this.MainComponent);
        end
    end

    methods(Access = private)
        function onXLabelPostSet(this, evtData)
            this.XLabel = evtData.AffectedObject.XLabel;

            axNames = keys(this.AxesMap);
            for i = 1:this.AxesMap.numEntries
                ax = this.AxesMap(axNames{i});
                xlabel(ax, this.XLabel, Interpreter="none");
            end

            groupedAxNames = keys(this.GroupedAxesMap);
            for i = 1:this.GroupedAxesMap.numEntries
                ax = this.GroupedAxesMap(groupedAxNames{i});
                xlabel(ax, this.XLabel, Interpreter="none");
            end
        end

        function onMetricDisplayNameSet(this)
            metricDisplayMap = this.Model.MetricDisplayNameMap;

            metricNames = keys(metricDisplayMap);
            metricDisplayNames = values(metricDisplayMap);
            numDisplayNames = length(metricNames);

            for i = 1:numDisplayNames
                anLine = this.AnimatedLinesMap(metricNames(i));
                anLine.DisplayName = metricDisplayNames(i);
                this.AnimatedLinesMap(metricNames(i)) = anLine;
            end
        end

        function onYLimitsSet(this)
            ylimsMap = this.Model.YLimitsMap;

            axesNames = keys(ylimsMap);
            yLimits = values(ylimsMap);
            numLimitsSet = length(axesNames);

            for i = 1:numLimitsSet
                thisAxesName = axesNames(i);
                if isKey(this.AxesMap, thisAxesName)
                    ax = this.AxesMap(thisAxesName);
                    ax.YLim = yLimits{i};
                    this.AxesMap(thisAxesName) = ax;
                end

                if isKey(this.GroupedAxesMap, thisAxesName)
                    ax = this.GroupedAxesMap(thisAxesName);
                    ax.YLim = yLimits{i};
                    this.GroupedAxesMap(thisAxesName) = ax;
                end
            end
        end

        function onYScaleSet(this,evtData)
            axisName = evtData.data{1};
            yscale = evtData.data{2};

            if isKey(this.AxesMap, axisName)
                this.AxesMap(axisName).YScale = yscale;
                this.AxesYScaleButtonMap(axisName).Value = yscale == "log";
            end

            if isKey(this.GroupedAxesMap, axisName)
                this.GroupedAxesMap(axisName).YScale = yscale;
                this.GroupedAxesYScaleButtonMap(axisName).Value = yscale == "log";
            end
        end

        function onLegendLocationSet(this)
            legendLocations = this.Model.LegendLocationMap;

            axesNames = keys(legendLocations);
            locations = values(legendLocations);
            numLocationsSet = length(axesNames);

            for i = 1:numLocationsSet
                thisAxesName = axesNames(i);
                if isKey(this.AxesMap, thisAxesName)
                    ax = this.AxesMap(thisAxesName);
                    ax.Legend.Location = locations(i);
                    this.AxesMap(thisAxesName) = ax;
                end

                if isKey(this.GroupedAxesMap, thisAxesName)
                    ax = this.GroupedAxesMap(thisAxesName);
                    ax.Legend.Location = locations(i);
                    this.GroupedAxesMap(thisAxesName) = ax;
                end
            end
        end

        function onGroupPlot(this, evtData)
            subPlotMap = evtData.data.SubPlotMap;

            this.updateAxes(subPlotMap);
        end

        function onMetricsAdded(this, evtData)
            subPlotMap = evtData.data.SubPlotMap;

            this.updateAxes(subPlotMap);
        end

        function updateAxes(this, subPlotMap)
            % Make sure to unparent all existing lines first in
            % order to ensure that their order will match the order
            % provided by subPlotMap instead of staying in the old order.
            lineNames = string(keys(this.AnimatedLinesMap));
            for i = 1:length(lineNames)
                l = this.AnimatedLinesMap(lineNames(i));
                m = this.MarkerMap(lineNames(i));

                l.Parent = [];
                m.Parent = [];
            end

            metricNames = string(keys(subPlotMap));
            for i = 1:length(metricNames)
                metricName = metricNames(i);
                axName = subPlotMap(metricName).Title;

                isGrouped = subPlotMap(metricName).IsGrouped;
                if isGrouped
                    axMapName = "GroupedAxesMap";
                    logBtnMapName = "GroupedAxesYScaleButtonMap";
                    appendTag = "GROUPED_";
                else
                    axMapName = "AxesMap";
                    logBtnMapName = "AxesYScaleButtonMap";
                    appendTag = "";
                end

                axesNameExists = this.(axMapName).isKey(axName);
                if axesNameExists
                    ax = this.(axMapName)(axName);
                    ax.Parent = this.TiledLayout;
                    ax.Layout.Tile = this.NextTileCounter;
                else
                    ax = nexttile(this.TiledLayout, this.NextTileCounter);
                    grid(ax, "on");
                    ax.FontSize = 10;
                    ax.YLim = this.Model.YLimitsMap{axName};
                    ax.YScale = this.Model.YScalesMap(axName);
                    ylabel(ax, axName, Interpreter="none");
                    xlabel(ax, this.XLabel, Interpreter="none");
                    ax.Tag = "EXPERIMENT_MULTIAXES_AXES_" + appendTag + upper(axName);

                    this.(axMapName)(axName) = ax;
                    this.addAxesToolbar(ax,axName,appendTag,logBtnMapName);
                end

                this.NextTileCounter = this.NextTileCounter + 1;
                legend(ax, {}, Interpreter="none", Location=this.Model.LegendLocationMap(axName));

                lineNameExists = this.AnimatedLinesMap.isKey(metricName);
                if lineNameExists
                    anLine = this.AnimatedLinesMap(metricName);
                    marker = this.MarkerMap(metricName);
                else
                    anLine = animatedline(ax,...
                        "LineWidth", 1.5,...
                        "SeriesIndex", 1,...
                        "DisplayName", this.Model.MetricDisplayNameMap(metricName),...
                        "Tag", "EXPERIMENT_MULTIAXES_LINE_" + upper(metricName));

                    marker = line(ax, NaN, NaN, Marker=".", MarkerSize=20,...
                        SeriesIndex = 1,...
                        Tag="EXPERIMENT_MULTIAXES_MARKER_" + upper(metricName));
                    marker.Annotation.LegendInformation.IconDisplayStyle = 'off';

                    this.AnimatedLinesMap(metricName) = anLine;
                    this.MarkerMap(metricName) = marker;
                end

                anLine.Parent = ax;
                marker.Parent = ax;
            end

            this.deleteAxesIfNoChildren();
            this.assignDifferentColorsInAxes();
        end

        function deleteAxesIfNoChildren(this)
            oldAxesNames = string(keys(this.AxesMap));
            for i = 1:length(oldAxesNames)
                oldAx = this.AxesMap(oldAxesNames(i));
                if isempty(oldAx.Children)
                    this.AxesMap = remove(this.AxesMap, oldAxesNames(i));
                    this.AxesYScaleButtonMap = remove(this.AxesYScaleButtonMap, oldAxesNames(i));
                    delete(oldAx);
                end
            end

            oldGroupedAxesNames = string(keys(this.GroupedAxesMap));
            for i = 1:length(oldGroupedAxesNames)
                oldAx = this.GroupedAxesMap(oldGroupedAxesNames(i));
                if isempty(oldAx.Children)
                    this.GroupedAxesMap = remove(this.GroupedAxesMap, oldGroupedAxesNames(i));
                    this.GroupedAxesYScaleButtonMap = remove(this.GroupedAxesYScaleButtonMap, oldGroupedAxesNames(i));
                    delete(oldAx);
                end
            end
        end

        function assignDifferentColorsInAxes(this)
            singleLineAxNames = string(keys(this.AxesMap));
            for i = 1:length(singleLineAxNames)
                ax = this.AxesMap(singleLineAxNames(i));

                % Find all the children that belong to this axes. This will
                % be a mix of AnimatedLine and Line objects. The latter
                % represents the markers.
                animatedLine = findall(ax, "Type", "AnimatedLine");
                marker = findall(ax, "Type", "Line");

                animatedLine.SeriesIndex = 1;
                marker.SeriesIndex = 1;
            end

            groupedAxNames = string(keys(this.GroupedAxesMap));
            for i = 1:length(groupedAxNames)
                ax = this.GroupedAxesMap(groupedAxNames(i));
                
                % Find all the children that belong to this axes. This will
                % be a mix of AnimatedLine and Line objects. The latter
                % represents the markers.
                animatedLines = findall(ax, "Type", "AnimatedLine");
                marker = findall(ax, "Type", "Line");

                numLines = length(animatedLines);
                for j = 1:numLines
                    animatedLines(numLines+1-j).SeriesIndex = j;
                    marker(numLines+1-j).SeriesIndex = j;
                end
            end
        end

        function onMetricsUpdated(this, evtData)

            metricNames = evtData.data.MetricNamesForPlotting;

            for i=1:numel(metricNames)
                xvalues = evtData.data.PlotData(i).XVal;
                metricValues = evtData.data.PlotData(i).MetricValues;
                addpoints(this.AnimatedLinesMap(metricNames(i)), xvalues, metricValues);
                marker = this.MarkerMap(metricNames(i));

                % We only put a marker on the final point of each plot,
                % regardless of how many points were drawn in the most
                % recent plot update.
                marker.XData = xvalues(end);
                marker.YData = metricValues(end);
            end
        end

        function updateLines(this)
            metricNames = this.Model.Metrics;
            for i = 1:length(metricNames)
                thisMetricData = this.Model.MetricData.(metricNames(i));
                if ~isempty(thisMetricData)
                    line = this.AnimatedLinesMap(metricNames(i));
                    xvals = thisMetricData(:, 1);
                    yvals = thisMetricData(:, 2);
                    addpoints(line, xvals, yvals);
                    marker = this.MarkerMap(metricNames(i));
                    marker.XData = xvals(end);
                    marker.YData = yvals(end);
                end
            end
        end

        function addAxesToolbar(this,ax,axName,appendTag,logButtonMapName)
            tb = axtoolbar(ax,{'export','datacursor','pan','zoomin','zoomout','restoreview'});

            yscaleButton = axtoolbarbtn(tb,'state',...
                Serializable=false,...
                Tag="EXPERIMENT_MULTIAXES_YSCALE_BUTTON_" + appendTag + upper(axName));
            yscaleButton.Icon = iGetPathToIcon();
            yscaleButton.Tooltip = iGetYScaleButtonTooltip();
            yscaleButton.ValueChangedFcn = @this.yscaleButtonPushed;
            yscaleButton.Value = this.Model.YScalesMap(axName) == "log";

            % Store yscale button in map
            this.(logButtonMapName)(axName) = yscaleButton;
        end

        function yscaleButtonPushed(this,~,evt)
            axName = string(evt.Axes.YLabel.String);
            switch evt.Value
                case matlab.lang.OnOffSwitchState.off
                    val = "linear";
                case matlab.lang.OnOffSwitchState.on
                    val = "log";
            end
            this.Model.setYScale(axName, val);
        end

        function onMainComponentDestroyed(this)
            % If the MainComponent gets deleted before the MultiAxesView,
            % then make sure to also delete the MultiAxesView so that all
            % listeners get deleted avoiding callbacks getting executed
            % with invalid graphics objects.
            delete(this);
        end
    end
end

function iconPath = iGetPathToIcon()
fullPathToThisFile = mfilename('fullpath');
parentDir = fileparts(fullPathToThisFile);
iconPath = fullfile(parentDir, 'semilogYPlot.png');
end

function str = iGetYScaleButtonTooltip()
str = getString(message("shared_experimentmonitor:multiAxesView:LogScaleTooltip"));
end
