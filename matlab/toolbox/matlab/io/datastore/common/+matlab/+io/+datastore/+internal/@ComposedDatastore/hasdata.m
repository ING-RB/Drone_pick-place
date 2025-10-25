function tf = hasdata(compds)
%HASDATA   Returns true if there is data available to read from the datastore.

%   Copyright 2021 The MathWorks, Inc.

    tf = compds.UnderlyingDatastore.hasdata();
end
