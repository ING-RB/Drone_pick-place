function data = preview(schds)
%PREVIEW   Return a subset of data from the start of the datastore without
%          changing its current position.

%   Copyright 2022 The MathWorks, Inc.

    if schds.isEmptyDatastore()
        data = schds.Schema;
    else
        data = schds.UnderlyingDatastore.preview();
    end
end
