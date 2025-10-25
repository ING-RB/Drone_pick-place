classdef shim
    % Shim-layer that can access internals of specific datastore
    % implementations.
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    methods (Static)
        function disableCalcBytesForInfo(ds)
            % Disable ShouldCalcBytesForInfo if the given datastore is of
            % type TabularTextDatastore.
            %
            % TODO(g1758457): We disable the info struct for performance
            % reasons in cases where it is not needed.  This optimization
            % will be made obsolete in the fullness of time.
            if isa(ds, 'matlab.io.datastore.TabularTextDatastore')
                ds.ShouldCalcBytesForInfo = false;
            end
        end
        
        function location = getLocation(ds)
            %getLocation Compatibility layer for accessing HadoopFileBased/getLocation
            ds = matlab.io.datastore.internal.shim.unwrapTransforms(ds);
            if matlab.io.datastore.internal.shim.isV1ApiDatastore(ds)
                if ~ds.areSplitsOverCompleteFiles()
                    error(message('MATLAB:datastoreio:datastore:partitionUnsupportedOnHadoop'));
                end
                location = ds.Files;
            else
                location = ds.internalGetLocation();
            end
        end
        
        function initializeDatastore(ds, split)
            %initializeDatastore Compatibility layer for accessing HadoopFileBased/initializeDatastore
            ds = matlab.io.datastore.internal.shim.unwrapTransforms(ds);
            if isa(split, 'org.apache.hadoop.mapreduce.lib.input.FileSplit') ...
                    || isa(split, 'org.apache.hadoop.mapred.FileSplit')
                % Fake a matlab.bigdata.internal.hadoop.FileSplit. We
                % cannot use the real thing because MATLAB toolbox cannot
                % depend on shared/bigdata.
                [iri, off, len] = ...
                    matlab.io.datastore.internal.getHadoopInfoFromSplit(split);
                split = struct;
                split.Location = table(string(iri), off, len, ...
                    'VariableNames', ["FileName", "Offset", "Size"]);
            end

            if matlab.io.datastore.internal.shim.isV1ApiDatastore(ds)
                ds.initFromHadoopSplit(split);
            else
                location = split.Location;
                % Make this a struct for legacy reasons - HadoopFileBased
                % uses structs instead of tables.
                if matlab.io.datastore.internal.shim.isHadoopFileBased(ds)
                    location = table2struct(location);
                    location.FileName = char(location.FileName);
                end
                ds.internalInitializeDatastore(location);
            end
        end
        
        function tf = isFullfile(ds)
            %isFullfile Compatibility layer for accessing HadoopFileBased/isfullfile
            ds = matlab.io.datastore.internal.shim.unwrapTransforms(ds);
            if matlab.io.datastore.internal.shim.isV1ApiDatastore(ds)
                tf = ds.areSplitsWholeFile();
            else
                tf = ds.internalIsFullfile();
            end
        end
    end
    
    methods (Access = private)
        function obj = shim()
        end
    end
end
