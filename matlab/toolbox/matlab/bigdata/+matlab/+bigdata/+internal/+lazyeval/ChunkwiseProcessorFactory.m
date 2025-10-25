%BufferedZipProcessDecoratorFactory
% Factory for building a BufferedZipProcessDecorator

%   Copyright 2018-2022 The MathWorks, Inc.

classdef (Sealed) ChunkwiseProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying function to be applied chunkwise to the data.
        Function (1,1)
        
        % Number of outputs emitted from the function
        NumOutputs (1,1) double
        
        % For each input, is that input a broadcast?
        IsInputBroadcastVector (1,:) logical
        
        % Should broadcasts be allowed in the input? This controls what
        % error message is issued for mismatching size.
        AllowTallDimExpansion (1,1) logical
        
        IncompatibleErrorHandler
    end
    
    methods
        function obj = ChunkwiseProcessorFactory(fcn, numOutputs, ...
                isInputBroadcastVector, allowTallDimExpansion, incompatibleErrorHandler)
            % Build a ChunkwiseProcessorFactory whose processor applies
            % a chunkwise function per chunk of underlying data.
            if nargin < 4
                allowTallDimExpansion = true;
            end
            obj.Function = fcn;
            obj.NumOutputs = numOutputs;
            obj.IsInputBroadcastVector = isInputBroadcastVector;
            obj.AllowTallDimExpansion = allowTallDimExpansion;
            if nargin < 5
                obj.IncompatibleErrorHandler = obj.Function.ErrorStack;
            else
                obj.IncompatibleErrorHandler = incompatibleErrorHandler;
            end
        end
        
        % Build the processor.
        function processor = feval(obj, ~, ~)
            numInputs = numel(obj.IsInputBroadcastVector);
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessor
            import matlab.bigdata.internal.lazyeval.DecellificationProcessorDecorator
            import matlab.bigdata.internal.lazyeval.BufferedZipProcessDecorator
            processor = ChunkwiseProcessor(copy(obj.Function), numInputs, obj.NumOutputs);
            
            % If there is a single input, we disable the buffering behavior
            % as it is not needed and comes with performance overhead.
            if isscalar(obj.IsInputBroadcastVector)
                processor = DecellificationProcessorDecorator(processor);
            else
                processor = BufferedZipProcessDecorator.wrapSimple(processor, ...
                    obj.IsInputBroadcastVector, obj.AllowTallDimExpansion, ...
                    obj.IncompatibleErrorHandler);
            end
        end
    end
end
