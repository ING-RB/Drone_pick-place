%ReadFailureAccumulator Accumulator that collects read failures
% This is used to collect read failures in a big data job that is setup to
% continue in case of datastore error.

%   Copyright 2018 The MathWorks, Inc.

classdef ReadFailureAccumulator < handle
    properties (SetAccess = immutable)
        % Maximum number of read failures before an error is issued.
        MaxNumReadFailures (1,1) double = Inf
    end
    
    properties (SetAccess = private)
        % The summary of currently seen read failures.
        Summary (1,1) matlab.bigdata.internal.executor.ReadFailureSummary ...
            = matlab.bigdata.internal.executor.ReadFailureSummary();
    end
    
    methods
        function obj = ReadFailureAccumulator(maxNumReadFailures)
            % Build a ReadFailureAccumulator. Optionally pass in a maximum
            % number of read failures allowed, with default of Inf.
            if nargin
                obj.MaxNumReadFailures = maxNumReadFailures;
            end
        end
        
        function append(obj, readFailureSummary)
            % Append the given read failure summary to the currently
            % collected results.
            for ii = 1:numel(readFailureSummary)
                obj.Summary = merge(obj.Summary, readFailureSummary(ii));
            end
            if obj.Summary.NumFailures > obj.MaxNumReadFailures
                firstFewLocations = readFailureSummary.Locations(1:min(3, end));
                matlab.bigdata.internal.throw(...
                    message("MATLAB:bigdata:executor:ReadFailureError", ...
                    obj.MaxNumReadFailures, strjoin(firstFewLocations, newline)));
            end
        end
    end
end
