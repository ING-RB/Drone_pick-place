function tf = hasdata(arrds)
%HASDATA   Returns true if there is data available to read from the ArrayDatastore.

%   Copyright 2020 The MathWorks, Inc.
    tf = arrds.NumBlocksRead < arrds.TotalNumBlocks;
end
