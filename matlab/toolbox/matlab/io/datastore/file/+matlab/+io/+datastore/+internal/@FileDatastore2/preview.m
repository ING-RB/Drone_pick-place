function data = preview(fds)
%PREVIEW   Return a subset of data from the start of the FileDatastore without
%          changing its current position.

%   Copyright 2022 The MathWorks, Inc.

    % If the FileDatastore is empty, preview should just return
    % the same result as readall to avoid erroring.
    if fds.numobservations() == 0
        data = fds.readall();
        return;
    end

    data = preview@matlab.io.Datastore(fds);
end
