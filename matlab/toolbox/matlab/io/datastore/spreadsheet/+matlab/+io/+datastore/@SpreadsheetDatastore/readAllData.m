function data = readAllData(ds, varargin)
%READALLDATA Read all of the data from a SpreadsheetDatastore.
%   T = READALLDATA(SSDS) reads all of the data from SSDS.
%   T is a table with variables governed by SSDS.SelectedVariableNames.
%
%   T = READALL(SSDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   Example:
%   --------
%      % Create a SpreadsheetDatastore
%      ssds = spreadsheetDatastore('airlinesmall_subset.xlsx')
%      % We are only interested in the Arrival Delay data
%      ssds.SelectedVariableNames = 'ArrDelay'
%      % read all the data
%      tab = readall(ssds);
%
%   See also - matlab.io.datastore.SpreadsheetDatastore, hasdata, readall, preview, reset.

%   Copyright 2016-2020 The MathWorks, Inc.

    if matlab.io.datastore.read.validateReadallParameters(varargin{:})
        data = matlab.io.datastore.read.readallParallel(dsCopy);
        return;
    end

    try
        dsCopy = copy(ds);
        reset(dsCopy);

        % If empty files return an empty table with correct SelectedVariableNames
        if isEmptyFiles(dsCopy) || ~hasdata(dsCopy)
            data = matlab.io.datastore.TabularDatastore.emptyTabularWithVarTypes(...
                dsCopy, dsCopy.SelectedVariableNames, dsCopy.TextType);
            return;
        end

        % set ReadSize to 'file'
        dsCopy.ReadSize = 'file';
        tblCells = cell(1, dsCopy.Splitter.NumSplits);

        readIdx = 1;
        origReadCounter = dsCopy.PrivateReadCounter;
        dsCopy.PrivateReadCounter = true;
        while hasdata(dsCopy)
            try
                tblCells{readIdx} = read(dsCopy);
            catch ME
                if strcmpi(ME.identifier,'MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded')
                    ds.PrivateReadFailuresList = dsCopy.PrivateReadFailuresList;
                end
                throwAsCaller(ME);
            end
            readIdx = readIdx + 1;
        end
        dsCopy.PrivateReadCounter = origReadCounter;
        dispReadallWarning(dsCopy);
        ds.PrivateReadFailuresList = dsCopy.PrivateReadFailuresList;
        data = vertcat(tblCells{:});
    catch ME
        throwAsCaller(ME);
    end
end