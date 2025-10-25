%ReadFailureSummary Summary of read failures
%
% This abstracts out the format of how we represent read failures so that
% intermediate code (e.g. back-ends) do not need to be changed in future in
% response to changes in read failures.

%   Copyright 2018-2022 The MathWorks, Inc.

classdef ReadFailureSummary
    properties (SetAccess = immutable)
        % Number of failures
        NumFailures (1,1) double = 0
        
        % Number of unique locations over which failures have occurred
        Locations (:, 1) string = string.empty()
    end
    
    methods
        function obj = ReadFailureSummary(numFailures, locations)
            % Build a ReadFailureSummary, either from zero failures or from
            % the count + locations of failures.
            if nargin
                obj.NumFailures = numFailures;
                obj.Locations = unique(locations(:), "stable");
            end
        end
        
        function obj = merge(obj1, obj2)
            % Merge two summaries together.
            obj = matlab.bigdata.internal.executor.ReadFailureSummary(...
                obj1.NumFailures + obj2.NumFailures, ...
                [obj1.Locations; obj2.Locations]);
        end
    end
    
    methods (Static)
        function obj = fromJavaObject(jObj)
            % Convert the output of toJavaObject back into a
            % ReadFailureSummary.
            obj = matlab.bigdata.internal.executor.ReadFailureSummary(...
                jObj.getNumFailures(), string(jObj.getLocationsAsArray()));
        end
    end
end
