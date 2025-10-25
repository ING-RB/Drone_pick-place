function tf = hasdata(fds)
%HASDATA   Returns true if there is data available to read from the datastore.

%   Copyright 2022 The MathWorks, Inc.

    tf = fds.FileSet.hasNextFile();
end