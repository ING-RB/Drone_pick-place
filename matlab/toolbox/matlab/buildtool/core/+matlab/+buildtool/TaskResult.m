classdef TaskResult
    properties (SetAccess = {?matlab.buildtool.TaskResult, ?matlab.buildtool.internal.BuildRunData})
        Name (1,1) string
    end

    properties (Dependent, SetAccess = private)
        Failed (1,1) logical
    end
    
    properties (SetAccess = {?matlab.buildtool.TaskResult, ?matlab.buildtool.BuildRunner})
        Skipped (1,1) logical
        UpToDate (1,1) logical
    end

    properties (SetAccess = {?matlab.buildtool.TaskResult, ?matlab.buildtool.internal.BuildRunData})
        Duration (1,1) duration
    end

    properties (Hidden, SetAccess = {?matlab.buildtool.TaskResult, ?matlab.buildtool.BuildRunner})
        ValidationFailed (1,1) logical
        Errored (1,1) logical
        AssertionFailed (1,1) logical
    end
    
    methods (Hidden)
        function result = TaskResult()
        end

        function json = jsonencode(results, varargin)
            sarr = arrayfun(@encodeResult, results);
            json = jsonencode(sarr, varargin{:});

            function s = encodeResult(result)
                props = properties(result);

                for prop = string(props)'
                    s.(prop) = result.(prop);
                end

                s.Duration.Format = "hh:mm:ss.SSS";
                s.Duration = string(s.Duration);
            end
        end
    end

    methods
        function failed = get.Failed(result)
            failed = ...
                result.ValidationFailed || ...
                result.Errored || ...
                result.AssertionFailed;
        end
    end
end

% Copyright 2021-2023 The MathWorks, Inc.