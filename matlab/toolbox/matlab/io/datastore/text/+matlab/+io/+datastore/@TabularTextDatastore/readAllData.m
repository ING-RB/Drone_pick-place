function data = readAllData(ds, varargin)
%READALLDATA Read all of the data from a TabularTextDatastore.
%   T = READALLDATA(TDS) reads all of the data from TDS.
%   T is a table with variables governed by TDS.SelectedVariableNames.
%
%   T = READALL(TDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   Example:
%   --------
%      % Create a TabularTextDatastore
%      tabds = tabularTextDatastore('airlinesmall.csv')
%      % Handle erroneous data
%      tabds.TreatAsMissing = 'NA';
%      tabds.MissingValue = 0;
%      % We are only interested in the Arrival Delay data
%      tabds.SelectedVariableNames = 'ArrDelay'
%      tab = readall(tabds);
%      sumAD = sum(tab.ArrDelay)
%
%   See also - matlab.io.datastore.TabularTextDatastore, hasdata, read, preview, reset.

%   Copyright 2014-2020 The MathWorks, Inc.

if matlab.io.datastore.read.validateReadallParameters(varargin{:})
    data = matlab.io.datastore.read.readallParallel(ds);
    return;
end

try
    dsCopy = copy(ds);
    % TODO(g1758457): We disable the info struct for performance reasons in
    % cases where it is not needed. This optimization will be made obsolete
    % in the fullness of time.
    dsCopy.ShouldCalcBytesForInfo = false;
    reset(dsCopy);

    % If empty files return an empty table with correct SelectedVariableNames
    if isEmptyFiles(dsCopy) || ~hasdata(dsCopy)
        data = matlab.io.datastore.TabularDatastore.emptyTabularWithVarTypes(dsCopy, ...
            dsCopy.SelectedVariableNames, dsCopy.TextType);
        return;
    end

    % estimate max rows per read by num variables
    dsCopy.ReadSize = max( 1, floor(4e6/numel(dsCopy.VariableNames)) );

    tblCells = cell(1, dsCopy.Splitter.NumSplits);
    origReadCounter = dsCopy.PrivateReadCounter;
    dsCopy.PrivateReadCounter = true;
    readIdx = 1;
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