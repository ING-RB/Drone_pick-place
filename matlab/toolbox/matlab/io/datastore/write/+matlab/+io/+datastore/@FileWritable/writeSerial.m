function writeSerial(ds, location, compressStr, nvStruct)
%writeSerial    Serial processing of datastore writeall

%   Copyright 2023 The MathWorks, Inc.

    % Work on a copy of the datastore to ensure that write is a
    % stateless operation.
    dsCopy = copy(ds);
    dsCopy.OrigFileSep = ds.OrigFileSep;
    reset(dsCopy);
    numFilesRead = 0;
    cachedFilename = "";

    writingToParquet = any(lower(nvStruct.OutputFormat) == ["parquet", "parq"]);
    usingCustomWriteFcn = ~any(contains(nvStruct.UsingDefaults, "WriteFcn"));    
    while hasdata(dsCopy)
        % Read from the input datastore.
        [data, readInfo] = read(dsCopy);

        % Error here for CombinedDatastore, SequentialDatastore and
        % TransformedDatastore if the output of read is not a scalar unit.
        dsClass = class(dsCopy);
        isNotSupportedForOutputFormatCDSWrite = iscell(data) && size(data,2) > 1;
        classWithOutputFormatRestriction = "matlab.io.datastore." + ...
            ["TransformedDatastore", "CombinedDatastore", "SequentialDatastore"];
        isRestrictedOutputFormat = any(dsClass == classWithOutputFormatRestriction);
        if isNotSupportedForOutputFormatCDSWrite && isRestrictedOutputFormat ...
                && ~usingCustomWriteFcn
            error(message("MATLAB:io:datastore:write:write:SingleOutputRead", dsClass));
        end

        % Get file name from the info struct and normalize to string.
        currFilename = getCurrentFilename(dsCopy,readInfo);        

        if any(cachedFilename == "") || ~currentFileIndexComparator(dsCopy, numFilesRead)
            % Datastore has moved to the next file, check whether the new
            % file already exists in the output location.

            if isa(compressStr,"matlab.io.datastore.internal.CompressedStrings")
                [outputName, numFilesRead] = getOutputNames(data, compressStr, ...
                    numFilesRead, currFilename, dsCopy.OrigFileSep);
            else
                outputName = compressStr;
                if ~writingToParquet || ...
                        (writingToParquet && isempty(dsCopy.ParquetWriter))
                    checkForExistenceOfFile(outputName, currFilename)
                end
                numFilesRead = numFilesRead + 1;
            end

            % if writing to Parquet, close the current writer
            if writingToParquet && numFilesRead > 1
                commitToParquetFile(dsCopy, dsCopy.ParquetWriter);
            end
        end

        % Build the WriteInfo struct.
        writeInfo = matlab.io.datastore.WriteInfo(readInfo, outputName, location);

        % Call the necessary writing function while forwarding
        % unmatched N-V pairs.
        if usingCustomWriteFcn
            nvStruct.WriteFcn(data, writeInfo, nvStruct.OutputFormat, ...
                nvStruct.Unmatched{:});
        else
            if writingToParquet
                if isempty(nvStruct.Unmatched)
                    writeToParquet(dsCopy, data, writeInfo.SuggestedOutputName);
                else
                    error(message("MATLAB:io:datastore:write:write:UnrecognizedNVPair", ...
                        nvStruct.Unmatched{1}));
                end
            else
                dsCopy.write(data, writeInfo, nvStruct.OutputFormat, ...
                    nvStruct.Unmatched{:});
            end
        end
        cachedFilename = currFilename;
    end
end

function commitToParquetFile(ds, parquetWriter)
    close(parquetWriter);
    ds.ParquetWriter = [];
end

function writeToParquet(ds, data, filenameToWrite)
    % Check whether Parquet is OutputFormat, set up Parquet writing
    import matlab.io.parquet.internal.createParquetWriter
    import matlab.io.internal.arrow.schema.TableSchema

    try
        data = matlab.io.arrow.matlab2arrow(data);
        if isempty(ds.ParquetWriter)
            % first time, create the writer
            tableSchema = TableSchema.buildTableSchema(data);
            ds.ParquetWriter = createParquetWriter(filenameToWrite, tableSchema);
        end
    catch
        error(message("MATLAB:parquetio:table:DataNotTabular"));
    end
    write(ds.ParquetWriter, data);
end

function [outputName, numFilesRead] = getOutputNames(data, compressStr, ...
    numFilesRead, currFilename, origFileSep)
    % Get the output file name from the compressed string of file names
    if iscell(data) && size(currFilename,1) > 1
        % Case where ReadSize > 1
        outputName = strings(numel(data),1);
        for ii = 1: size(outputName,1)
            outputName(ii) = getCompressedString(compressStr, numFilesRead+1, ...
                origFileSep);
            checkForExistenceOfFile(outputName(ii), currFilename(ii));
            numFilesRead = numFilesRead + 1;
        end
    else
        currFilename = string(currFilename);
        outputName = getCompressedString(compressStr, numFilesRead+1, ...
            origFileSep);
        % Case where a single file is being written
        checkForExistenceOfFile(outputName, currFilename);
        numFilesRead = numFilesRead + 1;
    end
    outputName = string(outputName);
end

function checkForExistenceOfFile(outputName, origFilename)
    % check if the file exists
    if isfile(outputName)
        % file exists, error to avoid partial overwrites
        dirStruct = dir(outputName{1});
        error(message("MATLAB:io:datastore:write:write:ExistingFile", ...
            origFilename, fullfile(dirStruct.folder, dirStruct.name)));
    end
end
