%DataProcessorFactory
% Interface for classes that can build a DataProcessor object on MATLAB
% Workers.
%

%   Copyright 2018 The MathWorks, Inc.

classdef (Abstract) DataProcessorFactory < handle
    methods (Abstract)
        % Build the processor.
        %
        % This is invoked once per partition, in most cases with syntax:
        %
        %  processor = feval(obj, partitionContext)
        %
        % Where partitionContext is a PartitionContext object.
        %
        % If the data processor is used in combination with Any-to-Any
        % communication, the factory will be invoked with syntax:
        %  
        %  processor = feval(obj, partitionContext, outputPartitionStrategy)
        %
        % Where outputPartitionStrategy is the partition strategy after
        % communication.
        processor = feval(obj, partitionContext, outputPartitionStrategy);
    end
end
