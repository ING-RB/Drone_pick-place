%ReadProcessor
% Data Processor that reads a chunk from the datastore on each iteration.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, each iteration will emit a 1 x 1 cell array containing a
% chunk of data read from the internally held datastore.
%

%   Copyright 2015-2024 The MathWorks, Inc.

classdef (Sealed) ReadProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs = 1;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = false(0, 1);
    end
    
    properties (SetAccess = immutable)
        % The underlying datastore consisting of all the data represented
        % by the current partition.
        Datastore;
        
        % A flag that is true if and only if each read must be wrapped in a
        % cell.
        RequiresCells;
        
        % A chunk of output from the datastore that has size zero in the
        % tall dimension. This exists to handle the case when a partition
        % contains no data, the framework makes the guarantee that it will
        % pass forward a correctly sized empty.
        EmptyChunk;
        
        % A cell array of the class and size information of EmptyChunk. This
        % is the cached output of calling iRecursiveGetMetaInfo on EmptyChunk.
        EmptyChunkMetaInfo;
        
        % The chunk size to emit from this processor. This can be NaN,
        % which indicates to use the raw Datastore reads as the chunk size.
        ChunkSize = NaN;
        
        % A buffer for building up the output chunk. This is non-empty and
        % used if and only if ChunkSize is not NaN.
        OutputBuffer;
        
        % Function handle that is called to read a chunk of data from the
        % underlying datastore. This has signature fcn(obj), we do not
        % capture obj as part of the function handle to avoid cyclic
        % dependencies between obj and this property.
        ReadChunkFcn;
        
        % Context object for execution during the current partition.
        PartitionContext;
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        %PROCESS Perform the next iteration of processing
        function data = process(obj, ~)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            % If the datastore starts with no data, we emit an empty chunk
            % because we are required to emit at least one chunk before
            % IsFinished can be set to true. We should only hit this if the
            % partition was empty, otherwise IsFinished will have been set
            % on the previous call to read.
            if ~iHasdata(obj.Datastore) && obj.OutputBuffer.NumBufferedSlices == 0
                data = {obj.EmptyChunk};
                obj.IsFinished = true;
                return;
            end
            
            % Read some data and see if we are done.
            if isnan(obj.ChunkSize)
                data = { obj.ReadChunkFcn(obj) };
            else
                % We do not special case the instance where datastore/read
                % emits a chunk of size exactly ChunkSize because the
                % performance loss of going through the buffer is
                % negligible compared against the IO.
                while obj.OutputBuffer.NumBufferedSlices < obj.ChunkSize && hasdata(obj.Datastore)
                    obj.OutputBuffer.add(false, { obj.ReadChunkFcn(obj) });
                end
                data = obj.OutputBuffer.get(obj.ChunkSize);
            end
            obj.IsFinished = ~iHasdata(obj.Datastore) && obj.OutputBuffer.NumBufferedSlices == 0;
            if obj.IsFinished
                [numFailures, locations] = matlab.io.datastore.internal.shim.getReadFailures(obj.Datastore);
                readFailureSummary = matlab.bigdata.internal.executor.ReadFailureSummary(numFailures, locations);
                if numFailures ~= 0
                    obj.PartitionContext.addReadFailures(readFailureSummary);
                end
            end
        end
        
        %PROGRESS Return a value between 0 and 1 denoting the progress
        % through the current partition.
        function prog = progress(obj, ~)
            prog = progress(obj.Datastore);
        end
    end
    
    methods
        function obj = ReadProcessor(datastore, emptyChunk, partitionContext)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            obj.Datastore = datastore;
            obj.RequiresCells = matlab.io.datastore.internal.shim.isReadEncellified(...
                datastore);
            obj.EmptyChunk = emptyChunk;
            obj.EmptyChunkMetaInfo = iRecursiveGetMetadata(emptyChunk);
            
            obj.OutputBuffer = matlab.bigdata.internal.lazyeval.InputBuffer(1, false);
            
            % TODO(g1758457): We disable the info struct for performance
            % reasons in cases where it is not needed.  This optimization
            % will be made obsolete in the fullness of time.
            matlab.io.datastore.internal.shim.disableCalcBytesForInfo(datastore);
            
            if matlab.io.datastore.internal.shim.isUniformRead(datastore)
                % Read from the uniform datastore and check for any data
                % uniformity violations
                obj.ReadChunkFcn = @readWithUniformDataCheck;
            else
                % Read directly from the non-uniform datastore.
                obj.ReadChunkFcn = @readRaw;
            end
            obj.PartitionContext = partitionContext;
        end
    end
    
    methods (Access = private)
        function data = readRaw(obj)
            % Reads a chunk of data from the underlying uniform datastore
            data = iRead(obj.Datastore, obj.RequiresCells);
        end
        function data = readWithUniformDataCheck(obj)
            % Reads a chunk of data from the underlying uniform datastore
            % and applies the check to ensure uniformity.
            data = obj.readRaw();
            
            dataMetaInfo = iRecursiveGetMetadata(data);
            if isequal(dataMetaInfo, obj.EmptyChunkMetaInfo)
                return;
            end
            
            try %#ok<TRYNC>
                data = [data; obj.EmptyChunk];
            end
            dataMetaInfo = iRecursiveGetMetadata(data);
            if isequal(dataMetaInfo, obj.EmptyChunkMetaInfo)
                return;
            end
            
            varName = 'data';
            details = iFindUniformMismatch(dataMetaInfo, obj.EmptyChunkMetaInfo, varName, size(data, 1));
            assert(~isempty(details), 'Assertion failed: Uniform mismatch detected but could not find where.');
            
            if isa(obj.Datastore, 'matlab.io.datastore.FileDatastore')
                errId = 'MATLAB:bigdata:array:UniformFileDatastoreMismatch';
            else
                errId = 'MATLAB:bigdata:array:UniformMismatch';
            end
            err = MException(message(errId, details{:}));
            matlab.bigdata.internal.throw(err);
        end
    end
