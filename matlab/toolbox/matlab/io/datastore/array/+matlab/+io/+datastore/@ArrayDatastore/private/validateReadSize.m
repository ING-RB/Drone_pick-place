function readSize = validateReadSize(readSize)
%

%   Copyright 2020 The MathWorks, Inc.

    validateattributes(readSize, "numeric", ["scalar", "real", "integer", "positive"], ...
                       "matlab.io.datastore.ArrayDatastore", "ReadSize");

    readSize = double(readSize);
end
