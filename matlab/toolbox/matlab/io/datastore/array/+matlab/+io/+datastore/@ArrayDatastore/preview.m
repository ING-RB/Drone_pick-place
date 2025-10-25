function data = preview(arrds)
%PREVIEW   Return a subset of data from the start of the ArrayDatastore without
%          changing its current position.

%   Copyright 2020 The MathWorks, Inc.

    % If the ArrayDatastore is empty, preview should just return
    % the same result as readall to avoid erroring.
    if arrds.TotalNumBlocks == 0
        data = arrds.readall();
        return;
    end

    % Based on the matlab.io.Datastore preview() method, but
    % use ReadSize to get 8 blocks instead of slicing read output.
    copyds = copy(arrds);
    copyds.ReadSize = 8;
    reset(copyds);
    data = read(copyds);
end
