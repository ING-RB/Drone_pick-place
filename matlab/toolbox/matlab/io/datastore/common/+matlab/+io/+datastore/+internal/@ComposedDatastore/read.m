function [data, info] = read(compds)
%READ   Return the next block of data from the datastore.
%
%   DATA = READ(DS) reads the next block of data from the datastore.
%
%   [DATA, INFO] = READ(DS) also returns a struct containing
%       additional information about DATA.
%
%   See also: matlab.io.Datastore

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        [data, info] = compds.UnderlyingDatastore.read();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
