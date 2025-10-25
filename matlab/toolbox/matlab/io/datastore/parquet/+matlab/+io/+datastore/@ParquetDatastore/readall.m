function data = readall(pds, varargin)
%READALL   Read all of the data from the datastore
%
%   DATA = READALL(DS) returns all of the data in the datastore.
%
%   DATA = READALL(DS, UseParallel=TF) specifies whether a parallel
%       pool is used to read all of the data. By default, "UseParallel" is
%       set to false.

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        data = readall@matlab.io.datastore.internal.ComposedDatastore(pds, varargin{:});
    catch ME
        % Unwrap the TransformedDatastore error returned.
        if ME.identifier == "MATLAB:datastoreio:transformeddatastore:badTransformDef"
            ME = ME.cause{1};
        end

        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end