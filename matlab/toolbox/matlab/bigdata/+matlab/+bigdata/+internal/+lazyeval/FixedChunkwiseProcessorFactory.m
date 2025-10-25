%FixedChunkwiseProcessorFactory
% Factory for building a ChunkwiseProcessor where each input block is
% forced to have a fixed height.

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) FixedChunkwiseProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Number of slices per block
        NumSlices (1,1) double
        
        % Underlying function to be applied chunkwise to the data.
        Function (1,1)
        
        % Number of outputs emitted from the function
        NumOutputs (1,1) double
        
        % For each input, is that input a broadcast?
        IsInputBroadcastVector (1,:) logical
    end
    
    methods
        function obj = FixedChunkwiseProcessorFactory(numSlices, fcn, numOutputs, isInputBroadcastVector)
            % Build a FixedChunkwiseProcessorFactory whose processors
            % applies a function per fixed height chunk of underlying data.
            obj.NumSlices = numSlices;
            obj.Function = fcn;
            obj.NumOutputs = numOutputs;
            obj.IsInputBroadcastVector = isInputBroadcastVector;
        end
        
        function processor = feval(obj, ~, ~)
            numInputs = numel(obj.IsInputBroadcastVector);
            import matlab.bigdata.internal.lazyeval.ChunkwiseProcessor
            processor = ChunkwiseProcessor(copy(obj.Function), numInputs, obj.NumOutputs);
            
            import matlab.bigdata.internal.lazyeval.BufferedZipProcessDecorator
            allowTallDimExpansion = false;
            processor = BufferedZipProcessDecorator.wrapFixedHeight(processor, ...
                obj.NumSlices, ...
                obj.IsInputBroadcastVector, allowTallDimExpansion, ...
                obj.Function.ErrorStack);
        end
    end
end
