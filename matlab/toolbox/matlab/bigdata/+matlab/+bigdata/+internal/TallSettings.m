classdef TallSettings < handle & matlab.mixin.Copyable
    %TallSettings Collection of settings to tune tall array evaluation.
    %
    % Example:
    %  % To enable in-memory blocking, get the settings handle object and
    %  % set the appropriate property:
    %  tallSettings = matlab.bigdata.internal.TallSettings.get();
    %  tallSettings.EnableInMemoryBlock = true;
    
    %   Copyright 2019 The MathWorks, Inc.
    
    properties
        % Flag to enable in-memory blocking. If true, tall arrays
        % constructed from in-memory data will divide that in-memory data
        % into blocks and partitions.
        EnableInMemoryBlock (1,1) logical = true
        
        % Maximum size of each block in bytes if in-memory blocking is
        % enabled.
        InMemoryBlockSizeInBytes (1,1) double = 134217728 % 128 MB
        
        % Maximum number of partitions if in-memory blocking is enabled. If
        % left at Inf, the number of partitions is decided solely by the
        % tall evaluation back-end.
        InMemoryBlockMaxPartitions (1,1) double = Inf
        
        % Amount of time to wait before recalculating progress updates.
        TimePerProgressUpdate (1,1) double = 1 % 1 second
        
        % Maximum number of partitions for the serial environment. The choice
        % of 2 is the smallest value where the data is not all in a single
        % partition.
        SerialMaxNumPartitions (1,1) double = 2
        
        % List of datastore classes that environments must respect
        % numpartitions(ds) without fail. This exists for testing purposes.
        FixedPartitionDatastores (:,1) string = string.empty
    end
    
    methods (Static)
        function settings = get()
            % Get the settings for the local process. This must only be
            % invoked from the client MATLAB.
            settings = matlab.bigdata.internal.TallSettings.singleton();
        end
        
        function set(settings)
            % Set the settings for the local process. This must only be
            % invoked from the client MATLAB.
            assert(isa(settings, "matlab.bigdata.internal.TallSettings"), ...
                "Assertion failed: Input must be a TallSettings object");
            matlab.bigdata.internal.TallSettings.singleton(settings);
        end
    end
    
    methods
        function set.InMemoryBlockSizeInBytes(obj, data)
            validateattributes(data, "double", {'positive', 'scalar', 'integer'});
            obj.InMemoryBlockSizeInBytes = data;
        end
        
        function set.InMemoryBlockMaxPartitions(obj, data)
            validateattributes(data, "double", {'positive', 'scalar', 'integer'});
            obj.InMemoryBlockMaxPartitions = data;
        end
        
        function set.SerialMaxNumPartitions(obj, data)
            validateattributes(data, "double", {'positive', 'scalar', 'integer'});
            obj.SerialMaxNumPartitions = data;
        end
    end
    
    methods (Static, Access = private)
        function out = singleton(in)
            % Singleton TallSettings for the local process.
            persistent state;
            if isempty(state)
                state = matlab.bigdata.internal.TallSettings();
            end
            if nargout
                out = state;
            end
            if nargin
                state = in;
            end
        end
    end
end
