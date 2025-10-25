function writeParallel(ds, location, files, nvStruct)
%writeParallel    Determine whether writeall should be called in serial,
%   parallel, or on an HDFS cluster.
%

%   Copyright 2023 The MathWorks, Inc.
    % if UseParallel is set to true, start up a parallel pool or
    % use the existing parallel pool (if PCT is installed)
    import matlab.io.datastore.internal.write.utility.setupParallelPool;
    import matlab.io.datastore.internal.shim.isPartitionable;
    import matlab.io.datastore.write.createOutputNames;
    import matlab.io.datastore.write.createCompressedPaths;

    % check whether this datastore is partitionable and can suport UseParallel
    tf = isPartitionable(ds);
    if ~tf && nvStruct.UseParallel
        error(message("MATLAB:io:datastore:write:write:NoUseParallelSupport"));
    elseif isa(ds, "matlab.io.datastore.CombinedDatastore") && nvStruct.UseParallel
        error(message("MATLAB:io:datastore:write:write:NoUseParallelCombined"));
    elseif isTransformOfCombinedDatastore(ds) && nvStruct.UseParallel
        error(message("MATLAB:io:datastore:write:write:NoUseParallelCombined"));
    end

    % Get the parallel computing context
    mr = gcmr('nocreate');

    % Get the unique list of file names
    pathStruct = createOutputNames(files, location, nvStruct, ds.OrigFileSep);
    compressStr = createCompressedPaths(pathStruct, ds.OrigFileSep);
    if ~isempty(mr) && ~any(contains(class(mr), ["matlab.mapreduce.SerialMapReducer", ...
            "matlab.mapreduce.ParallelMapReducer"])) && nvStruct.UseParallel
        % Hadoop or deployed context
        writeHadoop(ds, location, compressStr, mr, nvStruct);
    else
        M = 0;
        if nvStruct.UseParallel
            % get workers for parallel writing
            poolObj = setupParallelPool();
            if ~isempty(poolObj)
                if isa(poolObj, "parallel.Pool")
                    M = poolObj.NumWorkers;
                end
            end
        end

        if ~nvStruct.UseParallel
            % Serial writing
            writeSerial(ds, location, compressStr, nvStruct);
        else
            % Parallel writing
            origFileSep = ds.OrigFileSep;
            parfor (ii = 1 : size(files,1), M)
                subds = partition(ds, 'Files', ii);
                subds.OrigFileSep = origFileSep;
                filenameToWrite = getPaths(compressStr.EncodedStrings, ii, ...
                    origFileSep); %#ok<PFBNS>
                writeSerial(subds, location, filenameToWrite, nvStruct);
            end
        end
    end
end

function tf = isTransformOfCombinedDatastore(ds)
    tf = false;
    if isa(ds, "matlab.io.datastore.TransformedDatastore")
        for ii = 1 : numel(ds.UnderlyingDatastores)
            if isa(ds.UnderlyingDatastores{ii}, "matlab.io.datastore.TransformedDatastore")
                tf = isTransformOfCombinedDatastore(ds.UnderlyingDatastores{ii});
                if tf
                    return;
                end
            elseif isa(ds.UnderlyingDatastores{ii}, "matlab.io.datastore.CombinedDatastore")
                tf = true;
                return;
            end
        end
    end
end