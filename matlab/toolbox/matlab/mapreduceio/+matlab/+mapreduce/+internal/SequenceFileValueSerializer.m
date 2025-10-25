classdef (Sealed, Hidden) SequenceFileValueSerializer < matlab.mapreduce.internal.Serializer
%SequenceFileValueSerializer
% Helper class that writes only value output to a Sequence File.
%

%   Copyright 2016-2020 The MathWorks, Inc.


    properties (Access = private)
        % The internal SequenceFile.Writer Java Object.
        InternalWriter = [];
        % Null Writable Key
        NullWritableKey = [];
    end

    methods
        function obj = SequenceFileValueSerializer(filename)
            % Construct a SequenceFileKeyValueSerializer that outputs to the sequence
            % file of given name.
            import matlab.io.internal.vfs.hadoop.hadoopLoader;
            import matlab.io.datastore.internal.ContextClassLoaderGuard;
            import matlab.io.datastore.internal.HadoopConfiguration;

            % Load hadoop provider, if not loaded already.
            hadoopLoader;
            
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();

            mxArrayWritable2 = hdfsLoader.newMxArrayWritable2();
            obj.NullWritableKey = hdfsLoader.newNullWritable();

            valueClass = mxArrayWritable2.getUnderlyingClass();
            keyClass = obj.NullWritableKey.getUnderlyingClass();

            guard = ContextClassLoaderGuard(); %#ok<NASGU>

            path = matlab.io.datastore.internal.buildHadoopPath(filename);
            
            fileSystem = HadoopConfiguration.getGlobalFileSystem(path.toUri());
            
            % Use the compatible api for both 1.x and 2.x
            obj.InternalWriter = hdfsLoader.newSequenceFileWriter(...
                fileSystem, fileSystem.getConf(), path, keyClass, valueClass);
        end

        function tf = serialize(obj, values)
            % Add the given values to the Sequence file.
            % The values input must be a cell array.
            writer = obj.InternalWriter;
            writer.sync();
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
            for ii = 1:numel(values)
                value = mxarraywritableproxyserialize(hdfsLoader, values{ii});
                writer.append(obj.NullWritableKey, value);
            end
        end

        function delete(obj)
            % Cleanup of internal resources
            if ~isempty(obj.InternalWriter)
                obj.InternalWriter.close();
            end
        end
    end
end
