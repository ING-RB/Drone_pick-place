function computeAllRepetitionIndices(rptds)
%computeAllRepetitionIndices   Compute all the RepetitionIndices values on this datastore.
%
%   This method forces computation of all the RepetitionIndices values.
%   It must be called before numpartitions and numobservations.
%   Since partition/subset/shuffle also call numobservations,
%   they also indirectly call this function.
%
%   computeAllRepetitionIndices is a slow function. This is because it has
%   to perform every read (that hasn't occurred yet) on the UnderlyingDatastore
%   and call the RepeatFcn on the output of every read.
%
%   As a result, if the OuterDatastore takes significant time to perform read()
%   or if the RepeatFcn takes a lot of time to execute, this function will block
%   for a significant amount of time during partition, subset, numpartitions, etc.
%
%   TODO: Experiment with alternate ways to return faster partition and numpartitions
%         information. This isn't possible with subset/numobservations since
%         they always have to be at the granularity of read, but partition
%         can be more coarse grained.

%   Copyright 2021-2022 The MathWorks, Inc.

    % Iterate over the RepetitionIndices cell array and get the indices of
    % all the values that are missing.
    missingIndices = cellfun(@isMissingType, rptds.RepetitionIndices);
    missingIndices = find(missingIndices);
    missingIndices = reshape(missingIndices, 1, []);

    % Early exit if all RepetitionIndices are already computed.
    if isempty(missingIndices)
        return;
    end

    % Small optimization: subset the UnderlyingDatastore so we only perform
    % the reads that are missing in the RepetitionIndices array.
    subds = rptds.UnderlyingDatastore.subset(missingIndices);

    missingRepeats = rptds.RepeatAllFcn(subds, rptds.RepeatFcn, rptds.IncludeInfo);

    % TODO: Better error message when RepeatAllFcn returns something weird.
    attributes = ["vector" "real" "integer" "nonnegative" "finite" "nonnan"];
    validateattributes(missingRepeats, "numeric", attributes, "RepeatFcn")
    missingRepeats = double(missingRepeats);

    % Create a temporary local copy of RepetRepetitionIndices to avoid the
    % cost of property validation on each iteration in the for loop below.
    reptitionIndices = rptds.RepetitionIndices;

    % Iterate over the subsetted UnderylingDatastore and populate each
    % RepetitionIndices value.
    for index = 1:subds.numpartitions()
        missingPosition = missingIndices(index);
        numRepetitions = missingRepeats(index);

        % Cache the NumRepetitions value through RepetitionIndices.
        reptitionIndices{missingPosition} = rptds.expandNumRepetitionsValue(numRepetitions);
    end

    % Set RepetitionIndices to the "filled in" cell array
    rptds.RepetitionIndices = reptitionIndices;
end

function tf = isMissingType(x)
    tf = isa(x, "missing");
end
