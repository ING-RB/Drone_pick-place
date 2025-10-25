classdef MonitorModel < experiment.shared.model.Model
    % The view-model used for the monitor object.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties(SetAccess = private)
        % Metrics  string array containing the metric names
        Metrics = string.empty()

        % Info  string array containing the info names
        Info = string.empty()

        % MetricData   struct which stores all the metrics being recorded.
        % Fields are the metric names and values are the metric values
        % e.g. MetricData = struct("MetricName1", [x1 metricValue1; x2 metricValue2],
        %                           "MetricName2", [x1; metricValue1]);
        MetricData = struct();

        % LastPlottedIdx struct noting the last index in MetricsData that
        % was plotted
        LastPlottedIdx = struct();

        % Info   struct which stores all the info being recorded.
        % Fields are the info names and values are the info values
        % e.g. InfoData = struct("InfoName1", [infoValue1; infoValue2],
        %                        "InfoName2", [InfoValue1; infoValue2; infoValue3]);
        InfoData = struct();

        % SubPlotMap   Dictionary mapping metric names to a struct with
        %   fields Title and IsGrouped, where Title is the name of the axes
        %   this metric belongs to and IsGrouped is true if this metric name
        %   is grouped with other metrics on the same axes.
        %   for example, "MetricName1" --> struct(Title = AxesName1, IsGrouped = true),
        %                "MetricName2" --> struct(Title = AxesName1, IsGrouped = true),
        %                "MetricName3" --> struct(Title = AxesName2, IsGrouped = false)
        SubPlotMap

        % ProgressWasSet (logical) Gets set to true by the Progress
        % property setter.
        ProgressWasSet = false;

        % StartTime   (datetime) The time when training starts. Training
        % is considered to have started on construction of the model.
        StartTime

        % ElapsedTime   (duration) The elapsed time since training started.
        ElapsedTime

        % MetricDisplayNameMap  (dictionary) Maps the Metrics to their
        % display name.
        MetricDisplayNameMap

        % InfoDisplayNameMap  (dictionary) Maps the Info to their display
        % name.
        InfoDisplayNameMap

        % YLimitsMap  (dictionary) Maps the axes names to their y-limits.
        YLimitsMap

        % YScalesMap  (dictionary) Maps the axes names to their y-scales.
        YScalesMap

        % LegendLocationMap  (dictionary) Maps the axes names to their
        % legend locations
        LegendLocationMap

        % LogScaleWarningMap  (dictionary) Maps the axes names to a logical
        % value representing whether the log scale warning was shown (both
        % on the command window and the view).
        LogScaleWarningMap
    end

    properties (SetObservable)
        % XLabel (string) x-label used for all the axes.
        XLabel = ""

        % Status   User-defined training status, specified as a string or character vector.
        Status = ""

        % Progress   Training progress percentage,specified as a numeric
        % scalar between 0 and 100.
        Progress = 0

        %StopRequested Flag to stop training specified as a numeric or
        %   logical 1 (true) or 0 (false). The value of this property
        %   changes to true when the Stop button is clicked in training
        %   progress plot.
        StopRequested = false

        % HasStopBeenAccessed (logical) Gets set to true by the Monitor if
        % the Stop property has been accessed, or if the AllowStoppingInfo
        % property on the Monitor is set to false.
        HasStopBeenAccessed = false

        % StopReason   (string) the reason training has stopped.
        StopReason = ""

        % PlotFrequency the number of iterations to wait between plot
        % updates
        PlotFrequency = 1;


    end

    properties (SetObservable, AbortSet)
        % LogWarningString   (string) the log scale warning string
        LogWarningString
    end

    properties (Constant, Access = private)
        Version = 5
    end

    methods
        function s = saveobj(this)
            s.StopRequested = this.StopRequested;
            s.HasStopBeenAccessed = this.HasStopBeenAccessed;
            s.Metrics = this.Metrics;
            s.Info = this.Info;
            s.MetricData = this.MetricData;
            s.InfoData = this.InfoData;
            s.XLabel = this.XLabel;
            s.Status = this.Status;
            s.Progress = this.Progress;
            s.ProgressWasSet = this.ProgressWasSet;
            s.StopReason = this.StopReason;
            s.SubPlotMap = this.SubPlotMap;
            s.MetricDisplayNameMap = this.MetricDisplayNameMap;
            s.InfoDisplayNameMap = this.InfoDisplayNameMap;
            s.YLimitsMap = this.YLimitsMap;
            s.YScalesMap = this.YScalesMap;
            s.LegendLocationMap = this.LegendLocationMap;
            s.StartTime = this.StartTime;
            s.ElapsedTime = this.ElapsedTime;
            s.LogScaleWarningMap = this.LogScaleWarningMap;
            s.LogWarningString = this.LogWarningString;
            s.PlotFrequency = this.PlotFrequency;
            s.LastPlottedIdx = this.LastPlottedIdx;

            s.Version = this.Version;
        end
    end

    methods(Static)
        function this = loadobj(s)
            if iIsModelFrom2022b(s)
                versionNumber23a = 2;
                s = iUpgradeModelFrom2022bTo2023a(s, versionNumber23a);
            end

            if iIsModelFrom2023a(s)
                versionNumber23b = 3;
                s = iUpgradeModelFrom2023aTo2023b(s, versionNumber23b);
            end

            if iIsModelFrom2023b(s)
                versionNumber24a = 4;
                s = iUpgradeModelFrom2023bTo2024a(s, versionNumber24a);
            end

            if iIsModelFrom2024a(s)
                versionNumber24b = 5;
                s = iUpgradeModelFrom2024aTo2024b(s, versionNumber24b);
            end

            newObj = experiment.shared.model.MonitorModel();
            newObj.StopRequested = s.StopRequested;
            newObj.HasStopBeenAccessed = s.HasStopBeenAccessed;
            newObj.Metrics = s.Metrics;
            newObj.Info = s.Info;
            newObj.MetricData = s.MetricData;
            newObj.InfoData = s.InfoData;
            newObj.XLabel = s.XLabel;
            newObj.Status = s.Status;
            newObj.Progress = s.Progress;
            newObj.ProgressWasSet = s.ProgressWasSet;
            newObj.StopReason = s.StopReason;
            newObj.SubPlotMap = s.SubPlotMap;
            newObj.MetricDisplayNameMap = s.MetricDisplayNameMap;
            newObj.InfoDisplayNameMap = s.InfoDisplayNameMap;
            newObj.YLimitsMap = s.YLimitsMap;
            newObj.YScalesMap = s.YScalesMap;
            newObj.LegendLocationMap = s.LegendLocationMap;
            newObj.StartTime = s.StartTime;
            newObj.ElapsedTime = s.ElapsedTime;
            newObj.LogScaleWarningMap = s.LogScaleWarningMap;
            newObj.LogWarningString = s.LogWarningString;
            newObj.PlotFrequency = s.PlotFrequency;
            newObj.LastPlottedIdx = s.LastPlottedIdx;

            this = newObj;
        end
    end

    methods
        function this = MonitorModel()
            this.SubPlotMap = dictionary(string.empty(), struct.empty());
            this.MetricDisplayNameMap = dictionary(string.empty(), string.empty());
            this.InfoDisplayNameMap = dictionary(string.empty(), string.empty());
            this.YLimitsMap = dictionary(string.empty(), cell.empty());
            this.YScalesMap = dictionary(string.empty(), string.empty());
            this.LegendLocationMap = dictionary(string.empty(), string.empty());
            this.LogScaleWarningMap = dictionary(string.empty(), logical.empty());
            this.LogWarningString = string.empty();
            this.startTiming();
        end

        function addMetrics(this, value)
            % Get the newly added metrics first and initalize their data.
            newMetrics = setdiff(value, this.Metrics, "stable");
            numNewMetrics = length(newMetrics);

            this.MetricDisplayNameMap(newMetrics) = newMetrics;
            this.YLimitsMap(newMetrics) = repmat(iDefaultYLims(), [1 numNewMetrics]);
            this.YScalesMap(newMetrics) = repmat(iDefaultYScale(), [1 numNewMetrics]);
            this.LogScaleWarningMap(newMetrics) = false([1 numNewMetrics]);
            this.LegendLocationMap(newMetrics) = repmat(iDefaultLegendLocation(), [1 numNewMetrics]);

            for i=1:numNewMetrics
                this.MetricData.(newMetrics(i)) = double.empty(0,2);
                this.LastPlottedIdx.(newMetrics(i)) = 0;
            end

            this.Metrics = unique([value, this.Metrics], "stable");

            % Go through all metrics, if the metric already exists then hold
            % its value from SubPlotMap before removing and adding again its
            % entry to SubPlotMap in order to ensure the same order as
            % this.Metrics. Otherwise, if the metrics doesn't exist, it means
            % it's new and can be added to SubPlotMap with IsGrouped = false
            for i=1:length(this.Metrics)
                thisMetric = this.Metrics(i);
                if this.SubPlotMap.isKey(thisMetric)
                    mapValue = this.SubPlotMap(thisMetric);
                    this.SubPlotMap(thisMetric) = [];
                    this.SubPlotMap(thisMetric) = mapValue;
                else
                    this.SubPlotMap(thisMetric) = struct(Title = thisMetric,...
                        IsGrouped = false);
                end
            end

            payload.SubPlotMap = this.SubPlotMap;

            evtData = experiment.internal.EventData(payload);
            this.notify("MetricsAdded", evtData);
        end

        function addInfo(this, value)
            newInfo = setdiff(value, this.Info, "stable");

            this.InfoDisplayNameMap(newInfo) = newInfo;

            for i=1:length(newInfo)
                this.InfoData.(newInfo(i)) = double.empty(0,1);
            end

            this.Info = unique([value this.Info], "stable");

            payload.InfoNames = this.Info;

            evtData = experiment.internal.EventData(payload);
            this.notify("InfoAdded", evtData);
        end

        function groupSubPlot(this, titleString, metricNamesToBeGrouped)
            % Assign the y-scale of grouped metrics to be the same as what
            % their individual y-scales were before grouping. This will
            % have been validated by the monitor to be the same.
            axNamesToBeGrouped = this.getAxesNameFromMetric(metricNamesToBeGrouped);

            yscalesToBeGrouped = this.YScalesMap(axNamesToBeGrouped);
            yscalesToBeGrouped = yscalesToBeGrouped(1);
            this.YScalesMap(metricNamesToBeGrouped) = [];
            this.YScalesMap(titleString) = yscalesToBeGrouped;

            isWarningShown = this.LogScaleWarningMap(axNamesToBeGrouped);
            isWarningShown = any(isWarningShown);
            this.LogScaleWarningMap(metricNamesToBeGrouped) = [];
            this.LogScaleWarningMap(titleString) = isWarningShown;
            this.updateWarningAboutNegativeValuesInLogScale();

            this.YLimitsMap(metricNamesToBeGrouped) = [];
            this.YLimitsMap(titleString) = iDefaultYLims();
            this.LegendLocationMap(metricNamesToBeGrouped) = [];
            this.LegendLocationMap(titleString) = iDefaultLegendLocation();

            metricNames = this.Metrics;

            groupSubPlotKeys = keys(this.SubPlotMap);
            for idx = 1:length(groupSubPlotKeys)
                thisMetric = metricNames(idx);

                % If metric is already in the group to be created then
                % isolate it (i.e. give it its own titleString, same as
                % when adding new metrics)
                isMetricGrouped = this.SubPlotMap(thisMetric).IsGrouped;
                metricHasThisTitle = titleString == this.SubPlotMap(thisMetric).Title;

                if  isMetricGrouped && metricHasThisTitle
                    % remove key from dictionary before updating it so that
                    % the order of non-grouped metrics are taken from
                    % this.Metrics instead of metricsNamesToBeGrouped.
                    % (See comment below)
                    this.SubPlotMap(thisMetric) = [];
                    this.SubPlotMap(thisMetric) = struct(Title = thisMetric,...
                        IsGrouped = false);
                    this.YLimitsMap(thisMetric) = iDefaultYLims();
                    this.YScalesMap(thisMetric) = iDefaultYScale();
                    this.LegendLocationMap(thisMetric) = iDefaultLegendLocation();
                    this.LogScaleWarningMap(thisMetric) = false;
                end
            end

            for idx = 1:length(metricNamesToBeGrouped)
                % remove key from dictionary before updating it so that the
                % order of the grouped metrics are taken from
                % metricsNamesToBeGrouped instead of this.Metrics.
                this.SubPlotMap(metricNamesToBeGrouped(idx)) = [];
                this.SubPlotMap(metricNamesToBeGrouped(idx)) = struct(Title = titleString,...
                    IsGrouped = true);
            end

            payload.SubPlotMap = this.SubPlotMap;

            evtData = experiment.internal.EventData(payload);
            this.notify("GroupPlot", evtData);
        end

        function recordMetrics(this, xvalue, metricNames, metricValues, opts)
            % metricNames: string array of metric names which must already
            % exist in this.MetricData.
            % metricValues: vector of doubles same length as and corresponding
            % to the metricNames. This is equivalent to the "y values"
            % which all correspond to the same xvalue.
            arguments
                this
                xvalue
                metricNames
                metricValues
                opts.EnableLogging (1,1) logical = true
            end

            % Handle negative metrics
            this.adjustForNegativeMetrics(metricNames, metricValues);

            % Update Metric values
            if opts.EnableLogging
                this.accumulateMetricData(xvalue, metricNames, metricValues);
            end
            this.updateElapsedTime();

            % if the step aligns with PlotFrequency (only plot at multiples
            % of PlotFrequency). We plot new values whenever the remainder
            % between our xvalue and PlotFrequency is zero. Also, we plot
            % these values whenever a user requests to stop training. When
            % plot frequency is 1, every call to recordMetrics causes a
            % plot update with the single point that was provided with the
            % call (same as pre R2024b).
            maxStepsRecorded = max(structfun(@(x)size(x,1),this.MetricData));

            if rem(maxStepsRecorded,this.PlotFrequency) == 0 || this.StopRequested

                payload = struct();
                if opts.EnableLogging && this.PlotFrequency > 1 % Use the logged data when it is available, unless plotfrequency is 1
                    k = 1;
                    thereIsNewDataToPlot = false;
                    metricsToDraw = this.Metrics;
                    for i=1:(numel(metricsToDraw))
                        thisMetricName = metricsToDraw(i);
                        thisMetricData = this.MetricData.(thisMetricName);
                        startingIdx = this.LastPlottedIdx.(metricsToDraw(i))+1;
                        thisMetricUnplottedData = thisMetricData(startingIdx:end,:);

                        if ~isempty(thisMetricUnplottedData) %Only package the non-empty entries
                            payload.PlotData(k).XVal = thisMetricUnplottedData(:,1);
                            payload.PlotData(k).MetricValues = thisMetricUnplottedData(:,2);

                            % update lastPlottedIdx
                            this.LastPlottedIdx.(metricsToDraw(i)) = this.LastPlottedIdx.(metricsToDraw(i)) + size(thisMetricUnplottedData,1);
                            
                            k = k + 1;
                            thereIsNewDataToPlot = true;

                            payload.MetricNamesForPlotting = metricsToDraw;
                        end
                    end
                else %pre R2024b behavior as backup, in case any of the following are true:
                    %  1) Logging is disabled
                    %  2) PlotFrequency is equal to 1
                    for i=1:(numel(metricNames))
                        payload.PlotData(i).XVal = xvalue;
                        payload.PlotData(i).MetricValues = metricValues(i);

                        thereIsNewDataToPlot = true;

                        % update lastPlottedIdx
                        this.LastPlottedIdx.(metricNames(i)) = this.LastPlottedIdx.(metricNames(i)) + 1;
                    end
                    payload.MetricNamesForPlotting = metricNames;
                end

                % Once the payload of data for the plot update has been
                % packaged, we send it using an event to be drawn (if there
                % is data to plot)
                evtData = experiment.internal.EventData(payload);
                this.notify("MetricsUpdated", evtData);

            end
        end

        function adjustForNegativeMetrics(this, metricNames, metricValues)
            % For trainnet training, all metrics start with a lower
            % y-limit of 0, so metrics like accuracy render with sensible
            % bounds. However, there are cases where metrics can become
            % negative; in that case, we want to change the lower y-limit
            % to -Inf to allow rendering negative values.
            negativeMetrics = metricValues < 0;
            if any(negativeMetrics)
                axesNames = [this.SubPlotMap(metricNames(negativeMetrics)).Title];
                yscales = this.YScalesMap(axesNames);

                isInLogScale = ismember(yscales, "log");
                if any(isInLogScale)
                    logScaleAxes = axesNames(isInLogScale);
                    this.updateWarningAboutNegativeValuesInLogScale(logScaleAxes);
                end
                ylims = this.YLimitsMap(axesNames);
                isNegativeValueCompatible = cellfun(@(x)x(1)<0, ylims);

                % If we have at least 1 negative metric value, and this
                % metric's axis has the wrong y-limits for negative values.
                % Update the lowerbound y-limit for only this axis so it
                % displays negative values while keeping the upperbound
                % y-limit the same.
                if any(~isNegativeValueCompatible)
                    oldLimits = this.YLimitsMap(axesNames(~isNegativeValueCompatible));
                    newLimits = cellfun(@(x)iAssignLowerLimToNegativeInf(x), oldLimits, UniformOutput=false);
                    this.setYLimits(axesNames(~isNegativeValueCompatible), newLimits);
                end
            end
        end

        function accumulateMetricData(this, xValue, metricNames, metricValues)
            for i=1:length(metricNames)
                this.MetricData.(metricNames(i))(end+1, :) = [xValue, metricValues(i)];
            end
        end

        function set.PlotFrequency(this, plotFreq)
            this.PlotFrequency = experiment.internal.validator.validateProgress(plotFreq);
        end

        function updateInfo(this, infoNames, infoValues, opts)
            % infoNames: string array of info names which must already
            % exist in this.InfoData.
            % infoValues: cell array of doubles same length as and corresponding
            % to the infoNames.
            arguments
                this
                infoNames
                infoValues
                opts.EnableLogging (1,1) logical = true
            end

            % Update Info
            if opts.EnableLogging
                for i=1:length(infoNames)
                    isStringOrChar = isstring(infoValues{i}) || ischar(infoValues{i});
                    if isempty(this.InfoData.(infoNames(i))) && isStringOrChar
                        this.InfoData.(infoNames(i)) = infoValues{i};
                    else
                        this.InfoData.(infoNames(i))(end+1) = infoValues{i};
                    end
                end
            end
            this.updateElapsedTime();

            payload.InfoNames = infoNames;
            payload.InfoValues = infoValues;

            evtData = experiment.internal.EventData(payload);
            this.notify("InfoUpdated", evtData);
        end

        function setYScale(this, axisName, yscale)
            data  = {axisName, yscale};
            evtData = experiment.internal.EventData(data);

            this.YScalesMap(axisName) = yscale;
            this.notify("YScaleSet", evtData);

            % If a log warning is shown for an axes, and that axes switched
            % to linear scale, stop showing the warning.
            isLogWarningShown = this.LogScaleWarningMap(axisName);
            if isLogWarningShown && (yscale == "linear")
                this.LogScaleWarningMap(axisName) = false;

                this.updateWarningAboutNegativeValuesInLogScale();
            end

            % When switching to log scale, show a warning if there are any
            % existing negative values.
            if yscale == "log"
                metricsInAxes = this.getMetricsInAxes(axisName);
                for i = 1:numel(metricsInAxes)
                    vals = this.MetricData.(metricsInAxes(i));
                    anyNegativeVals = any(vals(:,2) < 0);
                    if anyNegativeVals
                        this.updateWarningAboutNegativeValuesInLogScale(axisName);
                        break;
                    end
                end
            end
        end

        function set.Progress(this, progress)
            this.Progress = progress;

            this.ProgressWasSet = true;

            this.updateElapsedTime();
        end

        function setMetricDisplayNames(this, metricNames, metricDisplayNames)
            this.MetricDisplayNameMap(metricNames) = metricDisplayNames;
            this.notify("MetricDisplayNameWasSet");
        end

        function setInfoDisplayNames(this, infoNames, infoDisplayNames)
            this.InfoDisplayNameMap(infoNames) = infoDisplayNames;
            this.notify("InfoDisplayNameWasSet");
        end

        function setYLimits(this, axesNames, ylims)
            this.YLimitsMap(axesNames) = ylims;
            this.notify("YLimitsSet");
        end

        function setLegendLocation(this, axesNames, legendLocation)
            this.LegendLocationMap(axesNames) = legendLocation;
            this.notify("LegendLocationSet");
        end

        function updateWarningAboutNegativeValuesInLogScale(this, allAxesWithNewLogWarning)
            % This method gets called in 3 cases:
            %   - negative values recorded, then the parent axes is log scaled
            %   - axes is log scaled, then negative values are recorded
            %   - an axes which has a warning gets grouped
            %   - an axes which has a warning gets linear scaled (removes
            %     axes from warning message)
            arguments
                this
                allAxesWithNewLogWarning = string.empty();
            end

            hasWarningBeenShown = this.LogScaleWarningMap(allAxesWithNewLogWarning);

            if isempty(allAxesWithNewLogWarning) || any(~hasWarningBeenShown)
                allAxesWithExistingLogWarning = this.getAxesWithExistingWarning();
                allAxesWithWarning = [allAxesWithNewLogWarning, allAxesWithExistingLogWarning];
                allAxesWithWarning = unique(allAxesWithWarning, "stable");
                if ~isempty(allAxesWithWarning)
                    axesNamesStr = strjoin(allAxesWithWarning, '", "');
                    warningMsg = message("shared_experimentmonitor:multiAxesView:LogNegativeWarning", axesNamesStr);
                    warningStr = string(warningMsg);
                    previousState = warning("off","backtrace");
                    c = onCleanup(@()warning(previousState));
                    warning(warningMsg);

                    % Mark the warning as shown to avoid showing the warning
                    % multiple times.
                    this.LogScaleWarningMap(allAxesWithNewLogWarning(~hasWarningBeenShown)) = true;
                else
                    warningStr = string.empty();
                end

                this.LogWarningString = warningStr;
            end
        end
    end


    methods(Access = private)
        function startTiming(this)
            this.StartTime = datetime("now");
            this.ElapsedTime = duration(0,0,0,0);
            this.notify("ElapsedTimeUpdated");
        end

        function updateElapsedTime(this)
            % Update ElapsedTime.
            this.ElapsedTime = datetime("now") - this.StartTime;
            this.notify("ElapsedTimeUpdated");
        end

        function axesWithExistingWarning = getAxesWithExistingWarning(this)
            allAxesNames = keys(this.LogScaleWarningMap);
            hasWarning = values(this.LogScaleWarningMap);
            axesWithExistingWarning = allAxesNames(hasWarning);
            axesWithExistingWarning = reshape(axesWithExistingWarning,1,[]);
        end

        function metricsInAxes = getMetricsInAxes(this, axName)
            allAxes = [values(this.SubPlotMap).Title];
            idxOfAx = ismember(allAxes, axName);
            allMetrics = keys(this.SubPlotMap);
            metricsInAxes = allMetrics(idxOfAx);
            metricsInAxes = reshape(metricsInAxes,1,[]);
        end

        function axNames = getAxesNameFromMetric(this, metrics)
            axNames = [this.SubPlotMap(metrics).Title];
            axNames = unique(axNames, "stable");
        end
    end
