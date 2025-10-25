classdef(Abstract) Monitor < handle
    % Monitor   Interface for monitor object

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties (Abstract, SetObservable, AbortSet)
        %Metrics  Metric names, specified as a string, character vector, string array, or cell array of
        %   character vectors. Valid names begin with a letter, and can contain letters,
        %   digits, and underscores. Each metric appears in its own training subplot.
        Metrics (1,:) string {mustBeValidVariableName, ...
            experiment.internal.validator.mustHaveUniqueValues}

        %Info  Information names, specified as a string, character vector, string array, or cell array of
        %   character vectors. Valid names begin with a letter, and can contain letters,
        %   digits, and underscores. These names appear in the training
        %   progress plot.
        Info (1,:) string {mustBeValidVariableName, ...
            experiment.internal.validator.mustHaveUniqueValues}

        %Progress Training progress percentage, specified as a numeric 
        %   scalar between 0 and 100.
        Progress (1,1) {mustBeNumeric, mustBeReal,...
            mustBeInRange(Progress,0,100)}

        %XLabel Horizontal axis label in the training plot,
        %   specified as a string or character vector.
        XLabel (1,1) string

        %Status Training status, specified as a string or character vector.
        Status (1,1) string
    end

    properties (Abstract, SetObservable, SetAccess = private)
        %Stop Flag to stop training specified as a numeric or logical 1 (true)
        %   or 0 (false). The value of this property changes to true when you
        %   click Stop in training progress plot. (read-only)
        Stop (1,1) logical
    end

    properties(Abstract, SetAccess = private)
        %MetricData  Struct containing the metric values. The field names
        %   are the same as those specified by Metrics. Each field contains
        %   a matrix with two columns. The first column contains the iteration
        %   values and the second column contains the metric values.
        MetricData

        %InfoData  Struct containing the information values. The field
        %   names are the same as those specified by Info. Each field is a
        %   column vector containing the information values.
        InfoData
    end

    properties(Abstract)
        %Visible    Flag to specify whether to display the progress window.
        Visible (1,1) matlab.lang.OnOffSwitchState
    end

    methods(Abstract)
        %recordMetrics  Record metric values in the training progress plot
        %   and the MetricData property of the Monitor object.
        recordMetrics(this, xvalue, metricNames, metricValues)

        %updateInfo  Update information values in the training progress
        %   plot and save the values in the InfoData property of the Monitor
        %   object.
        updateInfo(this, infoNames, infoValues)

        %groupSubPlot  groups the specified metrics in a single training
        %   subplot with the title titleString. By default, each ungrouped
        %   metric is in its own subplot.
        groupSubPlot(this, titleString, metricNames)

        %yscale  sets the y-axis scale to "linear" or "log".
        yscale(this, axisName, scale)
    end

    events
      ReadStop
      MetricsUpdate
      InfoUpdate
      GroupPlot
      YScaleSet

      MetricDisplaySet
      YLimitsSet
      LegendLocationSet
      StopReasonSet
    end
end