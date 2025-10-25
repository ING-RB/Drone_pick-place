function tf = hasdata(rptds)
%HASDATA   Returns true if there is data available to read from the RepeatedDatastore.

%   Copyright 2021 The MathWorks, Inc.

    tf = rptds.UnderlyingDatastore.hasdata() || rptds.InnerDatastore.hasdata();
end
