function data = readall(tds, varargin)
%READALL Read all of the datas rows from an TallDatastore.
%   T = READALL(TDS) reads all of the data rows from TDS.
%
%   T = READALL(TDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   See also matlab.io.datastore.TallDatastore, hasdata, read, preview, reset

%   Copyright 2016-2020 The MathWorks, Inc.

if matlab.io.datastore.read.validateReadallParameters(varargin{:})
    data = matlab.io.datastore.read.readallParallel(tds);
    return;
end

try
    if isEmptyFiles(tds)
        data = getZeroFirstDimData(tds);
        return;
    end
    % reset the datastore to the beginning
    % reset also errors when files are deleted between save-load of the datastore
    % to/from MAT-Files (and between releases).
    tdsCopy = copy(tds);
    reset(tdsCopy);
    % read all the data
    origReadCounter = tdsCopy.PrivateReadCounter;
    tdsCopy.PrivateReadCounter = true;
    try
        data = readAllSplits(tdsCopy.Splitter, tdsCopy.ReadFailureRule, tdsCopy.MaxFailures);
    catch ME
        if strcmpi(ME.identifier,'MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded')
            tds.PrivateReadFailuresList = tdsCopy.Splitter.PrivateReadFailuresList;
        end
        throwAsCaller(ME);
    end
    tdsCopy.PrivateReadCounter = origReadCounter;
    tds.PrivateReadFailuresList = tdsCopy.Splitter.PrivateReadFailuresList;
    % Get only the values
    data = vertcat(data.Value{:});
catch ME
    throw(matlab.io.datastore.FileBasedDatastore.errorHandlerRoutine(tds,ME));
end
end
