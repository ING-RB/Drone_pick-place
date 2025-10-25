function cyc = hasCycles(G)
%HASCYCLES   Determine whether MLGraph has cycles
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2015-2020 The MathWorks, Inc.

if numnodes(G) == 0
    cyc = false;
    return;
end

if ismultigraph(G) || numedges(G) >= numnodes(G)
    cyc = true;
    return;
end

[~, nrBins] = connectedComponents(G);
cyclerank = numedges(G)-numnodes(G)+nrBins;
cyc = cyclerank > 0;






