function data = readall(rds, varargin)
%READALL   Read all of the data from the RangeDatastore
%
%   DATA = READALL(RDS) returns all of the data in the RangeDatastore.
%
%   DATA = READALL(RDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.

%   Copyright 2021 The MathWorks, Inc.

    if matlab.io.datastore.read.validateReadallParameters(varargin{:})
        data = matlab.io.datastore.read.readallParallel(rds);
        return;
    end

    data = rds.Start:rds.End;
    data = reshape(data, [], 1);
end
