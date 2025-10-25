function data = readall(fds, varargin)
%READALL   Read all of the data from the FileDatastore2.
%
%   DATA = READALL(FDS) returns all of the data in the FileDatastore2.
%
%   DATA = READALL(FDS, UseParallel=TF) specifies whether a parallel
%       pool is used to read all of the data. By default, "UseParallel" is
%       set to false.

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.read.*
    if validateReadallParameters(varargin{:})
        data = readallParallel(fds);
        return;
    end

    if fds.numobservations() == 0
        % Cannot do even 1 read from the ReadFcn, so FileDatastore2 doesn't
        % know what the schema of the data should be.
        % Legacy FileDatastore returned 0-by-1 double here (when UniformRead=true).
        % But 0-by-1 double wont pass contract tests since its not vertcat-able with
        % tables. So return 0-by-0 double here instead.
        data = [];
        return;
    end

    data = readall@matlab.io.Datastore(fds);
end