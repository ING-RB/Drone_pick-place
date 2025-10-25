classdef CoverageMetricsLiaison < handle

    % This class is undocumented and will change in a future release.
    % CoverageMetricsLiaison - Class to handle communication between CoverageMetricsService classes.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        MetricName string;        
    end

    properties
        MetricHandler matlab.unittest.internal.coverage.metrics.MetricHandler = matlab.unittest.internal.coverage.metrics.MetricHandler.empty;
        CollectorBuiltIn
        IssueWarningWhenLicenseIsNotAvailable
        LicenseCheckFailed = false;
    end

    methods
        function liaison = CoverageMetricsLiaison(metricName,optionalArgs)
            arguments
                metricName
                optionalArgs.IssueWarningIfLicenseIsMissing = false;
            end
            import matlab.unittest.internal.mustBeTextScalar;

            mustBeTextScalar(metricName,'metric');
            liaison.MetricName = metricName;
            liaison.IssueWarningWhenLicenseIsNotAvailable = optionalArgs.IssueWarningIfLicenseIsMissing;
        end
    end
end


