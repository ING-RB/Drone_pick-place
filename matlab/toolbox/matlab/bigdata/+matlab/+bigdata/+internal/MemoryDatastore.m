classdef (Sealed) MemoryDatastore < matlab.io.Datastore & matlab.io.datastore.Partitionable
    %MemoryDatastore Datastore for blocking/partitioning in-memory data.
    %
    % This wraps a MATLAB array in a datastore, with options to control the
    % partitioning and the blocking.
    %
    
    %  Copyright 2019-2020 The MathWorks, Inc.
    
    properties
        % Number of rows/slices per read. This must be a positive integer,
        % or Inf/NaN to denote read entire partitions.
        ReadSize (1,1) double = Inf
        
        % Maximum number of partitions allowed. Values greater than the
        % height of the data will be ignored, as well as Inf or NaN, will
        % be ignored.
        MaxPartitions (1,1) double = Inf
        
        % Unique ID that represents the data underlying this datastore.
        DatastoreId
        
        % Last index after the partition. If the partition is empty, this
        % will be zero.
        PartitionEnd (1,1) double
    end
    
    properties (Access = {?matlab.bigdata.internal.executor.PrepartitionablePartition})
        % The full data underlying the datastore. This is never altered,
        % even when partitioned, as such modifications would create a copy.
        Data
    end
    
    properties (Access = private)
        % First index of the partition.
        PartitionStart (1,1) double = 1
        
        % The index of the next slice to be read.
        Index (1,1) double = 1
    end
    
    properties (Access = private, Constant)
        % The means by which this class receives unique IDs.
        IdFactory = matlab.bigdata.internal.util.UniqueIdFactory('MemoryDatastore');
    end
    
    methods
        function obj = MemoryDatastore(data, id)
            % Main constructor.
            obj.Data = data;
            obj.PartitionEnd = size(data, 1);
            if nargin < 2
                obj.DatastoreId = obj.IdFactory.nextId();
            else
                obj.DatastoreId = id;
            end
        end
        
        %HASDATA   Returns true if more data is available.
        function tf = hasdata(obj)
            tf = (obj.Index <= obj.PartitionEnd);
        end
        
        %READ   Read data and information about the extracted data.
        function [data, info] = read(obj)
            startIndex = obj.Index;
            endIndex = min(obj.Index + obj.ReadSize - 1, obj.PartitionEnd);
            import matlab.bigdata.internal.util.indexSlices;
            data = indexSlices(obj.Data, startIndex:endIndex);
            
            if nargout >= 2
                info.Index = startIndex;
                info.Size = endIndex - startIndex + 1;
            end
            
            obj.Index = endIndex + 1;
        end
        
        %PREVIEW   Preview the data contained in the datastore.
        function data = preview(obj)
            endIndex = min(8, size(obj.Data, 1));
            import matlab.bigdata.internal.util.indexSlices;
            data = indexSlices(obj.Data, 1:endIndex);
        end
        
        %RESET   Reset to the start of the data.
        function reset(obj)
            obj.Index = obj.PartitionStart;
        end
        
        %PROGRESS   Percentage of consumed data between 0.0 and 1.0.
        function proc = progress(obj)
            proc = (obj.Index - obj.PartitionStart) / obj.sizeInTallDim();
            proc(isnan(proc)) = 1;
        end
        
        %PARTITION Return a partitioned part of the Datastore.
        function subds = partition(obj, N, idx)
            numSlices = obj.sizeInTallDim();
            startIndex = ceil((idx - 1) * numSlices / N) + 1;
            endIndex = ceil(idx * numSlices / N);
            subds = copy(obj);
            subds.PartitionStart = startIndex;
            subds.PartitionEnd = endIndex;
            subds.reset();
        end

        function tf = isCompatible(obj, other)
            % Check if two MemoryDatastore objects are compatible.
            tf = obj.sizeInTallDim() == other.sizeInTallDim();
        end
        
        function ds = createEmptyDatastore(obj, emptyChunk)
            % Create a copy of a datastore that contains an empty chunk of
            % data.
            ds = matlab.bigdata.internal.MemoryDatastore(emptyChunk, obj.DatastoreId);
            ds.PartitionEnd = obj.PartitionEnd;
            ds.ReadSize = obj.ReadSize;
        end
    end
    
    methods (Access = protected)
        %MAXPARTITIONS Return the maximum number of partitions possible for
        % the datastore.
        function n = maxpartitions(obj)
            n = min(obj.sizeInTallDim(), obj.MaxPartitions);
        end
    end
    
    methods (Access = private)
        function n = sizeInTallDim(obj)
            % Get the size of the partition of data in dimension 1.
            n = obj.PartitionEnd - obj.PartitionStart + 1;
        end
    end
end
