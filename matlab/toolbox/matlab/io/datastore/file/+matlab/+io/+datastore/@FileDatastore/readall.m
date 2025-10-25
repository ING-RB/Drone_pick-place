function data = readall(fds, varargin)
%READALL Read all of the files from the datastore.
%   DATAARR = READALL(FDS) reads all of the files from FDS.
%   DATAARR is a cell array containing the data returned by the read method
%   on reading all the files in the FileDatastore.
%
%   DATAARR = READALL(FDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   See also fileDatastore, hasdata, read, preview, reset.

%   Copyright 2015-2020 The MathWorks, Inc.

if matlab.io.datastore.read.validateReadallParameters(varargin{:})
    data = matlab.io.datastore.read.readallParallel(fds);
    return;
end

try
    if isEmptyFiles(fds)
        data = fds.BufferedZero1DimData;
        return;
    end
    fdsCopy = copy(fds);
    reset(fdsCopy);
    data = cell(numel(fdsCopy.Files), 1);
    ii = 1;
    origReadCounter = fdsCopy.PrivateReadCounter;
    fdsCopy.PrivateReadCounter = true;
    while hasdata(fdsCopy)
        try
            % ensures that concatenation is along the column dimension
            data{ii, :} = read(fdsCopy);
        catch ME
            if strcmpi(ME.identifier,'MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded')
                fds.PrivateReadFailuresList = fdsCopy.PrivateReadFailuresList;
            end
            throw(ME);
        end
        ii = ii + 1;
    end
    % data(cellfun(@isempty,data)) = [];
    fdsCopy.PrivateReadCounter = origReadCounter;
    dispReadallWarning(fdsCopy);
    fds.PrivateReadFailuresList = fdsCopy.PrivateReadFailuresList;
    if fds.UniformRead
        data = vertcat(data{:});
    end
catch ME
    throw(ME);
end
end