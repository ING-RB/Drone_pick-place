%ContextClassLoaderGuard
% Helper class to ensure the thread context ClassLoader is correct whenever
% accessing HDFS from MATLAB.

%   Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed, Hidden) ContextClassLoaderGuard < handle
    properties (SetAccess = immutable, Transient)
        Guard;
    end
    
    methods
        % The main constructor.
        function obj = ContextClassLoaderGuard()
            hdfsLoader = com.mathworks.storage.hdfsloader.GlobalHdfsLoader.get();
            obj.Guard = hdfsLoader.newContextClassLoaderGuard();
        end
        
        % Scope cleanup of the guard.
        function delete(obj)
            if ~isempty(obj.Guard)
                close(obj.Guard);
            end
        end
    end
end
