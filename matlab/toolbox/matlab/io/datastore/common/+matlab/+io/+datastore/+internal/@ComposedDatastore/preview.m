function data = preview(compds)
%PREVIEW   Return a subset of data from the start of the datastore without
%          changing its current position.

%   Copyright 2021-2022 The MathWorks, Inc.

    try
        data = compds.UnderlyingDatastore.preview();
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
