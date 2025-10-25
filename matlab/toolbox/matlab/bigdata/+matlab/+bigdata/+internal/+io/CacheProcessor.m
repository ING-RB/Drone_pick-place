%CacheProcessor
% Helper class that introduces a cache to the graph of operations.
%
% On cache hit, this will not require any input and read output chunks from
% the cache. On cache miss, this will require the input, write it to the
% cache as well as pass it forward.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef CacheProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (SetAccess = immutable)
        % The underlying processor that will read from the disk or memory
        % cache. This will be empty if no cache exists.
        ReadProcessor;
        
        % The underlying processor that will write to the disk or memory
        % cache. This will be empty if both disk and memory cache already
        % exists.
        WriteProcessor;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, data)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            if isempty(obj.ReadProcessor)
                % If no cache read processor, this is a straight pass
                % through.
                obj.IsFinished = isLastOfInput;
            else
                % Otherwise we redirect input to be from the cache read
                % processor.
                data = obj.ReadProcessor.process([]);
                obj.IsFinished = obj.ReadProcessor.IsFinished;
            end
            
            if ~isempty(obj.WriteProcessor)
                % If we need to write to cache, do that here.
                data = obj.WriteProcessor.process(obj.IsFinished, data);
                obj.IsFinished = obj.WriteProcessor.IsFinished;
            end
        end
    end
    
    methods
        function obj = CacheProcessor(readProcessor, writeProcessor, numVariables)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = numVariables;
            obj.ReadProcessor = readProcessor;
            obj.WriteProcessor = writeProcessor;
            obj.IsMoreInputRequired = isempty(readProcessor);
        end
    end
end
