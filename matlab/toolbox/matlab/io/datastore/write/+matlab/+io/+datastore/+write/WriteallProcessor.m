classdef WriteallProcessor < matlab.bigdata.internal.executor.DataProcessor
%WRITEALLPROCESSOR Implements the interface for the partitioned
%   datastore to call writeall on the entire file

%   Copyright 2023 The MathWorks, Inc.

    % Overloads of DataProcessor
    properties (SetAccess = immutable)
        % The number of output variables to be emitted by this processor.
        % Each call to process(..) is guaranteed to return a
        % NumChunks x NumOutputs cell array of chunks.
        NumOutputs = 0
    end
    
    % Overloads of DataProcessor
    properties (SetAccess = private)
        % A scalar logical that specifies if this data processor is
        % finished. A finished data processor has no more output or
        % side-effects.
        IsFinished = false

        % A vector of logicals that describe which inputs are required
        % before this can perform any further processing. Each logical
        % corresponds with the input of the same index.
        IsMoreInputRequired = []
    end

    properties (GetAccess = private, SetAccess = immutable)
        % The underlying Datastore
        Datastore

        % Index of this partition in 1:NumPartitions
        PartitionIndex

        % Number of partitions
        NumPartitions

        % Function to invoke per write
        %
        %  writefcn(data, info)
        WriteFcn
    end

    methods
        function obj = WriteallProcessor(datastore, writeFcn, partitionIndex, numPartitions)
            obj.Datastore = datastore;
            obj.PartitionIndex = partitionIndex;
            obj.NumPartitions = numPartitions;
            obj.WriteFcn = writeFcn;
        end
    end

    % Overloads of DataProcessor
    methods
        %PROCESS Process the next chunk of data.
        %
        % This will be invoked repeatedly until IsFinished is true or the
        % output of this processor is no longer required. This will never
        % be invoked after IsFinished is true.
        %
        % Syntax:
        %  out = process(obj,isLastOfInput,varargin)
        %
        % Inputs:
        %  - isLastOfInputs is a logical scalar indicating whether there
        %  potentially exists any more input after this call to process.
        %  The process method is guaranteed to always be called at least
        %  once with isLastOfInputs set to true.
        %  - varargin is the actual input itself. Each of varargin will be
        %  a chunk from the respective input source.
        %
        % Outputs:
        %  - out is an chunk of output from this data processor. This is
        %  expected to be a NumChunks x NumOutputs cell array of chunks.
        %  If the processor is attached to any-to-any communication, the
        %  first column of data must contain scalar partition indices
        %  indicating which target partition to send the row of chunks.
        function out = process(obj, ~)
            out = {};
            try
                feval(obj.WriteFcn, obj.Datastore, obj.PartitionIndex);
            catch err
                % Need to use our internal throw command if the given error
                % is intended to be customer visible.
                matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
            end
            obj.IsFinished = true;
        end

        function prog = progress(obj, ~)
            %PROGRESS Return a value between 0 and 1 denoting the progress
            % through the current partition.
            %
            % Syntax:
            %  prog = progress(obj, inputProgress)
            %
            % Inputs:
            %  - inputProgress is a vector of double values between 0 and 1
            %  representing the progress of each predecessor of the
            %  processor.
            %
            % Outputs:
            %  - prog must be a double value between 0 and 1. If the data
            %  processor is finished, prog must be 1.

            % Default implementation is to assume the processor has
            % progressed as far as the input with least progress.
            prog = progress(obj.Datastore);
        end
    end
end
