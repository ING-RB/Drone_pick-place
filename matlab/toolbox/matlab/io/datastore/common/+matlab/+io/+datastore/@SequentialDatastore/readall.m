function data = readall(ds, varargin)
%READALL   Returns all combined data from the SequentialDatastore
%
%   DATA = READALL(DS) returns all of the vertically-concatenated
%   data within this SequentialDatastore.
%
%   DATA = READALL(DS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.
%
%   See also read, hasdata, reset, preview

%   Copyright 2022 The MathWorks, Inc.

if nargin > 1
    matlab.io.datastore.read.validateReadallParameters(varargin{:});
end

copyds = copy(ds);
reset(copyds);

if ~hasdata(copyds)
    % Default for empty SequentialDatastore is [].
    if isempty(copyds.UnderlyingDatastores)
        data = [];
        return
    else
        % If all underlying datastores are empty, readall empty type should
        % match preview.
        data = preview(copyds);
        return
    end
end

try
    data = readall@matlab.io.Datastore(copyds, varargin{:});
catch ME
    throw(ME);
end
end