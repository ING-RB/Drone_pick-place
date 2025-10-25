function neighborSearcher = createNeighborSearcher(approxSearch, connMech)
%createNeighborSearcher - Create a NeighborSearcher object

% Copyright 2018 The MathWorks, Inc.

%#codegen

if approxSearch
    neighborSearcher = matlabshared.planning.internal.SqrtApproxNeighborSearcher(connMech);
else
    neighborSearcher = matlabshared.planning.internal.ExactNeighborSearcher(connMech);
end
end