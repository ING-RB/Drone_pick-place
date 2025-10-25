function [data, info] = read(pds)
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
        [data, info] = read@matlab.io.datastore.internal.ComposedDatastore(pds);
    catch ME
        % Unwrap the TransformedDatastore error returned.
        if ME.identifier == "MATLAB:datastoreio:transformeddatastore:badTransformDef"
            ME = ME.cause{1};
        end

        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end