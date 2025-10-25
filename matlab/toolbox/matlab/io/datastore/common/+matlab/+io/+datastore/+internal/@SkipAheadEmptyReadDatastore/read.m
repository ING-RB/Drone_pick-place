function [data, info] = read(ds)
%READ   Return the next block of data from the SkipAheadEmptyReadDatastore.
%
%   [DATA, INFO] = READ(SAERDS) reads the next chunk of data from the SkipAheadEmptyReadDatastore.
%       If EmptyFcn returns true, then the current read skips ahead to the
%       next read of the underlying datastore.
%
%
%   See also: matlab.io.datastore.internal.SkipAheadEmptyReadDatastore

%   Copyright 2022 The MathWorks, Inc.

% Since in MATLAB, we don't have do-while loop,
% we are mimicing by setting tf to true first, and ensure
% we run the while loop at least once before checking condition
% in executeEmptyFcn
tf = true;
data = [];
info = [];
while (tf)
    if (ds.IncludeInfo)
        % Some datastores have very small data outputs but larger and more expensive
        % info structs like ArrayDatastore and TabularTextDatastore when ReadSize=1.
        % so, we should include info, only when explicitly asked
        [data, info] = read(ds.UnderlyingDatastore);
    else
        data = read(ds.UnderlyingDatastore);
    end

    % The hasdata(ds) in the following line, will cause to break out of the loop
    % if all the followup partitions (including the last partition)
    % have empty data.

    tf = executeEmptyFcn(ds, data, info) && ...
        hasdata(ds);
end
end
