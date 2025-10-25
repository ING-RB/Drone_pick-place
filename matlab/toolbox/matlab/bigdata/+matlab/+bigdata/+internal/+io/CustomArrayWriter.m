classdef CustomArrayWriter < matlab.bigdata.internal.io.Writer & matlab.mixin.Copyable
    %CUSTOMARRAYWRITER Wrapper for writing data to disk using a user-supplied function.
    %   CustomArrayWriter Methods:
    %   ADD     Add array values to the current buffer
    %   COMMIT  Write the current buffer to disk
    %
    %   See also datastore, tall, mapreduce.
    
    %   Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        UserFcn;
        PartitionIndex;
        NumPartitions;
        Location;
        FilePattern;
        MaxRowsPerBlock;
    end
    
    properties (SetAccess = private)
        ArrayBuffer; % Buffer to hold on to arrays added.
        BlockInPartition;
        IsLastBlock;
    end
    
    methods
        function obj = CustomArrayWriter(fcn, partitionIndex, numPartitions, location, filePattern, maxRowsPerBlock)
            obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
            obj.UserFcn = fcn;
            obj.PartitionIndex = partitionIndex;
            obj.NumPartitions = numPartitions;
            obj.Location = location;
            if isempty(filePattern)
                obj.FilePattern = 'data_*';
            else
                obj.FilePattern = filePattern;
            end
            if nargin>5 && ~isempty(maxRowsPerBlock)
                obj.MaxRowsPerBlock = maxRowsPerBlock;
            else
                obj.MaxRowsPerBlock = 2000000;
            end
            obj.BlockInPartition = 0;
            obj.IsLastBlock = false;
        end
        
        function add(obj, value)
            append(obj.ArrayBuffer, {value});
            % Check if we've buffered too much and if so, commit.
            if rowsBuffered(obj.ArrayBuffer) > obj.MaxRowsPerBlock
                obj.flushBlocks(false);
            end
        end
        
        function commit(obj)
            % If any of the buffer has values, serialize them
            obj.flushBlocks(true);
        end
        
        function flushBlocks(obj, commitAll)
            % Write any full blocks to disk. Partial blocks are left in the
            % buffer unless flushPartial is set true.
            if numel(obj.ArrayBuffer.Buffer) == 0
                % Nothing to do
                return;
            end
            
            % Combine the buffer into one large array for writing
            data = vertcat(obj.ArrayBuffer.Buffer{1:obj.ArrayBuffer.SizeBuffered});
            numBlocks = floor(size(data,1) / obj.MaxRowsPerBlock);
            for block = 1:numBlocks
                % Make the info struct
                obj.BlockInPartition = obj.BlockInPartition + 1;
                startIdx = 1 + (block-1)*obj.MaxRowsPerBlock;
                endIdx = block*obj.MaxRowsPerBlock;
                obj.IsLastBlock = commitAll && (endIdx == size(data, 1));
                feval(obj.UserFcn, obj.makeInfoStruct(), data(startIdx:endIdx, :));
            end
            % If there is a partial block at the end, either write it out
            % or put it back in the buffer.
            if numBlocks*obj.MaxRowsPerBlock < size(data,1)
                startIdx = 1 + numBlocks*obj.MaxRowsPerBlock;
                data = data(startIdx:end, :);
                if commitAll
                    obj.BlockInPartition = obj.BlockInPartition + 1;
                    obj.IsLastBlock = true;
                    feval(obj.UserFcn, obj.makeInfoStruct(), data);
                    % We've written the last block, so reset the buffer
                    obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
                else
                    % Flush buffer, and re-insert the remaining data
                    obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
                    append(obj.ArrayBuffer, {data});
                end
            else
                % No partial blocks. Reset the buffer.
                obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
            end
        end
        
        function info = makeInfoStruct(obj)
            % Create an info struct to pass the the custom writer function
            
            % Build a suggested filename based on the partition (if more
            % than one) and block.
            if obj.NumPartitions <= 1
                % Block only
                uid = sprintf('%06u', obj.BlockInPartition);
            else
                % Partition and block
                uid = sprintf('%s_%06u', ...
                    matlab.bigdata.internal.util.convertToZeroPaddedString(obj.PartitionIndex, obj.NumPartitions), ...
                    obj.BlockInPartition);
            end
            filename = fullfile(obj.Location, strrep(obj.FilePattern, '*', uid));
            
            info = struct( ...
                'RequiredLocation', obj.Location, ...
                'RequiredFilePattern', obj.FilePattern, ...
                'SuggestedFilename', filename, ...
                'PartitionIndex', obj.PartitionIndex, ...
                'NumberOfPartitions',  obj.NumPartitions, ...
                'BlockIndexInPartition', obj.BlockInPartition, ...
                'IsLastBlock', obj.IsLastBlock);
        end
    end
end