end

% Helper function that performs a read and optionally places the data in a
% cell.
function data = iRead(ds, requiresCell)
oldWarnState = warning("off", "MATLAB:datastoreio:filebaseddatastore:warnFirstFailure");
warnCleanup = onCleanup(@() warning(oldWarnState));
try
    data = read(ds);
catch err
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end

% Need to remove RowNames/Events from any chunk of data because these
% properties are not supported by tall arrays.
if ~requiresCell && istable(data) && ~isequal(data.Properties.RowNames, {})
    data.Properties.RowNames = {};
elseif ~requiresCell && istimetable(data) && ~isequal(data.Properties.Events, [])
    data.Properties.Events = [];
end

% If the datastore is not tabular, the read method will
% return the contents of a single element of a cell array.
% We need to wrap this single element back up in a cell to
% conform with readall.
if requiresCell
    data = {data};
end
end

% Call datastore/hasdata.
function tf = iHasdata(ds)
try
    tf = hasdata(ds);
catch err
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end
end

% Find why a chunk of data does not match the empty prototype.
function details = iFindUniformMismatch(dataMetaInfo, emptyPrototypeMetaInfo, varName, height)
if ~isequal(dataMetaInfo{1}, emptyPrototypeMetaInfo{1})
    expression = sprintf('class(%s)', varName);
    actual = ['"', dataMetaInfo{1}, '"'];
    expected = ['"', emptyPrototypeMetaInfo{1}, '"'];
    details = {expression, actual, expected};
elseif ~isequal(dataMetaInfo{2}, emptyPrototypeMetaInfo{2})
    expression = sprintf('size(%s)', varName);
    actual = mat2str([height, dataMetaInfo{2}(2 : end)]);
    expected = mat2str([height, emptyPrototypeMetaInfo{2}(2 : end)]);
    details = {expression, actual, expected};
elseif numel(emptyPrototypeMetaInfo) > 2 && ~isequal(dataMetaInfo{3}, emptyPrototypeMetaInfo{3})
    idx = find(~strcmp(dataMetaInfo{3}, emptyPrototypeMetaInfo{3}), 1, 'first');
    assert(~isempty(idx), 'Assertion failed: Variable names same length and same names but not isequal');
    expression = sprintf('%s.Properties.VariableNames(%i)', varName, idx);
    actual = ['"', dataMetaInfo{3}{idx}, '"'];
    expected = ['"', emptyPrototypeMetaInfo{3}{idx}, '"'];
    details = {expression, actual, expected};
else
    details = {};
end

for ii = 4 : numel(emptyPrototypeMetaInfo)
    if ~isempty(details)
        break;
    end
    
    subVarName = [varName, '.', emptyPrototypeMetaInfo{3}{ii - 3}];
    details = iFindUniformMismatch(dataMetaInfo{ii}, emptyPrototypeMetaInfo{ii}, subVarName, height);
end
end

% Get the class and size info of an object, then for table and timetable
% recurse into the table's variables.
function metainfo = iRecursiveGetMetadata(chunk)
s = size(chunk);
s(1) = 0;
metainfo = {class(chunk); s};
if istable(chunk) || istimetable(chunk)
    % TODO(g1580766): This is an internal API of table and should be
    % replaced by the official API table2struct(chunk,'ToScalar',true).
    % This code uses the internal version as the official API is an order
    % of magnitude slower.
    metainfo = [metainfo; {chunk.Properties.VariableNames}];
    chunk = getVars(chunk, false)';
    metainfo = [metainfo; cellfun(@iRecursiveGetMetadata, chunk, 'UniformOutput', false)];
end
end

