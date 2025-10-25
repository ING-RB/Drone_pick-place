function data = readall(schds, varargin)
%READALL   Read all of the data from the SchemaDatastore

%   Copyright 2022 The MathWorks, Inc.

    if schds.isEmptyDatastore()
        data = schds.Schema;
    else
        data = schds.UnderlyingDatastore.readall(varargin{:});
    end
end
