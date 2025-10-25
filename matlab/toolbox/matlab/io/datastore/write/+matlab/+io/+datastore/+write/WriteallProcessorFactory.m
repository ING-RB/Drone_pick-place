classdef WriteallProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
%WRITEALLPROCESSORFACTORY Declares the interface for the partitioned
%   datastore to call writeall on the entire file

%   Copyright 2023 The MathWorks, Inc.
    properties
        OriginalDatastore
        WriteFcn
    end
    
    methods
        function obj = WriteallProcessorFactory(ds, writeFcn)
            obj.OriginalDatastore = ds;
            obj.WriteFcn = writeFcn;
        end
        
        % Build the processor.
        %
        % This is invoked once per partition, in most cases with syntax:
        %
        %  processor = feval(obj, partitionContext)
        %
        % Where partitionContext is a matlab.bigdata.internal.executor.PartitionContext object.
        %
        function processor = feval(obj, partitionContext)
            import matlab.io.datastore.write.WriteallProcessor;

            ds = partitionContext.partitionDatastore(obj.OriginalDatastore);
            processor = WriteallProcessor(ds, obj.WriteFcn, ...
                partitionContext.PartitionIndex, partitionContext.NumPartitions);
        end
    end
end
