function filenamePrefix = validateFilenamePrefix(filenamePrefix)
%validateFilenamePrefix    Validate that the prefix provided does not
%   contain characters that cannot be used in a filename.

%   Copyright 2023 The MathWorks, Inc.
    validateattributes(filenamePrefix, ["char","string"], "scalartext");
    tf = contains(filenamePrefix,["\","/","<",">",":","?","*","|",""""]);
    if any(tf)
        error(message("MATLAB:io:datastore:write:write:BadPrefix"));
    end
    filenamePrefix = convertCharsToStrings(filenamePrefix);
end