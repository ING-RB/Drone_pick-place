classdef ExternalInputBuffer < handle & matlab.mixin.Copyable
    %EXTERNALINPUTBUFFER An input buffer that spills to disk when needed.
    %
    % This class implements a FIFO buffer that will store received data in
    % memory until the maxBufferSize threshold is exceeded.  This class
    % ensures that the size of each chunk of data that is added to the
    % buffer with ADD is preserved when reading back from the buffer when
    % calling GETNEXT.
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    
    properties (Access = private, Transient)
        % An in-memory buffer to collect partition data within
        Buffer;
        
        % The base folder on disk that holds any data spilled to disk. This
        % is empty when no data has been spilled to disk.
        DataFolder;
        
        % A list of folders that contain data that has been spilled to disk.
        % Each path represents a single TallDatastore collection of data.
        SpilledDataPaths = {};
        
        % The datastore used to read data that has been spilled to disk.
        DiskDatastore;
    end
    
    properties (Constant)
        % The default maximum size in memory of the buffer. Once this is
        % exceeded, data is spilled to disk.
        DEFAULT_MAX_BUFFER_SIZE_IN_BYTES = 100 * 1024 ^ 2;
    end
    
    methods
        function add(obj, chunk)
            %ADD Add a chunk to held data and maintain FIFO order.
            obj.Buffer = [obj.Buffer; {chunk}];
            
            if obj.shouldSpill()
                obj.spillBuffer();
            end
        end
        
        function [isFinished, chunk] = getnext(obj)
            %GETNEXT Retrieve the next chunk from held data.
            
            if obj.hasSpilledData()
                % Out-of-memory case
                [isFinished, chunk] = obj.readSpilledBuffer();
            else
                % In-memory case
                chunk = obj.Buffer{1};
                obj.Buffer = obj.Buffer(2:end);
                isFinished = isempty(obj.Buffer);
            end
        end
    end
    
    methods (Access = private)
        function tf = shouldSpill(obj)
            data = obj.Buffer; %#ok<NASGU>
            whosData = whos('data');
            tf = whosData.bytes > obj.maxBufferSize();
        end
        
        function tf = hasSpilledData(obj)
            dsHasData = ~isempty(obj.DiskDatastore) && hasdata(obj.DiskDatastore);
            tf = ~isempty(obj.SpilledDataPaths) || dsHasData;
        end
        
        function spillBuffer(obj)
            %SPILLBUFFER Spill the contents of the in-memory buffer to disk
            import matlab.bigdata.internal.util.TempFolder;
            
            if isempty(obj.DataFolder)
                obj.DataFolder = TempFolder;
            end
            
            nextSpilledDataIndex = numel(obj.SpilledDataPaths) + 1;
            location = fullfile(obj.DataFolder.Path, sprintf('part-%05i', nextSpilledDataIndex));
            iWriteDataToDisk(location, obj.Buffer);
            
            obj.SpilledDataPaths{end + 1} = location;
            obj.Buffer = [];
        end
        
        function [isFinished, chunk] = readSpilledBuffer(obj)
            %READSPILLEDBUFFER Reads buffered data in FIFO order from disk
            
            import matlab.io.datastore.TallDatastore;
            
            if isempty(obj.DiskDatastore) || ~hasdata(obj.DiskDatastore)
                assert(~isempty(obj.SpilledDataPaths), 'No spilled data to read from');
                obj.DiskDatastore = TallDatastore(obj.SpilledDataPaths{1}, 'ReadSize', 1);
                obj.SpilledDataPaths = obj.SpilledDataPaths(2:end);
            end
            
            chunk = read(obj.DiskDatastore);
            chunk = chunk{1};
            isFinished = ~obj.hasSpilledData() && isempty(obj.Buffer);
        end
    end
    
    methods (Static)
        function out = maxBufferSize(in)
            % Persistent value for controlling the maximum buffer size
            % before this object spills to disk.
            
            import matlab.bigdata.internal.io.ExternalInputBuffer;
            
            persistent value;
            if isempty(value)
                value = ExternalInputBuffer.DEFAULT_MAX_BUFFER_SIZE_IN_BYTES;
            end
            if nargout
                out = value;
            end
            if nargin
                value = in;
            end
        end
        
    end
end

function iWriteDataToDisk(location, data)
% Write the contents of datastore or local MATLAB array to the given
% location.
import matlab.bigdata.internal.io.createWriteFunction;
try
    fileType = "auto";
    filePattern = "";
    isIri = false;
    isHdfs = false;
    iCreateDirectory(location);
    writer = createWriteFunction(fileType, location, filePattern, isIri, isHdfs);
    info = struct( ...
        'PartitionId', 1, ...
        'NumPartitions', 1, ...
        'IsLastChunk', true );
    
    feval(writer, info, data);
catch err
    matlab.bigdata.internal.io.throwTempStorageError(err);
end
end

function iCreateDirectory(path)
% Helper function that creates a directory with no warnings.
[success, msgId, message] = mkdir(path);
if ~success
    error(msgId, '%s', message);
end
end
