function data = validateData(data, iterationDimension)
%

%   Copyright 2020 The MathWorks, Inc.

    % 1. ndims validation.
    try
        n = ndims(data);
    catch ME
        throwValidationErrorWithCause("MATLAB:io:datastore:array:validation:NdimsError", ...
                                      class(data), ME);
    end
    n = double(n);

    % Verify that ndims returns a value that is compatible with later usage in ArrayDatastore.
    try
        validateattributes(n, "numeric", ["scalar", "integer", "positive"]);
    catch ME
        error(message("MATLAB:io:datastore:array:validation:UnexpectedDatatypeFromNdims", ...
                      class(data)));
    end

    % 2. size validation.
    try
        sz = size(data);
    catch ME
        throwValidationErrorWithCause("MATLAB:io:datastore:array:validation:SizeError", ...
                                      class(data), ME);
    end

    % Verify that size returns a value that is compatible with later usage in ArrayDatastore.
    try
        validateattributes(sz, "numeric", ["vector", "integer", "nonnegative"]);
    catch ME
        error(message("MATLAB:io:datastore:array:validation:UnexpectedDatatypeFromSize", ...
                      class(data)));
    end

    % 3. parentheses-based indexing validation.
    try
        % Only index into the first element if the input datatype is non-empty.
        if prod(sz) > 0
            index = num2cell(ones(1, max([n iterationDimension])));
            result = data(index{:});
        end
    catch ME
        throwValidationErrorWithCause("MATLAB:io:datastore:array:validation:IndexingError", ...
                                      class(data), ME);
    end
end

function throwValidationErrorWithCause(msgid, datatype, ME)
    MEBase = MException(message(msgid, datatype));

    % Add the original error as a cause.
    MEBase = MEBase.addCause(ME);
    throw(MEBase);
end
