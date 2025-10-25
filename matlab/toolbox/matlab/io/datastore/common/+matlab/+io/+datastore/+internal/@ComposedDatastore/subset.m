function newds = subset(ds, indices)
%SUBSET   returns a new datastore containing the specified read indices.
%
%   NEWDS = SUBSET(DS, INDICES) creates a new datastore that only contains
%       reads from the input datastore DS corresponding to INDICES.
%
%       It is only valid to call the SUBSET method on a
%       datastore if it returns isSubsettable true.
%
%       INDICES must be a vector of positive and unique integer numeric
%       values. INDICES can be a 0-by-1 empty array and does not need
%       to be provided in any sorted order when nonempty.
%
%       The output datastore NEWDS, contains the reads
%       corresponding to INDICES and in the same order as INDICES.
%
%       INDICES can also be specified as a N-by-1 vector of logical
%       values, where N is the number of reads in the datastore.
%
%   See also matlab.io.Datastore.isSubsettable, matlab.io.datastore.ImageDatastore.subset

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        ds.verifySubsettable("subset");

        newds = copy(ds);
        newds.UnderlyingDatastore = ds.UnderlyingDatastore.subset(indices);
        newds.reset();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
