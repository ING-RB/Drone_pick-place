function [location, isIri, isHdfs] = validateLocationString(location)
%VALIDATELOCATIONSTRING Validate location string provided to tall/write method.
%
%   [L, isIri, isHdfs] = VALIDATELOCATIONSTRING(L) validates the location
%   string, without checking for the existence of the location. This will
%   still resolve the location if the input is a relative local path.
%
%   This is safe to invoke on the client machine if in a parallel setting.

%   Copyright 2018-2020 The MathWorks, Inc.

import matlab.io.datastore.internal.localPathToIRI;
import matlab.io.datastore.internal.localPathFromIRI;
import matlab.io.internal.vfs.validators.hasIriPrefix;

validateattributes(location, {'char', 'string'}, {'nonempty'}, ...
    'tall/write', 'location');

% in case if location is a string
location = char(location);
isIri = matlab.io.datastore.internal.isIRI(location);
isHdfs = isIri && startsWith(location, 'hdfs');

if isIri
    location = matlab.io.internal.vfs.normalizeIRI(location);
end

if isHdfs
    % Check that a hadoop installation is available
    try
        matlab.io.internal.vfs.hadoop.discoverHadoopInstallFolder();
    catch
        error(message('MATLAB:bigdata:write:HadoopRequiredLocation'));
    end
end

if ~isIri && hasIriPrefix(location)
    error(message('MATLAB:bigdata:write:InvalidRemoteWriteLocation', location));
end

if ~isIri
    % This is to canonicalize any relative paths.
    try
        location = localPathFromIRI(localPathToIRI(location));
    catch
        error(message('MATLAB:bigdata:write:InvalidWriteLocation', location));
    end
    location = location{1};
end
