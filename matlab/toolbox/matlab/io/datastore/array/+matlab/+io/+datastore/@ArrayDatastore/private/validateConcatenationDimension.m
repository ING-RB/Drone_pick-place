function concatenationDimension = validateConcatenationDimension(concatenationDimension)
%

%   Copyright 2020 The MathWorks, Inc.

    validateattributes(concatenationDimension, "numeric", ["scalar", "real", "integer", "positive"], ...
                       "matlab.io.datastore.ArrayDatastore", "ConcatenationDimension");

    concatenationDimension = double(concatenationDimension);
end
