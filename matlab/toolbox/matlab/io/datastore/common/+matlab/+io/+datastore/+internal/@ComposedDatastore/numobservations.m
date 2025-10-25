function n = numobservations(ds)
%NUMOBSERVATIONS   Returns the number of reads in the datastore.

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        ds.verifySubsettable("numobservations");

        n = ds.UnderlyingDatastore.numobservations();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
