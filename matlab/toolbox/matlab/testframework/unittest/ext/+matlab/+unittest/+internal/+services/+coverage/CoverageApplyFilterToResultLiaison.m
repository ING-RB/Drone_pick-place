classdef CoverageApplyFilterToResultLiaison < handle
    % This class is undocumented and will change in a future release.
    % CoverageApplyFilterToResultLiaison - Class to finalize the
    % matlab.coverage.Result objects based on located
    % CoverageMetricsService classes.

    % Copyright 2024 The MathWorks, Inc.

    properties 
        Result (:,1) matlab.coverage.Result
        UnappliedFilters 
    end 
    
    properties (SetAccess = immutable)
        Filters
    end

    methods
        function liaison =  CoverageApplyFilterToResultLiaison(resultArray, filters)
            liaison.Result = resultArray;
            liaison.Filters = filters;
        end
    end
end