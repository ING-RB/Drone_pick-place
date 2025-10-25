function isDifferentFile = currentFileIndexComparator(obj, index)
%currentFileIndexComparator   Returns false if the supplied
%   (0-based) index matches the index of the file being read.
%
%   This is used during writeall.

%   Copyright 2022 The MathWorks, Inc.

    % TODO: We really need read index reporting from the underlying datastore tree.
    % Maybe this could be done through Skippable?
    fs = obj.getUnderlyingFileDatastore().FileSet;

    % FileWritable checks for currentFileIndexComparator *after* calling
    % read() on the datastore. So we have to compare if the previous file
    % index matches the current writeall index.
    isSameFile = (fs.NumFilesRead-1) == index;

    isDifferentFile = ~isSameFile;
end
