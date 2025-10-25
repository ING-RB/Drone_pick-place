function enableHdfsLogging()
%

%   Copyright 2017-2020 The MathWorks, Inc.

% Ensure the appropriate libraries are loaded.
matlab.io.internal.vfs.hadoop.hadoopLoader();

hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
hdfsLoader.enableLogging();
