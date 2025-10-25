function data = readall(compds, varargin)
%READALL   Read all of the data from the datastore
%
%   DATA = READALL(DS) returns all of the data in the datastore.
%
%   DATA = READALL(DS, UseParallel=TF) specifies whether a parallel
%       pool is used to read all of the data. By default, "UseParallel" is
%       set to false.

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        data = compds.UnderlyingDatastore.readall(varargin{:});
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
