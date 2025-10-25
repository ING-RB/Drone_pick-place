function n = numobservations(rptds)
%NUMOBSERVATIONS   Returns the number of reads in the RepeatedDatastore.

%   Copyright 2021 The MathWorks, Inc.

    % Need to populate all repetition information to find the total
    % number of reads.
    rptds.computeAllRepetitionIndices();

    % The number of reads is just the total number of values in the
    % RepetitionIndices cell array.
    n = sum(rptds.numRepetitionsPerRead(), 'all');
end
