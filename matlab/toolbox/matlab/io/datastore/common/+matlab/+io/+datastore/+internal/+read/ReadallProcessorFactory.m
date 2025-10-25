classdef ReadallProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
%READALLPROCESSORFACTORY Declares the interface for the partitioned
%   datastore to call readall on the specified partition

%   Copyright 2020 The MathWorks, Inc.
    properties
        OriginalDatastore
    end

    methods
        function obj = ReadallProcessorFactory(ds)
            obj.OriginalDatastore = ds;
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
            import matlab.io.datastore.internal.read.ReadallProcessor;

            partitionedDatastore = partitionContext.partitionDatastore(obj.OriginalDatastore);
            processor = ReadallProcessor(partitionedDatastore, ...
                partitionContext.PartitionIndex, partitionContext.NumPartitions);
        end
    end
end
