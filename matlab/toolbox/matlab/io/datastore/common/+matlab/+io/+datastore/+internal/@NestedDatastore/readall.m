function data = readall(nds, varargin)
%READALL   Read all of the data from the NestedDatastore
%
%   DATA = READALL(NDS) returns all of the data in the NestedDatastore.
%
%   DATA = READALL(NDS, "UseParallel", TF) specifies whether a parallel
%   pool is used to read all of the data. By default, "UseParallel" is
%   set to false.

%   Copyright 2021-2022 The MathWorks, Inc.

    if matlab.io.datastore.read.validateReadallParameters(varargin{:})
        data = matlab.io.datastore.read.readallParallel(nds);
        return;
    end

    copyDs = copy(nds);
    copyDs.reset();

    if ~copyDs.hasdata()
        % Cannot do even 1 read from the OuterDatastore. This means
        % that we can't find the "schema" of the data since no
        % InnerDatastore can be created.
        % Because of this, just return a 0-by-0 empty double.
        % NestedDatastore could potentially have a "SchemaFcn" in the
        % future to customize the output of this.
        data = [];
        return;
    end

    % Read into a cell and vertcat at the end to reduce incremental
    % vertcat overhead.
    data = cell.empty(0, 1);
    while hasdata(copyDs)
        data{end+1} = read(copyDs); %#ok<AGROW>
    end
    data = vertcat(data{:});
end
