%HadoopConfiguration
% Helper class to access the global Hadoop configuration object that is
% used by datastore to access HDFS.

%   Copyright 2014-2018 The MathWorks, Inc.

classdef (Sealed, Hidden) HadoopConfiguration
    
    methods (Static)
        % Get the global Hadoop configuration object.
        function conf = getGlobalConfiguration()
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
            conf = hdfsLoader.getGlobalConfiguration();
        end
        
        % Set the global Hadoop configuration object.
        function setGlobalConfiguration(conf)
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
            hdfsLoader.setGlobalConfiguration(conf);
        end
        
        % Create a FileSystem object using the global Hadoop configuration.
        % This expects to be passed an instance of java.net.URI with the
        % correct scheme for the filesystem.
        function fileSystem = getGlobalFileSystem(uri)
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
            fileSystem = hdfsLoader.getFileSystem(uri);
        end
    end
    
    methods (Access = private)
        % Not instantiable
        function obj = HadoopConfiguration(); end
    end    
end
