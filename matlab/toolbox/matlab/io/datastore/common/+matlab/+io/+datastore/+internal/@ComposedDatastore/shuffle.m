function newds = shuffle(ds)
%SHUFFLE   returns a new datastore containing data in a shuffled (randomized) order.
%
%   See also: matlab.io.datastore.ImageDatastore.shuffle

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        ds.verifyShuffleable("shuffle");

        newds = copy(ds);
        newds.UnderlyingDatastore = ds.UnderlyingDatastore.shuffle();
        newds.reset();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
