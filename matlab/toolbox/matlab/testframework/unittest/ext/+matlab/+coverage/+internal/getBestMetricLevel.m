%
% Infer the "best" metric level from the provided result object's settings

%   Copyright 2023 The MathWorks, Inc.

function [metricLevel, validMetricNames] = getBestMetricLevel(resObj)

arguments
    resObj matlab.coverage.Result
end

% Get the list of available metrics
coverageMetricsServices = matlab.unittest.internal.coverage.locateCoverageReportMetricServices;
validMetricNames = [coverageMetricsServices.ValidMetricNames];

% The settings to test
cfgMetricPropNames = {'Decision', 'Condition', 'MCDC'};

% Use 'statement' as default
idxBestMetricLevel = 1;

cfgObjs = [resObj.Settings];

for ii = 1 : numel(cfgMetricPropNames)
    metric = cfgMetricPropNames{ii};
    if any([cfgObjs.(metric)])
        % The metric must be available
        idxM = find(strcmpi(metric, validMetricNames), 1);
        if ~isempty(idxM)
            % Increase the metric level
            idxBestMetricLevel = idxM;
        end
    end
end

metricLevel = char(validMetricNames(idxBestMetricLevel));
