function newds = subset(rptds, subsetIndices)
%SUBSET   Create a new RepeatedDatastore containing a subset of the input RepeatedDatastore.
%
%   SUBDS = subset(RPTDS, INDICES) returns a new RepeatedDatastore SUBDS that contains
%   a subset of the data from the input RepeatedDatastore RPTDS.
%
%   INDICES can be specified as a numeric or logical vector of indices.

%   Copyright 2021-2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.RepeatedDatastore;
    import matlab.io.datastore.internal.validators.validateSubsetIndices;
    import matlab.io.datastore.exceptions.makeDebugModeHandler;

    try
        subsetIndices = validateSubsetIndices(subsetIndices, rptds.numobservations(), ...
                                              'matlab.io.datastore.internal.RepeatedDatastore', ...
                                              false); % Allow repeated subset indices.
    catch ME
        handler = makeDebugModeHandler();
        handler(ME);
    end

    % If all the RepetitionIndices are not already computed, go and compute them now.
    rptds.computeAllRepetitionIndices();

    % Since subset() is meant to operate at maximum granularity, we have
    % to index into RepetitionIndices to find the value corresponding to
    % a particular subset index.
    % For example, if a user does this:
    %
    %  rptds = RepeatedDatastore(arrayDatastore([2; 3]), RepeatFcn=@(x) x)
    %  newds = rptds.subset(4);
    %
    % The 4th subset really depends on counting the number of values
    % within the jagged cell array of RepetitionIndices. So for the above example:
    %
    %  disp(rptds.RepetitionIndices); % {[1 2];
    %                                 %  [1 2 3]}
    %
    % Here you can see the 4th subset corresponds to row 2, value 2.
    % That's what this code does, while also handling a vector of subset indices.

    % Find the number of repetitions on every read.
    numRepetitions = rptds.numRepetitionsPerRead();
    cumulativeNumRepetitions = cumsum(numRepetitions);

    % For every value in the subset indices, find the row index and
    % value index within a row.
    rowIndices = zeros(numel(subsetIndices), 1);
    newRepetitionIndices = zeros(numel(subsetIndices), 1);
    for index = 1:numel(subsetIndices)
        linearIndex = subsetIndices(index);
        [rowIndex, valueIndex] = linearIndicesToJaggedIndices(linearIndex, ...
                                                                       cumulativeNumRepetitions);

        % Get the actual repetition index by using the row and value
        % indices.
        row = rptds.RepetitionIndices{rowIndex};

        newRepetitionIndices(index) = row(valueIndex);
        rowIndices(index) = rowIndex;
    end

    % Small optimization - group adjacent rows with the same index into the same cell.
    % So if:  rowIndices   repetitionIndices
    %           [1;               [3;
    %            1;                2;
    %            2]                7]
    % Then this function returns:
    %         rowIndices   repetitionIndices
    %           [1;               {[3; 2];
    %            2]                7     }
    % This ensures that contiguous reads from the datastore are grouped together, avoiding
    % unnecessary duplicate reads.
    [newRepetitionIndices, rowIndices] = squeezeRepetitionIndices(newRepetitionIndices, rowIndices);

    % Subset the underlying datastore according to the new row indices.
    newUnderlyingDatastore = rptds.UnderlyingDatastore.subset(rowIndices);

    % Finally create the new RepeatedDatastore with the subsetted UnderlyingDatastore
    % and the new RepetitionIndices.
    newds = RepeatedDatastore(newUnderlyingDatastore, rptds.RepeatFcn, IncludeInfo=rptds.IncludeInfo, RepeatAllFcn=rptds.RepeatAllFcn);
    newds.RepetitionIndices = newRepetitionIndices;
    newds.reset();
end

function [rowIndex, valueIndex] = linearIndicesToJaggedIndices(linearIndex, cumulativeNumRepetitions)

    rowIndex = find(linearIndex <= cumulativeNumRepetitions, 1);

    if rowIndex == 1
        % The value index is just the linear index value (for the first row).
        valueIndex = linearIndex;
    else
        previousRowEnd = cumulativeNumRepetitions(rowIndex - 1);

        % The value index is the linear index less the previous row's ending point.
        valueIndex = linearIndex - previousRowEnd;
    end
end

function [repetitionIndices, rowIndices] = squeezeRepetitionIndices(repetitionIndices, rowIndices)
    if isempty(rowIndices)
        repetitionIndices = cell.empty(0, 1);
        return; % No indices to work on.
    end

    isRowRepeated = [false; diff(rowIndices) == 0];
    repeatedRowIndices = find(isRowRepeated);

    if isempty(repeatedRowIndices)
        repetitionIndices = num2cell(repetitionIndices);
        return; % No repeats.
    end

    squeezedRowIndices = rowIndices(~isRowRepeated);
    squeezedRepetitionIndices = cell(numel(squeezedRowIndices), 1);

    squeezedIndex = 0;
    for index = 1:numel(repetitionIndices)
        if isRowRepeated(index)
            % Add the new repetition index to the old one.
            squeezedRepetitionIndices{squeezedIndex} = [squeezedRepetitionIndices{squeezedIndex}; repetitionIndices(index)];
            % TODO: test repeated subset indices with 0 repetition indices.
        else
            squeezedIndex = squeezedIndex + 1;
            squeezedRepetitionIndices{squeezedIndex} = repetitionIndices(index);
        end
    end

    repetitionIndices = squeezedRepetitionIndices;
    rowIndices        = squeezedRowIndices;
end
