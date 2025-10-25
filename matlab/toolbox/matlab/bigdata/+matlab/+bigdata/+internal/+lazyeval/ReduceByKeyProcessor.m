%ReduceByKeyProcessor
% Data Processor that performs a reduction of the current partition to a
% single chunk per key.
%
% This will apply a rolling reduction to all input. It will emit the final
% result of this rolling reduction once all input has been received.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, this will receive a N x NumVariables cell array where the
% first variable when unpacked represent a set of keys. It will return a
% NumOutputPartitions x NumVariables cell array as output. Each row of this
% output is a chunk of data to be sent to the output partition of
% corresponding index in the same row of partitionIndices output. Every
% unique key is matched to exactly one output partition via hash mod n.
%

%   Copyright 2016-2023 The MathWorks, Inc.

classdef (Sealed) ReduceByKeyProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = true;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The underlying ReduceProcessor that does all reduction within the
        % local partition.
        UnderlyingProcessor;
        
        % The number of partitions in the output.
        NumOutputPartitions;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function out = process(obj, isLastOfInput, in)
            import matlab.bigdata.internal.UnknownEmptyArray;
            
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            out = process(obj.UnderlyingProcessor, isLastOfInput, in);
            assert(iscell(out) && ismatrix(out) && size(out, 2) == obj.NumOutputs - 1, ...
                "Assertion Failed: Expected ReduceProcessor to return a NumChunks x NumOutputs-1 cell array");
            obj.updateState();
            
            % ReduceByKeyProcessor expects to receive a 1xN cell with the
            % corresponding outputs coming from the underlying processor
            % (ReduceProcessor). In the case of a partition with
            % UnknownEmptyArray keys, out will be a cell array with as many
            % UnknownEmptyArray as outputs requested. If that's the case,
            % return the empty cell but do not partition the output based
            % on the keys. If the keys are known but the output data is
            % UnknownEmptyArray, partition unknown data outputs as they
            % will be merged with real data afterwards.
            if obj.IsFinished
                isKeysUnknown = UnknownEmptyArray.isUnknown(out{1});
                if isKeysUnknown
                    out = cell(0, obj.NumOutputs);
                else
                    out = iPartitionData(obj.NumOutputPartitions, out{:});
                end
            else
                assert(isempty(out), ...
                    'Assertion Failed: ReduceByKeyProcessor expected no output until the underlying ReduceProcessor was finished.');
                out = cell(0, obj.NumOutputs);
            end
        end
    end
    
    methods
        function obj = ReduceByKeyProcessor(underlyingProcessor, numOutputPartitions)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.NumOutputs = underlyingProcessor.NumOutputs + 1;
            obj.UnderlyingProcessor = underlyingProcessor;
            obj.NumOutputPartitions = numOutputPartitions;
        end
    end
    
    methods (Access = private)
        function updateState(obj)
            % Update the DataProcessor public properties to correspond with
            % the equivalent of the underlying processor.
            
            obj.IsFinished = obj.UnderlyingProcessor.IsFinished;
            obj.IsMoreInputRequired = obj.UnderlyingProcessor.IsMoreInputRequired;
        end
    end
end

% Partition the output into chunks based on binning the keys into the output
% partitions.
function data = iPartitionData(numPartitions, keys, varargin)
import matlab.bigdata.internal.util.splitSlices;
indices = (1:numPartitions)';
data = cell(numPartitions, 2 + numel(varargin));
data(:, 1) = num2cell(indices);

keyIndices = iPartition(keys, numPartitions);

[partitionIdxMap, ~, keyIndices] = unique(keyIndices);

data(:, 2) = iSplit(keys, keyIndices, partitionIdxMap, numPartitions);

for ii = 1:numel(varargin)
    data(:, ii + 2) = iSplit(varargin{ii}, keyIndices, partitionIdxMap, numPartitions);
end
end

% Bin the keys into the various output partitions by doing a crude hash
% modulo number of partitions.
function indices = iPartition(keys, numPartitions)
sz = size(keys);
if isa(keys, 'double')
    keys = double(mod(typecast(keys(:), 'uint64'), numPartitions));
elseif isfloat(keys)
    keys = double(mod(typecast(keys(:), 'uint32'), numPartitions));    
elseif isnumeric(keys) || islogical(keys)
    keys = mod(double(keys(:)), numPartitions);
elseif isdatetime(keys) || isduration(keys)
    keys = datenum(keys(:)); %#ok<DATNM> 
    keys = double(mod(typecast(keys, 'uint64'), numPartitions));
elseif isstring(keys) || iscellstr(keys) || iscategorical(keys)
    [uniqueKeys, ~, idx] = unique(keys);
    keySum = mod(cellfun(@sum, cellstr(uniqueKeys)), numPartitions);
    keys = keySum(idx);
else
    error(message('MATLAB:bigdata:executor:InvalidKeyType', class(keys)));
end
indices = mod(31 * sum(reshape(keys,sz(1),[]), 2), numPartitions) + 1;
end

function out = iSplit(data, idx, uniqueIdxMap, numOutputGroups)
import matlab.bigdata.internal.util.indexSlices;
import matlab.bigdata.internal.util.splitSlices;

if numOutputGroups > numel(uniqueIdxMap)
    emptyChunk = indexSlices(data, []);
    out(1:numOutputGroups, :) = {emptyChunk};
    out(uniqueIdxMap) = splitSlices(data, idx);
else
    out = splitSlices(data, idx);
end
end

