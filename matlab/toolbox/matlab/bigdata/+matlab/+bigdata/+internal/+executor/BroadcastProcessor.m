%BroadcastProcessor
% Data Processor that collects all data and when done, calls a broadcast
% function.
%

%   Copyright 2016-2019 The MathWorks, Inc.

classdef (Sealed) BroadcastProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs
    end
    properties (SetAccess = private)
        IsFinished = false
        IsMoreInputRequired = true
    end
    
    properties (SetAccess = immutable)
        % A key that uniquely identifies the output being broadcasted.
        Key (1,1) string
        
        % The partition that this processor is executing over.
        PartitionContext (1,1)
    end
    
    properties (SetAccess = private)
        % A buffer to collect all of the input before calling broadcast.
        Buffer = [];
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, data)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            if isempty(obj.Buffer)
                obj.Buffer = data;
            else
                obj.Buffer = [obj.Buffer; data];
            end
            
            if isLastOfInput
                obj.PartitionContext.addBroadcast(obj.Key, obj.Buffer);
                obj.Buffer = [];
                obj.IsFinished = true;
            end
        end
    end
    
    methods
        function obj = BroadcastProcessor(key, numVariables, partitionContext)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.Key = key;
            obj.NumOutputs = numVariables;
            obj.PartitionContext = partitionContext;
        end
    end
end
