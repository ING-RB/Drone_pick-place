function out = open(fh)
    arguments
        fh (1,1) function_handle
    end

    if nargout
        out = [];
    end

    try
        edit(fh);
    catch exception
        throw(exception);
    end
end

%   Copyright 2023 The MathWorks, Inc.
