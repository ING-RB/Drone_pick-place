function filename = validateFilename(filename, functionName)
%

% Copyright 2020 The MathWorks, Inc.

% Check datatype validity.
    arguments
        filename
        functionName = "writestruct";
    end

    validateattributes(filename, ["string", "char"], ["scalartext", "nonempty"], ...
        functionName, "FILENAME");
    filename = string(filename);
end
