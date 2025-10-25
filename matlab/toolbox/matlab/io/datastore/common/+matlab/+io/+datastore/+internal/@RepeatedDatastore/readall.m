function data = readall(rptds, varargin)
%READALL   Read all of the data from the RepeatedDatastore
%
%   DATA = READALL(RPTDS) returns all of the data in the RepeatedDatastore.
%
%   DATA = READALL(RPTDS, UseParallel=TF) specifies whether a parallel
%       pool is used to read all of the data. By default, "UseParallel" is
%       set to false.

%   Copyright 2021-2022 The MathWorks, Inc.

    copyDs = copy(rptds);
    copyDs.reset();

    if ~copyDs.hasdata()
        % Cannot do even 1 read from the UnderlyingDatastore.
        % Pass through readall on the UnderlyingDatastore instead.
        data = copyDs.UnderlyingDatastore.readall();
        return;
    end

    data = readall@matlab.io.Datastore(copyDs, varargin{:});
end
