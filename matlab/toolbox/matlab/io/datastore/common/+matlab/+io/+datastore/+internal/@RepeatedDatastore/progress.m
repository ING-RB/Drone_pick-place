function frac = progress(rptds)
%PROGRESS   Return the fraction of data read from the RepeatedDatastore.
%
%   The PROGRESS method will return:
%   - 0 if no data has been read yet,
%   - 1 if all the data has been read, and
%   - a value between 0 and 1 if some reads are completed, but not all.
%
%   The fraction returned by the PROGRESS method will monotonically increase
%   after each READ method call until it reaches 1.
%
%   The fraction returned by the PROGRESS method can be reset back to 0 by
%   calling the RESET method on the RepeatedDatastore.

%   Copyright 2021 The MathWorks, Inc.

    if ~rptds.hasdata()
        frac = 1;
        return;
    end

    % We have algorithm choices with progress. This does fine-grained progress,
    % but without reflecting the exact distribution of RepetitionIndices.
    % This avoids having to compute all RepetitionIndices on calling progress().
    % This can be changed if there's a need for exact distribution
    % of progress() value results.

    numReadsCompleted = double(rptds.UnderlyingDatastoreIndex.NumValuesRead);

    if numReadsCompleted == 0
        frac = 0;
        return;
    end

    numOuterReads = rptds.UnderlyingDatastore.numobservations();
    startFraction = (numReadsCompleted - 1) / numOuterReads;
    endFraction   =  numReadsCompleted      / numOuterReads;

    % Return a value between the start and end fractions depending on the
    % InnerDatastore's progress.
    frac = startFraction + ((endFraction - startFraction) * rptds.InnerDatastore.progress());
end
