classdef WriteFunction < handle & matlab.mixin.Copyable
%WRITEFUNCTION A function object to support writing partitioned tall chunks.
%   This function object is used by write methods of tall and distributed,
%   and is used to build writers for a variety of formats including
%   sequence files, CVS files and more.
%
%   See also datastore, tall, mapreduce.

%   Copyright 2016-2018 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % A function handle of the form writer = fcn(partitionIndex);
        WriterFactory;
    end

    properties (SetAccess = private, Transient)
        % Internal writer object to write tall arrays.
        Writer;
    end

    methods
        % Constructor for this object
        function obj = WriteFunction(writerFactory)
            obj.WriterFactory = writerFactory;
        end

        % feval needed for FunctionHandle
        %
        % isFinished - is true when the input is the last chunk.
        %              until then keep writing to the same internal writer.
        % emptyOut   - always empty []
        %              At least one output is needed other than isFinished
        %              emptyOut is just to fullfill FunctionHandle api 
        function [isFinished, emptyOut] = feval(obj, info, input)
            isFinished = info.IsLastChunk;

            if isempty(obj.Writer) || ~isvalid(obj.Writer)
                % Invoke the factory function handle to create the Writer.
                obj.Writer = feval(obj.WriterFactory, info.PartitionId, info.NumPartitions);
            end
            obj.Writer.add(input);

            if isFinished
                obj.Writer.commit();
                delete(obj.Writer);
            end
            emptyOut = [];
        end
    end
end
