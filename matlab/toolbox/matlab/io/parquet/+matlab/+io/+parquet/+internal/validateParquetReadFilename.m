function [filename, fileObj] = validateParquetReadFilename(filename)
%VALIDATEPARQUETREADFILENAME Validates filename for parquetread and
%parquetinfo.

%   Copyright 2022 The MathWorks, Inc.

    % filename should be a non-empty char row vec or string scalar.
    if ~matlab.internal.datatypes.isScalarText(filename, false)
        msg = message("MATLAB:parquetio:read:BadFilename");
        throwAsCaller(MException(msg));
    end

    % check if HTTP/HTTPS, download to local file if so
    if matlab.io.internal.vfs.stream.RemoteToLocal.hasHTTPSPrefix(filename)
        fileObj = matlab.io.internal.vfs.stream.RemoteToLocal(filename);
    else
        fileObj = [];
    end

    isIri = matlab.io.internal.vfs.validators.isIRI(char(filename));

    if isIri && ~isempty(fileObj)
        % Downloaded a temp copy of the file
        filename = fileObj.LocalFileName;
        isIri = false;
    end

    if isIri
        fileNotFound = lookupRemoteFilename(filename);
    else
        [filename, fileNotFound] = lookupLocalFilename(filename);
    end

    if fileNotFound
        % Provides a better error message if the reason the file was 
        % not found due to invalid env variables.
        matlab.io.internal.vfs.validators.validateCloudEnvVariables(filename);

        % Otherwise, throw a FileNotFound exception
        msg = message("MATLAB:parquetio:read:FileNotFound", filename);
        throwAsCaller(MException(msg));
    end
end

function fileNotFound = lookupRemoteFilename(filename)
    % Check remote path requirements to read from Hadoop
    if startsWith(filename, "hdfs")
        matlab.io.internal.vfs.hadoop.discoverHadoopInstallFolder();
    end

    % IRI must be absolute so just check if it exists.
    fileNotFound = ~matlab.io.internal.vfs.validators.isFile(filename);
end

function [filename, fileNotFound] = lookupLocalFilename(filename)
    try
        exts = {'.parquet', '.parq'};
        filename = matlab.io.internal.validators.validateFileName(filename, exts, true);
        filename = convertCharsToStrings(filename{1});
        fileNotFound = false;
    catch e
        % Rethrow all underlying error messages except the textio::FileNotFound
        % message which is explicitly handled later.
        if e.identifier == "MATLAB:textio:textio:FileNotFound"
            fileNotFound = true;
        else
            throwAsCaller(e);
        end
    end
end
