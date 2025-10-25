function mustBeColumn(x)
%mustBeColumn Validate that value is a column vector
%   mustBeColumn(A) throws an error if A is not a column vector.
%   MATLAB calls iscolumn to determine if A is a column vector.
%
%   See also: iscolumn, mustBeMatrix.

%   Copyright 2024 The MathWorks, Inc.

if ~iscolumn(x)
    throwAsCaller(MException(message('MATLAB:validators:mustBeColumn')));
end
