function indices = computeRepetitionIndices(rptds, readPosition, data, info)
%computeRepetitionIndices   Gets the repetition indices at a particular position
%                           in the UnderlyingDatastore.
%
%   IDXS = computeRepetitionIndices(RPTDS, POS, DATA, INFO) uses the RepeatFcn
%       on RepeatedDatastore to return an array of indices IDXS corresponding
%       to the repetitions that need to be done at positition POS in the UnderlyingDatastore.
%
%       DATA and INFO must be outputs from the read() method on UnderlyingDatastore at
%       position POS.
%
%       POS must be a non-negative double integer value. The returned indices will be
%       a column vector of non-negative double integer values.
%
%   Note: if the repetition index at this position was already found and cached, then
%   the RepeatFcn is not called again. Just the value from the RepetitionIndices array
%   at position POS is returned.
%
%   See also: matlab.io.datastore.internal.RepeatedDatastore

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        rptds        (1, 1) matlab.io.datastore.internal.RepeatedDatastore
        readPosition (1, 1) double {mustBeInteger, mustBePositive}
        data
        info
    end

    % Check if the value is already cached on the RepetitionIndices array.
    % TODO: Improve error message for datastores that potentially implement
    %       numobservations or subset incorrectly?
    if ~isMissingType(rptds.RepetitionIndices{readPosition})
        % Just return the cached value.
        indices = rptds.RepetitionIndices{readPosition};
        return;
    end

    % Value wasn't cached, so we need to call the RepeatFcn.
    if rptds.IncludeInfo
        numRepeats = rptds.RepeatFcn(data, info);
    else
        numRepeats = rptds.RepeatFcn(data);
    end

    % TODO: Better error message when RepeatFcn returns something weird.
    attributes = ["scalar" "real" "integer" "nonnegative" "finite" "nonnan"];
    validateattributes(numRepeats, "numeric", attributes, "RepeatFcn")

    indices = rptds.expandNumRepetitionsValue(numRepeats);

    % Track the number of repetitions so we can return a cached value
    % the next time this is requested.
    rptds.RepetitionIndices{readPosition} = indices;
end

function tf = isMissingType(x)
    tf = isa(x, "missing");
end
