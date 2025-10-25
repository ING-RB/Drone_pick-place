function [data, info] = read(fds)
%READ   Use the ReadFcn to read from the next filename in the datastore.
%
%   DATA = READ(DS) reads the next filename in the datastore using ReadFcn.
%
%   [DATA, INFO] = READ(DS) also returns a struct containing
%       additional information about DATA:
%        - Filename: scalar string filename
%        - FileSize: scalar double bytes (integer, non-negative)
%
%   See also: matlab.io.Datastore

%   Copyright 2022 The MathWorks, Inc.

    if ~fds.hasdata()
        msgid = "MATLAB:io:datastore:common:read:NoMoreData";
        error(message(msgid));
    end

    % Get the next Filename and FileSize.
    fileInfo = fds.FileSet.nextfile();

    filename = fileInfo.Filename;
    fileSize = fileInfo.FileSize;

    % Call the ReadFcn and build the info struct.
    data = fds.ReadFcn(filename);
    info = struct(Filename=filename, FileSize=fileSize);
end
