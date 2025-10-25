classdef BuildResult
    properties (Dependent, SetAccess = immutable)
        Failed (1,1) logical
    end
    
    properties (SetAccess = immutable)
        Duration (1,1) duration
        TaskResults (1,:) matlab.buildtool.TaskResult
    end

    properties (Hidden, SetAccess = immutable)
        Errored (1,1) logical
    end
    
    methods (Hidden)
        function result = BuildResult(options)
            arguments
                options.TaskResults
                options.Duration
                options.Errored
            end
            for prop = string(fieldnames(options))'
                result.(prop) = options.(prop);
            end
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
        function tf = get.Failed(result)
            tf = any([result.TaskResults.Failed]) || result.Errored;
        end
    end
end

% Copyright 2021-2023 The MathWorks, Inc.
