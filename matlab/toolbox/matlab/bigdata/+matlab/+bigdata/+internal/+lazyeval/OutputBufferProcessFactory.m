%OutputBufferProcessFactory
% Factory for building a OutputBufferProcessDecorator

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) OutputBufferProcessFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Underlying DataProcessorFactory to be decorated
        Factory (1,1)
        
        % Desired minimum number of bytes in each chunk
        DesiredMinChunkBytes (1,1) double
        
        % Maximum amount of time to wait to achieve the desired chunk size
        MaxTimePerChunk (1,1) double
    end
    
    methods
        function obj = OutputBufferProcessFactory(factory, desiredMinChunkBytes, maxTimePerChunk)
            % Build a OutputBufferProcessFactory whose processors try to
            % enlarge output chunks to optimize tall/write and
            % visualization.
            obj.Factory = factory;
            
            import matlab.bigdata.internal.lazyeval.ChunkResizeOperation;
            if nargin < 2
                desiredMinChunkBytes = ChunkResizeOperation.desiredMinBytesPerChunk();
            end
            obj.DesiredMinChunkBytes = desiredMinChunkBytes;
            
            if nargin < 3
                maxTimePerChunk = inf;
            end
            obj.MaxTimePerChunk = maxTimePerChunk;
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, varargin)
            import matlab.bigdata.internal.lazyeval.OutputBufferProcessDecorator;
            processor = feval(obj.Factory, partitionContext, varargin{:});
            processor = OutputBufferProcessDecorator(processor, ...
                obj.DesiredMinChunkBytes, obj.MaxTimePerChunk);
        end
    end
end
