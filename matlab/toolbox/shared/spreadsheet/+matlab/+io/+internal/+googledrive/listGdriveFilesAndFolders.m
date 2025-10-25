function [result, metadata] = listGdriveFilesAndFolders(location, opts)
%LISTGDRIVEFILESANDFOLDERS List files and folders in Google Drive.
%   Takes 2 inputs -- first input is folder whose listing is required, and
%   second input is options, i.e. list files, list folders, list all. If
%   the first input is empty, we consider that a recursive listing is
%   required.

% Copyright 2024 The MathWorks, Inc.

arguments(Input)
    location (1, 1) string = missing;
    opts.ListAll (1,1) logical {mustBeNumericOrLogical} = true
    opts.ListAllFiles (1,1) logical {mustBeNumericOrLogical} = false
    opts.ListAllFolders (1,1) logical {mustBeNumericOrLogical} = false
end

rawJsonResponseString = matlab.io.internal.googledrive.listFilesAndFolders(location, opts);
decodedJsonResponseString = jsondecode(rawJsonResponseString);

if isfield(decodedJsonResponseString, "error")
    error(decodedJsonResponseString.error.message);
end

namesCellArray = arrayfun(@(file) file.name, decodedJsonResponseString.files, ...
    'UniformOutput', false);

if nargout == 2
    metadata = struct2table(decodedJsonResponseString.files);
    metadata.Properties.VariableTypes = ["string", "string", "string", ...
        "string", "cell"];
    metadata.modifiedTime = datetime(metadata.modifiedTime, InputFormat= ...
        'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', TimeZone="UTC");
    metadata.quotaBytesUsed = str2double(metadata.quotaBytesUsed);
    metadata = movevars(metadata, "name", "Before", "mimeType");
    metadata = movevars(metadata, "id", "After", "name");
end

result = string(namesCellArray);
end