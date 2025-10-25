function data = preview(rds)
%PREVIEW   Return a subset of data from the start of the RangeDatastore without
%          changing its current position.

%   Copyright 2021 The MathWorks, Inc.

    % If the RangeDatastore is empty, preview should just return
    % the same result as readall to avoid erroring.
    if rds.TotalNumValues == 0
        data = rds.readall();
        return;
    end

    % Based on the matlab.io.Datastore preview() method, but
    % use ReadSize to get 8 blocks instead of slicing read output.
    copyds = copy(rds);
    copyds.ReadSize = 8;
    reset(copyds);
    data = read(copyds);
end
