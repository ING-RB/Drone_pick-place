classdef validator
    % The validator for the monitor object

    %   Copyright 2022-2024 The MathWorks, Inc.

    methods(Static)
        function mustBeAMetric(monitor, values)
            nonExistentMetrics = string(setdiff(values, monitor.Metrics));
            if ~isempty(nonExistentMetrics)
                ME = MException(message('shared_experimentmonitor:validator:MetricNotDefined', nonExistentMetrics(1)));
                throwAsCaller(ME);
            end
        end

        function mustHaveSameYScales(monitor, metricsToGroup)
            yscalesMap = monitor.Model.YScalesMap;
            subPlotMap = monitor.Model.SubPlotMap;

            axNames = [subPlotMap(metricsToGroup).Title];
            yscales = yscalesMap(axNames);
            yscales = unique(yscales);
            
            if ~isscalar(yscales)
                ME = MException(message('shared_experimentmonitor:validator:YScaleMismatchOnGrouping'));
				throwAsCaller(ME);
            end
        end

        function mustBeAnAxesName(userSpecifiedAxis, monitor, methodName)
            subPlotMap = monitor.Model.SubPlotMap;
            if numEntries(subPlotMap) == 0
                ME = MException(message('shared_experimentmonitor:validator:NoMetricsAdded', userSpecifiedAxis, methodName));
                throwAsCaller(ME);
            else
                existingAxesNames = [values(subPlotMap).Title];
                existingAxesNames = unique(existingAxesNames, "stable");

                if ~ismember(userSpecifiedAxis,existingAxesNames)
                    validAxesNames = strjoin(existingAxesNames, '", "');
                    ME = MException(message('shared_experimentmonitor:validator:AxesNotDefined',userSpecifiedAxis, validAxesNames));
                    throwAsCaller(ME);
                end
            end
        end

        function mustHaveUniqueValues(value)
            if numel(unique(value)) ~= numel(value)
                ME = MException(message('shared_experimentmonitor:validator:MustHaveUniqueValues'));
                throwAsCaller(ME);
            end
        end

        function mustNotReplace(oldMetrics, updatedMetrics, name)
            tf = all(ismember(oldMetrics, updatedMetrics));
            if ~tf
                msgFriendlyStringArray = """" + strjoin(updatedMetrics, {'","'}) + """";
                ME = MException(message('shared_experimentmonitor:validator:MustNotReplace', name, msgFriendlyStringArray));
                throwAsCaller(ME);
            end
        end

        function [step, metricNames, metricValues] = parseMetrics(metricData, step, metricName, metricValue)
            arguments
                metricData
                step {experiment.internal.validator.mustBeNumericScalarRealAndNonSparse(step, "step")}
            end

            arguments (Repeating)
                metricName {mustBeNonempty, mustBeTextScalar}
                metricValue
            end

            step = experiment.internal.validator.convertNumbersToDouble(step);

            numMetrics = numel(metricName);
            metricValues = zeros(1,numMetrics);
                       
            for i = 1:numMetrics
                thisMetricName = convertCharsToStrings(metricName{i});
                experiment.internal.validator.mustBeAnExistingName(thisMetricName, metricData, 'Metrics');

                thisMetricValue = metricValue{i};
                experiment.internal.validator.mustBeNumericScalarRealAndNonSparse(thisMetricValue,thisMetricName);
                metricValues(i) = experiment.internal.validator.convertNumbersToDouble(thisMetricValue);
            end

            metricNames = string(metricName);
            experiment.internal.validator.ensureStrictlyIncreasingStepValue(metricNames, metricData, step);

            % If metric names are not unique, take the last value only.
            [metricNames,idxs] = unique(metricNames,'last');
            metricValues = metricValues(idxs);
        end

        function [infoNames, infoValues] = parseInfo(infoData, infoName, infoValue)
            arguments
                infoData %#ok<INUSA>
            end

            arguments (Repeating)
                infoName {mustBeNonempty, mustBeTextScalar}
                infoValue 
            end

            numInfo = numel(infoName);
            infoValues = cell(1,numInfo);
            for i = 1:numInfo
                thisInfoName = convertCharsToStrings(infoName{i});
                experiment.internal.validator.mustBeAnExistingName(thisInfoName, infoData, 'Info');

                thisInfoValue = infoValue{i};
                experiment.internal.validator.validateInfo(infoData,thisInfoValue,thisInfoName);
                infoValues{i} = convertCharsToStrings(experiment.internal.validator.convertNumbersToDouble(thisInfoValue));
            end

            % If info names are not unique, take the last value only.
            [infoNames,idxs] = unique(string(infoName),'last');
            infoValues = infoValues(idxs);
        end

        function val = convertNumbersToDouble(val)
            if isnumeric(val)
                val = double(gather(val));
                if isa(val, 'dlarray')
                    val = extractdata(val);
                end
            end
        end

        function val = validateProgress(val)
            val = full(val);
            val = experiment.internal.validator.convertNumbersToDouble(val);
        end

        function mustBeNumericScalarRealAndNonSparse(val,name)
            try
                mustBeNonempty(val);
                mustBeScalarOrEmpty(val);
                mustBeNumeric(val);
                mustBeNonsparse(val);
                mustBeReal(val);
            catch ME
                ME = iWrapExceptionWithVariableName(ME,name);
                throwAsCaller(ME);
            end
        end

        function validateInfo(infoData, val, infoName)
            % Info accepts numeric (except for sparse and complex), logical,
            % or string.

            val = convertCharsToStrings(val);
            val = experiment.internal.validator.convertNumbersToDouble(val);

            try
                mustBeNonempty(val);
                mustBeScalarOrEmpty(val);
            catch ME
                ME = iWrapExceptionWithVariableName(ME,infoName);
                throwAsCaller(ME)
            end

            if ~isnumeric(val) && ~islogical(val) && ~isstring(val)
                ME = MException(message('shared_experimentmonitor:validator:InfoErrorType', infoName));
                throwAsCaller(ME);
            end

            if ~isstring(val)
                try
                    mustBeReal(val);
                    mustBeNonsparse(val);
                catch ME
                    ME = iWrapExceptionWithVariableName(ME,infoName);
                    throwAsCaller(ME);
                end
            end

            outputClass = class(val);
            isEmptyData = isempty(infoData.(infoName));
            infoClassName = class(infoData.(infoName));
            if ~strcmp(infoClassName, outputClass) && ~isEmptyData
                % Current type of Info value must match type of previous 
                % info values.
                ME = MException(message('shared_experimentmonitor:validator:InfoErrorTypeMismatch', ...
                    infoName, infoClassName));
                throwAsCaller(ME);
            end
        end

        function mustBeAnExistingName(name, data, msgHole)
            existingNames = string(fieldnames(data));
            try
                mustBeMember(name, existingNames);
            catch ME
                ME = MException(message('shared_experimentmonitor:validator:UndefinedName', name, msgHole));
                throwAsCaller(ME);
            end
        end

        function ensureStrictlyIncreasingStepValue(metricNames, metricData, step)
            % Check that for all metricNames that are being recorded, if
            % any metric's last step value is greater than or equal to the
            % current step value, then error out to ensure that all metrics'
            % step values are strictly increasing.
            numMetricNames = numel(metricNames);
            for i = 1:numMetricNames
                thisMetricName = metricNames(i);
                if ~isempty(metricData.(thisMetricName))
                    lastStep = metricData.(thisMetricName)(end,1);
                    if step <= lastStep
                        ME = MException(message('shared_experimentmonitor:validator:IndexCannotDecrease', thisMetricName, num2str(lastStep)));
                        throwAsCaller(ME);
                    end
                end
            end
        end
    end
end

function wrappedME = iWrapExceptionWithVariableName(ME, name)
wrappedME = MException(message("shared_experimentmonitor:validator:InvalidVariable", name, ME.message));
end