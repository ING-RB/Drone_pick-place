classdef MATLABCoverageMetricsService < matlab.unittest.internal.services.coverage.CoverageMetricsService
    % This class is undocumented and will change in a future release.

    % CoverageMetricsService - Interface for coverage metrics addition services.

    %   Copyright 2021-2024 The MathWorks, Inc.

    properties(SetAccess = private)
        ValidMetricNames = "statement";  % function is part of the statement metric
    end
   
    methods 
        function [handler, builtInFcnHandle, licenseValid] = createMetricHandlerAndCollector(~,~)
            import matlab.unittest.internal.coverage.metrics.StatementMetricHandler
            import matlab.unittest.internal.coverage.metrics.FunctionMetricHandler
            handler = [FunctionMetricHandler,StatementMetricHandler];
            builtInFcnHandle = @matlab.lang.internal.BasicCodeCoverageCollector;
            licenseValid = true;
        end

        function updateLiaisonWithFilterData(~,~)
        end

        function loadFiltersOnTheLiaison(~,~)
        end

        function applyFiltersToResult(~, ~)            
        end
    end
end
