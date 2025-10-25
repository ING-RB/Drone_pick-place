%SequenceFileHeader
% Helper to get Sequence file header information.

%   Copyright 2014-2020 The MathWorks, Inc.

classdef (Sealed, Hidden) SequenceFileReader < handle
    properties (Access = private, Constant)
        JAVA_SEQUENCE_FILE_READER_NAME = 'com.mathworks.storage.hdfsloader.proxy.SequenceFileReaderInterface';
        SEQUENCE_FILE_STR = 'Sequence file';
        SEQUENCE_KEY_VALUE_CLASSNAME_2 = 'com.mathworks.hadoop.MxArrayWritable2';
        SEQUENCE_KEY_VALUE_CLASSNAME_3 = 'org.apache.hadoop.io.NullWritable';
    end

    methods (Static)
        function [keyClass, valueClass] = getKeyValueClasses(sequenceFileReader)
            import matlab.io.datastore.internal.SequenceFileReader;
            assert(isa(sequenceFileReader, SequenceFileReader.JAVA_SEQUENCE_FILE_READER_NAME))
            keyClass = char(sequenceFileReader.getKeyClassName());
            valueClass = char(sequenceFileReader.getValueClassName());
        end
        
        function sequenceReader = create(filename)
            import matlab.io.datastore.internal.ContextClassLoaderGuard;
            import matlab.io.datastore.internal.HadoopConfiguration;
            import matlab.io.datastore.internal.SequenceFileReader;
            import matlab.io.datastore.internal.PathTools;
            guard = ContextClassLoaderGuard(); %#ok<NASGU>

            pth = matlab.io.datastore.internal.buildHadoopPath(filename);
            conf = HadoopConfiguration.getGlobalConfiguration();
            fileSystem = HadoopConfiguration.getGlobalFileSystem(pth.toUri());
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
            try
                sequenceReader = hdfsLoader.newSequenceFileReader(...
                    fileSystem, pth, conf);
            catch ME
                if contains(ME.message,"com.mathworks.hadoop.MxArrayWritable") && ...
                        ~contains(ME.message,"com.mathworks.hadoop.MxArrayWritable2")
                    error(message('MATLAB:datastoreio:sequencefilesplitreader:unreadableLegacyFile'));
                else
                    throwAsCaller(ME);
                end
            end
        end

        function tf = isSeqSupported(filename, valuesOnly)
            import matlab.io.datastore.internal.ContextClassLoaderGuard;
            import matlab.io.datastore.internal.SequenceFileReader;
            error(javachk('jvm', SequenceFileReader.SEQUENCE_FILE_STR))
            tf = true;
            import matlab.io.internal.vfs.stream.createStream;
            ch = createStream(filename,'rb');
            c1 = onCleanup(@() close(ch));
            % read 3 uint8 (bytes) as column vector
            data = read(ch, 3, 'uint8');
            if ~strcmp(char(data'), 'SEQ')
                tf = false;
                return;
            end
            import matlab.io.internal.vfs.hadoop.hadoopLoader;
            hadoopLoader;
            guard = ContextClassLoaderGuard(); %#ok<NASGU>
            reader = SequenceFileReader.create(filename);
            c2 = onCleanup(@() reader.close());
            [kname, vname] = SequenceFileReader.getKeyValueClasses(reader);
            tf = SequenceFileReader.isValidSequenceClassNames(kname, vname, valuesOnly);
        end

        function tf = isValidSequenceClassNames(kname, vname, valuesOnly)
            import matlab.io.datastore.internal.SequenceFileReader;
            if valuesOnly
                tf = strcmp(SequenceFileReader.SEQUENCE_KEY_VALUE_CLASSNAME_3, kname);
            else
                tf = strcmp(SequenceFileReader.SEQUENCE_KEY_VALUE_CLASSNAME_2, kname);
            end
            tf = tf && strcmp(SequenceFileReader.SEQUENCE_KEY_VALUE_CLASSNAME_2, vname);
        end
    end

    methods (Access = private)
        % Not instantiable
        function obj = SequenceFileReader(); end
    end
end
