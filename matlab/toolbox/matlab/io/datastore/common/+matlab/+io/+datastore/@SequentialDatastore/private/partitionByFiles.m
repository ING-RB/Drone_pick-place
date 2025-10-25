function partds = partitionByFiles(ds, partitionStrategy, partitionIndex)

%   Copyright 2022 The MathWorks, Inc.

try
    % Basic type validation for Partition Index/ Filename.
    partitionIndex = convertStringsToChars(partitionIndex);
    validateattributes(partitionIndex, {'char', 'string', 'numeric'}, ...
        {'nonempty'}, 'partition', 'third argument');

    if isnumeric(partitionIndex)
        validateattributes(partitionIndex, {'numeric'}, ...
            {'scalar', 'integer', 'positive'}, ...
            "partition", "PartitionIndex");
    else
        % Filename as Partition Index, do basic type, size validations.
        filename = partitionIndex;
        validateattributes(filename, {'char', 'string'}, ...
            {'nonempty', 'row'}, 'partition', 'Filename');
    end
catch ME
    throw(ME);
end

try
    % Populate files list from underlying datastores.
    [files, numFilesPerDS] = getFiles(ds);
catch ME
    switch ME.identifier
        case "MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastoreGetFilesError"
            PartitionByFilesErrorMsgID = "MATLAB:io:datastore:common:sequentialdatastore:PartitionByFilesError";
            PartitionByFilesErrorException = MException(PartitionByFilesErrorMsgID, message(PartitionByFilesErrorMsgID));

            appendedMsgBaseException = MException(PartitionByFilesErrorMsgID, [ME.message, '\n', PartitionByFilesErrorException.message]);
            appendedMsgBaseException = addCause(appendedMsgBaseException, ME.cause{1});

            throw(appendedMsgBaseException);
        otherwise
            throw(ME);
    end
end

try
    % Validate if all non-empty underlying datastores support partitioning
    % by "Files".
    if isempty(ds.isFilesPartitionable)
        for idx = 1:length(numFilesPerDS)
            if (numFilesPerDS(idx) > 0)
                % Non-empty datastore. If partition errors, catch and exit.
                try
                    partition(ds.UnderlyingDatastores{idx}, partitionStrategy, 1);
                catch ME
                    switch ME.identifier
                        case "MATLAB:partition:invalidType"
                            ds.isFilesPartitionable.value = false;
                            ds.isFilesPartitionable.idx = idx;
                            error(message("MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastorePartitionByFilesError", ds.isFilesPartitionable.idx));
                        otherwise
                            throw(ME);
                    end
                end
            end
        end

        % Set private property, so that we don't have to validate
        % partitionability by "Files" every time.
        ds.isFilesPartitionable.value = true;
        ds.isFilesPartitionable.idx = [];
    elseif ~ds.isFilesPartitionable.value
        error(message("MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastorePartitionByFilesError", ds.isFilesPartitionable.idx));
    end
catch ME
    switch ME.identifier
        case "MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastorePartitionByFilesError"
            PartitionByFilesErrorMsgID = "MATLAB:io:datastore:common:sequentialdatastore:PartitionByFilesError";
            PartitionByFilesErrorException = MException(PartitionByFilesErrorMsgID, message(PartitionByFilesErrorMsgID));

            appendedMsgBaseException = MException(ME.identifier, [ME.message, '\n', PartitionByFilesErrorException.message]);

            throwAsCaller(appendedMsgBaseException);
        otherwise
            throw(ME);
    end
end

if isnumeric(partitionIndex)
    % Numeric Partition Index, check if within valid range.
    totalNumFiles = length(files);
    validateattributes(partitionIndex, {'numeric'}, ...
        {'scalar', '<=', totalNumFiles}, "partition", "PartitionIndex");
else
    % Find the numeric index in files list corresponding to the input
    % filename. If none or more than one, error.
    partitionIndex = getNumericIndexForFilename(files, filename);
end

% Find the underlying datastore and the corresponding granularFileIndex for
% a given partitionIndex.
[dsIndex, granularFileIndex] = getDSIndexAndGranularFileIndex(numFilesPerDS, partitionIndex);

partds = partition(ds.UnderlyingDatastores{dsIndex}, partitionStrategy, granularFileIndex);
partds = matlab.io.datastore.SequentialDatastore(partds);
end

function fileIndex = getNumericIndexForFilename(files, filename)
% Get the index from the files list for an input filename. If none or more
% than one, error.

fileIndex = strcmp(files, filename);
fileIndex = find(fileIndex);
filenameCount = length(fileIndex);

if filenameCount == 1
    return;
elseif filenameCount > 1
    % Duplicate filenames exist, need index number to partition by "Files".
    error(message('MATLAB:datastoreio:splittabledatastore:ambiguousPartitionFile', filename))
elseif filenameCount == 0
    % Filename not available in the files list from datastore.
    error(message('MATLAB:datastoreio:splittabledatastore:invalidPartitionFile', filename));
end
end