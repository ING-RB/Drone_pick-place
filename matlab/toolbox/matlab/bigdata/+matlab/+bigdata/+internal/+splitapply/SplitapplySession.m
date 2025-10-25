%SplitapplySession
% Class that holds state shared by all GroupedPartitionedArray objects
% within one call to splitapply.

%   Copyright 2016-2018 The MathWorks, Inc.

classdef SplitapplySession < handle
    properties (SetAccess = immutable)
        % The underlying function handle for error purposes.
        FunctionHandle;
        
        % Number of groups over the session. This is stored in a
        % non-grouped partitioned array.
        NumGroups;
    end
    
    properties (SetAccess = private)
        % A logical scalar that is true if and only if we are still in the
        % call to splitapply. This is intended as a guard to prevent valid
        % GroupedPartitionedArray escaping out of the splitapply function.
        IsValid = true;
    end
    
    methods
        function obj = SplitapplySession(fun, numGroups)
            assert(isa(fun, 'function_handle'), ...
                'Assertion failed: fun must be a function handle.');
            assert(isa(numGroups, 'matlab.bigdata.internal.lazyeval.LazyPartitionedArray'), ...
                'Assertion failed: numGroups must be a non-grouped partitioned array');
            obj.FunctionHandle = fun;
            obj.NumGroups = numGroups;
        end
        
        % Close the session.
        function close(obj)
            obj.IsValid = false;
        end
    end
end
