function writeall(ds, location, varargin)
%WRITEALL    Read all the data in the datastore and write to disk
%   WRITEALL(DS, OUTPUTLOCATION, "OutputFormat", FORMAT)
%   writes files using the specified output format. The allowed
%   FORMAT values are:
%     - Tabular formats: "txt", "csv", "xlsx", "xls", "parquet", "parq"
%     - Image formats: "png", "jpg", "jpeg", "tif", "tiff"
%     - Audio formats: "wav", "ogg", "flac", "mp4", "m4a"
%
%   WRITEALL(__, "FolderLayout", LAYOUT) specifies whether folders
%   should be copied from the input data locations. Specify
%   LAYOUT as one of these values:
%
%     - "duplicate" (default): Input files are written to the output
%       folder using the folder structure under the folders listed
%       in the "Folders" property.
%
%     - "flatten": Files are written directly to the output
%       location without generating any intermediate folders.
%
%   WRITEALL(__, "FilenamePrefix", PREFIX) specifies a common
%   prefix to be applied to the output file names.
%
%   WRITEALL(__, "FilenameSuffix", SUFFIX) specifies a common
%   suffix to be applied to the output file names.
%
%   WRITEALL(DS, OUTPUTLOCATION, "WriteFcn", @MYCUSTOMWRITER)
%   customizes the function that is executed to write each
%   file. The signature of the "WriteFcn" must be similar to:
%
%      function MYCUSTOMWRITER(data, writeInfo, outputFmt, varargin)
%         ...
%      end
%
%   where 'data' is the output of the read method on the
%   datastore, 'outputFmt' is the output format to be written,
%   and 'writeInfo' is a struct containing the
%   following fields:
%
%     - "ReadInfo": the second output of the read method.
%
%     - "SuggestedOutputName": a fully qualified, unique file
%       name that meets the location and naming requirements.
%
%     - "Location": the location argument passed to the write
%       method.
%   Any optional Name-Value pairs can be passed in via varargin.
%
%   See also: matlab.io.datastore.SequentialDatastore

%   Copyright 2022 The MathWorks, Inc.

import matlab.io.datastore.write.*;
try
    % Validate the location input first.
    location = validateOutputLocation(ds, location);
    ds.OrigFileSep = matlab.io.datastore.internal.write.utility.iFindCorrectFileSep(location);

    % if this datastore is backed by files, get list of files
    files = getFiles(ds);

    % if this datastore is backed by files, get list of folders
    folders = getFolders(ds);

    % Set up the name-value pairs
    nvStruct = parseWriteallOptions(ds, varargin{:});

    % Check if the underlying datastore initialized
    % SupportedOutputFormats
    try
        underlyingFmts = getUnderlyingSupportedOutputFormats(ds);
    catch
        underlyingFmts = [];
    end
    outFmt = unique([ds.SupportedOutputFormats, underlyingFmts]);

    % Validate the name-value pairs
    nvStruct = validateWriteallOptions(ds, folders, nvStruct, outFmt);

    % Construct the output folder structure.
    createFolders(ds, location, folders, nvStruct.FolderLayout);

    % Write using a serial or parallel strategy.
    writeParallel(ds, location, files, nvStruct);
catch ME
    switch ME.identifier
        case "MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastoreGetFilesError"
            writeallErrorMsgID = "MATLAB:io:datastore:common:sequentialdatastore:WriteallError";
            writeallErrorException = MException(writeallErrorMsgID, message(writeallErrorMsgID));

            appendedMsgBaseException = MException(writeallErrorMsgID, [ME.message, '\n', writeallErrorException.message]);
            appendedMsgBaseException = addCause(appendedMsgBaseException, ME.cause{1});

            throw(appendedMsgBaseException);
        case "MATLAB:parquetio:table:DataNotTabular"
            % Special handling needed for "parquet" type formats as instead
            % of SequentialDatastore/write method, it uses the local
            % writeToParquet in  matlab.io.datastore.FileWritable/writeSerial.
            parquetWriteErrorID = "MATLAB:io:datastore:common:sequentialdatastore:ParquetWriteError";
            parquetWriteErrorException = MException(parquetWriteErrorID, message(parquetWriteErrorID, nvStruct.OutputFormat));

            writeallErrorMsgID = "MATLAB:io:datastore:common:sequentialdatastore:WriteallError";

            appendedMsgBaseException = MException(parquetWriteErrorID, [parquetWriteErrorException.message, '\n', message(writeallErrorMsgID).getString()]);
            appendedMsgBaseException = addCause(appendedMsgBaseException, ME);
            throw(appendedMsgBaseException);
        otherwise
            % Throw an exception without the full stack trace. If the
            % MW_DATASTORE_DEBUG environment variable is set to 'on',
            % the full stacktrace is shown.
            handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
            handler(ME);
    end
end
end