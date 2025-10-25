function frac = progress(arrds)
%PROGRESS   Return the fraction of data read from the ArrayDatastore.
%
%   The PROGRESS method will return:
%   - 0 if no data has been read yet,
%   - 1 if all the data has been read, and
%   - a value between 0 and 1 if some reads are completed, but not all.
%
%   The fraction returned by the PROGRESS method will monotonically increase
%   after each READ method call until it reaches 1.
%
%   The fraction returned by the PROGRESS method can be reset back to 0 by
%   calling the RESET method on the ArrayDatastore.
%
%   See also: matlab.io.datastore.ArrayDatastore/read,
%             matlab.io.datastore.ArrayDatastore/reset

%   Copyright 2020 The MathWorks, Inc.
    if arrds.TotalNumBlocks == 0
        % Handle the empty case too.
        frac = 1;
    else
        frac = arrds.NumBlocksRead / arrds.TotalNumBlocks;
    end
end
