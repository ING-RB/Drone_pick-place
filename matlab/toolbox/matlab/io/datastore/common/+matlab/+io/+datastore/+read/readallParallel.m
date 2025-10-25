function data = readallParallel(ds)
%readallParallel    Parallel processing of datastore readall

%   Copyright 2021-2024 The MathWorks, Inc.
    import matlab.io.datastore.internal.write.utility.setupParallelPool;
    tf = isPartitionable(ds);
    if ~tf
        error(message("MATLAB:io:datastore:write:write:NoUseParallelSupport"));
    end

    % number of partitions
    N = numpartitions(ds);
    % Get the parallel computing context. We guard against gcmr function
    % not being present because that is a downstream API and as such, MATLAB
    % Compiler is allowed to not include it if the end-user didn't setup
    % such an environment.
    mr = [];
    if exist('gcmr', 'file')
        mr = gcmr('nocreate');
    end
    if ~isempty(mr) && ~any(contains(class(mr), ["matlab.mapreduce.SerialMapReducer", ...
            "matlab.mapreduce.ParallelMapReducer"]))
        % Hadoop or deployed context
        if isUnsupportedOnHadoop(ds)
            error(message("MATLAB:datastoreio:datastorereadall:DsNotSupported", class(ds)));
        else
            if N > 0
                data = matlab.io.datastore.internal.read.readallHadoop(ds, mr);
            else
                % empty datastore, serial case can handle appropriate return type
                data = [];
            end
        end
    else
        % make a copy of the datastore and reset it
        copyds = copy(ds);
        reset(copyds);

        % get workers for parallel reading
        poolObj = setupParallelPool();
        if isempty(poolObj)
            M = 1;
        else
            M = poolObj.NumWorkers;
            % Recompute numpartitions with the Pool's suggestion.
            N = numpartitions(copyds, poolObj);
        end

        % Preallocate the output from each worker.
        data = cell(N, 1);

        % MDFDatastore is not compatible with ThreadPools.
        if isa(copyds, "matlab.io.datastore.MDFDatastore") && isa(poolObj, "parallel.ThreadPool")
            error(message("MATLAB:datastoreio:datastorereadall:MDFThreadsNotSupported"));
        end

        % Partition the datastore into N pieces.
        % Distribute reading data from the partitions
        % among M parallel workers.
        parfor (ii = 1 : N, M)
            subds = partition(copyds, N, ii);
            data{ii} = readall(subds);
        end

        % Unpack and vertically concatenate the results
        % from all the partitions.
        data = vertcat(data{:});
    end
    if N == 0
        % The parfor loop wasn't executed, so we need to get the right
        % empty datatype from the datastore itself.
        data = readall(ds);
    end
end

function tf = isUnsupportedOnHadoop(ds)

    % Variadic meta-datastores are not performing readall in parallel on Hadoop.
    isVariadicTransformFcn = @(ds) isa(ds, "matlab.io.datastore.TransformedDatastore") ...
                                   && (numel(ds.UnderlyingDatastores) > 1);
    isVariadicCombineFcn = @(ds) isa(ds, "matlab.io.datastore.CombinedDatastore");
    isKeyValueDatastore = @(ds) isa(ds, "matlab.io.datastore.KeyValueDatastore");

    isUnsupportedDatastoreFcn = @(ds) isVariadicTransformFcn(ds) ...
                                   || isVariadicCombineFcn(ds) ...
                                   || isKeyValueDatastore(ds);

    % Returns true if any underlying datastore is unsupported.
    tf = ds.anyUnderlyingDatastores(isUnsupportedDatastoreFcn);
end
