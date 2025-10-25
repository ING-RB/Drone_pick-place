%GatedPassthroughProcessorFactory
% Factory for building a GatedPassthroughProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) GatedPassthroughProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Function to decide whether the input should be passed through or
        % not.
        %
        % This must have signature:
        %    tf = fcn(partition)
        PredicateFunction (1,1)
        
        % Number of variables to pass through
        NumVariables (1,1) double
    end
    
    methods
        function obj = GatedPassthroughProcessorFactory(predicateFunction, numVariables)
            % Build a GatedPassthroughProcessorFactory whose processor
            % gates data from passing through based on a predicate
            % function.
            obj.PredicateFunction = predicateFunction;
            obj.NumVariables = numVariables;
        end
        
        function dataProcessor = feval(obj, partitionContext, ~)
            allowPassthrough = feval(obj.PredicateFunction, partitionContext);
            assert(isscalar(allowPassthrough) && islogical(allowPassthrough), ...
                'AssertionFailed: GatedPassthroughProcessor constructed with an invalid predicate function');
            
            import matlab.bigdata.internal.executor.GatedPassthroughProcessor
            dataProcessor = GatedPassthroughProcessor(allowPassthrough, obj.NumVariables);
        end
    end
end
