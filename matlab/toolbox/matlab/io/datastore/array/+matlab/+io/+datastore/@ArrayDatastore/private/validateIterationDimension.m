function iterationDimension = validateIterationDimension(iterationDimension)
%

%   Copyright 2020 The MathWorks, Inc.

    validateattributes(iterationDimension, "numeric", ["scalar", "real", "integer", "positive"], ...
                       "matlab.io.datastore.ArrayDatastore", "IterationDimension");

    iterationDimension = double(iterationDimension);
end
