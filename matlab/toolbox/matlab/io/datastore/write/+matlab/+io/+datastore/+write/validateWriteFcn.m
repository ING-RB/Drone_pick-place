function writeFcn = validateWriteFcn(writeFcn)
%validateWriteFcn    Validate that the supplied write function is a
%   function handle

%   Copyright 2023 The MathWorks, Inc.
    if ~isa(writeFcn, "function_handle")
        error(message("MATLAB:io:datastore:write:write:InvalidWriteFcn"));
    end
end
