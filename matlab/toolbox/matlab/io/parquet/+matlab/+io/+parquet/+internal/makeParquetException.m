function e = makeParquetException(e, filename, mode)
%MAKEPARQUETEXCEPTION Make a Parquet exception object.
%
% Read failures:
%
% If the environment variable MW_PARQUET_DEBUG == "on", then a
% MATLAB:parquetio:read:InternalInvalidRead exception is thrown.
% Otherwise, a MATLAB:parquetio:read:InvalidRead exception is thrown.
%
% Unsupported Parquet types:
%
% If trying to read an unsupported Parquet type, then a
% MATLAB:parquetio:read:UnsupportedParquetType exception is thrown.
% The resulting error message will contain a table mapping
% Parquet physical and Parquet logical types to MATLAB types.

% Copyright 2018-2024 The MathWorks, Inc.

    % Extract the filename back out of a ParquetReadCacher.
    if isa(filename, "matlab.io.parquet.internal.ParquetReadCacher")
        filename = filename.Filename;
    end

    % Normalize all filenames to be absolute paths.
    filename = absolutizePath(filename);
    
    switch e.identifier
        case 'MATLAB:parquetio:read:InternalUnsupportedParquetType'
            e = makeUnsupportedParquetTypeException(e, filename);
        case 'MATLAB:parquetio:read:InternalInvalidRead'
            e = makeInvalidReadException(e, filename);
        case 'MATLAB:virtualfileio:stream:fileNotFound'
            % Provides a better error message if the file was
            % not found due to invalid env variables.
            matlab.io.internal.vfs.validators.validateCloudEnvVariables(filename);
        case 'MATLAB:virtualfileio:stream:permissionDenied'
            e = makePermissionDeniedException(e, filename, mode);
    end
end

function e = makeUnsupportedParquetTypeException(e, filename)
    % Create a table containing the Parquet types in the given file.
    info = matlab.io.parquet.internal.parquetTypeErrorInfo(filename);
    
    t = table();
    % Supported types have a non-missing value for VariableTypes.
    t.("Supported") = ~ismissing(info.VariableTypes);
    t.("Parquet Type") = categorical(info.ParquetTypes);
    t.("MATLAB Type") = categorical(info.VariableTypes);

    % Set table RowNames to be the Parquet variable names.
    t.Properties.RowNames = info.VariableNames;
    
    % Create a string containing the table contents
    % which can be included in the resulting error
    % message.
    parquetTypesTableMessage = table2message(t);

    newMessage = message('MATLAB:parquetio:read:UnsupportedParquetType', ...
                         e.message, ...
                         filename, ...
                         parquetTypesTableMessage);
    
    e = MException(newMessage);
end

function e = makeInvalidReadException(e, filename)
    debugModeEnvironmentVariable = 'MW_PARQUET_DEBUG';
    debugModeEnabled = getenv(debugModeEnvironmentVariable) == "on";
    
    if ~debugModeEnabled
        msg = message('MATLAB:parquetio:read:InvalidRead', filename);
        e = MException(msg);
    end
end

function e = makePermissionDeniedException(e, filename, mode)
    % Provides a better error message if the file was
    % not found due to invalid env variables.
    matlab.io.internal.vfs.validators.validateCloudEnvVariables(filename);

    if mode == "read"
        msg = message("MATLAB:io:common:file:ReadPermissionDenied", filename);
        e = MException(msg);
    else % mode == "write"
        msg = message("MATLAB:io:common:file:WritePermissionDenied", filename);
        e = MException(msg);
    end
end

function msg = table2message(t) %#ok<INUSD> 
    % Disable hotlinks when in "-nodesktop"
    % mode so that XML attributes are not displayed.
    hotlinksAreEnabled = feature('hotlinks');
    if hotlinksAreEnabled
        msg = evalc('disp(t);');
    else
        msg = evalc('feature hotlinks off; disp(t);');
        feature('hotlinks', hotlinksAreEnabled);
    end
end

function filename = absolutizePath(filename)
    try
        filename = string(matlab.io.datastore.internal.pathLookup(filename));
    catch e
        % If the specified filename is not found on the path,
        % pass through the unmodified filename.
    end
end
