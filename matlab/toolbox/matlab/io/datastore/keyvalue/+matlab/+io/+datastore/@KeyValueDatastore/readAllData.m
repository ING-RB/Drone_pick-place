function data = readAllData(kvds, varargin)
%READALLDATA Read all of the key-value pairs from a KeyValueDatastore.
%   T = READALLDATA(KVDS) reads all of the key-value pairs from KVDS.
%   T is a table with variables 'Key' and 'Value'.
%
%   T = READALL(KVDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   See also matlab.io.datastore.KeyValueDatastore, hasdata, read, preview, reset

%   Copyright 2016-2020 The MathWorks, Inc.

import matlab.io.datastore.KeyValueDatastore;

if matlab.io.datastore.read.validateReadallParameters(varargin{:})
    data = matlab.io.datastore.read.readallParallel(kvds);
    return;
end

try
    % reset the datastore to the beginning
    % reset also errors when files are deleted between save-load of the datastore
    % to/from MAT-Files (and between releases).
    kvdsCopy = copy(kvds);
    reset(kvdsCopy);

    % If empty files return an empty table with correct VariableNames for the empty
    % empty table
    if isEmptyFiles(kvdsCopy) || ~hasdata(kvdsCopy)
        data = matlab.io.datastore.TabularDatastore.emptyTabular(kvdsCopy,KeyValueDatastore.TABLE_OUTPUT_VARIABLE_NAMES);
        return;
    end
    % read all the data
    origReadCounter = kvdsCopy.PrivateReadCounter;
    kvdsCopy.PrivateReadCounter = true;
    try
        data = readAllSplits(kvdsCopy.Splitter, kvds.ReadFailureRule, kvds.MaxFailures);
    catch ME
        if strcmpi(ME.identifier,'MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded')
            kvds.PrivateReadFailuresList = kvdsCopy.Splitter.PrivateReadFailuresList;
        end
        exp = matlab.io.datastore.FileBasedDatastore.errorHandlerRoutine(kvds,ME);
        throwAsCaller(exp);
    end
    kvdsCopy.PrivateReadCounter = origReadCounter;
    dispReadallWarning(kvdsCopy);
    kvds.PrivateReadFailuresList = kvdsCopy.Splitter.PrivateReadFailuresList;
catch ME
    throwAsCaller(ME);
end
end