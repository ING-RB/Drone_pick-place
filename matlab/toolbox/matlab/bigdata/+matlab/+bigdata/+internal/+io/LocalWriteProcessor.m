%LocalWriteProcessor
% Helper class that wraps a writer to temporary storage as a Data Processor.
%
% This will always write at least one chunk of input data.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef LocalWriteProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (SetAccess = immutable)
        % The underlying writer implementation.
        Writer;
        
        % Whether the underlying writer expects partition indices.
        RequiresPartitionIndices (1,1) logical = false;
    end
    
    properties (SetAccess = private)
        % A flag that is true if and only if data has been written.
        HasWrittenData (1,1) logical = false;
    end
    
    methods
        function obj = LocalWriteProcessor(writer, numOutputs, requiresPartitionIndices)
            obj.NumOutputs = numOutputs;
            obj.Writer = writer;
            if nargin >= 3
                obj.RequiresPartitionIndices = requiresPartitionIndices;
            end
        end
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, isLastOfInput, data)
            import matlab.bigdata.internal.util.vertcatCellContents;
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            if obj.RequiresPartitionIndices
                partitionIndices = vertcatCellContents(data(:, 1));
                data(:, 1) = [];
                % A wrinkle of the design of any-to-any communication is
                % that partition index must contain one index per chunk.
                % This breaks assumptions made in other parts of the code
                % where empty chunks are allowed, which cannot fit a
                % partition index. For now, ignore such empty chunks.
                if matlab.bigdata.internal.UnknownEmptyArray.isUnknown(partitionIndices)
                    partitionIndices = zeros(0, 1);
                    data = data([], :);
                end
                assert(isnumeric(partitionIndices) && numel(partitionIndices) == size(data,1), ...
                    'Assertion failed: LocalWriteProcessor requires partition indices to be a cell array of scalar numeric values.');
            else
                partitionIndices = [];
            end
            
            % We write only when there exists at least one chunk in the input.
            if size(data, 1) > 0
                try
                    add(obj.Writer, partitionIndices, data);
                catch err
                    matlab.bigdata.internal.io.throwTempStorageError(err);
                end
                obj.HasWrittenData = true;
            end
            
            if isLastOfInput
                try
                    % We only commit if data was actually written. This
                    % optimizes away any unnecessary file/database tables.
                    if obj.HasWrittenData
                        commit(obj.Writer);
                    else
                        delete(obj.Writer);
                    end
                catch err
                    matlab.bigdata.internal.io.throwTempStorageError(err);
                end
                obj.IsFinished = true;
            end
        end
    end
end
