function numRepetitions = numRepetitionsPerRead(rptds)
%numRepetitionsPerRead   Calculates the number of repetitions
%   for every read of the UnderlyingDatastore.
%
%   This is useful during subset and partition.

%   Copyright 2021 The MathWorks, Inc.

    % If all the RepetitionIndices are not already computed, go and compute them now.
    rptds.computeAllRepetitionIndices();

    % Just have to count the number of values in each member of RepetitionIndices.
    % TODO: check the empty datastore case, where RepetitionIndices is cell.empty(0, 1).
    numRepetitions = cellfun(@numel, rptds.RepetitionIndices, UniformOutput=true);
end