end

function tf = iIsModelFrom2022b(inStruct)
% For monitor model from 2022b, Version will be 1
tf = inStruct.Version == 1;
end

function tf = iIsModelFrom2023a(inStruct)
% For monitor model from 2023a, Version will be 2
tf = inStruct.Version == 2;
end

function tf = iIsModelFrom2023b(inStruct)
% For monitor model from 2023b, Version will be 3
tf = inStruct.Version == 3;
end

function tf = iIsModelFrom2024a(inStruct)
% For monitor model from 2024a, Version will be 4
tf = inStruct.Version == 4;
end

function inStruct = iUpgradeModelFrom2022bTo2023a(inStruct, version)
% Set properties that exist in 2022b by setting the version number
inStruct.Version = version;

% Set properties that don't exist in 2022b.
% Before 23a, ProgressWasSet is true only if the Progress property is set
% to anything other than 0.
inStruct.ProgressWasSet = inStruct.Progress ~= 0;
end

function inStruct = iUpgradeModelFrom2023aTo2023b(inStruct, version)
% Set properties that exist in 2023a by setting the version number
inStruct.Version = version;

% Set properties that don't exist in 2023a.
% Before 23b, StopReason will always have the same behavior as
% StopReason=""
inStruct.StopReason = "";

% Before 23b, the metric and info display names were always the same as the
% Metrics and Info property.
inStruct.MetricDisplayNameMap = dictionary(inStruct.Metrics, inStruct.Metrics);
inStruct.InfoDisplayNameMap = dictionary(inStruct.Info, inStruct.Info);
groupInfo = values(inStruct.SubPlotMap);
if iscell(groupInfo)
    axesNames = cellfun(@(x)x.Title, groupInfo);
