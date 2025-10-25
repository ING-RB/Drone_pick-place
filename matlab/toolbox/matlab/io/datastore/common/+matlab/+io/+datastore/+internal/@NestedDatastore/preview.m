function data = preview(nds)
%PREVIEW   Return a subset of data from the start of the NestedDatastore without
%          changing its current position.

%   Copyright 2021 The MathWorks, Inc.

    copyDs = copy(nds);
    copyDs.reset();

    % If the NestedDatastore is empty, preview should just return
    % the same result as readall to avoid erroring.
    if ~copyDs.hasdata()
        data = copyDs.readall();
        return;
    end

    data = preview@matlab.io.Datastore(copyDs);
end
