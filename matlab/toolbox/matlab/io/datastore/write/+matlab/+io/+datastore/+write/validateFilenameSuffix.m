function filenameSuffix = validateFilenameSuffix(filenameSuffix)
%validateFilenameSuffix    Validate that the suffix provided does not
%   contain characters that cannot be used in a filename.

%   Copyright 2023 The MathWorks, Inc.
    validateattributes(filenameSuffix, ["char","string"], "scalartext");
    tf = contains(filenameSuffix,["\","/","<",">",":","?","*","|",""""]);
    if any(tf)
        error(message("MATLAB:io:datastore:write:write:BadSuffix"));
    end
    filenameSuffix = convertCharsToStrings(filenameSuffix);
end