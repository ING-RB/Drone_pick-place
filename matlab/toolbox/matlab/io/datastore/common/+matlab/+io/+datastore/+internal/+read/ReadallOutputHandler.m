%READALLOUTPUTHANDLER Implements an output handler that gathers all output
% into one array then passes this to an underlying function handle.

%   Copyright 2020 The MathWorks, Inc.

classdef (Sealed) ReadallOutputHandler < matlab.bigdata.internal.executor.OutputHandler
    properties (SetAccess = immutable)
        % A logical scalar that is true if and only if this output handler
        % benefits from streaming.
        IsStreamingHandler = false;
    end

    properties (GetAccess = private, SetAccess = immutable)
        % Map of taskId_argoutIndex to a structure that contains the
        % current state for that particular output. For all outputs, this
        % will include:
        %   - CompletedPartitions, a logical vector that has size
        %   NumPartitions. Each is true if and only if the corresponding
        %   partition has no more data.
        %   - Data, the current accumulation of data for that output.
        OutputStateMap;
    end

    properties
        % To hold the final result
        Data;
    end

    methods
        function obj = ReadallOutputHandler()
            % Construct an output handler with the given default handler
            % function handle.
            obj.OutputStateMap = containers.Map('KeyType', 'char', ...
                'ValueType', 'any');
        end
    end

    % Methods overridden in the OutputHandler interface.
    methods (Access = protected)
        % Handle one set of chunks for the output of index outputIndex
        % of task corresponding to taskId.
        function [isHandled, cancel] = doHandle(obj, taskId, outputIndex, info, data)

            % ReadallOutputHandler handles all outputs.
            isHandled = true;

            key = iGetKey(taskId, outputIndex);
            if ~isKey(obj.OutputStateMap, key)
                obj.OutputStateMap(key) = struct(...
                    'CompletedPartitions', false(info.NumPartitions, 1), ...
                    'Data',                {cell(info.NumPartitions, 1)});
            end

            % Otherwise the default case.
            [obj.OutputStateMap(key), isFinished, cancel] = iHandleReadallData(...
                obj, obj.OutputStateMap(key), info, data);
            if isFinished
                remove(obj.OutputStateMap, key);
            end
        end
    end
end

function key = iGetKey(taskId, argoutIndex)
% Get the key for all maps of the output of given taskId and argoutIndex.
key = sprintf('%s_%i', taskId, argoutIndex);
end

function [state, isFinished, cancel] = iHandleReadallData(obj, state, ...
    info, data)
% Handle a chunk of output being read.

import matlab.bigdata.internal.util.vertcatCellContents;

state.Data{info.PartitionIndex} = [state.Data{info.PartitionIndex}; data];
if info.IsLastChunk
    state.CompletedPartitions(info.PartitionIndex) = true;
end

isFinished = all(state.CompletedPartitions);
if isFinished
    % At this point, Data is a cell array where each cell corresponds
    % to a partition. Each cell contains a cell array where each inner
    % cell contains one chunk for that partition.
    state.Data = vertcatCellContents(vertcatCellContents(state.Data));
    obj.Data = state.Data;
    cancel = false;
else
    cancel = false;
end
end
