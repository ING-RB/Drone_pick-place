function [location, isIri, isHdfs] = validateLocation(location)
%VALIDATELOCATION Validate location provided to tall/write method.
%
%   [L, isIri, isHdfs] = VALIDATELOCATION(L) resolves the supplied location
%   and returns it in L.  isIri is a scalar logical that is true when L is
%   a an IRI.  isHdfs is a scalar logical that is true when L is an IRI for
%   a Hadoop Distributed File System location.
%
%   This should only be invoked on a worker if in a parallel setting.

%   Copyright 2016-2020 The MathWorks, Inc.

[location, isIri, isHdfs] = matlab.bigdata.internal.util.validateLocationString(location);

% TODO: We need a datastore api just for checking if location is empty or
%       non-existing folder

files = [];
try
    files = matlab.io.datastore.internal.pathLookup(location);
catch err
    % Any EnvVariablesNotSet error indicates a problem that'll happen for
    % the actual write. Let this bubble up here.
    if contains(err.identifier, "EnvVariablesNotSet")
        rethrow(err);
    end
    % either not found or empty folder
end

if ~isempty(files)
    baseException = MException('MATLAB:bigdata:write:InvalidWriteLocation', ...
        message('MATLAB:bigdata:write:InvalidWriteLocation', location));
    causeException = MException('MATLAB:bigdata:write:InvalidNonEmptyLocation', ...
        message('MATLAB:bigdata:write:InvalidNonEmptyLocation'));
    err = addCause(baseException, causeException);
    throw(err);
end

% Convert file IRIs to an absolute path as seen by a worker.
isFileIri = isIri && startsWith(location, 'file');

if isFileIri
    location = matlab.io.datastore.internal.PathTools.convertIriToLocalPath(location);
end

if ~isIri || isFileIri
    try
        matlab.mapreduce.internal.validateFolderForWriting(location);
    catch err
        if ~isempty(err.cause)
            baseException = MException('MATLAB:bigdata:write:InvalidWriteLocation', ...
                message('MATLAB:bigdata:write:InvalidWriteLocation', location));
            err = addCause(baseException, err.cause{:});
            throw(err);
        else
            error(message('MATLAB:bigdata:write:InvalidWriteLocation', location));
        end
    end
end
end
