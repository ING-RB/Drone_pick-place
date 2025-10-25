classdef CoverageMetricsService < matlab.unittest.internal.services.Service
    % This class is undocumented and will change in a future release.

    % CoverageMetricsService - Interface for coverage metrics addition services.

    %  Copyright 2021-2024 The MathWorks, Inc.

    properties(Abstract, SetAccess = private)
        ValidMetricNames (1,:) string
    end
   
    methods (Abstract)
        createMetricHandlerAndCollector(service,value)
        updateLiaisonWithFilterData(service, liaison)
    end
    
    methods(Sealed)
        function fulfill(services, liaison)
            import matlab.unittest.internal.coverage.metrics.MetricHandler

            locatedValidMetricNames = [services.ValidMetricNames];
            inputMetricNames = liaison.MetricName;
            invalidMetric = setdiff(inputMetricNames,locatedValidMetricNames);
            if ~isempty(invalidMetric)
                 error(message('MATLAB:unittest:CodeCoveragePlugin:InvalidMetric'));
            end

            % generate metric handlers if all metric names are valid
            [metricHandlers, builtInFcnHandles, licenseValidCell] = arrayfun(@(s) s.createMetricHandlerAndCollector(liaison.MetricName), services, 'UniformOutput', false);
            assert(numel(services) <= 2 ,'The number of services must be limited to two or less for identifying the CollectorBuiltIn correctly from the service classes.')
            liaison.MetricHandler = [metricHandlers{:}];
            liaison.CollectorBuiltIn = builtInFcnHandles(end);
            if ~all([licenseValidCell{:}])
                liaison.LicenseCheckFailed=true;
                if liaison.IssueWarningWhenLicenseIsNotAvailable
                    orig_state = warning('off','backtrace');
                    cl = onCleanup(@()warning(orig_state));
                    warning(message('MATLAB:unittest:CodeCoveragePlugin:MissingLicense'));
                end
            end
        end

        function fulfillFiltermanagerDuty(services, liaison)
            arrayfun(@(s) s.updateLiaisonWithFilterData(liaison), services);
        end

        function fulfillFilterLoadingDuty(services, liaison)
            arrayfun(@(s) s.loadFiltersOnTheLiaison(liaison), services);
        end

        function fulfillApplyFilterDuty(services, liaison)
            arrayfun(@(s) s.applyFiltersToResult(liaison), services);
        end
    end
end