else
    axesNames = arrayfun(@(x)x.Title, groupInfo);
end
axesNames = unique(axesNames);
numAxes = length(axesNames);
inStruct.YLimitsMap = dictionary(axesNames, repmat(iDefaultYLims(), [1 numAxes]));
end

function inStruct = iUpgradeModelFrom2023bTo2024a(inStruct, version)
% Set properties that exist in 2023b by setting the version number
inStruct.Version = version;

% Before 24a, the legend location was always "best" by default and the
% yscale was "linear" by default".
groupInfo = values(inStruct.SubPlotMap);
if iscell(groupInfo)
    axesNames = cellfun(@(x)x.Title, groupInfo);
else
    axesNames = arrayfun(@(x)x.Title, groupInfo);
end
axesNames = unique(axesNames);
numAxes = length(axesNames);
inStruct.LegendLocationMap = dictionary(axesNames, repmat(iDefaultLegendLocation(), [1 numAxes]));
inStruct.YScalesMap = dictionary(axesNames, repmat(iDefaultYScale(), [1 numAxes]));
inStruct.LogScaleWarningMap = dictionary(axesNames, false([1 numAxes]));
inStruct.LogWarningString = string.empty();
end

function inStruct = iUpgradeModelFrom2024aTo2024b(inStruct, version)
% Set properties that exist in 2022b by setting the version number
inStruct.Version = version;

% Set properties that don't exist in 2024a.
% Before 24a, PlotFrequency did not exist, so we set it to default.
inStruct.PlotFrequency = 1;

% LastPlottedIdx is a property introduced to support plot frequency
% control, so it also needs to be instantiated.
for i=1:numel(inStruct.Metrics)
    thisMetricData = inStruct.MetricData.(inStruct.Metrics(i));
    numPlots = size(thisMetricData,1);
    inStruct.LastPlottedIdx.(inStruct.Metrics(i)) = numPlots;
end
end

function x = iAssignLowerLimToNegativeInf(x)
x(1) = -Inf;
end

function val = iDefaultYScale()
val = "linear";
end

function val = iDefaultLegendLocation()
val = "best";
end

function val = iDefaultYLims()
val = {[-inf inf]};
end