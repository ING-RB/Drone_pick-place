classdef Monitor < experiment.shared.Monitor
%EXPERIMENTS.MONITOR Monitor object to update results table and training plots
%   for custom training experiments.
%   When running a custom training experiment in Experiment Manager, use an
%   experiments.Monitor object to track the progress of the training, update
%   information fields in the results table, record values of the metrics used
%   by the training, and produce training plots.
%
%   For more information on custom training experiments,
%   see <a href="matlab:helpview('deeplearning','exp-mgr-create-custom-experiment')">Configure Custom Training Experiment</a>.
%
%   EXPERIMENTS.MONITOR properties:
%      Status     - Training status
%      Progress   - Training progress
%      Info       - Information column names
%      Metrics    - Metric column names
%      MetricData - Struct containing the metric values
%      InfoData   - Struct containing the information values
%      XLabel     - Horizontal axis label
%      Stop       - Flag to stop trial
%
%   EXPERIMENTS.MONITOR methods:
%      groupSubPlot   - Group metrics in experiment training plot
%      recordMetrics  - Record metric values in experiment results table and training plot
%      updateInfo     - Update information columns in experiment results table
%      yscale         - Sets y-axis scale in experiment training plot
%

% Copyright 2020-2024 The MathWorks, Inc.

    properties (SetObservable, AbortSet)

        %Progress Training progress for a trial, specified as a numeric scalar between 0 and 100.
        Progress  = 0

        %Status Training status for a trial, specified as a string or character vector.
        Status = 'Running'

        %Metrics Metric column names specified as a string, character vector, string array, or cell array of
        %   character vectors. Valid names begin with a letter, and can contain letters,
        %   digits, and underscores. These names appear as column headers in the experiment
        %   results table. Additionally, each metric appears in its own training subplot.
        %   To plot more than one metric in a single subplot, use the function <a href="matlab:help experiments.Monitor/groupSubPlot -displayBanner">groupSubPlot</a>.
        Metrics

        %Info Information column names, specified as a string, character vector, string array, or cell array of
        %   character vectors. Valid names begin with a letter, and can contain letters,
        %   digits, and underscores. These names appear as column headers in the experiment
        %   results table. The values in the information columns do not appear in the training plot.
        Info

        %XLabel Horizontal axis label in the training plot,
        %   specified as a string or character vector.
        %   Set this value before calling the function <a href="matlab:help experiments.Monitor/recordMetrics -displayBanner">recordMetrics</a>.
        XLabel = ""
    end

    properties(SetObservable, SetAccess = private)
        %Stop Flag to stop trial, specified as a numeric or logical 1 (true)
        %   or 0 (false). The value of this property changes to true when you
        %   click Stop in the Experiment Manager toolstrip or the results table.
        %   (read-only)
        Stop = false
    end

    properties(Dependent, SetAccess = private)
        %MetricData  Struct of vectors containing metric values. The field names
        %   are the same as those specified by Metrics. Each field contains
        %   a matrix with two columns. The first column contains the custom
        %   training loop step values and the second column contains the
        %   metric values.
        MetricData

        %InfoData  Struct of vectors containing information values. The field
        %   names are the same as those specified by Info. Each field is a
        %   column vector containing the information values.
        InfoData
    end

    methods
        function recordMetrics(monitor, step, varargin)
        %recordMetrics  Record metric values in experiment results table and training plot
        %
        %   recordMetrics(monitor,step,metricName,metricValue) records the specified metric value
        %   for a trial in the Experiment Manager results table and training plot.
        %
        %   recordMetrics(monitor,step,metricName1,metricValue1,...,metricNameN,metricValueN) records
        %   multiple metric values for a trial.
        %
        %   recordMetrics(monitor,step,metricsStruct) records the metric values specified by the
        %   structure metricsStruct.
        %

        if nargin == 3 & isstruct(varargin{1})
            str = varargin{1};
            varargin = namedargs2cell(str);
        end

        try
            [step, metricNames, metricValues] = experiment.internal.validator.parseMetrics(...
                monitor.MetricData,...
                step,...
                varargin{:});
        catch ME
            throw(ME);
        end

        monitor.Model.recordMetrics(step, metricNames, metricValues);

            args = [cellstr(metricNames); num2cell(metricValues)];
            metrics = struct(args{:});
            monitor.notify('MetricsUpdate', ...
                experiments.internal.ExpMgrEventData({step, metrics}));
        end

        function updateInfo(monitor, varargin)
        %updateInfo  Update information columns in experiment results table
        %   updateInfo(monitor,infoName,infoValue) updates the specified information
        %   column for a trial in the Experiment Manager results table.
        %
        %   updateInfo(monitor,infoName1,infoValue1,...,infoNameN,infoValueN) updates
        %   multiple information columns for a trial.
        %
        %   updateInfo(monitor,infoStruct) updates the information columns using
        %   the values specified by the structure infoStruct.
        %

        if nargin == 2 & isstruct(varargin{1})
            str = varargin{1};
            varargin = namedargs2cell(str);
        end

        try
            [infoNames, infoValues] = experiment.internal.validator.parseInfo(...
                monitor.InfoData,...
                varargin{:});
        catch ME
            throw(ME)
        end
        monitor.Model.updateInfo(infoNames, infoValues);

        args = [cellstr(infoNames); infoValues];
        info = struct(args{:});
        monitor.notify('InfoUpdate', ...
            experiments.internal.ExpMgrEventData({info}));
        end

        function groupSubPlot(monitor, groupName, metricNames)
        %groupSubPlot  Group metrics in experiment training plot
        %   groupSubPlot(monitor,groupName,metricNames) groups the specified metrics in
        %   a single training subplot with the y-axis label groupName. By
        %   default, Experiment Manager plots each ungrouped metric in its
        %   own training subplot.
        %
            arguments
                monitor
                groupName (1,1) string
                metricNames (1,:) string {experiment.internal.validator.mustHaveUniqueValues(metricNames),...
                                          experiment.internal.validator.mustBeAMetric(monitor, metricNames),...
                                          mustBeNonempty,...
                                          experiment.internal.validator.mustHaveSameYScales(monitor, metricNames)}
            end

            monitor.Model.groupSubPlot(groupName, metricNames);
            monitor.notify('GroupPlot', experiments.internal.ExpMgrEventData({groupName, metricNames}));
        end

        function yscale(monitor, axisName, scale)
            %yscale  sets the y-axis scale to "linear" or "log"
            %
            %   yscale(monitor,axisName,scale) sets the y-scale of the
            %   specified axis axisName to scale. By default, each axis is
            %   set to linear scale.
            arguments
                monitor
                axisName (1,1) string {experiment.internal.validator.mustBeAnAxesName(axisName, monitor, "yscale")}
                scale (1,1) string
            end

            % Don't use validatestring inside FAV as validatestring supports
            % partial matching and FAV doesn't set the argument to the output
            % of the validation function.
            scale = validatestring(scale, ["linear","log"]);

            data  = {axisName, scale};
            evtData = experiment.internal.EventData(data);
            monitor.notify("YScaleSet", evtData);

            monitor.Model.setYScale(axisName, scale);
        end
    end

    methods (Hidden = true)
        function monitor = Monitor()
            monitor.Model = experiment.shared.model.MonitorModel();
        end

        function stop(monitor, reason)
            % This method should get called at the end of training in order
            % to display the stop reason as well as disable the stop
            % button.
            monitor.notify('StopReasonSet', ...
                experiments.internal.ExpMgrEventData(reason));
        end

        function recordMetricsWithoutValidation(monitor, step, varargin)
            if isempty(varargin) % this is a temporary workaround
                return
            end
            metricNames = [varargin{1:2:end}];
            metricValues = [varargin{2:2:end}];

            monitor.Model.recordMetrics(step, metricNames, metricValues);

            args = [cellstr(metricNames); num2cell(metricValues)];
            metrics = struct(args{:});
            monitor.notify('MetricsUpdate', ...
                experiments.internal.ExpMgrEventData({step, metrics}));
            matlab.graphics.internal.drawnow.limitrate(600);
        end

        function updateInfoWithoutValidation(monitor, varargin)
            infoNames = [varargin{1:2:end}];
            infoValues = varargin(2:2:end);

            monitor.Model.updateInfo(infoNames, infoValues);

            args = [cellstr(infoNames); infoValues];
            info = struct(args{:});
            monitor.notify('InfoUpdate', ...
                experiments.internal.ExpMgrEventData({info}));
        end

        function setMetricDisplayNames(monitor, metricNames, metricDisplayNames)
            monitor.notify('MetricDisplaySet', ...
                experiments.internal.ExpMgrEventData({metricNames, metricDisplayNames}));
        end

        function setInfoDisplayNames(monitor, infoNames, infoDisplayNames)
            monitor.Model.setInfoDisplayNames(infoNames, infoDisplayNames);
        end

        function setYLimits(monitor, axesNames, ylims)
            monitor.notify('YLimitsSet', ...
                experiments.internal.ExpMgrEventData({axesNames, ylims}));
        end

        function setLegendLocation(monitor, axesNames, legendLocation)
             monitor.notify('LegendLocationSet', ...
                experiments.internal.ExpMgrEventData({axesNames, legendLocation}));
        end
    end
    methods
        function set.Metrics(monitor, newVal)
            experiment.internal.validator.mustNotReplace(monitor.Metrics, newVal, "Metrics");

            if (~strcmp(monitor.optimizableMetricName, "") && ~(ismember(monitor.optimizableMetricName, newVal)))
                 ME = MException(message('experiments:customExperiment:InvalidCustomMetricName', monitor.optimizableMetricName));
                 throwAsCaller(ME);
            end

            monitor.Model.addMetrics(newVal);

            monitor.Metrics = monitor.Model.Metrics;
        end

        function set.Info(monitor, newVal)
            experiment.internal.validator.mustNotReplace(monitor.Info, newVal, "Info");

            monitor.Model.addInfo(newVal);

            monitor.Info = monitor.Model.Info;
        end

        function set.Progress(monitor, newVal)
            monitor.Progress = experiment.internal.validator.validateProgress(newVal);
        end

        function metricData = get.MetricData(monitor)
            metricData = monitor.Model.MetricData;
        end

        function infoData = get.InfoData(monitor)
            infoData = monitor.Model.InfoData;
        end

        function set.XLabel(monitor, newVal)
            monitor.XLabel = newVal;
        end

        function val = get.Stop(monitor)
            monitor.notify('ReadStop');
            val = monitor.Stop;
        end
    end

    properties (GetAccess = ?experiment.internal.validator, SetAccess=private)
        Model
    end

    properties (Hidden = true)
        optimizableMetricName = ""
    end

    properties (Hidden = true, Transient)
        Visible = true
    end

    methods (Hidden = true)
        function setStopFlag(this, val)
            this.Stop = val;
        end
    end
end
