function location = buildHadoopIri(location)
%BUILDHADOOPPATH Build a IRI compatible with Hadoop that represents the given
% location.

%   Copyright 2017-2020 The MathWorks, Inc.
import matlab.io.datastore.internal.PathTools;
if matlab.io.datastore.internal.isIRI(location)
    location = matlab.io.internal.vfs.normalizeIRI(location);
else
    location = PathTools.convertLocalPathToIri(location);
end
if ispc
    % On Windows, we represent UNC paths by placing the hostname into the
    % hostname part of the IRI. Hadoop does not support this, so we
    % replace this with an explicit UNC \\ directly in the path part.
    fileIriBase = "file://";
    hostlessFileIriBase = "file:///";
    if startsWith(location, fileIriBase) && ~startsWith(location, hostlessFileIriBase)
        uncFileIriBase = "file:///%5C%5C";
        location = strrep(location, fileIriBase, uncFileIriBase);
    end
end
