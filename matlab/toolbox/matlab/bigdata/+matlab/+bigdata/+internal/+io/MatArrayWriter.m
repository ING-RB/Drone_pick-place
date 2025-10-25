classdef MatArrayWriter < matlab.bigdata.internal.io.Writer & matlab.mixin.Copyable
%MATARRAYWRITER A write to add tall data to disk.
%   MatArrayWriter Methods:
%   add - Add array values to MAT-Files
%
%   See also datastore, tall, mapreduce.

%   Copyright 2016-2018 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % Buffer to hold on to arrays added.
        ArrayBuffer;
        % Serializer used to serialize data to MAT-Files.
        Serializer;
    end

    properties (Constant, Access = private)
        OUTPUT_FILE_PREFIX = 'array';
        OUTPUT_FILE_SUFFIX = 'snapshot';
    end

    methods
        function obj = MatArrayWriter(arrayIdx, numIndices, location, filePattern, optionalMidfix)
            if nargin < 4
                filePattern = '';
            end
            if nargin < 5
                optionalMidfix = '';
            end
            
            arrayIdxStr = matlab.bigdata.internal.util.convertToZeroPaddedString(arrayIdx, numIndices);
            prefix = [matlab.bigdata.internal.io.MatArrayWriter.OUTPUT_FILE_PREFIX, optionalMidfix, ...
                sprintf('_r%s', arrayIdxStr)];
            obj.ArrayBuffer = matlab.mapreduce.internal.ValueBuffer;
            
            if ~isempty(filePattern) && strlength(filePattern)>0
                if endsWith(filePattern, ".mat")
                    [~, filePattern] = fileparts(filePattern);
                end
                filePattern = strrep(filePattern , "*", arrayIdxStr + "_%06u");
            end
            
            obj.Serializer = matlab.mapreduce.internal.MatValueSerializer(...
                prefix, location, matlab.bigdata.internal.io.MatArrayWriter.OUTPUT_FILE_SUFFIX, filePattern);
        end

        function add(obj, value)
            append(obj.ArrayBuffer, {value});
            if serialize(obj.Serializer,...
                    obj.ArrayBuffer.Buffer, obj.ArrayBuffer.BytesUsed, ...
                    obj.ArrayBuffer.SizeBuffered)
                % If serialized the buffer, make the buffer empty
                obj.ArrayBuffer.initialize();
            end
        end

        function commit(obj)
            % If any of the buffer has values, serialize them
            if numel(obj.ArrayBuffer.Buffer) > 0
                serialize(obj.Serializer,...
                    obj.ArrayBuffer.Buffer, inf, ...
                    obj.ArrayBuffer.SizeBuffered);
            end
        end
    end
end
