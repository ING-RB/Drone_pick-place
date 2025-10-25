function tf = hasdata(rds)
%HASDATA   Returns true if there is data available to read from the RangeDatastore.

%   Copyright 2021 The MathWorks, Inc.

    tf = rds.NumValuesRead < rds.TotalNumValues;
end
