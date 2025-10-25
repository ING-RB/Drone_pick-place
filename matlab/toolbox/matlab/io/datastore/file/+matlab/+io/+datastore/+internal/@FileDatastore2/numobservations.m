function n = numobservations(fds)
%NUMOBSERVATIONS   Returns the number of reads in the datastore.

%   Copyright 2022 The MathWorks, Inc.

    n = fds.FileSet.NumFiles;
end