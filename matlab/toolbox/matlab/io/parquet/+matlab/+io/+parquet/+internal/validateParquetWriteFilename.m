function filename = validateParquetWriteFilename(filename)
%VALIDATEPARQUETWRITEFILENAME  Validates filename for parquetwrite

%   Copyright 2022-2023 The MathWorks, Inc.

    % filename should be a non-empty char row vec or string scalar.
    if ~matlab.internal.datatypes.isScalarText(filename, false)
        msg = message("MATLAB:parquetio:write:BadFilename");
        throwAsCaller(MException(msg));
    end

     % Normalize input to use strings
    filename = convertCharsToStrings(filename);
    exts = [".parquet", ".parq"];

    % Check if a file extension was provided as part of the input
    [~,~,e] = fileparts(filename);
    hasProvidedExt = strlength(e) > 0;

    if ~hasProvidedExt && ~any(endsWith(filename, exts))
        % Append the default .parquet extension if no extension is present
        filename = filename + ".parquet";
    end

    isIRI = matlab.io.internal.vfs.validators.isIRI(char(filename));

    if isIRI
        if startsWith(filename, "http", IgnoreCase=true)
            % G3034920: Provide clear error message for HTTP/S URLs as we
            % can never write to HTTP/S URLs.
            msg = message("MATLAB:virtualfileio:stream:writeNotAllowed");
            throwAsCaller(MException(msg));
        end

        if startsWith(filename, "hdfs")
            % Check remote path requirements
            matlab.io.internal.vfs.hadoop.discoverHadoopInstallFolder();
        end
    end

    if ~isIRI
        % Error if the directory to write the file to doesn't exist.
        parentFolder = fileparts(filename);
        if ~isValidLocalPath(parentFolder)
            msg = message("MATLAB:parquetio:write:InvalidDirectory", parentFolder);
            throwAsCaller(MException(msg));
        end
    end
end

% Check if a non-existent path is provided for writing a new Parquet file.
function tf = isValidLocalPath(folder)
% Check if the parent folder name is empty. This signifies a relative path
% pointing to the current directory, which is a valid path.
    tf = strlength(folder) == 0;

    % If the parent folder name is nonempty, then check if the folder exists
    % in the local filesystem.
    tf = tf || isfolder(folder);
end

