function tf = hasdata(nds)
%HASDATA   Returns true if there is data available to read from the NestedDatastore.

%   Copyright 2021 The MathWorks, Inc.

    tf = nds.OuterDatastore.hasdata() || nds.InnerDatastore.hasdata();
end
