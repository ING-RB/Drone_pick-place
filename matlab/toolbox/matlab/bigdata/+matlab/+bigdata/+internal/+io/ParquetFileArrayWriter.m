classdef ParquetFileArrayWriter < matlab.bigdata.internal.io.Writer & matlab.mixin.Copyable
    %PARQUETFILEARRAYWRITER
    
    %   Copyright 2018-2023 The MathWorks, Inc.
    
    properties (Constant)
        % The default maximum row group size as measured in-memory
        DEFAULT_MAX_ROW_GROUP_SIZE_BYTES = 128 * 1024^2;
    end
    
    properties (Constant, Access = private)
        OUTPUT_FILE_NAME_FORMAT = 'data_%s.parquet';
    end
    
    properties (SetAccess = private)
        Filename
        FileWriter
        OptionalArgs
        ArrayBuffer
    end
    
    methods
        function obj = ParquetFileArrayWriter(partitionIndex, numPartitions, location, optionalArgs, filePattern)
            import matlab.bigdata.internal.io.ParquetFileArrayWriter;
            import matlab.io.datastore.internal.PathTools.ensureIsIri
            import matlab.bigdata.internal.util.convertToZeroPaddedString
            import matlab.io.datastore.internal.iriFullfile
            
            % ensureIsIri doesn't appear to support strings
            location = convertStringsToChars(location);
            location = ensureIsIri(location);
            obj.OptionalArgs = optionalArgs;
            
            if nargin<5 || isempty(filePattern) || strlength(filePattern)==0
                filePattern = ParquetFileArrayWriter.OUTPUT_FILE_NAME_FORMAT;
            else
                filePattern = convertStringsToChars(filePattern);
                filePattern = strrep(filePattern, '*', '%s');
            end
            
            arrayIdxStr = convertToZeroPaddedString(partitionIndex, numPartitions);
            filename = sprintf(filePattern, arrayIdxStr);
            obj.Filename = iriFullfile(location, filename);
            obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
        end
        
        function add(obj, value)
            import matlab.io.parquet.internal.createParquetWriter
            import matlab.io.parquet.internal.validateTabularShape
            import matlab.io.internal.arrow.schema.TableSchema
            import matlab.bigdata.internal.util.indexSlices

            % Check that data input is supported by Parquet.  This is done
            % a second time here as the full array attributes might not
            % have been known on the client.
            validateTabularShape(value);

            if isempty(value)
                % Don't bother writing anything for empty blocks.
                % This has the effect of removing empty partitions.
                return;
            end

            if isempty(obj.FileWriter)
                % First time through, create the writer with VariableNames
                % and optional settings applied.
                tableSchema = TableSchema.buildTableSchema( ...
                    matlab.io.arrow.matlab2arrow(value));
                obj.FileWriter = createParquetWriter(obj.Filename, tableSchema, obj.OptionalArgs{:});
            end

            % Combine the buffer into one large array for writing.
            obj.ArrayBuffer.append({value});
            data = vertcat(obj.ArrayBuffer.Buffer{1:obj.ArrayBuffer.SizeBuffered});

            numSlices = size(data, 1);
            numBytes = matlab.bigdata.internal.util.getSizeInBytes(data);
            numSlicesPerBlock = ceil(obj.maxRowGroupSize() / numBytes * numSlices);
            if numSlices <= 1 || numSlices < numSlicesPerBlock
                % Not enough data to write a full block.
                return;
            end

            % Write out full blocks.
            blockLimits = 1:numSlicesPerBlock:numSlices;
            for ii = 1:numel(blockLimits)-1
                value = matlab.io.arrow.matlab2arrow( ...
                    indexSlices(data, blockLimits(ii):blockLimits(ii+1)));
                write(obj.FileWriter, value);
            end

            % Flush buffer and re-insert any remaining data.
            remainingData = indexSlices(data, blockLimits(end):size(data,1));
            obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
            obj.ArrayBuffer.append({remainingData});
        end
        
        function commit(obj)
            % Write out any remaining data and flush the buffer.
            if obj.ArrayBuffer.SizeBuffered > 0
                data = vertcat(obj.ArrayBuffer.Buffer{1:obj.ArrayBuffer.SizeBuffered});
                data = matlab.io.arrow.matlab2arrow(data);
                write(obj.FileWriter, data);
                obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
            end
            % Close the file.
            close(obj.FileWriter);
        end
    end
    
    methods (Static)
        function out = maxRowGroupSize(in)
            % The maximum size in bytes for each written row group. Note,
            % the size is measured in-memory and not for the serialized
            % size on disk.
            
            import matlab.bigdata.internal.io.ParquetFileArrayWriter;
            persistent value;
            if isempty(value)
                value = ParquetFileArrayWriter.DEFAULT_MAX_ROW_GROUP_SIZE_BYTES;
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
