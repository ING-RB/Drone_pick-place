classdef(Abstract) Model < handle
    % The model used for the monitor object.
    
    %   Copyright 2022-2023 The MathWorks, Inc.

    properties(Abstract, SetAccess = private)
        % Metrics  string array of metric names
        Metrics

        % Info  string array of info names.
        Info

        % MetricData  Struct containing the metric values. The field names
        %   are the same as those specified by Metrics. Each field contains
        %   a matrix with two columns. The first column contains the iteration
        %   values and the second column contains the metric values.
        MetricData

        % InfoData  Struct containing the information values. The field
        %   names are the same as those specified by Info. Each field is a
        %   column vector containing the information values.
        InfoData

        % SubPlotMap Dictionary mapping metric names to a struct with
        %   fields Title and IsGrouped, where Title is the name of the axes
        %   this metric belongs to and IsGrouped is true if this metric name
        %   is grouped with other metrics on the same axes.
        SubPlotMap

        % ProgressWasSet (logical) Gets set to true by the Progress 
        % property setter.
        ProgressWasSet

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
        % value representing whether the log scale warning was shown.
        LogScaleWarningMap
    end

    properties(Abstract, SetObservable)
        % XLabel (string) x-label used for all the axes.
        XLabel

        % Status   User-defined training status, specified as a string or character vector.
        Status

        % Progress Training progress specified as a numeric scalar between 0 and 100.
        Progress

        %StopRequested Flag to stop training specified as a numeric or 
        %   logical 1 (true) or 0 (false). The value of this property 
        %   changes to true when the Stop button is clicked in training 
        %   progress plot.
        StopRequested

        % HasStopBeenAccessed (logical) Gets set to true by the Monitor if 
        % the Stop property has been accessed, or if the AllowStoppingInfo
        % property on the Monitor is set to false.
        HasStopBeenAccessed

        % StopReason   (string) the reason training has stopped.
        StopReason
    end

    properties (Abstract, SetObservable, AbortSet)
        % LogWarningString   (string) the log scale warning string
        LogWarningString
    end

    methods (Abstract)
        % recordMetrics  Record metric values in the training progress plot
        %   and the MetricData property of the Monitor object. 
        recordMetrics(this, xvalue, metricNames, metricValues, opts)

        % updateInfo  Update information values in the training progress
        %   plot and save the values in the InfoData property of the Monitor
        %   object.
        updateInfo(this, infoNames, infoValues, opts)

        % groupSubPlot  groups the specified metrics in a single training
        %   subplot with the title titleString. By default, each ungrouped 
        %   metric is in its own subplot.
        groupSubPlot(this, titleString, metricNames)

        % addMetrics  Adds new metrics names to the existing Metrics property
        addMetrics(this, newMetrics)

        % addInfo  Adds new info names to the existing Info property
        addInfo(this, newInfo)

        % setMetricDisplayNames  Changes the metrics display name
        setMetricDisplayNames(this, metricNames, metricDisplayNames)

        % setInfoDisplayNames  Changes the info display name
        setInfoDisplayNames(this, infoNames, infoDisplayNames)

        % setYLimits  Changes the axes y-limits
        setYLimits(this, axesNames, ylimits)

        % setYScale  Changes the axes y-scale.
        setYScale(this, axisName, yscale)

        % setLegendPosition  Changes the axes legend location
        setLegendLocation(this, axesNames, legendPosition)
    end

    events
        % MetricsUpdated  Fired when recordMetrics is called
        MetricsUpdated

        % GroupPlot Fired when groupSubPlot is called
        GroupPlot

        % MetricsAdded  Fired when addMetrics is called
        MetricsAdded
        
        % InfoAdded  Fired when addInfo is called
        InfoAdded
        
        % InfoUpdated  Fired when updateInfo is called
        InfoUpdated

        % ElapsedTimeUpdated   Fired when ElapsedTime is updated
        ElapsedTimeUpdated

        % MetricDisplayNameWasSet   Fired when setMetricDisplayNames is called
        MetricDisplayNameWasSet

        % InfoDisplayNameWasSet   Fired when setInfoDisplayNames is called
        InfoDisplayNameWasSet

        % YLimitsSet   Fired when setYLimits is called
        YLimitsSet

        % YScaleSet   Fired when setYScale is called
        YScaleSet

        % LegendLocationSet   Fired when setLegendLocation is called
        LegendLocationSet
    end
end