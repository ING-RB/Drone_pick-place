%RepartitionProcessorFactory
% Factory for building a RepartitionProcessor

%   Copyright 2018 The MathWorks, Inc.

classdef (Sealed) RepartitionProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % Number of variables to be reduced
        NumVariables (1,1) double
        
        % For each input, is that input a broadcast?
        IsInputBroadcastVector (1,:) logical
        
        % Error stack from the construction of the operation to attach to
        % any errors generated from repartition.
        SubmissionErrorStack
    end
    
    methods
        function obj = RepartitionProcessorFactory(numVariables, ...
                isInputBroadcastVector, submissionErrorStack)
            % Build a RepartitionProcessorFactory whose processors
            % repartition the input using an array of target partition
            % indices.
            obj.NumVariables = numVariables;
            obj.IsInputBroadcastVector = isInputBroadcastVector;
            obj.SubmissionErrorStack = submissionErrorStack;
        end
        
        % Build the processor.
        function processor = feval(obj, ~, outputPartitionStrategy)
            import matlab.bigdata.internal.lazyeval.RepartitionProcessor
            processor = RepartitionProcessor(obj.NumVariables, ...
                numpartitions(outputPartitionStrategy));
            
            % Need to ensure all inputs arrive at the processor in slice
            % for slice lockstep.
            import matlab.bigdata.internal.lazyeval.BufferedZipProcessDecorator
            allowTallDimExpansion = false;
            processor = BufferedZipProcessDecorator.wrapSimple(processor, ...
                obj.IsInputBroadcastVector, allowTallDimExpansion, ...
                obj.SubmissionErrorStack);
        end
    end
end
