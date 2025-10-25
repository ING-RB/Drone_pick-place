classdef SequenceFileArrayWriter < matlab.bigdata.internal.io.Writer & matlab.mixin.Copyable
%SEQUENCEARRAYWRITER A writer to add tall data to Sequence files on disk.
%   SequenceArrayWriter Methods:
%   add - Add array values to Sequence Files
%
%   See also datastore, tall, mapreduce.

%   Copyright 2016-2020 The MathWorks, Inc.
    properties (SetAccess = immutable)
        Serializer;
    end

    properties (Constant, Access = private)
        OUTPUT_FILE_NAME_FORMAT = 'part-%s-snapshot.seq';
    end

    methods
        function obj = SequenceFileArrayWriter(arrayIdx, numIndices, location, filePattern)
            import matlab.bigdata.internal.io.SequenceFileArrayWriter;
            location = matlab.io.datastore.internal.PathTools.ensureIsIri(location);

            if nargin<4 || isempty(filePattern) || strlength(filePattern)==0
                filePattern = SequenceFileArrayWriter.OUTPUT_FILE_NAME_FORMAT;
            else
                filePattern = strrep(filePattern, "*", "%s");
            end
            
            arrayIdxStr = matlab.bigdata.internal.util.convertToZeroPaddedString(arrayIdx, numIndices);
            filename = sprintf(filePattern, arrayIdxStr);
            if matlab.io.datastore.internal.isIRI(location)
                filename = matlab.io.datastore.internal.iriFullfile(location, filename);
            else
                filename = fullfile(location, filename);
            end
            try
                obj.Serializer = matlab.mapreduce.internal.SequenceFileValueSerializer(filename);
            catch ME
                % If tall data is on hdfs and if the cluster cannot write to this location 
                % directory, then we need to error asking to provide a writable location.
                if ME.identifier ~= "MATLAB:Java:GenericException"
                    throw(ME);
                end
                
                if isa(ME.ExceptionObject, 'com.mathworks.storage.hdfsloader.proxy.ExceptionProxy')
                    name = getName(ME.ExceptionObject);
                else
                    name = class(ME.ExceptionObject);
                end
                
                if strcmpi(name, 'java.io.FileNotFoundException') ...
                        && contains(ME.message, 'Permission denied')
                    % Parsing the error message in the Java exception seems
                    % to be the only way to get the root cause of
                    % "FileNotFoundException".
                    error(message('MATLAB:bigdata:write:UnwritableLocation', location));
                elseif strcmpi(name, 'org.apache.hadoop.security.AccessControlException')
                    baseException = MException('MATLAB:bigdata:write:InvalidWriteLocation', ...
                        message('MATLAB:bigdata:write:InvalidWriteLocation', location));
                    causeException = MException('MATLAB:mapreduceio:serialmapreducer:folderNotForWriting', ...
                        ME.message);
                    ME = addCause(baseException, causeException);
                end
                throw(ME);
            end
        end

        function add(obj, value)
            obj.Serializer.serialize({value});
        end

        % In a Hadoop context, commit is dealt with by Hadoop.
        function commit(~)
        end
    end
end
